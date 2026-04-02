import { useState, useEffect, useCallback } from 'react'
import { AlertCircle, Plus, UserCheck, CheckCircle, Clock, Eye, Filter } from 'lucide-react'
import { anonymousReportApi, AnonymousReport } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { safeArray } from '@/utils/safeArray'

export default function AnonymousReportPage() {
  const [reports, setReports] = useState<AnonymousReport[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showNew, setShowNew] = useState(false)
  const [newReport, setNewReport] = useState({ reportType: 'COMPLAINT', subject: '', description: '' })
  const [selectedReport, setSelectedReport] = useState<AnonymousReport | null>(null)
  const [filterStatus, setFilterStatus] = useState<string>('')
  const [assignWorkerId, setAssignWorkerId] = useState('')

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

  useEffect(() => { void loadData() }, [loadData])

  const handleCreate = async () => {
    if (!newReport.subject || !newReport.description) { toast.warning('Tárgy és leírás kötelező'); return }
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
    if (!assignWorkerId) { toast.warning('Felelős megadása szükséges'); return }
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
      case 'RESOLVED': return <span className="badge badge-green"><CheckCircle size={10} className="inline" /> Lezárt</span>
      case 'IN_PROGRESS': return <span className="badge badge-blue"><Clock size={10} className="inline" /> Folyamatban</span>
      case 'ASSIGNED': return <span className="badge badge-yellow"><UserCheck size={10} className="inline" /> Kiosztva</span>
      default: return <span className="badge badge-gray">{status || 'Új'}</span>
    }
  }

  const filtered = safeArray<AnonymousReport>(reports).filter(r => {
    if (filterStatus && r.status !== filterStatus) return false
    return true
  })

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2"><AlertCircle />Névtelen bejelentések</h1>
        <button onClick={() => setShowNew(true)} className="form-button-primary"><Plus size={16} /> Új bejelentés</button>
      </div>

      {error && <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>}

      {/* New report form */}
      {showNew && (
        <div className="form-panel space-y-3 border-2 border-blue-200">
          <h2 className="font-semibold">Új bejelentés rögzítése</h2>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label">Típus</label>
              <select className="form-input" value={newReport.reportType} onChange={e => setNewReport({ ...newReport, reportType: e.target.value })}>
                <option value="COMPLAINT">Panasz</option>
                <option value="FRAUD">Csalás gyanú</option>
                <option value="SUSPICIOUS_TRANSACTION">Gyanús tranzakció</option>
                <option value="MONEY_LAUNDERING">Pénzmosás gyanú</option>
                <option value="OTHER">Egyéb</option>
              </select>
            </div>
            <div>
              <label className="form-label">Tárgy *</label>
              <input className="form-input" value={newReport.subject} onChange={e => setNewReport({ ...newReport, subject: e.target.value })} />
            </div>
          </div>
          <div>
            <label className="form-label">Leírás *</label>
            <textarea className="form-input" rows={4} value={newReport.description} onChange={e => setNewReport({ ...newReport, description: e.target.value })} />
          </div>
          <div className="flex gap-2">
            <button onClick={() => void handleCreate()} className="form-button-primary">Rögzítés</button>
            <button onClick={() => setShowNew(false)} className="form-button">Mégse</button>
          </div>
        </div>
      )}

      {/* Detail modal */}
      {selectedReport && (
        <div className="form-panel space-y-3 border-2 border-yellow-200">
          <h2 className="font-semibold flex items-center gap-2"><Eye size={18} /> Bejelentés részletei</h2>
          <div className="grid grid-cols-2 gap-2 text-sm">
            <div><span className="text-gray-500">Típus:</span> {selectedReport.reportType}</div>
            <div><span className="text-gray-500">Státusz:</span> {getStatusBadge(selectedReport.status)}</div>
            <div><span className="text-gray-500">Tárgy:</span> {selectedReport.subject}</div>
            <div><span className="text-gray-500">Dátum:</span> {new Date(selectedReport.reportedAt).toLocaleString('hu-HU')}</div>
            <div className="col-span-2"><span className="text-gray-500">Leírás:</span> {selectedReport.description || '-'}</div>
            <div><span className="text-gray-500">Felelős:</span> {selectedReport.assignedToName || 'Nincs'}</div>
          </div>
          {selectedReport.status !== 'RESOLVED' && (
            <div className="flex gap-2 items-end">
              <div>
                <label className="form-label">Felelős ID</label>
                <input className="form-input" value={assignWorkerId} onChange={e => setAssignWorkerId(e.target.value)} placeholder="Dolgozó ID" />
              </div>
              <button onClick={() => void handleAssign(selectedReport.id)} className="form-button"><UserCheck size={16} /> Kiosztás</button>
              <button onClick={() => void handleResolve(selectedReport.id)} className="form-button-primary"><CheckCircle size={16} /> Lezárás</button>
            </div>
          )}
          <button onClick={() => setSelectedReport(null)} className="form-button text-sm">Bezárás</button>
        </div>
      )}

      {/* Filter */}
      <div className="form-panel flex gap-3 items-end">
        <Filter size={16} className="text-gray-400" />
        <div>
          <label className="form-label">Státusz</label>
          <select className="form-input" value={filterStatus} onChange={e => setFilterStatus(e.target.value)}>
            <option value="">Mind</option>
            <option value="NEW">Új</option>
            <option value="ASSIGNED">Kiosztva</option>
            <option value="IN_PROGRESS">Folyamatban</option>
            <option value="RESOLVED">Lezárt</option>
          </select>
        </div>
        <span className="text-sm text-gray-500">{filtered.length} bejelentés</span>
      </div>

      {/* Table */}
      <div className="form-panel">
        {loading ? <div>Betöltés...</div> : filtered.length === 0 ? (
          <div className="text-center text-gray-500 py-4">Nincs bejelentés</div>
        ) : (
          <table className="data-grid w-full">
            <thead><tr><th>Típus</th><th>Tárgy</th><th>Dátum</th><th>Státusz</th><th>Felelős</th><th>Műveletek</th></tr></thead>
            <tbody>
              {filtered.map(r => (
                <tr key={r.id} className={r.status !== 'RESOLVED' ? 'bg-yellow-50' : ''}>
                  <td className="text-sm">{r.reportType}</td>
                  <td>{r.subject || '-'}</td>
                  <td className="text-sm">{new Date(r.reportedAt).toLocaleDateString('hu-HU')}</td>
                  <td>{getStatusBadge(r.status)}</td>
                  <td>{r.assignedToName || '-'}</td>
                  <td>
                    <button onClick={() => setSelectedReport(r)} className="form-button text-xs"><Eye size={12} /> Részletek</button>
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
