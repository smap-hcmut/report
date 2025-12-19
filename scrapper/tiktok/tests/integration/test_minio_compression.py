"""
Integration tests for MinIO compression and async upload.

Tests the full integration of:
- MinIO storage with compression
- Async upload with progress tracking
- Auto-decompression on download
- Metadata preservation
"""

import pytest
import asyncio
import json
from pathlib import Path

from minio import Minio

from internal.infrastructure.minio.storage import MinioMediaStorage, MinioStorageConfig
from internal.infrastructure.compression import ZstdCompressor
from internal.infrastructure.minio.upload_task import UploadState


# Skip integration tests by default
pytestmark = pytest.mark.skip(
    reason="Integration tests require MinIO setup and --run-integration flag",
)


@pytest.fixture
async def minio_client():
    """Create MinIO client for testing."""
    client = Minio(
        endpoint="localhost:9000",
        access_key="minioadmin",
        secret_key="minioadmin",
        secure=False,
    )
    return client


@pytest.fixture
async def storage(minio_client):
    """Create MinIO storage instance for testing."""
    config = MinioStorageConfig(
        bucket="test-compression",
        enable_compression=True,
        compression_level=2,
        enable_async_upload=False,
    )

    compressor = ZstdCompressor()
    storage = MinioMediaStorage(
        client=minio_client, config=config, compressor=compressor
    )

    await storage.ensure_bucket()

    yield storage


@pytest.fixture
async def async_storage(minio_client):
    """Create MinIO storage with async upload enabled."""
    config = MinioStorageConfig(
        bucket="test-async-upload",
        enable_compression=True,
        compression_level=2,
        enable_async_upload=True,
        async_upload_workers=2,
    )

    compressor = ZstdCompressor()
    storage = MinioMediaStorage(
        client=minio_client, config=config, compressor=compressor
    )

    await storage.ensure_bucket()
    await storage.start_async_upload()

    yield storage

    await storage.stop_async_upload()


@pytest.fixture
def sample_json_data():
    """Create sample JSON data."""
    data = {
        "users": [
            {
                "id": i,
                "name": f"User {i}",
                "email": f"user{i}@test.com",
                "metadata": {"score": i * 10},
            }
            for i in range(5000)
        ]
    }
    return json.dumps(data).encode("utf-8")


class TestMinIOCompression:
    """Test MinIO storage with compression."""

    @pytest.mark.asyncio
    async def test_upload_compressed_bytes(self, storage, sample_json_data):
        """Test uploading compressed data."""
        object_name = "test-data.json"

        # Upload with compression
        key = await storage.upload_bytes(
            data=sample_json_data,
            object_name=object_name,
            enable_compression=True,
            compression_level=2,
        )

        assert key is not None

        # Get metadata
        metadata = await storage.get_object_metadata(object_name)

        # Should have compression metadata
        assert storage.is_compressed(metadata)
        assert metadata.get("x-amz-meta-compressed") == "true"
        assert metadata.get("x-amz-meta-compression-algorithm") == "zstd"
        assert metadata.get("x-amz-meta-compression-level") == "2"

        # Original size should match
        original_size = int(metadata.get("x-amz-meta-original-size"))
        assert original_size == len(sample_json_data)

        # Compressed size should be smaller
        compressed_size = int(metadata.get("x-amz-meta-compressed-size"))
        assert compressed_size < original_size

    @pytest.mark.asyncio
    async def test_upload_without_compression(self, storage, sample_json_data):
        """Test uploading without compression."""
        object_name = "test-uncompressed.json"

        # Upload without compression
        key = await storage.upload_bytes(
            data=sample_json_data, object_name=object_name, enable_compression=False
        )

        # Get metadata
        metadata = await storage.get_object_metadata(object_name)

        # Should NOT have compression metadata
        assert not storage.is_compressed(metadata)

    @pytest.mark.asyncio
    async def test_download_with_auto_decompression(self, storage, sample_json_data):
        """Test downloading and auto-decompressing data."""
        object_name = "test-auto-decompress.json"

        # Upload compressed
        await storage.upload_bytes(
            data=sample_json_data, object_name=object_name, enable_compression=True
        )

        # Download with auto-decompression
        downloaded = await storage.download_bytes(
            object_name=object_name, auto_decompress=True
        )

        # Should match original
        assert downloaded == sample_json_data

        # Parse as JSON to verify integrity
        parsed = json.loads(downloaded)
        assert len(parsed["users"]) == 5000

    @pytest.mark.asyncio
    async def test_download_without_decompression(self, storage, sample_json_data):
        """Test downloading compressed data without decompression."""
        object_name = "test-no-decompress.json"

        # Upload compressed
        await storage.upload_bytes(
            data=sample_json_data, object_name=object_name, enable_compression=True
        )

        # Download without auto-decompression
        downloaded = await storage.download_bytes(
            object_name=object_name, auto_decompress=False
        )

        # Should be compressed (different from original)
        assert downloaded != sample_json_data
        assert len(downloaded) < len(sample_json_data)

    @pytest.mark.asyncio
    async def test_compression_ratio(self, storage):
        """Test compression achieves expected ratio for JSON."""
        # Create large JSON dataset
        large_data = {
            "transactions": [
                {"id": f"txn-{i}", "amount": i * 100.50, "timestamp": 1700000000 + i}
                for i in range(10000)
            ]
        }

        data = json.dumps(large_data).encode("utf-8")
        object_name = "test-large.json"

        # Upload compressed
        await storage.upload_bytes(
            data=data,
            object_name=object_name,
            enable_compression=True,
            compression_level=2,
        )

        # Get metadata
        metadata = await storage.get_object_metadata(object_name)

        original_size = int(metadata.get("x-amz-meta-original-size"))
        compressed_size = int(metadata.get("x-amz-meta-compressed-size"))

        # Calculate compression ratio
        ratio = compressed_size / original_size

        # Should achieve at least 70% compression for JSON
        assert ratio < 0.3


class TestMinIOAsyncUpload:
    """Test async upload with progress tracking."""

    @pytest.mark.asyncio
    async def test_async_upload_basic(self, async_storage, sample_json_data):
        """Test basic async upload."""
        object_name = "test-async.json"

        # Upload async
        task_id = await async_storage.upload_bytes_async(
            data=sample_json_data, object_name=object_name, enable_compression=True
        )

        assert task_id is not None

        # Wait for completion
        result = await async_storage.wait_for_upload(task_id, timeout=10.0)

        assert result.success is True
        assert result.object_key is not None
        assert result.compression_ratio < 1.0

    @pytest.mark.asyncio
    async def test_async_upload_progress_tracking(
        self, async_storage, sample_json_data
    ):
        """Test tracking upload progress."""
        object_name = "test-progress.json"

        # Upload async
        task_id = await async_storage.upload_bytes_async(
            data=sample_json_data, object_name=object_name, enable_compression=True
        )

        # Poll for progress
        seen_states = set()
        max_polls = 50

        for _ in range(max_polls):
            status = async_storage.get_upload_status(task_id)

            if status:
                seen_states.add(status.status)

                if status.status in (UploadState.COMPLETED, UploadState.FAILED):
                    break

            await asyncio.sleep(0.1)

        # Should have seen multiple states
        assert UploadState.COMPLETED in seen_states

        # Should have seen either COMPRESSING or UPLOADING
        assert (
            UploadState.COMPRESSING in seen_states
            or UploadState.UPLOADING in seen_states
        )

    @pytest.mark.asyncio
    async def test_async_upload_multiple_concurrent(self, async_storage):
        """Test uploading multiple files concurrently."""
        num_files = 5
        task_ids = []

        # Queue multiple uploads
        for i in range(num_files):
            data = json.dumps({"index": i, "data": "x" * 10000}).encode("utf-8")
            task_id = await async_storage.upload_bytes_async(
                data=data,
                object_name=f"test-concurrent-{i}.json",
                enable_compression=True,
            )
            task_ids.append(task_id)

        # Wait for all to complete
        results = []
        for task_id in task_ids:
            result = await async_storage.wait_for_upload(task_id, timeout=15.0)
            results.append(result)

        # All should succeed
        assert all(r.success for r in results)

    @pytest.mark.asyncio
    async def test_async_upload_with_custom_metadata(
        self, async_storage, sample_json_data
    ):
        """Test async upload with custom metadata."""
        object_name = "test-metadata.json"

        custom_metadata = {
            "batch-id": "batch-001",
            "created-by": "test-user",
            "record-count": "5000",
        }

        # Upload async with metadata
        task_id = await async_storage.upload_bytes_async(
            data=sample_json_data,
            object_name=object_name,
            enable_compression=True,
            metadata=custom_metadata,
        )

        # Wait for completion
        result = await async_storage.wait_for_upload(task_id, timeout=10.0)
        assert result.success is True

        # Get metadata and verify custom fields preserved
        metadata = await async_storage.get_object_metadata(object_name)

        assert metadata.get("x-amz-meta-batch-id") == "batch-001"
        assert metadata.get("x-amz-meta-created-by") == "test-user"
        assert metadata.get("x-amz-meta-record-count") == "5000"

    @pytest.mark.asyncio
    async def test_async_upload_timeout(self, async_storage):
        """Test timeout handling for async upload."""
        # Create small data (should complete quickly)
        data = b"test data"

        task_id = await async_storage.upload_bytes_async(
            data=data, object_name="test-timeout.txt", enable_compression=False
        )

        # Very short timeout should work for small data
        result = await async_storage.wait_for_upload(task_id, timeout=5.0)
        assert result.success is True
