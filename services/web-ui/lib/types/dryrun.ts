/**
 * TypeScript interfaces for Dry-Run WebSocket data
 * Based on: docs/DRY-RUN-DATA-FLOW.md (Section 3.3 - WebSocket Message Structure)
 * 
 * @deprecated This file is deprecated and will be removed in a future version.
 * Use `lib/types/websocket.ts` instead for the new Job notification types.
 * 
 * Migration guide:
 * - DryRunWebSocketMessage → JobNotificationMessage
 * - DryRunContent → ContentItem
 * - DryRunAuthor → AuthorInfo
 * - DryRunInteraction → EngagementMetrics
 * - Platform type → Platform enum (UPPERCASE values)
 * 
 * @see documents/websocket_frontend_integration.md for new specification
 * @see lib/types/websocket.ts for new types
 */

// ============================================================================
// Top-level WebSocket Message (line 633-648)
// ============================================================================

/**
 * WebSocket message wrapper received from the WebSocket server
 * @deprecated Use JobNotificationMessage from lib/types/websocket.ts instead
 */
export interface DryRunWebSocketMessage {
  type: 'dryrun_result'
  payload: DryRunOuterPayload
  timestamp: string // ISO 8601
}

/**
 * Outer payload containing job metadata and nested content payload
 * @deprecated Use JobNotificationMessage from lib/types/websocket.ts instead
 */
export interface DryRunOuterPayload {
  type: 'dryrun_result'
  job_id: string
  platform: 'facebook' | 'tiktok' | 'youtube'
  status: 'success' | 'failed'
  payload: DryRunInnerPayload // Nested payload with actual content
}

/**
 * Inner payload containing the actual crawled content and errors
 */
export interface DryRunInnerPayload {
  content: DryRunContent[]
  errors: DryRunError[]
}

// ============================================================================
// Content Structure (line 502-573 reference)
// ============================================================================

/**
 * Single content item (post/video) with all associated data
 * @deprecated Use ContentItem from lib/types/websocket.ts instead
 */
export interface DryRunContent {
  meta: DryRunContentMeta
  content: DryRunContentData
  interaction: DryRunInteraction
  author: DryRunAuthor
  comments: DryRunComment[]
}

/**
 * Metadata about the crawled content
 */
export interface DryRunContentMeta {
  id: string
  platform: 'facebook' | 'tiktok' | 'youtube'
  job_id: string
  crawled_at: string // ISO 8601 (RFC3339)
  published_at: string // ISO 8601 (RFC3339)
  permalink: string
  keyword_source: string // The keyword that matched this content
  lang: string // Language code (e.g., "vi", "en")
  region: string // Region code (e.g., "VN", "US")
  pipeline_version: string // Crawler version (e.g., "crawler_tiktok_v3")
  fetch_status: string // "success" or "failed"
  fetch_error: string | null
}

/**
 * The actual content data (text, media, hashtags, etc.)
 */
export interface DryRunContentData {
  text: string
  duration?: number // Video/audio duration in seconds
  hashtags?: string[]
  sound_name?: string // TikTok: sound/music name
  category?: string | null // Content category
  title?: string | null // YouTube: video title
  media?: DryRunContentMedia
  transcription?: string | null // Audio/video transcription
}

/**
 * Media metadata (audio/video files)
 */
export interface DryRunContentMedia {
  type: string // "audio" or "video"
  video_path?: string
  audio_path?: string
  downloaded_at?: string // ISO 8601
}

/**
 * Interaction/engagement metrics
 * @deprecated Use EngagementMetrics from lib/types/websocket.ts instead
 */
export interface DryRunInteraction {
  views: number
  likes: number
  comments_count: number
  shares: number
  saves?: number // TikTok: bookmark/save count
  engagement_rate?: number // Calculated engagement rate (0.0 - 1.0)
  updated_at: string // ISO 8601
}

/**
 * Author/creator information
 * @deprecated Use AuthorInfo from lib/types/websocket.ts instead
 */
export interface DryRunAuthor {
  id: string
  name: string
  username: string
  followers: number
  following: number
  likes: number // Total likes on all content
  videos: number // Total video count
  is_verified: boolean
  bio?: string
  avatar_url?: string | null
  profile_url: string
  country?: string | null // YouTube only
  total_view_count?: number | null // YouTube: channel total views
}

/**
 * Comment on the content
 */
export interface DryRunComment {
  id: string
  parent_id?: string | null // For threaded comments/replies
  post_id: string
  user: DryRunCommentUser
  text: string
  likes: number
  replies_count: number
  published_at: string // ISO 8601
  is_author: boolean // Whether comment is from the content author
  media?: string | null
  is_favorited?: boolean // YouTube: whether comment is favorited by creator
}

/**
 * Comment author (simplified user info)
 */
export interface DryRunCommentUser {
  id?: string | null
  name: string
  avatar_url?: string | null
}

/**
 * Error information (for failed keyword searches)
 */
export interface DryRunError {
  code: string
  message: string
  keyword?: string // The keyword that caused the error
}

// ============================================================================
// Aggregated Metrics for UI Display
// ============================================================================

/**
 * Calculated metrics for display in the UI
 * (not from WebSocket, computed client-side)
 */
export interface DryRunMetrics {
  totalPosts: number
  totalViews: number
  totalLikes: number
  totalComments: number
  totalShares: number
  avgEngagement: number // Average engagement rate
  topKeywords: KeywordCount[]
  platforms: PlatformCount[]
}

export interface KeywordCount {
  keyword: string
  count: number
}

export interface PlatformCount {
  platform: string
  count: number
}

// ============================================================================
// Helper Types
// ============================================================================

/**
 * Platform type
 * @deprecated Use Platform enum from lib/types/websocket.ts instead
 * Note: 'facebook' is no longer supported, use UPPERCASE values
 */
export type Platform = 'facebook' | 'tiktok' | 'youtube'

/**
 * Status type
 * @deprecated Use JobStatus enum from lib/types/websocket.ts instead
 */
export type DryRunStatus = 'success' | 'failed'

/**
 * Engagement statistics for a single post
 */
export interface PostEngagementStats {
  views: number
  likes: number
  comments: number
  shares: number
  saves: number
  engagementRate: number
}

/**
 * Author statistics
 */
export interface AuthorStats {
  followers: number
  following: number
  totalLikes: number
  totalVideos: number
  verified: boolean
}
