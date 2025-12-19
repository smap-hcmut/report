import { useEffect, useRef, useState } from 'react'

export interface PerformanceMetrics {
  renderTime: number
  memoryUsage: number
  fps: number
  componentCount: number
}

export function usePerformanceMonitor(componentName: string) {
  const [metrics, setMetrics] = useState<PerformanceMetrics>({
    renderTime: 0,
    memoryUsage: 0,
    fps: 0,
    componentCount: 0
  })

  const renderStartTime = useRef<number>(0)
  const frameCount = useRef<number>(0)
  const lastTime = useRef<number>(performance.now())
  const animationFrameId = useRef<number | undefined>(undefined)

  useEffect(() => {
    renderStartTime.current = performance.now()

    return () => {
      const renderTime = performance.now() - renderStartTime.current
      setMetrics(prev => ({ ...prev, renderTime }))
    }
  }, [])

  useEffect(() => {
    const measureFPS = () => {
      frameCount.current++
      const currentTime = performance.now()

      if (currentTime - lastTime.current >= 1000) {
        const fps = Math.round((frameCount.current * 1000) / (currentTime - lastTime.current))
        frameCount.current = 0
        lastTime.current = currentTime

        setMetrics(prev => ({ ...prev, fps }))
      }

      animationFrameId.current = requestAnimationFrame(measureFPS)
    }

    animationFrameId.current = requestAnimationFrame(measureFPS)

    return () => {
      if (animationFrameId.current !== undefined) {
        cancelAnimationFrame(animationFrameId.current)
      }
    }
  }, [])

  useEffect(() => {
    const measureMemory = () => {
      if ('memory' in performance) {
        const memory = (performance as any).memory
        setMetrics(prev => ({
          ...prev,
          memoryUsage: Math.round(memory.usedJSHeapSize / 1024 / 1024)
        }))
      }
    }

    const interval = setInterval(measureMemory, 1000)
    return () => clearInterval(interval)
  }, [])

  useEffect(() => {

    const countComponents = () => {
      const reactComponents = document.querySelectorAll('[data-reactroot], [data-react-*]')
      setMetrics(prev => ({ ...prev, componentCount: reactComponents.length }))
    }

    const interval = setInterval(countComponents, 2000)
    return () => clearInterval(interval)
  }, [])

  useEffect(() => {
    if (metrics.renderTime > 16) {
      console.warn(`[${componentName}] Slow render: ${metrics.renderTime.toFixed(2)}ms`)
    }

    if (metrics.fps < 30 && metrics.fps > 0) {
      console.warn(`[${componentName}] Low FPS: ${metrics.fps}`)
    }

    if (metrics.memoryUsage > 100) {
      console.warn(`[${componentName}] High memory usage: ${metrics.memoryUsage}MB`)
    }
  }, [metrics, componentName])

  return metrics
}

export function useDashboardPerformance() {
  const [isMonitoring, setIsMonitoring] = useState(false)
  const [performanceData, setPerformanceData] = useState<PerformanceMetrics[]>([])

  const startMonitoring = () => {
    setIsMonitoring(true)
    setPerformanceData([])
  }

  const stopMonitoring = () => {
    setIsMonitoring(false)
  }

  const clearData = () => {
    setPerformanceData([])
  }

  useEffect(() => {
    if (!isMonitoring) return

    const interval = setInterval(() => {
      const metrics: PerformanceMetrics = {
        renderTime: performance.now(),
        memoryUsage: 'memory' in performance ?
          Math.round((performance as any).memory.usedJSHeapSize / 1024 / 1024) : 0,
        fps: 0,
        componentCount: document.querySelectorAll('[data-reactroot], [data-react-*]').length
      }

      setPerformanceData(prev => [...prev.slice(-99), metrics])
    }, 1000)

    return () => clearInterval(interval)
  }, [isMonitoring])

  return {
    isMonitoring,
    performanceData,
    startMonitoring,
    stopMonitoring,
    clearData
  }
}
