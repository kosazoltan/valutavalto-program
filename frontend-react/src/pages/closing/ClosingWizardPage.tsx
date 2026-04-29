import { useState, useCallback, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Lock, Check, X, Loader2, Minus, ChevronLeft, Coins } from 'lucide-react'
import { CashierHeader } from '../../components/cashier/CashierHeader'
import { toast } from '../../components/ui/toaster'
import { closingWizardApi } from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'

/** HUF cimletek — csökkeno sorrendben */
const HUF_DENOMINATIONS = [20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5] as const

/**
 * Napzaras wizard — backend-driven ellenorzesi lanc.
 *
 * Legacy: NAPZAR.DLL
 * A backend closingWizardApi vezérli a lépéseket — NINCS lokális szimuláció.
 *
 * Flow:
 *   Step 1 (MTCN) fut automatikusan →
 *   PAUSE: felhasználó kitölti a címletezést és rögzíti →
 *   Steps 2-9 futnak automatikusan →
 *   Finalize (csak ha denomSubmitted + minden step PASS)
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
  { id: 1, label: 'MTCN szám ellenőrzés (Western Union)', status: 'pending' },
  { id: 2, label: 'Esti pénztár címletezése', status: 'pending' },
  { id: 3, label: 'Kezelési díj címletezés', status: 'pending' },
  { id: 4, label: 'Western Union címletezés', status: 'pending' },
  { id: 5, label: 'ÁFA címletezés', status: 'pending' },
  { id: 6, label: 'Foglaló címletezés', status: 'pending' },
  { id: 7, label: 'E-kereskedelem címletezés', status: 'pending' },
  { id: 8, label: 'Egyéb címletezések (AXA/MoneyGram)', status: 'pending' },
  { id: 9, label: 'NAV kontroll és napi jelentés', status: 'pending' },
]

export default function ClosingWizardPage() {
  const navigate = useNavigate()
  const worker = useAuthStore((s) => s.worker)
  const [steps, setSteps] = useState<ClosingStep[]>(INITIAL_STEPS)
  const [isRunning, setIsRunning] = useState(false)
  const [wizardId, setWizardId] = useState<string | null>(null)

  // Denomination input state
  const [denomQuantities, setDenomQuantities] = useState<Record<number, number>>(
    () => Object.fromEntries(HUF_DENOMINATIONS.map((d) => [d, 0]))
  )
  const denomTotal = useMemo(
    () => HUF_DENOMINATIONS.reduce((sum, d) => sum + d * (denomQuantities[d] ?? 0), 0),
    [denomQuantities],
  )
  const [denomSubmitted, setDenomSubmitted] = useState(false)

  // Wizard pauses after step 1 for denomination input
  const [waitingForDenom, setWaitingForDenom] = useState(false)

  const completedCount = steps.filter((s) => s.status === 'done' || s.status === 'skipped').length
  const failedCount = steps.filter((s) => s.status === 'failed').length
  const progress = (completedCount / steps.length) * 100

  // Finalize requires ALL steps PASS **and** denomination submitted
  const canFinalize = completedCount === steps.length && failedCount === 0 && denomSubmitted

  /** Run backend steps from `from` to `to` (0-indexed). Returns true if all passed. */
  const runSteps = useCallback(async (wizId: string, from: number, to: number): Promise<boolean> => {
    for (let i = from; i <= to; i++) {
      setSteps((prev) =>
        prev.map((s, idx) => (idx === i ? { ...s, status: 'running' as StepStatus } : s))
      )

      try {
        const result = await closingWizardApi.navigate(wizId, i + 1)
        const stepData = result.steps?.find((s) => s.stepNumber === i + 1)
        const now = new Date().toLocaleTimeString('hu-HU')
        const passed = stepData ? stepData.completed : true

        setSteps((prev) =>
          prev.map((s, idx) =>
            idx === i
              ? {
                  ...s,
                  status: passed ? 'done' : 'failed',
                  // Issue #117: a backend stepData.message mezo tartalmazza a valodi hibauzenetet,
                  // NEM a stepDescription (ami a lepes leirasa). Priority: stepData.message -> stepDescription -> fallback.
                  message: passed
                    ? 'Rendben'
                    : (
                        (typeof stepData?.stepData?.message === 'string' ? stepData.stepData.message : undefined)
                        ?? stepData?.stepDescription
                        ?? 'Eltérés találva!'
                      ),
                  completedAt: now,
                }
              : s
          )
        )

        if (!passed) return false
      } catch (stepError) {
        const now = new Date().toLocaleTimeString('hu-HU')
        const errorMsg = stepError instanceof Error ? stepError.message : 'Ismeretlen hiba'

        setSteps((prev) =>
          prev.map((s, idx) =>
            idx === i
              ? { ...s, status: 'failed', message: errorMsg, completedAt: now }
              : s
          )
        )
        return false
      }
    }
    return true
  }, [])

  /** Phase 1: start wizard + run step 1, then pause for denomination input */
  const runClosing = useCallback(async () => {
    // 2026-04-29 B28 defensive logging: a click utan a teszt idejen
    // semmi nem tortenhetett — most kotelezo toast minden esetre + console
    console.log('[Napzaras] runClosing started, worker=', worker?.workerCode, worker?.branchId)

    if (!worker) {
      toast.error('Hiba', 'Nincs bejelentkezett felhasznalo!')
      return
    }

    setIsRunning(true)
    toast.info('Napzaras inditasa', 'Wizard inditasa folyamatban...')

    try {
      const wizard = await closingWizardApi.start(
        worker.branchId,
        undefined,
        'DAILY',
        String(worker.id),
      )
      console.log('[Napzaras] wizard started, id=', wizard.id)
      setWizardId(wizard.id)

      // Run step 1 (MTCN check)
      const step1Ok = await runSteps(wizard.id, 0, 0)
      if (!step1Ok) {
        toast.warning('Step 1 sikertelen', 'A MTCN ellenorzes nem ment at')
        setIsRunning(false)
        return
      }

      toast.success('Step 1 OK', 'Most rogzitsd a HUF cimletezest')

      // Pause: wait for denomination input before continuing
      setIsRunning(false)
      setWaitingForDenom(true)
    } catch (err) {
      console.error('[Napzaras] start failed:', err)
      const errorMsg = err instanceof Error ? err.message : 'Nem sikerult a napzaras wizard inditasa'
      toast.error('Napzaras hiba', errorMsg)
      setIsRunning(false)
    }
  }, [worker, runSteps])

  /** Phase 2: user submitted denomination → persist to backend, then continue steps 2-9 */
  const continueAfterDenom = useCallback(async () => {
    if (!wizardId) return

    setIsRunning(true)

    // Submit denomination data to backend before continuing
    try {
      const hufDenoms: Record<number, number> = {}
      for (const [faceValue, qty] of Object.entries(denomQuantities)) {
        if (qty > 0) hufDenoms[Number(faceValue)] = qty
      }
      await closingWizardApi.submitDenominations(wizardId, { HUF: hufDenoms })
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Cimletezés rögzítés sikertelen'
      toast.error('Cimletezés hiba', errorMsg)
      setIsRunning(false)
      return
    }

    setDenomSubmitted(true)
    setWaitingForDenom(false)

    // Run steps 2-9
    await runSteps(wizardId, 1, steps.length - 1)
    setIsRunning(false)
  }, [wizardId, denomQuantities, steps.length, runSteps])

  const handleFinalize = useCallback(async () => {
    if (!canFinalize || !wizardId || !worker) return

    try {
      await closingWizardApi.finalize(wizardId, String(worker.id))
      toast.success('Napzárás végrehajtva', 'A nap lezárva.')
      navigate('/')
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Napzárás véglegesítés sikertelen'
      toast.error('Hiba', errorMsg)
    }
  }, [canFinalize, wizardId, worker, navigate])

  const handleCancel = useCallback(async () => {
    if (wizardId) {
      try {
        await closingWizardApi.cancel(wizardId)
      } catch {
        // Wizard cancel hiba nem blokkoló
      }
    }
    setSteps(INITIAL_STEPS)
    setWizardId(null)
    setWaitingForDenom(false)
    setDenomSubmitted(false)
    setDenomQuantities(Object.fromEntries(HUF_DENOMINATIONS.map((d) => [d, 0])))
  }, [wizardId])

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
        return <span className="text-gray-400">VÁR</span>
    }
  }

  // Denomination inputs enabled only when waiting for denom input
  const denomEditable = waitingForDenom && !denomSubmitted && !isRunning

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
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">NAPZÁRÁS WIZARD</h1>
          </div>
          <span className="text-lg font-semibold bg-gray-200 dark:bg-gray-700 px-4 py-2 rounded-lg">
            {completedCount} / {steps.length} kész
          </span>
        </div>

        {/* PROGRESS BAR */}
        <div className="mb-8">
          <div className="flex justify-between text-sm text-gray-600 dark:text-gray-400 mb-2">
            <span>Előrehaladás</span>
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

        {/* ZARO CIMLETEZÉS — visible after step 1 completes */}
        {(waitingForDenom || denomSubmitted) && (
          <div
            className={`bg-white dark:bg-gray-800 rounded-xl border-2 p-6 mb-8 transition-colors ${
              waitingForDenom && !denomSubmitted
                ? 'border-amber-400 dark:border-amber-500 ring-2 ring-amber-200 dark:ring-amber-800'
                : 'border-gray-200 dark:border-gray-700'
            }`}
          >
            <div className="flex items-center gap-3 mb-4">
              <Coins className="w-6 h-6 text-amber-500" />
              <h2 className="text-lg font-bold text-gray-900 dark:text-white">Esti penztár cimletezése</h2>
              {waitingForDenom && !denomSubmitted && (
                <span className="ml-2 text-xs font-semibold text-amber-600 dark:text-amber-400 bg-amber-100 dark:bg-amber-900/30 px-2 py-0.5 rounded">
                  KITOLTÉS SZUKSÉGES
                </span>
              )}
            </div>
            {!denomSubmitted ? (
              <>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                  {HUF_DENOMINATIONS.map((faceValue) => (
                    <div key={faceValue} className="flex items-center gap-2">
                      <span className="w-20 text-right text-sm font-medium text-gray-700 dark:text-gray-300">
                        {faceValue.toLocaleString('hu-HU')} Ft
                      </span>
                      <input
                        type="number"
                        min={0}
                        value={denomQuantities[faceValue] || ''}
                        onChange={(e) => {
                          const val = Math.max(0, parseInt(e.target.value) || 0)
                          setDenomQuantities((prev) => ({ ...prev, [faceValue]: val }))
                        }}
                        className="w-20 rounded border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-2 py-1.5 text-center text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                        placeholder="0"
                        disabled={!denomEditable}
                      />
                      <span className="text-xs text-gray-500 dark:text-gray-400">
                        {(faceValue * (denomQuantities[faceValue] ?? 0)).toLocaleString('hu-HU')}
                      </span>
                    </div>
                  ))}
                </div>
                <div className="mt-4 flex items-center justify-between border-t border-gray-200 dark:border-gray-700 pt-3">
                  <span className="font-bold text-gray-800 dark:text-gray-200">Osszesen:</span>
                  <span className="text-xl font-bold text-blue-900 dark:text-blue-300">
                    {denomTotal.toLocaleString('hu-HU')} Ft
                  </span>
                </div>
                <button
                  onClick={continueAfterDenom}
                  disabled={denomTotal === 0 || !denomEditable}
                  className="mt-3 w-full rounded-lg bg-amber-600 py-2 text-sm font-bold text-white hover:bg-amber-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
                >
                  Cimletezés rogzitese és továbblépés
                </button>
              </>
            ) : (
              <div className="flex items-center gap-3 rounded-lg bg-green-50 dark:bg-green-900/20 p-4">
                <Check className="h-5 w-5 text-green-600" />
                <span className="text-sm font-medium text-green-800 dark:text-green-300">
                  Cimletezés rogzitve: {denomTotal.toLocaleString('hu-HU')} Ft
                </span>
              </div>
            )}
          </div>
        )}

        {/* GOMBOK */}
        <div className="flex justify-center gap-4">
          {!isRunning && completedCount === 0 && !waitingForDenom && (
            <button
              onClick={runClosing}
              className="px-8 py-4 bg-blue-600 hover:bg-blue-700 text-white text-xl font-bold rounded-xl shadow-lg transition-colors"
            >
              ELLENŐRZÉS INDÍTÁSA
            </button>
          )}

          {failedCount > 0 && !isRunning && (
            <button
              onClick={handleCancel}
              className="px-8 py-4 bg-gray-600 hover:bg-gray-700 text-white text-xl font-bold rounded-xl shadow-lg transition-colors"
            >
              ÚJRA
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
                RENDBEN — Napzárás végrehajtása
              </span>
            ) : (
              'Minden lépés szükséges a napzáráshoz'
            )}
          </button>
        </div>
      </div>
    </div>
  )
}
