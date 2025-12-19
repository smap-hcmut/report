import type { NextPage } from 'next'
import { serverSideTranslations } from 'next-i18next/serverSideTranslations'
import { useTranslation } from 'next-i18next'
import Navbar from '@/components/Navbar'

const DataCenter: NextPage = () => {
  const { t } = useTranslation('common')
  
  return (
    <div className="min-h-screen">
      <Navbar />
      <main className="container py-8">
        <h1 className="text-3xl font-bold mb-4">{t('navbar.dataCenter')}</h1>
        <p className="text-muted-foreground">Data Center page content will be here</p>
      </main>
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

export default DataCenter
