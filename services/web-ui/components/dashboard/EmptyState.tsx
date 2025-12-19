import React from 'react'
import { motion } from 'framer-motion'
import { useTranslation } from 'next-i18next'
import {
  Plus,
  TrendingUp,
  Users,
  BarChart3,
  ArrowRight,
  Sparkles,
  Target,
  Zap
} from 'lucide-react'

interface EmptyStateProps {
  onCreateProject: () => void
  onImportProject: () => void
}

export default function EmptyState({ onCreateProject, onImportProject }: EmptyStateProps) {
  const { t } = useTranslation('common')

  const features = [
    {
      icon: <TrendingUp className="h-6 w-6" />,
      title: t('emptyState.features.trendAnalysis.title'),
      description: t('emptyState.features.trendAnalysis.description')
    },
    {
      icon: <Users className="h-6 w-6" />,
      title: t('emptyState.features.competitorTracking.title'),
      description: t('emptyState.features.competitorTracking.description')
    },
    {
      icon: <BarChart3 className="h-6 w-6" />,
      title: t('emptyState.features.shareOfVoice.title'),
      description: t('emptyState.features.shareOfVoice.description')
    }
  ]

  const quickActions = [
    {
      title: t('emptyState.quickActions.createProject.title'),
      description: t('emptyState.quickActions.createProject.description'),
      icon: <Plus className="h-5 w-5" />,
      action: onCreateProject,
      primary: true
    },
    {
      title: t('emptyState.quickActions.importCSV.title'),
      description: t('emptyState.quickActions.importCSV.description'),
      icon: <Target className="h-5 w-5" />,
      action: onImportProject,
      primary: false
    }
  ]

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-muted/20 flex items-center justify-center p-6">
      <div className="max-w-4xl w-full">
        {}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-center mb-12"
        >
          <motion.div
            initial={{ scale: 0.8 }}
            animate={{ scale: 1 }}
            transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
            className="inline-flex items-center justify-center w-20 h-20 bg-gradient-to-r from-blue-600 to-violet-600 rounded-full mb-6"
          >
            <Sparkles className="h-10 w-10 text-white" />
          </motion.div>

          <h1 className="text-4xl font-bold bg-gradient-to-r from-blue-600 to-violet-600 bg-clip-text text-transparent mb-4">
            {t('emptyState.welcome.title')}
          </h1>

          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            {t('emptyState.welcome.description')}
          </p>
        </motion.div>

        {}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4, duration: 0.6 }}
          className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12"
        >
          {features.map((feature, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.6 + index * 0.1, duration: 0.6 }}
              whileHover={{ scale: 1.02, y: -5 }}
              className="bg-card border border-border rounded-lg p-6 text-center hover:shadow-lg transition-all"
            >
              <div className="inline-flex items-center justify-center w-12 h-12 bg-primary/10 rounded-lg mb-4 text-primary">
                {feature.icon}
              </div>
              <h3 className="text-lg font-semibold mb-2">{feature.title}</h3>
              <p className="text-muted-foreground text-sm">{feature.description}</p>
            </motion.div>
          ))}
        </motion.div>

        {}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.8, duration: 0.6 }}
          className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-2xl mx-auto"
        >
          {quickActions.map((action, index) => (
            <motion.button
              key={index}
              initial={{ opacity: 0, x: index === 0 ? -20 : 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 1 + index * 0.1, duration: 0.6 }}
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={action.action}
              className={`group relative overflow-hidden rounded-lg p-6 text-left transition-all ${
                action.primary
                  ? 'bg-gradient-to-r from-blue-600 to-violet-600 text-white hover:shadow-xl'
                  : 'bg-card border border-border hover:border-primary/50 hover:shadow-md'
              }`}
            >
              <div className="relative z-10">
                <div className="flex items-center gap-3 mb-3">
                  <div className={`p-2 rounded-lg ${
                    action.primary
                      ? 'bg-white/20'
                      : 'bg-primary/10 text-primary'
                  }`}>
                    {action.icon}
                  </div>
                  <h3 className="text-lg font-semibold">{action.title}</h3>
                </div>

                <p className={`text-sm mb-4 ${
                  action.primary ? 'text-white/80' : 'text-muted-foreground'
                }`}>
                  {action.description}
                </p>

                <div className="flex items-center gap-2 text-sm font-medium">
                  <span>{action.primary ? t('emptyState.quickActions.createProject.buttonText') : t('emptyState.quickActions.importCSV.buttonText')}</span>
                  <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
                </div>
              </div>

              {}
              {action.primary && (
                <div className="absolute inset-0 bg-gradient-to-r from-blue-600/20 to-violet-600/20 opacity-0 group-hover:opacity-100 transition-opacity" />
              )}
            </motion.button>
          ))}
        </motion.div>

        {}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 1.2, duration: 0.6 }}
          className="mt-12 text-center"
        >
          <div className="inline-flex items-center gap-2 text-sm text-muted-foreground bg-muted/50 rounded-full px-4 py-2">
            <Zap className="h-4 w-4" />
            <span>{t('emptyState.tip')}</span>
          </div>
        </motion.div>
      </div>
    </div>
  )
}
