import { useState, useEffect, useMemo, useCallback } from 'react'
import { Receipt as ReceiptIcon, Search, Printer, Eye, Clock } from 'lucide-react'
import { receiptApi, Receipt } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { useAuthStore } from '../../stores/authStore'
import ReceiptPreviewModal from '../../components/electron/ReceiptPreviewModal'
import {
  getPendingReceiptDrafts,
  printPendingReceiptDraft,
  type PendingReceiptDraft,
} from '../../utils/localQueue'
import { isElectron } from '../../utils/electron'
import { logger } from '../../utils/logger';

export default function ReceiptPage() {
  const worker = useAuthStore((state) => state.worker)
  const [receipts, setReceipts] = useState<Receipt[]>([])
  const [localDrafts, setLocalDrafts] = useState<PendingReceiptDraft[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedReceipt, setSelectedReceipt] = useState<Receipt | null>(null)
  const [selectedDraft, setSelectedDraft] = useState<PendingReceiptDraft | null>(null)

  const loadData = useCallback(async (): Promise<void> => {
    try {
      setLoading(true)
      const [data, drafts] = await Promise.all([
        receiptApi.list(),
        isElectron() ? getPendingReceiptDrafts(worker) : Promise.resolve([]),
      ])
      setReceipts(data)
      setLocalDrafts(drafts)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      logger.error('ReceiptPage', 'Failed to load receipts:', err)
      toast.error('Hiba történt a betöltés során', errorMessage)
    } finally {
      setLoading(false)
    }
  }, [worker])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const filteredReceipts = useMemo(() => {
    if (!searchTerm) return receipts
    const term = searchTerm.toLowerCase()
    return receipts.filter(r =>
      r.receiptNumber?.toLowerCase().includes(term) ||
      r.navReceiptNumber?.toLowerCase().includes(term)
    )
  }, [receipts, searchTerm])

  const handlePrint = async (id: string): Promise<void> => {
    try {
      await receiptApi.print(id)
      await loadData()
      toast.success('Bizonylat nyomtatása elindítva')
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      toast.error('Hiba történt a nyomtatás során', errorMessage)
      logger.error('ReceiptPage', 'Failed to print receipt:', err)
    }
  }

  const filteredDrafts = useMemo(() => {
    if (!searchTerm) {
      return localDrafts
    }

    const lowered = searchTerm.toLowerCase()
    return localDrafts.filter((draft) =>
      draft.referenceNumber.toLowerCase().includes(lowered)
      || draft.title.toLowerCase().includes(lowered)
      || draft.receiptData.customerName?.toLowerCase().includes(lowered),
    )
  }, [localDrafts, searchTerm])

  if (loading) {
    return <div className="flex items-center justify-center h-64">Betöltés...</div>
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <ReceiptIcon />
          Bizonylatok
        </h1>
      </div>

      <div className="form-panel">
        <div>
          <label className="form-label">Keresés</label>
          <div className="relative">
            <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
            <input type="text" className="form-input pl-8" placeholder="Bizonylatszám..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
          </div>
        </div>
      </div>

      {filteredDrafts.length > 0 && (
        <div className="form-panel">
          <div className="mb-4 flex items-center gap-2 text-amber-800">
            <Clock size={18} />
            <h2 className="text-lg font-bold">Helyi, függő bizonylatok</h2>
          </div>
          <div className="mb-4 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
            Ezek a bizonylatok már mentve vannak Electronban, de még nem kaptak végleges szerveres bizonylatszámot.
          </div>
          <table className="data-grid w-full">
            <thead>
              <tr><th>Helyi referencia</th><th>Típus</th><th>Létrehozva</th><th>Állapot</th><th>Műveletek</th></tr>
            </thead>
            <tbody>
              {filteredDrafts.map((draft) => (
                <tr key={draft.id}>
                  <td className="font-mono">{draft.referenceNumber}</td>
                  <td>{draft.title}</td>
                  <td>{new Date(draft.createdAt).toLocaleString('hu-HU')}</td>
                  <td><span className="badge badge-yellow">{draft.statusLabel}</span></td>
                  <td>
                    <div className="flex gap-2">
                      <button onClick={() => setSelectedDraft(draft)} className="form-button text-xs"><Eye size={12} />Előnézet</button>
                      <button onClick={() => setSelectedDraft(draft)} className="form-button text-xs"><Printer size={12} />Vázlat nyomtatás</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr><th>Bizonylatszám</th><th>NAV bizonylatszám</th><th>Típus</th><th>Kiadás dátuma</th><th>Nyomtatva</th><th>Műveletek</th></tr>
          </thead>
          <tbody>
            {filteredReceipts.length === 0 ? (
              <tr><td colSpan={6} className="text-center text-gray-500 py-4">Nincs találat</td></tr>
            ) : (
              filteredReceipts.map((r) => (
                <tr key={r.id}>
                  <td className="font-mono">{r.receiptNumber}</td>
                  <td className="font-mono">{r.navReceiptNumber || '-'}</td>
                  <td>{r.receiptType}</td>
                  <td>{new Date(r.issueDate).toLocaleDateString('hu-HU')}</td>
                  <td><span className={`badge ${r.isPrinted ? 'badge-green' : 'badge-yellow'}`}>{r.isPrinted ? 'Igen' : 'Nem'}</span></td>
                  <td>
                    <div className="flex gap-2">
                      <button onClick={() => setSelectedReceipt(r)} className="form-button text-xs"><Eye size={12} />Részletek</button>
                      {!r.isPrinted && <button onClick={() => handlePrint(r.id)} className="form-button text-xs"><Printer size={12} />Nyomtatás</button>}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {selectedReceipt && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">Bizonylat részletek</h2>
              <button onClick={() => setSelectedReceipt(null)} className="text-gray-500">X</button>
            </div>
            <div className="space-y-2">
              <div><strong>Bizonylatszám:</strong> {selectedReceipt.receiptNumber}</div>
              <div><strong>NAV bizonylatszám:</strong> {selectedReceipt.navReceiptNumber || '-'}</div>
              <div><strong>Típus:</strong> {selectedReceipt.receiptType}</div>
              <div><strong>Kiadás dátuma:</strong> {new Date(selectedReceipt.issueDate).toLocaleString('hu-HU')}</div>
              <div><strong>Nyomtatva:</strong> {selectedReceipt.isPrinted ? 'Igen' : 'Nem'}</div>
              {selectedReceipt.content && (
                <div className="mt-4 p-4 bg-gray-50 rounded">
                  <strong>Tartalom:</strong>
                  <pre className="mt-2 text-sm">{selectedReceipt.content}</pre>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      <ReceiptPreviewModal
        isOpen={Boolean(selectedDraft)}
        onClose={() => setSelectedDraft(null)}
        receiptData={selectedDraft?.receiptData ?? null}
        qrCodeDataUrl={null}
        variant="draft"
        statusMessage="Ez helyi vázlat. A hivatalos bizonylat csak a szerveres szinkron és a végleges bizonylatszám kiosztása után tekinthető lezártnak."
        onPrint={async () => {
          if (!selectedDraft) {
            return
          }

          const printed = await printPendingReceiptDraft(selectedDraft.receiptData)
          if (!printed) {
            throw new Error('A vázlat nyomtatása nem érhető el ebben a környezetben')
          }
          toast.success('A helyi bizonylatvázlat nyomtatása elindítva')
        }}
      />
    </div>
  )
}

