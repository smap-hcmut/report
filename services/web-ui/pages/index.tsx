import type { NextPage } from 'next'
import { serverSideTranslations } from 'next-i18next/serverSideTranslations'
import LandingHeader from '@/components/landing/LandingHeader'
import LandingFooter from '@/components/landing/LandingFooter'
import HeroSection from '@/components/landing/HeroSection'
import FeaturesSection from '@/components/landing/FeaturesSection'
import SolutionsSection from '@/components/landing/SolutionsSection'
import FeedbackSection from '@/components/landing/FeedbackSection'
// import PricingSection from '@/components/landing/PricingSection'
import AboutSection from '@/components/landing/AboutSection'
import ContactSection from '@/components/landing/ContactSection'

const Home: NextPage = () => {
  return (
    <div className="flex flex-col min-h-screen bg-amber-50 dark:bg-gray-950">
      {/* Background Effects */}
      <div className="fixed inset-0 pointer-events-none">
        {/* Sun Mode - Warm Glows */}
        <div className="absolute top-0 right-1/4 w-[600px] h-[600px] bg-yellow-100/60 rounded-full blur-[128px] dark:hidden" />
        <div className="absolute bottom-1/4 left-1/3 w-[500px] h-[500px] bg-amber-100/50 rounded-full blur-[128px] dark:hidden" />
        <div className="absolute top-1/3 left-0 w-[450px] h-[450px] bg-yellow-50/40 rounded-full blur-[128px] dark:hidden" />

        {/* Dark Mode - Night Sky Stars */}
        <div
          className="hidden dark:block absolute inset-0"
          style={{
            backgroundImage: `
              radial-gradient(2px 2px at 20% 30%, white, transparent),
              radial-gradient(2px 2px at 60% 70%, white, transparent),
              radial-gradient(1px 1px at 50% 50%, white, transparent),
              radial-gradient(1px 1px at 80% 10%, white, transparent),
              radial-gradient(2px 2px at 90% 60%, white, transparent),
              radial-gradient(1px 1px at 33% 80%, white, transparent),
              radial-gradient(1px 1px at 15% 60%, white, transparent)
            `,
            backgroundSize: '200px 200px, 250px 250px, 150px 150px, 180px 180px, 220px 220px, 300px 300px, 280px 280px',
            backgroundPosition: '0 0, 40px 60px, 130px 270px, 70px 100px, 150px 50px, 250px 150px, 100px 200px',
            opacity: 0.4
          }}
        />
        <div className="hidden dark:block absolute top-0 left-1/4 w-96 h-96 bg-white/5 rounded-full blur-[128px]" />
        <div className="hidden dark:block absolute bottom-1/3 right-1/4 w-[500px] h-[500px] bg-white/5 rounded-full blur-[128px]" />
      </div>

      <LandingHeader />
      <main className="flex-1 relative z-10">
        <HeroSection />
        <FeaturesSection />
        <SolutionsSection />
        <FeedbackSection />
        <AboutSection />
        {/* COMMENTED OUT - PricingSection component */}
        {/* <PricingSection /> */}
        <ContactSection />
      </main>
      <LandingFooter />
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

export default Home
