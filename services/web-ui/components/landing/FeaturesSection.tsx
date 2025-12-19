import { useTranslation } from 'next-i18next'
import { motion } from 'framer-motion'
import Image from 'next/image'

const features = [
  {
    step: '1',
    titleKey: 'step1Title',
    descriptionKey: 'step1Description',
    image: '/images/features/1.png',
    alignment: 'left',
    bgColor: 'bg-yellow-400/30 dark:bg-white/10',
  },
  {
    step: '2',
    titleKey: 'step2Title',
    descriptionKey: 'step2Description',
    image: '/images/features/2.png',
    alignment: 'right',
    bgColor: 'bg-amber-300/40 dark:bg-white/5',
  },
  {
    step: '3',
    titleKey: 'step3Title',
    descriptionKey: 'step3Description',
    image: '/images/features/3.png',
    alignment: 'left',
    bgColor: 'bg-yellow-300/35 dark:bg-white/10',
  },
]

export default function FeaturesSection() {
  const { t } = useTranslation('common')

  return (
    <section id="features" className="relative py-24 overflow-hidden">
      {/* Decorative glows */}
      <div className="absolute top-40 right-20 w-96 h-96 bg-yellow-200/40 dark:bg-white/5 rounded-full blur-[128px] -z-0" />
      <div className="absolute bottom-60 left-16 w-80 h-80 bg-amber-200/30 dark:bg-white/5 rounded-full blur-[128px] -z-0" />

      <div className="container mx-auto px-4 relative z-10">
        {/* Section Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-20 max-w-4xl mx-auto"
        >
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-black mb-6 leading-tight">
            {t('landing.features.title')}
          </h2>
          <p className="text-lg md:text-xl text-gray-700 dark:text-gray-300 leading-relaxed font-medium">
            {t('landing.features.subtitle')}
          </p>
        </motion.div>

        {/* Features Steps */}
        <div className="max-w-6xl mx-auto space-y-24">
          {features.map((feature, index) => (
            <motion.div
              key={feature.step}
              initial={{ opacity: 0, y: 40 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: '-100px' }}
              transition={{ duration: 0.5, delay: index * 0.15 }}
              className={`flex flex-col ${
                feature.alignment === 'right' ? 'md:flex-row-reverse' : 'md:flex-row'
              } items-center gap-8 md:gap-12`}
            >
              {/* Text Content */}
              <div className="flex-1 space-y-6">
                {/* Step Number Badge */}
                <motion.div
                  initial={{ opacity: 0, scale: 0.8 }}
                  whileInView={{ opacity: 1, scale: 1 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.4, delay: index * 0.15 + 0.2 }}
                  className="inline-block"
                >
                  <div className="inline-flex items-center justify-center w-20 h-20 bg-gray-900 dark:bg-white rounded-2xl shadow-lg">
                    <span className="text-4xl font-black text-white dark:text-gray-900">
                      {feature.step}
                    </span>
                  </div>
                </motion.div>

                <h3 className="text-3xl md:text-4xl font-black leading-tight">
                  {t(`landing.features.${feature.titleKey}`)}
                </h3>

                <p className="text-base md:text-lg text-gray-700 dark:text-gray-300 leading-relaxed font-medium">
                  {t(`landing.features.${feature.descriptionKey}`)}
                </p>
              </div>

              {/* Image */}
              <motion.div
                whileHover={{ y: -4 }}
                transition={{ duration: 0.2 }}
                className="flex-1 relative group"
              >
                <div className="relative border border-amber-300/60 dark:border-white/20 rounded-2xl overflow-hidden shadow-2xl bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm group-hover:shadow-xl transition-all duration-200">
                  <Image
                    src={feature.image}
                    alt={t(`landing.features.${feature.titleKey}`)}
                    width={600}
                    height={450}
                    className="w-full h-auto"
                  />
                </div>

                {/* Decorative colored blur */}
                <div
                  className={`absolute -z-10 w-full h-full ${feature.bgColor} rounded-2xl blur-2xl ${
                    feature.alignment === 'right' ? '-left-6 top-6' : '-right-6 top-6'
                  }`}
                />
              </motion.div>
            </motion.div>
          ))}
        </div>

        {/* Bottom CTA */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.3 }}
          className="text-center mt-24"
        >
          <button className="px-8 py-4 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg font-semibold text-lg hover:bg-gray-800 dark:hover:bg-gray-100 transition-all duration-200 shadow-lg">
            {t('landing.features.cta')}
          </button>
        </motion.div>
      </div>
    </section>
  )
}
