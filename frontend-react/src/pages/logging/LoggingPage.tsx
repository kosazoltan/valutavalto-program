import { useState, useEffect } from 'react'
import { FileText, Download, Search } from 'lucide-react'
import { loggingApi, AuditLog } from '../../services/api'

export default function LoggingPage() {
  const [logs, setLogs] = useState<AuditLog[]>([])
  const [loading, setLoading] = useState(true)
  const [logType, setLogType] = useState<'system' | 'pos' | 'nav'>('system')
  const [fromDate, setFromDate] = useState('')
  const [toDate, setToDate] = useState('')
  const [searchTerm, setSearchTerm] = useState('')
  const [page, setPage] = useState(0)
  const [totalElements, setTotalElements] = useState(0)

  useEffect(() => {
    void loadLogs()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [logType, fromDate, toDate, page])

  const loadLogs = async () => {
    try {
      setLoading(true)
      let result
      if (logType === 'system') {
        result = await loggingApi.getSystemLogs(fromDate || undefined, toDate || undefined, page, 50)
      } else if (logType === 'pos') {
        result = await loggingApi.getPosLogs(fromDate || undefined, toDate || undefined, page, 50)
      } else {
        result = await loggingApi.getNavLogs(fromDate || undefined, toDate || undefined, page, 50)
      }
      setLogs(result.content)
      setTotalElements(result.totalElements)
    } catch (error) {
      console.error('Hiba a logok betöltésekor:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleExport = async () => {
    try {
      const blob = await loggingApi.exportToCsv(fromDate || undefined, toDate || undefined)
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `logs-${logType}-${new Date().toISOString()}.csv`
      a.click()
    } catch (error) {
      console.error('Hiba az exportálásnál:', error)
      alert('Hiba történt az exportálás során')
    }
  }

  const filteredLogs = logs.filter(log =>
    log.action?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    log.entityType?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    log.userName?.toLowerCase().includes(searchTerm.toLowerCase())
  )

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileText />
          Logok
        </h1>
        <button onClick={handleExport} className="form-button-primary flex items-center gap-2">
          <Download size={16} />
          Exportálás CSV
        </button>
      </div>

      <div className="form-panel space-y-4">
        <div className="grid grid-cols-4 gap-4">
          <div>
            <label className="form-label">Log típus</label>
            <select className="form-input" value={logType} onChange={(e) => setLogType(e.target.value as typeof logType)}>
              <option value="system">Rendszer logok</option>
              <option value="pos">POS logok</option>
              <option value="nav">NAV logok</option>
            </select>
          </div>
          <div>
            <label className="form-label">Kezdő dátum</label>
            <input type="date" className="form-input" value={fromDate} onChange={(e) => setFromDate(e.target.value)} />
          </div>
          <div>
            <label className="form-label">Vég dátum</label>
            <input type="date" className="form-input" value={toDate} onChange={(e) => setToDate(e.target.value)} />
          </div>
          <div>
            <label className="form-label">Keresés</label>
            <div className="relative">
              <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
              <input type="text" className="form-input pl-8" placeholder="Keresés..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
            </div>
          </div>
        </div>
      </div>

      <div className="form-panel">
        <div className="mb-2 text-sm text-gray-600">
          Összesen: {totalElements} log
        </div>
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>Időpont</th>
              <th>Akció</th>
              <th>Entitás típus</th>
              <th>Entitás ID</th>
              <th>Felhasználó</th>
              <th>Fők</th>
              <th>IP cím</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={7} className="text-center py-4">Betöltés...</td></tr>
            ) : filteredLogs.length === 0 ? (
              <tr><td colSpan={7} className="text-center text-gray-500 py-4">Nincs találat</td></tr>
            ) : (
              filteredLogs.map((log) => (
                <tr key={log.id}>
                  <td>{new Date(log.createdAt).toLocaleString('hu-HU')}</td>
                  <td>{log.action}</td>
                  <td>{log.entityType}</td>
                  <td className="font-mono text-xs">{log.entityId}</td>
                  <td>{log.userName || '-'}</td>
                  <td>{log.branchName || '-'}</td>
                  <td>{log.ipAddress || '-'}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
        <div className="flex justify-between items-center mt-4">
          <button
            onClick={() => setPage(p => Math.max(0, p - 1))}
            disabled={page === 0}
            className="form-button"
          >
            Előző
          </button>
          <span className="text-sm text-gray-600">Oldal {page + 1}</span>
          <button
            onClick={() => setPage(p => p + 1)}
            disabled={(page + 1) * 50 >= totalElements}
            className="form-button"
          >
            Következő
          </button>
        </div>
      </div>
    </div>
  )
}

