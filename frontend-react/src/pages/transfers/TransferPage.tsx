import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowRightLeft,
  Send,
  Download,
  RefreshCw,
  CheckCircle,
  XCircle,
  AlertCircle,
  Eye,
  Clock,
  Building2
} from 'lucide-react'
import {
  transferApi,
  currencyApi,
  Transfer,
  CreateTransferRequest,
  Currency
} from '../../services/api'
import { useAuthStore } from '../../stores/authStore'
import { NumberInput } from '../../components/NumberInput'
import { formatDecimal, formatInteger } from '../../utils/numberFormat'
import { getErrorMessage } from '../../utils/errorHandling'

type TabType = 'outgoing' | 'incoming' | 'pending'

/**
 * Átadás-átvétel oldal
 *
 * Legacy: ATADVET.DLL funkciók
 * - Pénztárak közötti valuta/készpénz mozgás
 * - Átadólap generálás
 * - Átvétel kezelés
 */
export default function TransferPage() {
  const navigate = useNavigate()
  const worker = useAuthStore((state) => state.worker)

  // Tab state
  const [activeTab, setActiveTab] = useState<TabType>('pending')

  // Lists
  const [outgoingTransfers, setOutgoingTransfers] = useState<Transfer[]>([])
  const [incomingTransfers, setIncomingTransfers] = useState<Transfer[]>([])
  const [pendingTransfers, setPendingTransfers] = useState<Transfer[]>([])
  const [pendingCount, setPendingCount] = useState(0)

  // Form state for new transfer
  const [showNewTransfer, setShowNewTransfer] = useState(false)
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [branches, setBranches] = useState<{ id: string; code: string; name: string }[]>([])

  // New transfer form
  const [toBranchId, setToBranchId] = useState('')
  const [currencyId, setCurrencyId] = useState<number | null>(null)
  const [amount, setAmount] = useState('')
  const [transferType, setTransferType] = useState<CreateTransferRequest['transferType']>('CURRENCY')
  const [notes, setNotes] = useState('')

  // Receive modal
  const [showReceiveModal, setShowReceiveModal] = useState(false)
  const [selectedTransfer, setSelectedTransfer] = useState<Transfer | null>(null)
  const [receivedAmount, setReceivedAmount] = useState('')
  const [receiveNotes, setReceiveNotes] = useState('')

  // Loading & Error
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  // Load data
  useEffect(() => {
    void loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      const [outgoing, incoming, pending, count, currencyData] = await Promise.all([
        transferApi.getOutgoing(),
        transferApi.getIncoming(),
        transferApi.getPending(),
        transferApi.countPending(),
        currencyApi.getActive()
      ])

      setOutgoingTransfers(outgoing)
      setIncomingTransfers(incoming)
      setPendingTransfers(pending)
      setPendingCount(count)
      setCurrencies(currencyData)

      // TODO: Load branches from API
      setBranches([
        { id: 'branch-1', code: 'BP01', name: 'Budapest Központi' },
        { id: 'branch-2', code: 'BP02', name: 'Budapest Nyugati' },
        { id: 'branch-3', code: 'BP03', name: 'Budapest Keleti' }
      ])
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  // Create new transfer
  const handleCreateTransfer = async () => {
    if (!toBranchId || !currencyId || !amount) {
      setError('Minden mező kitöltése kötelező!')
      return
    }

    const amountValue = parseFloat(amount.replace(',', '.').replace(/\s/g, ''))
    if (amountValue <= 0) {
      setError('Adjon meg pozitív összeget!')
      return
    }

    try {
      setLoading(true)
      setError(null)

      const request: CreateTransferRequest = {
        toBranchId,
        currencyId,
        amount: amountValue,
        transferType,
        notes: notes || undefined
      }

      const result = await transferApi.create(request)
      setSuccess(`Átadás létrehozva: ${result.transferNumber}`)
      setShowNewTransfer(false)

      // Reset form
      setToBranchId('')
      setCurrencyId(null)
      setAmount('')
      setNotes('')

      // Reload
      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  // Receive transfer
  const handleReceive = async () => {
    if (!selectedTransfer || !receivedAmount) {
      setError('Adja meg az átvett összeget!')
      return
    }

    const amountValue = parseFloat(receivedAmount.replace(',', '.').replace(/\s/g, ''))

    try {
      setLoading(true)
      setError(null)

      await transferApi.receive(selectedTransfer.id, {
        receivedAmount: amountValue,
        notes: receiveNotes || undefined
      })

      setSuccess('Átvétel sikeres!')
      setShowReceiveModal(false)
      setSelectedTransfer(null)
      setReceivedAmount('')
      setReceiveNotes('')

      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  // Reject transfer
  const handleReject = async (transfer: Transfer) => {
    const reason = prompt('Visszautasítás oka:')
    if (!reason) return

    try {
      setLoading(true)
      await transferApi.reject(transfer.id, reason)
      setSuccess('Átadás visszautasítva')
      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  // Cancel transfer
  const handleCancel = async (transfer: Transfer) => {
    if (!confirm('Biztosan törli ezt az átadást?')) return

    try {
      setLoading(true)
      await transferApi.cancel(transfer.id)
      setSuccess('Átadás törölve')
      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  // Open receive modal
  const openReceiveModal = (transfer: Transfer) => {
    setSelectedTransfer(transfer)
    setReceivedAmount(transfer.amount.toString().replace('.', ','))
    setShowReceiveModal(true)
  }

  // Status badge
  const getStatusBadge = (status: string, statusDisplay: string) => {
    const statusMap: Record<string, string> = {
      PENDING: 'bg-yellow-100 text-yellow-700',
      IN_TRANSIT: 'bg-blue-100 text-blue-700',
      RECEIVED: 'bg-purple-100 text-purple-700',
      COMPLETED: 'bg-green-100 text-green-700',
      REJECTED: 'bg-red-100 text-red-700',
      CANCELLED: 'bg-gray-100 text-gray-500'
    }
    return (
      <span className={`px-2 py-1 text-xs rounded ${statusMap[status] || 'bg-gray-100'}`}>
        {statusDisplay}
      </span>
    )
  }

  // Transfer list component
  const TransferList = ({ transfers, showActions = false, isOutgoing = false }: {
    transfers: Transfer[]
    showActions?: boolean
    isOutgoing?: boolean
  }) => (
    <div className="overflow-x-auto">
      <table className="data-grid w-full">
        <thead>
          <tr>
            <th>Átadólap szám</th>
            <th>{isOutgoing ? 'Cél iroda' : 'Forrás iroda'}</th>
            <th>Típus</th>
            <th>Valuta</th>
            <th className="text-right">Összeg</th>
            <th>Dátum</th>
            <th>Státusz</th>
            {showActions && <th className="w-32">Műveletek</th>}
          </tr>
        </thead>
        <tbody>
          {transfers.length === 0 ? (
            <tr>
              <td colSpan={showActions ? 8 : 7} className="text-center text-gray-500 py-8">
                Nincsenek átadások
              </td>
            </tr>
          ) : (
            transfers.map((transfer) => (
              <tr key={transfer.id}>
                <td className="font-mono font-semibold">{transfer.transferNumber}</td>
                <td>
                  <div className="flex items-center gap-1">
                    <Building2 size={14} className="text-gray-400" />
                    <span>
                      {isOutgoing
                        ? `${transfer.toBranchCode} - ${transfer.toBranchName}`
                        : `${transfer.fromBranchCode} - ${transfer.fromBranchName}`}
                    </span>
                  </div>
                </td>
                <td>{transfer.transferTypeDisplay}</td>
                <td className="font-semibold">{transfer.currencyCode}</td>
                <td className="text-right font-mono">
                  {transfer.currencyCode === 'HUF'
                    ? formatInteger(transfer.amount)
                    : formatDecimal(transfer.amount, 2, 2)}
                </td>
                <td className="text-sm">
                  <div>{new Date(transfer.transferDate).toLocaleDateString('hu-HU')}</div>
                  <div className="text-gray-500">{transfer.transferTime}</div>
                </td>
                <td>{getStatusBadge(transfer.status, transfer.statusDisplay)}</td>
                {showActions && (
                  <td>
                    <div className="flex gap-1">
                      <button
                        type="button"
                        onClick={() => navigate(`/transfers/${transfer.id}`)}
                        className="toolbar-button"
                        title="Részletek"
                      >
                        <Eye size={14} />
                      </button>
                      {transfer.isPending && !isOutgoing && (
                        <>
                          <button
                            type="button"
                            onClick={() => openReceiveModal(transfer)}
                            className="toolbar-button text-green-600"
                            title="Átvétel"
                          >
                            <CheckCircle size={14} />
                          </button>
                          <button
                            type="button"
                            onClick={() => handleReject(transfer)}
                            className="toolbar-button text-red-600"
                            title="Visszautasítás"
                          >
                            <XCircle size={14} />
                          </button>
                        </>
                      )}
                      {transfer.isPending && isOutgoing && (
                        <button
                          type="button"
                          onClick={() => handleCancel(transfer)}
                          className="toolbar-button text-red-600"
                          title="Törlés"
                        >
                          <XCircle size={14} />
                        </button>
                      )}
                    </div>
                  </td>
                )}
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  )

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <ArrowRightLeft />
          Átadás-átvétel
          {pendingCount > 0 && (
            <span className="bg-red-500 text-white text-xs px-2 py-1 rounded-full">
              {pendingCount} új
            </span>
          )}
        </h1>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={loadData}
            className="form-button flex items-center gap-1"
            disabled={loading}
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            Frissítés
          </button>
          <button
            type="button"
            onClick={() => setShowNewTransfer(true)}
            className="form-button-primary flex items-center gap-1"
          >
            <Send size={16} />
            Új átadás
          </button>
        </div>
      </div>

      {/* Error/Success messages */}
      {error && (
        <div className="form-panel bg-red-50 border-red-200 flex items-center gap-2 text-red-700">
          <AlertCircle size={18} />
          <span>{error}</span>
          <button type="button" onClick={() => setError(null)} className="ml-auto text-red-500">×</button>
        </div>
      )}

      {success && (
        <div className="form-panel bg-green-50 border-green-200 flex items-center gap-2 text-green-700">
          <CheckCircle size={18} />
          <span>{success}</span>
          <button type="button" onClick={() => setSuccess(null)} className="ml-auto text-green-500">×</button>
        </div>
      )}

      {/* Tabs */}
      <div className="flex gap-1 border-b">
        <button
          type="button"
          onClick={() => setActiveTab('pending')}
          className={`px-4 py-2 font-medium border-b-2 transition-colors ${
            activeTab === 'pending'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-gray-600 hover:text-gray-800'
          }`}
        >
          <Clock size={16} className="inline mr-1" />
          Átvételre váró ({pendingCount})
        </button>
        <button
          type="button"
          onClick={() => setActiveTab('outgoing')}
          className={`px-4 py-2 font-medium border-b-2 transition-colors ${
            activeTab === 'outgoing'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-gray-600 hover:text-gray-800'
          }`}
        >
          <Send size={16} className="inline mr-1" />
          Kimenő átadások
        </button>
        <button
          type="button"
          onClick={() => setActiveTab('incoming')}
          className={`px-4 py-2 font-medium border-b-2 transition-colors ${
            activeTab === 'incoming'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-gray-600 hover:text-gray-800'
          }`}
        >
          <Download size={16} className="inline mr-1" />
          Bejövő átadások
        </button>
      </div>

      {/* Tab content */}
      <div className="form-panel p-0">
        {activeTab === 'pending' && (
          <TransferList transfers={pendingTransfers} showActions={true} isOutgoing={false} />
        )}
        {activeTab === 'outgoing' && (
          <TransferList transfers={outgoingTransfers} showActions={true} isOutgoing={true} />
        )}
        {activeTab === 'incoming' && (
          <TransferList transfers={incomingTransfers} showActions={false} isOutgoing={false} />
        )}
      </div>

      {/* New Transfer Modal */}
      {showNewTransfer && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md p-6">
            <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
              <Send />
              Új átadás létrehozása
            </h2>

            <div className="space-y-4">
              <div>
                <label htmlFor="to-branch" className="form-label">Cél iroda *</label>
                <select
                  id="to-branch"
                  value={toBranchId}
                  onChange={(e) => setToBranchId(e.target.value)}
                  className="form-input w-full"
                >
                  <option value="">-- Válasszon irodát --</option>
                  {branches
                    .filter(b => b.id !== worker?.branchId)
                    .map(b => (
                      <option key={b.id} value={b.id}>{b.code} - {b.name}</option>
                    ))}
                </select>
              </div>

              <div>
                <label htmlFor="transfer-type" className="form-label">Típus *</label>
                <select
                  id="transfer-type"
                  value={transferType}
                  onChange={(e) => setTransferType(e.target.value as CreateTransferRequest['transferType'])}
                  className="form-input w-full"
                >
                  <option value="CURRENCY">Valuta átadás</option>
                  <option value="CASH">Készpénz (HUF) átadás</option>
                  <option value="HANDLING_FEE">Kezelési díj átadás</option>
                  <option value="VAULT_DEPOSIT">Értéktár feltöltés</option>
                  <option value="VAULT_WITHDRAW">Értéktár leszedés</option>
                </select>
              </div>

              <div>
                <label htmlFor="currency" className="form-label">Valuta *</label>
                <select
                  id="currency"
                  value={currencyId ?? ''}
                  onChange={(e) => setCurrencyId(e.target.value ? Number(e.target.value) : null)}
                  className="form-input w-full"
                >
                  <option value="">-- Válasszon valutát --</option>
                  {currencies.map(c => (
                    <option key={c.id} value={c.id}>{c.code} - {c.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label htmlFor="amount" className="form-label">Összeg *</label>
                <NumberInput
                  id="amount"
                  value={amount}
                  onChange={setAmount}
                  className="form-input w-full"
                  placeholder="0,00"
                  allowDecimals={true}
                  allowNegative={false}
                />
              </div>

              <div>
                <label htmlFor="notes" className="form-label">Megjegyzés</label>
                <textarea
                  id="notes"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="form-input w-full"
                  rows={2}
                  placeholder="Opcionális megjegyzés..."
                />
              </div>
            </div>

            <div className="flex justify-end gap-2 mt-6">
              <button
                type="button"
                onClick={() => setShowNewTransfer(false)}
                className="form-button"
              >
                Mégsem
              </button>
              <button
                type="button"
                onClick={handleCreateTransfer}
                className="form-button-primary"
                disabled={loading}
              >
                {loading ? <RefreshCw size={16} className="animate-spin" /> : <Send size={16} />}
                Átadás létrehozása
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Receive Modal */}
      {showReceiveModal && selectedTransfer && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md p-6">
            <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
              <Download />
              Átvétel végrehajtása
            </h2>

            <div className="space-y-4">
              <div className="bg-gray-50 p-3 rounded">
                <div className="text-sm text-gray-600">Átadólap szám</div>
                <div className="font-mono font-semibold">{selectedTransfer.transferNumber}</div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <div className="text-sm text-gray-600">Forrás iroda</div>
                  <div className="font-semibold">{selectedTransfer.fromBranchCode}</div>
                </div>
                <div>
                  <div className="text-sm text-gray-600">Átadó</div>
                  <div className="font-semibold">{selectedTransfer.fromWorkerName}</div>
                </div>
              </div>

              <div className="bg-blue-50 p-3 rounded">
                <div className="text-sm text-gray-600">Küldött összeg</div>
                <div className="text-xl font-mono font-bold text-blue-700">
                  {formatDecimal(selectedTransfer.amount, 2, 2)} {selectedTransfer.currencyCode}
                </div>
              </div>

              <div>
                <label htmlFor="received-amount" className="form-label">Átvett összeg *</label>
                <NumberInput
                  id="received-amount"
                  value={receivedAmount}
                  onChange={setReceivedAmount}
                  className="form-input w-full text-lg"
                  allowDecimals={true}
                  allowNegative={false}
                />
              </div>

              <div>
                <label htmlFor="receive-notes" className="form-label">Megjegyzés</label>
                <textarea
                  id="receive-notes"
                  value={receiveNotes}
                  onChange={(e) => setReceiveNotes(e.target.value)}
                  className="form-input w-full"
                  rows={2}
                  placeholder="Eltérés esetén írja le az okot..."
                />
              </div>
            </div>

            <div className="flex justify-end gap-2 mt-6">
              <button
                type="button"
                onClick={() => {
                  setShowReceiveModal(false)
                  setSelectedTransfer(null)
                }}
                className="form-button"
              >
                Mégsem
              </button>
              <button
                type="button"
                onClick={handleReceive}
                className="form-button-primary"
                disabled={loading}
              >
                {loading ? <RefreshCw size={16} className="animate-spin" /> : <CheckCircle size={16} />}
                Átvétel megerősítése
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
