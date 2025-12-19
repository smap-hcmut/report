import React from 'react'
import { motion } from 'framer-motion'
import { Check, Clock, BarChart3, TrendingUp, Users, Settings } from 'lucide-react'
import { useTranslation } from 'next-i18next'
import { useReport } from '@/contexts/ReportContext'

export default function TemplateSelector() {
  const { t } = useTranslation('common')
  const { state, selectTemplate } = useReport()

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'performance': return <BarChart3 className="h-5 w-5" />
      case 'trend': return <TrendingUp className="h-5 w-5" />
      case 'competitor': return <Users className="h-5 w-5" />
      case 'custom': return <Settings className="h-5 w-5" />
      default: return <BarChart3 className="h-5 w-5" />
    }
  }

  const getCategoryColor = (category: string) => {
    switch (category) {
      case 'performance': return 'bg-blue-100 text-blue-700 border-blue-200'
      case 'trend': return 'bg-green-100 text-green-700 border-green-200'
      case 'competitor': return 'bg-purple-100 text-purple-700 border-purple-200'
      case 'custom': return 'bg-orange-100 text-orange-700 border-orange-200'
      default: return 'bg-gray-100 text-gray-700 border-gray-200'
    }
  }

  return (
    <div className="max-w-4xl mx-auto">
      <div className="text-center mb-8">
        <h2 className="text-2xl font-bold mb-2">{t('reportWizard.chooseTemplate')}</h2>
        <p className="text-muted-foreground">
          {t('reportWizard.selectTemplate')}
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {state.templates.map((template, index) => (
          <motion.div
            key={template.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, delay: index * 0.1 }}
            whileHover={{ scale: 1.02, y: -4 }}
            whileTap={{ scale: 0.98 }}
            onClick={() => selectTemplate(template)}
            className={`relative p-6 border-2 rounded-lg cursor-pointer transition-all ${
              state.selectedTemplate?.id === template.id
                ? 'border-primary bg-primary/5 shadow-lg'
                : 'border-border hover:border-primary/50 hover:shadow-md'
            }`}
          >
            {}
            {state.selectedTemplate?.id === template.id && (
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                className="absolute top-4 right-4 w-6 h-6 bg-primary text-primary-foreground rounded-full flex items-center justify-center"
              >
                <Check className="h-4 w-4" />
              </motion.div>
            )}

            {}
            <div className="flex items-center gap-3 mb-4">
              <div className="text-3xl">{template.icon}</div>
            <div>
              <h3 className="text-lg font-semibold">
                {template.id === 'performance-summary' && t('reportWizard.performanceSummary')}
                {template.id === 'trend-analysis' && t('reportWizard.trendAnalysisReport')}
                {template.id === 'competitor-comparison' && t('reportWizard.competitorComparison')}
                {template.id === 'custom-report' && t('reportWizard.customReport')}
                {!['performance-summary', 'trend-analysis', 'competitor-comparison', 'custom-report'].includes(template.id) && template.name}
              </h3>
              <div className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium border ${getCategoryColor(template.category)}`}>
                {getCategoryIcon(template.category)}
                {template.category}
              </div>
            </div>
            </div>

            {}
            <p className="text-muted-foreground mb-4">
              {template.id === 'performance-summary' && t('reportWizard.performanceSummaryDesc')}
              {template.id === 'trend-analysis' && t('reportWizard.trendAnalysisReportDesc')}
              {template.id === 'competitor-comparison' && t('reportWizard.competitorComparisonDesc')}
              {template.id === 'custom-report' && t('reportWizard.customReportDesc')}
              {!['performance-summary', 'trend-analysis', 'competitor-comparison', 'custom-report'].includes(template.id) && template.description}
            </p>

            {}
            <div className="mb-4">
              <h4 className="text-sm font-medium mb-2">{t('reportWizard.includes')}:</h4>
              <div className="flex flex-wrap gap-2">
                {template.sections.slice(0, 3).map((section) => (
                  <span
                    key={section.id}
                    className="px-2 py-1 bg-muted text-muted-foreground text-xs rounded-md"
                  >
                    {section.title}
                  </span>
                ))}
                {template.sections.length > 3 && (
                  <span className="px-2 py-1 bg-muted text-muted-foreground text-xs rounded-md">
                    +{template.sections.length - 3} more
                  </span>
                )}
              </div>
            </div>

            {}
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Clock className="h-4 w-4" />
              <span>~{template.estimatedTime} {t('reportWizard.minutesToGenerate')}</span>
            </div>

            {}
            <div className="absolute inset-0 rounded-lg bg-gradient-to-r from-primary/5 to-violet-500/5 opacity-0 hover:opacity-100 transition-opacity pointer-events-none" />
          </motion.div>
        ))}
      </div>

      {}
      {state.selectedTemplate && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-8 p-6 bg-muted/50 rounded-lg border border-border"
        >
          <h3 className="text-lg font-semibold mb-4">{t('reportWizard.templateDetails')}</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h4 className="font-medium mb-2">{t('reportWizard.sectionsIncluded')}:</h4>
              <ul className="space-y-2">
                {state.selectedTemplate.sections.map((section) => (
                  <li key={section.id} className="flex items-center gap-2 text-sm">
                    <div className={`w-2 h-2 rounded-full ${
                      section.required ? 'bg-primary' : 'bg-muted-foreground'
                    }`} />
                    <span className={section.required ? 'font-medium' : 'text-muted-foreground'}>
                      {section.title}
                    </span>
                    {section.required && (
                      <span className="text-xs text-primary">({t('reportWizard.required')})</span>
                    )}
                  </li>
                ))}
              </ul>
            </div>

            <div>
              <h4 className="font-medium mb-2">{t('reportWizard.reportFeatures')}:</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li>• {t('reportWizard.professionalPdf')}</li>
                <li>• {t('reportWizard.interactiveCharts')}</li>
                <li>• {t('reportWizard.executiveSummary')}</li>
                <li>• {t('reportWizard.dataInsights')}</li>
                <li>• {t('reportWizard.brandCustomization')}</li>
              </ul>
            </div>
          </div>
        </motion.div>
      )}
    </div>
  )
}
