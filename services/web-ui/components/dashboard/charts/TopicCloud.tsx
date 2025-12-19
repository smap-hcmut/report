import { useEffect, useRef, useState } from 'react'
import { motion } from 'framer-motion'
import {
  Download,
  Maximize2,
  Hash,
  TrendingUp
} from 'lucide-react'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js'
import { WordCloudController, WordElement } from 'chartjs-chart-wordcloud'

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  WordCloudController,
  WordElement
)

interface TopicData {
  text: string
  value: number
  sentiment?: number
  confidence?: number
  trend?: 'rising' | 'falling' | 'stable'
  mentions?: number
  engagement?: number
}

interface TopicCloudProps {
  title: string
  data: TopicData[]
  animation?: 'word-cloud' | 'fade-in'
  interaction?: 'click-filter' | 'hover-only'
  onTopicClick?: (topic: TopicData) => void
}

export default function TopicCloud({
  title,
  data,
  animation = 'word-cloud',
  interaction = 'click-filter',
  onTopicClick
}: TopicCloudProps) {
  const chartRef = useRef<ChartJS<'wordCloud', any, string> | null>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const timeoutRef = useRef<NodeJS.Timeout | null>(null)
  const [canvasKey, setCanvasKey] = useState(0)
  const [renderFallback, setRenderFallback] = useState(false)

  const getColor = (sentiment: number = 0, trend: string = 'stable') => {
    if (trend === 'rising') {
      return sentiment > 0 ? '#10b981' : sentiment < 0 ? '#ef4444' : '#6b7280'
    } else if (trend === 'falling') {
      return '#9ca3af'
    }
    return sentiment > 0 ? '#3b82f6' : sentiment < 0 ? '#f59e0b' : '#6b7280'
  }

  useEffect(() => {
    if (!data.length) return

    setRenderFallback(false)
    setCanvasKey(prev => prev + 1)
  }, [data])

  useEffect(() => {
    if (!canvasRef.current || !data.length) {
      setRenderFallback(true)
      return
    }

    if (chartRef.current) {
      chartRef.current.destroy()
      chartRef.current = null
    }

    const sortedData = [...data]
      .filter(item => item.text && item.text.trim().length > 0)
      .sort((a, b) => b.value - a.value)
      .slice(0, 50)

    if (sortedData.length === 0) {
      setRenderFallback(true)
      return
    }

    const words = sortedData.map(item => ({
      text: item.text.trim(),
      weight: Math.max(1, Math.min(item.value, 50)),
      sentiment: item.sentiment || 0,
      trend: item.trend || 'stable',
      mentions: item.mentions || 0,
      engagement: item.engagement || 0,
      color: getColor(item.sentiment, item.trend)
    }))

    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current)
    }

    timeoutRef.current = setTimeout(() => {
      try {
        chartRef.current = new ChartJS(canvasRef.current, {
        type: 'wordCloud',
        data: {
          labels: words.map(d => d.text),
          datasets: [
            {
              label: '',
              data: words.map(d => d.weight)
            }
          ]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          onClick: (event, elements) => {
            if (elements.length > 0 && onTopicClick && interaction === 'click-filter') {
              const elementIndex = elements[0].index
              const clickedTopic = sortedData[elementIndex]
              if (clickedTopic) {
                onTopicClick(clickedTopic)
              }
            }
          },
          plugins: {
            legend: {
              display: false
            },
            tooltip: {
              callbacks: {
                title: (context) => {
                  const index = context[0].dataIndex
                  return words[index]?.text || ''
                },
                label: (context) => {
                  const index = context.dataIndex
                  const word = words[index]
                  if (!word) return []
                  return [
                    `Frequency: ${word.weight}`,
                    `Mentions: ${word.mentions}`,
                    `Engagement: ${word.engagement}`,
                    `Trend: ${word.trend}`,
                    `Sentiment: ${word.sentiment?.toFixed(2) || '0.00'}`,
                    interaction === 'click-filter' ? 'Click to view details' : ''
                  ].filter(Boolean)
                }
              }
            }
          },
          scales: {
            x: {
              display: false
            },
            y: {
              display: false
            }
          }
        }
      })
      } catch (error) {
        console.warn('WordCloud rendering failed:', error)
        setRenderFallback(true)
      }
    }, 50)

    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current)
        timeoutRef.current = null
      }
      if (chartRef.current) {
        chartRef.current.destroy()
        chartRef.current = null
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [canvasKey, data])

  const topTrendingTopics = [...data]
    .filter(item => item.text && item.text.trim().length > 0)
    .sort((a, b) => b.value - a.value)
    .slice(0, 5)

  const handleTopicClick = (topic: TopicData) => {
    if (onTopicClick && interaction === 'click-filter') {
      onTopicClick(topic)
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, delay: 0.7 }}
      className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-lg p-6"
    >
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-4">
          <motion.h3
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.8 }}
            className="text-lg font-semibold text-gray-900 dark:text-white"
          >
            {title}
          </motion.h3>

          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.9 }}
            className="flex items-center gap-2"
          >
            <Hash className="h-4 w-4 text-blue-600" />
            <span className="text-sm font-medium text-blue-600">
              {data.length} Topics
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

      <div className="relative h-80 w-full mb-6 overflow-hidden rounded-lg bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50">
        {renderFallback ? (
          <div className="flex items-center justify-center h-full">
            <div className="text-center">
              <div className="text-4xl font-bold text-gray-600 dark:text-gray-400 mb-2">📊</div>
              <div className="text-sm text-gray-600 dark:text-gray-400">Word cloud unavailable</div>
              <div className="text-xs text-gray-600 dark:text-gray-400 mt-1">Showing topic list below</div>
            </div>
          </div>
        ) : (
          <canvas
            key={canvasKey}
            ref={canvasRef}
            className={`w-full h-full ${
              interaction === 'click-filter' && onTopicClick ? 'cursor-pointer' : ''
            }`}
          />
        )}
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 1.0 }}
        className="space-y-3"
      >
        <div className="flex items-center gap-2 mb-3">
          <TrendingUp className="h-4 w-4 text-green-600" />
          <h4 className="text-sm font-medium text-gray-600 dark:text-gray-400">Top Trending Topics</h4>
        </div>

        {topTrendingTopics.map((topic, index) => (
          <motion.div
            key={topic.text}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 1.1 + index * 0.1 }}
            onClick={() => handleTopicClick(topic)}
            className={`flex items-center justify-between p-3 rounded-lg bg-gray-200/50 dark:bg-gray-700/50 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors ${
              interaction === 'click-filter' ? 'cursor-pointer hover:shadow-md' : ''
            }`}
          >
            <div className="flex items-center gap-3">
              <div className="flex items-center justify-center w-6 h-6 rounded-full bg-gray-200 dark:bg-gray-700 text-xs font-bold">
                {index + 1}
              </div>
              <div
                className="w-3 h-3 rounded-full"
                style={{ backgroundColor: getColor(topic.sentiment, topic.trend) }}
              />
              <span className="font-medium">{topic.text}</span>
            </div>
            <div className="text-sm font-bold">{topic.value}</div>
          </motion.div>
        ))}
      </motion.div>
    </motion.div>
  )
}
