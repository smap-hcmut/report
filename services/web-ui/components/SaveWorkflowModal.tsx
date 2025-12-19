import { useState, useEffect } from 'react'
import * as Dialog from '@radix-ui/react-dialog'
import { X } from 'lucide-react'

interface SaveWorkflowModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSave: (name: string) => void
}

export default function SaveWorkflowModal({ open, onOpenChange, onSave }: SaveWorkflowModalProps) {
  const [workflowName, setWorkflowName] = useState('')

  useEffect(() => {
    if (open) {
      setWorkflowName('')
    }
  }, [open])

  const handleSave = () => {
    if (workflowName.trim()) {
      onSave(workflowName.trim())
      setWorkflowName('')
    }
  }

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && workflowName.trim()) {
      handleSave()
    }
  }

  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50" />
        <Dialog.Content className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-card border border-border rounded-lg p-6 w-full max-w-md z-50 shadow-xl">
          <div className="flex items-center justify-between mb-4">
            <Dialog.Title className="text-lg font-semibold">
              Save Workflow
            </Dialog.Title>
            <Dialog.Close className="rounded-md p-1 hover:bg-accent transition-colors">
              <X className="h-5 w-5" />
            </Dialog.Close>
          </div>

          <div className="space-y-4">
            <div>
              <label htmlFor="workflow-name" className="block text-sm font-medium mb-2">
                Workflow Name
              </label>
              <input
                id="workflow-name"
                type="text"
                value={workflowName}
                onChange={(e) => setWorkflowName(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="Enter workflow name..."
                className="w-full px-3 py-2 bg-background border border-border rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
                autoFocus
              />
            </div>

            <div className="flex gap-3 justify-end">
              <button
                onClick={() => onOpenChange(false)}
                className="px-4 py-2 rounded-md border border-border hover:bg-accent transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                disabled={!workflowName.trim()}
                className="px-4 py-2 rounded-md bg-primary text-primary-foreground hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Save
              </button>
            </div>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}
