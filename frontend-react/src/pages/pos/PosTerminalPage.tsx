import { useState, useEffect, useCallback } from 'react'
import { Activity, CreditCard, Eye, RefreshCw, Search } from 'lucide-react'
import {
  posTerminalApi,
  type PosTerminal,
  type PosTerminalRuntimeStatus,
} from '../../services/api/index'
import { safeArray } from '@/utils/safeArray'
import { logger } from '../../utils/logger'
import { toast } from '../../components/ui/toaster'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

export default function PosTerminalPage() {
  const { t } = useTranslation()
  const [terminals, setTerminals] = useState<PosTerminal[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [terminalStatuses, setTerminalStatuses] = useState<
    Record<string, PosTerminalRuntimeStatus>
  >({})
  const [statusLoading, setStatusLoading] = useState<Record<string, boolean>>({})
  const [selectedTerminal, setSelectedTerminal] = useState<PosTerminal | null>(null)
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      setTerminals(await posTerminalApi.list())
    } catch (err) {
      logger.error('PosTerminalPage', 'POS terminálok betöltési hiba:', err)
      setError('Nem sikerült betölteni a POS terminálokat')
      toast.error('Hiba', 'POS terminálok betöltése sikertelen')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const filtered = safeArray<PosTerminal>(terminals).filter(
    (t) =>
      !searchTerm ||
      t.terminalId.toLowerCase().includes(searchTerm.toLowerCase()) ||
      t.terminalName.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  const loadStatus = async (terminalId: string) => {
    try {
      setStatusLoading((current) => ({ ...current, [terminalId]: true }))
      setError(null)
      const status = await posTerminalApi.status(terminalId)
      setTerminalStatuses((current) => ({ ...current, [terminalId]: status }))
    } catch (err) {
      logger.error('PosTerminalPage', 'POS terminál státusz hiba:', err)
      setError('Nem sikerült lekérdezni a POS terminál állapotát')
      toast.error('Hiba', 'POS terminál állapotlekérdezés sikertelen')
    } finally {
      setStatusLoading((current) => ({ ...current, [terminalId]: false }))
    }
  }

  const loadDetails = async (id: string) => {
    try {
      setDetailLoadingId(id)
      setError(null)
      setSelectedTerminal(await posTerminalApi.getById(id))
    } catch (err) {
      logger.error('PosTerminalPage', 'POS terminál részletek hiba:', err)
      setError('Nem sikerült betölteni a POS terminál részleteit')
      toast.error('Hiba', 'POS terminál részletek betöltése sikertelen')
    } finally {
      setDetailLoadingId(null)
    }
  }

  const renderRuntimeStatus = (terminal: PosTerminal) => {
    const status = terminalStatuses[terminal.terminalId]
    if (!status)
      return <span className="badge badge-gray">{i18n.t('literals.nincs-lekerdezve')}</span>
    return (
      <span className={`badge ${status.connected ? 'badge-green' : 'badge-gray'}`}>
        {status.connected ? 'Elérhető' : 'Nem elérhető'}
      </span>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <CreditCard />
          {t('pos.posTerminalok')}
        </h1>
      </div>

      {/* Keresés */}
      <div className="flex gap-2 items-center">
        <Search size={16} className="text-gray-400" />
        <input
          className="form-input flex-1"
          placeholder="Keresés terminál ID vagy név alapján..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
        <button onClick={() => void loadData()} className="form-button" title="Frissítés">
          <RefreshCw size={16} />
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {selectedTerminal && (
        <section
          className="form-panel border-blue-200 bg-blue-50"
          data-testid="pos-terminal-detail-panel"
        >
          <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
            <div>
              <h2 className="text-base font-bold text-blue-950">{selectedTerminal.terminalName}</h2>
              <p className="font-mono text-sm text-blue-800">{selectedTerminal.terminalId}</p>
            </div>
            <span className={`badge ${selectedTerminal.isActive ? 'badge-green' : 'badge-gray'}`}>
              {selectedTerminal.isActive ? 'Aktív' : 'Inaktív'}
            </span>
          </div>
          <dl className="mt-4 grid grid-cols-1 gap-3 text-sm sm:grid-cols-2 lg:grid-cols-4">
            <div>
              <dt className="text-gray-500">{t('commissions.fiok')}</dt>
              <dd className="font-medium text-gray-900">{selectedTerminal.branchName || '-'}</dd>
            </div>
            <div>
              <dt className="text-gray-500">{t('display.kapcsolat')}</dt>
              <dd className="font-medium text-gray-900">
                {selectedTerminal.connectionType || 'SERIAL'}
              </dd>
            </div>
            <div>
              <dt className="text-gray-500">{i18n.t('literals.com-ip')}</dt>
              <dd className="font-medium text-gray-900">
                {selectedTerminal.comPort || selectedTerminal.ipAddress || '-'}
              </dd>
            </div>
            <div>
              <dt className="text-gray-500">{t('customers.utolsoTranzakcio')}</dt>
              <dd className="font-medium text-gray-900">
                {selectedTerminal.lastTransactionAt
                  ? new Date(selectedTerminal.lastTransactionAt).toLocaleString('hu-HU')
                  : '-'}
              </dd>
            </div>
          </dl>
        </section>
      )}

      {/* Terminálok lista */}
      {loading ? (
        <div>{i18n.t('literals.betoltes')}</div>
      ) : (
        <div className="form-panel">
          {filtered.length === 0 ? (
            <div className="text-center text-gray-500 py-8">
              {t('pos.nincsPosTerminalKonfiguralva')}
            </div>
          ) : (
            <>
              <div className="space-y-3 md:hidden">
                {filtered.map((terminal) => {
                  const runtimeStatus = terminalStatuses[terminal.terminalId]
                  return (
                    <article
                      key={terminal.id}
                      className="rounded border border-gray-200 bg-white p-3 shadow-sm"
                    >
                      <div className="mb-3 flex items-start justify-between gap-3">
                        <div className="min-w-0">
                          <p className="truncate text-lg font-bold text-gray-900">
                            {terminal.terminalName}
                          </p>
                          <p className="font-mono text-sm text-gray-500">{terminal.terminalId}</p>
                        </div>
                        <span
                          className={`badge ${terminal.isActive ? 'badge-green' : 'badge-gray'}`}
                        >
                          {terminal.isActive ? 'Aktív' : 'Inaktív'}
                        </span>
                      </div>
                      <dl className="grid grid-cols-2 gap-x-3 gap-y-2 text-sm">
                        <div>
                          <dt className="text-gray-500">{t('commissions.fiok')}</dt>
                          <dd className="text-gray-900">{terminal.branchName || '-'}</dd>
                        </div>
                        <div>
                          <dt className="text-gray-500">{t('display.kapcsolat')}</dt>
                          <dd className="text-gray-900">
                            {terminal.connectionType || 'SERIAL'} {terminal.comPort || ''}
                          </dd>
                        </div>
                        <div>
                          <dt className="text-gray-500">{i18n.t('literals.backend-allapot')}</dt>
                          <dd>{renderRuntimeStatus(terminal)}</dd>
                        </div>
                        <div>
                          <dt className="text-gray-500">{t('customers.utolsoTranzakcio')}</dt>
                          <dd className="text-gray-900">
                            {terminal.lastTransactionAt
                              ? new Date(terminal.lastTransactionAt).toLocaleString('hu-HU')
                              : '-'}
                          </dd>
                        </div>
                        {runtimeStatus?.message && (
                          <div className="col-span-2">
                            <dt className="text-gray-500">{i18n.t('literals.uzenet')}</dt>
                            <dd className="text-gray-900">{runtimeStatus.message}</dd>
                          </div>
                        )}
                      </dl>
                      <button
                        type="button"
                        onClick={() => void loadStatus(terminal.terminalId)}
                        disabled={Boolean(statusLoading[terminal.terminalId])}
                        className="form-button mt-3 flex w-full items-center justify-center gap-2 disabled:opacity-60"
                      >
                        <Activity size={14} />
                        {statusLoading[terminal.terminalId]
                          ? 'Lekérdezés...'
                          : 'Állapot lekérdezése'}
                      </button>
                      <button
                        type="button"
                        onClick={() => void loadDetails(terminal.id)}
                        disabled={detailLoadingId === terminal.id}
                        className="form-button mt-2 flex w-full items-center justify-center gap-2 disabled:opacity-60"
                      >
                        <Eye size={14} />
                        {detailLoadingId === terminal.id ? 'Betöltés...' : 'Részletek'}
                      </button>
                    </article>
                  )
                })}
              </div>

              <div className="hidden overflow-x-auto md:block">
                <table className="data-grid w-full">
                  <thead>
                    <tr>
                      <th>{t('pos.terminalId2')}</th>
                      <th>{t('display.megnevezes')}</th>
                      <th>{t('commissions.fiok')}</th>
                      <th>{t('display.kapcsolat')}</th>
                      <th>{t('customers.utolsoTranzakcio')}</th>
                      <th>{t('common.status')}</th>
                      <th>{i18n.t('literals.backend-allapot')}</th>
                      <th className="w-44">{t('common.actions')}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filtered.map((terminal) => (
                      <tr key={terminal.id}>
                        <td className="font-mono text-sm">{terminal.terminalId}</td>
                        <td>{terminal.terminalName}</td>
                        <td>{terminal.branchName || '-'}</td>
                        <td className="text-sm">
                          {terminal.connectionType || 'SERIAL'} {terminal.comPort || ''}
                        </td>
                        <td className="text-sm">
                          {terminal.lastTransactionAt
                            ? new Date(terminal.lastTransactionAt).toLocaleString('hu-HU')
                            : '-'}
                        </td>
                        <td>
                          <span
                            className={`badge ${terminal.isActive ? 'badge-green' : 'badge-gray'}`}
                          >
                            {terminal.isActive ? 'Aktív' : 'Inaktív'}
                          </span>
                        </td>
                        <td>{renderRuntimeStatus(terminal)}</td>
                        <td>
                          <div className="flex flex-wrap gap-2">
                            <button
                              type="button"
                              onClick={() => void loadStatus(terminal.terminalId)}
                              disabled={Boolean(statusLoading[terminal.terminalId])}
                              className="form-button text-xs"
                            >
                              {statusLoading[terminal.terminalId] ? 'Lekérdezés...' : 'Állapot'}
                            </button>
                            <button
                              type="button"
                              onClick={() => void loadDetails(terminal.id)}
                              disabled={detailLoadingId === terminal.id}
                              className="form-button text-xs"
                            >
                              {detailLoadingId === terminal.id ? 'Betöltés...' : 'Részletek'}
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </div>
      )}
    </div>
  )
}
