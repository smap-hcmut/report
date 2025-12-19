/**
 * WebSocket Types for SMAP Web
 * 
 * Based on: documents/websocket_frontend_integration.md
 * 
 * This file contains all TypeScript interfaces and enums for WebSocket
 * communication with the backend API.
 */

// ============================================================================
// Enums
// ============================================================================

/**
 * Supported social media platforms
 * Note: Facebook is deprecated and no longer supported
 */
export enum Platform {
  TIKTOK = 'TIKTOK',
  YOUTUBE = 'YOUTUBE',
  INSTAGRAM = 'INSTAGRAM',
}

/**
 * Project processing status
 * - PROCESSING: Includes both crawling and analysis phases
 * - COMPLETED: Project finished successfully
 * - FAILED: Project encountered fatal error
 * - PAUSED: Project temporarily stopped
 */
export enum ProjectStatus {
  PROCESSING = 'PROCESSING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  PAUSED = 'PAUSED',
}

/**
 * Job processing status
 * - PROCESSING: Job is actively crawling/processing
 * - COMPLETED: Job finished all batches
 * - FAILED: Job encountered fatal error
 * - PAUSED: Job temporarily stopped
 */
export enum JobStatus {
  PROCESSING = 'PROCESSING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  PAUSED = 'PAUSED',
}

// ============================================================================
// Progress Types
// ============================================================================

/**
 * Progress information for both Project and Job notifications
 */
export interface Progress {
  /** Current completed items (absolute value, not increment) */
  current: number
  /** Total items to process (may change during processing) */
  total: number
  /** Completion percentage (0-100) */
  percentage: number
  /** Estimated time remaining in minutes (float64, e.g., 8.5 = 8 min 30 sec) */
  eta: number
  /** Array of error messages encountered (replaces entire list, not appended) */
  errors: string[]
}

/**
 * Phase-based progress for individual phases (crawl/analyze)
 * Used in the new phase-based message format
 * 
 * @see documents/client-phase-progress-migration.md
 */
export interface PhaseProgress {
  /** Total items to process in this phase */
  total: number
  /** Number of completed items */
  done: number
  /** Number of failed items */
  errors: number
  /** Completion percentage (0.0 - 100.0) */
  progress_percent: number
}

/**
 * Phase-based project status values
 * Extended from ProjectStatus to include INITIALIZING and DONE
 */
export type PhaseBasedStatus = 'INITIALIZING' | 'PROCESSING' | 'DONE' | 'FAILED'

/**
 * Payload for phase-based project notification messages
 * Contains detailed progress for each phase (crawl, analyze)
 */
export interface ProjectPhasePayload {
  /** Project unique identifier */
  project_id: string
  /** Current project status */
  status: PhaseBasedStatus
  /** Crawl phase progress (optional - may not be present at INITIALIZING) */
  crawl?: PhaseProgress
  /** Analyze phase progress (optional - may not be present during crawl phase) */
  analyze?: PhaseProgress
  /** Overall progress percentage combining all phases */
  overall_progress_percent: number
}

/**
 * Phase-based message format with type wrapper
 * New format: { type: "project_progress" | "project_completed", payload: {...} }
 */
export interface ProjectPhaseMessage {
  /** Message type indicating progress update or completion */
  type: 'project_progress' | 'project_completed'
  /** Message payload with phase-based progress data */
  payload: ProjectPhasePayload
}


// ============================================================================
// Project Notification Types
// ============================================================================

/**
 * Project notification message received from WebSocket
 * 
 * Note: This is a flat structure without type wrapper.
 * The message is received directly as { status, progress? }
 */
export interface ProjectNotificationMessage {
  /** Current project status */
  status: ProjectStatus
  /** Overall progress (omitted if empty) */
  progress?: Progress
}

// ============================================================================
// Job Notification Types
// ============================================================================

/**
 * Author information for content items
 */
export interface AuthorInfo {
  /** Author unique ID */
  id: string
  /** Author username/handle */
  username: string
  /** Author display name */
  name: string
  /** Follower count */
  followers: number
  /** Verification status */
  is_verified: boolean
  /** Profile picture URL */
  avatar_url: string
}

/**
 * Engagement metrics for content items
 */
export interface EngagementMetrics {
  /** View count */
  views: number
  /** Like count */
  likes: number
  /** Comment count */
  comments: number
  /** Share count */
  shares: number
  /** Engagement rate percentage (0-100) */
  rate: number
}

/**
 * Media information for content items
 */
export interface MediaInfo {
  /** Media type: "video", "image", "audio" */
  type: string
  /** Duration in seconds (for video/audio) */
  duration?: number
  /** Thumbnail/preview URL */
  thumbnail: string
  /** Media file URL */
  url: string
}

/**
 * Single content item from crawled data
 */
export interface ContentItem {
  /** Content unique ID (used for deduplication) */
  id: string
  /** Content text/caption */
  text: string
  /** Author information */
  author: AuthorInfo
  /** Engagement statistics */
  metrics: EngagementMetrics
  /** Media information (if any) */
  media?: MediaInfo
  /** When content was published (ISO 8601 timestamp) */
  published_at: string
  /** Direct link to original content */
  permalink: string
}

/**
 * Batch data containing crawled content for a specific keyword
 */
export interface BatchData {
  /** Search keyword for this batch */
  keyword: string
  /** Crawled content items (append to feed, check for duplicates by id) */
  content_list: ContentItem[]
  /** When this batch was processed (ISO 8601 timestamp) */
  crawled_at: string
}

/**
 * Job notification message received from WebSocket
 * 
 * Note: This is a flat structure without type wrapper.
 * Multiple messages are sent per job (one per batch completion).
 */
export interface JobNotificationMessage {
  /** Social media platform */
  platform: Platform
  /** Current job processing status */
  status: JobStatus
  /** Current batch crawl results (omitted if empty) */
  batch?: BatchData
  /** Overall job progress statistics (omitted if empty) */
  progress?: Progress
}

// ============================================================================
// Helper Types
// ============================================================================

/**
 * Union type for all WebSocket notification messages
 */
export type WebSocketNotificationMessage =
  | ProjectNotificationMessage
  | JobNotificationMessage

/**
 * Type guard to check if message is a Project notification
 */
export function isProjectNotification(
  message: WebSocketNotificationMessage
): message is ProjectNotificationMessage {
  return !('platform' in message)
}

/**
 * Type guard to check if message is a Job notification
 */
export function isJobNotification(
  message: WebSocketNotificationMessage
): message is JobNotificationMessage {
  return 'platform' in message
}

/**
 * Type guard to check if message is in phase-based format
 * Phase-based messages have { type: "project_progress" | "project_completed", payload: {...} }
 * 
 * @see documents/client-phase-progress-migration.md
 */
export function isPhaseBasedMessage(data: unknown): data is ProjectPhaseMessage {
  if (typeof data !== 'object' || data === null) return false
  const msg = data as Record<string, unknown>
  return msg.type === 'project_progress' || msg.type === 'project_completed'
}

/**
 * Type guard to check if message is in legacy format
 * Legacy messages have { status, progress? } without type wrapper
 */
export function isLegacyMessage(data: unknown): data is ProjectNotificationMessage {
  if (typeof data !== 'object' || data === null) return false
  const msg = data as Record<string, unknown>
  return 'status' in msg && !('type' in msg) && !('platform' in msg)
}

/**
 * Format ETA from minutes (float64) to human-readable string
 * @param etaMinutes - ETA in minutes (e.g., 8.5)
 * @returns Formatted string (e.g., "8 phút 30 giây")
 */
export function formatETA(etaMinutes: number): string {
  if (etaMinutes <= 0) return 'Sắp hoàn thành'

  const minutes = Math.floor(etaMinutes)
  const seconds = Math.round((etaMinutes - minutes) * 60)

  if (minutes === 0) {
    return `${seconds} giây`
  }

  if (seconds === 0) {
    return `${minutes} phút`
  }

  return `${minutes} phút ${seconds} giây`
}

/**
 * Map legacy status values to new ProjectStatus
 * Used for backward compatibility during migration
 */
export function mapLegacyProjectStatus(status: string): ProjectStatus {
  switch (status) {
    case 'INITIALIZING':
    case 'CRAWLING':
      return ProjectStatus.PROCESSING
    case 'DONE':
      return ProjectStatus.COMPLETED
    case 'PROCESSING':
      return ProjectStatus.PROCESSING
    case 'COMPLETED':
      return ProjectStatus.COMPLETED
    case 'FAILED':
      return ProjectStatus.FAILED
    case 'PAUSED':
      return ProjectStatus.PAUSED
    default:
      return ProjectStatus.PROCESSING
  }
}

/**
 * Map legacy platform values to new Platform enum
 * Used for backward compatibility during migration
 */
export function mapLegacyPlatform(platform: string): Platform | null {
  const normalized = platform.toUpperCase()
  switch (normalized) {
    case 'TIKTOK':
      return Platform.TIKTOK
    case 'YOUTUBE':
      return Platform.YOUTUBE
    case 'INSTAGRAM':
      return Platform.INSTAGRAM
    case 'FACEBOOK':
      // Facebook is deprecated
      return null
    default:
      return null
  }
}
