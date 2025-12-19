import type { NextPage } from 'next'
import { useState, useEffect, useRef } from 'react'
import { useTranslation } from 'next-i18next'
import { serverSideTranslations } from 'next-i18next/serverSideTranslations'
import { motion } from 'framer-motion'
import Link from 'next/link'
import { useRouter } from 'next/router'
import { Shield, Mail, ArrowLeft } from 'lucide-react'
import { useSendOtp, useVerifyOtp } from '@/hooks/useOtp'

const VerifyOTP: NextPage = () => {
  const { t } = useTranslation('common')
  const router = useRouter()
  const { email: emailFromQuery } = router.query

  const { sendOtp, isLoading: isResending, error: resendError } = useSendOtp()
  const { verifyOtp, isLoading: isVerifying, error: verifyError } = useVerifyOtp()

  const [otp, setOtp] = useState(['', '', '', '', '', ''])
  const [countdown, setCountdown] = useState(60)
  const [canResend, setCanResend] = useState(false)
  const [email, setEmail] = useState<string>('')
  const [password, setPassword] = useState<string>('')

  const inputRefs = useRef<(HTMLInputElement | null)[]>([])

  // Get email and password from sessionStorage on mount
  useEffect(() => {
    const storedEmail = sessionStorage.getItem('otp_email')
    const storedPassword = sessionStorage.getItem('otp_password')

    if (storedEmail) setEmail(storedEmail)
    if (storedPassword) setPassword(storedPassword)

    // If no email in sessionStorage, use from query
    if (!storedEmail && emailFromQuery) {
      setEmail(emailFromQuery as string)
    }

    // Redirect if no email available
    if (!storedEmail && !emailFromQuery) {
      router.push('/login')
    }
  }, [emailFromQuery, router])

  // Countdown timer
  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000)
      return () => clearTimeout(timer)
    } else {
      setCanResend(true)
    }
  }, [countdown])

  const handleChange = (index: number, value: string) => {
    if (value.length > 1) {
      value = value[0]
    }

    if (!/^\d*$/.test(value)) {
      return
    }

    const newOtp = [...otp]
    newOtp[index] = value
    setOtp(newOtp)

    // Auto focus next input
    if (value && index < 5) {
      inputRefs.current[index + 1]?.focus()
    }
  }

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus()
    }
  }

  const handlePaste = (e: React.ClipboardEvent) => {
    e.preventDefault()
    const pastedData = e.clipboardData.getData('text').trim()

    if (!/^\d{6}$/.test(pastedData)) {
      return
    }

    const newOtp = pastedData.split('')
    setOtp(newOtp)
    inputRefs.current[5]?.focus()
  }

  const handleResend = async () => {
    if (!canResend || !email || !password) return

    setCanResend(false)
    setCountdown(60)

    try {
      await sendOtp(email, password)
    } catch (err) {
      // Error handled by hook
      console.error('Resend OTP error:', err)
      // Allow resend again if failed
      setCanResend(true)
      setCountdown(0)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    const otpCode = otp.join('')
    if (otpCode.length !== 6) {
      return
    }

    if (!email) {
      return
    }

    try {
      await verifyOtp(email, otpCode)

      // Clear sessionStorage on success
      sessionStorage.removeItem('otp_email')
      sessionStorage.removeItem('otp_password')

      // Redirect to projects page
      router.push('/projects')
    } catch (err) {
      // Error handled by hook
      console.error('Verify OTP error:', err)
    }
  }

  const error = resendError || verifyError

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

        {/* OTP Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="w-full max-w-md bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl p-8 shadow-xl"
        >
          {/* Icon */}
          <div className="flex justify-center mb-6">
            <div className="inline-flex items-center justify-center w-20 h-20 bg-gray-900 dark:bg-white rounded-2xl shadow-lg">
              <Shield className="w-10 h-10 text-white dark:text-gray-900" strokeWidth={2.5} />
            </div>
          </div>

          <h2 className="text-3xl font-black text-center mb-2 text-gray-900 dark:text-white">
            {t('verifyOtp.title')}
          </h2>
          <p className="text-gray-600 dark:text-gray-400 text-center mb-2">
            {t('verifyOtp.subtitle')}
          </p>

          {/* Email Display */}
          <div className="flex items-center justify-center gap-2 mb-8">
            <Mail className="w-4 h-4 text-gray-600 dark:text-gray-400" />
            <span className="text-sm font-semibold text-gray-900 dark:text-white">
              {email || 'your-email@example.com'}
            </span>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Error Message */}
            {error && (
              <div className="p-4 bg-red-100 dark:bg-red-900/40 border border-red-300 dark:border-red-700 rounded-lg">
                <p className="text-sm text-red-800 dark:text-red-200 text-center">{error}</p>
              </div>
            )}

            {/* OTP Input */}
            <div>
              <label className="block text-sm font-semibold mb-4 text-center text-gray-900 dark:text-white">
                {t('verifyOtp.enterCode')}
              </label>
              <div className="flex gap-3 justify-center">
                {otp.map((digit, index) => (
                  <input
                    key={index}
                    ref={(el) => {
                      inputRefs.current[index] = el
                    }}
                    type="text"
                    inputMode="numeric"
                    maxLength={1}
                    value={digit}
                    onChange={(e) => handleChange(index, e.target.value)}
                    onKeyDown={(e) => handleKeyDown(index, e)}
                    onPaste={handlePaste}
                    className="w-12 h-14 text-center text-2xl font-black border-2 border-amber-300/60 dark:border-white/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-gray-900 dark:focus:ring-white focus:border-transparent bg-white/80 dark:bg-gray-900/80 text-gray-900 dark:text-white transition-all"
                    disabled={isVerifying}
                  />
                ))}
              </div>
            </div>

            {/* Resend Code */}
            <div className="text-center">
              {canResend ? (
                <button
                  type="button"
                  onClick={handleResend}
                  disabled={isResending}
                  className="text-sm font-semibold text-gray-900 dark:text-white hover:underline underline-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isResending ? t('verifyOtp.resending') : t('verifyOtp.resendCode')}
                </button>
              ) : (
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  {t('verifyOtp.resendIn')} <span className="font-semibold text-gray-900 dark:text-white">{countdown}s</span>
                </p>
              )}
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={isVerifying || otp.join('').length !== 6}
              className="w-full flex items-center justify-center gap-2 px-6 py-4 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg font-semibold text-lg hover:bg-gray-800 dark:hover:bg-gray-100 transition-all duration-200 shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isVerifying ? (
                <>
                  <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                  {t('verifyOtp.verifying')}
                </>
              ) : (
                t('verifyOtp.verify')
              )}
            </button>
          </form>

          {/* Back Link */}
          <div className="mt-6 text-center">
            <Link
              href="/login"
              className="inline-flex items-center gap-2 text-sm font-semibold text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              {t('verifyOtp.backToLogin')}
            </Link>
          </div>
        </motion.div>

        {/* Security Info */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="mt-8 max-w-md"
        >
          <div className="p-6 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl shadow-lg">
            <div className="flex items-start gap-4">
              <div className="inline-flex items-center justify-center w-10 h-10 bg-yellow-400 dark:bg-white rounded-lg shadow-sm flex-shrink-0">
                <Shield className="w-5 h-5 text-gray-900" strokeWidth={2.5} />
              </div>
              <div>
                <h3 className="font-black text-sm mb-1 text-gray-900 dark:text-white">
                  {t('verifyOtp.securityInfo.title')}
                </h3>
                <p className="text-xs text-gray-600 dark:text-gray-400 leading-relaxed">
                  {t('verifyOtp.securityInfo.description')}
                </p>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  )
}

export async function getServerSideProps({ locale }: { locale: string }) {
  return {
    props: {
      ...(await serverSideTranslations(locale, ['common'])),
    },
  }
}

export default VerifyOTP
