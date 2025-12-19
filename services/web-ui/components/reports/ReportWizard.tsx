import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ArrowLeft,
  ArrowRight,
  Check,
  FileText,
  Download,
  Settings,
  Calendar,
  BarChart3,
  Users,
  Target
} from 'lucide-react'
import { useTranslation } from 'next-i18next'
import { useReport } from '@/contexts/ReportContext'
import TemplateSelector from './TemplateSelector'
import TimeRangeSelector from './TimeRangeSelector'
import DataSourceSelector from './DataSourceSelector'
import CustomizationPanel from './CustomizationPanel'

interface ReportWizardProps {
  onReportGenerated: (data: any) => void
}

export default function ReportWizard({ onReportGenerated }: ReportWizardProps) {
  const { t } = useTranslation('common')
  const { state, setStep, generateReport } = useReport()
  const [isGenerating, setIsGenerating] = useState(false)

  const steps = [
    { id: 1, title: t('reportWizard.chooseTemplate'), icon: <FileText className="h-5 w-5" /> },
    { id: 2, title: t('reportWizard.timeRange'), icon: <Calendar className="h-5 w-5" /> },
    { id: 3, title: t('reportWizard.dataSources'), icon: <Users className="h-5 w-5" /> },
    { id: 4, title: t('reportWizard.customize'), icon: <Settings className="h-5 w-5" /> }
  ]

  const handleNext = () => {
    if (state.currentStep < state.totalSteps) {
      setStep(state.currentStep + 1)
    }
  }

  const handlePrevious = () => {
    if (state.currentStep > 1) {
      setStep(state.currentStep - 1)
    }
  }

  const handleGenerate = async () => {
    if (!state.config) return

    setIsGenerating(true)
    try {
      const report = await generateReport(state.config)
      onReportGenerated(report)
    } catch (error) {
      console.error('Failed to generate report:', error)
    } finally {
      setIsGenerating(false)
    }
  }

  const canProceed = () => {
    switch (state.currentStep) {
      case 1:
        return state.selectedTemplate !== null
      case 2:
        return state.config?.timeRange.start && state.config?.timeRange.end
      case 3:
        return state.config?.dataSources.length > 0
      case 4:
        return state.config?.sections.length > 0
      default:
        return false
    }
  }

  const renderStepContent = () => {
    switch (state.currentStep) {
      case 1:
        return <TemplateSelector />
      case 2:
        return <TimeRangeSelector />
      case 3:
        return <DataSourceSelector />
      case 4:
        return <CustomizationPanel />
      default:
        return null
    }
  }

  return (
    <div className="h-full flex flex-col">
      {}
      <div className="p-6 border-b border-border bg-card/50">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-violet-600 bg-clip-text text-transparent">
              {t('reportWizard.title')}
            </h1>
            <p className="text-muted-foreground mt-1">
              {t('reportWizard.subtitle')}
            </p>
          </div>

          <div className="flex items-center gap-2">
            <div className="text-sm text-muted-foreground">
{t('reportWizard.step')} {state.currentStep} {t('reportWizard.of')} {state.totalSteps}
            </div>
          </div>
        </div>

        {}
        <div className="mt-6">
          <div className="flex items-center justify-between">
            {steps.map((step, index) => (
              <div key={step.id} className="flex items-center">
                <motion.div
                  initial={{ scale: 0.8 }}
                  animate={{
                    scale: state.currentStep >= step.id ? 1.1 : 1,
                    backgroundColor: state.currentStep >= step.id ? '#3b82f6' : '#e5e7eb'
                  }}
                  className={`flex items-center justify-center w-10 h-10 rounded-full border-2 transition-colors ${
                    state.currentStep >= step.id
                      ? 'border-primary bg-primary text-primary-foreground'
                      : 'border-muted bg-muted text-muted-foreground'
                  }`}
                >
                  {state.currentStep > step.id ? (
                    <Check className="h-5 w-5" />
                  ) : (
                    step.icon
                  )}
                </motion.div>

                <div className="ml-3 hidden sm:block">
                  <div className={`text-sm font-medium ${
                    state.currentStep >= step.id ? 'text-foreground' : 'text-muted-foreground'
                  }`}>
                    {step.title}
                  </div>
                </div>

                {index < steps.length - 1 && (
                  <div className={`w-16 h-0.5 mx-4 ${
                    state.currentStep > step.id ? 'bg-primary' : 'bg-muted'
                  }`} />
                )}
              </div>
            ))}
          </div>
        </div>
      </div>

      {}
      <div className="flex-1 overflow-auto">
        <div className="p-6">
          <AnimatePresence mode="wait">
            <motion.div
              key={state.currentStep}
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ duration: 0.3 }}
            >
              {renderStepContent()}
            </motion.div>
          </AnimatePresence>
        </div>
      </div>

      {}
      <div className="p-6 border-t border-border bg-card/50">
        <div className="flex items-center justify-between">
          <button
            onClick={handlePrevious}
            disabled={state.currentStep === 1}
            className="flex items-center gap-2 px-4 py-2 text-muted-foreground hover:text-foreground transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <ArrowLeft className="h-4 w-4" />
{t('reportWizard.previous')}
          </button>

          <div className="flex items-center gap-3">
            {state.currentStep === state.totalSteps ? (
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={handleGenerate}
                disabled={!canProceed() || isGenerating}
                className="flex items-center gap-2 px-6 py-3 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isGenerating ? (
                  <>
                    <div className="w-4 h-4 border-2 border-primary-foreground border-t-transparent rounded-full animate-spin" />
{t('reportWizard.generating')}
                  </>
                ) : (
                  <>
                    <Download className="h-4 w-4" />
{t('reportWizard.generateReport')}
                  </>
                )}
              </motion.button>
            ) : (
              <button
                onClick={handleNext}
                disabled={!canProceed()}
                className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
{t('reportWizard.next')}
                <ArrowRight className="h-4 w-4" />
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
