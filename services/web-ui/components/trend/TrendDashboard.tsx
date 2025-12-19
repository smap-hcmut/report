import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Search,
  Filter,
  TrendingUp,
  Hash,
  FileText,
  ArrowUp,
  ArrowDown,
  RefreshCw,
  Grid,
  List,
  BarChart3
} from 'lucide-react'
import { useTranslation } from 'next-i18next'
import { useTrend } from '@/contexts/TrendContext'
import TrendTopicCard from './TrendTopicCard'
import TrendHashtagCard from './TrendHashtagCard'
import TrendPostCard from './TrendPostCard'
import TrendMetrics from './TrendMetrics'

interface TrendDashboardProps {
  onTopicSelect: (topicId: string) => void
}

export default function TrendDashboard({ onTopicSelect }: TrendDashboardProps) {
  const { t } = useTranslation('common')
  const {
    state,
    filteredTopics,
    filteredHashtags,
    filteredPosts,
    setSearchQuery,
    setViewMode,
    setSort,
    refreshData
  } = useTrend()

  const [showMetrics, setShowMetrics] = useState(true)

  const handleSort = (by: 'volume' | 'delta' | 'confidence' | 'sentiment') => {
    const newOrder = state.sortBy === by && state.sortOrder === 'desc' ? 'asc' : 'desc'
    setSort(by, newOrder)
  }

  const SortButton = ({
    field,
    labelKey,
    icon
  }: {
    field: 'volume' | 'delta' | 'confidence' | 'sentiment'
    labelKey: string
    icon: React.ReactNode
  }) => (
    <button
      onClick={() => handleSort(field)}
      className={`flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
        state.sortBy === field
          ? 'bg-primary text-primary-foreground'
          : 'bg-muted hover:bg-muted/80 text-muted-foreground hover:text-foreground'
      }`}
    >
      {icon}
{t(labelKey)}
      {state.sortBy === field && (
        state.sortOrder === 'desc' ? <ArrowDown className="h-3 w-3" /> : <ArrowUp className="h-3 w-3" />
      )}
    </button>
  )

  return (
    <div className="h-full flex flex-col">
      {}
      <div className="p-6 border-b border-border bg-card/50">
        <div className="flex items-center gap-4 mb-4">
          {}
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <input
              type="text"
               placeholder={t('trendAnalysis.searchPlaceholder')}
              value={state.searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-3 border border-border rounded-lg bg-background focus:ring-2 focus:ring-primary focus:border-transparent"
            />
          </div>

          {}
          <div className="flex items-center gap-2 bg-muted rounded-lg p-1">
            <button
              onClick={() => setViewMode('topics')}
              className={`flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                state.viewMode === 'topics'
                  ? 'bg-background text-foreground shadow-sm'
                  : 'text-muted-foreground hover:text-foreground'
              }`}
            >
              <TrendingUp className="h-4 w-4" />
{t('trendAnalysis.topics')}
            </button>
            <button
              onClick={() => setViewMode('hashtags')}
              className={`flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                state.viewMode === 'hashtags'
                  ? 'bg-background text-foreground shadow-sm'
                  : 'text-muted-foreground hover:text-foreground'
              }`}
            >
              <Hash className="h-4 w-4" />
{t('trendAnalysis.hashtags')}
            </button>
            <button
              onClick={() => setViewMode('posts')}
              className={`flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                state.viewMode === 'posts'
                  ? 'bg-background text-foreground shadow-sm'
                  : 'text-muted-foreground hover:text-foreground'
              }`}
            >
              <FileText className="h-4 w-4" />
{t('trendAnalysis.posts')}
            </button>
          </div>

          {}
          <button
            onClick={refreshData}
            disabled={state.isLoading}
            className="flex items-center gap-2 px-4 py-3 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors disabled:opacity-50"
          >
             <RefreshCw className={`h-4 w-4 ${state.isLoading ? 'animate-spin' : ''}`} />
{t('trendAnalysis.refresh')}
          </button>
        </div>

        {}
        <div className="flex items-center gap-2">
           <span className="text-sm font-medium text-muted-foreground">{t('trendAnalysis.sortBy')}:</span>
          <SortButton field="volume" labelKey="trendAnalysis.sortByVolume" icon={<BarChart3 className="h-4 w-4" />} />
          <SortButton field="delta" labelKey="trendAnalysis.sortByDelta" icon={<TrendingUp className="h-4 w-4" />} />
          <SortButton field="confidence" labelKey="trendAnalysis.sortByConfidence" icon={<BarChart3 className="h-4 w-4" />} />
          <SortButton field="sentiment" labelKey="trendAnalysis.sortBySentiment" icon={<TrendingUp className="h-4 w-4" />} />
        </div>
      </div>

      {}
      {showMetrics && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: 'auto' }}
          exit={{ opacity: 0, height: 0 }}
          className="border-b border-border"
        >
          <TrendMetrics />
        </motion.div>
      )}

      {}
      <div className="flex-1 overflow-auto">
        {state.isLoading ? (
          <div className="flex items-center justify-center h-full">
            <div className="text-center">
              <RefreshCw className="h-8 w-8 animate-spin mx-auto mb-4 text-primary" />
              <p className="text-muted-foreground">Đang tải dữ liệu xu hướng...</p>
            </div>
          </div>
        ) : (
          <div className="p-6">
            <AnimatePresence mode="wait">
              {state.viewMode === 'topics' && (
                <motion.div
                  key="topics"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -20 }}
                  transition={{ duration: 0.3 }}
                  className="space-y-4"
                >
                  <div className="flex items-center justify-between mb-6">
                    <h2 className="text-xl font-semibold">
                      Trending Topics ({filteredTopics.length})
                    </h2>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => setShowMetrics(!showMetrics)}
                        className="flex items-center gap-2 px-3 py-2 text-sm text-muted-foreground hover:text-foreground transition-colors"
                      >
                        {showMetrics ? <Grid className="h-4 w-4" /> : <List className="h-4 w-4" />}
                        {showMetrics ? 'Hide' : 'Show'} Metrics
                      </button>
                    </div>
                  </div>

                  {filteredTopics.length === 0 ? (
                    <div className="text-center py-12">
                      <TrendingUp className="h-12 w-12 mx-auto mb-4 text-muted-foreground opacity-50" />
                      <h3 className="text-lg font-medium mb-2">Không tìm thấy chủ đề nào</h3>
                      <p className="text-muted-foreground">
                        Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm
                      </p>
                    </div>
                  ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                      {filteredTopics.map((topic, index) => (
                        <motion.div
                          key={topic.id}
                          initial={{ opacity: 0, y: 20 }}
                          animate={{ opacity: 1, y: 0 }}
                          transition={{ delay: index * 0.1 }}
                        >
                          <TrendTopicCard
                            topic={topic}
                            onClick={() => onTopicSelect(topic.id)}
                          />
                        </motion.div>
                      ))}
                    </div>
                  )}
                </motion.div>
              )}

              {state.viewMode === 'hashtags' && (
                <motion.div
                  key="hashtags"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -20 }}
                  transition={{ duration: 0.3 }}
                  className="space-y-4"
                >
                  <h2 className="text-xl font-semibold mb-6">
                    Trending Hashtags ({filteredHashtags.length})
                  </h2>

                  {filteredHashtags.length === 0 ? (
                    <div className="text-center py-12">
                      <Hash className="h-12 w-12 mx-auto mb-4 text-muted-foreground opacity-50" />
                      <h3 className="text-lg font-medium mb-2">Không tìm thấy hashtag nào</h3>
                      <p className="text-muted-foreground">
                        Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm
                      </p>
                    </div>
                  ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                      {filteredHashtags.map((hashtag, index) => (
                        <motion.div
                          key={hashtag.id}
                          initial={{ opacity: 0, y: 20 }}
                          animate={{ opacity: 1, y: 0 }}
                          transition={{ delay: index * 0.1 }}
                        >
                          <TrendHashtagCard hashtag={hashtag} />
                        </motion.div>
                      ))}
                    </div>
                  )}
                </motion.div>
              )}

              {state.viewMode === 'posts' && (
                <motion.div
                  key="posts"
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -20 }}
                  transition={{ duration: 0.3 }}
                  className="space-y-4"
                >
                  <h2 className="text-xl font-semibold mb-6">
                    Sample Posts ({filteredPosts.length})
                  </h2>

                  {filteredPosts.length === 0 ? (
                    <div className="text-center py-12">
                      <FileText className="h-12 w-12 mx-auto mb-4 text-muted-foreground opacity-50" />
                      <h3 className="text-lg font-medium mb-2">Không tìm thấy bài đăng nào</h3>
                      <p className="text-muted-foreground">
                        Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm
                      </p>
                    </div>
                  ) : (
                    <div className="space-y-4">
                      {filteredPosts.map((post, index) => (
                        <motion.div
                          key={post.id}
                          initial={{ opacity: 0, y: 20 }}
                          animate={{ opacity: 1, y: 0 }}
                          transition={{ delay: index * 0.1 }}
                        >
                          <TrendPostCard post={post} />
                        </motion.div>
                      ))}
                    </div>
                  )}
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        )}
      </div>
    </div>
  )
}
