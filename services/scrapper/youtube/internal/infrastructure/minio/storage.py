"""
MinIO storage helper for media uploads.

Provides async-friendly helpers for ensuring a bucket exists and uploading
objects while running MinIO's synchronous SDK calls in executor threads.

Enhanced with:
- Compression support (Zstd)
- Async upload with progress tracking
- Auto-decompression on download
- Metadata handling for compressed files
"""
import asyncio
import io
import logging
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Dict

from minio import Minio

from internal.infrastructure.compression import ICompressor, ZstdCompressor
from .async_uploader import AsyncUploadManager
from .upload_task import UploadStatus, UploadResult


logger = logging.getLogger(__name__)


@dataclass
class MinioStorageConfig:
    """Configuration details for MinIO media storage."""
    bucket: str
    base_path: Optional[str] = None
    enable_compression: bool = True
    compression_level: int = 2
    enable_async_upload: bool = False
    async_upload_workers: int = 4


class MinioMediaStorage:
    """
    Helper for uploading media files to MinIO.

    Enhanced with compression and async upload capabilities.
    """

    def __init__(
        self,
        client: Minio,
        config: MinioStorageConfig,
        compressor: Optional[ICompressor] = None,
    ) -> None:
        self._client = client
        self._bucket = config.bucket
        self._base_path = (config.base_path or "").strip("/ ")
        self._bucket_checked = False
        self._bucket_lock = asyncio.Lock()

        # Compression
        self._enable_compression = config.enable_compression
        self._compression_level = config.compression_level
        self._compressor = compressor or ZstdCompressor()

        # Async upload
        self._enable_async_upload = config.enable_async_upload
        self._async_manager: Optional[AsyncUploadManager] = None
        if config.enable_async_upload:
            self._async_manager = AsyncUploadManager(
                minio_client=client,
                compressor=self._compressor,
                num_workers=config.async_upload_workers
            )

    async def ensure_bucket(self) -> None:
        """Ensure target bucket exists (idempotent)."""
        if self._bucket_checked:
            return

        async with self._bucket_lock:
            if self._bucket_checked:
                return

            exists = await asyncio.to_thread(
                self._client.bucket_exists,
                bucket_name=self._bucket
            )
            if not exists:
                await asyncio.to_thread(
                    self._client.make_bucket,
                    bucket_name=self._bucket
                )
            self._bucket_checked = True

    def _build_object_name(self, object_name: str, prefix: Optional[str] = None) -> str:
        """Compose final object name with base path and prefix."""
        parts = []
        if self._base_path:
            parts.append(self._base_path)
        if prefix:
            trimmed = prefix.strip("/ ")
            if trimmed:
                parts.append(trimmed)
        parts.append(object_name.strip("/ "))
        return "/".join(parts)

    async def upload_file(
        self,
        source: Path,
        object_name: str,
        prefix: Optional[str] = None,
        content_type: Optional[str] = None
    ) -> str:
        """
        Upload a local file to MinIO and return the object key.

        Args:
            source: Path to the local file
            object_name: Target object filename
            prefix: Optional prefix/folder inside the bucket
            content_type: Optional MIME type for object metadata

        Returns:
            Object key within the bucket
        """
        await self.ensure_bucket()

        key = self._build_object_name(object_name, prefix)

        put_kwargs = {}
        if content_type:
            put_kwargs["content_type"] = content_type

        await asyncio.to_thread(
            self._client.fput_object,
            bucket_name=self._bucket,
            object_name=key,
            file_path=str(source),
            **put_kwargs
        )

        return key

    async def upload_bytes(
        self,
        data: bytes,
        object_name: str,
        prefix: Optional[str] = None,
        content_type: Optional[str] = None,
        enable_compression: Optional[bool] = None,
        compression_level: Optional[int] = None,
        metadata: Optional[Dict[str, str]] = None
    ) -> str:
        """
        Upload bytes data to MinIO with optional compression.

        Args:
            data: Bytes to upload
            object_name: Target object filename
            prefix: Optional prefix/folder inside the bucket
            content_type: Optional MIME type
            enable_compression: Override default compression setting
            compression_level: Override default compression level (0-3)
            metadata: Custom metadata

        Returns:
            Object key within the bucket
        """
        await self.ensure_bucket()

        key = self._build_object_name(object_name, prefix)
        compress = enable_compression if enable_compression is not None else self._enable_compression
        level = compression_level if compression_level is not None else self._compression_level

        data_to_upload = data
        upload_metadata = metadata.copy() if metadata else {}

        # Compress if enabled
        if compress and level > 0:
            compressed = await asyncio.to_thread(
                self._compressor.compress,
                data,
                level
            )

            compression_info = self._compressor.get_compression_info(
                original_size=len(data),
                compressed_size=len(compressed),
                level=level
            )

            data_to_upload = compressed

            # Add compression metadata
            upload_metadata.update({
                "compressed": "true",
                "compression-algorithm": compression_info.algorithm,
                "compression-level": str(compression_info.level),
                "original-size": str(compression_info.original_size),
                "compressed-size": str(compression_info.compressed_size),
                "compression-ratio": f"{compression_info.compression_ratio:.4f}",
            })

            logger.debug(
                f"Compressed {len(data)} → {len(compressed)} bytes "
                f"({compression_info.get_savings_percentage():.1f}% saved)"
            )

        # Upload
        data_stream = io.BytesIO(data_to_upload)
        await asyncio.to_thread(
            self._client.put_object,
            bucket_name=self._bucket,
            object_name=key,
            data=data_stream,
            length=len(data_to_upload),
            content_type=content_type,
            user_metadata=upload_metadata
        )

        logger.info(f"Uploaded {len(data_to_upload)} bytes to {key}")
        return self.object_uri(key)


    async def upload_bytes_async(
        self,
        data: bytes,
        object_name: str,
        prefix: Optional[str] = None,
        content_type: Optional[str] = None,
        enable_compression: Optional[bool] = None,
        compression_level: Optional[int] = None,
        metadata: Optional[Dict[str, str]] = None
    ) -> str:
        """
        Upload bytes data asynchronously (non-blocking).

        Returns task_id immediately. Use get_upload_status() to track progress.

        Args:
            data: Bytes to upload
            object_name: Target object filename
            prefix: Optional prefix/folder inside the bucket
            content_type: Optional MIME type
            enable_compression: Override default compression setting
            compression_level: Override default compression level (0-3)
            metadata: Custom metadata

        Returns:
            Task ID for tracking upload progress

        Raises:
            RuntimeError: If async upload not enabled
        """
        if not self._async_manager:
            raise RuntimeError(
                "Async upload not enabled. Set enable_async_upload=True in config."
            )

        if not self._async_manager.started:
            await self._async_manager.start()

        key = self._build_object_name(object_name, prefix)
        compress = enable_compression if enable_compression is not None else self._enable_compression
        level = compression_level if compression_level is not None else self._compression_level

        task_id = await self._async_manager.upload_async(
            bucket_name=self._bucket,
            object_name=key,
            data=data,
            content_type=content_type,
            enable_compression=compress,
            compression_level=level,
            metadata=metadata
        )

        logger.info(f"Queued async upload {task_id} for {key}")
        return task_id

    def get_upload_status(self, task_id: str) -> Optional[UploadStatus]:
        """
        Get status of async upload task.

        Args:
            task_id: Task ID from upload_bytes_async()

        Returns:
            UploadStatus or None if task not found
        """
        if not self._async_manager:
            return None
        return self._async_manager.get_upload_status(task_id)

    async def wait_for_upload(
        self,
        task_id: str,
        timeout: Optional[float] = None
    ) -> UploadResult:
        """
        Wait for async upload to complete.

        Args:
            task_id: Task ID from upload_bytes_async()
            timeout: Max seconds to wait (None = wait forever)

        Returns:
            UploadResult with final status

        Raises:
            RuntimeError: If async upload not enabled
            asyncio.TimeoutError: If timeout exceeded
        """
        if not self._async_manager:
            raise RuntimeError("Async upload not enabled")

        return await self._async_manager.wait_for_upload(task_id, timeout)

    async def download_bytes(
        self,
        object_name: str,
        prefix: Optional[str] = None,
        auto_decompress: bool = True
    ) -> bytes:
        """
        Download object as bytes with auto-decompression.

        Args:
            object_name: Object filename
            prefix: Optional prefix/folder
            auto_decompress: Automatically decompress if compressed

        Returns:
            Downloaded bytes (decompressed if auto_decompress=True)
        """
        key = self._build_object_name(object_name, prefix)

        # Get object metadata
        stat = await asyncio.to_thread(
            self._client.stat_object,
            bucket_name=self._bucket,
            object_name=key
        )

        metadata = stat.metadata or {}

        # Download object
        response = await asyncio.to_thread(
            self._client.get_object,
            bucket_name=self._bucket,
            object_name=key
        )

        try:
            data = response.read()
        finally:
            response.close()
            response.release_conn()

        # Auto-decompress if needed
        if auto_decompress and metadata.get("x-amz-meta-compressed") == "true":
            logger.debug(f"Auto-decompressing {key}")
            data = await asyncio.to_thread(
                self._compressor.decompress,
                data
            )
            logger.debug(f"Decompressed to {len(data)} bytes")

        return data

    async def get_object_metadata(
        self,
        object_name: str,
        prefix: Optional[str] = None
    ) -> Dict[str, str]:
        """
        Get object metadata.

        Args:
            object_name: Object filename
            prefix: Optional prefix/folder

        Returns:
            Metadata dictionary
        """
        key = self._build_object_name(object_name, prefix)

        stat = await asyncio.to_thread(
            self._client.stat_object,
            bucket_name=self._bucket,
            object_name=key
        )

        return stat.metadata or {}

    def is_compressed(self, metadata: Dict[str, str]) -> bool:
        """
        Check if object is compressed based on metadata.

        Args:
            metadata: Object metadata

        Returns:
            True if object is compressed
        """
        return metadata.get("x-amz-meta-compressed") == "true"

    def object_uri(self, object_key: str) -> str:
        """Return a URI-style identifier for the stored object."""
        return f"minio://{self._bucket}/{object_key}"
    
    async def get_presigned_url(
        self,
        object_uri: str,
        expires_hours: int = 168
    ) -> Optional[str]:
        """
        Generate presigned URL for an object
        
        Args:
            object_uri: MinIO URI (minio://bucket/key) or just the key
            expires_hours: Expiration time in hours (default 7 days)
            
        Returns:
            Presigned URL string or None if failed
        """
        from datetime import timedelta
        
        try:
            # Parse URI: minio://bucket/key -> bucket, key
            if object_uri.startswith("minio://"):
                # Remove minio:// prefix
                uri_without_scheme = object_uri[8:]
                # Split into bucket and key
                parts = uri_without_scheme.split("/", 1)
                if len(parts) != 2:
                    logger.error(f"Invalid MinIO URI format: {object_uri}")
                    return None
                bucket_name, object_key = parts
            else:
                # Assume it's just a key, use default bucket
                bucket_name = self._bucket
                object_key = object_uri
            
            # Generate presigned URL
            presigned_url = await asyncio.to_thread(
                self._client.presigned_get_object,
                bucket_name=bucket_name,
                object_name=object_key,
                expires=timedelta(hours=expires_hours)
            )
            
            logger.info(f"Generated presigned URL for {object_uri}: {presigned_url}")
            return presigned_url
            
        except Exception as e:
            logger.error(f"Failed to generate presigned URL for {object_uri}: {e}")
            return None

    async def start_async_upload(self) -> None:
        """Start async upload manager."""
        if self._async_manager and not self._async_manager.started:
            await self._async_manager.start()

    async def stop_async_upload(self) -> None:
        """Stop async upload manager."""
        if self._async_manager:
            await self._async_manager.stop()

