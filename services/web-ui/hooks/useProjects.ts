import { useState, useEffect } from 'react'
import { projectService, CreateProjectPayload } from '@/lib/api/services/project.service'
import { Project } from '@/contexts/DashboardContext'

interface UseProjectsReturn {
  projects: Project[]
  isLoading: boolean
  error: string | null
  refetch: () => Promise<void>
}

export const useProjects = (): UseProjectsReturn => {
  const [projects, setProjects] = useState<Project[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchProjects = async () => {
    setIsLoading(true)
    setError(null)

    try {
      const result = await projectService.getProjects()
      setProjects(result.projects)
    } catch (err: any) {
      setError(err?.message || 'Failed to load projects')
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchProjects()
  }, [])

  return {
    projects,
    isLoading,
    error,
    refetch: fetchProjects,
  }
}

interface UseCreateProjectReturn {
  createProject: (payload: CreateProjectPayload) => Promise<Project>
  isLoading: boolean
  error: string | null
  isSuccess: boolean
}

export const useCreateProject = (): UseCreateProjectReturn => {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isSuccess, setIsSuccess] = useState(false)

  const createProject = async (payload: CreateProjectPayload): Promise<Project> => {
    setIsLoading(true)
    setError(null)
    setIsSuccess(false)

    try {
      const newProject = await projectService.createProject(payload)
      setIsSuccess(true)
      return newProject
    } catch (err: any) {
      setError(err?.message || 'Failed to create project')
      throw err
    } finally {
      setIsLoading(false)
    }
  }

  return {
    createProject,
    isLoading,
    error,
    isSuccess,
  }
}

interface UseDeleteProjectReturn {
  deleteProject: (id: string) => Promise<void>
  isLoading: boolean
  error: string | null
}

export const useDeleteProject = (): UseDeleteProjectReturn => {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const deleteProject = async (id: string) => {
    setIsLoading(true)
    setError(null)

    try {
      await projectService.deleteProject(id)
    } catch (err: any) {
      setError(err?.message || 'Failed to delete project')
      throw err
    } finally {
      setIsLoading(false)
    }
  }

  return {
    deleteProject,
    isLoading,
    error,
  }
}
