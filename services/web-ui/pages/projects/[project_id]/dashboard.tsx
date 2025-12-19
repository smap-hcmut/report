import type { NextPage } from 'next'
import { serverSideTranslations } from 'next-i18next/serverSideTranslations'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import ProjectDetailLayout from '@/components/project/ProjectDetailLayout'
import DashboardSidebar from '@/components/dashboard/DashboardSidebar'
import DashboardGrid from '@/components/dashboard/DashboardGrid'
import MobileDashboard from '@/components/dashboard/MobileDashboard'
import ProjectSetupWizard from '@/components/dashboard/ProjectSetupWizard'
import ProjectProcessingState from '@/components/dashboard/ProjectProcessingState'
import { useDashboard, Project } from '@/contexts/DashboardContext'
import { useIsMobile } from '@/hooks/useResponsive'

const ProjectDashboardContent: React.FC<{ projectId: string }> = ({ projectId }) => {
  const router = useRouter()
  const { state, addProject, setProject } = useDashboard()
  const isMobile = useIsMobile()
  const [showWizard, setShowWizard] = useState(false)
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

  const handleProjectComplete = (projectData: any) => {
    const newProject: Project = {
      id: Date.now().toString(),
      name: projectData.name,
      description: projectData.description,
      brands: projectData.brands,
      competitors: projectData.competitors,
      createdAt: new Date(),
      status: 'completed'
    }

    addProject(newProject)
    setShowWizard(false)
  }

  if (isLoading) {
    return (
      <ProjectDetailLayout projectId={projectId}>
        <div className="flex items-center justify-center h-full">
          <div className="text-center">
            <div className="inline-block w-16 h-16 border-4 border-gray-900 dark:border-white border-t-transparent rounded-full animate-spin" />
            <p className="mt-4 text-gray-600 dark:text-gray-400">Loading dashboard...</p>
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

  // Handle processing projects
  if (currentProject?.status === 'process') {
    return (
      <ProjectDetailLayout projectId={projectId}>
        <ProjectProcessingState projectId={currentProject.id} />
      </ProjectDetailLayout>
    )
  }

  // Handle draft projects - redirect is handled in useEffect above
  if (currentProject?.status === 'draft') {
    return null
  }

  if (isMobile) {
    return (
      <>
        <MobileDashboard />
        <ProjectSetupWizard
          isOpen={showWizard}
          onClose={() => setShowWizard(false)}
          onComplete={handleProjectComplete}
        />
      </>
    )
  }

  return (
    <ProjectDetailLayout projectId={projectId}>
      <div className="flex h-full overflow-hidden">
        {/* Sidebar */}
        <DashboardSidebar />

        {/* Main Content */}
        <div className="flex-1 overflow-auto">
          <DashboardGrid />
        </div>
      </div>

      <ProjectSetupWizard
        isOpen={showWizard}
        onClose={() => setShowWizard(false)}
        onComplete={handleProjectComplete}
      />
    </ProjectDetailLayout>
  )
}

const ProjectDashboard: NextPage = () => {
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

  return <ProjectDashboardContent projectId={project_id} />
}

export async function getServerSideProps({ locale }: { locale: string }) {
  return {
    props: {
      ...(await serverSideTranslations(locale, ['common'])),
    },
  }
}

export default ProjectDashboard
