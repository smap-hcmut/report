"""Media conversion service using FFmpeg."""

import io
import logging
import subprocess
from contextlib import suppress
from typing import BinaryIO, Optional

from minio import Minio
from minio.error import S3Error

from core.config import Settings
from domain.entities import ConversionJob, MediaFile, ConversionResult
from domain.enums import AudioFormat, AudioQuality
from models.exceptions import (
    FFmpegExecutionError,
    InvalidMediaError,
    StorageAccessError,
    StorageNotFoundError,
    TransientConversionError,
)

logger = logging.getLogger(__name__)


class MediaConverter:
    """Handles media conversion by orchestrating FFmpeg and MinIO interactions."""

    def __init__(self, minio_client: Minio, settings: Settings) -> None:
        self.client = minio_client
        self.settings = settings

    def _build_presigned_url(self, bucket: str, object_name: str) -> str:
        """Generate a presigned URL for the source object."""
        try:
            return self.client.presigned_get_object(
                bucket,
                object_name,
                expires=self.settings.presigned_expiry(),
            )
        except S3Error as e:
            if e.code == "NoSuchKey":
                raise StorageNotFoundError(
                    f"Source file not found: {bucket}/{object_name}",
                    bucket=bucket,
                    object_key=object_name,
                    operation="presigned_get",
                ) from e
            raise StorageAccessError(
                f"Failed to generate presigned URL: {e}",
                bucket=bucket,
                object_key=object_name,
                operation="presigned_get",
            ) from e

    def _build_target_key(self, video_id: str, target_object: Optional[str]) -> str:
        """Build the target object key."""
        if target_object:
            return target_object
        prefix = self.settings.minio_target_prefix.rstrip("/")
        return f"{prefix}/{video_id}.mp3" if prefix else f"{video_id}.mp3"

    def _build_ffmpeg_command(
        self,
        input_url: str,
        audio_quality: AudioQuality,
    ) -> list[str]:
        """Build the FFmpeg command for MP4 to MP3 conversion."""
        return [
            self.settings.ffmpeg_path,
            "-nostdin",
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            input_url,
            "-vn",  # No video
            "-acodec",
            "libmp3lame",
            "-b:a",
            audio_quality.value,
            "-f",
            "mp3",
            "-",  # Output to stdout
        ]

    def _execute_ffmpeg(
        self,
        command: list[str],
        video_id: str,
    ) -> subprocess.Popen:
        """Execute FFmpeg subprocess."""
        logger.debug(f"[{video_id}] Starting FFmpeg conversion")

        try:
            process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                bufsize=0,
            )
        except FileNotFoundError as e:
            raise FFmpegExecutionError(
                "FFmpeg binary not found. Is FFmpeg installed?",
                video_id=video_id,
            ) from e
        except Exception as e:
            raise FFmpegExecutionError(
                f"Failed to spawn FFmpeg process: {e}",
                video_id=video_id,
            ) from e

        if process.stdout is None or process.stderr is None:
            raise FFmpegExecutionError(
                "Failed to capture FFmpeg stdout/stderr",
                video_id=video_id,
            )

        return process

    def _upload_to_minio(
        self,
        stream: BinaryIO,
        bucket: str,
        object_key: str,
        video_id: str,
    ) -> None:
        """Upload the converted audio to MinIO."""
        try:
            self.client.put_object(
                bucket,
                object_key,
                data=stream,
                length=-1,
                part_size=self.settings.minio_upload_part_size,
                content_type="audio/mpeg",
            )
            logger.debug(f"[{video_id}] Uploaded to {bucket}/{object_key}")
        except S3Error as e:
            raise StorageAccessError(
                f"Failed to upload converted file: {e}",
                bucket=bucket,
                object_key=object_key,
                operation="put_object",
                video_id=video_id,
            ) from e

    def _wait_for_completion(
        self,
        process: subprocess.Popen,
        video_id: str,
    ) -> tuple[int, str]:
        """Wait for FFmpeg to complete and return exit code and stderr."""
        try:
            return_code = process.wait(timeout=self.settings.ffmpeg_timeout_seconds)
        except subprocess.TimeoutExpired:
            process.kill()
            with suppress(Exception):
                if process.stderr:
                    process.stderr.close()
            raise TransientConversionError(
                f"FFmpeg timed out after {self.settings.ffmpeg_timeout_seconds} seconds",
                video_id=video_id,
            )

        stderr_output = ""
        if process.stderr:
            stderr_output = process.stderr.read().decode("utf-8", errors="ignore")
            with suppress(Exception):
                process.stderr.close()

        return return_code, stderr_output

    def convert_to_mp3(
        self,
        *,
        video_id: str,
        source_object: str,
        bucket_source: Optional[str] = None,
        bucket_target: Optional[str] = None,
        target_object: Optional[str] = None,
        audio_quality: AudioQuality = AudioQuality.MEDIUM,
    ) -> tuple[str, str]:
        """
        Convert a source object to MP3 and upload the result.

        Returns the (bucket, object_key) for the generated MP3.

        Raises:
            StorageNotFoundError: Source file not found
            StorageAccessError: MinIO connection issues
            FFmpegExecutionError: FFmpeg execution failed
            InvalidMediaError: Invalid or corrupted media file
            TransientConversionError: Temporary failure (timeout, network)
        """
        source_bucket = bucket_source or self.settings.minio_bucket_source
        target_bucket = bucket_target or self.settings.minio_bucket_target
        target_key = self._build_target_key(video_id, target_object)

        logger.info(
            f"[{video_id}] Converting {source_bucket}/{source_object} "
            f"to {target_bucket}/{target_key}"
        )

        # Generate presigned URL for source
        presigned_url = self._build_presigned_url(source_bucket, source_object)

        # Build FFmpeg command
        command = self._build_ffmpeg_command(presigned_url, audio_quality)

        # Execute FFmpeg
        process = self._execute_ffmpeg(command, video_id)

        # Upload output stream to MinIO
        try:
            if process.stdout:
                mp3_stream: BinaryIO = io.BufferedReader(process.stdout)
                self._upload_to_minio(mp3_stream, target_bucket, target_key, video_id)
        finally:
            with suppress(Exception):
                if process.stdout:
                    process.stdout.close()

        # Wait for FFmpeg to complete
        return_code, stderr_output = self._wait_for_completion(process, video_id)

        # Check for errors
        if return_code != 0:
            # Try to classify the error
            stderr_lower = stderr_output.lower()

            if any(
                keyword in stderr_lower
                for keyword in ["invalid", "corrupt", "unsupported", "no decoder"]
            ):
                raise InvalidMediaError(
                    f"Invalid or unsupported media file",
                    video_id=video_id,
                    details={"stderr": stderr_output, "exit_code": return_code},
                )

            raise FFmpegExecutionError(
                f"FFmpeg conversion failed",
                video_id=video_id,
                return_code=return_code,
                stderr=stderr_output,
            )

        logger.info(f"[{video_id}] Conversion completed successfully")
        return target_bucket, target_key

    def convert_job(self, job: ConversionJob) -> ConversionResult:
        """
        Execute a conversion job and return the result.

        This is a higher-level interface using domain entities.
        """
        try:
            job.start()

            target_bucket, target_key = self.convert_to_mp3(
                video_id=job.video_id,
                source_object=job.source.object_key,
                bucket_source=job.source.bucket,
                bucket_target=job.target_bucket,
                target_object=job.target_key,
                audio_quality=job.audio_quality,
            )

            output_file = MediaFile(
                bucket=target_bucket,
                object_key=target_key,
                format=AudioFormat.MP3,
            )

            result = ConversionResult.success_result(
                output_file=output_file,
                duration=job.duration_seconds or 0.0,
                bitrate=job.audio_quality.value,
            )

            job.complete(result)
            return result

        except Exception as e:
            error_msg = str(e)
            job.fail(error_msg)

            return ConversionResult.failure_result(
                error=error_msg,
                ffmpeg_stderr=getattr(e, "stderr", None),
            )
