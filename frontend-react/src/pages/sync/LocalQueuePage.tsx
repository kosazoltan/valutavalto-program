import { useCallback, useEffect, useState } from 'react'
import { Clock3, RefreshCw, FileText, ArrowLeftRight, ClipboardList } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { useAuthStore } from '../../stores/authStore'
import {
  getLocalAuditEvents,
  getLocalPendingBankTransactions,
  getLocalPendingHandoverOperations,
  getLocalPendingTransfers,
  getPendingReceiptDrafts,
  type LocalAuditEventView,
  type LocalPendingHandoverOperation,
  type PendingReceiptDraft,
} from '../../utils/localQueue'
import { isElectron } from '../../utils/electron'
import type { BankTransaction, Transfer } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

export default function LocalQueuePage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const [loading, setLoading] = useState(true)
  const [syncing, setSyncing] = useState(false)
  const [receiptDrafts, setReceiptDrafts] = useState<PendingReceiptDraft[]>([])
  const [transfers, setTransfers] = useState<Transfer[]>([])
  const [bankTransactions, setBankTransactions] = useState<BankTransaction[]>([])
  const [handoverOperations, setHandoverOperations] = useState<LocalPendingHandoverOperation[]>([])
  const [auditEvents, setAuditEvents] = useState<LocalAuditEventView[]>([])

  const loadQueue = useCallback(async () => {
    if (!isElectron()) {
      setLoading(false)
      return
    }

    setLoading(true)
    try {
      const [
        drafts,
        localTransfers,
        localBankTransactions,
        localHandoverOperations,
        localAuditEvents,
      ] = await Promise.all([
        getPendingReceiptDrafts(worker),
        getLocalPendingTransfers(worker),
        getLocalPendingBankTransactions(),
        getLocalPendingHandoverOperations(),
        getLocalAuditEvents(150),
      ])
      setReceiptDrafts(drafts)
      setTransfers(localTransfers)
      setBankTransactions(localBankTransactions)
      setHandoverOperations(localHandoverOperations)
      setAuditEvents(localAuditEvents)
    } catch (error) {
      logger.error('LocalQueuePage', 'Helyi queue betöltési hiba:', error)
      toast.error('Hiba történt a helyi queue betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [worker])

  useEffect(() => {
    void loadQueue()
  }, [loadQueue])

  const handleSync = async () => {
    if (!window.electronAPI?.syncOffline) {
      return
    }

    setSyncing(true)
    try {
      const synced = await window.electronAPI.syncOffline()
      toast.success(`Szinkron lefutott, ${synced} rekord került továbbításra`)
      await loadQueue()
    } catch (error) {
      logger.error('LocalQueuePage', 'Helyi queue szinkron hiba:', error)
      toast.error('A helyi queue szinkronizálása sikertelen')
    } finally {
      setSyncing(false)
    }
  }

  if (!isElectron()) {
    return (
      <div className="form-panel">
        <h1 className="text-xl font-bold text-gray-800 mb-3">{t('sync.helyiQueue')}</h1>
        <p className="text-gray-600">{t('sync.ezANezetCsakElectronKornyezetbenErhetoEl')}</p>
      </div>
    )
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">{i18n.t('literals.betoltes')}</div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Clock3 />
          {t('sync.helyiQueueEsAudit')}
        </h1>
        <div className="flex gap-2">
          <button onClick={() => void loadQueue()} className="form-button flex items-center gap-1">
            <RefreshCw size={16} />
            {t('common.refresh')}
          </button>
          <button
            onClick={() => void handleSync()}
            disabled={syncing}
            className="form-button-primary flex items-center gap-1"
          >
            <RefreshCw size={16} />
            {syncing ? 'Szinkron...' : 'Szinkron indítása'}
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="form-panel">
          <div className="text-sm text-gray-500">{t('sync.receiptDraft')}</div>
          <div className="text-lg font-bold">{receiptDrafts.length}</div>
        </div>
        <div className="form-panel">
          <div className="text-sm text-gray-500">{t('sync.transferQueue')}</div>
          <div className="text-lg font-bold">{transfers.length}</div>
        </div>
        <div className="form-panel">
          <div className="text-sm text-gray-500">{t('sync.bankQueue')}</div>
          <div className="text-lg font-bold">{bankTransactions.length}</div>
        </div>
        <div className="form-panel">
          <div className="text-sm text-gray-500">{t('sync.handoverQueue')}</div>
          <div className="text-lg font-bold">{handoverOperations.length}</div>
        </div>
      </div>

      <div className="form-panel">
        <h2 className="text-lg font-bold mb-3 flex items-center gap-2">
          <FileText size={18} />
          {t('sync.fuggoBizonylatok')}
        </h2>
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('sync.referencia')}</th>
              <th>{t('common.type')}</th>
              <th>{t('common.createdAt')}</th>
              <th>{t('common.status2')}</th>
            </tr>
          </thead>
          <tbody>
            {receiptDrafts.length === 0 ? (
              <tr>
                <td colSpan={4} className="text-center text-gray-500 py-4">
                  {t('sync.nincsFuggoBizonylat')}
                </td>
              </tr>
            ) : (
              receiptDrafts.map((draft) => (
                <tr key={draft.id}>
                  <td className="font-mono">{draft.referenceNumber}</td>
                  <td>{draft.title}</td>
                  <td>{new Date(draft.createdAt).toLocaleString('hu-HU')}</td>
                  <td>
                    <span className="badge badge-yellow">{draft.statusLabel}</span>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="form-panel">
        <h2 className="text-lg font-bold mb-3 flex items-center gap-2">
          <ArrowLeftRight size={18} />
          {t('sync.fuggoTreasuryMozgasok')}
        </h2>
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('sync.queue')}</th>
              <th>{t('sync.azonosito')}</th>
              <th>{t('sync.reszlet')}</th>
              <th>{t('common.createdAt')}</th>
            </tr>
          </thead>
          <tbody>
            {transfers.length === 0 &&
            bankTransactions.length === 0 &&
            handoverOperations.length === 0 ? (
              <tr>
                <td colSpan={4} className="text-center text-gray-500 py-4">
                  {t('sync.nincsFuggoTreasuryQueueElem')}
                </td>
              </tr>
            ) : (
              <>
                {transfers.map((transfer) => (
                  <tr key={`transfer-${transfer.id}`}>
                    <td>{t('sync.transfer')}</td>
                    <td className="font-mono">{transfer.transferNumber}</td>
                    <td>
                      {transfer.currencyCode} {transfer.amount.toLocaleString('hu-HU')}
                    </td>
                    <td>{new Date(transfer.createdAt).toLocaleString('hu-HU')}</td>
                  </tr>
                ))}
                {bankTransactions.map((transaction) => (
                  <tr key={`bank-${transaction.id}`}>
                    <td>{t('sync.bank')}</td>
                    <td className="font-mono">
                      {i18n.t('literals.lit-12')}
                      {Math.abs(transaction.id)}
                    </td>
                    <td>
                      {transaction.transactionType} {transaction.currencyCode}{' '}
                      {transaction.amount.toLocaleString('hu-HU')}
                    </td>
                    <td>{new Date(transaction.createdAt).toLocaleString('hu-HU')}</td>
                  </tr>
                ))}
                {handoverOperations.map((operation) => (
                  <tr key={operation.id}>
                    <td>{t('sync.handover')}</td>
                    <td className="font-mono">{operation.referenceNumber}</td>
                    <td>{operation.operationType}</td>
                    <td>{new Date(operation.createdAt).toLocaleString('hu-HU')}</td>
                  </tr>
                ))}
              </>
            )}
          </tbody>
        </table>
      </div>

      <div className="form-panel">
        <h2 className="text-lg font-bold mb-3 flex items-center gap-2">
          <ClipboardList size={18} />
          {t('sync.lokalisAuditTrail')}
        </h2>
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('sync.entity')}</th>
              <th>{t('sync.esemeny')}</th>
              <th>{t('sync.referencia')}</th>
              <th>{t('common.status2')}</th>
              <th>{t('common.createdAt')}</th>
              <th>{t('sync.retention')}</th>
            </tr>
          </thead>
          <tbody>
            {auditEvents.length === 0 ? (
              <tr>
                <td colSpan={6} className="text-center text-gray-500 py-4">
                  {t('sync.nincsLokalisAuditEsemeny')}
                </td>
              </tr>
            ) : (
              auditEvents.map((event) => (
                <tr key={event.id}>
                  <td>{event.entityType}</td>
                  <td>{event.eventType}</td>
                  <td className="font-mono">{event.referenceNumber || '-'}</td>
                  <td>
                    <span className="badge badge-blue">{event.status}</span>
                  </td>
                  <td>{new Date(event.createdAt).toLocaleString('hu-HU')}</td>
                  <td>{new Date(event.retentionUntil).toLocaleDateString('hu-HU')}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
