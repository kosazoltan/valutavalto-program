import { useState, useEffect, useCallback } from 'react'
import { Save, Loader2, RotateCcw, FileText } from 'lucide-react'
import { systemParameterApi, type SystemParameter } from '../../services/api/settings'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import i18n from '../../i18n'

interface ReceiptTextField {
  key: string
  label: string
  description: string
  multiline: boolean
  placeholder: string
}

const RECEIPT_FIELDS: ReceiptTextField[] = [
  {
    key: 'RECEIPT_BANK_PARTNER_NAME',
    label: 'Bankpartner neve',
    description: '300.000 Ft feletti bizonylaton megjelenő bankpartner neve',
    multiline: false,
    placeholder: 'Raiffeisen Bank Zrt.',
  },
  {
    key: 'RECEIPT_BANK_PARTNER_SUBTITLE',
    label: 'Bankpartner alcím',
    description: 'Bankpartner neve alatti felirat',
    multiline: false,
    placeholder: 'KIEMELT KÖZVETÍTŐJE',
  },
  {
    key: 'RECEIPT_MARKETING_TITLE',
    label: 'Marketing cím',
    description: '300.000 Ft feletti bizonylaton megjelenő marketing cím',
    multiline: false,
    placeholder: 'EXCLUSIVE CHANGE',
  },
  {
    key: 'RECEIPT_MARKETING_SLOGAN',
    label: 'Marketing szlogen',
    description: 'Soronként \\n elválasztva (pl. KEDVEZŐBB\\nGYORSABB\\nBIZTONSÁGOSABB)',
    multiline: true,
    placeholder: 'KEDVEZŐBB\nGYORSABB\nBIZTONSÁGOSABB',
  },
  {
    key: 'RECEIPT_FOOTER_THANKS',
    label: 'Lábléc köszöntő',
    description: 'Bizonylat alján megjelenő köszöntő szöveg',
    multiline: false,
    placeholder: 'Köszönjük, hogy minket választott!',
  },
  {
    key: 'RECEIPT_FOOTER_LEGAL',
    label: 'Lábléc jogi szöveg',
    description: 'Bizonylat alján megjelenő jogi figyelmeztetés',
    multiline: true,
    placeholder: 'A bizonylat a pénzmosás elleni törvény alapján nem helyettesíti a számlát.',
  },
  {
    key: 'RECEIPT_VAT_EXEMPTION',
    label: 'ÁFA-mentességi szöveg',
    description: 'Valutaváltás ÁFA-mentességére vonatkozó törvényi hivatkozás',
    multiline: true,
    placeholder:
      'Szj - 67.13.10.0\nAdómentes  a szolgáltatás nyújtása a 2007\nM.Á.A. evi CXVII tv. 86 § e) alapján\nmentes az adó alól',
  },
]

export default function ReceiptTextSettingsPage() {
  const [params, setParams] = useState<Map<string, SystemParameter>>(new Map())
  const [editValues, setEditValues] = useState<Map<string, string>>(new Map())
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [dirty, setDirty] = useState(false)

  const loadParams = useCallback(async () => {
    setLoading(true)
    try {
      const list = await systemParameterApi.getManagedByCategory('RECEIPT')
      const map = new Map<string, SystemParameter>()
      const values = new Map<string, string>()
      for (const p of list) {
        map.set(p.parameterKey, p)
        values.set(p.parameterKey, p.parameterValue)
      }
      setParams(map)
      setEditValues(values)
      setDirty(false)
    } catch (err) {
      logger.error('ReceiptTextSettings', 'Betöltés sikertelen:', err)
      toast.error('Hiba', 'Bizonylat szövegek betöltése sikertelen')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadParams()
  }, [loadParams])

  const handleChange = (key: string, value: string) => {
    setEditValues((prev) => {
      const next = new Map(prev)
      next.set(key, value)
      return next
    })
    setDirty(true)
  }

  const handleSave = async () => {
    setSaving(true)
    try {
      const updates: Record<string, string> = {}
      for (const field of RECEIPT_FIELDS) {
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
        toast.success('Mentve', `${savedCount} bizonylat szöveg frissítve`)
      } else {
        toast.success('Nincs változás', 'Minden szöveg változatlan maradt')
      }
      await loadParams()
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Ismeretlen hiba'
      toast.error('Mentés sikertelen', msg)
      logger.error('ReceiptTextSettings', 'Mentés sikertelen:', err)
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
        <span>{i18n.t('literals.bizonylat-szovegek-betoltese')}</span>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="section-title flex items-center gap-2">
          <FileText size={18} />
          {i18n.t('literals.bizonylat-szovegek-szerkesztese')}
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

      <div className="rounded border border-blue-200 bg-blue-50 p-3 text-sm text-blue-800">
        {i18n.t('literals.az-itt-modositott-szovegek-a-kovetkezo-b')}
      </div>

      <div className="space-y-4">
        {RECEIPT_FIELDS.map((field) => {
          const param = params.get(field.key)
          const isChanged = param && editValues.get(field.key) !== param.parameterValue

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
                </div>
              ) : field.multiline ? (
                <textarea
                  className="form-input w-full font-mono text-sm"
                  rows={4}
                  value={displayValue(field.key)}
                  onChange={(e) => handleChange(field.key, e.target.value)}
                  placeholder={field.placeholder}
                />
              ) : (
                <input
                  type="text"
                  className="form-input w-full"
                  value={displayValue(field.key)}
                  onChange={(e) => handleChange(field.key, e.target.value)}
                  placeholder={field.placeholder}
                />
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
