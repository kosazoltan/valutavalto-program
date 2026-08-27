import { useCallback, useEffect, useMemo, useState } from 'react'
import { AlertTriangle, Loader2, Plus, Trash2, Edit2 } from 'lucide-react'
import {
  valueBandApi,
  type ValueBandConfig,
  type ValueBandConfigRequest,
} from '../../services/api/settings'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import i18n from '../../i18n'

const DEFAULT_FORM: ValueBandConfigRequest = {
  simplifiedIdentificationLimitHuf: 100000,
  identificationLimitHuf: 300000,
  incomeProofLimitHuf: 10000000,
  rollingWindowDays: 8,
  effectiveFrom: '',
}

function todayIso(): string {
  return new Date().toISOString().slice(0, 10)
}

function tomorrowIso(): string {
  const d = new Date()
  d.setDate(d.getDate() + 1)
  return d.toISOString().slice(0, 10)
}

function defaultForm(): ValueBandConfigRequest {
  return { ...DEFAULT_FORM, effectiveFrom: tomorrowIso() }
}

function formatHuf(value: number): string {
  return `${value.toLocaleString('hu-HU').replace(/\s/g, ' ')} Ft`
}

function statusFor(
  row: ValueBandConfig,
  effectiveId: string | null,
): 'HATÁLYOS' | 'JÖVŐBELI' | 'LEJÁRT' {
  if (row.id === effectiveId) return 'HATÁLYOS'
  return row.effectiveFrom > todayIso() ? 'JÖVŐBELI' : 'LEJÁRT'
}

export default function ValueBandSettingsPage() {
  const [rows, setRows] = useState<ValueBandConfig[]>([])
  const [form, setForm] = useState<ValueBandConfigRequest>(defaultForm)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)

  const loadRows = useCallback(async () => {
    setLoading(true)
    try {
      const list = await valueBandApi.list()
      setRows([...list].sort((a, b) => b.effectiveFrom.localeCompare(a.effectiveFrom)))
    } catch (err) {
      logger.error('ValueBandSettingsPage', 'Értéksávok betöltése sikertelen:', err)
      toast.error('Betöltési hiba', getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadRows()
  }, [loadRows])

  const effectiveId = useMemo(() => {
    const today = todayIso()
    return (
      rows
        .filter((row) => row.effectiveFrom <= today)
        .sort((a, b) => b.effectiveFrom.localeCompare(a.effectiveFrom))[0]?.id ?? null
    )
  }, [rows])

  const updateNumber = (
    key: keyof Omit<ValueBandConfigRequest, 'effectiveFrom'>,
    value: string,
  ) => {
    const parsed = Number(value)
    setForm((prev) => ({ ...prev, [key]: Number.isFinite(parsed) ? parsed : 0 }))
  }

  const validateForm = (): string | null => {
    if (!form.effectiveFrom || form.effectiveFrom <= todayIso())
      return 'Az érvényesség kezdete csak jövőbeli nap lehet'
    if (
      form.simplifiedIdentificationLimitHuf <= 0 ||
      form.identificationLimitHuf <= 0 ||
      form.incomeProofLimitHuf <= 0
    ) {
      return 'Minden küszöbnek pozitívnak kell lennie'
    }
    if (form.simplifiedIdentificationLimitHuf > form.identificationLimitHuf) {
      return 'Az egyszerűsített küszöb nem lehet nagyobb a teljes azonosítási küszöbnél'
    }
    if (form.rollingWindowDays < 1) return 'A göngyölési ablak legalább 1 nap'
    return null
  }

  const resetForm = () => {
    setEditingId(null)
    setForm(defaultForm())
  }

  const handleEdit = (row: ValueBandConfig) => {
    setEditingId(row.id)
    setForm({
      simplifiedIdentificationLimitHuf: row.simplifiedIdentificationLimitHuf,
      identificationLimitHuf: row.identificationLimitHuf,
      incomeProofLimitHuf: row.incomeProofLimitHuf,
      rollingWindowDays: row.rollingWindowDays,
      effectiveFrom: row.effectiveFrom,
    })
  }

  const handleSave = async () => {
    const error = validateForm()
    if (error) {
      toast.error('Validációs hiba', error)
      return
    }
    setSaving(true)
    try {
      if (editingId) {
        await valueBandApi.update(editingId, form)
        toast.success('Mentve', 'AML értéksáv-konfiguráció módosítva')
      } else {
        await valueBandApi.create(form)
        toast.success('Mentve', 'Új AML értéksáv-konfiguráció létrehozva')
      }
      resetForm()
      await loadRows()
    } catch (err) {
      logger.error('ValueBandSettingsPage', 'Mentés sikertelen:', err)
      toast.error('Mentés sikertelen', getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async (id: string) => {
    if (!window.confirm('Biztosan törli a jövőbeli sávot?')) return
    setSaving(true)
    try {
      await valueBandApi.remove(id)
      toast.success('Törölve', 'Jövőbeli AML értéksáv-konfiguráció törölve')
      if (editingId === id) resetForm()
      await loadRows()
    } catch (err) {
      logger.error('ValueBandSettingsPage', 'Törlés sikertelen:', err)
      toast.error('Törlés sikertelen', getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center gap-2 text-gray-500 p-4">
        <Loader2 className="h-4 w-4 animate-spin" />
        <span>{i18n.t('literals.aml-erteksavok-betoltese')}</span>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <h2 className="section-title flex items-center gap-2">
        <AlertTriangle size={18} className="text-amber-600" />
        {i18n.t('literals.aml-erteksavok')}
      </h2>

      <div className="rounded border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
        {i18n.t('literals.a-100e-300e-10m-aml-kuszobok-jogszabalyi')}
      </div>

      <div className="rounded border border-gray-200 overflow-hidden">
        <table className="min-w-full text-sm">
          <thead className="bg-gray-50 text-left">
            <tr>
              <th className="p-2">{i18n.t('literals.ervenyesseg-kezdete')}</th>
              <th className="p-2">{i18n.t('literals.100e-sav')}</th>
              <th className="p-2">{i18n.t('literals.300e-sav')}</th>
              <th className="p-2">{i18n.t('literals.10m-sav')}</th>
              <th className="p-2">{i18n.t('literals.ablak')}</th>
              <th className="p-2">{i18n.t('literals.statusz')}</th>
              <th className="p-2">{i18n.t('literals.muveletek')}</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => {
              const status = statusFor(row, effectiveId)
              const editable = status === 'JÖVŐBELI'
              return (
                <tr key={row.id} data-testid={`value-band-row-${row.id}`} className="border-t">
                  <td className="p-2 font-mono">{row.effectiveFrom}</td>
                  <td className="p-2">{formatHuf(row.simplifiedIdentificationLimitHuf)}</td>
                  <td className="p-2">{formatHuf(row.identificationLimitHuf)}</td>
                  <td className="p-2">{formatHuf(row.incomeProofLimitHuf)}</td>
                  <td className="p-2">
                    {row.rollingWindowDays}
                    {i18n.t('literals.nap-2')}
                  </td>
                  <td className="p-2">
                    <span className="rounded bg-gray-100 px-2 py-1 text-xs font-medium">
                      {status}
                    </span>
                  </td>
                  <td className="p-2">
                    {editable && (
                      <div className="flex gap-2">
                        <button
                          className="form-button flex items-center gap-1"
                          disabled={saving}
                          type="button"
                          onClick={() => handleEdit(row)}
                        >
                          <Edit2 size={12} />
                          {i18n.t('literals.szerkesztes')}
                        </button>
                        <button
                          className="form-button text-red-600 flex items-center gap-1"
                          disabled={saving}
                          type="button"
                          onClick={() => void handleDelete(row.id)}
                        >
                          <Trash2 size={12} />
                          {i18n.t('literals.torles-2')}
                        </button>
                      </div>
                    )}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
        <h3 className="font-semibold flex items-center gap-2">
          {editingId ? <Edit2 size={16} /> : <Plus size={16} />}
          {editingId ? 'Sáv-konfiguráció szerkesztése' : 'Új sáv-konfiguráció'}
        </h3>
        <div className="grid grid-cols-1 gap-3 md:grid-cols-5">
          <label className="space-y-1">
            <span className="form-label">
              {i18n.t('literals.egyszerusitett-azonositasi-kuszob')}
            </span>
            <input
              aria-label="Egyszerűsített azonosítási küszöb"
              className="form-input"
              type="number"
              min={1}
              value={form.simplifiedIdentificationLimitHuf}
              onChange={(e) => updateNumber('simplifiedIdentificationLimitHuf', e.target.value)}
            />
          </label>
          <label className="space-y-1">
            <span className="form-label">{i18n.t('literals.teljes-azonositasi-kuszob')}</span>
            <input
              aria-label="Teljes azonosítási küszöb"
              className="form-input"
              type="number"
              min={1}
              value={form.identificationLimitHuf}
              onChange={(e) => updateNumber('identificationLimitHuf', e.target.value)}
            />
          </label>
          <label className="space-y-1">
            <span className="form-label">{i18n.t('literals.jovedelemforras-fokozott-kuszob')}</span>
            <input
              aria-label="Jövedelemforrás / fokozott küszöb"
              className="form-input"
              type="number"
              min={1}
              value={form.incomeProofLimitHuf}
              onChange={(e) => updateNumber('incomeProofLimitHuf', e.target.value)}
            />
          </label>
          <label className="space-y-1">
            <span className="form-label">{i18n.t('literals.gongyolesi-ablak-napok')}</span>
            <input
              aria-label="Göngyölési ablak napok"
              className="form-input"
              type="number"
              min={1}
              value={form.rollingWindowDays}
              onChange={(e) => updateNumber('rollingWindowDays', e.target.value)}
            />
          </label>
          <label className="space-y-1">
            <span className="form-label">{i18n.t('literals.ervenyesseg-kezdete')}</span>
            <input
              aria-label="Érvényesség kezdete"
              className="form-input"
              type="date"
              min={tomorrowIso()}
              value={form.effectiveFrom}
              onChange={(e) => setForm((prev) => ({ ...prev, effectiveFrom: e.target.value }))}
            />
          </label>
        </div>
        <div className="flex justify-end gap-2">
          {editingId && (
            <button className="form-button" disabled={saving} onClick={resetForm} type="button">
              {i18n.t('literals.megse')}
            </button>
          )}
          <button
            className="form-button-primary"
            disabled={saving}
            onClick={() => void handleSave()}
            type="button"
          >
            {saving ? 'Mentés...' : editingId ? 'Módosítás mentése' : 'Új sáv mentése'}
          </button>
        </div>
      </div>
    </div>
  )
}
