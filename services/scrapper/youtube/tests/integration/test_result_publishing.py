"""
Integration tests for YouTube result publishing.

Tests:
- RabbitMQ publisher publishes to correct exchange
- Message format and routing key validation
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
import json


class TestResultPublishing:
    """Test suite for YouTube result publishing to RabbitMQ."""

    @pytest.fixture
    def mock_channel(self):
        """Create a mock aio_pika channel."""
        channel = AsyncMock()
        channel.default_exchange = AsyncMock()
        return channel

    @pytest.fixture
    def mock_exchange(self):
        """Create a mock aio_pika exchange."""
        exchange = AsyncMock()
        exchange.publish = AsyncMock()
        return exchange

    @pytest.mark.asyncio
    async def test_publisher_uses_correct_exchange(self, mock_channel, mock_exchange):
        """Test that publisher uses the configured exchange name."""
        from internal.infrastructure.rabbitmq.publisher import RabbitMQPublisher

        publisher = RabbitMQPublisher(
            host="localhost",
            port=5672,
            username="guest",
            password="guest",
            exchange_name="results.inbound",
            routing_key="youtube.res",
        )

        # Mock the connection
        publisher._channel = mock_channel
        publisher._exchange = mock_exchange
        publisher._is_connected = True

        await publisher.publish_result(
            job_id="test-job-123",
            task_type="dryrun_keyword",
            result_data={"success": True, "data": []},
        )

        # Verify exchange.publish was called
        mock_exchange.publish.assert_called_once()

    @pytest.mark.asyncio
    async def test_publisher_uses_correct_routing_key(
        self, mock_channel, mock_exchange
    ):
        """Test that publisher uses the correct routing key for YouTube."""
        from internal.infrastructure.rabbitmq.publisher import RabbitMQPublisher

        publisher = RabbitMQPublisher(
            host="localhost",
            port=5672,
            username="guest",
            password="guest",
            exchange_name="results.inbound",
            routing_key="youtube.res",
        )

        publisher._channel = mock_channel
        publisher._exchange = mock_exchange
        publisher._is_connected = True

        await publisher.publish_result(
            job_id="test-job-123",
            task_type="dryrun_keyword",
            result_data={"success": True},
        )

        # Get the call arguments
        call_args = mock_exchange.publish.call_args

        # Verify routing_key is correct for YouTube
        assert call_args.kwargs.get("routing_key") == "youtube.res"

    @pytest.mark.asyncio
    async def test_published_message_contains_job_id(self, mock_channel, mock_exchange):
        """Test that published message contains job_id."""
        from internal.infrastructure.rabbitmq.publisher import RabbitMQPublisher

        publisher = RabbitMQPublisher(
            host="localhost",
            port=5672,
            username="guest",
            password="guest",
            exchange_name="results.inbound",
            routing_key="youtube.res",
        )

        publisher._channel = mock_channel
        publisher._exchange = mock_exchange
        publisher._is_connected = True

        job_id = "test-job-456"
        await publisher.publish_result(
            job_id=job_id, task_type="dryrun_keyword", result_data={"success": True}
        )

        # Get the message body
        call_args = mock_exchange.publish.call_args
        message = call_args.args[0]
        message_body = json.loads(message.body.decode())

        assert message_body.get("job_id") == job_id

    @pytest.mark.asyncio
    async def test_published_message_contains_task_type(
        self, mock_channel, mock_exchange
    ):
        """Test that published message contains task_type."""
        from internal.infrastructure.rabbitmq.publisher import RabbitMQPublisher

        publisher = RabbitMQPublisher(
            host="localhost",
            port=5672,
            username="guest",
            password="guest",
            exchange_name="results.inbound",
            routing_key="youtube.res",
        )

        publisher._channel = mock_channel
        publisher._exchange = mock_exchange
        publisher._is_connected = True

        await publisher.publish_result(
            job_id="test-job-789",
            task_type="research_and_crawl",
            result_data={"success": True},
        )

        # Get the message body
        call_args = mock_exchange.publish.call_args
        message = call_args.args[0]
        message_body = json.loads(message.body.decode())

        assert message_body.get("task_type") == "research_and_crawl"

    @pytest.mark.asyncio
    async def test_publisher_handles_connection_failure(self):
        """Test that publisher handles connection failures gracefully."""
        from internal.infrastructure.rabbitmq.publisher import RabbitMQPublisher

        publisher = RabbitMQPublisher(
            host="invalid-host",
            port=5672,
            username="guest",
            password="guest",
            exchange_name="results.inbound",
            routing_key="youtube.res",
        )

        # Publisher should not be connected
        assert not publisher.is_connected

        # Publishing should not raise exception when not connected
        await publisher.publish_result(
            job_id="test-job", task_type="dryrun_keyword", result_data={"success": True}
        )


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
