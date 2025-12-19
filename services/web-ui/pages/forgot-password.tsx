import type { NextPage } from 'next'
import { useState } from 'react'
import { useTranslation } from 'next-i18next'
import { serverSideTranslations } from 'next-i18next/serverSideTranslations'
import { motion } from 'framer-motion'
import Link from 'next/link'
import { ArrowLeft } from 'lucide-react'

const ForgotPassword: NextPage = () => {
  const { t } = useTranslation('common')
  const [email, setEmail] = useState('')
  const [submitted, setSubmitted] = useState(false)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    console.log({ email })
    setSubmitted(true)
  }

  return (
    <div className="min-h-screen relative bg-white dark:bg-gray-950 overflow-hidden">
      {/* Cross Pattern Background */}
      <div className="absolute inset-0">
        <div
          className="absolute inset-0"
          style={{
            backgroundImage: `radial-gradient(circle, #00000015 1px, transparent 1px)`,
            backgroundSize: '24px 24px',
          }}
        />
      </div>

      <div className="relative z-10 min-h-screen flex flex-col items-center justify-center px-4 py-12">
        {/* Logo */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="flex items-center gap-3 mb-16"
        >
          <div className="w-12 h-12 flex items-center justify-center">
            <svg className="w-12 h-12" viewBox="0 0 24 24" fill="none">
              <path
                d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"
                fill="#E74C3C"
                stroke="#E74C3C"
                strokeWidth="2"
              />
            </svg>
          </div>
          <h1 className="text-2xl font-black" style={{ color: '#E74C3C' }}>
            SMAP SOLUTION
          </h1>
        </motion.div>

        {/* Form Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="w-full max-w-md bg-white dark:bg-gray-900 border-4 border-black rounded-2xl p-8 shadow-brutal"
        >
          {!submitted ? (
            <>
              <h2 className="text-3xl font-black text-center mb-2">{t('forgotPassword.title')}</h2>
              <p className="text-gray-600 dark:text-gray-400 font-medium text-center mb-8">
                {t('forgotPassword.subtitle')}
              </p>

              <form onSubmit={handleSubmit} className="space-y-5">
                {/* Email */}
                <div>
                  <label className="block text-sm font-bold mb-2">
                    {t('forgotPassword.email')}
                  </label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full px-4 py-3 border-3 border-black rounded-lg font-medium focus:outline-none focus:ring-2 focus:ring-neo-navy bg-white dark:bg-gray-800"
                    placeholder={t('forgotPassword.emailPlaceholder')}
                    required
                  />
                </div>

                {/* Submit Button */}
                <button
                  type="submit"
                  className="w-full flex items-center justify-center gap-2 px-6 py-4 bg-neo-navy text-white border-3 border-black rounded-lg font-bold text-lg hover:bg-neo-taupe transition-all duration-200 shadow-brutal hover:translate-x-[2px] hover:translate-y-[2px]"
                >
                  {t('forgotPassword.submit')}
                </button>
              </form>
            </>
          ) : (
            <div className="text-center py-4">
              <div className="w-16 h-16 bg-neo-sage border-3 border-black rounded-full flex items-center justify-center mx-auto mb-6 shadow-brutal">
                <svg className="w-8 h-8 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <h2 className="text-2xl font-black mb-2">{t('forgotPassword.successTitle')}</h2>
              <p className="text-gray-600 dark:text-gray-400 font-medium mb-6">
                {t('forgotPassword.successMessage')}
              </p>
              <p className="text-sm text-gray-500 font-medium">
                {t('forgotPassword.checkSpam')}
              </p>
            </div>
          )}

          {/* Back to Login */}
          <Link
            href="/login"
            className="flex items-center justify-center gap-2 mt-6 text-sm font-bold text-neo-navy hover:underline decoration-2 underline-offset-2"
          >
            <ArrowLeft className="w-4 h-4" />
            {t('forgotPassword.backToLogin')}
          </Link>
        </motion.div>

        {/* Back to Home */}
        <Link
          href="/"
          className="mt-6 text-sm font-bold text-gray-500 hover:text-black transition-colors"
        >
          ← {t('forgotPassword.backToHome')}
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

export default ForgotPassword
