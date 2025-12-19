import React, { useState } from 'react'
import { motion } from 'framer-motion'
import { Calendar, Clock, ChevronRight } from 'lucide-react'
import { useReport } from '@/contexts/ReportContext'

export default function TimeRangeSelector() {
  const { state, updateConfig } = useReport()
  const [selectedPreset, setSelectedPreset] = useState<string>('')

  const presets = [
    { id: 'last-7-days', label: 'Last 7 Days', days: 7 },
    { id: 'last-30-days', label: 'Last 30 Days', days: 30 },
    { id: 'last-90-days', label: 'Last 90 Days', days: 90 },
    { id: 'this-month', label: 'This Month', days: 0, custom: true },
    { id: 'last-month', label: 'Last Month', days: 0, custom: true },
    { id: 'this-quarter', label: 'This Quarter', days: 0, custom: true },
    { id: 'last-quarter', label: 'Last Quarter', days: 0, custom: true },
    { id: 'this-year', label: 'This Year', days: 0, custom: true },
    { id: 'last-year', label: 'Last Year', days: 0, custom: true }
  ]

  const handlePresetSelect = (preset: any) => {
    setSelectedPreset(preset.id)

    const now = new Date()
    let start: Date, end: Date

    switch (preset.id) {
      case 'last-7-days':
        start = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
        end = now
        break
      case 'last-30-days':
        start = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000)
        end = now
        break
      case 'last-90-days':
        start = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000)
        end = now
        break
      case 'this-month':
        start = new Date(now.getFullYear(), now.getMonth(), 1)
        end = now
        break
      case 'last-month':
        start = new Date(now.getFullYear(), now.getMonth() - 1, 1)
        end = new Date(now.getFullYear(), now.getMonth(), 0)
        break
      case 'this-quarter':
        const quarter = Math.floor(now.getMonth() / 3)
        start = new Date(now.getFullYear(), quarter * 3, 1)
        end = now
        break
      case 'last-quarter':
        const lastQuarter = Math.floor(now.getMonth() / 3) - 1
        const lastQuarterYear = lastQuarter < 0 ? now.getFullYear() - 1 : now.getFullYear()
        const lastQuarterMonth = lastQuarter < 0 ? 9 : lastQuarter * 3
        start = new Date(lastQuarterYear, lastQuarterMonth, 1)
        end = new Date(lastQuarterYear, lastQuarterMonth + 3, 0)
        break
      case 'this-year':
        start = new Date(now.getFullYear(), 0, 1)
        end = now
        break
      case 'last-year':
        start = new Date(now.getFullYear() - 1, 0, 1)
        end = new Date(now.getFullYear() - 1, 11, 31)
        break
      default:
        return
    }

    updateConfig({
      timeRange: { start, end }
    })
  }

  const handleCustomDateChange = (type: 'start' | 'end', value: string) => {
    const date = new Date(value)
    if (isNaN(date.getTime())) return

    const currentRange = state.config?.timeRange || { start: new Date(), end: new Date() }
    const newRange = {
      ...currentRange,
      [type]: date
    }

    updateConfig({ timeRange: newRange })
    setSelectedPreset('custom')
  }

  const formatDate = (date: Date) => {
    return date.toISOString().split('T')[0]
  }

  const getDaysDifference = () => {
    if (!state.config?.timeRange) return 0
    const diff = state.config.timeRange.end.getTime() - state.config.timeRange.start.getTime()
    return Math.ceil(diff / (1000 * 60 * 60 * 24))
  }

  return (
    <div className="max-w-4xl mx-auto">
      <div className="text-center mb-8">
        <h2 className="text-2xl font-bold mb-2">Select Time Range</h2>
        <p className="text-muted-foreground">
          Choose the period for your report data
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {}
        <div>
          <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
            <Clock className="h-5 w-5" />
            Quick Presets
          </h3>

          <div className="grid grid-cols-1 gap-3">
            {presets.map((preset, index) => (
              <motion.button
                key={preset.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.3, delay: index * 0.05 }}
                whileHover={{ x: 4 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => handlePresetSelect(preset)}
                className={`p-4 rounded-lg border-2 text-left transition-all ${
                  selectedPreset === preset.id
                    ? 'border-primary bg-primary/5'
                    : 'border-border hover:border-primary/50 hover:bg-muted/50'
                }`}
              >
                <div className="flex items-center justify-between">
                  <div>
                    <div className="font-medium">{preset.label}</div>
                    {preset.days > 0 && (
                      <div className="text-sm text-muted-foreground">
                        {preset.days} days
                      </div>
                    )}
                  </div>
                  <ChevronRight className="h-4 w-4 text-muted-foreground" />
                </div>
              </motion.button>
            ))}
          </div>
        </div>

        {}
        <div>
          <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            Custom Range
          </h3>

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-2">Start Date</label>
              <input
                type="date"
                value={state.config?.timeRange.start ? formatDate(state.config.timeRange.start) : ''}
                onChange={(e) => handleCustomDateChange('start', e.target.value)}
                className="w-full p-3 border border-border rounded-lg bg-background focus:ring-2 focus:ring-primary focus:border-transparent"
              />
            </div>

            <div>
              <label className="block text-sm font-medium mb-2">End Date</label>
              <input
                type="date"
                value={state.config?.timeRange.end ? formatDate(state.config.timeRange.end) : ''}
                onChange={(e) => handleCustomDateChange('end', e.target.value)}
                className="w-full p-3 border border-border rounded-lg bg-background focus:ring-2 focus:ring-primary focus:border-transparent"
              />
            </div>
          </div>

          {}
          {state.config?.timeRange && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="mt-6 p-4 bg-muted/50 rounded-lg border border-border"
            >
              <h4 className="font-medium mb-2">Selected Period</h4>
              <div className="text-sm text-muted-foreground space-y-1">
                <div>
                  <strong>From:</strong> {state.config.timeRange.start.toLocaleDateString()}
                </div>
                <div>
                  <strong>To:</strong> {state.config.timeRange.end.toLocaleDateString()}
                </div>
                <div>
                  <strong>Duration:</strong> {getDaysDifference()} days
                </div>
              </div>
            </motion.div>
          )}
        </div>
      </div>

      {}
      {state.config?.timeRange && getDaysDifference() > 365 && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg"
        >
          <div className="flex items-center gap-2 text-yellow-800">
            <Clock className="h-4 w-4" />
            <span className="font-medium">Long Period Selected</span>
          </div>
          <p className="text-sm text-yellow-700 mt-1">
            Reports covering more than 1 year may take longer to generate and could result in large file sizes.
          </p>
        </motion.div>
      )}
    </div>
  )
}
