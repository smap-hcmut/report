import type { NextPage } from 'next'
import { motion } from 'framer-motion'
import Link from 'next/link'
import { useState } from 'react'

const StylePreview: NextPage = () => {
  const [isDark, setIsDark] = useState(true)

  return (
    <div className={`min-h-screen relative overflow-hidden transition-colors duration-500 ${
      isDark
        ? 'bg-gray-950 text-white'
        : 'bg-amber-50 text-gray-900'
    }`}>
      {/* Background Effects */}
      <div className="fixed inset-0 pointer-events-none">
        {isDark ? (
          <>
            {/* Dark Mode - Night Sky Stars */}
            <div className="absolute inset-0" style={{
              backgroundImage: `radial-gradient(2px 2px at 20% 30%, white, transparent),
                radial-gradient(2px 2px at 60% 70%, white, transparent),
                radial-gradient(1px 1px at 50% 50%, white, transparent),
                radial-gradient(1px 1px at 80% 10%, white, transparent),
                radial-gradient(2px 2px at 90% 60%, white, transparent)`,
              backgroundSize: '200px 200px, 300px 300px, 150px 150px, 250px 250px, 350px 350px',
              opacity: 0.4
            }} />
            {/* Subtle Glow Effects - Monochrome */}
            <div className="absolute top-0 left-1/4 w-96 h-96 bg-white/5 rounded-full blur-[128px]" />
            <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-white/5 rounded-full blur-[128px]" />
            <div className="absolute top-1/2 right-0 w-64 h-64 bg-white/5 rounded-full blur-[128px]" />
          </>
        ) : (
          <>
            {/* Sun Mode - Warm Glows */}
            <div className="absolute top-0 right-1/4 w-[600px] h-[600px] bg-yellow-100/60 rounded-full blur-[128px]" />
            <div className="absolute bottom-1/4 left-1/3 w-[500px] h-[500px] bg-amber-100/50 rounded-full blur-[128px]" />
            <div className="absolute top-1/3 left-0 w-[450px] h-[450px] bg-yellow-50/40 rounded-full blur-[128px]" />
          </>
        )}
      </div>

      {/* Header - Glassmorphism */}
      <header className={`relative z-50 border-b backdrop-blur-xl ${
        isDark
          ? 'border-white/10 bg-gray-900/30'
          : 'border-amber-200/50 bg-white/40'
      }`}>
        <div className="max-w-7xl mx-auto px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-3">
              <div className={`w-8 h-8 rounded-lg shadow-lg ${
                isDark ? 'bg-white' : 'bg-yellow-400'
              }`} />
              <span className={`text-lg font-semibold tracking-tight ${
                isDark ? 'text-white' : 'text-gray-900'
              }`}>
                SMAP SOLUTION
              </span>
            </div>
            <nav className="flex items-center gap-8">
              <a href="#" className={`text-sm font-medium transition-colors ${
                isDark
                  ? 'text-gray-300 hover:text-white'
                  : 'text-gray-700 hover:text-gray-900'
              }`}>
                Features
              </a>
              {/* COMMENTED OUT - Pricing navigation link */}
              {/*
              <a href="#" className={`text-sm font-medium transition-colors ${
                isDark
                  ? 'text-gray-300 hover:text-white'
                  : 'text-gray-700 hover:text-gray-900'
              }`}>
                Pricing
              </a>
              */}
              <a href="#" className={`text-sm font-medium transition-colors ${
                isDark
                  ? 'text-gray-300 hover:text-white'
                  : 'text-gray-700 hover:text-gray-900'
              }`}>
                About
              </a>
              <button
                onClick={() => setIsDark(!isDark)}
                className={`px-5 py-2.5 text-sm font-semibold rounded-lg transition-all shadow-lg ${
                  isDark
                    ? 'bg-white text-gray-950 hover:bg-gray-100'
                    : 'bg-gray-900 text-white hover:bg-gray-800'
                }`}
              >
                {isDark ? 'Sun Mode' : 'Dark Mode'}
              </button>
            </nav>
          </div>
        </div>
      </header>

      {/* Hero Section - Cosmic Typography */}
      <section className="relative max-w-7xl mx-auto px-6 lg:px-8 py-32">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="max-w-4xl"
        >
          <div className={`inline-flex items-center gap-2 px-4 py-2 mb-8 rounded-full backdrop-blur-sm ${
            isDark
              ? 'bg-white/5 border border-white/10'
              : 'bg-white/50 border border-amber-300/60'
          }`}>
            <div className={`w-2 h-2 rounded-full animate-pulse ${
              isDark ? 'bg-white' : 'bg-yellow-500'
            }`} />
            <span className={`text-sm font-semibold uppercase tracking-wider ${
              isDark ? 'text-gray-300' : 'text-gray-800'
            }`}>Analytics Platform</span>
          </div>

          <h1 className="text-6xl lg:text-7xl font-bold mb-6 leading-[1.1]">
            <span className={isDark ? 'text-white' : 'text-gray-900'}>
              Social Media Analytics
            </span>
            <br />
            <span className={isDark ? 'text-gray-400' : 'text-yellow-600'}>
              from the Sun
            </span>
          </h1>

          <p className={`text-xl mb-12 max-w-2xl font-medium leading-relaxed ${
            isDark ? 'text-gray-400' : 'text-gray-700'
          }`}>
            Transform raw data into brilliant insights. Track, analyze, and optimize your social media presence with radiant precision.
          </p>

          <div className="flex items-center gap-4">
            <button className={`group px-8 py-4 font-semibold rounded-xl transition-all duration-300 shadow-lg ${
              isDark
                ? 'bg-white text-gray-950 hover:bg-gray-100'
                : 'bg-gray-900 text-white hover:bg-gray-800'
            }`}>
              Start Free Trial
            </button>
            <button className={`px-8 py-4 font-semibold rounded-xl border backdrop-blur-sm transition-all ${
              isDark
                ? 'bg-white/5 text-white border-white/10 hover:bg-white/10'
                : 'bg-white/60 text-gray-900 border-amber-300/60 hover:bg-white/80'
            }`}>
              View Demo
            </button>
          </div>
        </motion.div>

        {/* Stats Grid - Glassmorphism Cards */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.2 }}
          className="mt-24 grid grid-cols-4 gap-6"
        >
          {[
            { value: '5000+', label: 'Active Users' },
            { value: '98%', label: 'Satisfaction' },
            { value: '24/7', label: 'Support' },
            { value: '50+', label: 'Integrations' },
          ].map((stat, index) => (
            <div
              key={index}
              className={`group relative p-8 backdrop-blur-xl rounded-2xl border transition-all duration-300 overflow-hidden ${
                isDark
                  ? 'bg-white/5 border-white/10 hover:bg-white/10'
                  : 'bg-white/40 border-amber-300/50 hover:bg-white/60'
              }`}
            >
              <div className={`absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity ${
                isDark ? 'bg-white/5' : 'bg-yellow-100/30'
              }`} />
              <div className="relative">
                <div className={`text-4xl font-bold mb-2 ${
                  isDark ? 'text-white' : 'text-gray-900'
                }`}>
                  {stat.value}
                </div>
                <div className={`text-sm font-medium uppercase tracking-wider ${
                  isDark ? 'text-gray-400' : 'text-gray-700'
                }`}>
                  {stat.label}
                </div>
              </div>
            </div>
          ))}
        </motion.div>
      </section>

      {/* Features Section - Cosmic Cards */}
      <section className="relative max-w-7xl mx-auto px-6 lg:px-8 py-24">
        <div className="mb-16 text-center">
          <h2 className={`text-4xl font-bold mb-4 ${
            isDark ? 'text-white' : 'text-gray-900'
          }`}>
            Core Features
          </h2>
          <p className={`text-lg max-w-2xl mx-auto font-medium ${
            isDark ? 'text-gray-400' : 'text-gray-700'
          }`}>
            Harness the power of daylight to understand your audience
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {[
            {
              title: 'Real-time Monitoring',
              description: 'Track mentions and engagement across all platforms with lightning speed.',
              icon: '⚡',
            },
            {
              title: 'AI-Powered Insights',
              description: 'Discover trends and patterns with our cosmic intelligence engine.',
              icon: '🧠',
            },
            {
              title: 'Enterprise Security',
              description: 'Your data protected by stellar-grade encryption technology.',
              icon: '🛡️',
            },
          ].map((feature, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              className="group relative"
            >
              <div className={`absolute inset-0 rounded-2xl blur-xl opacity-0 group-hover:opacity-100 transition-opacity ${
                isDark ? 'bg-white/5' : 'bg-yellow-200/40'
              }`} />

              <div className={`relative p-8 backdrop-blur-xl rounded-2xl border transition-all h-full ${
                isDark
                  ? 'bg-white/5 border-white/10 hover:border-white/20'
                  : 'bg-white/40 border-amber-300/50 hover:border-yellow-400/60'
              }`}>
                <div className={`w-16 h-16 rounded-2xl flex items-center justify-center text-3xl mb-6 shadow-lg ${
                  isDark ? 'bg-white' : 'bg-yellow-400'
                }`}>
                  {feature.icon}
                </div>
                <h3 className={`text-xl font-bold mb-3 ${
                  isDark ? 'text-white' : 'text-gray-900'
                }`}>
                  {feature.title}
                </h3>
                <p className={`font-medium leading-relaxed ${
                  isDark ? 'text-gray-400' : 'text-gray-700'
                }`}>
                  {feature.description}
                </p>
              </div>
            </motion.div>
          ))}
        </div>
      </section>

      {/* COMMENTED OUT - Pricing Section - Nebula Cards */}
      {/* This section displays alternative pricing design with glassmorphism effects */}
      {/*
      <section className="relative max-w-7xl mx-auto px-6 lg:px-8 py-24">
        <div className="mb-16 text-center">
          <h2 className={`text-4xl font-bold mb-4 ${
            isDark ? 'text-white' : 'text-gray-900'
          }`}>
            Choose Your Plan
          </h2>
          <p className={`text-lg font-medium ${
            isDark ? 'text-gray-400' : 'text-gray-700'
          }`}>
            Select the perfect plan for your journey
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {[
            {
              name: 'Starter',
              price: '$49',
              period: '/month',
              features: ['3 Projects', '1,000 Mentions', 'Basic Analytics', 'Email Support'],
              highlighted: false,
            },
            {
              name: 'Professional',
              price: '$149',
              period: '/month',
              features: ['10 Projects', '10,000 Mentions', 'Advanced Analytics', 'API Access', 'Priority Support'],
              highlighted: true,
            },
            {
              name: 'Enterprise',
              price: 'Custom',
              period: '',
              features: ['Unlimited Projects', 'Unlimited Mentions', 'Custom ML Models', 'Dedicated Support', 'SLA Guarantee'],
              highlighted: false,
            },
          ].map((plan, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              className={`relative group ${plan.highlighted ? 'scale-105' : ''}`}
            >
              {plan.highlighted && (
                <div className={`absolute -inset-0.5 rounded-3xl blur opacity-75 group-hover:opacity-100 transition-opacity ${
                  isDark ? 'bg-white/20' : 'bg-yellow-300/60'
                }`} />
              )}

              <div className={`relative p-8 backdrop-blur-xl rounded-2xl border transition-all ${
                isDark
                  ? `${plan.highlighted ? 'bg-white/10 border-white/20' : 'bg-white/5 border-white/10'} hover:border-white/20`
                  : `${plan.highlighted ? 'bg-white/50 border-yellow-400/60' : 'bg-white/40 border-amber-300/50'} hover:border-yellow-400/60`
              }`}>
                {plan.highlighted && (
                  <div className={`absolute -top-4 left-1/2 -translate-x-1/2 px-4 py-1 text-xs font-bold uppercase tracking-wider rounded-full shadow-lg ${
                    isDark
                      ? 'bg-white text-gray-950'
                      : 'bg-gray-900 text-white'
                  }`}>
                    Most Popular
                  </div>
                )}

                <div className="mb-8">
                  <h3 className={`text-sm font-bold uppercase tracking-wider mb-4 ${
                    isDark ? 'text-gray-300' : 'text-gray-700'
                  }`}>
                    {plan.name}
                  </h3>
                  <div className="flex items-baseline">
                    <span className={`text-5xl font-bold ${
                      isDark ? 'text-white' : 'text-gray-900'
                    }`}>
                      {plan.price}
                    </span>
                    {plan.period && (
                      <span className={`ml-2 text-sm font-medium ${
                        isDark ? 'text-gray-400' : 'text-gray-600'
                      }`}>{plan.period}</span>
                    )}
                  </div>
                </div>

                <ul className="space-y-4 mb-8">
                  {plan.features.map((feature, idx) => (
                    <li key={idx} className="flex items-start gap-3">
                      <svg className={`w-5 h-5 mt-0.5 flex-shrink-0 ${
                        isDark ? 'text-white' : 'text-yellow-600'
                      }`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                      </svg>
                      <span className={`text-sm font-medium ${
                        isDark ? 'text-gray-300' : 'text-gray-700'
                      }`}>{feature}</span>
                    </li>
                  ))}
                </ul>

                <button className={`w-full py-3 text-sm font-bold uppercase tracking-wider rounded-xl transition-all ${
                  plan.highlighted
                    ? isDark
                      ? 'bg-white text-gray-950 hover:bg-gray-100 shadow-lg'
                      : 'bg-gray-900 text-white hover:bg-gray-800 shadow-lg'
                    : isDark
                      ? 'bg-white/10 text-white hover:bg-white/20 border border-white/20'
                      : 'bg-white/50 text-gray-900 hover:bg-white/70 border border-amber-300/50'
                }`}>
                  Get Started
                </button>
              </div>
            </motion.div>
          ))}
        </div>
      </section>
      */}

      {/* CTA Section */}
      <section className="relative max-w-7xl mx-auto px-6 lg:px-8 py-24">
        <div className="relative overflow-hidden rounded-3xl">
          {/* Background */}
          {isDark ? (
            <>
              <div className="absolute inset-0 bg-gray-900" />
              <div className="absolute top-0 left-1/4 w-96 h-96 bg-white/5 rounded-full blur-[128px]" />
              <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-white/5 rounded-full blur-[128px]" />
            </>
          ) : (
            <>
              <div className="absolute inset-0 bg-yellow-400" />
              <div className="absolute top-0 left-1/4 w-96 h-96 bg-yellow-300/40 rounded-full blur-[128px]" />
              <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-amber-300/40 rounded-full blur-[128px]" />
            </>
          )}

          <div className={`relative z-10 p-16 text-center backdrop-blur-sm border ${
            isDark ? 'border-white/10' : 'border-yellow-600/30'
          }`}>
            <h2 className={`text-5xl font-bold mb-6 ${
              isDark ? 'text-white' : 'text-gray-900'
            }`}>
              Ready to Shine Brighter?
            </h2>
            <p className={`text-xl mb-10 max-w-2xl mx-auto font-medium ${
              isDark ? 'text-gray-400' : 'text-gray-800'
            }`}>
              Join thousands of businesses harnessing the power of social media analytics
            </p>
            <button className={`px-12 py-4 font-bold text-lg rounded-xl transition-all shadow-2xl ${
              isDark
                ? 'bg-white text-gray-950 hover:bg-gray-100'
                : 'bg-gray-900 text-white hover:bg-gray-800'
            }`}>
              Launch Your Journey
            </button>
            <p className={`mt-6 text-sm font-medium ${
              isDark ? 'text-gray-400' : 'text-gray-800'
            }`}>
              14-day free trial • No credit card required • Cancel anytime
            </p>
          </div>
        </div>
      </section>

      {/* Footer - Glassmorphism */}
      <footer className={`relative border-t backdrop-blur-xl mt-24 ${
        isDark
          ? 'border-white/10 bg-gray-900/30'
          : 'border-amber-200/40 bg-white/30'
      }`}>
        <div className="max-w-7xl mx-auto px-6 lg:px-8 py-16">
          <div className="grid grid-cols-4 gap-12 mb-12">
            <div>
              <div className="flex items-center gap-2 mb-4">
                <div className={`w-6 h-6 rounded-lg ${
                  isDark ? 'bg-white' : 'bg-yellow-400'
                }`} />
                <span className={`font-semibold ${
                  isDark ? 'text-white' : 'text-gray-900'
                }`}>SMAP</span>
              </div>
              <p className={`text-sm font-medium ${
                isDark ? 'text-gray-400' : 'text-gray-700'
              }`}>
                Analytics {isDark ? 'from the universe' : 'from the sun'}
              </p>
            </div>
            {[
              // COMMENTED OUT - Pricing link in footer
              { title: 'Product', links: ['Features', /* 'Pricing', */ 'Security', 'Roadmap'] },
              { title: 'Company', links: ['About', 'Blog', 'Careers', 'Press'] },
              { title: 'Legal', links: ['Privacy', 'Terms', 'Cookies', 'Licenses'] },
            ].map((column, index) => (
              <div key={index}>
                <h3 className={`text-sm font-bold uppercase tracking-wider mb-4 ${
                  isDark ? 'text-white' : 'text-gray-900'
                }`}>
                  {column.title}
                </h3>
                <ul className="space-y-3">
                  {column.links.map((link, idx) => (
                    <li key={idx}>
                      <a href="#" className={`text-sm font-medium transition-colors ${
                        isDark
                          ? 'text-gray-400 hover:text-white'
                          : 'text-gray-600 hover:text-gray-900'
                      }`}>
                        {link}
                      </a>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
          <div className={`pt-8 border-t flex items-center justify-between ${
            isDark ? 'border-white/10' : 'border-amber-200/40'
          }`}>
            <p className={`text-sm font-medium ${
              isDark ? 'text-gray-400' : 'text-gray-600'
            }`}>
              © 2025 SMAP Solution. All rights reserved.
            </p>
            <div className="flex items-center gap-6">
              <a href="#" className={`transition-colors ${
                isDark
                  ? 'text-gray-400 hover:text-white'
                  : 'text-gray-600 hover:text-gray-900'
              }`}>
                <span className="sr-only">Twitter</span>
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M8.29 20.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0022 5.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.072 4.072 0 012.8 9.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 012 18.407a11.616 11.616 0 006.29 1.84" />
                </svg>
              </a>
              <a href="#" className={`transition-colors ${
                isDark
                  ? 'text-gray-400 hover:text-white'
                  : 'text-gray-600 hover:text-gray-900'
              }`}>
                <span className="sr-only">GitHub</span>
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path fillRule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" clipRule="evenodd" />
                </svg>
              </a>
            </div>
          </div>
        </div>
      </footer>

      {/* Back to Home - Floating Button */}
      <div className="fixed bottom-8 left-8 z-50">
        <Link
          href="/"
          className={`flex items-center gap-2 px-5 py-3 backdrop-blur-xl text-sm font-semibold rounded-full border transition-all shadow-lg ${
            isDark
              ? 'bg-white/10 text-white border-white/20 hover:bg-white/20'
              : 'bg-white/50 text-gray-900 border-amber-300/50 hover:bg-white/70'
          }`}
        >
          ← Back to Home
        </Link>
      </div>
    </div>
  )
}

export default StylePreview
