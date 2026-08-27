import { useCallback, useEffect, useMemo, useState } from 'react'
import { Check, CircleX, Loader2, Plus, RefreshCw, Send, Trash2 } from 'lucide-react'
import { branchApi, type BranchInfo } from '../../services/api'
import { tradeApi, type TradeDto } from '../../services/api/trades'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import i18n from '../../i18n'

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
  const [targetBranches, setTargetBranches] = useState<BranchInfo[]>([])
  const [targetLoading, setTargetLoading] = useState(true)
  const [targetError, setTargetError] = useState<string | null>(null)
  const [currencyCode, setCurrencyCode] = useState('EUR')
  const [amount, setAmount] = useState('')
  const [rate, setRate] = useState('1')
  const [notes, setNotes] = useState('')
  const [rejectReason, setRejectReason] = useState('')
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const pendingCount = pending.length
  const acceptedCount = useMemo(
    () => pending.filter((trade) => trade.status === 'ACCEPTED').length,
    [pending],
  )
  const sourceBranchLabel = worker?.branchName || currentBranchId
  const canCreateTrade =
    !submitting &&
    !targetLoading &&
    !targetError &&
    targetBranches.length > 0 &&
    Boolean(toBranchId)

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

  const loadTargetBranches = useCallback(async () => {
    try {
      setTargetLoading(true)
      setTargetError(null)
      const response = await branchApi.listVaultCounterparties()
      const flattened = [
        ...(response.territorialCashiers ?? []),
        ...(response.peerVaults ?? []),
        ...(response.fixedCounterparties ?? []),
      ].filter((branch) => branch.id && branch.id !== currentBranchId)
      setTargetBranches(flattened)
    } catch (err) {
      const message = getErrorMessage(err)
      setTargetError(message)
      setTargetBranches([])
      logger.error('TradePage', 'target branches load failed', err)
    } finally {
      setTargetLoading(false)
    }
  }, [currentBranchId])

  useEffect(() => {
    void loadTargetBranches()
  }, [loadTargetBranches])

  const proposeTrade = async () => {
    const parsedAmount = Number(amount)
    const parsedRate = Number(rate)
    if (
      !currentBranchId ||
      !toBranchId.trim() ||
      targetError ||
      !currencyCode.trim() ||
      parsedAmount <= 0 ||
      parsedRate <= 0
    ) {
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
            {trade.fromBranchName}
            {i18n.t('literals.lit-56')}
            {trade.toBranchName}
          </div>
          <div className="mt-1 font-mono text-xs text-gray-500">{trade.id}</div>
        </div>
        <span className="rounded bg-blue-50 px-2 py-1 text-xs font-semibold text-blue-700">
          {statusLabels[trade.status] ?? trade.status}
        </span>
      </div>
      <div className="mt-3 grid grid-cols-2 gap-2 text-sm">
        <div>
          <span className="text-xs text-gray-500">{i18n.t('literals.valuta')}</span>
          <div className="font-semibold">{trade.currencyCode}</div>
        </div>
        <div>
          <span className="text-xs text-gray-500">{i18n.t('literals.osszeg')}</span>
          <div className="font-mono font-semibold">{formatNumber(trade.amount)}</div>
        </div>
        <div>
          <span className="text-xs text-gray-500">{i18n.t('literals.arfolyam')}</span>
          <div className="font-mono">{formatNumber(trade.rate)}</div>
        </div>
        <div>
          <span className="text-xs text-gray-500">{i18n.t('literals.ajanlat-ideje')}</span>
          <div>{trade.proposedAt?.slice(0, 16).replace('T', ' ')}</div>
        </div>
      </div>
      {trade.notes && <p className="mt-2 break-words text-xs text-gray-600">{trade.notes}</p>}
      {actions && (
        <div className="mt-3 flex flex-wrap gap-2">
          {trade.status === 'PROPOSED' && (
            <>
              <button
                className="form-button h-8 text-xs"
                onClick={() => void runAction(() => tradeApi.accept(trade.id))}
                disabled={submitting}
              >
                <Check size={14} />
                {i18n.t('literals.elfogadas')}
              </button>
              <button
                className="form-button h-8 text-xs"
                onClick={() => void runAction(() => tradeApi.reject(trade.id, rejectReason))}
                disabled={submitting}
              >
                <CircleX size={14} />
                {i18n.t('literals.elutasitas-2')}
              </button>
              <button
                className="form-button h-8 text-xs"
                onClick={() => void runAction(() => tradeApi.cancel(trade.id))}
                disabled={submitting}
              >
                <Trash2 size={14} />
                {i18n.t('literals.torles-2')}
              </button>
            </>
          )}
          {trade.status === 'ACCEPTED' && (
            <button
              className="form-button-primary h-8 text-xs"
              onClick={() => void runAction(() => tradeApi.complete(trade.id))}
              disabled={submitting}
            >
              <Check size={14} />
              {i18n.t('literals.teljesites')}
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
          <h1 className="text-xl font-bold text-gray-900">{i18n.t('literals.irodakozi-trade')}</h1>
          <p className="text-sm text-gray-500">
            {i18n.t('literals.deviza-ajanlatok-kezelese-irodak-kozott')}
          </p>
        </div>
        <div className="flex gap-2">
          <span className="badge badge-blue">
            {pendingCount}
            {i18n.t('literals.nyitott-2')}
          </span>
          {acceptedCount > 0 && (
            <span className="badge badge-green">
              {acceptedCount}
              {i18n.t('literals.teljesitheto')}
            </span>
          )}
          <button className="form-button h-8 text-xs" onClick={() => void loadTrades()}>
            <RefreshCw size={14} />
          </button>
        </div>
      </div>

      {error && <div className="form-error break-words">{error}</div>}

      <section className="grid gap-3 lg:grid-cols-[minmax(0,1fr)_340px]">
        <div className="form-panel">
          <h2 className="mb-3 text-sm font-semibold text-gray-800">
            {i18n.t('literals.nyitott-ajanlatok')}
          </h2>
          <div className="grid gap-2">
            <input
              className="form-input"
              placeholder="Elutasítás oka"
              value={rejectReason}
              onChange={(event) => setRejectReason(event.target.value)}
            />
            {pending.length === 0 ? (
              <p className="rounded border border-gray-200 bg-gray-50 p-3 text-sm text-gray-500">
                {i18n.t('literals.nincs-nyitott-trade')}
              </p>
            ) : (
              pending.map((trade) => renderTradeCard(trade, true))
            )}
          </div>
        </div>

        <div className="form-panel">
          <h2 className="mb-3 text-sm font-semibold text-gray-800">
            {i18n.t('literals.uj-ajanlat')}
          </h2>
          <div className="space-y-2">
            <div>
              <label className="form-label">{i18n.t('literals.forras-iroda')}</label>
              <input className="form-input w-full" value={sourceBranchLabel} disabled />
            </div>
            <div>
              <label className="form-label" htmlFor="trade-to-branch">
                {i18n.t('literals.cel-iroda')}
              </label>
              <select
                id="trade-to-branch"
                className="form-input w-full"
                value={toBranchId}
                onChange={(event) => setToBranchId(event.target.value)}
                disabled={targetLoading || Boolean(targetError) || targetBranches.length === 0}
              >
                <option value="">
                  {targetLoading ? 'Irodák betöltése...' : 'Válassz cél irodát'}
                </option>
                {targetBranches.map((branch) => (
                  <option key={branch.id} value={branch.id}>
                    {branch.code ? `${branch.code} - ${branch.name}` : branch.name}
                  </option>
                ))}
              </select>
              {targetError && (
                <p className="mt-1 text-xs text-red-600">
                  {i18n.t('literals.cel-irodak-betoltese-sikertelen')}
                  {targetError}
                </p>
              )}
              {!targetLoading && !targetError && targetBranches.length === 0 && (
                <p className="mt-1 text-xs text-amber-700">
                  {i18n.t('literals.nincs-valaszthato-cel-iroda')}
                </p>
              )}
            </div>
            <div className="grid grid-cols-3 gap-2">
              <div>
                <label className="form-label" htmlFor="trade-currency">
                  {i18n.t('literals.valuta')}
                </label>
                <input
                  id="trade-currency"
                  className="form-input w-full uppercase"
                  value={currencyCode}
                  onChange={(event) => setCurrencyCode(event.target.value)}
                  maxLength={3}
                />
              </div>
              <div>
                <label className="form-label" htmlFor="trade-amount">
                  {i18n.t('literals.osszeg')}
                </label>
                <input
                  id="trade-amount"
                  className="form-input w-full"
                  type="number"
                  min="0.01"
                  step="0.01"
                  value={amount}
                  onChange={(event) => setAmount(event.target.value)}
                />
              </div>
              <div>
                <label className="form-label" htmlFor="trade-rate">
                  {i18n.t('literals.arfolyam')}
                </label>
                <input
                  id="trade-rate"
                  className="form-input w-full"
                  type="number"
                  min="0.0001"
                  step="0.0001"
                  value={rate}
                  onChange={(event) => setRate(event.target.value)}
                />
              </div>
            </div>
            <div>
              <label className="form-label" htmlFor="trade-notes">
                {i18n.t('literals.megjegyzes')}
              </label>
              <textarea
                id="trade-notes"
                className="form-input min-h-20 w-full"
                value={notes}
                onChange={(event) => setNotes(event.target.value)}
              />
            </div>
            <button
              className="form-button-primary inline-flex min-h-10 w-full items-center justify-center gap-2"
              onClick={() => void proposeTrade()}
              disabled={!canCreateTrade}
            >
              {submitting ? <Loader2 className="animate-spin" size={16} /> : <Plus size={16} />}
              {i18n.t('literals.ajanlat-letrehozasa')}
            </button>
          </div>
        </div>
      </section>

      <section className="form-panel">
        <div className="mb-3 flex flex-wrap items-end justify-between gap-3">
          <div>
            <h2 className="text-sm font-semibold text-gray-800">
              {i18n.t('literals.trade-tortenet')}
            </h2>
            <p className="text-xs text-gray-500">
              {historyTotal}
              {i18n.t('literals.talalat-2')}
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            <input
              aria-label="Történet dátumtól"
              className="form-input h-8 text-xs"
              type="date"
              value={from}
              onChange={(event) => setFrom(event.target.value)}
            />
            <input
              aria-label="Történet dátumig"
              className="form-input h-8 text-xs"
              type="date"
              value={to}
              onChange={(event) => setTo(event.target.value)}
            />
            <button className="form-button h-8 text-xs" onClick={() => void loadTrades()}>
              <Send size={14} />
              {i18n.t('literals.lekeres')}
            </button>
          </div>
        </div>
        <div className="grid gap-2 md:grid-cols-2">
          {history.length === 0 ? (
            <p className="rounded border border-gray-200 bg-gray-50 p-3 text-sm text-gray-500">
              {i18n.t('literals.nincs-torteneti-trade')}
            </p>
          ) : (
            history.map((trade) => renderTradeCard(trade))
          )}
        </div>
      </section>
    </div>
  )
}
