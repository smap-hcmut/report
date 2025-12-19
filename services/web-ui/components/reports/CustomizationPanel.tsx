import React, { useState } from 'react'
import { motion } from 'framer-motion'
import {
  Settings,
  Palette,
  FileText,
  BarChart3,
  Table,
  TrendingUp,
  Check,
  Upload,
  Download,
  Globe
} from 'lucide-react'
import { useReport } from '@/contexts/ReportContext'

export default function CustomizationPanel() {
  const { state, updateConfig } = useReport()
  const [activeTab, setActiveTab] = useState<'sections' | 'branding' | 'output'>('sections')

  const handleSectionToggle = (sectionId: string) => {
    const currentSections = state.config?.sections || []
    const newSections = currentSections.includes(sectionId)
      ? currentSections.filter(id => id !== sectionId)
      : [...currentSections, sectionId]

    updateConfig({ sections: newSections })
  }

  const handleCustomizationToggle = (key: string) => {
    const currentCustomizations = state.config?.customizations || {
      includeCharts: true,
      includeTables: true,
      includeMetrics: true,
      includeInsights: true,
      branding: {}
    }

    updateConfig({
      customizations: {
        ...currentCustomizations,
        [key]: !currentCustomizations[key as keyof typeof currentCustomizations]
      }
    })
  }

  const handleBrandingUpdate = (key: string, value: string) => {
    const currentCustomizations = state.config?.customizations || {
      includeCharts: true,
      includeTables: true,
      includeMetrics: true,
      includeInsights: true,
      branding: {}
    }

    updateConfig({
      customizations: {
        ...currentCustomizations,
        branding: {
          ...currentCustomizations.branding,
          [key]: value
        }
      }
    })
  }

  const handleOutputFormatChange = (format: 'pdf' | 'excel' | 'powerpoint') => {
    updateConfig({ outputFormat: format })
  }

  const handleLanguageChange = (language: 'vi' | 'en') => {
    updateConfig({ language })
  }

  const tabs = [
    { id: 'sections', label: 'Sections', icon: <FileText className="h-4 w-4" /> },
    { id: 'branding', label: 'Branding', icon: <Palette className="h-4 w-4" /> },
    { id: 'output', label: 'Output', icon: <Download className="h-4 w-4" /> }
  ]

  const outputFormats = [
    { id: 'pdf', label: 'PDF', description: 'Professional document format', icon: '📄' },
    { id: 'excel', label: 'Excel', description: 'Spreadsheet with data tables', icon: '📊' },
    { id: 'powerpoint', label: 'PowerPoint', description: 'Presentation slides', icon: '📽️' }
  ]

  const languages = [
    { id: 'vi', label: 'Tiếng Việt', flag: '🇻🇳' },
    { id: 'en', label: 'English', flag: '🇺🇸' }
  ]

  return (
    <div className="max-w-4xl mx-auto">
      <div className="text-center mb-8">
        <h2 className="text-2xl font-bold mb-2">Customize Your Report</h2>
        <p className="text-muted-foreground">
          Fine-tune the content and appearance of your report
        </p>
      </div>

      {}
      <div className="flex border-b border-border mb-8">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as any)}
            className={`flex items-center gap-2 px-6 py-3 text-sm font-medium relative transition-colors ${
              activeTab === tab.id
                ? 'text-primary'
                : 'text-muted-foreground hover:text-foreground'
            }`}
          >
            {tab.icon}
            <span>{tab.label}</span>
            {activeTab === tab.id && (
              <motion.div
                layoutId="customization-tab-indicator"
                className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-blue-600 to-violet-600"
                transition={{ type: 'spring', bounce: 0.2, duration: 0.6 }}
              />
            )}
          </button>
        ))}
      </div>

      {}
      <div className="min-h-[400px]">
        {activeTab === 'sections' && (
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            className="space-y-6"
          >
            <div>
              <h3 className="text-lg font-semibold mb-4">Report Sections</h3>
              <p className="text-muted-foreground mb-6">
                Choose which sections to include in your report
              </p>
            </div>

            {}
            {state.selectedTemplate?.sections.map((section, index) => (
              <motion.div
                key={section.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.3, delay: index * 0.1 }}
                className={`p-4 border-2 rounded-lg cursor-pointer transition-all ${
                  state.config?.sections.includes(section.id)
                    ? 'border-primary bg-primary/5'
                    : 'border-border hover:border-primary/50'
                } ${section.required ? 'opacity-75' : ''}`}
                onClick={() => !section.required && handleSectionToggle(section.id)}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="flex items-center justify-center w-10 h-10 rounded-lg bg-muted">
                      {section.type === 'chart' && <BarChart3 className="h-5 w-5" />}
                      {section.type === 'table' && <Table className="h-5 w-5" />}
                      {section.type === 'metric' && <TrendingUp className="h-5 w-5" />}
                      {section.type === 'text' && <FileText className="h-5 w-5" />}
                    </div>
                    <div>
                      <h4 className="font-medium">{section.title}</h4>
                      <p className="text-sm text-muted-foreground">
                        {section.type} • {section.required ? 'Required' : 'Optional'}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    {section.required && (
                      <span className="text-xs text-primary font-medium">Required</span>
                    )}
                    {state.config?.sections.includes(section.id) && (
                      <div className="w-6 h-6 bg-primary text-primary-foreground rounded-full flex items-center justify-center">
                        <Check className="h-4 w-4" />
                      </div>
                    )}
                  </div>
                </div>
              </motion.div>
            ))}

            {}
            <div className="mt-8">
              <h4 className="font-medium mb-4">Content Types</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {[
                  { key: 'includeCharts', label: 'Charts & Graphs', icon: <BarChart3 className="h-5 w-5" /> },
                  { key: 'includeTables', label: 'Data Tables', icon: <Table className="h-5 w-5" /> },
                  { key: 'includeMetrics', label: 'Key Metrics', icon: <TrendingUp className="h-5 w-5" /> },
                  { key: 'includeInsights', label: 'AI Insights', icon: <Settings className="h-5 w-5" /> }
                ].map((item) => (
                  <div
                    key={item.key}
                    className={`p-4 border rounded-lg cursor-pointer transition-all ${
                      state.config?.customizations[item.key as keyof typeof state.config.customizations]
                        ? 'border-primary bg-primary/5'
                        : 'border-border hover:border-primary/50'
                    }`}
                    onClick={() => handleCustomizationToggle(item.key)}
                  >
                    <div className="flex items-center gap-3">
                      <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-muted">
                        {item.icon}
                      </div>
                      <span className="font-medium">{item.label}</span>
                      {state.config?.customizations[item.key as keyof typeof state.config.customizations] && (
                        <Check className="h-4 w-4 text-primary ml-auto" />
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </motion.div>
        )}

        {activeTab === 'branding' && (
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            className="space-y-6"
          >
            <div>
              <h3 className="text-lg font-semibold mb-4">Branding & Styling</h3>
              <p className="text-muted-foreground mb-6">
                Customize the appearance of your report
              </p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium mb-2">Company Name</label>
                <input
                  type="text"
                  value={state.config?.customizations.branding.companyName || ''}
                  onChange={(e) => handleBrandingUpdate('companyName', e.target.value)}
                  placeholder="Enter your company name"
                  className="w-full p-3 border border-border rounded-lg bg-background focus:ring-2 focus:ring-primary focus:border-transparent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">Logo Upload</label>
                <div className="border-2 border-dashed border-border rounded-lg p-6 text-center hover:border-primary/50 transition-colors cursor-pointer">
                  <Upload className="h-8 w-8 mx-auto mb-2 text-muted-foreground" />
                  <p className="text-sm text-muted-foreground">Click to upload logo</p>
                  <p className="text-xs text-muted-foreground mt-1">PNG, JPG up to 2MB</p>
                </div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium mb-2">Color Scheme</label>
              <div className="flex gap-2">
                {['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'].map((color) => (
                  <button
                    key={color}
                    className="w-8 h-8 rounded-full border-2 border-border hover:border-primary transition-colors"
                    style={{ backgroundColor: color }}
                    onClick={() => handleBrandingUpdate('colors', JSON.stringify([color]))}
                  />
                ))}
              </div>
            </div>
          </motion.div>
        )}

        {activeTab === 'output' && (
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            className="space-y-6"
          >
            <div>
              <h3 className="text-lg font-semibold mb-4">Output Settings</h3>
              <p className="text-muted-foreground mb-6">
                Choose the format and language for your report
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium mb-4">Output Format</label>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {outputFormats.map((format) => (
                  <div
                    key={format.id}
                    className={`p-4 border-2 rounded-lg cursor-pointer transition-all ${
                      state.config?.outputFormat === format.id
                        ? 'border-primary bg-primary/5'
                        : 'border-border hover:border-primary/50'
                    }`}
                    onClick={() => handleOutputFormatChange(format.id as any)}
                  >
                    <div className="text-center">
                      <div className="text-2xl mb-2">{format.icon}</div>
                      <h4 className="font-medium">{format.label}</h4>
                      <p className="text-sm text-muted-foreground">{format.description}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium mb-4">Language</label>
              <div className="flex gap-4">
                {languages.map((lang) => (
                  <button
                    key={lang.id}
                    onClick={() => handleLanguageChange(lang.id as any)}
                    className={`flex items-center gap-2 px-4 py-2 border-2 rounded-lg transition-all ${
                      state.config?.language === lang.id
                        ? 'border-primary bg-primary/5'
                        : 'border-border hover:border-primary/50'
                    }`}
                  >
                    <span className="text-lg">{lang.flag}</span>
                    <span>{lang.label}</span>
                  </button>
                ))}
              </div>
            </div>
          </motion.div>
        )}
      </div>

      {}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="mt-8 p-6 bg-muted/50 rounded-lg border border-border"
      >
        <h3 className="text-lg font-semibold mb-4">Report Summary</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div>
            <strong>Template:</strong> {state.selectedTemplate?.name}
          </div>
          <div>
            <strong>Time Range:</strong> {state.config?.timeRange ?
              `${Math.ceil((state.config.timeRange.end.getTime() - state.config.timeRange.start.getTime()) / (1000 * 60 * 60 * 24))} days` :
              'Not set'
            }
          </div>
          <div>
            <strong>Data Sources:</strong> {state.config?.dataSources.length || 0} selected
          </div>
          <div>
            <strong>Sections:</strong> {state.config?.sections.length || 0} included
          </div>
          <div>
            <strong>Format:</strong> {state.config?.outputFormat?.toUpperCase()}
          </div>
          <div>
            <strong>Language:</strong> {state.config?.language === 'vi' ? 'Tiếng Việt' : 'English'}
          </div>
        </div>
      </motion.div>
    </div>
  )
}
