import React from 'react'
import { motion } from 'framer-motion'
import {
  Hash,
  TrendingUp,
  TrendingDown,
  Users,
  MessageSquare,
  ExternalLink,
  BarChart3,
  Target,
  Bookmark,
  BookmarkCheck,
  Share2,
  Calendar,
  Eye,
  Heart
} from 'lucide-react'
import { useTranslation } from 'next-i18next'
import { TrendHashtag, useTrend } from '@/contexts/TrendContext'

interface TrendHashtagCardProps {
  hashtag: TrendHashtag
}

export default function TrendHashtagCard({ hashtag }: TrendHashtagCardProps) {
  const { t } = useTranslation('common')
  const { toggleSavedItem, isItemSaved } = useTrend()
  const isSaved = isItemSaved('hashtags', hashtag.id)

  const getEngagementColor = (rate: number) => {
    if (rate >= 5) return 'text-green-600 bg-green-100'
    if (rate >= 3) return 'text-yellow-600 bg-yellow-100'
    return 'text-red-600 bg-red-100'
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

  const handleSave = (e: React.MouseEvent) => {
    e.stopPropagation()
    toggleSavedItem('hashtags', hashtag.id)
  }

  const handleShare = (e: React.MouseEvent) => {
    e.stopPropagation()

    console.log('Share hashtag:', hashtag.hashtag)
  }

  return (
    <motion.div
      whileHover={{ scale: 1.02, y: -4 }}
      whileTap={{ scale: 0.98 }}
      className="bg-card border border-border rounded-lg p-6 hover:shadow-lg transition-all group"
    >
      {}
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-2">
          <Hash className="h-5 w-5 text-primary" />
          <h3 className="text-lg font-semibold group-hover:text-primary transition-colors">
            {hashtag.hashtag}
          </h3>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={handleSave}
            className="p-1 hover:bg-muted rounded transition-colors"
            title={isSaved ? 'Remove from saved' : 'Save hashtag'}
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
            title="Share hashtag"
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
            <p className="text-sm font-medium">{hashtag.volume.toLocaleString()}</p>
            <p className="text-xs text-muted-foreground">Volume</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <BarChart3 className="h-4 w-4 text-muted-foreground" />
          <div>
            <p className="text-sm font-medium">{hashtag.engagementRate.toFixed(1)}%</p>
            <p className="text-xs text-muted-foreground">Engagement</p>
          </div>
        </div>
      </div>

      {}
      <div className="mb-4">
        <div className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-sm font-medium ${getEngagementColor(hashtag.engagementRate)}`}>
          {hashtag.engagementRate >= 5 ? (
            <TrendingUp className="h-4 w-4" />
          ) : (
            <TrendingDown className="h-4 w-4" />
          )}
          {hashtag.engagementRate.toFixed(1)}% Engagement Rate
        </div>
      </div>

      {}
      <div className="mb-4">
        <p className="text-xs font-medium text-muted-foreground mb-2">Active Platforms</p>
        <div className="flex items-center gap-2">
          <Target className="h-4 w-4 text-muted-foreground" />
          <div className="flex gap-2">
            {hashtag.platforms.map((platform, index) => (
              <span
                key={index}
                className={`px-2 py-1 text-xs rounded-md font-medium ${getPlatformColor(platform)}`}
              >
                {platform}
              </span>
            ))}
          </div>
        </div>
      </div>

      {}
      <div className="grid grid-cols-2 gap-4 mb-4">
        <div className="flex items-center gap-2">
          <Eye className="h-4 w-4 text-muted-foreground" />
          <div>
            <p className="text-sm font-medium">{(hashtag.volume * 2.5).toLocaleString()}</p>
            <p className="text-xs text-muted-foreground">Est. Reach</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <Heart className="h-4 w-4 text-muted-foreground" />
          <div>
            <p className="text-sm font-medium">{(hashtag.volume * 0.15).toLocaleString()}</p>
            <p className="text-xs text-muted-foreground">Est. Likes</p>
          </div>
        </div>
      </div>

      {}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <MessageSquare className="h-4 w-4 text-muted-foreground" />
          <span className="text-sm text-muted-foreground">
            {hashtag.samplePosts.length} sample posts
          </span>
        </div>

        <button className="text-xs text-primary hover:text-primary/80 transition-colors">
          View samples →
        </button>
      </div>
    </motion.div>
  )
}
