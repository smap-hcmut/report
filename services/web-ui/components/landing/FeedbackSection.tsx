'use client'

import { useTranslation } from 'next-i18next'
import { motion, AnimatePresence } from 'framer-motion'
import { Star, Quote, ChevronLeft, ChevronRight, Users, TrendingUp, Award } from 'lucide-react'
import { useState } from 'react'

const stats = [
  {
    icon: Users,
    valueKey: 'customersCount',
    labelKey: 'customersLabel',
    bgColor: 'bg-gray-900 dark:bg-white',
  },
  {
    icon: Star,
    valueKey: 'rating',
    labelKey: 'ratingLabel',
    bgColor: 'bg-gray-900 dark:bg-white',
  },
  {
    icon: TrendingUp,
    valueKey: 'growthRate',
    labelKey: 'growthLabel',
    bgColor: 'bg-gray-900 dark:bg-white',
  },
  {
    icon: Award,
    valueKey: 'satisfaction',
    labelKey: 'satisfactionLabel',
    bgColor: 'bg-gray-900 dark:bg-white',
  },
]

const testimonials = [
  {
    nameKey: 'testimonial1Name',
    positionKey: 'testimonial1Position',
    companyKey: 'testimonial1Company',
    quoteKey: 'testimonial1Quote',
    rating: 5,
    avatar: '/images/avatars/avatar1.jpg',
  },
  {
    nameKey: 'testimonial2Name',
    positionKey: 'testimonial2Position',
    companyKey: 'testimonial2Company',
    quoteKey: 'testimonial2Quote',
    rating: 5,
    avatar: '/images/avatars/avatar2.jpg',
  },
  {
    nameKey: 'testimonial3Name',
    positionKey: 'testimonial3Position',
    companyKey: 'testimonial3Company',
    quoteKey: 'testimonial3Quote',
    rating: 5,
    avatar: '/images/avatars/avatar3.jpg',
  },
]

export default function FeedbackSection() {
  const { t } = useTranslation('common')
  const [currentIndex, setCurrentIndex] = useState(0)

  const nextTestimonial = () => {
    setCurrentIndex((prev) => (prev + 1) % testimonials.length)
  }

  const prevTestimonial = () => {
    setCurrentIndex((prev) => (prev - 1 + testimonials.length) % testimonials.length)
  }

  return (
    <section id="feedback" className="relative py-24 overflow-hidden">
      {/* Decorative glows */}
      <div className="absolute top-32 left-10 w-[550px] h-[550px] bg-yellow-200/30 dark:bg-white/5 rounded-full blur-[128px] -z-0" />
      <div className="absolute bottom-40 right-16 w-[480px] h-[480px] bg-amber-200/40 dark:bg-white/5 rounded-full blur-[128px] -z-0" />

      <div className="container mx-auto px-4 relative z-10">
        {/* Section Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16 max-w-4xl mx-auto"
        >
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-black mb-6 leading-tight">
            {t('landing.feedback.title')}
          </h2>
          <p className="text-lg md:text-xl text-gray-700 dark:text-gray-300 leading-relaxed font-medium">
            {t('landing.feedback.subtitle')}
          </p>
        </motion.div>

        {/* Stats Grid */}
        <div className="max-w-6xl mx-auto mb-20">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {stats.map((stat, index) => {
              const Icon = stat.icon
              return (
                <motion.div
                  key={stat.labelKey}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: index * 0.1 }}
                  className="text-center"
                >
                  <div className={`inline-flex items-center justify-center w-16 h-16 ${stat.bgColor} rounded-2xl shadow-lg mb-4`}>
                    <Icon className="w-8 h-8 text-white dark:text-gray-900" strokeWidth={2.5} />
                  </div>
                  <motion.div
                    initial={{ scale: 0.5 }}
                    whileInView={{ scale: 1 }}
                    viewport={{ once: true }}
                    transition={{ duration: 0.5, delay: index * 0.1 + 0.2 }}
                    className="text-3xl md:text-4xl font-black mb-2"
                  >
                    {t(`landing.feedback.stats.${stat.valueKey}`)}
                  </motion.div>
                  <p className="text-sm text-gray-600 dark:text-gray-400 font-semibold">
                    {t(`landing.feedback.stats.${stat.labelKey}`)}
                  </p>
                </motion.div>
              )
            })}
          </div>
        </div>

        {/* Testimonials Carousel */}
        <div className="max-w-4xl mx-auto">
          <div className="relative">
            {/* Quote decoration */}
            <div className="absolute -top-8 -left-4 opacity-20">
              <Quote className="w-20 h-20 text-gray-900 dark:text-white" strokeWidth={3} />
            </div>

            <AnimatePresence mode="wait">
              <motion.div
                key={currentIndex}
                initial={{ opacity: 0, x: 100 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -100 }}
                transition={{ duration: 0.3 }}
                className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl p-8 md:p-12 shadow-2xl"
              >
                {/* Rating */}
                <div className="flex gap-1 mb-6 justify-center">
                  {Array.from({ length: testimonials[currentIndex].rating }).map((_, i) => (
                    <Star key={i} className="w-7 h-7 fill-yellow-400 text-yellow-400" strokeWidth={2} />
                  ))}
                </div>

                {/* Quote */}
                <blockquote className="text-lg md:text-xl text-center mb-8 leading-relaxed font-semibold">
                  &ldquo;{t(`landing.feedback.testimonials.${testimonials[currentIndex].quoteKey}`)}&rdquo;
                </blockquote>

                {/* Author Info */}
                <div className="flex flex-col items-center gap-4">
                  <div className="relative w-16 h-16 rounded-full overflow-hidden border-2 border-amber-300/60 dark:border-white/20 bg-gray-900 dark:bg-white shadow-lg">
                    {/* Avatar placeholder */}
                    <div className="w-full h-full flex items-center justify-center text-white dark:text-gray-900 text-2xl font-black">
                      {t(`landing.feedback.testimonials.${testimonials[currentIndex].nameKey}`).charAt(0)}
                    </div>
                    {/* Uncomment when avatars are provided:
                    <Image
                      src={testimonials[currentIndex].avatar}
                      alt={t(`landing.feedback.testimonials.${testimonials[currentIndex].nameKey}`)}
                      fill
                      className="object-cover"
                    />
                    */}
                  </div>
                  <div className="text-center">
                    <h4 className="font-black text-lg">
                      {t(`landing.feedback.testimonials.${testimonials[currentIndex].nameKey}`)}
                    </h4>
                    <p className="text-gray-600 dark:text-gray-400 text-sm font-semibold">
                      {t(`landing.feedback.testimonials.${testimonials[currentIndex].positionKey}`)} • {t(`landing.feedback.testimonials.${testimonials[currentIndex].companyKey}`)}
                    </p>
                  </div>
                </div>
              </motion.div>
            </AnimatePresence>

            {/* Navigation Arrows */}
            <div className="flex justify-center gap-4 mt-8">
              <button
                onClick={prevTestimonial}
                className="p-3 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-lg shadow-lg hover:bg-white/80 dark:hover:bg-gray-900/80 transition-all duration-200 group"
                aria-label="Previous testimonial"
              >
                <ChevronLeft className="w-6 h-6 text-gray-900 dark:text-white" strokeWidth={2.5} />
              </button>

              {/* Dots indicator */}
              <div className="flex items-center gap-2">
                {testimonials.map((_, index) => (
                  <button
                    key={index}
                    onClick={() => setCurrentIndex(index)}
                    className={`h-3 rounded-full border border-amber-300/60 dark:border-white/20 transition-all duration-300 ${
                      index === currentIndex
                        ? 'w-8 bg-gray-900 dark:bg-white'
                        : 'w-3 bg-white/60 dark:bg-white/10 hover:bg-white/80 dark:hover:bg-white/20'
                    }`}
                    aria-label={`Go to testimonial ${index + 1}`}
                  />
                ))}
              </div>

              <button
                onClick={nextTestimonial}
                className="p-3 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-lg shadow-lg hover:bg-white/80 dark:hover:bg-gray-900/80 transition-all duration-200 group"
                aria-label="Next testimonial"
              >
                <ChevronRight className="w-6 h-6 text-gray-900 dark:text-white" strokeWidth={2.5} />
              </button>
            </div>
          </div>
        </div>

        {/* Case Studies Grid (Optional showcase) */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="max-w-6xl mx-auto mt-20"
        >
          <h3 className="text-3xl md:text-4xl font-black text-center mb-12">
            {t('landing.feedback.caseStudiesTitle')}
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {[
              { num: 1, bgColor: 'bg-yellow-400/30 dark:bg-white/10' },
              { num: 2, bgColor: 'bg-amber-300/40 dark:bg-white/5' },
              { num: 3, bgColor: 'bg-yellow-300/35 dark:bg-white/10' },
            ].map((caseItem, index) => (
              <motion.div
                key={caseItem.num}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: index * 0.1 }}
                whileHover={{ y: -4 }}
                className="group p-6 rounded-2xl bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 shadow-lg hover:shadow-xl transition-all duration-200"
              >
                <div className={`inline-block px-4 py-2 ${caseItem.bgColor} rounded-lg shadow-lg mb-4 backdrop-blur-sm`}>
                  <div className="text-3xl font-black text-gray-900 dark:text-white">
                    {t(`landing.feedback.caseStudies.case${caseItem.num}.metric`)}
                  </div>
                </div>
                <h4 className="font-black text-lg mb-2 text-gray-900 dark:text-white">
                  {t(`landing.feedback.caseStudies.case${caseItem.num}.title`)}
                </h4>
                <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
                  {t(`landing.feedback.caseStudies.case${caseItem.num}.description`)}
                </p>
              </motion.div>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  )
}
