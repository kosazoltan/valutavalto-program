import { useState, useEffect, useCallback } from 'react'
import { Vault, RefreshCw, AlertTriangle, Info } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'

/**
 * v2.4.9: Az "Értéktári készlet" oldal — KIZÁRÓLAG az értéktár saját készletét
 * mutatja, valutánként a napi flow-val (nyitó / átvett / átadott / záró / diff).
 *
 * NEM a pénztárak készleteit — azok külön menüpontban: /cashier-stocks
 * (Pénztári készletek).
 */
interface VaultStockRow {
  currencyCode: string
  currencyName: string
  opening: number | null
  received: number | null
  issued: number | null
  closing: number | null
  difference: number | null
  lastUpdated: string | null
}

function formatCurrency(value: number | null | undefined, code?: string): string {
  if (value == null) return '—'
  const opts: Intl.NumberFormatOptions = code === 'HUF'
    ? { maximumFractionDigits: 0 }
    : { maximumFractionDigits: 2 }
  return value.toLocaleString('hu-HU', opts)
}

export default function InventoryPage() {
  const [rows, setRows] = useState<VaultStockRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [lastRefresh, setLastRefresh] = useState<Date | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<VaultStockRow[]>('/inventory/vault-stock')
      setRows(safeArray<VaultStockRow>(response.data))
      setLastRefresh(new Date())
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('InventoryPage', 'Értéktári készlet betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const totalHufClosing = rows
    .filter(r => r.currencyCode === 'HUF')
    .reduce((sum, r) => sum + (r.closing ?? 0), 0)

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <h1 className="text-lg font-bold text-secondary-900 flex items-center gap-2">
          <Vault className="h-5 w-5 text-primary-700" />
          Értéktári készlet
          <span className="text-xs text-gray-500 font-normal">(saját, valutánként)</span>
        </h1>
        <div className="flex items-center gap-2">
          {lastRefresh && (
            <span className="text-xs text-gray-500">
              {lastRefresh.toLocaleTimeString('hu-HU')}
            </span>
          )}
          <button onClick={() => void loadData()} className="form-button h-8 text-xs flex items-center gap-1" title="Frissítés">
            <RefreshCw className={`h-3 w-3 ${loading ? 'animate-spin' : ''}`} />
            Frissítés
          </button>
        </div>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {/* HUF összesen kiemelt kártya */}
      <div className="rounded-lg bg-gradient-to-br from-primary-50 to-primary-100 border-2 border-primary-200 p-4 shadow-sm">
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <Vault className="h-6 w-6 text-primary-700" />
            <div>
              <div className="text-sm text-primary-700 font-medium">Értéktári záró HUF készlet</div>
              <div className="text-2xl font-bold font-mono text-primary-900">
                {totalHufClosing.toLocaleString('hu-HU', { maximumFractionDigits: 0 })} Ft
              </div>
            </div>
          </div>
          <div className="text-right">
            <div className="text-sm text-primary-700">{rows.length} valuta</div>
          </div>
        </div>
      </div>

      {/* Vault flow tábla */}
      <div className="form-panel p-0">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr className="text-xs uppercase text-gray-600">
              <th className="px-3 py-2 text-left w-20">Kód</th>
              <th className="px-3 py-2 text-left">Megnevezés</th>
              <th className="px-3 py-2 text-right w-28">Nyitókészlet</th>
              <th className="px-3 py-2 text-right w-28">Átvett (in)</th>
              <th className="px-3 py-2 text-right w-28">Átadott (out)</th>
              <th className="px-3 py-2 text-right w-28">Zárókészlet</th>
              <th className="px-3 py-2 text-right w-24">Különbség</th>
              <th className="px-3 py-2 text-center w-24">Frissítve</th>
            </tr>
          </thead>
          <tbody>
            {loading && rows.length === 0 ? (
              <tr><td colSpan={8} className="px-3 py-8 text-center text-sm text-gray-500">Betöltés...</td></tr>
            ) : rows.length === 0 ? (
              <tr>
                <td colSpan={8} className="px-3 py-8 text-center text-sm text-gray-500">
                  <div className="flex flex-col items-center gap-2">
                    <Info className="h-5 w-5 text-gray-400" />
                    <div>Nincs értéktári készlet bejegyzés.</div>
                    <div className="text-xs text-gray-400">
                      Az értéktári készlet a Collection / Distribution / Bank tranzakciók során töltődik fel.
                    </div>
                  </div>
                </td>
              </tr>
            ) : rows.map((row, idx) => {
              const diff = row.difference ?? 0
              const diffClass = diff === 0 ? 'text-gray-500' : diff > 0 ? 'text-green-700' : 'text-red-700'
              return (
                <tr key={row.currencyCode} className={`${idx % 2 === 1 ? 'bg-gray-50' : ''} hover:bg-blue-50 border-b border-gray-100 last:border-0`}>
                  <td className="px-3 py-1.5 font-mono font-bold text-blue-700">{row.currencyCode}</td>
                  <td className="px-3 py-1.5">{row.currencyName}</td>
                  <td className="px-3 py-1.5 text-right font-mono text-gray-700">
                    {formatCurrency(row.opening, row.currencyCode)}
                  </td>
                  <td className="px-3 py-1.5 text-right font-mono text-green-700">
                    {formatCurrency(row.received, row.currencyCode)}
                  </td>
                  <td className="px-3 py-1.5 text-right font-mono text-red-700">
                    {formatCurrency(row.issued, row.currencyCode)}
                  </td>
                  <td className="px-3 py-1.5 text-right font-mono font-bold text-secondary-900">
                    {formatCurrency(row.closing, row.currencyCode)}
                  </td>
                  <td className={`px-3 py-1.5 text-right font-mono ${diffClass}`}>
                    {row.difference == null ? '—' : (diff > 0 ? '+' : '') + formatCurrency(diff, row.currencyCode)}
                  </td>
                  <td className="px-3 py-1.5 text-center text-xs text-gray-500">
                    {row.lastUpdated ? new Date(row.lastUpdated).toLocaleTimeString('hu-HU', { hour: '2-digit', minute: '2-digit' }) : '—'}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      {rows.length > 0 && rows[0]?.opening == null && (
        <div className="form-panel bg-amber-50 border-amber-200 flex items-start gap-2 text-xs text-amber-900">
          <Info className="h-4 w-4 mt-0.5 flex-shrink-0" />
          <span>
            <strong>Megjegyzés:</strong> A nyitó / átvett / átadott napi értékek
            követéséhez a v2.5.0 sprintben kerül implementálásra a daily-snapshot mechanizmus.
            Jelenleg csak a záró (jelenlegi) készlet érhető el.
          </span>
        </div>
      )}
    </div>
  )
}
