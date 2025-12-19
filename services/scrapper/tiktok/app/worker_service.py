"""
Worker Service - Clean Architecture Worker
Orchestrates the worker process with proper dependency injection

This replaces the old TikTokWorker with Clean Architecture approach:
- Uses Bootstrap for dependency injection
- Uses TaskService from application layer
- Integrates with RabbitMQ consumer
"""
import asyncio
import signal
import sys
from datetime import datetime
from typing import Optional

from config import settings
from utils.logger import logger
from .bootstrap import Bootstrap


class WorkerService:
    """
    Worker service that orchestrates the entire worker process

    Responsibilities:
    1. Initialize all dependencies via Bootstrap
    2. Connect to message queue
    3. Process incoming tasks via TaskService
    4. Handle graceful shutdown
    """

    def __init__(self):
        self.bootstrap: Optional[Bootstrap] = None
        self.consumer = None  # Will be RabbitMQ consumer
        self.shutdown_event = asyncio.Event()
        self.logger = logger

    async def startup(self):
        """
        Complete startup sequence
        1. Initialize bootstrap (DI container)
        2. Initialize message queue consumer
        """
        try:
            self.logger.info("=" * 70)
            self.logger.info("WORKER SERVICE: STARTING UP")
            self.logger.info("=" * 70)
            self.logger.info(f"Worker Name: {settings.worker_name}")
            self.logger.info(f"Environment: {settings.app_env}")
            self.logger.info(f"Log Level: {settings.log_level}")
            self.logger.info(f"Max Concurrent: {settings.crawler_max_concurrent}")
            self.logger.info(f"Media Downloads: Enabled")
            self.logger.info(f"Media Download Dir: {settings.media_download_dir}")
            self.logger.info(f"Media Default Type: {settings.media_default_type}")
            self.logger.info("=" * 70)

            # Step 1: Bootstrap (initialize all dependencies)
            self.bootstrap = Bootstrap()
            await self.bootstrap.startup()

            # Step 2: Initialize message queue consumer
            await self._init_consumer()

            self.logger.info("=" * 70)
            self.logger.info("WORKER SERVICE: STARTUP COMPLETE")
            self.logger.info("=" * 70)

        except Exception as e:
            self.logger.error(f"Worker startup failed: {e}")
            raise

    async def _init_consumer(self):
        """Initialize RabbitMQ consumer with TaskService"""
        try:
            self.logger.info("=" * 70)
            self.logger.info("INITIALIZING RABBITMQ CONSUMER")
            self.logger.info("=" * 70)

            # Import here to avoid circular dependency
            from internal.infrastructure.rabbitmq.consumer import RabbitMQConsumer

            # Get task service from bootstrap
            task_service = self.bootstrap.get_task_service()

            # Create consumer with task service
            self.consumer = RabbitMQConsumer(
                task_service=task_service,
                job_repo=self.bootstrap.mongo_repo
            )

            # Connect to RabbitMQ
            await self.consumer.connect()

            self.logger.info("RabbitMQ consumer initialized successfully")

        except Exception as e:
            self.logger.error(f"Failed to initialize consumer: {e}")
            raise

    async def run(self):
        """
        Main worker loop
        1. Start consuming messages from queue
        2. Wait for shutdown signal
        3. Cleanup gracefully
        """
        try:
            self.logger.info("=" * 70)
            self.logger.info("WORKER READY - WAITING FOR MESSAGES")
            self.logger.info("=" * 70)

            # Start consuming messages in background
            consume_task = asyncio.create_task(self.consumer.start_consuming())

            # Wait for shutdown signal
            await self.shutdown_event.wait()

            # Stop consuming
            self.logger.info("Shutdown signal received, stopping consumer...")
            await self.consumer.stop_consuming()

            # Wait for consume task to finish
            await consume_task

        except Exception as e:
            self.logger.error(f"Error in worker run loop: {e}")
            raise

        finally:
            await self.shutdown()

    async def shutdown(self):
        """
        Graceful shutdown
        1. Close message queue consumer
        2. Shutdown bootstrap (cleanup all resources)
        """
        try:
            self.logger.info("=" * 70)
            self.logger.info("WORKER SERVICE: SHUTTING DOWN")
            self.logger.info("=" * 70)

            # Close consumer
            if self.consumer:
                await self.consumer.close()

            # Shutdown bootstrap (closes database, etc.)
            if self.bootstrap:
                await self.bootstrap.shutdown()

            self.logger.info("Worker shutdown complete")

        except Exception as e:
            self.logger.error(f"Error during worker shutdown: {e}")

    def handle_shutdown(self, sig):
        """Handle shutdown signals (SIGINT, SIGTERM)"""
        self.logger.info(f"Received signal {sig}, initiating graceful shutdown...")
        self.shutdown_event.set()


async def main():
    """
    Main entry point for the worker

    This is the new Clean Architecture entry point that:
    1. Creates WorkerService
    2. Handles signals
    3. Runs the worker
    """

    # Print startup banner
    print("=" * 70)
    print("TIKTOK CRAWLER WORKER - CLEAN ARCHITECTURE")
    print("=" * 70)
    print(f"Version: 3.0 (Clean Architecture + Media Downloads)")
    print(f"Started at: {datetime.now().isoformat()}")
    print("=" * 70)
    print()

    # Create worker service
    worker = WorkerService()

    # Setup signal handlers (only on Unix-like systems)
    if sys.platform != 'win32':
        loop = asyncio.get_event_loop()
        # Handle SIGINT (Ctrl+C) and SIGTERM
        for sig in (signal.SIGINT, signal.SIGTERM):
            loop.add_signal_handler(
                sig,
                lambda s=sig: worker.handle_shutdown(s)
            )

    try:
        # Startup
        await worker.startup()

        # Run worker
        await worker.run()

    except KeyboardInterrupt:
        logger.info("Received keyboard interrupt")
        worker.handle_shutdown("SIGINT")

    except Exception as e:
        logger.error(f"Fatal error in worker: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

    finally:
        logger.info("=" * 70)
        logger.info("WORKER SHUTDOWN COMPLETE")
        logger.info("=" * 70)


if __name__ == "__main__":
    # Run worker
    asyncio.run(main())
