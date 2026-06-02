import { useState, useEffect, useCallback, useRef } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import {
  ArrowRightLeft,
  Send,
  Download,
  RefreshCw,
  CheckCircle,
  XCircle,
  AlertCircle,
  Eye,
  Clock,
  Building2,
  Printer
} from 'lucide-react'
import {
  transferApi,
  currencyApi,
  branchApi,
  cashBalanceApi,
  Transfer,
  CreateTransferRequest,
  Currency
} from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { NumberInput } from '../../components/NumberInput'
import { formatDecimal, formatInteger } from '../../utils/numberFormat'
import { getErrorMessage } from '../../utils/errorHandling'
import {
  isElectronQueueAvailable,
  recordLocalAuditEvent,
  saveAndSyncPendingTransfer,
} from '../../utils/electronTransactions'
import { getLocalPendingTransfers, getCompanyType } from '../../utils/localQueue'
import { useTranslation } from 'react-i18next'
import SupervisorPinModal from '../../components/auth/SupervisorPinModal'
import { ReceiptPreviewModal } from '../../components/electron'
import { isElectron } from '../../utils/electron'
import { toast } from '../../components/ui/toaster'
import type { PrintReceiptData } from '../../types/receipt'
import { localIsoDate } from '../../utils/dateFormat'
import { getAvailableTransferTypes, getAllowedTransferTypeValues, isHufOnlyTransferType, filterCurrenciesForType, buildTransferLines, filterTransferTargetBranches, isTHBranch, isMainCashierBranch, validateCarrierSeal, type CurrencyLineInput } from './transferRules'

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

/**
 * v2.3.45 (Sourcery #307): TransferTypeEnum union (NEM string), igy a
 * compiler-szinten figyelmeztet az ismeretlen enum-ra. A null/undefined
 * eseteket az exhaustive switch + assertNever pattern fedi le.
 */
function localizeTransferType(rawType: TransferTypeEnum | null | undefined): string {
  if (rawType == null) return '—'
  switch (rawType) {
    case 'CURRENCY': return 'Deviza'
    case 'CASH': return 'Készpénz'
    case 'HANDLING_FEE': return 'Kezelési díj'
    case 'VAULT_DEPOSIT': return 'Széf befizetés'
    case 'VAULT_WITHDRAW': return 'Széf kivét'
    case 'CORRECTION': return 'Korrekció'
    case 'OTHER': return 'Egyéb'
    default: {
      // Exhaustive check: ha uj enum bekerul a TransferTypeEnum-ba,
      // a TS compiler itt error-t dob (`Type 'X' is not assignable to type 'never'`).
      const _exhaustive: never = rawType
      return _exhaustive
    }
  }
}

type TabType = 'outgoing' | 'incoming' | 'pending'

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
  const navigate = useNavigate()
  const worker = useAuthStore((state) => state.worker)
  const electronQueueAvailable = isElectronQueueAvailable()

  // Tab state
  const [activeTab, setActiveTab] = useState<TabType>('pending')

  // Lists
  const [outgoingTransfers, setOutgoingTransfers] = useState<Transfer[]>([])
  const [incomingTransfers, setIncomingTransfers] = useState<Transfer[]>([])
  const [pendingTransfers, setPendingTransfers] = useState<Transfer[]>([])
  const [pendingCount, setPendingCount] = useState(0)

  // Form state for new transfer
  const [showNewTransfer, setShowNewTransfer] = useState(false)
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [branches, setBranches] = useState<{ id: string; code: string; name: string; isVault?: boolean; branchTypeCode?: string; region?: string; vaultTerritoryId?: number | null }[]>([])

  // New transfer form
  const [transferDirection, setTransferDirection] = useState<'out' | 'in'>('out')
  const [toBranchId, setToBranchId] = useState('')
  const [currencyId, setCurrencyId] = useState<number | null>(null)
  const [amount, setAmount] = useState('')
  // #6: több-valutás átadólap sorai (CSAK valuta-típusnál aktív). Az első sor a header.
  const lineIdRef = useRef(1)
  const [currencyLines, setCurrencyLines] = useState<CurrencyLineInput[]>([{ id: 0, currencyId: null, amount: '' }])
  const [transferType, setTransferType] = useState<CreateTransferRequest['transferType']>('CURRENCY')
  const [notes, setNotes] = useState('')
  const [carrierName, setCarrierName] = useState('')
  const [sealNumber, setSealNumber] = useState('')

  // Receive modal
  const [showReceiveModal, setShowReceiveModal] = useState(false)
  const [selectedTransfer, setSelectedTransfer] = useState<Transfer | null>(null)
  const [receivedAmount, setReceivedAmount] = useState('')
  const [receiveNotes, setReceiveNotes] = useState('')

  // Supervisor PIN for TH transfers
  const [showSupervisorPin, setShowSupervisorPin] = useState(false)
  const [pendingTransferAfterPin, setPendingTransferAfterPin] = useState(false)

  // Loading & Error
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  // FR-6: sikeres rögzítés után nyomtatható bizonylat (Szállító + Plombaszám a szállítólevélen)
  const [printReceiptData, setPrintReceiptData] = useState<PrintReceiptData | null>(null)
  const [showReceiptModal, setShowReceiptModal] = useState(false)

  // Load data
  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      const [outgoing, incoming, pending, count, currencyData, localPending] = await Promise.all([
        transferApi.getOutgoing(),
        transferApi.getIncoming(),
        transferApi.getPending(),
        transferApi.countPending(),
        currencyApi.getActive(),
        electronQueueAvailable ? getLocalPendingTransfers(worker) : Promise.resolve([]),
      ])

      setOutgoingTransfers([...localPending, ...outgoing])
      setIncomingTransfers(incoming)
      setPendingTransfers([...localPending, ...pending])
      setPendingCount(count + localPending.length)
      setCurrencies(currencyData)

      // FK-005/C1 HALASZTVA (Codex P1 #844): a region-scope elejtené a TH (többlet/hiány) és
      // az 1.sz Főpénztár cél-fiókokat, amiket az átadás-átvétel üzleti szabály (supervisor-PIN)
      // igényel. A banki/vault-átadás "csak Bankok + Területek" finomszűrése külön körben, a
      // speciális (TH / Főpénztár / vault) célok megőrzésével. Itt egyelőre az összes aktív.
      const branchData = await branchApi.listActive()
      setBranches(branchData.map(b => ({
        id: b.id, code: b.code, name: b.name,
        isVault: b.isVault, branchTypeCode: b.branchTypeCode,
        region: b.region, vaultTerritoryId: b.vaultTerritoryId,
      })))
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [electronQueueAvailable, worker])

  useEffect(() => {
    void loadData()
  }, [loadData])

  // Belső ellenőri (supervisor) PIN kell, ha a cél TH (többlet/hiány könyvelés) VAGY az
  // 1.sz Főpénztár (hó végi visszapótlás) — Kósa Zoltán 2026-05-20 üzleti szabály.
  const targetBranch = branches.find(b => b.id === toBranchId)
  const isTargetTH = targetBranch ? isTHBranch(targetBranch) : false
  const isTargetMainCashier = targetBranch ? isMainCashierBranch(targetBranch) : false
  const requiresSupervisorPin = isTargetTH || isTargetMainCashier

  // === Átadás-átvétel üzleti szabályok (Kósa Zoltán tesztelői kérés) ===
  // A bejelentkezett felhasználó saját fiókja — ez dönti el, hogy pénztár vagy értéktár.
  const ownBranch = branches.find(b => b.id === worker?.branchId)
  const isVaultUser = ownBranch?.isVault === true

  // (Req #2/#3) Iránytól + felhasználó-típustól függő választható átadás-típusok.
  const availableTransferTypes = getAvailableTransferTypes(isVaultUser, transferDirection)
  // (Req #4/#5) Valuta-szűrés a típus szerint.
  const isHufOnlyType = isHufOnlyTransferType(transferType)
  const filteredCurrencies = filterCurrenciesForType(currencies, transferType)
  // (#6) Több-valutás átadólap CSAK valuta-típusnál. Egyéb típus → egy-soros (HUF/egy valuta).
  const isMultiCurrency = transferType === 'CURRENCY'

  // #6 sor-kezelők
  const updateCurrencyLine = useCallback((idx: number, field: 'currencyId' | 'amount', value: string) => {
    setCurrencyLines(prev => prev.map((row, i) => i === idx
      ? { ...row, [field]: field === 'currencyId' ? (value ? Number(value) : null) : value }
      : row))
  }, [])
  const addCurrencyLine = useCallback(() => {
    setCurrencyLines(prev => [...prev, { id: lineIdRef.current++, currencyId: null, amount: '' }])
  }, [])
  const removeCurrencyLine = useCallback((idx: number) => {
    setCurrencyLines(prev => prev.length <= 1 ? prev : prev.filter((_, i) => i !== idx))
  }, [])

  // Ha a felhasználóhoz nem elérhető típus van kiválasztva (pl. pénztár + VAULT_*), visszaállítjuk.
  useEffect(() => {
    if (!getAllowedTransferTypeValues(isVaultUser).includes(transferType)) {
      setTransferType('CURRENCY')
    }
  }, [isVaultUser, transferType])

  // A valuta-választás szinkronban tartása a típussal: FT/kez.ktg → HUF auto (és ha a
  // felhasználó kitörli, AZONNAL visszaáll HUF-ra), valuta → HUF nem maradhat.
  // currencyId a dep-listában → önjavító, nincs szükség eslint-disable-re (Sourcery/Copilot #721).
  useEffect(() => {
    if (currencies.length === 0) return
    if (isHufOnlyType) {
      const huf = currencies.find(c => c.code === 'HUF')
      if (huf && currencyId !== huf.id) setCurrencyId(huf.id)
    } else if (transferType === 'CURRENCY') {
      const selected = currencies.find(c => c.id === currencyId)
      if (selected?.code === 'HUF') setCurrencyId(null)
    }
  }, [transferType, currencies, currencyId, isHufOnlyType])

  // Create new transfer
  const handleCreateTransfer = async (pinVerified = false) => {
    if (!toBranchId) {
      setError('Válasszon cél irodát!')
      return
    }

    // #6: valuta-típusnál a sorokból építünk (több valuta), egyébként a single mezőkből.
    let effLines: Array<{ currencyId: number; amount: number }> | undefined
    let effCurrencyId: number | null = currencyId
    let effAmountValue: number
    if (isMultiCurrency) {
      const built = buildTransferLines(currencyLines)
      if (built.error) {
        setError(built.error)
        return
      }
      effLines = built.lines
      effCurrencyId = built.lines[0]!.currencyId
      effAmountValue = built.lines[0]!.amount
    } else {
      if (!currencyId || !amount) {
        setError('Minden mező kitöltése kötelező!')
        return
      }
      effAmountValue = parseFloat(amount.replace(',', '.').replace(/\s/g, ''))
      if (!Number.isFinite(effAmountValue) || effAmountValue <= 0) {
        setError('Adjon meg pozitív összeget!')
        return
      }
    }

    // (Req #7 / FR-1..3, NFR-1,2) Szállító és plombaszám KÖTELEZŐ + hossz/formátum — közös validátor
    // (a MovementManagerrel és a backend Bean Validationnel egyező egyetlen forrás).
    const carrierSealError = validateCarrierSeal(carrierName, sealNumber)
    if (carrierSealError) {
      setError(carrierSealError)
      return
    }

    if (requiresSupervisorPin && !pinVerified && !pendingTransferAfterPin) {
      setShowSupervisorPin(true)
      return
    }
    setPendingTransferAfterPin(false)

    // Készlet-ellenőrzés SORONKÉNT (csak kimenő átadásnál, nem VAULT_DEPOSIT-nál).
    if (transferDirection === 'out' && transferType !== 'VAULT_DEPOSIT') {
      try {
        const balances = await cashBalanceApi.list()
        const linesToCheck = effLines ?? [{ currencyId: effCurrencyId!, amount: effAmountValue }]
        for (const ln of linesToCheck) {
          const cur = currencies.find(c => c.id === ln.currencyId)
          if (!cur) continue
          const bal = balances.find((b: { currencyCode: string }) => b.currencyCode === cur.code)
          const available = bal?.currentBalance ?? 0
          if (ln.amount > available) {
            setError(`Nincs ennyi készlet! ${cur.code}: elérhető ${available.toLocaleString('hu-HU')}, kért ${ln.amount.toLocaleString('hu-HU')}`)
            return
          }
        }
      } catch {
        setError('Készlet-ellenőrzés sikertelen. Próbálja újra!')
        return
      }
    }

    try {
      setLoading(true)
      setError(null)

      const request: CreateTransferRequest = {
        toBranchId,
        currencyId: effCurrencyId!,
        amount: effAmountValue,
        transferType,
        direction: transferDirection === 'in' ? 'U' : 'F',
        notes: notes || undefined,
        carrierName: carrierName.trim() || undefined,
        sealNumber: sealNumber.trim() || undefined,
        lines: effLines,
      }

      if (electronQueueAvailable) {
        const branch = branches.find((item) => item.id === toBranchId)
        const currency = currencies.find((item) => item.id === effCurrencyId)
        if (!branch || !currency) {
          setError('Az átadáshoz érvényes cél iroda és valuta szükséges!')
          return
        }

        const outcome = await saveAndSyncPendingTransfer({
          targetBranchId: toBranchId,
          targetBranchCode: branch.code,
          currencyId: effCurrencyId,
          currencyCode: currency.code,
          amount: effAmountValue,
          hufValue: null,
          transferType,
          denominations: null,
          note: notes || null,
          carrierName: carrierName.trim() || null,
          sealNumber: sealNumber.trim() || null,
          direction: transferDirection === 'in' ? 'U' : 'F',
          // #6: a teljes valuta-sor lista JSON-ként (az Electron-úton is megmarad).
          lines: effLines ? JSON.stringify(effLines) : null,
        })

        const label = transferDirection === 'out' ? 'Átadás' : 'Átvétel'
        setSuccess(
          outcome.allSavedSynced
            ? `${label} helyileg rögzítve és azonnal szinkronizálva`
            : `${label} helyileg rögzítve. A feltöltés az Electron queue-ból folytatódik.`,
        )
        // FR-6: offline esetben is nyomtatható a szállítólevél a lokális adatokból.
        const now = new Date()
        setPrintReceiptData({
          type: 'transfer',
          companyType: getCompanyType(worker),
          // A bizonylatszám a TÉNYLEGES queue-sor ID-jéhez kötve (savedIds[0]) — a fabrikált
          // időbélyeg csak fallback, ha valamiért nincs mentett ID (Codex P2: a valós rekordra mutasson).
          receiptNumber: outcome.savedIds[0] != null
            ? `LOCAL-${localIsoDate()}-#${outcome.savedIds[0]}`
            : `LOCAL-${localIsoDate()}-${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}${String(now.getSeconds()).padStart(2, '0')}`,
          branchCode: worker?.branchCode ?? branch.code,
          cashierName: worker?.fullName ?? '',
          date: localIsoDate(),
          time: now.toTimeString().slice(0, 8),
          currencyCode: currency.code,
          foreignAmount: effAmountValue,
          transferTarget: `${branch.code} - ${branch.name}`,
          transferNote: notes || undefined,
          carrierName: carrierName.trim(),
          sealNumber: sealNumber.trim(),
        })
      } else {
        const result = await transferApi.create(request)
        setSuccess(`${transferDirection === 'out' ? 'Átadás' : 'Átvétel'} létrehozva: ${result.transferNumber}`)
        // FR-6: nyomtatható szállítólevél a szerver-válaszból (Szállító + Plombaszám is rajta).
        setPrintReceiptData({
          type: 'transfer',
          companyType: getCompanyType(worker),
          receiptNumber: result.transferNumber,
          branchCode: worker?.branchCode ?? result.fromBranchCode ?? 'LOCAL',
          cashierName: worker?.fullName ?? result.fromWorkerName ?? '',
          date: result.transferDate,
          time: result.transferTime,
          currencyCode: result.currencyCode,
          foreignAmount: result.amount,
          transferTarget: `${result.toBranchCode} - ${result.toBranchName}`,
          transferNote: result.notes,
          carrierName: result.carrierName,
          sealNumber: result.sealNumber,
        })
      }
      setShowNewTransfer(false)

      // Reset form
      setTransferDirection('out')
      setToBranchId('')
      setCurrencyId(null)
      setAmount('')
      setCurrencyLines([{ id: lineIdRef.current++, currencyId: null, amount: '' }])
      setNotes('')
      setCarrierName('')
      setSealNumber('')

      // Reload
      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

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
        notes: receiveNotes || undefined
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

  // Reject transfer
  const handleReject = async (transfer: Transfer) => {
    const reason = prompt('Visszautasítás oka:')
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

  // Cancel transfer
  const handleCancel = async (transfer: Transfer) => {
    if (!confirm('Biztosan törli ezt az átadást?')) return

    try {
      setLoading(true)
      await transferApi.cancel(transfer.id)
      await recordLocalAuditEvent({
        entityType: 'TRANSFER',
        eventType: 'CANCEL',
        entityId: String(transfer.id),
        referenceNumber: transfer.transferNumber,
        payload: {
          transferId: transfer.id,
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

  // Open receive modal
  const openReceiveModal = (transfer: Transfer) => {
    setSelectedTransfer(transfer)
    setReceivedAmount(transfer.amount.toString().replace('.', ','))
    setShowReceiveModal(true)
  }

  // Status badge
  const getStatusBadge = (status: string, statusDisplay: string) => {
    const statusMap: Record<string, string> = {
      PENDING: 'bg-yellow-100 text-yellow-700',
      IN_TRANSIT: 'bg-blue-100 text-blue-700',
      RECEIVED: 'bg-purple-100 text-purple-700',
      COMPLETED: 'bg-green-100 text-green-700',
      REJECTED: 'bg-red-100 text-red-700',
      CANCELLED: 'bg-gray-100 text-gray-500'
    }
    return (
      <span className={`px-2 py-1 text-xs rounded ${statusMap[status] || 'bg-gray-100'}`}>
        {statusDisplay}
      </span>
    )
  }

  // Transfer list component
  const TransferList = ({ transfers, showActions = false, isOutgoing = false }: {
    transfers: Transfer[]
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
          {transfers.length === 0 ? (
            <tr>
              <td colSpan={showActions ? 8 : 7} className="text-center text-gray-500 py-8">
                {t('transfers.nincsenekAtadasok')}
              </td>
            </tr>
          ) : (
            transfers.map((transfer) => (
              <tr key={transfer.id}>
                <td className="font-mono font-semibold">{transfer.transferNumber}</td>
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
                <td>{transfer.transferTypeDisplay ?? localizeTransferType(transfer.transferType)}</td>
                <td className="font-semibold">{transfer.currencyCode}</td>
                <td className="text-right font-mono">
                  {transfer.currencyCode === 'HUF'
                    ? formatInteger(transfer.amount)
                    : formatDecimal(transfer.amount, 2, 2)}
                </td>
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
                        onClick={() => navigate(`/transfers/${transfer.id}`)}
                        className="toolbar-button"
                        title="Részletek"
                      >
                        <Eye size={14} />
                      </button>
                      {transfer.isPending && !isOutgoing && (
                        <>
                          <button
                            type="button"
                            onClick={() => openReceiveModal(transfer)}
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
                    </div>
                  </td>
                )}
              </tr>
            ))
          )}
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
          {t('transfers.atadasBankMasikErtektar')}
          {pendingCount > 0 && (
            <span className="bg-red-500 text-white text-xs px-2 py-1 rounded-full">
              {pendingCount} {t('common.uj')}
            </span>
          )}
        </h1>
      </div>

      {/* 2026-04-29 v2.3.12 (E-B8): info-banner — banki workflow vs pénztári átadás-átvétel */}
      <div className="bg-blue-50 border border-blue-200 rounded p-3 text-sm text-blue-800 flex items-start gap-2">
        <Building2 size={16} className="flex-shrink-0 mt-0.5" />
        <div>
          <strong>{t('transfers.bankiKiBeszallitasEsErtektarErtektarKozottiMozgas')}</strong>{t('transfers.aPenztarakFele')}
          {t('transfers.szervezettAtadasAtvetelhezHasznaljaAz')}<Link to="/shipments" className="underline font-semibold">{t('transfers.atadasAtvetelPenztaraknak')}</Link>{t('transfers.menupontot')}
          {t('transfers.aTeljesBankiWorkflowBankiRendelesWesternUnionNapiKereteSurgossegiKivetSkeletonJeMegnezhetoA')}<Link to="/bank-orders" className="underline font-semibold">{t('transfers.bankiRendelesek')}</Link>{t('transfers.menupontbanTeljesImplementacioV240')}
        </div>
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
        <button
          type="button"
          onClick={() => setShowNewTransfer(true)}
          className="form-button-primary flex items-center gap-1"
        >
          <Send size={16} />
          {t('transfers.ujAtadas')}
        </button>
      </div>

      {/* Error/Success messages */}
      {error && (
        <div className="form-panel bg-red-50 border-red-200 flex items-center gap-2 text-red-700">
          <AlertCircle size={18} />
          <span>{error}</span>
          <button type="button" onClick={() => setError(null)} className="ml-auto text-red-500">×</button>
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
              <Printer size={14} /> Nyomtatás
            </button>
          )}
          <button type="button" onClick={() => { setSuccess(null); setPrintReceiptData(null) }} className={printReceiptData ? 'text-green-500' : 'ml-auto text-green-500'}>×</button>
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
          {t('transfers.atvetelreVaro')}{pendingCount})
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
          <TransferList transfers={pendingTransfers} showActions={true} isOutgoing={false} />
        )}
        {activeTab === 'outgoing' && (
          <TransferList transfers={outgoingTransfers} showActions={true} isOutgoing={true} />
        )}
        {activeTab === 'incoming' && (
          <TransferList transfers={incomingTransfers} showActions={false} isOutgoing={false} />
        )}
      </div>

      {/* New Transfer Modal */}
      {showNewTransfer && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md p-4">
            <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
              {transferDirection === 'out' ? <Send /> : <Download />}
              {transferDirection === 'out' ? 'Új átadás létrehozása' : 'Új átvétel igénylése'}
            </h2>

            <div className="space-y-4">
              {/* Irány választó */}
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => setTransferDirection('out')}
                  className={`flex-1 py-2 px-3 rounded-lg text-sm font-semibold border-2 transition-all flex items-center justify-center gap-2 ${
                    transferDirection === 'out'
                      ? 'border-blue-500 bg-blue-50 text-blue-700'
                      : 'border-gray-200 bg-white text-gray-600 hover:border-blue-300'
                  }`}
                >
                  <Send size={16} /> Átadás (kimenő)
                </button>
                <button
                  type="button"
                  onClick={() => setTransferDirection('in')}
                  className={`flex-1 py-2 px-3 rounded-lg text-sm font-semibold border-2 transition-all flex items-center justify-center gap-2 ${
                    transferDirection === 'in'
                      ? 'border-green-500 bg-green-50 text-green-700'
                      : 'border-gray-200 bg-white text-gray-600 hover:border-green-300'
                  }`}
                >
                  <Download size={16} /> Átvétel (bejövő)
                </button>
              </div>

              <div>
                <label htmlFor="to-branch" className="form-label">
                  {transferDirection === 'out' ? 'Cél iroda' : 'Forrás iroda (ahonnan érkezik)'}
                </label>
                <select
                  id="to-branch"
                  value={toBranchId}
                  onChange={(e) => setToBranchId(e.target.value)}
                  className="form-input w-full"
                >
                  <option value="">{t('transfers.valasszonIrodat')}</option>
                  {(() => {
                    // #1 (Kósa Zoltán 2026-05-20): a cél-lista CSAK a saját terület értéktára +
                    // TH + "Egyes számú pénztár" (1.sz Főpénztár). filterTransferTargetBranches
                    // üres-fallbackkel (ha a törzsadat hiányos → mindet mutatja, nehogy üres
                    // legyen a dropdown, mint 2026-05-15-én).
                    const candidates = branches.filter(b => transferDirection === 'out' ? b.id !== worker?.branchId : true)
                    return filterTransferTargetBranches(candidates, ownBranch)
                      .map(b => {
                        const isTH = b.branchTypeCode === 'TH' || /\bTH\b/i.test(b.code) || /\bTH\b/i.test(b.name)
                        const isVault = b.isVault === true
                        const badge = isVault ? ' (értéktár)' : isTH ? ' (TH)' : ''
                        return (
                          <option key={b.id} value={b.id}>
                            {b.code} - {b.name}{badge}
                          </option>
                        )
                      })
                  })()}
                </select>
              </div>

              <div>
                <label htmlFor="transfer-type" className="form-label">{t('circulars.tipus')}</label>
                <select
                  id="transfer-type"
                  value={transferType}
                  onChange={(e) => setTransferType(e.target.value as CreateTransferRequest['transferType'])}
                  className="form-input w-full"
                >
                  {availableTransferTypes.map(opt => (
                    <option key={opt.value} value={opt.value}>{opt.label}</option>
                  ))}
                </select>
              </div>

              {isMultiCurrency ? (
                /* #6: több valuta egy átadólapon — soronként valuta + összeg */
                <div>
                  <label className="form-label">Valuták és összegek (több is megadható)</label>
                  <div className="space-y-2">
                    {currencyLines.map((line, idx) => (
                      <div key={line.id ?? idx} className="flex items-center gap-2">
                        <select
                          value={line.currencyId ?? ''}
                          onChange={(e) => updateCurrencyLine(idx, 'currencyId', e.target.value)}
                          className="form-input flex-1"
                          aria-label={`Valuta ${idx + 1}`}
                        >
                          <option value="">{t('transfers.valasszonValutat')}</option>
                          {filteredCurrencies.map(c => (
                            <option key={c.id} value={c.id}>{c.code} - {c.name}</option>
                          ))}
                        </select>
                        <NumberInput
                          value={line.amount}
                          onChange={(v) => updateCurrencyLine(idx, 'amount', v)}
                          className="form-input w-32"
                          placeholder="0"
                          allowDecimals={true}
                          allowNegative={false}
                          thousandSeparator={true}
                        />
                        <button
                          type="button"
                          onClick={() => removeCurrencyLine(idx)}
                          disabled={currencyLines.length <= 1}
                          className="toolbar-button text-red-600 disabled:opacity-30"
                          title="Sor törlése"
                          aria-label="Sor törlése"
                        >
                          <XCircle size={16} />
                        </button>
                      </div>
                    ))}
                  </div>
                  <button
                    type="button"
                    onClick={addCurrencyLine}
                    className="mt-2 text-sm text-blue-600 hover:underline"
                  >
                    + Valuta hozzáadása
                  </button>
                </div>
              ) : (
                <>
                  <div>
                    <label htmlFor="currency" className="form-label">{t('transfers.valuta')}</label>
                    <select
                      id="currency"
                      value={currencyId ?? ''}
                      onChange={(e) => setCurrencyId(e.target.value ? Number(e.target.value) : null)}
                      className="form-input w-full"
                    >
                      {/* FT/kez.ktg típusnál nincs üres opció — a HUF kötelezően kiválasztva marad. */}
                      {!isHufOnlyType && <option value="">{t('transfers.valasszonValutat')}</option>}
                      {filteredCurrencies.map(c => (
                        <option key={c.id} value={c.id}>{c.code} - {c.name}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label htmlFor="amount" className="form-label">{t('transfers.osszeg')}</label>
                    <NumberInput
                      id="amount"
                      value={amount}
                      onChange={setAmount}
                      className="form-input w-full"
                      placeholder="0"
                      allowDecimals={true}
                      allowNegative={false}
                      thousandSeparator={true}
                    />
                  </div>
                </>
              )}

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label htmlFor="carrier-name" className="form-label">Szállító neve <span className="text-red-500">*</span></label>
                  <input
                    id="carrier-name"
                    type="text"
                    maxLength={128}
                    value={carrierName}
                    onChange={(e) => setCarrierName(e.target.value)}
                    className="form-input w-full"
                    placeholder="Szállító neve..."
                  />
                </div>
                <div>
                  <label htmlFor="seal-number" className="form-label">Plombaszám <span className="text-red-500">*</span></label>
                  <input
                    id="seal-number"
                    type="text"
                    maxLength={64}
                    value={sealNumber}
                    onChange={(e) => setSealNumber(e.target.value)}
                    className="form-input w-full"
                    placeholder="Plombaszám..."
                  />
                </div>
              </div>

              <div>
                <label htmlFor="notes" className="form-label">{t('common.note')}</label>
                <textarea
                  id="notes"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  className="form-input w-full"
                  rows={2}
                  placeholder="Opcionális megjegyzés..."
                />
              </div>
            </div>

            <div className="flex justify-end gap-2 mt-6">
              <button
                type="button"
                onClick={() => setShowNewTransfer(false)}
                className="form-button"
              >
                {t('common.cancel')}
              </button>
              <button
                type="button"
                onClick={() => void handleCreateTransfer()}
                className="form-button-primary"
                disabled={loading}
              >
                {loading ? <RefreshCw size={16} className="animate-spin" /> : transferDirection === 'out' ? <Send size={16} /> : <Download size={16} />}
                {transferDirection === 'out' ? 'Átadás létrehozása' : 'Átvétel igénylése'}
              </button>
            </div>
          </div>
        </div>
      )}

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
                <label htmlFor="received-amount" className="form-label">{t('transfers.atvettOsszeg')}</label>
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
                <label htmlFor="receive-notes" className="form-label">{t('common.note')}</label>
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
                {loading ? <RefreshCw size={16} className="animate-spin" /> : <CheckCircle size={16} />}
                {t('transfers.atvetelMegerositese')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Supervisor PIN for TH transfers */}
      <SupervisorPinModal
        open={showSupervisorPin}
        workerId={worker?.id ?? 0}
        workerLabel={`${worker?.firstName ?? ''} ${worker?.lastName ?? ''}`}
        onSuccess={() => {
          setShowSupervisorPin(false)
          setPendingTransferAfterPin(true)
          void handleCreateTransfer(true)
        }}
        onCancel={() => setShowSupervisorPin(false)}
      />

      {/* FR-5/FR-6: szállítólevél előnézet + nyomtatás (Szállító + Plombaszám is rajta). */}
      <ReceiptPreviewModal
        isOpen={showReceiptModal}
        onClose={() => setShowReceiptModal(false)}
        receiptData={printReceiptData}
        qrCodeDataUrl={null}
        allowPrint={isElectron()}
        onPrint={async () => {
          if (!printReceiptData) return
          if (!window.electronAPI?.printReceipt) {
            toast.warning('Nyomtatás nem elérhető', isElectron()
              ? 'Electron preload/electronAPI hiba — indítsa újra a klienst.'
              : 'Webes módban nincs nyomtatás. Telepítse az Electron klienst.')
            return
          }
          try {
            const ok = await window.electronAPI.printReceipt(JSON.stringify(printReceiptData))
            if (ok) toast.success('Nyomtatás elindítva', `Bizonylat: ${printReceiptData.receiptNumber ?? '—'}`)
            else toast.error('Nyomtatás sikertelen', 'Ellenőrizze a nyomtatót (Beállítások > Nyomtatás).')
          } catch {
            toast.error('Nyomtatás sikertelen', 'A nyomtatási parancs nem futott le.')
          }
        }}
      />
    </div>
  )
}
