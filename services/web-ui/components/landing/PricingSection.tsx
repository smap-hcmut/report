// COMMENTED OUT - PricingSection component
// This component displays the pricing plans section on the landing page
// Features: 3 pricing tiers (Starter, Professional, Enterprise) with internationalization support

/*
ORIGINAL PRICING SECTION - COMMENTED OUT FOR REMOVAL

'use client'

import { useTranslation } from 'next-i18next'
import { motion } from 'framer-motion'
import { Check, Zap } from 'lucide-react'

const plans = [
  {
    nameKey: 'starter',
    priceKey: 'starterPrice',
    descriptionKey: 'starterDescription',
    features: ['feature1', 'feature2', 'feature3'],
    popular: false,
    bgColor: 'bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm',
  },
  {
    nameKey: 'professional',
    priceKey: 'professionalPrice',
    descriptionKey: 'professionalDescription',
    features: ['feature1', 'feature2', 'feature3', 'feature4', 'feature5'],
    popular: true,
    bgColor: 'bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm',
  },
  {
    nameKey: 'enterprise',
    priceKey: 'enterprisePrice',
    descriptionKey: 'enterpriseDescription',
    features: ['feature1', 'feature2', 'feature3', 'feature4', 'feature5', 'feature6'],
    popular: false,
    bgColor: 'bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm',
  },
]

export default function PricingSection() {
  const { t } = useTranslation('common')

  return (
    <section id="pricing" className="relative py-24 overflow-hidden">
      <div className="absolute top-20 left-10 w-[500px] h-[500px] bg-yellow-200/35 dark:bg-white/5 rounded-full blur-[128px] -z-0" />
      <div className="absolute bottom-32 right-16 w-[550px] h-[550px] bg-amber-200/30 dark:bg-white/5 rounded-full blur-[128px] -z-0" />

      <div className="container mx-auto px-4 relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16 max-w-4xl mx-auto"
        >
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-black mb-6 leading-tight">
            {t('landing.pricing.title')}
          </h2>
          <p className="text-lg md:text-xl text-gray-700 dark:text-gray-300 leading-relaxed font-medium">
            {t('landing.pricing.subtitle')}
          </p>
        </motion.div>

        <div className="max-w-6xl mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {plans.map((plan, index) => (
              <motion.div
                key={plan.nameKey}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                className={`relative ${plan.popular ? 'md:-mt-4 md:mb-4' : ''}`}
              >
                {plan.popular && (
                  <div className="absolute -top-4 left-1/2 -translate-x-1/2 z-10">
                    <div className="inline-flex items-center gap-2 px-4 py-2 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg shadow-lg font-semibold text-sm">
                      <Zap className="w-4 h-4" />
                      {t('landing.pricing.popular')}
                    </div>
                  </div>
                )}

                <div
                  className={`h-full p-8 ${plan.bgColor} border border-amber-300/60 dark:border-white/20 rounded-2xl shadow-xl hover:shadow-2xl transition-all duration-200 ${
                    plan.popular ? 'ring-2 ring-gray-900 dark:ring-white ring-offset-2 ring-offset-amber-50 dark:ring-offset-gray-950' : ''
                  }`}
                >
                  <h3 className="text-2xl font-black mb-2 text-gray-900 dark:text-white">
                    {t(`landing.pricing.plans.${plan.nameKey}.name`)}
                  </h3>

                  <div className="mb-4">
                    <span className="text-4xl md:text-5xl font-black text-gray-900 dark:text-white">
                      {t(`landing.pricing.plans.${plan.nameKey}.price`)}
                    </span>
                    <span className="text-gray-600 dark:text-gray-400">
                      /{t('landing.pricing.perMonth')}
                    </span>
                  </div>

                  <p className="text-gray-700 dark:text-gray-300 mb-6">
                    {t(`landing.pricing.plans.${plan.nameKey}.description`)}
                  </p>

                  <ul className="space-y-3 mb-8">
                    {plan.features.map((feature, featureIndex) => (
                      <li key={featureIndex} className="flex items-start gap-3">
                        <div className="flex-shrink-0 w-6 h-6 bg-yellow-400 rounded-md flex items-center justify-center mt-0.5 shadow-sm">
                          <Check className="w-4 h-4 text-gray-900" strokeWidth={3} />
                        </div>
                        <span className="text-gray-700 dark:text-gray-300">
                          {t(`landing.pricing.plans.${plan.nameKey}.features.${feature}`)}
                        </span>
                      </li>
                    ))}
                  </ul>

                  <button
                    className={`w-full py-4 rounded-lg font-semibold text-lg transition-all duration-200 shadow-lg ${
                      plan.popular
                        ? 'bg-gray-900 dark:bg-white text-white dark:text-gray-900 hover:bg-gray-800 dark:hover:bg-gray-100'
                        : 'bg-white/80 dark:bg-gray-800/80 text-gray-900 dark:text-white border border-amber-300/60 dark:border-white/20 hover:bg-white dark:hover:bg-gray-800'
                    }`}
                  >
                    {t('landing.pricing.getStarted')}
                  </button>
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.4 }}
          className="text-center text-gray-600 dark:text-gray-400 font-medium mt-12"
        >
          {t('landing.pricing.note')}
        </motion.p>
      </div>
    </section>
  )
}

END OF COMMENTED PRICING SECTION
*/

// Temporary placeholder component to prevent build errors
export default function PricingSection() {
  return (
    <div className="py-24 text-center">
      <p className="text-gray-500">Pricing section temporarily disabled</p>
    </div>
  )
}