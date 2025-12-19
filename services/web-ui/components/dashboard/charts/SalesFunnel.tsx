import { useState } from 'react'
import { motion } from 'framer-motion'
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
  LabelList
} from 'recharts'
import {
  Download,
  Maximize2,
  TrendingUp,
  TrendingDown,
  Users,
  MessageCircle,
  ShoppingCart,
  DollarSign
} from 'lucide-react'

interface FunnelStageData {
  stage: string
  count: number
  percentage: number
  change: number
  color: string
  icon: any
}

interface SalesFunnelProps {
  title: string
  data: FunnelStageData[]
  animation?: 'bar-grow' | 'fade-in'
  interaction?: 'hover-details' | 'click-stage'
  onStageClick?: (stage: FunnelStageData) => void
}

const CustomTooltip = ({ active, payload }: any) => {
  if (active && payload && payload.length) {
    const data = payload[0].payload
    const Icon = data.icon

    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-white dark:bg-gray-900 border border-amber-300/60 dark:border-white/20 rounded-lg p-3 shadow-lg"
      >
        <div className="flex items-center gap-2 mb-2">
          <Icon className="h-4 w-4" style={{ color: data.color }} />
          <span className="font-semibold text-sm text-gray-900 dark:text-white">
            {data.stage}
          </span>
        </div>
        <div className="text-xs text-gray-600 dark:text-gray-400 space-y-1">
          <div>Count: <span className="font-medium">{data.count.toLocaleString()}</span></div>
          <div>Conversion: <span className="font-medium">{data.percentage.toFixed(1)}%</span></div>
          <div className="flex items-center gap-1">
            Change:
            {data.change > 0 ? (
              <TrendingUp className="h-3 w-3 text-green-600" />
            ) : (
              <TrendingDown className="h-3 w-3 text-red-600" />
            )}
            <span className={`font-medium ${data.change > 0 ? 'text-green-600' : 'text-red-600'}`}>
              {data.change > 0 ? '+' : ''}{data.change.toFixed(1)}%
            </span>
          </div>
        </div>
      </motion.div>
    )
  }
  return null
}

const CustomLabel = (props: any) => {
  const { x, y, width, height, value } = props
  return (
    <text
      x={x + width / 2}
      y={y + height / 2}
      fill="#fff"
      textAnchor="middle"
      dominantBaseline="middle"
      className="text-sm font-bold"
    >
      {value.toLocaleString()}
    </text>
  )
}

export default function SalesFunnel({
  title,
  data = [],
  animation = 'bar-grow',
  interaction = 'hover-details',
  onStageClick
}: SalesFunnelProps) {
  const [selectedStage, setSelectedStage] = useState<string | null>(null)
  const [viewMode, setViewMode] = useState<'count' | 'percentage'>('count')

  // Add null check
  if (!data || !Array.isArray(data) || data.length === 0) {
    return (
      <div className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-lg p-6">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">{title}</h3>
        <div className="flex items-center justify-center h-80">
          <div className="text-center text-gray-600 dark:text-gray-400">No sales funnel data available</div>
        </div>
      </div>
    )
  }

  const handleBarClick = (data: any) => {
    if (interaction === 'click-stage') {
      setSelectedStage(selectedStage === data.stage ? null : data.stage)
      if (onStageClick) onStageClick(data)
    }
  }

  const getConversionRate = (index: number) => {
    if (index === 0) return 100
    const previousCount = data[index - 1].count
    const currentCount = data[index].count
    return (currentCount / previousCount) * 100
  }

  const totalLeads = data[0]?.count || 0
  const totalConverted = data[data.length - 1]?.count || 0
  const overallConversionRate = totalLeads > 0 ? (totalConverted / totalLeads) * 100 : 0

  const chartData = data.map((stage, index) => ({
    ...stage,
    displayValue: viewMode === 'count' ? stage.count : stage.percentage,
    conversionRate: getConversionRate(index)
  }))

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

          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.3 }}
            className="flex items-center gap-2 px-3 py-1 bg-green-100 dark:bg-green-900/30 rounded-full"
          >
            <TrendingUp className="h-4 w-4 text-green-600" />
            <span className="text-sm font-medium text-green-600">
              {overallConversionRate.toFixed(1)}% Overall
            </span>
          </motion.div>
        </div>

        <div className="flex items-center gap-2">
          {/* View Mode Toggle */}
          <div className="flex items-center bg-gray-200 dark:bg-gray-700 rounded-md p-1">
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={() => setViewMode('count')}
              className={`px-3 py-1 text-xs font-medium rounded-md transition-colors ${
                viewMode === 'count'
                  ? 'bg-gray-900 dark:bg-white text-white dark:text-gray-900 shadow-sm'
                  : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
              }`}
            >
              Count
            </motion.button>
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={() => setViewMode('percentage')}
              className={`px-3 py-1 text-xs font-medium rounded-md transition-colors ${
                viewMode === 'percentage'
                  ? 'bg-gray-900 dark:bg-white text-white dark:text-gray-900 shadow-sm'
                  : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
              }`}
            >
              %
            </motion.button>
          </div>

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

      {/* Funnel Chart */}
      <div className="h-80 w-full">
        <ResponsiveContainer width="100%" height="100%" minHeight={300}>
          <BarChart
            data={chartData}
            layout="vertical"
            margin={{ top: 20, right: 30, left: 20, bottom: 5 }}
          >
            <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" horizontal={false} />
            <XAxis
              type="number"
              tick={{ fontSize: 12, fill: '#6b7280' }}
              tickLine={{ stroke: '#e5e7eb' }}
              tickFormatter={(value) => viewMode === 'count' ? value.toLocaleString() : `${value}%`}
            />
            <YAxis
              type="category"
              dataKey="stage"
              tick={{ fontSize: 12, fill: '#6b7280' }}
              tickLine={{ stroke: '#e5e7eb' }}
              width={120}
            />
            <Tooltip content={<CustomTooltip />} cursor={{ fill: 'rgba(0, 0, 0, 0.05)' }} />
            <Bar
              dataKey="displayValue"
              onClick={handleBarClick}
              animationDuration={1500}
              animationEasing="ease-out"
              radius={[0, 8, 8, 0]}
            >
              {chartData.map((entry, index) => (
                <Cell
                  key={`cell-${index}`}
                  fill={entry.color}
                  className="cursor-pointer hover:opacity-80 transition-opacity"
                  opacity={selectedStage === entry.stage || selectedStage === null ? 1 : 0.5}
                />
              ))}
              <LabelList dataKey="displayValue" content={<CustomLabel />} />
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Conversion Rates */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="mt-6 space-y-3"
      >
        <h4 className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-3">Stage Conversion Rates</h4>
        {data.map((stage, index) => {
          const Icon = stage.icon
          const conversionRate = getConversionRate(index)
          const dropoffRate = index > 0 ? 100 - conversionRate : 0

          return (
            <motion.div
              key={stage.stage}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.5 + index * 0.1 }}
              className={`p-3 rounded-lg transition-colors cursor-pointer ${
                selectedStage === stage.stage
                  ? 'bg-primary/10 border border-primary/20'
                  : 'bg-gray-200/50 dark:bg-gray-700/50 hover:bg-gray-200 dark:hover:bg-gray-700'
              }`}
              onClick={() => setSelectedStage(selectedStage === stage.stage ? null : stage.stage)}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Icon className="h-5 w-5" style={{ color: stage.color }} />
                  <div>
                    <div className="font-medium text-sm">{stage.stage}</div>
                    <div className="text-xs text-gray-600 dark:text-gray-400">
                      {stage.count.toLocaleString()} leads
                    </div>
                  </div>
                </div>
                <div className="text-right">
                  {index > 0 && (
                    <div className="text-sm font-bold" style={{ color: stage.color }}>
                      {conversionRate.toFixed(1)}% converted
                    </div>
                  )}
                  {index > 0 && dropoffRate > 0 && (
                    <div className="text-xs text-red-600 dark:text-red-400">
                      -{dropoffRate.toFixed(1)}% drop-off
                    </div>
                  )}
                  {index === 0 && (
                    <div className="text-sm font-bold text-blue-600">
                      100% (Entry)
                    </div>
                  )}
                </div>
              </div>

              {/* Progress Bar */}
              <div className="mt-2 w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                <div
                  className="h-2 rounded-full transition-all duration-500"
                  style={{
                    width: `${stage.percentage}%`,
                    backgroundColor: stage.color
                  }}
                />
              </div>
            </motion.div>
          )
        })}
      </motion.div>

      {/* Summary Stats */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
        className="mt-6 grid grid-cols-2 md:grid-cols-4 gap-4 pt-4 border-t border-amber-300/60 dark:border-white/20"
      >
        <div className="text-center">
          <div className="text-2xl font-bold text-blue-600">
            {totalLeads.toLocaleString()}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Total Leads</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold text-green-600">
            {totalConverted.toLocaleString()}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Converted</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold text-purple-600">
            {overallConversionRate.toFixed(1)}%
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Conversion Rate</div>
        </div>
        <div className="text-center">
          <div className="text-2xl font-bold text-orange-600">
            {(totalLeads - totalConverted).toLocaleString()}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Drop-off</div>
        </div>
      </motion.div>
    </motion.div>
  )
}
