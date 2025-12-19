import { useRouter } from 'next/router'
import Link from 'next/link'
import { useTranslation } from 'next-i18next'
import { LayoutDashboard, TrendingUp, FileText } from 'lucide-react'

interface ProjectTabsProps {
  projectId: string
}

export default function ProjectTabs({ projectId }: ProjectTabsProps) {
  const router = useRouter()
  const { t } = useTranslation('common')

  const tabs = [
    {
      id: 'dashboard',
      label: t('nav.dashboard') || 'Dashboard',
      icon: LayoutDashboard,
      href: `/projects/${projectId}/dashboard`,
    },
    {
      id: 'trend-analysis',
      label: t('nav.trendAnalysis') || 'Trend Analysis',
      icon: TrendingUp,
      href: `/projects/${projectId}/trend-analysis`,
    },
    {
      id: 'report-wizard',
      label: t('nav.reportWizard') || 'Report Wizard',
      icon: FileText,
      href: `/projects/${projectId}/report-wizard`,
    },
  ]

  const currentPath = router.pathname
  const isActive = (tabId: string) => {
    return currentPath.includes(`/${tabId}`)
  }

  return (
    <div className="border-b border-amber-300/60 dark:border-white/20 bg-white/40 dark:bg-gray-900/40 backdrop-blur-sm">
      <div className="px-6">
        <nav className="flex space-x-1 overflow-x-auto scrollbar-hide" aria-label="Tabs">
          {tabs.map((tab) => {
            const Icon = tab.icon
            const active = isActive(tab.id)

            return (
              <Link
                key={tab.id}
                href={tab.href}
                className={`
                  group relative flex items-center gap-2 px-6 py-4 text-sm font-bold whitespace-nowrap
                  transition-all duration-200
                  ${
                    active
                      ? 'text-gray-900 dark:text-white border-b-4 border-gray-900 dark:border-white'
                      : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white border-b-4 border-transparent hover:border-gray-300 dark:hover:border-gray-600'
                  }
                `}
                aria-current={active ? 'page' : undefined}
              >
                <Icon className="w-5 h-5" />
                <span>{tab.label}</span>

                {/* Active tab indicator shadow effect */}
                {active && (
                  <div className="absolute bottom-0 left-0 right-0 h-1 bg-gradient-to-r from-yellow-400 via-amber-400 to-yellow-400 dark:from-white dark:via-gray-100 dark:to-white opacity-50 blur-sm" />
                )}
              </Link>
            )
          })}
        </nav>
      </div>
    </div>
  )
}
