import React, { useState, useRef, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { DryRunContent } from '@/lib/types/dryrun'
import FacebookPostCard from './FacebookPostCard'
import TikTokPostCard from './TikTokPostCard'
import YouTubePostCard from './YouTubePostCard'
import { Facebook, Music2, Youtube, TrendingUp, Eye, Heart, MessageCircle } from 'lucide-react'

type PlatformType = 'facebook' | 'tiktok' | 'youtube'

interface PlatformComparisonViewProps {
  allPosts: DryRunContent[]
  selectedKeyword: string
}

interface PlatformStats {
  totalPosts: number
  totalViews: number
  totalLikes: number
  totalComments: number
  avgEngagement: number
}

const platformConfig = {
  facebook: {
    icon: Facebook,
    label: 'Facebook',
    color: 'bg-blue-600',
    borderColor: 'border-blue-600',
    textColor: 'text-blue-600'
  },
  tiktok: {
    icon: Music2,
    label: 'TikTok',
    color: 'bg-black',
    borderColor: 'border-black',
    textColor: 'text-black'
  },
  youtube: {
    icon: Youtube,
    label: 'YouTube',
    color: 'bg-red-600',
    borderColor: 'border-red-600',
    textColor: 'text-red-600'
  }
}

export default function PlatformComparisonView({
  allPosts,
  selectedKeyword
}: PlatformComparisonViewProps) {
  const [syncScroll, setSyncScroll] = useState(true)
  const scrollRefs = useRef<{ [key: string]: HTMLDivElement | null }>({})
  const isScrolling = useRef(false)

  // Filter posts by platform and keyword
  const getPostsForPlatform = (platform: PlatformType) => {
    return allPosts.filter(post => {
      const keywordMatch = selectedKeyword === 'all' || post.meta.keyword_source === selectedKeyword
      const platformMatch = post.meta.platform === platform
      return keywordMatch && platformMatch
    })
  }

  // Calculate stats for each platform
  const calculateStats = (posts: DryRunContent[]): PlatformStats => {
    if (posts.length === 0) {
      return {
        totalPosts: 0,
        totalViews: 0,
        totalLikes: 0,
        totalComments: 0,
        avgEngagement: 0
      }
    }

    const totalViews = posts.reduce((sum, p) => sum + p.interaction.views, 0)
    const totalLikes = posts.reduce((sum, p) => sum + p.interaction.likes, 0)
    const totalComments = posts.reduce((sum, p) => sum + p.interaction.comments_count, 0)
    const totalEngagement = posts.reduce((sum, p) => sum + (p.interaction.engagement_rate || 0), 0)

    return {
      totalPosts: posts.length,
      totalViews,
      totalLikes,
      totalComments,
      avgEngagement: totalEngagement / posts.length
    }
  }

  const formatNumber = (num: number) => {
    if (num >= 1000000) return `${(num / 1000000).toFixed(1)}M`
    if (num >= 1000) return `${(num / 1000).toFixed(1)}K`
    return num.toString()
  }

  // Synchronized scrolling
  const handleScroll = (platform: PlatformType) => {
    if (!syncScroll || isScrolling.current) return

    const sourceRef = scrollRefs.current[platform]
    if (!sourceRef) return

    isScrolling.current = true

    const scrollPercentage = sourceRef.scrollTop / (sourceRef.scrollHeight - sourceRef.clientHeight)

    Object.keys(scrollRefs.current).forEach(key => {
      if (key !== platform && scrollRefs.current[key]) {
        const targetRef = scrollRefs.current[key]
        if (targetRef) {
          targetRef.scrollTop = scrollPercentage * (targetRef.scrollHeight - targetRef.clientHeight)
        }
      }
    })

    setTimeout(() => {
      isScrolling.current = false
    }, 100)
  }

  const platforms: PlatformType[] = ['facebook', 'tiktok', 'youtube']

  return (
    <div className="space-y-4">
      {/* Sync Scroll Toggle */}
      <div className="flex items-center justify-end gap-2">
        <label className="flex items-center gap-2 text-sm font-medium text-gray-700 dark:text-gray-300 cursor-pointer">
          <input
            type="checkbox"
            checked={syncScroll}
            onChange={(e) => setSyncScroll(e.target.checked)}
            className="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
          />
          <span>Đồng bộ cuộn trang</span>
        </label>
      </div>

      {/* 3 Panel Comparison Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {platforms.map((platform) => {
          const posts = getPostsForPlatform(platform)
          const stats = calculateStats(posts)
          const config = platformConfig[platform]
          const Icon = config.icon

          return (
            <div
              key={platform}
              className={`flex flex-col border-2 ${config.borderColor} rounded-xl overflow-hidden bg-white dark:bg-gray-900`}
            >
              {/* Platform Header */}
              <div className={`${config.color} text-white p-4`}>
                <div className="flex items-center gap-3">
                  <Icon className="w-6 h-6" />
                  <h3 className="text-xl font-bold">{config.label}</h3>
                </div>
              </div>

              {/* Posts List */}
              <div
                ref={(el) => { scrollRefs.current[platform] = el }}
                onScroll={() => handleScroll(platform)}
                className="flex-1 overflow-y-auto p-4 space-y-4 max-h-[600px]"
                style={{ scrollBehavior: syncScroll ? 'smooth' : 'auto' }}
              >
                {posts.length === 0 ? (
                  <div className="text-center py-12">
                    <div className={`w-16 h-16 ${config.color} rounded-full flex items-center justify-center mx-auto mb-4 opacity-20`}>
                      <Icon className="w-8 h-8 text-white" />
                    </div>
                    <p className="text-gray-500 dark:text-gray-400">
                      Không có bài đăng
                    </p>
                  </div>
                ) : (
                  <AnimatePresence mode="popLayout">
                    {posts.map((post, index) => (
                      <motion.div
                        key={post.meta.id}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0, scale: 0.95 }}
                        transition={{ delay: index * 0.03 }}
                      >
                        {platform === 'facebook' && <FacebookPostCard post={post} />}
                        {platform === 'tiktok' && <TikTokPostCard post={post} />}
                        {platform === 'youtube' && <YouTubePostCard post={post} />}
                      </motion.div>
                    ))}
                  </AnimatePresence>
                )}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
