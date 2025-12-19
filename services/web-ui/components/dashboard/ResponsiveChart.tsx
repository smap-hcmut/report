import { ReactNode } from 'react'
import { motion } from 'framer-motion'
import { useResponsive } from '@/hooks/useResponsive'

interface ResponsiveChartProps {
  children: ReactNode
  title: string
  className?: string
  mobileHeight?: number
  desktopHeight?: number
}

export default function ResponsiveChart({ 
  children, 
  title, 
  className = '',
  mobileHeight = 300,
  desktopHeight = 400
}: ResponsiveChartProps) {
  const { isMobile, isTablet } = useResponsive()
  
  const height = isMobile ? mobileHeight : isTablet ? mobileHeight + 50 : desktopHeight

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6 }}
      className={`bg-card border border-border rounded-lg p-4 ${className}`}
    >
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold">{title}</h3>
      </div>
      
      <div style={{ height: `${height}px` }} className="w-full">
        {children}
      </div>
    </motion.div>
  )
}
