import sys
from pathlib import Path

# Add project root to sys.path to allow running as script
# This resolves imports like 'cmd.api', 'services', 'core'
ROOT_DIR = Path(__file__).resolve().parent.parent.parent
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from cmd.api.routes import router, init_browser, close_browser

# Configure basic logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for application startup and shutdown.
    """
    # Startup
    logger.info("Playwright API Service starting up...")
    await init_browser()
    
    yield
    
    # Shutdown
    logger.info("Playwright API Service shutting down...")
    await close_browser()

app = FastAPI(
    title="Playwright API Service",
    description="Service to wrap Playwright functionalities with FastAPI.",
    version="0.1.0",
    lifespan=lifespan,
)

app.include_router(router)

@app.get("/health")
async def health_check():
    return {"status": "ok", "message": "Playwright API Service is running."}

if __name__ == "__main__":
    import uvicorn
    # Run the server directly
    uvicorn.run(app, host="0.0.0.0", port=8001)
