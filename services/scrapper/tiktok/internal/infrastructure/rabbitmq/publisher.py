"""
RabbitMQ Publisher Implementation

Publishes result messages to RabbitMQ collector exchange.
This module lives in the infrastructure layer to keep queue integration
away from the application core.
"""
import asyncio
import json
from typing import Optional, Dict, Any
from datetime import datetime

from aio_pika import connect_robust, Message, ExchangeType
from aio_pika.abc import AbstractChannel, AbstractExchange, AbstractConnection

from utils.logger import logger


class RabbitMQPublisher:
    """RabbitMQ publisher for result messages with robust reconnection support."""

    def __init__(
        self,
        connection_url: str,
        exchange_name: str,
        routing_key: str
    ):
        """
        Initialize publisher with connection details.
        
        Args:
            connection_url: RabbitMQ connection URL (amqp://...)
            exchange_name: Exchange to publish to (e.g., collector.tiktok)
            routing_key: Routing key for messages (e.g., tiktok.res)
        """
        if not connection_url:
            raise ValueError("connection_url is required")
        if not exchange_name:
            raise ValueError("exchange_name is required")
        if not routing_key:
            raise ValueError("routing_key is required")

        self.connection_url = connection_url
        self.exchange_name = exchange_name
        self.routing_key = routing_key

        self.connection: Optional[AbstractConnection] = None
        self.channel: Optional[AbstractChannel] = None
        self.exchange: Optional[AbstractExchange] = None

        self._is_connected = False

    async def connect(self):
        """
        Establish connection to RabbitMQ and declare exchange.
        
        Uses connect_robust for automatic reconnection on connection loss.
        """
        try:
            logger.info(
                "Connecting to RabbitMQ publisher - Exchange: %s",
                self.exchange_name
            )

            # Create robust connection (auto-reconnect)
            self.connection = await connect_robust(
                self.connection_url,
                loop=asyncio.get_event_loop()
            )

            # Create channel
            self.channel = await self.connection.channel()

            # Declare exchange (idempotent - safe to call multiple times)
            self.exchange = await self.channel.declare_exchange(
                self.exchange_name,
                ExchangeType.DIRECT,
                durable=True
            )

            self._is_connected = True
            logger.info(
                "Connected to RabbitMQ publisher - Exchange: %s, Routing Key: %s",
                self.exchange_name,
                self.routing_key
            )

        except Exception as exc:
            logger.error("Failed to connect RabbitMQ publisher: %s", exc)
            self._is_connected = False
            raise

    async def close(self):
        """Close RabbitMQ connection gracefully."""
        try:
            if self.channel:
                await self.channel.close()
                logger.debug("Publisher channel closed")

            if self.connection:
                await self.connection.close()
                logger.debug("Publisher connection closed")

            self._is_connected = False
            logger.info("RabbitMQ publisher connection closed")

        except Exception as exc:
            logger.error("Error closing RabbitMQ publisher connection: %s", exc)

    async def publish_result(
        self,
        job_id: str,
        task_type: str,
        result_data: Dict[str, Any]
    ):
        """
        Publish result message to collector exchange.
        
        Args:
            job_id: Unique job identifier (used for logging only)
            task_type: Type of task (used for logging only)
            result_data: Result data dictionary containing:
                - success: bool
                - payload: list
        
        Raises:
            RuntimeError: If not connected to RabbitMQ
            Exception: If message publication fails
        """
        if not self._is_connected or not self.exchange:
            raise RuntimeError(
                "Not connected to RabbitMQ. Call connect() first."
            )

        try:
            # Use result_data directly as message body (simplified format)
            message_body = result_data

            # Serialize to JSON with UTF-8 encoding
            json_body = json.dumps(message_body, ensure_ascii=False)
            encoded_body = json_body.encode("utf-8")

            # Create message with proper content type
            message = Message(
                body=encoded_body,
                content_type="application/json",
                content_encoding="utf-8",
                delivery_mode=2  # Persistent message
            )

            # Publish to exchange
            await self.exchange.publish(
                message,
                routing_key=self.routing_key
            )

            logger.info(
                "Published result message - Job: %s, Type: %s, Success: %s, Payload items: %d",
                job_id,
                task_type,
                result_data.get("success", "unknown"),
                len(result_data.get("payload", []))
            )
            logger.debug("Result message body: %s", message_body)

        except json.JSONEncodeError as exc:
            logger.error(
                "Failed to serialize result message to JSON: %s - Data: %s",
                exc,
                result_data
            )
            raise
        except Exception as exc:
            logger.error(
                "Failed to publish result message for job %s: %s",
                job_id,
                exc
            )
            raise

    @property
    def is_connected(self) -> bool:
        """Check if publisher is connected to RabbitMQ."""
        return self._is_connected


class RabbitMQPublisherContext:
    """Async context manager for RabbitMQPublisher lifecycle management."""

    def __init__(
        self,
        connection_url: str,
        exchange_name: str,
        routing_key: str
    ):
        self.publisher = RabbitMQPublisher(
            connection_url=connection_url,
            exchange_name=exchange_name,
            routing_key=routing_key
        )

    async def __aenter__(self) -> RabbitMQPublisher:
        await self.publisher.connect()
        return self.publisher

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.publisher.close()
