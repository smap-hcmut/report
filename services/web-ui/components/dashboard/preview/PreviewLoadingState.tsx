import React from 'react'
import { motion } from 'framer-motion'
import { Loader2 } from 'lucide-react'
import { useTranslation } from 'next-i18next'

export default function PreviewLoadingState() {
  const { t } = useTranslation('common')

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="space-y-6"
    >
      {/* Header Skeleton */}
      <div className="space-y-2">
        <div className="h-8 w-64 bg-gray-300 dark:bg-gray-700 rounded animate-pulse" />
        <div className="h-4 w-96 bg-gray-200 dark:bg-gray-800 rounded animate-pulse" />
      </div>

      {/* Loading Indicator */}
      <div className="flex flex-col items-center justify-center py-12 space-y-4">
        <Loader2 className="w-12 h-12 text-blue-600 dark:text-blue-400 animate-spin" />
        <p className="text-lg font-semibold text-gray-700 dark:text-gray-300">
          {t('preview.loading')}
        </p>
        <p className="text-sm text-gray-600 dark:text-gray-400">
          {t('preview.loadingSubtext')}
        </p>
      </div>

      {/* Metrics Skeleton */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        {[...Array(5)].map((_, i) => (
          <div
            key={i}
            className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-xl p-4 animate-pulse"
          >
            <div className="w-10 h-10 bg-gray-300 dark:bg-gray-700 rounded-lg mb-3" />
            <div className="h-3 w-20 bg-gray-200 dark:bg-gray-800 rounded mb-2" />
            <div className="h-6 w-16 bg-gray-300 dark:bg-gray-700 rounded" />
          </div>
        ))}
      </div>

      {/* Posts Skeleton */}
      <div className="space-y-4">
        {[...Array(3)].map((_, i) => (
          <div
            key={i}
            className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-xl p-6 animate-pulse"
          >
            <div className="flex items-center gap-3 mb-4">
              <div className="w-12 h-12 bg-gray-300 dark:bg-gray-700 rounded-full" />
              <div className="flex-1">
                <div className="h-4 w-32 bg-gray-300 dark:bg-gray-700 rounded mb-2" />
                <div className="h-3 w-24 bg-gray-200 dark:bg-gray-800 rounded" />
              </div>
            </div>
            <div className="space-y-2">
              <div className="h-4 w-full bg-gray-200 dark:bg-gray-800 rounded" />
              <div className="h-4 w-5/6 bg-gray-200 dark:bg-gray-800 rounded" />
              <div className="h-4 w-4/6 bg-gray-200 dark:bg-gray-800 rounded" />
            </div>
          </div>
        ))}
      </div>
    </motion.div>
  )
}
