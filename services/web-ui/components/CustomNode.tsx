import { memo } from 'react'
import { Handle, Position, NodeProps } from 'reactflow'
import { NodeConfig } from '@/config/nodes.config'

interface CustomNodeData {
  config: NodeConfig
  displayName?: string
  inputValues?: Record<string, string>
  requirementValues?: Record<string, string>
  outputValues?: Record<string, string>
}

function CustomNode({ data }: NodeProps<CustomNodeData>) {
  const { config } = data
  
  if (!config || !config.icon) {
    return null
  }
  
  const Icon = config.icon

  const getShapeClass = () => {
    switch (config.shape) {
      case 0:
        return 'rounded-lg'
      case 1:
        return 'rounded-2xl'
      case 2:
        return 'rounded-full'
      default:
        return 'rounded-lg'
    }
  }

  const getNodeSize = () => {
    switch (config.shape) {
      case 0:
        return 'w-20 h-20'
      case 1:
        return 'w-28 h-16'
      case 2:
        return 'w-20 h-20'
      default:
        return 'w-20 h-20'
    }
  }

  const inputHandles = config.links.filter(link => link.type === 'input')
  const requirementHandles = config.links.filter(link => link.type === 'requirement')
  const outputHandles = config.links.filter(link => link.type === 'output')

  return (
    <div className="relative">
      <div
        className={`${getNodeSize()} ${getShapeClass()} bg-card border-2 shadow-lg flex flex-col items-center justify-center p-2 transition-all hover:shadow-xl cursor-pointer`}
        style={{ borderColor: config.theme_color }}
      >
        <Icon className="text-2xl mb-1" style={{ color: config.theme_color }} />
        <p className="text-[10px] font-semibold text-center">{data.displayName || config.name}</p>
      </div>

      {inputHandles.map((handle, index) => {
        const totalHandles = inputHandles.length
        const offset = totalHandles > 1 
          ? ((index + 1) / (totalHandles + 1)) * 100 
          : 50
        
        return (
          <div 
            key={`input-${index}`} 
            className="absolute flex items-center"
            style={{ left: 0, top: `${offset}%`, transform: 'translateY(-50%)' }}
          >
            <Handle
              type="target"
              position={Position.Left}
              id={`input-${index}`}
              className="!w-2.5 !h-2.5 !border-2 !rounded-[2px]"
              style={{ 
                background: config.theme_color,
                borderColor: config.theme_color,
                position: 'absolute',
                left: 0,
                top: '50%',
                transform: 'translate(-50%, -50%)',
                zIndex: 10
              }}
            />
            <span className="text-[10px] font-medium text-muted-foreground mr-2 whitespace-nowrap -translate-x-[150%] pointer-events-none">
              {handle.label}
            </span>
          </div>
        )
      })}

      {requirementHandles.map((handle, index) => {
        const totalHandles = requirementHandles.length
        const offset = totalHandles > 1 
          ? ((index + 1) / (totalHandles + 1)) * 100 
          : 50
        
        return (
          <div 
            key={`requirement-${index}`} 
            className="absolute flex flex-col items-center"
            style={{ left: `${offset}%`, bottom: 0, transform: 'translateX(-50%)' }}
          >
            <Handle
              type="target"
              position={Position.Bottom}
              id={`requirement-${index}`}
              className="!w-2.5 !h-2.5 !border-2"
              style={{ 
                background: config.theme_color,
                borderColor: config.theme_color,
                position: 'absolute',
                left: '50%',
                bottom: 0,
                transform: 'translate(-50%, 50%) rotate(45deg)',
                borderRadius: '2px',
                zIndex: 10
              }}
            />
            <span className="text-[10px] font-medium text-muted-foreground whitespace-nowrap translate-y-[150%] mt-4 pointer-events-none">
              {handle.label}
            </span>
          </div>
        )
      })}

      {outputHandles.map((handle, index) => {
        const totalHandles = outputHandles.length
        const offset = totalHandles > 1 
          ? ((index + 1) / (totalHandles + 1)) * 100 
          : 50
        
        return (
          <div 
            key={`output-${index}`} 
            className="absolute flex items-center"
            style={{ right: 0, top: `${offset}%`, transform: 'translateY(-50%)' }}
          >
            <Handle
              type="source"
              position={Position.Right}
              id={`output-${index}`}
              className="!w-3.5 !h-1.5 !border-2 !rounded-sm"
              style={{ 
                background: config.theme_color,
                borderColor: config.theme_color,
                position: 'absolute',
                right: 0,
                top: '50%',
                transform: 'translate(50%, -50%)',
                zIndex: 10
              }}
            />
            <span className="text-[10px] font-medium text-muted-foreground ml-2 whitespace-nowrap translate-x-[150%] pointer-events-none">
              {handle.label}
            </span>
          </div>
        )
      })}
    </div>
  )
}

export default memo(CustomNode)
