import { useEffect } from 'react'
import { useRouter } from 'next/router'
import type { NextPage } from 'next'
import { serverSideTranslations } from 'next-i18next/serverSideTranslations'

const ProjectDetail: NextPage = () => {
  const router = useRouter()
  const { project_id } = router.query

  useEffect(() => {
    if (project_id && typeof project_id === 'string') {
      // Redirect to dashboard tab (default)
      router.replace(`/projects/${project_id}/dashboard`)
    }
  }, [project_id, router])

  // Show loading state while redirecting
  return (
    <div className="flex items-center justify-center min-h-screen bg-amber-50 dark:bg-gray-950">
      <div className="text-center">
        <div className="inline-block w-16 h-16 border-4 border-gray-900 dark:border-white border-t-transparent rounded-full animate-spin" />
        <p className="mt-4 text-gray-600 dark:text-gray-400">Loading project...</p>
      </div>
    </div>
  )
}

export async function getServerSideProps({ locale }: { locale: string }) {
  return {
    props: {
      ...(await serverSideTranslations(locale, ['common'])),
    },
  }
}

export default ProjectDetail
