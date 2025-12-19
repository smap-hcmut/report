"""
Simple logging utility for YouTube scraper
"""
import logging
import sys
from datetime import datetime
from pathlib import Path


def setup_logger(name='youtube_crawler', level=logging.INFO):
    """
    Setup logger with console and file output

    Args:
        name: Logger name
        level: Logging level

    Returns:
        Configured logger instance
    """
    logger = logging.getLogger(name)
    logger.setLevel(level)

    # Avoid duplicate handlers
    if logger.handlers:
        return logger

    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level)
    console_format = logging.Formatter(
        '%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    console_handler.setFormatter(console_format)
    logger.addHandler(console_handler)

    # File handler
    log_file = f'logs/crawler_{datetime.now().strftime("%Y%m%d")}.log'
    try:
        import os
        os.makedirs('logs', exist_ok=True)
        file_handler = logging.FileHandler(log_file, encoding='utf-8')
        file_handler.setLevel(level)
        file_handler.setFormatter(console_format)
        logger.addHandler(file_handler)
    except Exception as e:
        logger.warning(f"Could not create log file: {e}")

    return logger


# Default logger instance
logger = setup_logger()
