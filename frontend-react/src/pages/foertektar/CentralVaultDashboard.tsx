import { useEffect, useState } from 'react'
import { Activity, AlertTriangle, CheckCircle2, MapPin, XCircle } from 'lucide-react'
import { api } from '../../services/api/client'
import { logger } from '../../utils/logger'

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
}

// Fix 2026-04-24: backend /api/v1/stock-snapshot response shape (StockSnapshotDto)
// AI review (Codex PR #183 P2): null safety + unmapped region-code branches fallback
interface CurrencyDetail { currencyCode: string; stock: number }
interface BackendBranch { branchId: string; currencies: CurrencyDetail[] }
interface BackendRegion { regionCode?: string; branches: BackendBranch[] }
interface StockSnapshotResponse { regions?: BackendRegion[]; companyTotals?: unknown }

/**
 * Lapoz a hierarchikus StockSnapshotDto-t flat StockRow[]-ba.
 *
 * Codex P2 #183 javitas: ha a backend regions listan kivul keveri egyes branch-eket
 * a companyTotals-ba (pl. ismeretlen region_code), a flatten nem vesz rajuk
 * figyelembe -> a branch-nek nem lesz "stocks" rekordja, igy a dashboard
 * CRITICAL threshold alert hibasan piros lesz rajta. A missing branch-eket
 * `null`-koent jelezzuk: a dashboard logika a feltetelt atadja, fallback nelkul
 * csak a "stockAlert empty" marad -> NEM false-positive alert.
 */
function flattenStockSnapshot(snap: StockSnapshotResponse | null): StockRow[] {
    if (!snap?.regions) return []
    const rows: StockRow[] = []
    for (const region of snap.regions) {
        for (const branch of region?.branches ?? []) {
            if (!branch?.branchId) continue  // defensive
            for (const cur of branch?.currencies ?? []) {
                if (!cur?.currencyCode) continue
                rows.push({ branchId: branch.branchId, currencyCode: cur.currencyCode, amount: cur.stock ?? 0 })
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
    stockAlert: string[]  // e.g. "EUR < 500"
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
    const [rows, setRows] = useState<BranchSummary[]>([])
    const [loading, setLoading] = useState(true)
    const [err, setErr] = useState<string | null>(null)
    const [lastRefresh, setLastRefresh] = useState<Date | null>(null)

    const loadData = async () => {
        setLoading(true)
        setErr(null)
        try {
            const [branchesRes, devicesRes, stocksRes] = await Promise.all([
                api.get<Branch[]>('/branches'),
                api.get<CashRegisterDevice[]>('/cash-register/devices').catch(() => ({ data: [] as CashRegisterDevice[] })),
                // Fix 2026-04-24: /stock-snapshot (nem /current) + hierarchikus response flatten
                api.get<StockSnapshotResponse>('/stock-snapshot').catch(() => ({ data: null as StockSnapshotResponse | null })),
            ])
            const branches = branchesRes.data || []
            const devices = devicesRes.data || []
            const stocks = flattenStockSnapshot(stocksRes.data ?? null)
            const now = Date.now()

            const rows: BranchSummary[] = branches
                .filter((b) => b.isActive !== false)
                .map((b) => {
                    const device = devices.find((d) => d.branchId === b.id)
                    const branchStocks: Record<string, number> = {}
                    stocks.filter((s) => s.branchId === b.id).forEach((s) => {
                        branchStocks[s.currencyCode] = (branchStocks[s.currencyCode] || 0) + (s.amount || 0)
                    })
                    // Codex PR #183 P2: csak ha a branch-nek VAN legalabb 1 stock rekord a snapshot-ban,
                    // akkor ertekeljuk a CRITICAL threshold-okat. Ha nincs adat (unmapped region),
                    // NE dobjunk false-positive alert-et.
                    const hasStockData = Object.keys(branchStocks).length > 0
                    const stockAlert: string[] = []
                    if (hasStockData) {
                        for (const [ccy, threshold] of Object.entries(CRITICAL_THRESHOLDS)) {
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
        const id = setInterval(() => void loadData(), 60_000)  // auto-refresh 1 perc
        return () => clearInterval(id)
    }, [])

    const offlineCount = rows.filter((r) => !r.online).length
    const alertCount = rows.filter((r) => r.stockAlert.length > 0).length

    // Group by region for display
    const byRegion = rows.reduce<Record<string, BranchSummary[]>>((acc, r) => {
        const reg = r.branch.region || '(Ismeretlen)'
        if (!acc[reg]) acc[reg] = []
        acc[reg].push(r)
        return acc
    }, {})

    return (
        <div className="p-6 max-w-7xl mx-auto space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold text-slate-800">Főértéktári dashboard</h1>
                    <p className="text-sm text-slate-600 mt-1">
                        Országos pénztár-állapot és készlet — auto-refresh 1 percenként
                        {lastRefresh && <span className="ml-2 text-slate-400">Utolsó: {lastRefresh.toLocaleTimeString('hu-HU')}</span>}
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
                    <p className="text-red-800 font-medium">Hiba: {err}</p>
                </div>
            )}

            {/* Summary cards */}
            <div className="grid grid-cols-3 gap-4">
                <SummaryCard icon={<Activity className="w-8 h-8" />} label="Összes pénztár" value={rows.length} color="blue" />
                <SummaryCard icon={<XCircle className="w-8 h-8" />} label="Offline (>10 perc)" value={offlineCount} color={offlineCount > 0 ? 'red' : 'green'} />
                <SummaryCard icon={<AlertTriangle className="w-8 h-8" />} label="Készlet-riasztás" value={alertCount} color={alertCount > 0 ? 'amber' : 'green'} />
            </div>

            {/* Regions */}
            {loading && rows.length === 0 && <div className="text-center text-slate-500 py-12">Betöltés...</div>}
            {Object.entries(byRegion).map(([region, brs]) => (
                <div key={region} className="bg-white border border-slate-200 rounded-lg overflow-hidden">
                    <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 flex items-center justify-between">
                        <h2 className="font-bold text-slate-800 flex items-center gap-2">
                            <MapPin className="w-5 h-5 text-slate-500" /> {region}
                            <span className="text-sm font-normal text-slate-500">({brs.length} pénztár)</span>
                        </h2>
                    </div>
                    <table className="w-full text-sm">
                        <thead className="bg-slate-50">
                            <tr className="text-left text-xs text-slate-600 uppercase">
                                <th className="px-4 py-2">Kód</th>
                                <th className="px-4 py-2">Város</th>
                                <th className="px-4 py-2">Állapot</th>
                                <th className="px-4 py-2">Utolsó heartbeat</th>
                                <th className="px-4 py-2">Készlet (EUR / USD / HUF)</th>
                                <th className="px-4 py-2">Riasztás</th>
                            </tr>
                        </thead>
                        <tbody>
                            {brs.map((r) => (
                                <tr key={r.branch.id} className={`border-t border-slate-100 ${r.stockAlert.length > 0 || !r.online ? 'bg-red-50' : ''}`}>
                                    <td className="px-4 py-2 font-mono font-bold">{r.branch.code}</td>
                                    <td className="px-4 py-2">{r.branch.city || r.branch.name}</td>
                                    <td className="px-4 py-2">
                                        {r.online ? (
                                            <span className="inline-flex items-center gap-1 text-green-700"><CheckCircle2 className="w-4 h-4" /> Online</span>
                                        ) : r.lastSeenMinutes === null ? (
                                            <span className="inline-flex items-center gap-1 text-slate-500"><XCircle className="w-4 h-4" /> Sosem</span>
                                        ) : (
                                            <span className="inline-flex items-center gap-1 text-red-700"><XCircle className="w-4 h-4" /> Offline</span>
                                        )}
                                    </td>
                                    <td className="px-4 py-2 text-slate-600">{r.lastSeenMinutes === null ? '—' : r.lastSeenMinutes < 60 ? `${r.lastSeenMinutes} perc` : `${Math.floor(r.lastSeenMinutes / 60)} óra`}</td>
                                    <td className="px-4 py-2 text-slate-700">
                                        <div className="flex gap-3 text-xs">
                                            <Stock ccy="EUR" amount={r.stocks['EUR'] ?? 0} threshold={CRITICAL_THRESHOLDS['EUR'] ?? 500} />
                                            <Stock ccy="USD" amount={r.stocks['USD'] ?? 0} threshold={CRITICAL_THRESHOLDS['USD'] ?? 500} />
                                            <Stock ccy="HUF" amount={r.stocks['HUF'] ?? 0} threshold={CRITICAL_THRESHOLDS['HUF'] ?? 100000} />
                                        </div>
                                    </td>
                                    <td className="px-4 py-2">
                                        {r.stockAlert.length > 0 ? (
                                            <span className="text-red-700 text-xs font-medium flex items-center gap-1">
                                                <AlertTriangle className="w-4 h-4" /> {r.stockAlert.join(', ')}
                                            </span>
                                        ) : (
                                            <span className="text-green-700 text-xs">OK</span>
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

function SummaryCard({ icon, label, value, color }: { icon: React.ReactNode; label: string; value: number; color: 'blue' | 'red' | 'green' | 'amber' }) {
    const colors = {
        blue: 'bg-blue-50 text-blue-800 border-blue-200',
        red: 'bg-red-50 text-red-800 border-red-200',
        green: 'bg-green-50 text-green-800 border-green-200',
        amber: 'bg-amber-50 text-amber-800 border-amber-200',
    }
    return (
        <div className={`border rounded-lg p-4 flex items-center gap-3 ${colors[color]}`}>
            <div className="opacity-70">{icon}</div>
            <div>
                <div className="text-xs uppercase font-medium opacity-80">{label}</div>
                <div className="text-3xl font-bold">{value}</div>
            </div>
        </div>
    )
}

function Stock({ ccy, amount, threshold }: { ccy: string; amount: number; threshold: number }) {
    const critical = amount < threshold
    return (
        <div className={`flex flex-col items-end ${critical ? 'text-red-700 font-bold' : 'text-slate-700'}`}>
            <span className="text-slate-500">{ccy}</span>
            <span>{amount.toLocaleString('hu-HU')}</span>
        </div>
    )
}