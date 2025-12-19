import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Download,
  Maximize2,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  ExternalLink,
  Eye,
  Heart,
  Share,
  TrendingUp,
  AlertTriangle,
  Flame,
  Zap
} from 'lucide-react'

interface ViralPostData {
  id: number
  title: string
  platform: string
  engagement: number
  reach: number
  impact_score: number
  risk: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW'
  virality_index: number
  timestamp: string
}

interface TopViralPostsProps {
  title: string
  data: ViralPostData[]
  animation?: 'row-reveal' | 'fade-in'
  interaction?: 'sort-filter' | 'read-only'
  onPostClick?: (post: ViralPostData) => void
}

type SortField = 'impact_score' | 'virality_index' | 'engagement' | 'reach'
type SortDirection = 'asc' | 'desc'

const getRiskColor = (risk: string) => {
  switch (risk) {
    case 'CRITICAL':
      return 'text-red-600 bg-red-100 dark:bg-red-900/30'
    case 'HIGH':
      return 'text-orange-600 bg-orange-100 dark:bg-orange-900/30'
    case 'MEDIUM':
      return 'text-yellow-600 bg-yellow-100 dark:bg-yellow-900/30'
    case 'LOW':
      return 'text-blue-600 bg-blue-100 dark:bg-blue-900/30'
    default:
      return 'text-gray-600 bg-gray-100 dark:bg-gray-900/30'
  }
}

const getViralityLevel = (index: number) => {
  if (index >= 80) return { label: 'Viral', color: 'text-purple-600', icon: Flame }
  if (index >= 60) return { label: 'High', color: 'text-orange-600', icon: TrendingUp }
  if (index >= 40) return { label: 'Medium', color: 'text-yellow-600', icon: Zap }
  return { label: 'Low', color: 'text-blue-600', icon: TrendingUp }
}

export default function TopViralPosts({
  title,
  data = [],
  animation = 'row-reveal',
  interaction = 'sort-filter',
  onPostClick
}: TopViralPostsProps) {
  const [sortField, setSortField] = useState<SortField>('impact_score')
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc')
  const [selectedRow, setSelectedRow] = useState<number | null>(null)
  const [filterPlatform, setFilterPlatform] = useState<string>('all')
  const [filterRisk, setFilterRisk] = useState<string>('all')

  // Add null check
  if (!data || !Array.isArray(data) || data.length === 0) {
    return (
      <div className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-lg p-6">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">{title}</h3>
        <div className="flex items-center justify-center h-80">
          <div className="text-center text-gray-600 dark:text-gray-400">No viral posts data available</div>
        </div>
      </div>
    )
  }

  const platforms = ['all', ...Array.from(new Set(data.map(item => item.platform)))]
  const riskLevels = ['all', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW']

  const handleSort = (field: SortField) => {
    if (interaction === 'sort-filter') {
      if (sortField === field) {
        setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc')
      } else {
        setSortField(field)
        setSortDirection('desc')
      }
    }
  }

  const getSortedData = () => {
    let filteredData = data

    if (filterPlatform !== 'all') {
      filteredData = filteredData.filter(item => item.platform === filterPlatform)
    }

    if (filterRisk !== 'all') {
      filteredData = filteredData.filter(item => item.risk === filterRisk)
    }

    return filteredData.sort((a, b) => {
      const aValue = a[sortField]
      const bValue = b[sortField]

      if (typeof aValue === 'number' && typeof bValue === 'number') {
        return sortDirection === 'asc' ? aValue - bValue : bValue - aValue
      }

      return 0
    })
  }

  const getSortIcon = (field: SortField) => {
    if (sortField !== field) {
      return <ArrowUpDown className="h-4 w-4 text-gray-600 dark:text-gray-400" />
    }

    return sortDirection === 'asc'
      ? <ArrowUp className="h-4 w-4 text-primary" />
      : <ArrowDown className="h-4 w-4 text-primary" />
  }

  const formatNumber = (num: number) => {
    if (num >= 1000000) {
      return (num / 1000000).toFixed(1) + 'M'
    }
    if (num >= 1000) {
      return (num / 1000).toFixed(1) + 'K'
    }
    return num.toString()
  }

  const getPlatformIcon = (platform: string) => {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return '📘'
      case 'instagram':
        return '📷'
      case 'tiktok':
        return '🎵'
      case 'youtube':
        return '📺'
      case 'twitter':
        return '🐦'
      default:
        return '📱'
    }
  }

  const sortedData = getSortedData()
  const criticalCount = data.filter(d => d.risk === 'CRITICAL').length

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, delay: 0.8 }}
      className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-lg p-6"
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-4">
          <motion.h3
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.9 }}
            className="text-lg font-semibold text-gray-900 dark:text-white"
          >
            {title}
          </motion.h3>

          {criticalCount > 0 && (
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 1.0 }}
              className="flex items-center gap-2 px-3 py-1 bg-red-100 dark:bg-red-900/30 rounded-full"
            >
              <AlertTriangle className="h-4 w-4 text-red-600" />
              <span className="text-sm font-medium text-red-600">
                {criticalCount} Critical
              </span>
            </motion.div>
          )}
        </div>

        <div className="flex items-center gap-2">
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="p-2 rounded-md hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors text-gray-600 dark:text-gray-400"
          >
            <Download className="h-4 w-4" />
          </motion.button>

          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="p-2 rounded-md hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors text-gray-600 dark:text-gray-400"
          >
            <Maximize2 className="h-4 w-4" />
          </motion.button>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-2 mb-6">
        {/* Platform Filter */}
        <div className="flex items-center bg-gray-200 dark:bg-gray-700 rounded-md p-1">
          {platforms.map((platform) => (
            <motion.button
              key={platform}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={() => setFilterPlatform(platform)}
              className={`px-3 py-1 text-xs font-medium rounded-md transition-colors ${
                filterPlatform === platform
                  ? 'bg-gray-900 dark:bg-white text-white dark:text-gray-900 shadow-sm'
                  : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
              }`}
            >
              {platform === 'all' ? 'All' : platform}
            </motion.button>
          ))}
        </div>

        {/* Risk Filter */}
        <div className="flex items-center bg-gray-200 dark:bg-gray-700 rounded-md p-1">
          {riskLevels.map((risk) => (
            <motion.button
              key={risk}
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={() => setFilterRisk(risk)}
              className={`px-3 py-1 text-xs font-medium rounded-md transition-colors ${
                filterRisk === risk
                  ? 'bg-gray-900 dark:bg-white text-white dark:text-gray-900 shadow-sm'
                  : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
              }`}
            >
              {risk === 'all' ? 'All Risk' : risk}
            </motion.button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-amber-300/60 dark:border-white/20">
              <th className="text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400">
                #
              </th>
              <th className="text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400">
                Content
              </th>
              <th className="text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400">
                Platform
              </th>
              <th
                className={`text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400 ${
                  interaction === 'sort-filter' ? 'cursor-pointer hover:text-gray-900 dark:hover:text-white' : ''
                }`}
                onClick={() => handleSort('impact_score')}
              >
                <div className="flex items-center gap-2">
                  Impact Score
                  {interaction === 'sort-filter' && getSortIcon('impact_score')}
                </div>
              </th>
              <th
                className={`text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400 ${
                  interaction === 'sort-filter' ? 'cursor-pointer hover:text-gray-900 dark:hover:text-white' : ''
                }`}
                onClick={() => handleSort('virality_index')}
              >
                <div className="flex items-center gap-2">
                  Virality
                  {interaction === 'sort-filter' && getSortIcon('virality_index')}
                </div>
              </th>
              <th className="text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400">
                Risk
              </th>
              <th
                className={`text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400 ${
                  interaction === 'sort-filter' ? 'cursor-pointer hover:text-gray-900 dark:hover:text-white' : ''
                }`}
                onClick={() => handleSort('engagement')}
              >
                <div className="flex items-center gap-2">
                  Engagement
                  {interaction === 'sort-filter' && getSortIcon('engagement')}
                </div>
              </th>
              <th className="text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400">
                Actions
              </th>
            </tr>
          </thead>
          <tbody>
            <AnimatePresence>
              {sortedData.map((item, index) => {
                const viralityLevel = getViralityLevel(item.virality_index)
                const ViralityIcon = viralityLevel.icon

                return (
                  <motion.tr
                    key={item.id}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -20 }}
                    transition={{ delay: index * 0.05 }}
                    whileHover={{ backgroundColor: 'rgba(0, 0, 0, 0.02)' }}
                    className={`border-b border-amber-300/60 dark:border-white/20 transition-colors cursor-pointer ${
                      selectedRow === item.id ? 'bg-primary/5' : ''
                    }`}
                    onClick={() => {
                      setSelectedRow(selectedRow === item.id ? null : item.id)
                      if (onPostClick) onPostClick(item)
                    }}
                  >
                    <td className="py-4 px-4 text-sm text-gray-600 dark:text-gray-400">
                      {index + 1}
                    </td>
                    <td className="py-4 px-4">
                      <div className="font-medium text-sm max-w-xs truncate">
                        {item.title}
                      </div>
                      <div className="text-xs text-gray-600 dark:text-gray-400">
                        {item.timestamp}
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <div className="flex items-center gap-2">
                        <span className="text-lg">{getPlatformIcon(item.platform)}</span>
                        <span className="text-sm">{item.platform}</span>
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <div className="flex items-center gap-2">
                        <div className="w-16 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                          <div
                            className="bg-gradient-to-r from-blue-500 to-purple-500 h-2 rounded-full"
                            style={{ width: `${item.impact_score}%` }}
                          />
                        </div>
                        <span className="text-sm font-bold">{item.impact_score}</span>
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <div className="flex items-center gap-2">
                        <ViralityIcon className={`h-4 w-4 ${viralityLevel.color}`} />
                        <span className={`text-sm font-medium ${viralityLevel.color}`}>
                          {item.virality_index}
                        </span>
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <span className={`px-2 py-1 rounded-full text-xs font-medium ${getRiskColor(item.risk)}`}>
                        {item.risk}
                      </span>
                    </td>
                    <td className="py-4 px-4">
                      <div className="flex items-center gap-2">
                        <Heart className="h-4 w-4 text-red-500" />
                        <span className="text-sm font-medium">
                          {formatNumber(item.engagement)}
                        </span>
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <div className="flex items-center gap-2">
                        <motion.button
                          whileHover={{ scale: 1.1 }}
                          whileTap={{ scale: 0.9 }}
                          className="p-1 rounded-md hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                          onClick={(e) => {
                            e.stopPropagation()
                          }}
                        >
                          <ExternalLink className="h-4 w-4 text-gray-600 dark:text-gray-400" />
                        </motion.button>
                        <motion.button
                          whileHover={{ scale: 1.1 }}
                          whileTap={{ scale: 0.9 }}
                          className="p-1 rounded-md hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                          onClick={(e) => {
                            e.stopPropagation()
                          }}
                        >
                          <Share className="h-4 w-4 text-gray-600 dark:text-gray-400" />
                        </motion.button>
                      </div>
                    </td>
                  </motion.tr>
                )
              })}
            </AnimatePresence>
          </tbody>
        </table>
      </div>

      {/* Detail Panel */}
      <AnimatePresence>
        {selectedRow && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="mt-4 p-4 bg-gray-200/50 dark:bg-gray-700/50 rounded-lg"
          >
            <h4 className="font-medium mb-2">Post Analysis</h4>
            <div className="text-sm text-gray-600 dark:text-gray-400 space-y-1">
              {(() => {
                const item = data.find(d => d.id === selectedRow)
                if (!item) return null

                return (
                  <>
                    <div>Impact Score: <span className="font-medium">{item.impact_score}/100</span></div>
                    <div>Virality Index: <span className="font-medium">{item.virality_index}</span></div>
                    <div>Risk Level: <span className={`font-medium ${getRiskColor(item.risk)}`}>{item.risk}</span></div>
                    <div>Engagement Rate: <span className="font-medium">{((item.engagement / item.reach) * 100).toFixed(2)}%</span></div>
                    <div>Performance: <span className="font-medium">
                      {item.impact_score >= 80 ? 'Extremely High' :
                       item.impact_score >= 60 ? 'High' :
                       item.impact_score >= 40 ? 'Medium' : 'Low'}
                    </span></div>
                  </>
                )
              })()}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Summary Stats */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 1.0 }}
        className="mt-6 grid grid-cols-2 md:grid-cols-4 gap-4 pt-4 border-t border-amber-300/60 dark:border-white/20"
      >
        <div className="text-center">
          <div className="text-2xl font-bold text-purple-600">
            {(sortedData.reduce((sum, item) => sum + item.impact_score, 0) / sortedData.length).toFixed(1)}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Avg Impact</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold text-orange-600">
            {(sortedData.reduce((sum, item) => sum + item.virality_index, 0) / sortedData.length).toFixed(1)}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Avg Virality</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold text-blue-600">
            {formatNumber(sortedData.reduce((sum, item) => sum + item.engagement, 0))}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Total Engagement</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold text-red-600">
            {sortedData.filter(d => d.risk === 'CRITICAL' || d.risk === 'HIGH').length}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">High Risk Posts</div>
        </div>
      </motion.div>
    </motion.div>
  )
}
