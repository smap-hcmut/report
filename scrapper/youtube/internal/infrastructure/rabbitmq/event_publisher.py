"""
DataCollected Event Publisher Implementation

Publishes data.collected events to RabbitMQ smap.events exchange.
This is used to notify downstream services (e.g., Analytics) when
batch data has been uploaded to MinIO.

Features:
- Automatic retry with exponential backoff
- Robust connection handling
- Dead-letter support for permanent failures
"""

import asyncio
import json
import uuid
from typing import Optional, Dict, Any, List
from datetime import datetime, timezone

from aio_pika import connect_robust, Message, ExchangeType
from aio_pika.abc import AbstractChannel, AbstractExchange, AbstractConnection

from utils.logger import logger


# Retry configuration
DEFAULT_MAX_RETRIES = 3
DEFAULT_INITIAL_DELAY = 1.0  # seconds
DEFAULT_MAX_DELAY = 30.0  # seconds
DEFAULT_BACKOFF_MULTIPLIER = 2.0


class DataCollectedEventPublisher:
    """
    RabbitMQ publisher for data.collected events.

    Publishes to smap.events exchange (topic type) with routing key 'data.collected'.
    Used to notify downstream services when batch data is uploaded to MinIO.

    Features:
    - Exponential backoff retry on publish failures
    - Dead-letter queue for permanently failed events
    - Configurable retry parameters
    """

    def __init__(
        self,
        connection_url: str,
        exchange_name: str = "smap.events",
        routing_key: str = "data.collected",
        max_retries: int = DEFAULT_MAX_RETRIES,
        initial_delay: float = DEFAULT_INITIAL_DELAY,
        max_delay: float = DEFAULT_MAX_DELAY,
        backoff_multiplier: float = DEFAULT_BACKOFF_MULTIPLIER,
    ):
        """
        Initialize event publisher with connection details and retry configuration.

        Args:
            connection_url: RabbitMQ connection URL (amqp://...)
            exchange_name: Exchange to publish to (default: smap.events)
            routing_key: Routing key for messages (default: data.collected)
            max_retries: Maximum number of retry attempts (default: 3)
            initial_delay: Initial delay between retries in seconds (default: 1.0)
            max_delay: Maximum delay between retries in seconds (default: 30.0)
            backoff_multiplier: Multiplier for exponential backoff (default: 2.0)
        """
        if not connection_url:
            raise ValueError("connection_url is required")

        self.connection_url = connection_url
        self.exchange_name = exchange_name
        self.routing_key = routing_key

        # Retry configuration
        self.max_retries = max_retries
        self.initial_delay = initial_delay
        self.max_delay = max_delay
        self.backoff_multiplier = backoff_multiplier

        self.connection: Optional[AbstractConnection] = None
        self.channel: Optional[AbstractChannel] = None
        self.exchange: Optional[AbstractExchange] = None

        self._is_connected = False
        self._failed_events: List[Dict[str, Any]] = (
            []
        )  # Dead-letter queue for failed events

    async def connect(self):
        """
        Establish connection to RabbitMQ and declare exchange.

        Uses connect_robust for automatic reconnection on connection loss.
        Exchange type is TOPIC to allow flexible routing patterns.
        """
        try:
            logger.info(
                "Connecting to RabbitMQ event publisher - Exchange: %s",
                self.exchange_name,
            )

            # Create robust connection (auto-reconnect)
            self.connection = await connect_robust(
                self.connection_url, loop=asyncio.get_event_loop()
            )

            # Create channel
            self.channel = await self.connection.channel()

            # Declare exchange (topic type for flexible routing)
            self.exchange = await self.channel.declare_exchange(
                self.exchange_name, ExchangeType.TOPIC, durable=True
            )

            self._is_connected = True
            logger.info(
                "Connected to RabbitMQ event publisher - Exchange: %s, Routing Key: %s",
                self.exchange_name,
                self.routing_key,
            )

        except Exception as exc:
            logger.error("Failed to connect RabbitMQ event publisher: %s", exc)
            self._is_connected = False
            raise

    async def close(self):
        """Close RabbitMQ connection gracefully."""
        try:
            if self.channel:
                await self.channel.close()
                logger.debug("Event publisher channel closed")

            if self.connection:
                await self.connection.close()
                logger.debug("Event publisher connection closed")

            self._is_connected = False
            logger.info("RabbitMQ event publisher connection closed")

        except Exception as exc:
            logger.error("Error closing RabbitMQ event publisher connection: %s", exc)

    async def _publish_with_retry(
        self,
        event_payload: Dict[str, Any],
        job_id: str,
    ) -> bool:
        """
        Publish event with exponential backoff retry logic.

        Args:
            event_payload: Event payload to publish
            job_id: Job ID for logging

        Returns:
            True if published successfully, False if all retries failed
        """
        delay = self.initial_delay
        last_exception: Optional[Exception] = None

        for attempt in range(self.max_retries + 1):
            try:
                # Serialize to JSON with UTF-8 encoding
                json_body = json.dumps(event_payload, ensure_ascii=False)
                encoded_body = json_body.encode("utf-8")

                # Create message with proper content type
                message = Message(
                    body=encoded_body,
                    content_type="application/json",
                    content_encoding="utf-8",
                    delivery_mode=2,  # Persistent message
                )

                # Publish to exchange
                await self.exchange.publish(message, routing_key=self.routing_key)

                if attempt > 0:
                    logger.info(
                        "Successfully published event after %d retries for job %s",
                        attempt,
                        job_id,
                    )
                return True

            except Exception as exc:
                last_exception = exc
                if attempt < self.max_retries:
                    logger.warning(
                        "Failed to publish event for job %s (attempt %d/%d): %s. "
                        "Retrying in %.1f seconds...",
                        job_id,
                        attempt + 1,
                        self.max_retries + 1,
                        exc,
                        delay,
                    )
                    await asyncio.sleep(delay)
                    # Exponential backoff with max cap
                    delay = min(delay * self.backoff_multiplier, self.max_delay)
                else:
                    logger.error(
                        "Failed to publish event for job %s after %d attempts: %s",
                        job_id,
                        self.max_retries + 1,
                        exc,
                    )

        # All retries failed - add to dead-letter queue
        self._failed_events.append(
            {
                "event_payload": event_payload,
                "job_id": job_id,
                "failed_at": datetime.now(timezone.utc).isoformat(),
                "last_error": (
                    str(last_exception) if last_exception else "Unknown error"
                ),
                "retry_count": self.max_retries + 1,
            }
        )
        logger.error(
            "Event added to dead-letter queue for job %s. " "Total failed events: %d",
            job_id,
            len(self._failed_events),
        )
        return False

    async def publish_data_collected(
        self,
        project_id: str,
        job_id: str,
        platform: str,
        minio_path: str,
        content_count: int,
        batch_index: int,
        task_type: Optional[str] = None,
        brand_name: Optional[str] = None,
        keyword: Optional[str] = None,
        total_batches: Optional[int] = None,
    ) -> bool:
        """
        Publish data.collected event to smap.events exchange with retry logic.

        Args:
            project_id: Project identifier
            job_id: Job identifier
            platform: Platform name (tiktok, youtube)
            minio_path: Path to uploaded batch in MinIO
            content_count: Number of items in the batch
            batch_index: Index of this batch (1-based)
            task_type: Task type for routing (e.g., 'research_and_crawl')
            brand_name: Brand name being crawled
            keyword: Search keyword used
            total_batches: Total number of batches (optional)

        Returns:
            True if published successfully, False if all retries failed

        Raises:
            RuntimeError: If not connected to RabbitMQ
        """
        if not self._is_connected or not self.exchange:
            raise RuntimeError("Not connected to RabbitMQ. Call connect() first.")

        # Build event payload (Contract v2.0 compliant)
        event_payload = {
            "event_id": f"evt_{uuid.uuid4().hex[:12]}",
            "event_type": "data.collected",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "payload": {
                "project_id": project_id,
                "job_id": job_id,
                "platform": platform,
                "minio_path": minio_path,
                "content_count": content_count,
                "batch_index": batch_index,
                "task_type": task_type or "research_and_crawl",
                "brand_name": brand_name or "",
                "keyword": keyword or "",
            },
        }

        if total_batches is not None:
            event_payload["payload"]["total_batches"] = total_batches

        # Publish with retry
        success = await self._publish_with_retry(event_payload, job_id)

        if success:
            logger.info(
                "Published data.collected event - Project: %s, Job: %s, "
                "Platform: %s, Batch: %d, Items: %d, Path: %s",
                project_id,
                job_id,
                platform,
                batch_index,
                content_count,
                minio_path,
            )
            logger.debug("Event payload: %s", event_payload)

        return success

    @property
    def is_connected(self) -> bool:
        """Check if publisher is connected to RabbitMQ."""
        return self._is_connected

    @property
    def failed_events(self) -> List[Dict[str, Any]]:
        """Get list of failed events (dead-letter queue)."""
        return self._failed_events.copy()

    @property
    def failed_event_count(self) -> int:
        """Get count of failed events."""
        return len(self._failed_events)

    def clear_failed_events(self) -> List[Dict[str, Any]]:
        """
        Clear and return failed events from dead-letter queue.

        Returns:
            List of failed events that were cleared
        """
        events = self._failed_events.copy()
        self._failed_events.clear()
        logger.info("Cleared %d failed events from dead-letter queue", len(events))
        return events

    async def retry_failed_events(self) -> Dict[str, int]:
        """
        Retry publishing all failed events from dead-letter queue.

        Returns:
            Dict with 'success' and 'failed' counts
        """
        if not self._failed_events:
            return {"success": 0, "failed": 0}

        events_to_retry = self._failed_events.copy()
        self._failed_events.clear()

        success_count = 0
        failed_count = 0

        for failed_event in events_to_retry:
            event_payload = failed_event["event_payload"]
            job_id = failed_event["job_id"]

            success = await self._publish_with_retry(event_payload, job_id)
            if success:
                success_count += 1
            else:
                failed_count += 1

        logger.info(
            "Retry failed events completed: %d success, %d failed",
            success_count,
            failed_count,
        )
        return {"success": success_count, "failed": failed_count}


class DataCollectedEventPublisherContext:
    """Async context manager for DataCollectedEventPublisher lifecycle management."""

    def __init__(
        self,
        connection_url: str,
        exchange_name: str = "smap.events",
        routing_key: str = "data.collected",
        max_retries: int = DEFAULT_MAX_RETRIES,
        initial_delay: float = DEFAULT_INITIAL_DELAY,
        max_delay: float = DEFAULT_MAX_DELAY,
        backoff_multiplier: float = DEFAULT_BACKOFF_MULTIPLIER,
    ):
        self.publisher = DataCollectedEventPublisher(
            connection_url=connection_url,
            exchange_name=exchange_name,
            routing_key=routing_key,
            max_retries=max_retries,
            initial_delay=initial_delay,
            max_delay=max_delay,
            backoff_multiplier=backoff_multiplier,
        )

    async def __aenter__(self) -> DataCollectedEventPublisher:
        await self.publisher.connect()
        return self.publisher

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.publisher.close()
