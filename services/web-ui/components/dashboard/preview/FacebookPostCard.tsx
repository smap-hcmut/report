import React, { useState } from 'react'
import { motion } from 'framer-motion'
import {
  ThumbsUp,
  MessageCircle,
  Share2,
  MoreHorizontal,
  Globe,
  User,
  X
} from 'lucide-react'
import { DryRunContent } from '@/lib/types/dryrun'
import { useTranslation } from 'next-i18next'

interface FacebookPostCardProps {
  post: DryRunContent
}

export default function FacebookPostCard({ post }: FacebookPostCardProps) {
  const { t } = useTranslation('common')
  const [showComments, setShowComments] = useState(false)

  const formatDate = (dateString: string) => {
    try {
      const date = new Date(dateString)
      const now = new Date()
      const diffMs = now.getTime() - date.getTime()
      const diffMins = Math.floor(diffMs / 60000)
      const diffHours = Math.floor(diffMs / 3600000)
      const diffDays = Math.floor(diffMs / 86400000)

      if (diffMins < 1) return 'Vừa xong'
      if (diffMins < 60) return `${diffMins}ph`
      if (diffHours < 24) return `${diffHours}g`
      if (diffDays < 7) return `${diffDays} ngày`
      return date.toLocaleDateString('vi-VN', { day: 'numeric', month: 'numeric' })
    } catch {
      return dateString
    }
  }

  const formatNumber = (num: number) => {
    if (num >= 1000000) return `${(num / 1000000).toFixed(1)} Tr`
    if (num >= 1000) return `${(num / 1000).toFixed(1)}N`
    return num.toString()
  }

  return (
    <div className="bg-white dark:bg-[#242526] rounded-lg shadow-sm border-0">
      {/* Post Header */}
      <div className="px-4 pt-3 pb-0">
        <div className="flex items-start justify-between mb-3">
          <div className="flex items-center gap-2">
            {/* Avatar */}
            <div className="w-10 h-10 bg-gray-200 dark:bg-gray-600 rounded-full overflow-hidden flex-shrink-0">
              {post.author.avatar_url ? (
                <img
                  src={post.author.avatar_url}
                  alt={post.author.name}
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full flex items-center justify-center bg-blue-500">
                  <User className="w-5 h-5 text-white" />
                </div>
              )}
            </div>

            {/* Author Info */}
            <div className="leading-tight">
              <div className="flex items-center gap-1">
                <span className="font-semibold text-gray-900 dark:text-[#E4E6EB] text-[15px] hover:underline cursor-pointer">
                  {post.author.name}
                </span>
                {post.author.is_verified && (
                  <svg className="w-[14px] h-[14px] text-blue-500 fill-current" viewBox="0 0 16 16">
                    <path d="M8 0a8 8 0 100 16A8 8 0 008 0zm3.65 6.35l-4 4a.5.5 0 01-.7 0l-2-2a.5.5 0 01.7-.7L7 9l3.65-3.65a.5.5 0 01.7.7z"/>
                  </svg>
                )}
              </div>
              <div className="flex items-center gap-1 text-xs text-gray-500 dark:text-[#B0B3B8]">
                <span className="hover:underline cursor-pointer">{formatDate(post.meta.published_at)}</span>
                <span>·</span>
                <Globe className="w-3 h-3" />
              </div>
            </div>
          </div>

          <button className="text-gray-500 dark:text-[#B0B3B8] hover:bg-gray-100 dark:hover:bg-[#3A3B3C] p-2 rounded-full transition-colors">
            <MoreHorizontal className="w-5 h-5" />
          </button>
        </div>

        {/* Post Content */}
        <div className="text-gray-900 dark:text-[#E4E6EB] text-[15px] mb-3 leading-5">
          {post.content.text}
        </div>

        {/* Hashtags */}
        {post.content.hashtags && post.content.hashtags.length > 0 && (
          <div className="flex flex-wrap gap-1 mb-3">
            {post.content.hashtags.map((tag, idx) => (
              <span
                key={idx}
                className="text-[#385898] dark:text-[#4E9FEE] hover:underline cursor-pointer text-[15px] font-normal"
              >
                #{tag}
              </span>
            ))}
          </div>
        )}

        {/* Keyword Badge */}
        <div className="mb-3">
          <div className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800/50 rounded-md">
            <div className="w-1.5 h-1.5 bg-green-500 rounded-full"></div>
            <span className="text-xs font-medium text-green-700 dark:text-green-400">
              Từ khóa: {post.meta.keyword_source}
            </span>
          </div>
        </div>
      </div>

      {/* Interaction Stats Bar */}
      <div className="px-4 py-2">
        <div className="flex items-center justify-between text-[15px] text-gray-600 dark:text-[#B0B3B8]">
          <div className="flex items-center gap-1">
            {/* Like/Love/Care reactions */}
            <div className="flex items-center -space-x-1">
              {/* Like (blue thumbs up) */}
              <div className="w-[18px] h-[18px] bg-[#1877F2] rounded-full flex items-center justify-center z-30">
                <ThumbsUp className="w-2.5 h-2.5 text-white fill-white" />
              </div>
              {/* Love (red heart) */}
              <div className="w-[18px] h-[18px] bg-[#F33E58] rounded-full flex items-center justify-center z-20">
                <svg className="w-2.5 h-2.5 text-white fill-white" viewBox="0 0 16 16">
                  <path d="M8 2.748l-.717-.737C5.6.281 3.5.878 3.5 3.053c0 .848.31 1.587.868 2.168L8 8.848l3.632-3.627c.558-.58.868-1.32.868-2.168 0-2.175-2.1-2.772-3.783-1.042L8 2.748z"/>
                </svg>
              </div>
              {/* Care (yellow hug) */}
              <div className="w-[18px] h-[18px] bg-[#F7B125] rounded-full flex items-center justify-center z-10">
                <span className="text-[10px]">🤗</span>
              </div>
            </div>
            <span className="ml-1 hover:underline cursor-pointer">{formatNumber(post.interaction.likes)}</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="hover:underline cursor-pointer">{formatNumber(post.interaction.comments_count)} bình luận</span>
            <span className="hover:underline cursor-pointer">{formatNumber(post.interaction.shares)} lượt chia sẻ</span>
          </div>
        </div>
      </div>

      {/* Divider */}
      <div className="mx-4 border-t border-gray-200 dark:border-[#3A3B3C]"></div>

      {/* Action Buttons */}
      <div className="px-2 py-1">
        <div className="flex items-center">
          <button className="flex-1 flex items-center justify-center gap-2 py-2 hover:bg-gray-100 dark:hover:bg-[#3A3B3C] rounded-md transition-colors group">
            <ThumbsUp className="w-[18px] h-[18px] text-gray-600 dark:text-[#B0B3B8] group-hover:text-gray-700 dark:group-hover:text-[#E4E6EB]" />
            <span className="font-semibold text-[15px] text-gray-600 dark:text-[#B0B3B8] group-hover:text-gray-700 dark:group-hover:text-[#E4E6EB]">
              Thích
            </span>
          </button>
          <button
            onClick={() => setShowComments(!showComments)}
            className="flex-1 flex items-center justify-center gap-2 py-2 hover:bg-gray-100 dark:hover:bg-[#3A3B3C] rounded-md transition-colors group"
          >
            <MessageCircle className="w-[18px] h-[18px] text-gray-600 dark:text-[#B0B3B8] group-hover:text-gray-700 dark:group-hover:text-[#E4E6EB]" />
            <span className="font-semibold text-[15px] text-gray-600 dark:text-[#B0B3B8] group-hover:text-gray-700 dark:group-hover:text-[#E4E6EB]">
              Bình luận
            </span>
          </button>
          <button className="flex-1 flex items-center justify-center gap-2 py-2 hover:bg-gray-100 dark:hover:bg-[#3A3B3C] rounded-md transition-colors group">
            <Share2 className="w-[18px] h-[18px] text-gray-600 dark:text-[#B0B3B8] group-hover:text-gray-700 dark:group-hover:text-[#E4E6EB]" />
            <span className="font-semibold text-[15px] text-gray-600 dark:text-[#B0B3B8] group-hover:text-gray-700 dark:group-hover:text-[#E4E6EB]">
              Chia sẻ
            </span>
          </button>
        </div>
      </div>

      {/* Comments Section */}
      {post.comments && post.comments.length > 0 && showComments && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: 'auto' }}
          exit={{ opacity: 0, height: 0 }}
          className="px-4 pb-3 pt-2 space-y-2 border-t border-gray-200 dark:border-[#3A3B3C]"
        >
          {post.comments.slice(0, 3).map((comment) => (
            <div key={comment.id} className="flex gap-2">
              <div className="w-8 h-8 bg-gray-200 dark:bg-gray-600 rounded-full overflow-hidden flex-shrink-0">
                {comment.user.avatar_url ? (
                  <img
                    src={comment.user.avatar_url}
                    alt={comment.user.name}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center bg-blue-500">
                    <User className="w-4 h-4 text-white" />
                  </div>
                )}
              </div>
              <div className="flex-1">
                <div className="bg-gray-100 dark:bg-[#3A3B3C] rounded-2xl px-3 py-2 inline-block">
                  <div className="font-semibold text-[13px] text-gray-900 dark:text-[#E4E6EB]">
                    {comment.user.name}
                  </div>
                  <div className="text-[15px] text-gray-800 dark:text-[#E4E6EB]">
                    {comment.text}
                  </div>
                </div>
                <div className="flex items-center gap-3 mt-1 px-3 text-xs font-semibold text-gray-600 dark:text-[#B0B3B8]">
                  <button className="hover:underline">Thích</button>
                  <button className="hover:underline">Phản hồi</button>
                  <span>{formatDate(comment.published_at)}</span>
                  {comment.likes > 0 && (
                    <span className="flex items-center gap-1">
                      <ThumbsUp className="w-3 h-3 text-blue-500 fill-blue-500" />
                      {formatNumber(comment.likes)}
                    </span>
                  )}
                </div>
              </div>
            </div>
          ))}
          {post.comments.length > 3 && (
            <button className="text-[15px] font-semibold text-gray-600 dark:text-[#B0B3B8] hover:underline pl-10">
              Xem thêm bình luận
            </button>
          )}
        </motion.div>
      )}
    </div>
  )
}
