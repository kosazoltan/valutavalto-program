import { useState, useEffect, useCallback } from 'react'
import {
  FileText,
  Bell,
  CheckCircle,
  XCircle,
  Download,
  Plus,
  Send,
  Eye,
  AlertTriangle,
  X,
} from 'lucide-react'
import { useHotkeys } from 'react-hotkeys-hook'
import { reportApi, notificationApi } from '../../services/api/index'
import type { DailyClosingReport, Notification as AppNotification } from '../../services/api/index'
import { formatMillions, formatInteger, todayISO } from './treasuryUtils'
import { TableSkeleton } from './LoadingSkeleton'
import { logger } from '../../utils/logger';

type TabType = 'reports' | 'circulars'

interface BranchReport {
  branchId: string
  branchName: string
  totalBuy: number
  totalSell: number
  totalFee: number
  totalProfit: number
  transactionCount: number
  submitted: boolean
  submittedAt?: string
}

export default function ReportsCirculars() {
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<TabType>('reports')
  const [dailyReport, setDailyReport] = useState<DailyClosingReport | null>(null)
  const [branchReports, setBranchReports] = useState<BranchReport[]>([])
  const [circulars, setCirculars] = useState<AppNotification[]>([])
  const [showNewCircular, setShowNewCircular] = useState(false)

  // Circular form
  const [circularTitle, setCircularTitle] = useState('')
  const [circularContent, setCircularContent] = useState('')
  const [circularUrgent, setCircularUrgent] = useState(false)
  const [showCircularDetail, setShowCircularDetail] = useState<AppNotification | null>(null)

  const fetchData = useCallback(async () => {
    try {
      const [report, notifications] = await Promise.all([
        reportApi.getDailyClosing(todayISO()).catch(() => null),
        notificationApi.list().catch(() => [] as AppNotification[]),
      ])

      if (report) {
        setDailyReport(report)
        // Build branch reports from the daily report data
        const br: BranchReport = {
          branchId: report.branchId,
          branchName: report.branchName,
          totalBuy: report.totalBuyHuf,
          totalSell: report.totalSellHuf,
          totalFee: report.totalHandlingFees,
          totalProfit: report.totalHandlingFees || 0,
          transactionCount: report.transactionCount,
          submitted: report.sessionStatus === 'CLOSED',
          submittedAt: report.sessionStatus === 'CLOSED' ? todayISO() : undefined,
        }
        setBranchReports([br])
      }
      setCirculars(notifications)
    } catch (err) {
      logger.error('ReportsCirculars', 'ReportsCirculars fetch error:', err)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void fetchData()
  }, [fetchData])

  // Hotkeys
  useHotkeys('n', () => setShowNewCircular(true), { enableOnFormTags: false })
  useHotkeys('escape', () => {
    setShowNewCircular(false)
    setShowCircularDetail(null)
  }, { enableOnFormTags: true })

  const handleCircularSubmit = useCallback(async (e: React.FormEvent) => {
    e.preventDefault()
    if (!circularTitle || !circularContent) return
    try {
      const typeStr = circularUrgent ? 'URGENT' : 'INFO'
      await notificationApi.send({ title: circularTitle, message: circularContent, type: typeStr })
      setShowNewCircular(false)
      setCircularTitle('')
      setCircularContent('')
      setCircularUrgent(false)
      void fetchData()
    } catch (err) {
      logger.error('ReportsCirculars', 'Send circular error:', err)
    }
  }, [circularTitle, circularContent, circularUrgent, fetchData])

  if (loading) return <TableSkeleton rows={6} cols={6} />

  const submittedCount = branchReports.filter((r) => r.submitted).length
  const totalCount = branchReports.length

  // Totals
  const totalBuy = branchReports.reduce((sum, r) => sum + r.totalBuy, 0)
  const totalSell = branchReports.reduce((sum, r) => sum + r.totalSell, 0)
  const totalFee = branchReports.reduce((sum, r) => sum + r.totalFee, 0)
  const totalProfit = branchReports.reduce((sum, r) => sum + r.totalProfit, 0)
  const totalTransactions = branchReports.reduce((sum, r) => sum + r.transactionCount, 0)

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-secondary-900">Napi Jelentés &amp; Körlevél</h1>
        <span className="text-sm text-secondary-500">📅 {todayISO()}</span>
      </div>

      {/* Tabs */}
      <div className="flex gap-0 border-b border-form-border">
        <button
          onClick={() => setActiveTab('reports')}
          className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
            activeTab === 'reports'
              ? 'border-primary-600 text-primary-700'
              : 'border-transparent text-secondary-500 hover:text-secondary-700'
          }`}
        >
          <FileText size={16} className="inline mr-2" />
          Napi jelentések
        </button>
        <button
          onClick={() => setActiveTab('circulars')}
          className={`px-4 py-2.5 text-sm font-medium border-b-2 transition-colors ${
            activeTab === 'circulars'
              ? 'border-primary-600 text-primary-700'
              : 'border-transparent text-secondary-500 hover:text-secondary-700'
          }`}
        >
          <Bell size={16} className="inline mr-2" />
          Körlevelek
          {circulars.length > 0 && (
            <span className="ml-2 badge badge-blue text-xs">{circulars.length}</span>
          )}
        </button>
      </div>

      {/* TAB 1: Daily Reports */}
      {activeTab === 'reports' && (
        <div className="space-y-3">
          {/* Submission Status */}
          <div className="form-panel">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-bold text-secondary-900 flex items-center gap-2">
                <FileText size={20} className="text-primary-600" />
                Beküldési státusz ({submittedCount}/{totalCount} iroda)
              </h2>
              {submittedCount === totalCount && totalCount > 0 && (
                <div className="flex items-center gap-2 px-3 py-1.5 bg-success-50 border border-success-200 rounded-lg text-sm font-semibold text-success-700">
                  <CheckCircle size={18} />
                  Minden iroda beküdte
                </div>
              )}
            </div>
            <div className="flex flex-wrap gap-2">
              {branchReports.map((branch) => (
                <div
                  key={branch.branchId}
                  className={`px-3 py-2 rounded-lg border text-sm font-semibold flex items-center gap-2 ${
                    branch.submitted
                      ? 'bg-success-50 border-success-200 text-success-700'
                      : 'bg-danger-50 border-danger-200 text-danger-700'
                  }`}
                >
                  {branch.submitted ? (
                    <>
                      <CheckCircle size={16} />
                      {branch.branchName}
                    </>
                  ) : (
                    <>
                      <XCircle size={16} />
                      {branch.branchName} — nincs
                    </>
                  )}
                </div>
              ))}
              {branchReports.length === 0 && (
                <p className="text-sm text-secondary-400">Nincs iroda adat</p>
              )}
            </div>
          </div>

          {/* Consolidated Report Table */}
          <div className="form-panel">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-bold text-secondary-900">Konszolidált napi jelentés</h2>
              <button className="form-button h-8 text-xs">
                <Download size={16} />
                <span>Export PDF</span>
              </button>
            </div>
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th className="w-48">Iroda</th>
                  <th className="text-right w-32">Vétel (HUF)</th>
                  <th className="text-right w-32">Eladás (HUF)</th>
                  <th className="text-right w-24">Díj</th>
                  <th className="text-right w-28">Profit</th>
                  <th className="text-right w-20">Tranz.</th>
                </tr>
              </thead>
              <tbody>
                {branchReports.length === 0 && (
                  <tr>
                    <td colSpan={6} className="text-center text-sm text-secondary-400 py-8">
                      Nincs jelentés adat
                    </td>
                  </tr>
                )}
                {branchReports.map((report) => (
                  <tr key={report.branchId} className="hover:bg-primary-50">
                    <td className="font-semibold text-secondary-900">{report.branchName}</td>
                    <td className="text-right font-mono text-success-700 font-semibold">
                      {formatMillions(report.totalBuy)}
                    </td>
                    <td className="text-right font-mono text-danger-700 font-semibold">
                      {formatMillions(report.totalSell)}
                    </td>
                    <td className="text-right font-mono text-secondary-700">
                      {formatMillions(report.totalFee)}
                    </td>
                    <td className="text-right font-mono text-primary-700 font-bold">
                      {formatMillions(report.totalProfit)}
                    </td>
                    <td className="text-right font-semibold text-secondary-900">
                      {formatInteger(report.transactionCount)}
                    </td>
                  </tr>
                ))}
                {/* Summary row */}
                {branchReports.length > 0 && (
                  <tr className="bg-secondary-100 border-t-2 border-secondary-300">
                    <td className="font-bold text-secondary-900">ÖSSZES (∑)</td>
                    <td className="text-right font-mono font-bold text-success-700">
                      {formatMillions(totalBuy)}
                    </td>
                    <td className="text-right font-mono font-bold text-danger-700">
                      {formatMillions(totalSell)}
                    </td>
                    <td className="text-right font-mono font-bold text-secondary-900">
                      {formatMillions(totalFee)}
                    </td>
                    <td className="text-right font-mono font-bold text-primary-700 text-lg">
                      {formatMillions(totalProfit)}
                    </td>
                    <td className="text-right font-bold text-secondary-900">
                      {formatInteger(totalTransactions)}
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {/* Daily report detail from API */}
          {dailyReport && (
            <div className="form-panel">
              <h2 className="text-lg font-bold text-secondary-900 mb-4">
                Részletes forgalom — {dailyReport.branchName}
              </h2>
              <div className="grid grid-cols-4 gap-4">
                <StatBox label="Vétel (db)" value={formatInteger(dailyReport.buyCount)} />
                <StatBox label="Eladás (db)" value={formatInteger(dailyReport.sellCount)} />
                <StatBox label="Sztornó (db)" value={formatInteger(dailyReport.reversalCount)} />
                <StatBox label="Nyitó egyenleg" value={formatMillions(dailyReport.openingBalanceHuf)} />
              </div>
              {dailyReport.currencyTurnovers && dailyReport.currencyTurnovers.length > 0 && (
                <div className="mt-4">
                  <h3 className="text-sm font-semibold text-secondary-700 mb-2">Valutánkénti bontás</h3>
                  <table className="data-grid w-full">
                    <thead>
                      <tr>
                        <th>Valuta</th>
                        <th className="text-right">Vétel db</th>
                        <th className="text-right">Vétel összeg</th>
                        <th className="text-right">Eladás db</th>
                        <th className="text-right">Eladás összeg</th>
                      </tr>
                    </thead>
                    <tbody>
                      {dailyReport.currencyTurnovers.map((ct) => (
                        <tr key={ct.currencyCode}>
                          <td className="font-bold">{ct.currencyCode}</td>
                          <td className="text-right font-mono">{ct.buyCount}</td>
                          <td className="text-right font-mono">{formatInteger(ct.buyAmount)}</td>
                          <td className="text-right font-mono">{ct.sellCount}</td>
                          <td className="text-right font-mono">{formatInteger(ct.sellAmount)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {/* TAB 2: Circulars */}
      {activeTab === 'circulars' && (
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-bold text-secondary-900 flex items-center gap-2">
              <Bell size={20} className="text-accent-600" />
              Körlevelek
            </h2>
            <button onClick={() => setShowNewCircular(true)} className="form-button-primary h-8 text-xs">
              <Plus size={16} />
              <span>Új körlevél</span>
            </button>
          </div>

          <div className="space-y-3">
            {circulars.length === 0 && (
              <div className="form-panel text-center py-8">
                <p className="text-sm text-secondary-400">Nincs körlevél</p>
              </div>
            )}
            {circulars.map((circular) => {
              const isUrgent = circular.type === 'URGENT'
              return (
                <div
                  key={circular.id}
                  className={`p-4 rounded-lg border ${
                    isUrgent
                      ? 'border-danger-200 bg-danger-50'
                      : 'border-primary-200 bg-primary-50'
                  }`}
                >
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        {isUrgent && (
                          <span className="badge badge-red flex items-center gap-1">
                            <AlertTriangle size={12} />
                            SÜRGŐS
                          </span>
                        )}
                        <span className="font-bold text-secondary-900">{circular.title}</span>
                      </div>
                      <div className="text-sm text-secondary-700 mb-2">{circular.message}</div>
                      <div className="text-xs text-secondary-500">
                        {new Date(circular.createdAt).toLocaleString('hu-HU')}
                      </div>
                    </div>
                    <button
                      className="form-button h-8 text-xs ml-4"
                      onClick={() => setShowCircularDetail(circular)}
                    >
                      <Eye size={16} />
                      Részlet
                    </button>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <span className="text-secondary-600">Státusz:</span>
                    <span className={`font-semibold ${circular.isRead ? 'text-success-700' : 'text-warning-700'}`}>
                      {circular.isRead ? 'Olvasva' : 'Olvasatlan'}
                    </span>
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      )}

      {/* New Circular Modal */}
      {showNewCircular && (
        <ModalOverlay onClose={() => setShowNewCircular(false)}>
          <div className="bg-white rounded-lg shadow-xl p-4 max-w-2xl w-full mx-4">
            <div className="flex items-center justify-between mb-3">
              <h2 className="text-xl font-bold text-secondary-900">Új körlevél küldése</h2>
              <button onClick={() => setShowNewCircular(false)} className="text-secondary-400 hover:text-secondary-600">
                <X size={20} />
              </button>
            </div>
            <form onSubmit={(e) => void handleCircularSubmit(e)} className="space-y-4">
              <div>
                <label className="form-label">Cím</label>
                <input
                  type="text"
                  className="form-input w-full"
                  placeholder="Pl: Új árfolyam azonnal"
                  value={circularTitle}
                  onChange={(e) => setCircularTitle(e.target.value)}
                />
              </div>
              <div>
                <label className="form-label">Tartalom</label>
                <textarea
                  className="form-input w-full min-h-[120px]"
                  placeholder="Körlevél szövege..."
                  value={circularContent}
                  onChange={(e) => setCircularContent(e.target.value)}
                />
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="urgent-check"
                  className="w-4 h-4 rounded border-secondary-300 text-danger-600 focus:ring-danger-500"
                  checked={circularUrgent}
                  onChange={(e) => setCircularUrgent(e.target.checked)}
                />
                <label htmlFor="urgent-check" className="text-sm font-medium text-secondary-700">
                  Sürgős körlevél (piros jelöléssel)
                </label>
              </div>
              <div className="flex items-center justify-end gap-3 pt-4 border-t border-secondary-200">
                <button
                  type="button"
                  className="form-button"
                  onClick={() => setShowNewCircular(false)}
                >
                  Mégse
                </button>
                <button type="submit" className="form-button-primary">
                  <Send size={18} />
                  <span>Küldés</span>
                </button>
              </div>
            </form>
          </div>
        </ModalOverlay>
      )}

      {/* Circular Detail Modal */}
      {showCircularDetail && (
        <ModalOverlay onClose={() => setShowCircularDetail(null)}>
          <div className="bg-white rounded-lg shadow-xl p-4 max-w-lg w-full mx-4">
            <h2 className="text-xl font-bold text-secondary-900 mb-4">{showCircularDetail.title}</h2>
            <div className="space-y-3 text-sm">
              <div className="p-4 bg-secondary-50 rounded-lg text-secondary-700">
                {showCircularDetail.message}
              </div>
              <div className="flex justify-between text-xs text-secondary-500">
                <span>Típus: {showCircularDetail.type}</span>
                <span>{new Date(showCircularDetail.createdAt).toLocaleString('hu-HU')}</span>
              </div>
            </div>
            <button
              onClick={() => setShowCircularDetail(null)}
              className="form-button-primary w-full mt-6"
            >
              Bezárás
            </button>
          </div>
        </ModalOverlay>
      )}
    </div>
  )
}

// ---- Helper components ----

function StatBox({ label, value }: { label: string; value: string }) {
  return (
    <div className="p-3 bg-secondary-50 border border-secondary-200 rounded-lg">
      <div className="text-xs text-secondary-600 mb-1">{label}</div>
      <div className="text-sm font-bold font-mono text-secondary-900">{value}</div>
    </div>
  )
}

function ModalOverlay({ children, onClose }: { children: React.ReactNode; onClose: () => void }) {
  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center" onClick={onClose}>
      <div onClick={(e) => e.stopPropagation()}>{children}</div>
    </div>
  )
}
