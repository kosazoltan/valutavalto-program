import { useState, useEffect, useCallback } from 'react'
import { Download, AlertTriangle } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { useAuthStore } from '../../stores/authStore'

/**
 * Fix #146 live UI test: a korabbi page a nemletezo GET /booking-export-ot
 * hivta (404). A backend 3 sub-endpointot exposol CSV letoltessel:
 *  - GET /api/v1/booking/daily?branchId=&date=
 *  - GET /api/v1/booking/monthly?branchId=&month=YYYY-MM
 *  - GET /api/v1/booking/inventory?branchId=&date=
 *
 * Ezert a page 3-gombos export launcher (branch+datum valaszto + letoltes).
 */

interface BranchDto {
  id: string
  code?: string
  name: string
}

export default function BookingExportPage() {
  const workerBranchId = useAuthStore((s) => s.worker?.branchId ?? '')
  const [branches, setBranches] = useState<BranchDto[]>([])
  const [branchId, setBranchId] = useState<string>(workerBranchId)
  const [date, setDate] = useState<string>(() => new Date().toISOString().slice(0, 10))
  const [month, setMonth] = useState<string>(() => new Date().toISOString().slice(0, 7))
  const [busy, setBusy] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [info, setInfo] = useState<string | null>(null)

  const loadBranches = useCallback(async () => {
    try {
      const r = await api.get<BranchDto[]>('/branches')
      setBranches(Array.isArray(r.data) ? r.data : [])
      if (!branchId && workerBranchId) setBranchId(workerBranchId)
    } catch (err) {
      logger.warn('BookingExportPage', 'Branch load failed', err)
    }
  }, [workerBranchId])

  useEffect(() => { void loadBranches() }, [loadBranches])

  async function downloadCsv(path: string, params: Record<string, string>, filename: string) {
    if (!branchId) { setError('Valassz penztari egyseget (branch)'); return }
    try {
      setBusy(path); setError(null); setInfo(null)
      const response = await api.get(path, { params: { branchId, ...params }, responseType: 'blob' })
      const blob = new Blob([response.data as BlobPart], { type: 'text/csv;charset=utf-8' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url; a.download = filename; document.body.appendChild(a); a.click(); a.remove()
      URL.revokeObjectURL(url)
      setInfo('Letoltes: ' + filename)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('BookingExportPage', 'Export error: ' + path, err)
      setError(msg)
    } finally { setBusy(null) }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Download className="h-6 w-6" />
          Konyveles export (CSV)
        </h1>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-3 bg-white rounded shadow p-4">
        <div>
          <label className="block text-xs text-gray-500 mb-1">Penztari egyseg</label>
          <select value={branchId} onChange={(e) => setBranchId(e.target.value)} className="form-input w-full">
            <option value="">-- Valassz --</option>
            {branches.map((b) => (
              <option key={b.id} value={b.id}>{b.name}{b.code ? ' (' + b.code + ')' : ''}</option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1">Datum (napi / keszlet)</label>
          <input type="date" value={date} onChange={(e) => setDate(e.target.value)} className="form-input w-full" />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1">Honap (havi)</label>
          <input type="month" value={month} onChange={(e) => setMonth(e.target.value)} className="form-input w-full" />
        </div>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}
      {info && (
        <div className="bg-green-50 text-green-700 border border-green-200 rounded p-2 text-sm">{info}</div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
        <button
          onClick={() => void downloadCsv('/booking/daily', { date }, 'konyveles-napi-' + date + '.csv')}
          disabled={busy !== null}
          className="form-button-primary flex items-center justify-center gap-2 py-4"
        >
          <Download className="h-5 w-5" />
          Napi export ({date})
        </button>
        <button
          onClick={() => void downloadCsv('/booking/monthly', { month }, 'konyveles-havi-' + month + '.csv')}
          disabled={busy !== null}
          className="form-button-primary flex items-center justify-center gap-2 py-4"
        >
          <Download className="h-5 w-5" />
          Havi export ({month})
        </button>
        <button
          onClick={() => void downloadCsv('/booking/inventory', { date }, 'keszlet-' + date + '.csv')}
          disabled={busy !== null}
          className="form-button-primary flex items-center justify-center gap-2 py-4"
        >
          <Download className="h-5 w-5" />
          Keszlet export ({date})
        </button>
      </div>

      <div className="text-xs text-gray-500">
        Tipp: a letoltott CSV fajl konvertalhato Excel-be (UTF-8 encoding), vagy kozvetlenul
        beolvashato a konyvelesi rendszerbe.
      </div>
    </div>
  )
}
