import { Play, Pause, Save, Trash2 } from 'lucide-react'

interface CanvasControlsProps {
  onRun: () => void
  onPause: () => void
  onSave: () => void
  onClear: () => void
}

export default function CanvasControls({ onRun, onPause, onSave, onClear }: CanvasControlsProps) {
  return (
    <div className="absolute top-4 right-4 z-10 flex gap-2">
      <button
        onClick={onRun}
        className="p-2 bg-green-600 hover:bg-green-700 text-white rounded-md shadow-lg transition-colors flex items-center gap-1.5 text-sm font-medium"
        title="Run workflow"
      >
        <Play className="w-4 h-4" />
        Run
      </button>
      
      <button
        onClick={onPause}
        className="p-2 bg-yellow-600 hover:bg-yellow-700 text-white rounded-md shadow-lg transition-colors flex items-center gap-1.5 text-sm font-medium"
        title="Pause workflow"
      >
        <Pause className="w-4 h-4" />
        Pause
      </button>
      
      <button
        onClick={onSave}
        className="p-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md shadow-lg transition-colors flex items-center gap-1.5 text-sm font-medium"
        title="Save diagram"
      >
        <Save className="w-4 h-4" />
        Save
      </button>
      
      <button
        onClick={onClear}
        className="p-2 bg-red-600 hover:bg-red-700 text-white rounded-md shadow-lg transition-colors flex items-center gap-1.5 text-sm font-medium"
        title="Clear all nodes"
      >
        <Trash2 className="w-4 h-4" />
        Clear
      </button>
    </div>
  )
}
