/**
 * E-B8 Banki rendelés workflow oldal — v2.5.31 működő implementáció.
 *
 * Backend: BankOrderController (`/api/v1/bank-orders`) — V187 migráció.
 * GitHub issue: https://github.com/kosazoltan/valutavalto-program/issues/279
 *
 * Workflow: PENDING → APPROVED (ügyvezető) → EXECUTED (értéktár), vagy CANCELLED.
 */

import { useEffect, useState } from 'react'
import { Building2, Plus, RefreshCw } from 'lucide-react'
import {
  bankOrdersApi,
  BankOrder,
  BankOrderStatus,
} from '../../services/api/bankOrders'
import { logger } from '../../utils/logger'

const STATUS_LABELS: Record<BankOrderStatus, string> = {
  PENDING: 'Függőben',
  APPROVED: 'Jóváhagyva',
  EXECUTED: 'Teljesítve',
  CANCELLED: 'Visszavonva',
}

const STATUS_COLORS: Record<BankOrderStatus, string> = {
  PENDING: 'bg-yellow-100 text-yellow-800',
  APPROVED: 'bg-blue-100 text-blue-800',
  EXECUTED: 'bg-green-100 text-green-800',
  CANCELLED: 'bg-gray-100 text-gray-700',
}

export default function BankOrderPage() {
  const [orders, setOrders] = useState<BankOrder[]>([])
  const [statusFilter, setStatusFilter] = useState<BankOrderStatus | ''>('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [actionInProgress, setActionInProgress] = useState<string | null>(null)

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const result = await bankOrdersApi.list(statusFilter || undefined, 0, 100)
      setOrders(result.content)
    } catch (err) {
      logger.error('BankOrderPage', 'Lista hiba:', err)
      setError(err instanceof Error ? err.message : 'Ismeretlen hiba')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter])

  const handleApprove = async (id: string) => {
    if (!confirm('Biztosan jóváhagyja ezt a banki rendelést?')) return
    setActionInProgress(id)
    try {
      await bankOrdersApi.approve(id)
      await load()
    } catch (err) {
      alert('Hiba a jóváhagyásnál: ' + (err instanceof Error ? err.message : ''))
    } finally {
      setActionInProgress(null)
    }
  }

  const handleExecute = async (id: string) => {
    const ref = prompt('Bank hivatkozási szám (opcionális):')
    if (ref === null) return
    setActionInProgress(id)
    try {
      await bankOrdersApi.execute(id, ref || undefined)
      await load()
    } catch (err) {
      alert('Hiba a teljesítésnél: ' + (err instanceof Error ? err.message : ''))
    } finally {
      setActionInProgress(null)
    }
  }

  const handleCancel = async (id: string) => {
    const reason = prompt('Visszavonás indoklása:')
    if (!reason) return
    setActionInProgress(id)
    try {
      await bankOrdersApi.cancel(id, reason)
      await load()
    } catch (err) {
      alert('Hiba a visszavonásnál: ' + (err instanceof Error ? err.message : ''))
    } finally {
      setActionInProgress(null)
    }
  }

  return (
    <div className="space-y-4 p-4">
      <div className="flex items-center gap-2">
        <Building2 className="h-6 w-6 text-blue-600" />
        <h1 className="text-xl font-bold text-gray-800">Banki rendelések</h1>
      </div>

      <div className="flex items-center gap-3">
        <label className="text-sm font-semibold">Státusz szűrő:</label>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value as BankOrderStatus | '')}
          className="rounded border px-2 py-1 text-sm"
        >
          <option value="">Mind</option>
          <option value="PENDING">Függőben</option>
          <option value="APPROVED">Jóváhagyva</option>
          <option value="EXECUTED">Teljesítve</option>
          <option value="CANCELLED">Visszavonva</option>
        </select>
        <button
          onClick={() => void load()}
          className="flex items-center gap-1 rounded border px-3 py-1 text-sm hover:bg-gray-50"
        >
          <RefreshCw className="h-4 w-4" />
          Frissít
        </button>
        <button
          disabled
          title="Új rendelés (V2.6.0-ban érkezik teljes UI)"
          className="ml-auto flex items-center gap-1 rounded bg-blue-600 px-3 py-1 text-sm text-white opacity-50"
        >
          <Plus className="h-4 w-4" />
          Új rendelés
        </button>
      </div>

      {error && (
        <div className="rounded border border-red-300 bg-red-50 p-3 text-sm text-red-800">
          Hiba: {error}
        </div>
      )}

      {loading && <div className="text-sm text-gray-500">Betöltés…</div>}

      {!loading && orders.length === 0 && (
        <div className="rounded border border-gray-200 bg-gray-50 p-6 text-center text-sm text-gray-600">
          Nincs banki rendelés a kiválasztott szűrővel.
        </div>
      )}

      {!loading && orders.length > 0 && (
        <div className="overflow-x-auto rounded border border-gray-200">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-left">
              <tr>
                <th className="p-2">Idő</th>
                <th className="p-2">Iroda</th>
                <th className="p-2">Valuta</th>
                <th className="p-2 text-right">Összeg</th>
                <th className="p-2">Sürgősség</th>
                <th className="p-2">Státusz</th>
                <th className="p-2">Kérte</th>
                <th className="p-2">Jóváhagyta</th>
                <th className="p-2"></th>
              </tr>
            </thead>
            <tbody>
              {orders.map((o) => (
                <tr key={o.id} className="border-t hover:bg-gray-50">
                  <td className="p-2 whitespace-nowrap">
                    {new Date(o.requestedAt).toLocaleString('hu-HU')}
                  </td>
                  <td className="p-2">{o.branchCode}</td>
                  <td className="p-2 font-mono">{o.currencyCode}</td>
                  <td className="p-2 text-right font-mono">
                    {Number(o.amount).toLocaleString('hu-HU')}
                  </td>
                  <td className="p-2">{o.urgency}</td>
                  <td className="p-2">
                    <span className={`rounded px-2 py-0.5 text-xs font-semibold ${STATUS_COLORS[o.status]}`}>
                      {STATUS_LABELS[o.status]}
                    </span>
                  </td>
                  <td className="p-2 text-xs">{o.requestedByWorkerName ?? '-'}</td>
                  <td className="p-2 text-xs">{o.approvedByWorkerName ?? '-'}</td>
                  <td className="p-2 space-x-1 whitespace-nowrap">
                    {o.status === 'PENDING' && (
                      <>
                        <button
                          disabled={actionInProgress === o.id}
                          onClick={() => void handleApprove(o.id)}
                          className="rounded bg-blue-600 px-2 py-0.5 text-xs text-white hover:bg-blue-700 disabled:opacity-50"
                        >
                          Jóváhagy
                        </button>
                        <button
                          disabled={actionInProgress === o.id}
                          onClick={() => void handleCancel(o.id)}
                          className="rounded bg-gray-200 px-2 py-0.5 text-xs hover:bg-gray-300 disabled:opacity-50"
                        >
                          Visszavon
                        </button>
                      </>
                    )}
                    {o.status === 'APPROVED' && (
                      <>
                        <button
                          disabled={actionInProgress === o.id}
                          onClick={() => void handleExecute(o.id)}
                          className="rounded bg-green-600 px-2 py-0.5 text-xs text-white hover:bg-green-700 disabled:opacity-50"
                        >
                          Teljesít
                        </button>
                        <button
                          disabled={actionInProgress === o.id}
                          onClick={() => void handleCancel(o.id)}
                          className="rounded bg-gray-200 px-2 py-0.5 text-xs hover:bg-gray-300 disabled:opacity-50"
                        >
                          Visszavon
                        </button>
                      </>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <p className="text-xs text-gray-500">
        Az új-rendelés űrlap és a Western Union napi keret modul a v2.6.0-ban érkezik
        (issue <a className="underline" href="https://github.com/kosazoltan/valutavalto-program/issues/279" target="_blank" rel="noopener noreferrer">#279</a>).
      </p>
    </div>
  )
}
