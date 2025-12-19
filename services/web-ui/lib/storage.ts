import { Node, Edge } from 'reactflow'

export interface WorkflowData {
  nodes: Node[]
  edges: Edge[]
}

export interface SavedWorkflow {
  id: string
  name: string
  data: WorkflowData
  createdAt: string
  updatedAt: string
}

const DRAFT_KEY = 'workflow_draft'
const WORKFLOWS_KEY = 'saved_workflows'

export const storage = {
  saveDraft(data: WorkflowData) {
    try {
      localStorage.setItem(DRAFT_KEY, JSON.stringify(data))
    } catch (error) {
      console.error('Failed to save draft:', error)
    }
  },

  loadDraft(): WorkflowData | null {
    try {
      const data = localStorage.getItem(DRAFT_KEY)
      return data ? JSON.parse(data) : null
    } catch (error) {
      console.error('Failed to load draft:', error)
      return null
    }
  },

  clearDraft() {
    try {
      localStorage.removeItem(DRAFT_KEY)
    } catch (error) {
      console.error('Failed to clear draft:', error)
    }
  },

  saveWorkflow(name: string, data: WorkflowData): SavedWorkflow {
    try {
      const workflows = this.loadAllWorkflows()
      const now = new Date().toISOString()
      
      const newWorkflow: SavedWorkflow = {
        id: `workflow_${Date.now()}`,
        name,
        data,
        createdAt: now,
        updatedAt: now,
      }

      workflows.push(newWorkflow)
      localStorage.setItem(WORKFLOWS_KEY, JSON.stringify(workflows))
      
      return newWorkflow
    } catch (error) {
      console.error('Failed to save workflow:', error)
      throw error
    }
  },

  loadAllWorkflows(): SavedWorkflow[] {
    try {
      const data = localStorage.getItem(WORKFLOWS_KEY)
      return data ? JSON.parse(data) : []
    } catch (error) {
      console.error('Failed to load workflows:', error)
      return []
    }
  },

  loadWorkflow(id: string): SavedWorkflow | null {
    try {
      const workflows = this.loadAllWorkflows()
      return workflows.find(w => w.id === id) || null
    } catch (error) {
      console.error('Failed to load workflow:', error)
      return null
    }
  },

  deleteWorkflow(id: string) {
    try {
      const workflows = this.loadAllWorkflows()
      const filtered = workflows.filter(w => w.id !== id)
      localStorage.setItem(WORKFLOWS_KEY, JSON.stringify(filtered))
    } catch (error) {
      console.error('Failed to delete workflow:', error)
    }
  },

  updateWorkflow(id: string, name: string, data: WorkflowData) {
    try {
      const workflows = this.loadAllWorkflows()
      const index = workflows.findIndex(w => w.id === id)
      
      if (index !== -1) {
        workflows[index] = {
          ...workflows[index],
          name,
          data,
          updatedAt: new Date().toISOString(),
        }
        localStorage.setItem(WORKFLOWS_KEY, JSON.stringify(workflows))
      }
    } catch (error) {
      console.error('Failed to update workflow:', error)
    }
  },
}
