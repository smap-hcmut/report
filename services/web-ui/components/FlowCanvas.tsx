import { useCallback, useRef, useState, DragEvent, useMemo, useEffect } from 'react'
import { useRouter } from 'next/router'
import ReactFlow, {
  ReactFlowProvider,
  addEdge,
  useNodesState,
  useEdgesState,
  Controls,
  Background,
  BackgroundVariant,
  Connection,
  Edge,
  NodeTypes,
  ConnectionLineType,
  MarkerType,
  Node,
} from 'reactflow'
import CustomNode from './CustomNode'
import NodeConfigModal from './NodeConfigModal'
import CanvasControls from './CanvasControls'
import SaveWorkflowModal from './SaveWorkflowModal'
import { nodesConfig } from '@/config/nodes.config'
import { useTheme } from 'next-themes'
import { storage } from '@/lib/storage'
import { WorkflowExecutionEngine, ExecutionContext } from '@/lib/execution-engine'

let id = 0
const getId = () => `node_${id++}`

function FlowCanvas() {
  const nodeTypes: NodeTypes = useMemo(() => ({ custom: CustomNode }), [])
  const reactFlowWrapper = useRef<HTMLDivElement>(null)
  const router = useRouter()

  const [nodes, setNodes, onNodesChange] = useNodesState([])
  const [edges, setEdges, onEdgesChange] = useEdgesState([])
  const [reactFlowInstance, setReactFlowInstance] = useState<any>(null)
  const [configModalOpen, setConfigModalOpen] = useState(false)
  const [saveModalOpen, setSaveModalOpen] = useState(false)
  const [selectedNode, setSelectedNode] = useState<Node | null>(null)
  const { theme } = useTheme()

  useEffect(() => {
    const loadDraftFromStorage = () => {
      const draft = storage.loadDraft()
      if (draft) {

        const migratedNodes = draft.nodes.map(node => {
          const isSocialMediaNode = node.data?.config?.group === 'Social Media'
          if (isSocialMediaNode && !node.data.selectedFunction) {
            return {
              ...node,
              data: {
                ...node.data,
                selectedFunction: '',
                functionFields: {}
              }
            }
          }
          return node
        })

        setNodes(migratedNodes)
        setEdges(draft.edges)

        if (draft.nodes.length > 0) {
          const maxId = draft.nodes.reduce((max, node) => {
            const nodeId = parseInt(node.id.split('_')[1] || '0')
            return Math.max(max, nodeId)
          }, 0)
          id = maxId + 1
        }
      }
    }

    loadDraftFromStorage()

    const handleRouteChange = (url: string) => {
      if (url.includes('/overview')) {
        loadDraftFromStorage()
      }
    }

    router.events?.on('routeChangeComplete', handleRouteChange)

    return () => {
      router.events?.off('routeChangeComplete', handleRouteChange)
    }
  }, [router.events, setNodes, setEdges])

  useEffect(() => {
    const timer = setTimeout(() => {
      if (nodes.length === 0 && edges.length === 0) {
        storage.clearDraft()
      } else {
        storage.saveDraft({ nodes, edges })
      }
    }, 1000)

    return () => clearTimeout(timer)
  }, [nodes, edges])

  const handleNodeDoubleClick = useCallback((_event: React.MouseEvent, node: Node) => {
    setSelectedNode(node)
    setConfigModalOpen(true)
  }, [])

  const handleSaveNodeConfig = useCallback((data: {
    displayName: string
    inputValues: Record<string, string>
    requirementValues: Record<string, string>
    outputValues: Record<string, string>
    selectedFunction?: string
    functionFields?: Record<string, string>
  }) => {
    if (!selectedNode) return

    const updatedNodeData = {
      ...selectedNode.data,
      displayName: data.displayName,
      inputValues: data.inputValues,
      requirementValues: data.requirementValues,
      outputValues: data.outputValues,
      selectedFunction: data.selectedFunction,
      functionFields: data.functionFields,
    }

    setNodes((nds) =>
      nds.map((node) => {
        if (node.id === selectedNode.id) {
          return {
            ...node,
            data: updatedNodeData,
          }
        }
        return node
      })
    )

    setSelectedNode({
      ...selectedNode,
      data: updatedNodeData,
    })
  }, [selectedNode, setNodes])

  const handleRun = useCallback(async () => {
    if (nodes.length === 0) {
      alert('No nodes to execute')
      return
    }

    try {
      const engine = new WorkflowExecutionEngine(nodes, edges)

      const updateVisualization = (context: ExecutionContext) => {
        const updatedEdges = edges.map(edge => {
          const edgeState = context.edgeStates.get(edge.id)
          if (!edgeState) return edge

          let strokeColor = '#6366f1'
          let animated = true

          if (edgeState.status === 'running') {
            strokeColor = '#3b82f6'
            animated = true
          } else if (edgeState.status === 'success') {
            strokeColor = '#10b981'
            animated = false
          } else if (edgeState.status === 'error') {
            strokeColor = '#ef4444'
            animated = false
          }

          return {
            ...edge,
            animated,
            style: { ...edge.style, stroke: strokeColor, strokeWidth: 2 },
            markerEnd: {
              type: MarkerType.ArrowClosed,
              color: strokeColor,
            },
          }
        })

        setEdges(updatedEdges)
      }

      await engine.execute(updateVisualization)

      alert('Workflow executed successfully!')
    } catch (error) {
      alert(`Workflow execution failed: ${error instanceof Error ? error.message : 'Unknown error'}`)
    }
  }, [nodes, edges, setEdges])

  const handlePause = useCallback(() => {
    console.log('Pausing workflow...')
  }, [])

  const handleSave = useCallback(() => {
    if (nodes.length === 0) {
      alert('Cannot save empty workflow')
      return
    }
    setSaveModalOpen(true)
  }, [nodes])

  const handleSaveWorkflow = useCallback((name: string) => {
    try {
      const workflowData = { nodes, edges }
      storage.saveWorkflow(name, workflowData)
      setSaveModalOpen(false)
      alert(`Workflow "${name}" saved successfully!`)
    } catch (error) {
      alert('Failed to save workflow')
    }
  }, [nodes, edges])

  const handleClear = useCallback(() => {
    if (confirm('Are you sure you want to clear all nodes and connections?')) {
      setNodes([])
      setEdges([])
      storage.clearDraft()
    }
  }, [setNodes, setEdges])

  const onConnect = useCallback(
    (params: Connection | Edge) => {
      setEdges((eds) =>
        addEdge(
          {
            ...params,
            type: 'default',
            animated: true,
            style: { stroke: '#6366f1', strokeWidth: 2 },
            markerEnd: {
              type: MarkerType.ArrowClosed,
              color: '#6366f1',
            },
          },
          eds
        )
      )
    },
    [setEdges]
  )

  const onDragOver = useCallback((event: DragEvent) => {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
  }, [])

  const onDrop = useCallback(
    (event: DragEvent) => {
      event.preventDefault()

      if (!reactFlowWrapper.current || !reactFlowInstance) return

      const reactFlowBounds = reactFlowWrapper.current.getBoundingClientRect()
      const nodeId = event.dataTransfer.getData('application/reactflow')

      if (!nodeId) return

      const nodeConfig = nodesConfig.find(n => n.id === nodeId)
      if (!nodeConfig) return

      const position = reactFlowInstance.project({
        x: event.clientX - reactFlowBounds.left,
        y: event.clientY - reactFlowBounds.top,
      })

      const newNode = {
        id: getId(),
        type: 'custom',
        position,
        data: {
          config: nodeConfig,
          displayName: nodeConfig.name,
          inputValues: {},
          requirementValues: {},
          outputValues: {},
          selectedFunction: '',
          functionFields: {}
        },
      }

      setNodes((nds) => nds.concat(newNode))
    },
    [reactFlowInstance, setNodes]
  )

  return (
    <>
      <div className="w-full h-full relative" ref={reactFlowWrapper}>
        <CanvasControls
          onRun={handleRun}
          onPause={handlePause}
          onSave={handleSave}
          onClear={handleClear}
        />

        <ReactFlow
          nodes={nodes}
          edges={edges}
          onNodesChange={onNodesChange}
          onEdgesChange={onEdgesChange}
          onConnect={onConnect}
          onNodeDoubleClick={handleNodeDoubleClick}
          onInit={setReactFlowInstance}
          onDrop={onDrop}
          onDragOver={onDragOver}
          nodeTypes={nodeTypes}
          connectionLineType={ConnectionLineType.Bezier}
          fitView
          className="bg-background"
        >
          <Controls className="!bg-card !border-border" />
          <Background
            variant={BackgroundVariant.Dots}
            gap={16}
            size={1}
            color={theme === 'dark' ? '#374151' : '#d1d5db'}
          />
        </ReactFlow>
      </div>

      <NodeConfigModal
        open={configModalOpen}
        onOpenChange={setConfigModalOpen}
        nodeData={selectedNode?.data ? {
          id: selectedNode.id,
          config: selectedNode.data.config,
          displayName: selectedNode.data.displayName,
          inputValues: selectedNode.data.inputValues,
          requirementValues: selectedNode.data.requirementValues,
          outputValues: selectedNode.data.outputValues,
          selectedFunction: selectedNode.data.selectedFunction,
          functionFields: selectedNode.data.functionFields
        } : null}
        edges={edges}
        nodes={nodes}
        onSave={handleSaveNodeConfig}
      />

      <SaveWorkflowModal
        open={saveModalOpen}
        onOpenChange={setSaveModalOpen}
        onSave={handleSaveWorkflow}
      />
    </>
  )
}

export default function FlowCanvasWrapper() {
  return (
    <ReactFlowProvider>
      <FlowCanvas />
    </ReactFlowProvider>
  )
}
