import React, { useState, useCallback } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Loader2,
  CheckCircle,
  XCircle,
  PauseCircle,
  Clock,
  AlertTriangle,
  Hash,
  Play,
  Square,
} from 'lucide-react'
import { useJobWebSocket } from '@/hooks/useJobWebSocket'
import {
  JobStatus,
  Platform,
  Progress,
  formatETA,
} from '@/lib/types/websocket'
import ContentFeed from './ContentFeed'
import BatchIndicator from './BatchIndicator'

// Platform icons (using simple text for now, can be replaced with actual icons)
const PlatformIcon: React.FC<{ platform: Platform | null; className?: string }> = ({
  platform,
  className = 'h-6 w-6',
}) => {
  switch (platform) {
    case 'TIKTOK':
      return (
        <svg className={className} viewBox="0 0 24 24" fill="currentColor">
          <path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 0 1-5.2 1.74 2.89 2.89 0 0 1 2.31-4.64 2.93 2.93 0 0 1 .88.13V9.4a6.84 6.84 0 0 0-1-.05A6.33 6.33 0 0 0 5 20.1a6.34 6.34 0 0 0 10.86-4.43v-7a8.16 8.16 0 0 0 4.77 1.52v-3.4a4.85 4.85 0 0 1-1-.1z" />
        </svg>
      )
    case 'YOUTUBE':
      return (
        <svg className={className} viewBox="0 0 24 24" fill="currentColor">
          <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
        </svg>
      )
    case 'INSTAGRAM':
      return (
        <svg className={className} viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z" />
        </svg>
      )
    default:
      return <Hash className={className} />
  }
}

// Platform colors
const getPlatformColor = (platform: Platform | null): string => {
  switch (platform) {
    case 'TIKTOK':
      return 'text-black dark:text-white'
    case 'YOUTUBE':
      return 'text-red-600'
    case 'INSTAGRAM':
      return 'text-pink-600'
    default:
      return 'text-gray-600'
  }
}

const getPlatformBg = (platform: Platform | null): string => {
  switch (platform) {
    case 'TIKTOK':
      return 'bg-gray-100 dark:bg-gray-800'
    case 'YOUTUBE':
      return 'bg-red-100 dark:bg-red-900/30'
    case 'INSTAGRAM':
      return 'bg-gradient-to-br from-purple-100 to-pink-100 dark:from-purple-900/30 dark:to-pink-900/30'
    default:
      return 'bg-gray-100 dark:bg-gray-800'
  }
}

interface JobProgressStateProps {
  jobId: string
  /** Called when job completes */
  onComplete?: () => void
  /** Called when job fails */
  onFailed?: (errors?: string[]) => void
}

export default function JobProgressState({
  jobId,
  onComplete,
  onFailed,
}: JobProgressStateProps) {
  const [showErrors, setShowErrors] = useState(false)

  // WebSocket connection
  const {
    isConnected,
    status,
    platform,
    progress,
    currentKeyword,
    contentList,
    totalContentCount,
    error,
  } = useJobWebSocket({
    onCompleted: () => {
      console.log('Job completed:', jobId)
      onComplete?.()
    },
    onFailed: (errors) => {
      console.log('Job failed:', jobId, errors)
      onFailed?.(errors)
    },
  })

  // Get status message
  const getStatusMessage = useCallback(
    (status: JobStatus | null): string => {
      switch (status) {
        case 'PROCESSING':
          return 'Đang thu thập dữ liệu...'
        case 'COMPLETED':
          return 'Hoàn thành!'
        case 'FAILED':
          return 'Thu thập thất bại'
        case 'PAUSED':
          return 'Đã tạm dừng'
        default:
          return isConnected ? 'Đang chờ...' : 'Đang kết nối...'
      }
    },
    [isConnected]
  )

  // Get status icon
  const getStatusIcon = useCallback((status: JobStatus | null) => {
    switch (status) {
      case 'PROCESSING':
        return <Loader2 className="h-5 w-5 animate-spin" />
      case 'COMPLETED':
        return <CheckCircle className="h-5 w-5 text-green-600" />
      case 'FAILED':
        return <XCircle className="h-5 w-5 text-red-600" />
      case 'PAUSED':
        return <PauseCircle className="h-5 w-5 text-yellow-600" />
      default:
        return <Loader2 className="h-5 w-5 animate-spin" />
    }
  }, [])

  const progressPercent = progress?.percentage ?? 0
  const hasPartialResults = contentList.length > 0


  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="p-4 border-b border-border">
        <div className="flex items-center justify-between mb-4">
          {/* Platform indicator */}
          <div className={`flex items-center gap-2 px-3 py-1.5 rounded-full ${getPlatformBg(platform)}`}>
            <PlatformIcon platform={platform} className={`h-5 w-5 ${getPlatformColor(platform)}`} />
            <span className={`text-sm font-medium ${getPlatformColor(platform)}`}>
              {platform || 'Unknown'}
            </span>
          </div>

          {/* Status indicator */}
          <div className="flex items-center gap-2">
            {getStatusIcon(status)}
            <span className="text-sm font-medium">{getStatusMessage(status)}</span>
          </div>
        </div>

        {/* Batch indicator */}
        {(status === 'PROCESSING' || currentKeyword) && (
          <BatchIndicator
            keyword={currentKeyword}
            progress={progress}
            status={status}
          />
        )}

        {/* Progress bar */}
        <div className="mt-4">
          <div className="flex items-center justify-between mb-1">
            <span className="text-xs text-muted-foreground">
              {progress?.current ?? 0} / {progress?.total ?? 0} batches
            </span>
            <div className="flex items-center gap-2">
              {progress?.eta && progress.eta > 0 && status === 'PROCESSING' && (
                <span className="text-xs text-muted-foreground flex items-center gap-1">
                  <Clock className="h-3 w-3" />
                  {formatETA(progress.eta)}
                </span>
              )}
              <span className="text-xs font-medium">{Math.round(progressPercent)}%</span>
            </div>
          </div>
          <div className="w-full bg-muted rounded-full h-1.5">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${progressPercent}%` }}
              transition={{ duration: 0.3 }}
              className={`h-1.5 rounded-full ${
                status === 'COMPLETED'
                  ? 'bg-green-600'
                  : status === 'FAILED'
                    ? 'bg-red-600'
                    : status === 'PAUSED'
                      ? 'bg-yellow-600'
                      : 'bg-primary'
              }`}
            />
          </div>
        </div>

        {/* Error list */}
        <AnimatePresence>
          {status === 'FAILED' && progress?.errors && progress.errors.length > 0 && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              className="mt-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg"
            >
              <div
                className="flex items-center justify-between cursor-pointer"
                onClick={() => setShowErrors(!showErrors)}
              >
                <div className="flex items-center gap-2">
                  <AlertTriangle className="h-4 w-4 text-red-600" />
                  <span className="text-sm text-red-700 dark:text-red-300">
                    {progress.errors.length} lỗi
                  </span>
                </div>
                <span className="text-xs text-red-600">{showErrors ? 'Ẩn' : 'Xem'}</span>
              </div>
              <AnimatePresence>
                {showErrors && (
                  <motion.ul
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    className="mt-2 space-y-1 text-xs text-red-600 max-h-24 overflow-y-auto"
                  >
                    {progress.errors.map((err, idx) => (
                      <li key={idx}>• {err}</li>
                    ))}
                  </motion.ul>
                )}
              </AnimatePresence>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Partial results notice */}
        {status === 'FAILED' && hasPartialResults && (
          <div className="mt-3 p-2 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded text-xs text-yellow-700 dark:text-yellow-300">
            Đã thu thập được {totalContentCount} nội dung. Bạn có thể xem kết quả một phần.
          </div>
        )}

        {/* PAUSED notice */}
        {status === 'PAUSED' && (
          <div className="mt-3 p-2 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded text-xs text-yellow-700 dark:text-yellow-300 flex items-center gap-2">
            <PauseCircle className="h-4 w-4" />
            Job đã tạm dừng. Đã thu thập {totalContentCount} nội dung.
          </div>
        )}

        {/* Action buttons */}
        <div className="mt-4 flex gap-2">
          {status === 'PROCESSING' && (
            <>
              <button className="flex-1 px-3 py-1.5 text-sm bg-yellow-100 text-yellow-700 rounded hover:bg-yellow-200 transition-colors flex items-center justify-center gap-1">
                <PauseCircle className="h-4 w-4" />
                Tạm dừng
              </button>
              <button className="flex-1 px-3 py-1.5 text-sm bg-red-100 text-red-700 rounded hover:bg-red-200 transition-colors flex items-center justify-center gap-1">
                <Square className="h-4 w-4" />
                Hủy
              </button>
            </>
          )}
          {status === 'PAUSED' && (
            <>
              <button className="flex-1 px-3 py-1.5 text-sm bg-green-100 text-green-700 rounded hover:bg-green-200 transition-colors flex items-center justify-center gap-1">
                <Play className="h-4 w-4" />
                Tiếp tục
              </button>
              <button className="flex-1 px-3 py-1.5 text-sm bg-red-100 text-red-700 rounded hover:bg-red-200 transition-colors flex items-center justify-center gap-1">
                <Square className="h-4 w-4" />
                Hủy
              </button>
            </>
          )}
        </div>

        {/* Content count */}
        <div className="mt-4 text-sm text-muted-foreground">
          Đã thu thập: <span className="font-medium text-foreground">{totalContentCount}</span> nội dung
        </div>
      </div>

      {/* Content Feed */}
      <div className="flex-1 overflow-hidden">
        <ContentFeed
          items={contentList}
          platform={platform}
          isLoading={status === 'PROCESSING'}
        />
      </div>

      {/* Connection error */}
      {error && (
        <div className="p-2 bg-red-50 dark:bg-red-900/20 text-xs text-red-600 text-center">
          Lỗi kết nối: {error}
        </div>
      )}
    </div>
  )
}
