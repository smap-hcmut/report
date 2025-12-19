import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import { useTranslation } from 'next-i18next'
import { useTheme } from 'next-themes'
import { motion, AnimatePresence } from 'framer-motion'
import {
  Moon, Sun, Globe, User, LogOut, Settings,
  Download, Share2, RefreshCw, Bell
} from 'lucide-react'
import { cn } from '@/lib/utils'
import Link from 'next/link'
import { useAuth } from '@/contexts/AuthContext'
import { useDashboard } from '@/contexts/DashboardContext'
import ProjectSelector from './dashboard/ProjectSelector'
import TimeRangeSelector from './dashboard/TimeRangeSelector'
import RealTimeIndicator from './dashboard/RealTimeIndicator'

export default function Navbar() {
  const router = useRouter()
  const { t, i18n } = useTranslation('common')
  const { theme, setTheme } = useTheme()
  const [langOpen, setLangOpen] = useState(false)
  const [userMenuOpen, setUserMenuOpen] = useState(false)
  const [isRefreshing, setIsRefreshing] = useState(false)
  const { user, isAuthenticated, logout: authLogout } = useAuth()
  const { state, setTimeRange } = useDashboard()

  // Check if we're in a project context
  const { project_id } = router.query
  const isInProject = !!project_id || router.pathname.includes('/projects/[project_id]')

  // Close dropdowns when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as HTMLElement
      if (!target.closest('[data-dropdown]')) {
        setLangOpen(false)
        setUserMenuOpen(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const changeLanguage = (lang: string) => {
    i18n.changeLanguage(lang)
    router.push(router.pathname, router.asPath, { locale: lang })
    setLangOpen(false)
  }

  const handleLogout = async () => {
    await authLogout()
    setUserMenuOpen(false)
    router.push('/login')
  }

  const handleRefresh = async () => {
    setIsRefreshing(true)
    await new Promise(resolve => setTimeout(resolve, 1000))
    setIsRefreshing(false)
  }

  const handleExport = () => {
    console.log('Exporting dashboard...')
  }

  const handleShare = () => {
    console.log('Sharing dashboard...')
  }

  return (
    <nav className="sticky top-0 z-50 w-full border-b border-amber-300/60 dark:border-white/20 bg-white/95 dark:bg-gray-900/95 backdrop-blur supports-[backdrop-filter]:bg-white/60 dark:supports-[backdrop-filter]:bg-gray-900/60">
      <div className="flex h-16 items-center justify-between px-4 lg:px-6">
        {/* Left section - Logo + Project Tools (when in project) */}
        <div className="flex items-center gap-4 lg:gap-6">
          {/* Logo */}
          <Link href="/" className="flex items-center flex-shrink-0">
            <h1 className="text-lg lg:text-xl font-black bg-gradient-to-r from-blue-600 to-violet-600 bg-clip-text text-transparent">
              {t('navbar.brand')}
            </h1>
          </Link>

          {/* Project Context Tools - Show when in project */}
          {isInProject && (
            <>
              {/* Project Selector */}
              <div className="hidden md:block">
                <ProjectSelector />
              </div>

              {/* Time Range Selector */}
              <div className="hidden lg:block">
                <TimeRangeSelector
                  selectedRange={state.timeRange}
                  onRangeChange={setTimeRange}
                />
              </div>

              {/* Real-Time Indicator */}
              <div className="hidden xl:block">
                <RealTimeIndicator />
              </div>
            </>
          )}
        </div>

        {/* Right section - Actions + Settings */}
        <div className="flex items-center gap-1 lg:gap-2">
          {/* Project Action Buttons - Show when in project */}
          {isInProject && (
            <div className="hidden md:flex items-center gap-1 mr-2 lg:mr-4">
              {/* Refresh */}
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={handleRefresh}
                disabled={isRefreshing}
                className="p-2 rounded-lg transition-colors hover:bg-yellow-100 dark:hover:bg-gray-800 disabled:opacity-50"
                aria-label="Refresh"
              >
                <RefreshCw
                  className={cn('h-4 w-4', isRefreshing && 'animate-spin')}
                />
              </motion.button>

              {/* Export */}
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={handleExport}
                className="p-2 rounded-lg transition-colors hover:bg-yellow-100 dark:hover:bg-gray-800"
                aria-label="Export"
              >
                <Download className="h-4 w-4" />
              </motion.button>

              {/* Share */}
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={handleShare}
                className="p-2 rounded-lg transition-colors hover:bg-yellow-100 dark:hover:bg-gray-800"
                aria-label="Share"
              >
                <Share2 className="h-4 w-4" />
              </motion.button>

              {/* Notifications */}
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="p-2 rounded-lg transition-colors hover:bg-yellow-100 dark:hover:bg-gray-800 relative"
                aria-label="Notifications"
              >
                <Bell className="h-4 w-4" />
                <span className="absolute -top-1 -right-1 h-3 w-3 bg-red-500 rounded-full text-[10px] flex items-center justify-center text-white font-bold">
                  3
                </span>
              </motion.button>
            </div>
          )}

          {/* Theme Toggle */}
          <button
            onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
            className="inline-flex items-center justify-center rounded-lg p-2 text-sm font-medium transition-colors hover:bg-yellow-100 dark:hover:bg-gray-800"
            aria-label="Toggle theme"
          >
            <Sun className="h-5 w-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
            <Moon className="absolute h-5 w-5 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
          </button>

          {/* Language Selector */}
          <div className="relative" data-dropdown>
            <button
              onClick={() => setLangOpen(!langOpen)}
              className="inline-flex items-center gap-1 lg:gap-2 rounded-lg px-2 lg:px-3 py-2 text-sm font-medium transition-colors hover:bg-yellow-100 dark:hover:bg-gray-800"
              aria-label="Change language"
            >
              <Globe className="h-4 w-4" />
              <span className="hidden sm:inline-block font-bold">{i18n.language.toUpperCase()}</span>
            </button>

            <AnimatePresence>
              {langOpen && (
                <motion.div
                  initial={{ opacity: 0, y: -10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  className="absolute right-0 mt-2 w-32 rounded-lg border-2 border-gray-900 dark:border-white bg-white dark:bg-gray-900 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] p-1"
                >
                  <button
                    onClick={() => changeLanguage('en')}
                    className={cn(
                      'w-full rounded-md px-3 py-2 text-left text-sm font-semibold transition-colors hover:bg-yellow-100 dark:hover:bg-gray-800',
                      i18n.language === 'en' && 'bg-yellow-200 dark:bg-gray-700'
                    )}
                  >
                    {t('language.en')}
                  </button>
                  <button
                    onClick={() => changeLanguage('vi')}
                    className={cn(
                      'w-full rounded-md px-3 py-2 text-left text-sm font-semibold transition-colors hover:bg-yellow-100 dark:hover:bg-gray-800',
                      i18n.language === 'vi' && 'bg-yellow-200 dark:bg-gray-700'
                    )}
                  >
                    {t('language.vi')}
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* User Menu */}
          {isAuthenticated ? (
            <div className="relative" data-dropdown>
              <button
                onClick={() => setUserMenuOpen(!userMenuOpen)}
                className="inline-flex items-center justify-center rounded-full p-1.5 transition-colors hover:bg-yellow-100 dark:hover:bg-gray-800"
                aria-label="User menu"
              >
                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-blue-600 to-violet-600 border-2 border-gray-900 dark:border-white">
                  <User className="h-4 w-4 text-white" />
                </div>
              </button>

              <AnimatePresence>
                {userMenuOpen && (
                  <motion.div
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -10 }}
                    className="absolute right-0 mt-2 w-56 rounded-lg border-2 border-gray-900 dark:border-white bg-white dark:bg-gray-900 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] dark:shadow-[4px_4px_0px_0px_rgba(255,255,255,1)] p-2"
                  >
                    {user && (
                      <div className="px-3 py-2 mb-2 border-b-2 border-gray-900 dark:border-white">
                        <p className="text-sm font-bold text-gray-900 dark:text-white truncate">{user.name || user.email}</p>
                        <p className="text-xs text-gray-600 dark:text-gray-400 truncate">{user.email}</p>
                      </div>
                    )}
                    <Link
                      href="/settings"
                      className="flex items-center gap-2 w-full rounded-md px-3 py-2 text-left text-sm font-semibold transition-colors hover:bg-yellow-100 dark:hover:bg-gray-800"
                      onClick={() => setUserMenuOpen(false)}
                    >
                      <Settings className="h-4 w-4" />
                      {t('navbar.settings')}
                    </Link>
                    <button
                      onClick={handleLogout}
                      className="flex items-center gap-2 w-full rounded-md px-3 py-2 text-left text-sm font-bold transition-colors hover:bg-red-100 dark:hover:bg-red-900/20 text-red-600 dark:text-red-400"
                    >
                      <LogOut className="h-4 w-4" />
                      {t('navbar.logout')}
                    </button>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <Link
                href="/login"
                className="inline-flex items-center justify-center rounded-lg px-3 lg:px-4 py-2 text-sm font-semibold transition-colors hover:bg-yellow-100 dark:hover:bg-gray-800"
              >
                {t('navbar.login')}
              </Link>
              <Link
                href="/register"
                className="inline-flex items-center justify-center rounded-lg bg-gray-900 dark:bg-white px-3 lg:px-4 py-2 text-sm font-bold text-white dark:text-gray-900 transition-colors hover:bg-gray-800 dark:hover:bg-gray-100 border-2 border-gray-900 dark:border-white"
              >
                {t('navbar.register')}
              </Link>
            </div>
          )}
        </div>
      </div>
    </nav>
  )
}
