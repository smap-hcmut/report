"""
Crawl Job Entity - Domain Layer
Represents a job for orchestrating crawl tasks
Adapted from PostgreSQL crawl_jobs table to MongoDB, exact schema from refactor_modelDB.md
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from ..enums import JobType, JobStatus


class CrawlJob(BaseModel):
    """
    Crawl job entity

    Represents a job for orchestrating scraping tasks with retry logic
    and idempotency. Adapted to MongoDB (uses _id for id field).
    Exact schema from refactor_modelDB.md.
    """

    # Identifiers
    # Note: 'id' will be MongoDB _id (ObjectId, auto-generated)
    # 'job_id' is the external service tracking ID
    task_type: JobType = Field(..., description="Job task type (SEARCH_BY_KEYWORD, FETCH_CONTENT_DETAIL, etc.)")
    status: JobStatus = Field(JobStatus.QUEUED, description="Job status (QUEUED, RUNNING, RETRYING, COMPLETED, FAILED, CANCELED)")
    job_id: Optional[str] = Field(None, description="External service job ID for cross-service tracking")

    # Job configuration
    payload_json: dict = Field(default_factory=dict, description="Job payload for worker (JSONB/object in MongoDB)")
    time_range: Optional[int] = Field(
        default=None,
        ge=1,
        description="Publish window in days (only persist content published within the last N days)"
    )
    since_date: Optional[datetime] = Field(
        default=None,
        description="Filter content published after this date (inclusive)"
    )
    until_date: Optional[datetime] = Field(
        default=None,
        description="Filter content published before this date (inclusive)"
    )
    max_retry: int = Field(3, description="Maximum retry attempts")
    retry_count: int = Field(0, description="Current retry attempt count")
    error_msg: Optional[str] = Field(None, description="Error message if failed")

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.now, description="Job creation timestamp")
    updated_at: datetime = Field(default_factory=datetime.now, description="Last update timestamp")
    completed_at: Optional[datetime] = Field(None, description="Job completion timestamp")

    # Idempotency
    idempotency_key: Optional[str] = Field(None, description="Unique key to prevent duplicate job processing")
    
    # Results
    result: Optional[List[str]] = Field(default_factory=list, description="Array of MinIO object keys for uploaded content items")

    def is_completed(self) -> bool:
        """Check if job is completed"""
        return self.status == JobStatus.COMPLETED

    def is_failed(self) -> bool:
        """Check if job is failed"""
        return self.status == JobStatus.FAILED

    def is_running(self) -> bool:
        """Check if job is running"""
        return self.status == JobStatus.RUNNING

    def can_retry(self) -> bool:
        """Check if job can be retried"""
        return self.retry_count < self.max_retry and self.status == JobStatus.FAILED

    def increment_retry(self) -> None:
        """Increment retry count and set status to RETRYING"""
        self.retry_count += 1
        self.status = JobStatus.RETRYING
        self.updated_at = datetime.now()

    def mark_running(self) -> None:
        """Mark job as running"""
        self.status = JobStatus.RUNNING
        self.updated_at = datetime.now()

    def mark_completed(self) -> None:
        """Mark job as completed"""
        self.status = JobStatus.COMPLETED
        self.completed_at = datetime.now()
        self.updated_at = datetime.now()

    def mark_failed(self, error_message: str) -> None:
        """Mark job as failed with error message"""
        self.status = JobStatus.FAILED
        self.error_msg = error_message
        self.updated_at = datetime.now()

    def mark_canceled(self) -> None:
        """Mark job as canceled"""
        self.status = JobStatus.CANCELED
        self.updated_at = datetime.now()

    class Config:
        """Pydantic configuration"""
        populate_by_name = True
        use_enum_values = True
        json_schema_extra = {
            "example": {
                "task_type": "SEARCH_BY_KEYWORD",
                "status": "QUEUED",
                "job_id": "job-uuid-123",
                "payload_json": {
                    "keyword": "gaming highlights",
                    "sort_by": "LIKE",
                    "count": 50,
                    "time_range": 7
                },
                "time_range": 7,
                "max_retry": 3,
                "retry_count": 0,
                "error_msg": None,
                "created_at": "2025-11-10T10:00:00",
                "updated_at": "2025-11-10T10:00:00",
                "completed_at": None,
                "idempotency_key": "search-gaming-highlights-20251110"
            }
        }
