"""API routes for FFmpeg conversion service."""

import logging
import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import JSONResponse
from minio import Minio
from starlette.concurrency import run_in_threadpool

from core.concurrency import with_semaphore
from core.dependencies import get_converter, get_minio_client
from models.exceptions import (
    InvalidMediaError,
    PermanentConversionError,
    StorageNotFoundError,
    TransientConversionError,
)
from models.payloads import ConversionRequest, ConversionResponse, ErrorResponse
from services.converter import MediaConverter

logger = logging.getLogger(__name__)

router = APIRouter(default_response_class=JSONResponse)


@router.get("/health")
async def health_check(
    minio_client: Annotated[Minio, Depends(get_minio_client)],
):
    """
    Health check endpoint.

    Verifies that the service is running and can connect to MinIO.
    """
    health_status = {"status": "ok", "checks": {}}

    # Check MinIO connectivity
    try:
        # Simple bucket list to verify connectivity
        list(minio_client.list_buckets())
        health_status["checks"]["minio"] = "connected"
    except Exception as e:
        health_status["status"] = "degraded"
        health_status["checks"]["minio"] = f"error: {str(e)}"
        logger.warning(f"MinIO health check failed: {e}")

    return health_status


@router.post(
    "/convert",
    response_model=ConversionResponse,
    responses={
        status.HTTP_400_BAD_REQUEST: {"model": ErrorResponse},
        status.HTTP_404_NOT_FOUND: {"model": ErrorResponse},
        status.HTTP_500_INTERNAL_SERVER_ERROR: {"model": ErrorResponse},
        status.HTTP_503_SERVICE_UNAVAILABLE: {"model": ErrorResponse},
    },
)
async def convert_media(
    payload: ConversionRequest,
    converter: Annotated[MediaConverter, Depends(get_converter)],
    _=Depends(with_semaphore),
):
    """
    Convert MP4 video to MP3 audio.

    This endpoint:
    1. Fetches the source video from MinIO
    2. Converts it to MP3 using FFmpeg
    3. Uploads the result back to MinIO
    4. Returns the location of the converted file

    Error codes:
    - 400: Invalid media file (corrupted, unsupported format)
    - 404: Source file not found in MinIO
    - 500: Internal conversion error (FFmpeg failure)
    - 503: Temporary failure (timeout, network issues) - can retry
    """
    correlation_id = str(uuid.uuid4())
    logger.info(
        f"[{correlation_id}] Conversion request for video_id={payload.video_id}, "
        f"source={payload.source_object}"
    )

    try:
        target_bucket, target_key = await run_in_threadpool(
            converter.convert_to_mp3,
            video_id=payload.video_id,
            source_object=payload.source_object,
            bucket_source=payload.bucket_source,
            bucket_target=payload.bucket_target,
            target_object=payload.target_object,
        )

        logger.info(
            f"[{correlation_id}] Conversion succeeded for video_id={payload.video_id}, "
            f"output={target_bucket}/{target_key}"
        )

        return ConversionResponse(
            status="success",
            video_id=payload.video_id,
            audio_object=target_key,
            bucket=target_bucket,
        )

    except StorageNotFoundError as exc:
        logger.error(
            f"[{correlation_id}] Source file not found for video_id={payload.video_id}: {exc}"
        )
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Source file not found: {exc.message}",
        ) from exc

    except InvalidMediaError as exc:
        logger.error(
            f"[{correlation_id}] Invalid media for video_id={payload.video_id}: {exc}"
        )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid or unsupported media file: {exc.message}",
        ) from exc

    except TransientConversionError as exc:
        logger.warning(
            f"[{correlation_id}] Transient error for video_id={payload.video_id}: {exc}. "
            "Client should retry."
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Temporary conversion failure (retry recommended): {exc.message}",
        ) from exc

    except PermanentConversionError as exc:
        logger.error(
            f"[{correlation_id}] Permanent error for video_id={payload.video_id}: {exc}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Conversion failed: {exc.message}",
        ) from exc

    except Exception as exc:
        logger.exception(
            f"[{correlation_id}] Unexpected error for video_id={payload.video_id}: {exc}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during conversion",
        ) from exc
