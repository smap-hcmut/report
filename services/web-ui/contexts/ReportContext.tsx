import React, { createContext, useContext, useReducer, useEffect, ReactNode } from 'react'

export interface ReportTemplate {
  id: string
  name: string
  description: string
  category: 'performance' | 'trend' | 'competitor' | 'custom'
  sections: ReportSection[]
  estimatedTime: number
  icon: string
  color: string
}

export interface ReportSection {
  id: string
  title: string
  type: 'chart' | 'table' | 'metric' | 'text'
  dataSource: string
  config: any
  required: boolean
}

export interface ReportConfig {
  templateId: string
  timeRange: {
    start: Date
    end: Date
  }
  dataSources: string[]
  sections: string[]
  customizations: {
    includeCharts: boolean
    includeTables: boolean
    includeMetrics: boolean
    includeInsights: boolean
    branding: {
      logo?: string
      companyName?: string
      colors?: string[]
    }
  }
  outputFormat: 'pdf' | 'excel' | 'powerpoint'
  language: 'vi' | 'en'
}

export interface GeneratedReport {
  id: string
  name: string
  config: ReportConfig
  status: 'generating' | 'completed' | 'failed'
  progress: number
  downloadUrl?: string
  createdAt: Date
  completedAt?: Date
  error?: string
  fileSize?: number
  pageCount?: number
}

export interface ReportState {
  templates: ReportTemplate[]
  selectedTemplate: ReportTemplate | null
  config: ReportConfig | null
  generatedReports: GeneratedReport[]
  isLoading: boolean
  error: string | null
  currentStep: number
  totalSteps: number
}

export type ReportAction =
  | { type: 'SET_TEMPLATES'; payload: ReportTemplate[] }
  | { type: 'SET_SELECTED_TEMPLATE'; payload: ReportTemplate | null }
  | { type: 'SET_CONFIG'; payload: ReportConfig }
  | { type: 'UPDATE_CONFIG'; payload: Partial<ReportConfig> }
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_ERROR'; payload: string | null }
  | { type: 'SET_STEP'; payload: number }
  | { type: 'ADD_GENERATED_REPORT'; payload: GeneratedReport }
  | { type: 'UPDATE_REPORT_STATUS'; payload: { id: string; status: string; progress?: number; downloadUrl?: string; error?: string; fileSize?: number; pageCount?: number } }
  | { type: 'RESET_WIZARD' }

const initialState: ReportState = {
  templates: [],
  selectedTemplate: null,
  config: null,
  generatedReports: [],
  isLoading: false,
  error: null,
  currentStep: 1,
  totalSteps: 4
}

function reportReducer(state: ReportState, action: ReportAction): ReportState {
  switch (action.type) {
    case 'SET_TEMPLATES':
      return { ...state, templates: action.payload }

    case 'SET_SELECTED_TEMPLATE':
      return { ...state, selectedTemplate: action.payload }

    case 'SET_CONFIG':
      return { ...state, config: action.payload }

    case 'UPDATE_CONFIG':
      return {
        ...state,
        config: state.config ? { ...state.config, ...action.payload } : null
      }

    case 'SET_LOADING':
      return { ...state, isLoading: action.payload }

    case 'SET_ERROR':
      return { ...state, error: action.payload }

    case 'SET_STEP':
      return { ...state, currentStep: action.payload }

    case 'ADD_GENERATED_REPORT':
      return {
        ...state,
        generatedReports: [action.payload, ...state.generatedReports]
      }

    case 'UPDATE_REPORT_STATUS':
      return {
        ...state,
        generatedReports: state.generatedReports.map(report =>
          report.id === action.payload.id
            ? {
                ...report,
                status: action.payload.status as any,
                progress: action.payload.progress ?? report.progress,
                downloadUrl: action.payload.downloadUrl ?? report.downloadUrl,
                error: action.payload.error ?? report.error,
                completedAt: action.payload.status === 'completed' ? new Date() : report.completedAt
              }
            : report
        )
      }

    case 'RESET_WIZARD':
      return {
        ...state,
        selectedTemplate: null,
        config: null,
        currentStep: 1,
        error: null
      }

    default:
      return state
  }
}

interface ReportContextType {
  state: ReportState
  dispatch: React.Dispatch<ReportAction>

  selectTemplate: (template: ReportTemplate) => void
  updateConfig: (config: Partial<ReportConfig>) => void
  setStep: (step: number) => void
  generateReport: (config: ReportConfig) => Promise<GeneratedReport>
  downloadReport: (reportId: string) => void
  resetWizard: () => void
}

const ReportContext = createContext<ReportContextType | undefined>(undefined)

interface ReportProviderProps {
  children: ReactNode
}

export function ReportProvider({ children }: ReportProviderProps) {
  const [state, dispatch] = useReducer(reportReducer, initialState)

  const generateMockTemplates = (): ReportTemplate[] => [
    {
      id: 'performance-summary',
      name: 'Performance Summary',
      description: 'Overall performance overview with key metrics',
      category: 'performance',
      sections: [
        { id: 'metrics', title: 'Key Metrics', type: 'metric', dataSource: 'dashboard', config: {}, required: true },
        { id: 'trends', title: 'Trend Analysis', type: 'chart', dataSource: 'trends', config: {}, required: true },
        { id: 'top-content', title: 'Top Performing Content', type: 'table', dataSource: 'content', config: {}, required: false }
      ],
      estimatedTime: 2,
      icon: '📊',
      color: 'blue'
    },
    {
      id: 'trend-analysis',
      name: 'Trend Analysis Report',
      description: 'Trend analysis and insights from social media data',
      category: 'trend',
      sections: [
        { id: 'trending-topics', title: 'Trending Topics', type: 'chart', dataSource: 'trends', config: {}, required: true },
        { id: 'hashtag-analysis', title: 'Hashtag Performance', type: 'table', dataSource: 'hashtags', config: {}, required: true },
        { id: 'sentiment-analysis', title: 'Sentiment Analysis', type: 'chart', dataSource: 'sentiment', config: {}, required: true }
      ],
      estimatedTime: 3,
      icon: '📈',
      color: 'green'
    },
    {
      id: 'competitor-comparison',
      name: 'Competitor Comparison',
      description: 'Performance comparison with competitors',
      category: 'competitor',
      sections: [
        { id: 'sov-comparison', title: 'Share of Voice', type: 'chart', dataSource: 'competitors', config: {}, required: true },
        { id: 'sentiment-comparison', title: 'Sentiment Comparison', type: 'chart', dataSource: 'competitors', config: {}, required: true },
        { id: 'content-analysis', title: 'Content Analysis', type: 'table', dataSource: 'competitors', config: {}, required: false }
      ],
      estimatedTime: 4,
      icon: '🏆',
      color: 'purple'
    },
    {
      id: 'custom-report',
      name: 'Custom Report',
      description: 'Create custom report with selected sections',
      category: 'custom',
      sections: [
        { id: 'custom-metrics', title: 'Custom Metrics', type: 'metric', dataSource: 'custom', config: {}, required: false },
        { id: 'custom-charts', title: 'Custom Charts', type: 'chart', dataSource: 'custom', config: {}, required: false },
        { id: 'custom-tables', title: 'Custom Tables', type: 'table', dataSource: 'custom', config: {}, required: false }
      ],
      estimatedTime: 5,
      icon: '⚙️',
      color: 'orange'
    }
  ]

  useEffect(() => {
    dispatch({ type: 'SET_TEMPLATES', payload: generateMockTemplates() })
  }, [])

  const selectTemplate = (template: ReportTemplate) => {
    dispatch({ type: 'SET_SELECTED_TEMPLATE', payload: template })

    const defaultConfig: ReportConfig = {
      templateId: template.id,
      timeRange: {
        start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        end: new Date()
      },
      dataSources: ['facebook', 'instagram', 'tiktok'],
      sections: template.sections.filter(s => s.required).map(s => s.id),
      customizations: {
        includeCharts: true,
        includeTables: true,
        includeMetrics: true,
        includeInsights: true,
        branding: {
          companyName: 'Your Company',
          colors: ['#3b82f6', '#10b981', '#f59e0b']
        }
      },
      outputFormat: 'pdf',
      language: 'vi'
    }

    dispatch({ type: 'SET_CONFIG', payload: defaultConfig })
  }

  const updateConfig = (config: Partial<ReportConfig>) => {
    dispatch({ type: 'UPDATE_CONFIG', payload: config })
  }

  const setStep = (step: number) => {
    dispatch({ type: 'SET_STEP', payload: step })
  }

  const generateReport = async (config: ReportConfig): Promise<GeneratedReport> => {
    const reportId = `report_${Date.now()}`
    const report: GeneratedReport = {
      id: reportId,
      name: `${config.templateId} - ${new Date().toLocaleDateString()}`,
      config,
      status: 'generating',
      progress: 0,
      createdAt: new Date()
    }

    dispatch({ type: 'ADD_GENERATED_REPORT', payload: report })
    dispatch({ type: 'SET_LOADING', payload: true })

    try {

      for (let progress = 0; progress <= 100; progress += 10) {
        await new Promise(resolve => setTimeout(resolve, 200))
        dispatch({
          type: 'UPDATE_REPORT_STATUS',
          payload: {
            id: reportId,
            status: 'generating',
            progress
          }
        })
      }

      const downloadUrl = `/api/reports/${reportId}/download`
      dispatch({
        type: 'UPDATE_REPORT_STATUS',
        payload: {
          id: reportId,
          status: 'completed',
          progress: 100,
          downloadUrl,
          fileSize: Math.floor(Math.random() * 5000000) + 1000000,
          pageCount: Math.floor(Math.random() * 20) + 5
        }
      })

      dispatch({ type: 'SET_LOADING', payload: false })
      return { ...report, status: 'completed', progress: 100, downloadUrl }
    } catch (error) {
      dispatch({
        type: 'UPDATE_REPORT_STATUS',
        payload: {
          id: reportId,
          status: 'failed',
          error: error instanceof Error ? error.message : 'Unknown error'
        }
      })
      dispatch({ type: 'SET_LOADING', payload: false })
      throw error
    }
  }

  const downloadReport = (reportId: string) => {
    const report = state.generatedReports.find(r => r.id === reportId)
    if (report?.downloadUrl) {

      window.open(report.downloadUrl, '_blank')
    }
  }

  const resetWizard = () => {
    dispatch({ type: 'RESET_WIZARD' })
  }

  const contextValue: ReportContextType = {
    state,
    dispatch,
    selectTemplate,
    updateConfig,
    setStep,
    generateReport,
    downloadReport,
    resetWizard
  }

  return (
    <ReportContext.Provider value={contextValue}>
      {children}
    </ReportContext.Provider>
  )
}

export const useReport = () => {
  const context = useContext(ReportContext)
  if (context === undefined) {
    throw new Error('useReport must be used within a ReportProvider')
  }
  return context
}
