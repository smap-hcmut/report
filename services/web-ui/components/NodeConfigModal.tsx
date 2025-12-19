import { useState, useEffect } from 'react'
import * as Dialog from '@radix-ui/react-dialog'
import { X } from 'lucide-react'
import { NodeConfig } from '@/config/nodes.config'
import { getSocialMediaFunctions, getFunctionById } from '@/config/social-media-functions.config'

interface NodeConfigModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  nodeData: {
    id: string
    config: NodeConfig
    displayName?: string
    inputValues?: Record<string, string>
    requirementValues?: Record<string, string>
    outputValues?: Record<string, string>
    selectedFunction?: string
    functionFields?: Record<string, string>
  } | null
  edges: any[]
  nodes: any[]
  onSave: (data: {
    displayName: string
    inputValues: Record<string, string>
    requirementValues: Record<string, string>
    outputValues: Record<string, string>
    selectedFunction?: string
    functionFields?: Record<string, string>
  }) => void
}

export default function NodeConfigModal({ open, onOpenChange, nodeData, edges, nodes, onSave }: NodeConfigModalProps) {
  const [displayName, setDisplayName] = useState('')
  const [inputValues, setInputValues] = useState<Record<string, string>>({})
  const [requirementValues, setRequirementValues] = useState<Record<string, string>>({})
  const [outputValues, setOutputValues] = useState<Record<string, string>>({})
  const [selectedFunction, setSelectedFunction] = useState<string>('')
  const [functionFields, setFunctionFields] = useState<Record<string, string>>({})
  const [connectedData, setConnectedData] = useState<{
    inputs: Record<string, { value: string; sourceName: string }>,
    requirements: Record<string, { value: string; sourceName: string }>
  }>({ inputs: {}, requirements: {} })

  useEffect(() => {
    if (nodeData) {
      setDisplayName(nodeData.displayName || nodeData.config.name)
      setInputValues(nodeData.inputValues || {})
      setRequirementValues(nodeData.requirementValues || {})
      setOutputValues(nodeData.outputValues || {})
      setSelectedFunction(nodeData.selectedFunction || '')
      setFunctionFields(nodeData.functionFields || {})

      const inputs: Record<string, { value: string; sourceName: string }> = {}
      const requirements: Record<string, { value: string; sourceName: string }> = {}

      edges.forEach(edge => {
        if (edge.target === nodeData.id) {
          const sourceNode = nodes.find(n => n.id === edge.source)
          if (sourceNode && sourceNode.data.outputValues) {
            const targetHandle = edge.targetHandle || ''
            const sourceHandle = edge.sourceHandle || ''

            const sourceIndex = sourceHandle.split('-')[1]
            const outputKey = `output-${sourceIndex}`
            const outputValue = sourceNode.data.outputValues[outputKey]

            if (outputValue) {
              const sourceName = sourceNode.data.displayName || sourceNode.data.config.name

              if (targetHandle.startsWith('input-')) {
                inputs[targetHandle] = { value: outputValue, sourceName }
              } else if (targetHandle.startsWith('requirement-')) {
                requirements[targetHandle] = { value: outputValue, sourceName }
              }
            }
          }
        }
      })

      setConnectedData({ inputs, requirements })
    }
  }, [nodeData, edges, nodes])

  if (!nodeData) return null

  const inputHandles = nodeData.config.links.filter(link => link.type === 'input')
  const requirementHandles = nodeData.config.links.filter(link => link.type === 'requirement')
  const outputHandles = nodeData.config.links.filter(link => link.type === 'output')

  const isBasicNode = nodeData.config.group === 'Basic'
  const isSocialMediaNode = nodeData.config.group === 'Social Media'
  const availableFunctions = isSocialMediaNode ? getSocialMediaFunctions(nodeData.config.name) : []
  const currentFunction = selectedFunction ? getFunctionById(nodeData.config.name, selectedFunction) : null

  const handleSave = () => {

    if (isSocialMediaNode) {
      if (!selectedFunction) {
        alert('Please select a function for this Social Media node')
        return
      }

      if (currentFunction) {
        for (const field of currentFunction.fields) {
          if (field.required) {
            const value = functionFields[field.name]
            if (!value || (typeof value === 'string' && value.trim() === '')) {
              alert(`Please fill in required field: ${field.label}`)
              return
            }
          }
        }
      }
    }

    onSave({
      displayName,
      inputValues,
      requirementValues,
      outputValues,
      selectedFunction: isSocialMediaNode ? selectedFunction : undefined,
      functionFields: isSocialMediaNode ? functionFields : undefined
    })
    onOpenChange(false)
  }

  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50" />
        <Dialog.Content className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-card border border-border rounded-lg shadow-xl p-6 w-full max-w-md z-50 max-h-[80vh] overflow-y-auto">
          <div className="flex items-center justify-between mb-4">
            <Dialog.Title className="text-lg font-semibold">
              Configure Node
            </Dialog.Title>
            <Dialog.Close asChild>
              <button className="p-1 hover:bg-accent rounded-md transition-colors">
                <X className="w-5 h-5" />
              </button>
            </Dialog.Close>
          </div>

          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium mb-1.5 block">
                Display Name
              </label>
              <input
                type="text"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                className="w-full px-3 py-2 bg-background border border-border rounded-md focus:outline-none focus:ring-2 focus:ring-primary/50"
                placeholder={nodeData.config.name}
              />
            </div>

            {isSocialMediaNode && (
              <div>
                <label className="text-sm font-medium mb-1.5 block">
                  Function
                </label>
                <select
                  value={selectedFunction}
                  onChange={(e) => {
                    setSelectedFunction(e.target.value)
                    setFunctionFields({})
                  }}
                  className="w-full px-3 py-2 bg-background border border-border rounded-md focus:outline-none focus:ring-2 focus:ring-primary/50"
                >
                  <option value="">Select a function...</option>
                  {availableFunctions.map(func => (
                    <option key={func.id} value={func.id}>
                      {func.label}
                    </option>
                  ))}
                </select>
                {currentFunction && (
                  <p className="text-xs text-muted-foreground mt-1">
                    {currentFunction.description}
                  </p>
                )}
              </div>
            )}

            {isSocialMediaNode && currentFunction && (
              <div>
                <h3 className="text-sm font-semibold mb-2">Function Parameters</h3>
                {currentFunction.fields.map(field => (
                  <div key={field.name} className="mb-3">
                    <label className="text-sm font-medium mb-1.5 block">
                      {field.label}
                      {field.required && <span className="text-destructive ml-1">*</span>}
                    </label>
                    {field.type === 'textarea' ? (
                      <textarea
                        value={functionFields[field.name] || ''}
                        onChange={(e) => setFunctionFields({
                          ...functionFields,
                          [field.name]: e.target.value
                        })}
                        className="w-full px-3 py-2 bg-background border border-border rounded-md focus:outline-none focus:ring-2 focus:ring-primary/50 min-h-[80px]"
                        placeholder={field.placeholder}
                        required={field.required}
                      />
                    ) : field.type === 'select' ? (
                      <select
                        value={functionFields[field.name] || ''}
                        onChange={(e) => setFunctionFields({
                          ...functionFields,
                          [field.name]: e.target.value
                        })}
                        className="w-full px-3 py-2 bg-background border border-border rounded-md focus:outline-none focus:ring-2 focus:ring-primary/50"
                      >
                        <option value="">Select...</option>
                        {field.options?.map(opt => (
                          <option key={opt} value={opt}>{opt}</option>
                        ))}
                      </select>
                    ) : (
                      <input
                        type={field.type}
                        value={functionFields[field.name] || ''}
                        onChange={(e) => setFunctionFields({
                          ...functionFields,
                          [field.name]: e.target.value
                        })}
                        className="w-full px-3 py-2 bg-background border border-border rounded-md focus:outline-none focus:ring-2 focus:ring-primary/50"
                        placeholder={field.placeholder}
                        required={field.required}
                      />
                    )}
                  </div>
                ))}
              </div>
            )}

            {inputHandles.length > 0 && !isSocialMediaNode && (
              <div>
                <h3 className="text-sm font-semibold mb-2">Input Values</h3>
                {inputHandles.map((handle, index) => {
                  const handleKey = `input-${index}`
                  const connected = connectedData.inputs[handleKey]

                  return (
                    <div key={handleKey} className="mb-3">
                      <label className="text-sm font-medium mb-1.5 block">
                        {handle.label}
                        {connected && (
                          <span className="ml-2 text-xs text-primary/70">
                            (from {connected.sourceName})
                          </span>
                        )}
                      </label>
                      <input
                        type="text"
                        value={connected ? connected.value : (inputValues[handleKey] || '')}
                        onChange={(e) => setInputValues({
                          ...inputValues,
                          [handleKey]: e.target.value
                        })}
                        readOnly={!!connected}
                        className={`w-full px-3 py-2 border rounded-md ${
                          connected
                            ? 'bg-primary/5 border-primary/30 text-foreground cursor-not-allowed'
                            : 'bg-background border-border focus:outline-none focus:ring-2 focus:ring-primary/50'
                        }`}
                        placeholder={connected ? '' : `Enter ${handle.label.toLowerCase()}`}
                      />
                    </div>
                  )
                })}
              </div>
            )}

            {requirementHandles.length > 0 && !isSocialMediaNode && (
              <div>
                <h3 className="text-sm font-semibold mb-2">Requirements</h3>
                {requirementHandles.map((handle, index) => {
                  const handleKey = `requirement-${index}`
                  const connected = connectedData.requirements[handleKey]

                  return (
                    <div key={handleKey} className="mb-3">
                      <label className="text-sm font-medium mb-1.5 block">
                        {handle.label}
                        {connected && (
                          <span className="ml-2 text-xs text-primary/70">
                            (from {connected.sourceName})
                          </span>
                        )}
                      </label>
                      {handle.data_type.includes('text') || handle.label.toLowerCase().includes('text') ? (
                        <textarea
                          value={connected ? connected.value : (requirementValues[handleKey] || '')}
                          onChange={(e) => setRequirementValues({
                            ...requirementValues,
                            [handleKey]: e.target.value
                          })}
                          readOnly={!!connected}
                          className={`w-full px-3 py-2 border rounded-md min-h-[80px] ${
                            connected
                              ? 'bg-primary/5 border-primary/30 text-foreground cursor-not-allowed'
                              : 'bg-background border-border focus:outline-none focus:ring-2 focus:ring-primary/50'
                          }`}
                          placeholder={connected ? '' : `Enter ${handle.label.toLowerCase()}`}
                        />
                      ) : (
                        <input
                          type="text"
                          value={connected ? connected.value : (requirementValues[handleKey] || '')}
                          onChange={(e) => setRequirementValues({
                            ...requirementValues,
                            [handleKey]: e.target.value
                          })}
                          readOnly={!!connected}
                          className={`w-full px-3 py-2 border rounded-md ${
                            connected
                              ? 'bg-primary/5 border-primary/30 text-foreground cursor-not-allowed'
                              : 'bg-background border-border focus:outline-none focus:ring-2 focus:ring-primary/50'
                          }`}
                          placeholder={connected ? '' : `Enter ${handle.label.toLowerCase()}`}
                        />
                      )}
                    </div>
                  )
                })}
              </div>
            )}

            {outputHandles.length > 0 && (
              <div>
                <h3 className="text-sm font-semibold mb-2">
                  {isBasicNode ? 'Input Data' : 'Output Data'}
                </h3>
                {outputHandles.map((handle, index) => (
                  <div key={`output-${index}`} className="mb-3">
                    <label className="text-sm font-medium mb-1.5 block">
                      {handle.label}
                    </label>
                    <textarea
                      value={outputValues[`output-${index}`] || ''}
                      onChange={(e) => setOutputValues({
                        ...outputValues,
                        [`output-${index}`]: e.target.value
                      })}
                      className="w-full px-3 py-2 bg-background border border-border rounded-md focus:outline-none focus:ring-2 focus:ring-primary/50 min-h-[100px] font-mono text-sm"
                      placeholder={isBasicNode ? `Enter ${handle.label.toLowerCase()} data...` : 'Output data will appear here...'}
                    />
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="flex gap-3 mt-6">
            <Dialog.Close asChild>
              <button className="flex-1 px-4 py-2 bg-accent hover:bg-accent/80 rounded-md transition-colors font-medium">
                Cancel
              </button>
            </Dialog.Close>
            <button
              onClick={handleSave}
              className="flex-1 px-4 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-md transition-colors font-medium"
            >
              Save
            </button>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}
