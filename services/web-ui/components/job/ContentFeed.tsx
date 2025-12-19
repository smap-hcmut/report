import React, { useRef, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Eye,
  Heart,
  MessageCircle,
  Share2,
  ExternalLink,
  CheckCircle,
  User,
} from 'lucide-react'
import type { ContentItem, Platform } from '@/lib/types/websocket'

interface ContentFeedProps {
  items: ContentItem[]
  platform: Platform | null
  isLoading?: boolean
}

// Format large numbers
const formatNumber = (num: number): string => {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + 'M'
  }
  if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'K'
  }
  return num.toString()
}

// Format date
const formatDate = (dateStr: string): string => {
  try {
    const date = new Date(dateStr)
    const now = new Date()
    const diffMs = now.getTime() - date.getTime()
    const diffMins = Math.floor(diffMs / 60000)
    const diffHours = Math.floor(diffMs / 3600000)
    const diffDays = Math.floor(diffMs / 86400000)

    if (diffMins < 60) return `${diffMins} phút trước`
    if (diffHours < 24) return `${diffHours} giờ trước`
    if (diffDays < 7) return `${diffDays} ngày trước`
    return date.toLocaleDateString('vi-VN')
  } catch {
    return dateStr
  }
}

// Content Item Component
const ContentItemCard: React.FC<{
  item: ContentItem
  index: number
}> = ({ item, index }) => {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      transition={{ duration: 0.3, delay: index * 0.05 }}
      className="p-4 border-b border-border hover:bg-muted/50 transition-colors"
    >
      {/* Author info */}
      <div className="flex items-center gap-3 mb-3">
        {item.author.avatar_url ? (
          <img
            src={item.author.avatar_url}
            alt={item.author.name}
            className="w-10 h-10 rounded-full object-cover"
          />
        ) : (
          <div className="w-10 h-10 rounded-full bg-muted flex items-center justify-center">
            <User className="h-5 w-5 text-muted-foreground" />
          </div>
        )}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-1">
            <span className="font-medium text-sm truncate">{item.author.name}</span>
            {item.author.is_verified && (
              <CheckCircle className="h-4 w-4 text-blue-500 flex-shrink-0" />
            )}
          </div>
          <div className="flex items-center gap-2 text-xs text-muted-foreground">
            <span>@{item.author.username}</span>
            <span>•</span>
            <span>{formatNumber(item.author.followers)} followers</span>
          </div>
        </div>
        <a
          href={item.permalink}
          target="_blank"
          rel="noopener noreferrer"
          className="p-2 hover:bg-muted rounded-full transition-colors"
        >
          <ExternalLink className="h-4 w-4 text-muted-foreground" />
        </a>
      </div>

      {/* Content text */}
      <p className="text-sm mb-3 line-clamp-3">{item.text}</p>

      {/* Media thumbnail */}
      {item.media && (
        <div className="mb-3 relative rounded-lg overflow-hidden bg-muted">
          <img
            src={item.media.thumbnail}
            alt="Content thumbnail"
            className="w-full h-40 object-cover"
          />
          {item.media.type === 'video' && item.media.duration && (
            <div className="absolute bottom-2 right-2 px-1.5 py-0.5 bg-black/70 text-white text-xs rounded">
              {Math.floor(item.media.duration / 60)}:{String(item.media.duration % 60).padStart(2, '0')}
            </div>
          )}
        </div>
      )}

      {/* Engagement metrics */}
      <div className="flex items-center gap-4 text-xs text-muted-foreground">
        <div className="flex items-center gap-1">
          <Eye className="h-4 w-4" />
          <span>{formatNumber(item.metrics.views)}</span>
        </div>
        <div className="flex items-center gap-1">
          <Heart className="h-4 w-4" />
          <span>{formatNumber(item.metrics.likes)}</span>
        </div>
        <div className="flex items-center gap-1">
          <MessageCircle className="h-4 w-4" />
          <span>{formatNumber(item.metrics.comments)}</span>
        </div>
        <div className="flex items-center gap-1">
          <Share2 className="h-4 w-4" />
          <span>{formatNumber(item.metrics.shares)}</span>
        </div>
        <div className="ml-auto text-xs">
          {item.metrics.rate.toFixed(1)}% engagement
        </div>
      </div>

      {/* Published date */}
      <div className="mt-2 text-xs text-muted-foreground">
        {formatDate(item.published_at)}
      </div>
    </motion.div>
  )
}

export default function ContentFeed({
  items,
  platform,
  isLoading = false,
}: ContentFeedProps) {
  const containerRef = useRef<HTMLDivElement>(null)
  const prevLengthRef = useRef(items.length)

  // Auto-scroll to top when new items are added
  useEffect(() => {
    if (items.length > prevLengthRef.current && containerRef.current) {
      containerRef.current.scrollTop = 0
    }
    prevLengthRef.current = items.length
  }, [items.length])

  if (items.length === 0) {
    return (
      <div className="h-full flex items-center justify-center text-muted-foreground">
        {isLoading ? (
          <div className="text-center">
            <div className="animate-pulse mb-2">Đang thu thập nội dung...</div>
            <div className="text-xs">Nội dung sẽ hiển thị khi được crawl</div>
          </div>
        ) : (
          <div className="text-center">
            <div className="mb-2">Chưa có nội dung</div>
            <div className="text-xs">Bắt đầu job để thu thập nội dung</div>
          </div>
        )}
      </div>
    )
  }

  return (
    <div
      ref={containerRef}
      className="h-full overflow-y-auto"
    >
      <AnimatePresence mode="popLayout">
        {items.map((item, index) => (
          <ContentItemCard key={item.id} item={item} index={index} />
        ))}
      </AnimatePresence>

      {/* Loading indicator at bottom */}
      {isLoading && items.length > 0 && (
        <div className="p-4 text-center text-sm text-muted-foreground">
          <div className="animate-pulse">Đang thu thập thêm...</div>
        </div>
      )}
    </div>
  )
}
