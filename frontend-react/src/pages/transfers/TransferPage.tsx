import { useState, useEffect, useCallback, useRef, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import {
  ArrowRightLeft,
  Send,
  Download,
  RefreshCw,
  CheckCircle,
  XCircle,
  AlertCircle,
  Eye,
  Search,
  Clock,
  Building2,
  Printer,
  Ban,
} from 'lucide-react'
import {
  transferApi,
  shipmentRequestApi,
  currencyApi,
  branchApi,
  Transfer,
  ShipmentRequest,
  Currency,
} from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { NumberInput } from '../../components/NumberInput'
import { formatDecimal, formatInteger } from '../../utils/numberFormat'
import { getErrorMessage } from '../../utils/errorHandling'
import { isElectronQueueAvailable, recordLocalAuditEvent } from '../../utils/electronTransactions'
import {
  getLocalPendingTransfers,
  getCompanyType,
  getShipmentReceiptOutboxState,
  queueOfflineShipmentReceipt,
  queueOfflineTransferStorno,
} from '../../utils/localQueue'
import { useTranslation } from 'react-i18next'
import { toast } from '../../components/ui/toaster'
import type { PrintReceiptData } from '../../types/receipt'
import { localIsoDate } from '../../utils/dateFormat'
import TransferReceiptModal from './TransferReceiptModal'
import { buildVaultLabel, loadOwnVaultContact } from './transferPageShared'
import StaleShipmentConfirmDialog from '../../components/shipments/StaleShipmentConfirmDialog'
import { useTextReasonModal } from '../../components/TextReasonModal'
import i18n from '../../i18n'

/**
 * v2.3.41 (B31 audit fix): Raw enum -> magyar label mapping.
 * Az electron-queue local fallback eseten a transferTypeDisplay nincs feltoltve
 * a backend-bol, ezert a UI raw 'CURRENCY' / 'CASH' enum-ot rendert volna —
 * ezt forditjuk magyarra a frontend-szinten.
 *
 * v2.3.42 (Sourcery #306): TransferType union explicit (NEM raw string),
 * igy ha az enum bovul, a switch-statement compiler-szinten figyelmeztet.
 */
type TransferTypeEnum =
  | 'CURRENCY'
  | 'CASH'
  | 'HANDLING_FEE'
  | 'VAULT_DEPOSIT'
  | 'VAULT_WITHDRAW'
  | 'CORRECTION'
  | 'OTHER'
  | 'ERB'
  | 'FRB'
  | 'TRB'
  | 'PRB'

/**
 * v2.3.45 (Sourcery #307): TransferTypeEnum union (NEM string), igy a
 * compiler-szinten figyelmeztet az ismeretlen enum-ra. A null/undefined
 * eseteket az exhaustive switch + assertNever pattern fedi le.
 */
function localizeTransferType(rawType: TransferTypeEnum | null | undefined): string {
  if (rawType == null) return '—'
  switch (rawType) {
    case 'CURRENCY':
      return 'Deviza'
    case 'CASH':
      return 'Készpénz'
    case 'HANDLING_FEE':
      return 'Kezelési díj'
    case 'VAULT_DEPOSIT':
      return 'Széf befizetés'
    case 'VAULT_WITHDRAW':
      return 'Széf kivét'
    case 'CORRECTION':
      return 'Korrekció'
    case 'OTHER':
      return 'Egyéb'
    case 'ERB':
      return 'Fixing valuta mozgás RB (ERB)'
    case 'FRB':
      return 'Forint mozgás RB (FRB)'
    case 'TRB':
      return 'Egyedi kötés RB (TRB)'
    case 'PRB':
      return 'POS átvétel banktól (PRB)'
    default: {
      // Exhaustive check: ha uj enum bekerul a TransferTypeEnum-ba,
      // a TS compiler itt error-t dob (`Type 'X' is not assignable to type 'never'`).
      const _exhaustive: never = rawType
      return _exhaustive
    }
  }
}

type TabType = 'outgoing' | 'incoming' | 'pending'

const SHIPMENT_RETRYABLE_TRANSPORT_CODES = new Set([
  'ERR_NETWORK',
  'ECONNABORTED',
  'ECONNRESET',
  'ECONNREFUSED',
  'ETIMEDOUT',
  'ENOTFOUND',
  'EAI_AGAIN',
])

function isAmbiguousShipmentTransportFailure(error: unknown): boolean {
  const transportError = error as { code?: unknown; response?: unknown }
  return (
    transportError.response == null &&
    typeof transportError.code === 'string' &&
    SHIPMENT_RETRYABLE_TRANSPORT_CODES.has(transportError.code)
  )
}

/**
 * Átadás-átvétel oldal
 *
 * Legacy: ATADVET.DLL funkciók
 * - Pénztárak közötti valuta/készpénz mozgás
 * - Átadólap generálás
 * - Átvétel kezelés
 */
export default function TransferPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const electronQueueAvailable = isElectronQueueAvailable()

  // Tab state
  const [activeTab, setActiveTab] = useState<TabType>('pending')

  // Lists
  const [outgoingTransfers, setOutgoingTransfers] = useState<Transfer[]>([])
  const [incomingTransfers, setIncomingTransfers] = useState<Transfer[]>([])
  const [pendingTransfers, setPendingTransfers] = useState<Transfer[]>([])
  const [pendingShipments, setPendingShipments] = useState<ShipmentRequest[]>([])
  const [staleConfirmShipment, setStaleConfirmShipment] = useState<ShipmentRequest | null>(null)
  const [queuedShipmentReceiptIds, setQueuedShipmentReceiptIds] = useState<Set<string>>(new Set())
  const [shipmentReceiptIssues, setShipmentReceiptIssues] = useState<
    Array<{ requestNumber: string; message: string }>
  >([])
  const [pendingCount, setPendingCount] = useState(0)
  const shipmentReceiptKeysRef = useRef(new Map<string, string>())

  // A listák bizonylat-előnézetéhez szükséges törzsadatok
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [branches, setBranches] = useState<
    {
      id: string
      code: string
      name: string
      isVault?: boolean
      branchTypeCode?: string
      region?: string
      regionCode?: string | null
      vaultTerritoryId?: number | null
    }[]
  >([])

  // Receive modal
  const [showReceiveModal, setShowReceiveModal] = useState(false)
  const [selectedTransfer, setSelectedTransfer] = useState<Transfer | null>(null)
  const [receivedAmount, setReceivedAmount] = useState('')
  const [receiveNotes, setReceiveNotes] = useState('')
  const [receiveDetailLoading, setReceiveDetailLoading] = useState(false)
  const [transferLookupNumber, setTransferLookupNumber] = useState('')
  const [transferLookupLoading, setTransferLookupLoading] = useState(false)

  // Loading & Error
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  // FR-6: sikeres rögzítés után nyomtatható bizonylat (Szállító + Plombaszám a szállítólevélen)
  const [printReceiptData, setPrintReceiptData] = useState<PrintReceiptData | null>(null)
  const [showReceiptModal, setShowReceiptModal] = useState(false)

  // FR-12..16: sztornó modal (indoklással)
  const [showStornoModal, setShowStornoModal] = useState(false)
  const [stornoTarget, setStornoTarget] = useState<Transfer | null>(null)
  const [stornoReason, setStornoReason] = useState('')
  const stornoPreviewRequestRef = useRef(0)

  // FKH-027 B-csoport: a natív window.prompt() kiváltása (Electronban silent no-op)
  const { modal: reasonModal, requestReason } = useTextReasonModal()

  // Load data
  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      const [localPending, shipmentOutbox] = electronQueueAvailable
        ? await Promise.all([getLocalPendingTransfers(worker), getShipmentReceiptOutboxState()])
        : [[], { pending: [], issues: [] }]
      const localShipmentIntents: ShipmentRequest[] = shipmentOutbox.pending.map((intent) => {
        const requestedAt = intent.createdAt.includes('T')
          ? intent.createdAt
          : intent.createdAt.replace(' ', 'T')
        return {
          id: intent.shipmentId,
          requestNumber: intent.requestNumber,
          requestingBranchId: '',
          requestingBranchName: 'Offline átvételi szándék',
          targetBranchId: intent.branchId,
          targetBranchName: worker?.branchName ?? intent.branchId,
          shipmentType: 'TRANSFER',
          requestedDeliveryDate: requestedAt.slice(0, 10),
          requestStatus: 'PENDING_SYNC',
          requestedByWorkerId: String(intent.workerId),
          requestedByWorkerName: worker?.fullName ?? 'Helyi pénztáros',
          requestedAt,
          items: [],
        }
      })
      const queuedShipmentIds = new Set(localShipmentIntents.map((shipment) => shipment.id))

      // A tartós helyi állapotot a hálózati kérések ELŐTT publikáljuk. Így egy REST-hiba vagy
      // renderer-újraindítás nem rejti el a már rögzített átvételi szándékot.
      setOutgoingTransfers(localPending)
      setPendingTransfers(localPending)
      setPendingShipments(localShipmentIntents)
      setQueuedShipmentReceiptIds(queuedShipmentIds)
      setShipmentReceiptIssues(shipmentOutbox.issues)
      setPendingCount(localPending.length + localShipmentIntents.length)

      const [outgoing, incoming, pending, count, shipmentPending, currencyData] = await Promise.all(
        [
          transferApi.getOutgoing(),
          transferApi.getIncoming(),
          transferApi.getPending(),
          transferApi.countPending(),
          shipmentRequestApi.getPendingForBranch(),
          currencyApi.getActive(),
        ],
      )

      const remoteShipmentIds = new Set(shipmentPending.map((shipment) => shipment.id))
      const mergedShipments = [
        ...shipmentPending,
        ...localShipmentIntents.filter((shipment) => !remoteShipmentIds.has(shipment.id)),
      ]

      setOutgoingTransfers([...localPending, ...outgoing])
      setIncomingTransfers(incoming)
      setPendingTransfers([...localPending, ...pending])
      setPendingShipments(mergedShipments)
      setQueuedShipmentReceiptIds(queuedShipmentIds)
      setShipmentReceiptIssues(shipmentOutbox.issues)
      setPendingCount(count + localPending.length + mergedShipments.length)
      setCurrencies(currencyData)

      // FK-005/C1 HALASZTVA (Codex P1 #844): a region-scope elejtené a TH (többlet/hiány) és
      // az 1.sz Főpénztár cél-fiókokat, amiket az átadás-átvétel üzleti szabály (supervisor-PIN)
      // igényel. A banki/vault-átadás "csak Bankok + Területek" finomszűrése külön körben, a
      // speciális (TH / Főpénztár / vault) célok megőrzésével. Itt egyelőre az összes aktív.
      const branchData = await branchApi.listActive()
      setBranches(
        branchData.map((b) => ({
          id: b.id,
          code: b.code,
          name: b.name,
          isVault: b.isVault,
          branchTypeCode: b.branchTypeCode,
          region: b.region,
          vaultTerritoryId: b.vaultTerritoryId,
        })),
      )
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [electronQueueAvailable, worker])

  useEffect(() => {
    void loadData()
  }, [loadData])

  // A bejelentkezett felhasználó saját fiókja a bizonylat értéktár-feliratához.
  const ownBranch = branches.find((b) => b.id === worker?.branchId)

  // FR-4 (fejléc-javítás 2026-06-11): a „Kérő iroda" automatikus kitöltése. Elsődleges forrás a
  // betöltött branch-törzs; ha az még nem érhető el, a worker JWT-kontextus branchName/branchCode
  // mezői; „—" csak ha egyik sincs.
  // FR-1/FR-5/FR-6 (bizonylat-doc 2. kör, 2026-06-12): ÉRTÉKTÁRNÁL a formátum
  // "[azonosító]. [Értéktár neve]" (pl. "20. Szeged Értéktár") — az azonosító a
  // NUMERIKUS branch.region_code (TBD-1 megerősítve: V239 seed, BR020→'20'; a
  // BranchDto.regionCode hordozza — a .region a SZÖVEGES terület-név, pl.
  // "SZEGED", Codex #1114). Pénztárnál marad a kód-név (a régió-kód a TERÜLETET
  // jelöli, több pénztár osztozik rajta — ott nem egyedi azonosító). Hiányzó
  // kódnál TBD-2 szerint kód-név fallback, sosem "—"/null.
  const vaultLabel = buildVaultLabel(ownBranch, worker)

  // Receive transfer
  const handleReceive = async () => {
    if (!selectedTransfer || !receivedAmount) {
      setError('Adja meg az átvett összeget!')
      return
    }

    const amountValue = parseFloat(receivedAmount.replace(',', '.').replace(/\s/g, ''))

    try {
      setLoading(true)
      setError(null)

      await transferApi.receive(selectedTransfer.id, {
        receivedAmount: amountValue,
        notes: receiveNotes || undefined,
      })

      await recordLocalAuditEvent({
        entityType: 'TRANSFER',
        eventType: 'RECEIVE',
        entityId: String(selectedTransfer.id),
        referenceNumber: selectedTransfer.transferNumber,
        payload: {
          transferId: selectedTransfer.id,
          receivedAmount: amountValue,
          notes: receiveNotes || null,
        },
        status: 'SERVER_FORWARDED',
      })

      setSuccess('Átvétel sikeres!')
      setShowReceiveModal(false)
      setSelectedTransfer(null)
      setReceivedAmount('')
      setReceiveNotes('')

      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  const handleShipmentReceive = async (shipment: ShipmentRequest, confirmedStale = false) => {
    if (queuedShipmentReceiptIds.has(shipment.id)) return
    if (shipment.staleForDelivery === true && !confirmedStale) {
      setStaleConfirmShipment(shipment)
      return
    }
    const idempotencyKey =
      shipmentReceiptKeysRef.current.get(shipment.id) ?? globalThis.crypto.randomUUID()
    shipmentReceiptKeysRef.current.set(shipment.id, idempotencyKey)
    try {
      setLoading(true)
      setError(null)
      if (confirmedStale) {
        await shipmentRequestApi.deliver(shipment.id, idempotencyKey, { confirmedStale: true })
      } else {
        await shipmentRequestApi.deliver(shipment.id, idempotencyKey)
      }
      shipmentReceiptKeysRef.current.delete(shipment.id)
      setSuccess(`Shipment átvétele sikeres: ${shipment.requestNumber}`)
      await loadData()
    } catch (err) {
      if (
        electronQueueAvailable &&
        isAmbiguousShipmentTransportFailure(err) &&
        worker?.branchId &&
        worker.id != null
      ) {
        try {
          const queued = confirmedStale
            ? await queueOfflineShipmentReceipt(
                shipment.id,
                shipment.requestNumber,
                worker.branchId,
                Number(worker.id),
                idempotencyKey,
                true,
              )
            : await queueOfflineShipmentReceipt(
                shipment.id,
                shipment.requestNumber,
                worker.branchId,
                Number(worker.id),
                idempotencyKey,
              )
          if (queued) {
            shipmentReceiptKeysRef.current.delete(shipment.id)
            setQueuedShipmentReceiptIds((current) => new Set(current).add(shipment.id))
            setSuccess(
              `Shipment átvétele helyben rögzítve: ${shipment.requestNumber}. Szinkronra vár; a készlet csak szervernyugta után változik.`,
            )
            return
          }
        } catch (queueError) {
          setError(getErrorMessage(queueError))
          return
        }
      }
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  // Reject transfer
  const handleReject = async (transfer: Transfer) => {
    const reason = await requestReason({ title: 'Visszautasítás oka:' })
    if (!reason) return

    try {
      setLoading(true)
      await transferApi.reject(transfer.id, reason)
      await recordLocalAuditEvent({
        entityType: 'TRANSFER',
        eventType: 'REJECT',
        entityId: String(transfer.id),
        referenceNumber: transfer.transferNumber,
        payload: {
          transferId: transfer.id,
          reason,
        },
        status: 'SERVER_FORWARDED',
      })
      setSuccess('Átadás visszautasítva')
      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  // Cancel transfer — a backend mostantól a biztonságos sztornó-útvonalra irányít
  // (kassza-visszapótlás + bizonylat + audit), ezért az indoklás KÖTELEZŐ.
  const handleCancel = async (transfer: Transfer) => {
    const reason = await requestReason({
      title: 'Átadás visszavonása — az indoklás kötelező',
      placeholder: 'Pl. téves rögzítés, elmaradt szállítás',
    })
    if (reason === null) return // megszakítva
    const trimmedReason = reason.trim()
    if (!trimmedReason) {
      setError('Az átadás visszavonásához az indoklás megadása kötelező!')
      return
    }

    try {
      setLoading(true)
      setError(null)
      await transferApi.cancel(transfer.id, trimmedReason)
      await recordLocalAuditEvent({
        entityType: 'TRANSFER',
        eventType: 'CANCEL',
        entityId: String(transfer.id),
        referenceNumber: transfer.transferNumber,
        payload: {
          transferId: transfer.id,
          reason: trimmedReason,
        },
        status: 'SERVER_FORWARDED',
      })
      setSuccess('Átadás törölve')
      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  const closeStornoModal = () => {
    stornoPreviewRequestRef.current += 1
    setShowStornoModal(false)
    setStornoTarget(null)
  }

  // Copilot PR #1101: régi/offline pending soroknál a lines currencyCode-ja hiányozhat —
  // a currencyId alapján a betöltött valuta-törzsből oldjuk fel (végső fallback: #id).
  const resolveLineCode = useCallback(
    (line: { currencyId: number; currencyCode?: string }): string =>
      line.currencyCode ??
      currencies.find((c) => c.id === line.currencyId)?.code ??
      `#${line.currencyId}`,
    [currencies],
  )

  // Penztar-batch A.2 (2026-06-12): a lista szem-ikonja a BIZONYLATOT hívja elő.
  // (Korábban a /transfers/:id route-ra navigált, ami ugyanerre a lista-komponensre volt
  // kötve — látható hatás nélkül.) A bizonylat a lista-sor TELJES Transfer objektumából
  // épül (a lista-DTO minden mezőt hordoz, offline pending soroknál is) — nincs extra
  // API-hívás. A Kérő/Cél a kanonikus fromBranch/toBranch mezőkből jön (NEM a bejelentkezett
  // fiók vaultLabel-jéből — visszanézéskor a kiállító eltérhet a nézegetőtől).
  const openDocumentPreview = async (transfer: Transfer) => {
    // FR-1 (bizonylat-doc 2. kör): az értéktár-oldal "[region_code]. [név]" formátumban
    // (pl. "20. Szeged Értéktár"), ha a region_code ismert; egyébként kód-név (TBD-2).
    const regionLabel = (code: string, name: string, region?: string | null) =>
      region?.trim() ? `${region.trim()}. ${name}` : `${code} - ${name}`
    const fromLabel = `${transfer.fromBranchCode} - ${transfer.fromBranchName}`
    const toLabel = `${transfer.toBranchCode} - ${transfer.toBranchName}`
    const isReceiptDoc = transfer.direction === 'U'
    // Átadásnál (F) a from-, átvételnél (U) a to-oldal az értéktár (a kiállító).
    const vaultSideLabel = isReceiptDoc
      ? regionLabel(transfer.toBranchCode, transfer.toBranchName, transfer.toBranchRegionCode)
      : regionLabel(transfer.fromBranchCode, transfer.fromBranchName, transfer.fromBranchRegionCode)
    // Batch2-E: offline (electron-queue) sorok nem hordoznak fejléc cím/telefon adatot —
    // fallback a lokális cached_cash_desks mirrorból, kizárólag hiány esetén.
    const vaultContact =
      !transfer.vaultAddress || !transfer.vaultPhone
        ? await loadOwnVaultContact(worker?.branchId)
        : {}
    setPrintReceiptData({
      type: 'transfer',
      companyType: getCompanyType(worker),
      // Sztornózott bizonylatnál a sztornó-sorszám + jelölés (a sztornó-ág mintája szerint).
      receiptNumber: transfer.isCancelled
        ? (transfer.stornoSerialNumber ?? `${transfer.transferNumber}-SZ`)
        : transfer.transferNumber,
      // FR-5/FR-6: a Kérő/Cél mező értéktár-oldala is region-formátumban.
      branchCode: vaultSideLabel,
      transferTarget: isReceiptDoc ? fromLabel : toLabel,
      transferDocType: isReceiptDoc ? 'receipt' : 'handover',
      cashierName: transfer.fromWorkerName ?? '',
      date: transfer.transferDate,
      time: transfer.transferTime,
      currencyCode: transfer.currencyCode,
      foreignAmount: transfer.amount,
      roundedHufAmount: transfer.hufValue,
      // Batch2-E: a deviza-bizonylat árfolyama a tárolt forintosított értékből DERIVÁLT
      // (rate = hufValue / amount) — a transfer-adatmodellben nincs külön rate oszlop,
      // és definíció szerint pontosan ezzel az aránnyal készült a forintosítás.
      rate:
        transfer.currencyCode !== 'HUF' && transfer.hufValue != null && transfer.amount > 0
          ? Number((transfer.hufValue / transfer.amount).toFixed(2))
          : undefined,
      transferNote: transfer.notes,
      carrierName: transfer.carrierName,
      sealNumber: transfer.sealNumber,
      vaultAddress: transfer.vaultAddress ?? vaultContact.address,
      vaultPhone: transfer.vaultPhone ?? vaultContact.phone,
      // Batch2-E + FR-1: a kiállító értéktár azonosító + név a fejlécben,
      // region-formátumban ("20. Szeged Értéktár"), ha a region_code ismert.
      vaultBranchLabel: vaultSideLabel,
      isStorno: transfer.isCancelled === true,
      stornoReason: transfer.cancellationReason,
      denominations: transfer.denominations,
      // A.1: több-valutás átadólapon minden sor a bizonylatra kerül.
      transferLines:
        transfer.lines && transfer.lines.length > 1
          ? transfer.lines.map((l) => ({ currencyCode: resolveLineCode(l), amount: l.amount }))
          : undefined,
    })
    setShowReceiptModal(true)
  }

  const handleTransferNumberLookup = async (event?: FormEvent<HTMLFormElement>) => {
    event?.preventDefault()
    const transferNumber = transferLookupNumber.trim()
    if (!transferNumber) {
      setError('Adja meg az átadólap számát!')
      return
    }
    try {
      setTransferLookupLoading(true)
      setError(null)
      const transfer = await transferApi.getByTransferNumber(transferNumber)
      await openDocumentPreview(transfer)
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setTransferLookupLoading(false)
    }
  }

  // FR-12/FR-15: sztornó modal megnyitása + szerveroldali preview betöltése.
  const openStornoModal = async (transfer: Transfer) => {
    const requestId = stornoPreviewRequestRef.current + 1
    stornoPreviewRequestRef.current = requestId
    setStornoTarget(transfer)
    setStornoReason('')
    setShowStornoModal(true)
    try {
      const preview = await transferApi.getStornoPreview(transfer.id)
      if (stornoPreviewRequestRef.current === requestId) {
        setStornoTarget(preview)
      }
    } catch (err) {
      if (stornoPreviewRequestRef.current === requestId) {
        toast.warning('Sztornó előnézet nem frissült', getErrorMessage(err))
      }
    }
  }

  // FR-12..16: sztornó rögzítése indoklással → a sztornó bizonylat nyomtatható
  const handleStornoConfirm = async () => {
    if (!stornoTarget) return
    const reason = stornoReason.trim()
    if (!reason) {
      setError('A sztornó indoklása kötelező!')
      return
    }
    try {
      setLoading(true)
      setError(null)
      const result = await transferApi.storno(stornoTarget.id, reason)
      closeStornoModal()
      setSuccess(`Sztornózva: ${result.stornoSerialNumber ?? `${result.transferNumber}-SZ`}`)
      // FR-16: a sztornó bizonylat előnézet + nyomtatás. A Kérő/Cél orientáció az EREDETI irányt
      // követi (átvételnél fordított), hogy egyezzen az eredeti bizonylattal. A vaultLabel a
      // component-szintű FR-4 auto-kitöltött érték.
      const stornoIsReceipt = result.direction === 'U'
      const stornoOther = `${result.toBranchCode} - ${result.toBranchName}`
      setPrintReceiptData({
        type: 'transfer',
        companyType: getCompanyType(worker),
        receiptNumber: result.stornoSerialNumber ?? `${result.transferNumber}-SZ`,
        branchCode: stornoIsReceipt ? stornoOther : vaultLabel,
        transferTarget: stornoIsReceipt ? vaultLabel : stornoOther,
        transferDocType: stornoIsReceipt ? 'receipt' : 'handover',
        cashierName: worker?.fullName ?? '',
        date: result.transferDate,
        time: result.transferTime,
        currencyCode: result.currencyCode,
        foreignAmount: result.amount,
        roundedHufAmount: result.hufValue,
        carrierName: result.carrierName,
        sealNumber: result.sealNumber,
        vaultAddress: result.vaultAddress,
        vaultPhone: result.vaultPhone, // FR-2 (fejléc-javítás)
        vaultBranchLabel: stornoIsReceipt ? stornoOther : vaultLabel, // Batch2-E
        isStorno: true, // FR-13/15
        stornoReason: result.cancellationReason ?? reason,
        denominations: result.denominations, // FR-17..19
      })
      setShowReceiptModal(true) // FR-16: a sztornó bizonylat azonnal nyomtatható
      await loadData()
    } catch (err) {
      // OFFLINE (internetkimaradás): queue-oljuk a sztornót — a backend a szinkronkor fordítja
      // vissza a készletet (a tranzakció-sztornóval azonos minta). A bizonylat-előnézet a memóriából.
      const e = err as { response?: unknown; code?: string }
      const networkErr = !e?.response || e?.code === 'ERR_NETWORK'
      const target = stornoTarget
      if (electronQueueAvailable && networkErr && target) {
        try {
          const queued = await queueOfflineTransferStorno(target.id, target.transferNumber, reason)
          if (queued) {
            closeStornoModal()
            setSuccess(
              `Sztornó helyben rögzítve (offline): ${target.transferNumber}-SZ. A szinkronizálás az internet visszatértekor folytatódik.`,
            )
            const stornoIsReceipt = target.direction === 'U'
            const stornoOther = `${target.toBranchCode} - ${target.toBranchName}`
            const now = new Date()
            setPrintReceiptData({
              type: 'transfer',
              companyType: getCompanyType(worker),
              receiptNumber: `${target.transferNumber}-SZ`,
              branchCode: stornoIsReceipt ? stornoOther : vaultLabel,
              transferTarget: stornoIsReceipt ? vaultLabel : stornoOther,
              transferDocType: stornoIsReceipt ? 'receipt' : 'handover',
              cashierName: worker?.fullName ?? '',
              date: localIsoDate(),
              time: now.toTimeString().slice(0, 8),
              currencyCode: target.currencyCode,
              foreignAmount: target.amount,
              roundedHufAmount: target.hufValue,
              carrierName: target.carrierName,
              sealNumber: target.sealNumber,
              vaultAddress: target.vaultAddress,
              vaultPhone: target.vaultPhone, // FR-2 (fejléc-javítás)
              vaultBranchLabel: stornoIsReceipt ? stornoOther : vaultLabel, // Batch2-E
              isStorno: true,
              stornoReason: reason,
            })
            setShowReceiptModal(true)
            return
          }
        } catch {
          /* ha a queue-olás is bukik, az általános hiba jelzés következik */
        }
      }
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  // Open receive modal
  const openReceiveModal = async (transfer: Transfer) => {
    setSelectedTransfer(transfer)
    setReceivedAmount(transfer.amount.toString().replace('.', ','))
    setReceiveNotes('')
    setShowReceiveModal(true)
    setReceiveDetailLoading(true)
    try {
      const detail = await transferApi.getById(transfer.id)
      setSelectedTransfer(detail)
      setReceivedAmount(detail.amount.toString().replace('.', ','))
    } catch (err) {
      toast.warning('Átadás részlete nem frissült', getErrorMessage(err))
    } finally {
      setReceiveDetailLoading(false)
    }
  }

  // Status badge
  const getStatusBadge = (status: string, statusDisplay: string) => {
    const statusMap: Record<string, string> = {
      PENDING: 'bg-yellow-100 text-yellow-700',
      IN_TRANSIT: 'bg-blue-100 text-blue-700',
      RECEIVED: 'bg-purple-100 text-purple-700',
      COMPLETED: 'bg-green-100 text-green-700',
      REJECTED: 'bg-red-100 text-red-700',
      CANCELLED: 'bg-gray-100 text-gray-500',
    }
    return (
      <span className={`px-2 py-1 text-xs rounded ${statusMap[status] || 'bg-gray-100'}`}>
        {statusDisplay}
      </span>
    )
  }

  // Transfer list component
  const TransferList = ({
    transfers,
    shipments = [],
    showActions = false,
    isOutgoing = false,
  }: {
    transfers: Transfer[]
    shipments?: ShipmentRequest[]
    showActions?: boolean
    isOutgoing?: boolean
  }) => (
    <div className="overflow-x-auto">
      <table className="data-grid w-full">
        <thead>
          <tr>
            <th>{t('transfers.atadolapSzam')}</th>
            <th>{isOutgoing ? 'Cél iroda' : 'Forrás iroda'}</th>
            <th>{t('common.type')}</th>
            <th>{t('common.currency')}</th>
            <th className="text-right">{t('common.amount')}</th>
            <th>{t('common.date')}</th>
            <th>{t('common.status')}</th>
            {showActions && <th className="w-32">{t('common.actions')}</th>}
          </tr>
        </thead>
        <tbody>
          {transfers.length === 0 && shipments.length === 0 ? (
            <tr>
              <td colSpan={showActions ? 8 : 7} className="text-center text-gray-500 py-8">
                {t('transfers.nincsenekAtadasok')}
              </td>
            </tr>
          ) : (
            transfers.map((transfer) => (
              <tr key={transfer.id} className={transfer.isCancelled ? 'opacity-60' : ''}>
                <td className="font-mono font-semibold">
                  <span className={transfer.isCancelled ? 'line-through' : ''}>
                    {transfer.transferNumber}
                  </span>
                  {/* FR-14: sztornózott bizonylat jelölése a listában */}
                  {transfer.isCancelled && (
                    <span className="ml-1 inline-block rounded bg-red-100 text-red-700 text-[10px] font-semibold px-1.5 py-0.5 align-middle">
                      {i18n.t('literals.sztornozva')}
                    </span>
                  )}
                </td>
                <td>
                  <div className="flex items-center gap-1">
                    <Building2 size={14} className="text-gray-400" />
                    <span>
                      {isOutgoing
                        ? `${transfer.toBranchCode} - ${transfer.toBranchName}`
                        : `${transfer.fromBranchCode} - ${transfer.fromBranchName}`}
                    </span>
                  </div>
                </td>
                {/* v2.3.41 (B31 audit fix): fallback raw enum -> magyar label
                  ha transferTypeDisplay missing (electron-queue lokal fallback). */}
                <td>
                  {transfer.transferTypeDisplay ?? localizeTransferType(transfer.transferType)}
                </td>
                {/* Penztar-batch A.1 (2026-06-12): több-valutás átadólapon MINDEN sor látszik
                    (eddig csak a fejléc = első valuta jelent meg). Egysorosnál változatlan. */}
                {transfer.lines && transfer.lines.length > 1 ? (
                  <>
                    <td className="font-semibold">
                      {transfer.lines.map((line, i) => (
                        <div key={i}>{resolveLineCode(line)}</div>
                      ))}
                    </td>
                    <td className="text-right font-mono">
                      {transfer.lines.map((line, i) => (
                        <div key={i}>
                          {/* Copilot PR #1101: a kód a törzsből feloldva — HUF-nál egész formázás. */}
                          {resolveLineCode(line) === 'HUF'
                            ? formatInteger(line.amount)
                            : formatDecimal(line.amount, 2, 2)}
                        </div>
                      ))}
                    </td>
                  </>
                ) : (
                  <>
                    <td className="font-semibold">{transfer.currencyCode}</td>
                    <td className="text-right font-mono">
                      {transfer.currencyCode === 'HUF'
                        ? formatInteger(transfer.amount)
                        : formatDecimal(transfer.amount, 2, 2)}
                    </td>
                  </>
                )}
                <td className="text-sm">
                  <div>{new Date(transfer.transferDate).toLocaleDateString('hu-HU')}</div>
                  <div className="text-gray-500">{transfer.transferTime}</div>
                </td>
                <td>{getStatusBadge(transfer.status, transfer.statusDisplay)}</td>
                {showActions && (
                  <td>
                    <div className="flex gap-1">
                      <button
                        type="button"
                        onClick={() => {
                          void openDocumentPreview(transfer)
                        }}
                        className="toolbar-button"
                        title="Bizonylat megtekintése"
                      >
                        <Eye size={14} />
                      </button>
                      {transfer.isPending && !isOutgoing && (
                        <>
                          <button
                            type="button"
                            onClick={() => {
                              void openReceiveModal(transfer)
                            }}
                            className="toolbar-button text-green-600"
                            title="Átvétel"
                          >
                            <CheckCircle size={14} />
                          </button>
                          <button
                            type="button"
                            onClick={() => handleReject(transfer)}
                            className="toolbar-button text-red-600"
                            title="Visszautasítás"
                          >
                            <XCircle size={14} />
                          </button>
                        </>
                      )}
                      {transfer.isPending && isOutgoing && (
                        <button
                          type="button"
                          onClick={() => handleCancel(transfer)}
                          className="toolbar-button text-red-600"
                          title="Törlés"
                        >
                          <XCircle size={14} />
                        </button>
                      )}
                      {/* FR-12: sztornó (indoklással) — CSAK véglegesített (COMPLETED), még nem sztornózott
                          bizonylaton. A PENDING-et a „Törlés" (/cancel) kezeli; a még nem szinkronizált
                          lokális sorok PENDING-ek, így itt nem jelennek meg (nincs backend-id). */}
                      {transfer.isCompleted && !transfer.isCancelled && (
                        <button
                          type="button"
                          onClick={() => {
                            void openStornoModal(transfer)
                          }}
                          className="toolbar-button text-orange-600"
                          title="Sztornó (indoklással)"
                        >
                          <Ban size={14} />
                        </button>
                      )}
                    </div>
                  </td>
                )}
              </tr>
            ))
          )}
          {shipments.map((shipment) => (
            <tr key={`shipment-${shipment.id}`}>
              <td className="font-mono font-semibold">{shipment.requestNumber}</td>
              <td>
                <div className="flex items-center gap-1">
                  <Building2 size={14} className="text-gray-400" />
                  <span>{shipment.requestingBranchName}</span>
                </div>
              </td>
              <td>{i18n.t('literals.shipment')}</td>
              <td className="font-semibold">
                {shipment.items?.map((item) => (
                  <div key={item.id}>{item.currencyCode ?? `#${item.currencyId}`}</div>
                ))}
              </td>
              <td className="text-right font-mono">
                {shipment.items?.map((item) => (
                  <div key={item.id}>
                    {formatDecimal(item.requestedAmount ?? item.amount ?? 0, 2, 2)}
                  </div>
                ))}
              </td>
              <td className="text-sm">{new Date(shipment.requestedAt).toLocaleString('hu-HU')}</td>
              <td>
                {queuedShipmentReceiptIds.has(shipment.id)
                  ? getStatusBadge('PENDING', 'Szinkronra vár')
                  : getStatusBadge(shipment.requestStatus, 'Átvételre vár')}
              </td>
              {showActions && (
                <td>
                  <button
                    type="button"
                    onClick={() => void handleShipmentReceive(shipment)}
                    className="toolbar-button text-green-600"
                    title="Shipment átvétele"
                    disabled={loading || queuedShipmentReceiptIds.has(shipment.id)}
                  >
                    <CheckCircle size={14} />
                  </button>
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <ArrowRightLeft />
          {t('transfers.visszaigazolasAlairas')}
          {pendingCount > 0 && (
            <span className="bg-red-500 text-white text-xs px-2 py-1 rounded-full">
              {pendingCount} {t('common.uj')}
            </span>
          )}
        </h1>
      </div>

      {/* Header tools (frissítés + új átadás) */}
      <div className="flex justify-end gap-2">
        <button
          type="button"
          onClick={loadData}
          className="form-button flex items-center gap-1"
          disabled={loading}
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          {t('common.refresh')}
        </button>
        <Link to="/transfers/new" className="form-button-primary flex items-center gap-1">
          <Send size={16} />
          {/* FKH-026 v3 FR-7: a felirat-kontraktus "+ Új átadás" — a "+ " prefix a
              fordítási kulcson kívül, az i18n-kulcs (transfers.ujAtadas) változatlan. */}
          {`+ ${t('transfers.ujAtadas')}`}
        </Link>
      </div>

      <form
        onSubmit={(event) => {
          void handleTransferNumberLookup(event)
        }}
        className="form-panel p-3 flex flex-col gap-2 sm:flex-row sm:items-end"
      >
        <div className="min-w-0 flex-1">
          <label htmlFor="transfer-number-lookup" className="form-label">
            {i18n.t('literals.atadolap-keresese')}
          </label>
          <input
            id="transfer-number-lookup"
            value={transferLookupNumber}
            onChange={(event) => setTransferLookupNumber(event.target.value)}
            className="form-input w-full"
            placeholder="AT105000042"
            autoComplete="off"
          />
        </div>
        <button
          type="submit"
          className="form-button flex items-center justify-center gap-1"
          disabled={transferLookupLoading || transferLookupNumber.trim() === ''}
        >
          {transferLookupLoading ? (
            <RefreshCw size={16} className="animate-spin" />
          ) : (
            <Search size={16} />
          )}
          {i18n.t('literals.kereses-2')}
        </button>
      </form>

      {/* Error/Success messages */}
      {error && (
        <div className="form-panel bg-red-50 border-red-200 flex items-center gap-2 text-red-700">
          <AlertCircle size={18} />
          <span>{error}</span>
          <button type="button" onClick={() => setError(null)} className="ml-auto text-red-500">
            {i18n.t('literals.lit-34')}
          </button>
        </div>
      )}

      {success && (
        <div className="form-panel bg-green-50 border-green-200 flex items-center gap-2 text-green-700">
          <CheckCircle size={18} />
          <span>{success}</span>
          {/* FR-6: sikeres rögzítés után Nyomtatás gomb a szállítólevélhez. */}
          {printReceiptData && (
            <button
              type="button"
              onClick={() => setShowReceiptModal(true)}
              className="ml-auto inline-flex items-center gap-1 rounded bg-green-600 px-2.5 py-1 text-xs font-semibold text-white hover:bg-green-700"
            >
              <Printer size={14} />
              {i18n.t('literals.nyomtatas-2')}
            </button>
          )}
          <button
            type="button"
            onClick={() => {
              setSuccess(null)
              setPrintReceiptData(null)
            }}
            className={printReceiptData ? 'text-green-500' : 'ml-auto text-green-500'}
          >
            {i18n.t('literals.lit-34')}
          </button>
        </div>
      )}

      {shipmentReceiptIssues.length > 0 && (
        <div className="form-panel border-amber-300 bg-amber-50 text-amber-900">
          <div className="mb-1 flex items-center gap-2 font-semibold">
            <AlertCircle size={18} />
            {i18n.t('literals.offline-shipment-atveteli-hibak')}
          </div>
          <ul className="list-disc space-y-1 pl-5 text-sm">
            {shipmentReceiptIssues.map((issue) => (
              <li key={`${issue.requestNumber}-${issue.message}`}>
                {issue.requestNumber}
                {i18n.t('literals.lit-22')}
                {issue.message}
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Tabs */}
      <div className="flex gap-1 border-b">
        <button
          type="button"
          onClick={() => setActiveTab('pending')}
          className={`px-4 py-2 font-medium border-b-2 transition-colors ${
            activeTab === 'pending'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-gray-600 hover:text-gray-800'
          }`}
        >
          <Clock size={16} className="inline mr-1" />
          {t('transfers.atvetelreVaro')}
          {` (${pendingCount})`}
        </button>
        <button
          type="button"
          onClick={() => setActiveTab('outgoing')}
          className={`px-4 py-2 font-medium border-b-2 transition-colors ${
            activeTab === 'outgoing'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-gray-600 hover:text-gray-800'
          }`}
        >
          <Send size={16} className="inline mr-1" />
          {t('transfers.kimenoAtadasok')}
        </button>
        <button
          type="button"
          onClick={() => setActiveTab('incoming')}
          className={`px-4 py-2 font-medium border-b-2 transition-colors ${
            activeTab === 'incoming'
              ? 'border-blue-600 text-blue-600'
              : 'border-transparent text-gray-600 hover:text-gray-800'
          }`}
        >
          <Download size={16} className="inline mr-1" />
          {t('transfers.bejovoAtadasok')}
        </button>
      </div>

      {/* Tab content */}
      <div className="form-panel p-0">
        {activeTab === 'pending' && (
          <TransferList
            transfers={pendingTransfers}
            shipments={pendingShipments}
            showActions={true}
            isOutgoing={false}
          />
        )}
        {activeTab === 'outgoing' && (
          <TransferList transfers={outgoingTransfers} showActions={true} isOutgoing={true} />
        )}
        {activeTab === 'incoming' && (
          <TransferList transfers={incomingTransfers} showActions={false} isOutgoing={false} />
        )}
      </div>

      {/* Receive Modal */}
      {showReceiveModal && selectedTransfer && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md p-4">
            <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
              <Download />
              {t('transfers.atvetelVegrehajtasa')}
            </h2>

            <div className="space-y-4">
              <div className="bg-gray-50 p-3 rounded">
                <div className="text-sm text-gray-600">{t('transfers.atadolapSzam')}</div>
                <div className="font-mono font-semibold">{selectedTransfer.transferNumber}</div>
                {receiveDetailLoading && (
                  <div className="mt-1 text-xs text-gray-500">
                    {i18n.t('literals.reszletadatok-frissitese')}
                  </div>
                )}
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <div className="text-sm text-gray-600">{t('transfers.forrasIroda')}</div>
                  <div className="font-semibold">{selectedTransfer.fromBranchCode}</div>
                </div>
                <div>
                  <div className="text-sm text-gray-600">{t('transfers.atado')}</div>
                  <div className="font-semibold">{selectedTransfer.fromWorkerName}</div>
                </div>
              </div>

              <div className="bg-blue-50 p-3 rounded">
                <div className="text-sm text-gray-600">{t('transfers.kuldottOsszeg')}</div>
                <div className="text-xl font-mono font-bold text-blue-700">
                  {formatDecimal(selectedTransfer.amount, 2, 2)} {selectedTransfer.currencyCode}
                </div>
              </div>

              <div>
                <label htmlFor="received-amount" className="form-label">
                  {t('transfers.atvettOsszeg')}
                </label>
                <NumberInput
                  id="received-amount"
                  value={receivedAmount}
                  onChange={setReceivedAmount}
                  className="form-input w-full text-lg"
                  allowDecimals={true}
                  allowNegative={false}
                />
              </div>

              <div>
                <label htmlFor="receive-notes" className="form-label">
                  {t('common.note')}
                </label>
                <textarea
                  id="receive-notes"
                  value={receiveNotes}
                  onChange={(e) => setReceiveNotes(e.target.value)}
                  className="form-input w-full"
                  rows={2}
                  placeholder="Eltérés esetén írja le az okot..."
                />
              </div>
            </div>

            <div className="flex justify-end gap-2 mt-6">
              <button
                type="button"
                onClick={() => {
                  setShowReceiveModal(false)
                  setSelectedTransfer(null)
                }}
                className="form-button"
              >
                {t('common.cancel')}
              </button>
              <button
                type="button"
                onClick={handleReceive}
                className="form-button-primary"
                disabled={loading}
              >
                {loading ? (
                  <RefreshCw size={16} className="animate-spin" />
                ) : (
                  <CheckCircle size={16} />
                )}
                {t('transfers.atvetelMegerositese')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* FR-12..16: sztornó modal — kötelező indoklással */}
      {showStornoModal && stornoTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md p-6">
            <h3 className="text-lg font-bold mb-2 flex items-center gap-2">
              <Ban size={18} className="text-orange-600" />
              {i18n.t('literals.bizonylat-sztornozasa')}
            </h3>
            <p className="text-sm text-gray-600 mb-3">
              {stornoTarget.transferNumber}
              {i18n.t('literals.a-sztorno-bizonylat-sorszama')}{' '}
              <span className="font-mono font-semibold">
                {stornoTarget.stornoSerialNumber ?? `${stornoTarget.transferNumber}-SZ`}
              </span>
            </p>
            <label htmlFor="storno-reason" className="form-label">
              {i18n.t('literals.sztorno-indoklasa')}
              <span className="text-red-500">{i18n.t('literals.lit-3')}</span>
            </label>
            <textarea
              id="storno-reason"
              value={stornoReason}
              onChange={(e) => setStornoReason(e.target.value)}
              className="form-input w-full"
              rows={3}
              maxLength={500}
              placeholder="Az érvénytelenítés oka (kötelező, max 500 karakter)…"
            />
            <div className="flex justify-end gap-2 mt-4">
              <button type="button" onClick={closeStornoModal} className="form-button">
                {t('common.cancel')}
              </button>
              <button
                type="button"
                onClick={() => void handleStornoConfirm()}
                disabled={loading || !stornoReason.trim()}
                className="form-button-primary bg-orange-600 hover:bg-orange-700 disabled:opacity-50"
              >
                {i18n.t('literals.sztorno-rogzitese')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* FR-5/FR-6: szállítólevél előnézet + nyomtatás (Szállító + Plombaszám is rajta). */}
      <TransferReceiptModal
        isOpen={showReceiptModal}
        onClose={() => setShowReceiptModal(false)}
        receiptData={printReceiptData}
      />
      {staleConfirmShipment && (
        <StaleShipmentConfirmDialog
          shipment={staleConfirmShipment}
          onCancel={() => setStaleConfirmShipment(null)}
          onConfirm={() => {
            const shipment = staleConfirmShipment
            setStaleConfirmShipment(null)
            void handleShipmentReceive(shipment, true)
          }}
        />
      )}
      {reasonModal}
    </div>
  )
}
