"""
MongoDB Repository Implementation (YouTube)
Implements repository interfaces using Motor (async MongoDB driver) following the
refactor_modelDB schema shared with the TikTok service. Provides adapters for
Content, Author, Comment, SearchSession, and CrawlJob repositories.
"""
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pymongo import UpdateOne
from typing import List, Dict, Optional, Any
from datetime import datetime

from domain import Content, Author, Comment, SearchSession, CrawlJob
from domain.enums import SourcePlatform, ParentType
from application.interfaces import (
    IContentRepository,
    IAuthorRepository,
    ICommentRepository,
    IJobRepository,
    ISearchSessionRepository,
)


class MongoContentRepository(IContentRepository):
    """MongoDB implementation of content repository (replaces MongoVideoRepository)."""

    def __init__(self, db: AsyncIOMotorDatabase, logger):
        self.db = db
        self.logger = logger
        self.collection = db.content

    async def upsert_content(self, content: Content) -> bool:
        """Insert or update a content document with smart static/dynamic field handling."""
        try:
            existing = await self.collection.find_one({
                "source": content.source,
                "external_id": content.external_id
            })
            now = datetime.now()
            content_dict = content.model_dump()

            if existing:
                update_data = {
                    k: v for k, v in content_dict.items()
                    if k in Content.get_dynamic_fields()
                }
                update_data["updated_at"] = now
                await self.collection.update_one(
                    {"source": content.source, "external_id": content.external_id},
                    {"$set": update_data}
                )
                self.logger.info(
                    "Updated content %s:%s (dynamic fields only)",
                    content.source,
                    content.external_id
                )
            else:
                content_dict["created_at"] = now
                content_dict["updated_at"] = now
                content_dict["crawled_at"] = content_dict.get("crawled_at") or now
                try:
                    await self.collection.insert_one(content_dict)
                    self.logger.info(
                        "Inserted new content %s:%s",
                        content.source,
                        content.external_id
                    )
                except Exception as insert_error:
                    if "duplicate key" in str(insert_error).lower():
                        self.logger.warning(
                            "Content %s:%s raced insert, retrying update",
                            content.source,
                            content.external_id
                        )
                        update_data = {
                            k: v for k, v in content_dict.items()
                            if k in Content.get_dynamic_fields()
                        }
                        update_data["updated_at"] = now
                        await self.collection.update_one(
                            {"source": content.source, "external_id": content.external_id},
                            {"$set": update_data}
                        )
                    else:
                        raise
            return True
        except Exception as exc:
            self.logger.error("Error upserting content: %s", exc)
            return False

    async def get_content(self, source: str, external_id: str) -> Optional[Dict[str, Any]]:
        """Get content by source and external_id."""
        try:
            return await self.collection.find_one({"source": source, "external_id": external_id})
        except Exception as exc:
            self.logger.error("Error getting content: %s", exc)
            return None

    async def get_content_by_keyword(self, keyword: str, limit: int = 100) -> List[Dict[str, Any]]:
        """Get content by search keyword."""
        try:
            cursor = self.collection.find({"keyword": keyword}).limit(limit)
            return await cursor.to_list(length=limit)
        except Exception as exc:
            self.logger.error("Error getting content by keyword: %s", exc)
            return []


class MongoAuthorRepository(IAuthorRepository):
    """MongoDB implementation of author (channel) repository."""

    def __init__(self, db: AsyncIOMotorDatabase, logger):
        self.db = db
        self.logger = logger
        self.collection = db.authors

    async def upsert_author(self, author: Author) -> bool:
        """Insert or update an author document."""
        try:
            existing = await self.collection.find_one({
                "source": author.source,
                "external_id": author.external_id
            })
            now = datetime.now()
            author_dict = author.model_dump()

            if existing:
                update_data = {
                    k: v for k, v in author_dict.items()
                    if k in Author.get_dynamic_fields()
                }
                update_data["updated_at"] = now
                await self.collection.update_one(
                    {"source": author.source, "external_id": author.external_id},
                    {"$set": update_data}
                )
                self.logger.info(
                    "Updated author %s:%s (dynamic fields only)",
                    author.source,
                    author.external_id
                )
            else:
                author_dict["created_at"] = now
                author_dict["updated_at"] = now
                author_dict["crawled_at"] = author_dict.get("crawled_at") or now
                try:
                    await self.collection.insert_one(author_dict)
                    self.logger.info(
                        "Inserted new author %s:%s",
                        author.source,
                        author.external_id
                    )
                except Exception as insert_error:
                    if "duplicate key" in str(insert_error).lower():
                        self.logger.warning(
                            "Author %s:%s raced insert, retrying update",
                            author.source,
                            author.external_id
                        )
                        update_data = {
                            k: v for k, v in author_dict.items()
                            if k in Author.get_dynamic_fields()
                        }
                        update_data["updated_at"] = now
                        await self.collection.update_one(
                            {"source": author.source, "external_id": author.external_id},
                            {"$set": update_data}
                        )
                    else:
                        raise
            return True
        except Exception as exc:
            self.logger.error("Error upserting author: %s", exc)
            return False

    async def get_author(self, source: str, external_id: str) -> Optional[Dict[str, Any]]:
        """Get author by source and external_id."""
        try:
            return await self.collection.find_one({"source": source, "external_id": external_id})
        except Exception as exc:
            self.logger.error("Error getting author: %s", exc)
            return None


class MongoCommentRepository(ICommentRepository):
    """MongoDB implementation of comment repository."""

    def __init__(self, db: AsyncIOMotorDatabase, logger):
        self.db = db
        self.logger = logger
        self.collection = db.comments

    async def upsert_comments(self, comments: List[Comment]) -> bool:
        """Bulk upsert comments with ordered static/dynamic handling."""
        if not comments:
            return True

        operations = []
        now = datetime.now()

        for comment in comments:
            comment_dict = comment.model_dump()
            comment_dict.setdefault("crawled_at", now)
            comment_dict.setdefault("created_at", now)
            comment_dict.setdefault("source", SourcePlatform.YOUTUBE)

            operations.append(UpdateOne(
                {"source": comment_dict["source"], "external_id": comment_dict["external_id"]},
                {
                    "$setOnInsert": {
                        "created_at": comment_dict["created_at"],
                        "parent_type": comment_dict["parent_type"],
                        "parent_id": comment_dict["parent_id"],
                        "job_id": comment_dict.get("job_id"),
                    },
                    "$set": {
                        **{k: v for k, v in comment_dict.items() if k in Comment.get_dynamic_fields()},
                        "updated_at": now,
                    }
                },
                upsert=True
            ))

        try:
            if operations:
                await self.collection.bulk_write(operations, ordered=False)
            return True
        except Exception as exc:
            self.logger.error("Error upserting comments: %s", exc)
            return False

    async def get_comments_by_parent(self, parent_id: str, limit: int = 1000) -> List[Dict[str, Any]]:
        """Get comments for a content/comment parent."""
        try:
            cursor = self.collection.find({"parent_id": parent_id}).limit(limit)
            return await cursor.to_list(length=limit)
        except Exception as exc:
            self.logger.error("Error getting comments by parent: %s", exc)
            return []


class MongoSearchSessionRepository(ISearchSessionRepository):
    """MongoDB implementation for search session persistence."""

    def __init__(self, db: AsyncIOMotorDatabase, logger):
        self.db = db
        self.logger = logger
        self.collection = db.search_sessions

    async def save_search_session(self, session: SearchSession) -> bool:
        """Insert/update a search session entry."""
        try:
            session_dict = session.model_dump()
            session_dict["updated_at"] = datetime.now()
            await self.collection.update_one(
                {"search_id": session.search_id},
                {"$set": session_dict},
                upsert=True
            )
            return True
        except Exception as exc:
            self.logger.error("Error saving search session: %s", exc)
            return False

    async def get_search_sessions_by_keyword(self, keyword: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Retrieve search sessions for a keyword."""
        try:
            cursor = self.collection.find({"keyword": keyword}).limit(limit)
            return await cursor.to_list(length=limit)
        except Exception as exc:
            self.logger.error("Error getting search sessions: %s", exc)
            return []


class MongoCrawlJobRepository:
    """MongoDB implementation for crawl job persistence."""

    def __init__(self, db: AsyncIOMotorDatabase, logger):
        self.db = db
        self.logger = logger
        self.collection = db.crawl_jobs

    async def create_job(self, job: CrawlJob) -> bool:
        """
        Create a crawl job with idempotency handling.
        
        If job with same idempotency_key exists:
        - If status is QUEUED/RUNNING: return True (skip, job already running)
        - If status is FAILED: return True (allow retry)
        - If status is COMPLETED: return True (skip, already completed)
        """
        try:
            # Check if job already exists by idempotency_key
            existing_job = await self.collection.find_one(
                {"idempotency_key": job.idempotency_key}
            )
            
            if existing_job:
                existing_status = existing_job.get("status")
                self.logger.info(
                    "Job with idempotency_key '%s' already exists with status '%s'. Skipping creation.",
                    job.idempotency_key,
                    existing_status
                )
                # Job already exists - return True to allow processing to continue
                # The existing job will be updated to RUNNING status in handle_task
                return True
            
            # Job doesn't exist, create new one
            job_dict = job.model_dump()
            job_dict["created_at"] = datetime.now()
            job_dict["updated_at"] = datetime.now()
            await self.collection.insert_one(job_dict)
            self.logger.info("Created new crawl job with idempotency_key '%s'", job.idempotency_key)
            return True
        except Exception as exc:
            # Handle duplicate key error gracefully (race condition)
            if "duplicate key" in str(exc).lower() or "E11000" in str(exc):
                self.logger.warning(
                    "Duplicate key error for idempotency_key '%s' (race condition). Job may already exist.",
                    job.idempotency_key
                )
                # Check if job actually exists now
                existing_job = await self.collection.find_one(
                    {"idempotency_key": job.idempotency_key}
                )
                if existing_job:
                    self.logger.info(
                        "Job with idempotency_key '%s' exists. Allowing processing to continue.",
                        job.idempotency_key
                    )
                    return True
            self.logger.error("Error creating crawl job: %s", exc)
            return False

    async def update_job_status(
        self,
        job_id: str,
        status: str,
        error_message: Optional[str] = None
    ) -> bool:
        try:
            update_data = {
                "status": status,
                "updated_at": datetime.now(),
            }
            if error_message:
                update_data["error_msg"] = error_message
            await self.collection.update_one(
                {"job_id": job_id},
                {"$set": update_data}
            )
            return True
        except Exception as exc:
            self.logger.error("Error updating crawl job %s: %s", job_id, exc)
            return False

    async def get_job_by_id(self, job_id: str) -> Optional[Dict[str, Any]]:
        try:
            return await self.collection.find_one({"job_id": job_id})
        except Exception as exc:
            self.logger.error("Error getting crawl job %s: %s", job_id, exc)
            return None

    async def update_job_results(self, job_id: str, result_urls: List[str]) -> bool:
        """Update job results with MinIO object keys"""
        try:
            update_data = {
                "result": result_urls,
                "updated_at": datetime.now()
            }
            
            result = await self.collection.update_one(
                {"job_id": job_id},
                {"$set": update_data}
            )
            
            return result.modified_count > 0
        except Exception as exc:
            self.logger.error("Error updating job results for %s: %s", job_id, exc)
            return False



class MongoRepository(IJobRepository, ISearchSessionRepository):
    """
    Main MongoDB repository combining all repository interfaces. Keeps backwards
    compatibility while migrating to the new Clean Architecture naming.
    """

    def __init__(self, default_max_retries: int = 3):
        self.client: Optional[AsyncIOMotorClient] = None
        self.db: Optional[AsyncIOMotorDatabase] = None
        self.logger = None
        self.content_repo: Optional[MongoContentRepository] = None
        self.author_repo: Optional[MongoAuthorRepository] = None
        self.comment_repo: Optional[MongoCommentRepository] = None
        self.search_session_repo: Optional[MongoSearchSessionRepository] = None
        self.crawl_job_repo: Optional[MongoCrawlJobRepository] = None
        self.default_max_retries = default_max_retries

    def _init_logger(self):
        if self.logger is None:
            from utils.logger import logger
            self.logger = logger

    async def connect(self, mongodb_url: str, mongodb_database: str):
        """Connect to MongoDB and initialize repositories."""
        self._init_logger()
        try:
            self.logger.info("Connecting to MongoDB database: %s", mongodb_database)
            self.client = AsyncIOMotorClient(mongodb_url)
            self.db = self.client[mongodb_database]
            await self.client.admin.command("ping")
            self.logger.info("Connected to MongoDB database: %s", mongodb_database)

            self.content_repo = MongoContentRepository(self.db, self.logger)
            self.author_repo = MongoAuthorRepository(self.db, self.logger)
            self.comment_repo = MongoCommentRepository(self.db, self.logger)
            self.search_session_repo = MongoSearchSessionRepository(self.db, self.logger)
            self.crawl_job_repo = MongoCrawlJobRepository(self.db, self.logger)

            await self._create_indexes()
        except Exception as exc:
            self.logger.error("Failed to connect to MongoDB: %s", exc)
            raise

    async def close(self):
        if self.client is not None:
            self.client.close()
            if self.logger:
                self.logger.info("MongoDB connection closed")

    async def _create_indexes(self):
        """Create indexes for the unified schema."""
        try:
            await self.db.content.create_index(
                [("source", 1), ("external_id", 1)],
                unique=True,
                name="content_source_external_id_unique"
            )
            await self.db.content.create_index("author_id")
            await self.db.content.create_index("published_at")
            await self.db.content.create_index([("keyword", 1), ("source", 1)])

            await self.db.authors.create_index(
                [("source", 1), ("external_id", 1)],
                unique=True,
                name="authors_source_external_id_unique"
            )
            await self.db.authors.create_index("username")

            await self.db.comments.create_index(
                [("source", 1), ("external_id", 1)],
                unique=True,
                name="comments_source_external_id_unique"
            )
            await self.db.comments.create_index([("parent_id", 1), ("published_at", 1)])

            await self.db.search_sessions.create_index("search_id", unique=True)

            await self.db.crawl_jobs.create_index("status")
            await self.db.crawl_jobs.create_index([("task_type", 1), ("status", 1)])
            await self.db.crawl_jobs.create_index("idempotency_key", unique=True, sparse=True)
            await self.db.crawl_jobs.create_index("created_at")

            if self.logger:
                self.logger.info("MongoDB indexes created successfully")
        except Exception as exc:
            if self.logger:
                self.logger.warning("Error creating indexes (non-critical): %s", exc)

    # ---- Delegation helpers ----

    async def upsert_content(self, content: Content) -> bool:
        return await self.content_repo.upsert_content(content)

    async def get_content(self, source: str, external_id: str) -> Optional[Dict[str, Any]]:
        return await self.content_repo.get_content(source, external_id)

    async def get_content_by_keyword(self, keyword: str, limit: int = 100) -> List[Dict[str, Any]]:
        return await self.content_repo.get_content_by_keyword(keyword, limit)

    async def upsert_author(self, author: Author) -> bool:
        return await self.author_repo.upsert_author(author)

    async def get_author(self, source: str, external_id: str) -> Optional[Dict[str, Any]]:
        return await self.author_repo.get_author(source, external_id)

    async def upsert_comments(self, comments: List[Comment]) -> bool:
        return await self.comment_repo.upsert_comments(comments)

    async def get_comments_by_parent(self, parent_id: str, limit: int = 1000) -> List[Dict[str, Any]]:
        return await self.comment_repo.get_comments_by_parent(parent_id, limit)

    async def save_search_session(self, session: SearchSession) -> bool:
        return await self.search_session_repo.save_search_session(session)

    async def get_search_sessions_by_keyword(self, keyword: str, limit: int = 50) -> List[Dict[str, Any]]:
        return await self.search_session_repo.get_search_sessions_by_keyword(keyword, limit)

    # ---- Crawl job helpers ----

    async def create_job(
        self,
        job_id: str,
        task_type: str,
        payload: Dict[str, Any],
        time_range: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None
    ) -> bool:
        if self.db is None:
            raise RuntimeError("MongoRepository not connected. Call connect() first.")
        try:
            from domain.enums import JobType, JobStatus
            job = CrawlJob(
                task_type=JobType(task_type),
                status=JobStatus.QUEUED,
                job_id=job_id,
                payload_json=payload,
                time_range=time_range,
                since_date=since_date,
                until_date=until_date,
                max_retry=payload.get("max_retries", self.default_max_retries),
                idempotency_key=f"{job_id}_{task_type}"
            )
            return await self.crawl_job_repo.create_job(job)
        except Exception as exc:
            if self.logger:
                self.logger.error("Error creating job %s: %s", job_id, exc)
            return False

    async def update_job_status(
        self,
        job_id: str,
        status: str,
        error_message: Optional[str] = None
    ) -> bool:
        return await self.crawl_job_repo.update_job_status(job_id, status, error_message)

    async def get_job(self, job_id: str) -> Optional[Dict[str, Any]]:
        return await self.crawl_job_repo.get_job_by_id(job_id)

    async def update_job_results(self, job_id: str, result_urls: List[str]) -> bool:
        """Update job results with MinIO object keys"""
        return await self.crawl_job_repo.update_job_results(job_id, result_urls)


    async def get_stats(self) -> Dict[str, Any]:
        """Return simple collection counts for monitoring."""
        try:
            return {
                "content": await self.db.content.count_documents({}),
                "authors": await self.db.authors.count_documents({}),
                "comments": await self.db.comments.count_documents({}),
                "search_sessions": await self.db.search_sessions.count_documents({}),
                "crawl_jobs": await self.db.crawl_jobs.count_documents({})
            }
        except Exception as exc:
            if self.logger:
                self.logger.error("Error getting MongoDB stats: %s", exc)
            return {}
