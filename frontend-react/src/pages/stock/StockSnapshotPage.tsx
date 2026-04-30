import { useState, useEffect, useCallback } from 'react'
import { Camera, RefreshCw, AlertTriangle, Download } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'

/**
 * StockSnapshotDto shape (backend dto/stocksnapshot/*):
 *   { snapshotTime, companyId, companyName,
 *     regions: [RegionSnapshotDto],
 *     companyTotals: BranchStockTotalsDto }
 *
 * RegionSnapshotDto: { regionCode, regionName, branches: [BranchSnapshotDto], totals }
 * BranchSnapshotDto: { branchId, branchName, branchCode, lastUpdated,
 *                      currencies: [CurrencyStockDetailDto],
 *                      wuBalance, reservations }
 * BranchStockTotalsDto: { currencies, wuBalance, reservations }
 * CurrencyStockDetailDto: { currencyCode, amount, stockHuf, ... }
 *
 * Fix #148 re-verify: a korabbi feltetelezes (totals.totalValueHuf) rossz volt.
 * A totals valojaban currencies LIST-et tartalmaz, az aggregalt HUF érték
 * a currencies[].stockHuf osszege.
 */
interface CurrencyStockDetail {
  currencyCode?: string
  stock?: number | string
  amount?: number | string
  stockHuf?: number | string
}
interface BranchStockTotals {
  currencies?: CurrencyStockDetail[]
}
interface BranchSnapshot {
  branchId?: string
  branchName?: string
  branchCode?: string
  lastUpdated?: string
  currencies?: CurrencyStockDetail[]
}
interface RegionSnapshot {
  regionCode?: string
  regionName?: string
  branches?: BranchSnapshot[]
  totals?: BranchStockTotals
}
interface StockSnapshot {
  snapshotTime?: string
  companyId?: string
  companyName?: string
  regions?: RegionSnapshot[]
  companyTotals?: BranchStockTotals
}

function sumHuf(currencies: CurrencyStockDetail[] | undefined): number {
  if (!currencies) return 0
  return currencies.reduce((sum, c) => {
    const v = typeof c.stockHuf === 'string' ? Number(c.stockHuf) : (c.stockHuf ?? 0)
    return sum + (Number.isNaN(v) ? 0 : v)
  }, 0)
}

function formatHuf(v: number | string | undefined): string {
  if (v == null) return '-'
  const n = typeof v === 'string' ? Number(v) : v
  if (Number.isNaN(n)) return String(v)
  return n.toLocaleString('hu-HU') + ' Ft'
}

export default function StockSnapshotPage() {
  const { t } = useTranslation()
  const [snapshot, setSnapshot] = useState<StockSnapshot | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true); setError(null)
      const response = await api.get<StockSnapshot>('/stock-snapshot')
      setSnapshot(response.data ?? null)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('StockSnapshotPage', 'Betöltési hiba:', err)
      setError(msg); setSnapshot(null)
    } finally { setLoading(false) }
  }, [])

  useEffect(() => { void loadData() }, [loadData])

  async function downloadExcel() {
    try {
      setError(null)
      const r = await api.get('/stock-snapshot/excel', { responseType: 'blob' })
      const blob = new Blob([r.data as BlobPart], {
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url; a.download = 'keszlet-export-' + new Date().toISOString().slice(0, 10) + '.xlsx'
      document.body.appendChild(a); a.click(); a.remove()
      URL.revokeObjectURL(url)
    } catch (err) {
      logger.error('StockSnapshotPage', 'Excel letöltés hiba:', err)
      setError(getErrorMessage(err))
    }
  }

  const companyTotal = snapshot?.companyTotals ? sumHuf(snapshot.companyTotals.currencies) : 0
  const hasCompanyTotalsFallback =
    (snapshot?.regions?.length ?? 0) === 0 &&
    (snapshot?.companyTotals?.currencies?.length ?? 0) > 0

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Camera className="h-6 w-6" />
          {t('stockSnapshot.title')}
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title={t('common.refresh')}>
            <RefreshCw className={loading ? 'h-4 w-4 animate-spin' : 'h-4 w-4'} />
          </button>
          <button onClick={() => void downloadExcel()} className="form-button-primary flex items-center gap-2">
            <Download className="h-4 w-4" /> {t('common.exportExcel')}
          </button>
        </div>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {loading ? (
        <div className="text-center text-sm text-gray-500 py-8">{t('common.loading')}</div>
      ) : !snapshot ? (
        <div className="text-center text-sm text-gray-500 py-8">{t('common.noData')}</div>
      ) : (
        <div className="space-y-4">
          <div className="bg-white rounded shadow p-4 grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
            <div><span className="text-gray-500">{t('stockSnapshot.company')}:</span> <b>{snapshot.companyName ?? '-'}</b></div>
            <div><span className="text-gray-500">{t('stockSnapshot.snapshotTime')}:</span> {snapshot.snapshotTime ? new Date(snapshot.snapshotTime).toLocaleString('hu-HU') : '-'}</div>
            <div><span className="text-gray-500">{t('stockSnapshot.totalHuf')}:</span> <b className="font-mono">{formatHuf(companyTotal)}</b></div>
          </div>

          {(snapshot.regions ?? []).map((region, ri) => {
            const regionTotal = sumHuf(region.totals?.currencies)
            return (
              <div key={(region.regionCode ?? 'r') + ri} className="bg-white rounded shadow">
                <div className="bg-gray-50 px-4 py-2 border-b">
                  <h2 className="font-semibold">{region.regionName ?? region.regionCode ?? t('stockSnapshot.regionFallback')}</h2>
                  <div className="text-xs text-gray-500">
                    {t('stockSnapshot.regionTotal')}: {formatHuf(regionTotal)} / {t('stockSnapshot.regionBranchCount', { count: region.branches?.length ?? 0 })}
                  </div>
                </div>
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('stockSnapshot.branchHeader')}</th>
                      <th className="px-4 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('stockSnapshot.lastUpdated')}</th>
                      <th className="px-4 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('stockSnapshot.hufValue')}</th>
                      <th className="px-4 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('stockSnapshot.currencies')}</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {(region.branches ?? []).map((b) => {
                      const branchTotal = sumHuf(b.currencies)
                      return (
                        <tr key={b.branchId} className="hover:bg-gray-50">
                          <td className="px-4 py-2 text-sm">{b.branchName ?? b.branchCode ?? '-'}</td>
                          <td className="px-4 py-2 text-sm">{b.lastUpdated ? new Date(b.lastUpdated).toLocaleString('hu-HU') : '-'}</td>
                          <td className="px-4 py-2 text-right text-sm font-mono">{formatHuf(branchTotal)}</td>
                          <td className="px-4 py-2 text-right text-sm">{b.currencies?.length ?? 0}</td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            )
          })}

          {/* Fallback: ha nincs regio besorolas, companyTotals.currencies tabla */}
          {hasCompanyTotalsFallback && (
            <div className="bg-white rounded shadow">
              <div className="bg-gray-50 px-4 py-2 border-b">
                <h2 className="font-semibold">{t('stockSnapshot.fallbackTitle')}</h2>
                <div className="text-xs text-gray-500">{t('stockSnapshot.fallbackCount', { count: snapshot.companyTotals?.currencies?.length ?? 0 })}</div>
              </div>
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('stockSnapshot.currencyHeader')}</th>
                    <th className="px-4 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('stockSnapshot.stockHeader')}</th>
                    <th className="px-4 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('stockSnapshot.hufValue')}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {(snapshot.companyTotals?.currencies ?? []).map((c, i) => (
                    <tr key={(c.currencyCode ?? "") + i} className="hover:bg-gray-50">
                      <td className="px-4 py-2 text-sm font-mono">{c.currencyCode ?? "-"}</td>
                      <td className="px-4 py-2 text-right text-sm font-mono">{c.stock ?? c.amount ?? "-"}</td>
                      <td className="px-4 py-2 text-right text-sm font-mono">{formatHuf(c.stockHuf)}</td>
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
