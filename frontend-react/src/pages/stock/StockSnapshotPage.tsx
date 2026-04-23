import { useState, useEffect, useCallback } from 'react'
import { Camera, RefreshCw, AlertTriangle, Download } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'

/**
 * StockSnapshotDto shape (backend: /api/v1/stock-snapshot):
 * {
 *   snapshotTime, companyId, companyName,
 *   regions: [{ regionName, branches: [{ branchId, branchName, totals: {...} }] }],
 *   companyTotals: { totalValueHuf, currencyCount, ... }
 * }
 *
 * Fix #146+ live UI test:
 *  - URL javitas: /stock-snapshots (plural, 404) -> /stock-snapshot (singular, backend matching)
 *  - Objektum kezelesi: safeArray helyett single DTO (regionok + company totals)
 */
interface BranchTotals {
  totalValueHuf?: number
  currencyCount?: number
}

interface BranchStock {
  branchId?: string
  branchName?: string
  totals?: BranchTotals
}

interface RegionSnapshot {
  regionName?: string
  branches?: BranchStock[]
  regionTotals?: BranchTotals
}

interface StockSnapshot {
  snapshotTime?: string
  companyId?: string
  companyName?: string
  regions?: RegionSnapshot[]
  companyTotals?: BranchTotals
}

function formatHuf(v: number | string | undefined): string {
  if (v == null) return '-'
  const n = typeof v === 'string' ? Number(v) : v
  if (Number.isNaN(n)) return String(v)
  return n.toLocaleString('hu-HU') + ' Ft'
}

export default function StockSnapshotPage() {
  const [snapshot, setSnapshot] = useState<StockSnapshot | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<StockSnapshot>('/stock-snapshot')
      setSnapshot(response.data ?? null)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('StockSnapshotPage', 'Betoltesi hiba:', err)
      setError(msg)
      setSnapshot(null)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  async function downloadExcel() {
    try {
      const r = await api.get('/stock-snapshot/excel', { responseType: 'blob' })
      const blob = new Blob([r.data as BlobPart], {
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = 'keszlet-export-' + new Date().toISOString().slice(0, 10) + '.xlsx'
      document.body.appendChild(a); a.click(); a.remove()
      URL.revokeObjectURL(url)
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Camera className="h-6 w-6" />
          Keszlet pillanatkep
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissites">
            <RefreshCw className={loading ? 'h-4 w-4 animate-spin' : 'h-4 w-4'} />
          </button>
          <button onClick={() => void downloadExcel()} className="form-button-primary flex items-center gap-2">
            <Download className="h-4 w-4" /> Excel letoltes
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
        <div className="text-center text-sm text-gray-500 py-8">Betoltes...</div>
      ) : !snapshot ? (
        <div className="text-center text-sm text-gray-500 py-8">Nincs adat</div>
      ) : (
        <div className="space-y-4">
          <div className="bg-white rounded shadow p-4 grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
            <div><span className="text-gray-500">Ceg:</span> <b>{snapshot.companyName ?? '-'}</b></div>
            <div><span className="text-gray-500">Snapshot ido:</span> {snapshot.snapshotTime ? new Date(snapshot.snapshotTime).toLocaleString('hu-HU') : '-'}</div>
            <div><span className="text-gray-500">Osszes HUF ertek:</span> <b className="font-mono">{formatHuf(snapshot.companyTotals?.totalValueHuf)}</b></div>
          </div>

          {(snapshot.regions ?? []).map((region, ri) => (
            <div key={(region.regionName ?? 'r') + ri} className="bg-white rounded shadow">
              <div className="bg-gray-50 px-4 py-2 border-b">
                <h2 className="font-semibold">{region.regionName ?? 'Regio'}</h2>
                <div className="text-xs text-gray-500">
                  Regio osszesen: {formatHuf(region.regionTotals?.totalValueHuf)} / {region.branches?.length ?? 0} penztar
                </div>
              </div>
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-2 text-left text-xs font-medium uppercase text-gray-500">Penztar</th>
                    <th className="px-4 py-2 text-right text-xs font-medium uppercase text-gray-500">Osszes ertek (HUF)</th>
                    <th className="px-4 py-2 text-right text-xs font-medium uppercase text-gray-500">Valutak szama</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {(region.branches ?? []).map((b) => (
                    <tr key={b.branchId} className="hover:bg-gray-50">
                      <td className="px-4 py-2 text-sm">{b.branchName ?? '-'}</td>
                      <td className="px-4 py-2 text-right text-sm font-mono">{formatHuf(b.totals?.totalValueHuf)}</td>
                      <td className="px-4 py-2 text-right text-sm">{b.totals?.currencyCount ?? '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}