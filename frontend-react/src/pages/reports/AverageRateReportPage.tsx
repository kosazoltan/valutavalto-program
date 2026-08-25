import { useState, useEffect, useCallback, useMemo, Fragment } from 'react'
import { TrendingUp, AlertTriangle, Search, Download } from 'lucide-react'
import { averageRateApi, branchApi } from '../../services/api/index'
import type { AverageRatePivotResponse, BranchInfo } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getBlobErrorMessage, getErrorMessage } from '../../utils/errorHandling'
import { localIsoDate } from '../../utils/dateFormat'
import { downloadBlob } from '../../utils/downloadBlob'

/**
 * FK-027 — Átlag árfolyam riport (legacy ATLAGARF / Atlagarfolyam.xls parity).
 *
 * Sorok = valuták (mind a 22), oszlopcsoportok = 8 terület + "EXCLUSIVE BEST CHANGE ZRT"
 * összesítő (vagy 1 fiók, ha az "Iroda" szűrő egy konkrét pénztárra szól). Minden
 * oszlopcsoport 4 oszloppal: Vétel Árfolyam, Vétel Összeg, Eladás Árfolyam, Eladás Összeg.
 * Nincs "Típus" és "Valuta" szűrő — Vétel és Eladás mindig párhuzamosan, minden valuta sorként.
 *
 * Backend: GET /api/v1/reports/average-rate/pivot + /export (Excel).
 */

const SUB_HEADERS = ['Vétel Árfolyam', 'Vétel Összeg', 'Eladás Árfolyam', 'Eladás Összeg']

function formatAmount(n: number): string {
  return (n ?? 0).toLocaleString('hu-HU', { maximumFractionDigits: 2 })
}

function formatRate(n: number): string {
  return (n ?? 0).toLocaleString('hu-HU', { minimumFractionDigits: 4, maximumFractionDigits: 4 })
}

export default function AverageRateReportPage() {
  const today = useMemo(() => new Date(), [])
  const monthStart = useMemo(() => {
    const d = new Date(today)
    d.setDate(1)
    return d
  }, [today])

  const [from, setFrom] = useState<string>(localIsoDate(monthStart))
  const [to, setTo] = useState<string>(localIsoDate(today))
  const [branchId, setBranchId] = useState<string>('')
  const [branches, setBranches] = useState<BranchInfo[]>([])
  const [data, setData] = useState<AverageRatePivotResponse | null>(null)
  const [queried, setQueried] = useState(false)
  const [loading, setLoading] = useState(false)
  const [exporting, setExporting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadFilters = useCallback(async () => {
    try {
      const br = await branchApi.listActive()
      setBranches(br ?? [])
    } catch (err) {
      logger.error('AverageRateReportPage', 'Iroda-lista betöltés hiba:', err)
    }
  }, [])

  useEffect(() => {
    void loadFilters()
  }, [loadFilters])

  const handleQuery = useCallback(async () => {
    if (!from || !to) {
      setError('Adj meg egy Tól és Ig dátumot!')
      return
    }
    setLoading(true)
    setError(null)
    try {
      const resp = await averageRateApi.getPivot(from, to, branchId || undefined)
      setData(resp)
      setQueried(true)
    } catch (err) {
      logger.error('AverageRateReportPage', 'Lekérdezés hiba:', err)
      setError(getErrorMessage(err))
      setData(null)
      setQueried(true)
    } finally {
      setLoading(false)
    }
  }, [from, to, branchId])

  const handleExport = useCallback(async () => {
    if (!from || !to) {
      setError('Adj meg egy Tól és Ig dátumot az exporthoz!')
      return
    }
    setExporting(true)
    setError(null)
    try {
      // FK-051 v2 (FR-7): defenzív Blob-becsomagolás explicit xlsx MIME-típussal —
      // másodlagos védelmi réteg az IPC proxy whitelist-detekciója mellett.
      const rawData = await averageRateApi.exportExcel(from, to)
      const blob = new Blob([rawData as BlobPart], {
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      })
      downloadBlob(blob, `atlag_arfolyam_${from}_${to}.xlsx`)
    } catch (err) {
      logger.error('AverageRateReportPage', 'Excel export hiba:', err)
      setError(await getBlobErrorMessage(err))
    } finally {
      setExporting(false)
    }
  }, [from, to])

  const groups = data?.columnGroups ?? []
  const currencyRows = data?.currencyRows ?? []
  // FK-094: az értéktári (isVault === true) fiókok sosem adnak riport-adatot —
  // a lenyíló csak a nem-értéktári fiókokat listázza; a hiányzó/undefined isVault látszik.
  const visibleBranches = useMemo(() => branches.filter((b) => b.isVault !== true), [branches])

  return (
    <div className="form-panel space-y-4">
      <div>
        <h1 className="form-title flex items-center gap-2">
          <TrendingUp className="h-6 w-6" />
          Átlag árfolyam riport
        </h1>
        <p className="text-xs text-gray-500 mt-1">
          HUF-súlyozott átlagárfolyam, területenkénti és összesített Vétel/Eladás bontásban.
        </p>
        <p
          className="mt-2 text-xs text-amber-800 bg-amber-50 border border-amber-200 rounded px-2 py-1"
          data-testid="average-rate-export-notice"
        >
          Az Excel export mindig a teljes, minden irodát tartalmazó struktúrát (8 terület +
          összesítő) tölti le — az „Iroda” szűrő csak a képernyőn látható táblázatra hat.
        </p>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-2 text-red-700 text-sm flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="bg-white rounded shadow p-4 grid grid-cols-1 md:grid-cols-5 gap-3 items-end">
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="ar-from">
            Tól
          </label>
          <input
            id="ar-from"
            type="date"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            className="form-input w-full text-sm"
          />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="ar-to">
            Ig
          </label>
          <input
            id="ar-to"
            type="date"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            className="form-input w-full text-sm"
          />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="ar-branch">
            Iroda
          </label>
          <select
            id="ar-branch"
            value={branchId}
            onChange={(e) => setBranchId(e.target.value)}
            className="form-input w-full text-sm"
            aria-label="Iroda szűrő"
          >
            <option value="">Összes iroda</option>
            {visibleBranches.map((b) => (
              <option key={b.id} value={b.id}>
                {b.code} - {b.name}
              </option>
            ))}
          </select>
        </div>
        <div>
          <button
            type="button"
            onClick={() => void handleQuery()}
            disabled={loading}
            className="form-button-primary flex items-center gap-2"
          >
            <Search className="h-4 w-4" />
            {loading ? 'Betöltés…' : 'Lekérdezés'}
          </button>
        </div>
        <div>
          <button
            type="button"
            onClick={() => void handleExport()}
            disabled={exporting}
            className="form-button flex items-center gap-2"
            title="A teljes (8 terület + összesítő) struktúra letöltése a dátum-intervallumra"
          >
            <Download className="h-4 w-4" />
            {exporting ? 'Exportálás…' : 'Excel export'}
          </button>
        </div>
      </div>

      {loading && <div className="text-center text-sm text-gray-500 py-8">Betöltés…</div>}
      {!loading && data && currencyRows.length > 0 && (
        <div className="bg-white rounded shadow">
          {/* FK-031 "ablak rögzítése" (freeze panes) + FK-033 regresszió-javítás: a táblázat saját, belső
              görgetése (korábbi `overflow-auto max-h-[70vh]`) MEGSZŰNT, hogy NE legyen kettős, egymásba
              ágyazott scroll-kontextus a layout külső `.app-print-content` konténerével (MainLayout.tsx).
              Egyetlen görgető kontextus marad (a layout-szintű, külső), amelyhez a VALUTA oszlop (sticky
              left) és a fejléc-sorok (sticky thead) MEGBÍZHATÓAN kötődnek — minden területi oszlopcsoportnál
              (Békéscsabától az Exclusive Best Change Zrt-ig) és a teljes függőleges hosszban; a vízszintes
              görgetősáv is mindig elérhető marad (FK-033 FR-2/FR-3/FR-5). A sticky CSS-osztályok lent
              változatlanok — azok helyesek voltak, csak a görgető kontextus volt hibás. */}
          <table className="min-w-full border-collapse text-sm" data-testid="pivot-table">
            {/* sticky top-0: a teljes (2 soros) fejléc a táblázat tetején marad függőleges görgetésnél */}
            <thead className="bg-gray-50 sticky top-0 z-20">
              <tr>
                {/* bal-felső sarokcella: sticky MINDKÉT irányban (left-0 + top-0), legmagasabb z-index;
                    border-r-2 a görgethető tartalomtól való vizuális elválasztáshoz (FR-3) */}
                <th
                  rowSpan={2}
                  className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500 border sticky left-0 top-0 z-30 bg-gray-50 border-r-2 border-r-gray-300"
                >
                  Valuta
                </th>
                {groups.map((g) => (
                  <th
                    key={g.groupCode}
                    colSpan={4}
                    className="px-3 py-2 text-center text-xs font-semibold text-gray-700 border bg-gray-50"
                  >
                    {g.groupName}
                  </th>
                ))}
              </tr>
              <tr>
                {groups.map((g) => (
                  <Fragment key={g.groupCode}>
                    {SUB_HEADERS.map((h) => (
                      <th
                        key={`${g.groupCode}-${h}`}
                        className="px-2 py-1 text-right text-[10px] font-medium uppercase text-gray-500 border bg-gray-50 whitespace-nowrap"
                      >
                        {h}
                      </th>
                    ))}
                  </Fragment>
                ))}
              </tr>
            </thead>
            <tbody>
              {currencyRows.map((row) => (
                <tr key={row.currencyCode} className="hover:bg-gray-50">
                  {/* VALUTA oszlop: sticky left (vízszintes görgetésnél marad); z-10 a sima cellák fölött,
                      a fejléc (z-20) alatt; opak háttér (NFR-1) + border-r-2 elválasztó (FR-1/FR-3) */}
                  <td className="px-3 py-1.5 font-semibold border sticky left-0 z-10 bg-white border-r-2 border-r-gray-300">
                    {row.currencyCode}
                  </td>
                  {groups.map((g) => {
                    const v = row.values[g.groupCode]
                    return (
                      <Fragment key={g.groupCode}>
                        <td className="px-2 py-1.5 text-right font-mono text-green-700 border">
                          {formatRate(v?.buyAvgRate ?? 0)}
                        </td>
                        <td className="px-2 py-1.5 text-right font-mono border">
                          {formatAmount(v?.buySumAmount ?? 0)}
                        </td>
                        <td className="px-2 py-1.5 text-right font-mono text-blue-700 border">
                          {formatRate(v?.sellAvgRate ?? 0)}
                        </td>
                        <td className="px-2 py-1.5 text-right font-mono border">
                          {formatAmount(v?.sellSumAmount ?? 0)}
                        </td>
                      </Fragment>
                    )
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {!loading && queried && (!data || currencyRows.length === 0) && !error && (
        <div className="text-center text-sm text-gray-500 py-8">
          Nincs megjeleníthető adat erre az időszakra.
        </div>
      )}

      {!loading && !queried && (
        <div className="text-center text-sm text-gray-500 py-8">
          Adj meg egy dátum-intervallumot és kattints a „Lekérdezés" gombra.
        </div>
      )}
    </div>
  )
}
