import { useTranslation } from 'next-i18next'
import { motion } from 'framer-motion'
import { TrendingUp, ArrowRight, Sparkles } from 'lucide-react'
import Image from 'next/image'
import { useRouter } from 'next/router'

export default function HeroSection() {
  const { t } = useTranslation('common')
  const router = useRouter()

  return (
    <section id="home" className="relative min-h-screen flex items-center justify-center overflow-hidden pt-20">

      <div className="container mx-auto px-4 lg:px-8 py-20 relative z-10">
        <div className="grid lg:grid-cols-2 gap-12 items-center max-w-7xl mx-auto">
          {/* Left: Content */}
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center lg:text-left space-y-8"
          >
            {/* Badge */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
              className="inline-block"
            >
              <div className="inline-flex items-center gap-2 px-4 py-2 bg-white/50 dark:bg-white/10 border border-amber-300/60 dark:border-white/20 rounded-lg shadow-lg backdrop-blur-sm font-semibold text-sm text-gray-900 dark:text-white">
                <Sparkles className="h-4 w-4" />
                Social Media Analytics Platform
              </div>
            </motion.div>

            {/* Main Headline */}
            <motion.h1
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="text-5xl md:text-6xl lg:text-7xl font-black leading-[1.1] tracking-tight"
            >
              {t('landing.hero.tagline')}
            </motion.h1>

            {/* Subtitle */}
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.3 }}
              className="text-lg md:text-xl text-gray-700 dark:text-gray-300 max-w-2xl leading-relaxed"
            >
              {t('landing.hero.subtitle')}
            </motion.p>

            {/* CTAs */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.4 }}
              className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start"
            >
              <button
                onClick={() => router.push('/projects')}
                className="group px-8 py-4 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg font-semibold text-lg hover:bg-gray-800 dark:hover:bg-gray-100 transition-all duration-200 shadow-lg flex items-center justify-center gap-2"
              >
                {t('landing.hero.cta')}
                <ArrowRight className="h-5 w-5 group-hover:translate-x-1 transition-transform" />
              </button>

              <button className="px-8 py-4 bg-white/60 dark:bg-white/10 text-gray-900 dark:text-white border border-amber-300/60 dark:border-white/20 rounded-lg font-semibold text-lg hover:bg-white/80 dark:hover:bg-white/20 transition-all duration-200 shadow-lg backdrop-blur-sm">
                {t('landing.hero.watchDemo')}
              </button>
            </motion.div>

            {/* Stats */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.5 }}
              className="flex flex-wrap gap-8 justify-center lg:justify-start pt-8"
            >
              {[
                { value: '5000+', label: 'Khách hàng' },
                { value: '300%', label: 'Tăng trưởng' },
                { value: '4.9/5', label: 'Đánh giá' },
              ].map((stat, index) => (
                <div key={index} className="text-center lg:text-left">
                  <div className="text-3xl md:text-4xl font-black">{stat.value}</div>
                  <div className="text-sm text-gray-600 dark:text-gray-400 font-semibold">{stat.label}</div>
                </div>
              ))}
            </motion.div>
          </motion.div>

          {/* Right: Dashboard Image */}
          <motion.div
            initial={{ opacity: 0, x: 50 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.6, delay: 0.3 }}
            className="relative"
          >
            {/* Decorative elements */}
            <div className="absolute -top-8 -left-8 w-32 h-32 bg-yellow-400/30 dark:bg-white/10 rounded-2xl -z-10 blur-xl" />
            <div className="absolute -bottom-8 -right-8 w-40 h-40 bg-yellow-400/20 dark:bg-white/5 rounded-2xl -z-10 blur-2xl" />
            <div className="absolute top-1/2 -right-4 w-24 h-24 bg-amber-300/40 dark:bg-white/10 rounded-full -z-10 blur-xl" />

            {/* Main Dashboard Image */}
            <div className="relative border border-amber-300/60 dark:border-white/20 rounded-2xl overflow-hidden shadow-2xl bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm">
              <div className="aspect-[4/3] relative">
                <Image
                  src="/images/dashboard-preview.png"
                  alt="SMAP Analytics Dashboard"
                  fill
                  className="object-cover"
                  priority
                />
              </div>

              {/* Floating metric cards */}
              <motion.div
                animate={{ y: [0, -10, 0] }}
                transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
                className="absolute top-4 -left-4 bg-white/90 dark:bg-gray-900/90 backdrop-blur-md border border-amber-300/60 dark:border-white/20 rounded-lg p-3 shadow-lg"
              >
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-green-500 rounded-full" />
                  <span className="font-semibold text-sm text-gray-900 dark:text-white">+24% ROI</span>
                </div>
              </motion.div>

              <motion.div
                animate={{ y: [0, 10, 0] }}
                transition={{ duration: 2.5, repeat: Infinity, ease: "easeInOut", delay: 0.5 }}
                className="absolute bottom-4 -right-4 bg-white/90 dark:bg-gray-900/90 backdrop-blur-md border border-amber-300/60 dark:border-white/20 rounded-lg p-3 shadow-lg"
              >
                <div className="flex items-center gap-2">
                  <TrendingUp className="h-4 w-4 text-gray-900 dark:text-white" />
                  <span className="font-semibold text-sm text-gray-900 dark:text-white">Live Data</span>
                </div>
              </motion.div>
            </div>
          </motion.div>
        </div>
      </div>

      {/* Bottom separator */}
      <div className="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-amber-300/60 dark:via-white/20 to-transparent" />
    </section>
  )
}
