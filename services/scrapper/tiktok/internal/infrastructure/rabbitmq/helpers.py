"""
RabbitMQ Infrastructure Helpers
Shared RabbitMQ utilities and helper functions
"""
from aio_pika import connect_robust, Message, ExchangeType
from aio_pika.abc import AbstractConnection, AbstractChannel, AbstractExchange, AbstractQueue
from typing import Optional, Dict, Any, Callable
import logging
import json

logger = logging.getLogger(__name__)


class RabbitMQConnectionManager:
    """
    Manages RabbitMQ connection lifecycle

    This is a shared utility for RabbitMQ connections
    with automatic reconnection support.
    """

    def __init__(
        self,
        connection_url: str,
        exchange_name: str = "",
        exchange_type: ExchangeType = ExchangeType.DIRECT
    ):
        self.connection_url = connection_url
        self.exchange_name = exchange_name
        self.exchange_type = exchange_type

        self.connection: Optional[AbstractConnection] = None
        self.channel: Optional[AbstractChannel] = None
        self.exchange: Optional[AbstractExchange] = None

    async def connect(self):
        """Establish connection to RabbitMQ"""
        try:
            # Create robust connection (auto-reconnect)
            self.connection = await connect_robust(self.connection_url)

            # Create channel
            self.channel = await self.connection.channel()

            # Declare exchange if specified
            if self.exchange_name:
                self.exchange = await self.channel.declare_exchange(
                    self.exchange_name,
                    self.exchange_type,
                    durable=True
                )

            logger.info(f"Connected to RabbitMQ: {self.exchange_name or 'default'}")

        except Exception as e:
            logger.error(f"Failed to connect to RabbitMQ: {e}")
            raise

    async def close(self):
        """Close RabbitMQ connection"""
        if self.channel:
            await self.channel.close()
        if self.connection:
            await self.connection.close()
        logger.info("RabbitMQ connection closed")

    async def declare_queue(
        self,
        queue_name: str,
        durable: bool = True,
        routing_key: Optional[str] = None
    ) -> AbstractQueue:
        """
        Declare a queue and optionally bind it to exchange

        Args:
            queue_name: Name of the queue
            durable: Whether queue survives broker restart
            routing_key: Routing key to bind (if using exchange)

        Returns:
            AbstractQueue instance
        """
        if not self.channel:
            raise RuntimeError("Not connected. Call connect() first.")

        queue = await self.channel.declare_queue(queue_name, durable=durable)

        # Bind to exchange if routing key provided
        if routing_key and self.exchange:
            await queue.bind(self.exchange, routing_key=routing_key)
            logger.info(f"Queue '{queue_name}' bound to exchange with key '{routing_key}'")

        return queue


async def publish_message(
    channel: AbstractChannel,
    exchange: AbstractExchange,
    routing_key: str,
    message_body: Dict[str, Any],
    **kwargs
):
    """
    Helper to publish a JSON message to RabbitMQ

    Args:
        channel: RabbitMQ channel
        exchange: Exchange to publish to
        routing_key: Routing key
        message_body: Message content (will be JSON serialized)
        **kwargs: Additional message properties
    """
    try:
        message = Message(
            body=json.dumps(message_body).encode(),
            content_type='application/json',
            **kwargs
        )

        await exchange.publish(
            message,
            routing_key=routing_key
        )

        logger.debug(f"Published message to {routing_key}")

    except Exception as e:
        logger.error(f"Failed to publish message: {e}")
        raise


async def consume_queue(
    queue: AbstractQueue,
    callback: Callable,
    prefetch_count: int = 1
):
    """
    Helper to start consuming messages from a queue

    Args:
        queue: Queue to consume from
        callback: Async function to handle messages
        prefetch_count: Max concurrent messages
    """
    # Set QoS
    await queue.channel.set_qos(prefetch_count=prefetch_count)

    # Start consuming
    await queue.consume(callback)

    logger.info(f"Started consuming from queue: {queue.name}")
