import { useState, useEffect, useCallback } from 'react'
import {
  Plus,
  Building2,
  TrendingUp,
  TrendingDown,
  RefreshCw,
  CheckCircle,
  Eye,
} from 'lucide-react'
import { useHotkeys } from 'react-hotkeys-hook'
import { ertektarApi, currencyApi } from '../../services/api/index'
import type { BankTransaction, BankTransactionRequest, Currency } from '../../services/api/index'
import { formatInteger, formatDateTime, currencyColorClass } from './treasuryUtils'
import { TableSkeleton } from './LoadingSkeleton'
import {
  isElectronQueueAvailable,
  saveAndSyncPendingBankTransaction,
} from '../../utils/electronTransactions'
import { getLocalPendingBankTransactions } from '../../utils/localQueue'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'

export default function BankTransactions() {
  const electronQueueAvailable = isElectronQueueAvailable()
  const [loading, setLoading] = useState(true)
  const [transactions, setTransactions] = useState<BankTransaction[]>([])
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [showNewModal, setShowNewModal] = useState(false)
  const [showDetailModal, setShowDetailModal] = useState<BankTransaction | null>(null)
  const [typeFilter, setTypeFilter] = useState('all')

  // Form state
  const [txType, setTxType] = useState<'BUY' | 'SELL'>('BUY')
  const [currencyCode, setCurrencyCode] = useState('')
  const [amount, setAmount] = useState('')
  const [exchangeRate, setExchangeRate] = useState('')
  const [bankName, setBankName] = useState('')
  const [bankRef, setBankRef] = useState('')
  const [note, setNote] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const fetchData = useCallback(async () => {
    try {
      const [txDataRaw, currDataRaw, localPending] = await Promise.all([
        ertektarApi.getBankTransactions().catch(() => []),
        currencyApi.list().catch(() => []),
        electronQueueAvailable ? getLocalPendingBankTransactions() : Promise.resolve([] as BankTransaction[]),
      ])
      const txData = safeArray<BankTransaction>(txDataRaw)
      const currData = safeArray<Currency>(currDataRaw)
      setTransactions([...localPending, ...txData])
      setCurrencies(currData)
    } catch (err) {
      logger.error('BankTransactions', 'BankTransactions fetch error:', err)
    } finally {
      setLoading(false)
    }
  }, [electronQueueAvailable])

  useEffect(() => {
    void fetchData()
  }, [fetchData])

  useHotkeys('n', () => setShowNewModal(true), { enableOnFormTags: false })
  useHotkeys('escape', () => { setShowNewModal(false); setShowDetailModal(null) }, { enableOnFormTags: true })

  const handleSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault()
    if (!currencyCode || !amount || !exchangeRate) return
    setSubmitting(true)
    try {
      const computedHufAmount = (parseFloat(amount) * parseFloat(exchangeRate)) || 0
      const request: BankTransactionRequest = {
        transactionType: txType,
        currencyCode,
        amount: parseFloat(amount),
        exchangeRate: parseFloat(exchangeRate),
        bankName: bankName || undefined,
        bankReference: bankRef || undefined,
        note: note || undefined,
      }

      if (electronQueueAvailable) {
        await saveAndSyncPendingBankTransaction({
          transactionType: txType,
          currencyCode,
          amount: parseFloat(amount),
          exchangeRate: parseFloat(exchangeRate),
          hufAmount: computedHufAmount,
          vaultTerritoryId: null,
          bankName: bankName || null,
          bankReference: bankRef || null,
          note: note || null,
        })
      } else {
        await ertektarApi.createBankTransaction(request)
      }

      setShowNewModal(false)
      resetForm()
      void fetchData()
    } catch (err) {
      logger.error('BankTransactions', 'Create bank transaction error:', err)
    } finally {
      setSubmitting(false)
    }
  }, [txType, currencyCode, amount, exchangeRate, bankName, bankRef, note, fetchData, electronQueueAvailable])

  const resetForm = () => {
    setCurrencyCode('')
    setAmount('')
    setExchangeRate('')
    setBankName('')
    setBankRef('')
    setNote('')
  }

  const hufAmount = amount && exchangeRate
    ? (parseFloat(amount) * parseFloat(exchangeRate)).toFixed(0)
    : ''

  const filtered = transactions.filter(t =>
    typeFilter === 'all' || t.transactionType === typeFilter
  )

  if (loading) return <TableSkeleton rows={6} cols={7} />

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <h1 className="text-xl font-bold text-secondary-900">Banki Tranzakciok</h1>
          <span className="badge badge-blue">
            <TrendingUp size={12} /> Vetel: {transactions.filter(t => t.transactionType === 'BUY').length}
          </span>
          <span className="badge badge-orange">
            <TrendingDown size={12} /> Eladas: {transactions.filter(t => t.transactionType === 'SELL').length}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <select
            className="form-input w-36 h-8 text-xs"
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
          >
            <option value="all">Minden tipus</option>
            <option value="BUY">Vetel</option>
            <option value="SELL">Eladas</option>
          </select>
          <button onClick={() => void fetchData()} className="form-button h-8 text-xs">
            <RefreshCw size={14} />
          </button>
          <button onClick={() => setShowNewModal(true)} className="form-button-primary h-8 text-xs">
            <Plus size={16} />
            <span>Uj tranzakcio</span>
          </button>
        </div>
      </div>

      {/* Transaction table */}
      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th className="w-16">ID</th>
              <th className="w-20">Típus</th>
              <th className="w-16">Valuta</th>
              <th className="text-right w-28">Mennyiség</th>
              <th className="text-right w-24">Árfolyam</th>
              <th className="text-right w-28">HUF érték</th>
              <th className="w-32">Bank</th>
              <th className="w-24">Státusz</th>
              <th className="w-32">Dátum</th>
              <th className="w-8"></th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 && (
              <tr>
                <td colSpan={10} className="text-center text-sm text-secondary-400 py-8">
                  Nincs talalat
                </td>
              </tr>
            )}
            {filtered.map((tx) => (
              <tr key={tx.id}>
                <td className="font-mono text-xs">#{tx.id}</td>
                <td>
                  <span className={`badge ${tx.transactionType === 'BUY' ? 'badge-blue' : 'badge-orange'}`}>
                    {tx.transactionType === 'BUY' ? 'Vetel' : 'Eladas'}
                  </span>
                </td>
                <td className={`font-bold ${currencyColorClass(tx.currencyCode)}`}>
                  {tx.currencyCode}
                </td>
                <td className="text-right font-mono font-semibold">
                  {formatInteger(tx.amount)}
                </td>
                <td className="text-right font-mono text-xs">
                  {tx.exchangeRate?.toFixed(2)}
                </td>
                <td className="text-right font-mono font-semibold">
                  {formatInteger(tx.hufAmount)} Ft
                </td>
                <td className="text-xs text-secondary-600">
                  {tx.bankName || '-'}
                </td>
                <td>
                  <span className={`badge ${tx.status === 'COMPLETED' ? 'badge-green' : 'badge-yellow'}`}>
                    {tx.status === 'COMPLETED' ? 'Teljesitett' : tx.status}
                  </span>
                </td>
                <td className="text-xs">{formatDateTime(tx.createdAt)}</td>
                <td>
                  <button
                    className="text-primary-600 hover:text-primary-700"
                    onClick={() => setShowDetailModal(tx)}
                  >
                    <Eye size={16} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* New Transaction Modal */}
      {showNewModal && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center" onClick={() => setShowNewModal(false)}>
          <div className="bg-white rounded-lg shadow-xl p-4 max-w-lg w-full mx-4" onClick={e => e.stopPropagation()}>
            <h2 className="text-xl font-bold text-secondary-900 mb-3 flex items-center gap-2">
              <Building2 size={24} className="text-primary-600" />
              Uj banki tranzakcio
            </h2>
            <form onSubmit={(e) => void handleSubmit(e)} className="space-y-4">
              {/* Type selector */}
              <div className="grid grid-cols-2 gap-3">
                <button
                  type="button"
                  onClick={() => setTxType('BUY')}
                  className={`p-3 rounded-lg border-2 transition-all flex items-center gap-2 ${
                    txType === 'BUY'
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-secondary-200 hover:border-secondary-400'
                  }`}
                >
                  <TrendingUp size={20} className={txType === 'BUY' ? 'text-blue-600' : 'text-secondary-400'} />
                  <div className="text-left">
                    <div className="font-semibold">Vetel</div>
                    <div className="text-xs text-secondary-500">Bankbol valuta</div>
                  </div>
                </button>
                <button
                  type="button"
                  onClick={() => setTxType('SELL')}
                  className={`p-3 rounded-lg border-2 transition-all flex items-center gap-2 ${
                    txType === 'SELL'
                      ? 'border-orange-500 bg-orange-50'
                      : 'border-secondary-200 hover:border-secondary-400'
                  }`}
                >
                  <TrendingDown size={20} className={txType === 'SELL' ? 'text-orange-600' : 'text-secondary-400'} />
                  <div className="text-left">
                    <div className="font-semibold">Eladas</div>
                    <div className="text-xs text-secondary-500">Banknak valuta</div>
                  </div>
                </button>
              </div>

              {/* Currency */}
              <div>
                <label className="form-label">Valuta</label>
                <select
                  className="form-input w-full"
                  value={currencyCode}
                  onChange={e => setCurrencyCode(e.target.value)}
                  required
                >
                  <option value="">Valassz valutat</option>
                  {currencies.filter(c => c.code !== 'HUF').map(c => (
                    <option key={c.code} value={c.code}>{c.code} — {c.name}</option>
                  ))}
                </select>
              </div>

              {/* Amount + Rate */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">Mennyiseg</label>
                  <input
                    type="number"
                    className="form-input w-full font-mono"
                    placeholder="0"
                    value={amount}
                    onChange={e => setAmount(e.target.value)}
                    required
                    min="0.01"
                    step="0.01"
                  />
                </div>
                <div>
                  <label className="form-label">Árfolyam (HUF/1 egység)</label>
                  <input
                    type="number"
                    className="form-input w-full font-mono"
                    placeholder="0.00"
                    value={exchangeRate}
                    onChange={e => setExchangeRate(e.target.value)}
                    required
                    min="0.0001"
                    step="0.0001"
                  />
                </div>
              </div>

              {/* HUF preview */}
              {hufAmount && (
                <div className="p-3 rounded-lg bg-secondary-50 border border-secondary-200">
                  <div className="text-sm text-secondary-600">HUF ellenerteke:</div>
                  <div className="text-lg font-bold font-mono text-secondary-900">
                    {parseInt(hufAmount).toLocaleString('hu-HU')} Ft
                  </div>
                </div>
              )}

              {/* Bank details */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">Bank neve</label>
                  <input
                    type="text"
                    className="form-input w-full"
                    placeholder="pl. OTP, Raiffeisen"
                    value={bankName}
                    onChange={e => setBankName(e.target.value)}
                  />
                </div>
                <div>
                  <label className="form-label">Banki hivatkozas</label>
                  <input
                    type="text"
                    className="form-input w-full"
                    placeholder="Referenciaszam"
                    value={bankRef}
                    onChange={e => setBankRef(e.target.value)}
                  />
                </div>
              </div>

              {/* Note */}
              <div>
                <label className="form-label">Megjegyzes</label>
                <textarea
                  className="form-input w-full min-h-[60px]"
                  value={note}
                  onChange={e => setNote(e.target.value)}
                />
              </div>

              {/* Buttons */}
              <div className="flex justify-end gap-3 pt-4 border-t">
                <button type="button" className="form-button" onClick={() => setShowNewModal(false)}>
                  Mégse
                </button>
                <button type="submit" className="form-button-primary" disabled={submitting}>
                  <CheckCircle size={18} />
                  <span>{submitting ? 'Feldolgozás...' : 'Végrehajtás'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Detail Modal */}
      {showDetailModal && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center" onClick={() => setShowDetailModal(null)}>
          <div className="bg-white rounded-lg shadow-xl p-4 max-w-md w-full mx-4" onClick={e => e.stopPropagation()}>
            <h2 className="text-xl font-bold text-secondary-900 mb-4">
              Tranzakcio #{showDetailModal.id}
            </h2>
            <div className="space-y-2 text-sm">
              <Row label="Típus" value={showDetailModal.transactionType === 'BUY' ? 'Banki vétel' : 'Banki eladás'} />
              <Row label="Valuta" value={showDetailModal.currencyCode} />
              <Row label="Mennyiség" value={formatInteger(showDetailModal.amount)} mono />
              <Row label="Árfolyam" value={showDetailModal.exchangeRate?.toFixed(4)} mono />
              <Row label="HUF érték" value={`${formatInteger(showDetailModal.hufAmount)} Ft`} mono />
              <Row label="Bank" value={showDetailModal.bankName || '-'} />
              <Row label="Ref." value={showDetailModal.bankReference || '-'} />
              <Row label="Státusz" value={showDetailModal.status} />
              <Row label="Dátum" value={formatDateTime(showDetailModal.createdAt)} />
              {showDetailModal.note && <Row label="Megjegyzes" value={showDetailModal.note} />}
            </div>
            <button onClick={() => setShowDetailModal(null)} className="form-button-primary w-full mt-6">
              Bezaras
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

function Row({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex justify-between py-1 border-b border-secondary-100">
      <span className="text-secondary-600">{label}</span>
      <span className={`font-semibold text-secondary-900 ${mono ? 'font-mono' : ''}`}>{value}</span>
    </div>
  )
}
