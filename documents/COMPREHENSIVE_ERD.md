# Comprehensive Entity-Relationship Diagram (ERD) - SMAP System

**Mục đích:** ERD tổng thể cho toàn bộ hệ thống SMAP, bao gồm tất cả databases và services
**Ngày tạo:** 2025-12-29
**Phạm vi:** PostgreSQL (Identity, Project, Analytics) + MongoDB (Collector)

---

## Tổng quan hệ thống Database

SMAP sử dụng **Database per Service pattern** với 4 databases chính:

| Database          | Technology | Service           | Collections/Tables                                      |
| ----------------- | ---------- | ----------------- | ------------------------------------------------------- |
| **identity_db**   | PostgreSQL | Identity Service  | users, plans, subscriptions                             |
| **project_db**    | PostgreSQL | Project Service   | projects                                                |
| **analytics_db**  | PostgreSQL | Analytics Service | post_analytics, post_comments, crawl_errors             |
| **collection_db** | MongoDB    | Collector Service | content, authors, comments, search_sessions, crawl_jobs |

---

## 1. Identity Service Database (PostgreSQL)

### ERD Diagram

```mermaid
erDiagram
    USERS ||--o{ SUBSCRIPTIONS : "has"
    PLANS ||--o{ SUBSCRIPTIONS : "defines"

    USERS {
        uuid id PK "Primary Key"
        varchar username UK "Email address (unique)"
        varchar full_name "Display name"
        varchar password_hash "bcrypt cost 10"
        text role_hash "Encrypted role (USER/ADMIN)"
        varchar avatar_url "Profile picture URL"
        boolean is_active "Account verified flag"
        varchar otp "6-digit OTP for verification"
        timestamp otp_expired_at "OTP expiry (10 minutes)"
        timestamp created_at "Account creation"
        timestamp updated_at "Last update"
        timestamp deleted_at "Soft delete"
    }

    PLANS {
        uuid id PK "Primary Key"
        varchar name UK "Plan display name (unique)"
        varchar code UK "Plan code (FREE, PRO, ENTERPRISE)"
        text description "Plan description"
        int max_usage "API call limit per day"
        timestamp created_at "Plan creation"
        timestamp updated_at "Last update"
        timestamp deleted_at "Soft delete"
    }

    SUBSCRIPTIONS {
        uuid id PK "Primary Key"
        uuid user_id FK "Foreign Key → users.id"
        uuid plan_id FK "Foreign Key → plans.id"
        varchar status "active | trialing | past_due | cancelled | expired"
        timestamp trial_ends_at "Trial period end"
        timestamp starts_at "Subscription start"
        timestamp ends_at "Subscription end"
        timestamp cancelled_at "Cancellation timestamp"
        timestamp created_at "Subscription creation"
        timestamp updated_at "Last update"
        timestamp deleted_at "Soft delete"
    }
```

### Relationships

| Relationship          | Cardinality | Description                                           |
| --------------------- | ----------- | ----------------------------------------------------- |
| USERS → SUBSCRIPTIONS | 1:N         | One user can have multiple subscriptions (historical) |
| PLANS → SUBSCRIPTIONS | 1:N         | One plan can be subscribed by multiple users          |

### Indexes

- `users.username` - Unique index for login
- `subscriptions.user_id` - Query subscriptions by user
- `subscriptions.plan_id` - Query subscriptions by plan
- `subscriptions.status` - Filter active subscriptions

---

## 2. Project Service Database (PostgreSQL)

### ERD Diagram

```mermaid
erDiagram
    PROJECTS {
        uuid id PK "Primary Key (VARCHAR UUID)"
        varchar name "Project name (VARCHAR 255)"
        text description "Project description (nullable)"
        varchar status "draft | process | completed (VARCHAR 50)"
        timestamptz from_date "Project start date"
        timestamptz to_date "Project end date"
        varchar brand_name "Brand name to track (VARCHAR 255)"
        text_array brand_keywords "Array of brand keywords (TEXT[])"
        text_array competitor_names "Array of competitor names (TEXT[])"
        jsonb competitor_keywords_map "Array/Map: competitor → keywords (JSONB)"
        text_array exclude_keywords "Keywords to exclude (TEXT[])"
        uuid created_by "User ID from JWT - NO FK CONSTRAINT"
        timestamptz created_at "Project creation"
        timestamptz updated_at "Last update"
        timestamptz deleted_at "Soft delete"
    }
```

### Cross-Database References

```
projects.created_by → users.id (Identity Service)
  - NO FK constraint (Database per Service pattern)
  - User ID extracted from JWT token
  - Validation via JWT, not database FK
```

### Indexes

- `projects.created_by` - Query projects by user
- `projects.status` - Filter by project status
- `projects.deleted_at` - Exclude deleted records

---

## 3. Analytics Service Database (PostgreSQL)

### ERD Diagram

```mermaid
erDiagram
    post_analytics ||--o{ post_comments : "has many"
    post_analytics ||--o{ crawl_errors : "may have"

    post_analytics {
        string id PK "Content ID from platform (VARCHAR 50)"
        uuid project_id "External reference - NO FK CONSTRAINT (nullable)"
        string platform "TIKTOK | YOUTUBE (VARCHAR 20)"
        timestamp published_at "Content publish date"
        timestamp analyzed_at "Analysis timestamp"
        string overall_sentiment "POSITIVE | NEGATIVE | NEUTRAL (VARCHAR 10)"
        float overall_sentiment_score "-1.0 to 1.0"
        float overall_confidence "Confidence score for sentiment"
        string primary_intent "REVIEW | COMPLAINT | QUESTION | PRAISE (VARCHAR 20)"
        float intent_confidence "Confidence score for intent"
        float impact_score "0 to 100"
        string risk_level "LOW | MEDIUM | HIGH | CRITICAL (VARCHAR 10)"
        boolean is_viral "Viral content flag (default false)"
        boolean is_kol "KOL/Influencer flag (default false)"
        jsonb aspects_breakdown "Aspect-based sentiment analysis"
        jsonb keywords "Extracted keywords with aspects"
        jsonb sentiment_probabilities "Sentiment probability distribution"
        jsonb impact_breakdown "Impact calculation details"
        integer view_count "Video views (default 0)"
        integer like_count "Video likes (default 0)"
        integer comment_count "Total comments (default 0)"
        integer share_count "Total shares (default 0)"
        integer save_count "Total saves (default 0)"
        integer follower_count "Author follower count (default 0)"
        integer processing_time_ms "Processing time in milliseconds"
        string model_version "AI model version used (VARCHAR 50)"
        string job_id "Crawl job ID (VARCHAR 100, indexed)"
        integer batch_index "Batch processing index"
        string task_type "Task type (VARCHAR 30, indexed)"
        string keyword_source "Search keyword source (VARCHAR 200)"
        timestamp crawled_at "Crawl timestamp"
        string pipeline_version "Pipeline version (VARCHAR 50)"
        text content_text "Original content text"
        text content_transcription "Speech-to-text transcription"
        integer media_duration "Media duration in seconds"
        jsonb hashtags "Array of hashtags"
        text permalink "Content URL"
        string author_id "Author ID from platform (VARCHAR 100)"
        string author_name "Author display name (VARCHAR 200)"
        string author_username "Author username (VARCHAR 100)"
        text author_avatar_url "Author avatar URL"
        boolean author_is_verified "Author verification status (default false)"
        string brand_name "Tracked brand name (VARCHAR 100, indexed)"
        string keyword "Search keyword (VARCHAR 200, indexed)"
        string fetch_status "success | error (VARCHAR 10, indexed, default 'success')"
        text fetch_error "Fetch error message"
        string error_code "Error code (VARCHAR 50, indexed)"
        jsonb error_details "Error details JSON"
    }

    post_comments {
        serial id PK "Auto-increment primary key (INTEGER)"
        string post_id FK "Foreign Key → post_analytics.id (VARCHAR 50, CASCADE DELETE)"
        string comment_id "Comment ID from platform (VARCHAR 100, nullable)"
        text text "Comment text content (required)"
        string author_name "Commenter name (VARCHAR 200, nullable)"
        integer likes "Comment likes (nullable, default 0)"
        string sentiment "POSITIVE | NEGATIVE | NEUTRAL (VARCHAR 10, nullable)"
        float sentiment_score "-1.0 to 1.0 (nullable)"
        timestamp commented_at "Comment publish date (nullable)"
        timestamp created_at "DB insert timestamp (auto-generated)"
    }

    crawl_errors {
        serial id PK "Auto-increment primary key (INTEGER)"
        string content_id "Content ID that failed (VARCHAR 50)"
        uuid project_id "External reference - NO FK CONSTRAINT (nullable)"
        string job_id "Crawl job ID (VARCHAR 100)"
        string platform "TIKTOK | YOUTUBE (VARCHAR 20)"
        string error_code "Error code (VARCHAR 50)"
        string error_category "ERROR | WARNING | INFO (VARCHAR 30)"
        text error_message "Human-readable error message (nullable)"
        jsonb error_details "Detailed error information (nullable)"
        text permalink "Content URL (nullable)"
        timestamp created_at "Error log timestamp (auto-generated)"
    }
```

### Relationships

| Relationship                   | Cardinality | Description                                      |
| ------------------------------ | ----------- | ------------------------------------------------ |
| post_analytics → post_comments | 1:N         | One post can have many comments (CASCADE DELETE) |
| post_analytics → crawl_errors  | 1:N         | One post may have multiple error logs            |

### Cross-Database References

```
post_analytics.project_id → projects.id (Project Service)
  - NO FK constraint (Database per Service pattern)
  - Nullable to support dry-run tasks

crawl_errors.project_id → projects.id (Project Service)
  - NO FK constraint
  - For error tracking per project
```

### JSONB Fields

- **aspects_breakdown**: Aspect-based sentiment

  ```json
  {
    "product_quality": { "sentiment": "POSITIVE", "score": 0.8, "count": 5 },
    "customer_service": { "sentiment": "NEUTRAL", "score": 0.1, "count": 2 },
    "price": { "sentiment": "NEGATIVE", "score": -0.6, "count": 3 }
  }
  ```

- **keywords**: Extracted keywords with aspects mapping

  ```json
  {
    "keywords": ["chất lượng tốt", "giá cao", "dịch vụ ổn"],
    "aspects": {
      "chất lượng tốt": "product_quality",
      "giá cao": "price",
      "dịch vụ ổn": "customer_service"
    }
  }
  ```

- **impact_breakdown**: Impact calculation details
  ```json
  {
    "engagement_score": 85,
    "reach_score": 92,
    "velocity_score": 78,
    "kol_multiplier": 1.5
  }
  ```

### Indexes

**post_analytics:**
- `idx_post_analytics_job_id` - Query by job_id
- `idx_post_analytics_fetch_status` - Filter by fetch status
- `idx_post_analytics_task_type` - Filter by task type
- `idx_post_analytics_error_code` - Query by error code
- `idx_post_analytics_brand_name` - Filter by brand name
- `idx_post_analytics_keyword` - Filter by keyword
- `idx_post_analytics_author_id` - Query by author

**post_comments:**
- `idx_post_comments_post_id` - Query comments by post (FK with CASCADE DELETE)
- `idx_post_comments_sentiment` - Filter comments by sentiment
- `idx_post_comments_commented_at` - Order comments by time

**crawl_errors:**
- `idx_crawl_errors_project_id` - Query errors by project
- `idx_crawl_errors_error_code` - Filter by error code
- `idx_crawl_errors_created_at` - Order errors by time
- `idx_crawl_errors_job_id` - Query errors by job

---

## 4. Collector Service Database (MongoDB)

### ERD Diagram

```mermaid
erDiagram
    content ||--o{ comments : "has many"
    authors ||--o{ content : "creates"
    search_sessions ||--o{ content : "discovers"
    crawl_jobs ||--o{ content : "produces"

    content {
        ObjectId _id PK "MongoDB auto-generated ID"
        string source "TIKTOK | YOUTUBE | FACEBOOK"
        string external_id "Platform-specific content ID"
        string url "Public content URL"
        string job_id "Crawl job ID for tracking"
        string author_id "Reference to authors._id"
        string author_external_id "Platform author ID (channel_id)"
        string author_username "Author handle (@username)"
        string author_display_name "Author display name"
        string title "Content title (YouTube, Facebook)"
        string description "Content description/caption"
        int duration_seconds "Duration in seconds"
        string sound_name "Sound/music name (TikTok)"
        string category "Category (YouTube category)"
        array tags "Hashtags/tags array"
        string media_type "VIDEO | IMAGE | AUDIO | POST"
        string media_path "Storage path (S3/MinIO)"
        timestamp media_downloaded_at "Media download timestamp"
        int view_count "Total views"
        int like_count "Total likes"
        int comment_count "Total comments"
        int share_count "Total shares"
        int save_count "Total saves (TikTok)"
        timestamp published_at "Content publish date"
        timestamp crawled_at "Last crawl timestamp"
        timestamp created_at "First insert timestamp"
        timestamp updated_at "Last update timestamp"
        string keyword "Search keyword"
        object extra_json "Platform-specific fields"
        string content_detail "AI-generated summary"
        string transcription "Speech-to-text transcription"
        string transcription_status "PROCESSING | COMPLETED | FAILED"
    }

    authors {
        ObjectId _id PK "MongoDB auto-generated ID"
        string source "TIKTOK | YOUTUBE | FACEBOOK"
        string external_id "Platform author ID (channel_id)"
        string profile_url "Author profile URL"
        string username "Unique handle (@username)"
        string display_name "Display name"
        boolean verified "Verification badge"
        int follower_count "Followers/subscribers"
        int following_count "Following count"
        int like_count "Total likes (TikTok)"
        int video_count "Total videos/posts"
        timestamp crawled_at "Last crawl timestamp"
        timestamp created_at "First insert timestamp"
        timestamp updated_at "Last update timestamp"
        object extra_json "Platform-specific fields"
    }

    comments {
        ObjectId _id PK "MongoDB auto-generated ID"
        string source "TIKTOK | YOUTUBE | FACEBOOK"
        string external_id "Platform comment ID"
        string parent_type "CONTENT | COMMENT"
        string parent_id "Reference to content._id or comments._id"
        string job_id "Crawl job ID"
        string comment_text "Comment text content"
        string commenter_name "Commenter username"
        int like_count "Comment likes"
        int reply_count "Reply count"
        timestamp published_at "Comment publish date"
        timestamp crawled_at "Last crawl timestamp"
        timestamp created_at "First insert timestamp"
        timestamp updated_at "Last update timestamp"
        object extra_json "Platform-specific fields"
    }

    search_sessions {
        ObjectId _id PK "MongoDB auto-generated ID"
        string search_id "Unique search session ID"
        string source "TIKTOK | YOUTUBE | FACEBOOK"
        string keyword "Search keyword"
        string sort_by "RELEVANCE | LIKE | VIEW | DATE"
        timestamp searched_at "Search timestamp"
        int total_found "Total results found"
        array urls "List of discovered content URLs"
        string job_id "Crawl job ID"
        string params_raw "JSON string of search parameters"
    }

    crawl_jobs {
        ObjectId _id PK "MongoDB auto-generated ID"
        string task_type "SEARCH_BY_KEYWORD | FETCH_CONTENT_DETAIL"
        string status "QUEUED | RUNNING | RETRYING | COMPLETED | FAILED | CANCELED"
        string job_id "External service job ID"
        object payload_json "Job payload for worker"
        int time_range "Publish window in days"
        timestamp since_date "Filter content after this date"
        timestamp until_date "Filter content before this date"
        int max_retry "Maximum retry attempts"
        int retry_count "Current retry count"
        string error_msg "Error message if failed"
        timestamp created_at "Job creation timestamp"
        timestamp updated_at "Last update timestamp"
        timestamp completed_at "Job completion timestamp"
        string idempotency_key "Unique key to prevent duplicates"
        array result "Array of MinIO object keys"
    }
```

### Relationships

| Relationship              | Cardinality | Description                                             |
| ------------------------- | ----------- | ------------------------------------------------------- |
| authors → content         | 1:N         | One author creates many content items                   |
| content → comments        | 1:N         | One content has many comments (parent_type=CONTENT)     |
| comments → comments       | 1:N         | One comment can have many replies (parent_type=COMMENT) |
| search_sessions → content | 1:N         | One search discovers many content items                 |
| crawl_jobs → content      | 1:N         | One job produces many content items                     |

### MongoDB Indexes

**content collection:**

- `{ source: 1, external_id: 1 }` - Unique compound index
- `{ job_id: 1 }` - Query content by job
- `{ author_external_id: 1 }` - Query content by author
- `{ keyword: 1 }` - Query content by search keyword
- `{ published_at: -1 }` - Sort by publish date

**authors collection:**

- `{ source: 1, external_id: 1 }` - Unique compound index
- `{ username: 1 }` - Query by username

**comments collection:**

- `{ source: 1, external_id: 1 }` - Unique compound index
- `{ parent_id: 1, parent_type: 1 }` - Query comments by parent
- `{ job_id: 1 }` - Query comments by job

**search_sessions collection:**

- `{ search_id: 1 }` - Unique index
- `{ job_id: 1 }` - Query sessions by job

**crawl_jobs collection:**

- `{ job_id: 1 }` - Unique index
- `{ status: 1 }` - Filter jobs by status
- `{ idempotency_key: 1 }` - Prevent duplicate jobs

---

## 5. Cross-Database Relationships

```mermaid
graph LR
    subgraph Identity Service
        A[USERS]
    end

    subgraph Project Service
        B[PROJECTS]
    end

    subgraph Analytics Service
        C[post_analytics]
        D[post_comments]
    end

    subgraph Collector Service
        E[content]
        F[authors]
        G[crawl_jobs]
    end

    A -.->|created_by NO FK| B
    B -.->|project_id NO FK| C
    B -.->|project_id NO FK| G
    E -.->|external_id match| C

    style A fill:#e1f5ff
    style B fill:#e1f5ff
    style C fill:#ffe1e1
    style D fill:#ffe1e1
    style E fill:#fff4e1
    style F fill:#fff4e1
    style G fill:#fff4e1
```

### Cross-Database Reference Summary

| Source Entity     | Target Entity               | Reference Field   | FK Constraint | Validation Method          |
| ----------------- | --------------------------- | ----------------- | ------------- | -------------------------- |
| projects          | users                       | created_by        | ❌ NO         | JWT token validation       |
| post_analytics    | projects                    | project_id        | ❌ NO         | API validation             |
| crawl_errors      | projects                    | project_id        | ❌ NO         | API validation             |
| content (MongoDB) | post_analytics (PostgreSQL) | external_id match | ❌ NO         | Application-level matching |

**Rationale for NO FK Constraints:**

- **Database per Service pattern**: Each service owns its database
- **Service independence**: Services can be deployed, scaled, and maintained independently
- **Eventual consistency**: Cross-service references validated at application level
- **Resilience**: Service failures don't cascade via database FK constraints

---

## 6. Complete Entity Summary

### PostgreSQL Entities (3 databases, 7 tables)

| Service   | Table          | Fields | Rows (est) | Purpose                       |
| --------- | -------------- | ------ | ---------- | ----------------------------- |
| Identity  | users          | 12     | 10K-100K   | User authentication & profile |
| Identity  | plans          | 8      | 3-10       | Subscription plans            |
| Identity  | subscriptions  | 11     | 10K-100K   | User subscriptions            |
| Project   | projects       | 15     | 100K-1M    | Marketing projects            |
| Analytics | post_analytics | 45     | 10M-100M   | NLP analysis results          |
| Analytics | post_comments  | 10     | 50M-500M   | Comment-level sentiment       |
| Analytics | crawl_errors   | 11     | 1M-10M     | Error tracking                |

### MongoDB Collections (1 database, 5 collections)

| Collection      | Fields | Rows (est) | Purpose                   |
| --------------- | ------ | ---------- | ------------------------- |
| content         | 31     | 10M-100M   | Raw crawled videos/posts  |
| authors         | 14     | 1M-10M     | Content creators/channels |
| comments        | 14     | 50M-500M   | Raw comments              |
| search_sessions | 9      | 100K-1M    | Search metadata           |
| crawl_jobs      | 15     | 1M-10M     | Job orchestration         |

---

## 7. Key Design Patterns

### 1. Database per Service

- ✅ Each service owns its database
- ✅ No direct database access across services
- ✅ Cross-service communication via APIs

### 2. Soft Delete

- ✅ All PostgreSQL tables have `deleted_at` timestamp
- ✅ Enables data recovery and audit trails
- ✅ Queries filter `WHERE deleted_at IS NULL`

### 3. Immutable Identifiers

- ✅ UUIDs for PostgreSQL primary keys
- ✅ MongoDB ObjectIds for document IDs
- ✅ External platform IDs (external_id) for content deduplication

### 4. Timestamp Tracking

- ✅ `created_at`: First insert (immutable)
- ✅ `updated_at`: Last modification (auto-updated)
- ✅ `crawled_at`: Last crawl/refresh (for dynamic data)

### 5. JSONB for Flexibility

- ✅ `extra_json`: Platform-specific fields
- ✅ `aspects_breakdown`: Complex nested sentiment data
- ✅ `payload_json`: Dynamic job configurations

### 6. Polyglot Persistence

- ✅ PostgreSQL: Structured, relational data (Identity, Project, Analytics)
- ✅ MongoDB: Document-oriented, schema-flexible data (Collector)
- ✅ Redis: Caching, pub/sub, session storage
- ✅ MinIO: Object storage for media files

---

## 8. Data Flow Across Services

```
1. User creates Project (Project Service → project_db)
   ↓
2. Collector dispatches crawl job (Collector Service → collection_db.crawl_jobs)
   ↓
3. Scrapper crawls content (Scrapper Service → collection_db.content, authors, comments)
   ↓
4. Analytics analyzes content (Analytics Service → analytics_db.post_analytics, post_comments)
   ↓
5. User views results (Web UI queries Analytics Service)
```

**Data Consistency:**

- ✅ Eventual consistency across services
- ✅ Idempotency keys prevent duplicate processing
- ✅ Retry mechanisms handle transient failures
- ✅ Dead-letter queues for failed jobs

---

## 9. Scalability Considerations

### Horizontal Scaling

- ✅ PostgreSQL: Read replicas for Analytics Service (read-heavy)
- ✅ MongoDB: Sharding on `source` + `external_id` for content collection
- ✅ Redis: Redis Cluster for distributed caching

### Partitioning

- ✅ `post_analytics`: Partition by `analyzed_at` (time-series data)
- ✅ `content`: Shard by `source` (TIKTOK, YOUTUBE)

### Archival

- ✅ Old analytics results (>1 year) archived to S3
- ✅ Deleted projects soft-deleted for 90 days, then purged

---

**End of Comprehensive ERD**
