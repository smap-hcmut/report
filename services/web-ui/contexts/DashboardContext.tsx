import React, { createContext, useContext, useReducer, useEffect, ReactNode } from 'react'
import { useRealTimeData, RealTimeData } from '@/hooks/useRealTimeData'
import { useProjectWebSocket } from '@/hooks/useProjectWebSocket'

export interface Project {
  id: string
  name: string
  description: string
  brands: Brand[]
  competitors: Brand[]
  createdAt: Date
  status: 'completed' | 'draft' | 'process'
}

export interface Brand {
  id: string
  name: string
  type: 'own' | 'competitor'
  keywords: string[]
  urls: string[]
}

export interface DashboardState {
  projects: Project[]
  selectedProject: string | null
  timeRange: string
  filters: {
    platform: string[]
    sentiment: string[]
    dateRange: {
      start: Date | null
      end: Date | null
    }
  }
  viewMode: 'grid' | 'list'
  sidebarCollapsed: boolean
  selectedMetrics: string[]
  realTimeData: RealTimeData | null
  isRealTimeEnabled: boolean
  lastUpdate: Date | null
  error: string | null
  showEmptyState: boolean
  selectedTopic: any | null
}

export type DashboardAction =
  | { type: 'SET_PROJECT'; payload: string | null }
  | { type: 'ADD_PROJECT'; payload: Project }
  | { type: 'UPDATE_PROJECT'; payload: Project }
  | { type: 'DELETE_PROJECT'; payload: string }
  | { type: 'SET_TIME_RANGE'; payload: string }
  | { type: 'SET_FILTERS'; payload: Partial<DashboardState['filters']> }
  | { type: 'SET_VIEW_MODE'; payload: 'grid' | 'list' }
  | { type: 'TOGGLE_SIDEBAR' }
  | { type: 'SET_SELECTED_METRICS'; payload: string[] }
  | { type: 'SET_REAL_TIME_DATA'; payload: RealTimeData }
  | { type: 'TOGGLE_REAL_TIME' }
  | { type: 'SET_LAST_UPDATE'; payload: Date }
  | { type: 'SET_ERROR'; payload: string | null }
  | { type: 'RESET_FILTERS' }
  | { type: 'SET_SHOW_EMPTY_STATE'; payload: boolean }
  | { type: 'SET_SELECTED_TOPIC'; payload: any | null }

const mockProjects: Project[] = [
  {
    id: 'project_1',
    name: 'Tech Startup Analysis',
    description: 'Analyzing tech startup trends and competitor landscape',
    brands: [
      { id: 'brand_1', name: 'Our Startup', type: 'own', keywords: ['tech', 'startup', 'innovation'], urls: ['https://ourstartup.com'] }
    ],
    competitors: [
      { id: 'comp_1', name: 'Competitor A', type: 'competitor', keywords: ['tech', 'startup'], urls: ['https://competitor-a.com'] },
      { id: 'comp_2', name: 'Competitor B', type: 'competitor', keywords: ['innovation', 'tech'], urls: ['https://competitor-b.com'] }
    ],
    createdAt: new Date('2024-01-15'),
    status: 'completed'
  },
  {
    id: 'project_2',
    name: 'E-commerce Brand Tracking',
    description: 'Monitoring e-commerce brand performance and market share',
    brands: [
      { id: 'brand_2', name: 'Our Store', type: 'own', keywords: ['ecommerce', 'shopping', 'retail'], urls: ['https://ourstore.com'] }
    ],
    competitors: [
      { id: 'comp_3', name: 'Big Retailer', type: 'competitor', keywords: ['ecommerce', 'retail'], urls: ['https://bigretailer.com'] },
      { id: 'comp_4', name: 'Online Market', type: 'competitor', keywords: ['shopping', 'online'], urls: ['https://onlinemarket.com'] }
    ],
    createdAt: new Date('2024-02-01'),
    status: 'completed'
  }
]

const initialState: DashboardState = {
  projects: mockProjects,
  selectedProject: null,
  timeRange: '7d',
  filters: {
    platform: [],
    sentiment: [],
    dateRange: {
      start: null,
      end: null
    }
  },
  viewMode: 'grid',
  sidebarCollapsed: false,
  selectedMetrics: ['sov', 'sentiment', 'mentions', 'engagement'],
  realTimeData: null,
  isRealTimeEnabled: true,
  lastUpdate: null,
  error: null,
  showEmptyState: true,
  selectedTopic: null
}

function dashboardReducer(state: DashboardState, action: DashboardAction): DashboardState {
  switch (action.type) {
    case 'SET_PROJECT':
      return {
        ...state,
        selectedProject: action.payload,
        showEmptyState: action.payload === null || state.projects.length === 0
      }

    case 'ADD_PROJECT':
      return {
        ...state,
        projects: [...state.projects, action.payload],
        selectedProject: action.payload.id,
        showEmptyState: false
      }

    case 'UPDATE_PROJECT':
      return {
        ...state,
        projects: state.projects.map(project =>
          project.id === action.payload.id ? action.payload : project
        )
      }

    case 'DELETE_PROJECT':
      const remainingProjects = state.projects.filter(p => p.id !== action.payload)
      return {
        ...state,
        projects: remainingProjects,
        selectedProject: remainingProjects.length > 0 ? remainingProjects[0].id : null,
        showEmptyState: remainingProjects.length === 0
      }

    case 'SET_TIME_RANGE':
      return { ...state, timeRange: action.payload }

    case 'SET_FILTERS':
      return {
        ...state,
        filters: { ...state.filters, ...action.payload }
      }

    case 'SET_VIEW_MODE':
      return { ...state, viewMode: action.payload }

    case 'TOGGLE_SIDEBAR':
      return { ...state, sidebarCollapsed: !state.sidebarCollapsed }

    case 'SET_SELECTED_METRICS':
      return { ...state, selectedMetrics: action.payload }

    case 'SET_REAL_TIME_DATA':
      return { ...state, realTimeData: action.payload }

    case 'TOGGLE_REAL_TIME':
      return { ...state, isRealTimeEnabled: !state.isRealTimeEnabled }

    case 'SET_LAST_UPDATE':
      return { ...state, lastUpdate: action.payload }

    case 'SET_ERROR':
      return { ...state, error: action.payload }

    case 'RESET_FILTERS':
      return {
        ...state,
        filters: initialState.filters
      }

    case 'SET_SHOW_EMPTY_STATE':
      return { ...state, showEmptyState: action.payload }

    case 'SET_SELECTED_TOPIC':
      return { ...state, selectedTopic: action.payload }

    default:
      return state
  }
}

interface DashboardContextType {
  state: DashboardState
  dispatch: React.Dispatch<DashboardAction>

  filteredData: RealTimeData | null
  isLoading: boolean
  currentProject: Project | null

  setProject: (projectId: string | null) => void
  addProject: (project: Project) => void
  updateProject: (project: Project) => void
  deleteProject: (projectId: string) => void
  setTimeRange: (range: string) => void
  setFilters: (filters: Partial<DashboardState['filters']>) => void
  toggleSidebar: () => void
  toggleRealTime: () => void
  resetFilters: () => void
  setSelectedTopic: (topic: any | null) => void
}

const DashboardContext = createContext<DashboardContextType | undefined>(undefined)

interface DashboardProviderProps {
  children: ReactNode
}

export function DashboardProvider({ children }: DashboardProviderProps) {
  const [state, dispatch] = useReducer(dashboardReducer, initialState)

  // Project-specific WebSocket connection (only when ?project={id} exists)
  const { isConnected: wsConnected, error: wsError } = useProjectWebSocket({
    onMessage: (message) => {
      console.log('[Dashboard] Received WebSocket message:', message)
      // Handle project-specific WebSocket messages here
      // You can dispatch actions based on message type
    },
    onConnect: () => {
      console.log('[Dashboard] WebSocket connected to project')
    },
    onDisconnect: () => {
      console.log('[Dashboard] WebSocket disconnected from project')
    },
    onError: (error) => {
      console.error('[Dashboard] WebSocket error:', error)
    }
  })

  const {
    data: realTimeData,
    isConnected,
    isConnecting,
    error: realTimeError,
    lastUpdate,
    refresh
  } = useRealTimeData({
    projectId: state.selectedProject || 'demo',
    interval: state.isRealTimeEnabled ? 5000 : 0,
    autoConnect: state.isRealTimeEnabled && state.selectedProject !== null
  })

  useEffect(() => {
    if (realTimeData) {
      dispatch({ type: 'SET_REAL_TIME_DATA', payload: realTimeData })
    }
  }, [realTimeData])

  useEffect(() => {
    if (lastUpdate) {
      dispatch({ type: 'SET_LAST_UPDATE', payload: lastUpdate })
    }
  }, [lastUpdate])

  useEffect(() => {
    if (realTimeError) {
      dispatch({ type: 'SET_ERROR', payload: realTimeError })
    }
  }, [realTimeError])

  const filteredData = React.useMemo(() => {
    if (!state.realTimeData) return null

    let filtered = { ...state.realTimeData }

    if (state.filters.platform.length > 0) {
      filtered.content = filtered.content.filter(item =>
        state.filters.platform.includes(item.platform)
      )
    }

    if (state.filters.sentiment.length > 0) {
      filtered.sentiment = filtered.sentiment.filter(item =>
        state.filters.sentiment.includes(item.name.toLowerCase())
      )
    }

    if (state.filters.dateRange.start && state.filters.dateRange.end) {
      filtered.trends = filtered.trends.filter(item => {
        const itemDate = new Date(item.date)
        return itemDate >= state.filters.dateRange.start! &&
               itemDate <= state.filters.dateRange.end!
      })
    }

    return filtered
  }, [state.realTimeData, state.filters])

  const isLoading = isConnecting || !state.realTimeData
  const currentProject = state.projects.find(p => p.id === state.selectedProject) || null

  const setProject = (projectId: string | null) => {
    dispatch({ type: 'SET_PROJECT', payload: projectId })
  }

  const addProject = (project: Project) => {
    dispatch({ type: 'ADD_PROJECT', payload: project })
  }

  const updateProject = (project: Project) => {
    dispatch({ type: 'UPDATE_PROJECT', payload: project })
  }

  const deleteProject = (projectId: string) => {
    dispatch({ type: 'DELETE_PROJECT', payload: projectId })
  }

  const setTimeRange = (range: string) => {
    dispatch({ type: 'SET_TIME_RANGE', payload: range })
  }

  const setFilters = (filters: Partial<DashboardState['filters']>) => {
    dispatch({ type: 'SET_FILTERS', payload: filters })
  }

  const toggleSidebar = () => {
    dispatch({ type: 'TOGGLE_SIDEBAR' })
  }

  const toggleRealTime = () => {
    dispatch({ type: 'TOGGLE_REAL_TIME' })
  }

  const resetFilters = () => {
    dispatch({ type: 'RESET_FILTERS' })
  }

  const setSelectedTopic = (topic: any | null) => {
    dispatch({ type: 'SET_SELECTED_TOPIC', payload: topic })
  }

  const contextValue: DashboardContextType = {
    state,
    dispatch,
    filteredData,
    isLoading,
    currentProject,
    setProject,
    addProject,
    updateProject,
    deleteProject,
    setTimeRange,
    setFilters,
    toggleSidebar,
    toggleRealTime,
    resetFilters,
    setSelectedTopic
  }

  return (
    <DashboardContext.Provider value={contextValue}>
      {children}
    </DashboardContext.Provider>
  )
}

export function useDashboard() {
  const context = useContext(DashboardContext)
  if (context === undefined) {
    throw new Error('useDashboard must be used within a DashboardProvider')
  }
  return context
}
