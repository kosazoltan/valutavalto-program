import { useEffect, useState } from 'react'
import { Shield, AlertTriangle, Users, Clock, XCircle, FileText, RefreshCw } from 'lucide-react'
import { amlApi, RollingWindowAuditDto, AmlDailySummary, AmlReportDto } from '../../services/api/aml'
import { logger } from '../../utils/logger'

// ============================================================================
// Sprint 6.2 - Compliance Dashboard
//
// Pmt. (2017. LIII. tv.) + AML + Szankciós komplex osszesito feluletre.
// Celja: hatosagi ellenorzesek szempontjabol egybe gyujteni:
//  1. Overdue (lejárt hataridejű) bejelentesek - 2 munkanap utan
//  2. 8 napos rolling window feletti ugyfelek - 4.5M HUF alapertelmezett limit
//  3. Pending bejelentesek
//  4. Napi osszesito (mai nap)
// ============================================================================

export default function ComplianceDashboardPage() {
    const [today] = useState(() => new Date().toISOString().slice(0, 10))
    const [summary, setSummary] = useState<AmlDailySummary | null>(null)
    const [overdue, setOverdue] = useState<AmlReportDto[]>([])
    const [pending, setPending] = useState<AmlReportDto[]>([])
    const [rollingWindow, setRollingWindow] = useState<RollingWindowAuditDto[]>([])
    const [threshold, setThreshold] = useState<number>(4500000)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    const load = async () => {
        setLoading(true)
        setError(null)
        try {
            const [s, o, p, r] = await Promise.all([
                amlApi.dailySummary(today).catch(e => { logger.warn('compliance', 'summary error: ' + String(e)); return null }),
                amlApi.overdueReports().catch(e => { logger.warn('compliance', 'overdue error: ' + String(e)); return [] }),
                amlApi.pendingReports().catch(e => { logger.warn('compliance', 'pending error: ' + String(e)); return [] }),
                amlApi.rollingWindowAudit(threshold).catch(e => { logger.warn('compliance', 'rolling error: ' + String(e)); return [] }),
            ])
            setSummary(s)
            setOverdue(o)
            setPending(p)
            setRollingWindow(r)
        } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : String(err)
            setError(msg)
        } finally {
            setLoading(false)
        }
    }

    useEffect(() => {
        load()
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [today])

    const handleRollingRefresh = async () => {
        try {
            const r = await amlApi.rollingWindowAudit(threshold)
            setRollingWindow(r)
        } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : String(err)
            setError(msg)
        }
    }

    return (
        <div className="p-6 max-w-7xl mx-auto">
            <div className="flex items-center justify-between mb-6">
                <div>
                    <h1 className="text-2xl font-bold flex items-center gap-2">
                        <Shield className="w-7 h-7 text-blue-600" />
                        Compliance Dashboard
                    </h1>
                    <p className="text-gray-600 text-sm mt-1">
                        Pmt. (2017. LIII. tv.) + AML + Szankciós + 8 napos gördülő limit audit
                    </p>
                </div>
                <button
                    onClick={load}
                    className="flex items-center gap-1 px-3 py-2 border rounded hover:bg-gray-50"
                >
                    <RefreshCw className="w-4 h-4" />
                    Frissítés
                </button>
            </div>

            {error && (
                <div className="bg-red-50 border border-red-200 rounded p-3 mb-4 text-red-700 flex items-center gap-2">
                    <XCircle className="w-5 h-5" /> {error}
                </div>
            )}

            {loading ? (
                <div className="text-center text-gray-500 py-8">Toltodik...</div>
            ) : (
                <>
                    {/* KPI kartyak */}
                    <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
                        <div className="bg-red-50 border border-red-200 rounded p-4">
                            <div className="text-sm text-red-700 flex items-center gap-1">
                                <Clock className="w-4 h-4" /> OVERDUE bejelentések
                            </div>
                            <div className="text-3xl font-bold text-red-700 mt-1">{overdue.length}</div>
                            <div className="text-xs text-red-600 mt-1">2 munkanap után lejárt</div>
                        </div>
                        <div className="bg-yellow-50 border border-yellow-200 rounded p-4">
                            <div className="text-sm text-yellow-700 flex items-center gap-1">
                                <FileText className="w-4 h-4" /> Pending bejelentések
                            </div>
                            <div className="text-3xl font-bold mt-1">{pending.length}</div>
                            <div className="text-xs text-gray-600 mt-1">DRAFT / SUBMITTED</div>
                        </div>
                        <div className="bg-orange-50 border border-orange-200 rounded p-4">
                            <div className="text-sm text-orange-700 flex items-center gap-1">
                                <Users className="w-4 h-4" /> 8 napos limit
                            </div>
                            <div className="text-3xl font-bold mt-1">{rollingWindow.length}</div>
                            <div className="text-xs text-gray-600 mt-1">Ügyfél a küszöb fölött</div>
                        </div>
                        <div className="bg-blue-50 border border-blue-200 rounded p-4">
                            <div className="text-sm text-blue-700 flex items-center gap-1">
                                <AlertTriangle className="w-4 h-4" /> Mai gyanús
                            </div>
                            <div className="text-3xl font-bold mt-1">{summary?.suspiciousChecks ?? 0}</div>
                            <div className="text-xs text-gray-600 mt-1">{today}</div>
                        </div>
                    </div>

                    {/* OVERDUE tablazat */}
                    {overdue.length > 0 && (
                        <div className="bg-white shadow rounded overflow-hidden mb-6">
                            <div className="bg-red-100 px-4 py-2 text-red-900 font-semibold">
                                Lejárt határidejű bejelentések ({overdue.length})
                            </div>
                            <table className="w-full text-sm">
                                <thead className="bg-gray-50">
                                    <tr>
                                        <th className="px-4 py-2 text-left">Ügyfél</th>
                                        <th className="px-4 py-2 text-left">Tipus</th>
                                        <th className="px-4 py-2 text-right">Osszeg HUF</th>
                                        <th className="px-4 py-2 text-left">Hatarido</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {overdue.slice(0, 10).map(r => (
                                        <tr key={r.id} className="border-t">
                                            <td className="px-4 py-2">{r.customerName || r.customerId}</td>
                                            <td className="px-4 py-2">{r.reportType}</td>
                                            <td className="px-4 py-2 text-right font-mono">{r.amountHuf.toLocaleString('hu-HU')}</td>
                                            <td className="px-4 py-2 text-red-600">
                                                {r.deadlineAt && new Date(r.deadlineAt).toLocaleString('hu-HU')}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}

                    {/* Rolling window tablazat */}
                    <div className="bg-white shadow rounded overflow-hidden mb-6">
                        <div className="bg-orange-100 px-4 py-3 flex items-center justify-between">
                            <div className="text-orange-900 font-semibold">
                                8 napos gördülő limit feletti ügyfelek ({rollingWindow.length})
                            </div>
                            <div className="flex items-center gap-2">
                                <label className="text-sm">Küszöb (HUF):</label>
                                <input
                                    type="number"
                                    value={threshold}
                                    onChange={e => setThreshold(parseInt(e.target.value) || 4500000)}
                                    className="border rounded px-2 py-1 w-28 text-sm"
                                />
                                <button
                                    onClick={handleRollingRefresh}
                                    className="px-2 py-1 bg-orange-600 text-white rounded text-xs"
                                >
                                    Frissítés
                                </button>
                            </div>
                        </div>
                        {rollingWindow.length === 0 ? (
                            <div className="p-6 text-center text-gray-500 text-sm">Nincs ügyfél a küszöb felett</div>
                        ) : (
                            <table className="w-full text-sm">
                                <thead className="bg-gray-50">
                                    <tr>
                                        <th className="px-4 py-2 text-left">Ügyfél</th>
                                        <th className="px-4 py-2 text-right">8 napos osszeg</th>
                                        <th className="px-4 py-2 text-right">Kuszob%</th>
                                        <th className="px-4 py-2 text-center">High-risk flag</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {rollingWindow.map(r => (
                                        <tr key={r.customerId} className="border-t">
                                            <td className="px-4 py-2">
                                                <div className="font-medium">{r.customerName || r.customerId}</div>
                                                <div className="text-xs text-gray-500">{r.customerId}</div>
                                            </td>
                                            <td className="px-4 py-2 text-right font-mono">
                                                {r.rollingWindowTotalHuf.toLocaleString('hu-HU')}
                                            </td>
                                            <td className="px-4 py-2 text-right font-mono">
                                                {r.exceedPercent.toFixed(1)}%
                                            </td>
                                            <td className="px-4 py-2 text-center">
                                                {r.highRiskFlag ? (
                                                    <span className="px-2 py-1 bg-red-100 text-red-700 rounded text-xs">
                                                        MAGAS
                                                    </span>
                                                ) : (
                                                    <span className="text-gray-400 text-xs">-</span>
                                                )}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        )}
                    </div>

                    {/* Napi osszesito */}
                    {summary && (
                        <div className="bg-white shadow rounded overflow-hidden">
                            <div className="bg-blue-100 px-4 py-2 text-blue-900 font-semibold">
                                Mai nap összesítő ({summary.date})
                            </div>
                            <div className="grid grid-cols-4 gap-4 p-4">
                                <div>
                                    <div className="text-xs text-gray-600">Standard ellenőrzés</div>
                                    <div className="text-lg font-bold">{summary.standardChecks}</div>
                                </div>
                                <div>
                                    <div className="text-xs text-gray-600">Fokozott</div>
                                    <div className="text-lg font-bold">{summary.enhancedChecks}</div>
                                </div>
                                <div>
                                    <div className="text-xs text-gray-600">Gyanús</div>
                                    <div className="text-lg font-bold text-orange-600">{summary.suspiciousChecks}</div>
                                </div>
                                <div>
                                    <div className="text-xs text-gray-600">Összeg (HUF)</div>
                                    <div className="text-lg font-bold font-mono">
                                        {summary.totalAmountHuf.toLocaleString('hu-HU')}
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}
                </>
            )}
        </div>
    )
}