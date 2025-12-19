"""
Unit tests for Speech2TextRestClient constructor
Tests that the constructor properly initializes with configuration parameters
"""

import pytest
from internal.infrastructure.rest_client import Speech2TextRestClient


class TestSpeech2TextRestClientConstructor:
    """Test Speech2TextRestClient constructor initialization"""

    def test_constructor_with_defaults(self):
        """Test constructor with default parameters"""
        client = Speech2TextRestClient(
            base_url="http://test-stt:8000",
            api_key="test-key"
        )
        
        assert client.base_url == "http://test-stt:8000"
        assert client.api_key == "test-key"
        assert client.timeout == 300  # Default timeout
        assert client.max_retries == 60  # Default max_retries
        assert client.wait_interval == 3  # Default wait_interval
        assert client.client is not None  # httpx.AsyncClient should be initialized

    def test_constructor_with_custom_parameters(self):
        """Test constructor with custom parameters"""
        client = Speech2TextRestClient(
            base_url="http://custom-stt:9000",
            api_key="custom-key",
            timeout=120,
            max_retries=30,
            wait_interval=5
        )
        
        assert client.base_url == "http://custom-stt:9000"
        assert client.api_key == "custom-key"
        assert client.timeout == 120
        assert client.max_retries == 30
        assert client.wait_interval == 5
        assert client.client is not None

    def test_constructor_strips_trailing_slash(self):
        """Test that constructor strips trailing slash from base_url"""
        client = Speech2TextRestClient(
            base_url="http://test-stt:8000/",
            api_key="test-key"
        )
        
        assert client.base_url == "http://test-stt:8000"

    def test_constructor_stores_all_config_values(self):
        """Test that all configuration values are stored as instance variables"""
        client = Speech2TextRestClient(
            base_url="http://test:8000",
            api_key="key123",
            timeout=90,
            max_retries=45,
            wait_interval=2
        )
        
        # Verify all instance variables are set
        assert hasattr(client, 'base_url')
        assert hasattr(client, 'api_key')
        assert hasattr(client, 'timeout')
        assert hasattr(client, 'max_retries')
        assert hasattr(client, 'wait_interval')
        assert hasattr(client, 'client')
        
        # Verify values
        assert client.base_url == "http://test:8000"
        assert client.api_key == "key123"
        assert client.timeout == 90
        assert client.max_retries == 45
        assert client.wait_interval == 2

    def test_httpx_client_initialization(self):
        """Test that httpx.AsyncClient is initialized with timeout configuration"""
        client = Speech2TextRestClient(
            base_url="http://test:8000",
            api_key="test-key",
            timeout=150
        )
        
        # Verify client is initialized
        assert client.client is not None
        
        # Verify timeout is set on the client
        # httpx.AsyncClient stores timeout as httpx.Timeout object
        assert client.client.timeout.read == 150
        assert client.client.timeout.write == 150
        assert client.client.timeout.connect == 150
        assert client.client.timeout.pool == 150
