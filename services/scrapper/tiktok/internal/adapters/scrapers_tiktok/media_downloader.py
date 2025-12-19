"""
Media Downloader - TikTok Media Download
Downloads audio (MP3) and video (MP4) from TikTok and stores them in
MinIO object storage.

Strategy:
1. Audio: Try music.playUrl first (already MP3!)
2. Audio fallback: Download video → extract with ffmpeg
3. Video: Use downloadAddr or playAddr
"""

import asyncio
import aiohttp
import aiofiles
from pathlib import Path
from typing import Optional, Literal
import re
import logging
import mimetypes
import shutil
import tempfile

from domain import Content
from internal.infrastructure.minio.storage import MinioMediaStorage


logger = logging.getLogger(__name__)


class MediaDownloader:
    """
    Media Downloader for TikTok

    Downloads audio (MP3) and video (MP4) files from TikTok.
    Implements async streaming for efficient memory usage.
    """

    def __init__(
        self,
        enable_ffmpeg: bool = True,
        ffmpeg_path: str = "ffmpeg",
        max_file_size_mb: int = 500,
        download_timeout: int = 300,
        chunk_size: int = 8192,
        storage: Optional[MinioMediaStorage] = None,
    ):
        """
        Initialize media downloader

        Args:
            enable_ffmpeg: Enable ffmpeg fallback for audio extraction
            ffmpeg_path: Path to ffmpeg executable
            max_file_size_mb: Maximum file size in MB
            download_timeout: Download timeout in seconds
            chunk_size: Download chunk size in bytes
        """
        self.enable_ffmpeg = enable_ffmpeg
        self.ffmpeg_path = ffmpeg_path
        self.max_file_size_mb = max_file_size_mb
        self.download_timeout = download_timeout
        self.chunk_size = chunk_size
        if storage is None:
            raise ValueError("MinIO storage instance must be provided")
        self.storage = storage

    async def download_media(
        self, content: Content, media_type: Literal["video", "audio"], save_dir: str
    ) -> Optional[str]:
        """
        Download media from TikTok

        Args:
            content: Content entity carrying transient download URLs
            media_type: Type of media to download ("video" or "audio")
            save_dir: Target prefix inside remote storage

        Returns:
            Storage URI if successful, otherwise None
        """
        logger.info(f"Downloading {media_type} for content {content.external_id}")

        if not self.storage:
            raise RuntimeError("Media storage is not configured; cannot download media")

        target = self._normalize_prefix(save_dir)

        try:
            if media_type == "audio":
                return await self._download_audio(content, target)
            if media_type == "video":
                return await self._download_video(content, target)

            logger.error(f"Invalid media_type: {media_type}")
            return None

        except Exception as e:
            logger.error(
                f"Error downloading {media_type} for content {content.external_id}: {e}"
            )
            return None

    async def _download_audio(self, content: Content, save_dir: str) -> Optional[str]:
        """
        Download audio (MP3)

        Strategy:
        1. Try direct MP3 download from music.playUrl (primary)
        2. Fallback: Download video → extract audio with ffmpeg

        Args:
            content: Content entity
            save_dir: Storage prefix inside MinIO

        Returns:
            Storage URI or None if download failed
        """
        # Primary: Direct MP3 download
        if content.audio_url:
            logger.info(f"Trying direct MP3 download for content {content.external_id}")
            file_path = await self._download_file(
                url=content.audio_url,
                content_id=content.external_id,
                extension="mp3",
                save_dir=save_dir,
            )

            if file_path:
                logger.info(f"Successfully downloaded MP3: {file_path}")
                return file_path

        # Fallback: Extract audio from video with ffmpeg
        if self.enable_ffmpeg and content.video_download_url:
            logger.info(
                f"Falling back to ffmpeg extraction for content {content.external_id}"
            )
            return await self._download_and_extract_audio(content, save_dir)

        logger.warning(
            f"No audio download method available for content {content.external_id}"
        )
        return None

    async def _download_video(self, content: Content, save_dir: str) -> Optional[str]:
        """
        Download video (MP4)

        Args:
            content: Content entity
            save_dir: Storage prefix inside MinIO

        Returns:
            Storage URI or None if download failed
        """
        if not content.video_download_url:
            logger.warning(f"No video download URL for content {content.external_id}")
            return None

        logger.info(f"Downloading MP4 for content {content.external_id}")
        file_path = await self._download_file(
            url=content.video_download_url,
            content_id=content.external_id,
            extension="mp4",
            save_dir=save_dir,
        )

        if file_path:
            logger.info(f"Successfully downloaded MP4: {file_path}")
            return file_path

        return None

    async def _download_file(
        self,
        url: str,
        content_id: str,
        extension: str,
        save_dir: str,
        use_storage: bool = True,
    ) -> Optional[str]:
        """
        Download a file from URL with async streaming.

        Args:
            url: Download URL
            content_id: TikTok content ID
            extension: File extension (mp3, mp4)
            save_dir: Directory/prefix for storage uploads
            use_storage: When True and storage backend is configured,
                upload the downloaded file to remote storage and return
                its URI. When False, always return local file path.

        Returns:
            Storage URI or absolute local path, depending on configuration.
        """
        safe_filename = self._sanitize_filename(content_id, extension)
        content_type = self._guess_mime_type(extension)
        prefix = save_dir if self.storage else None

        # Determine local path for download (temp file if using storage)
        if self.storage and use_storage:
            temp_dir = Path(tempfile.mkdtemp(prefix="tiktok_media_"))
            local_path = temp_dir / safe_filename
        else:
            local_path = Path(save_dir) / safe_filename
            local_path.parent.mkdir(parents=True, exist_ok=True)

        try:
            timeout = aiohttp.ClientTimeout(total=self.download_timeout)

            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.get(url) as response:
                    if response.status != 200:
                        logger.error(f"HTTP {response.status} for URL: {url}")
                        return None

                    content_length = response.headers.get("Content-Length")
                    if content_length:
                        size_mb = int(content_length) / (1024 * 1024)
                        if size_mb > self.max_file_size_mb:
                            logger.error(
                                f"File too large: {size_mb:.2f} MB > {self.max_file_size_mb} MB"
                            )
                            return None
                        logger.info(f"Downloading {size_mb:.2f} MB to {local_path}")

                    async with aiofiles.open(local_path, "wb") as f:
                        downloaded = 0
                        async for chunk in response.content.iter_chunked(
                            self.chunk_size
                        ):
                            if chunk:
                                await f.write(chunk)
                                downloaded += len(chunk)

                    logger.info(
                        f"Downloaded {downloaded / (1024 * 1024):.2f} MB successfully"
                    )

            if self.storage and use_storage:
                try:
                    # Check if async upload is enabled
                    # Accessing protected member _enable_async_upload as we are in the same package context logic
                    if getattr(self.storage, "_enable_async_upload", False):
                        async with aiofiles.open(local_path, "rb") as f:
                            file_data = await f.read()

                        task_id = await self.storage.upload_bytes_async(
                            data=file_data,
                            object_name=safe_filename,
                            prefix=prefix,
                            content_type=content_type,
                        )
                        # Wait for upload to complete before returning
                        # This ensures the file is available for other services
                        logger.info(
                            f"Waiting for async upload task {task_id} to complete..."
                        )
                        result = await self.storage.wait_for_upload(
                            task_id, timeout=300
                        )
                        if not result.success:
                            raise Exception(f"Async upload failed: {result.error}")
                        logger.info(
                            f"Async upload task {task_id} completed successfully"
                        )

                        full_key = self.storage._build_object_name(
                            safe_filename, prefix
                        )
                        return self.storage.object_uri(full_key)
                    else:
                        object_key = await self.storage.upload_file(
                            source=local_path,
                            object_name=safe_filename,
                            prefix=prefix,
                            content_type=content_type,
                        )
                        # Return the full URI including prefix
                        return self.storage.object_uri(object_key)
                finally:
                    try:
                        shutil.rmtree(local_path.parent, ignore_errors=True)
                    except Exception as cleanup_error:
                        logger.debug(
                            f"Failed to clean temp directory {local_path.parent}: {cleanup_error}"
                        )

            return str(local_path.absolute())

        except asyncio.TimeoutError:
            logger.error(f"Download timeout for content {content_id}")
            return None
        except Exception as e:
            logger.error(f"Error downloading file: {e}")
            return None

    async def _download_and_extract_audio(
        self, content: Content, save_dir: str
    ) -> Optional[str]:
        """
        Download video and extract audio using ffmpeg

        Args:
            content: Content entity
            save_dir: Save directory

        Returns:
            Storage URI or local path depending on configuration, otherwise None
        """
        if not content.video_download_url:
            return None

        temp_dir = Path(tempfile.mkdtemp(prefix="tiktok_media_extract_"))
        temp_audio_path = temp_dir / self._sanitize_filename(content.external_id, "mp3")

        try:
            # Download video locally for ffmpeg processing
            temp_video_path = await self._download_file(
                url=content.video_download_url,
                content_id=content.external_id,
                extension="mp4",
                save_dir=str(temp_dir),
                use_storage=False,
            )

            if not temp_video_path:
                return None

            success = await self.extract_audio_with_ffmpeg(
                video_path=temp_video_path, audio_path=str(temp_audio_path)
            )

            # Clean up temp video file
            try:
                Path(temp_video_path).unlink()
            except Exception as exc:
                logger.debug(f"Failed to delete temp video file: {exc}")

            if not success:
                return None

            logger.info(f"Successfully extracted audio: {temp_audio_path}")

            if self.storage:
                prefix = save_dir
                object_key = await self.storage.upload_file(
                    source=temp_audio_path,
                    object_name=temp_audio_path.name,
                    prefix=prefix,
                    content_type=self._guess_mime_type("mp3"),
                )
                return self.storage.object_uri(object_key)

            raise RuntimeError(
                "Media storage is not configured; cannot upload extracted audio"
            )

        except Exception as e:
            logger.error(f"Error in download and extract: {e}")
            return None
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)

    async def extract_audio_with_ffmpeg(self, video_path: str, audio_path: str) -> bool:
        """
        Extract audio from video file using ffmpeg

        Args:
            video_path: Path to video file
            audio_path: Destination path for audio file

        Returns:
            True if successful, False otherwise
        """
        if not self.enable_ffmpeg:
            logger.warning("ffmpeg is disabled")
            return False

        try:
            # ffmpeg command to extract audio as MP3
            # -i: input file
            # -vn: no video
            # -acodec libmp3lame: use MP3 encoder
            # -q:a 2: quality (2 = high quality, 0-9 scale)
            # -y: overwrite output file
            cmd = [
                self.ffmpeg_path,
                "-i",
                video_path,
                "-vn",
                "-acodec",
                "libmp3lame",
                "-q:a",
                "2",
                "-y",
                audio_path,
            ]

            logger.info(f"Running ffmpeg: {' '.join(cmd)}")

            # Run ffmpeg as subprocess
            process = await asyncio.create_subprocess_exec(
                *cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
            )

            stdout, stderr = await process.communicate()

            if process.returncode == 0:
                logger.info("ffmpeg extraction successful")
                return True
            else:
                logger.error(f"ffmpeg failed with code {process.returncode}")
                logger.error(f"ffmpeg stderr: {stderr.decode()}")
                return False

        except FileNotFoundError:
            logger.error(f"ffmpeg not found at: {self.ffmpeg_path}")
            logger.error("Install ffmpeg or set correct path in config")
            return False
        except Exception as e:
            logger.error(f"Error running ffmpeg: {e}")
            return False

    @staticmethod
    def _sanitize_filename(content_id: str, extension: str) -> str:
        """
        Sanitize content ID and create safe filename

        Args:
            content_id: TikTok content ID
            extension: File extension

        Returns:
            Safe filename
        """
        # Remove any characters that aren't alphanumeric, dash, or underscore
        safe_id = re.sub(r"[^a-zA-Z0-9_-]", "", content_id)

        # Limit length
        if len(safe_id) > 50:
            safe_id = safe_id[:50]

        return f"{safe_id}.{extension}"

    @staticmethod
    def _guess_mime_type(extension: str) -> Optional[str]:
        """Return a MIME type for the given file extension if known."""
        if not extension:
            return None
        ext = extension if extension.startswith(".") else f".{extension}"
        return mimetypes.types_map.get(ext.lower())

    @staticmethod
    def _normalize_prefix(prefix: str) -> str:
        """Normalize a directory prefix for object storage usage."""
        if not prefix:
            return ""
        normalized = prefix.replace("\\", "/").strip()
        # Remove leading ./ and redundant slashes
        normalized = re.sub(r"^(\./)+", "", normalized)
        normalized = normalized.strip("/")
        return normalized

    @staticmethod
    def is_ffmpeg_available() -> bool:
        """
        Check if ffmpeg is available

        Returns:
            True if ffmpeg is installed and accessible
        """
        try:
            import subprocess

            result = subprocess.run(
                ["ffmpeg", "-version"], capture_output=True, timeout=5
            )
            return result.returncode == 0
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return False
