import { useState, useMemo } from 'react'
import { ChevronLeft, ChevronRight, ChevronDown } from 'lucide-react'
import { nodesConfig } from '@/config/nodes.config'
import NodeItem from './NodeItem'
import { motion, AnimatePresence } from 'framer-motion'
import * as Collapsible from '@radix-ui/react-collapsible'

export default function NodesSidebar() {
  const [isOpen, setIsOpen] = useState(true)
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(
    new Set(['Social Media', 'AI', 'Processing', 'Basic', 'Output', 'Charts', 'Action'])
  )

  const groupedNodes = useMemo(() => {
    const groups: Record<string, typeof nodesConfig> = {}
    
    nodesConfig.forEach(node => {
      if (!groups[node.group]) {
        groups[node.group] = []
      }
      groups[node.group].push(node)
    })
    
    return groups
  }, [])

  const groupOrder = ['Social Media', 'AI', 'Processing', 'Basic', 'Output', 'Charts', 'Action']

  const toggleGroup = (group: string) => {
    setExpandedGroups(prev => {
      const newSet = new Set(prev)
      if (newSet.has(group)) {
        newSet.delete(group)
      } else {
        newSet.add(group)
      }
      return newSet
    })
  }

  return (
    <div className="relative h-full">
      <AnimatePresence mode="wait">
        {isOpen ? (
          <motion.div
            key="sidebar-open"
            initial={{ width: 0, opacity: 0 }}
            animate={{ width: 280, opacity: 1 }}
            exit={{ width: 0, opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="h-full border-r border-border bg-card/50"
          >
            <div className="flex h-full flex-col">
              <div className="flex items-center justify-between border-b border-border px-4 py-3">
                <h3 className="text-sm font-semibold">Nodes</h3>
                <button
                  onClick={() => setIsOpen(false)}
                  className="rounded-md p-1 hover:bg-accent transition-colors"
                  aria-label="Collapse sidebar"
                >
                  <ChevronLeft className="h-4 w-4" />
                </button>
              </div>
              
              <div className="flex-1 overflow-y-auto p-4 space-y-4">
                {groupOrder.map((groupName) => {
                  const groupNodes = groupedNodes[groupName]
                  if (!groupNodes) return null
                  
                  const isExpanded = expandedGroups.has(groupName)
                  
                  return (
                    <Collapsible.Root
                      key={groupName}
                      open={isExpanded}
                      onOpenChange={() => toggleGroup(groupName)}
                    >
                      <Collapsible.Trigger className="flex items-center justify-between w-full px-2 py-1.5 rounded-md hover:bg-accent/50 transition-colors group">
                        <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wide">
                          {groupName}
                        </span>
                        <ChevronDown 
                          className={`h-3.5 w-3.5 text-muted-foreground transition-transform ${
                            isExpanded ? 'rotate-0' : '-rotate-90'
                          }`} 
                        />
                      </Collapsible.Trigger>
                      
                      <Collapsible.Content className="mt-2">
                        <div className="grid grid-cols-4 gap-3">
                          {groupNodes.map((node) => (
                            <NodeItem key={node.id} node={node} />
                          ))}
                        </div>
                      </Collapsible.Content>
                    </Collapsible.Root>
                  )
                })}
              </div>
            </div>
          </motion.div>
        ) : (
          <motion.div
            key="sidebar-closed"
            initial={{ width: 0, opacity: 0 }}
            animate={{ width: 48, opacity: 1 }}
            exit={{ width: 0, opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="h-full border-r border-border bg-card/50"
          >
            <div className="flex h-full flex-col items-center pt-3">
              <button
                onClick={() => setIsOpen(true)}
                className="rounded-md p-1 hover:bg-accent transition-colors"
                aria-label="Expand sidebar"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}
