import { NodeConfig } from '@/config/nodes.config'
import * as Tooltip from '@radix-ui/react-tooltip'

interface NodeItemProps {
  node: NodeConfig
  onDragStart?: (node: NodeConfig) => void
}

export default function NodeItem({ node, onDragStart }: NodeItemProps) {
  const Icon = node.icon

  const handleDragStart = (e: React.DragEvent) => {
    e.dataTransfer.setData('application/reactflow', node.id)
    e.dataTransfer.effectAllowed = 'move'
    onDragStart?.(node)
  }

  return (
    <Tooltip.Provider delayDuration={200}>
      <Tooltip.Root>
        <Tooltip.Trigger asChild>
          <div
            draggable
            onDragStart={handleDragStart}
            className="group relative flex h-12 w-12 cursor-grab items-center justify-center rounded-md border border-border bg-card transition-all hover:scale-105 hover:shadow-md active:cursor-grabbing active:scale-95"
            style={{
              borderColor: node.theme_color + '40',
            }}
          >
            <Icon 
              className="h-6 w-6 transition-colors" 
              style={{ color: node.theme_color }}
            />
            <div
              className="absolute inset-0 rounded-md opacity-0 transition-opacity group-hover:opacity-10"
              style={{ backgroundColor: node.theme_color }}
            />
          </div>
        </Tooltip.Trigger>
        <Tooltip.Portal>
          <Tooltip.Content
            side="right"
            sideOffset={8}
            className="z-50 overflow-hidden rounded-md border bg-popover px-3 py-1.5 text-sm text-popover-foreground shadow-md animate-in fade-in-0 zoom-in-95"
          >
            {node.name}
            <Tooltip.Arrow className="fill-popover" />
          </Tooltip.Content>
        </Tooltip.Portal>
      </Tooltip.Root>
    </Tooltip.Provider>
  )
}
