import { useState, useEffect, useCallback } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, ChevronLeft, ChevronRight, CheckCircle, Circle, XCircle, Save, X } from 'lucide-react'
import { closingWizardApi, ClosingWizard, ClosingWizardStep } from '../../services/api'
import { useAuthStore } from '../../stores/authStore'
import { formatDecimal } from '../../utils/numberFormat'

interface StepData {
  totalTransactionCount?: number
  currencyTransactionSummaries?: Array<{
    currencyCode: string
    buyAmount?: number
    buyCount?: number
    sellAmount?: number
    sellCount?: number
  }>
  openingBalances?: Array<{
    currencyCode: string
    balance?: number
  }>
  closingBalances?: Array<{
    currencyCode: string
    balance?: number
  }>
  totalHandlingFee?: number
  transferSummaries?: Array<{
    transferId: number
    transferNumber: string
    currencyCode: string
    amount?: number
    transferDate: string
  }>
  exchangeRateSummaries?: Array<{
    currencyCode: string
    buyRate?: number
    sellRate?: number
    midRate?: number
  }>
}

export default function ClosingWizardPage() {
  const { wizardId } = useParams<{ wizardId?: string }>()
  const navigate = useNavigate()
  const worker = useAuthStore((state) => state.worker)
  const workerId = worker?.id ? String(worker.id) : ''

  const [wizard, setWizard] = useState<ClosingWizard | null>(null)
  const [currentStepData, setCurrentStepData] = useState<ClosingWizardStep | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [closingType, setClosingType] = useState<'DAILY' | 'POS' | 'DECADE' | 'MONTHLY'>('DAILY')

  const loadWizard = useCallback(async () => {
    if (!wizardId) return
    try {
      setLoading(true)
      const data = await closingWizardApi.get(wizardId)
      setWizard(data)
    } catch (err) {
      const error = err as { response?: { data?: { message?: string } } }
      setError(error.response?.data?.message || 'Hiba a wizard betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [wizardId])

  const loadStepData = useCallback(async (stepNumber: number) => {
    if (!wizardId) return
    try {
      const stepData = await closingWizardApi.getStep(wizardId, stepNumber)
      setCurrentStepData(stepData)
    } catch (err) {
      const error = err as { response?: { data?: { message?: string } } }
      setError(error.response?.data?.message || 'Hiba a lépés adatainak betöltésekor')
    }
  }, [wizardId])

  useEffect(() => {
    if (wizardId) {
      void loadWizard()
    }
  }, [wizardId, loadWizard])

  useEffect(() => {
    if (wizard) {
      void loadStepData(wizard.currentStep)
    }
  }, [wizard, loadStepData])

  const handleStartWizard = async () => {
    if (!worker?.branchId || !workerId) {
      setError('Hiányzó adatok a wizard indításához')
      return
    }

    try {
      setLoading(true)
      const newWizard = await closingWizardApi.start(
        worker.branchId,
        undefined, // cashDeskId - TODO: kiválasztani
        closingType,
        workerId
      )
      navigate(`/closing/wizard/${newWizard.id}`)
    } catch (err) {
      const error = err as { response?: { data?: { message?: string } } }
      setError(error.response?.data?.message || 'Hiba a wizard indításakor')
    } finally {
      setLoading(false)
    }
  }

  const handleNavigate = async (targetStep: number) => {
    if (!wizardId) return

    try {
      setLoading(true)
      const updatedWizard = await closingWizardApi.navigate(wizardId, targetStep)
      setWizard(updatedWizard)
      await loadStepData(targetStep)
    } catch (err) {
      const error = err as { response?: { data?: { message?: string } } }
      setError(error.response?.data?.message || 'Hiba a navigáció során')
    } finally {
      setLoading(false)
    }
  }

  const handleComplete = async () => {
    if (!wizardId || !workerId) return

    if (!confirm('Biztosan be szeretné fejezni a zárást?')) {
      return
    }

    try {
      setLoading(true)
      await closingWizardApi.complete(wizardId, workerId)
      navigate('/cashdesk', { state: { message: 'Zárás sikeresen befejezve' } })
    } catch (err) {
      const error = err as { response?: { data?: { message?: string } } }
      setError(error.response?.data?.message || 'Hiba a zárás befejezésekor')
    } finally {
      setLoading(false)
    }
  }

  const handleCancel = async () => {
    if (!wizardId) return

    if (!confirm('Biztosan megszakítja a zárást?')) {
      return
    }

    try {
      setLoading(true)
      await closingWizardApi.cancel(wizardId)
      navigate('/cashdesk')
    } catch (err) {
      const error = err as { response?: { data?: { message?: string } } }
      setError(error.response?.data?.message || 'Hiba a zárás megszakításakor')
    } finally {
      setLoading(false)
    }
  }

  // Start screen
  if (!wizardId) {
    return (
      <div className="space-y-4">
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate('/cashdesk')}
            className="toolbar-button"
          >
            <ArrowLeft size={16} />
          </button>
          <h1 className="text-xl font-bold text-gray-800">Zárás Wizard</h1>
        </div>

        <div className="form-panel">
          <h2 className="text-lg font-semibold mb-4">Zárás típusa</h2>
          <div className="space-y-3">
            <label className="flex items-center gap-3 p-3 border rounded cursor-pointer hover:bg-gray-50">
              <input
                type="radio"
                name="closingType"
                value="DAILY"
                checked={closingType === 'DAILY'}
                onChange={(e) => setClosingType(e.target.value as typeof closingType)}
                className="w-4 h-4"
              />
              <div>
                <div className="font-semibold">Napi zárás</div>
                <div className="text-sm text-gray-600">Napi tranzakciók, készpénz, költségek</div>
              </div>
            </label>
            <label className="flex items-center gap-3 p-3 border rounded cursor-pointer hover:bg-gray-50">
              <input
                type="radio"
                name="closingType"
                value="POS"
                checked={closingType === 'POS'}
                onChange={(e) => setClosingType(e.target.value as typeof closingType)}
                className="w-4 h-4"
              />
              <div>
                <div className="font-semibold">POS zárás</div>
                <div className="text-sm text-gray-600">Kártyás tranzakciók zárása</div>
              </div>
            </label>
            <label className="flex items-center gap-3 p-3 border rounded cursor-pointer hover:bg-gray-50">
              <input
                type="radio"
                name="closingType"
                value="DECADE"
                checked={closingType === 'DECADE'}
                onChange={(e) => setClosingType(e.target.value as typeof closingType)}
                className="w-4 h-4"
              />
              <div>
                <div className="font-semibold">Dekád zárás</div>
                <div className="text-sm text-gray-600">10 napos összesítés</div>
              </div>
            </label>
            <label className="flex items-center gap-3 p-3 border rounded cursor-pointer hover:bg-gray-50">
              <input
                type="radio"
                name="closingType"
                value="MONTHLY"
                checked={closingType === 'MONTHLY'}
                onChange={(e) => setClosingType(e.target.value as typeof closingType)}
                className="w-4 h-4"
              />
              <div>
                <div className="font-semibold">Havi zárás</div>
                <div className="text-sm text-gray-600">Havi összesítés és riportok</div>
              </div>
            </label>
          </div>

          {error && (
            <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded text-red-700">
              {error}
            </div>
          )}

          <div className="mt-6 flex gap-3">
            <button
              onClick={handleStartWizard}
              disabled={loading}
              className="form-button-primary flex items-center gap-2"
            >
              <Save size={16} />
              Zárás indítása
            </button>
            <button
              onClick={() => navigate('/cashdesk')}
              className="form-button"
              disabled={loading}
            >
              Mégse
            </button>
          </div>
        </div>
      </div>
    )
  }

  if (!wizard || !currentStepData) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Betöltés...</div>
      </div>
    )
  }

  const canGoBack = wizard.currentStep > 1
  const canGoForward = currentStepData.canProceed && wizard.currentStep < wizard.totalSteps
  const canComplete = currentStepData.completed && wizard.currentStep === wizard.totalSteps

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate('/cashdesk')}
            className="toolbar-button"
          >
            <ArrowLeft size={16} />
          </button>
          <div>
            <h1 className="text-xl font-bold text-gray-800">
              {wizard.closingType === 'DAILY' ? 'Napi zárás' :
               wizard.closingType === 'POS' ? 'POS zárás' :
               wizard.closingType === 'DECADE' ? 'Dekád zárás' :
               'Havi zárás'}
            </h1>
            <div className="text-sm text-gray-600">
              {new Date(wizard.closingDate).toLocaleDateString('hu-HU')} - {wizard.branchName}
            </div>
          </div>
        </div>
        <div className="text-sm text-gray-600">
          Lépés {wizard.currentStep} / {wizard.totalSteps}
        </div>
      </div>

      {/* Error */}
      {error && (
        <div className="form-panel bg-red-50 border-red-200">
          <div className="flex items-center gap-2 text-red-700">
            <XCircle size={16} />
            <span>{error}</span>
          </div>
        </div>
      )}

      {/* Progress Steps */}
      <div className="form-panel">
        <div className="flex items-center justify-between">
          {Array.from({ length: wizard.totalSteps }, (_, i) => i + 1).map((stepNum) => {
            const isActive = stepNum === wizard.currentStep
            const isCompleted = stepNum < wizard.currentStep
            const step = wizard.steps?.find(s => s.stepNumber === stepNum)

            return (
              <div key={stepNum} className="flex items-center flex-1">
                <div className="flex flex-col items-center flex-1">
                  <button
                    onClick={() => isCompleted && handleNavigate(stepNum)}
                    disabled={!isCompleted}
                    className={`w-10 h-10 rounded-full flex items-center justify-center border-2 ${
                      isActive
                        ? 'bg-primary text-white border-primary'
                        : isCompleted
                        ? 'bg-green-100 text-green-700 border-green-300 cursor-pointer'
                        : 'bg-gray-100 text-gray-400 border-gray-300'
                    }`}
                  >
                    {isCompleted ? (
                      <CheckCircle size={20} />
                    ) : (
                      <Circle size={20} />
                    )}
                  </button>
                  {step && (
                    <div className="mt-2 text-xs text-center max-w-24">
                      {step.stepTitle}
                    </div>
                  )}
                </div>
                {stepNum < wizard.totalSteps && (
                  <div className={`h-0.5 flex-1 mx-2 ${
                    isCompleted ? 'bg-green-300' : 'bg-gray-200'
                  }`} />
                )}
              </div>
            )
          })}
        </div>
      </div>

      {/* Current Step Content */}
      <div className="form-panel">
        <h2 className="text-lg font-semibold mb-2">{currentStepData.stepTitle}</h2>
        {currentStepData.stepDescription && (
          <p className="text-sm text-gray-600 mb-4">{currentStepData.stepDescription}</p>
        )}

        {/* Step-specific content */}
        <div className="mt-4">
          {renderStepContent(currentStepData)}
        </div>
      </div>

      {/* Navigation */}
      <div className="form-panel">
        <div className="flex justify-between">
          <button
            onClick={() => handleNavigate(wizard.currentStep - 1)}
            disabled={!canGoBack || loading}
            className="form-button flex items-center gap-2"
          >
            <ChevronLeft size={16} />
            Előző
          </button>

          <div className="flex gap-3">
            <button
              onClick={handleCancel}
              disabled={loading}
              className="form-button flex items-center gap-2 text-red-600"
            >
              <X size={16} />
              Megszakítás
            </button>

            {canComplete ? (
              <button
                onClick={handleComplete}
                disabled={loading}
                className="form-button-primary flex items-center gap-2"
              >
                <Save size={16} />
                Zárás befejezése
              </button>
            ) : (
              <button
                onClick={() => handleNavigate(wizard.currentStep + 1)}
                disabled={!canGoForward || loading}
                className="form-button-primary flex items-center gap-2"
              >
                Következő
                <ChevronRight size={16} />
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

function renderStepContent(step: ClosingWizardStep) {
  const stepData = step.stepData as StepData

  switch (step.stepNumber) {
    case 1: // Transaction summary
      return (
        <div className="space-y-4">
          <div className="text-sm text-gray-600">
            Összes tranzakció: <strong>{stepData.totalTransactionCount || 0}</strong>
          </div>
          {stepData.currencyTransactionSummaries && (
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th>Deviza</th>
                  <th className="text-right">Vétel összeg</th>
                  <th className="text-right">Vétel db</th>
                  <th className="text-right">Eladás összeg</th>
                  <th className="text-right">Eladás db</th>
                </tr>
              </thead>
              <tbody>
                {stepData.currencyTransactionSummaries.map((summary: { currencyCode: string; buyAmount?: number; buyCount?: number; sellAmount?: number; sellCount?: number }) => (
                  <tr key={summary.currencyCode}>
                    <td className="font-bold">{summary.currencyCode}</td>
                    <td className="text-right font-mono">{summary.buyAmount ? formatDecimal(summary.buyAmount, 2, 2) : '0'}</td>
                    <td className="text-right font-mono">{summary.buyCount || 0}</td>
                    <td className="text-right font-mono">{summary.sellAmount ? formatDecimal(summary.sellAmount, 2, 2) : '0'}</td>
                    <td className="text-right">{summary.sellCount || 0}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )

    case 2: // Cash balances
      return (
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <h3 className="font-semibold mb-2">Nyitó készlet</h3>
              {stepData.openingBalances && (
                <table className="data-grid w-full">
                  <thead>
                    <tr>
                      <th>Deviza</th>
                      <th className="text-right">Összeg</th>
                    </tr>
                  </thead>
                  <tbody>
                    {stepData.openingBalances.map((balance: { currencyCode: string; balance?: number }) => (
                      <tr key={balance.currencyCode}>
                        <td className="font-bold">{balance.currencyCode}</td>
                        <td className="text-right font-mono">{balance.balance?.toLocaleString('hu-HU', { minimumFractionDigits: 2 })}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
            <div>
              <h3 className="font-semibold mb-2">Záró készlet</h3>
              {stepData.closingBalances && (
                <table className="data-grid w-full">
                  <thead>
                    <tr>
                      <th>Deviza</th>
                      <th className="text-right">Összeg</th>
                    </tr>
                  </thead>
                  <tbody>
                    {stepData.closingBalances.map((balance: { currencyCode: string; balance?: number }) => (
                      <tr key={balance.currencyCode}>
                        <td className="font-bold">{balance.currencyCode}</td>
                        <td className="text-right font-mono">{balance.balance?.toLocaleString('hu-HU', { minimumFractionDigits: 2 })}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        </div>
      )

    case 3: // Handling fees
      return (
        <div className="space-y-4">
          <div className="text-lg">
            Összes kezelési költség: <strong className="font-mono">{stepData.totalHandlingFee?.toLocaleString('hu-HU')} Ft</strong>
          </div>
        </div>
      )

    case 4: // Transfers
      return (
        <div className="space-y-4">
          {stepData.transferSummaries && stepData.transferSummaries.length > 0 ? (
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th>Szállítmány szám</th>
                  <th>Deviza</th>
                  <th className="text-right">Összeg</th>
                  <th>Dátum</th>
                </tr>
              </thead>
              <tbody>
                {stepData.transferSummaries.map((transfer: { transferId: number; transferNumber: string; currencyCode: string; amount?: number; transferDate: string }) => (
                  <tr key={transfer.transferId}>
                    <td>{transfer.transferNumber}</td>
                    <td className="font-bold">{transfer.currencyCode}</td>
                    <td className="text-right font-mono">{transfer.amount?.toLocaleString('hu-HU', { minimumFractionDigits: 2 })}</td>
                    <td>{new Date(transfer.transferDate).toLocaleDateString('hu-HU')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="text-gray-500 text-center py-8">Nincsenek pénztárak közötti mozgások</div>
          )}
        </div>
      )

    case 5: // Exchange rates
      return (
        <div className="space-y-4">
          {stepData.exchangeRateSummaries && (
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th>Deviza</th>
                  <th className="text-right">Vételi árfolyam</th>
                  <th className="text-right">Eladási árfolyam</th>
                  <th className="text-right">Középárfolyam</th>
                </tr>
              </thead>
              <tbody>
                {stepData.exchangeRateSummaries.map((rate: { currencyCode: string; buyRate?: number; sellRate?: number; midRate?: number }) => (
                  <tr key={rate.currencyCode}>
                    <td className="font-bold">{rate.currencyCode}</td>
                    <td className="text-right font-mono">{rate.buyRate?.toFixed(4)}</td>
                    <td className="text-right font-mono">{rate.sellRate?.toFixed(4)}</td>
                    <td className="text-right font-mono">{rate.midRate?.toFixed(4)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )

    default:
      return (
        <div className="text-gray-500">
          Lépés adatok: {JSON.stringify(stepData, null, 2)}
        </div>
      )
  }
}

