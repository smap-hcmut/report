import { useTranslation } from 'next-i18next'
import { motion } from 'framer-motion'
import { Shield, TrendingUp, Users, Rocket, Lightbulb, Sparkles } from 'lucide-react'

const solutions = [
  {
    icon: Shield,
    titleKey: 'solution1Title',
    descriptionKey: 'solution1Description',
    bgColor: 'bg-gray-900 dark:bg-white',
  },
  {
    icon: TrendingUp,
    titleKey: 'solution2Title',
    descriptionKey: 'solution2Description',
    bgColor: 'bg-gray-900 dark:bg-white',
  },
  {
    icon: Users,
    titleKey: 'solution3Title',
    descriptionKey: 'solution3Description',
    bgColor: 'bg-gray-900 dark:bg-white',
  },
  {
    icon: Rocket,
    titleKey: 'solution4Title',
    descriptionKey: 'solution4Description',
    bgColor: 'bg-gray-900 dark:bg-white',
  },
  {
    icon: Lightbulb,
    titleKey: 'solution5Title',
    descriptionKey: 'solution5Description',
    bgColor: 'bg-gray-900 dark:bg-white',
  },
  {
    icon: Sparkles,
    titleKey: 'solution6Title',
    descriptionKey: 'solution6Description',
    bgColor: 'bg-gray-900 dark:bg-white',
  },
]

export default function SolutionsSection() {
  const { t } = useTranslation('common')

  return (
    <section id="solutions" className="relative py-24 overflow-hidden">
      {/* Decorative glows */}
      <div className="absolute top-20 right-10 w-[500px] h-[500px] bg-amber-200/30 dark:bg-white/5 rounded-full blur-[128px] -z-0" />
      <div className="absolute bottom-40 left-10 w-[450px] h-[450px] bg-yellow-200/40 dark:bg-white/5 rounded-full blur-[128px] -z-0" />

      <div className="container mx-auto px-4 relative z-10">
        {/* Section Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16 max-w-4xl mx-auto"
        >
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-black mb-6 leading-tight">
            {t('landing.solutions.title')}
          </h2>
          <p className="text-lg md:text-xl text-gray-700 dark:text-gray-300 leading-relaxed">
            {t('landing.solutions.subtitle')}
          </p>
        </motion.div>

        {/* Solutions Grid */}
        <div className="max-w-6xl mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {solutions.map((solution, index) => {
              const Icon = solution.icon
              return (
                <motion.div
                  key={solution.titleKey}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true, margin: '-50px' }}
                  transition={{ duration: 0.4, delay: index * 0.1 }}
                  whileHover={{ y: -4, transition: { duration: 0.2 } }}
                  className="group cursor-pointer"
                >
                  <div className="h-full p-6 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-200">
                    {/* Icon */}
                    <div className={`inline-flex p-3 ${solution.bgColor} rounded-xl mb-4 group-hover:scale-110 transition-transform duration-200 shadow-lg`}>
                      <Icon className="w-7 h-7 text-white dark:text-gray-900" strokeWidth={2.5} />
                    </div>

                    {/* Content */}
                    <h3 className="text-xl font-black mb-3 text-gray-900 dark:text-white">
                      {t(`landing.solutions.${solution.titleKey}`)}
                    </h3>
                    <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
                      {t(`landing.solutions.${solution.descriptionKey}`)}
                    </p>
                  </div>
                </motion.div>
              )
            })}
          </div>
        </div>

        {/* Bottom CTA */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.5 }}
          className="text-center mt-16"
        >
          <button className="px-8 py-4 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg font-semibold text-lg hover:bg-gray-800 dark:hover:bg-gray-100 transition-all duration-200 shadow-lg">
            Khám phá thêm →
          </button>
        </motion.div>
      </div>
    </section>
  )
}
