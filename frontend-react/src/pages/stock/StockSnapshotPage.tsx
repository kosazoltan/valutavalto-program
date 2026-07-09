import { useState, useEffect, useCallback, useMemo, Fragment } from 'react'
import { Camera, RefreshCw, AlertTriangle, Download } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getBlobErrorMessage, getErrorMessage } from '../../utils/errorHandling'
import { downloadBlob } from '../../utils/downloadBlob'

/**
 * FK-003/004 — Készlet pillanatkép (főértéktári élő készlet + napi forgalom).
 *
 * Backend: GET /stock-snapshot (StockSnapshotDto). Per-régió → per-pénztár → per-valuta
 * készlet (stock/stockHuf) + napi forgalom (dailyBuy/dailyBuyHuf + dailySell/dailySellHuf).
 * A 27 valuta fix sorrendben, HUF az utolsó (a backend CURRENCY_CODES adja a sorrendet, de a
 * megjelenítés a kapott currencies-listára épül). Fülek = körzetek + Összesítő (utolsó).
 */

// FK-003/004 spec: 27 valuta teljes neve. HUF mindig utolsó (a backend így is rendezi).
const CURRENCY_NAMES: Record<string, string> = {
  AUD: 'AUSZTRÁL DOLLÁR',
  BAM: 'BOSNYÁK MÁRKA',
  BGN: 'BOLGÁR LEVA',
  BRL: 'BRAZIL REÁL',
  CAD: 'KANADAI DOLLÁR',
  CHF: 'SVÁJCI FRANK',
  CNY: 'KÍNAI YUAN',
  CZK: 'CSEH KORONA',
  DKK: 'DÁN KORONA',
  EUR: 'EURÓ',
  GBP: 'ANGOL FONT',
  HRK: 'HORVÁT KUNA',
  ILS: 'IZRAELI SHEKEL',
  JPY: 'JAPÁN YEN',
  MXN: 'MEXIKÓI PESO',
  NOK: 'NORVÉG KORONA',
  NZD: 'ÚJ-ZÉLANDI DOLLÁR',
  PLN: 'LENGYEL ZLOTYI',
  RON: 'ROMÁN LEJ',
  RSD: 'SZERB DINÁR',
  RUB: 'OROSZ RUBEL',
  SEK: 'SVÉD KORONA',
  THB: 'THAI BAHT',
  TRY: 'TÖRÖK LÍRA',
  UAH: 'UKRÁN HRIVNYA',
  USD: 'AMERIKAI DOLLÁR',
  HUF: 'MAGYAR FORINT',
}

interface CurrencyStockDetail {
  currencyCode?: string
  stock?: number | string
  stockHuf?: number | string
  dailyBuy?: number | string
  dailyBuyHuf?: number | string
  dailySell?: number | string
  dailySellHuf?: number | string
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
  lastSyncedAt?: string
}
interface StockSnapshot {
  snapshotTime?: string
  companyName?: string
  regions?: RegionSnapshot[]
  companyTotals?: BranchStockTotals
}

/** Egy megjelenítendő oszlop (pénztár a körzet-fülön, vagy körzet az Összesítőn). */
interface SnapshotColumn {
  key: string
  label: string
  lastUpdated?: string
  byCode: Record<string, CurrencyStockDetail>
}

function num(v: number | string | undefined): number {
  if (v == null) return 0
  const n = typeof v === 'string' ? Number(v) : v
  return Number.isNaN(n) ? 0 : n
}
function fmtInt(v: number | string | undefined): string {
  return num(v).toLocaleString('hu-HU')
}
function fmtHuf(v: number | string | undefined): string {
  return num(v).toLocaleString('hu-HU') + ' Ft'
}
function byCodeMap(
  currencies: CurrencyStockDetail[] | undefined,
): Record<string, CurrencyStockDetail> {
  const m: Record<string, CurrencyStockDetail> = {}
  for (const c of currencies ?? []) if (c.currencyCode) m[c.currencyCode] = c
  return m
}

/** A megjelenített valutakódok sorrendje: a kapott adat sorrendje (backend HUF-utolsó), fallback a fix lista. */
function currencyOrder(columns: SnapshotColumn[]): string[] {
  const seen = new Set<string>()
  const order: string[] = []
  for (const col of columns) {
    for (const code of Object.keys(col.byCode)) {
      if (!seen.has(code)) {
        seen.add(code)
        order.push(code)
      }
    }
  }
  // HUF mindig az utolsó (spec), a többi a beérkezés sorrendjében
  const withoutHuf = order.filter((c) => c !== 'HUF')
  return order.includes('HUF') ? [...withoutHuf, 'HUF'] : withoutHuf
}

/** Szinkron-idő formázás: soha = "–"; >30 perc → narancs. */
function SyncTime({ iso }: { iso?: string }) {
  if (!iso) return <span className="text-gray-400">–</span>
  const d = new Date(iso)
  const stale = Date.now() - d.getTime() > 30 * 60 * 1000
  return (
    <span className={stale ? 'text-orange-500' : 'text-gray-500'}>
      {d.toLocaleString('hu-HU', { dateStyle: 'short', timeStyle: 'short' })}
    </span>
  )
}

export default function StockSnapshotPage() {
  const { t } = useTranslation()
  const [snapshot, setSnapshot] = useState<StockSnapshot | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState(0)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<StockSnapshot>('/stock-snapshot')
      setSnapshot(response.data ?? null)
    } catch (err) {
      logger.error('StockSnapshotPage', 'Betöltési hiba:', err)
      setError(getErrorMessage(err))
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
      setError(null)
      const r = await api.get('/stock-snapshot/excel', { responseType: 'blob' })
      // Spec fájlnév: Keszlet_pillanatkep_YYYYMMDD_HHMMSS.xlsx. A timestampet dátum-komponensekből
      // építjük — NEM regex-szel, mert a `[...]` mintát a Tailwind arbitrary-property class-nak
      // hinné és érvénytelen CSS-t generálna (lightningcss build-törés).
      // SZÁNDÉKOSAN HELYI idő (NEM UTC): a magyar főértéktár a képernyőn is a helyi „Snapshot idő"-t
      // látja, így a fájlnév időbélyege ezzel konzisztens (Sourcery bug_risk #855 — dokumentált döntés).
      const now = new Date()
      const pad = (n: number) => String(n).padStart(2, '0')
      const ts =
        `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}_` +
        `${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`
      downloadBlob(
        r.data as BlobPart,
        `Keszlet_pillanatkep_${ts}.xlsx`,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      )
    } catch (err) {
      logger.error('StockSnapshotPage', 'Excel letöltés hiba:', err)
      setError(await getBlobErrorMessage(err))
    }
  }

  const regions = useMemo(() => snapshot?.regions ?? [], [snapshot])
  const isSummary = activeTab >= regions.length
  const companyTotal = useMemo(
    () => (snapshot?.companyTotals?.currencies ?? []).reduce((s, c) => s + num(c.stockHuf), 0),
    [snapshot],
  )
  // Codex P1: ha nincs régió-besorolás, de a cég-összesítő tartalmaz adatot, akkor is
  // jelenítsük meg (az Összesítő nézet a companyTotals-ra esik vissza), NE „nincs adat".
  const companyHasCurrencies = (snapshot?.companyTotals?.currencies?.length ?? 0) > 0

  // A kiválasztott fül oszlopai + területi/cég összesen oszlop.
  const columns = useMemo<SnapshotColumn[]>(() => {
    if (!snapshot) return []
    if (isSummary) {
      const cols: SnapshotColumn[] = regions.map((r, i) => ({
        key: r.regionCode ?? `r${i}`,
        label: r.regionName ?? r.regionCode ?? '?',
        byCode: byCodeMap(r.totals?.currencies),
      }))
      cols.push({
        key: '__company',
        label: t('stockSnapshot.companyTotal'),
        byCode: byCodeMap(snapshot.companyTotals?.currencies),
      })
      return cols
    }
    const region = regions[activeTab]
    if (!region) return []
    const cols: SnapshotColumn[] = (region.branches ?? []).map((b, i) => ({
      key: b.branchId ?? `b${i}`,
      label: b.branchName ?? b.branchCode ?? '?',
      lastUpdated: b.lastUpdated,
      byCode: byCodeMap(b.currencies),
    }))
    cols.push({
      key: '__regiontotal',
      label: t('stockSnapshot.regionTotalCol'),
      byCode: byCodeMap(region.totals?.currencies),
    })
    return cols
  }, [snapshot, regions, activeTab, isSummary, t])

  const codes = useMemo(() => currencyOrder(columns), [columns])

  const stickyCol = 'sticky left-0 z-10 bg-white'
  const stickyColName = 'sticky left-16 z-10 bg-white'

  function renderStockTable() {
    const totalsHuf = columns.map(() => 0)
    return (
      <table className="text-sm border-collapse">
        <thead>
          <tr className="bg-gray-100">
            <th className={`${stickyCol} px-2 py-1 text-left bg-gray-100`}>
              {t('stockSnapshot.currencyHeader')}
            </th>
            <th className={`${stickyColName} px-2 py-1 text-left bg-gray-100 min-w-[140px]`}>
              {t('stockSnapshot.currencyName')}
            </th>
            {columns.map((col) => (
              <th
                key={col.key}
                colSpan={2}
                className="px-2 py-1 text-center border-l whitespace-nowrap"
              >
                <div className="font-semibold">{col.label}</div>
                {!isSummary && (
                  <div className="text-[10px] font-normal">
                    <SyncTime iso={col.lastUpdated} />
                  </div>
                )}
              </th>
            ))}
          </tr>
          <tr className="bg-gray-50 text-[11px] text-gray-500">
            <th className={`${stickyCol} bg-gray-50`}></th>
            <th className={`${stickyColName} bg-gray-50`}></th>
            {columns.map((col) => (
              <Fragment key={col.key}>
                <th className="px-2 py-1 text-right border-l">{t('stockSnapshot.stockHeader')}</th>
                <th className="px-2 py-1 text-right">{t('stockSnapshot.hufValue')}</th>
              </Fragment>
            ))}
          </tr>
        </thead>
        <tbody>
          {codes.map((code) => (
            <tr key={code} className="border-t hover:bg-blue-50">
              <td className={`${stickyCol} px-2 py-1 font-mono font-semibold`}>{code}</td>
              <td className={`${stickyColName} px-2 py-1 whitespace-nowrap`}>
                {CURRENCY_NAMES[code] ?? ''}
              </td>
              {columns.map((col, ci) => {
                const c = col.byCode[code]
                totalsHuf[ci] = (totalsHuf[ci] ?? 0) + num(c?.stockHuf)
                return (
                  <Fragment key={col.key}>
                    <td className="px-2 py-1 text-right font-mono border-l">{fmtInt(c?.stock)}</td>
                    <td className="px-2 py-1 text-right font-mono">{fmtInt(c?.stockHuf)}</td>
                  </Fragment>
                )
              })}
            </tr>
          ))}
          <tr className="border-t-2 border-gray-400 bg-gray-100 font-semibold">
            <td className={`${stickyCol} px-2 py-1 bg-gray-100`}>{t('stockSnapshot.total')}</td>
            <td className={`${stickyColName} px-2 py-1 bg-gray-100`}></td>
            {columns.map((col, ci) => (
              <Fragment key={col.key}>
                <td className="px-2 py-1 border-l"></td>
                <td className="px-2 py-1 text-right font-mono">{fmtHuf(totalsHuf[ci])}</td>
              </Fragment>
            ))}
          </tr>
        </tbody>
      </table>
    )
  }

  function renderTurnoverTable() {
    return (
      <table className="text-sm border-collapse">
        <thead>
          <tr className="bg-gray-100">
            <th className={`${stickyCol} px-2 py-1 text-left bg-gray-100`}>
              {t('stockSnapshot.currencyHeader')}
            </th>
            <th className={`${stickyColName} px-2 py-1 text-left bg-gray-100 min-w-[140px]`}>
              {t('stockSnapshot.currencyName')}
            </th>
            {columns.map((col) => (
              <th
                key={col.key}
                colSpan={4}
                className="px-2 py-1 text-center border-l whitespace-nowrap font-semibold"
              >
                {col.label}
              </th>
            ))}
          </tr>
          <tr className="bg-gray-50 text-[11px] text-gray-500">
            <th className={`${stickyCol} bg-gray-50`}></th>
            <th className={`${stickyColName} bg-gray-50`}></th>
            {columns.map((col) => (
              <Fragment key={col.key}>
                <th className="px-2 py-1 text-right border-l">{t('stockSnapshot.buy')}</th>
                <th className="px-2 py-1 text-right">{t('stockSnapshot.buyHuf')}</th>
                <th className="px-2 py-1 text-right border-l">{t('stockSnapshot.sell')}</th>
                <th className="px-2 py-1 text-right">{t('stockSnapshot.sellHuf')}</th>
              </Fragment>
            ))}
          </tr>
        </thead>
        <tbody>
          {codes.map((code) => (
            <tr key={code} className="border-t hover:bg-blue-50">
              <td className={`${stickyCol} px-2 py-1 font-mono font-semibold`}>{code}</td>
              <td className={`${stickyColName} px-2 py-1 whitespace-nowrap`}>
                {CURRENCY_NAMES[code] ?? ''}
              </td>
              {columns.map((col) => {
                const c = col.byCode[code]
                return (
                  <Fragment key={col.key}>
                    <td className="px-2 py-1 text-right font-mono border-l">
                      {fmtInt(c?.dailyBuy)}
                    </td>
                    <td className="px-2 py-1 text-right font-mono">{fmtInt(c?.dailyBuyHuf)}</td>
                    <td className="px-2 py-1 text-right font-mono border-l">
                      {fmtInt(c?.dailySell)}
                    </td>
                    <td className="px-2 py-1 text-right font-mono">{fmtInt(c?.dailySellHuf)}</td>
                  </Fragment>
                )
              })}
            </tr>
          ))}
        </tbody>
      </table>
    )
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h1 className="form-title flex items-center gap-2">
          <Camera className="h-6 w-6" />
          {t('stockSnapshot.title')}
        </h1>
        <div className="flex items-center gap-3 text-sm">
          <span className="text-gray-500">{snapshot?.companyName ?? '-'}</span>
          <span className="text-gray-500">
            {snapshot?.snapshotTime ? new Date(snapshot.snapshotTime).toLocaleString('hu-HU') : '-'}
          </span>
          <span className="font-mono font-semibold">{fmtHuf(companyTotal)}</span>
          <button
            onClick={() => void loadData()}
            className="form-button p-2"
            title={t('common.refresh')}
          >
            <RefreshCw className={loading ? 'h-4 w-4 animate-spin' : 'h-4 w-4'} />
          </button>
          <button
            onClick={() => void downloadExcel()}
            className="form-button-primary flex items-center gap-2"
          >
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
      ) : !snapshot || (regions.length === 0 && !companyHasCurrencies) ? (
        <div className="text-center text-sm text-gray-500 py-8">{t('common.noData')}</div>
      ) : (
        <>
          {/* Körzet-fülek + Összesítő (utolsó) */}
          <div className="flex flex-wrap gap-1 border-b">
            {regions.map((r, i) => (
              <button
                key={r.regionCode ?? i}
                onClick={() => setActiveTab(i)}
                className={`px-3 py-1.5 text-sm rounded-t ${activeTab === i ? 'bg-blue-600 text-white font-semibold' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}
              >
                {r.regionName ?? r.regionCode}
              </button>
            ))}
            <button
              onClick={() => setActiveTab(regions.length)}
              className={`px-3 py-1.5 text-sm rounded-t ${isSummary ? 'bg-blue-600 text-white font-semibold' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}
            >
              {t('stockSnapshot.summaryTab')}
            </button>
          </div>

          {/* KÉSZLET szekció */}
          <div className="bg-white rounded shadow">
            <div className="bg-blue-50 px-4 py-1.5 font-semibold text-blue-800 border-b">
              {t('stockSnapshot.stockSection')}
            </div>
            <div className="overflow-x-auto">{renderStockTable()}</div>
          </div>

          {/* NAPI FORGALOM szekció */}
          <div className="bg-white rounded shadow">
            <div className="bg-amber-50 px-4 py-1.5 font-semibold text-amber-800 border-b">
              {t('stockSnapshot.turnoverSection')}
            </div>
            <div className="overflow-x-auto">{renderTurnoverTable()}</div>
          </div>
        </>
      )}
    </div>
  )
}
