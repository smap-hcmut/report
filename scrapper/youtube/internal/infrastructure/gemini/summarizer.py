"""Gemini AI summarization service for YouTube videos."""

from __future__ import annotations

import json
import logging
import re
from typing import Any, Dict, Optional

import google.generativeai as genai
from youtube_transcript_api import (
    NoTranscriptFound,
    TranscriptsDisabled,
    VideoUnavailable,
    YouTubeTranscriptApi,
)

logger = logging.getLogger(__name__)

_YOUTUBE_ID_REGEX = re.compile(r"(?:v=|\/)([0-9A-Za-z_-]{11})")


class GeminiSummarizer:
    """Service for generating AI summaries of YouTube videos using Gemini."""

    def __init__(
        self,
        api_key: str,
        model_name: str = "gemini-2.5-flash",
        transcript_languages: list[str] = None,
        timeout: int = 120,
    ):
        """Initialize the Gemini summarizer.

        Args:
            api_key: Gemini API key
            model_name: Gemini model to use
            transcript_languages: Preferred transcript languages
            timeout: Request timeout in seconds
        """
        self.api_key = api_key
        self.model_name = model_name
        self.transcript_languages = transcript_languages or ["en", "vi", "en-US", "en-GB", "vi-VN"]
        self.timeout = timeout

        # Configure Gemini
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel(model_name)

        logger.info(f"GeminiSummarizer initialized with model: {model_name}")

    async def summarize_video(
        self,
        url: str,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Optional[str]:
        """Generate a text summary for a YouTube video.

        Args:
            url: YouTube video URL
            metadata: Optional video metadata (title, channel, duration, etc.)

        Returns:
            Summary text (overview) or None if generation fails

        Raises:
            Exception: If summarization fails
        """
        try:
            video_id = self._extract_video_id(url)
            logger.info(f"Generating summary for video: {video_id}")

            # 1. Try to fetch transcript
            transcript_text: Optional[str] = None
            transcript_language: Optional[str] = None
            transcript_error: Optional[str] = None

            try:
                transcript_result = self._fetch_transcript(video_id)
                transcript_text = transcript_result["text"]
                transcript_language = transcript_result["language"]
                logger.info(
                    f"Transcript fetched: {len(transcript_text)} chars, "
                    f"language={transcript_language}"
                )
            except Exception as exc:
                transcript_error = str(exc)
                logger.warning(f"Transcript unavailable: {transcript_error}")

            # 2. Generate summary using Gemini
            prompt = self._build_prompt(
                metadata=metadata or {},
                transcript_text=transcript_text,
                transcript_language=transcript_language,
                transcript_error=transcript_error,
            )

            # Call Gemini API (sync call in async context)
            response = self.model.generate_content(prompt)
            raw_text = (response.text or "").strip()

            # 3. Parse response
            summary_text = self._extract_overview(raw_text)

            logger.info(f"Summary generated successfully: {len(summary_text)} chars")
            return summary_text

        except Exception as exc:
            logger.error(f"Summary generation failed for {url}: {exc}")
            raise

    def _extract_video_id(self, url: str) -> str:
        """Extract video ID from YouTube URL.

        Args:
            url: YouTube URL

        Returns:
            Video ID

        Raises:
            ValueError: If video ID cannot be extracted
        """
        match = _YOUTUBE_ID_REGEX.search(url)
        if not match:
            raise ValueError(f"Could not parse video ID from URL: {url}")
        return match.group(1)

    def _fetch_transcript(self, video_id: str) -> Dict[str, str]:
        """Fetch video transcript using YouTube Transcript API.

        Args:
            video_id: YouTube video ID

        Returns:
            Dictionary with 'text' and 'language' keys

        Raises:
            Exception: If transcript cannot be fetched
        """
        try:
            transcript = YouTubeTranscriptApi.get_transcript(
                video_id, languages=self.transcript_languages
            )
            text = " ".join(
                chunk["text"].strip() for chunk in transcript if chunk.get("text")
            )
            language = (
                transcript[0].get("language_code", self.transcript_languages[0])
                if transcript
                else self.transcript_languages[0]
            )

            return {"text": text, "language": language}
        except (TranscriptsDisabled, NoTranscriptFound, VideoUnavailable, Exception) as exc:
            raise Exception(f"Transcript unavailable: {str(exc)}") from exc

    def _build_prompt(
        self,
        metadata: Dict[str, Any],
        transcript_text: Optional[str],
        transcript_language: Optional[str],
        transcript_error: Optional[str],
    ) -> str:
        """Build prompt for Gemini AI.

        Args:
            metadata: Video metadata
            transcript_text: Transcript text (if available)
            transcript_language: Transcript language
            transcript_error: Error message if transcript unavailable

        Returns:
            Prompt string
        """
        # Truncate transcript to 12000 chars to fit Gemini context
        transcript_excerpt = (transcript_text or "")[:12000]

        transcript_notice = (
            f"Transcript language: {transcript_language or 'unknown'}."
            if transcript_text
            else f"No transcript available. Reason: {transcript_error or 'Unknown'}."
        )

        title = metadata.get("title", "Unknown")
        channel = metadata.get("uploader") or metadata.get("channel", "Unknown")
        duration = metadata.get("duration") or metadata.get("duration_seconds", 0)
        video_url = metadata.get("url", "")

        return f"""
You are an AI assistant that summarizes YouTube videos for content analysis.

Video metadata:
- Title: {title}
- Channel: {channel}
- Duration (seconds): {duration}
- Video URL: {video_url}

{transcript_notice}

Transcript excerpt (may be truncated):
\"\"\"{transcript_excerpt}\"\"\"

Task: Provide a clear, concise summary of this video in 2-3 sentences.
Focus on the main topic, key messages, and overall purpose of the video.

Respond with ONLY the summary text, no additional formatting or commentary.
"""

    def _extract_overview(self, raw_text: str) -> str:
        """Extract overview from Gemini response.

        Args:
            raw_text: Raw response text from Gemini

        Returns:
            Cleaned overview text
        """
        # Remove markdown code blocks if present
        if raw_text.startswith("```json"):
            raw_text = raw_text[7:]
        elif raw_text.startswith("```"):
            raw_text = raw_text[3:]

        if raw_text.endswith("```"):
            raw_text = raw_text[:-3]

        raw_text = raw_text.strip()

        # Try to parse as JSON (in case Gemini returns structured data)
        try:
            data = json.loads(raw_text)
            # If it's a dict with "overview" key, extract it
            if isinstance(data, dict) and "overview" in data:
                return data["overview"]
            # Otherwise return the raw text
            return raw_text
        except json.JSONDecodeError:
            # Not JSON, return as-is
            return raw_text
