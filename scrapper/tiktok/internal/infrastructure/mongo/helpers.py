"""
MongoDB Infrastructure Helpers
Shared MongoDB utilities and helper functions
"""
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)


class MongoConnectionManager:
    """
    Manages MongoDB connection lifecycle

    This is a shared utility for MongoDB connections
    that ensures proper connection pooling and cleanup.
    """

    def __init__(self, connection_url: str, database_name: str):
        self.connection_url = connection_url
        self.database_name = database_name
        self.client: Optional[AsyncIOMotorClient] = None
        self.db: Optional[AsyncIOMotorDatabase] = None

    async def connect(self) -> AsyncIOMotorDatabase:
        """Establish connection to MongoDB"""
        try:
            self.client = AsyncIOMotorClient(self.connection_url)
            self.db = self.client[self.database_name]

            # Test connection
            await self.client.admin.command('ping')
            logger.info(f"Connected to MongoDB: {self.database_name}")

            return self.db
        except Exception as e:
            logger.error(f"Failed to connect to MongoDB: {e}")
            raise

    async def close(self):
        """Close MongoDB connection"""
        if self.client:
            self.client.close()
            logger.info("MongoDB connection closed")

    def get_database(self) -> AsyncIOMotorDatabase:
        """Get database instance"""
        if not self.db:
            raise RuntimeError("Not connected to MongoDB. Call connect() first.")
        return self.db


async def create_indexes_for_collection(
    db: AsyncIOMotorDatabase,
    collection_name: str,
    indexes: list[Dict[str, Any]]
):
    """
    Helper to create multiple indexes for a collection

    Args:
        db: MongoDB database instance
        collection_name: Name of collection
        indexes: List of index specifications

    Example:
        await create_indexes_for_collection(
            db,
            "videos",
            [
                {"keys": [("video_id", 1)], "unique": True},
                {"keys": [("created_at", -1)]},
            ]
        )
    """
    collection = db[collection_name]

    for index_spec in indexes:
        keys = index_spec.get("keys")
        options = {k: v for k, v in index_spec.items() if k != "keys"}

        try:
            await collection.create_index(keys, **options)
            logger.debug(f"Created index on {collection_name}: {keys}")
        except Exception as e:
            logger.warning(f"Error creating index on {collection_name}: {e}")


async def bulk_upsert(
    collection,
    documents: list[Dict],
    key_field: str = "_id"
) -> Dict[str, int]:
    """
    Helper for bulk upsert operations

    Args:
        collection: MongoDB collection
        documents: List of documents to upsert
        key_field: Field to use as unique key

    Returns:
        Dict with counts: {"inserted": int, "updated": int, "errors": int}
    """
    from pymongo import UpdateOne

    if not documents:
        return {"inserted": 0, "updated": 0, "errors": 0}

    operations = []
    for doc in documents:
        filter_query = {key_field: doc[key_field]}
        operations.append(
            UpdateOne(
                filter_query,
                {"$set": doc},
                upsert=True
            )
        )

    try:
        result = await collection.bulk_write(operations, ordered=False)
        return {
            "inserted": result.upserted_count,
            "updated": result.modified_count,
            "errors": 0
        }
    except Exception as e:
        logger.error(f"Bulk upsert error: {e}")
        # Try to extract partial success info
        error_str = str(e)
        return {
            "inserted": 0,
            "updated": 0,
            "errors": 1
        }
