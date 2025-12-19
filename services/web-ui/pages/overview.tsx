import type { NextPage } from 'next'
import { serverSideTranslations } from 'next-i18next/serverSideTranslations'
import { useTranslation } from 'next-i18next'
import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import NodesSidebar from '@/components/NodesSidebar'
import FlowCanvas from '@/components/FlowCanvas'

const Overview: NextPage = () => {
  const { t } = useTranslation('common')
  
  return (
    <div className="flex flex-col h-screen">
      <Navbar />
      <div className="flex flex-1 overflow-hidden">
        <NodesSidebar />
        <main className="flex-1 overflow-hidden bg-background">
          <FlowCanvas />
        </main>
      </div>
      <Footer />
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

export default Overview
