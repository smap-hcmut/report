import { useState } from 'react'
import { motion } from 'framer-motion'
import {
  ScatterChart,
  Scatter,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
  ZAxis
} from 'recharts'
import {
  Download,
  Maximize2,
  AlertTriangle,
  AlertCircle,
  Info
} from 'lucide-react'

interface CrisisDataPoint {
  id: string
  timestamp: number
  date: string
  impact_score: number
  risk: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW'
  title: string
  platform: string
  mentions: number
}

interface CrisisRadarProps {
  title: string
  data: CrisisDataPoint[]
  animation?: 'fade-in' | 'scale-up'
  interaction?: 'click-details' | 'hover-only'
  onPointClick?: (point: CrisisDataPoint) => void
}

const CustomTooltip = ({ active, payload }: any) => {
  if (active && payload && payload.length) {
    const data = payload[0].payload
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-white dark:bg-gray-900 border border-amber-300/60 dark:border-white/20 rounded-lg p-3 shadow-lg max-w-xs"
      >
        <div className="flex items-center gap-2 mb-2">
          {data.risk === 'CRITICAL' && <AlertTriangle className="h-4 w-4 text-red-500" />}
          {data.risk === 'HIGH' && <AlertCircle className="h-4 w-4 text-orange-500" />}
          {data.risk === 'MEDIUM' && <Info className="h-4 w-4 text-yellow-500" />}
          {data.risk === 'LOW' && <Info className="h-4 w-4 text-blue-500" />}
          <span className="font-semibold text-sm text-gray-900 dark:text-white">
            {data.risk} RISK
          </span>
        </div>
        <p className="text-sm font-medium text-gray-900 dark:text-white mb-1">{data.title}</p>
        <div className="text-xs text-gray-600 dark:text-gray-400 space-y-1">
          <div>Impact Score: <span className="font-medium">{data.impact_score.toFixed(2)}</span></div>
          <div>Platform: <span className="font-medium">{data.platform}</span></div>
          <div>Mentions: <span className="font-medium">{data.mentions.toLocaleString()}</span></div>
          <div>Time: <span className="font-medium">{data.date}</span></div>
        </div>
      </motion.div>
    )
  }
  return null
}

const getRiskColor = (risk: string) => {
  switch (risk) {
    case 'CRITICAL':
      return '#ef4444' // red-500
    case 'HIGH':
      return '#f97316' // orange-500
    case 'MEDIUM':
      return '#eab308' // yellow-500
    case 'LOW':
      return '#3b82f6' // blue-500
    default:
      return '#6b7280' // gray-500
  }
}

export default function CrisisRadar({
  title,
  data = [],
  animation = 'fade-in',
  interaction = 'hover-only',
  onPointClick
}: CrisisRadarProps) {
  const [selectedRisk, setSelectedRisk] = useState<string | null>(null)
  const [hoveredPoint, setHoveredPoint] = useState<CrisisDataPoint | null>(null)

  // Add null check
  if (!data || !Array.isArray(data)) {
    return (
      <div className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-lg p-6">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">{title}</h3>
        <div className="flex items-center justify-center h-80">
          <div className="text-center text-gray-600 dark:text-gray-400">No crisis data available</div>
        </div>
      </div>
    )
  }

  const filteredData = selectedRisk
    ? data.filter(d => d.risk === selectedRisk)
    : data

  const criticalCount = data.filter(d => d.risk === 'CRITICAL').length
  const highCount = data.filter(d => d.risk === 'HIGH').length

  const riskLevels = [
    { level: 'CRITICAL', count: criticalCount, color: '#ef4444', icon: AlertTriangle },
    { level: 'HIGH', count: highCount, color: '#f97316', icon: AlertCircle },
    { level: 'MEDIUM', count: data.filter(d => d.risk === 'MEDIUM').length, color: '#eab308', icon: Info },
    { level: 'LOW', count: data.filter(d => d.risk === 'LOW').length, color: '#3b82f6', icon: Info }
  ]

  const formatXAxisLabel = (timestamp: number) => {
    const date = new Date(timestamp)
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
  }

  const handlePointClick = (data: any) => {
    if (interaction === 'click-details' && onPointClick) {
      onPointClick(data)
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6 }}
      className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-lg p-6"
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-4">
          <motion.h3
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.2 }}
            className="text-lg font-semibold text-gray-900 dark:text-white"
          >
            {title}
          </motion.h3>

          {criticalCount > 0 && (
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.3 }}
              className="flex items-center gap-2 px-3 py-1 bg-red-100 dark:bg-red-900/30 rounded-full"
            >
              <AlertTriangle className="h-4 w-4 text-red-600" />
              <span className="text-sm font-medium text-red-600">
                {criticalCount} Critical Alert{criticalCount > 1 ? 's' : ''}
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

      {/* Risk Level Filters */}
      <div className="flex gap-2 mb-6 overflow-x-auto pb-2">
        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={() => setSelectedRisk(null)}
          className={`px-3 py-2 rounded-lg text-sm font-medium transition-colors whitespace-nowrap ${
            selectedRisk === null
              ? 'bg-gray-900 dark:bg-white text-white dark:text-gray-900'
              : 'bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-300 dark:hover:bg-gray-600'
          }`}
        >
          All ({data.length})
        </motion.button>
        {riskLevels.map((risk, index) => {
          const Icon = risk.icon
          return (
            <motion.button
              key={risk.level}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.1 * index }}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => setSelectedRisk(selectedRisk === risk.level ? null : risk.level)}
              className={`px-3 py-2 rounded-lg text-sm font-medium transition-colors flex items-center gap-2 whitespace-nowrap ${
                selectedRisk === risk.level
                  ? 'bg-gray-900 dark:bg-white text-white dark:text-gray-900'
                  : 'bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-300 dark:hover:bg-gray-600'
              }`}
              style={
                selectedRisk === risk.level
                  ? { backgroundColor: risk.color, color: 'white' }
                  : {}
              }
            >
              <Icon className="h-4 w-4" />
              {risk.level} ({risk.count})
            </motion.button>
          )
        })}
      </div>

      {/* Chart */}
      <div className="h-80 w-full">
        <ResponsiveContainer width="100%" height="100%" minHeight={300}>
          <ScatterChart margin={{ top: 20, right: 20, bottom: 20, left: 20 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
            <XAxis
              dataKey="timestamp"
              type="number"
              domain={['dataMin', 'dataMax']}
              tick={{ fontSize: 12, fill: '#6b7280' }}
              tickLine={{ stroke: '#e5e7eb' }}
              tickFormatter={formatXAxisLabel}
              name="Time"
            />
            <YAxis
              dataKey="impact_score"
              type="number"
              tick={{ fontSize: 12, fill: '#6b7280' }}
              tickLine={{ stroke: '#e5e7eb' }}
              name="Impact Score"
              domain={[0, 100]}
            />
            <ZAxis dataKey="mentions" range={[50, 400]} />
            <Tooltip content={<CustomTooltip />} cursor={{ strokeDasharray: '3 3' }} />
            <Scatter
              data={filteredData}
              onClick={handlePointClick}
              animationDuration={1500}
              animationEasing="ease-out"
            >
              {filteredData.map((entry, index) => (
                <Cell
                  key={`cell-${index}`}
                  fill={getRiskColor(entry.risk)}
                  fillOpacity={0.8}
                  className="cursor-pointer hover:opacity-100 transition-opacity"
                />
              ))}
            </Scatter>
          </ScatterChart>
        </ResponsiveContainer>
      </div>

      {/* Summary Stats */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="mt-6 grid grid-cols-2 md:grid-cols-4 gap-4"
      >
        {riskLevels.map((risk, index) => {
          const Icon = risk.icon
          return (
            <motion.div
              key={risk.level}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.5 + index * 0.1 }}
              className="p-3 rounded-lg bg-gray-200/50 dark:bg-gray-700/50"
            >
              <div className="flex items-center gap-2 mb-1">
                <Icon className="h-4 w-4" style={{ color: risk.color }} />
                <span className="text-xs font-medium text-gray-600 dark:text-gray-400">
                  {risk.level}
                </span>
              </div>
              <div className="text-2xl font-bold" style={{ color: risk.color }}>
                {risk.count}
              </div>
            </motion.div>
          )
        })}
      </motion.div>
    </motion.div>
  )
}
