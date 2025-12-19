import React, { useState } from 'react'
import { motion } from 'framer-motion'
import {
  Heart,
  MessageCircle,
  Bookmark,
  Share2,
  Music2,
  Play,
  User,
  ChevronDown,
  ChevronUp,
  Volume2,
  MoreHorizontal
} from 'lucide-react'
import { DryRunContent } from '@/lib/types/dryrun'
import { useTranslation } from 'next-i18next'

interface TikTokPostCardProps {
  post: DryRunContent
}

export default function TikTokPostCard({ post }: TikTokPostCardProps) {
  const { t } = useTranslation('common')
  const [showTranscription, setShowTranscription] = useState(false)
  const [showComments, setShowComments] = useState(false)

  const formatNumber = (num: number) => {
    if (num >= 1000000) return `${(num / 1000000).toFixed(1)}M`
    if (num >= 1000) return `${(num / 1000).toFixed(1)}K`
    return num.toString()
  }

  const formatDate = (dateString: string) => {
    try {
      const date = new Date(dateString)
      return date.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' })
    } catch {
      return dateString
    }
  }

  const formatDuration = (seconds?: number) => {
    if (!seconds) return '0:00'
    const mins = Math.floor(seconds / 60)
    const secs = Math.floor(seconds % 60)
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  return (
    <div className="bg-black rounded-xl overflow-hidden relative">
      {/* Main Container - Mobile TikTok Style */}
      <div className="flex gap-3 p-4">
        {/* Left: Video Thumbnail (Vertical 9:16) */}
        <div className="relative w-[200px] h-[355px] flex-shrink-0 bg-gradient-to-br from-[#fe2c55] via-[#000] to-[#25f4ee] rounded-lg overflow-hidden group">
          {/* Video Thumbnail/Preview */}
          <div className="absolute inset-0 bg-black/20 backdrop-blur-[1px]">
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="relative">
                <div className="absolute -inset-4 bg-white/10 rounded-full blur-xl"></div>
                <Play className="w-16 h-16 text-white relative z-10 drop-shadow-2xl" />
              </div>
            </div>
          </div>

          {/* Duration Badge */}
          {post.content.duration && (
            <div className="absolute top-2 right-2 bg-black/70 text-white text-xs font-semibold px-2 py-1 rounded">
              {formatDuration(post.content.duration)}
            </div>
          )}

          {/* Volume Icon */}
          <div className="absolute bottom-2 left-2">
            <div className="bg-black/50 p-1.5 rounded-full">
              <Volume2 className="w-4 h-4 text-white" />
            </div>
          </div>

          {/* Right Side Action Buttons (TikTok Style) */}
          <div className="absolute right-2 bottom-16 flex flex-col gap-3">
            {/* Avatar with Follow Button */}
            <div className="relative">
              <div className="w-12 h-12 rounded-full border-2 border-white overflow-hidden bg-gray-800">
                {post.author.avatar_url ? (
                  <img src={post.author.avatar_url} alt={post.author.name} className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center bg-gray-700">
                    <User className="w-6 h-6 text-gray-400" />
                  </div>
                )}
              </div>
              <div className="absolute -bottom-1.5 left-1/2 -translate-x-1/2">
                <div className="w-5 h-5 bg-[#fe2c55] rounded-full flex items-center justify-center">
                  <span className="text-white text-xs font-bold">+</span>
                </div>
              </div>
            </div>

            {/* Like Button */}
            <button className="flex flex-col items-center gap-1">
              <div className="w-11 h-11 flex items-center justify-center">
                <Heart className="w-8 h-8 text-white drop-shadow-lg" />
              </div>
              <span className="text-white text-xs font-semibold drop-shadow-lg">{formatNumber(post.interaction.likes)}</span>
            </button>

            {/* Comment Button */}
            <button className="flex flex-col items-center gap-1" onClick={() => setShowComments(!showComments)}>
              <div className="w-11 h-11 flex items-center justify-center">
                <MessageCircle className="w-8 h-8 text-white drop-shadow-lg" />
              </div>
              <span className="text-white text-xs font-semibold drop-shadow-lg">{formatNumber(post.interaction.comments_count)}</span>
            </button>

            {/* Bookmark Button */}
            {post.interaction.saves && (
              <button className="flex flex-col items-center gap-1">
                <div className="w-11 h-11 flex items-center justify-center">
                  <Bookmark className="w-7 h-7 text-white drop-shadow-lg" />
                </div>
                <span className="text-white text-xs font-semibold drop-shadow-lg">{formatNumber(post.interaction.saves)}</span>
              </button>
            )}

            {/* Share Button */}
            <button className="flex flex-col items-center gap-1">
              <div className="w-11 h-11 flex items-center justify-center">
                <Share2 className="w-7 h-7 text-white drop-shadow-lg" />
              </div>
              <span className="text-white text-xs font-semibold drop-shadow-lg">{formatNumber(post.interaction.shares)}</span>
            </button>
          </div>

          {/* Bottom Overlay Info */}
          <div className="absolute bottom-0 left-0 right-0 p-3 bg-gradient-to-t from-black/80 via-black/40 to-transparent">
            <div className="flex items-center gap-2 mb-1.5">
              <span className="text-white font-bold text-sm drop-shadow-lg">@{post.author.username}</span>
              {post.author.is_verified && (
                <svg className="w-4 h-4 text-white drop-shadow-lg" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M10 0C4.477 0 0 4.477 0 10s4.477 10 10 10 10-4.477 10-10S15.523 0 10 0zm4.95 7.636l-5.5 5.5a.5.5 0 01-.707 0l-2.5-2.5a.5.5 0 01.707-.707L9 11.986l5.146-5.147a.5.5 0 01.708.707z"/>
                </svg>
              )}
            </div>
            {post.content.sound_name && (
              <div className="flex items-center gap-1.5 text-white text-xs drop-shadow-lg">
                <Music2 className="w-3.5 h-3.5" />
                <span className="truncate">{post.content.sound_name}</span>
              </div>
            )}
          </div>
        </div>

        {/* Right: Content Details */}
        <div className="flex-1 flex flex-col gap-3 min-w-0">
          {/* Author Info */}
          <div className="flex items-start justify-between gap-2">
            <div className="flex items-center gap-2 min-w-0">
              <div className="w-10 h-10 rounded-full bg-gray-800 overflow-hidden flex-shrink-0">
                {post.author.avatar_url ? (
                  <img src={post.author.avatar_url} alt={post.author.name} className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <User className="w-5 h-5 text-gray-500" />
                  </div>
                )}
              </div>
              <div className="min-w-0">
                <div className="flex items-center gap-1.5">
                  <h3 className="font-bold text-white text-sm truncate">{post.author.name}</h3>
                  {post.author.is_verified && (
                    <svg className="w-4 h-4 text-[#20d5ec] flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M10 0C4.477 0 0 4.477 0 10s4.477 10 10 10 10-4.477 10-10S15.523 0 10 0zm4.95 7.636l-5.5 5.5a.5.5 0 01-.707 0l-2.5-2.5a.5.5 0 01.707-.707L9 11.986l5.146-5.147a.5.5 0 01.708.707z"/>
                    </svg>
                  )}
                </div>
                <p className="text-gray-400 text-xs">@{post.author.username}</p>
              </div>
            </div>
            <button className="p-1 hover:bg-gray-800 rounded-full transition-colors flex-shrink-0">
              <MoreHorizontal className="w-5 h-5 text-gray-400" />
            </button>
          </div>

          {/* Stats */}
          <div className="flex items-center gap-4 text-xs text-gray-400">
            <span>{formatNumber(post.author.followers)} Followers</span>
            <span>•</span>
            <span>{formatNumber(post.author.likes)} Likes</span>
          </div>

          {/* Caption */}
          <div className="text-white text-sm leading-relaxed">
            {post.content.text}
          </div>

          {/* Hashtags */}
          {post.content.hashtags && post.content.hashtags.length > 0 && (
            <div className="flex flex-wrap gap-2">
              {post.content.hashtags.map((tag, idx) => (
                <span
                  key={idx}
                  className="text-[#20d5ec] hover:text-[#25f4ee] cursor-pointer text-sm font-semibold"
                >
                  #{tag}
                </span>
              ))}
            </div>
          )}

          {/* Keyword Badge */}
          <div className="inline-flex items-center gap-1.5 px-2.5 py-1.5 bg-gradient-to-r from-[#fe2c55]/20 to-[#25f4ee]/20 border border-[#fe2c55]/30 rounded-lg self-start">
            <div className="w-1.5 h-1.5 bg-[#fe2c55] rounded-full animate-pulse"></div>
            <span className="text-xs font-semibold text-[#25f4ee]">
              Khớp: {post.meta.keyword_source}
            </span>
          </div>

          {/* Video Summary/Transcription */}
          {post.content.transcription && (
            <div>
              <button
                onClick={() => setShowTranscription(!showTranscription)}
                className="flex items-center gap-2 text-sm font-semibold text-gray-300 hover:text-white transition-colors"
              >
                {showTranscription ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                Xem tóm tắt nội dung
              </button>
              {showTranscription && (
                <motion.div
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: 'auto' }}
                  exit={{ opacity: 0, height: 0 }}
                  className="mt-2 p-3 bg-gray-900 rounded-lg border border-gray-800"
                >
                  <p className="text-sm text-gray-300 leading-relaxed">
                    {post.content.transcription}
                  </p>
                </motion.div>
              )}
            </div>
          )}

          {/* Metadata */}
          <div className="flex items-center gap-2 text-xs text-gray-500">
            <span>{formatDate(post.meta.published_at)}</span>
            <span>•</span>
            <span>{formatNumber(post.interaction.views)} views</span>
            {post.interaction.engagement_rate && (
              <>
                <span>•</span>
                <span>{(post.interaction.engagement_rate * 100).toFixed(1)}% engagement</span>
              </>
            )}
          </div>

          {/* Comments Section */}
          {post.comments && post.comments.length > 0 && (
            <div className="border-t border-gray-800 pt-3 mt-2">
              <button
                onClick={() => setShowComments(!showComments)}
                className="flex items-center gap-2 text-sm font-semibold text-gray-300 hover:text-white transition-colors mb-3"
              >
                {showComments ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                {post.comments.length} bình luận
              </button>

              {showComments && (
                <motion.div
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: 'auto' }}
                  exit={{ opacity: 0, height: 0 }}
                  className="space-y-3 max-h-64 overflow-y-auto"
                >
                  {post.comments.slice(0, 5).map((comment) => (
                    <div key={comment.id} className="flex gap-2">
                      <div className="w-8 h-8 rounded-full bg-gray-800 overflow-hidden flex-shrink-0">
                        {comment.user.avatar_url ? (
                          <img src={comment.user.avatar_url} alt={comment.user.name} className="w-full h-full object-cover" />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center">
                            <User className="w-4 h-4 text-gray-500" />
                          </div>
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <span className="font-semibold text-sm text-white truncate">
                            {comment.user.name}
                          </span>
                          {comment.is_author && (
                            <span className="px-1.5 py-0.5 bg-[#fe2c55]/20 text-[#fe2c55] text-xs font-semibold rounded flex-shrink-0">
                              Creator
                            </span>
                          )}
                        </div>
                        <p className="text-sm text-gray-300 break-words">{comment.text}</p>
                        <div className="flex items-center gap-3 mt-1 text-xs text-gray-500">
                          {comment.likes > 0 && <span>{formatNumber(comment.likes)} likes</span>}
                          {comment.replies_count > 0 && <span>{formatNumber(comment.replies_count)} replies</span>}
                        </div>
                      </div>
                    </div>
                  ))}
                  {post.comments.length > 5 && (
                    <button className="text-sm font-semibold text-gray-400 hover:text-white">
                      View {post.comments.length - 5} more comments
                    </button>
                  )}
                </motion.div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
