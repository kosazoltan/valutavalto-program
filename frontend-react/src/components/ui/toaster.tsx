import { useEffect, useState } from 'react'
import { CheckCircle, XCircle, AlertCircle, X, Info } from 'lucide-react'

export interface Toast {
  id: string
  type: 'success' | 'error' | 'warning' | 'info'
  title: string
  message?: string
  duration?: number
}

let toastListeners: ((toasts: Toast[]) => void)[] = []
let toasts: Toast[] = []

const updateToasts = (newToasts: Toast[]) => {
  toasts = newToasts
  toastListeners.forEach(listener => listener(toasts))
}

export const toast = {
  success: (title: string, message?: string) => {
    const id = Date.now().toString()
    updateToasts([...toasts, { id, type: 'success', title, message, duration: 3000 }])
  },
  error: (title: string, message?: string) => {
    const id = Date.now().toString()
    updateToasts([...toasts, { id, type: 'error', title, message, duration: 5000 }])
  },
  warning: (title: string, message?: string) => {
    const id = Date.now().toString()
    updateToasts([...toasts, { id, type: 'warning', title, message, duration: 4000 }])
  },
  info: (title: string, message?: string) => {
    const id = Date.now().toString()
    updateToasts([...toasts, { id, type: 'info', title, message, duration: 3000 }])
  },
  dismiss: (id: string) => {
    updateToasts(toasts.filter(t => t.id !== id))
  }
}

export function Toaster() {
  const [currentToasts, setCurrentToasts] = useState<Toast[]>([])

  useEffect(() => {
    const listener = (newToasts: Toast[]) => setCurrentToasts([...newToasts])
    toastListeners.push(listener)
    return () => {
      toastListeners = toastListeners.filter(l => l !== listener)
    }
  }, [])

  useEffect(() => {
    currentToasts.forEach(t => {
      if (t.duration) {
        const timer = setTimeout(() => {
          toast.dismiss(t.id)
        }, t.duration)
        return () => clearTimeout(timer)
      }
    })
  }, [currentToasts])

  const getIcon = (type: Toast['type']) => {
    switch (type) {
      case 'success': return <CheckCircle className="text-green-500" size={20} />
      case 'error': return <XCircle className="text-red-500" size={20} />
      case 'warning': return <AlertCircle className="text-yellow-500" size={20} />
      case 'info': return <Info className="text-blue-500" size={20} />
    }
  }

  const getStyles = (type: Toast['type']) => {
    switch (type) {
      case 'success': return 'bg-green-50 border-green-200'
      case 'error': return 'bg-red-50 border-red-200'
      case 'warning': return 'bg-yellow-50 border-yellow-200'
      case 'info': return 'bg-blue-50 border-blue-200'
    }
  }

  return (
    <div className="fixed bottom-4 right-4 z-50 space-y-2">
      {currentToasts.map(t => (
        <div
          key={t.id}
          className={`flex items-start gap-3 p-4 rounded-lg border shadow-lg min-w-[300px] max-w-md animate-slide-in ${getStyles(t.type)}`}
        >
          {getIcon(t.type)}
          <div className="flex-1">
            <div className="font-semibold">{t.title}</div>
            {t.message && <div className="text-sm text-gray-600">{t.message}</div>}
          </div>
          <button
            onClick={() => toast.dismiss(t.id)}
            className="text-gray-400 hover:text-gray-600"
          >
            <X size={16} />
          </button>
        </div>
      ))}
    </div>
  )
}
