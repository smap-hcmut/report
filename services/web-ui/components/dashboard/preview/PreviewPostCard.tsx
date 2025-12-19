import React, { useState } from 'react'
import { motion } from 'framer-motion'
import {
  Eye,
  Heart,
  MessageCircle,
  Share2,
  ExternalLink,
  ChevronDown,
  ChevronUp,
  Bookmark,
  User,
  Calendar,
  Hash
} from 'lucide-react'
import { DryRunContent, Platform } from '@/lib/types/dryrun'
import { useTranslation } from 'next-i18next'

interface PreviewPostCardProps {
  post: DryRunContent
  platform: Platform
}

export default function PreviewPostCard({ post, platform }: PreviewPostCardProps) {
  const { t } = useTranslation('common')
  const [showComments, setShowComments] = useState(false)
  const [showTranscription, setShowTranscription] = useState(false)

  // Platform icon/badge
  const platformBadge = {
    tiktok: { label: 'TikTok', color: 'bg-black text-white' },
    youtube: { label: 'YouTube', color: 'bg-red-600 text-white' }
  }[platform]

  // Format date
  const formatDate = (dateString: string) => {
    try {
      const date = new Date(dateString)
      const now = new Date()
      const diffMs = now.getTime() - date.getTime()
      const diffMins = Math.floor(diffMs / 60000)
      const diffHours = Math.floor(diffMs / 3600000)
      const diffDays = Math.floor(diffMs / 86400000)

      if (diffMins < 60) {
        return `${diffMins} ${t('preview.minutesAgo') || 'minutes ago'}`
      } else if (diffHours < 24) {
        return `${diffHours} ${t('preview.hoursAgo') || 'hours ago'}`
      } else if (diffDays < 30) {
        return `${diffDays} ${t('preview.daysAgo') || 'days ago'}`
      } else {
        return date.toLocaleDateString()
      }
    } catch {
      return dateString
    }
  }

  const publishedDate = formatDate(post.meta.published_at)

  return (
    <div className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-xl p-6 shadow-brutal hover:shadow-brutal-lg transition-shadow">
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          {/* Author Avatar */}
          <div className="w-12 h-12 bg-gray-300 dark:bg-gray-700 rounded-full flex items-center justify-center overflow-hidden">
            {post.author.avatar_url ? (
              <img
                src={post.author.avatar_url}
                alt={post.author.name}
                className="w-full h-full object-cover"
              />
            ) : (
              <User className="w-6 h-6 text-gray-500 dark:text-gray-400" />
            )}
          </div>

          {/* Author Info */}
          <div>
            <div className="flex items-center gap-2">
              <p className="font-bold text-gray-900 dark:text-white">
                {post.author.name}
              </p>
              {post.author.is_verified && (
                <span className="text-blue-500 text-sm">✓</span>
              )}
            </div>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              @{post.author.username}
            </p>
            <p className="text-xs text-gray-500 dark:text-gray-500 flex items-center gap-1 mt-1">
              <Calendar className="w-3 h-3" />
              {publishedDate}
            </p>
          </div>
        </div>

        {/* Platform Badge */}
        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${platformBadge.color}`}>
          {platformBadge.label}
        </span>
      </div>

      {/* Content */}
      <div className="mb-4">
        {/* Title (YouTube only) */}
        {post.content.title && (
          <h4 className="text-lg font-bold text-gray-900 dark:text-white mb-2">
            {post.content.title}
          </h4>
        )}

        {/* Text Content */}
        <p className="text-gray-700 dark:text-gray-300 whitespace-pre-wrap">
          {post.content.text}
        </p>

        {/* Hashtags */}
        {post.content.hashtags && post.content.hashtags.length > 0 && (
          <div className="flex flex-wrap gap-2 mt-3">
            {post.content.hashtags.map((tag, idx) => (
              <span
                key={idx}
                className="inline-flex items-center gap-1 px-2 py-1 bg-blue-100 dark:bg-blue-900/40 text-blue-800 dark:text-blue-300 rounded text-xs font-semibold"
              >
                <Hash className="w-3 h-3" />
                {tag}
              </span>
            ))}
          </div>
        )}

        {/* Keyword Source */}
        <div className="mt-3 text-sm">
          <span className="text-gray-600 dark:text-gray-400">{t('preview.matchedKeyword')}:</span>
          <span className="ml-2 px-2 py-1 bg-green-100 dark:bg-green-900/40 text-green-800 dark:text-green-300 rounded font-semibold">
            {post.meta.keyword_source}
          </span>
        </div>

        {/* Transcription Toggle */}
        {post.content.transcription && (
          <div className="mt-3">
            <button
              onClick={() => setShowTranscription(!showTranscription)}
              className="flex items-center gap-2 text-sm text-blue-600 dark:text-blue-400 hover:underline"
            >
              {showTranscription ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
              {t('preview.transcription')}
            </button>
            {showTranscription && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                className="mt-2 p-3 bg-gray-100 dark:bg-gray-800 rounded-lg text-sm text-gray-700 dark:text-gray-300"
              >
                {post.content.transcription}
              </motion.div>
            )}
          </div>
        )}
      </div>

      {/* Interaction Stats */}
      <div className="flex items-center gap-6 mb-4 pb-4 border-b border-gray-200 dark:border-gray-700">
        <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
          <Eye className="w-5 h-5" />
          <span className="text-sm font-semibold">{post.interaction.views.toLocaleString()}</span>
        </div>
        <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
          <Heart className="w-5 h-5" />
          <span className="text-sm font-semibold">{post.interaction.likes.toLocaleString()}</span>
        </div>
        <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
          <MessageCircle className="w-5 h-5" />
          <span className="text-sm font-semibold">{post.interaction.comments_count.toLocaleString()}</span>
        </div>
        <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
          <Share2 className="w-5 h-5" />
          <span className="text-sm font-semibold">{post.interaction.shares.toLocaleString()}</span>
        </div>
        {post.interaction.saves && (
          <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
            <Bookmark className="w-5 h-5" />
            <span className="text-sm font-semibold">{post.interaction.saves.toLocaleString()}</span>
          </div>
        )}
        {post.interaction.engagement_rate && (
          <div className="ml-auto">
            <span className="px-3 py-1 bg-purple-100 dark:bg-purple-900/40 text-purple-800 dark:text-purple-300 rounded-full text-xs font-semibold">
              {(post.interaction.engagement_rate * 100).toFixed(2)}% {t('preview.engagement')}
            </span>
          </div>
        )}
      </div>

      {/* Author Stats */}
      <div className="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400 mb-4">
        <span>{post.author.followers.toLocaleString()} {t('preview.followers')}</span>
        <span>•</span>
        <span>{post.author.videos} {t('preview.videos')}</span>
        {post.author.bio && (
          <>
            <span>•</span>
            <span className="truncate max-w-xs">{post.author.bio}</span>
          </>
        )}
      </div>

      {/* Comments Section */}
      {post.comments && post.comments.length > 0 && (
        <div>
          <button
            onClick={() => setShowComments(!showComments)}
            className="flex items-center gap-2 text-sm font-semibold text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-colors"
          >
            {showComments ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
            {t('preview.viewComments')} ({post.comments.length})
          </button>

          {showComments && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              className="mt-3 space-y-3"
            >
              {post.comments.slice(0, 5).map(comment => (
                <div
                  key={comment.id}
                  className="p-3 bg-gray-50 dark:bg-gray-800 rounded-lg"
                >
                  <div className="flex items-start gap-2">
                    <div className="w-8 h-8 bg-gray-300 dark:bg-gray-700 rounded-full flex items-center justify-center flex-shrink-0 overflow-hidden">
                      {comment.user.avatar_url ? (
                        <img
                          src={comment.user.avatar_url}
                          alt={comment.user.name}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <User className="w-4 h-4 text-gray-500 dark:text-gray-400" />
                      )}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <p className="text-sm font-semibold text-gray-900 dark:text-white">
                          {comment.user.name}
                        </p>
                        {comment.is_author && (
                          <span className="px-2 py-0.5 bg-blue-100 dark:bg-blue-900/40 text-blue-800 dark:text-blue-300 rounded text-xs font-semibold">
                            {t('preview.author')}
                          </span>
                        )}
                      </div>
                      <p className="text-sm text-gray-700 dark:text-gray-300 mb-2">
                        {comment.text}
                      </p>
                      <div className="flex items-center gap-3 text-xs text-gray-500 dark:text-gray-500">
                        <span className="flex items-center gap-1">
                          <Heart className="w-3 h-3" />
                          {comment.likes}
                        </span>
                        {comment.replies_count > 0 && (
                          <span>{comment.replies_count} {t('preview.replies')}</span>
                        )}
                        <span>{formatDate(comment.published_at)}</span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
              {post.comments.length > 5 && (
                <p className="text-sm text-gray-500 dark:text-gray-500 text-center">
                  +{post.comments.length - 5} {t('preview.moreComments')}
                </p>
              )}
            </motion.div>
          )}
        </div>
      )}

      {/* View Original Link */}
      <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
        <a
          href={post.meta.permalink}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2 text-sm text-blue-600 dark:text-blue-400 hover:underline"
        >
          <ExternalLink className="w-4 h-4" />
          {t('preview.viewOriginal')}
        </a>
      </div>
    </div>
  )
}
