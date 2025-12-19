import { useState, useEffect, useMemo } from 'react'
import type { NextPage } from 'next'
import { serverSideTranslations } from 'next-i18next/serverSideTranslations'
import { useTranslation } from 'next-i18next'
import { useRouter } from 'next/router'
import Navbar from '@/components/Navbar'
import Footer from '@/components/Footer'
import RenameWorkflowModal from '@/components/RenameWorkflowModal'
import { storage, SavedWorkflow } from '@/lib/storage'
import { Trash2, Play, FolderOpen, Edit2, Copy, Download, Search } from 'lucide-react'

const Workflow: NextPage = () => {
  const { t } = useTranslation('common')
  const router = useRouter()
  const [workflows, setWorkflows] = useState<SavedWorkflow[]>([])
  const [searchQuery, setSearchQuery] = useState('')
  const [renameModalOpen, setRenameModalOpen] = useState(false)
  const [selectedWorkflow, setSelectedWorkflow] = useState<SavedWorkflow | null>(null)

  useEffect(() => {
    loadWorkflows()
  }, [])

  const loadWorkflows = () => {
    const allWorkflows = storage.loadAllWorkflows()
    setWorkflows(allWorkflows)
  }

  const filteredWorkflows = useMemo(() => {
    if (!searchQuery.trim()) return workflows
    
    const query = searchQuery.toLowerCase()
    return workflows.filter(w => 
      w.name.toLowerCase().includes(query)
    )
  }, [workflows, searchQuery])

  const handleLoad = (workflow: SavedWorkflow) => {
    storage.saveDraft(workflow.data)
    router.push('/overview')
  }

  const handleDelete = (id: string) => {
    if (confirm('Are you sure you want to delete this workflow?')) {
      storage.deleteWorkflow(id)
      loadWorkflows()
    }
  }

  const handleRename = (workflow: SavedWorkflow) => {
    setSelectedWorkflow(workflow)
    setRenameModalOpen(true)
  }

  const handleRenameSubmit = (newName: string) => {
    if (selectedWorkflow) {
      storage.updateWorkflow(selectedWorkflow.id, newName, selectedWorkflow.data)
      loadWorkflows()
      setSelectedWorkflow(null)
    }
  }

  const handleDuplicate = (workflow: SavedWorkflow) => {
    const newName = `${workflow.name} (Copy)`
    storage.saveWorkflow(newName, workflow.data)
    loadWorkflows()
  }

  const handleExport = (workflow: SavedWorkflow) => {
    const exportData = {
      name: workflow.name,
      createdAt: workflow.createdAt,
      updatedAt: workflow.updatedAt,
      data: workflow.data
    }
    
    const dataStr = JSON.stringify(exportData, null, 2)
    const blob = new Blob([dataStr], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `${workflow.name.replace(/[^a-z0-9]/gi, '_')}.json`
    link.click()
    URL.revokeObjectURL(url)
  }

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr)
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], { 
      hour: '2-digit', 
      minute: '2-digit' 
    })
  }

  return (
    <div className="min-h-screen flex flex-col">
      <Navbar />
      <main className="flex-1 container py-8">
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">{t('navbar.workflow')}</h1>
          <p className="text-muted-foreground">
            Manage your saved workflows
          </p>
        </div>

        {workflows.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 text-center">
            <FolderOpen className="h-16 w-16 text-muted-foreground mb-4" />
            <h3 className="text-xl font-semibold mb-2">No workflows yet</h3>
            <p className="text-muted-foreground mb-6">
              Create your first workflow in the Overview page
            </p>
            <button
              onClick={() => router.push('/overview')}
              className="px-6 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 transition-colors"
            >
              Go to Overview
            </button>
          </div>
        ) : (
          <>
            <div className="mb-6">
              <div className="relative max-w-md">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
                <input
                  type="text"
                  placeholder="Search workflows..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-background border border-border rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
                />
              </div>
            </div>

            {filteredWorkflows.length === 0 ? (
              <div className="text-center py-12">
                <p className="text-muted-foreground">No workflows found matching &quot;{searchQuery}&quot;</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {filteredWorkflows.map((workflow) => (
                  <div
                    key={workflow.id}
                    className="border border-border rounded-lg p-6 bg-card hover:shadow-lg transition-shadow"
                  >
                    <div className="flex items-start justify-between mb-4">
                      <h3 className="text-lg font-semibold truncate flex-1 mr-2">
                        {workflow.name}
                      </h3>
                      <div className="flex gap-1">
                        <button
                          onClick={() => handleRename(workflow)}
                          className="p-2 rounded-md hover:bg-accent transition-colors"
                          aria-label="Rename workflow"
                          title="Rename"
                        >
                          <Edit2 className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleDelete(workflow.id)}
                          className="p-2 rounded-md hover:bg-destructive/10 text-destructive transition-colors"
                          aria-label="Delete workflow"
                          title="Delete"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </div>

                    <div className="space-y-2 mb-4 text-sm text-muted-foreground">
                      <div className="flex justify-between">
                        <span>Nodes:</span>
                        <span className="font-medium text-foreground">
                          {workflow.data.nodes.length}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span>Connections:</span>
                        <span className="font-medium text-foreground">
                          {workflow.data.edges.length}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span>Updated:</span>
                        <span className="font-medium text-foreground text-xs">
                          {formatDate(workflow.updatedAt)}
                        </span>
                      </div>
                    </div>

                    <div className="flex gap-2">
                      <button
                        onClick={() => handleLoad(workflow)}
                        className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-md hover:bg-primary/90 transition-colors"
                      >
                        <Play className="h-4 w-4" />
                        Load
                      </button>
                      <button
                        onClick={() => handleDuplicate(workflow)}
                        className="px-3 py-2 border border-border rounded-md hover:bg-accent transition-colors"
                        aria-label="Duplicate workflow"
                        title="Duplicate"
                      >
                        <Copy className="h-4 w-4" />
                      </button>
                      <button
                        onClick={() => handleExport(workflow)}
                        className="px-3 py-2 border border-border rounded-md hover:bg-accent transition-colors"
                        aria-label="Export workflow"
                        title="Export JSON"
                      >
                        <Download className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </>
        )}
      </main>

      <RenameWorkflowModal
        open={renameModalOpen}
        onOpenChange={setRenameModalOpen}
        currentName={selectedWorkflow?.name || ''}
        onRename={handleRenameSubmit}
      />

      <Footer />
    </div>
  )
}

export async function getStaticProps({ locale }: { locale: string }) {
  return {
    props: {
      ...(await serverSideTranslations(locale, ['common'])),
    },
  }
}

export default Workflow
