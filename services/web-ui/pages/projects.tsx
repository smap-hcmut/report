import type { NextPage } from 'next'
import { useState, useEffect, useCallback } from 'react'
import { useTranslation } from 'next-i18next'
import { serverSideTranslations } from 'next-i18next/serverSideTranslations'
import { motion, AnimatePresence } from 'framer-motion'
import { useRouter } from 'next/router'
import {
  Plus,
  Search,
  FolderOpen,
  MoreVertical,
  Edit,
  Trash2,
  Eye,
  Calendar,
  Users,
  Target,
  AlertCircle,
  ChevronLeft,
  ChevronRight,
  Filter,
} from 'lucide-react'
import { Project, useDashboard } from '@/contexts/DashboardContext'
import ProjectSetupWizard from '@/components/dashboard/ProjectSetupWizard'
import { projectService } from '@/lib/api/services/project.service'
import Swal from 'sweetalert2'

// Hardcoded projects data - temporary until API is ready
const mockProjects: Project[] = [
  {
    id: '1',
    name: 'VinFast Automotive',
    description: 'Monitor VinFast brand performance and compare with automotive competitors',
    brands: [
      {
        id: 'b1',
        name: 'VinFast',
        type: 'own',
        keywords: ['vinfast', 'vf8', 'vf9', 'xe điện vinfast'],
        urls: ['https://vinfastauto.com'],
      },
    ],
    competitors: [
      {
        id: 'c1',
        name: 'Tesla',
        type: 'competitor',
        keywords: ['tesla', 'model 3', 'model y'],
        urls: ['https://tesla.com'],
      },
      {
        id: 'c2',
        name: 'Hyundai',
        type: 'competitor',
        keywords: ['hyundai', 'tucson', 'santa fe'],
        urls: ['https://hyundai.com'],
      },
    ],
    createdAt: new Date('2024-01-15'),
    status: 'completed',
  },
  {
    id: '2',
    name: 'Momo E-Wallet',
    description: 'Social media sentiment analysis for Momo payment platform',
    brands: [
      {
        id: 'b2',
        name: 'Momo',
        type: 'own',
        keywords: ['momo', 'ví momo', 'thanh toán momo'],
        urls: ['https://momo.vn'],
      },
    ],
    competitors: [
      {
        id: 'c3',
        name: 'ZaloPay',
        type: 'competitor',
        keywords: ['zalopay', 'ví zalopay'],
        urls: ['https://zalopay.vn'],
      },
      {
        id: 'c4',
        name: 'VNPay',
        type: 'competitor',
        keywords: ['vnpay', 'ví vnpay'],
        urls: ['https://vnpay.vn'],
      },
      {
        id: 'c5',
        name: 'ShopeePay',
        type: 'competitor',
        keywords: ['shopeepay', 'ví shopee'],
        urls: ['https://shopee.vn'],
      },
    ],
    createdAt: new Date('2024-02-20'),
    status: 'completed',
  },
  {
    id: '3',
    name: 'The Coffee House',
    description: 'Track customer feedback and competitor analysis in F&B sector',
    brands: [
      {
        id: 'b3',
        name: 'The Coffee House',
        type: 'own',
        keywords: ['the coffee house', 'tch', 'cà phê nhà'],
        urls: ['https://thecoffeehouse.com'],
      },
    ],
    competitors: [
      {
        id: 'c6',
        name: 'Highlands Coffee',
        type: 'competitor',
        keywords: ['highlands', 'highlands coffee'],
        urls: ['https://highlandscoffee.com.vn'],
      },
      {
        id: 'c7',
        name: 'Starbucks',
        type: 'competitor',
        keywords: ['starbucks', 'starbucks vietnam'],
        urls: ['https://starbucks.vn'],
      },
    ],
    createdAt: new Date('2024-03-10'),
    status: 'process',
  },
]

const ProjectsContent: React.FC = () => {
  const { t } = useTranslation('common')
  const router = useRouter()
  const { state, addProject: addProjectToContext, setProject } = useDashboard()

  const [projects, setProjects] = useState<Project[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [searchQuery, setSearchQuery] = useState('')
  const [searchInput, setSearchInput] = useState('') // For input field
  const [isWizardOpen, setIsWizardOpen] = useState(false)
  const [selectedProjectId, setSelectedProjectId] = useState<string | null>(null)

  // Pagination and filters state
  const [currentPage, setCurrentPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [statusFilter, setStatusFilter] = useState<'all' | 'completed' | 'process' | 'draft'>('all')
  const [totalProjects, setTotalProjects] = useState(0)
  const [totalPages, setTotalPages] = useState(0)

  // Debounce search
  useEffect(() => {
    const timer = setTimeout(() => {
      setSearchQuery(searchInput)
      setCurrentPage(1) // Reset to first page on search
    }, 500)

    return () => clearTimeout(timer)
  }, [searchInput])

  // Fetch projects from API with filters
  useEffect(() => {
    const fetchProjects = async () => {
      setIsLoading(true)
      setError(null)

      try {
        const result = await projectService.getProjects({
          search_name: searchQuery || undefined,
          statuses: statusFilter !== 'all' ? [statusFilter as any] : ['completed', 'process', 'draft'],
          page: currentPage,
          limit: pageSize
        })

        setProjects(result.projects)
        setTotalProjects(result.paginator.total)
        setTotalPages(Math.ceil(result.paginator.total / result.paginator.per_page))

        // Sync to context if needed
        result.projects.forEach(project => addProjectToContext(project))
      } catch (err: any) {
        console.error('Failed to fetch projects:', err)
        setError(err?.message || t('projects.fetchError'))

        // Fallback to mock data on error
        setProjects(mockProjects)
      } finally {
        setIsLoading(false)
      }
    }

    fetchProjects()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchQuery, statusFilter, currentPage, pageSize])

  // Use projects directly (already filtered by API)
  const filteredProjects = projects

  const handleCreateProject = async (projectData: any) => {
    // Note: API calls (createProject + executeProject) are already done in ProjectSetupWizard
    // This callback only updates local state after successful creation
    
    // Refresh projects list from server to get the newly created project
    try {
      const response = await projectService.getProjects()
      setProjects(response.projects || [])
      setIsWizardOpen(false)
    } catch (err: any) {
      console.error('Failed to refresh projects list:', err)
      // Still close wizard even if refresh fails
      setIsWizardOpen(false)
    }
  }

  const handleDeleteProject = async (id: string) => {
    const project = projects.find((p) => p.id === id)
    if (!project) return

    const result = await Swal.fire({
      title: t('projects.deleteConfirm.title'),
      html: `${t('projects.deleteConfirm.text')}<br><strong>${project.name}</strong>`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#dc2626',
      cancelButtonColor: '#6b7280',
      confirmButtonText: t('projects.deleteConfirm.confirm'),
      cancelButtonText: t('projects.deleteConfirm.cancel'),
      background: document.documentElement.classList.contains('dark') ? '#1f2937' : '#ffffff',
      color: document.documentElement.classList.contains('dark') ? '#ffffff' : '#000000',
    })

    if (!result.isConfirmed) return

    try {
      // Call API to delete project
      await projectService.deleteProject(id)

      // Update local state
      setProjects(projects.filter((p) => p.id !== id))
      setSelectedProjectId(null)

      // Success notification
      await Swal.fire({
        title: t('projects.deleteConfirm.success'),
        text: t('projects.deleteConfirm.successText'),
        icon: 'success',
        timer: 2000,
        showConfirmButton: false,
        background: document.documentElement.classList.contains('dark') ? '#1f2937' : '#ffffff',
        color: document.documentElement.classList.contains('dark') ? '#ffffff' : '#000000',
      })
    } catch (err: any) {
      console.error('Delete project error:', err)

      // Error notification
      await Swal.fire({
        title: t('projects.deleteConfirm.error'),
        text: err?.message || t('projects.deleteConfirm.errorText'),
        icon: 'error',
        confirmButtonColor: '#dc2626',
        background: document.documentElement.classList.contains('dark') ? '#1f2937' : '#ffffff',
        color: document.documentElement.classList.contains('dark') ? '#ffffff' : '#000000',
      })
    }
  }

  const handleViewProject = (id: string) => {
    const project = projects.find(p => p.id === id)
    
    if (!project) {
      Swal.fire({
        title: t('projects.error.notFound'),
        text: t('projects.error.notFoundText'),
        icon: 'error',
        confirmButtonColor: '#dc2626',
        background: document.documentElement.classList.contains('dark') ? '#1f2937' : '#ffffff',
        color: document.documentElement.classList.contains('dark') ? '#ffffff' : '#000000',
      })
      return
    }
    
    // Handle based on status
    switch (project.status) {
      case 'completed':
        setProject(id)
        router.push(`/projects/${id}/dashboard`)
        break

      case 'draft':
        Swal.fire({
          title: t('projects.draft.title'),
          text: t('projects.draft.message'),
          icon: 'warning',
          confirmButtonColor: '#6b7280',
          background: document.documentElement.classList.contains('dark') ? '#1f2937' : '#ffffff',
          color: document.documentElement.classList.contains('dark') ? '#ffffff' : '#000000',
        })
        break

      case 'process':
        setProject(id)
        router.push(`/projects/${id}/dashboard`)
        break

      default:
        Swal.fire({
          title: t('projects.error.invalidStatus'),
          text: t('projects.error.invalidStatusText'),
          icon: 'error',
          confirmButtonColor: '#dc2626',
          background: document.documentElement.classList.contains('dark') ? '#1f2937' : '#ffffff',
          color: document.documentElement.classList.contains('dark') ? '#ffffff' : '#000000',
        })
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-300'
      case 'draft':
        return 'bg-gray-100 text-gray-800 dark:bg-gray-800/40 dark:text-gray-300'
      case 'process':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900/40 dark:text-blue-300'
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-800/40 dark:text-gray-300'
    }
  }

  return (
    <div className="min-h-screen relative bg-amber-50 dark:bg-gray-950 overflow-hidden">
      {/* Background Effects */}
      <div className="fixed inset-0 pointer-events-none">
        {/* Sun Mode - Warm Glows */}
        <div className="absolute top-0 right-1/4 w-[600px] h-[600px] bg-yellow-100/60 rounded-full blur-[128px] dark:hidden" />
        <div className="absolute bottom-1/4 left-1/3 w-[500px] h-[500px] bg-amber-100/50 rounded-full blur-[128px] dark:hidden" />

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
            opacity: 0.4,
          }}
        />
        <div className="hidden dark:block absolute top-0 left-1/4 w-96 h-96 bg-white/5 rounded-full blur-[128px]" />
        <div className="hidden dark:block absolute bottom-1/3 right-1/4 w-[500px] h-[500px] bg-white/5 rounded-full blur-[128px]" />
      </div>

      <div className="relative z-10 min-h-screen px-4 py-8 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          {/* Header */}
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="mb-8"
          >
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
              <div>
                <h1 className="text-4xl font-black text-gray-900 dark:text-white mb-2">
                  {t('projects.title')}
                </h1>
                <p className="text-gray-600 dark:text-gray-400">
                  {t('projects.subtitle')}
                </p>
              </div>

              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => setIsWizardOpen(true)}
                className="flex items-center justify-center gap-2 px-6 py-3 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg font-semibold hover:bg-gray-800 dark:hover:bg-gray-100 transition-all shadow-lg"
              >
                <Plus className="w-5 h-5" />
                {t('projects.createNew')}
              </motion.button>
            </div>
          </motion.div>

          {/* Search Bar & Filters */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="mb-8 space-y-4"
          >
            <div className="flex flex-col sm:flex-row gap-4">
              <div className="relative flex-1 max-w-md">
                <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="text"
                  value={searchInput}
                  onChange={(e) => setSearchInput(e.target.value)}
                  placeholder={t('projects.searchPlaceholder')}
                  className="w-full pl-12 pr-4 py-3 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-gray-900 dark:focus:ring-white text-gray-900 dark:text-white"
                />
              </div>

              <div className="flex items-center gap-2">
                <Filter className="w-5 h-5 text-gray-600 dark:text-gray-400" />
                <select
                  value={statusFilter}
                  onChange={(e) => {
                    setStatusFilter(e.target.value as any)
                    setCurrentPage(1)
                  }}
                  className="px-4 py-3 bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-gray-900 dark:focus:ring-white text-gray-900 dark:text-white"
                >
                  <option value="all">All Status</option>
                  <option value="completed">Completed</option>
                  <option value="process">Processing</option>
                  <option value="draft">Draft</option>
                </select>
              </div>
            </div>

            {/* Results Info */}
            <div className="flex items-center justify-between text-sm text-gray-600 dark:text-gray-400">
              <p>
                Showing {projects.length} of {totalProjects} projects
              </p>
              <div className="flex items-center gap-2">
                <label>Per page:</label>
                <select
                  value={pageSize}
                  onChange={(e) => {
                    setPageSize(Number(e.target.value))
                    setCurrentPage(1)
                  }}
                  className="px-3 py-1 bg-white/60 dark:bg-gray-900/60 border border-amber-300/60 dark:border-white/20 rounded-lg"
                >
                  <option value={10}>10</option>
                  <option value={20}>20</option>
                  <option value={50}>50</option>
                </select>
              </div>
            </div>
          </motion.div>

          {/* Error State */}
          {error && (
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              className="mb-8 p-4 bg-red-100 dark:bg-red-900/40 border border-red-300 dark:border-red-700 rounded-lg flex items-start gap-3"
            >
              <AlertCircle className="w-5 h-5 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5" />
              <div>
                <h3 className="font-semibold text-red-800 dark:text-red-200 mb-1">
                  {t('projects.error')}
                </h3>
                <p className="text-sm text-red-700 dark:text-red-300">{error}</p>
              </div>
            </motion.div>
          )}

          {/* Loading State */}
          {isLoading && (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {[1, 2, 3].map((i) => (
                <div
                  key={i}
                  className="bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl p-6 animate-pulse"
                >
                  <div className="h-6 bg-gray-300 dark:bg-gray-700 rounded w-3/4 mb-4" />
                  <div className="h-4 bg-gray-200 dark:bg-gray-800 rounded w-full mb-2" />
                  <div className="h-4 bg-gray-200 dark:bg-gray-800 rounded w-2/3" />
                </div>
              ))}
            </div>
          )}

          {/* Empty State */}
          {!isLoading && filteredProjects.length === 0 && !error && (
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.5 }}
              className="text-center py-16"
            >
              <div className="inline-flex items-center justify-center w-20 h-20 bg-gray-100 dark:bg-gray-800 rounded-full mb-6">
                <FolderOpen className="w-10 h-10 text-gray-400" />
              </div>
              <h3 className="text-2xl font-black text-gray-900 dark:text-white mb-2">
                {searchQuery ? t('projects.noResults') : t('projects.noProjects')}
              </h3>
              <p className="text-gray-600 dark:text-gray-400 mb-6">
                {searchQuery
                  ? t('projects.noResultsDescription')
                  : t('projects.noProjectsDescription')}
              </p>
              {!searchQuery && (
                <button
                  onClick={() => setIsWizardOpen(true)}
                  className="inline-flex items-center gap-2 px-6 py-3 bg-gray-900 dark:bg-white text-white dark:text-gray-900 rounded-lg font-semibold hover:bg-gray-800 dark:hover:bg-gray-100 transition-all shadow-lg"
                >
                  <Plus className="w-5 h-5" />
                  {t('projects.createFirst')}
                </button>
              )}
            </motion.div>
          )}

          {/* Projects Grid */}
          {!isLoading && filteredProjects.length > 0 && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.5, delay: 0.2 }}
              className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
            >
              <AnimatePresence>
                {filteredProjects.map((project, index) => {
                  const isInactive = project.status === 'draft'
                  const isProcessing = project.status === 'process'
                  
                  return (
                    <motion.div
                      key={project.id}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, scale: 0.9 }}
                      transition={{ duration: 0.3, delay: index * 0.05 }}
                      whileHover={!isInactive ? { y: -5 } : {}}
                      className={`bg-white/60 dark:bg-gray-900/60 backdrop-blur-sm border border-amber-300/60 dark:border-white/20 rounded-2xl p-6 shadow-lg transition-all group relative ${
                        isInactive 
                          ? 'opacity-50 cursor-not-allowed' 
                          : 'hover:shadow-xl cursor-pointer'
                      }`}
                      onClick={() => handleViewProject(project.id)}
                    >
                      {/* Processing Animated Indicator */}
                      {isProcessing && (
                        <div className="absolute -top-1 -right-1 w-4 h-4">
                          <span className="absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75 animate-ping" />
                          <span className="relative inline-flex rounded-full h-4 w-4 bg-blue-500" />
                        </div>
                      )}
                      
                      {/* Project Header */}
                      <div className="flex items-start justify-between mb-4">
                        <div className="flex items-center gap-3">
                          <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                            isInactive 
                              ? 'bg-gray-300 dark:bg-gray-700' 
                              : 'bg-yellow-400 dark:bg-white'
                          }`}>
                            <FolderOpen className={`w-6 h-6 ${
                              isInactive ? 'text-gray-500 dark:text-gray-600' : 'text-gray-900'
                            }`} />
                          </div>
                          <div>
                            <h3 className={`text-lg font-black transition-colors ${
                              isInactive 
                                ? 'text-gray-500 dark:text-gray-600' 
                                : 'text-gray-900 dark:text-white group-hover:text-gray-700 dark:group-hover:text-gray-200'
                            }`}>
                              {project.name}
                            </h3>
                            <div className="flex items-center gap-2 mt-1">
                              <span
                                className={`text-xs px-2 py-1 rounded-full font-semibold ${getStatusColor(
                                  project.status
                                )}`}
                              >
                                {t(`projects.status.${project.status}`)}
                              </span>
                              {isProcessing && (
                                <span className="text-xs text-blue-600 dark:text-blue-400 animate-pulse">
                                  ●
                                </span>
                              )}
                            </div>
                          </div>
                        </div>

                        {/* Actions Menu */}
                        <button
                          onClick={(e) => {
                            e.stopPropagation()
                            setSelectedProjectId(
                              selectedProjectId === project.id ? null : project.id
                            )
                          }}
                          className={`p-2 rounded-lg transition-colors ${
                            isInactive 
                              ? 'text-gray-400 dark:text-gray-600' 
                              : 'hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-600 dark:text-gray-400'
                          }`}
                        >
                          <MoreVertical className="w-5 h-5" />
                        </button>

                      {/* Actions Dropdown */}
                      <AnimatePresence>
                        {selectedProjectId === project.id && (
                          <motion.div
                            initial={{ opacity: 0, scale: 0.9 }}
                            animate={{ opacity: 1, scale: 1 }}
                            exit={{ opacity: 0, scale: 0.9 }}
                            onClick={(e) => e.stopPropagation()}
                            className="absolute right-6 mt-10 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-xl z-10 overflow-hidden"
                          >
                            <button
                              onClick={() => handleViewProject(project.id)}
                              className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 w-full text-left"
                            >
                              <Eye className="w-4 h-4" />
                              {t('projects.actions.view')}
                            </button>
                            <button
                              onClick={() => handleDeleteProject(project.id)}
                              className="flex items-center gap-2 px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 w-full text-left"
                            >
                              <Trash2 className="w-4 h-4" />
                              {t('projects.actions.delete')}
                            </button>
                          </motion.div>
                        )}
                      </AnimatePresence>
                    </div>

                      {/* Project Description */}
                      <p className={`text-sm mb-4 line-clamp-2 ${
                        isInactive 
                          ? 'text-gray-400 dark:text-gray-600' 
                          : 'text-gray-600 dark:text-gray-400'
                      }`}>
                        {project.description || t('projects.noDescription')}
                      </p>

                      {/* Project Stats */}
                      <div className="grid grid-cols-2 gap-4">
                        <div className="flex items-center gap-2">
                          <div className={`p-2 rounded-lg ${
                            isInactive 
                              ? 'bg-gray-200 dark:bg-gray-800' 
                              : 'bg-blue-100 dark:bg-blue-900/40'
                          }`}>
                            <Target className={`w-4 h-4 ${
                              isInactive 
                                ? 'text-gray-400 dark:text-gray-600' 
                                : 'text-blue-600 dark:text-blue-400'
                            }`} />
                          </div>
                          <div>
                            <p className={`text-xs ${
                              isInactive 
                                ? 'text-gray-400 dark:text-gray-600' 
                                : 'text-gray-600 dark:text-gray-400'
                            }`}>
                              {t('projects.brands')}
                            </p>
                            <p className={`text-sm font-bold ${
                              isInactive 
                                ? 'text-gray-500 dark:text-gray-600' 
                                : 'text-gray-900 dark:text-white'
                            }`}>
                              {project.brands.length}
                            </p>
                          </div>
                        </div>

                        <div className="flex items-center gap-2">
                          <div className={`p-2 rounded-lg ${
                            isInactive 
                              ? 'bg-gray-200 dark:bg-gray-800' 
                              : 'bg-purple-100 dark:bg-purple-900/40'
                          }`}>
                            <Users className={`w-4 h-4 ${
                              isInactive 
                                ? 'text-gray-400 dark:text-gray-600' 
                                : 'text-purple-600 dark:text-purple-400'
                            }`} />
                          </div>
                          <div>
                            <p className={`text-xs ${
                              isInactive 
                                ? 'text-gray-400 dark:text-gray-600' 
                                : 'text-gray-600 dark:text-gray-400'
                            }`}>
                              {t('projects.competitors')}
                            </p>
                            <p className={`text-sm font-bold ${
                              isInactive 
                                ? 'text-gray-500 dark:text-gray-600' 
                                : 'text-gray-900 dark:text-white'
                            }`}>
                              {project.competitors.length}
                            </p>
                          </div>
                        </div>
                      </div>

                      {/* Created Date */}
                      <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                        <div className={`flex items-center gap-2 text-xs ${
                          isInactive 
                            ? 'text-gray-400 dark:text-gray-600' 
                            : 'text-gray-500 dark:text-gray-400'
                        }`}>
                          <Calendar className="w-4 h-4" />
                          {t('projects.created')}{' '}
                          {new Date(project.createdAt).toLocaleDateString()}
                        </div>
                      </div>
                    </motion.div>
                  )
                })}
              </AnimatePresence>
            </motion.div>
          )}
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.3 }}
            className="flex items-center justify-center gap-2 mt-8"
          >
            <button
              onClick={() => setCurrentPage(prev => Math.max(prev - 1, 1))}
              disabled={currentPage === 1}
              className="p-2 rounded-lg border border-amber-300/60 dark:border-white/20 bg-white/60 dark:bg-gray-900/60 hover:bg-white/80 dark:hover:bg-gray-900/80 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronLeft className="w-5 h-5" />
            </button>

            <div className="flex items-center gap-1">
              {Array.from({ length: Math.min(totalPages, 7) }, (_, i) => {
                let pageNum: number

                if (totalPages <= 7) {
                  pageNum = i + 1
                } else if (currentPage <= 4) {
                  pageNum = i + 1
                } else if (currentPage >= totalPages - 3) {
                  pageNum = totalPages - 6 + i
                } else {
                  pageNum = currentPage - 3 + i
                }

                return (
                  <button
                    key={i}
                    onClick={() => setCurrentPage(pageNum)}
                    className={`w-10 h-10 rounded-lg border transition-colors ${
                      currentPage === pageNum
                        ? 'bg-gray-900 dark:bg-white text-white dark:text-gray-900 border-gray-900 dark:border-white'
                        : 'border-amber-300/60 dark:border-white/20 bg-white/60 dark:bg-gray-900/60 hover:bg-white/80 dark:hover:bg-gray-900/80'
                    }`}
                  >
                    {pageNum}
                  </button>
                )
              })}
            </div>

            <button
              onClick={() => setCurrentPage(prev => Math.min(prev + 1, totalPages))}
              disabled={currentPage === totalPages}
              className="p-2 rounded-lg border border-amber-300/60 dark:border-white/20 bg-white/60 dark:bg-gray-900/60 hover:bg-white/80 dark:hover:bg-gray-900/80 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronRight className="w-5 h-5" />
            </button>
          </motion.div>
        )}
      </div>

      {/* Project Setup Wizard */}
      <ProjectSetupWizard
        isOpen={isWizardOpen}
        onClose={() => setIsWizardOpen(false)}
        onComplete={handleCreateProject}
      />
    </div>
  )
}

const Projects: NextPage = () => {
  return (
    <ProjectsContent />
  )
}

export async function getStaticProps({ locale }: { locale: string }) {
  return {
    props: {
      ...(await serverSideTranslations(locale, ['common'])),
    },
  }
}

export default Projects
