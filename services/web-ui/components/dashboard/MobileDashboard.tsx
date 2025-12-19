import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Menu,
  X,
  ChevronDown,
  Filter,
  Download,
  Share2,
  Settings,
  Bell
} from 'lucide-react'
import { useDashboard } from '@/contexts/DashboardContext'
import MetricCard from './MetricCard'
import TrendChart from './charts/TrendChart'
import SentimentChart from './charts/SentimentChart'
import CompetitorChart from './charts/CompetitorChart'
import TopicCloud from './charts/TopicCloud'
import DataTable from './DataTable'
import TopicDetailModal from './TopicDetailModal'

export default function MobileDashboard() {
  const { state, filteredData, isLoading, toggleSidebar, setFilters, setSelectedTopic } = useDashboard()
  const [activeTab, setActiveTab] = useState<'overview' | 'trends' | 'competitors' | 'content'>('overview')
  const [showFilters, setShowFilters] = useState(false)

  const data = filteredData || {
    metrics: {
      sov: 26.2,
      sentiment: 0.34,
      mentions: 45200,
      engagement: 4.8
    },
    trends: [
      { date: '2024-01-01', mentions: 1200, sentiment: 0.2 },
      { date: '2024-01-02', mentions: 1350, sentiment: 0.3 },
      { date: '2024-01-03', mentions: 1100, sentiment: 0.1 },
      { date: '2024-01-04', mentions: 1600, sentiment: 0.4 },
      { date: '2024-01-05', mentions: 1800, sentiment: 0.5 },
      { date: '2024-01-06', mentions: 1500, sentiment: 0.3 },
      { date: '2024-01-07', mentions: 2000, sentiment: 0.6 },
    ],
    sentiment: [
      { name: 'Positive', value: 45, color: '#10b981' },
      { name: 'Neutral', value: 35, color: '#6b7280' },
      { name: 'Negative', value: 20, color: '#ef4444' },
    ],
    competitors: [
      { brand: 'Your Brand', sov: 26.2, color: '#3b82f6' },
      { brand: 'Competitor A', sov: 24.8, color: '#10b981' },
      { brand: 'Competitor B', sov: 18.5, color: '#f59e0b' },
      { brand: 'Competitor C', sov: 15.2, color: '#ef4444' },
      { brand: 'Others', sov: 15.3, color: '#8b5cf6' },
    ],
    topics: [
      { text: 'coffee', value: 100 },
      { text: 'quality', value: 80 },
      { text: 'service', value: 70 },
      { text: 'price', value: 60 },
      { text: 'atmosphere', value: 50 },
    ],
    content: [
      { id: 1, title: 'New Coffee Blend Launch', platform: 'Facebook', engagement: 1250, reach: 15000 },
      { id: 2, title: 'Customer Story Feature', platform: 'Instagram', engagement: 980, reach: 12000 },
      { id: 3, title: 'Behind the Scenes Video', platform: 'TikTok', engagement: 2100, reach: 25000 },
    ]
  }

  const metrics = [
    {
      id: 'sov',
      title: 'Share of Voice',
      value: `${data.metrics.sov.toFixed(1)}%`,
      delta: '+2.1%',
      trend: 'up' as const,
      animation: 'counter' as const,
      color: 'text-blue-600'
    },
    {
      id: 'sentiment',
      title: 'Net Sentiment',
      value: data.metrics.sentiment > 0 ? `+${data.metrics.sentiment.toFixed(2)}` : data.metrics.sentiment.toFixed(2),
      delta: '-0.12',
      trend: data.metrics.sentiment > 0 ? 'up' as const : 'down' as const,
      animation: 'gauge' as const,
      color: data.metrics.sentiment > 0 ? 'text-green-600' : 'text-red-600'
    },
    {
      id: 'mentions',
      title: 'Total Mentions',
      value: data.metrics.mentions >= 1000 ? `${(data.metrics.mentions / 1000).toFixed(1)}K` : data.metrics.mentions.toString(),
      delta: '+12.3%',
      trend: 'up' as const,
      animation: 'counter' as const,
      color: 'text-purple-600'
    },
    {
      id: 'engagement',
      title: 'Engagement Rate',
      value: `${data.metrics.engagement.toFixed(1)}%`,
      delta: '+0.3%',
      trend: 'up' as const,
      animation: 'progress' as const,
      color: 'text-orange-600'
    }
  ]

  const tabs = [
    { id: 'overview', label: 'Overview', icon: '📊' },
    { id: 'trends', label: 'Trends', icon: '📈' },
    { id: 'competitors', label: 'Competitors', icon: '🏆' },
    { id: 'content', label: 'Content', icon: '📝' },
  ]

  const renderTabContent = () => {
    switch (activeTab) {
      case 'overview':
        return (
          <div className="space-y-4">
            {}
            <div className="space-y-3">
              {metrics.map((metric, index) => (
                <motion.div
                  key={metric.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                >
                  <MetricCard {...metric} />
                </motion.div>
              ))}
            </div>

            {}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
            >
              <SentimentChart
                title="Sentiment Distribution"
                data={data.sentiment}
                animation="pie-reveal"
                interaction="hover-details"
              />
            </motion.div>
          </div>
        )

      case 'trends':
        return (
          <div className="space-y-4">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
            >
              <TrendChart
                title="Trend Analysis"
                data={data.trends}
                animation="line-draw"
                interaction="zoom-pan"
              />
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
            >
              <TopicCloud
                title="Trending Topics"
                data={data.topics}
                animation="word-cloud"
                interaction="click-filter"
                onTopicClick={setSelectedTopic}
              />
            </motion.div>
          </div>
        )

      case 'competitors':
        return (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
          >
            <CompetitorChart
              title="Share of Voice Comparison"
              data={data.competitors}
              animation="bar-stack"
              interaction="drill-down"
            />
          </motion.div>
        )

      case 'content':
        return (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
          >
            <DataTable
              title="Top Performing Content"
              data={data.content}
              animation="row-reveal"
              interaction="sort-filter"
            />
          </motion.div>
        )

      default:
        return null
    }
  }

  if (isLoading) {
    return (
      <div className="space-y-4 p-4">
        <div className="h-16 bg-muted rounded-lg animate-pulse"></div>
        <div className="space-y-3">
          {Array.from({ length: 4 }).map((_, index) => (
            <div key={index} className="h-20 bg-muted rounded-lg animate-pulse"></div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background">
      {}
      <motion.header
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="sticky top-0 z-50 bg-card/95 backdrop-blur-sm border-b border-border"
      >
        <div className="flex items-center justify-between p-4">
          <div className="flex items-center gap-3">
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={toggleSidebar}
              className="p-2 rounded-md hover:bg-accent transition-colors"
            >
              <Menu className="h-5 w-5" />
            </motion.button>

            <h1 className="text-lg font-bold bg-gradient-to-r from-blue-600 to-violet-600 bg-clip-text text-transparent">
              SMAP
            </h1>
          </div>

          <div className="flex items-center gap-2">
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={() => setShowFilters(!showFilters)}
              className="p-2 rounded-md hover:bg-accent transition-colors"
            >
              <Filter className="h-5 w-5" />
            </motion.button>

            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="p-2 rounded-md hover:bg-accent transition-colors relative"
            >
              <Bell className="h-5 w-5" />
              <span className="absolute -top-1 -right-1 h-3 w-3 bg-red-500 rounded-full text-xs flex items-center justify-center text-white">
                3
              </span>
            </motion.button>
          </div>
        </div>

        {}
        <div className="px-4 pb-3">
          <div className="text-sm text-muted-foreground">
            Project: Coffee Shop Analysis
          </div>
          <div className="text-xs text-muted-foreground">
            Last updated: {state.lastUpdate?.toLocaleTimeString() || 'Never'}
          </div>
        </div>
      </motion.header>

      {}
      <AnimatePresence>
        {showFilters && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="border-b border-border bg-muted/50"
          >
            <div className="p-4 space-y-3">
              <div>
                <label className="text-sm font-medium mb-2 block">Platform</label>
                <div className="flex gap-2 flex-wrap">
                  {['Facebook', 'Instagram', 'TikTok', 'YouTube'].map(platform => (
                    <button
                      key={platform}
                      onClick={() => {
                        const currentPlatforms = state.filters.platform
                        const newPlatforms = currentPlatforms.includes(platform)
                          ? currentPlatforms.filter(p => p !== platform)
                          : [...currentPlatforms, platform]
                        setFilters({ platform: newPlatforms })
                      }}
                      className={`px-3 py-1 text-xs rounded-full transition-colors ${
                        state.filters.platform.includes(platform)
                          ? 'bg-primary text-primary-foreground'
                          : 'bg-background border border-border hover:bg-accent'
                      }`}
                    >
                      {platform}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="text-sm font-medium mb-2 block">Time Range</label>
                <div className="flex gap-2">
                  {['1h', '24h', '7d', '30d'].map(range => (
                    <button
                      key={range}
                      onClick={() => setFilters({})}
                      className={`px-3 py-1 text-xs rounded-md transition-colors ${
                        state.timeRange === range
                          ? 'bg-primary text-primary-foreground'
                          : 'bg-background border border-border hover:bg-accent'
                      }`}
                    >
                      {range}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {}
      <div className="sticky top-[120px] z-40 bg-background border-b border-border">
        <div className="flex overflow-x-auto scrollbar-hide">
          {tabs.map((tab) => (
            <motion.button
              key={tab.id}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => setActiveTab(tab.id as any)}
              className={`flex items-center gap-2 px-4 py-3 text-sm font-medium whitespace-nowrap transition-colors border-b-2 ${
                activeTab === tab.id
                  ? 'text-primary border-primary'
                  : 'text-muted-foreground border-transparent hover:text-foreground'
              }`}
            >
              <span>{tab.icon}</span>
              {tab.label}
            </motion.button>
          ))}
        </div>
      </div>

      {}
      <main className="p-4">
        <AnimatePresence mode="wait">
          <motion.div
            key={activeTab}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.3 }}
          >
            {renderTabContent()}
          </motion.div>
        </AnimatePresence>
      </main>

      {}
      <motion.button
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        whileHover={{ scale: 1.1 }}
        whileTap={{ scale: 0.9 }}
        className="fixed bottom-6 right-6 w-14 h-14 bg-primary text-primary-foreground rounded-full shadow-lg flex items-center justify-center z-50"
      >
        <Share2 className="h-6 w-6" />
      </motion.button>

      {}
      <TopicDetailModal
        topic={state.selectedTopic}
        isOpen={!!state.selectedTopic}
        onClose={() => setSelectedTopic(null)}
      />
    </div>
  )
}
