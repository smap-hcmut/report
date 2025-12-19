import React from 'react'
import { useTranslation } from 'next-i18next'
import { KeywordCount } from '@/lib/types/dryrun'

interface PreviewKeywordTabsProps {
  keywords: string[]
  selectedKeyword: string
  onSelectKeyword: (keyword: string) => void
  keywordCounts: KeywordCount[]
}

export default function PreviewKeywordTabs({
  keywords,
  selectedKeyword,
  onSelectKeyword,
  keywordCounts
}: PreviewKeywordTabsProps) {
  const { t } = useTranslation('common')

  const getCount = (keyword: string) => {
    if (keyword === 'all') {
      return keywordCounts.reduce((sum, k) => sum + k.count, 0)
    }
    return keywordCounts.find(k => k.keyword === keyword)?.count || 0
  }

  return (
    <div className="flex flex-wrap gap-2">
      {keywords.map(keyword => {
        const isActive = selectedKeyword === keyword
        const count = getCount(keyword)

        return (
          <button
            key={keyword}
            onClick={() => onSelectKeyword(keyword)}
            className={`relative px-4 py-2 rounded-lg font-semibold transition-all ${
              isActive
                ? 'bg-gray-900 dark:bg-white text-white dark:text-gray-900 shadow-brutal'
                : 'bg-white/60 dark:bg-gray-900/60 border border-amber-300/60 dark:border-white/20 text-gray-700 dark:text-gray-300 hover:bg-white dark:hover:bg-gray-800'
            }`}
          >
            <span>{keyword === 'all' ? t('preview.allKeywords') : keyword}</span>
            <span
              className={`ml-2 text-xs px-2 py-0.5 rounded-full ${
                isActive
                  ? 'bg-white/20 dark:bg-gray-900/20'
                  : 'bg-gray-200 dark:bg-gray-700'
              }`}
            >
              {count}
            </span>
          </button>
        )
      })}
    </div>
  )
}
