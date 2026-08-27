import { useState, useCallback, useEffect, useMemo } from 'react'
import { ClipboardCheck, RefreshCw } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { localIsoDate } from '../../utils/dateFormat'
import {
  dailyBalanceGridApi,
  branchApi,
  currencyApi,
  type BranchInfo,
  type DailyBalanceGridRow,
} from '../../services/api/index'
import i18n from '../../i18n'

// FK-047/FK-052: Napi ellenőrző lista — valutánkénti mérleg-grid a daily_balance pénztári
// és értéktári BANK+/BANK− adataiból. Az értéktári SZÁMZÁR továbbra is jövőbeli FK.

// FR-3/FR-5: három egység-nézet — a Napi forgalom (DailyTurnoverPage) mintája.
type UnitMode = 'company' | 'territory' | 'branch'

export default function DailyCheckPage() {
  const today = localIsoDate()
  const [date, setDate] = useState<string>(today)

  const [unitMode, setUnitMode] = useState<UnitMode>('company')
  const [territoryId, setTerritoryId] = useState<number | ''>('')
  const [branchId, setBranchId] = useState<string>('')

  const [branches, setBranches] = useState<BranchInfo[]>([])
  const [activeCurrencies, setActiveCurrencies] = useState<string[]>([])
  const [data, setData] = useState<DailyBalanceGridRow[] | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Egység-választóhoz: aktív pénztárak + a belőlük derivált területek (FK-045 minta).
  useEffect(() => {
    branchApi
      .listActive()
      .then((list) => setBranches(list || []))
      .catch((err) => logger.error('DailyCheckPage', 'Fiók-lista hiba:', err))
  }, [])

  // FR-2: minden aktív valutára sor jelenik meg (displayOrder szerint), a forgalom
  // nélküliekre is — üres „–" sorként, nem rejtve.
  useEffect(() => {
    currencyApi
      .getActive()
      .then((list) =>
        setActiveCurrencies(
          (list || [])
            .slice()
            .sort((a, b) => (a.displayOrder ?? 0) - (b.displayOrder ?? 0))
            .map((c) => c.code),
        ),
      )
      .catch((err) => logger.error('DailyCheckPage', 'Valuta-lista hiba:', err))
  }, [])

  // Pénztárak pénztárszám szerint, értéktárak kizárva (csak pénztári adat jelenik meg — FK-047 OUT).
  const cashierBranches = useMemo(
    () =>
      branches
        .filter((b) => !b.isVault)
        .slice()
        .sort((a, b) => (a.code || '').localeCompare(b.code || '', 'hu')),
    [branches],
  )

  // A területek a branch-ekből derivált egyedi (id, név) lista (FK-045 FR-4 minta).
  const territories = useMemo(() => {
    const map = new Map<number, string>()
    for (const b of branches) {
      if (b.vaultTerritoryId != null && !map.has(b.vaultTerritoryId)) {
        map.set(b.vaultTerritoryId, b.region || `Terület ${b.vaultTerritoryId}`)
      }
    }
    return Array.from(map.entries())
      .map(([id, name]) => ({ id, name }))
      .sort((a, b) => a.name.localeCompare(b.name, 'hu'))
  }, [branches])

  const loadGrid = useCallback(async () => {
    if (unitMode === 'territory' && territoryId === '') {
      toast.warning('Válasszon területet!')
      return
    }
    if (unitMode === 'branch' && !branchId) {
      toast.warning('Válasszon pénztárt!')
      return
    }
    try {
      setLoading(true)
      setError(null)
      const rows = await dailyBalanceGridApi.getGrid(
        date,
        unitMode === 'branch' ? branchId : undefined,
        unitMode === 'territory' ? Number(territoryId) : undefined,
      )
      setData(rows || [])
    } catch (err) {
      logger.error('DailyCheckPage', 'Napi ellenőrző lista betöltési hiba:', err)
      setError(getErrorMessage(err))
      setData(null)
    } finally {
      setLoading(false)
    }
  }, [date, unitMode, territoryId, branchId])

  const fmt = (n: number | null | undefined) => {
    if (n == null) return '–'
    const formatted = n
      .toLocaleString('hu-HU', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
        useGrouping: true,
      })
      .replace(/[\u00a0\u202f]/g, ' ')
    const [rawIntegerPart, fractionPart] = formatted.split(',')
    const integerPart = rawIntegerPart ?? ''
    // A hu-HU CLDR egyes runtime-okban 4 számjegynél még nem csoportosít; a pénzügyi
    // grid szerződése viszont következetesen szóközös ezres tagolást kér.
    const groupedInteger = integerPart.replace(/\B(?=(\d{3})+(?!\d))/g, ' ')
    return fractionPart == null ? groupedInteger : `${groupedInteger},${fractionPart}`
  }

  // FR-2/FR-8: minden aktív valutára sor — a backend csak a daily_balance-ben létező valutákat
  // adja; a hiányzókat „–" (null-mezős) sorral pótoljuk, nem rejtjük és nem hibázunk.
  const rows = useMemo(() => {
    if (!data) return []
    const byCode = new Map(data.map((r) => [r.currencyCode, r]))
    const order = activeCurrencies.length > 0 ? activeCurrencies : data.map((r) => r.currencyCode)
    const extra = data.map((r) => r.currencyCode).filter((c) => !order.includes(c))
    return [...order, ...extra].map(
      (code) =>
        byCode.get(code) ??
        ({ currencyCode: code } as Partial<DailyBalanceGridRow> as DailyBalanceGridRow),
    )
  }, [data, activeCurrencies])

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2">
        <ClipboardCheck />
        {i18n.t('literals.napi-ellenorzo-lista')}
      </h1>

      {/* FR-5: egység + dátum szűrők (alapértelmezés: mai nap, Teljes cég) */}
      <div className="form-panel flex gap-3 items-end flex-wrap">
        <div>
          <label className="form-label">{i18n.t('literals.datum-2')}</label>
          <input
            className="form-input"
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
          />
        </div>
        <div>
          <label className="form-label">{i18n.t('literals.egyseg')}</label>
          <select
            className="form-input"
            value={unitMode}
            onChange={(e) => setUnitMode(e.target.value as UnitMode)}
          >
            <option value="company">{i18n.t('literals.teljes-ceg')}</option>
            <option value="territory">{i18n.t('literals.terulet')}</option>
            <option value="branch">{i18n.t('literals.penztar-2')}</option>
          </select>
        </div>
        {unitMode === 'territory' && (
          <div>
            <label className="form-label">{i18n.t('literals.terulet')}</label>
            <select
              className="form-input"
              value={territoryId}
              onChange={(e) => setTerritoryId(e.target.value === '' ? '' : Number(e.target.value))}
            >
              <option value="">{i18n.t('literals.valasszon-2')}</option>
              {territories.map((tr) => (
                <option key={tr.id} value={tr.id}>
                  {tr.name}
                </option>
              ))}
            </select>
          </div>
        )}
        {unitMode === 'branch' && (
          <div>
            <label className="form-label">{i18n.t('literals.penztar-2')}</label>
            <select
              className="form-input"
              value={branchId}
              onChange={(e) => setBranchId(e.target.value)}
            >
              <option value="">{i18n.t('literals.valasszon-2')}</option>
              {cashierBranches.map((b) => (
                <option key={b.id} value={b.id}>
                  {b.code}
                  {i18n.t('literals.lit-18')}
                  {b.name}
                </option>
              ))}
            </select>
          </div>
        )}
        <button onClick={() => void loadGrid()} disabled={loading} className="form-button-primary">
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          {i18n.t('literals.lekerdezes')}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {data && (
        <div className="form-panel">
          <h2 className="font-semibold mb-2">
            {i18n.t('literals.valutankenti-merleg')}
            {date}
          </h2>
          {data.length === 0 && activeCurrencies.length === 0 ? (
            /* NFR-5: érthető, nem-hibaüzenet jellegű tájékoztatás */
            <div className="text-center text-gray-500 py-4">
              {i18n.t('literals.nincs-adat-a-kivalasztott-idoszakra')}
            </div>
          ) : (
            /* FR-7/NFR-1: .data-grid — a váltakozó sorszín (bg-gray-50 páratlan) az FK-050 közös CSS-ből jön */
            <table className="data-grid w-full text-sm" data-testid="daily-check-grid">
              <thead>
                <tr>
                  <th>{i18n.t('literals.deviza')}</th>
                  <th className="text-right">{i18n.t('literals.nyito-2')}</th>
                  <th className="text-right">{i18n.t('literals.vetel-3')}</th>
                  <th className="text-right">{i18n.t('literals.eladas-3')}</th>
                  <th className="text-right">{i18n.t('literals.ptar')}</th>
                  <th className="text-right">{i18n.t('literals.ptar-2')}</th>
                  <th className="text-right">{i18n.t('literals.zaro')}</th>
                  <th className="text-right">{i18n.t('literals.szamzar')}</th>
                  <th className="text-right">{i18n.t('literals.tobb')}</th>
                  <th className="text-right">{i18n.t('literals.hiany')}</th>
                  <th className="text-right">{i18n.t('literals.bank')}</th>
                  <th className="text-right">{i18n.t('literals.bank-2')}</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((r) => (
                  <tr key={r.currencyCode}>
                    <td className="font-mono font-bold">{r.currencyCode}</td>
                    <td className="text-right font-mono">{fmt(r.openingBalance)}</td>
                    <td className="text-right font-mono">{fmt(r.purchases)}</td>
                    <td className="text-right font-mono">{fmt(r.sales)}</td>
                    <td className="text-right font-mono">{fmt(r.transfersIn)}</td>
                    <td className="text-right font-mono">{fmt(r.transfersOut)}</td>
                    <td className="text-right font-mono">{fmt(r.closingBalance)}</td>
                    <td className="text-right font-mono">{fmt(r.actualStock)}</td>
                    <td className="text-right font-mono">{fmt(r.surplus)}</td>
                    <td className="text-right font-mono">{fmt(r.shortage)}</td>
                    <td className="text-right font-mono">{fmt(r.bankPlus)}</td>
                    <td className="text-right font-mono">{fmt(r.bankMinus)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  )
}
