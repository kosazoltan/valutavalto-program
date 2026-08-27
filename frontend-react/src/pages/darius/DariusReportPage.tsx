import { useState, useEffect, useCallback } from 'react'
import {
  FileSpreadsheet,
  CheckCircle,
  XCircle,
  Clock,
  RefreshCw,
  Send,
  ThumbsUp,
  AlertTriangle,
  Calendar,
} from 'lucide-react'
import { dariusApi, DariusDailyReport, DariusMonthlyDto } from '../../services/api/index'
import { downloadBlob } from '../../utils/downloadBlob'
import { getBlobErrorMessage, getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { localIsoDate } from '../../utils/dateFormat'
import { filenameFromContentDisposition } from '../../utils/contentDisposition'
import { useTranslation } from 'react-i18next'
import DariusFixingPanel from './DariusFixingPanel'
import i18n from '../../i18n'

type Tab = 'daily' | 'monthly' | 'missing' | 'fixing'

const TAB_LABELS: Record<Tab, string> = {
  daily: 'Napi',
  monthly: 'Havi összesítő',
  missing: 'Hiányzó napok',
  fixing: 'Fixing igények',
}

const STATUS_LABELS: Record<string, { label: string; color: string; icon: typeof CheckCircle }> = {
  DRAFT: { label: 'Vázlat', color: 'bg-gray-100 text-gray-700', icon: Clock },
  GENERATED: { label: 'Generálva', color: 'bg-blue-100 text-blue-700', icon: FileSpreadsheet },
  SUBMITTED: { label: 'Beküldve', color: 'bg-yellow-100 text-yellow-700', icon: Send },
  ACKNOWLEDGED: {
    label: 'Visszaigazolva',
    color: 'bg-green-100 text-green-700',
    icon: CheckCircle,
  },
  FAILED: { label: 'Sikertelen', color: 'bg-red-100 text-red-700', icon: XCircle },
}

function formatDate(d: string) {
  return d ? new Date(d).toLocaleDateString('hu-HU') : '—'
}
function formatNum(n?: number) {
  return n != null ? n.toLocaleString('hu-HU') : '—'
}

export default function DariusReportPage() {
  const { t } = useTranslation()
  const [tab, setTab] = useState<Tab>('daily')
  const [dateFrom, setDateFrom] = useState(() => {
    const d = new Date()
    d.setDate(1)
    return localIsoDate(d)
  })
  const [dateTo, setDateTo] = useState(() => localIsoDate())
  const [reports, setReports] = useState<DariusDailyReport[]>([])
  const [monthly, setMonthly] = useState<DariusMonthlyDto | null>(null)
  const [missingDates, setMissingDates] = useState<string[]>([])
  const [selected, setSelected] = useState<DariusDailyReport | null>(null)
  const [loading, setLoading] = useState(false)
  const [importDownloading, setImportDownloading] = useState(false)
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)
  const [error, setError] = useState('')
  const [generateDate, setGenerateDate] = useState(localIsoDate())
  const [erteknap, setErteknap] = useState(0)
  const [ackReference, setAckReference] = useState('')
  const [ackSaving, setAckSaving] = useState(false)

  const loadReports = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const res = await dariusApi.getRange(dateFrom, dateTo)
      setReports(safeArray<DariusDailyReport>(res?.data))
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [dateFrom, dateTo])

  const loadMonthly = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const d = new Date(dateFrom)
      const res = await dariusApi.getMonthly(d.getFullYear(), d.getMonth() + 1)
      setMonthly(res.data)
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [dateFrom])

  const loadMissing = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const res = await dariusApi.getMissingDates(dateFrom, dateTo)
      setMissingDates(safeArray<string>(res?.data))
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [dateFrom, dateTo])

  useEffect(() => {
    if (tab === 'daily') loadReports()
    else if (tab === 'monthly') loadMonthly()
    else if (tab === 'missing') loadMissing()
  }, [tab, loadReports, loadMonthly, loadMissing])

  const handleGenerate = async () => {
    setLoading(true)
    setError('')
    try {
      const res = await dariusApi.generate(generateDate)
      setSelected(res.data)
      setAckReference(res.data.ackReference || '')
      loadReports()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  const handleLoadByDate = async () => {
    setLoading(true)
    setError('')
    try {
      const res = await dariusApi.getByDate(generateDate)
      setSelected(res.data)
      setAckReference(res.data.ackReference || '')
      setTab('daily')
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  const handleDownloadImportFile = async () => {
    setImportDownloading(true)
    setError('')
    try {
      const res = await dariusApi.downloadImportFile(generateDate, erteknap)
      const serverName = filenameFromContentDisposition(
        res.headers?.['content-disposition'] as string | undefined,
      )
      downloadBlob(res.data, serverName ?? `raiffeisen_import_${generateDate}.imp`)
    } catch (err) {
      setError(await getBlobErrorMessage(err))
    } finally {
      setImportDownloading(false)
    }
  }

  const handleSelectReport = async (report: DariusDailyReport) => {
    setDetailLoadingId(report.id)
    setError('')
    try {
      const res = await dariusApi.getById(report.id)
      setSelected(res.data)
      setAckReference(res.data.ackReference || '')
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setDetailLoadingId(null)
    }
  }

  const handleApprove = async (id: string) => {
    try {
      const res = await dariusApi.approve(id)
      setSelected(res.data)
      setAckReference(res.data.ackReference || '')
      loadReports()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const handleSubmit = async (id: string) => {
    try {
      const res = await dariusApi.submit(id)
      setSelected(res.data)
      setAckReference(res.data.ackReference || '')
      loadReports()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const handleAcknowledge = async (id: string) => {
    const ref = ackReference.trim()
    if (!ref) {
      setError('A visszaigazolási referencia megadása kötelező.')
      return
    }
    setAckSaving(true)
    setError('')
    try {
      const res = await dariusApi.acknowledge(id, ref)
      setSelected(res.data)
      setAckReference(res.data.ackReference || '')
      loadReports()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setAckSaving(false)
    }
  }

  const handleRetry = async () => {
    try {
      await dariusApi.retryFailed()
      loadReports()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const StatusBadge = ({ status }: { status: string }) => {
    const s = STATUS_LABELS[status] ?? STATUS_LABELS.DRAFT!
    const Icon = s!.icon
    return (
      <span
        className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${s!.color}`}
      >
        <Icon size={12} />
        {s!.label}
      </span>
    )
  }

  return (
    <div className="space-y-3">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileSpreadsheet />
          {t('darius.dariusRaiffeisenJelentesek')}
        </h1>
        <div className="flex gap-2">
          <button
            onClick={handleRetry}
            className="btn-secondary text-xs flex items-center gap-1"
            title="Sikertelenek újraküldése"
          >
            <RefreshCw size={14} />
            {t('darius.retry')}
          </button>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-2 text-red-700 text-sm flex items-center gap-2">
          <AlertTriangle size={16} />
          {error}
        </div>
      )}

      {/* Tabs */}
      <div className="flex gap-1 border-b">
        {(Object.keys(TAB_LABELS) as Tab[]).map((tabKey) => (
          <button
            key={tabKey}
            onClick={() => setTab(tabKey)}
            className={`px-3 py-1.5 text-sm font-medium border-b-2 -mb-px ${tab === tabKey ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700'}`}
          >
            {TAB_LABELS[tabKey]}
          </button>
        ))}
      </div>

      {/* Filters */}
      <div className="flex gap-3 items-end">
        <div>
          <label className="text-xs text-gray-500">{t('darius.datumTol')}</label>
          <input
            type="date"
            value={dateFrom}
            onChange={(e) => setDateFrom(e.target.value)}
            className="input-field text-sm"
          />
        </div>
        <div>
          <label className="text-xs text-gray-500">{t('darius.datumIg')}</label>
          <input
            type="date"
            value={dateTo}
            onChange={(e) => setDateTo(e.target.value)}
            className="input-field text-sm"
          />
        </div>
        <div className="border-l pl-3 flex gap-2 items-end">
          <div>
            <label className="text-xs text-gray-500">{t('darius.generalasDatuma')}</label>
            <input
              type="date"
              value={generateDate}
              onChange={(e) => setGenerateDate(e.target.value)}
              className="input-field text-sm"
            />
          </div>
          <button
            type="button"
            onClick={handleLoadByDate}
            disabled={loading}
            className="btn-secondary text-sm flex items-center gap-1"
          >
            <Calendar size={14} />
            {i18n.t('literals.napi-lekerdezes')}
          </button>
          <button
            onClick={handleGenerate}
            disabled={loading}
            className="btn-primary text-sm flex items-center gap-1"
          >
            <FileSpreadsheet size={14} />
            {t('darius.generalas')}
          </button>
          <label className="flex items-center gap-1 text-sm text-gray-600">
            {i18n.t('literals.erteknap-t-n')}
            <input
              type="number"
              min={-200}
              max={200}
              value={erteknap}
              onChange={(e) =>
                setErteknap(Math.max(-200, Math.min(200, Number(e.target.value) || 0)))
              }
              className="w-20 border rounded px-2 py-1"
              aria-label="Értéknap (T+N)"
            />
          </label>
          <button
            type="button"
            onClick={handleDownloadImportFile}
            disabled={loading || importDownloading}
            className="btn-secondary text-sm flex items-center gap-1"
          >
            <FileSpreadsheet size={14} />
            {importDownloading ? 'Import fájl letöltése...' : 'Import fájl letöltése (.imp)'}
          </button>
        </div>
      </div>

      {/* Content */}
      {loading && (
        <div className="text-center py-8 text-gray-400">{i18n.t('literals.betoltes')}</div>
      )}

      {tab === 'daily' && !loading && (
        <div className="grid grid-cols-3 gap-3">
          {/* Report list */}
          <div className="col-span-2 space-y-1">
            {reports.length === 0 && (
              <div className="text-gray-400 text-sm py-4 text-center">
                {t('darius.nincsJelentesAzIdoszakban')}
              </div>
            )}
            {reports.map((r) => (
              <div
                key={r.id}
                data-testid={`darius-report-${r.id}`}
                role="button"
                tabIndex={0}
                onClick={() => handleSelectReport(r)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault()
                    handleSelectReport(r)
                  }
                }}
                className={`p-3 rounded border cursor-pointer hover:bg-gray-50 transition ${selected?.id === r.id ? 'border-blue-400 bg-blue-50' : 'border-gray-200'}`}
              >
                <div className="flex justify-between items-center">
                  <div className="flex items-center gap-2">
                    <Calendar size={14} className="text-gray-400" />
                    <span className="font-medium text-sm">{formatDate(r.reportDate)}</span>
                    <StatusBadge status={r.status} />
                  </div>
                  <div className="text-xs text-gray-500">
                    {r.transactionCount} {t('darius.tx')} {r.branchCount} {t('common.iroda')}
                  </div>
                </div>
                <div className="flex gap-4 mt-1 text-xs text-gray-500">
                  <span>
                    {t('darius.vetel')}
                    {formatNum(r.totalBuyHuf)} {t('components.ft')}
                  </span>
                  <span>
                    {t('darius.eladas')}
                    {formatNum(r.totalSellHuf)} {t('components.ft')}
                  </span>
                  <span>
                    {t('darius.dij')}
                    {formatNum(r.totalHandlingFeeHuf)} {t('components.ft')}
                  </span>
                </div>
                {detailLoadingId === r.id && (
                  <div className="mt-1 text-xs text-blue-600">
                    {i18n.t('literals.reszletek-betoltese-2')}
                  </div>
                )}
              </div>
            ))}
          </div>

          {/* Detail panel */}
          <div className="space-y-2">
            {selected ? (
              <div className="p-3 border rounded space-y-2">
                <h3 className="font-medium text-sm">
                  {t('darius.reszletek')}
                  {formatDate(selected.reportDate)}
                </h3>
                <div className="text-xs space-y-1">
                  <div>
                    {t('darius.statusz')}
                    <StatusBadge status={selected.status} />
                  </div>
                  <div>
                    {t('darius.payloadHash')}
                    <code className="text-[10px] bg-gray-100 px-1 rounded">
                      {selected.payloadHash?.slice(0, 16)}
                      {i18n.t('literals.lit-16')}
                    </code>
                  </div>
                  {selected.approvedBy && (
                    <div>
                      {t('camera.jovahagyta')} {selected.approvedBy}
                      {i18n.t('literals.lit')}
                      {formatDate(selected.approvedAt || '')}
                      {i18n.t('literals.lit-2')}
                    </div>
                  )}
                  {selected.submittedBy && (
                    <div>
                      {t('darius.bekuldte')} {selected.submittedBy}
                    </div>
                  )}
                  {selected.ackReference && (
                    <div>
                      {t('darius.ackRef')} {selected.ackReference}
                    </div>
                  )}
                  {selected.errorMessage && (
                    <div className="text-red-600">
                      {t('foertektar.hiba')} {selected.errorMessage}
                    </div>
                  )}
                  {selected.retryCount > 0 && (
                    <div>
                      {t('darius.retry')} {selected.retryCount}
                      {i18n.t('literals.lit-4')}
                      {selected.maxRetries}
                    </div>
                  )}
                </div>

                {/* Actions */}
                <div className="flex gap-2 pt-2 border-t">
                  {selected.status === 'GENERATED' && !selected.approvedBy && (
                    <button
                      onClick={() => handleApprove(selected.id)}
                      className="btn-secondary text-xs flex items-center gap-1"
                    >
                      <ThumbsUp size={12} />
                      {t('common.approve')}
                    </button>
                  )}
                  {(selected.status === 'GENERATED' || selected.status === 'FAILED') &&
                    selected.approvedBy && (
                      <button
                        onClick={() => handleSubmit(selected.id)}
                        className="btn-primary text-xs flex items-center gap-1"
                      >
                        <Send size={12} />
                        {t('darius.bekuldes')}
                      </button>
                    )}
                </div>
                {selected.status === 'SUBMITTED' && (
                  <div className="space-y-2 border-t pt-2">
                    <label
                      className="block text-xs font-medium text-gray-600"
                      htmlFor="darius-ack-reference"
                    >
                      {i18n.t('literals.visszaigazolasi-referencia')}
                    </label>
                    <input
                      id="darius-ack-reference"
                      type="text"
                      className="input-field w-full text-sm"
                      value={ackReference}
                      onChange={(event) => setAckReference(event.target.value)}
                      placeholder="pl. ACK-2026-0001"
                    />
                    <button
                      type="button"
                      onClick={() => handleAcknowledge(selected.id)}
                      disabled={ackSaving}
                      className="btn-primary flex w-full items-center justify-center gap-1 text-xs"
                    >
                      <CheckCircle size={12} />
                      {ackSaving ? 'Visszaigazolás mentése...' : 'Visszaigazolás rögzítése'}
                    </button>
                  </div>
                )}

                {/* Lines */}
                {selected.lines && selected.lines.length > 0 && (
                  <div className="pt-2 border-t">
                    <h4 className="text-xs font-medium mb-1">{t('darius.valutaSorok')}</h4>
                    <div className="max-h-60 overflow-y-auto">
                      <table className="w-full text-[10px]">
                        <thead className="bg-gray-50">
                          <tr>
                            <th className="text-left p-1">{t('common.office')}</th>
                            <th className="text-left p-1">{t('common.currency')}</th>
                            <th className="text-right p-1">{t('darius.vetelDb')}</th>
                            <th className="text-right p-1">{t('darius.eladasDb')}</th>
                            <th className="text-right p-1">{t('darius.vetelFt')}</th>
                            <th className="text-right p-1">{t('darius.eladasFt')}</th>
                          </tr>
                        </thead>
                        <tbody>
                          {selected.lines.map((l) => (
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
              <div className="text-gray-400 text-sm text-center py-8">
                {t('darius.valasszonEgyJelentest')}
              </div>
            )}
          </div>
        </div>
      )}

      {tab === 'monthly' && !loading && monthly && (
        <div className="space-y-3">
          <div className="grid grid-cols-4 gap-3">
            <div className="p-3 bg-blue-50 rounded border">
              <div className="text-xs text-gray-500">{t('darius.osszesJelentes')}</div>
              <div className="text-lg font-bold">{monthly.totalReports}</div>
            </div>
            <div className="p-3 bg-green-50 rounded border">
              <div className="text-xs text-gray-500">{t('darius.visszaigazolt')}</div>
              <div className="text-lg font-bold text-green-700">{monthly.acknowledgedCount}</div>
            </div>
            <div className="p-3 bg-red-50 rounded border">
              <div className="text-xs text-gray-500">{t('darius.sikertelen')}</div>
              <div className="text-lg font-bold text-red-700">{monthly.failedCount}</div>
            </div>
            <div className="p-3 bg-yellow-50 rounded border">
              <div className="text-xs text-gray-500">{t('darius.fuggoben')}</div>
              <div className="text-lg font-bold text-yellow-700">{monthly.pendingCount}</div>
            </div>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div className="p-3 border rounded">
              <div className="text-xs text-gray-500">{t('cashdesk.vetelOsszesen')}</div>
              <div className="font-bold">
                {formatNum(monthly.totalBuyHuf)} {t('components.ft')}
              </div>
            </div>
            <div className="p-3 border rounded">
              <div className="text-xs text-gray-500">{t('cashdesk.eladasOsszesen')}</div>
              <div className="font-bold">
                {formatNum(monthly.totalSellHuf)} {t('components.ft')}
              </div>
            </div>
            <div className="p-3 border rounded">
              <div className="text-xs text-gray-500">{t('darius.kezelesiDijOsszesen')}</div>
              <div className="font-bold">
                {formatNum(monthly.totalHandlingFeeHuf)} {t('components.ft')}
              </div>
            </div>
          </div>
        </div>
      )}

      {tab === 'missing' && !loading && (
        <div>
          {missingDates.length === 0 ? (
            <div className="text-green-600 text-sm flex items-center gap-2 py-4">
              <CheckCircle size={16} />
              {t('darius.nincsHianyzoNapAzIdoszakban')}
            </div>
          ) : (
            <div className="space-y-1">
              <div className="text-sm text-red-600 font-medium">
                {missingDates.length} {t('darius.hianyzoNap')}
              </div>
              <div className="flex flex-wrap gap-2">
                {missingDates.map((d) => (
                  <button
                    key={d}
                    onClick={() => {
                      setGenerateDate(d)
                      handleGenerate()
                    }}
                    className="px-2 py-1 text-xs bg-red-50 border border-red-200 rounded hover:bg-red-100 transition"
                  >
                    {formatDate(d)}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {tab === 'fixing' && <DariusFixingPanel date={generateDate} />}
    </div>
  )
}
