import type { NextPage } from 'next'
import { serverSideTranslations } from 'next-i18next/serverSideTranslations'
import { useTranslation } from 'next-i18next'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import ProjectDetailLayout from '@/components/project/ProjectDetailLayout'
import TrendDashboard from '@/components/trend/TrendDashboard'
import TopicDetail from '@/components/trend/TopicDetail'
import TrendFilters from '@/components/trend/TrendFilters'
import SavedItems from '@/components/trend/SavedItems'
import { TrendProvider } from '@/contexts/TrendContext'
import { useDashboard } from '@/contexts/DashboardContext'

const ProjectTrendAnalysisContent: React.FC<{ projectId: string }> = ({ projectId }) => {
  const router = useRouter()
  const { t } = useTranslation('common')
  const { state, setProject } = useDashboard()
  const [selectedTopic, setSelectedTopic] = useState<string | null>(null)
  const [showFilters, setShowFilters] = useState(false)
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

  if (isLoading) {
    return (
      <ProjectDetailLayout projectId={projectId}>
        <div className="flex items-center justify-center h-full">
          <div className="text-center">
            <div className="inline-block w-16 h-16 border-4 border-gray-900 dark:border-white border-t-transparent rounded-full animate-spin" />
            <p className="mt-4 text-gray-600 dark:text-gray-400">Loading trend analysis...</p>
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
      <div className="flex h-full">
        <div className="flex-1 flex flex-col overflow-hidden">
          {/* Header */}
          <div className="flex items-center justify-between p-6 border-b border-amber-300/60 dark:border-white/20">
            <div>
              <h1 className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-violet-600 bg-clip-text text-transparent">
                Trend Analysis
              </h1>
              <p className="text-gray-600 dark:text-gray-400 mt-1">
                Khám phá xu hướng nội dung theo thời gian thực
              </p>
            </div>

            <div className="flex items-center gap-3">
              <button
                onClick={() => setShowFilters(!showFilters)}
                className="flex items-center gap-2 px-4 py-2 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg font-semibold hover:bg-gray-800 dark:hover:bg-gray-100 transition-colors"
              >
                <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" />
                </svg>
                Filters
              </button>
            </div>
          </div>

          {/* Content */}
          <div className="flex-1 overflow-hidden">
            {selectedTopic ? (
              <TopicDetail
                topicId={selectedTopic}
                onBack={() => setSelectedTopic(null)}
              />
            ) : (
              <TrendDashboard onTopicSelect={setSelectedTopic} />
            )}
          </div>
        </div>

        {/* Filters Sidebar */}
        {showFilters && (
          <div className="w-80 border-l border-amber-300/60 dark:border-white/20 bg-white/40 dark:bg-gray-900/40">
            <TrendFilters onClose={() => setShowFilters(false)} />
          </div>
        )}
      </div>

      {/* Saved Items Modal */}
      <SavedItems />
    </ProjectDetailLayout>
  )
}

const ProjectTrendAnalysis: NextPage = () => {
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
    <TrendProvider>
      <ProjectTrendAnalysisContent projectId={project_id} />
    </TrendProvider>
  )
}

export async function getServerSideProps({ locale }: { locale: string }) {
  return {
    props: {
      ...(await serverSideTranslations(locale, ['common'])),
    },
  }
}

export default ProjectTrendAnalysis
