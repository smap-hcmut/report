import React from 'react'
import { motion } from 'framer-motion'
import { Eye, Heart, MessageCircle, Share2, TrendingUp } from 'lucide-react'
import { DryRunMetrics } from '@/lib/types/dryrun'
import { useTranslation } from 'next-i18next'

interface PreviewMetricsSummaryProps {
  metrics: DryRunMetrics
}

export default function PreviewMetricsSummary({ metrics }: PreviewMetricsSummaryProps) {
  const { t } = useTranslation('common')

  const metricCards = [
    {
      icon: Eye,
      label: t('preview.metrics.views'),
      value: metrics.totalViews,
      color: 'text-blue-600 dark:text-blue-400',
      bg: 'bg-blue-100 dark:bg-blue-900/40'
    },
    {
      icon: Heart,
      label: t('preview.metrics.likes'),
      value: metrics.totalLikes,
      color: 'text-red-600 dark:text-red-400',
      bg: 'bg-red-100 dark:bg-red-900/40'
    },
    {
      icon: MessageCircle,
      label: t('preview.metrics.comments'),
      value: metrics.totalComments,
      color: 'text-green-600 dark:text-green-400',
      bg: 'bg-green-100 dark:bg-green-900/40'
    },
    {
      icon: Share2,
      label: t('preview.metrics.shares'),
      value: metrics.totalShares,
      color: 'text-purple-600 dark:text-purple-400',
      bg: 'bg-purple-100 dark:bg-purple-900/40'
    },
    {
      icon: TrendingUp,
      label: t('preview.metrics.avgEngagement'),
      value: `${(metrics.avgEngagement * 100).toFixed(2)}%`,
      color: 'text-orange-600 dark:text-orange-400',
      bg: 'bg-orange-100 dark:bg-orange-900/40'
    }
  ]

  return (
    <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
      {metricCards.map((metric, index) => (
        <motion.div
          key={metric.label}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: index * 0.1 }}
          className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-xl p-4 shadow-brutal"
        >
          <div className={`w-10 h-10 ${metric.bg} rounded-lg flex items-center justify-center mb-3`}>
            <metric.icon className={`w-5 h-5 ${metric.color}`} />
          </div>
          <p className="text-sm text-gray-600 dark:text-gray-400 mb-1">{metric.label}</p>
          <p className="text-2xl font-black text-gray-900 dark:text-white">
            {typeof metric.value === 'number' ? metric.value.toLocaleString() : metric.value}
          </p>
        </motion.div>
      ))}
    </div>
  )
}
