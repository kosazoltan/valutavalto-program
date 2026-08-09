import { useState, useCallback, useEffect, useMemo } from 'react'
import { BarChart3, RefreshCw, TrendingUp, TrendingDown } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { localIsoDate } from '../../utils/dateFormat'
import { turnoverApi, branchApi, currencyApi, type BranchInfo } from '../../services/api/index'
import { useTranslation } from 'react-i18next'

// FK-045 FR-11: a backend TurnoverReportDto TÉNYLEGES struktúrája (nem a régi, soha össze nem
// hangolt `TurnoverData`). A vak `as TurnoverData` cast megszűnt — proper típus-leképezés.
interface CurrencyTurnoverRow {
  currencyCode: string
  officialRate: number | null // MNB elszámolási árfolyam (100/Ft); null → „–"
  buyVolume: number // vásárolt bankjegy mennyiség
  buyHuf: number // vásárolt forint érték
  sellVolume: number // eladott bankjegy mennyiség
  sellHuf: number // eladott forint érték
  fee?: number
  transactionCount?: number
}

interface TurnoverReport {
  period: string
  totalBuy: number // VETT összesen (Ft)
  totalSell: number // ELADOTT összesen (Ft)
  byCurrency: CurrencyTurnoverRow[]
}

// FK-045 FR-3/4/5 (TBD-2): három egység-nézet.
type UnitMode = 'company' | 'territory' | 'branch'

export default function DailyTurnoverPage() {
  const { t } = useTranslation()
  const today = localIsoDate()
  const [yearStr, monthStr] = useMemo(() => today.split('-'), [today])

  // FK-045 FR-2 (TBD-3): Év + Hónap + Nap-tól + Nap-ig. Alapértelmezés: aktuális év/hónap, 1..utolsó nap.
  const [year, setYear] = useState<number>(Number(yearStr))
  const [month, setMonth] = useState<number>(Number(monthStr))
  const [dayFrom, setDayFrom] = useState<number>(1)
  const lastDayOfMonth = useMemo(() => new Date(year, month, 0).getDate(), [year, month])
  const [dayTo, setDayTo] = useState<number>(lastDayOfMonth)

  // FK-045 #5 (GLM-review): hónap/év váltáskor a dayFrom/dayTo a hónap hosszára korlátozódik, hogy a
  // beviteli mező ne mutasson érvénytelen napot (pl. 31 egy 30 napos hónapnál).
  useEffect(() => {
    setDayTo((d) => Math.min(d, lastDayOfMonth))
    setDayFrom((d) => Math.min(d, lastDayOfMonth))
  }, [lastDayOfMonth])

  const [unitMode, setUnitMode] = useState<UnitMode>('company')
  const [territoryId, setTerritoryId] = useState<number | ''>('')
  const [branchId, setBranchId] = useState<string>('')

  const [branches, setBranches] = useState<BranchInfo[]>([])
  const [activeCurrencies, setActiveCurrencies] = useState<string[]>([])
  const [data, setData] = useState<TurnoverReport | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Egység-választóhoz: aktív (nem-értéktári) pénztárak + a belőlük derivált területek.
  useEffect(() => {
    branchApi
      .listActive()
      .then((list) => setBranches(list || []))
      .catch((err) => logger.error('DailyTurnoverPage', 'Fiók-lista hiba:', err))
  }, [])

  // FR-6: az ÖSSZES aktív valuta (displayOrder szerint) — a táblázat ezeket mind mutatja,
  // a forgalom nélkülieket is üres sorként (nem rejtve).
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
      .catch((err) => logger.error('DailyTurnoverPage', 'Valuta-lista hiba:', err))
  }, [])

  // FR-3: pénztárak pénztárszám (code) szerint rendezve, az értéktárak kizárva.
  const cashierBranches = useMemo(
    () =>
      branches
        .filter((b) => !b.isVault)
        .slice()
        .sort((a, b) => (a.code || '').localeCompare(b.code || '', 'hu')),
    [branches],
  )

  // FR-4: a 8 terület a branch-ekből derivált egyedi (id, név) lista.
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

  const clampDay = (d: number) => Math.min(Math.max(d, 1), lastDayOfMonth)

  const buildRange = useCallback(() => {
    const mm = String(month).padStart(2, '0')
    const from = `${year}-${mm}-${String(clampDay(dayFrom)).padStart(2, '0')}`
    const to = `${year}-${mm}-${String(clampDay(dayTo)).padStart(2, '0')}`
    return { from, to }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [year, month, dayFrom, dayTo, lastDayOfMonth])

  const loadTurnover = useCallback(async () => {
    const { from, to } = buildRange()
    if (from > to) {
      toast.warning('A kezdő nap nem lehet nagyobb a záró napnál!')
      return
    }
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
      let res: TurnoverReport
      if (unitMode === 'company') {
        res = (await turnoverApi.company(from, to)) as TurnoverReport
      } else if (unitMode === 'territory') {
        res = (await turnoverApi.territory(Number(territoryId), from, to)) as TurnoverReport
      } else {
        // FR-3 pénztár nézet: a teljes [from, to] tartomány a branch-range végponton (a régi /daily
        // csak egyetlen napot adott vissza — a kiválasztott intervallum elveszett).
        res = (await turnoverApi.branchRange(branchId, from, to)) as TurnoverReport
      }
      setData(res)
    } catch (err) {
      logger.error('DailyTurnoverPage', 'Forgalom betöltési hiba:', err)
      setError(getErrorMessage(err))
      setData(null)
    } finally {
      setLoading(false)
    }
    // Lint-audit 2026-08-09: a `t` felesleges volt — a callback egyetlen
    // forditott sztringet sem hasznal (a hibauzenet a `getErrorMessage`-bol jon),
    // igy a nyelvvaltas feleslegesen ujra-kreaciot es refetch-et valtott ki.
  }, [buildRange, unitMode, territoryId, branchId])

  const fmtNum = (n: number) =>
    (n ?? 0).toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  const fmtHuf = (n: number) =>
    (n ?? 0).toLocaleString('hu-HU', { minimumFractionDigits: 0, maximumFractionDigits: 0 }) + ' Ft'
  const fmtRate = (r: number | null) =>
    r == null
      ? '–'
      : r.toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 4 })

  // FR-6: a táblázat MINDEN aktív valutát mutat. A backend csak a forgalmazott valutákat adja vissza
  // (GROUP BY currency), ezért a hiányzó aktív valutákat üres (0/„–") sorként pótoljuk — nem rejtjük.
  const rows = useMemo<CurrencyTurnoverRow[]>(() => {
    if (!data) return []
    const byCode = new Map(data.byCurrency.map((r) => [r.currencyCode, r]))
    const order =
      activeCurrencies.length > 0 ? activeCurrencies : data.byCurrency.map((r) => r.currencyCode)
    // a backend-ben szereplő, de a katalógusban (még) nem listázott kódokat is megtartjuk a végén
    const extra = data.byCurrency.map((r) => r.currencyCode).filter((c) => !order.includes(c))
    return [...order, ...extra].map(
      (code) =>
        byCode.get(code) ?? {
          currencyCode: code,
          officialRate: null,
          buyVolume: 0,
          buyHuf: 0,
          sellVolume: 0,
          sellHuf: 0,
        },
    )
  }, [data, activeCurrencies])

  const years = useMemo(() => {
    const cur = Number(yearStr)
    return [cur - 2, cur - 1, cur, cur + 1]
  }, [yearStr])
  const months = [
    'Január',
    'Február',
    'Március',
    'Április',
    'Május',
    'Június',
    'Július',
    'Augusztus',
    'Szeptember',
    'Október',
    'November',
    'December',
  ]

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2">
        <BarChart3 />
        {t('reports.forgalomOsszesito')}
      </h1>

      {/* FR-2 Dátum + FR-3/4/5 egység szűrők */}
      <div className="form-panel flex gap-3 items-end flex-wrap">
        <div>
          <label className="form-label">Év</label>
          <select
            className="form-input"
            aria-label="Év"
            value={year}
            onChange={(e) => setYear(Number(e.target.value))}
          >
            {years.map((y) => (
              <option key={y} value={y}>
                {y}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="form-label">Hónap</label>
          <select
            className="form-input"
            aria-label="Hónap"
            value={month}
            onChange={(e) => setMonth(Number(e.target.value))}
          >
            {months.map((m, i) => (
              <option key={m} value={i + 1}>
                {m}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="form-label">Nap (tól)</label>
          <input
            className="form-input w-20"
            aria-label="Nap (tól)"
            type="number"
            min={1}
            max={lastDayOfMonth}
            value={dayFrom}
            onChange={(e) => setDayFrom(clampDay(Number(e.target.value)))}
          />
        </div>
        <div>
          <label className="form-label">Nap (ig)</label>
          <input
            className="form-input w-20"
            aria-label="Nap (ig)"
            type="number"
            min={1}
            max={lastDayOfMonth}
            value={dayTo}
            onChange={(e) => setDayTo(clampDay(Number(e.target.value)))}
          />
        </div>
        <div>
          <label className="form-label">Egység</label>
          <select
            className="form-input"
            aria-label="Egység"
            value={unitMode}
            onChange={(e) => setUnitMode(e.target.value as UnitMode)}
          >
            <option value="company">Teljes cég</option>
            <option value="territory">Terület</option>
            <option value="branch">Pénztár</option>
          </select>
        </div>
        {unitMode === 'territory' && (
          <div>
            <label className="form-label">Terület</label>
            <select
              className="form-input"
              aria-label="Terület"
              value={territoryId}
              onChange={(e) => setTerritoryId(e.target.value === '' ? '' : Number(e.target.value))}
            >
              <option value="">— válasszon —</option>
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
            <label className="form-label">Pénztár</label>
            <select
              className="form-input"
              aria-label="Pénztár"
              value={branchId}
              onChange={(e) => setBranchId(e.target.value)}
            >
              <option value="">— válasszon —</option>
              {cashierBranches.map((b) => (
                <option key={b.id} value={b.id}>
                  {b.code} — {b.name}
                </option>
              ))}
            </select>
          </div>
        )}
        <button
          onClick={() => void loadTurnover()}
          disabled={loading}
          className="form-button-primary"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          Időszak rendben
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {data && (
        <>
          {/* FR-6 valutánkénti táblázat */}
          <div className="form-panel">
            <h2 className="font-semibold mb-2">
              {t('reports.devizankentiForgalom')} — {data.period}
            </h2>
            {(data?.byCurrency.length ?? 0) === 0 ? (
              <div className="text-center text-gray-500 py-4">
                Nincs forgalmi adat a megadott időszakra
              </div>
            ) : (
              <table className="data-grid w-full text-sm">
                <thead>
                  <tr>
                    <th>{t('common.deviza')}</th>
                    <th className="text-right">Elszámolási árfolyam (100/Ft)</th>
                    <th className="text-right">Vásárlás (mennyiség)</th>
                    <th className="text-right">Vásárlás (Ft)</th>
                    <th className="text-right">Eladás (mennyiség)</th>
                    <th className="text-right">Eladás (Ft)</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((c) => (
                    <tr key={c.currencyCode}>
                      <td className="font-mono font-bold">{c.currencyCode}</td>
                      <td className="text-right font-mono">{fmtRate(c.officialRate)}</td>
                      <td className="text-right font-mono">{fmtNum(c.buyVolume)}</td>
                      <td className="text-right font-mono">{fmtHuf(c.buyHuf)}</td>
                      <td className="text-right font-mono">{fmtNum(c.sellVolume)}</td>
                      <td className="text-right font-mono">{fmtHuf(c.sellHuf)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          {/* FR-8 összesítő sor */}
          <div className="grid grid-cols-2 gap-3">
            <div className="form-panel text-center bg-green-50">
              <TrendingUp size={24} className="mx-auto text-green-600 mb-1" />
              <div className="text-lg font-bold text-green-700">{fmtHuf(data.totalBuy)}</div>
              <div className="text-sm text-gray-500">VETT összesen</div>
            </div>
            <div className="form-panel text-center bg-blue-50">
              <TrendingDown size={24} className="mx-auto text-blue-600 mb-1" />
              <div className="text-lg font-bold text-blue-700">{fmtHuf(data.totalSell)}</div>
              <div className="text-sm text-gray-500">ELADOTT összesen</div>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
