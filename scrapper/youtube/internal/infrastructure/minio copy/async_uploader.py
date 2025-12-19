"""
Async MinIO uploader with compression and progress tracking.

Provides non-blocking upload operations with:
- Background worker pool for concurrent uploads
- Zstd compression support
- Real-time progress tracking
- Task queue management
"""

import asyncio
import logging
import uuid
from datetime import datetime, timedelta
from typing import Dict, Optional, Callable
from pathlib import Path
import io

from minio import Minio

from internal.infrastructure.compression import ICompressor, CompressionInfo
from .upload_task import (
    UploadTask,
    UploadStatus,
    UploadResult,
    UploadState
)


logger = logging.getLogger(__name__)


class AsyncUploadManager:
    """
    Async upload manager with worker pool and progress tracking.

    Manages a queue of upload tasks and processes them using a pool
    of background workers. Provides progress tracking and task cancellation.
    """

    def __init__(
        self,
        minio_client: Minio,
        compressor: ICompressor,
        num_workers: int = 4,
        queue_size: int = 100,
        cleanup_after_seconds: int = 3600
    ):
        """
        Initialize async upload manager.

        Args:
            minio_client: MinIO client instance
            compressor: Compression implementation
            num_workers: Number of concurrent worker tasks
            queue_size: Maximum size of upload queue
            cleanup_after_seconds: Time to keep completed tasks in memory
        """
        self.minio_client = minio_client
        self.compressor = compressor
        self.num_workers = num_workers
        self.cleanup_after_seconds = cleanup_after_seconds

        # Task queue and tracking
        self.queue: asyncio.Queue[UploadTask] = asyncio.Queue(maxsize=queue_size)
        self.tasks: Dict[str, UploadStatus] = {}
        self.results: Dict[str, UploadResult] = {}

        # Worker management
        self.workers: list[asyncio.Task] = []
        self.shutdown_event = asyncio.Event()
        self.started = False

        # Cleanup task
        self.cleanup_task: Optional[asyncio.Task] = None

    async def start(self) -> None:
        """Start the upload manager and worker pool."""
        if self.started:
            logger.warning("AsyncUploadManager already started")
            return

        logger.info(f"Starting AsyncUploadManager with {self.num_workers} workers")

        # Start worker pool
        for i in range(self.num_workers):
            worker = asyncio.create_task(self._worker(i))
            self.workers.append(worker)

        # Start cleanup task
        self.cleanup_task = asyncio.create_task(self._cleanup_loop())

        self.started = True
        logger.info("AsyncUploadManager started successfully")

    async def stop(self) -> None:
        """Stop the upload manager and wait for workers to finish."""
        if not self.started:
            return

        logger.info("Stopping AsyncUploadManager...")

        # Signal shutdown
        self.shutdown_event.set()

        # Wait for all workers to finish
        await asyncio.gather(*self.workers, return_exceptions=True)

        # Cancel cleanup task
        if self.cleanup_task:
            self.cleanup_task.cancel()
            try:
                await self.cleanup_task
            except asyncio.CancelledError:
                pass

        self.started = False
        logger.info("AsyncUploadManager stopped")

    async def upload_async(
        self,
        bucket_name: str,
        object_name: str,
        data: bytes,
        content_type: Optional[str] = None,
        enable_compression: bool = True,
        compression_level: int = 2,
        metadata: Optional[Dict[str, str]] = None
    ) -> str:
        """
        Queue data for async upload.

        Args:
            bucket_name: Target bucket
            object_name: Target object path
            data: Data to upload
            content_type: MIME type
            enable_compression: Whether to compress data
            compression_level: Compression level (0-3)
            metadata: Custom metadata

        Returns:
            Task ID for tracking progress

        Raises:
            RuntimeError: If manager not started
            asyncio.QueueFull: If queue is full
        """
        if not self.started:
            raise RuntimeError("AsyncUploadManager not started. Call start() first.")

        # Generate task ID
        task_id = str(uuid.uuid4())

        # Create upload task
        task = UploadTask(
            task_id=task_id,
            bucket_name=bucket_name,
            object_name=object_name,
            data=data,
            content_type=content_type,
            enable_compression=enable_compression,
            compression_level=compression_level,
            metadata=metadata or {}
        )

        # Initialize status
        status = UploadStatus(
            task_id=task_id,
            status=UploadState.QUEUED,
            total_bytes=len(data)
        )
        self.tasks[task_id] = status

        # Queue task
        await self.queue.put(task)

        logger.info(
            f"Queued upload task {task_id}: {task.get_size_mb():.2f} MB "
            f"to {bucket_name}/{object_name}"
        )

        return task_id

    def get_upload_status(self, task_id: str) -> Optional[UploadStatus]:
        """
        Get current status of upload task.

        Args:
            task_id: Task ID from upload_async()

        Returns:
            UploadStatus or None if task not found
        """
        return self.tasks.get(task_id)

    async def wait_for_upload(
        self,
        task_id: str,
        timeout: Optional[float] = None
    ) -> UploadResult:
        """
        Wait for upload to complete.

        Args:
            task_id: Task ID from upload_async()
            timeout: Max time to wait in seconds (None = wait forever)

        Returns:
            UploadResult with final status

        Raises:
            asyncio.TimeoutError: If timeout exceeded
            KeyError: If task_id not found
        """
        if task_id not in self.tasks:
            raise KeyError(f"Task {task_id} not found")

        start_time = datetime.now()

        # Poll until complete or timeout
        while True:
            # Check if result is ready
            if task_id in self.results:
                return self.results[task_id]

            # Check timeout
            if timeout is not None:
                elapsed = (datetime.now() - start_time).total_seconds()
                if elapsed >= timeout:
                    raise asyncio.TimeoutError(
                        f"Upload {task_id} did not complete within {timeout}s"
                    )

            # Wait a bit before checking again
            await asyncio.sleep(0.1)

    async def cancel_upload(self, task_id: str) -> bool:
        """
        Cancel a queued or in-progress upload.

        Args:
            task_id: Task ID to cancel

        Returns:
            True if canceled, False if not found or already completed
        """
        status = self.tasks.get(task_id)
        if not status:
            return False

        if status.is_terminal():
            return False

        # Mark as canceled
        status.mark_canceled()

        logger.info(f"Upload task {task_id} canceled")
        return True

    async def _worker(self, worker_id: int) -> None:
        """
        Background worker that processes upload tasks.

        Args:
            worker_id: Worker identifier for logging
        """
        logger.info(f"Worker {worker_id} started")

        while not self.shutdown_event.is_set():
            try:
                # Get task from queue (with timeout to check shutdown)
                task = await asyncio.wait_for(
                    self.queue.get(),
                    timeout=1.0
                )

                # Process task
                await self._process_task(task, worker_id)

            except asyncio.TimeoutError:
                # No task in queue, continue loop
                continue
            except Exception as e:
                logger.error(f"Worker {worker_id} error: {e}", exc_info=True)

        logger.info(f"Worker {worker_id} stopped")

    async def _process_task(self, task: UploadTask, worker_id: int) -> None:
        """
        Process a single upload task.

        Args:
            task: Upload task to process
            worker_id: Worker identifier
        """
        task_id = task.task_id
        status = self.tasks[task_id]

        # Check if canceled
        if status.status == UploadState.CANCELED:
            logger.info(f"Skipping canceled task {task_id}")
            return

        logger.info(
            f"Worker {worker_id} processing task {task_id}: "
            f"{task.get_size_mb():.2f} MB"
        )

        status.mark_started()
        data_to_upload = task.data
        compression_info: Optional[CompressionInfo] = None

        try:
            # Step 1: Compress if enabled
            if task.enable_compression and task.compression_level > 0:
                status.status = UploadState.COMPRESSING
                logger.debug(f"Compressing task {task_id} (level={task.compression_level})")

                compressed_data = await asyncio.to_thread(
                    self.compressor.compress,
                    task.data,
                    task.compression_level
                )

                compression_info = self.compressor.get_compression_info(
                    original_size=len(task.data),
                    compressed_size=len(compressed_data),
                    level=task.compression_level
                )

                data_to_upload = compressed_data

                logger.info(
                    f"Task {task_id} compressed: {compression_info.original_size} → "
                    f"{compression_info.compressed_size} bytes "
                    f"({compression_info.get_savings_percentage():.1f}% saved)"
                )

            # Step 2: Prepare metadata
            upload_metadata = task.metadata.copy()
            if compression_info:
                upload_metadata.update({
                    "x-amz-meta-compressed": "true",
                    "x-amz-meta-compression-algorithm": compression_info.algorithm,
                    "x-amz-meta-compression-level": str(compression_info.level),
                    "x-amz-meta-original-size": str(compression_info.original_size),
                    "x-amz-meta-compressed-size": str(compression_info.compressed_size),
                    "x-amz-meta-compression-ratio": f"{compression_info.compression_ratio:.4f}",
                })

            # Step 3: Upload to MinIO
            status.status = UploadState.UPLOADING
            logger.debug(f"Uploading task {task_id} to MinIO")

            # Ensure bucket exists
            await asyncio.to_thread(
                self._ensure_bucket,
                task.bucket_name
            )

            # Upload data
            data_stream = io.BytesIO(data_to_upload)
            await asyncio.to_thread(
                self.minio_client.put_object,
                task.bucket_name,
                task.object_name,
                data_stream,
                length=len(data_to_upload),
                content_type=task.content_type,
                metadata=upload_metadata
            )

            # Update progress
            status.update_progress(len(data_to_upload), len(data_to_upload))

            # Mark completed
            status.mark_completed()

            # Store result
            result = UploadResult(
                task_id=task_id,
                success=True,
                object_key=task.object_name,
                duration=status.get_duration_seconds(),
                original_size=compression_info.original_size if compression_info else len(task.data),
                compressed_size=compression_info.compressed_size if compression_info else len(data_to_upload),
                compression_ratio=compression_info.compression_ratio if compression_info else 1.0,
                compression_algorithm=compression_info.algorithm if compression_info else None
            )
            self.results[task_id] = result

            logger.info(
                f"Task {task_id} completed successfully in "
                f"{result.duration:.2f}s"
            )

        except Exception as e:
            logger.error(f"Task {task_id} failed: {e}", exc_info=True)

            # Mark failed
            status.mark_failed(str(e))

            # Store error result
            result = UploadResult(
                task_id=task_id,
                success=False,
                error=str(e),
                duration=status.get_duration_seconds()
            )
            self.results[task_id] = result

    def _ensure_bucket(self, bucket_name: str) -> None:
        """
        Ensure bucket exists (sync method for thread executor).

        Args:
            bucket_name: Bucket to check/create
        """
        if not self.minio_client.bucket_exists(bucket_name):
            self.minio_client.make_bucket(bucket_name)
            logger.info(f"Created bucket: {bucket_name}")

    async def _cleanup_loop(self) -> None:
        """Background task to cleanup old completed tasks."""
        logger.info("Cleanup task started")

        while not self.shutdown_event.is_set():
            try:
                await asyncio.sleep(300)  # Run every 5 minutes

                now = datetime.now()
                cutoff = now - timedelta(seconds=self.cleanup_after_seconds)

                # Find old completed tasks
                to_remove = []
                for task_id, status in self.tasks.items():
                    if status.is_terminal() and status.completed_at:
                        if status.completed_at < cutoff:
                            to_remove.append(task_id)

                # Remove old tasks
                for task_id in to_remove:
                    del self.tasks[task_id]
                    if task_id in self.results:
                        del self.results[task_id]

                if to_remove:
                    logger.info(f"Cleaned up {len(to_remove)} old tasks")

            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Cleanup error: {e}", exc_info=True)

        logger.info("Cleanup task stopped")

    def get_queue_size(self) -> int:
        """Get current number of tasks in queue."""
        return self.queue.qsize()

    def get_active_tasks(self) -> int:
        """Get number of active (non-terminal) tasks."""
        return sum(1 for status in self.tasks.values() if not status.is_terminal())
