/**
 * FK-071 FR-4 — Tranzakció read-only nézet (👁 "Megtekintés").
 *
 * A /transactions/:id route-on az adott tranzakció TÉNYLEGES adatai jelennek meg
 * (bizonylatszám, típus, deviza, összeg, árfolyam, dátum, HUF-összeg, ügyfél) —
 * szerkesztési és mentési lehetőség nélkül. Korábban ez a route az üres, új
 * tranzakció felviteli űrlapot nyitotta, mert a TransactionPage nem olvasta a
 * :id paramétert.
 */
import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, Eye, Loader2 } from 'lucide-react'
import { transactionApi } from '../../services/api/index'
import type { Transaction } from '../../services/api/index'
import { isElectron } from '../../utils/electron'
import i18n from '../../i18n'

function formatNumber(n: number | null | undefined, decimals = 2): string {
  if (n === null || n === undefined) return '—'
  return n.toLocaleString('hu-HU', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  })
}

function typeLabel(transactionType: Transaction['transactionType']): string {
  switch (transactionType) {
    case 'BUY':
      return 'Vétel'
    case 'SELL':
      return 'Eladás'
    case 'REVERSAL':
      return 'Sztornó'
    case 'TRANSFER_OUT':
      return 'Átadás'
    case 'TRANSFER_IN':
      return 'Átvétel'
    default:
      return 'Átváltás'
  }
}

function statusLabel(status: Transaction['status']): string {
  // FK-071 Döntés 2 + kiegészítés, a Tranzakciólistával összhangban: a
  // "Feltöltve" csak Electron/offline kontextusban jelenik meg, web-módban a
  // COMPLETED felirata "Teljesítve" marad.
  if (status === 'COMPLETED') return isElectron() ? 'Feltöltve' : 'Teljesítve'
  if (status === 'REVERSED') return 'Sztornózva'
  return 'Szinkronra vár'
}

function DetailRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between gap-4 border-b border-gray-100 py-1.5 text-sm">
      <span className="text-gray-500">{label}</span>
      <span className="font-mono font-semibold text-gray-800">{value}</span>
    </div>
  )
}

export default function TransactionReadOnlyView({ transactionId }: { transactionId: string }) {
  const navigate = useNavigate()
  const [transaction, setTransaction] = useState<Transaction | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    // FK-071 Bugbot#3: transactionId-váltásnál a KORÁBBI tranzakció adatai nem
    // maradhatnak láthatók — sem a betöltés alatt, sem az új lekérés hibájakor
    // (első betöltésnél a state amúgy is null, ott nincs viselkedés-változás).
    setTransaction(null)
    setLoading(true)
    setError(null)
    transactionApi
      .getById(transactionId)
      .then((tx) => {
        if (!cancelled) setTransaction(tx)
      })
      .catch((err: unknown) => {
        if (!cancelled) {
          setError(
            err instanceof Error ? err.message : 'Nem sikerült betölteni a tranzakció adatait',
          )
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [transactionId])

  return (
    <div className="mx-auto max-w-xl space-y-3">
      <div className="flex items-center justify-between">
        <h1 className="flex items-center gap-2 text-xl font-bold text-gray-800">
          <Eye />
          {i18n.t('literals.tranzakcio-megtekintese')}
        </h1>
        <button
          className="form-button flex items-center gap-1"
          onClick={() => navigate('/transactions')}
          data-testid="tx-view-back"
        >
          <ArrowLeft size={16} />
          {i18n.t('literals.vissza-a-listahoz')}
        </button>
      </div>

      {loading && (
        <div className="form-panel flex items-center justify-center py-8">
          <Loader2 className="animate-spin text-gray-400" size={32} />
        </div>
      )}

      {error && (
        <div className="form-panel border-red-200 bg-red-50 text-sm text-red-700">{error}</div>
      )}

      {transaction && (
        <div className="form-panel" data-testid="tx-view-panel">
          <DetailRow label="Bizonylatszám" value={transaction.receiptNumber || '—'} />
          <DetailRow label="Típus" value={typeLabel(transaction.transactionType)} />
          <DetailRow
            label="Dátum"
            value={`${transaction.transactionDate}${
              transaction.transactionTime ? ` ${transaction.transactionTime.substring(0, 5)}` : ''
            }`}
          />
          <DetailRow label="Deviza" value={transaction.currencyCode} />
          <DetailRow label="Deviza összeg" value={formatNumber(transaction.currencyAmount)} />
          <DetailRow label="Árfolyam" value={formatNumber(transaction.exchangeRate, 4)} />
          <DetailRow
            label="HUF összeg"
            value={`${formatNumber(transaction.roundedHufAmount ?? transaction.hufAmount, 0)} Ft`}
          />
          <DetailRow label="Ügyfél" value={transaction.customerName || '—'} />
          <DetailRow label="Státusz" value={statusLabel(transaction.status)} />
        </div>
      )}
    </div>
  )
}
