import React from 'react'
import { motion } from 'framer-motion'
import { Hash, Loader2, CheckCircle, PauseCircle } from 'lucide-react'
import type { Progress, JobStatus } from '@/lib/types/websocket'

interface BatchIndicatorProps {
  keyword: string | null
  progress: Progress | null
  status: JobStatus | null
}

export default function BatchIndicator({
  keyword,
  progress,
  status,
}: BatchIndicatorProps) {
  const isProcessing = status === 'PROCESSING'
  const isPaused = status === 'PAUSED'
  const isCompleted = status === 'COMPLETED'

  return (
    <motion.div
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      className={`p-3 rounded-lg border ${
        isPaused
          ? 'bg-yellow-50 dark:bg-yellow-900/20 border-yellow-200 dark:border-yellow-800'
          : isCompleted
            ? 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800'
            : 'bg-muted/50 border-border'
      }`}
    >
      <div className="flex items-center gap-3">
        {/* Status icon */}
        <div
          className={`flex items-center justify-center w-8 h-8 rounded-full ${
            isPaused
              ? 'bg-yellow-100 dark:bg-yellow-800'
              : isCompleted
                ? 'bg-green-100 dark:bg-green-800'
                : 'bg-primary/10'
          }`}
        >
          {isProcessing ? (
            <Loader2 className="h-4 w-4 text-primary animate-spin" />
          ) : isPaused ? (
            <PauseCircle className="h-4 w-4 text-yellow-600" />
          ) : isCompleted ? (
            <CheckCircle className="h-4 w-4 text-green-600" />
          ) : (
            <Hash className="h-4 w-4 text-muted-foreground" />
          )}
        </div>

        {/* Keyword info */}
        <div className="flex-1 min-w-0">
          <div className="text-xs text-muted-foreground mb-0.5">
            {isCompleted
              ? 'Hoàn thành tất cả từ khóa'
              : isPaused
                ? 'Đã tạm dừng tại từ khóa'
                : 'Đang xử lý từ khóa'}
          </div>
          {keyword ? (
            <div className="flex items-center gap-1">
              <Hash className="h-3 w-3 text-muted-foreground" />
              <span className="font-medium text-sm truncate">{keyword}</span>
            </div>
          ) : (
            <div className="text-sm text-muted-foreground">
              {isCompleted ? 'Tất cả từ khóa đã được xử lý' : 'Đang chờ...'}
            </div>
          )}
        </div>

        {/* Batch count */}
        {progress && (
          <div className="text-right">
            <div className="text-xs text-muted-foreground">Batch</div>
            <div className="text-sm font-medium">
              {progress.current}/{progress.total}
            </div>
          </div>
        )}
      </div>

      {/* Mini progress bar */}
      {progress && !isCompleted && (
        <div className="mt-2">
          <div className="w-full bg-muted rounded-full h-1">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${progress.percentage}%` }}
              transition={{ duration: 0.3 }}
              className={`h-1 rounded-full ${
                isPaused ? 'bg-yellow-500' : 'bg-primary'
              }`}
            />
          </div>
        </div>
      )}
    </motion.div>
  )
}
