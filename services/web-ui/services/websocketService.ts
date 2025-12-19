import { EventEmitter } from 'events'
import type {
  ProjectNotificationMessage,
  JobNotificationMessage,
} from '@/lib/types/websocket'

/**
 * Legacy WebSocket message format (deprecated)
 * Old format: { type: string, data: any, timestamp: number }
 * @deprecated Use ProjectNotificationMessage or JobNotificationMessage instead
 */
export interface WebSocketMessage {
  type: string
  data: any
  timestamp: number
}

/**
 * New WebSocket message format
 * Messages are now flat structures without type wrapper:
 * - Project: { status, progress? }
 * - Job: { platform, status, batch?, progress? }
 */
export type NewWebSocketMessage = ProjectNotificationMessage | JobNotificationMessage

export interface WebSocketConfig {
  url: string
  reconnectInterval?: number
  maxReconnectAttempts?: number
  heartbeatInterval?: number
  connectionTimeout?: number
}

export class WebSocketService extends EventEmitter {
  private ws: WebSocket | null = null
  private config: WebSocketConfig
  private reconnectAttempts = 0
  private reconnectTimeout: NodeJS.Timeout | null = null
  private heartbeatInterval: NodeJS.Timeout | null = null
  private isConnecting = false
  private isConnected = false
  private shouldReconnect = true

  constructor(config: WebSocketConfig) {
    super()
    this.config = {
      reconnectInterval: 5000,
      maxReconnectAttempts: 5,
      heartbeatInterval: 30000,
      connectionTimeout: 10000, // 10 seconds
      ...config
    }
  }

  connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      if (this.isConnecting || this.isConnected) {
        resolve()
        return
      }

      this.isConnecting = true
      this.shouldReconnect = true

      // Setup connection timeout
      const timeoutId = setTimeout(() => {
        if (!this.isConnected && this.ws) {
          console.error('[WebSocket] Connection timeout:', {
            url: this.config.url,
            timeout: this.config.connectionTimeout
          })
          this.isConnecting = false
          this.ws.close()
          reject(new Error('Connection timeout'))
        }
      }, this.config.connectionTimeout!)

      try {
        this.ws = new WebSocket(this.config.url)

        this.ws.onopen = () => {
          clearTimeout(timeoutId) // Clear timeout on successful connection
          this.isConnected = true
          this.isConnecting = false
          this.reconnectAttempts = 0
          this.emit('connected')
          this.startHeartbeat()
          resolve()
        }

        this.ws.onmessage = (event) => {
          try {
            const rawMessage = JSON.parse(event.data)

            // Emit raw message for all listeners
            this.emit('message', rawMessage)

            // Priority 1: Check for phase-based format (new format with type wrapper)
            // Format: { type: "project_progress" | "project_completed", payload: {...} }
            if ('type' in rawMessage && ('payload' in rawMessage)) {
              const messageType = rawMessage.type
              if (messageType === 'project_progress' || messageType === 'project_completed') {
                // Phase-based project notification
                this.emit('project_phase_notification', rawMessage)
                this.emit(messageType, rawMessage.payload)

                // Also emit status-specific events from payload
                if (rawMessage.payload?.status) {
                  this.emit(`project_phase_${rawMessage.payload.status.toLowerCase()}`, rawMessage)
                }
                return
              }
            }

            // Priority 2: Check for flat format (status at root, no type wrapper)
            // Format: { status, progress? } or { platform, status, batch?, progress? }
            if ('status' in rawMessage && !('type' in rawMessage)) {
              if ('platform' in rawMessage) {
                // Job notification (flat format)
                this.emit('job_notification', rawMessage)
                this.emit(`job_${rawMessage.status.toLowerCase()}`, rawMessage)
              } else {
                // Project notification (legacy flat format)
                this.emit('project_notification', rawMessage)
                this.emit(`project_${rawMessage.status.toLowerCase()}`, rawMessage)
              }
              return
            }

            // Priority 3: Legacy wrapped format { type, data, timestamp }
            if ('type' in rawMessage && 'data' in rawMessage) {
              const legacyMessage = rawMessage as WebSocketMessage
              this.emit(legacyMessage.type, legacyMessage.data)
            }
          } catch (error) {
            this.emit('error', new Error('Failed to parse message'))
          }
        }

        this.ws.onclose = (event) => {
          clearTimeout(timeoutId) // Clear timeout on close
          this.isConnected = false
          this.isConnecting = false
          this.stopHeartbeat()
          this.emit('disconnected', event.code, event.reason)

          // Only reconnect if shouldReconnect is true and connection wasn't clean
          if (this.shouldReconnect && !event.wasClean && this.reconnectAttempts < this.config.maxReconnectAttempts!) {
            this.scheduleReconnect()
          }
        }

        this.ws.onerror = (error) => {
          clearTimeout(timeoutId) // Clear timeout on error
          this.isConnecting = false
          console.error('[WebSocket] Connection error:', {
            url: this.config.url,
            error,
            readyState: this.ws?.readyState
          })
          this.emit('error', error)
          reject(error)
        }

      } catch (error) {
        clearTimeout(timeoutId) // Clear timeout on exception
        this.isConnecting = false
        reject(error)
      }
    })
  }

  disconnect(): void {
    // Prevent any reconnection attempts
    this.shouldReconnect = false
    this.reconnectAttempts = 0

    this.stopHeartbeat()
    this.clearReconnectTimeout()

    if (this.ws) {
      this.ws.close(1000, 'Client disconnect')
      this.ws = null
    }

    this.isConnected = false
    this.isConnecting = false
  }

  send(message: WebSocketMessage): void {
    if (this.isConnected && this.ws) {
      this.ws.send(JSON.stringify(message))
    } else {
      throw new Error('WebSocket is not connected')
    }
  }

  /**
   * Start heartbeat mechanism
   * 
   * Note: Per new specification, ping/pong is handled automatically by the browser.
   * This heartbeat is kept for connection health monitoring but can be disabled
   * by setting heartbeatInterval to 0 in config.
   */
  private startHeartbeat(): void {
    // Skip heartbeat if interval is 0 or not set
    if (!this.config.heartbeatInterval) {
      return
    }

    this.heartbeatInterval = setInterval(() => {
      if (this.isConnected) {
        // Send ping message for connection health check
        // Server may or may not respond to this
        try {
          this.send({
            type: 'ping',
            data: { timestamp: Date.now() },
            timestamp: Date.now()
          })
        } catch {
          // Ignore send errors during heartbeat
        }
      }
    }, this.config.heartbeatInterval)
  }

  private stopHeartbeat(): void {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval)
      this.heartbeatInterval = null
    }
  }

  private scheduleReconnect(): void {
    // Don't schedule reconnect if shouldReconnect is false
    if (!this.shouldReconnect) {
      return
    }

    this.reconnectAttempts++
    const delay = this.config.reconnectInterval! * Math.pow(2, this.reconnectAttempts - 1)

    this.reconnectTimeout = setTimeout(() => {
      // Double check before reconnecting
      if (!this.shouldReconnect) {
        return
      }

      this.emit('reconnecting', this.reconnectAttempts)
      this.connect().catch(() => {
        // Reconnect failed
      })
    }, delay)
  }

  private clearReconnectTimeout(): void {
    if (this.reconnectTimeout) {
      clearTimeout(this.reconnectTimeout)
      this.reconnectTimeout = null
    }
  }

  getConnectionState(): {
    isConnected: boolean
    isConnecting: boolean
    reconnectAttempts: number
  } {
    return {
      isConnected: this.isConnected,
      isConnecting: this.isConnecting,
      reconnectAttempts: this.reconnectAttempts
    }
  }
}

/**
 * Default WebSocket base URL
 * Port changed from 8080 to 8081 per new specification
 */
const DEFAULT_WS_URL = 'ws://localhost:8081/ws'

// Global dashboard WebSocket (for non-project specific updates)
export const dashboardWebSocket = new WebSocketService({
  url: process.env.NEXT_PUBLIC_WS_URL || DEFAULT_WS_URL,
  reconnectInterval: 3000,
  maxReconnectAttempts: 10,
  heartbeatInterval: 30000
})

/**
 * Create a project-specific WebSocket connection
 * 
 * URL pattern changed from path params to query params:
 * - Old: /ws/project/{projectId}
 * - New: /ws?projectId={projectId}
 * 
 * Authentication: HttpOnly Cookie (automatic)
 * 
 * @param projectId - The project ID to connect to
 * @returns WebSocketService instance configured for the project
 */
export function createProjectWebSocket(projectId: string): WebSocketService {
  const baseUrl = process.env.NEXT_PUBLIC_WS_URL || DEFAULT_WS_URL
  // Changed from path params to query params per new specification
  const projectUrl = `${baseUrl}?projectId=${projectId}`

  return new WebSocketService({
    url: projectUrl,
    reconnectInterval: 3000,
    maxReconnectAttempts: 10,
    heartbeatInterval: 30000
  })
}

/**
 * Create a job-specific WebSocket connection
 * 
 * URL pattern: /ws?jobId={jobId}
 * Authentication: HttpOnly Cookie (automatic)
 * 
 * Used for real-time job progress and content streaming.
 * Replaces the old dry-run WebSocket flow.
 * 
 * @param jobId - The job ID to connect to
 * @returns WebSocketService instance configured for the job
 */
export function createJobWebSocket(jobId: string): WebSocketService {
  const baseUrl = process.env.NEXT_PUBLIC_WS_URL || DEFAULT_WS_URL
  const jobUrl = `${baseUrl}?jobId=${jobId}`

  return new WebSocketService({
    url: jobUrl,
    reconnectInterval: 3000,
    maxReconnectAttempts: 10,
    heartbeatInterval: 30000
  })
}
