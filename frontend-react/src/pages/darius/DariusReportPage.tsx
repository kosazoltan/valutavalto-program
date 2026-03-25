import { useState, useEffect, useCallback } from 'react'
import { FileSpreadsheet, CheckCircle, XCircle, Clock, RefreshCw, Send, ThumbsUp, AlertTriangle, Calendar } from 'lucide-react'
import { dariusApi, DariusDailyReport, DariusMonthlyDto } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'

type Tab = 'daily' | 'monthly' | 'missing'

const STATUS_LABELS: Record<string, { label: string; color: string; icon: typeof CheckCircle }> = {
  DRAFT: { label: 'Vázlat', color: 'bg-gray-100 text-gray-700', icon: Clock },
  GENERATED: { label: 'Generálva', color: 'bg-blue-100 text-blue-700', icon: FileSpreadsheet },
  SUBMITTED: { label: 'Beküldve', color: 'bg-yellow-100 text-yellow-700', icon: Send },
  ACKNOWLEDGED: { label: 'Visszaigazolva', color: 'bg-green-100 text-green-700', icon: CheckCircle },
  FAILED: { label: 'Sikertelen', color: 'bg-red-100 text-red-700', icon: XCircle },
}

function formatDate(d: string) { return d ? new Date(d).toLocaleDateString('hu-HU') : '—' }
function formatNum(n?: number) { return n != null ? n.toLocaleString('hu-HU') : '—' }

export default function DariusReportPage() {
  const [tab, setTab] = useState<Tab>('daily')
  const [dateFrom, setDateFrom] = useState(() => {
    const d = new Date(); d.setDate(1); return d.toISOString().slice(0, 10)
  })
  const [dateTo, setDateTo] = useState(() => new Date().toISOString().slice(0, 10))
  const [reports, setReports] = useState<DariusDailyReport[]>([])
  const [monthly, setMonthly] = useState<DariusMonthlyDto | null>(null)
  const [missingDates, setMissingDates] = useState<string[]>([])
  const [selected, setSelected] = useState<DariusDailyReport | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [generateDate, setGenerateDate] = useState(new Date().toISOString().slice(0, 10))

  const loadReports = useCallback(async () => {
    setLoading(true); setError('')
    try {
      const res = await dariusApi.getRange(dateFrom, dateTo)
      setReports(res.data)
    } catch (err) { setError(getErrorMessage(err)) }
    finally { setLoading(false) }
  }, [dateFrom, dateTo])

  const loadMonthly = useCallback(async () => {
    setLoading(true); setError('')
    try {
      const d = new Date(dateFrom)
      const res = await dariusApi.getMonthly(d.getFullYear(), d.getMonth() + 1)
      setMonthly(res.data)
    } catch (err) { setError(getErrorMessage(err)) }
    finally { setLoading(false) }
  }, [dateFrom])

  const loadMissing = useCallback(async () => {
    setLoading(true); setError('')
    try {
      const res = await dariusApi.getMissingDates(dateFrom, dateTo)
      setMissingDates(res.data)
    } catch (err) { setError(getErrorMessage(err)) }
    finally { setLoading(false) }
  }, [dateFrom, dateTo])

  useEffect(() => {
    if (tab === 'daily') loadReports()
    else if (tab === 'monthly') loadMonthly()
    else if (tab === 'missing') loadMissing()
  }, [tab, loadReports, loadMonthly, loadMissing])

  const handleGenerate = async () => {
    setLoading(true); setError('')
    try {
      const res = await dariusApi.generate(generateDate)
      setSelected(res.data)
      loadReports()
    } catch (err) { setError(getErrorMessage(err)) }
    finally { setLoading(false) }
  }

  const handleApprove = async (id: string) => {
    try {
      const res = await dariusApi.approve(id)
      setSelected(res.data); loadReports()
    } catch (err) { setError(getErrorMessage(err)) }
  }

  const handleSubmit = async (id: string) => {
    try {
      const res = await dariusApi.submit(id)
      setSelected(res.data); loadReports()
    } catch (err) { setError(getErrorMessage(err)) }
  }

  const handleRetry = async () => {
    try {
      await dariusApi.retryFailed()
      loadReports()
    } catch (err) { setError(getErrorMessage(err)) }
  }

  const StatusBadge = ({ status }: { status: string }) => {
    const s = STATUS_LABELS[status] ?? STATUS_LABELS.DRAFT!
    const Icon = s!.icon
    return <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${s!.color}`}><Icon size={12} />{s!.label}</span>
  }

  return (
    <div className="space-y-3">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileSpreadsheet /> Darius / Raiffeisen jelentések
        </h1>
        <div className="flex gap-2">
          <button onClick={handleRetry} className="btn-secondary text-xs flex items-center gap-1" title="Sikertelenek újraküldése">
            <RefreshCw size={14} /> Retry
          </button>
        </div>
      </div>

      {error && <div className="bg-red-50 border border-red-200 rounded p-2 text-red-700 text-sm flex items-center gap-2"><AlertTriangle size={16} />{error}</div>}

      {/* Tabs */}
      <div className="flex gap-1 border-b">
        {(['daily', 'monthly', 'missing'] as Tab[]).map(t => (
          <button key={t} onClick={() => setTab(t)}
            className={`px-3 py-1.5 text-sm font-medium border-b-2 -mb-px ${tab === t ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}>
            {t === 'daily' ? 'Napi' : t === 'monthly' ? 'Havi összesítő' : 'Hiányzó napok'}
          </button>
        ))}
      </div>

      {/* Filters */}
      <div className="flex gap-3 items-end">
        <div>
          <label className="text-xs text-gray-500">Dátum tól</label>
          <input type="date" value={dateFrom} onChange={e => setDateFrom(e.target.value)} className="input-field text-sm" />
        </div>
        <div>
          <label className="text-xs text-gray-500">Dátum ig</label>
          <input type="date" value={dateTo} onChange={e => setDateTo(e.target.value)} className="input-field text-sm" />
        </div>
        <div className="border-l pl-3 flex gap-2 items-end">
          <div>
            <label className="text-xs text-gray-500">Generálás dátuma</label>
            <input type="date" value={generateDate} onChange={e => setGenerateDate(e.target.value)} className="input-field text-sm" />
          </div>
          <button onClick={handleGenerate} disabled={loading} className="btn-primary text-sm flex items-center gap-1">
            <FileSpreadsheet size={14} /> Generálás
          </button>
        </div>
      </div>

      {/* Content */}
      {loading && <div className="text-center py-8 text-gray-400">Betöltés...</div>}

      {tab === 'daily' && !loading && (
        <div className="grid grid-cols-3 gap-3">
          {/* Report list */}
          <div className="col-span-2 space-y-1">
            {reports.length === 0 && <div className="text-gray-400 text-sm py-4 text-center">Nincs jelentés az időszakban</div>}
            {reports.map(r => (
              <div key={r.id} onClick={() => setSelected(r)}
                className={`p-3 rounded border cursor-pointer hover:bg-gray-50 transition ${selected?.id === r.id ? 'border-blue-400 bg-blue-50' : 'border-gray-200'}`}>
                <div className="flex justify-between items-center">
                  <div className="flex items-center gap-2">
                    <Calendar size={14} className="text-gray-400" />
                    <span className="font-medium text-sm">{formatDate(r.reportDate)}</span>
                    <StatusBadge status={r.status} />
                  </div>
                  <div className="text-xs text-gray-500">
                    {r.transactionCount} tx · {r.branchCount} iroda
                  </div>
                </div>
                <div className="flex gap-4 mt-1 text-xs text-gray-500">
                  <span>Vétel: {formatNum(r.totalBuyHuf)} Ft</span>
                  <span>Eladás: {formatNum(r.totalSellHuf)} Ft</span>
                  <span>Díj: {formatNum(r.totalHandlingFeeHuf)} Ft</span>
                </div>
              </div>
            ))}
          </div>

          {/* Detail panel */}
          <div className="space-y-2">
            {selected ? (
              <div className="p-3 border rounded space-y-2">
                <h3 className="font-medium text-sm">Részletek — {formatDate(selected.reportDate)}</h3>
                <div className="text-xs space-y-1">
                  <div>Státusz: <StatusBadge status={selected.status} /></div>
                  <div>Payload hash: <code className="text-[10px] bg-gray-100 px-1 rounded">{selected.payloadHash?.slice(0, 16)}...</code></div>
                  {selected.approvedBy && <div>Jóváhagyta: {selected.approvedBy} ({formatDate(selected.approvedAt || '')})</div>}
                  {selected.submittedBy && <div>Beküldte: {selected.submittedBy}</div>}
                  {selected.ackReference && <div>ACK ref: {selected.ackReference}</div>}
                  {selected.errorMessage && <div className="text-red-600">Hiba: {selected.errorMessage}</div>}
                  {selected.retryCount > 0 && <div>Retry: {selected.retryCount}/{selected.maxRetries}</div>}
                </div>

                {/* Actions */}
                <div className="flex gap-2 pt-2 border-t">
                  {selected.status === 'GENERATED' && !selected.approvedBy && (
                    <button onClick={() => handleApprove(selected.id)} className="btn-secondary text-xs flex items-center gap-1">
                      <ThumbsUp size={12} /> Jóváhagyás
                    </button>
                  )}
                  {(selected.status === 'GENERATED' || selected.status === 'FAILED') && selected.approvedBy && (
                    <button onClick={() => handleSubmit(selected.id)} className="btn-primary text-xs flex items-center gap-1">
                      <Send size={12} /> Beküldés
                    </button>
                  )}
                </div>

                {/* Lines */}
                {selected.lines && selected.lines.length > 0 && (
                  <div className="pt-2 border-t">
                    <h4 className="text-xs font-medium mb-1">Valuta sorok</h4>
                    <div className="max-h-60 overflow-y-auto">
                      <table className="w-full text-[10px]">
                        <thead className="bg-gray-50">
                          <tr>
                            <th className="text-left p-1">Iroda</th>
                            <th className="text-left p-1">Valuta</th>
                            <th className="text-right p-1">Vétel db</th>
                            <th className="text-right p-1">Eladás db</th>
                            <th className="text-right p-1">Vétel Ft</th>
                            <th className="text-right p-1">Eladás Ft</th>
                          </tr>
                        </thead>
                        <tbody>
                          {selected.lines.map(l => (
                            <tr key={l.id} className="border-t">
                              <td className="p-1">{l.branchCode}</td>
                              <td className="p-1 font-medium">{l.currencyCode}</td>
                              <td className="p-1 text-right">{l.buyCount}</td>
                              <td className="p-1 text-right">{l.sellCount}</td>
                              <td className="p-1 text-right">{formatNum(l.buyHufAmount)}</td>
                              <td className="p-1 text-right">{formatNum(l.sellHufAmount)}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                )}
              </div>
            ) : (
              <div className="text-gray-400 text-sm text-center py-8">Válasszon egy jelentést</div>
            )}
          </div>
        </div>
      )}

      {tab === 'monthly' && !loading && monthly && (
        <div className="space-y-3">
          <div className="grid grid-cols-4 gap-3">
            <div className="p-3 bg-blue-50 rounded border">
              <div className="text-xs text-gray-500">Összes jelentés</div>
              <div className="text-lg font-bold">{monthly.totalReports}</div>
            </div>
            <div className="p-3 bg-green-50 rounded border">
              <div className="text-xs text-gray-500">Visszaigazolt</div>
              <div className="text-lg font-bold text-green-700">{monthly.acknowledgedCount}</div>
            </div>
            <div className="p-3 bg-red-50 rounded border">
              <div className="text-xs text-gray-500">Sikertelen</div>
              <div className="text-lg font-bold text-red-700">{monthly.failedCount}</div>
            </div>
            <div className="p-3 bg-yellow-50 rounded border">
              <div className="text-xs text-gray-500">Függőben</div>
              <div className="text-lg font-bold text-yellow-700">{monthly.pendingCount}</div>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div className="p-3 border rounded">
              <div className="text-xs text-gray-500">Vétel összesen</div>
              <div className="font-bold">{formatNum(monthly.totalBuyHuf)} Ft</div>
            </div>
            <div className="p-3 border rounded">
              <div className="text-xs text-gray-500">Eladás összesen</div>
              <div className="font-bold">{formatNum(monthly.totalSellHuf)} Ft</div>
            </div>
            <div className="p-3 border rounded">
              <div className="text-xs text-gray-500">Kezelési díj összesen</div>
              <div className="font-bold">{formatNum(monthly.totalHandlingFeeHuf)} Ft</div>
            </div>
          </div>
        </div>
      )}

      {tab === 'missing' && !loading && (
        <div>
          {missingDates.length === 0 ? (
            <div className="text-green-600 text-sm flex items-center gap-2 py-4"><CheckCircle size={16} /> Nincs hiányzó nap az időszakban</div>
          ) : (
            <div className="space-y-1">
              <div className="text-sm text-red-600 font-medium">{missingDates.length} hiányzó nap:</div>
              <div className="flex flex-wrap gap-2">
                {missingDates.map(d => (
                  <button key={d} onClick={() => { setGenerateDate(d); handleGenerate() }}
                    className="px-2 py-1 text-xs bg-red-50 border border-red-200 rounded hover:bg-red-100 transition">
                    {formatDate(d)}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
