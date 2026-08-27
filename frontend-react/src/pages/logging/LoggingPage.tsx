import { useState, useEffect, useCallback } from 'react'
import { FileText, Download, Search } from 'lucide-react'
import { loggingApi, AuditLog } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import { downloadBlob } from '../../utils/downloadBlob'
import i18n from '../../i18n'

export default function LoggingPage() {
  const { t } = useTranslation()
  const [logs, setLogs] = useState<AuditLog[]>([])
  const [loading, setLoading] = useState(true)
  const [logType, setLogType] = useState<'system' | 'pos' | 'nav'>('system')
  const [fromDate, setFromDate] = useState('')
  const [toDate, setToDate] = useState('')
  const [searchTerm, setSearchTerm] = useState('')
  const [page, setPage] = useState(0)
  const [totalElements, setTotalElements] = useState(0)

  const loadLogs = useCallback(async () => {
    try {
      setLoading(true)
      let result
      if (logType === 'system') {
        result = await loggingApi.getSystemLogs(
          fromDate || undefined,
          toDate || undefined,
          page,
          50,
        )
      } else if (logType === 'pos') {
        result = await loggingApi.getPosLogs(fromDate || undefined, toDate || undefined, page, 50)
      } else {
        result = await loggingApi.getNavLogs(fromDate || undefined, toDate || undefined, page, 50)
      }
      setLogs(Array.isArray(result?.content) ? result.content : [])
      setTotalElements(typeof result?.totalElements === 'number' ? result.totalElements : 0)
    } catch (error) {
      logger.error('LoggingPage', 'Hiba a logok betöltésekor:', error)
    } finally {
      setLoading(false)
    }
  }, [logType, fromDate, toDate, page])

  useEffect(() => {
    void loadLogs()
  }, [loadLogs])

  const handleExport = async () => {
    try {
      const blob = await loggingApi.exportToCsv(fromDate || undefined, toDate || undefined)
      downloadBlob(blob, `logs-${logType}-${new Date().toISOString()}.csv`)
    } catch (error) {
      logger.error('LoggingPage', 'Hiba az exportálásnál:', error)
      toast.error('Exportálási hiba', 'Hiba történt az exportálás során')
    }
  }

  const filteredLogs = logs.filter(
    (log) =>
      log.action?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      log.entityType?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      log.userName?.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileText />
          {t('logging.logok')}
        </h1>
        <button onClick={handleExport} className="form-button-primary flex items-center gap-2">
          <Download size={16} />
          {t('logging.exportalasCsv')}
        </button>
      </div>

      <div className="form-panel space-y-4">
        <div className="grid grid-cols-4 gap-4">
          <div>
            <label className="form-label">{t('logging.logTipus')}</label>
            <select
              className="form-input"
              value={logType}
              onChange={(e) => setLogType(e.target.value as typeof logType)}
            >
              <option value="system">{t('logging.rendszerLogok')}</option>
              <option value="pos">{t('logging.posLogok')}</option>
              <option value="nav">{t('logging.navLogok')}</option>
            </select>
          </div>
          <div>
            <label className="form-label">{t('common.startDate')}</label>
            <input
              type="date"
              className="form-input"
              value={fromDate}
              onChange={(e) => setFromDate(e.target.value)}
            />
          </div>
          <div>
            <label className="form-label">{t('common.endDate')}</label>
            <input
              type="date"
              className="form-input"
              value={toDate}
              onChange={(e) => setToDate(e.target.value)}
            />
          </div>
          <div>
            <label className="form-label">{t('common.search')}</label>
            <div className="relative">
              <Search
                className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400"
                size={16}
              />
              <input
                type="text"
                className="form-input pl-8"
                placeholder="Keresés..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
        </div>
      </div>

      <div className="form-panel">
        <div className="mb-2 text-sm text-gray-600">
          {t('audit.osszesen')}
          {totalElements} {t('common.log')}
        </div>
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('audit.idopont')}</th>
              <th>{t('audit.akcio')}</th>
              <th>{t('commissions.entitasTipus')}</th>
              <th>{t('logging.entitasId')}</th>
              <th>{t('logging.felhasznalo')}</th>
              <th>{t('commissions.fok')}</th>
              <th>{t('common.ipAddress')}</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={7} className="text-center py-4">
                  {i18n.t('literals.betoltes')}
                </td>
              </tr>
            ) : filteredLogs.length === 0 ? (
              <tr>
                <td colSpan={7} className="text-center text-gray-500 py-4">
                  {t('common.noResult')}
                </td>
              </tr>
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
            onClick={() => setPage((p) => Math.max(0, p - 1))}
            disabled={page === 0}
            className="form-button"
          >
            {t('audit.elozo')}
          </button>
          <span className="text-sm text-gray-600">
            {t('audit.oldal')}
            {page + 1}
          </span>
          <button
            onClick={() => setPage((p) => p + 1)}
            disabled={(page + 1) * 50 >= totalElements}
            className="form-button"
          >
            {t('audit.kovetkezo')}
          </button>
        </div>
      </div>
    </div>
  )
}
