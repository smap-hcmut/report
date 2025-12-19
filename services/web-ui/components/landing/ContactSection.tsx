'use client'

import { useTranslation } from 'next-i18next'
import { motion } from 'framer-motion'
import { Mail, Phone, MapPin, Send, Clock } from 'lucide-react'

export default function ContactSection() {
  const { t } = useTranslation('common')

  return (
    <section id="contact" className="relative py-24 overflow-hidden">
      {/* Decorative glows */}
      <div className="absolute top-20 right-10 w-[480px] h-[480px] bg-amber-200/30 dark:bg-white/5 rounded-full blur-[128px] -z-0" />
      <div className="absolute bottom-32 left-16 w-[520px] h-[520px] bg-yellow-200/35 dark:bg-white/5 rounded-full blur-[128px] -z-0" />

      <div className="container mx-auto px-4 relative z-10">
        {/* Section Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16 max-w-4xl mx-auto"
        >
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-black mb-6 leading-tight">
            {t('landing.contact.title')}
          </h2>
          <p className="text-lg md:text-xl text-gray-700 dark:text-gray-300 leading-relaxed font-medium">
            {t('landing.contact.subtitle')}
          </p>
        </motion.div>

        <div className="max-w-6xl mx-auto">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
            {/* Contact Form */}
            <motion.div
              initial={{ opacity: 0, x: -30 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5 }}
              className="p-8 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl shadow-xl"
            >
              <h3 className="text-2xl font-black mb-6 text-gray-900 dark:text-white">{t('landing.contact.form.title')}</h3>

              <form className="space-y-5">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div>
                    <label className="block text-sm font-semibold mb-2 text-gray-900 dark:text-white">
                      {t('landing.contact.form.name')}
                    </label>
                    <input
                      type="text"
                      className="w-full px-4 py-3 border border-amber-300/60 dark:border-white/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-gray-900 dark:focus:ring-white bg-white/80 dark:bg-gray-900/80 text-gray-900 dark:text-white"
                      placeholder={t('landing.contact.form.namePlaceholder')}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-semibold mb-2 text-gray-900 dark:text-white">
                      {t('landing.contact.form.email')}
                    </label>
                    <input
                      type="email"
                      className="w-full px-4 py-3 border border-amber-300/60 dark:border-white/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-gray-900 dark:focus:ring-white bg-white/80 dark:bg-gray-900/80 text-gray-900 dark:text-white"
                      placeholder={t('landing.contact.form.emailPlaceholder')}
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-semibold mb-2 text-gray-900 dark:text-white">
                    {t('landing.contact.form.company')}
                  </label>
                  <input
                    type="text"
                    className="w-full px-4 py-3 border border-amber-300/60 dark:border-white/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-gray-900 dark:focus:ring-white bg-white/80 dark:bg-gray-900/80 text-gray-900 dark:text-white"
                    placeholder={t('landing.contact.form.companyPlaceholder')}
                  />
                </div>

                <div>
                  <label className="block text-sm font-semibold mb-2 text-gray-900 dark:text-white">
                    {t('landing.contact.form.message')}
                  </label>
                  <textarea
                    rows={4}
                    className="w-full px-4 py-3 border border-amber-300/60 dark:border-white/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-gray-900 dark:focus:ring-white bg-white/80 dark:bg-gray-900/80 text-gray-900 dark:text-white resize-none"
                    placeholder={t('landing.contact.form.messagePlaceholder')}
                  />
                </div>

                <button
                  type="submit"
                  className="w-full flex items-center justify-center gap-2 px-6 py-4 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg font-semibold text-lg hover:bg-gray-800 dark:hover:bg-gray-100 transition-all duration-200 shadow-lg"
                >
                  <Send className="w-5 h-5" />
                  {t('landing.contact.form.submit')}
                </button>
              </form>
            </motion.div>

            {/* Contact Info */}
            <motion.div
              initial={{ opacity: 0, x: 30 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5 }}
              className="space-y-6"
            >
              {/* Info Cards */}
              <div className="p-6 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl shadow-lg">
                <div className="flex items-start gap-4">
                  <div className="inline-flex items-center justify-center w-12 h-12 bg-gray-900 dark:bg-white rounded-xl shadow-lg flex-shrink-0">
                    <Mail className="w-6 h-6 text-white dark:text-gray-900" />
                  </div>
                  <div>
                    <h4 className="font-black text-lg mb-1 text-gray-900 dark:text-white">{t('landing.contact.info.email')}</h4>
                    <a href="mailto:contact@smapsolution.com" className="text-gray-700 dark:text-gray-300 hover:underline">
                      contact@smapsolution.com
                    </a>
                  </div>
                </div>
              </div>

              <div className="p-6 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl shadow-lg">
                <div className="flex items-start gap-4">
                  <div className="inline-flex items-center justify-center w-12 h-12 bg-gray-900 dark:bg-white rounded-xl shadow-lg flex-shrink-0">
                    <Phone className="w-6 h-6 text-white dark:text-gray-900" />
                  </div>
                  <div>
                    <h4 className="font-black text-lg mb-1 text-gray-900 dark:text-white">{t('landing.contact.info.phone')}</h4>
                    <a href="tel:+84123456789" className="text-gray-700 dark:text-gray-300 hover:underline">
                      +84 123 456 789
                    </a>
                  </div>
                </div>
              </div>

              <div className="p-6 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl shadow-lg">
                <div className="flex items-start gap-4">
                  <div className="inline-flex items-center justify-center w-12 h-12 bg-gray-900 dark:bg-white rounded-xl shadow-lg flex-shrink-0">
                    <MapPin className="w-6 h-6 text-white dark:text-gray-900" />
                  </div>
                  <div>
                    <h4 className="font-black text-lg mb-1 text-gray-900 dark:text-white">{t('landing.contact.info.address')}</h4>
                    <p className="text-gray-700 dark:text-gray-300">
                      {t('landing.contact.info.addressValue')}
                    </p>
                  </div>
                </div>
              </div>

              <div className="p-6 bg-gray-900 dark:bg-white rounded-2xl shadow-lg">
                <div className="flex items-start gap-4">
                  <div className="inline-flex items-center justify-center w-12 h-12 bg-white dark:bg-gray-900 rounded-xl shadow-lg flex-shrink-0">
                    <Clock className="w-6 h-6 text-gray-900 dark:text-white" />
                  </div>
                  <div>
                    <h4 className="font-black text-lg mb-1 text-white dark:text-gray-900">{t('landing.contact.info.hours')}</h4>
                    <p className="text-gray-300 dark:text-gray-600">
                      {t('landing.contact.info.hoursValue')}
                    </p>
                  </div>
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  )
}
