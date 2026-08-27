import { useState, useEffect, useCallback } from 'react'
import { AlertCircle, Plus, UserCheck, CheckCircle, Clock, Eye, Filter } from 'lucide-react'
import { anonymousReportApi, AnonymousReport } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { safeArray } from '@/utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

export default function AnonymousReportPage() {
  const { t } = useTranslation()
  const [reports, setReports] = useState<AnonymousReport[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showNew, setShowNew] = useState(false)
  const [newReport, setNewReport] = useState({
    reportType: 'COMPLAINT',
    subject: '',
    description: '',
  })
  const [selectedReport, setSelectedReport] = useState<AnonymousReport | null>(null)
  const [filterStatus, setFilterStatus] = useState<string>('')
  const [assignWorkerId, setAssignWorkerId] = useState('')
  const [detailsLoadingId, setDetailsLoadingId] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      setReports(await anonymousReportApi.list())
    } catch (err) {
      logger.error('AnonymousReportPage', 'Failed to load reports:', err)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const handleCreate = async () => {
    if (!newReport.subject || !newReport.description) {
      toast.warning('Tárgy és leírás kötelező')
      return
    }
    try {
      setError(null)
      await anonymousReportApi.create(newReport)
      toast.success('Bejelentés rögzítve')
      setShowNew(false)
      setNewReport({ reportType: 'COMPLAINT', subject: '', description: '' })
      await loadData()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const handleAssign = async (id: string) => {
    if (!assignWorkerId) {
      toast.warning('Felelős megadása szükséges')
      return
    }
    try {
      await anonymousReportApi.assign(id, assignWorkerId)
      toast.success('Bejelentés kiosztva')
      setSelectedReport(null)
      setAssignWorkerId('')
      await loadData()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const handleOpenDetails = async (id: string) => {
    try {
      setError(null)
      setDetailsLoadingId(id)
      setAssignWorkerId('')
      setSelectedReport(await anonymousReportApi.getById(id))
    } catch (err) {
      logger.error('AnonymousReportPage', 'Failed to load report details:', err)
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setDetailsLoadingId(null)
    }
  }

  const handleResolve = async (id: string) => {
    if (!confirm('Biztosan lezárja a bejelentést?')) return
    try {
      await anonymousReportApi.resolve(id, 'Lezárva')
      toast.success('Bejelentés lezárva')
      setSelectedReport(null)
      await loadData()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'RESOLVED':
        return (
          <span className="badge badge-green">
            <CheckCircle size={10} className="inline" />
            {t('reports.lezart')}
          </span>
        )
      case 'IN_PROGRESS':
        return (
          <span className="badge badge-blue">
            <Clock size={10} className="inline" />
            {t('common.inProgress')}
          </span>
        )
      case 'ASSIGNED':
        return (
          <span className="badge badge-yellow">
            <UserCheck size={10} className="inline" />
            {t('reports.kiosztva')}
          </span>
        )
      default:
        return <span className="badge badge-gray">{status || 'Új'}</span>
    }
  }

  const filtered = safeArray<AnonymousReport>(reports).filter((r) => {
    if (filterStatus && r.status !== filterStatus) return false
    return true
  })

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <AlertCircle />
          {t('reports.nevtelenBejelentesek')}
        </h1>
        <button onClick={() => setShowNew(true)} className="form-button-primary">
          <Plus size={16} />
          {t('reports.ujBejelentes')}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {/* New report form */}
      {showNew && (
        <div className="form-panel space-y-3 border-2 border-blue-200">
          <h2 className="font-semibold">{t('reports.ujBejelentesRogzitese')}</h2>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label">{t('common.type')}</label>
              <select
                className="form-input"
                value={newReport.reportType}
                onChange={(e) => setNewReport({ ...newReport, reportType: e.target.value })}
              >
                <option value="COMPLAINT">{t('reports.panasz')}</option>
                <option value="FRAUD">{t('reports.csalasGyanu')}</option>
                <option value="SUSPICIOUS_TRANSACTION">{t('reports.gyanusTranzakcio')}</option>
                <option value="MONEY_LAUNDERING">{t('reports.penzmosasGyanu')}</option>
                <option value="OTHER">{t('common.other')}</option>
              </select>
            </div>
            <div>
              <label className="form-label">{t('reports.targy')}</label>
              <input
                className="form-input"
                value={newReport.subject}
                onChange={(e) => setNewReport({ ...newReport, subject: e.target.value })}
              />
            </div>
          </div>
          <div>
            <label className="form-label">{t('reports.leiras')}</label>
            <textarea
              className="form-input"
              rows={4}
              value={newReport.description}
              onChange={(e) => setNewReport({ ...newReport, description: e.target.value })}
            />
          </div>
          <div className="flex gap-2">
            <button onClick={() => void handleCreate()} className="form-button-primary">
              {t('reports.rogzites')}
            </button>
            <button onClick={() => setShowNew(false)} className="form-button">
              {t('common.cancel')}
            </button>
          </div>
        </div>
      )}

      {/* Detail modal */}
      {selectedReport && (
        <div className="form-panel space-y-3 border-2 border-yellow-200">
          <h2 className="font-semibold flex items-center gap-2">
            <Eye size={18} />
            {t('reports.bejelentesReszletei')}
          </h2>
          <div className="grid grid-cols-2 gap-2 text-sm">
            <div>
              <span className="text-gray-500">{t('cashdesk.tipus')}</span>{' '}
              {selectedReport.reportType}
            </div>
            <div>
              <span className="text-gray-500">{t('darius.statusz')}</span>{' '}
              {getStatusBadge(selectedReport.status)}
            </div>
            <div>
              <span className="text-gray-500">{t('reports.targy2')}</span> {selectedReport.subject}
            </div>
            <div>
              <span className="text-gray-500">{t('components.datum')}</span>{' '}
              {new Date(selectedReport.reportedAt).toLocaleString('hu-HU')}
            </div>
            <div className="col-span-2">
              <span className="text-gray-500">{t('reports.leiras2')}</span>{' '}
              {selectedReport.description || '-'}
            </div>
            <div>
              <span className="text-gray-500">{t('reports.felelos')}</span>{' '}
              {selectedReport.assignedToName || 'Nincs'}
            </div>
          </div>
          {selectedReport.status !== 'RESOLVED' && (
            <div className="flex gap-2 items-end">
              <div>
                <label className="form-label">{t('reports.felelosId')}</label>
                <input
                  className="form-input"
                  value={assignWorkerId}
                  onChange={(e) => setAssignWorkerId(e.target.value)}
                  placeholder="Dolgozó ID"
                />
              </div>
              <button onClick={() => void handleAssign(selectedReport.id)} className="form-button">
                <UserCheck size={16} />
                {t('reports.kiosztas')}
              </button>
              <button
                onClick={() => void handleResolve(selectedReport.id)}
                className="form-button-primary"
              >
                <CheckCircle size={16} />
                {t('decade.lezaras')}
              </button>
            </div>
          )}
          <button onClick={() => setSelectedReport(null)} className="form-button text-sm">
            {t('common.close')}
          </button>
        </div>
      )}

      {/* Filter */}
      <div className="form-panel flex gap-3 items-end">
        <Filter size={16} className="text-gray-400" />
        <div>
          <label className="form-label">{t('common.status')}</label>
          <select
            className="form-input"
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
          >
            <option value="">{t('common.all')}</option>
            <option value="NEW">{t('common.new')}</option>
            <option value="ASSIGNED">{t('reports.kiosztva')}</option>
            <option value="IN_PROGRESS">{t('common.inProgress')}</option>
            <option value="RESOLVED">{t('reports.lezart')}</option>
          </select>
        </div>
        <span className="text-sm text-gray-500">
          {filtered.length} {t('reports.bejelentes')}
        </span>
      </div>

      {/* Table */}
      <div className="form-panel">
        {loading ? (
          <div>{i18n.t('literals.betoltes')}</div>
        ) : filtered.length === 0 ? (
          <div className="text-center text-gray-500 py-4">{t('reports.nincsBejelentes')}</div>
        ) : (
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>{t('common.type')}</th>
                <th>{t('reports.targy3')}</th>
                <th>{t('common.date')}</th>
                <th>{t('common.status')}</th>
                <th>{t('reports.felelos2')}</th>
                <th>{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((r) => (
                <tr key={r.id} className={r.status !== 'RESOLVED' ? 'bg-yellow-50' : ''}>
                  <td className="text-sm">{r.reportType}</td>
                  <td>{r.subject || '-'}</td>
                  <td className="text-sm">{new Date(r.reportedAt).toLocaleDateString('hu-HU')}</td>
                  <td>{getStatusBadge(r.status)}</td>
                  <td>{r.assignedToName || '-'}</td>
                  <td>
                    <button
                      onClick={() => void handleOpenDetails(r.id)}
                      disabled={detailsLoadingId === r.id}
                      className="form-button text-xs disabled:opacity-50"
                    >
                      <Eye size={12} />
                      {t('common.details')}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
