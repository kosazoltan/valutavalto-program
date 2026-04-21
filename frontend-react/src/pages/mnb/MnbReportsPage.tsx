import { useEffect, useState, useCallback } from 'react'
import { Download, Send, FileText, RefreshCw, AlertTriangle, CheckCircle2, Clock, XCircle, Plus } from 'lucide-react'
import { mnbReportsApi, type MnbReport, type MnbReportStatus } from '../../services/api/mnbReports'
import { logger } from '../../utils/logger'

const STATUS_LABELS: Record<MnbReportStatus, string> = {
    DRAFT: 'Vázlat',
    SUBMITTED: 'Beküldve',
    ACKNOWLEDGED: 'Elfogadva',
    REJECTED: 'Elutasítva',
}

const STATUS_COLORS: Record<MnbReportStatus, string> = {
    DRAFT: 'bg-amber-100 text-amber-800 border-amber-300',
    SUBMITTED: 'bg-blue-100 text-blue-800 border-blue-300',
    ACKNOWLEDGED: 'bg-green-100 text-green-800 border-green-300',
    REJECTED: 'bg-red-100 text-red-800 border-red-300',
}

export default function MnbReportsPage() {
    const [reports, setReports] = useState<MnbReport[]>([])
    const [loading, setLoading] = useState(true)
    const [err, setErr] = useState<string | null>(null)
    const [busyId, setBusyId] = useState<string | null>(null)
    const [generating, setGenerating] = useState(false)

    // Month picker for new report
    const today = new Date()
    const [genYear, setGenYear] = useState(today.getFullYear())
    const [genMonth, setGenMonth] = useState(today.getMonth() + 1)

    const loadReports = useCallback(async () => {
        setLoading(true)
        setErr(null)
        try {
            const data = await mnbReportsApi.list()
            setReports(data.sort((a, b) => (b.periodStart > a.periodStart ? 1 : -1)))
        } catch (e) {
            logger.error('MnbReports', 'list err', e)
            setErr(e instanceof Error ? e.message : String(e))
        } finally {
            setLoading(false)
        }
    }, [])

    useEffect(() => {
        void loadReports()
    }, [loadReports])

    const handleGenerate = async () => {
        setGenerating(true)
        setErr(null)
        try {
            const periodStart = `${genYear}-${String(genMonth).padStart(2, '0')}-01`
            // last day of month
            const lastDay = new Date(genYear, genMonth, 0).getDate()
            const periodEnd = `${genYear}-${String(genMonth).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`
            await mnbReportsApi.generate(periodStart, periodEnd)
            await loadReports()
        } catch (e) {
            setErr(e instanceof Error ? e.message : String(e))
        } finally {
            setGenerating(false)
        }
    }

    const handleSubmit = async (id: string) => {
        if (!confirm('Biztosan beküldöd a riportot az MNB-hez? Ez éles adatot küld.')) return
        setBusyId(id)
        try {
            await mnbReportsApi.submit(id)
            await loadReports()
        } catch (e) {
            setErr(e instanceof Error ? e.message : String(e))
        } finally {
            setBusyId(null)
        }
    }

    const handleDownload = async (r: MnbReport) => {
        setBusyId(r.id)
        try {
            const blob = await mnbReportsApi.downloadXml(r.id)
            const url = URL.createObjectURL(blob)
            const a = document.createElement('a')
            a.href = url
            a.download = `mnb-report-${r.periodStart}_${r.periodEnd}.xml`
            a.click()
            URL.revokeObjectURL(url)
        } catch (e) {
            setErr(e instanceof Error ? e.message : String(e))
        } finally {
            setBusyId(null)
        }
    }

    const statusIcon = (s: MnbReportStatus) => {
        if (s === 'ACKNOWLEDGED') return <CheckCircle2 className="w-3.5 h-3.5" />
        if (s === 'REJECTED') return <XCircle className="w-3.5 h-3.5" />
        if (s === 'SUBMITTED') return <Clock className="w-3.5 h-3.5" />
        return <FileText className="w-3.5 h-3.5" />
    }

    // year/month options
    const years = Array.from({ length: 5 }, (_, i) => today.getFullYear() - i)
    const months = Array.from({ length: 12 }, (_, i) => i + 1)

    return (
        <div className="p-6 max-w-7xl mx-auto space-y-6">
            <div>
                <h1 className="text-3xl font-bold text-slate-800">MNB jelentések</h1>
                <p className="text-sm text-slate-600 mt-1">
                    Havi pénzváltó forgalmi jelentés az MNB-nek. Generálás után ellenőrizd, majd kattints "Beküld"-re.
                </p>
            </div>

            {err && (
                <div className="bg-red-50 border-l-4 border-red-600 p-4 rounded flex items-start gap-3">
                    <AlertTriangle className="w-5 h-5 text-red-600 mt-0.5" />
                    <div>
                        <p className="text-red-800 font-medium">Hiba</p>
                        <p className="text-sm text-red-700 whitespace-pre-wrap">{err}</p>
                    </div>
                </div>
            )}

            {/* Generate new report */}
            <div className="bg-white border border-slate-200 rounded-lg p-4">
                <h2 className="font-bold text-slate-800 mb-3 flex items-center gap-2">
                    <Plus className="w-5 h-5" /> Új havi riport
                </h2>
                <div className="flex items-end gap-3">
                    <div>
                        <label className="block text-xs text-slate-600 mb-1" htmlFor="year">Év</label>
                        <select id="year" value={genYear} onChange={(e) => setGenYear(Number(e.target.value))} className="border border-slate-300 rounded px-3 py-2">
                            {years.map((y) => <option key={y} value={y}>{y}</option>)}
                        </select>
                    </div>
                    <div>
                        <label className="block text-xs text-slate-600 mb-1" htmlFor="month">Hónap</label>
                        <select id="month" value={genMonth} onChange={(e) => setGenMonth(Number(e.target.value))} className="border border-slate-300 rounded px-3 py-2">
                            {months.map((m) => <option key={m} value={m}>{m.toString().padStart(2, '0')}</option>)}
                        </select>
                    </div>
                    <button type="button" onClick={() => void handleGenerate()} disabled={generating}
                        className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50">
                        <Plus className="w-4 h-4" />
                        {generating ? 'Generálás...' : 'Generál'}
                    </button>
                    <button type="button" onClick={() => void loadReports()} disabled={loading}
                        className="flex items-center gap-2 px-3 py-2 bg-slate-100 text-slate-700 rounded hover:bg-slate-200 disabled:opacity-50">
                        <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
                        Frissítés
                    </button>
                </div>
            </div>

            {/* Report list */}
            {reports.length === 0 && !loading && (
                <div className="text-center text-slate-400 py-16">
                    <FileText className="w-12 h-12 mx-auto mb-3 opacity-40" />
                    <p>Még nincsenek riportok. Generálj egyet fenti form segítségével.</p>
                </div>
            )}

            {reports.length > 0 && (
                <div className="bg-white border border-slate-200 rounded-lg overflow-hidden">
                    <table className="w-full text-sm">
                        <thead className="bg-slate-50">
                            <tr className="text-left text-xs text-slate-600 uppercase">
                                <th className="px-4 py-3">Időszak</th>
                                <th className="px-4 py-3">Státusz</th>
                                <th className="px-4 py-3">MNB ref.</th>
                                <th className="px-4 py-3">Létrehozva</th>
                                <th className="px-4 py-3">Beküldve</th>
                                <th className="px-4 py-3 text-right">Művelet</th>
                            </tr>
                        </thead>
                        <tbody>
                            {reports.map((r) => (
                                <tr key={r.id} className={`border-t border-slate-100 hover:bg-slate-50 ${r.status === 'REJECTED' ? 'bg-red-50' : ''}`}>
                                    <td className="px-4 py-3 font-mono">{r.periodStart} — {r.periodEnd}</td>
                                    <td className="px-4 py-3">
                                        <span className={`inline-flex items-center gap-1 px-2 py-0.5 text-xs font-medium rounded border ${STATUS_COLORS[r.status]}`}>
                                            {statusIcon(r.status)} {STATUS_LABELS[r.status]}
                                        </span>
                                        {r.retryCount && r.retryCount > 0 && (
                                            <span className="ml-2 text-xs text-slate-500">×{r.retryCount} retry</span>
                                        )}
                                    </td>
                                    <td className="px-4 py-3 font-mono text-xs text-slate-600">{r.mnbReferenceNumber || '—'}</td>
                                    <td className="px-4 py-3 text-xs text-slate-500">{new Date(r.createdAt).toLocaleDateString('hu-HU')}</td>
                                    <td className="px-4 py-3 text-xs text-slate-500">{r.submittedAt ? new Date(r.submittedAt).toLocaleString('hu-HU') : '—'}</td>
                                    <td className="px-4 py-3 text-right">
                                        <div className="flex gap-1 justify-end">
                                            <button type="button" onClick={() => void handleDownload(r)} disabled={busyId === r.id}
                                                className="inline-flex items-center gap-1 px-3 py-1.5 bg-slate-100 text-slate-700 rounded text-xs hover:bg-slate-200 disabled:opacity-50">
                                                <Download className="w-3.5 h-3.5" />
                                                XML
                                            </button>
                                            {(r.status === 'DRAFT' || r.status === 'REJECTED') && (
                                                <button type="button" onClick={() => void handleSubmit(r.id)} disabled={busyId === r.id}
                                                    className="inline-flex items-center gap-1 px-3 py-1.5 bg-green-600 text-white rounded text-xs hover:bg-green-700 disabled:opacity-50">
                                                    <Send className="w-3.5 h-3.5" />
                                                    {busyId === r.id ? 'Küldés...' : 'Beküld'}
                                                </button>
                                            )}
                                        </div>
                                        {r.submissionError && (
                                            <div className="text-xs text-red-700 mt-1">{r.submissionError.slice(0, 60)}</div>
                                        )}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    )
}