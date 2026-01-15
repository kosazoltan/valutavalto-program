import { useState, useEffect } from 'react'
import { AlertCircle } from 'lucide-react'
import { anonymousReportApi, AnonymousReport } from '../../services/api'
import { getErrorMessage } from '../../utils/errorHandling'

export default function AnonymousReportPage() {
  const [reports, setReports] = useState<AnonymousReport[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let mounted = true

    const load = async (): Promise<void> => {
      await loadData()
    }

    load().catch(err => {
      if (mounted) {
        console.error('Failed to load anonymous reports:', err)
      }
    })

    return () => {
      mounted = false
    }
  }, [])

  const loadData = async (): Promise<void> => {
    try {
      setLoading(true)
      setReports(await anonymousReportApi.list())
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      console.error('Failed to load reports:', err)
      alert(`Hiba történt a betöltés során: ${errorMessage}`)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2"><AlertCircle />Névtelen bejelentések</h1>
      {loading ? <div>Betöltés...</div> : (
        <div className="form-panel">
          <table className="data-grid w-full">
            <thead><tr><th>Típus</th><th>Tárgy</th><th>Dátum</th><th>Státusz</th><th>Felelős</th></tr></thead>
            <tbody>
              {reports.map(r => (
                <tr key={r.id}>
                  <td>{r.reportType}</td>
                  <td>{r.subject || '-'}</td>
                  <td>{new Date(r.reportedAt).toLocaleDateString('hu-HU')}</td>
                  <td><span className={`badge ${r.status === 'RESOLVED' ? 'badge-green' : 'badge-yellow'}`}>{r.status}</span></td>
                  <td>{r.assignedToName || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

