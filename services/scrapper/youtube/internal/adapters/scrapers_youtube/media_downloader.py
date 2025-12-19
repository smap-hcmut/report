"""
Media Downloader - YouTube Media Download
Downloads audio (MP3) and video (MP4) from YouTube using yt-dlp download URLs.
Supports local storage and MinIO object storage.
Relies on the external FFmpeg service for audio conversion.
"""
import asyncio
import aiohttp
import aiofiles
from pathlib import Path, PurePosixPath
from typing import Optional, Literal, TYPE_CHECKING
import tempfile
import shutil
import mimetypes
import re
import yt_dlp
from concurrent.futures import ThreadPoolExecutor

from domain import Content
from application.interfaces import IMediaDownloader
from utils.logger import logger
from config import settings

if TYPE_CHECKING:
    from internal.infrastructure.ffmpeg.client import RemoteFFmpegClient
    from application.interfaces import ISpeech2TextClient


class YouTubeMediaDownloader(IMediaDownloader):
    """
    Media Downloader for YouTube

    Downloads audio (MP3) and video (MP4) files from YouTube.
    Implements async streaming for efficient memory usage.
    """

    def __init__(
        self,
        max_file_size_mb: int = 500,
        download_timeout: int = 300,
        chunk_size: int = 8192,
        storage=None,  # Optional MinIO storage service
        executor: Optional[ThreadPoolExecutor] = None,
        ffmpeg_client: Optional["RemoteFFmpegClient"] = None,
        speech2text_client: Optional["ISpeech2TextClient"] = None,
    ):
        """
        Initialize media downloader

        Args:
            max_file_size_mb: Maximum file size in MB
            download_timeout: Download timeout in seconds
            chunk_size: Download chunk size in bytes
            storage: Optional MinIO storage service
            executor: Thread pool executor for async operations
            ffmpeg_client: Optional remote ffmpeg service client
            speech2text_client: Optional STT service client
        """
        self.max_file_size_mb = max_file_size_mb
        self.download_timeout = download_timeout
        self.chunk_size = chunk_size
        self.storage = storage
        self.executor = executor or ThreadPoolExecutor(max_workers=2)
        self.ffmpeg_client = ffmpeg_client
        self.speech2text_client = speech2text_client

    async def download_media(
        self,
        content: Content,
        media_type: Literal["video", "audio"],
        save_dir: str
    ) -> Optional[str]:
        """
        Download media from YouTube

        Args:
            content: Content entity with download URLs
            media_type: Type of media to download ("video" or "audio")
            save_dir: Directory/prefix to store the file in MinIO

        Returns:
            Absolute path to downloaded file, or None if failed
        """
        logger.info(f"Downloading {media_type} for content {content.external_id}")

        if not self.storage:
            raise RuntimeError("Storage upload requested but storage backend is not configured")

        temp_dir: Optional[Path] = None
        temp_dir = Path(tempfile.mkdtemp(prefix="youtube_media_"))
        download_dir = temp_dir

        try:
            local_path: Optional[str]
            if media_type == "audio":
                local_path = await self._download_audio(content, str(download_dir))
            elif media_type == "video":
                local_path = await self._download_video(content, str(download_dir))
            else:
                logger.error(f"Invalid media_type: {media_type}")
                return None

            if not local_path:
                return None

            final_path = Path(local_path)

            if media_type == "audio":
                if not self.ffmpeg_client:
                    logger.error("Remote FFmpeg client not configured; cannot process audio for %s", content.external_id)
                    return None

                converted_uri = await self._convert_audio_via_service(
                    content=content,
                    source_path=final_path,
                    save_dir=save_dir
                )
                try:
                    if final_path.exists():
                        final_path.unlink()
                except Exception as exc:
                    logger.debug(f"Failed cleaning local file {final_path}: {exc}")

                if not converted_uri:
                    logger.error("Remote FFmpeg conversion failed for %s", content.external_id)
                    return None
                
                # STT transcription after successful conversion
                if self.speech2text_client:
                    try:
                        logger.info(f"Generating presigned URL for {converted_uri}")
                        presigned_url = await self.storage.get_presigned_url(
                            object_uri=converted_uri,
                            expires_hours=168
                        )
                        
                        if presigned_url:
                            logger.info(f"Calling STT API for {content.external_id}")
                            stt_result = await self.speech2text_client.transcribe(
                                audio_url=presigned_url,
                                language="vi",
                                request_id=str(content.external_id)
                            )
                            
                            if stt_result.success:
                                content.transcription = stt_result.transcription
                                content.transcription_status = stt_result.status
                                logger.info(
                                    f"STT completed for {content.external_id}: "
                                    f"status={stt_result.status}, "
                                    f"length={len(stt_result.transcription) if stt_result.transcription else 0} chars"
                                )
                            else:
                                content.transcription = None
                                content.transcription_status = stt_result.status
                                logger.error(
                                    f"STT failed for {content.external_id}: "
                                    f"status={stt_result.status}, "
                                    f"error={stt_result.error_message}"
                                )
                        else:
                            logger.warning(f"Failed to generate presigned URL for {converted_uri}")
                            content.transcription = None
                            content.transcription_status = "PRESIGNED_URL_FAILED"
                    except Exception as stt_error:
                        logger.error(f"STT transcription exception for {content.external_id}: {stt_error}")
                        content.transcription = None
                        content.transcription_status = "EXCEPTION"
                
                return converted_uri

            object_name = self._build_object_name(
                video_id=content.external_id,
                extension=final_path.suffix.lstrip("."),
                prefix=save_dir,
                media_type=media_type
            )
            storage_uri = await self._upload_file_to_storage(final_path, object_name)
            if not storage_uri:
                raise RuntimeError("MinIO upload failed")

            # Local file no longer needed after successful upload
            try:
                if final_path.exists():
                    final_path.unlink()
            except Exception as exc:
                logger.debug(f"Failed cleaning local file {final_path}: {exc}")
            return storage_uri

        except Exception as e:
            logger.error(f"Error downloading {media_type} for content {content.external_id}: {e}")
            return None
        finally:
            if temp_dir:
                try:
                    shutil.rmtree(temp_dir, ignore_errors=True)
                except Exception as cleanup_error:
                    logger.debug(f"Failed to clean temp directory {temp_dir}: {cleanup_error}")

    async def _download_audio(
        self,
        content: Content,
        save_dir: str
    ) -> Optional[str]:
        """
        Download audio (MP3) using yt-dlp

        This uses yt-dlp's built-in download capability which handles
        YouTube's authentication and download restrictions properly.

        Args:
            content: Content entity
            save_dir: Save directory

        Returns:
            Absolute path to downloaded file, or None if failed
        """
        media_type = "video" if self.ffmpeg_client else "audio"
        logger.info(
            "Downloading %s using yt-dlp for content %s",
            media_type,
            content.external_id
        )
        return await self._download_with_ytdlp(
            video_url=content.url,
            video_id=content.external_id,
            media_type=media_type,
            save_dir=save_dir
        )

    async def _download_video(
        self,
        content: Content,
        save_dir: str
    ) -> Optional[str]:
        """
        Download video (MP4) using yt-dlp

        Args:
            content: Content entity
            save_dir: Save directory

        Returns:
            Absolute path to downloaded file, or None if failed
        """
        logger.info(f"Downloading video using yt-dlp for content {content.external_id}")
        return await self._download_with_ytdlp(
            video_url=content.url,
            video_id=content.external_id,
            media_type="video",
            save_dir=save_dir
        )

    async def _download_with_ytdlp(
        self,
        video_url: str,
        video_id: str,
        media_type: Literal["audio", "video"],
        save_dir: str
    ) -> Optional[str]:
        """
        Download media using yt-dlp (handles YouTube auth properly)

        Args:
            video_url: YouTube video URL
            video_id: Video ID
            media_type: "audio" or "video"
            save_dir: Save directory

        Returns:
            Path to downloaded file or None if failed
        """
        try:
            save_path = Path(save_dir)
            save_path.mkdir(parents=True, exist_ok=True)

            # Determine output filename
            extension = "mp3" if media_type == "audio" else "mp4"
            output_template = str(save_path / f"{video_id}.%(ext)s")

            # Configure yt-dlp options with Android client (most reliable for bypassing restrictions)
            ydl_opts = {
                'outtmpl': output_template,
                'quiet': True,
                'no_warnings': True,
                'noprogress': True,
                # Use Android client - most reliable for downloads
                'extractor_args': {
                    'youtube': {
                        'player_client': ['android', 'web'],  # Android first, fallback to web
                        'player_skip': ['webpage'],  # Skip webpage extraction which can be blocked
                    }
                },
                # Basic headers (don't override too much or it breaks)
                'http_headers': {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                },
                # Retry and timeout settings
                'retries': 10,
                'fragment_retries': 10,
                'socket_timeout': 30,
                'sleep_interval_requests': 1,
                'sleep_interval': 1,
                'max_sleep_interval': 5,
                # Skip unavailable fragments
                'ignoreerrors': False,
                'no_check_certificates': True,
            }

            if media_type == "audio":
                # Download audio - use simple format that works reliably
                # Just download best available audio, or worst case a low-res video with audio
                ydl_opts.update({
                    'format': 'bestaudio/best',  # Simple format selection that works
                })
                logger.info(f"Downloading audio for video {video_id}")
            else:
                # Download best video
                ydl_opts.update({
                    'format': 'best',  # Simple format that works
                })
                logger.info(f"Downloading video for {video_id}")

            # Run yt-dlp download in executor (sync -> async)
            try:
                loop = asyncio.get_event_loop()
                await loop.run_in_executor(
                    self.executor,
                    self._ytdlp_download_sync,
                    video_url,
                    ydl_opts
                )
            except asyncio.CancelledError:
                logger.warning(f"Download cancelled for video {video_id}")
                raise
            except Exception as e:
                logger.error(f"Download failed for video {video_id}: {e}")
                raise

            # Find the downloaded file - check for multiple possible extensions
            possible_extensions = [extension, 'm4a', 'webm', 'opus', 'mp4'] if media_type == "audio" else [extension, 'mp4', 'webm']
            final_path = None

            for ext in possible_extensions:
                test_path = save_path / f"{video_id}.{ext}"
                if test_path.exists():
                    final_path = test_path
                    logger.info(f"Found downloaded file: {final_path}")
                    break

            if not final_path:
                # Try glob pattern to find any downloaded file
                import glob
                pattern = str(save_path / f"{video_id}.*")
                matches = glob.glob(pattern)
                if matches:
                    final_path = Path(matches[0])
                    logger.info(f"Found downloaded file via glob: {final_path}")

            if final_path and final_path.exists():
                file_size_mb = final_path.stat().st_size / 1024 / 1024
                logger.info(f"Downloaded {file_size_mb:.2f} MB successfully")
                return str(final_path.absolute())

            logger.error(f"Downloaded file not found in: {save_path}")
            return None

        except Exception as e:
            logger.error(f"yt-dlp download error: {e}")
            return None

    def _ytdlp_download_sync(self, video_url: str, ydl_opts: dict):
        """
        Synchronous yt-dlp download (runs in thread pool)

        Args:
            video_url: YouTube video URL
            ydl_opts: yt-dlp options dict
        """
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([video_url])

    async def _upload_file_to_storage(self, file_path: Path, object_name: str) -> Optional[str]:
        """
        Upload a file to configured storage backend.

        Args:
            file_path: Local file path
            object_name: Desired object name in storage

        Returns:
            Storage URI or None if upload failed.
        """
        if not self.storage:
            return None

        try:
            # Check if async upload is enabled
            # Accessing protected member _enable_async_upload as we are in the same package context logic
            if getattr(self.storage, '_enable_async_upload', False):
                async with aiofiles.open(file_path, 'rb') as f:
                    file_data = await f.read()
                
                task_id = await self.storage.upload_bytes_async(
                    data=file_data,
                    object_name=object_name,
                    content_type=self._guess_mime_type(file_path.suffix)
                )
                
                if task_id:
                    logger.info(f"Queued async upload for {object_name}, waiting for completion...")
                    
                    # Wait for upload to complete before returning URI
                    # This ensures FFmpeg can access the file
                    try:
                        result = await self.storage.wait_for_upload(task_id, timeout=60.0)
                        if result.success:
                            logger.info(f"Async upload completed for {object_name}")
                            return self.storage.object_uri(object_name)
                        else:
                            logger.error(f"Async upload failed for {object_name}: {result.error}")
                            return None
                    except Exception as wait_error:
                        logger.error(f"Error waiting for upload {task_id}: {wait_error}")
                        return None

            # Fallback to sync upload
            storage_uri = await self.storage.upload_file(
                source=file_path,
                object_name=object_name
            )
            if storage_uri:
                logger.info(f"Uploaded to MinIO: {storage_uri}")
            return self.storage.object_uri(storage_uri) if storage_uri else None
        except Exception as exc:
            logger.error(f"MinIO upload failed: {exc}")
            raise

    def _build_object_name(self, video_id: str, extension: str, prefix: str, media_type: str) -> str:
        """
        Build a storage object name using optional prefix.

        Args:
            video_id: Video identifier
            extension: File extension (without dot)
            prefix: Requested save directory/prefix
            media_type: Media type ('audio' or 'video')

        Returns:
            Object name suitable for storage upload.
        """
        filename = f"{video_id}.{extension}"
        normalized_prefix = self._normalize_prefix(prefix)

        parts = []
        if normalized_prefix:
            parts.append(normalized_prefix)
        else:
            parts.append(media_type)
        parts.append(filename)
        return "/".join(part for part in parts if part)

    async def _download_file(
        self,
        url: str,
        video_id: str,
        extension: str,
        save_dir: str,
        use_storage: bool = True
    ) -> Optional[str]:
        """
        Download a file from URL with async streaming

        Args:
            url: Download URL
            video_id: YouTube video ID
            extension: File extension (mp3, mp4)
            save_dir: Directory/prefix for storage
            use_storage: When True and storage backend is configured,
                upload the downloaded file to remote storage and return
                its URI. When False, always return local file path.

        Returns:
            Storage URI or absolute local path, depending on configuration
        """
        safe_filename = self._sanitize_filename(video_id, extension)
        content_type = self._guess_mime_type(extension)
        prefix = save_dir if self.storage else None

        # Determine local path for download (temp file if using storage)
        if self.storage and use_storage:
            temp_dir = Path(tempfile.mkdtemp(prefix="youtube_media_"))
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

                    content_length = response.headers.get('Content-Length')
                    if content_length:
                        size_mb = int(content_length) / (1024 * 1024)
                        if size_mb > self.max_file_size_mb:
                            logger.error(
                                f"File too large: {size_mb:.2f} MB > {self.max_file_size_mb} MB"
                            )
                            return None
                        logger.info(
                            f"Downloading {size_mb:.2f} MB to {local_path}"
                        )

                    async with aiofiles.open(local_path, 'wb') as f:
                        downloaded = 0
                        async for chunk in response.content.iter_chunked(self.chunk_size):
                            if chunk:
                                await f.write(chunk)
                                downloaded += len(chunk)

                    logger.info(
                        f"Downloaded {downloaded / (1024 * 1024):.2f} MB successfully"
                    )

            # Upload to MinIO if configured and requested
            if self.storage and use_storage:
                try:
                    # Build object name with prefix if provided
                    if prefix:
                        normalized_prefix = self._normalize_prefix(prefix)
                        object_name = f"{normalized_prefix}/{safe_filename}" if normalized_prefix else safe_filename
                    else:
                        object_name = safe_filename

                    object_key = await self.storage.upload_file(
                        file_path=str(local_path),
                        object_name=object_name,
                        bucket_name=None  # Use default bucket
                    )
                    if object_key:
                        logger.info(f"Uploaded to MinIO: {object_key}")
                        return object_key
                    else:
                        logger.error("MinIO upload failed, returning local path")
                        return str(local_path.absolute())
                finally:
                    # Clean up temp directory after upload
                    try:
                        shutil.rmtree(local_path.parent, ignore_errors=True)
                    except Exception as cleanup_error:
                        logger.debug(
                            f"Failed to clean temp directory {local_path.parent}: {cleanup_error}"
                        )

            return str(local_path.absolute())

        except asyncio.TimeoutError:
            logger.error(f"Download timeout for video {video_id}")
            return None
        except Exception as e:
            logger.error(f"Error downloading file: {e}")
            return None

    def _parse_minio_uri(self, uri: str) -> tuple[Optional[str], Optional[str]]:
        if not uri.startswith("minio://"):
            return None, None
        path = uri[len("minio://"):]
        if "/" not in path:
            return None, None
        bucket, key = path.split("/", 1)
        return bucket, key

    async def _convert_audio_via_service(
        self,
        content: Content,
        source_path: Path,
        save_dir: str
    ) -> Optional[str]:
        if not self.storage or not self.ffmpeg_client:
            return None

        object_name = self._build_object_name(
            video_id=content.external_id,
            extension=source_path.suffix.lstrip("."),
            prefix=save_dir,
            media_type="video"
        )

        # Use SYNC upload for FFmpeg source files to ensure they're available immediately
        object_name_result = await self.storage.upload_file(
            source=source_path,
            object_name=object_name
        )
        if not object_name_result:
            return None
        
        # Convert to full MinIO URI
        storage_uri = self.storage.object_uri(object_name_result)

        bucket, source_key = self._parse_minio_uri(storage_uri)
        if not bucket or not source_key:
            logger.error("Failed to parse storage URI: %s", storage_uri)
            return None

        target_key = str(PurePosixPath(source_key).with_suffix(".mp3"))

        response = await self.ffmpeg_client.convert_to_mp3(
            video_id=content.external_id,
            source_object=source_key,
            target_object=target_key,
            bucket_source=bucket,
            bucket_target=bucket,
        )
        if not response or "audio_object" not in response or "bucket" not in response:
            logger.error("Invalid response from ffmpeg service for %s: %s", content.external_id, response)
            return None

        logger.info(
            "Remote ffmpeg conversion completed for %s: %s",
            content.external_id,
            response["audio_object"],
        )

        return f"minio://{response['bucket']}/{response['audio_object']}"

    @staticmethod
    def _guess_mime_type(extension: str) -> Optional[str]:
        """
        Return a MIME type for the given file extension if known.

        Args:
            extension: File extension (with or without dot)

        Returns:
            MIME type string or None if not found
        """
        if not extension:
            return None
        ext = extension if extension.startswith(".") else f".{extension}"
        return mimetypes.types_map.get(ext.lower())

    @staticmethod
    def _normalize_prefix(prefix: str) -> str:
        """
        Normalize a directory prefix for object storage usage.

        Args:
            prefix: Directory prefix path

        Returns:
            Normalized prefix without leading/trailing slashes
        """
        if not prefix:
            return ""
        normalized = prefix.replace("\\", "/").strip()
        # Remove leading ./ and redundant slashes
        normalized = re.sub(r"^(\./)+", "", normalized)
        normalized = normalized.strip("/")
        return normalized

    @staticmethod
    def _sanitize_filename(video_id: str, extension: str) -> str:
        """
        Create safe filename from video ID

        Args:
            video_id: YouTube video ID
            extension: File extension

        Returns:
            Sanitized filename
        """
        # YouTube IDs are already safe, but let's be extra careful
        safe_id = "".join(c for c in video_id if c.isalnum() or c in "-_")
        return f"{safe_id}.{extension}"
