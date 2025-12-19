import { useTranslation } from 'next-i18next'
import { Facebook, Twitter, Linkedin, Instagram, Youtube, Mail } from 'lucide-react'

const footerLinks = {
  product: [
    { key: 'features', href: '#features' },
    { key: 'solutions', href: '#solutions' },
    // { key: 'pricing', href: '#pricing' },
  ],
  company: [
    { key: 'aboutUs', href: '#about' },
    { key: 'careers', href: '#careers' },
    { key: 'blog', href: '#blog' },
    { key: 'contact', href: '#contact' },
  ],
  support: [
    { key: 'documentation', href: '#docs' },
    { key: 'helpCenter', href: '#help' },
    { key: 'community', href: '#community' },
  ],
  legal: [
    { key: 'privacy', href: '#privacy' },
    { key: 'terms', href: '#terms' },
  ],
}

const socialLinks = [
  { icon: Facebook, href: 'https://facebook.com', label: 'Facebook' },
  { icon: Twitter, href: 'https://twitter.com', label: 'Twitter' },
  { icon: Linkedin, href: 'https://linkedin.com', label: 'LinkedIn' },
  { icon: Instagram, href: 'https://instagram.com', label: 'Instagram' },
  { icon: Youtube, href: 'https://youtube.com', label: 'YouTube' },
]

export default function LandingFooter() {
  const { t } = useTranslation('common')

  return (
    <footer className="border-t border-amber-300/60 dark:border-white/20 bg-white/40 dark:bg-gray-900/40 backdrop-blur-md">
      <div className="container mx-auto px-4 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-8 mb-8">
          {/* Brand & Description */}
          <div className="lg:col-span-2">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-lg bg-yellow-400 shadow-lg dark:bg-white" />
              <h2 className="text-lg font-black text-gray-900 dark:text-white">
                {t('navbar.brand')}
              </h2>
            </div>
            <p className="text-sm text-gray-700 dark:text-gray-300 mb-6 max-w-xs">
              {t('landing.footer.description')}
            </p>

            {/* Social Links */}
            <div>
              <h3 className="text-sm font-black mb-3 text-gray-900 dark:text-white">{t('landing.footer.followUs')}</h3>
              <div className="flex items-center gap-3">
                {socialLinks.map((social) => {
                  const Icon = social.icon
                  return (
                    <a
                      key={social.label}
                      href={social.href}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center justify-center h-9 w-9 rounded-lg border border-amber-300/60 dark:border-white/20 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm shadow-lg hover:bg-white/80 dark:hover:bg-gray-900/80 transition-all duration-200"
                      aria-label={social.label}
                    >
                      <Icon className="h-4 w-4 text-gray-900 dark:text-white" />
                    </a>
                  )
                })}
              </div>
            </div>
          </div>

          {/* Product */}
          <div>
            <h3 className="text-sm font-black mb-4 text-gray-900 dark:text-white">{t('landing.footer.product')}</h3>
            <ul className="space-y-3">
              {footerLinks.product.map((link) => (
                <li key={link.key}>
                  <a
                    href={link.href}
                    className="text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
                  >
                    {t(`landing.footer.${link.key}`)}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {/* Company */}
          <div>
            <h3 className="text-sm font-black mb-4 text-gray-900 dark:text-white">{t('landing.footer.company')}</h3>
            <ul className="space-y-3">
              {footerLinks.company.map((link) => (
                <li key={link.key}>
                  <a
                    href={link.href}
                    className="text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
                  >
                    {t(`landing.footer.${link.key}`)}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {/* Support */}
          <div>
            <h3 className="text-sm font-black mb-4 text-gray-900 dark:text-white">{t('landing.footer.support')}</h3>
            <ul className="space-y-3">
              {footerLinks.support.map((link) => (
                <li key={link.key}>
                  <a
                    href={link.href}
                    className="text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
                  >
                    {t(`landing.footer.${link.key}`)}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {/* Legal */}
          <div>
            <h3 className="text-sm font-black mb-4 text-gray-900 dark:text-white">{t('landing.footer.legal')}</h3>
            <ul className="space-y-3">
              {footerLinks.legal.map((link) => (
                <li key={link.key}>
                  <a
                    href={link.href}
                    className="text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
                  >
                    {t(`landing.footer.${link.key}`)}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Divider */}
        <div className="border-t border-amber-300/60 dark:border-white/20 pt-8">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <p className="text-sm text-gray-600 dark:text-gray-400">
              {t('landing.footer.copyright')}
            </p>
            <div className="flex items-center gap-2">
              <div className="inline-flex items-center gap-2 px-4 py-2 bg-gray-900 dark:bg-white rounded-lg shadow-lg">
                <Mail className="h-4 w-4 text-white dark:text-gray-900" />
                <a
                  href="mailto:contact@smapsolution.com"
                  className="text-sm font-semibold text-white dark:text-gray-900 hover:underline underline-offset-2"
                >
                  contact@smapsolution.com
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
}
