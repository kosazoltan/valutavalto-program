import { useState, useEffect, useCallback, useRef } from 'react'
import { Vault, RefreshCw, AlertTriangle, Info, Printer } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import { useAuthStore } from '../../stores/authStore'
import { useVaultStockUpdates } from '../../hooks/useVaultStockUpdates'

/**
 * v2.4.9: Az "Értéktári készlet" oldal — KIZÁRÓLAG az értéktár saját készletét
 * mutatja, valutánként a napi flow-val (nyitó / átvett / átadott / záró).
 *
 * NEM a pénztárak készleteit — azok külön menüpontban: /cashier-stocks
 * (Pénztári készletek).
 *
 * 2026-06-17 (FR-1..6): KÜLÖNBSÉG + FRISSÍTVE oszlopok eltávolítva; zebra + pozitív
 * egyenleg kiemelés; nyomtatás; automatikus frissítés átadás-átvétel COMPLETED eseménynél
 * (WebSocket invalidáció + change-detection).
 */
interface VaultStockRow {
  currencyCode: string
  currencyName: string
  opening: number | null
  received: number | null
  issued: number | null
  closing: number | null
}

function formatCurrency(value: number | null | undefined, code?: string): string {
  if (value == null) return '—'
  const opts: Intl.NumberFormatOptions = code === 'HUF'
    ? { maximumFractionDigits: 0 }
    : { maximumFractionDigits: 2 }
  return value.toLocaleString('hu-HU', opts)
}

/** Change-detection kulcs: csak a megjelenített számszerű mezők számítanak. */
function serializeRows(rows: VaultStockRow[]): string {
  return JSON.stringify(
    rows.map(r => [r.currencyCode, r.opening, r.received, r.issued, r.closing]),
  )
}

export default function InventoryPage() {
  const { t } = useTranslation()
  const worker = useAuthStore(s => s.worker)
  const [rows, setRows] = useState<VaultStockRow[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [lastRefresh, setLastRefresh] = useState<Date | null>(null)

  // A WS-callback (refreshIfChanged) a legfrissebb sorokat ref-en keresztül éri el,
  // hogy ne épüljön újra a feliratkozás minden adatváltozásnál.
  const rowsRef = useRef<VaultStockRow[]>(rows)
  useEffect(() => { rowsRef.current = rows }, [rows])

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

  // FR-3: WebSocket-invalidációra csendben re-fetch, és CSAK akkor frissít, ha a
  // (territory-scope-olt) válasz ténylegesen változott → más iroda/értéktár mozgása
  // (ami a saját scope-olt nézetet nem érinti) nem okoz látható frissítést.
  // NFR-5: az automatikus frissítés hibája silent fail (nincs hibaüzenet).
  const refreshIfChanged = useCallback(async () => {
    try {
      const response = await api.get<VaultStockRow[]>('/inventory/vault-stock')
      const next = safeArray<VaultStockRow>(response.data)
      if (serializeRows(next) !== serializeRows(rowsRef.current)) {
        setRows(next)
        setLastRefresh(new Date())
      }
    } catch (err) {
      logger.debug('InventoryPage', 'Automatikus frissítés sikertelen (silent):', err)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  useVaultStockUpdates(refreshIfChanged)

  const totalHufClosing = rows
    .filter(r => r.currencyCode === 'HUF')
    .reduce((sum, r) => sum + (r.closing ?? 0), 0)

  return (
    <div className="space-y-3 app-print-content">
      <div className="no-print flex items-center justify-between gap-3 flex-wrap">
        <h1 className="text-lg font-bold text-secondary-900 flex items-center gap-2">
          <Vault className="h-5 w-5 text-primary-700" />
          {t('inventory.ertektariKeszlet')}
          <span className="text-xs text-gray-500 font-normal">{t('inventory.sajatValutankent')}</span>
        </h1>
        <div className="flex items-center gap-2">
          {lastRefresh && (
            <span className="text-xs text-gray-500">
              {lastRefresh.toLocaleTimeString('hu-HU')}
            </span>
          )}
          <button onClick={() => void loadData()} className="form-button h-8 text-xs flex items-center gap-1" title={t('common.refresh')}>
            <RefreshCw className={`h-3 w-3 ${loading ? 'animate-spin' : ''}`} />
            {t('common.refresh')}
          </button>
          <button onClick={() => window.print()} className="form-button h-8 text-xs flex items-center gap-1" title={t('common.print')}>
            <Printer className="h-3 w-3" />
            {t('common.print')}
          </button>
        </div>
      </div>

      {/* Nyomtatási fejléc — csak nyomtatáskor látszik (telephely + dátum), lábléc nélkül */}
      <div className="hidden print:block mb-2">
        <div className="text-base font-bold">{t('inventory.ertektariKeszlet')}</div>
        <div className="text-sm">
          {worker?.branchName ?? worker?.branchCode ?? ''} — {new Date().toLocaleDateString('hu-HU')}
        </div>
      </div>

      {error && (
        <div className="no-print form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {/* HUF összesen kiemelt kártya */}
      <div className="no-print rounded-lg bg-gradient-to-br from-primary-50 to-primary-100 border-2 border-primary-200 p-4 shadow-sm">
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <Vault className="h-6 w-6 text-primary-700" />
            <div>
              <div className="text-sm text-primary-700 font-medium">{t('inventory.ertektariZaroHufKeszlet')}</div>
              <div className="text-2xl font-bold font-mono text-primary-900">
                {totalHufClosing.toLocaleString('hu-HU', { maximumFractionDigits: 0 })} {t('common.ft')}
              </div>
            </div>
          </div>
          <div className="text-right">
            <div className="text-sm text-primary-700">{rows.length} {t('inventory.valuta')}</div>
          </div>
        </div>
      </div>

      {/* Vault flow tábla */}
      <div className="form-panel p-0">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr className="text-xs uppercase text-gray-600">
              <th className="px-3 py-2 text-left w-20">{t('common.code')}</th>
              <th className="px-3 py-2 text-left">{t('display.megnevezes')}</th>
              <th className="px-3 py-2 text-right w-28">{t('inventory.nyitokeszlet')}</th>
              <th className="px-3 py-2 text-right w-28">{t('inventory.atvettIn')}</th>
              <th className="px-3 py-2 text-right w-28">{t('inventory.atadottOut')}</th>
              <th className="px-3 py-2 text-right w-28">{t('inventory.zarokeszlet')}</th>
            </tr>
          </thead>
          <tbody>
            {loading && rows.length === 0 ? (
              <tr><td colSpan={6} className="px-3 py-8 text-center text-sm text-gray-500">Betöltés...</td></tr>
            ) : rows.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-3 py-8 text-center text-sm text-gray-500">
                  <div className="flex flex-col items-center gap-2">
                    <Info className="h-5 w-5 text-gray-400" />
                    <div>{t('inventory.nincsErtektariKeszletBejegyzes')}</div>
                    <div className="text-xs text-gray-400">
                      {t('inventory.azErtektariKeszletACollectionDistributionBankTranzakciokSoranToltodikFel')}
                    </div>
                  </div>
                </td>
              </tr>
            ) : rows.map((row, idx) => {
              // FR-5: pozitív záróegyenlegű sor enyhe zöld tónussal kiemelve (a 0-egyenlegtől
              // elkülönítve); FR-4: a többi sor zebra-csíkozással (páros/páratlan).
              const positive = (row.closing ?? 0) > 0
              const rowBg = positive ? 'bg-emerald-50' : (idx % 2 === 1 ? 'bg-gray-50' : '')
              return (
                <tr key={row.currencyCode} className={`${rowBg} hover:bg-blue-50 border-b border-gray-100 last:border-0`}>
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
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      {rows.length > 0 && rows[0]?.opening == null && (
        <div className="no-print form-panel bg-amber-50 border-amber-200 flex items-start gap-2 text-xs text-amber-900">
          <Info className="h-4 w-4 mt-0.5 flex-shrink-0" />
          <span>
            <strong>{t('components.megjegyzes')}</strong>{t('inventory.aNyitoAtvettAtadottNapiErtekek')}
            {t('inventory.kovetesehezAV250SprintbenKerulImplementalasraADailySnapshotMechanizmus')}
            {t('inventory.jelenlegCsakAZaroJelenlegiKeszletErhetoEl')}
          </span>
        </div>
      )}
    </div>
  )
}
