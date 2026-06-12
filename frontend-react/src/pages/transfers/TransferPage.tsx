import { useState, useEffect, useCallback, useRef } from 'react'
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
  Clock,
  Building2,
  Printer,
  Ban
} from 'lucide-react'
import {
  transferApi,
  currencyApi,
  branchApi,
  cashBalanceApi,
  denominationApi,
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
import { getLocalPendingTransfers, getCompanyType, queueOfflineTransferStorno } from '../../utils/localQueue'
import { useTranslation } from 'react-i18next'
import SupervisorPinModal from '../../components/auth/SupervisorPinModal'
import { ReceiptPreviewModal } from '../../components/electron'
import { isElectron } from '../../utils/electron'
import { toast } from '../../components/ui/toaster'
import type { PrintReceiptData } from '../../types/receipt'
import { localIsoDate } from '../../utils/dateFormat'
import { getAvailableTransferTypes, getAllowedTransferTypeValues, isHufOnlyTransferType, isCurrencyOnlyTransferType, filterCurrenciesForType, buildTransferLines, filterTransferTargetBranches, isTHBranch, isMainCashierBranch, validateCarrierSeal, buildDenominationPayload, type CurrencyLineInput } from './transferRules'

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
    case 'CURRENCY': return 'Deviza'
    case 'CASH': return 'Készpénz'
    case 'HANDLING_FEE': return 'Kezelési díj'
    case 'VAULT_DEPOSIT': return 'Széf befizetés'
    case 'VAULT_WITHDRAW': return 'Széf kivét'
    case 'CORRECTION': return 'Korrekció'
    case 'OTHER': return 'Egyéb'
    case 'ERB': return 'Fixing valuta mozgás RB (ERB)'
    case 'FRB': return 'Forint mozgás RB (FRB)'
    case 'TRB': return 'Egyedi kötés RB (TRB)'
    case 'PRB': return 'POS átvétel banktól (PRB)'
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
  // FR-17/18: opcionális címletezés (darab × névleges érték). Üres → nem küldjük, a bizonylaton nem jelenik meg.
  const [showDenominations, setShowDenominations] = useState(false)
  const denomIdRef = useRef(1)
  const [denominationLines, setDenominationLines] = useState<Array<{ id: number; quantity: string; faceValue: string }>>([
    { id: 0, quantity: '', faceValue: '' },
  ])
  // Penztar-batch A.3 (2026-06-12, user-kérés): a kiválasztott valuta TÉNYLEGES címleteit
  // ajánljuk fel (denomination törzs, GET /denominations/currency/{id} — a Címletezés
  // menüvel azonos forrás), hogy ne kézzel kelljen a névleges értéket beírni (elgépelés-
  // védelem). A sorok szabadon szerkeszthetők maradnak; törzs-hiány / offline → szabad bevitel.
  const [denomPresetCode, setDenomPresetCode] = useState<string | null>(null)
  const denomPresetCurrencyRef = useRef<number | null>(null)

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

  // FR-12..16: sztornó modal (indoklással)
  const [showStornoModal, setShowStornoModal] = useState(false)
  const [stornoTarget, setStornoTarget] = useState<Transfer | null>(null)
  const [stornoReason, setStornoReason] = useState('')
  const stornoPreviewRequestRef = useRef(0)

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

  // FR-4 (fejléc-javítás 2026-06-11): a „Kérő iroda" automatikus kitöltése. Elsődleges forrás a
  // betöltött branch-törzs (kód + név, a cél-iroda formátummal egyezően); ha az még nem érhető el,
  // a worker JWT-kontextus branchName/branchCode mezői; „—" csak ha egyik sincs.
  const vaultLabel = ownBranch
    ? `${ownBranch.code} - ${ownBranch.name}`
    : (worker?.branchName ?? worker?.branchCode ?? '—')

  // (Req #2/#3) Iránytól + felhasználó-típustól függő választható átadás-típusok.
  const availableTransferTypes = getAvailableTransferTypes(isVaultUser, transferDirection)
  // Irányváltás-guard: a PRB csak átvétel ('in') irányban választható — ha a user PRB-vel
  // vált át 'out'-ra, a típus visszaesik az alapértelmezett CURRENCY-re (ne maradjon a
  // select-ben a listából hiányzó, backend által is elutasított érték). Teljes dep-lista,
  // önjavító (a CURRENCY minden irány/szerep mellett elérhető → nincs loop).
  useEffect(() => {
    if (!getAvailableTransferTypes(isVaultUser, transferDirection).some(o => o.value === transferType)) {
      setTransferType('CURRENCY')
    }
  }, [transferDirection, isVaultUser, transferType])
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
    } else if (isCurrencyOnlyTransferType(transferType)) {
      // CURRENCY mellett az ERB/TRB (csak-deviza technikai RB-kötések) is: a beragadt
      // HUF currencyId-t töröljük, különben üresnek látszó select + backend 400.
      const selected = currencies.find(c => c.id === currencyId)
      if (selected?.code === 'HUF') setCurrencyId(null)
    }
  }, [transferType, currencies, currencyId, isHufOnlyType])

  // Penztar-batch A.3: a címletezés-blokk előtöltése a kiválasztott valuta címlet-törzséből.
  // Több-valutás módban az ELSŐ kitöltött sor valutájára kötünk (a címletezés-modell
  // fejléc-szintű — backend: TransferService a fejléc-valutával menti és az első sor
  // összegéhez validálja). Hiba / üres törzs / offline → szabad bevitel marad.
  useEffect(() => {
    if (!showDenominations) {
      denomPresetCurrencyRef.current = null
      setDenomPresetCode(null)
      return
    }
    const denomCurrencyId = isMultiCurrency
      ? currencyLines.find(l => l.currencyId != null)?.currencyId ?? null
      : currencyId
    if (denomCurrencyId == null || denomPresetCurrencyRef.current === denomCurrencyId) return
    let cancelled = false
    void (async () => {
      try {
        const denoms = await denominationApi.getByCurrencyId(denomCurrencyId)
        if (cancelled) return
        // Copilot PR #1101: a ref MINDEN kimenetelnél beáll — üres törzs ne okozzon
        // rerender-enkénti újra-lekérést (checkbox ki/be vagy valutaváltás újraengedi).
        denomPresetCurrencyRef.current = denomCurrencyId
        if (denoms.length === 0) {
          // Codex PR #1101 P2: valutaváltáskor az ELŐZŐ valuta stale presetje nem
          // maradhat — üres törzsnél vissza a szabad bevitelre.
          setDenomPresetCode(null)
          setDenominationLines([{ id: denomIdRef.current++, quantity: '', faceValue: '' }])
          return
        }
        const code = currencies.find(c => c.id === denomCurrencyId)?.code ?? null
        setDenomPresetCode(code)
        // Címletenként egy sor, csökkenő névértékkel (a DenominationPage rendezése) —
        // a felhasználó csak a darabszámot tölti ki; a sorok szerkeszthetők maradnak.
        setDenominationLines(
          [...denoms]
            .sort((a, b) => b.faceValue - a.faceValue)
            .map(d => ({ id: denomIdRef.current++, quantity: '', faceValue: String(d.faceValue) })),
        )
      } catch {
        // Törzs nem elérhető (pl. offline) → szabad bevitel; a ref beállítása megakadályozza
        // a rerender-enkénti újrapróbálkozást (Copilot PR #1101) — checkbox-toggle újraenged.
        if (!cancelled) denomPresetCurrencyRef.current = denomCurrencyId
      }
    })()
    return () => { cancelled = true }
  }, [showDenominations, isMultiCurrency, currencyId, currencyLines, currencies])

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

    // FR-17..20b: opcionális címletezés feldolgozása + összeg-egyezés (pure helper, tesztelt).
    const denomResult = buildDenominationPayload(showDenominations, denominationLines, effAmountValue)
    if (denomResult.error) {
      setError(denomResult.error)
      return
    }
    const effDenominations = denomResult.denominations

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

      // A.1: a sorok valutakóddal dúsítva — az offline lista + bizonylat internet nélkül
      // is meg tudja jeleníteni a kódokat (a backend TransferLineDto fogadja a mezőt).
      const enrichedLines = effLines?.map(l => ({
        ...l,
        currencyCode: currencies.find(c => c.id === l.currencyId)?.code,
      }))
      // A.1: a bizonylaton minden valuta-sor megjelenik (egysorosnál a fejléc-mezők maradnak).
      const receiptTransferLines = enrichedLines && enrichedLines.length > 1
        ? enrichedLines.map(l => ({ currencyCode: l.currencyCode ?? `#${l.currencyId}`, amount: l.amount }))
        : undefined

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
        denominations: effDenominations,
      }

      // FR-1/FR-2/FR-3/FR-4: a bizonylat fejléc-adatai. A bejelentkezett értéktár neve a vault-oldal
      // (component-szintű vaultLabel, FR-4 auto-kitöltéssel); átadásnál Kérő iroda = értéktár,
      // átvételnél Cél iroda = értéktár.
      const transferDocType: 'handover' | 'receipt' = transferDirection === 'in' ? 'receipt' : 'handover'
      // FR-17..19: a bizonylaton megjelenő címletezési sorok (lineTotal a frontend számolja az előnézethez).
      const receiptDenominations = effDenominations?.map(d => ({
        quantity: d.quantity,
        faceValue: d.faceValue,
        currencyCode: currencies.find(c => c.id === effCurrencyId)?.code,
        lineTotal: d.quantity * d.faceValue,
      }))

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
          denominations: effDenominations ? JSON.stringify(effDenominations) : null,
          note: notes || null,
          carrierName: carrierName.trim() || null,
          sealNumber: sealNumber.trim() || null,
          direction: transferDirection === 'in' ? 'U' : 'F',
          // #6 + A.1: a teljes valuta-sor lista JSON-ként, valutakóddal dúsítva (az
          // Electron-úton is megmarad; az offline lista ebből jeleníti meg a kódokat).
          lines: enrichedLines ? JSON.stringify(enrichedLines) : null,
        })

        const label = transferDirection === 'out' ? 'Átadás' : 'Átvétel'
        setSuccess(
          outcome.allSavedSynced
            ? `${label} helyileg rögzítve és azonnal szinkronizálva`
            : `${label} helyileg rögzítve. A feltöltés az Electron queue-ból folytatódik.`,
        )
        // FR-6: offline esetben is nyomtatható a szállítólevél a lokális adatokból.
        // NFR-1 (offline fejléc): az értéktár címe/telefonszáma a lokális cached_cash_desks
        // mirrorból (a sync-engine tartja frissen) — internet nélkül is helyes fejléc.
        let offlineVaultAddress: string | undefined
        let offlineVaultPhone: string | undefined
        try {
          const cachedDesks = await window.electronAPI?.getCachedCashDesks?.()
          const ownDesk = cachedDesks?.find(d => d.id === worker?.branchId)
          if (ownDesk) {
            // A backend formatBranchAddress() formátumával egyezően: "Város, Cím, IRSZ".
            const parts = [ownDesk.city, ownDesk.address, ownDesk.zip_code]
              .map(p => (p ?? '').trim())
              .filter(p => p !== '')
            offlineVaultAddress = parts.length > 0 ? parts.join(', ') : undefined
            offlineVaultPhone = ownDesk.phone?.trim() || undefined
          }
        } catch { /* cache-hiány nem blokkolja a bizonylatot — fallback a cég-székhely cím */ }
        const now = new Date()
        setPrintReceiptData({
          type: 'transfer',
          companyType: getCompanyType(worker),
          // A bizonylatszám a TÉNYLEGES, rögzített átadólap-sorszám (local_reference_number, pl.
          // AT105000042) — ezt szinkronizáljuk a backendre is, így a kinyomtatott szállítólevél
          // EGYEZIK a rögzített átadással. Ha hiányzik (régi telepítő / null), fallback a queue-sor
          // ID-jére, végső soron a fabrikált időbélyegre.
          receiptNumber: outcome.localReferenceNumbers?.[0]
            ?? (outcome.savedIds[0] != null
              ? `LOCAL-${localIsoDate()}-#${outcome.savedIds[0]}`
              : `LOCAL-${localIsoDate()}-${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}${String(now.getSeconds()).padStart(2, '0')}`),
          // FR-3/4: átadásnál Kérő=értéktár (vaultLabel), Cél=másik; átvételnél fordítva.
          branchCode: transferDirection === 'in' ? `${branch.code} - ${branch.name}` : vaultLabel,
          cashierName: worker?.fullName ?? '',
          date: localIsoDate(),
          time: now.toTimeString().slice(0, 8),
          currencyCode: currency.code,
          foreignAmount: effAmountValue,
          transferTarget: transferDirection === 'in' ? vaultLabel : `${branch.code} - ${branch.name}`,
          transferNote: notes || undefined,
          carrierName: carrierName.trim(),
          sealNumber: sealNumber.trim(),
          vaultAddress: offlineVaultAddress, // FR-1 (offline: cached_cash_desks mirrorból)
          vaultPhone: offlineVaultPhone, // FR-2 (offline)
          transferDocType, // FR-2
          denominations: receiptDenominations, // FR-17..19 (offline: lokális adatokból)
          transferLines: receiptTransferLines, // A.1: több-valutás sorok a bizonylaton
        })
      } else {
        const result = await transferApi.create(request)
        setSuccess(`${transferDirection === 'out' ? 'Átadás' : 'Átvétel'} létrehozva: ${result.transferNumber}`)
        // FR-6: nyomtatható szállítólevél a szerver-válaszból (Szállító + Plombaszám is rajta).
        {
          const otherLabel = `${result.toBranchCode} - ${result.toBranchName}`
          setPrintReceiptData({
            type: 'transfer',
            companyType: getCompanyType(worker),
            receiptNumber: result.transferNumber,
            // FR-3/4: átadásnál Kérő=értéktár, Cél=másik iroda; átvételnél fordítva.
            branchCode: transferDirection === 'in' ? otherLabel : vaultLabel,
            transferTarget: transferDirection === 'in' ? vaultLabel : otherLabel,
            cashierName: worker?.fullName ?? result.fromWorkerName ?? '',
            date: result.transferDate,
            time: result.transferTime,
            currencyCode: result.currencyCode,
            foreignAmount: result.amount,
            roundedHufAmount: result.hufValue, // FR-6: HUF forintosított érték
            transferNote: result.notes,
            carrierName: result.carrierName,
            sealNumber: result.sealNumber,
            vaultAddress: result.vaultAddress, // FR-1
            vaultPhone: result.vaultPhone, // FR-2 (fejléc-javítás): branch.phone a szerver-válaszból
            transferDocType, // FR-2
            denominations: result.denominations ?? receiptDenominations, // FR-17..19
            // A.1: a szerver-válasz sorai (currencyCode-dal), fallback a kérés soraira.
            transferLines: result.lines && result.lines.length > 1
              ? result.lines.map(l => ({ currencyCode: l.currencyCode ?? `#${l.currencyId}`, amount: l.amount }))
              : receiptTransferLines,
          })
        }
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
      setShowDenominations(false)
      setDenominationLines([{ id: denomIdRef.current++, quantity: '', faceValue: '' }])

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

  const closeStornoModal = () => {
    stornoPreviewRequestRef.current += 1
    setShowStornoModal(false)
    setStornoTarget(null)
  }

  // Copilot PR #1101: régi/offline pending soroknál a lines currencyCode-ja hiányozhat —
  // a currencyId alapján a betöltött valuta-törzsből oldjuk fel (végső fallback: #id).
  const resolveLineCode = useCallback(
    (line: { currencyId: number; currencyCode?: string }): string =>
      line.currencyCode ?? currencies.find(c => c.id === line.currencyId)?.code ?? `#${line.currencyId}`,
    [currencies],
  )

  // Penztar-batch A.2 (2026-06-12): a lista szem-ikonja a BIZONYLATOT hívja elő.
  // (Korábban a /transfers/:id route-ra navigált, ami ugyanerre a lista-komponensre volt
  // kötve — látható hatás nélkül.) A bizonylat a lista-sor TELJES Transfer objektumából
  // épül (a lista-DTO minden mezőt hordoz, offline pending soroknál is) — nincs extra
  // API-hívás. A Kérő/Cél a kanonikus fromBranch/toBranch mezőkből jön (NEM a bejelentkezett
  // fiók vaultLabel-jéből — visszanézéskor a kiállító eltérhet a nézegetőtől).
  const openDocumentPreview = (transfer: Transfer) => {
    const fromLabel = `${transfer.fromBranchCode} - ${transfer.fromBranchName}`
    const toLabel = `${transfer.toBranchCode} - ${transfer.toBranchName}`
    const isReceiptDoc = transfer.direction === 'U'
    setPrintReceiptData({
      type: 'transfer',
      companyType: getCompanyType(worker),
      // Sztornózott bizonylatnál a sztornó-sorszám + jelölés (a sztornó-ág mintája szerint).
      receiptNumber: transfer.isCancelled
        ? (transfer.stornoSerialNumber ?? `${transfer.transferNumber}-SZ`)
        : transfer.transferNumber,
      branchCode: isReceiptDoc ? toLabel : fromLabel,
      transferTarget: isReceiptDoc ? fromLabel : toLabel,
      transferDocType: isReceiptDoc ? 'receipt' : 'handover',
      cashierName: transfer.fromWorkerName ?? '',
      date: transfer.transferDate,
      time: transfer.transferTime,
      currencyCode: transfer.currencyCode,
      foreignAmount: transfer.amount,
      roundedHufAmount: transfer.hufValue,
      transferNote: transfer.notes,
      carrierName: transfer.carrierName,
      sealNumber: transfer.sealNumber,
      vaultAddress: transfer.vaultAddress,
      vaultPhone: transfer.vaultPhone,
      isStorno: transfer.isCancelled === true,
      stornoReason: transfer.cancellationReason,
      denominations: transfer.denominations,
      // A.1: több-valutás átadólapon minden sor a bizonylatra kerül.
      transferLines: transfer.lines && transfer.lines.length > 1
        ? transfer.lines.map(l => ({ currencyCode: resolveLineCode(l), amount: l.amount }))
        : undefined,
    })
    setShowReceiptModal(true)
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
    if (!reason) { setError('A sztornó indoklása kötelező!'); return }
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
            setSuccess(`Sztornó helyben rögzítve (offline): ${target.transferNumber}-SZ. A szinkronizálás az internet visszatértekor folytatódik.`)
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
              isStorno: true,
              stornoReason: reason,
            })
            setShowReceiptModal(true)
            return
          }
        } catch { /* ha a queue-olás is bukik, az általános hiba jelzés következik */ }
      }
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
              <tr key={transfer.id} className={transfer.isCancelled ? 'opacity-60' : ''}>
                <td className="font-mono font-semibold">
                  <span className={transfer.isCancelled ? 'line-through' : ''}>{transfer.transferNumber}</span>
                  {/* FR-14: sztornózott bizonylat jelölése a listában */}
                  {transfer.isCancelled && (
                    <span className="ml-1 inline-block rounded bg-red-100 text-red-700 text-[10px] font-semibold px-1.5 py-0.5 align-middle">
                      Sztornózva
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
                <td>{transfer.transferTypeDisplay ?? localizeTransferType(transfer.transferType)}</td>
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
                        onClick={() => openDocumentPreview(transfer)}
                        className="toolbar-button"
                        title="Bizonylat megtekintése"
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
                      {/* FR-12: sztornó (indoklással) — CSAK véglegesített (COMPLETED), még nem sztornózott
                          bizonylaton. A PENDING-et a „Törlés" (/cancel) kezeli; a még nem szinkronizált
                          lokális sorok PENDING-ek, így itt nem jelennek meg (nincs backend-id). */}
                      {transfer.isCompleted && !transfer.isCancelled && (
                        <button
                          type="button"
                          onClick={() => { void openStornoModal(transfer) }}
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

              {/* FR-17/18: opcionális címletezés (darab × névleges érték). Ha megadják, az összegnek
                  egyeznie kell az átadás összegével. */}
              <div className="border-t pt-3">
                <label className="flex items-center gap-2 text-sm font-medium cursor-pointer">
                  <input
                    type="checkbox"
                    checked={showDenominations}
                    onChange={(e) => setShowDenominations(e.target.checked)}
                  />
                  Címletezés megadása (opcionális)
                </label>
                {showDenominations && (
                  <div className="mt-2 space-y-2">
                    {/* A.3: jelzés, hogy a címlet-törzs előtöltötte a névértékeket. */}
                    {denomPresetCode && (
                      <p className="text-xs text-blue-700">
                        A(z) {denomPresetCode} címletei betöltve — csak a darabszámot adja meg
                        (a sorok szabadon szerkeszthetők, az üresen hagyott címlet kimarad).
                      </p>
                    )}
                    {denominationLines.map((line, idx) => {
                      const q = parseInt(line.quantity, 10)
                      const fv = parseFloat(line.faceValue.replace(',', '.').replace(/\s/g, ''))
                      const lineTotal = (Number.isFinite(q) && Number.isFinite(fv)) ? q * fv : 0
                      return (
                        <div key={line.id} className="grid grid-cols-[1fr_1fr_1fr_auto] gap-2 items-end">
                          <div>
                            {idx === 0 && <label className="form-label text-xs">Darab</label>}
                            <NumberInput
                              value={line.quantity}
                              onChange={(v) => setDenominationLines(prev => prev.map((r, i) => i === idx ? { ...r, quantity: v } : r))}
                              className="form-input w-full"
                              placeholder="db"
                              allowDecimals={false}
                              allowNegative={false}
                            />
                          </div>
                          <div>
                            {idx === 0 && <label className="form-label text-xs">Névleges érték</label>}
                            <NumberInput
                              value={line.faceValue}
                              onChange={(v) => setDenominationLines(prev => prev.map((r, i) => i === idx ? { ...r, faceValue: v } : r))}
                              className="form-input w-full"
                              placeholder="0"
                              allowDecimals={true}
                              allowNegative={false}
                            />
                          </div>
                          <div>
                            {idx === 0 && <label className="form-label text-xs">Összesen</label>}
                            <div className="form-input w-full bg-gray-50 text-right font-mono">
                              {lineTotal ? lineTotal.toLocaleString('hu-HU') : '—'}
                            </div>
                          </div>
                          <button
                            type="button"
                            onClick={() => setDenominationLines(prev => prev.length > 1 ? prev.filter((_, i) => i !== idx) : prev)}
                            className="toolbar-button text-red-600 mb-1"
                            title="Sor törlése"
                            disabled={denominationLines.length <= 1}
                          >
                            <XCircle size={16} />
                          </button>
                        </div>
                      )
                    })}
                    <button
                      type="button"
                      onClick={() => setDenominationLines(prev => [...prev, { id: denomIdRef.current++, quantity: '', faceValue: '' }])}
                      className="text-sm text-blue-600 hover:underline"
                    >
                      + Sor hozzáadása
                    </button>
                  </div>
                )}
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

      {/* FR-12..16: sztornó modal — kötelező indoklással */}
      {showStornoModal && stornoTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md p-6">
            <h3 className="text-lg font-bold mb-2 flex items-center gap-2">
              <Ban size={18} className="text-orange-600" /> Bizonylat sztornózása
            </h3>
            <p className="text-sm text-gray-600 mb-3">
              {stornoTarget.transferNumber} — a sztornó bizonylat sorszáma:{' '}
              <span className="font-mono font-semibold">{stornoTarget.stornoSerialNumber ?? `${stornoTarget.transferNumber}-SZ`}</span>
            </p>
            <label htmlFor="storno-reason" className="form-label">Sztornó indoklása <span className="text-red-500">*</span></label>
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
              <button
                type="button"
                onClick={closeStornoModal}
                className="form-button"
              >
                {t('common.cancel')}
              </button>
              <button
                type="button"
                onClick={() => void handleStornoConfirm()}
                disabled={loading || !stornoReason.trim()}
                className="form-button-primary bg-orange-600 hover:bg-orange-700 disabled:opacity-50"
              >
                Sztornó rögzítése
              </button>
            </div>
          </div>
        </div>
      )}

      {/* FR-5/FR-6: szállítólevél előnézet + nyomtatás (Szállító + Plombaszám is rajta). */}
      <ReceiptPreviewModal
        isOpen={showReceiptModal}
        onClose={() => setShowReceiptModal(false)}
        receiptData={printReceiptData}
        qrCodeDataUrl={null}
        allowPrint={isElectron()}
        onPrint={async () => {
          // Copilot PR #1100 (storno-minta): a hibás ágak THROW-val zárulnak — a
          // ReceiptPreviewModal csak SIKERES onPrint után zár be (2s auto-close),
          // hiba esetén nyitva marad és újrapróbálható.
          if (!printReceiptData) throw new Error('Nincs aktív bizonylat-adat')
          if (!window.electronAPI?.printReceipt) {
            toast.warning('Nyomtatás nem elérhető', isElectron()
              ? 'Electron preload/electronAPI hiba — indítsa újra a klienst.'
              : 'Webes módban nincs nyomtatás. Telepítse az Electron klienst.')
            throw new Error('printReceipt nem elérhető')
          }
          try {
            const ok = await window.electronAPI.printReceipt(JSON.stringify(printReceiptData))
            if (!ok) {
              toast.error('Nyomtatás sikertelen', 'Ellenőrizze a nyomtatót (Beállítások > Nyomtatás).')
              throw new Error('Nyomtatás sikertelen')
            }
            toast.success('Nyomtatás elindítva', `Bizonylat: ${printReceiptData.receiptNumber ?? '—'}`)
          } catch (err) {
            if (!(err instanceof Error && err.message === 'Nyomtatás sikertelen')) {
              toast.error('Nyomtatás sikertelen', 'A nyomtatási parancs nem futott le.')
            }
            throw err
          }
        }}
      />
    </div>
  )
}
