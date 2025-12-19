import { useState, useEffect, useCallback, useRef } from 'react'

export interface RealTimeData {
  timestamp: number
  metrics: {
    sov: number
    sentiment: number
    mentions: number
    engagement: number
  }
  trends: {
    date: string
    mentions: number
    sentiment: number
  }[]
  sentiment: {
    name: string
    value: number
    color: string
  }[]
  competitors: {
    brand: string
    sov: number
    color: string
  }[]
  topics: {
    text: string
    value: number
    sentiment?: number
    confidence?: number
    trend?: 'rising' | 'falling' | 'stable'
    mentions?: number
    engagement?: number
  }[]
  content: {
    id: number
    title: string
    platform: string
    engagement: number
    reach: number
  }[]
}

interface UseRealTimeDataOptions {
  projectId: string
  interval?: number
  autoConnect?: boolean
}

interface UseRealTimeDataReturn {
  data: RealTimeData | null
  isConnected: boolean
  isConnecting: boolean
  error: string | null
  lastUpdate: Date | null
  connect: () => void
  disconnect: () => void
  refresh: () => void
}

const generateMockData = (): RealTimeData => {
  const now = new Date()
  const baseTime = now.getTime()

  const trends = Array.from({ length: 7 }, (_, i) => {
    const date = new Date(baseTime - (6 - i) * 24 * 60 * 60 * 1000)
    return {
      date: date.toISOString().split('T')[0],
      mentions: Math.floor(Math.random() * 1000) + 500,
      sentiment: (Math.random() - 0.5) * 2
    }
  })

  return {
    timestamp: baseTime,
    metrics: {
      sov: 26.2 + (Math.random() - 0.5) * 2,
      sentiment: 0.34 + (Math.random() - 0.5) * 0.2,
      mentions: 45200 + Math.floor((Math.random() - 0.5) * 5000),
      engagement: 4.8 + (Math.random() - 0.5) * 0.5
    },
    trends,
    sentiment: [
      { name: 'Positive', value: 45 + Math.floor((Math.random() - 0.5) * 10), color: '#10b981' },
      { name: 'Neutral', value: 35 + Math.floor((Math.random() - 0.5) * 10), color: '#6b7280' },
      { name: 'Negative', value: 20 + Math.floor((Math.random() - 0.5) * 10), color: '#ef4444' }
    ],
    competitors: [
      { brand: 'Your Brand', sov: 26.2 + (Math.random() - 0.5) * 2, color: '#3b82f6' },
      { brand: 'Competitor A', sov: 24.8 + (Math.random() - 0.5) * 2, color: '#10b981' },
      { brand: 'Competitor B', sov: 18.5 + (Math.random() - 0.5) * 2, color: '#f59e0b' },
      { brand: 'Competitor C', sov: 15.2 + (Math.random() - 0.5) * 2, color: '#ef4444' },
      { brand: 'Others', sov: 15.3 + (Math.random() - 0.5) * 2, color: '#8b5cf6' }
    ],
    topics: [
      { text: 'coffee', value: 100 + Math.floor((Math.random() - 0.5) * 20), sentiment: 0.7, trend: 'rising', mentions: 1250, engagement: 4.8 },
      { text: 'quality', value: 80 + Math.floor((Math.random() - 0.5) * 20), sentiment: 0.6, trend: 'stable', mentions: 980, engagement: 4.2 },
      { text: 'service', value: 70 + Math.floor((Math.random() - 0.5) * 20), sentiment: 0.5, trend: 'rising', mentions: 850, engagement: 3.9 },
      { text: 'price', value: 60 + Math.floor((Math.random() - 0.5) * 20), sentiment: -0.2, trend: 'falling', mentions: 720, engagement: 3.1 },
      { text: 'atmosphere', value: 50 + Math.floor((Math.random() - 0.5) * 20), sentiment: 0.8, trend: 'stable', mentions: 650, engagement: 4.5 },
      { text: 'taste', value: 45 + Math.floor((Math.random() - 0.5) * 15), sentiment: 0.9, trend: 'rising', mentions: 580, engagement: 4.7 },
      { text: 'experience', value: 40 + Math.floor((Math.random() - 0.5) * 15), sentiment: 0.7, trend: 'stable', mentions: 520, engagement: 4.3 },
      { text: 'location', value: 35 + Math.floor((Math.random() - 0.5) * 15), sentiment: 0.4, trend: 'stable', mentions: 480, engagement: 3.8 },
      { text: 'staff', value: 30 + Math.floor((Math.random() - 0.5) * 15), sentiment: 0.6, trend: 'rising', mentions: 420, engagement: 4.1 },
      { text: 'ambiance', value: 28 + Math.floor((Math.random() - 0.5) * 12), sentiment: 0.8, trend: 'stable', mentions: 380, engagement: 4.4 },
      { text: 'menu', value: 25 + Math.floor((Math.random() - 0.5) * 12), sentiment: 0.5, trend: 'stable', mentions: 350, engagement: 3.7 },
      { text: 'fresh', value: 22 + Math.floor((Math.random() - 0.5) * 12), sentiment: 0.9, trend: 'rising', mentions: 320, engagement: 4.6 },
      { text: 'delicious', value: 20 + Math.floor((Math.random() - 0.5) * 10), sentiment: 0.9, trend: 'stable', mentions: 290, engagement: 4.8 },
      { text: 'friendly', value: 18 + Math.floor((Math.random() - 0.5) * 10), sentiment: 0.7, trend: 'rising', mentions: 260, engagement: 4.2 },
      { text: 'comfortable', value: 16 + Math.floor((Math.random() - 0.5) * 10), sentiment: 0.6, trend: 'stable', mentions: 240, engagement: 3.9 },
      { text: 'aroma', value: 15 + Math.floor((Math.random() - 0.5) * 8), sentiment: 0.8, trend: 'stable', mentions: 220, engagement: 4.3 },
      { text: 'brew', value: 14 + Math.floor((Math.random() - 0.5) * 8), sentiment: 0.7, trend: 'rising', mentions: 200, engagement: 4.1 },
      { text: 'beans', value: 13 + Math.floor((Math.random() - 0.5) * 8), sentiment: 0.6, trend: 'stable', mentions: 180, engagement: 3.8 },
      { text: 'roast', value: 12 + Math.floor((Math.random() - 0.5) * 8), sentiment: 0.7, trend: 'stable', mentions: 160, engagement: 4.0 },
      { text: 'espresso', value: 11 + Math.floor((Math.random() - 0.5) * 6), sentiment: 0.8, trend: 'rising', mentions: 140, engagement: 4.4 }
    ],
    content: [
      { id: 1, title: 'New Coffee Blend Launch', platform: 'Facebook', engagement: 1250 + Math.floor((Math.random() - 0.5) * 200), reach: 15000 + Math.floor((Math.random() - 0.5) * 2000) },
      { id: 2, title: 'Customer Story Feature', platform: 'Instagram', engagement: 980 + Math.floor((Math.random() - 0.5) * 200), reach: 12000 + Math.floor((Math.random() - 0.5) * 2000) },
      { id: 3, title: 'Behind the Scenes Video', platform: 'TikTok', engagement: 2100 + Math.floor((Math.random() - 0.5) * 200), reach: 25000 + Math.floor((Math.random() - 0.5) * 2000) }
    ]
  }
}

export const useRealTimeData = ({
  projectId,
  interval = 5000,
  autoConnect = true
}: UseRealTimeDataOptions): UseRealTimeDataReturn => {
  const [data, setData] = useState<RealTimeData | null>(null)
  const [isConnected, setIsConnected] = useState(false)
  const [isConnecting, setIsConnecting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [lastUpdate, setLastUpdate] = useState<Date | null>(null)

  const intervalRef = useRef<NodeJS.Timeout | null>(null)
  const wsRef = useRef<WebSocket | null>(null)
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null)
  const reconnectAttempts = useRef(0)
  const maxReconnectAttempts = 5

  const connect = useCallback(() => {
    if (isConnecting || isConnected) return

    setIsConnecting(true)
    setError(null)

    try {

      setTimeout(() => {
        setIsConnected(true)
        setIsConnecting(false)
        setLastUpdate(new Date())
        reconnectAttempts.current = 0

        setData(generateMockData())

        intervalRef.current = setInterval(() => {
          setData(prevData => {
            const newData = generateMockData()
            setLastUpdate(new Date())
            return newData
          })
        }, interval)
      }, 1000)

    } catch (err) {
      setError(err instanceof Error ? err.message : 'Connection failed')
      setIsConnecting(false)
      setIsConnected(false)
    }
  }, [projectId, interval, isConnecting, isConnected])

  const disconnect = useCallback(() => {
    if (intervalRef.current) {
      clearInterval(intervalRef.current)
      intervalRef.current = null
    }

    if (wsRef.current) {
      wsRef.current.close()
      wsRef.current = null
    }

    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current)
      reconnectTimeoutRef.current = null
    }

    setIsConnected(false)
    setIsConnecting(false)
    setError(null)
  }, [])

  const refresh = useCallback(() => {
    if (isConnected) {
      setData(generateMockData())
      setLastUpdate(new Date())
    }
  }, [isConnected])

  useEffect(() => {
    if (autoConnect) {
      connect()
    }

    return () => {
      disconnect()
    }
  }, [autoConnect])

  useEffect(() => {
    return () => {
      disconnect()
    }
  }, [])

  return {
    data,
    isConnected,
    isConnecting,
    error,
    lastUpdate,
    connect,
    disconnect,
    refresh
  }
}
