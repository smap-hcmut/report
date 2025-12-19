"""
Integration tests for TikTok result publishing.

Tests:
- RabbitMQ publisher publishes to correct exchange
- Message format and routing key validation
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
import json


class TestResultPublishing:
    """Test suite for TikTok result publishing to RabbitMQ."""

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
            routing_key="tiktok.res",
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
        """Test that publisher uses the correct routing key for TikTok."""
        from internal.infrastructure.rabbitmq.publisher import RabbitMQPublisher

        publisher = RabbitMQPublisher(
            host="localhost",
            port=5672,
            username="guest",
            password="guest",
            exchange_name="results.inbound",
            routing_key="tiktok.res",
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

        # Verify routing_key is correct
        assert call_args.kwargs.get("routing_key") == "tiktok.res"

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
            routing_key="tiktok.res",
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
            routing_key="tiktok.res",
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
            routing_key="tiktok.res",
        )

        # Publisher should not be connected
        assert not publisher.is_connected

        # Publishing should not raise exception when not connected
        # (it should log warning and return)
        await publisher.publish_result(
            job_id="test-job", task_type="dryrun_keyword", result_data={"success": True}
        )


class TestResearchAndCrawlMessageFormat:
    """Test suite for research_and_crawl message format validation."""

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
    async def test_research_and_crawl_message_has_all_required_fields(
        self, mock_channel, mock_exchange
    ):
        """Test that research_and_crawl message contains all required fields per contract."""
        from internal.infrastructure.rabbitmq.publisher import RabbitMQPublisher

        publisher = RabbitMQPublisher(
            host="localhost",
            port=5672,
            username="guest",
            password="guest",
            exchange_name="results.inbound",
            routing_key="tiktok.res",
        )

        publisher._channel = mock_channel
        publisher._exchange = mock_exchange
        publisher._is_connected = True

        # Flat message format per CrawlerResultMessage contract
        result_data = {
            "success": True,
            "task_type": "research_and_crawl",
            "job_id": "proj123-brand-0",
            "platform": "tiktok",
            "requested_limit": 50,
            "applied_limit": 50,
            "total_found": 30,
            "platform_limited": True,
            "successful": 28,
            "failed": 2,
            "skipped": 0,
            "error_code": None,
            "error_message": None,
        }

        await publisher.publish_result(
            job_id="proj123-brand-0",
            task_type="research_and_crawl",
            result_data=result_data,
        )

        # Get the message body
        call_args = mock_exchange.publish.call_args
        message = call_args.args[0]
        message_body = json.loads(message.body.decode())

        # Verify all required fields are present
        required_fields = [
            "success",
            "task_type",
            "job_id",
            "platform",
            "requested_limit",
            "applied_limit",
            "total_found",
            "platform_limited",
            "successful",
            "failed",
            "skipped",
        ]

        for field in required_fields:
            assert field in message_body, f"Missing required field: {field}"

    @pytest.mark.asyncio
    async def test_research_and_crawl_message_is_flat_structure(
        self, mock_channel, mock_exchange
    ):
        """Test that research_and_crawl message has flat structure (no nested payload)."""
        from internal.infrastructure.rabbitmq.publisher import RabbitMQPublisher

        publisher = RabbitMQPublisher(
            host="localhost",
            port=5672,
            username="guest",
            password="guest",
            exchange_name="results.inbound",
            routing_key="tiktok.res",
        )

        publisher._channel = mock_channel
        publisher._exchange = mock_exchange
        publisher._is_connected = True

        result_data = {
            "success": True,
            "task_type": "research_and_crawl",
            "job_id": "proj123-brand-0",
            "platform": "tiktok",
            "requested_limit": 50,
            "applied_limit": 50,
            "total_found": 30,
            "platform_limited": True,
            "successful": 28,
            "failed": 2,
            "skipped": 0,
            "error_code": None,
            "error_message": None,
        }

        await publisher.publish_result(
            job_id="proj123-brand-0",
            task_type="research_and_crawl",
            result_data=result_data,
        )

        call_args = mock_exchange.publish.call_args
        message = call_args.args[0]
        message_body = json.loads(message.body.decode())

        # Verify no nested payload field (flat structure)
        assert (
            "payload" not in message_body
        ), "research_and_crawl should not have payload field"

        # Verify stats are at root level, not nested
        assert "successful" in message_body
        assert "failed" in message_body
        assert "skipped" in message_body

    @pytest.mark.asyncio
    async def test_research_and_crawl_uses_correct_routing_key(
        self, mock_channel, mock_exchange
    ):
        """Test that research_and_crawl uses correct routing key."""
        from internal.infrastructure.rabbitmq.publisher import RabbitMQPublisher

        publisher = RabbitMQPublisher(
            host="localhost",
            port=5672,
            username="guest",
            password="guest",
            exchange_name="results.inbound",
            routing_key="tiktok.res",
        )

        publisher._channel = mock_channel
        publisher._exchange = mock_exchange
        publisher._is_connected = True

        result_data = {
            "success": True,
            "task_type": "research_and_crawl",
            "job_id": "proj123-brand-0",
            "platform": "tiktok",
            "requested_limit": 50,
            "applied_limit": 50,
            "total_found": 30,
            "platform_limited": True,
            "successful": 28,
            "failed": 2,
            "skipped": 0,
            "error_code": None,
            "error_message": None,
        }

        await publisher.publish_result(
            job_id="proj123-brand-0",
            task_type="research_and_crawl",
            result_data=result_data,
        )

        call_args = mock_exchange.publish.call_args
        assert call_args.kwargs.get("routing_key") == "tiktok.res"

    @pytest.mark.asyncio
    async def test_research_and_crawl_error_message_format(
        self, mock_channel, mock_exchange
    ):
        """Test that error messages have correct format."""
        from internal.infrastructure.rabbitmq.publisher import RabbitMQPublisher

        publisher = RabbitMQPublisher(
            host="localhost",
            port=5672,
            username="guest",
            password="guest",
            exchange_name="results.inbound",
            routing_key="tiktok.res",
        )

        publisher._channel = mock_channel
        publisher._exchange = mock_exchange
        publisher._is_connected = True

        result_data = {
            "success": False,
            "task_type": "research_and_crawl",
            "job_id": "proj123-brand-0",
            "platform": "tiktok",
            "requested_limit": 50,
            "applied_limit": 50,
            "total_found": 0,
            "platform_limited": False,
            "successful": 0,
            "failed": 0,
            "skipped": 0,
            "error_code": "RATE_LIMITED",
            "error_message": "TikTok API rate limited",
        }

        await publisher.publish_result(
            job_id="proj123-brand-0",
            task_type="research_and_crawl",
            result_data=result_data,
        )

        call_args = mock_exchange.publish.call_args
        message = call_args.args[0]
        message_body = json.loads(message.body.decode())

        # Verify error fields
        assert message_body["success"] is False
        assert message_body["error_code"] == "RATE_LIMITED"
        assert message_body["error_message"] == "TikTok API rate limited"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
