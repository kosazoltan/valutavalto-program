import { useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { Lock, Check, X, Loader2, Minus, ChevronLeft } from 'lucide-react'
import { CashierHeader } from '../../components/cashier/CashierHeader'

/**
 * Napzaras wizard — 9 lepesu ellenorzesi lanc.
 *
 * Legacy: NAPZAR.DLL
 * 1. MTCN szam ellenorzes (Western Union)
 * 2. Esti cimletez es
 * 3. Kezelesi dij cimletezes
 * 4. Western Union cimletezes
 * 5. AFA cimletezes
 * 6. Foglalo cimletezes
 * 7. E-kereskedelem cimletezes
 * 8. Egyeb cimletezesek (AXA/MoneyGram)
 * 9. NAV kontroll es napi jelentes
 */

type StepStatus = 'pending' | 'running' | 'done' | 'failed' | 'skipped'

interface ClosingStep {
  id: number
  label: string
  status: StepStatus
  message?: string
  completedAt?: string
}

const INITIAL_STEPS: ClosingStep[] = [
  { id: 1, label: 'MTCN szam ellenorzes (Western Union)', status: 'pending' },
  { id: 2, label: 'Esti penztar cimletezese', status: 'pending' },
  { id: 3, label: 'Kezelesi dij cimletezes', status: 'pending' },
  { id: 4, label: 'Western Union cimletezes', status: 'pending' },
  { id: 5, label: 'AFA cimletezes', status: 'pending' },
  { id: 6, label: 'Foglalo cimletezes', status: 'pending' },
  { id: 7, label: 'E-kereskedelem cimletezes', status: 'pending' },
  { id: 8, label: 'Egyeb cimletezesek (AXA/MoneyGram)', status: 'pending' },
  { id: 9, label: 'NAV kontroll es napi jelentes', status: 'pending' },
]

export default function ClosingWizardPage() {
  const navigate = useNavigate()
  const [steps, setSteps] = useState<ClosingStep[]>(INITIAL_STEPS)
  const [isRunning, setIsRunning] = useState(false)

  const completedCount = steps.filter((s) => s.status === 'done' || s.status === 'skipped').length
  const failedCount = steps.filter((s) => s.status === 'failed').length
  const progress = (completedCount / steps.length) * 100
  const canFinalize = completedCount === steps.length && failedCount === 0

  const runClosing = useCallback(async () => {
    setIsRunning(true)

    for (let i = 0; i < steps.length; i++) {
      // Lepes inditasa
      setSteps((prev) =>
        prev.map((s, idx) => (idx === i ? { ...s, status: 'running' as StepStatus } : s))
      )

      // Szimulalt var (production-ben API hivas)
      await new Promise((r) => setTimeout(r, 800 + Math.random() * 400))

      // Szimulalt eredmeny (production-ben a backend adja)
      const now = new Date().toLocaleTimeString('hu-HU')
      const passed = Math.random() > 0.1 // 90% PASS

      setSteps((prev) =>
        prev.map((s, idx) =>
          idx === i
            ? {
                ...s,
                status: passed ? 'done' : 'failed',
                message: passed ? 'Rendben' : 'Elter es talalva!',
                completedAt: now,
              }
            : s
        )
      )

      // Ha FAIL, megallunk
      if (!passed) {
        setIsRunning(false)
        return
      }
    }

    setIsRunning(false)
  }, [steps.length])

  const handleFinalize = useCallback(() => {
    if (!canFinalize) return
    alert('Napzaras vegrehajtva! A nap lezarva.')
    navigate('/')
  }, [canFinalize, navigate])

  const statusIcon = (status: StepStatus) => {
    switch (status) {
      case 'done':
        return <Check className="w-5 h-5 text-green-500" />
      case 'failed':
        return <X className="w-5 h-5 text-red-500" />
      case 'running':
        return <Loader2 className="w-5 h-5 text-blue-500 animate-spin" />
      case 'skipped':
        return <Minus className="w-5 h-5 text-gray-400" />
      default:
        return <div className="w-5 h-5 rounded-full border-2 border-gray-300 dark:border-gray-600" />
    }
  }

  const statusText = (step: ClosingStep) => {
    switch (step.status) {
      case 'done':
        return <span className="text-green-600 dark:text-green-400 font-medium">RENDBEN ({step.completedAt})</span>
      case 'failed':
        return <span className="text-red-600 dark:text-red-400 font-medium">HIBA: {step.message}</span>
      case 'running':
        return <span className="text-blue-600 dark:text-blue-400 font-medium animate-pulse">FOLYAMATBAN...</span>
      case 'skipped':
        return <span className="text-gray-400">KIHAGYVA</span>
      default:
        return <span className="text-gray-400">VAR</span>
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <CashierHeader />

      <div className="max-w-4xl mx-auto p-8">
        {/* FEJLEC */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center gap-3">
            <button
              onClick={() => navigate('/')}
              className="p-2 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
            >
              <ChevronLeft className="w-6 h-6" />
            </button>
            <Lock className="w-8 h-8 text-[var(--primary)]" />
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">NAPZARAS WIZARD</h1>
          </div>
          <span className="text-lg font-semibold bg-gray-200 dark:bg-gray-700 px-4 py-2 rounded-lg">
            {completedCount} / {steps.length} kesz
          </span>
        </div>

        {/* PROGRESS BAR */}
        <div className="mb-8">
          <div className="flex justify-between text-sm text-gray-600 dark:text-gray-400 mb-2">
            <span>Elorehaladas</span>
            <span>{Math.round(progress)}%</span>
          </div>
          <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-green-500 to-emerald-600 transition-all duration-500"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>

        {/* ELLENORZESI LISTA */}
        <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden mb-8">
          {steps.map((step) => (
            <div
              key={step.id}
              className={`flex items-center justify-between px-6 py-4 border-b border-gray-100 dark:border-gray-700 last:border-b-0 transition-colors ${
                step.status === 'running' ? 'bg-blue-50 dark:bg-blue-950/20' : ''
              } ${step.status === 'failed' ? 'bg-red-50 dark:bg-red-950/20' : ''}`}
            >
              <div className="flex items-center gap-4">
                <span className="w-8 h-8 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center text-sm font-bold text-gray-600 dark:text-gray-300">
                  {step.id}
                </span>
                {statusIcon(step.status)}
                <span className="font-medium text-gray-900 dark:text-white">{step.label}</span>
              </div>
              <div>{statusText(step)}</div>
            </div>
          ))}
        </div>

        {/* GOMBOK */}
        <div className="flex justify-center gap-4">
          {!isRunning && completedCount === 0 && (
            <button
              onClick={runClosing}
              className="px-8 py-4 bg-blue-600 hover:bg-blue-700 text-white text-xl font-bold rounded-xl shadow-lg transition-colors"
            >
              ELLENORZES INDITASA
            </button>
          )}

          {failedCount > 0 && !isRunning && (
            <button
              onClick={() => {
                setSteps(INITIAL_STEPS)
              }}
              className="px-8 py-4 bg-gray-600 hover:bg-gray-700 text-white text-xl font-bold rounded-xl shadow-lg transition-colors"
            >
              UJRA
            </button>
          )}

          <button
            onClick={handleFinalize}
            disabled={!canFinalize}
            className={`px-10 py-4 text-xl font-bold rounded-xl shadow-lg transition-all ${
              canFinalize
                ? 'bg-gradient-to-r from-green-600 to-emerald-700 hover:from-green-700 hover:to-emerald-800 text-white'
                : 'bg-gray-300 dark:bg-gray-700 text-gray-500 dark:text-gray-400 cursor-not-allowed'
            }`}
          >
            {canFinalize ? (
              <span className="flex items-center gap-3">
                <Check className="w-6 h-6" />
                RENDBEN — Napzaras vegrehajtasa
              </span>
            ) : (
              'Minden lepes szukseges a napzarashoz'
            )}
          </button>
        </div>
      </div>
    </div>
  )
}
