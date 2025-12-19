import React from 'react'
import { motion } from 'framer-motion'
import {
  TrendingUp,
  TrendingDown,
  Hash,
  MessageSquare,
  Users,
  BarChart3,
  Target,
  Clock
} from 'lucide-react'
import { useTranslation } from 'next-i18next'
import { useTrend } from '@/contexts/TrendContext'

export default function TrendMetrics() {
  const { t } = useTranslation('common')
  const { state, filteredTopics, filteredHashtags, filteredPosts } = useTrend()

  const totalVolume = filteredTopics.reduce((sum, topic) => sum + topic.volume, 0)
  const avgConfidence = filteredTopics.length > 0
    ? filteredTopics.reduce((sum, topic) => sum + topic.confidence, 0) / filteredTopics.length
    : 0
  const avgSentiment = filteredTopics.length > 0
    ? filteredTopics.reduce((sum, topic) => sum + topic.sentiment.positive, 0) / filteredTopics.length
    : 0
  const totalHashtagVolume = filteredHashtags.reduce((sum, hashtag) => sum + hashtag.volume, 0)
  const avgEngagementRate = filteredHashtags.length > 0
    ? filteredHashtags.reduce((sum, hashtag) => sum + hashtag.engagementRate, 0) / filteredHashtags.length
    : 0

  const metrics = [
    {
      id: 'total-topics',
      title: 'Active Topics',
      value: filteredTopics.length.toString(),
      delta: '+12%',
      trend: 'up' as const,
      icon: <Target className="h-5 w-5" />,
      color: 'text-blue-600'
    },
    {
      id: 'total-volume',
      title: 'Total Volume',
      value: totalVolume >= 1000 ? `${(totalVolume / 1000).toFixed(1)}K` : totalVolume.toString(),
      delta: '+8.3%',
      trend: 'up' as const,
      icon: <BarChart3 className="h-5 w-5" />,
      color: 'text-green-600'
    },
    {
      id: 'avg-confidence',
      title: 'Avg Confidence',
      value: `${(avgConfidence * 100).toFixed(0)}%`,
      delta: '+2.1%',
      trend: 'up' as const,
      icon: <TrendingUp className="h-5 w-5" />,
      color: 'text-purple-600'
    },
    {
      id: 'avg-sentiment',
      title: 'Avg Sentiment',
      value: `${avgSentiment.toFixed(0)}%`,
      delta: '-1.2%',
      trend: 'down' as const,
      icon: <MessageSquare className="h-5 w-5" />,
      color: 'text-orange-600'
    },
    {
      id: 'hashtag-volume',
      title: 'Hashtag Volume',
      value: totalHashtagVolume >= 1000 ? `${(totalHashtagVolume / 1000).toFixed(1)}K` : totalHashtagVolume.toString(),
      delta: '+15.7%',
      trend: 'up' as const,
      icon: <Hash className="h-5 w-5" />,
      color: 'text-pink-600'
    },
    {
      id: 'engagement-rate',
      title: 'Engagement Rate',
      value: `${avgEngagementRate.toFixed(1)}%`,
      delta: '+0.8%',
      trend: 'up' as const,
      icon: <Users className="h-5 w-5" />,
      color: 'text-indigo-600'
    }
  ]

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h3 className="text-lg font-semibold">Trend Overview</h3>
          <p className="text-sm text-muted-foreground">
            Real-time insights from {state.filters.timeRange} data
          </p>
        </div>

        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <Clock className="h-4 w-4" />
          <span>Last updated: {state.lastUpdate?.toLocaleTimeString() || 'Never'}</span>
        </div>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {metrics.map((metric, index) => (
          <motion.div
            key={metric.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            whileHover={{ scale: 1.05, y: -2 }}
            className="bg-background border border-border rounded-lg p-4 hover:shadow-md transition-all"
          >
            <div className="flex items-center justify-between mb-2">
              <div className={`p-2 rounded-lg bg-muted ${metric.color}`}>
                {metric.icon}
              </div>
              <div className="flex items-center gap-1">
                {metric.trend === 'up' ? (
                  <TrendingUp className="h-3 w-3 text-green-600" />
                ) : (
                  <TrendingDown className="h-3 w-3 text-red-600" />
                )}
                <span className={`text-xs font-medium ${
                  metric.trend === 'up' ? 'text-green-600' : 'text-red-600'
                }`}>
                  {metric.delta}
                </span>
              </div>
            </div>

            <div>
              <p className="text-2xl font-bold mb-1">{metric.value}</p>
              <p className="text-xs text-muted-foreground">{metric.title}</p>
            </div>
          </motion.div>
        ))}
      </div>

      {}
      <div className="mt-6 grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-muted/50 rounded-lg p-4">
          <h4 className="font-medium mb-2">Top Platform</h4>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-blue-500 rounded-full" />
            <span className="text-sm">Instagram (45%)</span>
          </div>
        </div>

        <div className="bg-muted/50 rounded-lg p-4">
          <h4 className="font-medium mb-2">Peak Activity</h4>
          <div className="flex items-center gap-2">
            <Clock className="h-4 w-4 text-muted-foreground" />
            <span className="text-sm">2:00 PM - 4:00 PM</span>
          </div>
        </div>

        <div className="bg-muted/50 rounded-lg p-4">
          <h4 className="font-medium mb-2">Trending Now</h4>
          <div className="flex items-center gap-2">
            <Hash className="h-4 w-4 text-muted-foreground" />
            <span className="text-sm">#coffee #sustainable</span>
          </div>
        </div>
      </div>
    </div>
  )
}
