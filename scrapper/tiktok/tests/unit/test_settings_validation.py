"""
Unit tests for Settings validation
Tests that the settings properly validate STT polling configuration
"""

import pytest
from unittest.mock import patch
from config.settings import Settings


class TestSettingsValidation:
    """Test Settings validation for STT polling configuration"""

    def test_default_stt_polling_values(self):
        """Test that default STT polling values are set correctly"""
        settings = Settings()
        
        assert settings.stt_polling_max_retries == 60
        assert settings.stt_polling_wait_interval == 3

    @patch.dict('os.environ', {'STT_POLLING_MAX_RETRIES': '120', 'STT_POLLING_WAIT_INTERVAL': '5'})
    def test_custom_stt_polling_values_from_env(self):
        """Test that custom STT polling values can be set from environment"""
        settings = Settings()
        
        assert settings.stt_polling_max_retries == 120
        assert settings.stt_polling_wait_interval == 5

    @patch.dict('os.environ', {'STT_POLLING_MAX_RETRIES': '0'})
    def test_invalid_max_retries_uses_default(self):
        """Test that invalid max_retries (0 or negative) uses default value"""
        settings = Settings()
        
        # Should use default value of 60
        assert settings.stt_polling_max_retries == 60

    @patch.dict('os.environ', {'STT_POLLING_MAX_RETRIES': '-10'})
    def test_negative_max_retries_uses_default(self):
        """Test that negative max_retries uses default value"""
        settings = Settings()
        
        # Should use default value of 60
        assert settings.stt_polling_max_retries == 60

    @patch.dict('os.environ', {'STT_POLLING_WAIT_INTERVAL': '0'})
    def test_invalid_wait_interval_uses_default(self):
        """Test that invalid wait_interval (0 or negative) uses default value"""
        settings = Settings()
        
        # Should use default value of 3
        assert settings.stt_polling_wait_interval == 3

    @patch.dict('os.environ', {'STT_POLLING_WAIT_INTERVAL': '-5'})
    def test_negative_wait_interval_uses_default(self):
        """Test that negative wait_interval uses default value"""
        settings = Settings()
        
        # Should use default value of 3
        assert settings.stt_polling_wait_interval == 3

    def test_total_wait_time_calculation(self):
        """Test that total wait time can be calculated from settings"""
        settings = Settings()
        
        total_wait_time = settings.stt_polling_max_retries * settings.stt_polling_wait_interval
        
        # Default: 60 * 3 = 180 seconds (3 minutes)
        assert total_wait_time == 180

    @patch.dict('os.environ', {'STT_POLLING_MAX_RETRIES': '30', 'STT_POLLING_WAIT_INTERVAL': '2'})
    def test_custom_total_wait_time_calculation(self):
        """Test total wait time calculation with custom values"""
        settings = Settings()
        
        total_wait_time = settings.stt_polling_max_retries * settings.stt_polling_wait_interval
        
        # Custom: 30 * 2 = 60 seconds (1 minute)
        assert total_wait_time == 60
