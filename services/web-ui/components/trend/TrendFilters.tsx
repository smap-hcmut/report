import React, { useState } from 'react'
import { motion } from 'framer-motion'
import {
  X,
  Calendar,
  Smartphone,
  Hash,
  Filter,
  RotateCcw,
  Check,
  ChevronDown
} from 'lucide-react'
import { useTrend } from '@/contexts/TrendContext'

interface TrendFiltersProps {
  onClose: () => void
}

export default function TrendFilters({ onClose }: TrendFiltersProps) {
  const { state, setFilters, resetFilters } = useTrend()
  const [expandedSections, setExpandedSections] = useState<Set<string>>(
    new Set(['time-range', 'platforms'])
  )

  const timeRanges = [
    { id: '1h', label: 'Last Hour', value: '1h' },
    { id: '24h', label: 'Last 24 Hours', value: '24h' },
    { id: '7d', label: 'Last 7 Days', value: '7d' },
    { id: '30d', label: 'Last 30 Days', value: '30d' },
    { id: '90d', label: 'Last 90 Days', value: '90d' },
    { id: 'custom', label: 'Custom Range', value: 'custom' },
  ]

  const platforms = [
    { id: 'facebook', label: 'Facebook', icon: '📘' },
    { id: 'instagram', label: 'Instagram', icon: '📷' },
    { id: 'tiktok', label: 'TikTok', icon: '🎵' },
    { id: 'twitter', label: 'Twitter', icon: '🐦' },
    { id: 'linkedin', label: 'LinkedIn', icon: '💼' },
    { id: 'youtube', label: 'YouTube', icon: '📺' },
  ]

  const industries = [
    { id: 'food-beverage', label: 'Food & Beverage' },
    { id: 'fashion', label: 'Fashion' },
    { id: 'technology', label: 'Technology' },
    { id: 'beauty', label: 'Beauty' },
    { id: 'travel', label: 'Travel' },
    { id: 'fitness', label: 'Fitness' },
    { id: 'finance', label: 'Finance' },
    { id: 'education', label: 'Education' },
  ]

  const sentimentOptions = [
    { id: 'positive', label: 'Positive', color: 'text-green-600' },
    { id: 'neutral', label: 'Neutral', color: 'text-gray-600' },
    { id: 'negative', label: 'Negative', color: 'text-red-600' },
  ]

  const toggleSection = (section: string) => {
    setExpandedSections(prev => {
      const newSet = new Set(prev)
      if (newSet.has(section)) {
        newSet.delete(section)
      } else {
        newSet.add(section)
      }
      return newSet
    })
  }

  const handlePlatformToggle = (platformId: string) => {
    const newPlatforms = state.filters.platforms.includes(platformId)
      ? state.filters.platforms.filter(p => p !== platformId)
      : [...state.filters.platforms, platformId]

    setFilters({ platforms: newPlatforms })
  }

  const handleIndustryToggle = (industryId: string) => {
    const newIndustries = state.filters.industries.includes(industryId)
      ? state.filters.industries.filter(i => i !== industryId)
      : [...state.filters.industries, industryId]

    setFilters({ industries: newIndustries })
  }

  const handleSentimentToggle = (sentimentId: string) => {
    const newSentiment = state.filters.sentiment.includes(sentimentId)
      ? state.filters.sentiment.filter(s => s !== sentimentId)
      : [...state.filters.sentiment, sentimentId]

    setFilters({ sentiment: newSentiment })
  }

  const FilterSection = ({
    title,
    sectionId,
    icon,
    children
  }: {
    title: string
    sectionId: string
    icon: React.ReactNode
    children: React.ReactNode
  }) => (
    <div className="border-b border-border pb-4 mb-4">
      <button
        onClick={() => toggleSection(sectionId)}
        className="flex items-center justify-between w-full text-left"
      >
        <div className="flex items-center gap-2">
          {icon}
          <span className="font-medium">{title}</span>
        </div>
        <ChevronDown
          className={`h-4 w-4 transition-transform ${
            expandedSections.has(sectionId) ? 'rotate-180' : ''
          }`}
        />
      </button>

      {expandedSections.has(sectionId) && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: 'auto' }}
          exit={{ opacity: 0, height: 0 }}
          className="mt-3"
        >
          {children}
        </motion.div>
      )}
    </div>
  )

  return (
    <div className="h-full flex flex-col">
      {}
      <div className="flex items-center justify-between p-4 border-b border-border">
        <div className="flex items-center gap-2">
          <Filter className="h-5 w-5" />
          <h3 className="font-semibold">Filters</h3>
        </div>
        <button
          onClick={onClose}
          className="p-2 hover:bg-muted rounded-lg transition-colors"
        >
          <X className="h-4 w-4" />
        </button>
      </div>

      {}
      <div className="flex-1 overflow-y-auto p-4">
        {}
        <FilterSection
          title="Time Range"
          sectionId="time-range"
          icon={<Calendar className="h-4 w-4" />}
        >
          <div className="space-y-2">
            {timeRanges.map((range) => (
              <label key={range.id} className="flex items-center gap-3 cursor-pointer">
                <input
                  type="radio"
                  name="timeRange"
                  value={range.value}
                  checked={state.filters.timeRange === range.value}
                  onChange={(e) => setFilters({ timeRange: e.target.value })}
                  className="w-4 h-4 text-primary"
                />
                <span className="text-sm">{range.label}</span>
              </label>
            ))}
          </div>
        </FilterSection>

        {}
        <FilterSection
          title="Platforms"
          sectionId="platforms"
          icon={<Smartphone className="h-4 w-4" />}
        >
          <div className="space-y-2">
            {platforms.map((platform) => (
              <label key={platform.id} className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={state.filters.platforms.includes(platform.id)}
                  onChange={() => handlePlatformToggle(platform.id)}
                  className="w-4 h-4 text-primary rounded"
                />
                <span className="text-lg">{platform.icon}</span>
                <span className="text-sm">{platform.label}</span>
              </label>
            ))}
          </div>
        </FilterSection>

        {}
        <FilterSection
          title="Industries"
          sectionId="industries"
          icon={<Hash className="h-4 w-4" />}
        >
          <div className="space-y-2">
            {industries.map((industry) => (
              <label key={industry.id} className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={state.filters.industries.includes(industry.id)}
                  onChange={() => handleIndustryToggle(industry.id)}
                  className="w-4 h-4 text-primary rounded"
                />
                <span className="text-sm">{industry.label}</span>
              </label>
            ))}
          </div>
        </FilterSection>

        {}
        <FilterSection
          title="Sentiment"
          sectionId="sentiment"
          icon={<Check className="h-4 w-4" />}
        >
          <div className="space-y-2">
            {sentimentOptions.map((sentiment) => (
              <label key={sentiment.id} className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={state.filters.sentiment.includes(sentiment.id)}
                  onChange={() => handleSentimentToggle(sentiment.id)}
                  className="w-4 h-4 text-primary rounded"
                />
                <span className={`text-sm ${sentiment.color}`}>{sentiment.label}</span>
              </label>
            ))}
          </div>
        </FilterSection>

        {}
        <FilterSection
          title="Volume Range"
          sectionId="volume"
          icon={<Hash className="h-4 w-4" />}
        >
          <div className="space-y-3">
            <div>
              <label className="block text-sm font-medium mb-2">Minimum Volume</label>
              <input
                type="number"
                value={state.filters.minVolume}
                onChange={(e) => setFilters({ minVolume: parseInt(e.target.value) || 0 })}
                className="w-full px-3 py-2 border border-border rounded-md focus:ring-2 focus:ring-primary focus:border-transparent"
                placeholder="100"
              />
            </div>

            <div>
              <label className="block text-sm font-medium mb-2">Minimum Confidence</label>
              <input
                type="number"
                min="0"
                max="1"
                step="0.1"
                value={state.filters.minConfidence}
                onChange={(e) => setFilters({ minConfidence: parseFloat(e.target.value) || 0 })}
                className="w-full px-3 py-2 border border-border rounded-md focus:ring-2 focus:ring-primary focus:border-transparent"
                placeholder="0.7"
              />
            </div>
          </div>
        </FilterSection>
      </div>

      {}
      <div className="p-4 border-t border-border">
        <div className="flex gap-2">
          <button
            onClick={resetFilters}
            className="flex-1 flex items-center justify-center gap-2 px-4 py-2 border border-border rounded-lg hover:bg-muted transition-colors"
          >
            <RotateCcw className="h-4 w-4" />
            Reset
          </button>
          <button
            onClick={onClose}
            className="flex-1 px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors"
          >
            Apply Filters
          </button>
        </div>
      </div>
    </div>
  )
}
