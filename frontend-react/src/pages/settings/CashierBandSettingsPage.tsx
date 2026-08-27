import { useState, useEffect, useCallback } from 'react'
import { Save, Loader2, RotateCcw, AlertTriangle } from 'lucide-react'
import { systemParameterApi, type SystemParameter } from '../../services/api/settings'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import i18n from '../../i18n'

interface CashierBandField {
  key: string
  label: string
  description: string
  unit: string
  min: number
  max: number
  placeholder: string
}

const CASHIER_FIELDS: CashierBandField[] = [
  {
    key: 'CASHIER_CUSTOM_RATE_MIN_AMOUNT',
    label: 'Pénztárosi sáv minimum összeg',
    description: 'A pénztáros egyedi árfolyamot csak ezen összeg FELETT alkalmazhat',
    unit: 'Ft',
    min: 100_000,
    max: 5_000_000,
    placeholder: '400000',
  },
  {
    key: 'CASHIER_CUSTOM_RATE_DAILY_LIMIT',
    label: 'Pénztárosi sáv napi limit',
    description: 'Hány alkalommal alkalmazhat egy pénztáros egyedi árfolyamot egy napon belül',
    unit: 'db / pénztáros / nap',
    min: 1,
    max: 50,
    placeholder: '5',
  },
]

/**
 * v2.5.50 (2026-05-13): pénztárosi sáv (cashier custom rate) admin UI.
 *
 * A főértéktáros vagy admin szerkesztheti a 2 SystemParameter értéket. A backend
 * (PR #564 óta) ezeket élesen enforce-olja minden POST /transactions/buy + /sell
 * hívásnál — egy 6. tranzakció (a limit felett) ValidationException-nel elutasít.
 */
export default function CashierBandSettingsPage() {
  const [params, setParams] = useState<Map<string, SystemParameter>>(new Map())
  const [editValues, setEditValues] = useState<Map<string, string>>(new Map())
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [dirty, setDirty] = useState(false)

  const loadParams = useCallback(async () => {
    setLoading(true)
    try {
      // CASHIER_CUSTOM_RATE_* paraméterek a TRANSACTION kategóriában vannak
      const list = await systemParameterApi.getManagedByCategory('TRANSACTION')
      const map = new Map<string, SystemParameter>()
      const values = new Map<string, string>()
      for (const p of list) {
        if (p.parameterKey.startsWith('CASHIER_CUSTOM_RATE_')) {
          map.set(p.parameterKey, p)
          values.set(p.parameterKey, p.parameterValue)
        }
      }
      setParams(map)
      setEditValues(values)
      setDirty(false)
    } catch (err) {
      logger.error('CashierBandSettings', 'Betöltés sikertelen:', err)
      toast.error('Hiba', 'Pénztárosi sáv beállítások betöltése sikertelen')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadParams()
  }, [loadParams])

  const handleChange = (key: string, value: string) => {
    // Csak numerikus értékek (positive integer)
    if (value !== '' && !/^\d+$/.test(value)) {
      return
    }
    setEditValues((prev) => {
      const next = new Map(prev)
      next.set(key, value)
      return next
    })
    setDirty(true)
  }

  const validateValue = (field: CashierBandField, value: string): string | null => {
    const num = parseInt(value, 10)
    if (isNaN(num)) return 'Érvényes számot adj meg'
    if (num < field.min) return `Minimum: ${field.min.toLocaleString('hu-HU')}`
    if (num > field.max) return `Maximum: ${field.max.toLocaleString('hu-HU')}`
    return null
  }

  const handleSave = async () => {
    // Validation — csak a meglévő paramétereket (Codex P2 finding #565)
    for (const field of CASHIER_FIELDS) {
      if (!params.has(field.key)) {
        continue
      }
      const value = editValues.get(field.key) ?? ''
      const error = validateValue(field, value)
      if (error) {
        toast.error('Validációs hiba', `${field.label}: ${error}`)
        return
      }
    }

    setSaving(true)
    try {
      const updates: Record<string, string> = {}
      for (const field of CASHIER_FIELDS) {
        const newValue = editValues.get(field.key)
        const existing = params.get(field.key)
        if (existing && newValue !== undefined && newValue !== existing.parameterValue) {
          updates[field.key] = newValue
        }
      }
      const changedKeys = Object.keys(updates)
      if (changedKeys.length === 1) {
        const key = changedKeys[0]!
        await systemParameterApi.updateByKey(key, { value: updates[key]! })
      } else if (changedKeys.length > 1) {
        await systemParameterApi.bulkUpdate(updates)
      }
      const savedCount = changedKeys.length
      if (savedCount > 0) {
        toast.success('Mentve', `${savedCount} pénztárosi sáv beállítás frissítve`)
      } else {
        toast.success('Nincs változás', 'A beállítások változatlanok maradtak')
      }
      await loadParams()
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Ismeretlen hiba'
      toast.error('Mentés sikertelen', msg)
      logger.error('CashierBandSettings', 'Mentés sikertelen:', err)
    } finally {
      setSaving(false)
    }
  }

  const handleReset = () => {
    const values = new Map<string, string>()
    for (const [key, p] of params) {
      values.set(key, p.parameterValue)
    }
    setEditValues(values)
    setDirty(false)
  }

  const displayValue = (key: string): string => {
    return editValues.get(key) ?? ''
  }

  if (loading) {
    return (
      <div className="flex items-center gap-2 text-gray-500 p-4">
        <Loader2 className="h-4 w-4 animate-spin" />
        <span>{i18n.t('literals.penztarosi-sav-beallitasok-betoltese')}</span>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="section-title flex items-center gap-2">
          <AlertTriangle size={18} className="text-amber-600" />
          {i18n.t('literals.penztarosi-sav-egyedi-arfolyam-napi-kvot')}
        </h2>
        <div className="flex gap-2">
          <button
            className="form-button flex items-center gap-1"
            onClick={handleReset}
            disabled={!dirty || saving}
          >
            <RotateCcw size={14} />
            {i18n.t('literals.visszaallitas')}
          </button>
          <button
            className="form-button-primary flex items-center gap-1"
            onClick={() => void handleSave()}
            disabled={!dirty || saving}
          >
            {saving ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />}
            {saving ? 'Mentés...' : 'Mentés'}
          </button>
        </div>
      </div>

      <div className="rounded border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
        <strong>{i18n.t('literals.uzleti-szabaly')}</strong>
        {i18n.t('literals.a-penztaros-maximum-a-napi-limitig-alkal')}
      </div>

      <div className="space-y-4">
        {CASHIER_FIELDS.map((field) => {
          const param = params.get(field.key)
          const isChanged = param && editValues.get(field.key) !== param.parameterValue
          const value = displayValue(field.key)
          const validationError = value !== '' ? validateValue(field, value) : null

          return (
            <div
              key={field.key}
              className={`p-3 rounded border ${isChanged ? 'border-amber-300 bg-amber-50' : 'border-gray-200 bg-white'}`}
            >
              <div className="flex items-start justify-between mb-1">
                <label className="form-label font-medium text-gray-800">{field.label}</label>
                {isChanged && (
                  <span className="text-xs text-amber-600 font-medium">
                    {i18n.t('literals.modositva-2')}
                  </span>
                )}
              </div>
              <p className="text-xs text-gray-500 mb-2">{field.description}</p>
              {!param ? (
                <div className="text-sm text-red-600">
                  {i18n.t('literals.hianyzo-rendszerparameter')}
                  {field.key}
                  {i18n.t('literals.v213-migracio-szukseges-v211-hibas-volt')}
                </div>
              ) : (
                <>
                  <div className="flex items-center gap-2">
                    <input
                      type="text"
                      inputMode="numeric"
                      pattern="[0-9]*"
                      className={`form-input flex-1 ${validationError ? 'border-red-300' : ''}`}
                      value={value}
                      onChange={(e) => handleChange(field.key, e.target.value)}
                      placeholder={field.placeholder}
                    />
                    <span className="text-sm text-gray-600 whitespace-nowrap">{field.unit}</span>
                  </div>
                  {validationError && (
                    <p className="text-xs text-red-600 mt-1">{validationError}</p>
                  )}
                  <p className="text-xs text-gray-400 mt-1">
                    {i18n.t('literals.tartomany')}
                    {field.min.toLocaleString('hu-HU')}
                    {i18n.t('literals.lit-57')} {field.max.toLocaleString('hu-HU')} {field.unit}
                  </p>
                </>
              )}
            </div>
          )
        })}
      </div>

      {dirty && (
        <div className="flex justify-end gap-2 pt-2 border-t">
          <button
            className="form-button flex items-center gap-1"
            onClick={handleReset}
            disabled={saving}
          >
            <RotateCcw size={14} />
            {i18n.t('literals.visszaallitas')}
          </button>
          <button
            className="form-button-primary flex items-center gap-1"
            onClick={() => void handleSave()}
            disabled={saving}
          >
            {saving ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />}
            {saving ? 'Mentés...' : 'Mentés'}
          </button>
        </div>
      )}
    </div>
  )
}
