import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ChevronDown, FolderOpen, Plus } from 'lucide-react'
import { useTranslation } from 'next-i18next'
import { useDashboard } from '@/contexts/DashboardContext'

export default function ProjectSelector() {
  const { t } = useTranslation('common')
  const { state, setProject, addProject } = useDashboard()
  const [isOpen, setIsOpen] = useState(false)

  const currentProject = state.projects.find(p => p.id === state.selectedProject)

  const handleProjectSelect = (projectId: string) => {
    setProject(projectId)
    setIsOpen(false)
  }

  const handleCreateProject = () => {

    setProject(null)
    setIsOpen(false)
  }

  return (
    <div className="relative">
      <motion.button
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-2 bg-muted/50 hover:bg-muted rounded-lg border border-border transition-colors"
      >
        <FolderOpen className="h-4 w-4 text-muted-foreground" />
        <span className="text-sm font-medium">
          {currentProject?.name || t('dashboard.selectProject')}
        </span>
        <ChevronDown className={`h-3 w-3 text-muted-foreground transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </motion.button>

      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: -10, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -10, scale: 0.95 }}
            transition={{ duration: 0.2 }}
            className="absolute top-full left-0 mt-2 w-64 bg-card border border-border rounded-lg shadow-lg z-50"
          >
            <div className="p-2">
              {}
              <motion.button
                whileHover={{ backgroundColor: 'rgba(0,0,0,0.05)' }}
                onClick={handleCreateProject}
                className="w-full flex items-center gap-2 px-3 py-2 text-sm text-muted-foreground hover:text-foreground rounded-md transition-colors"
              >
                <Plus className="h-4 w-4" />
                {t('dashboard.createNewProject')}
              </motion.button>

              {}
              {state.projects.length > 0 && (
                <div className="border-t border-border my-2" />
              )}

              {}
              {state.projects.length === 0 ? (
                <div className="px-3 py-2 text-sm text-muted-foreground text-center">
                  {t('dashboard.noProjects')}
                </div>
              ) : (
                state.projects.map((project) => (
                  <motion.button
                    key={project.id}
                    whileHover={{ backgroundColor: 'rgba(0,0,0,0.05)' }}
                    onClick={() => handleProjectSelect(project.id)}
                    className={`w-full flex items-center gap-2 px-3 py-2 text-sm rounded-md transition-colors ${
                      project.id === state.selectedProject
                        ? 'bg-primary/10 text-primary'
                        : 'text-foreground hover:bg-muted/50'
                    }`}
                  >
                    <FolderOpen className="h-4 w-4" />
                    <div className="flex-1 text-left">
                      <div className="font-medium">{project.name}</div>
                      <div className="text-xs text-muted-foreground">
                        {project.brands.length} brands, {project.competitors.length} competitors
                      </div>
                    </div>
                  </motion.button>
                ))
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setIsOpen(false)}
            className="fixed inset-0 z-40"
          />
        )}
      </AnimatePresence>
    </div>
  )
}
