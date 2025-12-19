"""Setup script to upload test video to MinIO for integration tests."""

import asyncio
import httpx
import tempfile
from pathlib import Path
from minio import Minio
from minio.error import S3Error

# MinIO configuration for test environment
MINIO_ENDPOINT = "localhost:9010"
MINIO_ACCESS_KEY = "minioadmin"
MINIO_SECRET_KEY = "minioadmin"
BUCKET_NAME = "test-videos"
TEST_VIDEO_URL = "https://download.samplelib.com/mp4/sample-5s.mp4"
TEST_VIDEO_PATH = Path(tempfile.gettempdir()) / "test_video_sample.mp4"
TEST_VIDEO_KEY = "test/test_video_sample.mp4"


async def download_test_video():
    """Download a small test video."""
    print(f"Downloading test video from {TEST_VIDEO_URL}...")

    async with httpx.AsyncClient() as client:
        response = await client.get(TEST_VIDEO_URL, follow_redirects=True)
        response.raise_for_status()

        TEST_VIDEO_PATH.write_bytes(response.content)
        print(f"[OK] Downloaded test video to {TEST_VIDEO_PATH} ({len(response.content)} bytes)")


def setup_minio():
    """Create bucket and upload test video to MinIO."""
    print(f"\nConnecting to MinIO at {MINIO_ENDPOINT}...")

    # Create MinIO client
    client = Minio(
        MINIO_ENDPOINT,
        access_key=MINIO_ACCESS_KEY,
        secret_key=MINIO_SECRET_KEY,
        secure=False
    )

    # Create bucket if it doesn't exist
    print(f"Creating bucket '{BUCKET_NAME}' if it doesn't exist...")
    try:
        if not client.bucket_exists(BUCKET_NAME):
            client.make_bucket(BUCKET_NAME)
            print(f"[OK] Created bucket '{BUCKET_NAME}'")
        else:
            print(f"[OK] Bucket '{BUCKET_NAME}' already exists")
    except S3Error as e:
        print(f"[ERROR] Error creating bucket: {e}")
        raise

    # Upload test video
    print(f"Uploading test video to {BUCKET_NAME}/{TEST_VIDEO_KEY}...")
    try:
        client.fput_object(
            BUCKET_NAME,
            TEST_VIDEO_KEY,
            str(TEST_VIDEO_PATH),
            content_type="video/mp4"
        )
        print(f"[OK] Uploaded test video to MinIO")

        # Verify upload
        stat = client.stat_object(BUCKET_NAME, TEST_VIDEO_KEY)
        print(f"[OK] Verified: {stat.object_name} ({stat.size} bytes)")

    except S3Error as e:
        print(f"[ERROR] Error uploading video: {e}")
        raise


async def main():
    """Main setup function."""
    print("=" * 60)
    print("Setting up test video for FFmpeg integration tests")
    print("=" * 60)

    try:
        # Download test video
        await download_test_video()

        # Setup MinIO
        setup_minio()

        print("\n" + "=" * 60)
        print("[OK] Setup complete!")
        print("=" * 60)
        print("\nYou can now run integration tests with:")
        print("  docker-compose -f docker-compose.test.yml run --rm youtube-test-integration")

    except Exception as e:
        print(f"\n[ERROR] Setup failed: {e}")
        raise


if __name__ == "__main__":
    asyncio.run(main())
