import { useState, useEffect, useCallback } from 'react'
import {
  Globe,
  Search,
  RefreshCw,
  Send,
  Download,
  RotateCcw,
  AlertTriangle,
  X,
  ArrowLeftRight,
  Building2,
  Plus,
  Trash2,
} from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useAuthStore } from '../../stores/authStore'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface WuTransaction {
  id: string
  branchId: string
  wuCustomerId?: string
  transactionType: string
  mtcn?: string
  amountUsd?: number
  amountHuf?: number
  exchangeRate?: number
  feeAmount?: number
  senderName?: string
  receiverName?: string
  destinationCountry?: string
  receiptNumber?: string
  status?: string
  workerId?: number
  transactionDate?: string
  createdAt?: string
}

type ModalType = 'send' | 'receive' | 'ic-in' | 'ic-out' | null

interface BranchOption {
  id: string
  code?: string
  name: string
  isActive?: boolean
}

const TX_TYPE_LABELS: Record<string, string> = {
  SEND: 'Küldés',
  RECEIVE: 'Fogadás',
  IC_IN: 'IC bejövő',
  IC_OUT: 'IC kimenő',
  STORNO: 'Sztornó',
}

const STATUS_COLORS: Record<string, string> = {
  COMPLETED: 'bg-green-100 text-green-800',
  PENDING: 'bg-yellow-100 text-yellow-800',
  REVERSED: 'bg-red-100 text-red-800',
}

const emptyForm = {
  branchId: '',
  mtcn: '',
  amountUsd: '',
  amountHuf: '',
  exchangeRate: '',
  feeAmount: '',
  senderName: '',
  receiverName: '',
  destinationCountry: '',
  // SOF (V.2.8 A.1): 10M/7nap kumulált triggernél a backend kötelezővé teszi.
  sourceOfFundsDocType: '',
  sourceOfFundsDocDate: '',
}

/** Elfogadható forrás-dokumentum típusok (V.2.8 B.2 — a backend WU_SOF_ACCEPTABLE_DOC_TYPES tükre). */
const SOF_DOC_TYPES: { value: string; label: string }[] = [
  { value: '', label: '— nincs (csak kumulált küszöbnél kötelező) —' },
  { value: 'JOVEDELEMIGAZOLAS', label: 'Jövedelemigazolás' },
  { value: 'NAV_IGAZOLAS', label: 'NAV-igazolás' },
  { value: 'BANKSZAMLAKIVONAT', label: 'Bankszámlakivonat' },
  { value: 'ADASVETELI_SZERZODES', label: 'Adásvételi szerződés' },
  { value: 'OROKLESI_OKIRAT', label: 'Öröklési okirat' },
  { value: 'AJANDEKOZASI_SZERZODES', label: 'Ajándékozási szerződés' },
  { value: 'VALLALKOZOI_JOVEDELEM', label: 'Vállalkozói jövedelem' },
  { value: 'NYUGDIJ_IGAZOLAS', label: 'Nyugdíj-igazolás' },
  { value: 'MAGANOKIRAT_KOZJEGYZO', label: 'Magánokirat (közjegyző)' },
  { value: 'MAGANOKIRAT_UGYVED', label: 'Magánokirat (ügyvéd)' },
  { value: 'BANK_SZLIP', label: 'Banki bizonylat (szlip)' },
]

export default function WesternUnionPage() {
  const { t } = useTranslation()
  const workerBranchId = useAuthStore((state) => state.worker?.branchId ?? '')
  const [items, setItems] = useState<WuTransaction[]>([])
  const [branches, setBranches] = useState<BranchOption[]>([])
  const [branchId, setBranchId] = useState(workerBranchId)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [modal, setModal] = useState<ModalType>(null)
  const [form, setForm] = useState(emptyForm)
  const [submitting, setSubmitting] = useState(false)

  // N4 (legacy GETWCEG / WUCEGEK) — WU partner-cég törzs
  const [partnerOpen, setPartnerOpen] = useState(false)
  const [partners, setPartners] = useState<{ id: string; name: string }[]>([])
  const [partnerSearch, setPartnerSearch] = useState('')
  const [newPartner, setNewPartner] = useState('')

  const loadPartners = useCallback(async (q = '') => {
    try {
      const res = await api.get<{ id: string; name: string }[]>('/wu-partner-companies', {
        params: q ? { q } : {},
      })
      setPartners(safeArray(res.data))
    } catch (err) {
      logger.error('WesternUnionPage', 'partner load', err)
    }
  }, [])

  const addPartner = async () => {
    if (!newPartner.trim()) return
    try {
      await api.post('/wu-partner-companies', { name: newPartner.trim() })
      setNewPartner('')
      await loadPartners(partnerSearch)
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const removePartner = async (id: string) => {
    try {
      await api.delete(`/wu-partner-companies/${id}`)
      await loadPartners(partnerSearch)
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const loadData = useCallback(async () => {
    if (!branchId) {
      setItems([])
      setLoading(false)
      return
    }
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<{ content: WuTransaction[] }>('/western-union/transactions', {
        params: { branchId, page: 0, size: 50 },
      })
      setItems(safeArray<WuTransaction>(response.data?.content ?? response.data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('WesternUnionPage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [branchId])

  const loadBranches = useCallback(async () => {
    try {
      const response = await api.get<BranchOption[]>('/branches')
      const activeBranches = safeArray<BranchOption>(response.data).filter(
        (branch) => branch.isActive !== false,
      )
      setBranches(activeBranches)
      setBranchId((current) => current || workerBranchId || activeBranches[0]?.id || '')
    } catch (err) {
      logger.warn('WesternUnionPage', 'Fióklista betöltési hiba:', err)
    }
  }, [workerBranchId])

  useEffect(() => {
    void loadBranches()
  }, [loadBranches])
  useEffect(() => {
    void loadData()
  }, [loadData])

  const filtered = items.filter((item) => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return [
      item.mtcn,
      item.senderName,
      item.receiverName,
      item.destinationCountry,
      item.status,
    ].some((v) => v != null && String(v).toLowerCase().includes(term))
  })

  const openModal = (type: ModalType) => {
    setForm(emptyForm)
    setModal(type)
    setError(null)
    setSuccess(null)
  }

  const handleSubmit = async () => {
    if (!modal) return
    setSubmitting(true)
    setError(null)
    try {
      const body = {
        branchId: form.branchId || branchId,
        mtcn: form.mtcn || undefined,
        amountUsd: form.amountUsd ? parseFloat(form.amountUsd) : undefined,
        amountHuf: form.amountHuf ? parseFloat(form.amountHuf) : undefined,
        exchangeRate: form.exchangeRate ? parseFloat(form.exchangeRate) : undefined,
        feeAmount: form.feeAmount ? parseFloat(form.feeAmount) : undefined,
        senderName: form.senderName || undefined,
        receiverName: form.receiverName || undefined,
        destinationCountry: form.destinationCountry || undefined,
        sourceOfFundsDocType: form.sourceOfFundsDocType || undefined,
        sourceOfFundsDocDate: form.sourceOfFundsDocDate || undefined,
      }
      if (modal === 'send') {
        await api.post('/western-union/send', body)
      } else if (modal === 'receive') {
        await api.post('/western-union/receive', body)
      } else if (modal === 'ic-in') {
        await api.post('/western-union/ic-in', body)
      } else {
        await api.post('/western-union/ic-out', body)
      }
      setSuccess(`WU ${modal.toUpperCase()} sikeresen rögzítve!`)
      setModal(null)
      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setSubmitting(false)
    }
  }

  // Sztornó-indok modal — Electron-kompatibilis (NEM window.prompt, az a rendererben nem támogatott).
  const [stornoTarget, setStornoTarget] = useState<{ id: string; reason: string } | null>(null)

  const handleStornoSubmit = async () => {
    if (!stornoTarget) return
    const reason = stornoTarget.reason.trim()
    if (!reason) return
    try {
      await api.post(`/western-union/storno/${stornoTarget.id}`, null, { params: { reason } })
      setSuccess('Sztornó sikeres!')
      setStornoTarget(null)
      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const modalTitle: Record<string, string> = {
    send: 'WU Küldés rögzítése',
    receive: 'WU Fogadás rögzítése',
    'ic-in': 'IC bejövő (USD)',
    'ic-out': 'IC kimenő (USD)',
  }

  return (
    <div className="form-panel space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Globe className="h-6 w-6" />
          {t('westernunion.westernUnion')}
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={() => {
              setPartnerOpen(true)
              void loadPartners()
            }}
            className="form-button flex items-center gap-1"
            title="WU partnercégek kezelése (legacy GETWCEG)"
          >
            <Building2 className="h-4 w-4" />
            {t('westernunion.partnerCegek')}
          </button>
          <button
            onClick={() => openModal('send')}
            className="form-button-primary flex items-center gap-1"
          >
            <Send className="h-4 w-4" />
            {t('common.send')}
          </button>
          <button
            onClick={() => openModal('receive')}
            className="form-button flex items-center gap-1 border-green-300 text-green-700 hover:bg-green-50"
          >
            <Download className="h-4 w-4" />
            {t('westernunion.fogadas')}
          </button>
          <button
            onClick={() => openModal('ic-in')}
            className="form-button flex items-center gap-1 text-sm"
          >
            <ArrowLeftRight className="h-3 w-3" />
            {t('westernunion.icIn')}
          </button>
          <button
            onClick={() => openModal('ic-out')}
            className="form-button flex items-center gap-1 text-sm"
          >
            <ArrowLeftRight className="h-3 w-3" />
            {t('westernunion.icOut')}
          </button>
        </div>
      </div>

      {/* Search */}
      <div className="flex items-center gap-2">
        <select
          value={branchId}
          onChange={(event) => {
            setBranchId(event.target.value)
            setItems([])
          }}
          className="form-input w-72"
        >
          <option value="">{t('export.valassz')}</option>
          {branches.map((branch) => (
            <option key={branch.id} value={branch.id}>
              {branch.name}
              {branch.code ? ` (${branch.code})` : ''}
            </option>
          ))}
        </select>
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Keresés (MTCN, név, ország)..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="form-input w-full pl-10"
          />
        </div>
      </div>

      {/* Alerts */}
      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}
      {success && (
        <div className="rounded-md bg-green-50 p-3 text-sm text-green-700 flex items-center gap-2">
          {success}
          <button onClick={() => setSuccess(null)} className="ml-auto">
            <X className="h-4 w-4" />
          </button>
        </div>
      )}

      {/* Table */}
      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.type')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.mtcn')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('handover.kuldo')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('transit.cimzett')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.country')}
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.usd')}
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.huf')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.status2')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.date')}
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                {t('common.operation')}
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr>
                <td colSpan={10} className="px-4 py-8 text-center text-sm text-gray-500">
                  {i18n.t('literals.betoltes')}
                </td>
              </tr>
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan={10} className="px-4 py-8 text-center text-sm text-gray-500">
                  {t('westernunion.nincsWuTranzakcio')}
                </td>
              </tr>
            ) : (
              filtered.map((item) => (
                <tr key={item.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-sm font-medium">
                    {TX_TYPE_LABELS[item.transactionType] ?? item.transactionType}
                  </td>
                  <td className="px-4 py-3 text-sm font-mono">{item.mtcn ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.senderName ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.receiverName ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.destinationCountry ?? '-'}</td>
                  <td className="px-4 py-3 text-sm text-right font-mono">
                    {typeof item.amountUsd === 'number'
                      ? item.amountUsd.toLocaleString('hu-HU', { minimumFractionDigits: 2 })
                      : '-'}
                  </td>
                  <td className="px-4 py-3 text-sm text-right font-mono">
                    {typeof item.amountHuf === 'number'
                      ? item.amountHuf.toLocaleString('hu-HU')
                      : '-'}
                  </td>
                  <td className="px-4 py-3 text-sm">
                    <span
                      className={`rounded-full px-2 py-1 text-xs font-medium ${STATUS_COLORS[item.status ?? ''] ?? 'bg-gray-100 text-gray-800'}`}
                    >
                      {item.status ?? '-'}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-sm">
                    {item.createdAt ? new Date(item.createdAt).toLocaleString('hu-HU') : '-'}
                  </td>
                  <td className="px-4 py-3 text-right">
                    {item.status === 'COMPLETED' && item.transactionType !== 'STORNO' && (
                      <button
                        onClick={() => setStornoTarget({ id: item.id, reason: '' })}
                        className="form-button p-1 text-red-600"
                        title="Sztornó"
                      >
                        <RotateCcw className="h-4 w-4" />
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

      {/* Modal */}
      {modal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-lg rounded-lg bg-white p-4 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-bold">{modalTitle[modal]}</h2>
              <button onClick={() => setModal(null)}>
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="form-label">{i18n.t('literals.mtcn')}</label>
                  <input
                    type="text"
                    className="form-input w-full"
                    placeholder="MTCN szám"
                    value={form.mtcn}
                    onChange={(e) => setForm((f) => ({ ...f, mtcn: e.target.value }))}
                  />
                </div>
                <div>
                  <label className="form-label">{t('westernunion.celOrszag')}</label>
                  <input
                    type="text"
                    className="form-input w-full"
                    placeholder="pl. HU"
                    value={form.destinationCountry}
                    onChange={(e) => setForm((f) => ({ ...f, destinationCountry: e.target.value }))}
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="form-label">{t('westernunion.kuldoNeve')}</label>
                  <input
                    type="text"
                    className="form-input w-full"
                    value={form.senderName}
                    onChange={(e) => setForm((f) => ({ ...f, senderName: e.target.value }))}
                  />
                </div>
                <div>
                  <label className="form-label">{t('westernunion.cimzettNeve')}</label>
                  <input
                    type="text"
                    className="form-input w-full"
                    value={form.receiverName}
                    onChange={(e) => setForm((f) => ({ ...f, receiverName: e.target.value }))}
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="form-label">{t('westernunion.usdOsszeg')}</label>
                  <input
                    type="number"
                    step="0.01"
                    className="form-input w-full"
                    value={form.amountUsd}
                    onChange={(e) => setForm((f) => ({ ...f, amountUsd: e.target.value }))}
                  />
                </div>
                <div>
                  <label className="form-label">{t('stornos.hufOsszeg')}</label>
                  <input
                    type="number"
                    step="1"
                    className="form-input w-full"
                    value={form.amountHuf}
                    onChange={(e) => setForm((f) => ({ ...f, amountHuf: e.target.value }))}
                  />
                </div>
                <div>
                  <label className="form-label">{t('cashier.exchangeRate')}</label>
                  <input
                    type="number"
                    step="0.01"
                    className="form-input w-full"
                    value={form.exchangeRate}
                    onChange={(e) => setForm((f) => ({ ...f, exchangeRate: e.target.value }))}
                  />
                </div>
              </div>

              <div>
                <label className="form-label">{t('westernunion.dijFee')}</label>
                <input
                  type="number"
                  step="0.01"
                  className="form-input w-full"
                  value={form.feeAmount}
                  onChange={(e) => setForm((f) => ({ ...f, feeAmount: e.target.value }))}
                />
              </div>

              {/* SOF (V.2.8 A.1): a backend a 10M/7nap kumulált triggernél követeli meg */}
              {(modal === 'send' || modal === 'receive') && (
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="form-label">
                      {i18n.t('literals.penzeszkoz-forras-dokumentum')}
                    </label>
                    <select
                      className="form-input w-full"
                      value={form.sourceOfFundsDocType}
                      onChange={(e) =>
                        setForm((f) => ({ ...f, sourceOfFundsDocType: e.target.value }))
                      }
                    >
                      {SOF_DOC_TYPES.map((o) => (
                        <option key={o.value} value={o.value}>
                          {o.label}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="form-label">
                      {i18n.t('literals.forras-dokumentum-datuma')}
                    </label>
                    <input
                      type="date"
                      className="form-input w-full"
                      value={form.sourceOfFundsDocDate}
                      onChange={(e) =>
                        setForm((f) => ({ ...f, sourceOfFundsDocDate: e.target.value }))
                      }
                    />
                  </div>
                </div>
              )}
            </div>

            <div className="mt-6 flex justify-end gap-3">
              <button onClick={() => setModal(null)} className="form-button">
                {t('common.cancel')}
              </button>
              <button
                onClick={handleSubmit}
                disabled={submitting}
                className="form-button-primary flex items-center gap-1"
              >
                {submitting ? 'Mentés...' : 'Rögzítés'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Sztornó-indok modal (Electron-kompatibilis) */}
      {stornoTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md rounded-lg bg-white p-4 shadow-xl">
            <div className="mb-3 flex items-center justify-between">
              <h2 className="text-lg font-bold">{i18n.t('literals.sztorno-indoka')}</h2>
              <button onClick={() => setStornoTarget(null)}>
                <X className="h-5 w-5" />
              </button>
            </div>
            <textarea
              autoFocus
              rows={3}
              className="form-input w-full"
              placeholder="Adja meg a sztornó indokát…"
              value={stornoTarget.reason}
              onChange={(e) => setStornoTarget((s) => (s ? { ...s, reason: e.target.value } : s))}
            />
            <div className="mt-4 flex justify-end gap-3">
              <button onClick={() => setStornoTarget(null)} className="form-button">
                {t('common.cancel')}
              </button>
              <button
                onClick={handleStornoSubmit}
                disabled={!stornoTarget.reason.trim()}
                className="form-button-primary"
              >
                {i18n.t('literals.sztorno-vegrehajtasa')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* N4 — WU partnercég törzs (legacy GETWCEG / WUCEGEK) */}
      {partnerOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-lg rounded-lg bg-white p-5 shadow-xl">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold flex items-center gap-2">
                <Building2 className="h-5 w-5" />
                {t('westernunion.partnerCegek')}
              </h2>
              <button onClick={() => setPartnerOpen(false)}>
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="mt-3 flex gap-2">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  placeholder="Keresés..."
                  value={partnerSearch}
                  onChange={(e) => {
                    setPartnerSearch(e.target.value)
                    void loadPartners(e.target.value)
                  }}
                  className="form-input w-full pl-10"
                />
              </div>
            </div>

            <div className="mt-2 flex gap-2">
              <input
                type="text"
                placeholder="Új partnercég neve"
                value={newPartner}
                onChange={(e) => setNewPartner(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') void addPartner()
                }}
                className="form-input flex-1"
              />
              <button
                onClick={() => void addPartner()}
                disabled={!newPartner.trim()}
                className="form-button-primary flex items-center gap-1 disabled:opacity-40"
              >
                <Plus className="h-4 w-4" />
                {t('common.add')}
              </button>
            </div>

            <ul className="mt-3 max-h-72 divide-y divide-gray-100 overflow-auto rounded border border-gray-200">
              {partners.length === 0 && (
                <li className="px-3 py-2 text-sm text-gray-400">{t('common.noData')}</li>
              )}
              {partners.map((p) => (
                <li key={p.id} className="flex items-center justify-between px-3 py-2 text-sm">
                  <span>{p.name}</span>
                  <button
                    onClick={() => void removePartner(p.id)}
                    title={t('common.delete')}
                    className="text-red-500 hover:text-red-700"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </li>
              ))}
            </ul>
          </div>
        </div>
      )}
    </div>
  )
}
