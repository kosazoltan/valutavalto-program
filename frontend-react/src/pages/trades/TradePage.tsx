import { useCallback, useEffect, useMemo, useState } from 'react'
import { Check, CircleX, Loader2, Plus, RefreshCw, Send, Trash2 } from 'lucide-react'
import { tradeApi, type TradeDto } from '../../services/api/trades'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'

function todayIsoDate(): string {
  return new Date().toISOString().slice(0, 10)
}

function oneMonthAgoIsoDate(): string {
  const date = new Date()
  date.setMonth(date.getMonth() - 1)
  return date.toISOString().slice(0, 10)
}

function formatNumber(value: number | undefined): string {
  if (value == null || Number.isNaN(value)) return '0'
  return value.toLocaleString('hu-HU', { maximumFractionDigits: 4 })
}

const statusLabels: Record<string, string> = {
  PROPOSED: 'Ajánlat',
  ACCEPTED: 'Elfogadva',
  REJECTED: 'Elutasítva',
  COMPLETED: 'Teljesítve',
  CANCELLED: 'Törölve',
}

export default function TradePage() {
  const worker = useAuthStore((state) => state.worker)
  const currentBranchId = worker?.branchId ?? ''
  const [pending, setPending] = useState<TradeDto[]>([])
  const [history, setHistory] = useState<TradeDto[]>([])
  const [historyTotal, setHistoryTotal] = useState(0)
  const [from, setFrom] = useState(oneMonthAgoIsoDate())
  const [to, setTo] = useState(todayIsoDate())
  const [toBranchId, setToBranchId] = useState('')
  const [currencyCode, setCurrencyCode] = useState('EUR')
  const [amount, setAmount] = useState('')
  const [rate, setRate] = useState('1')
  const [notes, setNotes] = useState('')
  const [rejectReason, setRejectReason] = useState('')
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const pendingCount = pending.length
  const acceptedCount = useMemo(() => pending.filter((trade) => trade.status === 'ACCEPTED').length, [pending])

  const loadTrades = useCallback(async () => {
    if (!currentBranchId) {
      setLoading(false)
      return
    }
    try {
      setLoading(true)
      setError(null)
      const [pendingData, historyPage] = await Promise.all([
        tradeApi.pending(currentBranchId),
        tradeApi.history({ branchId: currentBranchId, from, to, size: 20 }),
      ])
      setPending(pendingData)
      setHistory(historyPage.content ?? [])
      setHistoryTotal(historyPage.totalElements ?? 0)
    } catch (err) {
      const message = getErrorMessage(err)
      setError(message)
      logger.error('TradePage', 'load failed', err)
    } finally {
      setLoading(false)
    }
  }, [currentBranchId, from, to])

  useEffect(() => {
    void loadTrades()
  }, [loadTrades])

  const proposeTrade = async () => {
    const parsedAmount = Number(amount)
    const parsedRate = Number(rate)
    if (!currentBranchId || !toBranchId.trim() || !currencyCode.trim() || parsedAmount <= 0 || parsedRate <= 0) {
      setError('Forrás iroda, cél iroda, valuta, pozitív összeg és pozitív árfolyam kötelező.')
      return
    }

    try {
      setSubmitting(true)
      setError(null)
      await tradeApi.propose({
        fromBranchId: currentBranchId,
        toBranchId: toBranchId.trim(),
        currencyCode: currencyCode.trim().toUpperCase(),
        amount: parsedAmount,
        rate: parsedRate,
        notes: notes.trim() || undefined,
      })
      setToBranchId('')
      setAmount('')
      setNotes('')
      await loadTrades()
    } catch (err) {
      const message = getErrorMessage(err)
      setError(message)
      logger.error('TradePage', 'propose failed', err)
    } finally {
      setSubmitting(false)
    }
  }

  const runAction = async (action: () => Promise<TradeDto>) => {
    try {
      setSubmitting(true)
      setError(null)
      await action()
      await loadTrades()
    } catch (err) {
      const message = getErrorMessage(err)
      setError(message)
      logger.error('TradePage', 'action failed', err)
    } finally {
      setSubmitting(false)
    }
  }

  const renderTradeCard = (trade: TradeDto, actions = false) => (
    <div key={trade.id} className="rounded border border-gray-200 bg-white p-3">
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0">
          <div className="break-words text-sm font-semibold text-gray-900">
            {trade.fromBranchName} &rarr; {trade.toBranchName}
          </div>
          <div className="mt-1 font-mono text-xs text-gray-500">{trade.id}</div>
        </div>
        <span className="rounded bg-blue-50 px-2 py-1 text-xs font-semibold text-blue-700">
          {statusLabels[trade.status] ?? trade.status}
        </span>
      </div>
      <div className="mt-3 grid grid-cols-2 gap-2 text-sm">
        <div>
          <span className="text-xs text-gray-500">Valuta</span>
          <div className="font-semibold">{trade.currencyCode}</div>
        </div>
        <div>
          <span className="text-xs text-gray-500">Összeg</span>
          <div className="font-mono font-semibold">{formatNumber(trade.amount)}</div>
        </div>
        <div>
          <span className="text-xs text-gray-500">Árfolyam</span>
          <div className="font-mono">{formatNumber(trade.rate)}</div>
        </div>
        <div>
          <span className="text-xs text-gray-500">Ajánlat ideje</span>
          <div>{trade.proposedAt?.slice(0, 16).replace('T', ' ')}</div>
        </div>
      </div>
      {trade.notes && <p className="mt-2 break-words text-xs text-gray-600">{trade.notes}</p>}
      {actions && (
        <div className="mt-3 flex flex-wrap gap-2">
          {trade.status === 'PROPOSED' && (
            <>
              <button className="form-button h-8 text-xs" onClick={() => void runAction(() => tradeApi.accept(trade.id))} disabled={submitting}>
                <Check size={14} /> Elfogadás
              </button>
              <button className="form-button h-8 text-xs" onClick={() => void runAction(() => tradeApi.reject(trade.id, rejectReason))} disabled={submitting}>
                <CircleX size={14} /> Elutasítás
              </button>
              <button className="form-button h-8 text-xs" onClick={() => void runAction(() => tradeApi.cancel(trade.id))} disabled={submitting}>
                <Trash2 size={14} /> Törlés
              </button>
            </>
          )}
          {trade.status === 'ACCEPTED' && (
            <button className="form-button-primary h-8 text-xs" onClick={() => void runAction(() => tradeApi.complete(trade.id))} disabled={submitting}>
              <Check size={14} /> Teljesítés
            </button>
          )}
        </div>
      )}
    </div>
  )

  if (loading) {
    return (
      <div className="flex min-h-[240px] items-center justify-center">
        <Loader2 className="animate-spin text-gray-500" size={22} />
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold text-gray-900">Irodaközi trade</h1>
          <p className="text-sm text-gray-500">Deviza ajánlatok kezelése irodák között.</p>
        </div>
        <div className="flex gap-2">
          <span className="badge badge-blue">{pendingCount} nyitott</span>
          {acceptedCount > 0 && <span className="badge badge-green">{acceptedCount} teljesíthető</span>}
          <button className="form-button h-8 text-xs" onClick={() => void loadTrades()}>
            <RefreshCw size={14} />
          </button>
        </div>
      </div>

      {error && <div className="form-error break-words">{error}</div>}

      <section className="grid gap-3 lg:grid-cols-[minmax(0,1fr)_340px]">
        <div className="form-panel">
          <h2 className="mb-3 text-sm font-semibold text-gray-800">Nyitott ajánlatok</h2>
          <div className="grid gap-2">
            <input
              className="form-input"
              placeholder="Elutasítás oka"
              value={rejectReason}
              onChange={(event) => setRejectReason(event.target.value)}
            />
            {pending.length === 0 ? (
              <p className="rounded border border-gray-200 bg-gray-50 p-3 text-sm text-gray-500">Nincs nyitott trade.</p>
            ) : (
              pending.map((trade) => renderTradeCard(trade, true))
            )}
          </div>
        </div>

        <div className="form-panel">
          <h2 className="mb-3 text-sm font-semibold text-gray-800">Új ajánlat</h2>
          <div className="space-y-2">
            <div>
              <label className="form-label">Forrás iroda</label>
              <input className="form-input w-full" value={currentBranchId} disabled />
            </div>
            <div>
              <label className="form-label" htmlFor="trade-to-branch">Cél iroda UUID</label>
              <input id="trade-to-branch" className="form-input w-full" value={toBranchId} onChange={(event) => setToBranchId(event.target.value)} />
            </div>
            <div className="grid grid-cols-3 gap-2">
              <div>
                <label className="form-label" htmlFor="trade-currency">Valuta</label>
                <input id="trade-currency" className="form-input w-full uppercase" value={currencyCode} onChange={(event) => setCurrencyCode(event.target.value)} maxLength={3} />
              </div>
              <div>
                <label className="form-label" htmlFor="trade-amount">Összeg</label>
                <input id="trade-amount" className="form-input w-full" type="number" min="0.01" step="0.01" value={amount} onChange={(event) => setAmount(event.target.value)} />
              </div>
              <div>
                <label className="form-label" htmlFor="trade-rate">Árfolyam</label>
                <input id="trade-rate" className="form-input w-full" type="number" min="0.0001" step="0.0001" value={rate} onChange={(event) => setRate(event.target.value)} />
              </div>
            </div>
            <div>
              <label className="form-label" htmlFor="trade-notes">Megjegyzés</label>
              <textarea id="trade-notes" className="form-input min-h-20 w-full" value={notes} onChange={(event) => setNotes(event.target.value)} />
            </div>
            <button className="form-button-primary inline-flex min-h-10 w-full items-center justify-center gap-2" onClick={() => void proposeTrade()} disabled={submitting}>
              {submitting ? <Loader2 className="animate-spin" size={16} /> : <Plus size={16} />}
              Ajánlat létrehozása
            </button>
          </div>
        </div>
      </section>

      <section className="form-panel">
        <div className="mb-3 flex flex-wrap items-end justify-between gap-3">
          <div>
            <h2 className="text-sm font-semibold text-gray-800">Trade történet</h2>
            <p className="text-xs text-gray-500">{historyTotal} találat</p>
          </div>
          <div className="flex flex-wrap gap-2">
            <input aria-label="Történet dátumtól" className="form-input h-8 text-xs" type="date" value={from} onChange={(event) => setFrom(event.target.value)} />
            <input aria-label="Történet dátumig" className="form-input h-8 text-xs" type="date" value={to} onChange={(event) => setTo(event.target.value)} />
            <button className="form-button h-8 text-xs" onClick={() => void loadTrades()}>
              <Send size={14} /> Lekérés
            </button>
          </div>
        </div>
        <div className="grid gap-2 md:grid-cols-2">
          {history.length === 0 ? (
            <p className="rounded border border-gray-200 bg-gray-50 p-3 text-sm text-gray-500">Nincs történeti trade.</p>
          ) : (
            history.map((trade) => renderTradeCard(trade))
          )}
        </div>
      </section>
    </div>
  )
}
