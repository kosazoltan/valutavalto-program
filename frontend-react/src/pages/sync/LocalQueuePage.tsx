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
import { logger } from '../../utils/logger';

export default function LocalQueuePage() {
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
      const [drafts, localTransfers, localBankTransactions, localHandoverOperations, localAuditEvents] = await Promise.all([
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
        <h1 className="text-xl font-bold text-gray-800 mb-3">Helyi Queue</h1>
        <p className="text-gray-600">Ez a nézet csak Electron környezetben érhető el.</p>
      </div>
    )
  }

  if (loading) {
    return <div className="flex items-center justify-center h-64">Betöltés...</div>
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Clock3 />
          Helyi Queue és Audit
        </h1>
        <div className="flex gap-2">
          <button onClick={() => void loadQueue()} className="form-button flex items-center gap-1">
            <RefreshCw size={16} />
            Frissítés
          </button>
          <button onClick={() => void handleSync()} disabled={syncing} className="form-button-primary flex items-center gap-1">
            <RefreshCw size={16} />
            {syncing ? 'Szinkron...' : 'Szinkron indítása'}
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="form-panel"><div className="text-sm text-gray-500">Receipt draft</div><div className="text-2xl font-bold">{receiptDrafts.length}</div></div>
        <div className="form-panel"><div className="text-sm text-gray-500">Transfer queue</div><div className="text-2xl font-bold">{transfers.length}</div></div>
        <div className="form-panel"><div className="text-sm text-gray-500">Bank queue</div><div className="text-2xl font-bold">{bankTransactions.length}</div></div>
        <div className="form-panel"><div className="text-sm text-gray-500">Handover queue</div><div className="text-2xl font-bold">{handoverOperations.length}</div></div>
      </div>

      <div className="form-panel">
        <h2 className="text-lg font-bold mb-3 flex items-center gap-2"><FileText size={18} />Függő bizonylatok</h2>
        <table className="data-grid w-full">
          <thead>
            <tr><th>Referencia</th><th>Típus</th><th>Létrehozva</th><th>Állapot</th></tr>
          </thead>
          <tbody>
            {receiptDrafts.length === 0 ? (
              <tr><td colSpan={4} className="text-center text-gray-500 py-4">Nincs függő bizonylat</td></tr>
            ) : receiptDrafts.map((draft) => (
              <tr key={draft.id}>
                <td className="font-mono">{draft.referenceNumber}</td>
                <td>{draft.title}</td>
                <td>{new Date(draft.createdAt).toLocaleString('hu-HU')}</td>
                <td><span className="badge badge-yellow">{draft.statusLabel}</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="form-panel">
        <h2 className="text-lg font-bold mb-3 flex items-center gap-2"><ArrowLeftRight size={18} />Függő treasury mozgások</h2>
        <table className="data-grid w-full">
          <thead>
            <tr><th>Queue</th><th>Azonosító</th><th>Részlet</th><th>Létrehozva</th></tr>
          </thead>
          <tbody>
            {transfers.length === 0 && bankTransactions.length === 0 && handoverOperations.length === 0 ? (
              <tr><td colSpan={4} className="text-center text-gray-500 py-4">Nincs függő treasury queue elem</td></tr>
            ) : (
              <>
                {transfers.map((transfer) => (
                  <tr key={`transfer-${transfer.id}`}>
                    <td>Transfer</td>
                    <td className="font-mono">{transfer.transferNumber}</td>
                    <td>{transfer.currencyCode} {transfer.amount.toLocaleString('hu-HU')}</td>
                    <td>{new Date(transfer.createdAt).toLocaleString('hu-HU')}</td>
                  </tr>
                ))}
                {bankTransactions.map((transaction) => (
                  <tr key={`bank-${transaction.id}`}>
                    <td>Bank</td>
                    <td className="font-mono">#{Math.abs(transaction.id)}</td>
                    <td>{transaction.transactionType} {transaction.currencyCode} {transaction.amount.toLocaleString('hu-HU')}</td>
                    <td>{new Date(transaction.createdAt).toLocaleString('hu-HU')}</td>
                  </tr>
                ))}
                {handoverOperations.map((operation) => (
                  <tr key={operation.id}>
                    <td>Handover</td>
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
        <h2 className="text-lg font-bold mb-3 flex items-center gap-2"><ClipboardList size={18} />Lokális audit trail</h2>
        <table className="data-grid w-full">
          <thead>
            <tr><th>Entity</th><th>Esemény</th><th>Referencia</th><th>Állapot</th><th>Létrehozva</th><th>Retention</th></tr>
          </thead>
          <tbody>
            {auditEvents.length === 0 ? (
              <tr><td colSpan={6} className="text-center text-gray-500 py-4">Nincs lokális audit esemény</td></tr>
            ) : auditEvents.map((event) => (
              <tr key={event.id}>
                <td>{event.entityType}</td>
                <td>{event.eventType}</td>
                <td className="font-mono">{event.referenceNumber || '-'}</td>
                <td><span className="badge badge-blue">{event.status}</span></td>
                <td>{new Date(event.createdAt).toLocaleString('hu-HU')}</td>
                <td>{new Date(event.retentionUntil).toLocaleDateString('hu-HU')}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}