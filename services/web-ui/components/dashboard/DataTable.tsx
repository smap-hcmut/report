import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  MoreHorizontal,
  Download,
  Maximize2,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  ExternalLink,
  Eye,
  Heart,
  MessageCircle,
  Share
} from 'lucide-react'

interface ContentData {
  id: number
  title: string
  platform: string
  engagement: number
  reach: number
}

interface DataTableProps {
  title: string
  data: ContentData[]
  animation?: 'row-reveal' | 'fade-in'
  interaction?: 'sort-filter' | 'read-only'
}

type SortField = 'title' | 'platform' | 'engagement' | 'reach'
type SortDirection = 'asc' | 'desc'

export default function DataTable({
  title,
  data,
  animation = 'row-reveal',
  interaction = 'sort-filter'
}: DataTableProps) {
  const [sortField, setSortField] = useState<SortField>('engagement')
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc')
  const [selectedRow, setSelectedRow] = useState<number | null>(null)
  const [filterPlatform, setFilterPlatform] = useState<string>('all')

  const platforms = ['all', ...Array.from(new Set(data.map(item => item.platform)))]

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
      filteredData = data.filter(item => item.platform === filterPlatform)
    }

    return filteredData.sort((a, b) => {
      const aValue = a[sortField]
      const bValue = b[sortField]

      if (typeof aValue === 'string' && typeof bValue === 'string') {
        return sortDirection === 'asc'
          ? aValue.localeCompare(bValue)
          : bValue.localeCompare(aValue)
      }

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

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, delay: 0.8 }}
      className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-lg p-6"
    >
      {}
      <div className="flex items-center justify-between mb-6">
        <motion.h3
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.9 }}
          className="text-lg font-semibold text-gray-900 dark:text-white"
        >
          {title}
        </motion.h3>

        <div className="flex items-center gap-2">
          {}
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

          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="p-2 rounded-md hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
          >
            <Download className="h-4 w-4" />
          </motion.button>

          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            className="p-2 rounded-md hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
          >
            <Maximize2 className="h-4 w-4" />
          </motion.button>
        </div>
      </div>

      {}
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-amber-300/60 dark:border-white/20">
              <th className="text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400">
                #
              </th>
              <th
                className={`text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400 ${
                  interaction === 'sort-filter' ? 'cursor-pointer hover:text-gray-900 dark:hover:text-white' : ''
                }`}
                onClick={() => handleSort('title')}
              >
                <div className="flex items-center gap-2">
                  Content
                  {interaction === 'sort-filter' && getSortIcon('title')}
                </div>
              </th>
              <th
                className={`text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400 ${
                  interaction === 'sort-filter' ? 'cursor-pointer hover:text-gray-900 dark:hover:text-white' : ''
                }`}
                onClick={() => handleSort('platform')}
              >
                <div className="flex items-center gap-2">
                  Platform
                  {interaction === 'sort-filter' && getSortIcon('platform')}
                </div>
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
              <th
                className={`text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400 ${
                  interaction === 'sort-filter' ? 'cursor-pointer hover:text-gray-900 dark:hover:text-white' : ''
                }`}
                onClick={() => handleSort('reach')}
              >
                <div className="flex items-center gap-2">
                  Reach
                  {interaction === 'sort-filter' && getSortIcon('reach')}
                </div>
              </th>
              <th className="text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400">
                Actions
              </th>
            </tr>
          </thead>
          <tbody>
            <AnimatePresence>
              {sortedData.map((item, index) => (
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
                  onClick={() => setSelectedRow(selectedRow === item.id ? null : item.id)}
                >
                  <td className="py-4 px-4 text-sm text-gray-600 dark:text-gray-400">
                    {index + 1}
                  </td>
                  <td className="py-4 px-4">
                    <div className="font-medium text-sm max-w-xs truncate">
                      {item.title}
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
                      <Heart className="h-4 w-4 text-red-500" />
                      <span className="text-sm font-medium">
                        {formatNumber(item.engagement)}
                      </span>
                    </div>
                  </td>
                  <td className="py-4 px-4">
                    <div className="flex items-center gap-2">
                      <Eye className="h-4 w-4 text-blue-500" />
                      <span className="text-sm font-medium">
                        {formatNumber(item.reach)}
                      </span>
                    </div>
                  </td>
                  <td className="py-4 px-4">
                    <div className="flex items-center gap-2">
                      <motion.button
                        whileHover={{ scale: 1.1 }}
                        whileTap={{ scale: 0.9 }}
                        className="p-1 rounded-md hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                      >
                        <ExternalLink className="h-4 w-4 text-gray-600 dark:text-gray-400" />
                      </motion.button>
                      <motion.button
                        whileHover={{ scale: 1.1 }}
                        whileTap={{ scale: 0.9 }}
                        className="p-1 rounded-md hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                      >
                        <Share className="h-4 w-4 text-gray-600 dark:text-gray-400" />
                      </motion.button>
                    </div>
                  </td>
                </motion.tr>
              ))}
            </AnimatePresence>
          </tbody>
        </table>
      </div>

      {}
      <AnimatePresence>
        {selectedRow && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="mt-4 p-4 bg-muted/50 rounded-lg"
          >
            <h4 className="font-medium mb-2">Content Analysis</h4>
            <div className="text-sm text-gray-600 dark:text-gray-400 space-y-1">
              {(() => {
                const item = data.find(d => d.id === selectedRow)
                if (!item) return null

                return (
                  <>
                    <div>Title: {item.title}</div>
                    <div>Platform: {item.platform}</div>
                    <div>Engagement Rate: {((item.engagement / item.reach) * 100).toFixed(2)}%</div>
                    <div>Performance: {item.engagement > 1000 ? 'High' : item.engagement > 500 ? 'Medium' : 'Low'}</div>
                  </>
                )
              })()}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 1.0 }}
        className="mt-6 grid grid-cols-3 gap-4 pt-4 border-t border-amber-300/60 dark:border-white/20"
      >
        <div className="text-center">
          <div className="text-2xl font-bold text-blue-600">
            {formatNumber(sortedData.reduce((sum, item) => sum + item.engagement, 0))}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Total Engagement</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold text-green-600">
            {formatNumber(sortedData.reduce((sum, item) => sum + item.reach, 0))}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Total Reach</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold text-purple-600">
            {((sortedData.reduce((sum, item) => sum + item.engagement, 0) /
               sortedData.reduce((sum, item) => sum + item.reach, 0)) * 100).toFixed(1)}%
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Avg Engagement Rate</div>
        </div>
      </motion.div>
    </motion.div>
  )
}
