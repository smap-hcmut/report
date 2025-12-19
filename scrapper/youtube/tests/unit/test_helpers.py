"""
Unit tests for YouTube helper utilities.

Tests:
- task_type propagation in map_to_new_format()
- project_id extraction from job_id
"""

import pytest
from unittest.mock import MagicMock
from datetime import datetime, timezone

from utils.helpers import map_to_new_format, extract_project_id, extract_brand_info


class TestMapToNewFormat:
    """Test suite for map_to_new_format function - task_type propagation and Contract v2.0 compliance."""

    @pytest.fixture
    def mock_content(self):
        """Create a mock Content object."""
        content = MagicMock()
        content.external_id = "dQw4w9WgXcQ"
        content.source = "youtube"
        content.url = "https://youtube.com/watch?v=dQw4w9WgXcQ"
        content.title = "Test YouTube Video"
        content.description = "Test video description"
        content.view_count = 1000000
        content.like_count = 50000
        content.comment_count = 5000
        content.share_count = None
        content.save_count = None
        content.duration_seconds = 212
        content.tags = ["music", "video"]
        content.sound_name = None
        content.category = "Music"
        content.media_type = None
        content.media_path = None
        content.media_downloaded_at = None
        content.transcription = None
        content.transcription_status = None
        content.transcription_error = None
        content.crawled_at = datetime.now(timezone.utc)
        content.published_at = datetime.now(timezone.utc)
        content.updated_at = datetime.now(timezone.utc)
        content.keyword = "test keyword"
        content.author_username = "testchannel"
        content.author_display_name = "Test Channel"
        content.author_external_id = "UC123456"
        return content

    @pytest.fixture
    def mock_crawl_result(self, mock_content):
        """Create a mock CrawlResult object."""
        result = MagicMock()
        result.success = True
        result.content = mock_content
        result.author = None
        result.comments = []
        result.error_message = None
        result.error_code = None
        result.error_response = None
        return result

    @pytest.fixture
    def mock_failed_crawl_result(self, mock_content):
        """Create a mock failed CrawlResult object."""
        result = MagicMock()
        result.success = False
        result.content = mock_content
        result.author = None
        result.comments = []
        result.error_message = "Video not found"
        result.error_code = "VIDEO_NOT_FOUND"
        result.error_response = {"status": 404, "detail": "Video does not exist"}
        return result

    def test_task_type_included_in_meta(self, mock_crawl_result):
        """Test that task_type is included in meta section."""
        result = map_to_new_format(
            result=mock_crawl_result,
            job_id="test-job-123",
            keyword="test keyword",
            task_type="dryrun_keyword",
        )

        assert "meta" in result
        assert "task_type" in result["meta"]
        assert result["meta"]["task_type"] == "dryrun_keyword"

    def test_task_type_dryrun_keyword(self, mock_crawl_result):
        """Test task_type value for dry-run keyword tasks."""
        result = map_to_new_format(
            result=mock_crawl_result,
            job_id="550e8400-e29b-41d4-a716-446655440000",
            keyword="test keyword",
            task_type="dryrun_keyword",
        )

        assert result["meta"]["task_type"] == "dryrun_keyword"

    def test_task_type_research_and_crawl(self, mock_crawl_result):
        """Test task_type value for research_and_crawl tasks."""
        result = map_to_new_format(
            result=mock_crawl_result,
            job_id="proj123-brand-0",
            keyword="brand keyword",
            task_type="research_and_crawl",
        )

        assert result["meta"]["task_type"] == "research_and_crawl"

    def test_task_type_none_when_not_provided(self, mock_crawl_result):
        """Test task_type is None when not provided."""
        result = map_to_new_format(
            result=mock_crawl_result,
            job_id="test-job-123",
            keyword="test keyword",
            # task_type not provided
        )

        assert "task_type" in result["meta"]
        assert result["meta"]["task_type"] is None

    def test_task_type_custom_value(self, mock_crawl_result):
        """Test task_type with custom value."""
        result = map_to_new_format(
            result=mock_crawl_result,
            job_id="test-job-123",
            keyword="test keyword",
            task_type="custom_task_type",
        )

        assert result["meta"]["task_type"] == "custom_task_type"

    def test_meta_contains_required_fields(self, mock_crawl_result):
        """Test that meta section contains all required fields (Contract v2.0)."""
        result = map_to_new_format(
            result=mock_crawl_result,
            job_id="test-job-123",
            keyword="test keyword",
            task_type="dryrun_keyword",
        )

        meta = result["meta"]
        required_fields = [
            "id",
            "platform",
            "job_id",
            "task_type",
            "crawled_at",
            "published_at",
            "permalink",
            "keyword_source",
            "lang",
            "region",
            "pipeline_version",
            "fetch_status",
            # Contract v2.0 error fields
            "error_code",
            "error_message",
            "error_details",
        ]

        for field in required_fields:
            assert field in meta, f"Missing required field: {field}"

    def test_meta_platform_is_uppercase(self, mock_crawl_result):
        """Test that platform in meta is UPPERCASE per Contract v2.0."""
        result = map_to_new_format(
            result=mock_crawl_result,
            job_id="test-job-123",
            keyword="test keyword",
            task_type="dryrun_keyword",
        )

        assert result["meta"]["platform"] == "YOUTUBE"

    def test_error_fields_on_success(self, mock_crawl_result):
        """Test that error fields are None on successful crawl."""
        result = map_to_new_format(
            result=mock_crawl_result,
            job_id="test-job-123",
            keyword="test keyword",
            task_type="dryrun_keyword",
        )

        assert result["meta"]["error_code"] is None
        assert result["meta"]["error_message"] is None
        assert result["meta"]["error_details"] is None
        assert result["meta"]["fetch_status"] == "success"

    def test_error_fields_on_failure(self, mock_failed_crawl_result):
        """Test that error fields are populated on failed crawl."""
        result = map_to_new_format(
            result=mock_failed_crawl_result,
            job_id="test-job-123",
            keyword="test keyword",
            task_type="dryrun_keyword",
        )

        assert result["meta"]["error_code"] == "VIDEO_NOT_FOUND"
        assert result["meta"]["error_message"] == "Video not found"
        assert result["meta"]["error_details"] == {
            "status": 404,
            "detail": "Video does not exist",
        }
        assert result["meta"]["fetch_status"] == "error"

    def test_comments_have_flat_author_name(self, mock_crawl_result):
        """Test that comments have flat author_name field per Contract v2.0."""
        # Add mock comment
        mock_comment = MagicMock()
        mock_comment.external_id = "comment123"
        mock_comment.comment_text = "Great video!"
        mock_comment.commenter_name = "commenter_user"
        mock_comment.like_count = 10
        mock_comment.published_at = datetime.now(timezone.utc)
        mock_comment.parent_type = None
        mock_comment.parent_id = None
        mock_comment.reply_count = 0
        mock_comment.extra_json = {"author_channel_id": "UC123", "is_favorited": True}
        mock_crawl_result.comments = [mock_comment]

        result = map_to_new_format(
            result=mock_crawl_result,
            job_id="test-job-123",
            keyword="test keyword",
            task_type="dryrun_keyword",
        )

        assert len(result["comments"]) == 1
        comment = result["comments"][0]
        # Flat author_name field (Contract v2.0)
        assert "author_name" in comment
        assert comment["author_name"] == "commenter_user"
        # Also has nested user object for backward compatibility
        assert "user" in comment
        assert comment["user"]["name"] == "commenter_user"
        assert comment["user"]["id"] == "UC123"  # YouTube-specific
        assert comment["is_favorited"] is True  # YouTube-specific


class TestExtractBrandInfo:
    """Test suite for extract_brand_info function."""

    # Standard test UUID
    TEST_UUID = "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"

    def test_brand_job_id_format(self):
        """Test extraction from brand job_id format: {uuid}-brand-{index}."""
        brand_name, brand_type = extract_brand_info(f"{self.TEST_UUID}-brand-0")
        assert brand_name is None  # brand_name comes from task payload
        assert brand_type == "brand"

    def test_competitor_with_name_format(self):
        """Test extraction from competitor format: {uuid}-competitor-{name}-{index}."""
        brand_name, brand_type = extract_brand_info(
            f"{self.TEST_UUID}-competitor-Toyota-0"
        )
        assert brand_name == "Toyota"
        assert brand_type == "competitor"

    def test_competitor_with_hyphenated_name(self):
        """Test extraction when competitor name contains hyphens."""
        brand_name, brand_type = extract_brand_info(
            f"{self.TEST_UUID}-competitor-Brand-X-0"
        )
        assert brand_name == "Brand-X"
        assert brand_type == "competitor"

    def test_uuid_only_returns_unknown(self):
        """Test that UUID-only format (dry-run) returns unknown type."""
        brand_name, brand_type = extract_brand_info(self.TEST_UUID)
        assert brand_name is None
        assert brand_type == "unknown"

    def test_empty_job_id(self):
        """Test that empty job_id returns unknown type."""
        brand_name, brand_type = extract_brand_info("")
        assert brand_name is None
        assert brand_type == "unknown"

        brand_name, brand_type = extract_brand_info(None)
        assert brand_name is None
        assert brand_type == "unknown"


class TestExtractProjectId:
    """Test suite for extract_project_id function.

    Tests UUID extraction from job_id formats:
    - {uuid}-brand-{index}
    - {uuid}-competitor-{index}
    - {uuid}-competitor-{name}-{index}
    - {uuid} (dry-run → returns None)
    """

    # Standard test UUID
    TEST_UUID = "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"
    TEST_UUID_2 = "550e8400-e29b-41d4-a716-446655440000"

    def test_brand_job_id_format(self):
        """Test extraction from brand job_id format: {uuid}-brand-{index}."""
        assert extract_project_id(f"{self.TEST_UUID}-brand-0") == self.TEST_UUID
        assert extract_project_id(f"{self.TEST_UUID}-brand-5") == self.TEST_UUID
        assert extract_project_id(f"{self.TEST_UUID}-brand-123") == self.TEST_UUID

    def test_competitor_simple_format(self):
        """Test extraction from simple competitor format: {uuid}-competitor-{index}."""
        assert extract_project_id(f"{self.TEST_UUID}-competitor-0") == self.TEST_UUID
        assert extract_project_id(f"{self.TEST_UUID}-competitor-5") == self.TEST_UUID
        assert extract_project_id(f"{self.TEST_UUID}-competitor-99") == self.TEST_UUID

    def test_competitor_with_name_format(self):
        """Test extraction from competitor with name format: {uuid}-competitor-{name}-{index}.

        This is the main bug fix - previously rsplit("-", 2) would fail for this format.
        """
        # Simple name
        assert (
            extract_project_id(f"{self.TEST_UUID}-competitor-Misa-0") == self.TEST_UUID
        )
        assert (
            extract_project_id(f"{self.TEST_UUID}-competitor-BrandX-5")
            == self.TEST_UUID
        )

        # Name with numbers
        assert (
            extract_project_id(f"{self.TEST_UUID}-competitor-Brand123-0")
            == self.TEST_UUID
        )

        # Longer name
        assert (
            extract_project_id(f"{self.TEST_UUID}-competitor-SomeCompetitor-10")
            == self.TEST_UUID
        )

    def test_competitor_with_hyphenated_name(self):
        """Test extraction when competitor name contains hyphens: {uuid}-competitor-{name-with-hyphen}-{index}.

        Edge case: competitor name itself contains hyphens.
        """
        assert (
            extract_project_id(f"{self.TEST_UUID}-competitor-Brand-X-0")
            == self.TEST_UUID
        )
        assert (
            extract_project_id(f"{self.TEST_UUID}-competitor-Some-Brand-Name-5")
            == self.TEST_UUID
        )

    def test_uuid_only_returns_none(self):
        """Test that UUID-only format (dry-run) returns None."""
        # Standard UUID format - dry-run jobs
        assert extract_project_id(self.TEST_UUID) is None
        assert extract_project_id(self.TEST_UUID_2) is None
        assert extract_project_id("123e4567-e89b-12d3-a456-426614174000") is None

    def test_uppercase_uuid_returns_none(self):
        """Test that uppercase UUID (dry-run) returns None."""
        assert extract_project_id(self.TEST_UUID.upper()) is None
        assert extract_project_id("550E8400-E29B-41D4-A716-446655440000") is None

    def test_empty_job_id_returns_none(self):
        """Test that empty job_id returns None."""
        assert extract_project_id("") is None
        assert extract_project_id(None) is None

    def test_invalid_format_returns_none(self):
        """Test that invalid formats (non-UUID prefix) return None."""
        # Non-UUID prefix
        assert extract_project_id("invalid-brand-0") is None
        assert extract_project_id("proj_abc123-brand-0") is None
        assert extract_project_id("single") is None
        assert extract_project_id("project-brand") is None

    def test_production_job_id_samples(self):
        """Test with actual production job_id samples from PRODUCTION_ISSUE_2025-12-15.md."""
        uuid = "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"

        # These are the exact formats from production
        assert extract_project_id(f"{uuid}-brand-0") == uuid
        assert extract_project_id(f"{uuid}-competitor-0") == uuid
        assert extract_project_id(f"{uuid}-competitor-Misa-0") == uuid

        # Dry-run format
        assert extract_project_id("550e8400-e29b-41d4-a716-446655440000") is None

    def test_case_insensitive_uuid(self):
        """Test that UUID matching is case-insensitive."""
        uuid_lower = "fc5d5ffb-36cc-4c8d-a288-f5215af7fb80"
        uuid_upper = "FC5D5FFB-36CC-4C8D-A288-F5215AF7FB80"
        uuid_mixed = "Fc5d5Ffb-36Cc-4c8D-a288-F5215aF7fb80"

        # All should extract the same UUID (lowercase)
        assert extract_project_id(f"{uuid_lower}-brand-0") == uuid_lower
        assert extract_project_id(f"{uuid_upper}-brand-0") == uuid_lower
        assert extract_project_id(f"{uuid_mixed}-brand-0") == uuid_lower


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
