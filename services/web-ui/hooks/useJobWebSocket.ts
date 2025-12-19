/**
 * Hook to manage job-specific WebSocket connections
 *
 * Used for real-time job progress and content streaming.
 * Replaces the old dry-run WebSocket flow.
 *
 * Features:
 * - URL pattern: /ws?jobId={jobId} (query params)
 * - Authentication: HttpOnly Cookie (automatic)
 * - Message format: { platform, status, batch?, progress? }
 * - Real-time content streaming with deduplication
 *
 * @see documents/websocket_frontend_integration.md
 */

import { useEffect, useRef, useState, useCallback } from 'react'
import { useRouter } from 'next/router'
import {
  WebSocketService,
  createJobWebSocket,
} from '@/services/websocketService'
import type {
  JobNotificationMessage,
  JobStatus,
  Platform,
  Progress,
  BatchData,
  ContentItem,
} from '@/lib/types/websocket'

/**
 * Options for useJobWebSocket hook
 */
interface UseJobWebSocketOptions {
  /** Called when any message is received */
  onMessage?: (message: JobNotificationMessage) => void
  /** Called when connection is established */
  onConnect?: () => void
  /** Called when connection is closed */
  onDisconnect?: () => void
  /** Called when an error occurs */
  onError?: (error: Error) => void
  /** Called when a new batch of content is received */
  onBatch?: (batch: BatchData) => void
  /** Called when job status changes to PROCESSING */
  onProcessing?: (progress?: Progress) => void
  /** Called when job status changes to COMPLETED */
  onCompleted?: (progress?: Progress) => void
  /** Called when job status changes to FAILED */
  onFailed?: (errors?: string[]) => void
  /** Called when job status changes to PAUSED */
  onPaused?: () => void
  /** Maximum number of content items to keep in state (default: 500) */
  maxContentItems?: number
  /** Disable auto-connect from URL query param (default: false) */
  disableAutoConnect?: boolean
}

/**
 * Return type for useJobWebSocket hook
 */
interface UseJobWebSocketReturn {
  /** Whether WebSocket is currently connected */
  isConnected: boolean
  /** Current error message if any */
  error: string | null
  /** Current job ID being monitored */
  jobId: string | null
  /** Current job status */
  status: JobStatus | null
  /** Current platform */
  platform: Platform | null
  /** Current progress data */
  progress: Progress | null
  /** Current keyword being processed */
  currentKeyword: string | null
  /** Accumulated content items (newest first, deduplicated) */
  contentList: ContentItem[]
  /** Total content count received */
  totalContentCount: number
  /** Manually disconnect from WebSocket */
  disconnect: () => void
  /** Manually connect to a specific job */
  connect: (jobId: string) => Promise<void>
  /** Clear content list */
  clearContent: () => void
}


/**
 * Hook to manage job-specific WebSocket connections
 *
 * Automatically connects when URL has ?job={jobId} parameter.
 * Handles real-time content streaming with automatic deduplication.
 *
 * @example
 * ```tsx
 * const { isConnected, status, contentList, currentKeyword } = useJobWebSocket({
 *   onBatch: (batch) => console.log('New batch:', batch.keyword),
 *   onCompleted: () => router.push('/results'),
 * })
 * ```
 */
export function useJobWebSocket(
  options: UseJobWebSocketOptions = {}
): UseJobWebSocketReturn {
  const router = useRouter()
  const wsRef = useRef<WebSocketService | null>(null)
  const currentJobIdRef = useRef<string | null>(null)
  const pendingConnectionRef = useRef<WebSocketService | null>(null)
  const connectingJobIdRef = useRef<string | null>(null)
  const optionsRef = useRef(options)
  const contentIdsRef = useRef<Set<string>>(new Set())

  // Keep options ref updated
  optionsRef.current = options

  // Default max content items
  const maxContentItems = options.maxContentItems ?? 500
  
  // Check if auto-connect is disabled
  const disableAutoConnect = options.disableAutoConnect ?? false

  // State
  const [isConnected, setIsConnected] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [status, setStatus] = useState<JobStatus | null>(null)
  const [platform, setPlatform] = useState<Platform | null>(null)
  const [progress, setProgress] = useState<Progress | null>(null)
  const [currentKeyword, setCurrentKeyword] = useState<string | null>(null)
  const [contentList, setContentList] = useState<ContentItem[]>([])
  const [totalContentCount, setTotalContentCount] = useState(0)

  // Extract job ID from URL (only if auto-connect is enabled)
  const jobId = disableAutoConnect ? null : ((router.query.job as string) || null)

  /**
   * Add content items with deduplication
   */
  const addContent = useCallback(
    (newItems: ContentItem[]) => {
      // Filter out duplicates
      const uniqueItems = newItems.filter((item) => {
        if (contentIdsRef.current.has(item.id)) {
          return false
        }
        contentIdsRef.current.add(item.id)
        return true
      })

      if (uniqueItems.length === 0) return

      setContentList((prev) => {
        // Prepend new items (newest first)
        const updated = [...uniqueItems, ...prev]
        // Limit to maxContentItems
        if (updated.length > maxContentItems) {
          // Remove oldest items and their IDs from tracking
          const removed = updated.slice(maxContentItems)
          removed.forEach((item) => contentIdsRef.current.delete(item.id))
          return updated.slice(0, maxContentItems)
        }
        return updated
      })

      setTotalContentCount((prev) => prev + uniqueItems.length)
    },
    [maxContentItems]
  )

  /**
   * Handle incoming job notification message
   */
  const handleMessage = useCallback(
    (message: JobNotificationMessage) => {
      // Update state
      setStatus(message.status)
      setPlatform(message.platform)
      setProgress(message.progress || null)

      // Handle batch data
      if (message.batch) {
        setCurrentKeyword(message.batch.keyword)
        if (message.batch.content_list?.length > 0) {
          addContent(message.batch.content_list)
        }
        optionsRef.current.onBatch?.(message.batch)
      }

      // Call general message handler
      optionsRef.current.onMessage?.(message)

      // Call status-specific handlers
      switch (message.status) {
        case 'PROCESSING':
          optionsRef.current.onProcessing?.(message.progress)
          break
        case 'COMPLETED':
          optionsRef.current.onCompleted?.(message.progress)
          break
        case 'FAILED':
          optionsRef.current.onFailed?.(message.progress?.errors)
          break
        case 'PAUSED':
          optionsRef.current.onPaused?.()
          break
      }
    },
    [addContent]
  )

  /**
   * Connect to WebSocket for specific job
   * 
   * Fixes applied:
   * 1. Race condition: Wait for new connection to open BEFORE disconnecting old one
   * 2. Rapid switching: Cancel pending connections before creating new ones
   * 3. Memory leaks: Clean up event listeners from old connections
   * 4. Timeout: Connection timeout handled by WebSocketService
   */
  const connectToJob = useCallback(
    async (jobId: string) => {
      // If already connected to this job, don't reconnect
      if (currentJobIdRef.current === jobId && isConnected) {
        console.log(`[WebSocket] Already connected to job: ${jobId}`)
        return
      }

      // RAPID SWITCHING PROTECTION: Cancel any pending connection
      if (pendingConnectionRef.current && connectingJobIdRef.current !== jobId) {
        console.log(`[WebSocket] Canceling pending connection to job: ${connectingJobIdRef.current}`)
        pendingConnectionRef.current.disconnect()
        pendingConnectionRef.current.removeAllListeners()
        pendingConnectionRef.current = null
        connectingJobIdRef.current = null
      }

      // Store reference to old connection (don't disconnect yet!)
      const oldWs = wsRef.current
      const oldJobId = currentJobIdRef.current

      // Reset state for new connection
      setStatus(null)
      setPlatform(null)
      setProgress(null)
      setCurrentKeyword(null)
      setContentList([])
      setTotalContentCount(0)
      setError(null)
      contentIdsRef.current.clear()

      try {
        console.log(`[WebSocket] Creating new connection to job: ${jobId}`)
        
        // Create new WebSocket connection
        const newWs = createJobWebSocket(jobId)
        
        // Track pending connection for rapid switching protection
        pendingConnectionRef.current = newWs
        connectingJobIdRef.current = jobId

        // Setup event listeners for new connection
        newWs.on('connected', () => {
          console.log(`[WebSocket] New connection established to job: ${jobId}`)
          
          // Clear pending connection tracking
          if (pendingConnectionRef.current === newWs) {
            pendingConnectionRef.current = null
            connectingJobIdRef.current = null
          }
          
          // CLEANUP: Remove all event listeners from old connection before disconnecting
          if (oldWs && oldJobId !== jobId) {
            console.log(`[WebSocket] Cleaning up and disconnecting old connection from job: ${oldJobId}`)
            oldWs.removeAllListeners()
            oldWs.disconnect()
          }
          
          // Update state
          setIsConnected(true)
          setError(null)
          currentJobIdRef.current = jobId
          wsRef.current = newWs
          optionsRef.current.onConnect?.()
        })

        newWs.on('disconnected', (code: number, reason: string) => {
          console.log(`[WebSocket] Disconnected from job: ${jobId}`, {
            code,
            reason,
          })
          
          // Clear pending connection tracking if this was the pending connection
          if (pendingConnectionRef.current === newWs) {
            pendingConnectionRef.current = null
            connectingJobIdRef.current = null
          }
          
          // Only update state if this is still the current connection
          if (currentJobIdRef.current === jobId) {
            setIsConnected(false)
            currentJobIdRef.current = null
            wsRef.current = null
          }
          
          optionsRef.current.onDisconnect?.()
        })

        newWs.on('error', (err: Error) => {
          console.error(`[WebSocket] Error for job: ${jobId}`, err)
          
          // Clear pending connection tracking on error
          if (pendingConnectionRef.current === newWs) {
            pendingConnectionRef.current = null
            connectingJobIdRef.current = null
          }
          
          setError(err?.message || 'WebSocket error')
          optionsRef.current.onError?.(err)
        })

        // Listen for job notification messages
        newWs.on('job_notification', handleMessage)
        newWs.on('job_processing', handleMessage)
        newWs.on('job_completed', handleMessage)
        newWs.on('job_failed', handleMessage)
        newWs.on('job_paused', handleMessage)

        // Connect to new WebSocket (this will trigger 'connected' event)
        await newWs.connect()
        
      } catch (err) {
        console.error(`[WebSocket] Failed to connect to job: ${jobId}`, err)
        
        // Clear pending connection tracking on failure
        if (connectingJobIdRef.current === jobId) {
          pendingConnectionRef.current = null
          connectingJobIdRef.current = null
        }
        
        setError(err instanceof Error ? err.message : 'Connection failed')
        setIsConnected(false)
        
        // If new connection failed, keep old connection if it exists
        if (oldWs && oldJobId) {
          console.log(`[WebSocket] Keeping old connection to job: ${oldJobId}`)
          wsRef.current = oldWs
          currentJobIdRef.current = oldJobId
        }
      }
    },
    [handleMessage, isConnected]
  )

  /**
   * Disconnect from current WebSocket
   */
  const disconnect = useCallback(() => {
    // Cancel any pending connection
    if (pendingConnectionRef.current) {
      console.log(`[WebSocket] Canceling pending connection to job: ${connectingJobIdRef.current}`)
      pendingConnectionRef.current.removeAllListeners()
      pendingConnectionRef.current.disconnect()
      pendingConnectionRef.current = null
      connectingJobIdRef.current = null
    }
    
    // Disconnect current connection
    if (wsRef.current) {
      console.log(
        `[WebSocket] Disconnecting from job: ${currentJobIdRef.current}`
      )
      wsRef.current.removeAllListeners()
      wsRef.current.disconnect()
      wsRef.current = null
      setIsConnected(false)
      currentJobIdRef.current = null
    }
  }, [])

  /**
   * Clear content list
   */
  const clearContent = useCallback(() => {
    setContentList([])
    setTotalContentCount(0)
    contentIdsRef.current.clear()
  }, [])

  // Main effect: Connect/disconnect based on URL param (only if auto-connect is enabled)
  useEffect(() => {
    // Skip if auto-connect is disabled
    if (disableAutoConnect) {
      return
    }

    // Skip if job param is empty string or invalid
    const hasJobParam = jobId !== null && jobId !== undefined && jobId !== ''

    if (hasJobParam) {
      // Connect to WebSocket for this job
      if (currentJobIdRef.current !== jobId) {
        console.log(`[WebSocket] URL changed to job: ${jobId}`)
        connectToJob(jobId)
      }
    } else {
      // No job param → disconnect immediately
      if (currentJobIdRef.current !== null) {
        console.log(`[WebSocket] No job param, disconnecting`)
        disconnect()
      }
    }

    // Cleanup on unmount
    return () => {
      disconnect()
    }
  }, [jobId, connectToJob, disconnect, disableAutoConnect])

  // Cleanup on component unmount
  useEffect(() => {
    return () => {
      if (wsRef.current) {
        console.log(`[WebSocket] Component unmounting, disconnecting`)
        wsRef.current.disconnect()
      }
    }
  }, [])

  return {
    isConnected,
    error,
    jobId: currentJobIdRef.current,
    status,
    platform,
    progress,
    currentKeyword,
    contentList,
    totalContentCount,
    disconnect,
    connect: connectToJob,
    clearContent,
  }
}
