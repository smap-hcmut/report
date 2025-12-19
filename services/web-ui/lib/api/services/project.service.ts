import apiClient from '../config'
import { Project, Brand } from '@/contexts/DashboardContext'

// Backend API response interface
interface ApiProject {
  id: string
  name: string
  description: string
  brand_name: string
  brand_keywords: string[]
  competitors: Array<{
    name: string
    keywords: string[]
  }>
  status: string
  from_date: string
  to_date: string
  created_at: string
  updated_at: string
  created_by: string
}

// Backend API request payload for creating project
interface CreateProjectApiPayload {
  name: string
  description: string
  brand_name: string
  brand_keywords: string[]
  competitors: Array<{
    name: string
    keywords: string[]
  }>
  from_date: string
  to_date: string
}

// Frontend payload interface
export interface CreateProjectPayload {
  name: string
  description: string
  brands: Omit<Brand, 'id'>[]
  competitors: Omit<Brand, 'id'>[]
  fromDate?: string
  toDate?: string
  status?: 'active' | 'inactive' | 'processing'
}

interface UpdateProjectPayload extends Partial<CreateProjectPayload> {
  id: string
}

interface ProjectResponse {
  data: Project
  message?: string
}

interface ProjectsListResponse {
  error_code: number
  message: string
  data: {
    projects: ApiProject[]
    paginator: {
      total: number
      count: number
      per_page: number
      current_page: number
    }
  }
}

export interface GetProjectsParams {
  statuses?: Array<'completed' | 'process' | 'draft'>
  search_name?: string
  page?: number
  limit?: number
}

// Transform API response to frontend Project format
const transformApiProject = (apiProject: ApiProject): Project => {
  // Transform brand
  const brand: Brand = {
    id: 'b1',
    name: apiProject.brand_name,
    type: 'own',
    keywords: apiProject.brand_keywords || [],
    urls: [],
  }

  // Transform competitors
  const competitors: Brand[] = (apiProject.competitors || []).map((competitor, index) => ({
    id: `c${index + 1}`,
    name: competitor.name,
    type: 'competitor' as const,
    keywords: competitor.keywords || [],
    urls: [],
  }))

  // Map API status to Project status
  const mapStatus = (apiStatus: string): 'completed' | 'draft' | 'process' => {
    switch (apiStatus) {
      case 'completed':
        return 'completed'
      case 'process':
        return 'process'
      case 'draft':
        return 'draft'
      default:
        console.warn(`Unknown API status: ${apiStatus}, defaulting to draft`)
        return 'draft'
    }
  }

  return {
    id: apiProject.id,
    name: apiProject.name,
    description: apiProject.description,
    brands: [brand],
    competitors,
    createdAt: new Date(apiProject.created_at),
    status: mapStatus(apiProject.status),
  }
}

// Helper function to format date to "YYYY-MM-DD HH:mm:ss"
const formatDateToBackend = (dateString: string): string => {
  const date = new Date(dateString)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  const seconds = String(date.getSeconds()).padStart(2, '0')

  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`
}

// Transform frontend payload to backend API format
const transformToApiPayload = (payload: CreateProjectPayload): CreateProjectApiPayload => {
  // Get the first brand (assuming single brand per project)
  const brand = payload.brands[0]

  // Transform competitors to backend format
  const competitors = payload.competitors.map((competitor) => ({
    name: competitor.name,
    keywords: competitor.keywords,
  }))

  return {
    name: payload.name,
    description: payload.description,
    brand_name: brand.name,
    brand_keywords: brand.keywords,
    competitors,
    from_date: payload.fromDate ? formatDateToBackend(payload.fromDate) : formatDateToBackend(new Date().toISOString()),
    to_date: payload.toDate ? formatDateToBackend(payload.toDate) : formatDateToBackend(new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString()),
  }
}

export const projectService = {
  // Get all projects with pagination and filters
  getProjects: async (params?: GetProjectsParams): Promise<{
    projects: Project[]
    paginator: {
      total: number
      count: number
      per_page: number
      current_page: number
    }
  }> => {
    // Build query string
    const queryParams = new URLSearchParams()

    if (params?.statuses && params.statuses.length > 0) {
      params.statuses.forEach(status => queryParams.append('statuses', status))
    }

    if (params?.search_name) {
      queryParams.append('search_name', params.search_name)
    }

    if (params?.page) {
      queryParams.append('page', params.page.toString())
    }

    if (params?.limit) {
      queryParams.append('limit', params.limit.toString())
    }

    const queryString = queryParams.toString()
    const url = `/project/projects${queryString ? `?${queryString}` : ''}`

    const response = await apiClient.get<ProjectsListResponse>(url)

    return {
      projects: response.data.data.projects.map(transformApiProject),
      paginator: response.data.data.paginator
    }
  },

  // Get single project by ID
  getProject: async (id: string): Promise<ProjectResponse> => {
    const response = await apiClient.get<ProjectResponse>(`/projects/${id}`)
    return response.data
  },

  // Create new project
  createProject: async (payload: CreateProjectPayload): Promise<Project> => {
    const apiPayload = transformToApiPayload(payload)
    const response = await apiClient.post<{ data: ApiProject }>('/project/projects', apiPayload)
    const apiProject = response.data.data || response.data
    return transformApiProject(apiProject as ApiProject)
  },

  // Update existing project
  updateProject: async (payload: UpdateProjectPayload): Promise<ProjectResponse> => {
    const { id, ...data } = payload
    const response = await apiClient.put<ProjectResponse>(`/projects/${id}`, data)
    return response.data
  },

  // Delete project(s)
  deleteProjects: async (ids: string[]): Promise<{ message: string }> => {
    const response = await apiClient.delete<{ message: string }>('/project/projects', {
      data: { ids }
    })
    return response.data
  },

  // Delete single project (convenience method)
  deleteProject: async (id: string): Promise<{ message: string }> => {
    return projectService.deleteProjects([id])
  },

  // Update project status
  updateProjectStatus: async (
    id: string,
    status: 'active' | 'inactive' | 'processing'
  ): Promise<ProjectResponse> => {
    const response = await apiClient.patch<ProjectResponse>(`/projects/${id}/status`, {
      status,
    })
    return response.data
  },

  // Execute project
  executeProject: async (id: string): Promise<{ message: string; status: string }> => {
    const response = await apiClient.post<{ message: string; status: string }>(
      `/project/projects/${id}/execute`
    )
    return response.data
  },

  // Create dry-run (trigger keyword preview)
  createDryRun: async (keywords: string[]): Promise<{ job_id: string; status: string; message: string }> => {
    try {
      const response = await apiClient.post<{
        error_code: number
        message: string
        data: {
          job_id: string
          status: string
          message: string
        }
      }>('/project/projects/dryrun', {
        keywords
      })

      if (response.data.error_code !== 0) {
        throw new Error(response.data.message || 'Failed to create dry-run')
      }

      return response.data.data
    } catch (error: any) {
      // Extract error details from response
      const errorMessage = error.response?.data?.message || error.message || 'Failed to create dry-run'
      const errorCode = error.response?.data?.error_code || error.response?.status || 500

      console.error('Dry-run API error:', {
        errorCode,
        errorMessage,
        responseData: error.response?.data,
        keywords
      })

      throw {
        error_code: errorCode,
        message: errorMessage,
        status: error.response?.status,
        statusText: error.response?.statusText || ''
      }
    }
  },
}
