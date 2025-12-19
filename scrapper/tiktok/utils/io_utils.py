"""
File I/O Utilities
Helper functions for file and directory operations
"""
import re
import aiofiles
from pathlib import Path
from typing import Optional


def sanitize_filename(filename: str, max_length: int = 255) -> str:
    """
    Sanitize filename by removing invalid characters

    Args:
        filename: Original filename
        max_length: Maximum filename length (default: 255)

    Returns:
        Sanitized filename safe for filesystem

    Examples:
        >>> sanitize_filename("hello@world!.txt")
        "helloworld.txt"
        >>> sanitize_filename("my/bad\\file:name.mp3")
        "mybadfilename.mp3"
    """
    # Remove any characters that aren't alphanumeric, dash, underscore, or period
    safe_name = re.sub(r'[^a-zA-Z0-9_\-.]', '', filename)

    # Remove leading/trailing dots and spaces
    safe_name = safe_name.strip('. ')

    # Ensure it's not empty
    if not safe_name:
        safe_name = "file"

    # Limit length
    if len(safe_name) > max_length:
        # Try to preserve extension
        name_parts = safe_name.rsplit('.', 1)
        if len(name_parts) == 2:
            name, ext = name_parts
            # Reserve space for extension + dot
            max_name_length = max_length - len(ext) - 1
            safe_name = f"{name[:max_name_length]}.{ext}"
        else:
            safe_name = safe_name[:max_length]

    return safe_name


def ensure_dir_exists(directory: str) -> Path:
    """
    Ensure directory exists, create if it doesn't

    Args:
        directory: Directory path (string or Path)

    Returns:
        Path object of the directory

    Examples:
        >>> ensure_dir_exists("./downloads/audio")
        PosixPath('downloads/audio')
    """
    dir_path = Path(directory)
    dir_path.mkdir(parents=True, exist_ok=True)
    return dir_path


def get_file_size_mb(file_path: str) -> float:
    """
    Get file size in megabytes

    Args:
        file_path: Path to file

    Returns:
        File size in MB, or 0 if file doesn't exist

    Examples:
        >>> get_file_size_mb("/path/to/file.mp3")
        4.5
    """
    try:
        path = Path(file_path)
        if path.exists():
            size_bytes = path.stat().st_size
            return size_bytes / (1024 * 1024)
        return 0.0
    except Exception:
        return 0.0


def is_valid_file_path(file_path: str, must_exist: bool = False) -> bool:
    """
    Check if file path is valid

    Args:
        file_path: Path to check
        must_exist: If True, also check if file exists

    Returns:
        True if valid, False otherwise

    Examples:
        >>> is_valid_file_path("/path/to/file.mp3")
        True
        >>> is_valid_file_path("/path/to/file.mp3", must_exist=True)
        False  # if file doesn't exist
    """
    try:
        path = Path(file_path)

        # Check if path is valid
        if not path.is_absolute() and not path.exists():
            # Relative paths are OK
            pass

        # Check if file exists if required
        if must_exist:
            return path.exists() and path.is_file()

        return True
    except Exception:
        return False


async def read_file_async(file_path: str, mode: str = 'r') -> Optional[str]:
    """
    Read file asynchronously

    Args:
        file_path: Path to file
        mode: File mode ('r' for text, 'rb' for binary)

    Returns:
        File contents or None if error

    Examples:
        >>> await read_file_async("/path/to/file.txt")
        "file contents"
    """
    try:
        async with aiofiles.open(file_path, mode) as f:
            contents = await f.read()
            return contents
    except Exception:
        return None


async def write_file_async(
    file_path: str,
    content: str,
    mode: str = 'w',
    ensure_dir: bool = True
) -> bool:
    """
    Write file asynchronously

    Args:
        file_path: Path to file
        content: Content to write
        mode: File mode ('w' for text, 'wb' for binary)
        ensure_dir: If True, create parent directory if needed

    Returns:
        True if successful, False otherwise

    Examples:
        >>> await write_file_async("/path/to/file.txt", "hello world")
        True
    """
    try:
        path = Path(file_path)

        # Ensure parent directory exists
        if ensure_dir:
            path.parent.mkdir(parents=True, exist_ok=True)

        async with aiofiles.open(file_path, mode) as f:
            await f.write(content)

        return True
    except Exception:
        return False


def get_file_extension(file_path: str) -> str:
    """
    Get file extension from path

    Args:
        file_path: Path to file

    Returns:
        File extension (without dot), or empty string if none

    Examples:
        >>> get_file_extension("/path/to/file.mp3")
        "mp3"
        >>> get_file_extension("/path/to/file")
        ""
    """
    path = Path(file_path)
    ext = path.suffix.lstrip('.')
    return ext


def join_paths(*paths: str) -> str:
    """
    Join path components in a cross-platform way

    Args:
        *paths: Path components to join

    Returns:
        Joined path as string

    Examples:
        >>> join_paths("downloads", "audio", "file.mp3")
        "downloads/audio/file.mp3"  # or "downloads\\audio\\file.mp3" on Windows
    """
    return str(Path(*paths))


def get_absolute_path(file_path: str) -> str:
    """
    Get absolute path from relative or absolute path

    Args:
        file_path: Path (relative or absolute)

    Returns:
        Absolute path as string

    Examples:
        >>> get_absolute_path("./downloads/file.mp3")
        "/full/path/to/downloads/file.mp3"
    """
    return str(Path(file_path).absolute())


def create_unique_filename(directory: str, base_name: str, extension: str) -> str:
    """
    Create unique filename by appending number if file exists

    Args:
        directory: Directory path
        base_name: Base filename (without extension)
        extension: File extension (without dot)

    Returns:
        Unique filename (not full path, just filename)

    Examples:
        >>> create_unique_filename("/downloads", "audio", "mp3")
        "audio.mp3"  # or "audio_1.mp3" if audio.mp3 exists
    """
    dir_path = Path(directory)
    counter = 0

    while True:
        if counter == 0:
            filename = f"{base_name}.{extension}"
        else:
            filename = f"{base_name}_{counter}.{extension}"

        file_path = dir_path / filename

        if not file_path.exists():
            return filename

        counter += 1

        # Safety limit to prevent infinite loop
        if counter > 1000:
            # Fallback to timestamp-based unique name
            import time
            timestamp = int(time.time() * 1000)
            return f"{base_name}_{timestamp}.{extension}"
