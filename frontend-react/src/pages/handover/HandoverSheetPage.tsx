import { useState, useEffect, useCallback, useMemo } from 'react'
import { FileText, Plus, Printer, CheckCircle, Search, Eye } from 'lucide-react'
import { handoverSheetApi, HandoverSheet, cashDeskApi, CashDesk } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import {
  isElectronQueueAvailable,
  recordLocalAuditEvent,
  saveAndSyncPendingHandoverOperation,
} from '../../utils/electronTransactions'
import {
  getLocalPendingHandoverOperations,
  mapPendingHandoverGeneratesToSheets,
  type LocalPendingHandoverOperation,
} from '../../utils/localQueue'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

export default function HandoverSheetPage() {
  const { t } = useTranslation()
  const electronQueueAvailable = isElectronQueueAvailable()
  const [sheets, setSheets] = useState<HandoverSheet[]>([])
  const [cashDesks, setCashDesks] = useState<CashDesk[]>([])
  const [localPendingOperations, setLocalPendingOperations] = useState<
    LocalPendingHandoverOperation[]
  >([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [selectedSheet, setSelectedSheet] = useState<HandoverSheet | null>(null)
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)
  const [formData, setFormData] = useState({
    fromCashDeskId: '',
    toCashDeskId: '',
    transferDate: new Date().toISOString().split('T')[0],
    amounts: {},
  })

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await handoverSheetApi.list()
      setSheets(data)
      if (electronQueueAvailable) {
        setLocalPendingOperations(await getLocalPendingHandoverOperations())
      }
    } catch (err) {
      logger.error('HandoverSheetPage', 'Átadó lapok betöltési hiba:', err)
      setError('Hiba az átadó lapok betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [electronQueueAvailable])

  const loadCashDesks = useCallback(async () => {
    try {
      const data = await cashDeskApi.list()
      setCashDesks(data)
    } catch (err) {
      logger.error('HandoverSheetPage', 'Pénztárak betöltési hiba:', err)
      setError('Hiba a pénztárak betöltésekor')
    }
  }, [])

  useEffect(() => {
    void loadData()
    void loadCashDesks()
  }, [loadData, loadCashDesks])

  const filteredSheets = useMemo(() => {
    const cashDeskNames = new Map(cashDesks.map((desk) => [desk.id, desk.name]))
    const localGenerated = mapPendingHandoverGeneratesToSheets(
      localPendingOperations,
      cashDeskNames,
    )
    let filtered = [...localGenerated, ...sheets]
    if (searchTerm) {
      const term = searchTerm.toLowerCase()
      filtered = filtered.filter((s) => s.sheetNumber?.toLowerCase().includes(term))
    }
    return filtered
  }, [sheets, searchTerm, localPendingOperations, cashDesks])

  const handleGenerate = async () => {
    try {
      setError(null)
      if (electronQueueAvailable) {
        const outcome = await saveAndSyncPendingHandoverOperation({
          operationType: 'GENERATE',
          fromCashDeskId: formData.fromCashDeskId || '',
          toCashDeskId: formData.toCashDeskId || '',
          transferDate: (formData.transferDate || new Date().toISOString().split('T')[0]) as string,
          amounts: formData.amounts,
        })
        toast.success(
          outcome.allSavedSynced
            ? 'Átadó lap helyileg rögzítve és azonnal szinkronizálva'
            : 'Átadó lap helyileg rögzítve. A feltöltés az Electron queue-ból folytatódik.',
        )
      } else {
        await handoverSheetApi.generate(
          formData.fromCashDeskId || '',
          formData.toCashDeskId || '',
          (formData.transferDate || new Date().toISOString().split('T')[0]) as string,
          formData.amounts,
        )
        await recordLocalAuditEvent({
          entityType: 'HANDOVER_SHEET',
          eventType: 'GENERATE',
          payload: {
            fromCashDeskId: formData.fromCashDeskId || '',
            toCashDeskId: formData.toCashDeskId || '',
            transferDate: formData.transferDate,
            amounts: formData.amounts,
          },
          status: 'SERVER_FORWARDED',
        })
      }
      await loadData()
      setShowForm(false)
      if (!electronQueueAvailable) {
        toast.success('Átadó lap sikeresen létrehozva')
      }
    } catch (err) {
      logger.error('HandoverSheetPage', 'Generálási hiba:', err)
      setError('Hiba történt a generálás során')
    }
  }

  const handlePrint = async (id: string) => {
    try {
      setError(null)
      if (electronQueueAvailable) {
        const outcome = await saveAndSyncPendingHandoverOperation({
          operationType: 'PRINT',
          sheetId: id,
        })
        toast.success(
          outcome.allSavedSynced
            ? 'Nyomtatási kérés azonnal továbbítva'
            : 'Nyomtatási kérés helyileg mentve. Szinkron után kerül továbbításra.',
        )
      } else {
        await handoverSheetApi.print(id)
        await recordLocalAuditEvent({
          entityType: 'HANDOVER_SHEET',
          eventType: 'PRINT',
          entityId: id,
          payload: { id },
          status: 'SERVER_FORWARDED',
        })
        toast.success('Átadó lap nyomtatása elindítva')
      }
      await loadData()
    } catch (err) {
      logger.error('HandoverSheetPage', 'Nyomtatási hiba:', err)
      setError('Hiba történt a nyomtatás során')
    }
  }

  const handleViewDetails = async (id: string) => {
    try {
      setError(null)
      setDetailLoadingId(id)
      setSelectedSheet(await handoverSheetApi.getById(id))
    } catch (err) {
      logger.error('HandoverSheetPage', 'Átadó lap részletek betöltési hiba:', err)
      setError('Hiba az átadó lap részleteinek betöltésekor')
    } finally {
      setDetailLoadingId(null)
    }
  }

  const handleComplete = async (id: string) => {
    try {
      setError(null)
      if (electronQueueAvailable) {
        const outcome = await saveAndSyncPendingHandoverOperation({
          operationType: 'COMPLETE',
          sheetId: id,
        })
        toast.success(
          outcome.allSavedSynced
            ? 'Befejezési kérés azonnal továbbítva'
            : 'Befejezési kérés helyileg mentve. Szinkron után kerül továbbításra.',
        )
      } else {
        await handoverSheetApi.complete(id)
        await recordLocalAuditEvent({
          entityType: 'HANDOVER_SHEET',
          eventType: 'COMPLETE',
          entityId: id,
          payload: { id },
          status: 'SERVER_FORWARDED',
        })
      }
      await loadData()
      if (!electronQueueAvailable) {
        toast.success('Átadó lap sikeresen befejezve')
      }
    } catch (err) {
      logger.error('HandoverSheetPage', 'Befejezési hiba:', err)
      setError('Hiba történt a befejezés során')
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">{i18n.t('literals.betoltes')}</div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileText />
          {t('handover.atadoLapok')}
        </h1>
        <button
          type="button"
          onClick={() => setShowForm(true)}
          className="form-button-primary flex items-center gap-2"
        >
          <Plus size={16} />
          {t('handover.ujAtadoLap')}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="form-panel">
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
              placeholder="Lapszám..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>
      </div>

      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 w-full max-w-2xl">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">{t('handover.ujAtadoLap')}</h2>
              <button type="button" onClick={() => setShowForm(false)} className="text-gray-500">
                {i18n.t('literals.x-2')}
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label htmlFor="fromCashDesk" className="form-label">
                  {t('handover.kuldoPenztar')}
                </label>
                <select
                  id="fromCashDesk"
                  title="Küldő pénztár kiválasztása"
                  className="form-input"
                  value={formData.fromCashDeskId}
                  onChange={(e) => setFormData({ ...formData, fromCashDeskId: e.target.value })}
                >
                  <option value="">{i18n.t('literals.valasszon')}</option>
                  {cashDesks.map((cd) => (
                    <option key={cd.id} value={cd.id}>
                      {cd.name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label htmlFor="toCashDesk" className="form-label">
                  {t('handover.fogadoPenztar')}
                </label>
                <select
                  id="toCashDesk"
                  title="Fogadó pénztár kiválasztása"
                  className="form-input"
                  value={formData.toCashDeskId}
                  onChange={(e) => setFormData({ ...formData, toCashDeskId: e.target.value })}
                >
                  <option value="">{i18n.t('literals.valasszon')}</option>
                  {cashDesks.map((cd) => (
                    <option key={cd.id} value={cd.id}>
                      {cd.name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label htmlFor="transferDate" className="form-label">
                  {t('handover.atadasDatuma')}
                </label>
                <input
                  id="transferDate"
                  type="date"
                  className="form-input"
                  placeholder="éééé-hh-nn"
                  value={formData.transferDate}
                  onChange={(e) => setFormData({ ...formData, transferDate: e.target.value })}
                />
              </div>
              <div className="flex justify-end gap-2 pt-4 border-t">
                <button type="button" onClick={() => setShowForm(false)} className="form-button">
                  {t('common.cancel')}
                </button>
                <button type="button" onClick={handleGenerate} className="form-button-primary">
                  {t('darius.generalas')}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="form-panel">
        {localPendingOperations.length > 0 && (
          <div className="mb-4 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
            {localPendingOperations.length} {t('handover.helyiHandoverMuveletVar')}
          </div>
        )}
        {selectedSheet && (
          <div className="mb-4 rounded border border-blue-200 bg-blue-50 px-4 py-3 text-sm text-blue-900">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <div className="font-semibold">{selectedSheet.sheetNumber}</div>
                <div className="text-xs text-blue-700">
                  {selectedSheet.fromCashDeskName ?? selectedSheet.fromCashDeskId}
                  {i18n.t('literals.lit-37')}{' '}
                  {selectedSheet.toCashDeskName ?? selectedSheet.toCashDeskId}
                </div>
              </div>
              <span className="badge badge-yellow">{selectedSheet.status}</span>
            </div>
            <div className="mt-2 grid gap-2 text-xs md:grid-cols-3">
              <div>
                <span className="font-semibold">
                  {t('common.date')}
                  {i18n.t('literals.lit-7')}
                </span>{' '}
                {new Date(selectedSheet.transferDate).toLocaleDateString('hu-HU')}
              </div>
              <div>
                <span className="font-semibold">
                  {t('handover.kuldo')}
                  {i18n.t('literals.lit-7')}
                </span>{' '}
                {selectedSheet.fromCashDeskName ?? selectedSheet.fromCashDeskId}
              </div>
              <div>
                <span className="font-semibold">
                  {t('handover.fogado')}
                  {i18n.t('literals.lit-7')}
                </span>{' '}
                {selectedSheet.toCashDeskName ?? selectedSheet.toCashDeskId}
              </div>
            </div>
          </div>
        )}
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('handover.lapszam')}</th>
              <th>{t('handover.kuldo')}</th>
              <th>{t('handover.fogado')}</th>
              <th>{t('common.date')}</th>
              <th>{t('common.status')}</th>
              <th>{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {filteredSheets.length === 0 ? (
              <tr>
                <td colSpan={6} className="text-center text-gray-500 py-4">
                  {t('common.noResult')}
                </td>
              </tr>
            ) : (
              filteredSheets.map((s) => (
                <tr key={s.id}>
                  <td className="font-mono">{s.sheetNumber}</td>
                  <td>{s.fromCashDeskName}</td>
                  <td>{s.toCashDeskName}</td>
                  <td>{new Date(s.transferDate).toLocaleDateString('hu-HU')}</td>
                  <td>
                    <span
                      className={`badge ${s.status === 'COMPLETED' ? 'badge-green' : s.status === 'PENDING_SYNC' ? 'badge-yellow' : 'badge-yellow'}`}
                    >
                      {s.status === 'PENDING_SYNC' ? 'HELYBEN MENTVE' : s.status}
                    </span>
                  </td>
                  <td>
                    <div className="flex gap-2">
                      <button
                        type="button"
                        onClick={() => void handleViewDetails(s.id)}
                        disabled={s.status === 'PENDING_SYNC' || detailLoadingId === s.id}
                        className="form-button text-xs disabled:opacity-50"
                      >
                        <Eye
                          size={12}
                          className={detailLoadingId === s.id ? 'animate-pulse' : ''}
                        />
                        {t('common.details')}
                      </button>
                      <button
                        type="button"
                        onClick={() => handlePrint(s.id)}
                        disabled={s.status === 'PENDING_SYNC'}
                        className="form-button text-xs disabled:opacity-50"
                      >
                        <Printer size={12} />
                        {t('common.print')}
                      </button>
                      {s.status !== 'COMPLETED' && (
                        <button
                          type="button"
                          onClick={() => handleComplete(s.id)}
                          disabled={s.status === 'PENDING_SYNC'}
                          className="form-button text-xs disabled:opacity-50"
                        >
                          <CheckCircle size={12} />
                          {t('archiving.befejezes')}
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
