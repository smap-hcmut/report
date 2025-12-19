import React from 'react'
import { motion } from 'framer-motion'
import {
  Heart,
  Share2,
  MessageCircle,
  Eye,
  ExternalLink,
  Calendar,
  User,
  ThumbsUp,
  ThumbsDown,
  Minus,
  Bookmark,
  BookmarkCheck,
  BarChart3,
  TrendingUp,
  TrendingDown,
  Clock
} from 'lucide-react'
import { useTranslation } from 'next-i18next'
import { TrendPost, useTrend } from '@/contexts/TrendContext'

interface TrendPostCardProps {
  post: TrendPost
}

export default function TrendPostCard({ post }: TrendPostCardProps) {
  const { t } = useTranslation('common')
  const { toggleSavedItem, isItemSaved } = useTrend()
  const isSaved = isItemSaved('posts', post.id)

  const getSentimentIcon = (label: string) => {
    switch (label) {
      case 'positive': return <ThumbsUp className="h-4 w-4 text-green-600" />
      case 'negative': return <ThumbsDown className="h-4 w-4 text-red-600" />
      default: return <Minus className="h-4 w-4 text-gray-600" />
    }
  }

  const getSentimentColor = (label: string) => {
    switch (label) {
      case 'positive': return 'text-green-600 bg-green-100'
      case 'negative': return 'text-red-600 bg-red-100'
      default: return 'text-gray-600 bg-gray-100'
    }
  }

  const formatTimeAgo = (date: Date) => {
    const now = new Date()
    const diffInHours = Math.floor((now.getTime() - date.getTime()) / (1000 * 60 * 60))

    if (diffInHours < 1) return 'Just now'
    if (diffInHours < 24) return `${diffInHours}h ago`
    const diffInDays = Math.floor(diffInHours / 24)
    return `${diffInDays}d ago`
  }

  const getPlatformColor = (platform: string) => {
    switch (platform.toLowerCase()) {
      case 'facebook': return 'bg-blue-100 text-blue-700'
      case 'instagram': return 'bg-pink-100 text-pink-700'
      case 'tiktok': return 'bg-black text-white'
      case 'twitter': return 'bg-blue-100 text-blue-700'
      case 'linkedin': return 'bg-blue-100 text-blue-700'
      case 'youtube': return 'bg-red-100 text-red-700'
      default: return 'bg-gray-100 text-gray-700'
    }
  }

  const getPlatformIcon = (platform: string) => {
    switch (platform.toLowerCase()) {
      case 'facebook': return '📘'
      case 'instagram': return '📷'
      case 'tiktok': return '🎵'
      case 'twitter': return '🐦'
      case 'linkedin': return '💼'
      case 'youtube': return '📺'
      default: return '📱'
    }
  }

  const calculateEngagementRate = () => {
    const totalEngagement = post.metrics.likes + post.metrics.comments + post.metrics.shares
    return ((totalEngagement / post.metrics.views) * 100).toFixed(1)
  }

  const handleSave = (e: React.MouseEvent) => {
    e.stopPropagation()
    toggleSavedItem('posts', post.id)
  }

  const handleShare = (e: React.MouseEvent) => {
    e.stopPropagation()

    console.log('Share post:', post.title)
  }

  return (
    <motion.div
      whileHover={{ scale: 1.01, y: -2 }}
      className="bg-card border border-border rounded-lg p-6 hover:shadow-lg transition-all group"
    >
      {}
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
            <User className="h-5 w-5 text-primary" />
          </div>
          <div>
            <h4 className="font-medium">{post.author}</h4>
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Clock className="h-3 w-3" />
              <span>{formatTimeAgo(post.publishedAt)}</span>
            </div>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <span className={`px-2 py-1 rounded-full text-xs font-medium ${getPlatformColor(post.platform)}`}>
            <span className="mr-1">{getPlatformIcon(post.platform)}</span>
            {post.platform}
          </span>
          <button
            onClick={handleSave}
            className="p-1 hover:bg-muted rounded transition-colors"
            title={isSaved ? 'Remove from saved' : 'Save post'}
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
            title="Share post"
          >
            <Share2 className="h-4 w-4 text-muted-foreground hover:text-primary transition-colors" />
          </button>
          <a
            href={post.canonicalUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="p-1 hover:bg-muted rounded transition-colors"
            title="View original post"
          >
            <ExternalLink className="h-4 w-4 text-muted-foreground" />
          </a>
        </div>
      </div>

      {}
      <div className="mb-4">
        <h3 className="font-semibold mb-2 group-hover:text-primary transition-colors">
          {post.title}
        </h3>
        <p className="text-muted-foreground text-sm line-clamp-3">
          {post.content}
        </p>
      </div>

      {}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          {getSentimentIcon(post.sentiment.label)}
          <span className={`px-2 py-1 rounded-full text-xs font-medium ${getSentimentColor(post.sentiment.label)}`}>
            {post.sentiment.label} ({(post.sentiment.score * 100).toFixed(0)}%)
          </span>
        </div>

        <div className="flex items-center gap-2">
          <BarChart3 className="h-4 w-4 text-muted-foreground" />
          <span className="text-sm font-medium text-muted-foreground">
            {calculateEngagementRate()}% ER
          </span>
        </div>
      </div>

      {}
      <div className="grid grid-cols-4 gap-4 mb-4">
        <div className="flex items-center gap-2">
          <Heart className="h-4 w-4 text-red-500" />
          <div>
            <p className="text-sm font-medium">{post.metrics.likes.toLocaleString()}</p>
            <p className="text-xs text-muted-foreground">Likes</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <MessageCircle className="h-4 w-4 text-blue-500" />
          <div>
            <p className="text-sm font-medium">{post.metrics.comments.toLocaleString()}</p>
            <p className="text-xs text-muted-foreground">Comments</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <Share2 className="h-4 w-4 text-green-500" />
          <div>
            <p className="text-sm font-medium">{post.metrics.shares.toLocaleString()}</p>
            <p className="text-xs text-muted-foreground">Shares</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <Eye className="h-4 w-4 text-purple-500" />
          <div>
            <p className="text-sm font-medium">{post.metrics.views.toLocaleString()}</p>
            <p className="text-xs text-muted-foreground">Views</p>
          </div>
        </div>
      </div>

      {}
      <div className="mb-4 p-3 bg-muted/50 rounded-lg">
        <div className="flex items-center justify-between text-sm">
          <span className="text-muted-foreground">Performance</span>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-1">
              <TrendingUp className="h-3 w-3 text-green-600" />
              <span className="text-green-600 font-medium">+12%</span>
            </div>
            <div className="flex items-center gap-1">
              <BarChart3 className="h-3 w-3 text-blue-600" />
              <span className="text-blue-600 font-medium">Top 5%</span>
            </div>
          </div>
        </div>
      </div>

      {}
      <div className="flex items-center justify-between pt-4 border-t border-border">
        <button className="text-sm text-primary hover:text-primary/80 transition-colors">
          View full post →
        </button>

        <div className="flex items-center gap-2">
          <button className="px-3 py-1 text-xs bg-muted hover:bg-muted/80 rounded-md transition-colors">
            Copy Link
          </button>
          <button className="px-3 py-1 text-xs bg-primary text-primary-foreground hover:bg-primary/90 rounded-md transition-colors">
            Analyze
          </button>
        </div>
      </div>
    </motion.div>
  )
}
