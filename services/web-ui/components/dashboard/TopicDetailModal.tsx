import React from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  X,
  TrendingUp,
  TrendingDown,
  Users,
  MessageSquare,
  BarChart3,
  Target,
  Calendar,
  ExternalLink,
  Heart,
  Share2,
  Eye,
  Download,
  Bookmark,
  Hash
} from 'lucide-react'

interface TopicData {
  text: string
  value: number
  sentiment?: number
  confidence?: number
  trend?: 'rising' | 'falling' | 'stable'
  mentions?: number
  engagement?: number
}

interface TopicDetailModalProps {
  topic: TopicData | null
  isOpen: boolean
  onClose: () => void
}

export default function TopicDetailModal({ topic, isOpen, onClose }: TopicDetailModalProps) {
  if (!topic) return null

  const getSentimentColor = (sentiment: number = 0) => {
    if (sentiment > 0.1) return 'text-green-600 bg-green-100'
    if (sentiment < -0.1) return 'text-red-600 bg-red-100'
    return 'text-gray-600 bg-gray-100'
  }

  const getSentimentLabel = (sentiment: number = 0) => {
    if (sentiment > 0.1) return 'Positive'
    if (sentiment < -0.1) return 'Negative'
    return 'Neutral'
  }

  const getTrendIcon = (trend: string = 'stable') => {
    switch (trend) {
      case 'rising':
        return <TrendingUp className="h-4 w-4 text-green-600" />
      case 'falling':
        return <TrendingDown className="h-4 w-4 text-red-600" />
      default:
        return <BarChart3 className="h-4 w-4 text-gray-600" />
    }
  }

  const getTrendColor = (trend: string = 'stable') => {
    switch (trend) {
      case 'rising':
        return 'text-green-600'
      case 'falling':
        return 'text-red-600'
      default:
        return 'text-gray-600'
    }
  }

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50"
          />

          {}
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            transition={{ type: "spring", duration: 0.5 }}
            className="fixed inset-4 z-50 flex items-center justify-center p-4"
          >
            <div className="bg-white dark:bg-gray-900 border border-amber-300/60 dark:border-white/20 rounded-lg shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-hidden">
              {}
              <div className="p-6 border-b border-amber-300/60 dark:border-white/20 bg-white/50 dark:bg-gray-900/50">
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-3">
                    <div className="p-2 rounded-lg bg-primary/10">
                      <Hash className="h-6 w-6 text-primary" />
                    </div>
                    <div>
                      <h1 className="text-2xl font-bold">{topic.text}</h1>
                      <div className="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400">
                        <div className="flex items-center gap-2">
                          <Calendar className="h-4 w-4" />
                          <span>Updated {new Date().toLocaleDateString()}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <Target className="h-4 w-4" />
                          <span>Topic Analysis</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <div className={`px-3 py-1 rounded-full text-sm font-medium ${getSentimentColor(topic.sentiment)}`}>
                      {getSentimentLabel(topic.sentiment)}
                    </div>
                    <button
                      onClick={onClose}
                      className="p-2 hover:bg-muted rounded-lg transition-colors"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              </div>

              {}
              <div className="p-6 overflow-y-auto max-h-[calc(90vh-200px)]">
                {}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.1 }}
                    className="bg-muted/50 rounded-lg p-4"
                  >
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-blue-100">
                        <BarChart3 className="h-5 w-5 text-blue-600" />
                      </div>
                      <div>
                        <p className="text-sm text-gray-600 dark:text-gray-400">Frequency</p>
                        <p className="text-2xl font-bold">{topic.value}</p>
                      </div>
                    </div>
                  </motion.div>

                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.2 }}
                    className="bg-muted/50 rounded-lg p-4"
                  >
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-green-100">
                        <MessageSquare className="h-5 w-5 text-green-600" />
                      </div>
                      <div>
                        <p className="text-sm text-gray-600 dark:text-gray-400">Mentions</p>
                        <p className="text-2xl font-bold">{topic.mentions || 0}</p>
                      </div>
                    </div>
                  </motion.div>

                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.3 }}
                    className="bg-muted/50 rounded-lg p-4"
                  >
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-purple-100">
                        <Heart className="h-5 w-5 text-purple-600" />
                      </div>
                      <div>
                        <p className="text-sm text-gray-600 dark:text-gray-400">Engagement</p>
                        <p className="text-2xl font-bold">{topic.engagement || 0}</p>
                      </div>
                    </div>
                  </motion.div>

                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.4 }}
                    className="bg-muted/50 rounded-lg p-4"
                  >
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-orange-100">
                        {getTrendIcon(topic.trend)}
                      </div>
                      <div>
                        <p className="text-sm text-gray-600 dark:text-gray-400">Trend</p>
                        <p className={`text-2xl font-bold capitalize ${getTrendColor(topic.trend)}`}>
                          {topic.trend || 'stable'}
                        </p>
                      </div>
                    </div>
                  </motion.div>
                </div>

                {}
                <div className="space-y-6">
                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.5 }}
                    className="bg-muted/30 rounded-lg p-6"
                  >
                    <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                      <BarChart3 className="h-5 w-5" />
                      Sentiment Analysis
                    </h3>
                    <div className="space-y-3">
                      <div className="flex items-center justify-between">
                        <span className="text-gray-600 dark:text-gray-400">Sentiment Score</span>
                        <span className="font-medium">
                          {topic.sentiment ? topic.sentiment.toFixed(2) : '0.00'}
                        </span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span className="text-gray-600 dark:text-gray-400">Confidence</span>
                        <span className="font-medium">
                          {topic.confidence ? `${(topic.confidence * 100).toFixed(1)}%` : 'N/A'}
                        </span>
                      </div>
                    </div>
                  </motion.div>

                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.6 }}
                    className="bg-muted/30 rounded-lg p-6"
                  >
                    <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
                      <TrendingUp className="h-5 w-5" />
                      Performance Metrics
                    </h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div className="space-y-2">
                        <div className="flex items-center justify-between">
                          <span className="text-gray-600 dark:text-gray-400">Total Mentions</span>
                          <span className="font-medium">{topic.mentions || 0}</span>
                        </div>
                        <div className="flex items-center justify-between">
                          <span className="text-gray-600 dark:text-gray-400">Engagement Rate</span>
                          <span className="font-medium">{topic.engagement || 0}%</span>
                        </div>
                      </div>
                      <div className="space-y-2">
                        <div className="flex items-center justify-between">
                          <span className="text-gray-600 dark:text-gray-400">Frequency Score</span>
                          <span className="font-medium">{topic.value}</span>
                        </div>
                        <div className="flex items-center justify-between">
                          <span className="text-gray-600 dark:text-gray-400">Trend Direction</span>
                          <div className="flex items-center gap-1">
                            {getTrendIcon(topic.trend)}
                            <span className="font-medium capitalize">{topic.trend || 'stable'}</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </motion.div>
                </div>
              </div>

              {}
              <div className="p-6 border-t border-amber-300/60 dark:border-white/20 bg-white/50 dark:bg-gray-900/50">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <button className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors">
                      <Download className="h-4 w-4" />
                      Export Data
                    </button>
                    <button className="flex items-center gap-2 px-4 py-2 border border-amber-300/60 dark:border-white/20 rounded-lg hover:bg-muted transition-colors">
                      <Share2 className="h-4 w-4" />
                      Share
                    </button>
                  </div>
                  <button
                    onClick={onClose}
                    className="px-6 py-2 bg-muted text-gray-600 dark:text-gray-400 rounded-lg hover:bg-muted/80 transition-colors"
                  >
                    Close
                  </button>
                </div>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
