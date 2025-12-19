import React from 'react'
import { motion } from 'framer-motion'
import { Wifi, WifiOff } from 'lucide-react'
import { useTranslation } from 'next-i18next'
import { useDashboard } from '@/contexts/DashboardContext'

export default function RealTimeIndicator() {
  const { t } = useTranslation('common')
  const { state, toggleRealTime } = useDashboard()

  return (
    <div className="flex items-center gap-3">
      <motion.div
        animate={{
          scale: state.isRealTimeEnabled ? [1, 1.2, 1] : 1,
          opacity: state.isRealTimeEnabled ? [0.7, 1, 0.7] : 0.5
        }}
        transition={{
          duration: 2,
          repeat: state.isRealTimeEnabled ? Infinity : 0,
          ease: "easeInOut"
        }}
        className="relative"
      >
        {state.isRealTimeEnabled ? (
          <Wifi className="h-4 w-4 text-green-500" />
        ) : (
          <WifiOff className="h-4 w-4 text-muted-foreground" />
        )}

        {}
        {state.isRealTimeEnabled && (
          <motion.div
            animate={{
              scale: [0, 1, 0],
              opacity: [0, 1, 0]
            }}
            transition={{
              duration: 1.5,
              repeat: Infinity,
              ease: "easeInOut"
            }}
            className="absolute -top-1 -right-1 h-2 w-2 bg-green-500 rounded-full"
          />
        )}
      </motion.div>

      <span className="text-sm text-muted-foreground">
        {state.isRealTimeEnabled ? t('dashboard.realTime') : t('dashboard.offline')}
      </span>

      {}
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={toggleRealTime}
        className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 ${
          state.isRealTimeEnabled ? 'bg-primary' : 'bg-muted'
        }`}
        role="switch"
        aria-checked={state.isRealTimeEnabled}
        aria-label={state.isRealTimeEnabled ? t('dashboard.disableRealTime') : t('dashboard.enableRealTime')}
      >
        <motion.span
          animate={{
            x: state.isRealTimeEnabled ? 16 : 0
          }}
          transition={{
            type: "spring",
            stiffness: 500,
            damping: 30
          }}
          className={`inline-block h-4 w-4 transform rounded-full bg-white shadow-lg transition-colors ${
            state.isRealTimeEnabled ? 'shadow-primary/25' : 'shadow-muted-foreground/25'
          }`}
        />
      </motion.button>
    </div>
  )
}
