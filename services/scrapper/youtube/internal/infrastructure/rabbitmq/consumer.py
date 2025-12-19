"""
RabbitMQ Consumer Implementation

Consumes messages from RabbitMQ and delegates handling to TaskService.
This module lives in the infrastructure layer to keep queue integration
away from the application core.
"""
import asyncio
import json
from typing import Optional, TYPE_CHECKING, Dict, Any
import logging

from aio_pika import connect_robust, IncomingMessage
from aio_pika.abc import AbstractChannel, AbstractQueue, AbstractConnection

from config.settings import settings
from utils.logger import logger

if TYPE_CHECKING:
    from application.task_service import TaskService
    from application.interfaces import IJobRepository


class RabbitMQConsumer:
    """RabbitMQ consumer with robust reconnection support."""

    def __init__(
        self,
        task_service: "TaskService",
        job_repo: Optional["IJobRepository"] = None
    ):
        if task_service is None:
            raise ValueError("RabbitMQConsumer requires a task_service instance")

        self.task_service = task_service
        self.job_repo = job_repo

        self.connection: Optional[AbstractConnection] = None
        self.channel: Optional[AbstractChannel] = None
        self.queue: Optional[AbstractQueue] = None

        self.is_consuming = False
        self.should_stop = False

    async def connect(self):
        """Connect to RabbitMQ and declare queue bindings."""
        try:
            logger.info("=" * 70)
            logger.info("CONNECTING TO RABBITMQ")
            logger.info("Host: %s:%s", settings.rabbitmq_host, settings.rabbitmq_port)
            logger.info("Queue: %s", settings.rabbitmq_queue_name)
            logger.info("Exchange: %s", settings.rabbitmq_exchange)
            logger.info("Routing Key: %s", settings.rabbitmq_routing_key)
            logger.info("=" * 70)

            self.connection = await connect_robust(
                settings.rabbitmq_url,
                loop=asyncio.get_event_loop()
            )
            logger.info("Connection established")

            self.channel = await self.connection.channel()
            logger.info("Channel created")

            await self.channel.set_qos(prefetch_count=settings.rabbitmq_prefetch_count)
            logger.info("  QoS set (prefetch_count=%d)", settings.rabbitmq_prefetch_count)

            exchange = await self.channel.declare_exchange(
                settings.rabbitmq_exchange,
                durable=True
            )
            logger.info("Exchange declared: %s", settings.rabbitmq_exchange)

            self.queue = await self.channel.declare_queue(
                settings.rabbitmq_queue_name,
                durable=True
            )
            logger.info("Queue declared: %s", settings.rabbitmq_queue_name)

            await self.queue.bind(exchange, routing_key=settings.rabbitmq_routing_key)
            logger.info("Queue bound to exchange with routing key: %s", settings.rabbitmq_routing_key)

            logger.info("=" * 70)
            logger.info("RABBITMQ CONNECTION COMPLETE")
            logger.info("=" * 70)

        except Exception as exc:
            logger.error("Failed to connect to RabbitMQ: %s", exc, exc_info=True)
            raise

    async def close(self):
        """Close RabbitMQ connection gracefully."""
        try:
            self.should_stop = True

            if self.channel:
                await self.channel.close()

            if self.connection:
                await self.connection.close()

            logger.info("RabbitMQ connection closed")

        except Exception as exc:
            logger.error("Error closing RabbitMQ connection: %s", exc)

    async def process_message(self, message: IncomingMessage):
        """
        Process an incoming queue message with manual ACK.

        Always ACKs messages (even on failure) to prevent infinite redelivery.
        Failed jobs are marked in the database for separate retry handling.
        """
        should_ack = False
        job_id = None

        try:
            # Decode message
            data = self._decode_message(message)
            task_type = data.get("task_type")
            payload: Dict[str, Any] = data.get("payload", {}) or {}
            job_id = data.get("job_id")

            # Log received message with full details
            logger.info("=" * 70)
            logger.info("RECEIVED MESSAGE FROM QUEUE")
            logger.info("Task Type: %s", task_type)
            logger.info("Job ID: %s", job_id or "will be generated")
            logger.info("Payload: %s", payload)
            logger.info("=" * 70)

            if not task_type:
                logger.error("Message missing task_type: %s", data)
                should_ack = True  # ACK invalid messages to discard them
                return

            # Process the task
            logger.info("Processing task: %s (job_id: %s)", task_type, job_id or "generated")

            result = await self.task_service.handle_task(
                task_type=task_type,
                payload=payload,
                job_id=job_id
            )

            success = result.get("success", False)
            resolved_job_id = result.get("job_id", job_id)
            error_type = result.get("error_type")
            error_msg = result.get("error")

            if success:
                logger.info("=" * 70)
                logger.info("SUCCESS - Job %s completed", resolved_job_id)
                logger.info("=" * 70)
            else:
                logger.error("=" * 70)
                logger.error("FAILED - Job %s", resolved_job_id)
                logger.error("Error Type: %s", error_type or "unknown")
                logger.error("Error Message: %s", error_msg or "No error message")
                logger.error("=" * 70)

                # Log infrastructure errors as CRITICAL, scraping errors as ERROR
                if error_type == "infrastructure":
                    logger.critical(
                        "INFRASTRUCTURE ERROR - Job %s failed: %s",
                        resolved_job_id,
                        error_msg
                    )
                else:
                    logger.error(
                        "SCRAPING ERROR - Job %s failed: %s",
                        resolved_job_id,
                        error_msg
                    )

            # Always ACK after processing (success or failure)
            should_ack = True

        except json.JSONDecodeError as exc:
            logger.error("=" * 70)
            logger.error("JSON DECODE ERROR")
            logger.error("Invalid JSON in message: %s", exc, exc_info=True)
            logger.error("=" * 70)
            # ACK invalid JSON to discard the message
            should_ack = True

        except Exception as exc:
            logger.error("=" * 70)
            logger.error("UNEXPECTED ERROR IN MESSAGE PROCESSING")
            logger.error("Job ID: %s", job_id or "unknown")
            logger.error("Exception: %s", exc, exc_info=True)
            logger.error("=" * 70)
            # ACK to prevent infinite redelivery
            should_ack = True

        finally:
            if should_ack:
                try:
                    await message.ack()
                    logger.debug("Message acknowledged and removed from queue")
                except Exception as ack_exc:
                    logger.error("Failed to ACK message: %s", ack_exc)

    async def start_consuming(self):
        """Start consuming messages from the queue."""
        try:
            if not self.queue:
                raise RuntimeError("Not connected to RabbitMQ. Call connect() first.")

            logger.info("=" * 70)
            logger.info("STARTING MESSAGE CONSUMPTION")
            logger.info("Queue: %s", settings.rabbitmq_queue_name)
            logger.info("=" * 70)

            self.is_consuming = True

            await self.queue.consume(self.process_message)

            logger.info("=" * 70)
            logger.info("CONSUMER ACTIVE - LISTENING FOR MESSAGES")
            logger.info("Queue: %s", settings.rabbitmq_queue_name)
            logger.info("Press Ctrl+C to stop")
            logger.info("=" * 70)

            # Keep the consumer running
            while not self.should_stop:
                await asyncio.sleep(1)

            logger.info("Consumer loop stopped")

        except Exception as exc:
            logger.error("Error in consumer: %s", exc, exc_info=True)
            raise

    async def stop_consuming(self):
        """Signal the consumer loop to stop."""
        logger.info("Stopping consumer...")
        self.should_stop = True
        self.is_consuming = False

    @staticmethod
    def _decode_message(message: IncomingMessage) -> Dict[str, Any]:
        """Decode and parse message body."""
        body = message.body.decode("utf-8")
        return json.loads(body)


class RabbitMQConsumerContext:
    """Async context manager for RabbitMQConsumer lifecycle management."""

    def __init__(
        self,
        task_service: "TaskService",
        job_repo: Optional["IJobRepository"] = None
    ):
        self.consumer = RabbitMQConsumer(task_service=task_service, job_repo=job_repo)

    async def __aenter__(self) -> RabbitMQConsumer:
        await self.consumer.connect()
        return self.consumer

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.consumer.close()
