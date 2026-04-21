import { useEffect, useState, useCallback } from 'react'
import { CheckCircle2, Send, XCircle, RefreshCw, AlertTriangle, FileText, Users, Clock } from 'lucide-react'
import { exchangeRateMasterApi, type ExchangeRateMaster, type MasterRateStatus, type ExchangeRateDistribution } from '../../services/api/exchangeRateMaster'
import { logger } from '../../utils/logger'

// =============================================================================
// RateMasterWorkflowPage — Foertektari arfolyam-publikalas workflow
//
// 3 tab:
//   1. DRAFT    - arfolyam-tervek, "Approve" gomb
//   2. APPROVED - jovahagyott arfolyamok, "Publish" gomb (workgroup selector)
//   3. PUBLISHED - aktiv arfolyamok + elosztas-status (melyik penztar kapta meg)
// =============================================================================

type TabKey = 'DRAFT' | 'APPROVED' | 'PUBLISHED'

const STATUS_LABELS: Record<MasterRateStatus, string> = {
    DRAFT: 'Vázlat',
    APPROVED: 'Jóváhagyva',
    PUBLISHED: 'Publikálva',
    REVOKED: 'Visszavonva',
    ARCHIVED: 'Archív',
}

const STATUS_COLORS: Record<MasterRateStatus, string> = {
    DRAFT: 'bg-amber-100 text-amber-800 border-amber-300',
    APPROVED: 'bg-blue-100 text-blue-800 border-blue-300',
    PUBLISHED: 'bg-green-100 text-green-800 border-green-300',
    REVOKED: 'bg-red-100 text-red-800 border-red-300',
    ARCHIVED: 'bg-slate-100 text-slate-600 border-slate-300',
}

export default function RateMasterWorkflowPage() {
    const [activeTab, setActiveTab] = useState<TabKey>('DRAFT')
    const [rates, setRates] = useState<ExchangeRateMaster[]>([])
    const [loading, setLoading] = useState(true)
    const [err, setErr] = useState<string | null>(null)
    const [busyId, setBusyId] = useState<string | null>(null)
    const [expandedDistId, setExpandedDistId] = useState<string | null>(null)
    const [distData, setDistData] = useState<Record<string, ExchangeRateDistribution[]>>({})

    const loadRates = useCallback(async () => {
        setLoading(true)
        setErr(null)
        try {
            const data = await exchangeRateMasterApi.list(activeTab)
            setRates(data)
        } catch (e) {
            logger.error('RateMasterWorkflowPage', 'list err:', e)
            setErr(e instanceof Error ? e.message : String(e))
        } finally {
            setLoading(false)
        }
    }, [activeTab])

    useEffect(() => {
        void loadRates()
    }, [loadRates])

    const handleApprove = async (id: string) => {
        setBusyId(id)
        try {
            await exchangeRateMasterApi.approve(id)
            await loadRates()
        } catch (e) {
            setErr(e instanceof Error ? e.message : String(e))
        } finally {
            setBusyId(null)
        }
    }

    const handlePublish = async (id: string) => {
        setBusyId(id)
        try {
            await exchangeRateMasterApi.publish(id)
            await loadRates()
        } catch (e) {
            setErr(e instanceof Error ? e.message : String(e))
        } finally {
            setBusyId(null)
        }
    }

    const handleRevoke = async (id: string) => {
        if (!confirm('Biztosan visszavonod a publikált árfolyamot? A pénztárak a korábbira térnek vissza.')) return
        setBusyId(id)
        try {
            await exchangeRateMasterApi.revoke(id)
            await loadRates()
        } catch (e) {
            setErr(e instanceof Error ? e.message : String(e))
        } finally {
            setBusyId(null)
        }
    }

    const toggleDistribution = async (rateId: string) => {
        if (expandedDistId === rateId) {
            setExpandedDistId(null)
            return
        }
        setExpandedDistId(rateId)
        if (!distData[rateId]) {
            try {
                const dist = await exchangeRateMasterApi.getDistributionStatus(rateId)
                setDistData({ ...distData, [rateId]: dist })
            } catch (e) {
                logger.error('RateMasterWorkflowPage', 'dist err:', e)
            }
        }
    }

    return (
        <div className="p-6 max-w-7xl mx-auto space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold text-slate-800">Árfolyam publikálás</h1>
                    <p className="text-sm text-slate-600 mt-1">
                        Főértéktári workflow: vázlat → jóváhagyás → publikálás → pénztárak értesítése
                    </p>
                </div>
                <button
                    type="button"
                    onClick={() => void loadRates()}
                    disabled={loading}
                    className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
                >
                    <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
                    Frissítés
                </button>
            </div>

            {err && (
                <div className="bg-red-50 border-l-4 border-red-600 p-4 rounded flex items-start gap-3">
                    <AlertTriangle className="w-5 h-5 text-red-600 mt-0.5" />
                    <div>
                        <p className="text-red-800 font-medium">Hiba</p>
                        <p className="text-sm text-red-700">{err}</p>
                    </div>
                </div>
            )}

            {/* Tabs */}
            <div className="flex gap-2 border-b border-slate-200">
                {(['DRAFT', 'APPROVED', 'PUBLISHED'] as const).map((tab) => (
                    <button
                        key={tab}
                        type="button"
                        onClick={() => setActiveTab(tab)}
                        className={`px-6 py-3 font-medium transition border-b-2 ${
                            activeTab === tab
                                ? 'border-blue-600 text-blue-700'
                                : 'border-transparent text-slate-600 hover:text-slate-800'
                        }`}
                    >
                        {STATUS_LABELS[tab]} {rates.length > 0 && activeTab === tab && <span className="ml-2 text-xs bg-slate-200 rounded-full px-2 py-0.5">{rates.length}</span>}
                    </button>
                ))}
            </div>

            {/* Tab content */}
            {loading && rates.length === 0 && <div className="text-center text-slate-500 py-12">Betöltés...</div>}

            {!loading && rates.length === 0 && (
                <div className="text-center text-slate-400 py-16">
                    <FileText className="w-12 h-12 mx-auto mb-3 opacity-40" />
                    <p className="text-lg">Nincs {STATUS_LABELS[activeTab].toLowerCase()} árfolyam</p>
                    {activeTab === 'DRAFT' && <p className="text-sm mt-1">Új árfolyamot az Árfolyam készítés menüpontban készíthetsz</p>}
                </div>
            )}

            {rates.length > 0 && (
                <div className="bg-white border border-slate-200 rounded-lg overflow-hidden">
                    <table className="w-full text-sm">
                        <thead className="bg-slate-50">
                            <tr className="text-left text-xs text-slate-600 uppercase">
                                <th className="px-4 py-3">Deviza</th>
                                <th className="px-4 py-3">Vétel</th>
                                <th className="px-4 py-3">Eladás</th>
                                <th className="px-4 py-3">MNB</th>
                                <th className="px-4 py-3">Limit1 (V/E)</th>
                                <th className="px-4 py-3">Limit2 (V/E)</th>
                                <th className="px-4 py-3">Létrehozva</th>
                                <th className="px-4 py-3">Státusz</th>
                                <th className="px-4 py-3 text-right">Művelet</th>
                            </tr>
                        </thead>
                        <tbody>
                            {rates.map((r) => (
                                <>
                                    <tr key={r.id} className="border-t border-slate-100 hover:bg-slate-50">
                                        <td className="px-4 py-3 font-mono font-bold">{r.currencyCode || r.currencyId}</td>
                                        <td className="px-4 py-3 text-right font-mono">{r.baseBuyRate?.toLocaleString('hu-HU', { maximumFractionDigits: 2 })}</td>
                                        <td className="px-4 py-3 text-right font-mono">{r.baseSellRate?.toLocaleString('hu-HU', { maximumFractionDigits: 2 })}</td>
                                        <td className="px-4 py-3 text-right text-slate-500">{r.officialRate?.toLocaleString('hu-HU', { maximumFractionDigits: 2 }) || '—'}</td>
                                        <td className="px-4 py-3 text-xs text-slate-600">
                                            {r.limit1Amount ? (
                                                <>
                                                    <div>{r.limit1Amount?.toLocaleString('hu-HU')}</div>
                                                    <div className="text-slate-400">{r.limit1BuyRate?.toLocaleString('hu-HU', { maximumFractionDigits: 2 })} / {r.limit1SellRate?.toLocaleString('hu-HU', { maximumFractionDigits: 2 })}</div>
                                                </>
                                            ) : '—'}
                                        </td>
                                        <td className="px-4 py-3 text-xs text-slate-600">
                                            {r.limit2Amount ? (
                                                <>
                                                    <div>{r.limit2Amount?.toLocaleString('hu-HU')}</div>
                                                    <div className="text-slate-400">{r.limit2BuyRate?.toLocaleString('hu-HU', { maximumFractionDigits: 2 })} / {r.limit2SellRate?.toLocaleString('hu-HU', { maximumFractionDigits: 2 })}</div>
                                                </>
                                            ) : '—'}
                                        </td>
                                        <td className="px-4 py-3 text-xs text-slate-500">
                                            <div className="flex items-center gap-1"><Clock className="w-3 h-3" />{new Date(r.createdAt).toLocaleString('hu-HU')}</div>
                                        </td>
                                        <td className="px-4 py-3">
                                            <span className={`inline-block px-2 py-0.5 text-xs font-medium rounded border ${STATUS_COLORS[r.status]}`}>
                                                {STATUS_LABELS[r.status]}
                                            </span>
                                        </td>
                                        <td className="px-4 py-3 text-right">
                                            {activeTab === 'DRAFT' && (
                                                <button type="button" onClick={() => void handleApprove(r.id)} disabled={busyId === r.id}
                                                    className="inline-flex items-center gap-1 px-3 py-1.5 bg-blue-600 text-white rounded text-xs hover:bg-blue-700 disabled:opacity-50">
                                                    <CheckCircle2 className="w-3.5 h-3.5" />
                                                    {busyId === r.id ? 'Folyamatban...' : 'Jóváhagy'}
                                                </button>
                                            )}
                                            {activeTab === 'APPROVED' && (
                                                <button type="button" onClick={() => void handlePublish(r.id)} disabled={busyId === r.id}
                                                    className="inline-flex items-center gap-1 px-3 py-1.5 bg-green-600 text-white rounded text-xs hover:bg-green-700 disabled:opacity-50">
                                                    <Send className="w-3.5 h-3.5" />
                                                    {busyId === r.id ? 'Publikálás...' : 'Publikál'}
                                                </button>
                                            )}
                                            {activeTab === 'PUBLISHED' && (
                                                <div className="flex gap-1 justify-end">
                                                    <button type="button" onClick={() => void toggleDistribution(r.id)}
                                                        className="inline-flex items-center gap-1 px-3 py-1.5 bg-slate-100 text-slate-700 rounded text-xs hover:bg-slate-200">
                                                        <Users className="w-3.5 h-3.5" />
                                                        {expandedDistId === r.id ? 'Elrejt' : 'Elosztás'}
                                                    </button>
                                                    <button type="button" onClick={() => void handleRevoke(r.id)} disabled={busyId === r.id}
                                                        className="inline-flex items-center gap-1 px-3 py-1.5 bg-red-50 text-red-700 rounded text-xs hover:bg-red-100 disabled:opacity-50">
                                                        <XCircle className="w-3.5 h-3.5" />
                                                        Visszavon
                                                    </button>
                                                </div>
                                            )}
                                        </td>
                                    </tr>
                                    {expandedDistId === r.id && (() => {
                                        const dists = distData[r.id];
                                        return (
                                        <tr key={r.id + '-dist'}>
                                            <td colSpan={9} className="bg-slate-50 px-4 py-3">
                                                <div className="text-xs font-medium text-slate-700 mb-2">Elosztás státusz ({dists?.length ?? 0} pénztár):</div>
                                                {!dists && <div className="text-slate-500">Betöltés...</div>}
                                                {dists && dists.length === 0 && <div className="text-slate-500">Nincs elosztás rekord</div>}
                                                {dists && dists.length > 0 && (
                                                    <div className="grid grid-cols-4 gap-2">
                                                        {dists.map((d) => (
                                                            <div key={d.id} className={`text-xs p-2 rounded border ${
                                                                d.status === 'ACKNOWLEDGED' ? 'bg-green-50 border-green-300 text-green-800' :
                                                                d.status === 'DISTRIBUTED' ? 'bg-blue-50 border-blue-300 text-blue-800' :
                                                                d.status === 'PENDING' ? 'bg-amber-50 border-amber-300 text-amber-800' :
                                                                'bg-red-50 border-red-300 text-red-800'
                                                            }`}>
                                                                <div className="font-mono font-bold">{d.branchCode || d.branchId.slice(0, 8)}</div>
                                                                <div className="text-xs opacity-75">{d.branchName}</div>
                                                                <div className="mt-1 text-xxs">{d.status}</div>
                                                            </div>
                                                        ))}
                                                    </div>
                                                )}
                                            </td>
                                        </tr>
                                        );
                                    })()}
                                </>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    )
}