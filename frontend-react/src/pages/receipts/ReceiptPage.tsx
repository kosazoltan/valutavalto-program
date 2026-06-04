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
import { useTranslation } from 'react-i18next'

// A backend Receipt.receiptType = TransactionType.name() (enum-név). Magyar megjelenítő-címkék, hogy a
// tábla/részletek a típus-szűrővel konzisztens, olvasható szöveget mutassanak (a TransactionType.java
// magyar leírásai alapján). Ismeretlen érték → a nyers kód (fallback).
const RECEIPT_TYPE_LABELS: Record<string, string> = {
  BUY: 'Vétel',
  SELL: 'Eladás',
  REVERSAL: 'Sztornó',
  PARTIAL_REFUND: 'Részleges visszatérítés',
  CONVERSION: 'Konverzió',
  TRANSFER_OUT: 'Pénz-átadás',
  TRANSFER_IN: 'Pénz-átvétel',
  WESTERN_UNION_SEND: 'WU küldés',
  WESTERN_UNION_RECEIVE: 'WU fogadás',
  MONEYGRAM_SEND: 'MG küldés',
  MONEYGRAM_RECEIVE: 'MG fogadás',
  VIGNETTE: 'Autópálya matrica',
  PHONE_TOPUP: 'Telefon feltöltés',
  OTHER: 'Egyéb',
}
export const receiptTypeLabel = (code?: string): string => (code ? (RECEIPT_TYPE_LABELS[code.toUpperCase()] ?? code) : '—')

export default function ReceiptPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const [receipts, setReceipts] = useState<Receipt[]>([])
  const [localDrafts, setLocalDrafts] = useState<PendingReceiptDraft[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  // EXCMD b5b FR-BSZUR-01: bizonylattípus-szűrő (egyszerre egy aktív). A backend Receipt.receiptType =
  // TransactionType.name() (verifikálva: ReceiptService:166), ezért az ENUM-NEVEKRE szűrünk:
  // BUY/SELL/CONVERSION/TRANSFER_OUT/TRANSFER_IN/REVERSAL. A "csak ügyfeles" (FR-BSZUR-02) + ügyfél-adatlap
  // szűrőmezők + AML-jelölők (FR-03..05) richer list-adatot igényelnek (customerName/hufAmount/approver a
  // GET /receipts-ben) → következő increment (a list-DTO dúsítása). Itt a típus-szűrő a meglévő adatból.
  const [typeFilter, setTypeFilter] = useState<string>('ALL')
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
    const term = searchTerm.toLowerCase()
    return receipts.filter(r => {
      // EXCMD b5b FR-BSZUR-01: típus-szűrő (ALL = kikapcsolva). A receiptType case-insensitive egyezés.
      if (typeFilter !== 'ALL' && (r.receiptType ?? '').toUpperCase() !== typeFilter) return false
      if (!term) return true
      return (
        r.receiptNumber?.toLowerCase().includes(term) ||
        r.navReceiptNumber?.toLowerCase().includes(term)
      )
    })
  }, [receipts, searchTerm, typeFilter])

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
          {t('receipts.bizonylatok')}
        </h1>
      </div>

      <div className="form-panel">
        <div className="flex flex-wrap gap-4">
          <div className="flex-1 min-w-[200px]">
            <label className="form-label">{t('common.search')}</label>
            <div className="relative">
              <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
              <input type="text" className="form-input pl-8" placeholder="Bizonylatszám..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
            </div>
          </div>
          {/* EXCMD b5b FR-BSZUR-01: bizonylattípus-szűrő (egyszerre egy aktív; ALL = szűrés kikapcsolva). */}
          <div className="min-w-[200px]">
            <label className="form-label">Bizonylattípus</label>
            <select className="form-input" value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)}>
              {/* A backend Receipt.receiptType = TransactionType.name() — az enum-nevekre szűrünk (verifikálva:
                  ReceiptService:166, TransactionType.java). A "csak ügyfeles" (FR-BSZUR-02) richer list-adatot
                  igényel (customerName a GET /receipts-ben) → következő increment. */}
              <option value="ALL">Szűrés kikapcsolva (összes)</option>
              <option value="BUY">Csak vételi</option>
              <option value="SELL">Csak eladási</option>
              <option value="CONVERSION">Csak konverziós</option>
              <option value="TRANSFER_OUT">Csak pénz-átadási</option>
              <option value="TRANSFER_IN">Csak pénz-átvételi</option>
              <option value="REVERSAL">Csak stornózott</option>
            </select>
          </div>
        </div>
      </div>

      {filteredDrafts.length > 0 && (
        <div className="form-panel">
          <div className="mb-4 flex items-center gap-2 text-amber-800">
            <Clock size={18} />
            <h2 className="text-lg font-bold">{t('receipts.helyiFuggoBizonylatok')}</h2>
          </div>
          <div className="mb-4 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
            {t('receipts.ezekABizonylatokHelyilegVeglegesSzigoruSzamadasuSorszammalRendelkeznekNgm232014ASzerverSzinkronFolyamatbanVanASorszamNemFogMegvaltozniCsakASzerverOldaliAuditNaploEgeszulKi')}
          </div>
          <table className="data-grid w-full">
            <thead>
              <tr><th>{t('receipts.helyiReferencia')}</th><th>{t('common.type')}</th><th>{t('common.createdAt')}</th><th>{t('common.status2')}</th><th>{t('common.actions')}</th></tr>
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
                      <button onClick={() => setSelectedDraft(draft)} className="form-button text-xs"><Eye size={12} />{t('closing.elonezet')}</button>
                      <button onClick={() => setSelectedDraft(draft)} className="form-button text-xs"><Printer size={12} />{t('receipts.vazlatNyomtatas')}</button>
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
            <tr><th>{t('cashier.receiptNumber')}</th><th>{t('receipts.navBizonylatszam')}</th><th>{t('common.type')}</th><th>{t('cashier.issueDate')}</th><th>{t('cashier.printed')}</th><th>{t('common.actions')}</th></tr>
          </thead>
          <tbody>
            {filteredReceipts.length === 0 ? (
              <tr><td colSpan={6} className="text-center text-gray-500 py-4">{t('common.noResult')}</td></tr>
            ) : (
              filteredReceipts.map((r) => (
                <tr key={r.id}>
                  <td className="font-mono">{r.receiptNumber}</td>
                  <td className="font-mono">{r.navReceiptNumber || '-'}</td>
                  <td>{receiptTypeLabel(r.receiptType)}</td>
                  <td>{new Date(r.issueDate).toLocaleDateString('hu-HU')}</td>
                  <td><span className={`badge ${r.isPrinted ? 'badge-green' : 'badge-yellow'}`}>{r.isPrinted ? 'Igen' : 'Nem'}</span></td>
                  <td>
                    <div className="flex gap-2">
                      <button onClick={() => setSelectedReceipt(r)} className="form-button text-xs"><Eye size={12} />{t('common.details')}</button>
                      {!r.isPrinted && <button onClick={() => handlePrint(r.id)} className="form-button text-xs"><Printer size={12} />{t('common.print')}</button>}
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
              <h2 className="text-lg font-bold">{t('receipts.bizonylatReszletek')}</h2>
              <button onClick={() => setSelectedReceipt(null)} className="text-gray-500">X</button>
            </div>
            <div className="space-y-2">
              <div><strong>{t('receipts.bizonylatszam')}</strong> {selectedReceipt.receiptNumber}</div>
              <div><strong>{t('receipts.navBizonylatszam2')}</strong> {selectedReceipt.navReceiptNumber || '-'}</div>
              <div><strong>{t('cashdesk.tipus')}</strong> {receiptTypeLabel(selectedReceipt.receiptType)}</div>
              <div><strong>{t('receipts.kiadasDatuma')}</strong> {new Date(selectedReceipt.issueDate).toLocaleString('hu-HU')}</div>
              <div><strong>{t('receipts.nyomtatva')}</strong> {selectedReceipt.isPrinted ? 'Igen' : 'Nem'}</div>
              {selectedReceipt.content && (
                <div className="mt-4 p-4 bg-gray-50 rounded">
                  <strong>{t('receipts.tartalom')}</strong>
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
        statusMessage="Szigorú számadású bizonylat — helyileg már véglegesítve, lezárva. Szerver-szinkron függőben (auditnapló kiegészítése)."
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

