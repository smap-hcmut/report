import React, { useState } from 'react'
import { motion } from 'framer-motion'
import {
  ThumbsUp,
  ThumbsDown,
  Share2,
  Download,
  MoreHorizontal,
  User,
  ChevronDown,
  ChevronUp,
  Eye,
  Calendar
} from 'lucide-react'
import { DryRunContent } from '@/lib/types/dryrun'
import { useTranslation } from 'next-i18next'

interface YouTubePostCardProps {
  post: DryRunContent
}

export default function YouTubePostCard({ post }: YouTubePostCardProps) {
  const { t } = useTranslation('common')
  const [showDescription, setShowDescription] = useState(false)
  const [showComments, setShowComments] = useState(false)

  const formatNumber = (num: number) => {
    if (num >= 1000000000) return `${(num / 1000000000).toFixed(1)}B`
    if (num >= 1000000) return `${(num / 1000000).toFixed(1)} triệu`
    if (num >= 1000) return `${(num / 1000).toFixed(1)} N`
    return num.toString()
  }

  const formatDate = (dateString: string) => {
    try {
      const date = new Date(dateString)
      const now = new Date()
      const diffMs = now.getTime() - date.getTime()
      const diffDays = Math.floor(diffMs / 86400000)
      const diffMonths = Math.floor(diffDays / 30)
      const diffYears = Math.floor(diffDays / 365)

      if (diffDays < 1) return 'Hôm nay'
      if (diffDays < 7) return `${diffDays} ngày trước`
      if (diffDays < 30) return `${Math.floor(diffDays / 7)} tuần trước`
      if (diffMonths < 12) return `${diffMonths} tháng trước`
      return `${diffYears} năm trước`
    } catch {
      return dateString
    }
  }

  const formatDuration = (seconds?: number) => {
    if (!seconds) return '0:00'
    const hours = Math.floor(seconds / 3600)
    const mins = Math.floor((seconds % 3600) / 60)
    const secs = Math.floor(seconds % 60)
    if (hours > 0) {
      return `${hours}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
    }
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  // Extract YouTube video ID from permalink
  const getYouTubeVideoId = (url: string) => {
    try {
      const urlObj = new URL(url)
      if (urlObj.hostname.includes('youtube.com')) {
        return urlObj.searchParams.get('v')
      } else if (urlObj.hostname.includes('youtu.be')) {
        return urlObj.pathname.slice(1)
      }
    } catch {
      return null
    }
    return null
  }

  const videoId = getYouTubeVideoId(post.meta.permalink)
  const embedUrl = videoId ? `https://www.youtube.com/embed/${videoId}` : null

  return (
    <div className="bg-white dark:bg-gray-900 rounded-xl overflow-hidden">
      {/* Video Player */}
      <div className="relative w-full bg-black aspect-video">
        {embedUrl ? (
          <iframe
            src={embedUrl}
            className="w-full h-full"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center bg-gray-800">
            <div className="text-center text-white">
              <div className="w-20 h-20 bg-red-600 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg className="w-10 h-10" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M8 5v14l11-7z" />
                </svg>
              </div>
              <p className="text-sm">Video không khả dụng</p>
            </div>
          </div>
        )}
        {post.content.duration && (
          <div className="absolute bottom-2 right-2 bg-black/80 text-white text-xs font-semibold px-2 py-1 rounded">
            {formatDuration(post.content.duration)}
          </div>
        )}
      </div>

      {/* Video Info */}
      <div className="p-4">
        {/* Title */}
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2 line-clamp-2">
          {post.content.title || post.content.text}
        </h3>

        {/* Stats */}
        <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 mb-4">
          <span>{formatNumber(post.interaction.views)} lượt xem</span>
          <span>•</span>
          <span>{formatDate(post.meta.published_at)}</span>
        </div>

        {/* Keyword Badge */}
        <div className="inline-flex items-center gap-2 px-3 py-1.5 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-full mb-4">
          <span className="text-xs font-semibold text-red-700 dark:text-red-400">
            🎯 Khớp từ khóa: {post.meta.keyword_source}
          </span>
        </div>

        {/* Channel Info */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
              {post.author.avatar_url ? (
                <img
                  src={post.author.avatar_url}
                  alt={post.author.name}
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center">
                  <User className="w-5 h-5 text-gray-400" />
                </div>
              )}
            </div>
            <div>
              <div className="flex items-center gap-1">
                <h4 className="font-semibold text-sm text-gray-900 dark:text-white">
                  {post.author.name}
                </h4>
                {post.author.is_verified && (
                  <svg className="w-4 h-4 text-gray-600 dark:text-gray-400" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" />
                  </svg>
                )}
              </div>
              <p className="text-xs text-gray-600 dark:text-gray-400">
                {formatNumber(post.author.followers)} người đăng ký
              </p>
            </div>
          </div>
          <button className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-semibold rounded-full text-sm transition-colors">
            Đăng ký
          </button>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-2 mb-4 overflow-x-auto pb-2">
          <button className="flex items-center gap-2 px-4 py-2 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 rounded-full transition-colors">
            <ThumbsUp className="w-5 h-5" />
            <span className="text-sm font-semibold">{formatNumber(post.interaction.likes)}</span>
            <div className="w-px h-5 bg-gray-300 dark:bg-gray-600 mx-1" />
            <ThumbsDown className="w-5 h-5" />
          </button>
          <button className="flex items-center gap-2 px-4 py-2 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 rounded-full transition-colors">
            <Share2 className="w-5 h-5" />
            <span className="text-sm font-semibold">Chia sẻ</span>
          </button>
          <button className="flex items-center gap-2 px-4 py-2 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 rounded-full transition-colors">
            <Download className="w-5 h-5" />
            <span className="text-sm font-semibold">Tải xuống</span>
          </button>
          <button className="p-2 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 rounded-full transition-colors">
            <MoreHorizontal className="w-5 h-5" />
          </button>
        </div>

        {/* Description */}
        <div className="bg-gray-100 dark:bg-gray-800 rounded-xl p-3">
          <div className="flex items-center gap-2 text-xs font-semibold text-gray-900 dark:text-white mb-2">
            <Eye className="w-4 h-4" />
            <span>{formatNumber(post.interaction.views)} lượt xem</span>
            <Calendar className="w-4 h-4 ml-2" />
            <span>{formatDate(post.meta.published_at)}</span>
          </div>
          <div className={`text-sm text-gray-700 dark:text-gray-300 ${!showDescription ? 'line-clamp-2' : ''}`}>
            {post.content.text}
          </div>
          {post.content.text && post.content.text.length > 100 && (
            <button
              onClick={() => setShowDescription(!showDescription)}
              className="text-sm font-semibold text-gray-900 dark:text-white mt-2 hover:bg-gray-200 dark:hover:bg-gray-700 px-2 py-1 rounded transition-colors"
            >
              {showDescription ? 'Ẩn bớt' : 'Xem thêm'}
            </button>
          )}
        </div>

        {/* Comments Section */}
        {post.comments && post.comments.length > 0 && (
          <div className="mt-6">
            <div className="flex items-center justify-between mb-4">
              <h4 className="font-semibold text-gray-900 dark:text-white">
                {post.interaction.comments_count} bình luận
              </h4>
              <button
                onClick={() => setShowComments(!showComments)}
                className="text-sm font-semibold text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
              >
                {showComments ? (
                  <div className="flex items-center gap-1">
                    <ChevronUp className="w-4 h-4" />
                    Ẩn bớt
                  </div>
                ) : (
                  <div className="flex items-center gap-1">
                    <ChevronDown className="w-4 h-4" />
                    Hiển thị
                  </div>
                )}
              </button>
            </div>

            {showComments && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                className="space-y-4 max-h-96 overflow-y-auto"
              >
                {post.comments.slice(0, 10).map((comment) => (
                  <div key={comment.id} className="flex gap-3">
                    <div className="w-10 h-10 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden flex-shrink-0">
                      {comment.user.avatar_url ? (
                        <img
                          src={comment.user.avatar_url}
                          alt={comment.user.name}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center">
                          <User className="w-5 h-5 text-gray-400" />
                        </div>
                      )}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="font-semibold text-sm text-gray-900 dark:text-white">
                          {comment.user.name}
                        </span>
                        {comment.is_author && (
                          <span className="px-2 py-0.5 bg-red-100 dark:bg-red-900/40 text-red-700 dark:text-red-400 text-xs font-semibold rounded">
                            Tác giả
                          </span>
                        )}
                        <span className="text-xs text-gray-500 dark:text-gray-500">
                          {formatDate(comment.published_at)}
                        </span>
                      </div>
                      <p className="text-sm text-gray-700 dark:text-gray-300 mb-2">
                        {comment.text}
                      </p>
                      <div className="flex items-center gap-4">
                        <button className="flex items-center gap-1 text-xs text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white">
                          <ThumbsUp className="w-4 h-4" />
                          {comment.likes > 0 && <span>{formatNumber(comment.likes)}</span>}
                        </button>
                        <button className="flex items-center gap-1 text-xs text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white">
                          <ThumbsDown className="w-4 h-4" />
                        </button>
                        {comment.replies_count > 0 && (
                          <button className="text-xs font-semibold text-blue-600 dark:text-blue-400 hover:underline">
                            {comment.replies_count} phản hồi
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
                {post.comments.length > 10 && (
                  <button className="w-full text-center text-sm font-semibold text-blue-600 dark:text-blue-400 hover:underline py-2">
                    Xem thêm {post.comments.length - 10} bình luận
                  </button>
                )}
              </motion.div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
