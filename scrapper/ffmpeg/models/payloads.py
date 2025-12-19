from typing import Optional

from pydantic import BaseModel, Field


class ConversionRequest(BaseModel):
    video_id: str = Field(..., description="Logical identifier of the video.")
    source_object: str = Field(..., description="MinIO object key for the source media (MP4).")
    target_object: Optional[str] = Field(
        default=None, description="Optional MinIO object key for the generated MP3. Defaults to prefix/video_id.mp3."
    )
    bucket_source: Optional[str] = Field(
        default=None, description="Optional source bucket override. Defaults to configured minio_bucket_source."
    )
    bucket_target: Optional[str] = Field(
        default=None, description="Optional target bucket override. Defaults to configured minio_bucket_target."
    )


class ConversionResponse(BaseModel):
    status: str = Field(..., description="Conversion result status.")
    video_id: str = Field(..., description="Identifier of the processed video.")
    audio_object: str = Field(..., description="Object key where the MP3 is stored.")
    bucket: str = Field(..., description="Bucket containing the MP3 object.")
    message: Optional[str] = Field(default=None, description="Optional diagnostic message.")


class ErrorResponse(BaseModel):
    detail: str
