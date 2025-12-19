"""
Unit tests for compression service.

Tests the Zstd compression implementation including:
- Basic compression/decompression
- Compression levels
- Stream processing
- Error handling
"""

import pytest
import io
import json

from internal.infrastructure.compression import (
    ZstdCompressor,
    CompressionInfo
)


class TestZstdCompressor:
    """Test suite for ZstdCompressor."""

    @pytest.fixture
    def compressor(self):
        """Create compressor instance."""
        return ZstdCompressor()

    @pytest.fixture
    def sample_data(self):
        """Create sample JSON data."""
        data = {
            "users": [
                {"id": i, "name": f"User {i}", "email": f"user{i}@example.com"}
                for i in range(1000)
            ]
        }
        return json.dumps(data).encode('utf-8')

    def test_compress_and_decompress(self, compressor, sample_data):
        """Test basic compression and decompression."""
        # Compress
        compressed = compressor.compress(sample_data, level=2)

        # Should be smaller
        assert len(compressed) < len(sample_data)

        # Decompress
        decompressed = compressor.decompress(compressed)

        # Should match original
        assert decompressed == sample_data

    def test_compression_level_0_no_compression(self, compressor, sample_data):
        """Test that level 0 returns data unchanged."""
        compressed = compressor.compress(sample_data, level=0)
        assert compressed == sample_data

    def test_compression_levels(self, compressor, sample_data):
        """Test different compression levels."""
        results = {}

        for level in [1, 2, 3]:
            compressed = compressor.compress(sample_data, level=level)
            results[level] = len(compressed)

            # Should be able to decompress
            decompressed = compressor.decompress(compressed)
            assert decompressed == sample_data

        # Higher levels should generally produce smaller output
        # (though not guaranteed for all data)
        assert results[3] <= results[1]

    def test_compression_ratio_calculation(self, compressor, sample_data):
        """Test compression ratio calculation."""
        compressed = compressor.compress(sample_data, level=2)

        info = compressor.get_compression_info(
            original_size=len(sample_data),
            compressed_size=len(compressed),
            level=2
        )

        assert info.original_size == len(sample_data)
        assert info.compressed_size == len(compressed)
        assert 0.0 < info.compression_ratio < 1.0
        assert info.algorithm == "zstd"
        assert info.level == 2

        # Savings should be positive
        savings = info.get_savings_percentage()
        assert savings > 0
        assert savings < 100

    def test_compress_empty_data(self, compressor):
        """Test compressing empty data."""
        empty = b""
        compressed = compressor.compress(empty, level=2)

        # Should handle gracefully
        decompressed = compressor.decompress(compressed)
        assert decompressed == empty

    def test_compress_small_data(self, compressor):
        """Test compressing very small data."""
        small = b"hello"
        compressed = compressor.compress(small, level=2)

        # Might be larger due to overhead
        decompressed = compressor.decompress(compressed)
        assert decompressed == small

    def test_compress_large_json(self, compressor):
        """Test compressing large JSON structure."""
        # Create large JSON dataset
        large_data = {
            "transactions": [
                {
                    "id": f"txn-{i}",
                    "amount": i * 100.50,
                    "user_id": f"user-{i % 1000}",
                    "timestamp": 1700000000 + i,
                    "metadata": {
                        "ip": "192.168.1.1",
                        "user_agent": "Mozilla/5.0...",
                        "session_id": f"session-{i}"
                    }
                }
                for i in range(10000)
            ]
        }

        data = json.dumps(large_data).encode('utf-8')
        compressed = compressor.compress(data, level=2)

        # Should achieve good compression for JSON
        ratio = len(compressed) / len(data)
        assert ratio < 0.3  # At least 70% compression

        # Verify decompression
        decompressed = compressor.decompress(compressed)
        assert decompressed == data

    def test_compress_stream(self, compressor, sample_data):
        """Test stream compression."""
        source = io.BytesIO(sample_data)
        destination = io.BytesIO()

        info = compressor.compress_stream(source, destination, level=2)

        # Check compression info
        assert info.original_size == len(sample_data)
        assert info.compressed_size > 0
        assert info.compressed_size < len(sample_data)

        # Verify compressed data
        destination.seek(0)
        compressed_data = destination.read()

        # Decompress and verify
        decompressed = compressor.decompress(compressed_data)
        assert decompressed == sample_data

    def test_decompress_stream(self, compressor, sample_data):
        """Test stream decompression."""
        # First compress
        compressed = compressor.compress(sample_data, level=2)

        # Stream decompress
        source = io.BytesIO(compressed)
        destination = io.BytesIO()

        bytes_decompressed = compressor.decompress_stream(source, destination)

        assert bytes_decompressed == len(sample_data)

        # Verify decompressed data
        destination.seek(0)
        decompressed_data = destination.read()
        assert decompressed_data == sample_data

    def test_invalid_compression_level(self, compressor, sample_data):
        """Test invalid compression level."""
        with pytest.raises(ValueError):
            compressor.compress(sample_data, level=99)

    def test_invalid_compressed_data(self, compressor):
        """Test decompressing invalid data."""
        invalid_data = b"this is not compressed data"

        with pytest.raises(Exception):  # zstd.ZstdError
            compressor.decompress(invalid_data)

    def test_algorithm_name(self, compressor):
        """Test getting algorithm name."""
        assert compressor.get_algorithm_name() == "zstd"

    def test_is_available(self):
        """Test checking if zstandard is available."""
        assert ZstdCompressor.is_available() is True

    def test_get_version(self):
        """Test getting zstandard version."""
        version = ZstdCompressor.get_version()
        assert version is not None
        assert len(version) > 0


class TestCompressionInfo:
    """Test suite for CompressionInfo."""

    def test_calculate_ratio(self):
        """Test compression ratio calculation."""
        ratio = CompressionInfo.calculate_ratio(1000, 100)
        assert ratio == 0.1

        ratio = CompressionInfo.calculate_ratio(1000, 500)
        assert ratio == 0.5

        # Edge case: zero size
        ratio = CompressionInfo.calculate_ratio(0, 0)
        assert ratio == 0.0

    def test_get_savings_percentage(self):
        """Test savings percentage calculation."""
        info = CompressionInfo(
            original_size=1000,
            compressed_size=100,
            compression_ratio=0.1,
            algorithm="zstd",
            level=2
        )

        savings = info.get_savings_percentage()
        assert savings == 90.0

    def test_compression_info_creation(self):
        """Test creating CompressionInfo."""
        info = CompressionInfo(
            original_size=10000,
            compressed_size=500,
            compression_ratio=0.05,
            algorithm="zstd",
            level=3
        )

        assert info.original_size == 10000
        assert info.compressed_size == 500
        assert info.compression_ratio == 0.05
        assert info.algorithm == "zstd"
        assert info.level == 3
        assert info.get_savings_percentage() == 95.0
