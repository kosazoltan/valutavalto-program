import { useState, useEffect, useCallback } from 'react'
import {
  Lock,
  Search,
  RefreshCw,
  Plus,
  AlertTriangle,
  Play,
  CheckCircle,
  Unlock,
  ShieldCheck,
} from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useAuthStore } from '../../stores/authStore'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface SealTrackingItem {
  id: string | number
  transferType?: string
  transferId?: number
  sealNumber?: string
  transitStatus?: string
  sealedAt?: string
  sealedBy?: number
  openedAt?: string
  openedBy?: number
  notes?: string | null
}

interface SealFormState {
  transferType: string
  transferId: string
  sealNumber: string
}

type SealType = 'OPEN' | 'CLOSE' | 'TRANSFER'

interface SealNumberRecord {
  id: string
  branchId?: string
  sealNumber?: string
  sealType?: SealType
  sessionId?: string | null
  workerId?: number | null
  note?: string | null
  createdAt?: string | null
  usedAt?: string | null
}

export default function SealTrackingPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const [items, setItems] = useState<SealTrackingItem[]>([])
  const [todaySealNumbers, setTodaySealNumbers] = useState<SealNumberRecord[]>([])
  const [unusedSealNumbers, setUnusedSealNumbers] = useState<SealNumberRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [sealNumbersLoading, setSealNumbersLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [form, setForm] = useState<SealFormState | null>(null)
  const [generatedBranchCode, setGeneratedBranchCode] = useState('')
  const [generatedSealNote, setGeneratedSealNote] = useState('')
  const [sealLookup, setSealLookup] = useState('')
  const [transferLookup, setTransferLookup] = useState({ transferType: 'TRANSFER', transferId: '' })

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<SealTrackingItem[]>('/seal-tracking/active')
      setItems(safeArray<SealTrackingItem>(response.data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('SealTrackingPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  const loadSealNumbers = useCallback(async () => {
    try {
      setSealNumbersLoading(true)
      const [todayResponse, unusedResponse] = await Promise.all([
        api.get<SealNumberRecord[]>('/seal-numbers/today'),
        api.get<SealNumberRecord[]>('/seal-numbers/unused'),
      ])
      setTodaySealNumbers(safeArray<SealNumberRecord>(todayResponse.data))
      setUnusedSealNumbers(safeArray<SealNumberRecord>(unusedResponse.data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('SealTrackingPage', 'Plombaszám lista betöltési hiba:', err)
      setError(msg)
      setTodaySealNumbers([])
      setUnusedSealNumbers([])
    } finally {
      setSealNumbersLoading(false)
    }
  }, [])

  const refreshAll = useCallback(async () => {
    await Promise.all([loadData(), loadSealNumbers()])
  }, [loadData, loadSealNumbers])

  useEffect(() => {
    void refreshAll()
  }, [refreshAll])

  const openNewForm = () => {
    setError(null)
    setMessage(null)
    setForm({ transferType: 'TRANSFER', transferId: '', sealNumber: '' })
  }

  const replaceItem = (updated: SealTrackingItem) => {
    setItems((current) => {
      const index = current.findIndex((item) => item.id === updated.id)
      if (index < 0) return [updated, ...current]
      return current.map((item) => (item.id === updated.id ? updated : item))
    })
  }

  const generateSealNumber = async () => {
    const branchCode = generatedBranchCode.trim() || worker?.branchCode?.trim() || ''
    if (!branchCode) {
      setError('A plombaszám generálásához hiányzik a telephelykód.')
      return
    }

    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      await api.post<SealNumberRecord>('/seal-numbers/generate', {
        branchCode,
        sealType: 'CLOSE',
        sessionId: null,
        note: generatedSealNote.trim() || null,
      })
      setGeneratedSealNote('')
      setMessage('Plombaszám generálva.')
      await loadSealNumbers()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('SealTrackingPage', 'Plombaszám generálási hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const markSealNumberAsUsed = async (seal: SealNumberRecord) => {
    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      await api.post<SealNumberRecord>(`/seal-numbers/${seal.id}/use`)
      setMessage('Plombaszám felhasználása rögzítve.')
      await loadSealNumbers()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('SealTrackingPage', 'Plombaszám felhasználási hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const createSeal = async () => {
    if (!form) return
    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      const response = await api.post<SealTrackingItem>('/seal-tracking/seal', null, {
        params: {
          transferType: form.transferType.trim(),
          transferId: Number(form.transferId),
          sealNumber: form.sealNumber.trim(),
        },
      })
      setForm(null)
      replaceItem(response.data)
      setMessage('Plomba felhelyezve.')
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('SealTrackingPage', 'Plomba létrehozási hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const runTransition = async (
    item: SealTrackingItem,
    endpoint: 'start-transit' | 'confirm-arrival' | 'open',
    successMessage: string,
  ) => {
    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      const params = {
        transferType: item.transferType,
        transferId: item.transferId,
      }
      const response =
        endpoint === 'start-transit'
          ? await api.post<SealTrackingItem>('/seal-tracking/start-transit', null, { params })
          : endpoint === 'confirm-arrival'
            ? await api.post<SealTrackingItem>('/seal-tracking/confirm-arrival', null, { params })
            : await api.post<SealTrackingItem>('/seal-tracking/open', null, { params })
      replaceItem(response.data)
      setMessage(successMessage)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('SealTrackingPage', 'Plomba státuszváltási hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const validateSeal = async (item: SealTrackingItem) => {
    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      const response = await api.get<boolean>('/seal-tracking/validate', {
        params: {
          transferType: item.transferType,
          transferId: item.transferId,
          expectedSealNumber: item.sealNumber,
        },
      })
      setMessage(response.data ? 'Plomba integritás rendben.' : 'Plomba integritás eltérés.')
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('SealTrackingPage', 'Plomba validációs hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const lookupBySeal = async () => {
    const sealNumber = sealLookup.trim()
    if (!sealNumber) return
    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      const response = await api.get<SealTrackingItem>(
        `/seal-tracking/by-seal/${encodeURIComponent(sealNumber)}`,
      )
      replaceItem(response.data)
      setMessage('Plomba megtalálva.')
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('SealTrackingPage', 'Plomba szám keresési hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const lookupByTransfer = async () => {
    if (!transferLookup.transferType.trim() || !transferLookup.transferId.trim()) return
    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      const response = await api.get<SealTrackingItem>('/seal-tracking/by-transfer', {
        params: {
          transferType: transferLookup.transferType.trim(),
          transferId: Number(transferLookup.transferId),
        },
      })
      replaceItem(response.data)
      setMessage('Átadás plombája megtalálva.')
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('SealTrackingPage', 'Átadás szerinti keresési hiba:', err)
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  const filtered = items.filter((item) => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return Object.values(item).some((v) => v != null && String(v).toLowerCase().includes(term))
  })

  return (
    <div className="form-panel space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Lock className="h-6 w-6" />
          {t('seals.plombaNyilvantartas')}
        </h1>
        <div className="flex flex-wrap items-center gap-2">
          <button
            onClick={() => void refreshAll()}
            className="form-button p-2"
            title="Frissítés"
            aria-label="Plomba nézet frissítése"
          >
            <RefreshCw
              className={`h-4 w-4 ${loading || sealNumbersLoading ? 'animate-spin' : ''}`}
            />
          </button>
          <button onClick={openNewForm} className="form-button-primary flex items-center gap-1">
            <Plus className="h-4 w-4" />
            {t('common.new')}
          </button>
        </div>
      </div>

      {form && (
        <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
          <h2 className="text-base font-semibold">{i18n.t('literals.uj-plomba')}</h2>
          <div className="grid gap-3 md:grid-cols-3">
            <div>
              <label htmlFor="seal-transfer-type" className="form-label">
                {i18n.t('literals.atadas-tipusa')}
              </label>
              <input
                id="seal-transfer-type"
                value={form.transferType}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, transferType: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="seal-transfer-id" className="form-label">
                {i18n.t('literals.atadas-id')}
              </label>
              <input
                id="seal-transfer-id"
                value={form.transferId}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, transferId: e.target.value } : current,
                  )
                }
                className="form-input w-full"
                inputMode="numeric"
              />
            </div>
            <div>
              <label htmlFor="seal-number" className="form-label">
                {i18n.t('literals.plombaszam')}
              </label>
              <input
                id="seal-number"
                value={form.sealNumber}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, sealNumber: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => void createSeal()}
              disabled={
                saving ||
                !form.transferType.trim() ||
                !form.transferId.trim() ||
                !form.sealNumber.trim()
              }
              className="form-button-primary"
            >
              {saving ? 'Mentés...' : 'Mentés'}
            </button>
            <button type="button" onClick={() => setForm(null)} className="form-button">
              {i18n.t('literals.megse')}
            </button>
          </div>
        </div>
      )}

      <section className="rounded border border-gray-200 bg-white p-4">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <h2 className="flex items-center gap-2 text-base font-semibold">
              <ShieldCheck className="h-5 w-5 text-blue-600" />
              {i18n.t('literals.generalt-plombaszamok')}
            </h2>
            <div className="mt-2 flex flex-wrap gap-2 text-sm">
              <span className="rounded bg-blue-50 px-2 py-1 text-blue-800">
                {i18n.t('literals.mai')}
                {sealNumbersLoading ? '...' : todaySealNumbers.length}
              </span>
              <span className="rounded bg-emerald-50 px-2 py-1 text-emerald-800">
                {i18n.t('literals.felhasznalatlan')}
                {sealNumbersLoading ? '...' : unusedSealNumbers.length}
              </span>
            </div>
          </div>
          <div className="grid w-full gap-2 sm:grid-cols-[minmax(0,10rem)_minmax(0,1fr)_auto] lg:max-w-2xl">
            <input
              id="seal-number-branch-code"
              value={generatedBranchCode}
              onChange={(e) => setGeneratedBranchCode(e.target.value)}
              className="form-input w-full"
              placeholder={worker?.branchCode || 'Telephelykód'}
              aria-label="Telephelykód plombaszám generáláshoz"
            />
            <input
              id="seal-number-note"
              value={generatedSealNote}
              onChange={(e) => setGeneratedSealNote(e.target.value)}
              className="form-input w-full"
              placeholder="Megjegyzés"
              aria-label="Plombaszám megjegyzés"
            />
            <button
              type="button"
              onClick={() => void generateSealNumber()}
              disabled={saving}
              className="form-button-primary whitespace-nowrap"
            >
              {i18n.t('literals.generalas')}
            </button>
          </div>
        </div>

        <div className="mt-4 grid gap-3 lg:grid-cols-2">
          <div className="rounded border border-gray-100 bg-gray-50 p-3">
            <h3 className="text-sm font-semibold text-gray-800">
              {i18n.t('literals.felhasznalatlan-plombaszamok')}
            </h3>
            <div className="mt-2 space-y-2">
              {sealNumbersLoading ? (
                <div className="text-sm text-gray-500">{i18n.t('literals.betoltes')}</div>
              ) : unusedSealNumbers.length === 0 ? (
                <div className="text-sm text-gray-500">
                  {i18n.t('literals.nincs-felhasznalatlan-plombaszam')}
                </div>
              ) : (
                unusedSealNumbers.slice(0, 5).map((seal) => (
                  <div
                    key={seal.id}
                    className="flex flex-col gap-2 rounded border border-gray-200 bg-white px-3 py-2 sm:flex-row sm:items-center sm:justify-between"
                  >
                    <div className="min-w-0">
                      <div className="break-all font-mono text-sm font-semibold">
                        {seal.sealNumber ?? '-'}
                      </div>
                      <div className="text-xs text-gray-500">
                        {seal.sealType ?? 'CLOSE'}
                        {i18n.t('literals.lit-29')}{' '}
                        {seal.createdAt
                          ? new Date(seal.createdAt).toLocaleString('hu-HU')
                          : 'Nincs dátum'}
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={() => void markSealNumberAsUsed(seal)}
                      disabled={saving}
                      className="form-button text-sm"
                    >
                      {i18n.t('literals.felhasznalva-2')}
                    </button>
                  </div>
                ))
              )}
            </div>
          </div>

          <div className="rounded border border-gray-100 bg-gray-50 p-3">
            <h3 className="text-sm font-semibold text-gray-800">
              {i18n.t('literals.mai-plombaszamok')}
            </h3>
            <div className="mt-2 space-y-2">
              {sealNumbersLoading ? (
                <div className="text-sm text-gray-500">{i18n.t('literals.betoltes')}</div>
              ) : todaySealNumbers.length === 0 ? (
                <div className="text-sm text-gray-500">
                  {i18n.t('literals.ma-meg-nincs-generalt-plombaszam')}
                </div>
              ) : (
                todaySealNumbers.slice(0, 5).map((seal) => (
                  <div key={seal.id} className="rounded border border-gray-200 bg-white px-3 py-2">
                    <div className="break-all font-mono text-sm font-semibold">
                      {seal.sealNumber ?? '-'}
                    </div>
                    <div className="text-xs text-gray-500">
                      {seal.usedAt
                        ? `Felhasználva: ${new Date(seal.usedAt).toLocaleString('hu-HU')}`
                        : 'Felhasználatlan'}
                      {seal.note ? ` · ${seal.note}` : ''}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      </section>

      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Keresés..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="form-input w-full pl-10"
          />
        </div>
      </div>

      <div className="rounded border border-gray-200 bg-white p-3">
        <div className="grid gap-3 lg:grid-cols-2">
          <div className="flex gap-2">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <input
                id="seal-lookup-number"
                type="text"
                placeholder="Plombaszám keresése"
                value={sealLookup}
                onChange={(e) => setSealLookup(e.target.value)}
                className="form-input w-full pl-10"
              />
            </div>
            <button
              type="button"
              onClick={() => void lookupBySeal()}
              disabled={saving || !sealLookup.trim()}
              className="form-button"
            >
              {i18n.t('literals.kereses-2')}
            </button>
          </div>
          <div className="grid gap-2 sm:grid-cols-[1fr_1fr_auto]">
            <input
              id="seal-lookup-transfer-type"
              type="text"
              value={transferLookup.transferType}
              onChange={(e) =>
                setTransferLookup((current) => ({ ...current, transferType: e.target.value }))
              }
              className="form-input w-full"
              placeholder="Átadás típusa"
            />
            <input
              id="seal-lookup-transfer-id"
              type="text"
              inputMode="numeric"
              value={transferLookup.transferId}
              onChange={(e) =>
                setTransferLookup((current) => ({ ...current, transferId: e.target.value }))
              }
              className="form-input w-full"
              placeholder="Átadás ID"
            />
            <button
              type="button"
              onClick={() => void lookupByTransfer()}
              disabled={
                saving || !transferLookup.transferType.trim() || !transferLookup.transferId.trim()
              }
              className="form-button"
            >
              {i18n.t('literals.atadas-kereses')}
            </button>
          </div>
        </div>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {message && (
        <div className="rounded border border-green-200 bg-green-50 px-3 py-2 text-sm text-green-800">
          {message}
        </div>
      )}

      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('seals.plombaSzam')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.atadas')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.status2')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('seals.felhelyezve')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('seals.eltavolitva')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.kezelok')}
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                {t('common.actions')}
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr>
                <td colSpan={7} className="px-4 py-8 text-center text-sm text-gray-500">
                  {i18n.t('literals.betoltes')}
                </td>
              </tr>
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-4 py-8 text-center text-sm text-gray-500">
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              filtered.map((item) => (
                <tr key={item.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-sm">{item.sealNumber ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">
                    {item.transferType ?? '-'}
                    {i18n.t('literals.lit-10')}
                    {item.transferId ?? '-'}
                  </td>
                  <td className="px-4 py-3 text-sm">{item.transitStatus ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">
                    {item.sealedAt ? new Date(item.sealedAt).toLocaleString('hu-HU') : '-'}
                  </td>
                  <td className="px-4 py-3 text-sm">
                    {item.openedAt ? new Date(item.openedAt).toLocaleString('hu-HU') : '-'}
                  </td>
                  <td className="px-4 py-3 text-sm">
                    {item.sealedBy ?? '-'}
                    {i18n.t('literals.lit-10')}
                    {item.openedBy ?? '-'}
                  </td>
                  <td className="px-4 py-3 text-right whitespace-nowrap">
                    <button
                      onClick={() => void validateSeal(item)}
                      disabled={saving}
                      className="form-button mr-2 p-1 text-blue-600"
                      title="Integritás ellenőrzés"
                    >
                      <ShieldCheck className="h-4 w-4" />
                    </button>
                    {item.transitStatus === 'SEALED' && (
                      <button
                        onClick={() =>
                          void runTransition(item, 'start-transit', 'Szállítás elindítva.')
                        }
                        disabled={saving}
                        className="form-button mr-2 p-1 text-green-700"
                        title="Tranzit indítása"
                      >
                        <Play className="h-4 w-4" />
                      </button>
                    )}
                    {item.transitStatus === 'IN_TRANSIT' && (
                      <button
                        onClick={() =>
                          void runTransition(item, 'confirm-arrival', 'Megérkezés visszaigazolva.')
                        }
                        disabled={saving}
                        className="form-button mr-2 p-1 text-green-700"
                        title="Megérkezés visszaigazolása"
                      >
                        <CheckCircle className="h-4 w-4" />
                      </button>
                    )}
                    {item.transitStatus === 'ARRIVED' && (
                      <button
                        onClick={() => void runTransition(item, 'open', 'Plomba felnyitva.')}
                        disabled={saving}
                        className="form-button p-1 text-red-700"
                        title="Plomba felnyitása"
                      >
                        <Unlock className="h-4 w-4" />
                      </button>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        {t('audit.osszesen')}
        {filtered.length}
        {i18n.t('literals.lit-10')}
        {items.length}
      </div>
    </div>
  )
}
