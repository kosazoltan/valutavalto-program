import { useState, useEffect, useMemo, useCallback } from 'react'
import { Receipt as ReceiptIcon, Search, Printer, Eye, Clock } from 'lucide-react'
import { receiptApi, Receipt } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { useAuthStore } from '../../stores/authStore'
import ReceiptPreviewModal from '../../components/electron/ReceiptPreviewModal'
import {
  getPendingReceiptDrafts,
  getReprintableReceiptDrafts,
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

// A helyi (offline) bizonylat-vázlatok receiptData.type-ja PrintJobType (kisbetűs: 'buy'/'sell'/'conversion'/
// 'storno' — ld. localQueue.ts), NEM a TransactionType enum-név. A típus-szűrőnek a vázlat-listára is hatnia
// kell (Codex P2 #1034), ezért a szűrő enum-nevét a vázlat-típusra képezzük. A TRANSFER_OUT/IN-hez nincs
// vázlat-típus (a draftok csak vétel/eladás/konverzió/sztornó) → ilyenkor a vázlat-lista üres (helyes).
const TYPE_FILTER_TO_DRAFT_TYPE: Record<string, string> = {
  BUY: 'buy',
  SELL: 'sell',
  CONVERSION: 'conversion',
  REVERSAL: 'storno',
}

// EXCMD b5b FR-BSZUR-02: "csak ügyfeles" szűrő — NEM bizonylattípus (nem receiptType-ra szűr),
// hanem az ügyfél-jelenlétre (customerName kitöltött). Ezért a típus-szűrő dropdown-ban külön,
// speciálisan kezelt értékként szerepel (nem a TransactionType enum-nevek között).
export const TYPE_FILTER_CUSTOMER_ONLY = 'CUSTOMER_ONLY'

// EXCMD b5b FR-BSZUR-05: 10 millió Ft-os AML küszöb. A küszöböt elérő/meghaladó bizonylatokat
// vizuálisan jelöljük (10M+ badge). A 10 M Ft-os AML-küszöb nem kerülhető meg (Pmt.).
export const AML_10M_THRESHOLD_HUF = 10_000_000

/** EXCMD b5b FR-BSZUR-02: van-e (nem üres) ügyfél a bizonylaton. */
export const hasCustomer = (name?: string | null): boolean =>
  typeof name === 'string' && name.trim().length > 0

/** EXCMD b5b FR-BSZUR-05: eléri-e a HUF összeg a 10 M Ft-os AML küszöböt. */
export const isAmlThresholdExceeded = (hufAmount?: number | null): boolean =>
  typeof hufAmount === 'number' && Number.isFinite(hufAmount) && hufAmount >= AML_10M_THRESHOLD_HUF

const HUF_FORMATTER = new Intl.NumberFormat('hu-HU', { maximumFractionDigits: 0 })
/** HUF összeg hu-HU formázása (pl. "10 000 000"); üres érték → "—". */
export const formatHuf = (hufAmount?: number | null): string =>
  typeof hufAmount === 'number' && Number.isFinite(hufAmount) ? HUF_FORMATTER.format(hufAmount) : '—'

export default function ReceiptPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const [receipts, setReceipts] = useState<Receipt[]>([])
  const [localDrafts, setLocalDrafts] = useState<PendingReceiptDraft[]>([])
  // Fizikai újranyomtatás (Codex P2 #1035): a már szinkronizált (synced=1) helyi bizonylatok,
  // amelyeket egy meghiúsult nyomtatás (papírelakadás) után ESC/POS-on újra ki lehet nyomtatni.
  const [reprintable, setReprintable] = useState<PendingReceiptDraft[]>([])
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
      const [data, drafts, reprints] = await Promise.all([
        receiptApi.list(),
        isElectron() ? getPendingReceiptDrafts(worker) : Promise.resolve([]),
        isElectron() ? getReprintableReceiptDrafts(worker) : Promise.resolve([]),
      ])
      setReceipts(data)
      setLocalDrafts(drafts)
      setReprintable(reprints)
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
      // EXCMD b5b FR-BSZUR-02: "csak ügyfeles" — NEM receiptType-ra szűr, hanem ügyfél-jelenlétre.
      if (typeFilter === TYPE_FILTER_CUSTOMER_ONLY) {
        if (!hasCustomer(r.customerName)) return false
      } else if (typeFilter !== 'ALL') {
        // FR-BSZUR-01: bizonylattípus-szűrő (ALL = kikapcsolva). receiptType case-insensitive egyezés.
        if ((r.receiptType ?? '').toUpperCase() !== typeFilter) return false
      }
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
    const lowered = searchTerm.toLowerCase()
    return localDrafts.filter((draft) => {
      // EXCMD b5b FR-BSZUR-02: "csak ügyfeles" a vázlat-listára is hat (a draft customerName-je
      // a receiptData-ban van). NEM a típusra szűr — ügyfél-jelenlétre.
      if (typeFilter === TYPE_FILTER_CUSTOMER_ONLY) {
        if (!hasCustomer(draft.receiptData.customerName)) return false
      // Codex P2 (#1034): a típus-szűrő a helyi vázlat-listára is hat (különben "Csak vételi" mellett is
      // látszanának eladási/konverziós/sztornó vázlatok). A draft type-ja PrintJobType (kisbetűs).
      } else if (typeFilter !== 'ALL') {
        // A TRANSFER_OUT/IN-hez nincs vázlat-típus (a draftok csak vétel/eladás/konverzió/sztornó) →
        // ilyenkor egy vázlat sem egyezik (üres vázlat-lista, helyes).
        const draftType = TYPE_FILTER_TO_DRAFT_TYPE[typeFilter]
        if (!draftType || (draft.receiptData.type ?? '') !== draftType) return false
      }
      if (!lowered) return true
      return (
        draft.referenceNumber.toLowerCase().includes(lowered)
        || draft.title.toLowerCase().includes(lowered)
        || draft.receiptData.customerName?.toLowerCase().includes(lowered)
      )
    })
  }, [localDrafts, searchTerm, typeFilter])

  // Fizikai újranyomtatás (Codex P2 #1035): a szinkronizált, újranyomtatható helyi bizonylatokra
  // a kereső + típus-szűrő ugyanúgy hat, mint a vázlat-listára (azonos PrintJobType-alapú szűrés).
  const filteredReprintable = useMemo(() => {
    const lowered = searchTerm.toLowerCase()
    return reprintable.filter((item) => {
      if (typeFilter === TYPE_FILTER_CUSTOMER_ONLY) {
        if (!hasCustomer(item.receiptData.customerName)) return false
      } else if (typeFilter !== 'ALL') {
        const draftType = TYPE_FILTER_TO_DRAFT_TYPE[typeFilter]
        if (!draftType || (item.receiptData.type ?? '') !== draftType) return false
      }
      if (!lowered) return true
      return (
        item.referenceNumber.toLowerCase().includes(lowered)
        || item.title.toLowerCase().includes(lowered)
        || item.receiptData.customerName?.toLowerCase().includes(lowered)
      )
    })
  }, [reprintable, searchTerm, typeFilter])

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
                  ReceiptService:166, TransactionType.java). A "csak ügyfeles" (FR-BSZUR-02) NEM TransactionType:
                  az ügyfél-jelenlétre (customerName kitöltött) szűr, ezért külön, speciális értékkel. */}
              <option value="ALL">Szűrés kikapcsolva (összes)</option>
              <option value={TYPE_FILTER_CUSTOMER_ONLY}>Csak ügyfeles</option>
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

      {/* Fizikai újranyomtatás (Codex P2 #1035): már szinkronizált helyi bizonylatok, amelyeknél a
          fizikai nyomtatás meghiúsult (papírelakadás) — a lokális adatból ESC/POS-on újranyomtathatók. */}
      {filteredReprintable.length > 0 && (
        <div className="form-panel">
          <div className="mb-4 flex items-center gap-2 text-blue-800">
            <Printer size={18} />
            <h2 className="text-lg font-bold">Fizikai újranyomtatás</h2>
          </div>
          <div className="mb-4 rounded-lg border border-blue-200 bg-blue-50 px-4 py-3 text-sm text-blue-800">
            Ezek a bizonylatok már véglegesítve és szinkronizálva vannak. Ha a nyomtatás meghiúsult
            (pl. papírelakadás), itt a tárolt adatból fizikailag újranyomtathatók — a sorszám nem változik.
          </div>
          <table className="data-grid w-full">
            <thead>
              <tr><th>{t('receipts.helyiReferencia')}</th><th>{t('common.type')}</th><th>{t('common.createdAt')}</th><th>{t('common.status2')}</th><th>{t('common.actions')}</th></tr>
            </thead>
            <tbody>
              {filteredReprintable.map((item) => (
                <tr key={item.id}>
                  <td className="font-mono">{item.referenceNumber}</td>
                  <td>{item.title}</td>
                  <td>{new Date(item.createdAt).toLocaleString('hu-HU')}</td>
                  <td><span className="badge badge-blue">{item.statusLabel}</span></td>
                  <td>
                    <div className="flex gap-2">
                      <button onClick={() => setSelectedDraft(item)} className="form-button text-xs"><Eye size={12} />{t('closing.elonezet')}</button>
                      <button onClick={() => setSelectedDraft(item)} className="form-button text-xs"><Printer size={12} />Újranyomtatás</button>
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
            {/* EXCMD b5b: Ügyfél (FR-BSZUR-02) + Összeg/AML-jelölő (FR-BSZUR-05) oszlopok. */}
            <tr><th>{t('cashier.receiptNumber')}</th><th>{t('receipts.navBizonylatszam')}</th><th>{t('common.type')}</th><th>Ügyfél</th><th>Összeg (Ft)</th><th>{t('cashier.issueDate')}</th><th>{t('cashier.printed')}</th><th>{t('common.actions')}</th></tr>
          </thead>
          <tbody>
            {filteredReceipts.length === 0 ? (
              <tr><td colSpan={8} className="text-center text-gray-500 py-4">{t('common.noResult')}</td></tr>
            ) : (
              filteredReceipts.map((r) => (
                <tr key={r.id}>
                  <td className="font-mono">{r.receiptNumber}</td>
                  <td className="font-mono">{r.navReceiptNumber || '-'}</td>
                  <td>{receiptTypeLabel(r.receiptType)}</td>
                  <td>{hasCustomer(r.customerName) ? r.customerName : '—'}</td>
                  {/* EXCMD b5b FR-BSZUR-05: 10 M Ft AML-küszöb vizuális jelölő (nem kerülhető meg, Pmt.). */}
                  <td className="text-right whitespace-nowrap">
                    {formatHuf(r.hufAmount)}
                    {isAmlThresholdExceeded(r.hufAmount) && (
                      <span className="badge badge-red ml-2" title="10 millió Ft feletti — AML küszöb (Pmt.)">10M+</span>
                    )}
                  </td>
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
              {/* EXCMD b5b: ügyfél (FR-BSZUR-02) + összeg/AML-jelölő (FR-BSZUR-05), csak olvasható szűrési segédadat. */}
              <div><strong>Ügyfél:</strong> {hasCustomer(selectedReceipt.customerName) ? selectedReceipt.customerName : '—'}</div>
              <div>
                <strong>Összeg (Ft):</strong> {formatHuf(selectedReceipt.hufAmount)}
                {isAmlThresholdExceeded(selectedReceipt.hufAmount) && (
                  <span className="badge badge-red ml-2" title="10 millió Ft feletti — AML küszöb (Pmt.)">10M+</span>
                )}
              </div>
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
        printLabel={selectedDraft?.reprint ? 'Újranyomtatás' : undefined}
        statusMessage={
          selectedDraft?.reprint
            // Fizikai újranyomtatás (Codex P2 #1035): a bizonylat már szinkronizált — ez nem új
            // kiállítás, csak a meglévő (azonos sorszámú) bizonylat ismételt fizikai nyomtatása.
            ? 'Már szinkronizált bizonylat fizikai újranyomtatása — a sorszám és a tartalom változatlan (pl. papírelakadás utáni ismételt nyomtatás).'
            : 'Szigorú számadású bizonylat — helyileg már véglegesítve, lezárva. Szerver-szinkron függőben (auditnapló kiegészítése).'
        }
        onPrint={async () => {
          if (!selectedDraft) {
            return
          }

          const printed = await printPendingReceiptDraft(selectedDraft.receiptData)
          if (!printed) {
            throw new Error('A bizonylat nyomtatása nem érhető el ebben a környezetben')
          }
          toast.success(
            selectedDraft.reprint
              ? 'A bizonylat fizikai újranyomtatása elindítva'
              : 'A helyi bizonylatvázlat nyomtatása elindítva',
          )
        }}
      />
    </div>
  )
}

