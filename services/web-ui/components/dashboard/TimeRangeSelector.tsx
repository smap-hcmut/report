import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Calendar, ChevronDown } from 'lucide-react'
import { useTranslation } from 'next-i18next'

interface TimeRangeSelectorProps {
  selectedRange: string
  onRangeChange: (range: string) => void
}

export default function TimeRangeSelector({ selectedRange, onRangeChange }: TimeRangeSelectorProps) {
  const { t } = useTranslation('common')
  const [isOpen, setIsOpen] = useState(false)

  const ranges = [
    { value: '7d', label: t('dashboard.timeRanges.last7Days') },
    { value: '30d', label: t('dashboard.timeRanges.last30Days') },
    { value: '90d', label: t('dashboard.timeRanges.last90Days') },
    { value: '1y', label: t('dashboard.timeRanges.lastYear') }
  ]

  const selectedRangeLabel = ranges.find(r => r.value === selectedRange)?.label || t('dashboard.selectRange')

  const handleRangeSelect = (range: string) => {
    onRangeChange(range)
    setIsOpen(false)
  }

  return (
    <div className="relative">
      <motion.button
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-2 bg-muted/50 hover:bg-muted rounded-lg border border-border transition-colors"
      >
        <Calendar className="h-4 w-4 text-muted-foreground" />
        <span className="text-sm font-medium">
          {selectedRangeLabel}
        </span>
        <ChevronDown className={`h-3 w-3 text-muted-foreground transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </motion.button>

      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: -10, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -10, scale: 0.95 }}
            transition={{ duration: 0.2 }}
            className="absolute top-full right-0 mt-2 w-48 bg-card border border-border rounded-lg shadow-lg z-50"
          >
            <div className="p-2">
              {ranges.map((range) => (
                <motion.button
                  key={range.value}
                  whileHover={{ backgroundColor: 'rgba(0,0,0,0.05)' }}
                  onClick={() => handleRangeSelect(range.value)}
                  className={`w-full flex items-center gap-2 px-3 py-2 text-sm rounded-md transition-colors ${
                    range.value === selectedRange
                      ? 'bg-primary/10 text-primary'
                      : 'text-foreground hover:bg-muted/50'
                  }`}
                >
                  <Calendar className="h-4 w-4" />
                  <span>{range.label}</span>
                </motion.button>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setIsOpen(false)}
            className="fixed inset-0 z-40"
          />
        )}
      </AnimatePresence>
    </div>
  )
}
