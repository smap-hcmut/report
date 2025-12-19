import type { NextPage } from 'next'
import { serverSideTranslations } from 'next-i18next/serverSideTranslations'
import { useTranslation } from 'next-i18next'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import ProjectDetailLayout from '@/components/project/ProjectDetailLayout'
import ReportWizard from '@/components/reports/ReportWizard'
import ReportPreview from '@/components/reports/ReportPreview'
import { ReportProvider } from '@/contexts/ReportContext'
import { useDashboard } from '@/contexts/DashboardContext'

const ProjectReportWizardContent: React.FC<{ projectId: string }> = ({ projectId }) => {
  const router = useRouter()
  const { state, setProject } = useDashboard()
  const [currentStep, setCurrentStep] = useState<'wizard' | 'preview'>('wizard')
  const [reportData, setReportData] = useState<any>(null)
  const [isLoading, setIsLoading] = useState(true)

  // Handle project selection from URL route parameter
  useEffect(() => {
    if (projectId && projectId !== state.selectedProject) {
      const projectExists = state.projects.some(p => p.id === projectId)
      if (projectExists) {
        setProject(projectId)
      }
    }
    setIsLoading(false)
  }, [projectId, state.selectedProject, state.projects, setProject])

  // Handle redirect for draft projects
  useEffect(() => {
    const currentProject = state.projects.find(p => p.id === state.selectedProject)
    if (currentProject?.status === 'draft') {
      router.push('/projects')
    }
  }, [state.selectedProject, state.projects, router])

  const handleReportGenerated = (data: any) => {
    setReportData(data)
    setCurrentStep('preview')
  }

  const handleBackToWizard = () => {
    setCurrentStep('wizard')
    setReportData(null)
  }

  if (isLoading) {
    return (
      <ProjectDetailLayout projectId={projectId}>
        <div className="flex items-center justify-center h-full">
          <div className="text-center">
            <div className="inline-block w-16 h-16 border-4 border-gray-900 dark:border-white border-t-transparent rounded-full animate-spin" />
            <p className="mt-4 text-gray-600 dark:text-gray-400">Loading report wizard...</p>
          </div>
        </div>
      </ProjectDetailLayout>
    )
  }

  const currentProject = state.projects.find(p => p.id === state.selectedProject)

  // Handle project not found
  if (!currentProject && !isLoading) {
    return (
      <ProjectDetailLayout projectId={projectId}>
        <div className="flex items-center justify-center h-full">
          <div className="text-center">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Project Not Found</h2>
            <p className="text-gray-600 dark:text-gray-400 mb-4">The project you&apos;re looking for doesn&apos;t exist.</p>
            <button
              onClick={() => router.push('/projects')}
              className="px-6 py-3 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg font-semibold hover:bg-gray-800 dark:hover:bg-gray-100"
            >
              Back to Projects
            </button>
          </div>
        </div>
      </ProjectDetailLayout>
    )
  }

  return (
    <ProjectDetailLayout projectId={projectId}>
      <div className="h-full">
        {currentStep === 'wizard' ? (
          <ReportWizard onReportGenerated={handleReportGenerated} />
        ) : (
          <ReportPreview
            reportData={reportData}
            onBack={handleBackToWizard}
          />
        )}
      </div>
    </ProjectDetailLayout>
  )
}

const ProjectReportWizard: NextPage = () => {
  const router = useRouter()
  const { project_id } = router.query

  if (!project_id || typeof project_id !== 'string') {
    return (
      <div className="flex items-center justify-center min-h-screen bg-amber-50 dark:bg-gray-950">
        <div className="text-center">
          <div className="inline-block w-16 h-16 border-4 border-gray-900 dark:border-white border-t-transparent rounded-full animate-spin" />
          <p className="mt-4 text-gray-600 dark:text-gray-400">Loading...</p>
        </div>
      </div>
    )
  }

  return (
    <ReportProvider>
      <ProjectReportWizardContent projectId={project_id} />
    </ReportProvider>
  )
}

export async function getServerSideProps({ locale }: { locale: string }) {
  return {
    props: {
      ...(await serverSideTranslations(locale, ['common'])),
    },
  }
}

export default ProjectReportWizard
