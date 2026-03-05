import { useState, useEffect, useCallback } from 'react'
import {
  Plus,
  Clock,
  CheckCircle,
  XCircle,
  Eye,
  Save,
  ArrowLeftRight,
  Building2,
  Banknote,
  PenLine,
  RefreshCw,
} from 'lucide-react'
import { useHotkeys } from 'react-hotkeys-hook'
import { transferApi, currencyApi } from '../../services/api'
import type { Transfer, Currency, CreateTransferRequest } from '../../services/api'
import {
  formatInteger,
  formatDateTime,
  formatTime,
  currencyColorClass,
  MOVEMENT_TYPE_LABELS,
  MOVEMENT_STATUS_LABELS,
} from './treasuryUtils'
import { TableSkeleton } from './LoadingSkeleton'

const MOVEMENT_TYPES = [
  { value: 'VAULT_WITHDRAW' as const, label: 'Bank kivét', description: 'Értéktárból bankba szállítás', icon: Banknote },
  { value: 'VAULT_DEPOSIT' as const, label: 'Bank befizetés', description: 'Bankból értéktárba befizetés', icon: Banknote },
  { value: 'CURRENCY' as const, label: 'Iroda szállítás', description: 'Irodák közti készletmozgatás', icon: ArrowLeftRight },
  { value: 'CORRECTION' as const, label: 'Korrekció', description: 'Leltárkülönbözet rendezés', icon: PenLine },
] as const

export default function MovementManager() {
  const [loading, setLoading] = useState(true)
  const [pendingTransfers, setPendingTransfers] = useState<Transfer[]>([])
  const [allTransfers, setAllTransfers] = useState<Transfer[]>([])
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [showNewModal, setShowNewModal] = useState(false)
  const [showDetailModal, setShowDetailModal] = useState<Transfer | null>(null)
  const [statusFilter, setStatusFilter] = useState('all')
  const [typeFilter, setTypeFilter] = useState('all')

  // New movement form state
  const [movementType, setMovementType] = useState<CreateTransferRequest['transferType']>('CURRENCY')
  const [toBranchId, setToBranchId] = useState('')
  const [currencyId, setCurrencyId] = useState<number>(0)
  const [amount, setAmount] = useState('')
  const [notes, setNotes] = useState('')

  const fetchData = useCallback(async () => {
    try {
      const [pending, all, currData] = await Promise.all([
        transferApi.getPending().catch(() => [] as Transfer[]),
        transferApi.search({ page: 0, size: 50 }).catch(() => ({ content: [] as Transfer[], totalElements: 0, totalPages: 0, size: 50, number: 0 })),
        currencyApi.list().catch(() => [] as Currency[]),
      ])
      setPendingTransfers(pending)
      setAllTransfers(all.content)
      setCurrencies(currData)
    } catch (err) {
      console.error('MovementManager fetch error:', err)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void fetchData()
    const interval = setInterval(() => void fetchData(), 15_000) // 15s polling for pending
    return () => clearInterval(interval)
  }, [fetchData])

  // Hotkeys
  useHotkeys('n', () => setShowNewModal(true), { enableOnFormTags: false })
  useHotkeys('escape', () => { setShowNewModal(false); setShowDetailModal(null) }, { enableOnFormTags: true })

  const handleApprove = useCallback(async (id: number) => {
    try {
      await transferApi.receive(id, { receivedAmount: 0 })
      void fetchData()
    } catch (err) {
      console.error('Approve error:', err)
    }
  }, [fetchData])

  const handleReject = useCallback(async (id: number) => {
    try {
      await transferApi.reject(id, 'Értéktáros által elutasítva')
      void fetchData()
    } catch (err) {
      console.error('Reject error:', err)
    }
  }, [fetchData])

  const handleSubmitNew = useCallback(async (e: React.FormEvent) => {
    e.preventDefault()
    if (!currencyId || !amount) return
    try {
      await transferApi.create({
        toBranchId,
        currencyId,
        amount: parseFloat(amount),
        transferType: movementType,
        notes: notes || undefined,
      })
      setShowNewModal(false)
      setAmount('')
      setNotes('')
      void fetchData()
    } catch (err) {
      console.error('Create movement error:', err)
    }
  }, [toBranchId, currencyId, amount, movementType, notes, fetchData])

  // Filtered history
  const filteredTransfers = allTransfers.filter((t) => {
    if (statusFilter !== 'all' && t.status !== statusFilter) return false
    if (typeFilter !== 'all' && t.transferType !== typeFilter) return false
    return true
  })

  if (loading) return <TableSkeleton rows={6} cols={7} />

  const approvedToday = allTransfers.filter(
    (t) => t.status === 'COMPLETED' || t.status === 'RECEIVED'
  ).length

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <h1 className="text-xl font-bold text-secondary-900">Készlet Mozgások</h1>
          <span className="badge badge-yellow">📥 Függő: {pendingTransfers.length}</span>
          <span className="badge badge-green">✅ Jóváhagyva (ma): {approvedToday}</span>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={() => void fetchData()} className="form-button h-8 text-xs">
            <RefreshCw size={14} />
          </button>
          <button onClick={() => setShowNewModal(true)} className="form-button-primary h-8 text-xs">
            <Plus size={16} />
            <span>Új mozgás</span>
          </button>
        </div>
      </div>

      {/* Pending movements */}
      {pendingTransfers.length > 0 && (
        <div className="form-panel">
          <h2 className="text-lg font-bold text-secondary-900 mb-4 flex items-center gap-2">
            <Clock size={20} className="text-warning-500" />
            Függő mozgások ({pendingTransfers.length})
          </h2>
          <div className="space-y-3">
            {pendingTransfers.map((t) => (
              <div
                key={t.id}
                className="p-4 rounded-lg border border-warning-200 bg-warning-50 hover:bg-warning-100 transition-colors"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <span className="font-bold text-secondary-900">#{t.transferNumber}</span>
                      <span className="badge badge-yellow">
                        {MOVEMENT_TYPE_LABELS[t.transferType] ?? t.transferTypeDisplay}
                      </span>
                      <span className="text-sm text-secondary-600">
                        {t.fromBranchName}
                        {t.toBranchName && ` → ${t.toBranchName}`}
                      </span>
                    </div>
                    <div className="text-sm text-secondary-700 mb-2">
                      <span className={`font-bold ${currencyColorClass(t.currencyCode)}`}>
                        {t.currencyCode}
                      </span>{' '}
                      <span className="font-mono font-semibold">{formatInteger(t.amount)}</span>{' '}
                      <span className="text-secondary-500">| Kérte: {t.fromWorkerName}</span>
                    </div>
                    <div className="text-xs text-secondary-500">{formatDateTime(t.createdAt)}</div>
                  </div>
                  <div className="flex items-center gap-2 ml-4">
                    <button
                      className="form-button-success h-8 text-xs"
                      onClick={() => void handleApprove(t.id)}
                    >
                      <CheckCircle size={16} />
                      Jóváhagy
                    </button>
                    <button
                      className="form-button-danger h-8 text-xs"
                      onClick={() => void handleReject(t.id)}
                    >
                      <XCircle size={16} />
                      Elutasít
                    </button>
                    <button
                      className="form-button h-8 text-xs"
                      onClick={() => setShowDetailModal(t)}
                    >
                      <Eye size={16} />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Movement History */}
      <div className="form-panel">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-bold text-secondary-900">Mozgás történet</h2>
          <div className="flex items-center gap-2">
            <select
              className="form-input w-40 h-8 text-xs"
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
            >
              <option value="all">Minden típus</option>
              <option value="VAULT_WITHDRAW">Bank kivét</option>
              <option value="VAULT_DEPOSIT">Bank befizetés</option>
              <option value="CURRENCY">Szállítás</option>
              <option value="CORRECTION">Korrekció</option>
            </select>
            <select
              className="form-input w-40 h-8 text-xs"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <option value="all">Minden státusz</option>
              <option value="PENDING">Függő</option>
              <option value="COMPLETED">Jóváhagyva</option>
              <option value="REJECTED">Elutasítva</option>
            </select>
          </div>
        </div>
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th className="w-20">ID</th>
              <th className="w-20">Idő</th>
              <th className="w-32">Típus</th>
              <th className="w-48">Iroda</th>
              <th className="w-20">Valuta</th>
              <th className="text-right w-28">Összeg</th>
              <th className="w-32">Státusz</th>
              <th className="w-12"></th>
            </tr>
          </thead>
          <tbody>
            {filteredTransfers.length === 0 && (
              <tr>
                <td colSpan={8} className="text-center text-sm text-secondary-400 py-8">
                  Nincs találat
                </td>
              </tr>
            )}
            {filteredTransfers.map((t) => (
              <tr key={t.id}>
                <td className="font-mono text-xs">#{t.transferNumber}</td>
                <td className="text-xs">{formatTime(t.createdAt)}</td>
                <td className="text-xs">
                  {MOVEMENT_TYPE_LABELS[t.transferType] ?? t.transferTypeDisplay}
                </td>
                <td className="text-xs">
                  {t.fromBranchName}
                  {t.toBranchName && (
                    <span className="text-secondary-400"> → {t.toBranchName}</span>
                  )}
                </td>
                <td className={`font-bold ${currencyColorClass(t.currencyCode)}`}>
                  {t.currencyCode}
                </td>
                <td className="text-right font-mono font-semibold">
                  {formatInteger(t.amount)}
                </td>
                <td>
                  <span
                    className={`badge ${
                      t.status === 'PENDING'
                        ? 'badge-yellow'
                        : t.status === 'COMPLETED' || t.status === 'RECEIVED'
                          ? 'badge-green'
                          : t.status === 'REJECTED'
                            ? 'badge-red'
                            : 'badge-gray'
                    }`}
                  >
                    {MOVEMENT_STATUS_LABELS[t.status] ?? t.statusDisplay}
                  </span>
                </td>
                <td className="text-center">
                  <button
                    className="text-primary-600 hover:text-primary-700"
                    onClick={() => setShowDetailModal(t)}
                  >
                    <Eye size={16} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* New Movement Modal */}
      {showNewModal && (
        <ModalOverlay onClose={() => setShowNewModal(false)}>
          <div className="bg-white rounded-lg shadow-xl p-6 max-w-2xl w-full mx-4">
            <h2 className="text-xl font-bold text-secondary-900 mb-6">Új készlet mozgás</h2>
            <form onSubmit={(e) => void handleSubmitNew(e)} className="space-y-4">
              {/* Movement type */}
              <div>
                <label className="form-label">Mozgás típusa</label>
                <div className="grid grid-cols-2 gap-3">
                  {MOVEMENT_TYPES.map((type) => (
                    <button
                      type="button"
                      key={type.value}
                      onClick={() => setMovementType(type.value)}
                      className={`p-4 rounded-lg border-2 transition-all text-left ${
                        movementType === type.value
                          ? 'border-primary-600 bg-primary-50'
                          : 'border-secondary-200 bg-white hover:border-secondary-400'
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <type.icon
                          size={24}
                          className={
                            movementType === type.value
                              ? 'text-primary-600'
                              : 'text-secondary-400'
                          }
                        />
                        <div>
                          <div className="font-semibold text-secondary-900">{type.label}</div>
                          <div className="text-xs text-secondary-500">{type.description}</div>
                        </div>
                      </div>
                    </button>
                  ))}
                </div>
              </div>

              {/* Branch */}
              <div>
                <label className="form-label">
                  <Building2 size={14} className="inline mr-1" />
                  Cél iroda
                </label>
                <input
                  type="text"
                  className="form-input w-full"
                  placeholder="Iroda azonosító"
                  value={toBranchId}
                  onChange={(e) => setToBranchId(e.target.value)}
                />
              </div>

              {/* Currency + Amount */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">Valuta</label>
                  <select
                    className="form-input w-full"
                    value={currencyId}
                    onChange={(e) => setCurrencyId(Number(e.target.value))}
                  >
                    <option value={0}>Válassz valutát</option>
                    {currencies.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.code} — {c.name}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="form-label">Mennyiség</label>
                  <input
                    type="number"
                    className="form-input w-full font-mono"
                    placeholder="0"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                  />
                </div>
              </div>

              {/* Notes */}
              <div>
                <label className="form-label">Indoklás</label>
                <textarea
                  className="form-input w-full min-h-[80px]"
                  placeholder="Miért szükséges ez a mozgás?"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                />
              </div>

              {/* Buttons */}
              <div className="flex items-center justify-end gap-3 pt-4 border-t border-secondary-200">
                <button
                  type="button"
                  className="form-button"
                  onClick={() => setShowNewModal(false)}
                >
                  Mégse
                </button>
                <button type="submit" className="form-button-primary">
                  <Save size={18} />
                  <span>Létrehozás</span>
                </button>
              </div>
            </form>
          </div>
        </ModalOverlay>
      )}

      {/* Detail Modal */}
      {showDetailModal && (
        <ModalOverlay onClose={() => setShowDetailModal(null)}>
          <div className="bg-white rounded-lg shadow-xl p-6 max-w-lg w-full mx-4">
            <h2 className="text-xl font-bold text-secondary-900 mb-4">
              Mozgás részletei — #{showDetailModal.transferNumber}
            </h2>
            <div className="space-y-3 text-sm">
              <DetailRow label="Típus" value={MOVEMENT_TYPE_LABELS[showDetailModal.transferType] ?? showDetailModal.transferTypeDisplay} />
              <DetailRow label="Forrás" value={showDetailModal.fromBranchName} />
              <DetailRow label="Cél" value={showDetailModal.toBranchName} />
              <DetailRow label="Valuta" value={showDetailModal.currencyCode} />
              <DetailRow label="Összeg" value={formatInteger(showDetailModal.amount)} mono />
              <DetailRow label="Státusz" value={MOVEMENT_STATUS_LABELS[showDetailModal.status] ?? showDetailModal.statusDisplay} />
              <DetailRow label="Kérte" value={showDetailModal.fromWorkerName} />
              <DetailRow label="Létrehozva" value={formatDateTime(showDetailModal.createdAt)} />
              {showDetailModal.notes && <DetailRow label="Megjegyzés" value={showDetailModal.notes} />}
            </div>
            <button
              onClick={() => setShowDetailModal(null)}
              className="form-button-primary w-full mt-6"
            >
              Bezárás
            </button>
          </div>
        </ModalOverlay>
      )}
    </div>
  )
}

// ---- Helper components ----

function ModalOverlay({ children, onClose }: { children: React.ReactNode; onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center" onClick={onClose}>
      <div onClick={(e) => e.stopPropagation()}>{children}</div>
    </div>
  )
}

function DetailRow({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex justify-between py-1 border-b border-secondary-100">
      <span className="text-secondary-600">{label}</span>
      <span className={`font-semibold text-secondary-900 ${mono ? 'font-mono' : ''}`}>{value}</span>
    </div>
  )
}
