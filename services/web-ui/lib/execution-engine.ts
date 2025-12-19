import { Node, Edge } from 'reactflow'

export type ExecutionStatus = 'idle' | 'running' | 'success' | 'error'

export interface NodeExecutionState {
  nodeId: string
  status: ExecutionStatus
  error?: string
  output?: Record<string, any>
}

export interface EdgeExecutionState {
  edgeId: string
  status: ExecutionStatus
}

export interface ExecutionContext {
  nodes: Node[]
  edges: Edge[]
  nodeStates: Map<string, NodeExecutionState>
  edgeStates: Map<string, EdgeExecutionState>
}

export class WorkflowExecutionEngine {
  private context: ExecutionContext

  constructor(nodes: Node[], edges: Edge[]) {
    this.context = {
      nodes,
      edges,
      nodeStates: new Map(),
      edgeStates: new Map()
    }

    this.initializeStates()
  }

  private initializeStates() {
    this.context.nodes.forEach(node => {
      this.context.nodeStates.set(node.id, {
        nodeId: node.id,
        status: 'idle',
        output: {}
      })
    })

    this.context.edges.forEach(edge => {
      this.context.edgeStates.set(edge.id, {
        edgeId: edge.id,
        status: 'idle'
      })
    })
  }

  private topologicalSort(): string[] {
    const graph = new Map<string, string[]>()
    const inDegree = new Map<string, number>()

    this.context.nodes.forEach(node => {
      graph.set(node.id, [])
      inDegree.set(node.id, 0)
    })

    this.context.edges.forEach(edge => {
      const from = edge.source
      const to = edge.target
      graph.get(from)?.push(to)
      inDegree.set(to, (inDegree.get(to) || 0) + 1)
    })

    const queue: string[] = []
    inDegree.forEach((degree, nodeId) => {
      if (degree === 0) {
        queue.push(nodeId)
      }
    })

    const sortedNodes: string[] = []
    while (queue.length > 0) {
      const nodeId = queue.shift()!
      sortedNodes.push(nodeId)

      const neighbors = graph.get(nodeId) || []
      neighbors.forEach(neighbor => {
        const degree = inDegree.get(neighbor)! - 1
        inDegree.set(neighbor, degree)
        if (degree === 0) {
          queue.push(neighbor)
        }
      })
    }

    if (sortedNodes.length !== this.context.nodes.length) {
      throw new Error('Workflow contains a cycle - cannot execute')
    }

    return sortedNodes
  }

  private validateDataType(value: any, allowedTypes: string[]): boolean {
    const valueType = this.getDataType(value)
    return allowedTypes.some(type => {
      if (type === valueType) return true
      if (type === 'array' && Array.isArray(value)) return true
      if (type === 'object' && typeof value === 'object' && !Array.isArray(value)) return true
      if (type === 'json' && typeof value === 'object') return true
      if (type === 'csv' && typeof value === 'string') return true
      if ((type === 'number' || type === 'int') && typeof value === 'number') return true
      return false
    })
  }

  private getDataType(value: any): string {
    if (value === null || value === undefined) return 'null'
    if (Array.isArray(value)) return 'array'
    if (typeof value === 'object') return 'object'
    if (typeof value === 'string') return 'string'
    if (typeof value === 'number') return Number.isInteger(value) ? 'int' : 'number'
    if (typeof value === 'boolean') return 'boolean'
    return 'unknown'
  }

  private getNodeInputData(nodeId: string): Map<string, any> {
    const inputData = new Map<string, any>()
    const incomingEdges = this.context.edges.filter(edge => edge.target === nodeId)

    incomingEdges.forEach(edge => {
      const sourceNode = this.context.nodes.find(n => n.id === edge.source)
      const sourceState = this.context.nodeStates.get(edge.source)

      if (sourceNode && sourceState?.output) {
        const sourceHandle = edge.sourceHandle || 'output-0'
        const targetHandle = edge.targetHandle || 'input-0'
        const outputValue = sourceState.output[sourceHandle]

        if (outputValue !== undefined) {
          inputData.set(targetHandle, outputValue)
        }
      }
    })

    return inputData
  }

  private async executeNode(nodeId: string, onUpdate: (context: ExecutionContext) => void): Promise<void> {
    const node = this.context.nodes.find(n => n.id === nodeId)
    if (!node) return

    const nodeState = this.context.nodeStates.get(nodeId)!

    nodeState.status = 'running'
    onUpdate(this.context)

    try {
      const config = node.data.config
      const isBasicNode = config.group === 'Basic'
      const isSocialMediaNode = config.group === 'Social Media'

      if (isSocialMediaNode && !node.data.selectedFunction) {
        throw new Error(`Social Media node "${config.name}" must have a function selected. Please configure the node.`)
      }

      if (isBasicNode) {
        const outputValues = node.data.outputValues || {}
        const outputHandles = config.links.filter((link: any) => link.type === 'output')

        outputHandles.forEach((handle: any, index: number) => {
          const handleKey = `output-${index}`
          const value = outputValues[handleKey]

          if (value && value.trim() !== '') {
            try {
              nodeState.output![handleKey] = JSON.parse(value)
            } catch {
              nodeState.output![handleKey] = value
            }
          }
        })

        nodeState.status = 'success'
      } else {
        const inputData = this.getNodeInputData(nodeId)
        const inputHandles = config.links.filter((link: any) => link.type === 'input')

        for (const [index, handle] of inputHandles.entries()) {
          const handleKey = `input-${index}`
          const value = inputData.get(handleKey)

          if (value === undefined) {
            throw new Error(`Missing input data for ${handle.label}`)
          }

          if (!this.validateDataType(value, handle.data_type)) {
            throw new Error(`Invalid data type for ${handle.label}. Expected: ${handle.data_type.join(' or ')}, got: ${this.getDataType(value)}`)
          }
        }

        const requirementHandles = config.links.filter((link: any) => link.type === 'requirement')

        for (const [index, handle] of requirementHandles.entries()) {
          const handleKey = `requirement-${index}`

          let value = inputData.get(handleKey)

          if (value === undefined) {

            const requirementValues = node.data.requirementValues || {}
            value = requirementValues[handleKey]
          }

          if (!value || (typeof value === 'string' && value.trim() === '')) {
            throw new Error(`Missing requirement: ${handle.label}`)
          }
        }

        await this.simulateNodeExecution(node, inputData)

        nodeState.status = 'success'
      }

      const outgoingEdges = this.context.edges.filter(edge => edge.source === nodeId)
      outgoingEdges.forEach(edge => {
        const edgeState = this.context.edgeStates.get(edge.id)!
        edgeState.status = 'success'
      })

    } catch (error) {
      nodeState.status = 'error'
      nodeState.error = error instanceof Error ? error.message : 'Unknown error'

      const outgoingEdges = this.context.edges.filter(edge => edge.source === nodeId)
      outgoingEdges.forEach(edge => {
        const edgeState = this.context.edgeStates.get(edge.id)!
        edgeState.status = 'error'
      })

      throw error
    } finally {
      onUpdate(this.context)
    }
  }

  private async simulateNodeExecution(node: Node, inputData: Map<string, any>): Promise<void> {
    await new Promise(resolve => setTimeout(resolve, 500))

    const outputHandles = node.data.config.links.filter((link: any) => link.type === 'output')
    const nodeState = this.context.nodeStates.get(node.id)!

    outputHandles.forEach((handle: any, index: number) => {
      const handleKey = `output-${index}`
      const firstInputValue = Array.from(inputData.values())[0]

      nodeState.output![handleKey] = {
        processed: true,
        data: firstInputValue,
        timestamp: new Date().toISOString()
      }
    })
  }

  async execute(onUpdate: (context: ExecutionContext) => void): Promise<void> {
    try {
      const executionOrder = this.topologicalSort()

      for (const nodeId of executionOrder) {
        const outgoingEdges = this.context.edges.filter(edge => edge.source === nodeId)

        outgoingEdges.forEach(edge => {
          const edgeState = this.context.edgeStates.get(edge.id)!
          edgeState.status = 'running'
        })
        onUpdate(this.context)

        await this.executeNode(nodeId, onUpdate)
      }

    } catch (error) {
      console.error('Workflow execution failed:', error)
      throw error
    }
  }

  getExecutionContext(): ExecutionContext {
    return this.context
  }
}
