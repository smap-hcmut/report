import React from 'react'
import { motion } from 'framer-motion'
import { AlertCircle, ArrowLeft, RefreshCw } from 'lucide-react'
import { useTranslation } from 'next-i18next'

interface PreviewErrorStateProps {
  error: string
  onBack: () => void
  onRetry?: () => void
}

export default function PreviewErrorState({
  error,
  onBack,
  onRetry
}: PreviewErrorStateProps) {
  const { t } = useTranslation('common')

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      className="flex flex-col items-center justify-center py-12 space-y-6"
    >
      {/* Error Icon */}
      <div className="w-20 h-20 bg-red-100 dark:bg-red-900/40 rounded-full flex items-center justify-center">
        <AlertCircle className="w-10 h-10 text-red-600 dark:text-red-400" />
      </div>

      {/* Error Message */}
      <div className="text-center space-y-2">
        <h3 className="text-2xl font-black text-gray-900 dark:text-white">
          {t('preview.errorTitle')}
        </h3>
        <p className="text-gray-600 dark:text-gray-400 max-w-md">
          {error}
        </p>
      </div>

      {/* Action Buttons */}
      <div className="flex items-center gap-4">
        <button
          onClick={onBack}
          className="flex items-center gap-2 px-6 py-3 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 rounded-lg font-semibold hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
          {t('common.back')}
        </button>

        {onRetry && (
          <button
            onClick={onRetry}
            className="flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors"
          >
            <RefreshCw className="w-5 h-5" />
            {t('preview.retry')}
          </button>
        )}
      </div>
    </motion.div>
  )
}
