import React from 'react'
import { motion } from 'framer-motion'
import { Facebook, Music2, Youtube } from 'lucide-react'

type PlatformType = 'facebook' | 'tiktok' | 'youtube'

interface PlatformTabsProps {
  selectedPlatform: PlatformType
  onSelectPlatform: (platform: PlatformType) => void
  platformCounts: {
    facebook: number
    tiktok: number
    youtube: number
  }
}

const platformConfig = {
  facebook: {
    icon: Facebook,
    label: 'Facebook',
    color: 'bg-blue-600',
    hoverColor: 'hover:bg-blue-700',
    activeColor: 'bg-blue-600',
    textColor: 'text-blue-600',
    borderColor: 'border-blue-600'
  },
  tiktok: {
    icon: Music2,
    label: 'TikTok',
    color: 'bg-black',
    hoverColor: 'hover:bg-gray-800',
    activeColor: 'bg-black',
    textColor: 'text-black',
    borderColor: 'border-black'
  },
  youtube: {
    icon: Youtube,
    label: 'YouTube',
    color: 'bg-red-600',
    hoverColor: 'hover:bg-red-700',
    activeColor: 'bg-red-600',
    textColor: 'text-red-600',
    borderColor: 'border-red-600'
  }
}

export default function PlatformTabs({
  selectedPlatform,
  onSelectPlatform,
  platformCounts
}: PlatformTabsProps) {
  return (
    <div className="flex gap-3 mb-6">
      {(Object.keys(platformConfig) as PlatformType[]).map((platform) => {
        const config = platformConfig[platform]
        const Icon = config.icon
        const isActive = selectedPlatform === platform
        const count = platformCounts[platform]

        return (
          <button
            key={platform}
            onClick={() => onSelectPlatform(platform)}
            className={`relative flex items-center gap-3 px-6 py-4 rounded-xl font-semibold transition-all ${
              isActive
                ? `${config.activeColor} text-white shadow-lg`
                : `bg-white dark:bg-gray-800 ${config.textColor} dark:text-gray-300 border-2 ${config.borderColor} dark:border-gray-600 ${config.hoverColor} hover:text-white`
            }`}
          >
            <Icon className="w-5 h-5" />
            <span>{config.label}</span>
            {count > 0 && (
              <span
                className={`px-2 py-1 rounded-full text-xs font-bold ${
                  isActive
                    ? 'bg-white/20 text-white'
                    : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300'
                }`}
              >
                {count}
              </span>
            )}
            {isActive && (
              <motion.div
                layoutId="platformTab"
                className="absolute inset-0 rounded-xl border-2 border-white/30"
                transition={{ type: 'spring', bounce: 0.2, duration: 0.6 }}
              />
            )}
          </button>
        )
      })}
    </div>
  )
}
