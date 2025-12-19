'use client'

import { useTranslation } from 'next-i18next'
import { motion } from 'framer-motion'
import { Target, Eye, Heart, Users, Award, Zap } from 'lucide-react'

const values = [
  { icon: Target, key: 'innovation' },
  { icon: Eye, key: 'transparency' },
  { icon: Heart, key: 'customerFirst' },
  { icon: Zap, key: 'excellence' },
]

const stats = [
  { valueKey: 'yearsExperience', labelKey: 'yearsLabel' },
  { valueKey: 'teamMembers', labelKey: 'teamLabel' },
  { valueKey: 'projectsCompleted', labelKey: 'projectsLabel' },
  { valueKey: 'clientSatisfaction', labelKey: 'satisfactionLabel' },
]

export default function AboutSection() {
  const { t } = useTranslation('common')

  return (
    <section id="about" className="relative py-24 overflow-hidden">
      {/* Decorative glows */}
      <div className="absolute top-40 left-10 w-[500px] h-[500px] bg-amber-200/35 dark:bg-white/5 rounded-full blur-[128px] -z-0" />
      <div className="absolute bottom-32 right-16 w-[450px] h-[450px] bg-yellow-200/40 dark:bg-white/5 rounded-full blur-[128px] -z-0" />

      <div className="container mx-auto px-4 relative z-10">
        {/* Section Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16 max-w-4xl mx-auto"
        >
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-black mb-6 leading-tight">
            {t('landing.about.title')}
          </h2>
          <p className="text-lg md:text-xl text-gray-700 dark:text-gray-300 leading-relaxed font-medium">
            {t('landing.about.subtitle')}
          </p>
        </motion.div>

        {/* Mission & Vision */}
        <div className="max-w-6xl mx-auto mb-20">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {/* Mission */}
            <motion.div
              initial={{ opacity: 0, x: -30 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5 }}
              className="p-8 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl shadow-xl"
            >
              <div className="inline-flex items-center justify-center w-16 h-16 bg-gray-900 dark:bg-white rounded-2xl shadow-lg mb-6">
                <Target className="w-8 h-8 text-white dark:text-gray-900" strokeWidth={2.5} />
              </div>
              <h3 className="text-2xl font-black mb-4 text-gray-900 dark:text-white">{t('landing.about.mission.title')}</h3>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
                {t('landing.about.mission.description')}
              </p>
            </motion.div>

            {/* Vision */}
            <motion.div
              initial={{ opacity: 0, x: 30 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5 }}
              className="p-8 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl shadow-xl"
            >
              <div className="inline-flex items-center justify-center w-16 h-16 bg-gray-900 dark:bg-white rounded-2xl shadow-lg mb-6">
                <Eye className="w-8 h-8 text-white dark:text-gray-900" strokeWidth={2.5} />
              </div>
              <h3 className="text-2xl font-black mb-4 text-gray-900 dark:text-white">{t('landing.about.vision.title')}</h3>
              <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
                {t('landing.about.vision.description')}
              </p>
            </motion.div>
          </div>
        </div>

        {/* Our Story */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="max-w-4xl mx-auto mb-20 text-center"
        >
          <h3 className="text-3xl font-black mb-6">{t('landing.about.story.title')}</h3>
          <p className="text-lg text-gray-700 dark:text-gray-300 font-medium leading-relaxed">
            {t('landing.about.story.description')}
          </p>
        </motion.div>

        {/* Core Values */}
        <div className="max-w-6xl mx-auto mb-20">
          <motion.h3
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-3xl font-black text-center mb-12"
          >
            {t('landing.about.values.title')}
          </motion.h3>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {values.map((value, index) => {
              const Icon = value.icon
              return (
                <motion.div
                  key={value.key}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: index * 0.1 }}
                  className="text-center p-6 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-200"
                >
                  <div className="inline-flex items-center justify-center w-14 h-14 bg-gray-900 dark:bg-white rounded-xl shadow-lg mb-4">
                    <Icon className="w-7 h-7 text-white dark:text-gray-900" strokeWidth={2.5} />
                  </div>
                  <h4 className="font-black text-lg mb-2 text-gray-900 dark:text-white">
                    {t(`landing.about.values.${value.key}.title`)}
                  </h4>
                  <p className="text-sm text-gray-600 dark:text-gray-400">
                    {t(`landing.about.values.${value.key}.description`)}
                  </p>
                </motion.div>
              )
            })}
          </div>
        </div>

        {/* Stats */}
        <div className="max-w-4xl mx-auto">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {stats.map((stat, index) => (
              <motion.div
                key={stat.labelKey}
                initial={{ opacity: 0, scale: 0.8 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                className="text-center p-6 bg-gray-900 dark:bg-white rounded-2xl shadow-lg"
              >
                <div className="text-3xl md:text-4xl font-black text-white dark:text-gray-900 mb-2">
                  {t(`landing.about.stats.${stat.valueKey}`)}
                </div>
                <p className="text-sm text-gray-300 dark:text-gray-600 font-semibold">
                  {t(`landing.about.stats.${stat.labelKey}`)}
                </p>
              </motion.div>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
