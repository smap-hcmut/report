"""
MongoDB Repository Implementation
Implements repository interfaces using Motor (async MongoDB driver)

Clean Architecture Adapter:
- Implements repository interfaces for Content, Author, Comment, SearchSession, CrawlJob
- Uses domain entities instead of database models
- Smart upsert logic: static fields on insert, dynamic fields on update
- Updated to match refactor_modelDB.md schema
"""
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pymongo import InsertOne, UpdateOne
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
    """MongoDB implementation of content repository (replaces VideoRepository)"""

    def __init__(self, db: AsyncIOMotorDatabase, logger):
        self.db = db
        self.logger = logger
        self.collection = db.content  # Changed from db.videos

    async def upsert_content(self, content: Content) -> bool:
        """
        Upsert content with smart update logic
        - If content exists: only update dynamic fields
        - If content is new: insert all fields
        - Automatically sets source="TIKTOK" for TikTok content

        Args:
            content: Content entity to persist

        Returns:
            True if successful
        """
        try:
            # Check if content exists in DB (by source + external_id)
            existing = await self.collection.find_one({
                "source": content.source,
                "external_id": content.external_id
            })
            now = datetime.now()

            # Convert Content entity to dict
            content_dict = content.model_dump()

            if existing:
                # Content exists -> update only dynamic fields
                dynamic_fields = Content.get_dynamic_fields()

                update_data = {k: v for k, v in content_dict.items() if k in dynamic_fields}
                update_data["updated_at"] = now

                await self.collection.update_one(
                    {"source": content.source, "external_id": content.external_id},
                    {"$set": update_data}
                )
                self.logger.info(f"Updated content {content.source}:{content.external_id} (dynamic fields only)")
            else:
                # New content -> insert all fields
                content_dict["created_at"] = now
                content_dict["updated_at"] = now
                content_dict["crawled_at"] = now

                try:
                    await self.collection.insert_one(content_dict)
                    self.logger.info(f"Inserted new content {content.source}:{content.external_id}")
                except Exception as insert_error:
                    # Handle duplicate key error (race condition)
                    if "duplicate key" in str(insert_error).lower():
                        self.logger.warning(
                            f"Content {content.source}:{content.external_id} was inserted by another process, updating instead"
                        )
                        # Retry with update
                        dynamic_fields = Content.get_dynamic_fields()
                        update_data = {k: v for k, v in content_dict.items() if k in dynamic_fields}
                        update_data["updated_at"] = now
                        await self.collection.update_one(
                            {"source": content.source, "external_id": content.external_id},
                            {"$set": update_data}
                        )
                    else:
                        raise

            return True
        except Exception as e:
            self.logger.error(f"Error upserting content: {e}")
            return False

    async def get_content(self, source: str, external_id: str) -> Optional[Dict[str, Any]]:
        """Get content by source and external_id"""
        try:
            content = await self.collection.find_one({"source": source, "external_id": external_id})
            return content
        except Exception as e:
            self.logger.error(f"Error getting content: {e}")
            return None

    async def get_content_by_keyword(self, keyword: str, limit: int = 100) -> List[Dict[str, Any]]:
        """Get content by search keyword"""
        try:
            cursor = self.collection.find({"keyword": keyword}).limit(limit)
            content_list = await cursor.to_list(length=limit)
            return content_list
        except Exception as e:
            self.logger.error(f"Error getting content by keyword: {e}")
            return []


class MongoAuthorRepository(IAuthorRepository):
    """MongoDB implementation of author repository (replaces CreatorRepository)"""

    def __init__(self, db: AsyncIOMotorDatabase, logger):
        self.db = db
        self.logger = logger
        self.collection = db.authors  # Changed from db.creators

    async def upsert_author(self, author: Author) -> bool:
        """
        Upsert author with smart update logic
        - If author exists: only update dynamic fields
        - If author is new: insert all fields
        - Automatically sets source="TIKTOK" for TikTok authors

        Args:
            author: Author entity to persist

        Returns:
            True if successful
        """
        try:
            existing = await self.collection.find_one({
                "source": author.source,
                "external_id": author.external_id
            })
            now = datetime.now()

            # Convert Author entity to dict
            author_dict = author.model_dump()

            if existing:
                # Author exists -> update only dynamic fields
                dynamic_fields = Author.get_dynamic_fields()

                update_data = {k: v for k, v in author_dict.items() if k in dynamic_fields}
                update_data["updated_at"] = now

                await self.collection.update_one(
                    {"source": author.source, "external_id": author.external_id},
                    {"$set": update_data}
                )
                self.logger.info(f"Updated author {author.source}:{author.external_id} (dynamic fields only)")
            else:
                # New author -> insert all fields
                author_dict["created_at"] = now
                author_dict["updated_at"] = now
                author_dict["crawled_at"] = now

                try:
                    await self.collection.insert_one(author_dict)
                    self.logger.info(f"Inserted new author {author.source}:{author.external_id}")
                except Exception as insert_error:
                    # Handle duplicate key error (race condition)
                    if "duplicate key" in str(insert_error).lower():
                        self.logger.warning(
                            f"Author {author.source}:{author.external_id} was inserted by another process, updating instead"
                        )
                        # Retry with update
                        dynamic_fields = Author.get_dynamic_fields()
                        update_data = {k: v for k, v in author_dict.items() if k in dynamic_fields}
                        update_data["updated_at"] = now
                        await self.collection.update_one(
                            {"source": author.source, "external_id": author.external_id},
                            {"$set": update_data}
                        )
                    else:
                        raise

            return True
        except Exception as e:
            self.logger.error(f"Error upserting author: {e}")
            return False

    async def get_author(self, source: str, external_id: str) -> Optional[Dict[str, Any]]:
        """Get author by source and external_id"""
        try:
            author = await self.collection.find_one({"source": source, "external_id": external_id})
            return author
        except Exception as e:
            self.logger.error(f"Error getting author: {e}")
            return None


class MongoCommentRepository(ICommentRepository):
    """MongoDB implementation of comment repository"""

    def __init__(self, db: AsyncIOMotorDatabase, logger):
        self.db = db
        self.logger = logger
        self.collection = db.comments

    async def upsert_comments(self, comments: List[Comment]) -> bool:
        """
        Bulk upsert comments with smart update logic
        - Existing comments: update only dynamic fields (like_count, reply_count)
        - New comments: insert all fields
        - Automatically sets source="TIKTOK" and parent_type="CONTENT"

        Args:
            comments: List of Comment entities

        Returns:
            True if successful
        """
        if not comments:
            return True

        try:
            now = datetime.now()

            # Step 1: Deduplicate comments within batch (keep last occurrence)
            # Use composite key (source, external_id) since external_id can duplicate across platforms
            unique_comments = {}
            for comment in comments:
                composite_key = (comment.source, comment.external_id)
                unique_comments[composite_key] = comment

            comments = list(unique_comments.values())
            self.logger.debug(f"Deduplicated {len(unique_comments)} unique comments from batch")

            # Step 2: Get existing comment composite keys from DB
            # Build $or query for each (source, external_id) pair
            or_conditions = [
                {"source": c.source, "external_id": c.external_id}
                for c in comments
            ]

            if or_conditions:
                existing_docs = await self.collection.find(
                    {"$or": or_conditions},
                    {"source": 1, "external_id": 1}
                ).to_list(length=len(comments))
                # Store as set of tuples (source, external_id)
                existing_keys = {(doc["source"], doc["external_id"]) for doc in existing_docs}
            else:
                existing_keys = set()

            # Step 3: Prepare bulk operations
            operations = []
            dynamic_fields = Comment.get_dynamic_fields()

            for comment in comments:
                comment_dict = comment.model_dump()
                composite_key = (comment.source, comment.external_id)

                if composite_key in existing_keys:
                    # Existing comment -> update dynamic fields only
                    update_data = {k: v for k, v in comment_dict.items() if k in dynamic_fields}
                    update_data["updated_at"] = now

                    operations.append(
                        UpdateOne(
                            filter={"source": comment.source, "external_id": comment.external_id},
                            update={"$set": update_data}
                        )
                    )
                else:
                    # New comment -> insert all fields
                    comment_dict["created_at"] = now
                    comment_dict["updated_at"] = now
                    comment_dict["crawled_at"] = now

                    operations.append(
                        InsertOne(document=comment_dict)
                    )

            if operations:
                try:
                    result = await self.collection.bulk_write(operations, ordered=False)
                    self.logger.info(f"Upserted {len(comments)} comments to MongoDB")
                except Exception as bulk_error:
                    # Handle partial success in bulk write
                    if "writeErrors" in str(bulk_error):
                        error_str = str(bulk_error)
                        # Extract success count from error message
                        if "nInserted" in error_str:
                            self.logger.warning(f"Bulk write partially successful: {bulk_error}")
                            self.logger.info("Some comments saved despite errors (duplicate key conflicts)")
                        else:
                            raise
                    else:
                        raise

            return True
        except Exception as e:
            self.logger.error(f"Error upserting comments: {e}")
            return False

    async def get_comments_by_parent(self, parent_id: str, limit: int = 1000) -> List[Dict[str, Any]]:
        """Get comments for a parent (content or comment)"""
        try:
            cursor = self.collection.find({"parent_id": parent_id}).limit(limit)
            comments = await cursor.to_list(length=limit)
            return comments
        except Exception as e:
            self.logger.error(f"Error getting comments: {e}")
            return []


class MongoSearchSessionRepository(ISearchSessionRepository):
    """MongoDB implementation for search session persistence (replaces SearchResultRepository)"""

    def __init__(self, db: AsyncIOMotorDatabase, logger):
        self.db = db
        self.logger = logger
        self.collection = db.search_sessions  # Changed from db.search_results

    async def save_search_session(self, session: SearchSession) -> bool:
        """Insert or update a search session entry"""
        try:
            session_dict = session.model_dump()
            await self.collection.update_one(
                {"search_id": session.search_id},
                {"$set": session_dict},
                upsert=True
            )
            if self.logger:
                self.logger.info(f"Saved search session for keyword '{session.keyword}'")
            return True
        except Exception as e:
            if self.logger:
                self.logger.error(f"Error saving search session {session.search_id}: {e}")
            return False

    async def get_search_sessions_by_keyword(self, keyword: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Retrieve recent search sessions for a keyword"""
        try:
            cursor = self.collection.find({"keyword": keyword}).sort("searched_at", -1).limit(limit)
            return await cursor.to_list(length=limit)
        except Exception as e:
            if self.logger:
                self.logger.error(f"Error retrieving search sessions for '{keyword}': {e}")
            return []


class MongoCrawlJobRepository:
    """MongoDB implementation for crawl job persistence (adapted from PostgreSQL schema)"""

    def __init__(self, db: AsyncIOMotorDatabase, logger):
        self.db = db
        self.logger = logger
        self.collection = db.crawl_jobs  # Changed from db.jobs

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
                if self.logger:
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
            # MongoDB will auto-generate _id if not provided
            if "id" in job_dict:
                del job_dict["id"]  # Let MongoDB generate _id

            await self.collection.insert_one(job_dict)
            if self.logger:
                self.logger.info(f"Created crawl job for task_type '{job.task_type}' with idempotency_key '{job.idempotency_key}'")
            return True
        except Exception as e:
            # Handle duplicate key error gracefully (race condition)
            if "duplicate key" in str(e).lower() or "E11000" in str(e):
                if self.logger:
                    self.logger.warning(
                        "Duplicate key error for idempotency_key '%s' (race condition). Job may already exist.",
                        job.idempotency_key
                    )
                # Check if job actually exists now
                existing_job = await self.collection.find_one(
                    {"idempotency_key": job.idempotency_key}
                )
                if existing_job:
                    if self.logger:
                        self.logger.info(
                            "Job with idempotency_key '%s' exists. Allowing processing to continue.",
                            job.idempotency_key
                        )
                    return True
            if self.logger:
                self.logger.error(f"Error creating crawl job: {e}")
            return False

    async def update_job_status(self, job_id: str, status: str, error_msg: Optional[str] = None) -> bool:
        """Update job status by job_id (external service tracking ID)"""
        try:
            update_data = {
                "status": status,
                "updated_at": datetime.now()
            }

            if status == "COMPLETED":
                update_data["completed_at"] = datetime.now()
            elif status == "FAILED":
                if error_msg:
                    update_data["error_msg"] = error_msg
                # Increment retry_count
                await self.collection.update_one(
                    {"job_id": job_id},
                    {
                        "$set": update_data,
                        "$inc": {"retry_count": 1}
                    }
                )
                return True

            result = await self.collection.update_one(
                {"job_id": job_id},
                {"$set": update_data}
            )
            return result.modified_count > 0
        except Exception as e:
            if self.logger:
                self.logger.error(f"Error updating job status: {e}")
            return False

    async def get_job_by_id(self, job_id: str) -> Optional[Dict[str, Any]]:
        """Get job by external job_id"""
        try:
            return await self.collection.find_one({"job_id": job_id})
        except Exception as e:
            if self.logger:
                self.logger.error(f"Error getting job: {e}")
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
            
            if self.logger:
                self.logger.info(f"Updated job {job_id} with {len(result_urls)} result URLs")
            
            return result.modified_count > 0
        except Exception as e:
            if self.logger:
                self.logger.error(f"Error updating job results: {e}")
            return False



class MongoRepository(IJobRepository, ISearchSessionRepository):
    """
    Main MongoDB repository that combines all repository interfaces
    This maintains compatibility with existing code while using new Clean Architecture
    Updated to match refactor_modelDB.md schema
    """

    def __init__(self, default_max_retries: int = 3):
        self.client: Optional[AsyncIOMotorClient] = None
        self.db: Optional[AsyncIOMotorDatabase] = None
        self.logger = None

        # Repository instances (initialized after connect)
        self.content_repo: Optional[MongoContentRepository] = None  # Changed from video_repo
        self.author_repo: Optional[MongoAuthorRepository] = None  # Changed from creator_repo
        self.comment_repo: Optional[MongoCommentRepository] = None
        self.search_session_repo: Optional[MongoSearchSessionRepository] = None  # Changed from search_result_repo
        self.crawl_job_repo: Optional[MongoCrawlJobRepository] = None  # New
        self.default_max_retries = default_max_retries

    def _init_logger(self):
        """Initialize logger (lazy loading to avoid import issues)"""
        if self.logger is None:
            from utils.logger import logger
            self.logger = logger

    async def connect(self, mongodb_url: str, mongodb_database: str):
        """Connect to MongoDB"""
        self._init_logger()

        try:
            self.logger.info(f"Connecting to MongoDB database: {mongodb_database}")
            self.client = AsyncIOMotorClient(mongodb_url)
            self.db = self.client[mongodb_database]

            # Test connection
            await self.client.admin.command('ping')
            self.logger.info(f"Successfully connected to MongoDB database: {mongodb_database}")

            # Initialize repository instances with new names
            self.content_repo = MongoContentRepository(self.db, self.logger)
            self.author_repo = MongoAuthorRepository(self.db, self.logger)
            self.comment_repo = MongoCommentRepository(self.db, self.logger)
            self.search_session_repo = MongoSearchSessionRepository(self.db, self.logger)
            self.crawl_job_repo = MongoCrawlJobRepository(self.db, self.logger)

            # Create indexes
            await self._create_indexes()

        except Exception as e:
            self.logger.error(f"Failed to connect to MongoDB: {e}")
            raise

    async def close(self):
        """Close MongoDB connection"""
        if self.client is not None:
            self.client.close()
            if self.logger:
                self.logger.info("MongoDB connection closed")

    async def _create_indexes(self):
        """Create indexes for better query performance (exact from refactor_modelDB.md)"""
        try:
            # Content collection indexes
            await self.db.content.create_index(
                [("source", 1), ("external_id", 1)],
                unique=True,
                name="content_source_external_id_unique"
            )
            await self.db.content.create_index("author_id")
            await self.db.content.create_index("published_at")
            await self.db.content.create_index([("keyword", 1), ("source", 1)])

            # Authors collection indexes
            await self.db.authors.create_index(
                [("source", 1), ("external_id", 1)],
                unique=True,
                name="authors_source_external_id_unique"
            )
            await self.db.authors.create_index("username")

            # Comments collection indexes
            await self.db.comments.create_index(
                [("source", 1), ("external_id", 1)],
                unique=True,
                name="comments_source_external_id_unique"
            )
            await self.db.comments.create_index([("parent_id", 1), ("published_at", 1)])

            # Search sessions collection indexes
            await self.db.search_sessions.create_index("search_id", unique=True)

            # Crawl jobs collection indexes
            await self.db.crawl_jobs.create_index("status")
            await self.db.crawl_jobs.create_index([("task_type", 1), ("status", 1)])
            await self.db.crawl_jobs.create_index("idempotency_key", unique=True, sparse=True)
            await self.db.crawl_jobs.create_index("created_at")

            if self.logger:
                self.logger.info("MongoDB indexes created successfully")

        except Exception as e:
            if self.logger:
                self.logger.warning(f"Error creating indexes (non-critical): {e}")

    # ========== Compatibility/Delegation Methods ==========

    async def upsert_content(self, content: Content) -> bool:
        """Upsert content (delegates to content repository)"""
        return await self.content_repo.upsert_content(content)

    async def get_content(self, source: str, external_id: str) -> Optional[Dict]:
        """Get content by source and external_id"""
        return await self.content_repo.get_content(source, external_id)

    async def get_content_by_keyword(self, keyword: str, limit: int = 100) -> List[Dict]:
        """Get content by keyword"""
        return await self.content_repo.get_content_by_keyword(keyword, limit)

    async def upsert_author(self, author: Author) -> bool:
        """Upsert author (delegates to author repository)"""
        return await self.author_repo.upsert_author(author)

    async def get_author(self, source: str, external_id: str) -> Optional[Dict]:
        """Get author by source and external_id"""
        return await self.author_repo.get_author(source, external_id)

    async def upsert_comments(self, comments: List[Comment]) -> bool:
        """Upsert comments (delegates to comment repository)"""
        return await self.comment_repo.upsert_comments(comments)

    async def get_comments_by_parent(self, parent_id: str, limit: int = 1000) -> List[Dict]:
        """Get comments for parent"""
        return await self.comment_repo.get_comments_by_parent(parent_id, limit)

    async def save_search_session(self, session: SearchSession) -> bool:
        """Save search session (delegates to search session repository)"""
        return await self.search_session_repo.save_search_session(session)

    async def get_search_sessions_by_keyword(self, keyword: str, limit: int = 50) -> List[Dict]:
        """Get search sessions by keyword"""
        return await self.search_session_repo.get_search_sessions_by_keyword(keyword, limit)

    # ========== Crawl Job Repository Methods ==========

    async def create_job(
        self,
        job_id: str,
        task_type: str,
        payload: Dict[str, Any],
        time_range: Optional[int] = None,
        since_date: Optional[datetime] = None,
        until_date: Optional[datetime] = None
    ) -> bool:
        """Create a crawl job"""
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
        except Exception as e:
            if self.logger:
                self.logger.error(f"Error creating job {job_id}: {e}")
            return False

    async def update_job_status(
        self,
        job_id: str,
        status: str,
        error_message: Optional[str] = None
    ) -> bool:
        """Update job status"""
        return await self.crawl_job_repo.update_job_status(job_id, status, error_message)

    async def get_job(self, job_id: str) -> Optional[Dict[str, Any]]:
        """Get job by external job_id"""
        return await self.crawl_job_repo.get_job_by_id(job_id)

    async def update_job_results(self, job_id: str, result_urls: List[str]) -> bool:
        """Update job results with MinIO object keys"""
        return await self.crawl_job_repo.update_job_results(job_id, result_urls)


    # ========== Utility Methods ==========

    async def get_stats(self) -> Dict:
        """Get database statistics"""
        try:
            stats = {
                "content": await self.db.content.count_documents({}),
                "authors": await self.db.authors.count_documents({}),
                "comments": await self.db.comments.count_documents({}),
                "search_sessions": await self.db.search_sessions.count_documents({}),
                "crawl_jobs": await self.db.crawl_jobs.count_documents({})
            }
            return stats
        except Exception as e:
            if self.logger:
                self.logger.error(f"Error getting stats: {e}")
            return {}
