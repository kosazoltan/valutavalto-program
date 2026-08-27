import { useEffect, useState } from 'react'
import { Activity, AlertTriangle, CheckCircle2, MapPin, XCircle } from 'lucide-react'
import { api } from '../../services/api/client'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

// ============================================================================
// Foertektar kozponti dashboard - orszagos penztar-allapot + keszlet egy helyen.
//
// Foertektar feladatai:
//   - Orszagos forgalmi felulet: ki mennyit forgalmazott ma
//   - Keszlet-riasztas: melyik penztarban kritikusan keves deviza
//   - Penztar-allapot: melyik penztar fut online (heartbeat < 10 perc)
//   - Ertektari teruletek irányitasa
// ============================================================================

interface Branch {
  id: string
  code: string
  name: string
  city?: string
  region?: string
  regionCode?: string
  isActive?: boolean
}

interface CashRegisterDevice {
  id: string
  companyId: string
  branchId: string
  code: string
  name?: string
  appMode: string
  lastSeenAt: string | null
  isActive: boolean
}

interface StockRow {
  branchId: string
  currencyCode: string
  amount: number
  hasBalance: boolean
}

// Fix 2026-04-24: backend /api/v1/stock-snapshot response shape (StockSnapshotDto)
// AI review (Codex PR #183 P2): null safety + unmapped region-code branches fallback
interface CurrencyDetail {
  currencyCode: string
  stock: number
  hasBalance?: boolean
}
interface BackendBranch {
  branchId: string
  currencies: CurrencyDetail[]
}
interface BackendRegion {
  regionCode?: string
  branches: BackendBranch[]
}
interface StockSnapshotResponse {
  regions?: BackendRegion[]
}

/**
 * Lapoz a hierarchikus StockSnapshotDto-t flat StockRow[]-ba.
 *
 * Sourcery PR #186: a JSDoc most valosan tukrozi a viselkedest.
 * A backend /stock-snapshot response kizárólag `regions[].branches[].currencies[]`
 * strukturaban ad stock rekordokat. A `companyTotals` NEM tartalmaz branch-szintu
 * adatot, csak aggregalt company-level osszeget (currency-szintu totalBalance).
 *
 * Ha egy aktiv branch nincs a `regions` listaban (pl. unmapped region_code),
 * a flatten NEM kapja meg a stock adatait. A dashboard logikaja (lasd loadData)
 * ezt UNKNOWN jelzovel kezeli - NEM false-positive CRITICAL alert, de NEM is
 * silent healthy state (Codex P1 PR #186 javitas).
 */
function flattenStockSnapshot(snap: StockSnapshotResponse | null): StockRow[] {
  if (!snap?.regions) return []
  const rows: StockRow[] = []
  for (const region of snap.regions) {
    for (const branch of region?.branches ?? []) {
      if (!branch?.branchId) continue // defensive
      for (const cur of branch?.currencies ?? []) {
        if (!cur?.currencyCode) continue
        rows.push({
          branchId: branch.branchId,
          currencyCode: cur.currencyCode,
          amount: cur.stock ?? 0,
          hasBalance: cur.hasBalance === true,
        })
      }
    }
  }
  return rows
}

interface BranchSummary {
  branch: Branch
  device?: CashRegisterDevice
  online: boolean
  lastSeenMinutes: number | null
  stocks: Record<string, number>
  stockAlert: string[] // e.g. "EUR < 500" — CSAK valódi, küszöb alatti riasztás (FK-048 FR-3)
  hasStockData: boolean // FK-048 FR-2: van-e cash_balance adat; ha nincs → STOCK UNKNOWN (semleges)
}

const CRITICAL_THRESHOLDS: Record<string, number> = {
  EUR: 500,
  USD: 500,
  GBP: 300,
  CHF: 300,
  HUF: 100_000,
}

const HEARTBEAT_STALE_MINUTES = 10

export default function CentralVaultDashboard() {
  const { t } = useTranslation()
  const [rows, setRows] = useState<BranchSummary[]>([])
  const [loading, setLoading] = useState(true)
  const [err, setErr] = useState<string | null>(null)
  const [stockUnavailable, setStockUnavailable] = useState(false) // FK-048 FR-4: a /stock-snapshot hívás hibája
  const [devicesUnavailable, setDevicesUnavailable] = useState(false) // FK-085 FR-4: a /cash-register/devices hívás hibája
  const [lastRefresh, setLastRefresh] = useState<Date | null>(null)

  const loadData = async () => {
    setLoading(true)
    setErr(null)
    try {
      // FK-048 FR-4: a /stock-snapshot hibáját NEM nyeljük el csendben "nincs adat"-ként —
      // külön stockFailed flaggel jelöljük, hogy a felhasználó látható hibaüzenetet kapjon,
      // megkülönböztethetően a "egyes fiókoknak nincs adata" (STOCK UNKNOWN) esettől.
      // FK-085 FR-4: a /cash-register/devices hibáját sem nyeljük el — devicesFailed flag
      // jelöli, és a sor-építés üres device-listával fut tovább (hamis Soha/Offline helyett
      // „—" státusz + figyelmeztető banner).
      let stockFailed = false
      let devicesFailed = false
      const [branchesRes, devicesRes, stocksRes] = await Promise.all([
        api.get<Branch[]>('/branches'),
        api.get<CashRegisterDevice[]>('/cash-register/devices').catch(() => {
          devicesFailed = true
          return { data: [] as CashRegisterDevice[] }
        }),
        // Fix 2026-04-24: /stock-snapshot (nem /current) + hierarchikus response flatten
        api.get<StockSnapshotResponse>('/stock-snapshot').catch(() => {
          stockFailed = true
          return { data: null as StockSnapshotResponse | null }
        }),
      ])
      setStockUnavailable(stockFailed)
      setDevicesUnavailable(devicesFailed)
      const branches = branchesRes.data || []
      const devices = devicesRes.data || []
      const stocks = flattenStockSnapshot(stocksRes.data ?? null)
      const now = Date.now()

      const rows: BranchSummary[] = branches
        .filter((b) => b.isActive !== false)
        .map((b) => {
          const device = devices.find((d) => d.branchId === b.id)
          const branchStocks: Record<string, number> = {}
          const hasBalanceByCurrency: Record<string, boolean> = {}
          stocks
            .filter((s) => s.branchId === b.id)
            .forEach((s) => {
              branchStocks[s.currencyCode] = (branchStocks[s.currencyCode] || 0) + (s.amount || 0)
              hasBalanceByCurrency[s.currencyCode] = s.hasBalance
            })
          // FK-048 FR-1/2 + FK-093: STOCK UNKNOWN = egyetlen vezetett deviza sincs (hasBalance);
          // a nem-forgalmazott deviza (stock:0, hasBalance:false) NEM riasztás.
          const hasStockData = Object.values(hasBalanceByCurrency).some(Boolean)
          const stockAlert: string[] = []
          if (hasStockData) {
            for (const [ccy, threshold] of Object.entries(CRITICAL_THRESHOLDS)) {
              if (!hasBalanceByCurrency[ccy]) continue
              const amt = branchStocks[ccy] || 0
              if (amt < threshold) stockAlert.push(`${ccy} < ${threshold.toLocaleString('hu-HU')}`)
            }
          }
          const lastSeenAt = device?.lastSeenAt ? new Date(device.lastSeenAt).getTime() : null
          const mins = lastSeenAt ? Math.floor((now - lastSeenAt) / 60_000) : null
          const online = mins !== null && mins < HEARTBEAT_STALE_MINUTES
          return {
            branch: b,
            device,
            online,
            lastSeenMinutes: mins,
            stocks: branchStocks,
            stockAlert,
            hasStockData,
          }
        })
        .sort((a, b) => {
          // Region, then branch code
          const r = (a.branch.region || '').localeCompare(b.branch.region || '')
          if (r !== 0) return r
          return (a.branch.code || '').localeCompare(b.branch.code || '')
        })
      setRows(rows)
      setLastRefresh(new Date())
    } catch (e) {
      logger.error('CentralVaultDashboard', 'Load error:', e)
      setErr(e instanceof Error ? e.message : String(e))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void loadData()
    const id = setInterval(() => void loadData(), 60_000) // auto-refresh 1 perc
    return () => clearInterval(id)
  }, [])

  const offlineCount = rows.filter((r) => !r.online).length
  // FK-048 FR-1: a Készlet-riasztás szám CSAK a valódi, küszöb alatti riasztásokat számolja
  // (a stockAlert mostantól nem tartalmazza a STOCK UNKNOWN esetet).
  const alertCount = rows.filter((r) => r.stockAlert.length > 0).length

  // Group by region for display
  // FK-085 TBD-1 ellenőrzés (2026-08-17): a tábla sorai a /branches válaszából épülnek
  // (minden aktív fiók), a stock-snapshot CSAK készlet-összegeket ad hozzá; ezért egy
  // nem leképezhető régiójú fiók NEM tűnhet el a dashboardról — legfeljebb „nincs adat"
  // készlettel jelenik meg ebben a 'Régió nincs beállítva' fallback csoportban.
  const byRegion = rows.reduce<Record<string, BranchSummary[]>>((acc, r) => {
    const reg = r.branch.region || 'Régió nincs beállítva'
    if (!acc[reg]) acc[reg] = []
    acc[reg].push(r)
    return acc
  }, {})

  return (
    <div className="max-w-7xl mx-auto space-y-2">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-lg font-bold text-slate-800">
            {t('foertektar.foertektariDashboard')}
          </h1>
          <p className="text-xs text-slate-600">
            {t('foertektar.orszagosPenztarAllapotEsKeszletAutoRefresh1Percenkent')}
            {lastRefresh && (
              <span className="ml-2 text-slate-400">
                {t('foertektar.utolso')} {lastRefresh.toLocaleTimeString('hu-HU')}
              </span>
            )}
          </p>
        </div>
        <button
          type="button"
          onClick={() => void loadData()}
          disabled={loading}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
        >
          {loading ? 'Betöltés...' : 'Frissítés most'}
        </button>
      </div>

      {err && (
        <div className="bg-red-50 border-l-4 border-red-600 p-4 rounded">
          <p className="text-red-800 font-medium">
            {t('foertektar.hiba')}
            {err}
          </p>
        </div>
      )}

      {/* FK-048 FR-4/5: a /stock-snapshot lekérdezés hibája — látható, a STOCK UNKNOWN-tól
                egyértelműen megkülönböztethető hibajelzés (NEM csendes "nincs adat"). */}
      {stockUnavailable && (
        <div className="bg-orange-50 border-l-4 border-orange-500 p-4 rounded">
          <p className="text-orange-800 font-medium flex items-center gap-2">
            <AlertTriangle className="w-5 h-5" />
            {i18n.t('literals.a-keszletadatok-betoltese-sikertelen-a-k')}
          </p>
        </div>
      )}

      {/* FK-085 FR-4: a /cash-register/devices lekérdezés hibája — látható figyelmeztetés,
                hamis Soha/Offline státusz és Offline-összesítő helyett. */}
      {devicesUnavailable && (
        <div className="bg-orange-50 border-l-4 border-orange-500 p-4 rounded">
          <p className="text-orange-800 font-medium flex items-center gap-2">
            <AlertTriangle className="w-5 h-5" />
            {i18n.t('literals.a-penztargep-allapot-betoltese-sikertele')}
          </p>
        </div>
      )}

      {/* Summary cards */}
      <div className="grid grid-cols-3 gap-4">
        <SummaryCard
          icon={<Activity className="w-8 h-8" />}
          label="Összes pénztár"
          value={rows.length}
          color="blue"
        />
        <SummaryCard
          icon={<XCircle className="w-8 h-8" />}
          label="Offline (>10 perc)"
          value={devicesUnavailable ? '—' : offlineCount}
          color={devicesUnavailable ? 'slate' : offlineCount > 0 ? 'red' : 'green'}
          testId="offline-count"
        />
        <SummaryCard
          icon={<AlertTriangle className="w-8 h-8" />}
          label="Készlet-riasztás"
          value={stockUnavailable ? '—' : alertCount}
          color={stockUnavailable ? 'slate' : alertCount > 0 ? 'amber' : 'green'}
          testId="stock-alert-count"
        />
      </div>

      {/* Regions */}
      {loading && rows.length === 0 && (
        <div className="text-center text-slate-500 py-12">{i18n.t('literals.betoltes')}</div>
      )}
      {Object.entries(byRegion).map(([region, brs]) => (
        <div key={region} className="bg-white border border-slate-200 rounded-lg overflow-hidden">
          <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 flex items-center justify-between">
            <h2 className="font-bold text-slate-800 flex items-center gap-2">
              <MapPin className="w-5 h-5 text-slate-500" /> {region}
              <span className="text-sm font-normal text-slate-500">
                {i18n.t('literals.lit-19')}
                {brs.length} {t('foertektar.penztar')}
              </span>
            </h2>
          </div>
          <table className="w-full text-sm">
            <thead className="bg-slate-50">
              <tr className="text-left text-xs text-slate-600 uppercase">
                <th className="px-4 py-2">{t('common.code')}</th>
                <th className="px-4 py-2">{t('common.city')}</th>
                <th className="px-4 py-2">{t('common.status2')}</th>
                <th className="px-4 py-2">{t('foertektar.utolsoHeartbeat')}</th>
                <th className="px-4 py-2">{t('foertektar.keszletOtDeviza')}</th>
                <th className="px-4 py-2">{t('foertektar.riasztas')}</th>
              </tr>
            </thead>
            <tbody>
              {brs.map((r) => (
                <tr
                  key={r.branch.id}
                  className={`border-t border-slate-100 ${r.stockAlert.length > 0 || (!r.online && !devicesUnavailable) ? 'bg-red-50' : ''}`}
                >
                  <td className="px-4 py-2 font-mono font-bold">{r.branch.code}</td>
                  <td className="px-4 py-2">{r.branch.city || r.branch.name}</td>
                  <td className="px-4 py-2">
                    {devicesUnavailable ? (
                      <span className="inline-flex items-center gap-1 text-slate-500">
                        {i18n.t('literals.lit-8')}
                      </span>
                    ) : r.online ? (
                      <span className="inline-flex items-center gap-1 text-green-700">
                        <CheckCircle2 className="w-4 h-4" />
                        {t('common.online')}
                      </span>
                    ) : r.lastSeenMinutes === null ? (
                      <span className="inline-flex items-center gap-1 text-slate-500">
                        <XCircle className="w-4 h-4" />
                        {t('foertektar.sosem')}
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 text-red-700">
                        <XCircle className="w-4 h-4" />
                        {t('foertektar.offline')}
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-2 text-slate-600">
                    {r.lastSeenMinutes === null
                      ? '—'
                      : r.lastSeenMinutes < 60
                        ? `${r.lastSeenMinutes} perc`
                        : `${Math.floor(r.lastSeenMinutes / 60)} óra`}
                  </td>
                  <td className="px-4 py-2 text-slate-700">
                    {/* FK-048 FR-2: ha nincs készletadat, semleges "nincs adat" a KÉSZLET oszlopban */}
                    {r.hasStockData ? (
                      <div className="flex gap-3 text-xs">
                        <Stock
                          ccy="EUR"
                          amount={r.stocks['EUR'] ?? 0}
                          threshold={CRITICAL_THRESHOLDS['EUR'] ?? 500}
                        />
                        <Stock
                          ccy="USD"
                          amount={r.stocks['USD'] ?? 0}
                          threshold={CRITICAL_THRESHOLDS['USD'] ?? 500}
                        />
                        <Stock
                          ccy="GBP"
                          amount={r.stocks['GBP'] ?? 0}
                          threshold={CRITICAL_THRESHOLDS['GBP'] ?? 300}
                        />
                        <Stock
                          ccy="CHF"
                          amount={r.stocks['CHF'] ?? 0}
                          threshold={CRITICAL_THRESHOLDS['CHF'] ?? 300}
                        />
                        <Stock
                          ccy="HUF"
                          amount={r.stocks['HUF'] ?? 0}
                          threshold={CRITICAL_THRESHOLDS['HUF'] ?? 100000}
                        />
                      </div>
                    ) : (
                      <span className="text-slate-400 text-xs italic">
                        {i18n.t('literals.nincs-adat-2')}
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-2">
                    {/* FK-048 FR-2/3/5: valódi riasztás (piros) ↔ STOCK UNKNOWN (semleges) ↔ OK */}
                    {r.stockAlert.length > 0 ? (
                      <span className="text-red-700 text-xs font-medium flex items-center gap-1">
                        <AlertTriangle className="w-4 h-4" /> {r.stockAlert.join(', ')}
                      </span>
                    ) : !r.hasStockData ? (
                      <span className="text-slate-400 text-xs italic">
                        {i18n.t('literals.nincs-keszletadat')}
                      </span>
                    ) : (
                      <span className="text-green-700 text-xs">{i18n.t('literals.ok')}</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ))}
    </div>
  )
}

function SummaryCard({
  icon,
  label,
  value,
  color,
  testId,
}: {
  icon: React.ReactNode
  label: string
  value: number | string
  color: 'blue' | 'red' | 'green' | 'amber' | 'slate'
  testId?: string
}) {
  const colors = {
    blue: 'bg-blue-50 text-blue-800 border-blue-200',
    red: 'bg-red-50 text-red-800 border-red-200',
    green: 'bg-green-50 text-green-800 border-green-200',
    amber: 'bg-amber-50 text-amber-800 border-amber-200',
    slate: 'bg-slate-100 text-slate-600 border-slate-300',
  }
  return (
    <div className={`border rounded-lg p-4 flex items-center gap-3 ${colors[color]}`}>
      <div className="opacity-70">{icon}</div>
      <div>
        <div className="text-xs uppercase font-medium opacity-80">{label}</div>
        <div className="text-3xl font-bold" data-testid={testId}>
          {value}
        </div>
      </div>
    </div>
  )
}

function Stock({ ccy, amount, threshold }: { ccy: string; amount: number; threshold: number }) {
  const critical = amount < threshold
  return (
    <div
      className={`flex flex-col items-end ${critical ? 'text-red-700 font-bold' : 'text-slate-700'}`}
    >
      <span className="text-slate-500">{ccy}</span>
      <span>{amount.toLocaleString('hu-HU')}</span>
    </div>
  )
}
