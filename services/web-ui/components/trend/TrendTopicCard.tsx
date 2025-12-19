import React from 'react'
import { motion } from 'framer-motion'
import {
  TrendingUp,
  TrendingDown,
  Users,
  MessageSquare,
  ExternalLink,
  BarChart3,
  Target,
  Calendar,
  Bookmark,
  BookmarkCheck,
  Share2
} from 'lucide-react'
import { useTranslation } from 'next-i18next'
import { TrendTopic, useTrend } from '@/contexts/TrendContext'

interface TrendTopicCardProps {
  topic: TrendTopic
  onClick: () => void
}

export default function TrendTopicCard({ topic, onClick }: TrendTopicCardProps) {
  const { t } = useTranslation('common')
  const { toggleSavedItem, isItemSaved } = useTrend()
  const isSaved = isItemSaved('topics', topic.id)

  const getSentimentColor = (sentiment: 'positive' | 'neutral' | 'negative') => {
    switch (sentiment) {
      case 'positive': return 'text-green-600 bg-green-100'
      case 'neutral': return 'text-gray-600 bg-gray-100'
      case 'negative': return 'text-red-600 bg-red-100'
    }
  }

  const getDominantSentiment = () => {
    const { positive, neutral, negative } = topic.sentiment
    if (positive >= neutral && positive >= negative) return 'positive'
    if (negative >= neutral && negative >= positive) return 'negative'
    return 'neutral'
  }

  const dominantSentiment = getDominantSentiment()

  const handleSave = (e: React.MouseEvent) => {
    e.stopPropagation()
    toggleSavedItem('topics', topic.id)
  }

  const handleShare = (e: React.MouseEvent) => {
    e.stopPropagation()

    console.log('Share topic:', topic.name)
  }

  return (
    <motion.div
      whileHover={{ scale: 1.02, y: -4 }}
      whileTap={{ scale: 0.98 }}
      onClick={onClick}
      className="bg-card border border-border rounded-lg p-6 cursor-pointer hover:shadow-lg transition-all group"
    >
      {}
      <div className="flex items-start justify-between mb-4">
        <div className="flex-1">
          <h3 className="text-lg font-semibold mb-2 group-hover:text-primary transition-colors">
            {topic.name}
          </h3>
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <Calendar className="h-4 w-4" />
            <span>Updated {topic.createdAt.toLocaleDateString()}</span>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <div className={`px-2 py-1 rounded-full text-xs font-medium ${getSentimentColor(dominantSentiment)}`}>
            {dominantSentiment}
          </div>
          <button
            onClick={handleSave}
            className="p-1 hover:bg-muted rounded transition-colors"
            title={isSaved ? t('trendAnalysis.removeFromSaved') : t('trendAnalysis.saveTopic')}
          >
            {isSaved ? (
              <BookmarkCheck className="h-4 w-4 text-primary" />
            ) : (
              <Bookmark className="h-4 w-4 text-muted-foreground hover:text-primary transition-colors" />
            )}
          </button>
          <button
            onClick={handleShare}
            className="p-1 hover:bg-muted rounded transition-colors"
            title={t('trendAnalysis.shareTopic')}
          >
            <Share2 className="h-4 w-4 text-muted-foreground hover:text-primary transition-colors" />
          </button>
          <ExternalLink className="h-4 w-4 text-muted-foreground group-hover:text-primary transition-colors" />
        </div>
      </div>

      {}
      <div className="grid grid-cols-2 gap-4 mb-4">
        <div className="flex items-center gap-2">
          <Users className="h-4 w-4 text-muted-foreground" />
          <div>
            <p className="text-sm font-medium">{topic.volume.toLocaleString()}</p>
            <p className="text-xs text-muted-foreground">Volume</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <BarChart3 className="h-4 w-4 text-muted-foreground" />
          <div>
            <p className="text-sm font-medium">{(topic.confidence * 100).toFixed(0)}%</p>
            <p className="text-xs text-muted-foreground">{t('trendAnalysis.confidence')}</p>
          </div>
        </div>
      </div>

      {}
      <div className="flex items-center gap-2 mb-4">
        {topic.delta > 0 ? (
          <TrendingUp className="h-4 w-4 text-green-600" />
        ) : (
          <TrendingDown className="h-4 w-4 text-red-600" />
        )}
        <span className={`text-sm font-medium ${
          topic.delta > 0 ? 'text-green-600' : 'text-red-600'
        }`}>
          {topic.delta > 0 ? '+' : ''}{topic.delta.toFixed(1)}%
        </span>
        <span className="text-xs text-muted-foreground">vs last period</span>
      </div>

      {}
      <div className="mb-4">
        <p className="text-xs font-medium text-muted-foreground mb-2">Sentiment Distribution</p>
        <div className="flex gap-1 h-2 bg-muted rounded-full overflow-hidden">
          <div
            className="bg-green-500 h-full"
            style={{ width: `${topic.sentiment.positive}%` }}
          />
          <div
            className="bg-gray-500 h-full"
            style={{ width: `${topic.sentiment.neutral}%` }}
          />
          <div
            className="bg-red-500 h-full"
            style={{ width: `${topic.sentiment.negative}%` }}
          />
        </div>
        <div className="flex justify-between text-xs text-muted-foreground mt-1">
          <span>{topic.sentiment.positive}% pos</span>
          <span>{topic.sentiment.neutral}% neu</span>
          <span>{topic.sentiment.negative}% neg</span>
        </div>
      </div>

      {}
      <div className="mb-4">
        <p className="text-xs font-medium text-muted-foreground mb-2">Keywords</p>
        <div className="flex flex-wrap gap-1">
          {topic.keywords.slice(0, 4).map((keyword, index) => (
            <span
              key={index}
              className="px-2 py-1 bg-muted text-xs rounded-md text-muted-foreground"
            >
              {keyword}
            </span>
          ))}
          {topic.keywords.length > 4 && (
            <span className="px-2 py-1 bg-muted text-xs rounded-md text-muted-foreground">
              +{topic.keywords.length - 4} more
            </span>
          )}
        </div>
      </div>

      {}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Target className="h-4 w-4 text-muted-foreground" />
          <div className="flex gap-1">
            {topic.platforms.map((platform, index) => (
              <div
                key={index}
                className="w-2 h-2 rounded-full bg-primary"
                title={platform}
              />
            ))}
          </div>
        </div>

        <div className="flex items-center gap-1 text-xs text-muted-foreground">
          <MessageSquare className="h-3 w-3" />
          <span>{topic.samplePosts.length} samples</span>
        </div>
      </div>
    </motion.div>
  )
}
