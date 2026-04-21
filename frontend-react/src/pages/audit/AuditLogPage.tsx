import { useState, useEffect, useCallback } from 'react'
import { Shield, Search, ChevronLeft, ChevronRight, X } from 'lucide-react'
import { auditLogApi } from '../../services/api/index'
import type { AuditLog } from '../../services/api/index'
import { logger } from '../../utils/logger';

/**
 * AuditLogPage — érzékeny műveletek audit naplója.
 * Szűrők: dátum tartomány, akció típus, pénztáros, iroda.
 * Részletek modal: régi ↔ új érték diff.
 *
 * Ctrl+U hotkey-vel elérhető (admin).
 */

// Akció típusok szűréshez
const ACTION_TYPES = [
  { value: '', label: 'Mind' },
  { value: 'RATE_OVERRIDE', label: 'Árfolyam felülírás' },
  { value: 'RATE_CHANGE', label: 'Árfolyam változás' },
  { value: 'RATE_APPROVE', label: 'Árfolyam jóváhagyás' },
  { value: 'RATE_PUBLISH', label: 'Árfolyam publikálás' },
  { value: 'RATE_REVOKE', label: 'Árfolyam visszavonás' },
  { value: 'STORNO_APPROVE', label: 'Sztornó jóváhagyás' },
  { value: 'TRANSACTION_STORNO', label: 'Tranzakció sztornó' },
  { value: 'TRANSACTION_PARTIAL_REFUND', label: 'Részleges visszatérítés' },
  { value: 'TRANSACTION_MODIFY', label: 'Tranzakció módosítás' },
  { value: 'FEE_DISCOUNT', label: 'Díjkedvezmény' },
  { value: 'SUPERVISOR_OVERRIDE', label: 'Supervisor felülírás' },
  { value: 'USER_LOGIN', label: 'Bejelentkezés' },
  { value: 'USER_LOGOUT', label: 'Kijelentkezés' },
  { value: 'PERMISSION_CHANGE', label: 'Jogosultság változás' },
]

export default function AuditLogPage() {
  const [logs, setLogs] = useState<AuditLog[]>([])
  const [loading, setLoading] = useState(true)
  const [fromDate, setFromDate] = useState('')
  const [toDate, setToDate] = useState('')
  const [actionFilter, setActionFilter] = useState('')
  const [workerFilter, setWorkerFilter] = useState('')
  const [branchFilter, setBranchFilter] = useState('')
  const [searchTerm, setSearchTerm] = useState('')
  const [page, setPage] = useState(0)
  const [totalElements, setTotalElements] = useState(0)
  const [selectedLog, setSelectedLog] = useState<AuditLog | null>(null)

  const loadLogs = useCallback(async () => {
    try {
      setLoading(true)
      const from = fromDate ? `${fromDate}T00:00:00` : undefined
      const to = toDate ? `${toDate}T23:59:59` : undefined

      let result: { content: AuditLog[]; totalElements: number }

      if (actionFilter) {
        result = await auditLogApi.getByAction(actionFilter, from, to, page, 50)
      } else if (workerFilter) {
        result = await auditLogApi.getByWorker(workerFilter, from, to, page, 50)
      } else if (branchFilter) {
        result = await auditLogApi.getByBranch(branchFilter, from, to, page, 50)
      } else {
        // Fallback: általános dátum szűrés (rendszer logok)
        result = await auditLogApi.getAll(from, to, page, 50)
      }

      setLogs(Array.isArray(result?.content) ? result.content : [])
      setTotalElements(typeof result?.totalElements === 'number' ? result.totalElements : 0)
    } catch (error) {
      logger.error('AuditLogPage', 'Hiba az audit logok betöltésekor:', error)
    } finally {
      setLoading(false)
    }
  }, [fromDate, toDate, actionFilter, workerFilter, branchFilter, page])

  useEffect(() => {
    void loadLogs()
  }, [loadLogs])

  // Szűrt logok (kliens oldali kereséssel)
  const filteredLogs = logs.filter(log =>
    searchTerm === '' ||
    log.action?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    log.entityType?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    log.userName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    log.branchName?.toLowerCase().includes(searchTerm.toLowerCase())
  )

  // Akció badge szín
  const getActionColor = (action: string): string => {
    if (action?.includes('STORNO')) return 'bg-red-100 text-red-700'
    if (action?.includes('OVERRIDE')) return 'bg-orange-100 text-orange-700'
    if (action?.includes('DISCOUNT')) return 'bg-yellow-100 text-yellow-700'
    if (action?.includes('RATE')) return 'bg-blue-100 text-blue-700'
    if (action?.includes('LOGIN') || action?.includes('LOGOUT')) return 'bg-gray-100 text-gray-700'
    return 'bg-purple-100 text-purple-700'
  }

  // JSON diff megjelenítő
  const renderDiff = (oldVal: string | undefined, newVal: string | undefined) => {
    const parseJson = (val: string | undefined) => {
      if (!val) return null
      try { return JSON.parse(val) } catch { return val }
    }

    const oldObj = parseJson(oldVal)
    const newObj = parseJson(newVal)

    if (!oldObj && !newObj) return <p className="text-gray-500 text-sm">Nincs részletes adat</p>

    return (
      <div className="grid grid-cols-2 gap-4">
        <div>
          <h4 className="text-sm font-semibold text-red-600 mb-2">Régi érték</h4>
          <pre className="bg-red-50 p-3 rounded text-xs overflow-auto max-h-60">
            {typeof oldObj === 'object' ? JSON.stringify(oldObj, null, 2) : String(oldObj ?? '—')}
          </pre>
        </div>
        <div>
          <h4 className="text-sm font-semibold text-green-600 mb-2">Új érték</h4>
          <pre className="bg-green-50 p-3 rounded text-xs overflow-auto max-h-60">
            {typeof newObj === 'object' ? JSON.stringify(newObj, null, 2) : String(newObj ?? '—')}
          </pre>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Shield className="text-primary-600" />
          Audit Log — Érzékeny Műveletek
        </h1>
        <span className="text-sm text-gray-500">
          Összesen: {totalElements} bejegyzés
        </span>
      </div>

      {/* Szűrők */}
      <div className="form-panel space-y-4">
        <div className="grid grid-cols-5 gap-4">
          <div>
            <label className="form-label">Kezdő dátum</label>
            <input
              type="date"
              className="form-input"
              value={fromDate}
              onChange={(e) => { setFromDate(e.target.value); setPage(0) }}
            />
          </div>
          <div>
            <label className="form-label">Vég dátum</label>
            <input
              type="date"
              className="form-input"
              value={toDate}
              onChange={(e) => { setToDate(e.target.value); setPage(0) }}
            />
          </div>
          <div>
            <label className="form-label">Akció típus</label>
            <select
              className="form-input"
              value={actionFilter}
              onChange={(e) => { setActionFilter(e.target.value); setPage(0) }}
            >
              {ACTION_TYPES.map(at => (
                <option key={at.value} value={at.value}>{at.label}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="form-label">Pénztáros ID</label>
            <input
              type="text"
              className="form-input"
              placeholder="Worker ID..."
              value={workerFilter}
              onChange={(e) => { setWorkerFilter(e.target.value); setPage(0) }}
            />
          </div>
          <div>
            <label className="form-label">Iroda ID</label>
            <input
              type="text"
              className="form-input"
              placeholder="Branch ID..."
              value={branchFilter}
              onChange={(e) => { setBranchFilter(e.target.value); setPage(0) }}
            />
          </div>
        </div>
        <div className="relative max-w-md">
          <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
          <input
            type="text"
            className="form-input pl-8"
            placeholder="Szabad szavas keresés..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      {/* Tábla */}
      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>Időpont</th>
              <th>Akció</th>
              <th>Entitás</th>
              <th>Pénztáros</th>
              <th>Iroda</th>
              <th>IP cím</th>
              <th>Részletek</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={7} className="text-center py-8">Betöltés...</td></tr>
            ) : filteredLogs.length === 0 ? (
              <tr><td colSpan={7} className="text-center text-gray-500 py-8">Nincs találat</td></tr>
            ) : (
              filteredLogs.map((log) => (
                <tr key={log.id} className="hover:bg-gray-50 cursor-pointer">
                  <td className="text-sm">{new Date(log.createdAt).toLocaleString('hu-HU')}</td>
                  <td>
                    <span className={`px-2 py-1 rounded text-xs font-medium ${getActionColor(log.action)}`}>
                      {log.action}
                    </span>
                  </td>
                  <td>
                    <div className="text-sm">{log.entityType}</div>
                    <div className="text-xs text-gray-400 font-mono">{log.entityId?.slice(0, 8)}...</div>
                  </td>
                  <td className="text-sm">{log.userName || '—'}</td>
                  <td className="text-sm">{log.branchName || '—'}</td>
                  <td className="text-xs text-gray-500">{log.ipAddress || '—'}</td>
                  <td>
                    <button
                      onClick={() => setSelectedLog(log)}
                      className="text-primary-600 hover:text-primary-800 text-sm font-medium"
                    >
                      Részletek
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>

        {/* Pagination */}
        <div className="flex justify-between items-center mt-4">
          <button
            onClick={() => setPage(p => Math.max(0, p - 1))}
            disabled={page === 0}
            className="form-button flex items-center gap-1"
          >
            <ChevronLeft size={16} /> Előző
          </button>
          <span className="text-sm text-gray-600">
            Oldal {page + 1} / {Math.max(1, Math.ceil(totalElements / 50))}
          </span>
          <button
            onClick={() => setPage(p => p + 1)}
            disabled={(page + 1) * 50 >= totalElements}
            className="form-button flex items-center gap-1"
          >
            Következő <ChevronRight size={16} />
          </button>
        </div>
      </div>

      {/* Részletek Modal */}
      {selectedLog && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => setSelectedLog(null)}>
          <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[80vh] overflow-auto" onClick={e => e.stopPropagation()}>
            <div className="flex justify-between items-center p-4 border-b">
              <h3 className="text-lg font-bold text-gray-800">
                Audit Log Részletek
              </h3>
              <button onClick={() => setSelectedLog(null)} className="text-gray-400 hover:text-gray-600">
                <X size={20} />
              </button>
            </div>
            <div className="p-4 space-y-4">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span className="text-gray-500">Akció:</span>
                  <span className={`ml-2 px-2 py-1 rounded text-xs font-medium ${getActionColor(selectedLog.action)}`}>
                    {selectedLog.action}
                  </span>
                </div>
                <div>
                  <span className="text-gray-500">Időpont:</span>
                  <span className="ml-2">{new Date(selectedLog.createdAt).toLocaleString('hu-HU')}</span>
                </div>
                <div>
                  <span className="text-gray-500">Entitás típus:</span>
                  <span className="ml-2 font-medium">{selectedLog.entityType}</span>
                </div>
                <div>
                  <span className="text-gray-500">Entitás ID:</span>
                  <span className="ml-2 font-mono text-xs">{selectedLog.entityId}</span>
                </div>
                <div>
                  <span className="text-gray-500">Pénztáros:</span>
                  <span className="ml-2">{selectedLog.userName || '—'}</span>
                </div>
                <div>
                  <span className="text-gray-500">Iroda:</span>
                  <span className="ml-2">{selectedLog.branchName || '—'}</span>
                </div>
                <div>
                  <span className="text-gray-500">IP cím:</span>
                  <span className="ml-2">{selectedLog.ipAddress || '—'}</span>
                </div>
                {selectedLog.reason && (
                  <div className="col-span-2">
                    <span className="text-gray-500">Indoklás:</span>
                    <span className="ml-2 italic">{selectedLog.reason}</span>
                  </div>
                )}
              </div>

              {/* Régi ↔ Új érték diff */}
              <div className="border-t pt-4">
                <h4 className="text-sm font-semibold text-gray-700 mb-3">Változások</h4>
                {selectedLog.changes ? (
                  <pre className="bg-gray-50 p-3 rounded text-xs overflow-auto max-h-40">
                    {selectedLog.changes}
                  </pre>
                ) : null}
                {renderDiff(selectedLog.oldValue, selectedLog.newValue)}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
