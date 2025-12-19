import type { NextPage } from 'next'
import { useState, useEffect } from 'react'
import { useTranslation } from 'next-i18next'
import { serverSideTranslations } from 'next-i18next/serverSideTranslations'
import { motion } from 'framer-motion'
import Link from 'next/link'
import { useRouter } from 'next/router'
import { Mail } from 'lucide-react'
import { useLogin } from '@/hooks/useLogin'
import { useSendOtp } from '@/hooks/useOtp'
import { useAuth } from '@/contexts/AuthContext'

const Login: NextPage = () => {
  const { t } = useTranslation('common')
  const router = useRouter()
  const { login, isLoading: isLoggingIn, error: loginError } = useLogin()
  const { sendOtp, isLoading: isSendingOtp, error: otpError } = useSendOtp()
  const { isAuthenticated, checkAuth, setUser } = useAuth()

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [remember, setRemember] = useState(false)
  const [deviceInfo, setDeviceInfo] = useState({
    device_name: '',
    user_agent: '',
    ip_address: '0.0.0.0'
  })

  // Check if user is already logged in - fast redirect without render
  useEffect(() => {
    if (isAuthenticated) {
      router.replace('/projects')
    }
  }, [isAuthenticated, router])

  // Get device info on mount (removed slow IP API call)
  useEffect(() => {
    const getUserAgent = () => window.navigator.userAgent
    const getDeviceName = () => {
      const ua = window.navigator.userAgent
      if (/iPhone/.test(ua)) return 'iPhone'
      if (/iPad/.test(ua)) return 'iPad'
      if (/Android/.test(ua)) return 'Android'
      if (/Windows/.test(ua)) return 'Windows PC'
      if (/Mac/.test(ua)) return 'Mac'
      if (/Linux/.test(ua)) return 'Linux'
      return 'Unknown Device'
    }

    setDeviceInfo({
      device_name: getDeviceName(),
      user_agent: getUserAgent(),
      ip_address: '0.0.0.0'
    })
  }, [])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    try {
      // Attempt login
      const result = await login({
        email,
        password,
        remember,
        ...deviceInfo
      })

      // Check if user needs OTP verification
      if (result.needsOtp) {
        // User not verified, send OTP
        await sendOtp(email, password)

        // Store email and password in sessionStorage for OTP page
        sessionStorage.setItem('otp_email', email)
        sessionStorage.setItem('otp_password', password)

        // Redirect to OTP verification page
        router.push(`/verify-otp?email=${encodeURIComponent(email)}`)
      } else if (result.isVerified) {
        // Login successful, update auth context
        if (result.user) {
          setUser(result.user)
        } else {
          // Fallback: fetch user data from /me endpoint
          await checkAuth()
        }
        // Redirect to projects page
        router.push('/projects')
      }
    } catch (err) {
      // Error handling is done by hooks
      console.error('Login error:', err)
    }
  }

  const error = loginError || otpError
  const isLoading = isLoggingIn || isSendingOtp

  // Don't render login form if already authenticated
  if (isAuthenticated) {
    return null
  }

  return (
    <div className="min-h-screen relative bg-amber-50 dark:bg-gray-950 overflow-hidden">
      {/* Background Effects */}
      <div className="fixed inset-0 pointer-events-none">
        {/* Sun Mode - Warm Glows */}
        <div className="absolute top-0 right-1/4 w-[600px] h-[600px] bg-yellow-100/60 rounded-full blur-[128px] dark:hidden" />
        <div className="absolute bottom-1/4 left-1/3 w-[500px] h-[500px] bg-amber-100/50 rounded-full blur-[128px] dark:hidden" />

        {/* Dark Mode - Night Sky Stars */}
        <div
          className="hidden dark:block absolute inset-0"
          style={{
            backgroundImage: `
              radial-gradient(2px 2px at 20% 30%, white, transparent),
              radial-gradient(2px 2px at 60% 70%, white, transparent),
              radial-gradient(1px 1px at 50% 50%, white, transparent),
              radial-gradient(1px 1px at 80% 10%, white, transparent),
              radial-gradient(2px 2px at 90% 60%, white, transparent),
              radial-gradient(1px 1px at 33% 80%, white, transparent),
              radial-gradient(1px 1px at 15% 60%, white, transparent)
            `,
            backgroundSize: '200px 200px, 250px 250px, 150px 150px, 180px 180px, 220px 220px, 300px 300px, 280px 280px',
            backgroundPosition: '0 0, 40px 60px, 130px 270px, 70px 100px, 150px 50px, 250px 150px, 100px 200px',
            opacity: 0.4
          }}
        />
        <div className="hidden dark:block absolute top-0 left-1/4 w-96 h-96 bg-white/5 rounded-full blur-[128px]" />
        <div className="hidden dark:block absolute bottom-1/3 right-1/4 w-[500px] h-[500px] bg-white/5 rounded-full blur-[128px]" />
      </div>

      <div className="relative z-10 min-h-screen flex flex-col items-center justify-center px-4 py-12">
        {/* Logo */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="flex items-center gap-3 mb-16"
        >
          <div className="w-12 h-12 rounded-lg bg-yellow-400 shadow-lg dark:bg-white" />
          <h1 className="text-2xl font-black text-gray-900 dark:text-white">
            SMAP SOLUTION
          </h1>
        </motion.div>

        {/* Form Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="w-full max-w-md bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl p-8 shadow-xl"
        >
          <h2 className="text-3xl font-black text-center mb-2 text-gray-900 dark:text-white">{t('login.welcome')}</h2>
          <p className="text-gray-600 dark:text-gray-400 text-center mb-8">
            {t('login.subtitle')}
          </p>

          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Error Message */}
            {error && (
              <div className="p-4 bg-red-100 dark:bg-red-900/40 border border-red-300 dark:border-red-700 rounded-lg">
                <p className="text-sm text-red-800 dark:text-red-200 text-center">{error}</p>
              </div>
            )}

            {/* Email */}
            <div>
              <label className="block text-sm font-semibold mb-2 text-gray-900 dark:text-white">
                {t('login.email')}
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-3 border border-amber-300/60 dark:border-white/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-gray-900 dark:focus:ring-white bg-white/80 dark:bg-gray-900/80 text-gray-900 dark:text-white"
                placeholder={t('login.emailPlaceholder')}
                required
                disabled={isLoading}
              />
            </div>

            {/* Password */}
            <div>
              <label className="block text-sm font-semibold mb-2 text-gray-900 dark:text-white">
                {t('login.password')}
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3 border border-amber-300/60 dark:border-white/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-gray-900 dark:focus:ring-white bg-white/80 dark:bg-gray-900/80 text-gray-900 dark:text-white"
                placeholder={t('login.passwordPlaceholder')}
                required
                minLength={8}
                disabled={isLoading}
              />
            </div>

            {/* Remember Me */}
            <div className="flex items-center">
              <input
                type="checkbox"
                id="remember"
                checked={remember}
                onChange={(e) => setRemember(e.target.checked)}
                className="w-4 h-4 rounded border-amber-300/60 dark:border-white/20 text-gray-900 dark:text-white focus:ring-2 focus:ring-gray-900 dark:focus:ring-white"
                disabled={isLoading}
              />
              <label htmlFor="remember" className="ml-2 text-sm font-semibold text-gray-900 dark:text-white">
                {t('login.rememberMe')}
              </label>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={isLoading}
              className="w-full flex items-center justify-center gap-2 px-6 py-4 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg font-semibold text-lg hover:bg-gray-800 dark:hover:bg-gray-100 transition-all duration-200 shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <>
                  <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                  {isSendingOtp ? t('login.sendingOtp') : t('login.loggingIn')}
                </>
              ) : (
                t('login.submit')
              )}
            </button>
          </form>

          {/* Divider */}
          <div className="flex items-center gap-4 my-6">
            <div className="flex-1 h-px bg-gray-300 dark:bg-gray-700" />
          </div>

          {/* Social Login */}
          <div className="flex gap-3">
            <button className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-white/80 dark:bg-gray-800/80 border border-amber-300/60 dark:border-white/20 rounded-lg font-semibold hover:bg-white dark:hover:bg-gray-800 transition-all duration-200 shadow-lg">
              <svg className="w-5 h-5" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              <span className="text-sm text-gray-900 dark:text-white">{t('login.loginWithGoogle')}</span>
            </button>
            <button className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-white/80 dark:bg-gray-800/80 border border-amber-300/60 dark:border-white/20 rounded-lg font-semibold hover:bg-white dark:hover:bg-gray-800 transition-all duration-200 shadow-lg">
              <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              <span className="text-sm text-gray-900 dark:text-white">{t('login.loginWithApple')}</span>
            </button>
          </div>

          {/* Register Link */}
          <p className="text-center mt-6 text-sm">
            {t('login.noAccount')}{' '}
            <Link
              href="/register"
              className="font-semibold text-gray-900 dark:text-white hover:underline underline-offset-2"
            >
              {t('login.register')}
            </Link>
          </p>
        </motion.div>

        {/* Features Grid */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="mt-12 w-full max-w-4xl"
        >
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Feature 1 */}
            <div className="p-6 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl shadow-lg">
              <div className="w-12 h-12 bg-gray-900 dark:bg-white rounded-xl shadow-lg flex items-center justify-center mb-4">
                <svg className="w-6 h-6 text-white dark:text-gray-900" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              </div>
              <h3 className="text-lg font-black mb-2 text-gray-900 dark:text-white">{t('login.features.feature1.title')}</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                {t('login.features.feature1.description')}
              </p>
            </div>

            {/* Feature 2 */}
            <div className="p-6 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl shadow-lg">
              <div className="w-12 h-12 bg-gray-900 dark:bg-white rounded-xl shadow-lg flex items-center justify-center mb-4">
                <svg className="w-6 h-6 text-white dark:text-gray-900" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              </div>
              <h3 className="text-lg font-black mb-2 text-gray-900 dark:text-white">{t('login.features.feature2.title')}</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                {t('login.features.feature2.description')}
              </p>
            </div>

            {/* Feature 3 */}
            <div className="p-6 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl shadow-lg">
              <div className="w-12 h-12 bg-gray-900 dark:bg-white rounded-xl shadow-lg flex items-center justify-center mb-4">
                <svg className="w-6 h-6 text-white dark:text-gray-900" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
              <h3 className="text-lg font-black mb-2 text-gray-900 dark:text-white">{t('login.features.feature3.title')}</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                {t('login.features.feature3.description')}
              </p>
            </div>
          </div>
        </motion.div>

        {/* Trust Badges */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="mt-12 text-center"
        >
          <div className="flex items-center justify-center gap-1 mb-4">
            <span className="text-sm font-semibold text-gray-600">{t('login.trustedBy')}</span>
            <div className="flex gap-0.5">
              {[1, 2, 3, 4, 5].map((star) => (
                <svg key={star} className="w-4 h-4 text-yellow-400 fill-current" viewBox="0 0 20 20">
                  <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                </svg>
              ))}
            </div>
          </div>
          <div className="flex items-center justify-center gap-8 opacity-50">
            <span className="text-sm font-bold text-gray-500">VNEXPRESS</span>
            <span className="text-sm font-bold text-gray-500">CAFEBIZ</span>
            <span className="text-sm font-bold text-gray-500">TECHCOMBANK</span>
          </div>
        </motion.div>

        {/* Footer */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="mt-8 text-center max-w-2xl"
        >
          <h3 className="font-bold text-gray-700 dark:text-gray-300 mb-1">
            SMAP Solution: {t('login.tagline')}
          </h3>
          <p className="text-sm text-gray-500">
            {t('login.footerDescription')}
          </p>
        </motion.div>

        {/* Back to Home */}
        <Link
          href="/"
          className="mt-6 text-sm font-semibold text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
        >
          ← {t('login.backToHome')}
        </Link>
      </div>
    </div>
  )
}

export async function getStaticProps({ locale }: { locale: string }) {
  return {
    props: {
      ...(await serverSideTranslations(locale, ['common'])),
    },
  }
}

export default Login
