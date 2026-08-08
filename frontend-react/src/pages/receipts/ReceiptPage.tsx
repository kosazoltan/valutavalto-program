import { useState, useEffect, useMemo, useCallback } from 'react'
import {
  Receipt as ReceiptIcon,
  Search,
  Printer,
  Eye,
  Clock,
  ChevronDown,
  ChevronRight,
  X,
  Download,
  AlertTriangle,
  RefreshCw,
} from 'lucide-react'
import { receiptApi, Receipt } from '../../services/api/index'
import { getBlobErrorMessage, getErrorMessage } from '../../utils/errorHandling'
import { downloadBlob } from '../../utils/downloadBlob'
import { toast } from '../../components/ui/toaster'
import { useAuthStore } from '../../stores/authStore'
import ReceiptPreviewModal from '../../components/electron/ReceiptPreviewModal'
import {
  getCompanyType,
  getPendingReceiptDrafts,
  getReprintableReceiptDrafts,
  printPendingReceiptDraft,
  type PendingReceiptDraft,
} from '../../utils/localQueue'
import { isElectron, getElectronAPI } from '../../utils/electron'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import type { PrintReceiptData, TransactionReceiptLine } from '../../types/receipt'
import type { Worker } from '../../stores/authStore'

// A backend Receipt.receiptType = TransactionType.name() (enum-név). Magyar megjelenítő-címkék, hogy a
// tábla/részletek a típus-szűrővel konzisztens, olvasható szöveget mutassanak (a TransactionType.java
// magyar leírásai alapján). Ismeretlen érték → a nyers kód (fallback).
const RECEIPT_TYPE_LABELS: Record<string, string> = {
  BUY: 'Vétel',
  SELL: 'Eladás',
  REVERSAL: 'Sztornó',
  CANCELLED_TRANSACTION: 'Megszakított tranzakció',
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
export const receiptTypeLabel = (code?: string): string =>
  code ? (RECEIPT_TYPE_LABELS[code.toUpperCase()] ?? code) : '—'

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

// EXCMD b5b FR-BSZUR-01 (lista 2. opció): "csak ügyfeles" szűrő — NEM bizonylattípus (nem
// receiptType-ra szűr), hanem az ügyfél-jelenlétre (customerName kitöltött). Ezért a típus-szűrő
// dropdown-ban külön, speciálisan kezelt értékként szerepel (nem a TransactionType enum-nevek között).
export const TYPE_FILTER_CUSTOMER_ONLY = 'CUSTOMER_ONLY'

// EXCMD b5b FR-BSZUR-05: 10 millió Ft-os AML küszöb. A küszöböt elérő/meghaladó bizonylatokat
// vizuálisan jelöljük (10M+ badge). A 10 M Ft-os AML-küszöb nem kerülhető meg (Pmt.).
export const AML_10M_THRESHOLD_HUF = 10_000_000

/** EXCMD b5b FR-BSZUR-01: van-e (nem üres) ügyfél a bizonylaton. */
export const hasCustomer = (name?: string | null): boolean =>
  typeof name === 'string' && name.trim().length > 0

/** EXCMD b5b FR-BSZUR-05: eléri-e a HUF összeg a 10 M Ft-os AML küszöböt. */
export const isAmlThresholdExceeded = (hufAmount?: number | null): boolean =>
  typeof hufAmount === 'number' && Number.isFinite(hufAmount) && hufAmount >= AML_10M_THRESHOLD_HUF

// EXCMD b5b FR-BSZUR-05 (V312): az ENGEDÉLYEZŐ beosztás-pillanatkép (Worker.role enum-név)
// magyar megjelenítő-címkéi. Ismeretlen/új szerepkörnél a nyers kód jelenik meg (nem tör el).
const APPROVER_ROLE_LABELS: Record<string, string> = {
  SUPERVISOR: 'Műszakvezető',
  MANAGER: 'Ügyvezető',
  ADMIN: 'Adminisztrátor',
}
export const approverRoleLabel = (role?: string): string =>
  role ? (APPROVER_ROLE_LABELS[role.toUpperCase()] ?? role) : ''

const HUF_FORMATTER = new Intl.NumberFormat('hu-HU', { maximumFractionDigits: 0 })
/** HUF összeg hu-HU formázása (pl. "10 000 000"); üres érték → "—". */
export const formatHuf = (hufAmount?: number | null): string =>
  typeof hufAmount === 'number' && Number.isFinite(hufAmount)
    ? HUF_FORMATTER.format(hufAmount)
    : '—'

type CancelledReceiptContent = {
  receiptNumber?: unknown
  reason?: unknown
  mode?: unknown
  cancelledAt?: unknown
  workerCode?: unknown
  customerName?: unknown
  customerDocumentNumber?: unknown
  lines?: unknown
}

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null && !Array.isArray(value)

const optionalString = (value: unknown): string | undefined =>
  typeof value === 'string' && value.trim().length > 0 ? value.trim() : undefined

const finiteNumber = (value: unknown): number | undefined =>
  typeof value === 'number' && Number.isFinite(value) ? value : undefined

function safeJsonRecord(value?: string): Record<string, unknown> | null {
  if (!value) return null
  try {
    const parsed = JSON.parse(value) as unknown
    return isRecord(parsed) ? parsed : null
  } catch {
    return null
  }
}

function toReceiptDateParts(value: string): { date: string; time: string } {
  const normalized = value.includes('T') ? value : value.replace(' ', 'T')
  const date = new Date(normalized)
  if (Number.isNaN(date.getTime())) {
    return {
      date: normalized.slice(0, 10) || '—',
      time: normalized.length >= 19 ? normalized.slice(11, 19) : '—',
    }
  }
  return {
    date: date.toLocaleDateString('hu-HU'),
    time: date.toLocaleTimeString('hu-HU'),
  }
}

const CANCELLED_TRANSACTION_NOTE = 'Pénzmozgás nem történt.'

export function isCancelledTransactionReceipt(receipt: Receipt): boolean {
  return (receipt.receiptType ?? '').toUpperCase() === 'CANCELLED_TRANSACTION'
}

export function buildCancelledTransactionPrintData(
  receipt: Receipt,
  worker: Worker | null,
): PrintReceiptData | null {
  if (!isCancelledTransactionReceipt(receipt)) return null

  const content = safeJsonRecord(receipt.content) as CancelledReceiptContent | null
  if (!content) return null

  const lines = Array.isArray(content.lines)
    ? content.lines
        .filter(isRecord)
        .map((line): TransactionReceiptLine | null => {
          const currencyCode = optionalString(line.currencyCode)
          const foreignAmount = finiteNumber(line.foreignAmount)
          const rate = finiteNumber(line.rate)
          const hufAmount = finiteNumber(line.hufAmount)
          if (
            !currencyCode ||
            foreignAmount === undefined ||
            rate === undefined ||
            hufAmount === undefined
          ) {
            return null
          }
          return { currencyCode, foreignAmount, rate, hufAmount }
        })
        .filter((line): line is TransactionReceiptLine => line !== null)
    : []

  if (lines.length === 0) return null

  const totalHuf = lines.reduce((sum, line) => sum + line.hufAmount, 0)
  const firstLine = lines[0]!
  const dateParts = toReceiptDateParts(optionalString(content.cancelledAt) ?? receipt.issueDate)
  const reason = optionalString(content.reason) ?? 'MEGSEM'

  return {
    type: 'cancelled_transaction',
    companyType: getCompanyType(worker),
    receiptNumber: optionalString(content.receiptNumber) ?? receipt.receiptNumber,
    branchCode: worker?.branchCode ?? 'LOCAL',
    cashierName: worker?.fullName ?? optionalString(content.workerCode) ?? '—',
    date: dateParts.date,
    time: dateParts.time,
    currencyCode: firstLine.currencyCode,
    foreignAmount: firstLine.foreignAmount,
    rate: firstLine.rate,
    hufAmount: totalHuf,
    roundedHufAmount: totalHuf,
    customerName: optionalString(content.customerName) ?? receipt.customerName,
    customerDocNumber:
      optionalString(content.customerDocumentNumber) ?? receipt.customerDocumentNumber,
    transactionLines: lines,
    stornoReason: reason,
    note: `${CANCELLED_TRANSACTION_NOTE} Mód: ${optionalString(content.mode) ?? '—'}.`,
  }
}

// EXCMD b5b FR-BSZUR-02: hatókör/időszak-választó.
//  - ALL: nincs időszak-szűrés (összes bizonylat).
//  - MONTH: "A HÓNAP ÖSSZES BIZONYLATA" — egy naptári hónap (YYYY-MM).
//  - CUSTOM: "CSAK A VÁLASZTOTT [időszak]" — dátumtól-ig (inkluzív), bármelyik vég nyitva hagyható.
export type PeriodMode = 'ALL' | 'MONTH' | 'CUSTOM'

/**
 * EXCMD b5b FR-BSZUR-02: eldönti, hogy egy bizonylat dátuma a választott időszakba esik-e.
 * A {@code dateStr} ISO dátum ("YYYY-MM-DD") vagy ISO timestamp (a kezdő 10 karakter a nap).
 * ISO-dátum sztringeken a lexikografikus összehasonlítás megegyezik a kronológiaival (azonos formátum),
 * ezért Date-parszolás nélkül, determinisztikusan dolgozunk.
 */
export const matchesPeriod = (
  dateStr: string | undefined | null,
  mode: PeriodMode,
  month: string,
  from: string,
  to: string,
): boolean => {
  if (mode === 'ALL') return true
  if (typeof dateStr !== 'string') return false
  if (mode === 'MONTH') {
    // Hónap-egyezéshez "YYYY-MM" (7 kar.) elég.
    if (dateStr.length < 7) return false
    if (!month) return true
    return dateStr.slice(0, 7) === month
  }
  // CUSTOM: a tól-ig összehasonlításhoz TELJES "YYYY-MM-DD" (10 kar.) kell — különben egy
  // csonka "YYYY-MM" érték a prefix-egyezés miatt félreesne (Copilot). Nyitott végek megengedettek.
  if (dateStr.length < 10) return false
  const day = dateStr.slice(0, 10)
  if (from && day < from) return false
  if (to && day > to) return false
  return true
}

/** Az aktuális naptári hónap "YYYY-MM" alakban (a MONTH-mód alapértéke). */
const currentMonthValue = (): string => {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
}

/**
 * EXCMD b5b FR-BSZUR-02 (Codex P2): a periódus-állapotot a backend list-query ISO from/to
 * dátumaira képezi, hogy a dátum-szűrés a DB-ben fusson (a top-500 limit a választott időszakon
 * BELÜL érvényesüljön, ne csonkoljon a szűrés előtt). MONTH → a hónap első/utolsó napja (a tényleges
 * hónaphossz alapján, hogy a backend LocalDate-parszolása ne dobjon érvénytelen dátumra). ALL → üres.
 */
export const periodToBackendRange = (
  mode: PeriodMode,
  month: string,
  from: string,
  to: string,
): { from?: string; to?: string } => {
  if (mode === 'MONTH') {
    if (!month) return {}
    const [y, m] = month.split('-').map(Number)
    if (!y || !m) return {}
    const lastDay = new Date(y, m, 0).getDate() // a hónap utolsó napja (m: 1-alapú → Date(y, m, 0))
    return { from: `${month}-01`, to: `${month}-${String(lastDay).padStart(2, '0')}` }
  }
  if (mode === 'CUSTOM') {
    return { from: from || undefined, to: to || undefined }
  }
  return {}
}

/**
 * Közös szűrő a helyi vázlat- ÉS a fizikai-újranyomtatás-listára (Sourcery: a két szűrő korábban
 * majdnem azonos volt). A hatókör/időszak (FR-BSZUR-02, a tétel createdAt-je alapján), a "csak
 * ügyfeles" (FR-BSZUR-01 opció 2) ügyfél-jelenlétre, a típus-szűrő a PrintJobType-ra (Codex P2 #1034),
 * a keresőszó a referenciára/címre/ügyfélnévre szűr.
 */
export function draftMatchesFilters(
  draft: PendingReceiptDraft,
  typeFilter: string,
  searchTerm: string,
  periodMode: PeriodMode,
  periodMonth: string,
  periodFrom: string,
  periodTo: string,
): boolean {
  // EXCMD b5b FR-BSZUR-02: hatókör/időszak-szűrő a helyi tételekre (a draft createdAt-je alapján).
  if (!matchesPeriod(draft.createdAt, periodMode, periodMonth, periodFrom, periodTo)) return false
  if (typeFilter === TYPE_FILTER_CUSTOMER_ONLY) {
    if (!hasCustomer(draft.receiptData.customerName)) return false
  } else if (typeFilter !== 'ALL') {
    // A TRANSFER_OUT/IN-hez nincs vázlat-típus (a draftok csak vétel/eladás/konverzió/sztornó) →
    // ilyenkor egy tétel sem egyezik (üres lista, helyes).
    const draftType = TYPE_FILTER_TO_DRAFT_TYPE[typeFilter]
    if (!draftType || (draft.receiptData.type ?? '') !== draftType) return false
  }
  const lowered = searchTerm.toLowerCase()
  if (!lowered) return true
  return (
    draft.referenceNumber.toLowerCase().includes(lowered) ||
    draft.title.toLowerCase().includes(lowered) ||
    (draft.receiptData.customerName?.toLowerCase().includes(lowered) ?? false)
  )
}

// EXCMD b5b FR-BSZUR-03: természetes személy ügyfél-adatlap szűrőmezők. A `key` a dúsított Receipt
// mezőre mutat (a tx-snapshotból), a `label` a megjelenítés. LEÁNYKORI NEVE nincs a tx-snapshotban → kimarad.
// Jogi személy (FR-BSZUR-04) telephely/képviselő-beosztás sincs külön snapshot-mezőként → külön increment.
export const CUSTOMER_FILTER_FIELDS: { key: keyof Receipt; labelKey: string }[] = [
  { key: 'customerName', labelKey: 'receipts.filter.customerName' },
  { key: 'customerMotherName', labelKey: 'receipts.filter.customerMotherName' },
  { key: 'customerBirthPlace', labelKey: 'receipts.filter.customerBirthPlace' },
  { key: 'customerBirthDate', labelKey: 'receipts.filter.customerBirthDate' },
  { key: 'customerNationality', labelKey: 'receipts.filter.customerNationality' },
  { key: 'customerAddress', labelKey: 'receipts.filter.customerAddress' },
  { key: 'customerDocumentType', labelKey: 'receipts.filter.customerDocumentType' },
  { key: 'customerDocumentNumber', labelKey: 'receipts.filter.customerDocumentNumber' },
  // FR-BSZUR-04 (jogi személy): képviselő/meghatalmazott neve. "Jogi személy neve" → customerName,
  // "Telephely címe" → customerAddress (a tx-snapshot jogi személynél is ezeket hordozza);
  // "Képviselő beosztása" nincs az adatmodellben → defer (lásd Receipt.java megjegyzés).
  { key: 'customerActorName', labelKey: 'receipts.filter.customerActorName' },
]

/**
 * EXCMD b5b FR-BSZUR-03: a bizonylat megfelel-e az ÖSSZES (nem üres) ügyfél-adatlap szűrőnek.
 * Részleges egyezés (LIKE), kis/nagybetű-érzéketlen — a spec szerint. Üres szűrőmező → nem szűkít.
 */
export const matchesCustomerFilters = (
  receipt: Receipt,
  filters: Record<string, string>,
): boolean => {
  for (const { key } of CUSTOMER_FILTER_FIELDS) {
    const needle = (filters[key] ?? '').trim().toLowerCase()
    if (!needle) continue
    const hay = String(receipt[key] ?? '').toLowerCase()
    if (!hay.includes(needle)) return false
  }
  return true
}

/** Van-e legalább egy aktív (nem üres) ügyfél-adatlap szűrő. */
export const hasActiveCustomerFilter = (filters: Record<string, string>): boolean =>
  CUSTOMER_FILTER_FIELDS.some(({ key }) => (filters[key] ?? '').trim().length > 0)

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
  // BUY/SELL/CONVERSION/TRANSFER_OUT/TRANSFER_IN/REVERSAL. A "csak ügyfeles" (FR-BSZUR-01 opció 2) az
  // ügyfél-jelenlétre szűr. Az ügyfél-adatlap szűrőmezők + ENGEDÉLYEZŐ (FR-BSZUR-03/04 + 05-approver)
  // további list-adatot igényelnek → következő incrementek.
  const [typeFilter, setTypeFilter] = useState<string>('ALL')
  // EXCMD b5b FR-BSZUR-02: hatókör/időszak-szűrő (hónap vs. egyéni dátumtartomány).
  const [periodMode, setPeriodMode] = useState<PeriodMode>('ALL')
  const [periodMonth, setPeriodMonth] = useState<string>(currentMonthValue)
  const [periodFrom, setPeriodFrom] = useState<string>('')
  const [periodTo, setPeriodTo] = useState<string>('')
  // EXCMD b5b FR-BSZUR-03: természetes személy ügyfél-adatlap szűrőmezők (mezőkulcs → beírt érték).
  const [customerFilters, setCustomerFilters] = useState<Record<string, string>>({})
  const [customerPanelOpen, setCustomerPanelOpen] = useState(false)
  // FR-BSZUR-03 (Codex P2): az adatlap-szűrőket a BACKENDRE is továbbadjuk (a synthesized 500-as
  // csonkolás ELŐTT), de a gépeléskénti refetch elkerülésére debounce-oljuk (400 ms). A kliens-oldali
  // matchesCustomerFilters azonnali visszajelzést ad a már betöltött listán, a backend pótolja a >500-as
  // egyezéseket.
  const [debouncedCustomerFilters, setDebouncedCustomerFilters] = useState<Record<string, string>>(
    {},
  )
  useEffect(() => {
    const id = setTimeout(() => setDebouncedCustomerFilters(customerFilters), 400)
    return () => clearTimeout(id)
  }, [customerFilters])
  const [selectedReceipt, setSelectedReceipt] = useState<Receipt | null>(null)
  const [selectedDraft, setSelectedDraft] = useState<PendingReceiptDraft | null>(null)
  /** FKH-031 FR-4: eppen futo ujrakuldesek (draft.id) — a gomb ilyenkor letiltott. */
  const [retryingDraftIds, setRetryingDraftIds] = useState<Set<string>>(new Set())
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)
  const [closingPdfId, setClosingPdfId] = useState('')
  const [closingPdfLoading, setClosingPdfLoading] = useState(false)

  const loadData = useCallback(async (): Promise<void> => {
    try {
      setLoading(true)
      // EXCMD b5b FR-BSZUR-02 (Codex P2): a periódust a backendre is továbbadjuk, hogy a synthesized
      // lista dátum-szűrése a 500-as limit ELŐTT történjen (régi hónap/tartomány ne legyen csonka).
      const range = periodToBackendRange(periodMode, periodMonth, periodFrom, periodTo)
      // FR-BSZUR-03 (Codex P2): az ügyfél-adatlap szűrőket is a backendre adjuk (debounce-olt értékkel),
      // hogy a synthesized LIKE a 500-as csonkolás ELŐTT fusson — egy >500-as időszakban se vesszen el
      // egy régi egyező rekord.
      const [data, drafts, reprints] = await Promise.all([
        receiptApi.list({ ...range, customerFilters: debouncedCustomerFilters }),
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
  }, [worker, periodMode, periodMonth, periodFrom, periodTo, debouncedCustomerFilters])

  useEffect(() => {
    void loadData()
  }, [loadData])

  /**
   * FKH-031 FR-4: celzott ujrakuldes a bizonylat-vazlat listarol, a mar letezo
   * `retryPendingTransaction` IPC-fuggveny ujrahasznositasaval (FK-071 minta).
   * A lista nem blokkol; a gomb a futo kiserlet alatt letiltott, az eredmeny a
   * frissitett pending sorbol jon vissza (a sync-engine tartosan rogziti).
   */
  const handleDraftRetry = useCallback(
    async (draft: PendingReceiptDraft): Promise<void> => {
      const api = getElectronAPI()
      if (!api?.retryPendingTransaction || typeof draft.pendingTransactionId !== 'number') return
      setRetryingDraftIds((prev) => new Set(prev).add(draft.id))
      try {
        const result = await api.retryPendingTransaction(draft.pendingTransactionId)
        if (result?.success) {
          toast.success('Újraküldés sikeres', `${draft.referenceNumber} feltöltve a szerverre.`)
        } else {
          toast.error('Újraküldés sikertelen', result?.error ?? 'Ismeretlen hiba')
        }
      } catch (err) {
        logger.error('ReceiptPage', 'FKH-031 draft retry failed', err)
        toast.error('Újraküldés sikertelen', getErrorMessage(err))
      } finally {
        setRetryingDraftIds((prev) => {
          const next = new Set(prev)
          next.delete(draft.id)
          return next
        })
        await loadData()
      }
    },
    [loadData],
  )

  const filteredReceipts = useMemo(() => {
    const term = searchTerm.toLowerCase()
    return receipts.filter((r) => {
      // EXCMD b5b FR-BSZUR-02: hatókör/időszak-szűrő (a bizonylat issueDate-je alapján).
      if (!matchesPeriod(r.issueDate, periodMode, periodMonth, periodFrom, periodTo)) return false
      // EXCMD b5b FR-BSZUR-01 (opció 2): "csak ügyfeles" — NEM receiptType-ra szűr, hanem ügyfél-jelenlétre.
      if (typeFilter === TYPE_FILTER_CUSTOMER_ONLY) {
        if (!hasCustomer(r.customerName)) return false
      } else if (typeFilter !== 'ALL') {
        // FR-BSZUR-01: bizonylattípus-szűrő (ALL = kikapcsolva). receiptType case-insensitive egyezés.
        if ((r.receiptType ?? '').toUpperCase() !== typeFilter) return false
      }
      // EXCMD b5b FR-BSZUR-03: ügyfél-adatlap szűrőmezők (LIKE, kis/nagybetű-érzéketlen).
      if (!matchesCustomerFilters(r, customerFilters)) return false
      if (!term) return true
      return (
        r.receiptNumber?.toLowerCase().includes(term) ||
        r.navReceiptNumber?.toLowerCase().includes(term)
      )
    })
  }, [
    receipts,
    searchTerm,
    typeFilter,
    periodMode,
    periodMonth,
    periodFrom,
    periodTo,
    customerFilters,
  ])

  const handlePrint = async (receipt: Receipt): Promise<void> => {
    try {
      if (isCancelledTransactionReceipt(receipt)) {
        const receiptData = buildCancelledTransactionPrintData(receipt, worker)
        if (!receiptData) {
          toast.error('A megszakított tranzakció bizonylatának tartalma nem nyomtatható')
          return
        }
        const printed = await printPendingReceiptDraft(receiptData)
        if (!printed) {
          toast.error('A fizikai nyomtatás nem érhető el ebben a környezetben')
          return
        }
      }

      await receiptApi.print(receipt.id)
      await loadData()
      toast.success(
        isCancelledTransactionReceipt(receipt)
          ? 'Megszakított tranzakció bizonylata kinyomtatva'
          : 'Bizonylat nyomtatása elindítva',
      )
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      toast.error('Hiba történt a nyomtatás során', errorMessage)
      logger.error('ReceiptPage', 'Failed to print receipt:', err)
    }
  }

  const openReceiptDetails = useCallback(
    async (receipt: Receipt): Promise<void> => {
      setDetailLoadingId(receipt.id)
      try {
        const detailed = await receiptApi.getById(receipt.id)
        setSelectedReceipt(detailed)
      } catch (err) {
        const errorMessage = getErrorMessage(err)
        toast.error(t('receipts.detailLoadError'), errorMessage)
        logger.error('ReceiptPage', 'Failed to load receipt details:', err)
      } finally {
        setDetailLoadingId(null)
      }
    },
    [t],
  )

  const downloadClosingPdf = useCallback(async (): Promise<void> => {
    const closingId = closingPdfId.trim()
    if (!closingId) {
      toast.error('Adja meg a zárás azonosítóját')
      return
    }
    setClosingPdfLoading(true)
    try {
      const blob = await receiptApi.downloadClosingPdf(closingId)
      downloadBlob(blob, `zaras-${closingId}.pdf`)
      toast.success('Zárási bizonylat PDF letöltése elindítva')
    } catch (err) {
      toast.error('Nem sikerült a zárási bizonylat PDF letöltése', await getBlobErrorMessage(err))
      logger.error('ReceiptPage', 'Failed to download closing PDF:', err)
    } finally {
      setClosingPdfLoading(false)
    }
  }, [closingPdfId])

  // Sourcery (#1039 nitpick): a lista „Újranyomtatás" gombja KÖZVETLENÜL nyomtasson (1 klikk, ESC/POS),
  // ne csak előnézetet nyisson (a printer-ikon + címke azonnali nyomtatást sugall). Az előnézet az
  // „Előnézet" (szem) gombbal érhető el. Hibát toast-tal jelzünk (nem dobunk, mert ez közvetlen akció).
  const reprintDraft = useCallback(async (draft: PendingReceiptDraft): Promise<void> => {
    try {
      const printed = await printPendingReceiptDraft(draft.receiptData)
      if (!printed) {
        toast.error('A bizonylat nyomtatása nem érhető el ebben a környezetben')
        return
      }
      toast.success(
        draft.reprint
          ? 'A bizonylat fizikai újranyomtatása elindítva'
          : 'A helyi bizonylatvázlat nyomtatása elindítva',
      )
    } catch (err) {
      toast.error('Hiba történt a nyomtatás során', getErrorMessage(err))
      logger.error('ReceiptPage', 'Failed to reprint draft:', err)
    }
  }, [])

  // EXCMD b5b FR-BSZUR-01/02 + Codex P2 (#1034): a hatókör/időszak + "csak ügyfeles" + típus-szűrő +
  // keresőszó a helyi vázlat-listára is hat (közös helper: draftMatchesFilters).
  // FR-BSZUR-03: ha részletes ügyfél-adatlap szűrő aktív, a helyi vázlat-/újranyomtatás-listák
  // (amelyeknek nincs dúsított adatlap-mezőjük) NEM jeleníthetők meg — különben szűretlenül látszanának.
  const customerFilterActive = useMemo(
    () => hasActiveCustomerFilter(customerFilters),
    [customerFilters],
  )

  const filteredDrafts = useMemo(
    () =>
      customerFilterActive
        ? []
        : localDrafts.filter((draft) =>
            draftMatchesFilters(
              draft,
              typeFilter,
              searchTerm,
              periodMode,
              periodMonth,
              periodFrom,
              periodTo,
            ),
          ),
    [
      localDrafts,
      searchTerm,
      typeFilter,
      periodMode,
      periodMonth,
      periodFrom,
      periodTo,
      customerFilterActive,
    ],
  )

  // Fizikai újranyomtatás (Codex P2 #1035): a szinkronizált, újranyomtatható helyi bizonylatokra
  // ugyanaz a szűrés hat, mint a vázlat-listára (ugyanaz a draftMatchesFilters helper, periódussal).
  const filteredReprintable = useMemo(
    () =>
      customerFilterActive
        ? []
        : reprintable.filter((item) =>
            draftMatchesFilters(
              item,
              typeFilter,
              searchTerm,
              periodMode,
              periodMonth,
              periodFrom,
              periodTo,
            ),
          ),
    [
      reprintable,
      searchTerm,
      typeFilter,
      periodMode,
      periodMonth,
      periodFrom,
      periodTo,
      customerFilterActive,
    ],
  )

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
        <div className="mb-3 flex flex-wrap items-end gap-2 border-b pb-3">
          <div className="min-w-[220px]">
            <label className="form-label" htmlFor="closing-pdf-id">
              Zárás azonosító
            </label>
            <input
              id="closing-pdf-id"
              type="text"
              className="form-input"
              value={closingPdfId}
              onChange={(e) => setClosingPdfId(e.target.value)}
              placeholder="pl. closing-2026-06-19"
            />
          </div>
          <button
            type="button"
            className="form-button text-sm"
            data-testid="receipt-closing-pdf-download"
            disabled={closingPdfLoading}
            onClick={() => void downloadClosingPdf()}
          >
            <Download size={14} />
            {closingPdfLoading ? 'Letöltés...' : 'Zárási PDF'}
          </button>
        </div>
        <div className="flex flex-wrap gap-4">
          <div className="flex-1 min-w-[200px]">
            <label className="form-label">{t('common.search')}</label>
            <div className="relative">
              <Search
                className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400"
                size={16}
              />
              <input
                type="text"
                className="form-input pl-8"
                placeholder="Bizonylatszám..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
          {/* EXCMD b5b FR-BSZUR-01: bizonylattípus-szűrő (egyszerre egy aktív; ALL = szűrés kikapcsolva). */}
          <div className="min-w-[200px]">
            <label className="form-label">{t('receipts.filter.type')}</label>
            <select
              className="form-input"
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
            >
              {/* A backend Receipt.receiptType = TransactionType.name() — az enum-nevekre szűrünk (verifikálva:
                  ReceiptService:166, TransactionType.java). A "csak ügyfeles" (FR-BSZUR-01 opció 2) NEM
                  TransactionType: az ügyfél-jelenlétre (customerName kitöltött) szűr, ezért külön, spec. értékkel. */}
              <option value="ALL">{t('receipts.filter.allDisabled')}</option>
              <option value={TYPE_FILTER_CUSTOMER_ONLY}>{t('receipts.filter.customerOnly')}</option>
              <option value="BUY">{t('receipts.filter.buyOnly')}</option>
              <option value="SELL">{t('receipts.filter.sellOnly')}</option>
              <option value="CONVERSION">{t('receipts.filter.conversionOnly')}</option>
              <option value="TRANSFER_OUT">{t('receipts.filter.transferOutOnly')}</option>
              <option value="TRANSFER_IN">{t('receipts.filter.transferInOnly')}</option>
              <option value="REVERSAL">{t('receipts.filter.reversalOnly')}</option>
              <option value="CANCELLED_TRANSACTION">
                {t('receipts.filter.cancelledTransactionOnly')}
              </option>
            </select>
          </div>
          {/* EXCMD b5b FR-BSZUR-02: hatókör/időszak-választó (összes / hónap / egyéni dátumtartomány). */}
          <div className="min-w-[180px]">
            <label className="form-label" htmlFor="receipt-period-mode">
              {t('receipts.filter.period')}
            </label>
            <select
              id="receipt-period-mode"
              className="form-input"
              value={periodMode}
              onChange={(e) => setPeriodMode(e.target.value as PeriodMode)}
            >
              <option value="ALL">{t('receipts.filter.periodAll')}</option>
              <option value="MONTH">{t('receipts.filter.periodMonth')}</option>
              <option value="CUSTOM">{t('receipts.filter.periodCustom')}</option>
            </select>
          </div>
          {periodMode === 'MONTH' && (
            <div className="min-w-[160px]">
              <label className="form-label" htmlFor="receipt-period-month">
                {t('receipts.filter.month')}
              </label>
              <input
                id="receipt-period-month"
                type="month"
                className="form-input"
                value={periodMonth}
                onChange={(e) => setPeriodMonth(e.target.value)}
              />
            </div>
          )}
          {periodMode === 'CUSTOM' && (
            <>
              <div className="min-w-[150px]">
                <label className="form-label" htmlFor="receipt-period-from">
                  {t('receipts.filter.dateFrom')}
                </label>
                <input
                  id="receipt-period-from"
                  type="date"
                  className="form-input"
                  value={periodFrom}
                  max={periodTo || undefined}
                  onChange={(e) => setPeriodFrom(e.target.value)}
                />
              </div>
              <div className="min-w-[150px]">
                <label className="form-label" htmlFor="receipt-period-to">
                  {t('receipts.filter.dateTo')}
                </label>
                <input
                  id="receipt-period-to"
                  type="date"
                  className="form-input"
                  value={periodTo}
                  min={periodFrom || undefined}
                  onChange={(e) => setPeriodTo(e.target.value)}
                />
              </div>
            </>
          )}
        </div>
        {/* EXCMD b5b FR-BSZUR-03: természetes személy ügyfél-adatlap szűrő (összecsukható panel). */}
        <div className="mt-3 border-t pt-3">
          <button
            type="button"
            className="form-button text-xs flex items-center gap-1"
            onClick={() => setCustomerPanelOpen((o) => !o)}
            aria-expanded={customerPanelOpen}
          >
            {customerPanelOpen ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
            {t('receipts.filter.customerPanel')}
            {customerFilterActive && (
              <>
                <span
                  className="inline-block w-2 h-2 rounded-full bg-blue-500"
                  aria-hidden="true"
                />
                <span className="sr-only">{t('receipts.filter.customerActive')}</span>
              </>
            )}
          </button>
          {customerPanelOpen && (
            <div className="mt-2">
              <p className="text-xs text-gray-500 mb-2">{t('receipts.filter.customerPanelHint')}</p>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
                {CUSTOMER_FILTER_FIELDS.map(({ key, labelKey }) => (
                  <div key={key}>
                    <label className="form-label" htmlFor={`receipt-cf-${key}`}>
                      {t(labelKey)}
                    </label>
                    <input
                      id={`receipt-cf-${key}`}
                      type="text"
                      className="form-input"
                      value={customerFilters[key] ?? ''}
                      onChange={(e) =>
                        setCustomerFilters((prev) => ({ ...prev, [key]: e.target.value }))
                      }
                    />
                  </div>
                ))}
              </div>
              {customerFilterActive && (
                <button
                  type="button"
                  className="form-button text-xs mt-2 flex items-center gap-1"
                  onClick={() => setCustomerFilters({})}
                >
                  <X size={12} />
                  {t('receipts.filter.clearCustomer')}
                </button>
              )}
            </div>
          )}
        </div>
      </div>

      {filteredDrafts.length > 0 && (
        <div className="form-panel">
          <div className="mb-4 flex items-center gap-2 text-amber-800">
            <Clock size={18} />
            <h2 className="text-lg font-bold">{t('receipts.helyiFuggoBizonylatok')}</h2>
          </div>
          <div className="mb-4 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
            {t(
              'receipts.ezekABizonylatokHelyilegVeglegesSzigoruSzamadasuSorszammalRendelkeznekNgm232014ASzerverSzinkronFolyamatbanVanASorszamNemFogMegvaltozniCsakASzerverOldaliAuditNaploEgeszulKi',
            )}
          </div>
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>{t('receipts.helyiReferencia')}</th>
                <th>{t('common.type')}</th>
                <th>{t('common.createdAt')}</th>
                <th>{t('common.status2')}</th>
                <th>{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {filteredDrafts.map((draft) => (
                <tr key={draft.id}>
                  <td className="font-mono">{draft.referenceNumber}</td>
                  <td>{draft.title}</td>
                  <td>{new Date(draft.createdAt).toLocaleString('hu-HU')}</td>
                  <td>
                    {/* FKH-031 FR-3: hiba eseten a TENYLEGES ok latszik, piros jelzessel,
                        nem a fix "szinkronra var" felirat. */}
                    {draft.syncError ? (
                      <div className="flex flex-col gap-1">
                        <span className="badge badge-red" data-testid={`draft-sync-error-${draft.id}`}>
                          <AlertTriangle size={12} className="mr-1 inline" />
                          {draft.statusLabel}
                        </span>
                        <span className="text-xs text-red-700">{draft.syncError}</span>
                        {typeof draft.syncAttempts === 'number' && draft.syncAttempts > 0 && (
                          <span className="text-xs text-gray-500">
                            Sikertelen kísérletek: {draft.syncAttempts}
                          </span>
                        )}
                      </div>
                    ) : (
                      <span className="badge badge-yellow">{draft.statusLabel}</span>
                    )}
                  </td>
                  <td>
                    <div className="flex gap-2">
                      <button
                        onClick={() => setSelectedDraft(draft)}
                        className="form-button text-xs"
                      >
                        <Eye size={12} />
                        {t('closing.elonezet')}
                      </button>
                      <button
                        onClick={() => setSelectedDraft(draft)}
                        className="form-button text-xs"
                      >
                        <Printer size={12} />
                        {t('receipts.vazlatNyomtatas')}
                      </button>
                      {/* FKH-031 FR-4: "Ujrakuldes" a mar meglevo retryPendingTransaction
                          IPC-fuggveny ujrahasznositasaval, csak hibas TRANSACTION tetelre. */}
                      {draft.syncError && typeof draft.pendingTransactionId === 'number' && (
                        <button
                          onClick={() => void handleDraftRetry(draft)}
                          disabled={retryingDraftIds.has(draft.id)}
                          className="form-button text-xs"
                          data-testid={`draft-retry-${draft.id}`}
                        >
                          <RefreshCw
                            size={12}
                            className={retryingDraftIds.has(draft.id) ? 'animate-spin' : ''}
                          />
                          Újraküldés
                        </button>
                      )}
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
            <h2 className="text-lg font-bold">{t('receipts.reprintSection')}</h2>
          </div>
          <div className="mb-4 rounded-lg border border-blue-200 bg-blue-50 px-4 py-3 text-sm text-blue-800">
            {t('receipts.reprintSectionHint')}
          </div>
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>{t('receipts.helyiReferencia')}</th>
                <th>{t('common.type')}</th>
                <th>{t('common.createdAt')}</th>
                <th>{t('common.status2')}</th>
                <th>{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {filteredReprintable.map((item) => (
                <tr key={item.id}>
                  <td className="font-mono">{item.referenceNumber}</td>
                  <td>{item.title}</td>
                  <td>{new Date(item.createdAt).toLocaleString('hu-HU')}</td>
                  <td>
                    <span className="badge badge-blue">{item.statusLabel}</span>
                  </td>
                  <td>
                    <div className="flex gap-2">
                      <button
                        onClick={() => setSelectedDraft(item)}
                        className="form-button text-xs"
                      >
                        <Eye size={12} />
                        {t('closing.elonezet')}
                      </button>
                      <button onClick={() => reprintDraft(item)} className="form-button text-xs">
                        <Printer size={12} />
                        {t('receipts.reprintAction')}
                      </button>
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
            <tr>
              <th>{t('cashier.receiptNumber')}</th>
              <th>{t('receipts.navBizonylatszam')}</th>
              <th>{t('common.type')}</th>
              <th>{t('receipts.ugyfel')}</th>
              <th>{t('receipts.osszegFt')}</th>
              <th>{t('cashier.issueDate')}</th>
              <th>{t('cashier.printed')}</th>
              <th>{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {filteredReceipts.length === 0 ? (
              <tr>
                <td colSpan={8} className="text-center text-gray-500 py-4">
                  {t('common.noResult')}
                </td>
              </tr>
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
                      <span className="badge badge-red ml-2" title={t('receipts.amlBadgeTitle')}>
                        {t('receipts.amlBadgeText')}
                      </span>
                    )}
                    {/* EXCMD b5b FR-BSZUR-05 (V312): ENGEDÉLYEZŐ-jelölő — tooltip: név (beosztás) */}
                    {r.approvedByName && (
                      <span
                        className="badge badge-green ml-2"
                        title={`${r.approvedByName}${r.approvedByRole ? ` (${approverRoleLabel(r.approvedByRole)})` : ''}`}
                      >
                        {t('receipts.approvedBadgeText')}
                      </span>
                    )}
                  </td>
                  <td>{new Date(r.issueDate).toLocaleDateString('hu-HU')}</td>
                  <td>
                    <span className={`badge ${r.isPrinted ? 'badge-green' : 'badge-yellow'}`}>
                      {r.isPrinted ? 'Igen' : 'Nem'}
                    </span>
                  </td>
                  <td>
                    <div className="flex gap-2">
                      <button
                        onClick={() => void openReceiptDetails(r)}
                        className="form-button text-xs"
                        disabled={detailLoadingId === r.id}
                      >
                        <Eye size={12} />
                        {t('common.details')}
                      </button>
                      {!r.isPrinted && (
                        <button onClick={() => handlePrint(r)} className="form-button text-xs">
                          <Printer size={12} />
                          {t('common.print')}
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

      {selectedReceipt && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">{t('receipts.bizonylatReszletek')}</h2>
              <button onClick={() => setSelectedReceipt(null)} className="text-gray-500">
                X
              </button>
            </div>
            <div className="space-y-2">
              <div>
                <strong>{t('receipts.bizonylatszam')}</strong> {selectedReceipt.receiptNumber}
              </div>
              <div>
                <strong>{t('receipts.navBizonylatszam2')}</strong>{' '}
                {selectedReceipt.navReceiptNumber || '-'}
              </div>
              <div>
                <strong>{t('cashdesk.tipus')}</strong>{' '}
                {receiptTypeLabel(selectedReceipt.receiptType)}
              </div>
              {/* EXCMD b5b: ügyfél (FR-BSZUR-02) + összeg/AML-jelölő (FR-BSZUR-05), csak olvasható szűrési segédadat. */}
              <div>
                <strong>{t('receipts.ugyfelLabel')}</strong>{' '}
                {hasCustomer(selectedReceipt.customerName) ? selectedReceipt.customerName : '—'}
              </div>
              <div>
                <strong>{t('receipts.osszegFtLabel')}</strong>{' '}
                {formatHuf(selectedReceipt.hufAmount)}
                {isAmlThresholdExceeded(selectedReceipt.hufAmount) && (
                  <span className="badge badge-red ml-2" title={t('receipts.amlBadgeTitle')}>
                    {t('receipts.amlBadgeText')}
                  </span>
                )}
              </div>
              {/* EXCMD b5b FR-BSZUR-05 (V312): ENGEDÉLYEZŐ neve + beosztása (csak olvasható, AML-audit). */}
              <div>
                <strong>{t('receipts.engedelyezoLabel')}</strong>{' '}
                {selectedReceipt.approvedByName
                  ? `${selectedReceipt.approvedByName}${selectedReceipt.approvedByRole ? ` (${approverRoleLabel(selectedReceipt.approvedByRole)})` : ''}`
                  : '—'}
              </div>
              <div>
                <strong>{t('receipts.kiadasDatuma')}</strong>{' '}
                {new Date(selectedReceipt.issueDate).toLocaleString('hu-HU')}
              </div>
              <div>
                <strong>{t('receipts.nyomtatva')}</strong>{' '}
                {selectedReceipt.isPrinted ? 'Igen' : 'Nem'}
              </div>
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
            ? // Fizikai újranyomtatás (Codex P2 #1035): a bizonylat már szinkronizált — ez nem új
              // kiállítás, csak a meglévő (azonos sorszámú) bizonylat ismételt fizikai nyomtatása.
              'Már szinkronizált bizonylat fizikai újranyomtatása — a sorszám és a tartalom változatlan (pl. papírelakadás utáni ismételt nyomtatás).'
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
