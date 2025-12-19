import { useState } from 'react'
import { motion } from 'framer-motion'
import {
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  Tooltip,
  Legend
} from 'recharts'
import {
  MoreHorizontal,
  Download,
  Maximize2,
  TrendingUp,
  TrendingDown,
  Minus
} from 'lucide-react'

interface SentimentData {
  name: string
  value: number
  color: string
  [key: string]: any
}

interface SentimentChartProps {
  title: string
  data: SentimentData[]
  animation?: 'pie-reveal' | 'fade-in'
  interaction?: 'hover-details' | 'click-slice'
}

const CustomTooltip = ({ active, payload }: any) => {
  if (active && payload && payload.length) {
    const data = payload[0]
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-lg p-3 shadow-lg"
      >
        <div className="flex items-center gap-2 mb-1">
          <div
            className="w-3 h-3 rounded-full"
            style={{ backgroundColor: data.payload.color }}
          />
          <span className="font-medium">{data.payload.name}</span>
        </div>
        <div className="text-sm text-gray-600 dark:text-gray-400">
          {data.value}% ({data.payload.value} mentions)
        </div>
      </motion.div>
    )
  }
  return null
}

const CustomLegend = ({ payload }: any) => {
  return (
    <div className="flex justify-center gap-4 mt-4">
      {payload.map((entry: any, index: number) => (
        <motion.div
          key={entry.value}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: index * 0.1 }}
          className="flex items-center gap-2"
        >
          <div
            className="w-3 h-3 rounded-full"
            style={{ backgroundColor: entry.color }}
          />
          <span className="text-sm text-gray-600 dark:text-gray-400">{entry.value}</span>
        </motion.div>
      ))}
    </div>
  )
}

export default function SentimentChart({
  title,
  data,
  animation = 'pie-reveal',
  interaction = 'hover-details'
}: SentimentChartProps) {
  const [activeIndex, setActiveIndex] = useState<number | null>(null)
  const [selectedSentiment, setSelectedSentiment] = useState<string | null>(null)

  const totalMentions = data.reduce((sum, item) => sum + item.value, 0)

  const getSentimentTrend = () => {
    const positive = data.find(d => d.name === 'Positive')?.value || 0
    const negative = data.find(d => d.name === 'Negative')?.value || 0
    const netSentiment = positive - negative

    return {
      value: netSentiment,
      trend: netSentiment > 0 ? 'up' : netSentiment < 0 ? 'down' : 'neutral'
    }
  }

  const { value: netSentiment, trend } = getSentimentTrend()

  const handlePieClick = (data: any, index: number) => {
    if (interaction === 'click-slice') {
      setActiveIndex(activeIndex === index ? null : index)
      setSelectedSentiment(data.name)
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.8, delay: 0.2 }}
      className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-lg p-6"
    >
      {}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-4">
          <motion.h3
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.3 }}
            className="text-lg font-semibold text-gray-900 dark:text-white"
          >
            {title}
          </motion.h3>

          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.4 }}
            className="flex items-center gap-2"
          >
            {trend === 'up' ? (
              <TrendingUp className="h-4 w-4 text-green-600" />
            ) : trend === 'down' ? (
              <TrendingDown className="h-4 w-4 text-red-600" />
            ) : (
              <Minus className="h-4 w-4 text-gray-600" />
            )}
            <span className={`text-sm font-medium ${
              trend === 'up' ? 'text-green-600' :
              trend === 'down' ? 'text-red-600' :
              'text-gray-600'
            }`}>
              Net: {netSentiment > 0 ? '+' : ''}{netSentiment.toFixed(1)}%
            </span>
          </motion.div>
        </div>

        <div className="flex items-center gap-2">
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
      <div className="h-80 w-full flex items-center justify-center">
        <ResponsiveContainer width="100%" height="100%" minHeight={300}>
          <PieChart>
            <Pie
              data={data}
              cx="50%"
              cy="50%"
              innerRadius={60}
              outerRadius={120}
              paddingAngle={2}
              dataKey="value"
              animationBegin={0}
              animationDuration={1500}
              animationEasing="ease-out"
              onClick={handlePieClick}
            >
              {data.map((entry, index) => (
                <Cell
                  key={`cell-${index}`}
                  fill={entry.color}
                  className={`hover:opacity-80 transition-opacity cursor-pointer ${
                    activeIndex === index ? 'opacity-80' : ''
                  }`}
                  stroke={activeIndex === index ? '#000' : 'none'}
                  strokeWidth={activeIndex === index ? 2 : 0}
                />
              ))}
            </Pie>

            <Tooltip content={<CustomTooltip />} />
            <Legend />
          </PieChart>
        </ResponsiveContainer>
      </div>

      {}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
        className="mt-6 grid grid-cols-3 gap-4"
      >
        {data.map((item, index) => (
          <motion.div
            key={item.name}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.7 + index * 0.1 }}
            className={`text-center p-3 rounded-lg transition-colors cursor-pointer ${
              selectedSentiment === item.name
                ? 'bg-primary/10 border border-primary/20'
                : 'bg-gray-200/50 dark:bg-gray-700/50 hover:bg-gray-200 dark:hover:bg-gray-700'
            }`}
            onClick={() => setSelectedSentiment(
              selectedSentiment === item.name ? null : item.name
            )}
          >
            <div className="text-lg font-bold" style={{ color: item.color }}>
              {item.value}%
            </div>
            <div className="text-sm text-gray-600 dark:text-gray-400">{item.name}</div>
            <div className="text-xs text-gray-600 dark:text-gray-400 mt-1">
              {Math.round((item.value / 100) * totalMentions)} mentions
            </div>
          </motion.div>
        ))}
      </motion.div>

      {}
      {selectedSentiment && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: 'auto' }}
          exit={{ opacity: 0, height: 0 }}
          className="mt-4 p-4 bg-gray-200/50 dark:bg-gray-700/50 rounded-lg"
        >
          <h4 className="font-medium mb-2">Details for {selectedSentiment}</h4>
          <div className="text-sm text-gray-600 dark:text-gray-400">
            This represents {data.find(d => d.name === selectedSentiment)?.value}% of total mentions.
            {selectedSentiment === 'Positive' && ' Great sentiment indicates strong brand perception.'}
            {selectedSentiment === 'Negative' && ' Consider addressing concerns to improve sentiment.'}
            {selectedSentiment === 'Neutral' && ' Neutral sentiment provides opportunity for engagement.'}
          </div>
        </motion.div>
      )}
    </motion.div>
  )
}
