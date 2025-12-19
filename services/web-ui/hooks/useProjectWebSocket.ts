/**
 * Hook to manage project-specific WebSocket connections
 * 
 * Updated for new WebSocket specification:
 * - URL pattern: /ws?projectId={projectId} (query params instead of path params)
 * - Authentication: HttpOnly Cookie (automatic, no token needed)
 * - Message format: { status, progress? } (flat structure, no type wrapper)
 * 
 * @see documents/websocket_frontend_integration.md
 */

import { useEffect, useRef, useState, useCallback } from 'react'
import { useRouter } from 'next/router'
import { WebSocketService, createProjectWebSocket } from '@/services/websocketService'
import type {
  ProjectNotificationMessage,
  ProjectStatus,
  Progress,
  PhaseProgress,
  ProjectPhaseMessage,
  PhaseBasedStatus,
} from '@/lib/types/websocket'
import { isPhaseBasedMessage } from '@/lib/types/websocket'

/**
 * Options for useProjectWebSocket hook
 */
interface UseProjectWebSocketOptions {
  /** Called when any message is received (raw message) */
  onMessage?: (message: ProjectNotificationMessage) => void
  /** Called when phase-based message is received */
  onPhaseMessage?: (message: ProjectPhaseMessage) => void
  /** Called when connection is established */
  onConnect?: () => void
  /** Called when connection is closed */
  onDisconnect?: () => void
  /** Called when an error occurs */
  onError?: (error: Error) => void
  /** Called when project status changes to PROCESSING */
  onProcessing?: (progress?: Progress) => void
  /** Called when project status changes to COMPLETED */
  onCompleted?: () => void
  /** Called when project status changes to FAILED */
  onFailed?: (errors?: string[]) => void
  /** Called when project status changes to PAUSED */
  onPaused?: () => void
  /** Called when crawl phase progress updates (phase-based format) */
  onCrawlProgress?: (crawl: PhaseProgress) => void
  /** Called when analyze phase progress updates (phase-based format) */
  onAnalyzeProgress?: (analyze: PhaseProgress) => void
}

/**
 * Return type for useProjectWebSocket hook
 */
interface UseProjectWebSocketReturn {
  /** Whether WebSocket is currently connected */
  isConnected: boolean
  /** Current error message if any */
  error: string | null
  /** Current project ID being monitored */
  projectId: string | null
  /** Current project status */
  status: ProjectStatus | null
  /** Current progress data (legacy format) */
  progress: Progress | null
  /** Crawl phase progress (phase-based format) */
  crawlProgress: PhaseProgress | null
  /** Analyze phase progress (phase-based format) */
  analyzeProgress: PhaseProgress | null
  /** Overall progress percentage (phase-based format) */
  overallPercent: number
  /** Manually disconnect from WebSocket */
  disconnect: () => void
  /** Manually connect to a specific project */
  connect: (projectId: string) => Promise<void>
}

/**
 * Hook to manage project-specific WebSocket connections
 * 
 * Automatically connects when URL has ?project={projectId} parameter.
 * Disconnects when leaving the page or project param is removed.
 * 
 * @example
 * ```tsx
 * const { isConnected, status, progress } = useProjectWebSocket({
 *   onCompleted: () => router.push('/results'),
 *   onFailed: (errors) => console.error('Failed:', errors),
 * })
 * ```
 */
export function useProjectWebSocket(
  options: UseProjectWebSocketOptions = {}
): UseProjectWebSocketReturn {
  const router = useRouter()
  const wsRef = useRef<WebSocketService | null>(null)
  const currentProjectIdRef = useRef<string | null>(null)
  const optionsRef = useRef(options)

  // Keep options ref updated
  optionsRef.current = options

  // State
  const [isConnected, setIsConnected] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [status, setStatus] = useState<ProjectStatus | null>(null)
  const [progress, setProgress] = useState<Progress | null>(null)

  // Phase-based state (new format)
  const [crawlProgress, setCrawlProgress] = useState<PhaseProgress | null>(null)
  const [analyzeProgress, setAnalyzeProgress] = useState<PhaseProgress | null>(null)
  const [overallPercent, setOverallPercent] = useState(0)

  // Extract project ID from URL
  const projectId = (router.query.project as string) || null

  /**
   * Handle incoming phase-based message
   * Format: { type: "project_progress" | "project_completed", payload: {...} }
   */
  const handlePhaseMessage = useCallback((message: ProjectPhaseMessage) => {
    const { payload, type } = message

    // Map phase-based status to ProjectStatus
    const mappedStatus = payload.status === 'DONE'
      ? 'COMPLETED' as ProjectStatus
      : payload.status === 'INITIALIZING'
        ? 'PROCESSING' as ProjectStatus
        : payload.status as ProjectStatus

    setStatus(mappedStatus)
    setCrawlProgress(payload.crawl || null)
    setAnalyzeProgress(payload.analyze || null)
    setOverallPercent(payload.overall_progress_percent)

    // Call phase message handler
    optionsRef.current.onPhaseMessage?.(message)

    // Call phase-specific callbacks
    if (payload.crawl) {
      optionsRef.current.onCrawlProgress?.(payload.crawl)
    }
    if (payload.analyze) {
      optionsRef.current.onAnalyzeProgress?.(payload.analyze)
    }

    // Call status-specific handlers
    switch (payload.status) {
      case 'PROCESSING':
        optionsRef.current.onProcessing?.()
        break
      case 'DONE':
        optionsRef.current.onCompleted?.()
        break
      case 'FAILED':
        optionsRef.current.onFailed?.()
        break
    }
  }, [])

  /**
   * Handle incoming project notification message (legacy flat format)
   */
  const handleMessage = useCallback((message: ProjectNotificationMessage) => {
    // Update state
    setStatus(message.status)
    setProgress(message.progress || null)

    // Update overall percent from legacy format
    if (message.progress?.percentage) {
      setOverallPercent(message.progress.percentage)
    }

    // Call general message handler
    optionsRef.current.onMessage?.(message)

    // Call status-specific handlers
    switch (message.status) {
      case 'PROCESSING':
        optionsRef.current.onProcessing?.(message.progress)
        break
      case 'COMPLETED':
        optionsRef.current.onCompleted?.()
        break
      case 'FAILED':
        optionsRef.current.onFailed?.(message.progress?.errors)
        break
      case 'PAUSED':
        optionsRef.current.onPaused?.()
        break
    }
  }, [])

  /**
   * Connect to WebSocket for specific project
   */
  const connectToProject = useCallback(async (projectId: string) => {
    // Disconnect existing connection if any
    if (wsRef.current) {
      wsRef.current.disconnect()
      wsRef.current = null
    }

    // Reset state
    setStatus(null)
    setProgress(null)
    setError(null)
    setCrawlProgress(null)
    setAnalyzeProgress(null)
    setOverallPercent(0)

    try {
      // Create new WebSocket connection for this project
      // URL is now: /ws?projectId={projectId}
      // Authentication via HttpOnly Cookie (automatic)
      const ws = createProjectWebSocket(projectId)

      // Setup event listeners
      ws.on('connected', () => {
        console.log(`[WebSocket] Connected to project: ${projectId}`)
        setIsConnected(true)
        setError(null)
        currentProjectIdRef.current = projectId
        optionsRef.current.onConnect?.()
      })

      ws.on('disconnected', (code: number, reason: string) => {
        console.log(`[WebSocket] Disconnected from project: ${projectId}`, { code, reason })
        setIsConnected(false)
        currentProjectIdRef.current = null
        optionsRef.current.onDisconnect?.()
      })

      ws.on('error', (err: Error) => {
        console.error(`[WebSocket] Error for project: ${projectId}`, err)
        setError(err?.message || 'WebSocket error')
        optionsRef.current.onError?.(err)
      })

      // Listen for phase-based format messages (new format with type wrapper)
      ws.on('project_phase_notification', handlePhaseMessage)

      // Listen for legacy flat format messages
      ws.on('project_notification', handleMessage)

      // Also listen for status-specific events (legacy)
      ws.on('project_processing', handleMessage)
      ws.on('project_completed', handleMessage)
      ws.on('project_failed', handleMessage)
      ws.on('project_paused', handleMessage)

      // Store reference and connect
      wsRef.current = ws
      await ws.connect()

    } catch (err) {
      console.error(`[WebSocket] Failed to connect to project: ${projectId}`, err)
      setError(err instanceof Error ? err.message : 'Connection failed')
      setIsConnected(false)
    }
  }, [handleMessage, handlePhaseMessage])

  /**
   * Disconnect from current WebSocket
   */
  const disconnect = useCallback(() => {
    if (wsRef.current) {
      console.log(`[WebSocket] Disconnecting from project: ${currentProjectIdRef.current}`)
      wsRef.current.disconnect()
      wsRef.current = null
      setIsConnected(false)
      setStatus(null)
      setProgress(null)
      setCrawlProgress(null)
      setAnalyzeProgress(null)
      setOverallPercent(0)
      currentProjectIdRef.current = null
    }
  }, [])

  // Main effect: Connect/disconnect based on URL param
  useEffect(() => {
    const hasProjectParam = projectId !== null && projectId !== undefined

    if (hasProjectParam) {
      // Connect to WebSocket for this project
      if (currentProjectIdRef.current !== projectId) {
        console.log(`[WebSocket] URL changed to project: ${projectId}`)
        connectToProject(projectId)
      }
    } else {
      // No project param → disconnect immediately
      if (currentProjectIdRef.current !== null) {
        console.log(`[WebSocket] No project param, disconnecting`)
        disconnect()
      }
    }

    // Cleanup on unmount or when dependencies change
    return () => {
      disconnect()
    }
  }, [projectId, connectToProject, disconnect])

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
    projectId: currentProjectIdRef.current,
    status,
    progress,
    crawlProgress,
    analyzeProgress,
    overallPercent,
    disconnect,
    connect: connectToProject,
  }
}
