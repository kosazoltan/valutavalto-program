import { useState, useCallback } from 'react'
import { Scale, RefreshCw, CheckCircle2, AlertTriangle } from 'lucide-react'
import { territoryReconciliationApi, type TerritoryReconciliation } from '../../services/api/territoryReconciliation'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'

const fmt = (n: number) => (n ?? 0).toLocaleString('hu-HU', { maximumFractionDigits: 0 }) + ' Ft'

/**
 * Területi reconciliation + értéktári átértékelés lecsorgatása a pénztárakra.
 * terület MNB-összhaszon = Σ(pénztár tiszta WAC-marzs) + Σ(allokált átértékelés).
 */
export default function TerritoryReconciliationPage() {
  const [territoryId, setTerritoryId] = useState('20')
  const [yearMonth, setYearMonth] = useState(new Date().toISOString().slice(0, 7))
  const [data, setData] = useState<TerritoryReconciliation | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    const tid = parseInt(territoryId, 10)
    if (Number.isNaN(tid)) { setError('Adj meg érvényes terület-azonosítót.'); return }
    try {
      setLoading(true); setError(null)
      setData(await territoryReconciliationApi.get(tid, yearMonth))
    } catch (err) {
      setError(getErrorMessage(err)); logger.error('TerritoryReconciliationPage', 'load', err)
    } finally {
      setLoading(false)
    }
  }, [territoryId, yearMonth])

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2"><Scale className="h-6 w-6" /> Területi reconciliation (értéktári átértékelés lecsorgatás)</h1>
      </div>

      <div className="flex items-end gap-2">
        <div>
          <label className="form-label">Terület (vaultTerritoryId)</label>
          <input className="form-input w-40" value={territoryId} onChange={e => setTerritoryId(e.target.value)} />
        </div>
        <div>
          <label className="form-label">Hónap</label>
          <input type="month" className="form-input w-44" value={yearMonth} onChange={e => setYearMonth(e.target.value)} />
        </div>
        <button onClick={() => void load()} disabled={loading} className="form-button-primary flex items-center gap-1">
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} /> Lekérdez
        </button>
      </div>

      {error && <div className="form-error flex items-center gap-2"><AlertTriangle className="h-4 w-4" />{error}</div>}

      {data && (
        <div className="space-y-4">
          <div className="grid grid-cols-3 gap-3">
            <div className="rounded border border-slate-200 p-3">
              <div className="text-xs text-slate-500">Σ pénztári WAC-marzs</div>
              <div className="text-lg font-bold">{fmt(data.territoryRealizedMargin)}</div>
            </div>
            <div className="rounded border border-slate-200 p-3">
              <div className="text-xs text-slate-500">Értéktári átértékelés (MNB − WAC)</div>
              <div className={`text-lg font-bold ${data.territoryRevaluation < 0 ? 'text-red-600' : 'text-green-700'}`}>{fmt(data.territoryRevaluation)}</div>
            </div>
            <div className="rounded border border-slate-200 p-3">
              <div className="text-xs text-slate-500">Terület MNB-összhaszon</div>
              <div className="text-lg font-bold">{fmt(data.territoryTotalProfit)}</div>
            </div>
          </div>

          <div className={`flex items-center gap-2 text-sm ${data.reconciliationOk ? 'text-green-700' : 'text-red-600'}`}>
            {data.reconciliationOk ? <CheckCircle2 className="h-4 w-4" /> : <AlertTriangle className="h-4 w-4" />}
            {data.reconciliationOk ? 'Reconciliation OK: Σ pénztár összhaszon = terület összhaszon' : 'Reconciliation eltérés!'}
          </div>

          <div className="data-grid overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50"><tr>
                <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Pénztár</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">Tiszta WAC-marzs</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">Allokált átértékelés</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">Összhaszon</th>
              </tr></thead>
              <tbody className="divide-y divide-gray-100">
                {data.cashiers.map(c => (
                  <tr key={c.branchId}>
                    <td className="px-3 py-2 text-sm">{c.branchCode} — {c.branchName}</td>
                    <td className="px-3 py-2 text-sm text-right font-mono">{fmt(c.realizedMargin)}</td>
                    <td className={`px-3 py-2 text-sm text-right font-mono ${c.allocatedRevaluation < 0 ? 'text-red-600' : ''}`}>{fmt(c.allocatedRevaluation)}</td>
                    <td className="px-3 py-2 text-sm text-right font-mono font-bold">{fmt(c.totalProfit)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {data.currencyRevaluations.length > 0 && (
            <div className="data-grid overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50"><tr>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">Valuta</th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">Értéktári készlet</th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">WAC</th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">MNB</th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">Átértékelés</th>
                </tr></thead>
                <tbody className="divide-y divide-gray-100">
                  {data.currencyRevaluations.map(r => (
                    <tr key={r.currencyCode}>
                      <td className="px-3 py-2 text-sm font-mono">{r.currencyCode}</td>
                      <td className="px-3 py-2 text-sm text-right font-mono">{(r.vaultHeldQty ?? 0).toLocaleString('hu-HU')}</td>
                      <td className="px-3 py-2 text-sm text-right font-mono">{r.weightedAvgCost}</td>
                      <td className="px-3 py-2 text-sm text-right font-mono">{r.mnbRate}</td>
                      <td className={`px-3 py-2 text-sm text-right font-mono ${r.revaluation < 0 ? 'text-red-600' : 'text-green-700'}`}>{fmt(r.revaluation)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
