import { useState } from 'react'
import { useRouter } from 'next/router'
import { useTranslation } from 'next-i18next'
import { useTheme } from 'next-themes'
import { motion } from 'framer-motion'
import { Moon, Sun, Globe, Menu, X, User, LogOut, Settings } from 'lucide-react'
import { cn } from '@/lib/utils'
import Link from 'next/link'
import { useAuth } from '@/contexts/AuthContext'

const navItems = [
  { key: 'home', href: '#home' },
  { key: 'features', href: '#features' },
  { key: 'solutions', href: '#solutions' },
  { key: 'feedback', href: '#feedback' },
  { key: 'aboutUs', href: '#about' },
  // { key: 'pricing', href: '#pricing' },
  { key: 'contact', href: '#contact' },
]

export default function LandingHeader() {
  const router = useRouter()
  const { t, i18n } = useTranslation('common')
  const { theme, setTheme } = useTheme()
  const [langOpen, setLangOpen] = useState(false)
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const [userMenuOpen, setUserMenuOpen] = useState(false)
  const { user, isAuthenticated, logout: authLogout } = useAuth()

  const changeLanguage = (lang: string) => {
    i18n.changeLanguage(lang)
    router.push(router.pathname, router.asPath, { locale: lang })
    setLangOpen(false)
  }

  const handleSmoothScroll = (e: React.MouseEvent<HTMLAnchorElement>, href: string) => {
    e.preventDefault()
    const targetId = href.replace('#', '')
    const element = document.getElementById(targetId)
    if (element) {
      element.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }

  const handleLogout = async () => {
    await authLogout()
    setUserMenuOpen(false)
    router.push('/login')
  }

  return (
    <header className="fixed top-0 left-0 right-0 z-50 w-full border-b backdrop-blur-xl bg-white/40 dark:bg-gray-900/30 border-amber-200/50 dark:border-white/10">
      <div className="container mx-auto px-4 lg:px-8">
        <div className="flex h-16 items-center justify-between">
          {/* Logo & Brand */}
          <motion.div
            className="flex items-center gap-3"
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5 }}
          >
            <div className="w-8 h-8 rounded-lg bg-yellow-400 shadow-lg dark:bg-white" />
            <h1 className="text-xl font-black text-gray-900 dark:text-white">
              {t('navbar.brand')}
            </h1>
          </motion.div>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex items-center gap-2">
            {navItems.map((item, index) => (
              <motion.a
                key={item.key}
                href={item.href}
                onClick={(e) => handleSmoothScroll(e, item.href)}
                className="relative px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-colors duration-200 rounded-lg"
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                whileHover={{ y: -2 }}
              >
                {t(`landing.header.${item.key}`)}
              </motion.a>
            ))}
          </nav>

          {/* Actions */}
          <div className="flex items-center gap-2">
            {/* Theme Toggle */}
            <motion.button
              onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
              className="inline-flex items-center justify-center rounded-lg p-2 bg-gray-900 dark:bg-white text-white dark:text-gray-900 hover:bg-gray-800 dark:hover:bg-gray-100 transition-all duration-200 shadow-lg"
              aria-label="Toggle theme"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              <Sun className="h-5 w-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
              <Moon className="absolute h-5 w-5 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
            </motion.button>

            {/* Language Selector */}
            <div className="relative">
              <motion.button
                onClick={() => setLangOpen(!langOpen)}
                className="inline-flex items-center gap-2 rounded-lg px-3 py-2 bg-white/60 dark:bg-white/10 border border-amber-300/60 dark:border-white/20 hover:bg-white/80 dark:hover:bg-white/20 transition-all duration-200 shadow-lg backdrop-blur-sm"
                aria-label="Change language"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <Globe className="h-4 w-4 text-gray-900 dark:text-white" />
                <span className="hidden sm:inline-block text-gray-900 dark:text-white font-semibold text-sm">{i18n.language.toUpperCase()}</span>
              </motion.button>

              {langOpen && (
                <motion.div
                  initial={{ opacity: 0, y: -10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  className="absolute right-0 mt-2 w-32 rounded-lg border border-amber-300/50 dark:border-white/20 bg-white/90 dark:bg-gray-900/90 p-2 shadow-lg backdrop-blur-xl"
                >
                  <button
                    onClick={() => changeLanguage('en')}
                    className={cn(
                      'w-full rounded-md px-2 py-1.5 text-left text-sm font-semibold transition-all',
                      i18n.language === 'en'
                        ? 'bg-gray-900 dark:bg-white text-white dark:text-gray-900'
                        : 'hover:bg-yellow-100/50 dark:hover:bg-white/10'
                    )}
                  >
                    {t('language.en')}
                  </button>
                  <button
                    onClick={() => changeLanguage('vi')}
                    className={cn(
                      'w-full rounded-md px-2 py-1.5 text-left text-sm font-semibold transition-all',
                      i18n.language === 'vi'
                        ? 'bg-gray-900 dark:bg-white text-white dark:text-gray-900'
                        : 'hover:bg-yellow-100/50 dark:hover:bg-white/10'
                    )}
                  >
                    {t('language.vi')}
                  </button>
                </motion.div>
              )}
            </div>

            {/* Desktop CTA Buttons / User Menu */}
            <div className="hidden md:flex items-center gap-2 ml-2">
              {isAuthenticated ? (
                <div className="relative">
                  <motion.button
                    onClick={() => setUserMenuOpen(!userMenuOpen)}
                    className="inline-flex items-center gap-2 justify-center rounded-lg px-3 py-2 bg-white/60 dark:bg-white/10 border border-amber-300/60 dark:border-white/20 hover:bg-white/80 dark:hover:bg-white/20 transition-all duration-200 shadow-lg backdrop-blur-sm"
                    aria-label="User menu"
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                  >
                    <div className="flex h-7 w-7 items-center justify-center rounded-full bg-gradient-to-br from-yellow-400 to-amber-500 dark:from-white dark:to-gray-100">
                      <User className="h-4 w-4 text-gray-900" />
                    </div>
                    {user && (
                      <span className="text-sm font-semibold text-gray-900 dark:text-white max-w-[100px] truncate">
                        {user.name || user.email}
                      </span>
                    )}
                  </motion.button>

                  {userMenuOpen && (
                    <motion.div
                      initial={{ opacity: 0, y: -10 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -10 }}
                      className="absolute right-0 mt-2 w-56 rounded-lg border border-amber-300/50 dark:border-white/20 bg-white/90 dark:bg-gray-900/90 p-2 shadow-lg backdrop-blur-xl"
                    >
                      {user && (
                        <div className="px-2 py-2 mb-2 border-b border-amber-200/50 dark:border-white/10">
                          <p className="text-sm font-semibold text-gray-900 dark:text-white">{user.name || user.email}</p>
                          <p className="text-xs text-gray-600 dark:text-gray-400">{user.email}</p>
                        </div>
                      )}
                      <Link
                        href="/overview"
                        className="flex items-center gap-2 w-full rounded-md px-2 py-2 text-left text-sm font-semibold transition-all hover:bg-yellow-100/50 dark:hover:bg-white/10 text-gray-900 dark:text-white"
                        onClick={() => setUserMenuOpen(false)}
                      >
                        <Settings className="h-4 w-4" />
                        {t('navbar.dashboard')}
                      </Link>
                      <button
                        onClick={handleLogout}
                        className="flex items-center gap-2 w-full rounded-md px-2 py-2 text-left text-sm font-semibold transition-all hover:bg-red-100/50 dark:hover:bg-red-900/20 text-red-600 dark:text-red-400"
                      >
                        <LogOut className="h-4 w-4" />
                        {t('navbar.logout')}
                      </button>
                    </motion.div>
                  )}
                </div>
              ) : (
                <>
                  <motion.a
                    href="/login"
                    className="px-4 py-2 text-sm font-semibold text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-colors"
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                  >
                    {t('landing.header.login')}
                  </motion.a>
                  <motion.a
                    href="/register"
                    className="inline-flex items-center justify-center rounded-lg px-4 py-2 text-sm font-semibold bg-gray-900 dark:bg-white text-white dark:text-gray-900 shadow-lg hover:bg-gray-800 dark:hover:bg-gray-100 transition-all duration-200"
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    {t('landing.header.getStarted')}
                  </motion.a>
                </>
              )}
            </div>

            {/* Mobile Menu Toggle */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="md:hidden inline-flex items-center justify-center rounded-lg p-2 bg-gray-900 dark:bg-white text-white dark:text-gray-900 hover:bg-gray-800 dark:hover:bg-gray-100 transition-all duration-200 shadow-lg"
              aria-label="Toggle mobile menu"
            >
              {mobileMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
            </button>
          </div>
        </div>

        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="md:hidden border-t border-amber-200/50 dark:border-white/10 py-4 bg-white/60 dark:bg-gray-900/60 backdrop-blur-xl"
          >
            <nav className="flex flex-col gap-2">
              {navItems.map((item) => (
                <a
                  key={item.key}
                  href={item.href}
                  className="px-4 py-2 text-sm font-semibold text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white hover:bg-yellow-100/30 dark:hover:bg-white/10 transition-all duration-200 rounded-lg mx-2"
                  onClick={(e) => {
                    handleSmoothScroll(e, item.href)
                    setMobileMenuOpen(false)
                  }}
                >
                  {t(`landing.header.${item.key}`)}
                </a>
              ))}
              <div className="flex flex-col gap-2 mt-2 px-2">
                {isAuthenticated ? (
                  <>
                    {user && (
                      <div className="px-4 py-2 mb-1 bg-white/60 dark:bg-white/10 border border-amber-300/60 dark:border-white/20 rounded-lg">
                        <p className="text-sm font-semibold text-gray-900 dark:text-white">{user.name || user.email}</p>
                        <p className="text-xs text-gray-600 dark:text-gray-400">{user.email}</p>
                      </div>
                    )}
                    <Link
                      href="/overview"
                      className="px-4 py-2 text-sm font-semibold text-center rounded-lg bg-white/60 dark:bg-white/10 border border-amber-300/60 dark:border-white/20 transition-all hover:bg-white/80 dark:hover:bg-white/20 shadow-lg backdrop-blur-sm text-gray-900 dark:text-white"
                      onClick={() => setMobileMenuOpen(false)}
                    >
                      {t('navbar.dashboard')}
                    </Link>
                    <button
                      onClick={() => {
                        handleLogout()
                        setMobileMenuOpen(false)
                      }}
                      className="px-4 py-2 text-sm font-semibold text-center bg-red-600 text-white rounded-lg shadow-lg hover:bg-red-700 transition-all duration-200"
                    >
                      {t('navbar.logout')}
                    </button>
                  </>
                ) : (
                  <>
                    <Link
                      href="/login"
                      className="px-4 py-2 text-sm font-semibold text-center rounded-lg bg-white/60 dark:bg-white/10 border border-amber-300/60 dark:border-white/20 transition-all hover:bg-white/80 dark:hover:bg-white/20 shadow-lg backdrop-blur-sm text-gray-900 dark:text-white"
                      onClick={() => setMobileMenuOpen(false)}
                    >
                      {t('landing.header.login')}
                    </Link>
                    <Link
                      href="/register"
                      className="px-4 py-2 text-sm font-semibold text-center bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg shadow-lg hover:bg-gray-800 dark:hover:bg-gray-100 transition-all duration-200"
                      onClick={() => setMobileMenuOpen(false)}
                    >
                      {t('landing.header.getStarted')}
                    </Link>
                  </>
                )}
              </div>
            </nav>
          </motion.div>
        )}
      </div>
    </header>
  )
}
