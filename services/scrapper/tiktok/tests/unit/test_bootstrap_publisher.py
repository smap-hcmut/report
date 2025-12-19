"""
Unit tests for Bootstrap publisher initialization
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from app.bootstrap import Bootstrap


@pytest.mark.asyncio
async def test_init_result_publisher_enabled():
    """Test that result publisher is initialized when enabled in settings"""
    bootstrap = Bootstrap()
    
    # Mock settings
    with patch('app.bootstrap.settings') as mock_settings:
        mock_settings.result_publisher_enabled = True
        mock_settings.rabbitmq_url = "amqp://guest:guest@localhost:5672/"
        mock_settings.result_exchange_name = "collector.tiktok"
        mock_settings.result_routing_key = "tiktok.res"
        
        # Mock RabbitMQPublisher
        with patch('app.bootstrap.RabbitMQPublisher') as mock_publisher_class:
            mock_publisher_instance = AsyncMock()
            mock_publisher_class.return_value = mock_publisher_instance
            
            # Call the initialization method
            await bootstrap._init_result_publisher()
            
            # Verify publisher was created with correct parameters
            mock_publisher_class.assert_called_once_with(
                connection_url="amqp://guest:guest@localhost:5672/",
                exchange_name="collector.tiktok",
                routing_key="tiktok.res"
            )
            
            # Verify connect was called
            mock_publisher_instance.connect.assert_called_once()
            
            # Verify publisher is set
            assert bootstrap.result_publisher == mock_publisher_instance


@pytest.mark.asyncio
async def test_init_result_publisher_disabled():
    """Test that result publisher is not initialized when disabled in settings"""
    bootstrap = Bootstrap()
    
    # Mock settings with publisher disabled
    with patch('app.bootstrap.settings') as mock_settings:
        mock_settings.result_publisher_enabled = False
        
        # Mock RabbitMQPublisher
        with patch('app.bootstrap.RabbitMQPublisher') as mock_publisher_class:
            # Call the initialization method
            await bootstrap._init_result_publisher()
            
            # Verify publisher was not created
            mock_publisher_class.assert_not_called()
            
            # Verify publisher is None
            assert bootstrap.result_publisher is None


@pytest.mark.asyncio
async def test_init_result_publisher_connection_failure():
    """Test that application continues when publisher connection fails"""
    bootstrap = Bootstrap()
    
    # Mock settings
    with patch('app.bootstrap.settings') as mock_settings:
        mock_settings.result_publisher_enabled = True
        mock_settings.rabbitmq_url = "amqp://guest:guest@localhost:5672/"
        mock_settings.result_exchange_name = "collector.tiktok"
        mock_settings.result_routing_key = "tiktok.res"
        
        # Mock RabbitMQPublisher to raise exception on connect
        with patch('app.bootstrap.RabbitMQPublisher') as mock_publisher_class:
            mock_publisher_instance = AsyncMock()
            mock_publisher_instance.connect.side_effect = Exception("Connection failed")
            mock_publisher_class.return_value = mock_publisher_instance
            
            # Call the initialization method - should not raise
            await bootstrap._init_result_publisher()
            
            # Verify publisher is None after failure
            assert bootstrap.result_publisher is None


@pytest.mark.asyncio
async def test_shutdown_closes_publisher():
    """Test that shutdown closes the result publisher"""
    bootstrap = Bootstrap()
    
    # Mock the publisher
    mock_publisher = AsyncMock()
    bootstrap.result_publisher = mock_publisher
    
    # Mock other components to avoid errors
    bootstrap.media_storage = None
    bootstrap.browser = None
    bootstrap.persistent_context = None
    bootstrap.playwright = None
    bootstrap.mongo_repo = None
    
    # Call shutdown
    await bootstrap.shutdown()
    
    # Verify publisher close was called
    mock_publisher.close.assert_called_once()
