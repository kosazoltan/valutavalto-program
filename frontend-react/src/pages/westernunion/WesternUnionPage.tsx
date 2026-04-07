import { useState, useEffect, useCallback } from 'react'
import { Globe, Search, RefreshCw, Send, Download, RotateCcw, AlertTriangle, X, ArrowLeftRight } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'

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
}

export default function WesternUnionPage() {
  const [items, setItems] = useState<WuTransaction[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [modal, setModal] = useState<ModalType>(null)
  const [form, setForm] = useState(emptyForm)
  const [submitting, setSubmitting] = useState(false)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      // Use transactions endpoint with current branch
      const response = await api.get<{ content: WuTransaction[] }>('/western-union/transactions', {
        params: { branchId: localStorage.getItem('branchId') || '', page: 0, size: 50 }
      })
      setItems(safeArray<WuTransaction>(response.data?.content ?? response.data))
    } catch {
      // Fallback to list endpoint
      try {
        const response = await api.get<WuTransaction[]>('/western-union')
        setItems(safeArray<WuTransaction>(response.data))
      } catch (err2) {
        const msg = getErrorMessage(err2)
        logger.error('WesternUnionPage', 'Betöltési hiba:', err2)
        setError(msg)
      }
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { void loadData() }, [loadData])

  const filtered = items.filter(item => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return [item.mtcn, item.senderName, item.receiverName, item.destinationCountry, item.status]
      .some(v => v != null && String(v).toLowerCase().includes(term))
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
        branchId: form.branchId || localStorage.getItem('branchId') || '',
        mtcn: form.mtcn || undefined,
        amountUsd: form.amountUsd ? parseFloat(form.amountUsd) : undefined,
        amountHuf: form.amountHuf ? parseFloat(form.amountHuf) : undefined,
        exchangeRate: form.exchangeRate ? parseFloat(form.exchangeRate) : undefined,
        feeAmount: form.feeAmount ? parseFloat(form.feeAmount) : undefined,
        senderName: form.senderName || undefined,
        receiverName: form.receiverName || undefined,
        destinationCountry: form.destinationCountry || undefined,
      }
      await api.post(`/western-union/${modal}`, body)
      setSuccess(`WU ${modal.toUpperCase()} sikeresen rögzítve!`)
      setModal(null)
      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setSubmitting(false)
    }
  }

  const handleStorno = async (id: string) => {
    const reason = prompt('Sztornó indoka:')
    if (reason === null) return
    try {
      await api.post(`/western-union/storno/${id}`, null, { params: { reason } })
      setSuccess('Sztornó sikeres!')
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
          Western Union
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button onClick={() => openModal('send')} className="form-button-primary flex items-center gap-1">
            <Send className="h-4 w-4" /> Küldés
          </button>
          <button onClick={() => openModal('receive')} className="form-button flex items-center gap-1 border-green-300 text-green-700 hover:bg-green-50">
            <Download className="h-4 w-4" /> Fogadás
          </button>
          <button onClick={() => openModal('ic-in')} className="form-button flex items-center gap-1 text-sm">
            <ArrowLeftRight className="h-3 w-3" /> IC In
          </button>
          <button onClick={() => openModal('ic-out')} className="form-button flex items-center gap-1 text-sm">
            <ArrowLeftRight className="h-3 w-3" /> IC Out
          </button>
        </div>
      </div>

      {/* Search */}
      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input type="text" placeholder="Keresés (MTCN, név, ország)..."
            value={searchTerm} onChange={e => setSearchTerm(e.target.value)}
            className="form-input w-full pl-10" />
        </div>
      </div>

      {/* Alerts */}
      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />{error}
        </div>
      )}
      {success && (
        <div className="rounded-md bg-green-50 p-3 text-sm text-green-700 flex items-center gap-2">
          {success}
          <button onClick={() => setSuccess(null)} className="ml-auto"><X className="h-4 w-4" /></button>
        </div>
      )}

      {/* Table */}
      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Típus</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">MTCN</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Küldő</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Címzett</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Ország</th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">USD</th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">HUF</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Állapot</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">Dátum</th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">Művelet</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr><td colSpan={10} className="px-4 py-8 text-center text-sm text-gray-500">Betöltés...</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={10} className="px-4 py-8 text-center text-sm text-gray-500">Nincs WU tranzakció</td></tr>
            ) : filtered.map(item => (
              <tr key={item.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm font-medium">
                  {TX_TYPE_LABELS[item.transactionType] ?? item.transactionType}
                </td>
                <td className="px-4 py-3 text-sm font-mono">{item.mtcn ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.senderName ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.receiverName ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.destinationCountry ?? '-'}</td>
                <td className="px-4 py-3 text-sm text-right font-mono">
                  {typeof item.amountUsd === 'number' ? item.amountUsd.toLocaleString('hu-HU', { minimumFractionDigits: 2 }) : '-'}
                </td>
                <td className="px-4 py-3 text-sm text-right font-mono">
                  {typeof item.amountHuf === 'number' ? item.amountHuf.toLocaleString('hu-HU') : '-'}
                </td>
                <td className="px-4 py-3 text-sm">
                  <span className={`rounded-full px-2 py-1 text-xs font-medium ${STATUS_COLORS[item.status ?? ''] ?? 'bg-gray-100 text-gray-800'}`}>
                    {item.status ?? '-'}
                  </span>
                </td>
                <td className="px-4 py-3 text-sm">
                  {item.createdAt ? new Date(item.createdAt).toLocaleString('hu-HU') : '-'}
                </td>
                <td className="px-4 py-3 text-right">
                  {item.status === 'COMPLETED' && item.transactionType !== 'STORNO' && (
                    <button onClick={() => handleStorno(item.id)}
                      className="form-button p-1 text-red-600" title="Sztornó">
                      <RotateCcw className="h-4 w-4" />
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        Összesen: {filtered.length} / {items.length}
      </div>

      {/* Modal */}
      {modal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-lg rounded-lg bg-white p-6 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-bold">{modalTitle[modal]}</h2>
              <button onClick={() => setModal(null)}><X className="h-5 w-5" /></button>
            </div>

            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="form-label">MTCN</label>
                  <input type="text" className="form-input w-full" placeholder="MTCN szám"
                    value={form.mtcn} onChange={e => setForm(f => ({ ...f, mtcn: e.target.value }))} />
                </div>
                <div>
                  <label className="form-label">Cél ország</label>
                  <input type="text" className="form-input w-full" placeholder="pl. HU"
                    value={form.destinationCountry} onChange={e => setForm(f => ({ ...f, destinationCountry: e.target.value }))} />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="form-label">Küldő neve</label>
                  <input type="text" className="form-input w-full"
                    value={form.senderName} onChange={e => setForm(f => ({ ...f, senderName: e.target.value }))} />
                </div>
                <div>
                  <label className="form-label">Címzett neve</label>
                  <input type="text" className="form-input w-full"
                    value={form.receiverName} onChange={e => setForm(f => ({ ...f, receiverName: e.target.value }))} />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="form-label">USD összeg</label>
                  <input type="number" step="0.01" className="form-input w-full"
                    value={form.amountUsd} onChange={e => setForm(f => ({ ...f, amountUsd: e.target.value }))} />
                </div>
                <div>
                  <label className="form-label">HUF összeg</label>
                  <input type="number" step="1" className="form-input w-full"
                    value={form.amountHuf} onChange={e => setForm(f => ({ ...f, amountHuf: e.target.value }))} />
                </div>
                <div>
                  <label className="form-label">Árfolyam</label>
                  <input type="number" step="0.01" className="form-input w-full"
                    value={form.exchangeRate} onChange={e => setForm(f => ({ ...f, exchangeRate: e.target.value }))} />
                </div>
              </div>

              <div>
                <label className="form-label">Díj (fee)</label>
                <input type="number" step="0.01" className="form-input w-full"
                  value={form.feeAmount} onChange={e => setForm(f => ({ ...f, feeAmount: e.target.value }))} />
              </div>
            </div>

            <div className="mt-6 flex justify-end gap-3">
              <button onClick={() => setModal(null)} className="form-button">Mégse</button>
              <button onClick={handleSubmit} disabled={submitting}
                className="form-button-primary flex items-center gap-1">
                {submitting ? 'Mentés...' : 'Rögzítés'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
