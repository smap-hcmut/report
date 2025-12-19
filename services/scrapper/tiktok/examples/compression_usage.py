"""
Example usage of MinIO compression and async upload features.

This script demonstrates:
1. Uploading compressed JSON data
2. Async upload with progress tracking
3. Downloading and auto-decompressing data
4. Working with metadata
"""

import asyncio
import json
import sys
from datetime import datetime
from typing import List, Dict, Any

# Add project root to path
from pathlib import Path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from minio import Minio
from internal.infrastructure.minio.storage import (
    MinioMediaStorage,
    MinioStorageConfig
)
from internal.infrastructure.compression import ZstdCompressor


# ============================================================
# Example 1: Basic Compressed Upload and Download
# ============================================================

async def example_1_basic_compression():
    """Upload and download JSON data with compression."""
    print("=" * 70)
    print("EXAMPLE 1: Basic Compression")
    print("=" * 70)

    # Setup MinIO client
    client = Minio(
        "localhost:9000",
        access_key="minioadmin",
        secret_key="minioadmin",
        secure=False
    )

    # Create storage with compression enabled
    config = MinioStorageConfig(
        bucket="example-compression",
        enable_compression=True,
        compression_level=2
    )

    compressor = ZstdCompressor()
    storage = MinioMediaStorage(client, config, compressor)

    # Create sample JSON data
    data = {
        "users": [
            {"id": i, "name": f"User {i}", "email": f"user{i}@example.com"}
            for i in range(1000)
        ]
    }

    json_bytes = json.dumps(data).encode('utf-8')
    print(f"\n📦 Original size: {len(json_bytes) / 1024:.2f} KB")

    # Upload with compression
    print("⬆️  Uploading with compression...")
    object_key = await storage.upload_bytes(
        data=json_bytes,
        object_name="users.json",
        content_type="application/json",
        enable_compression=True
    )

    print(f"✅ Uploaded to: {storage.object_uri(object_key)}")

    # Get metadata
    metadata = await storage.get_object_metadata("users.json")

    if storage.is_compressed(metadata):
        original_size = int(metadata["x-amz-meta-original-size"])
        compressed_size = int(metadata["x-amz-meta-compressed-size"])
        savings = (1 - compressed_size / original_size) * 100

        print(f"\n📊 Compression stats:")
        print(f"   Original: {original_size / 1024:.2f} KB")
        print(f"   Compressed: {compressed_size / 1024:.2f} KB")
        print(f"   Savings: {savings:.1f}%")

    # Download with auto-decompression
    print("\n⬇️  Downloading with auto-decompression...")
    downloaded = await storage.download_bytes(
        object_name="users.json",
        auto_decompress=True
    )

    print(f"✅ Downloaded: {len(downloaded) / 1024:.2f} KB (decompressed)")

    # Verify data integrity
    parsed = json.loads(downloaded)
    assert len(parsed["users"]) == 1000
    print("✅ Data integrity verified!")


# ============================================================
# Example 2: Async Upload with Progress Tracking
# ============================================================

async def example_2_async_upload():
    """Async upload with real-time progress tracking."""
    print("\n" + "=" * 70)
    print("EXAMPLE 2: Async Upload with Progress")
    print("=" * 70)

    # Setup with async upload enabled
    client = Minio(
        "localhost:9000",
        access_key="minioadmin",
        secret_key="minioadmin",
        secure=False
    )

    config = MinioStorageConfig(
        bucket="example-async",
        enable_compression=True,
        compression_level=2,
        enable_async_upload=True,
        async_upload_workers=2
    )

    compressor = ZstdCompressor()
    storage = MinioMediaStorage(client, config, compressor)

    # Start async upload manager
    await storage.start_async_upload()

    try:
        # Create larger dataset
        data = {
            "transactions": [
                {
                    "id": f"txn-{i}",
                    "amount": i * 100.50,
                    "timestamp": 1700000000 + i
                }
                for i in range(50000)
            ]
        }

        json_bytes = json.dumps(data).encode('utf-8')
        print(f"\n📦 Data size: {len(json_bytes) / 1024 / 1024:.2f} MB")

        # Queue async upload
        print("⬆️  Queuing async upload...")
        task_id = await storage.upload_bytes_async(
            data=json_bytes,
            object_name="transactions.json",
            content_type="application/json",
            metadata={
                "batch-id": "batch-001",
                "record-count": "50000"
            }
        )

        print(f"✅ Upload queued: {task_id}")

        # Track progress
        print("\n📊 Upload progress:")
        while True:
            status = storage.get_upload_status(task_id)

            if not status:
                break

            # Progress bar
            bar_length = 50
            filled = int(bar_length * status.percentage / 100)
            bar = '█' * filled + '-' * (bar_length - filled)

            sys.stdout.write(
                f"\r   [{bar}] {status.percentage:.1f}% - {status.status.value}"
            )
            sys.stdout.flush()

            if status.is_terminal():
                print()  # New line
                break

            await asyncio.sleep(0.1)

        # Get final result
        result = await storage.wait_for_upload(task_id, timeout=1.0)

        if result.success:
            print(f"\n✅ Upload completed in {result.duration:.2f}s")
            print(f"📊 Compression: {result.original_size / 1024 / 1024:.2f} MB → "
                  f"{result.compressed_size / 1024 / 1024:.2f} MB")
            print(f"💾 Savings: {result.get_compression_savings_percentage():.1f}%")
        else:
            print(f"\n❌ Upload failed: {result.error}")

    finally:
        # Stop async upload manager
        await storage.stop_async_upload()


# ============================================================
# Example 3: Multiple Concurrent Async Uploads
# ============================================================

async def example_3_concurrent_uploads():
    """Upload multiple files concurrently."""
    print("\n" + "=" * 70)
    print("EXAMPLE 3: Concurrent Async Uploads")
    print("=" * 70)

    client = Minio(
        "localhost:9000",
        access_key="minioadmin",
        secret_key="minioadmin",
        secure=False
    )

    config = MinioStorageConfig(
        bucket="example-concurrent",
        enable_compression=True,
        enable_async_upload=True,
        async_upload_workers=4
    )

    compressor = ZstdCompressor()
    storage = MinioMediaStorage(client, config, compressor)

    await storage.start_async_upload()

    try:
        # Queue multiple uploads
        num_files = 5
        task_ids = []

        print(f"\n⬆️  Queuing {num_files} uploads...")

        for i in range(num_files):
            data = {
                "batch": i,
                "items": [
                    {"id": j, "value": j * 10}
                    for j in range(1000)
                ]
            }

            json_bytes = json.dumps(data).encode('utf-8')

            task_id = await storage.upload_bytes_async(
                data=json_bytes,
                object_name=f"batch-{i}.json",
                metadata={"batch-id": str(i)}
            )

            task_ids.append(task_id)
            print(f"   ✅ Queued: batch-{i}.json ({task_id})")

        # Wait for all to complete
        print(f"\n⏳ Waiting for {len(task_ids)} uploads to complete...")

        results = []
        for i, task_id in enumerate(task_ids):
            result = await storage.wait_for_upload(task_id, timeout=30.0)
            results.append(result)

            if result.success:
                print(f"   ✅ batch-{i}.json completed in {result.duration:.2f}s")
            else:
                print(f"   ❌ batch-{i}.json failed: {result.error}")

        # Summary
        successful = sum(1 for r in results if r.success)
        print(f"\n📊 Summary: {successful}/{len(results)} uploads successful")

    finally:
        await storage.stop_async_upload()


# ============================================================
# Example 4: Working with Metadata
# ============================================================

async def example_4_metadata():
    """Working with compression metadata."""
    print("\n" + "=" * 70)
    print("EXAMPLE 4: Working with Metadata")
    print("=" * 70)

    client = Minio(
        "localhost:9000",
        access_key="minioadmin",
        secret_key="minioadmin",
        secure=False
    )

    config = MinioStorageConfig(
        bucket="example-metadata",
        enable_compression=True,
        compression_level=3
    )

    compressor = ZstdCompressor()
    storage = MinioMediaStorage(client, config, compressor)

    # Create data
    data = json.dumps({
        "records": [{"id": i} for i in range(10000)]
    }).encode('utf-8')

    # Upload with custom metadata
    print("\n⬆️  Uploading with custom metadata...")
    await storage.upload_bytes(
        data=data,
        object_name="records.json",
        metadata={
            "created-by": "example-script",
            "created-at": datetime.now().isoformat(),
            "record-count": "10000",
            "data-type": "records"
        }
    )

    # Get all metadata
    metadata = await storage.get_object_metadata("records.json")

    print("\n📋 Object metadata:")
    for key, value in sorted(metadata.items()):
        if key.startswith("x-amz-meta-"):
            clean_key = key.replace("x-amz-meta-", "")
            print(f"   {clean_key}: {value}")


# ============================================================
# Example 5: Compression Level Comparison
# ============================================================

async def example_5_compression_levels():
    """Compare different compression levels."""
    print("\n" + "=" * 70)
    print("EXAMPLE 5: Compression Level Comparison")
    print("=" * 70)

    client = Minio(
        "localhost:9000",
        access_key="minioadmin",
        secret_key="minioadmin",
        secure=False
    )

    # Create large dataset
    data = json.dumps({
        "data": [
            {"id": i, "value": f"value-{i}" * 10}
            for i in range(5000)
        ]
    }).encode('utf-8')

    print(f"\n📦 Original size: {len(data) / 1024 / 1024:.2f} MB")
    print("\n📊 Testing compression levels:")

    for level in [0, 1, 2, 3]:
        config = MinioStorageConfig(
            bucket="example-levels",
            enable_compression=True,
            compression_level=level
        )

        compressor = ZstdCompressor()
        storage = MinioMediaStorage(client, config, compressor)

        # Upload
        import time
        start = time.time()

        await storage.upload_bytes(
            data=data,
            object_name=f"data-level-{level}.json"
        )

        duration = time.time() - start

        # Get stats
        if level > 0:
            metadata = await storage.get_object_metadata(f"data-level-{level}.json")
            compressed_size = int(metadata["x-amz-meta-compressed-size"])
            ratio = float(metadata["x-amz-meta-compression-ratio"])
            savings = (1 - ratio) * 100

            print(f"\n   Level {level}:")
            print(f"      Size: {compressed_size / 1024 / 1024:.2f} MB")
            print(f"      Savings: {savings:.1f}%")
            print(f"      Time: {duration:.3f}s")
        else:
            print(f"\n   Level 0 (no compression):")
            print(f"      Size: {len(data) / 1024 / 1024:.2f} MB")
            print(f"      Time: {duration:.3f}s")


# ============================================================
# Main Function
# ============================================================

async def main():
    """Run all examples."""
    print("\n" + "=" * 70)
    print("MinIO COMPRESSION & ASYNC UPLOAD - EXAMPLES")
    print("=" * 70)

    try:
        # Run examples
        await example_1_basic_compression()
        await example_2_async_upload()
        await example_3_concurrent_uploads()
        await example_4_metadata()
        await example_5_compression_levels()

        print("\n" + "=" * 70)
        print("✅ ALL EXAMPLES COMPLETED SUCCESSFULLY")
        print("=" * 70)

    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    # Run examples
    asyncio.run(main())
