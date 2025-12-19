import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ArrowLeft,
  Download,
  Eye,
  FileText,
  BarChart3,
  Table,
  TrendingUp,
  CheckCircle,
  Clock,
  AlertCircle,
  Share2,
  RefreshCw
} from 'lucide-react'
import { useReport } from '@/contexts/ReportContext'

interface ReportPreviewProps {
  reportData: any
  onBack: () => void
}

export default function ReportPreview({ reportData, onBack }: ReportPreviewProps) {
  const { state, downloadReport } = useReport()
  const [activeTab, setActiveTab] = useState<'preview' | 'status'>('preview')

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="h-5 w-5 text-green-600" />
      case 'generating':
        return <RefreshCw className="h-5 w-5 text-blue-600 animate-spin" />
      case 'failed':
        return <AlertCircle className="h-5 w-5 text-red-600" />
      default:
        return <Clock className="h-5 w-5 text-gray-600" />
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'bg-green-100 text-green-800 border-green-200'
      case 'generating':
        return 'bg-blue-100 text-blue-800 border-blue-200'
      case 'failed':
        return 'bg-red-100 text-red-800 border-red-200'
      default:
        return 'bg-gray-100 text-gray-800 border-gray-200'
    }
  }

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  const mockPreviewData = {
    title: state.selectedTemplate?.name || 'Report Preview',
    sections: [
      {
        id: 'executive-summary',
        title: 'Executive Summary',
        type: 'text',
        content: 'This report provides a comprehensive analysis of your social media performance over the selected time period. Key highlights include significant growth in engagement rates and positive sentiment trends across all platforms.'
      },
      {
        id: 'key-metrics',
        title: 'Key Metrics',
        type: 'metrics',
        data: [
          { label: 'Total Reach', value: '2.4M', change: '+12%', trend: 'up' },
          { label: 'Engagement Rate', value: '4.2%', change: '+0.8%', trend: 'up' },
          { label: 'Sentiment Score', value: '0.73', change: '+0.15', trend: 'up' },
          { label: 'Content Volume', value: '156', change: '+23', trend: 'up' }
        ]
      },
      {
        id: 'trend-analysis',
        title: 'Trend Analysis',
        type: 'chart',
        description: 'Performance trends over time showing consistent growth in key metrics.'
      },
      {
        id: 'top-content',
        title: 'Top Performing Content',
        type: 'table',
        description: 'Best performing posts ranked by engagement and reach.'
      }
    ]
  }

  return (
    <div className="h-full flex flex-col">
      {}
      <div className="p-6 border-b border-border bg-card/50">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <button
              onClick={onBack}
              className="flex items-center gap-2 px-4 py-2 text-muted-foreground hover:text-foreground transition-colors"
            >
              <ArrowLeft className="h-4 w-4" />
              Back to Wizard
            </button>

            <div>
              <h1 className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-violet-600 bg-clip-text text-transparent">
                Report Preview
              </h1>
              <p className="text-muted-foreground mt-1">
                {mockPreviewData.title} - {new Date().toLocaleDateString()}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={() => setActiveTab(activeTab === 'preview' ? 'status' : 'preview')}
              className="flex items-center gap-2 px-4 py-2 bg-muted hover:bg-muted/80 rounded-lg transition-colors"
            >
              <Eye className="h-4 w-4" />
              {activeTab === 'preview' ? 'View Status' : 'View Preview'}
            </button>

            {reportData.status === 'completed' && (
              <button
                onClick={() => downloadReport(reportData.id)}
                className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors"
              >
                <Download className="h-4 w-4" />
                Download Report
              </button>
            )}
          </div>
        </div>

        {}
        <div className="flex border-b border-border mt-6">
          <button
            onClick={() => setActiveTab('preview')}
            className={`flex items-center gap-2 px-4 py-2 text-sm font-medium relative transition-colors ${
              activeTab === 'preview'
                ? 'text-primary'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            <FileText className="h-4 w-4" />
            <span>Preview</span>
            {activeTab === 'preview' && (
              <motion.div
                layoutId="preview-tab-indicator"
                className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-blue-600 to-violet-600"
                transition={{ type: 'spring', bounce: 0.2, duration: 0.6 }}
              />
            )}
          </button>

          <button
            onClick={() => setActiveTab('status')}
            className={`flex items-center gap-2 px-4 py-2 text-sm font-medium relative transition-colors ${
              activeTab === 'status'
                ? 'text-primary'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            <BarChart3 className="h-4 w-4" />
            <span>Status</span>
            {activeTab === 'status' && (
              <motion.div
                layoutId="preview-tab-indicator"
                className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-blue-600 to-violet-600"
                transition={{ type: 'spring', bounce: 0.2, duration: 0.6 }}
              />
            )}
          </button>
        </div>
      </div>

      {}
      <div className="flex-1 overflow-auto">
        <div className="p-6">
          <AnimatePresence mode="wait">
            {activeTab === 'preview' ? (
              <motion.div
                key="preview"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                className="max-w-4xl mx-auto"
              >
                {}
                <div className="text-center mb-8 p-8 bg-gradient-to-r from-blue-50 to-violet-50 rounded-lg border border-border">
                  <h2 className="text-3xl font-bold mb-2">{mockPreviewData.title}</h2>
                  <p className="text-muted-foreground">
                    Generated on {new Date().toLocaleDateString()} •
                    Period: {state.config?.timeRange ?
                      `${state.config.timeRange.start.toLocaleDateString()} - ${state.config.timeRange.end.toLocaleDateString()}` :
                      'Not specified'
                    }
                  </p>
                </div>

                {}
                <div className="space-y-8">
                  {mockPreviewData.sections.map((section, index) => (
                    <motion.div
                      key={section.id}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ duration: 0.3, delay: index * 0.1 }}
                      className="p-6 bg-card border border-border rounded-lg"
                    >
                      <h3 className="text-xl font-semibold mb-4 flex items-center gap-2">
                        {section.type === 'metrics' && <TrendingUp className="h-5 w-5" />}
                        {section.type === 'chart' && <BarChart3 className="h-5 w-5" />}
                        {section.type === 'table' && <Table className="h-5 w-5" />}
                        {section.type === 'text' && <FileText className="h-5 w-5" />}
                        {section.title}
                      </h3>

                      {section.type === 'text' && (
                        <p className="text-muted-foreground leading-relaxed">
                          {section.content}
                        </p>
                      )}

                      {section.type === 'metrics' && (
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                          {section.data.map((metric: any, i: number) => (
                            <div key={i} className="p-4 bg-muted/50 rounded-lg">
                              <div className="text-2xl font-bold mb-1">{metric.value}</div>
                              <div className="text-sm text-muted-foreground mb-2">{metric.label}</div>
                              <div className={`text-sm flex items-center gap-1 ${
                                metric.trend === 'up' ? 'text-green-600' : 'text-red-600'
                              }`}>
                                {metric.change}
                                <TrendingUp className={`h-3 w-3 ${metric.trend === 'down' ? 'rotate-180' : ''}`} />
                              </div>
                            </div>
                          ))}
                        </div>
                      )}

                      {section.type === 'chart' && (
                        <div className="h-64 bg-muted/30 rounded-lg flex items-center justify-center border-2 border-dashed border-muted">
                          <div className="text-center">
                            <BarChart3 className="h-12 w-12 mx-auto mb-2 text-muted-foreground" />
                            <p className="text-muted-foreground">{section.description}</p>
                          </div>
                        </div>
                      )}

                      {section.type === 'table' && (
                        <div className="h-64 bg-muted/30 rounded-lg flex items-center justify-center border-2 border-dashed border-muted">
                          <div className="text-center">
                            <Table className="h-12 w-12 mx-auto mb-2 text-muted-foreground" />
                            <p className="text-muted-foreground">{section.description}</p>
                          </div>
                        </div>
                      )}
                    </motion.div>
                  ))}
                </div>
              </motion.div>
            ) : (
              <motion.div
                key="status"
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                className="max-w-2xl mx-auto"
              >
                <div className="space-y-6">
                  {}
                  <div className="p-6 bg-card border border-border rounded-lg">
                    <div className="flex items-center gap-3 mb-4">
                      {getStatusIcon(reportData.status)}
                      <h3 className="text-lg font-semibold">Report Status</h3>
                    </div>

                    <div className={`inline-flex items-center gap-2 px-3 py-1 rounded-full text-sm font-medium border ${getStatusColor(reportData.status)}`}>
                      {reportData.status.charAt(0).toUpperCase() + reportData.status.slice(1)}
                    </div>

                    {reportData.status === 'generating' && (
                      <div className="mt-4">
                        <div className="flex items-center justify-between text-sm mb-2">
                          <span>Progress</span>
                          <span>{reportData.progress}%</span>
                        </div>
                        <div className="w-full bg-muted rounded-full h-2">
                          <motion.div
                            className="bg-primary h-2 rounded-full"
                            initial={{ width: 0 }}
                            animate={{ width: `${reportData.progress}%` }}
                            transition={{ duration: 0.5 }}
                          />
                        </div>
                      </div>
                    )}

                    {reportData.status === 'completed' && (
                      <div className="mt-4 space-y-2 text-sm">
                        <div><strong>File Size:</strong> {reportData.fileSize ? formatFileSize(reportData.fileSize) : 'N/A'}</div>
                        <div><strong>Pages:</strong> {reportData.pageCount || 'N/A'}</div>
                        <div><strong>Completed:</strong> {reportData.completedAt?.toLocaleString() || 'N/A'}</div>
                      </div>
                    )}

                    {reportData.status === 'failed' && (
                      <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg">
                        <p className="text-sm text-red-800">
                          <strong>Error:</strong> {reportData.error || 'Unknown error occurred'}
                        </p>
                      </div>
                    )}
                  </div>

                  {}
                  <div className="p-6 bg-card border border-border rounded-lg">
                    <h3 className="text-lg font-semibold mb-4">Report Details</h3>
                    <div className="space-y-3 text-sm">
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Report ID:</span>
                        <span className="font-mono">{reportData.id}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Created:</span>
                        <span>{reportData.createdAt.toLocaleString()}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Template:</span>
                        <span>{state.selectedTemplate?.name}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Format:</span>
                        <span>{state.config?.outputFormat?.toUpperCase()}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Language:</span>
                        <span>{state.config?.language === 'vi' ? 'Tiếng Việt' : 'English'}</span>
                      </div>
                    </div>
                  </div>

                  {}
                  {reportData.status === 'completed' && (
                    <div className="flex gap-3">
                      <button
                        onClick={() => downloadReport(reportData.id)}
                        className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors"
                      >
                        <Download className="h-4 w-4" />
                        Download Report
                      </button>
                      <button className="flex items-center gap-2 px-4 py-3 bg-muted hover:bg-muted/80 rounded-lg transition-colors">
                        <Share2 className="h-4 w-4" />
                        Share
                      </button>
                    </div>
                  )}
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
    </div>
  )
}
