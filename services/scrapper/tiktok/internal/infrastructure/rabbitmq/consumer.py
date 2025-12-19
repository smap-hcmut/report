"""
RabbitMQ Consumer Implementation

Consumes messages from RabbitMQ and delegates handling to TaskService.
This module lives in the infrastructure layer to keep queue integration
away from the application core.
"""
import asyncio
import json
from typing import Optional, TYPE_CHECKING, Dict, Any

from aio_pika import connect_robust, IncomingMessage
from aio_pika.abc import AbstractChannel, AbstractQueue, AbstractConnection

from config import settings
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
            logger.info(
                "Connecting to RabbitMQ: %s:%s",
                settings.rabbitmq_host,
                settings.rabbitmq_port,
            )

            self.connection = await connect_robust(
                settings.rabbitmq_url,
                loop=asyncio.get_event_loop()
            )
            self.channel = await self.connection.channel()
            await self.channel.set_qos(prefetch_count=settings.rabbitmq_prefetch_count)

            exchange = await self.channel.declare_exchange(
                settings.rabbitmq_exchange,
                durable=True
            )

            self.queue = await self.channel.declare_queue(
                settings.rabbitmq_queue_name,
                durable=True
            )
            await self.queue.bind(exchange, routing_key=settings.rabbitmq_routing_key)

            logger.info("Connected to RabbitMQ - Queue: %s", settings.rabbitmq_queue_name)

        except Exception as exc:
            logger.error("Failed to connect to RabbitMQ: %s", exc)
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
        Process an incoming queue message with manual ACK control.

        ACK Strategy:
        - Always ACK messages after processing (success or failure)
        - Failed jobs are marked in the database
        - A separate retry service handles reprocessing failed jobs
        - This prevents infinite redelivery loops in RabbitMQ
        - Crash safety: Unacked messages (due to crash) will be redelivered
        """
        should_ack = False

        try:
            data = self._decode_message(message)
            task_type = data.get("task_type")
            payload: Dict[str, Any] = data.get("payload", {}) or {}
            job_id = data.get("job_id")

            if not task_type:
                logger.error("Message missing task_type: %s", data)
                should_ack = True
                return

            logger.info(
                "Received message: %s (job_id: %s)",
                task_type,
                job_id or "generated",
            )

            result = await self.task_service.handle_task(
                task_type=task_type,
                payload=payload,
                job_id=job_id
            )

            success = result.get("success", False)
            error_type = result.get("error_type")
            resolved_job_id = result.get("job_id", job_id)

            if success:
                logger.info("Job %s completed successfully", resolved_job_id)
            else:
                # Log failure - another service will handle retry from DB
                error_msg = result.get("error", "Unknown error")
                if error_type == "infrastructure":
                    logger.critical(
                        "INFRASTRUCTURE ERROR - Job %s failed: %s - Marked as failed in DB for retry service",
                        resolved_job_id,
                        error_msg
                    )
                else:
                    logger.error(
                        "SCRAPING ERROR - Job %s failed: %s - Marked as failed in DB for retry service",
                        resolved_job_id,
                        error_msg
                    )

            # Always ACK after processing (success or failure)
            should_ack = True

        except json.JSONDecodeError as exc:
            logger.error("Invalid JSON in message: %s - Message will be acknowledged", exc)
            should_ack = True
        except Exception as exc:
            # Unexpected error - ACK to prevent infinite redelivery
            # Crash before ACK will cause redelivery (crash safety)
            logger.error(
                "Unexpected error processing message: %s - Message will be acknowledged",
                exc,
                exc_info=True
            )
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

            logger.info("Starting to consume messages...")
            self.is_consuming = True

            await self.queue.consume(self.process_message)
            logger.info(
                "Consumer started - waiting for messages on queue '%s'",
                settings.rabbitmq_queue_name
            )

            while not self.should_stop:
                await asyncio.sleep(1)

        except Exception as exc:
            logger.error("Error in consumer: %s", exc)
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
