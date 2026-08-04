import { useCallback, useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  AlertCircle,
  ArrowRightLeft,
  Building2,
  CheckCircle,
  Download,
  Printer,
  RefreshCw,
  Send,
  XCircle,
} from 'lucide-react'
import {
  branchApi,
  cashBalanceApi,
  CreateTransferRequest,
  currencyApi,
  Currency,
  denominationApi,
  exchangeRateApi,
  transferApi,
} from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { NumberInput } from '../../components/NumberInput'
import { getErrorMessage } from '../../utils/errorHandling'
import { isAllowedFaceValue } from '../../utils/denominationRules'
import {
  getElectronCachedRates,
  isElectronQueueAvailable,
  saveAndSyncPendingTransfer,
} from '../../utils/electronTransactions'
import { getCompanyType } from '../../utils/localQueue'
import { useTranslation } from 'react-i18next'
import SupervisorPinModal from '../../components/auth/SupervisorPinModal'
import { isElectron } from '../../utils/electron'
import type { PrintReceiptData } from '../../types/receipt'
import { localIsoDate } from '../../utils/dateFormat'
import { roundHuf } from '../../utils/rounding'
import {
  buildDenominationPayload,
  buildTransferLines,
  filterCurrenciesForType,
  filterTransferTargetBranches,
  getAllowedTransferTypeValues,
  getAvailableTransferTypes,
  isCurrencyOnlyTransferType,
  isHufOnlyTransferType,
  isMainCashierBranch,
  isTHBranch,
  validateCarrierSeal,
  type CurrencyLineInput,
} from './transferRules'
import TransferReceiptModal from './TransferReceiptModal'
import { buildVaultLabel, loadOwnVaultContact } from './transferPageShared'

export default function TransferCreatePage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const electronQueueAvailable = isElectronQueueAvailable()

  // Form state for new transfer
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

  // New transfer form
  const [transferDirection, setTransferDirection] = useState<'out' | 'in'>('out')
  const [toBranchId, setToBranchId] = useState('')
  const [currencyId, setCurrencyId] = useState<number | null>(null)
  const [amount, setAmount] = useState('')
  // #6: több-valutás átadólap sorai (CSAK valuta-típusnál aktív). Az első sor a header.
  const lineIdRef = useRef(1)
  const [currencyLines, setCurrencyLines] = useState<CurrencyLineInput[]>([
    { id: 0, currencyId: null, amount: '' },
  ])
  const [transferType, setTransferType] =
    useState<CreateTransferRequest['transferType']>('CURRENCY')
  const [notes, setNotes] = useState('')
  const [carrierName, setCarrierName] = useState('')
  const [sealNumber, setSealNumber] = useState('')
  // FR-17/18: opcionális címletezés (darab × névleges érték). Üres → nem küldjük, a bizonylaton nem jelenik meg.
  const [showDenominations, setShowDenominations] = useState(false)
  const denomIdRef = useRef(1)
  const [denominationLines, setDenominationLines] = useState<
    Array<{ id: number; quantity: string; faceValue: string }>
  >([{ id: 0, quantity: '', faceValue: '' }])
  // Penztar-batch A.3 (2026-06-12, user-kérés): a kiválasztott valuta TÉNYLEGES címleteit
  // ajánljuk fel (denomination törzs, GET /denominations/currency/{id} — a Címletezés
  // menüvel azonos forrás), hogy ne kézzel kelljen a névleges értéket beírni (elgépelés-
  // védelem). A sorok szabadon szerkeszthetők maradnak; törzs-hiány / offline → szabad bevitel.
  const [denomPresetCode, setDenomPresetCode] = useState<string | null>(null)
  const denomPresetCurrencyRef = useRef<number | null>(null)

  // Supervisor PIN for TH transfers
  const [showSupervisorPin, setShowSupervisorPin] = useState(false)
  const [pendingTransferAfterPin, setPendingTransferAfterPin] = useState(false)

  // FKH-028 Fázis 1: szinkron re-entry guard a dupla-beküldés ellen (a loading state
  // frissítése aszinkron, két azonos tickben érkező kattintást önmagában nem fogna meg).
  const submittingRef = useRef(false)

  // Loading & Error
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  // FR-6: sikeres rögzítés után nyomtatható bizonylat (Szállító + Plombaszám a szállítólevélen)
  const [printReceiptData, setPrintReceiptData] = useState<PrintReceiptData | null>(null)
  const [showReceiptModal, setShowReceiptModal] = useState(false)

  // A létrehozó oldalnak csak a valuta- és irodatörzs szükséges.
  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      const [currencyData, branchData] = await Promise.all([
        currencyApi.getActive(),
        branchApi.listActive(),
      ])
      setCurrencies(currencyData)

      // FK-005/C1 HALASZTVA (Codex P1 #844): a region-scope elejtené a TH (többlet/hiány) és
      // az 1.sz Főpénztár cél-fiókokat, amiket az átadás-átvétel üzleti szabály (supervisor-PIN)
      // igényel. A banki/vault-átadás "csak Bankok + Területek" finomszűrése külön körben, a
      // speciális (TH / Főpénztár / vault) célok megőrzésével. Itt egyelőre az összes aktív.
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
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  // Belső ellenőri (supervisor) PIN kell, ha a cél TH (többlet/hiány könyvelés) VAGY az
  // 1.sz Főpénztár (hó végi visszapótlás) — Kósa Zoltán 2026-05-20 üzleti szabály.
  const targetBranch = branches.find((b) => b.id === toBranchId)
  const isTargetTH = targetBranch ? isTHBranch(targetBranch) : false
  const isTargetMainCashier = targetBranch ? isMainCashierBranch(targetBranch) : false
  const requiresSupervisorPin = isTargetTH || isTargetMainCashier

  // === Átadás-átvétel üzleti szabályok (Kósa Zoltán tesztelői kérés) ===
  // A bejelentkezett felhasználó saját fiókja — ez dönti el, hogy pénztár vagy értéktár.
  const ownBranch = branches.find((b) => b.id === worker?.branchId)
  const isVaultUser = ownBranch?.isVault === true

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

  // (Req #2/#3) Iránytól + felhasználó-típustól függő választható átadás-típusok.
  const availableTransferTypes = getAvailableTransferTypes(isVaultUser, transferDirection)
  // Irányváltás-guard: a PRB csak átvétel ('in') irányban választható — ha a user PRB-vel
  // vált át 'out'-ra, a típus visszaesik az alapértelmezett CURRENCY-re (ne maradjon a
  // select-ben a listából hiányzó, backend által is elutasított érték). Teljes dep-lista,
  // önjavító (a CURRENCY minden irány/szerep mellett elérhető → nincs loop).
  useEffect(() => {
    if (
      !getAvailableTransferTypes(isVaultUser, transferDirection).some(
        (o) => o.value === transferType,
      )
    ) {
      setTransferType('CURRENCY')
    }
  }, [transferDirection, isVaultUser, transferType])
  // (Req #4/#5) Valuta-szűrés a típus szerint.
  const isHufOnlyType = isHufOnlyTransferType(transferType)
  const filteredCurrencies = filterCurrenciesForType(currencies, transferType)
  // (#6) Több-valutás átadólap CSAK valuta-típusnál. Egyéb típus → egy-soros (HUF/egy valuta).
  const isMultiCurrency = transferType === 'CURRENCY'

  // #6 sor-kezelők
  const updateCurrencyLine = useCallback(
    (idx: number, field: 'currencyId' | 'amount', value: string) => {
      setCurrencyLines((prev) =>
        prev.map((row, i) =>
          i === idx
            ? { ...row, [field]: field === 'currencyId' ? (value ? Number(value) : null) : value }
            : row,
        ),
      )
    },
    [],
  )
  const addCurrencyLine = useCallback(() => {
    setCurrencyLines((prev) => [...prev, { id: lineIdRef.current++, currencyId: null, amount: '' }])
  }, [])
  const removeCurrencyLine = useCallback((idx: number) => {
    setCurrencyLines((prev) => (prev.length <= 1 ? prev : prev.filter((_, i) => i !== idx)))
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
      const huf = currencies.find((c) => c.code === 'HUF')
      if (huf && currencyId !== huf.id) setCurrencyId(huf.id)
    } else if (isCurrencyOnlyTransferType(transferType)) {
      // CURRENCY mellett az ERB/TRB (csak-deviza technikai RB-kötések) is: a beragadt
      // HUF currencyId-t töröljük, különben üresnek látszó select + backend 400.
      const selected = currencies.find((c) => c.id === currencyId)
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
      ? (currencyLines.find((l) => l.currencyId != null)?.currencyId ?? null)
      : currencyId
    if (denomCurrencyId == null || denomPresetCurrencyRef.current === denomCurrencyId) return
    // Verif PR #1101 P2: a ref a fetch INDÍTÁSAKOR áll be (nem a válasznál) — így a
    // gépelés közbeni cleanup (currencyLines minden billentyűre új referencia) nem okoz
    // billentyűnkénti újra-lekérést; checkbox ki/be vagy valutaváltás újraenged.
    denomPresetCurrencyRef.current = denomCurrencyId
    let cancelled = false
    void (async () => {
      try {
        const denoms = await denominationApi.getByCurrencyId(denomCurrencyId)
        if (cancelled) return
        // Verif PR #1101 P2: a felhasználó által már elkezdett kitöltést (darabszám) a
        // később beérkező preset NEM írhatja felül — funkcionális update-ben ellenőrizzük.
        const applyIfPristine = (
          next: Array<{ id: number; quantity: string; faceValue: string }>,
        ) =>
          setDenominationLines((prev) => (prev.some((r) => r.quantity.trim() !== '') ? prev : next))
        // FK-072: a törzs tört (1 alatti) sora nem tölthet elő sort — az új validáció
        // úgyis elutasítaná, a felhasználó pedig nem értené, honnan jött.
        const allowedDenoms = denoms.filter((d) => isAllowedFaceValue(d.faceValue))
        if (allowedDenoms.length === 0) {
          // Codex PR #1101 P2: valutaváltáskor az ELŐZŐ valuta stale presetje nem
          // maradhat — üres (vagy csupa tört sorú) törzsnél vissza a szabad bevitelre.
          setDenomPresetCode(null)
          applyIfPristine([{ id: denomIdRef.current++, quantity: '', faceValue: '' }])
          return
        }
        const code = currencies.find((c) => c.id === denomCurrencyId)?.code ?? null
        setDenomPresetCode(code)
        // Címletenként egy sor, csökkenő névértékkel (a DenominationPage rendezése) —
        // a felhasználó csak a darabszámot tölti ki; a sorok szerkeszthetők maradnak.
        applyIfPristine(
          [...allowedDenoms]
            .sort((a, b) => b.faceValue - a.faceValue)
            .map((d) => ({
              id: denomIdRef.current++,
              quantity: '',
              faceValue: String(d.faceValue),
            })),
        )
      } catch {
        // Törzs nem elérhető (pl. offline) → szabad bevitel marad, jelzés nélkül.
      }
    })()
    return () => {
      cancelled = true
    }
  }, [showDenominations, isMultiCurrency, currencyId, currencyLines, currencies])

  // Create new transfer
  const handleCreateTransfer = async (pinVerified = false) => {
    // FKH-028 Fázis 1: dupla-beküldés védelem. A letiltás a függvény LEGELEJÉN aktiválódik
    // (a készlet-ellenőrző és árfolyam-feloldó await-ek előtt), a ref pedig az azonos
    // render-cikluson belüli második kattintást is fogja (a state-frissítés aszinkron).
    if (submittingRef.current) return
    submittingRef.current = true
    setLoading(true)
    // Korai (validációs) kilépéskor a letiltást vissza kell engedni — különben a gomb
    // beragadna; a sikeres/hibás beküldés végén az alsó finally teszi ugyanezt.
    const abortSubmit = () => {
      submittingRef.current = false
      setLoading(false)
    }
    if (!toBranchId) {
      setError('Válasszon cél irodát!')
      abortSubmit()
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
        abortSubmit()
        return
      }
      effLines = built.lines
      effCurrencyId = built.lines[0]!.currencyId
      effAmountValue = built.lines[0]!.amount
    } else {
      if (!currencyId || !amount) {
        setError('Minden mező kitöltése kötelező!')
        abortSubmit()
        return
      }
      effAmountValue = parseFloat(amount.replace(',', '.').replace(/\s/g, ''))
      if (!Number.isFinite(effAmountValue) || effAmountValue <= 0) {
        setError('Adjon meg pozitív összeget!')
        abortSubmit()
        return
      }
    }

    // (Req #7 / FR-1..3, NFR-1,2) Szállító és plombaszám KÖTELEZŐ + hossz/formátum — közös validátor
    // (a MovementManagerrel és a backend Bean Validationnel egyező egyetlen forrás).
    const carrierSealError = validateCarrierSeal(carrierName, sealNumber)
    if (carrierSealError) {
      setError(carrierSealError)
      abortSubmit()
      return
    }

    // FR-17..20b: opcionális címletezés feldolgozása + összeg-egyezés (pure helper, tesztelt).
    const denomResult = buildDenominationPayload(
      showDenominations,
      denominationLines,
      effAmountValue,
    )
    if (denomResult.error) {
      setError(denomResult.error)
      abortSubmit()
      return
    }
    const effDenominations = denomResult.denominations

    if (requiresSupervisorPin && !pinVerified && !pendingTransferAfterPin) {
      setShowSupervisorPin(true)
      // A PIN-modal alatt a gomb nem maradhat letiltva — a PIN után új hívás jön (pinVerified=true).
      abortSubmit()
      return
    }
    setPendingTransferAfterPin(false)

    // Készlet-ellenőrzés SORONKÉNT (csak kimenő átadásnál, nem VAULT_DEPOSIT-nál).
    if (transferDirection === 'out' && transferType !== 'VAULT_DEPOSIT') {
      try {
        const balances = await cashBalanceApi.list()
        const linesToCheck = effLines ?? [{ currencyId: effCurrencyId!, amount: effAmountValue }]
        for (const ln of linesToCheck) {
          const cur = currencies.find((c) => c.id === ln.currencyId)
          if (!cur) continue
          const bal = balances.find((b: { currencyCode: string }) => b.currencyCode === cur.code)
          const available = bal?.currentBalance ?? 0
          if (ln.amount > available) {
            setError(
              `Nincs ennyi készlet! ${cur.code}: elérhető ${available.toLocaleString('hu-HU')}, kért ${ln.amount.toLocaleString('hu-HU')}`,
            )
            abortSubmit()
            return
          }
        }
      } catch {
        setError('Készlet-ellenőrzés sikertelen. Próbálja újra!')
        abortSubmit()
        return
      }
    }

    try {
      setError(null)

      // A.1: a sorok valutakóddal dúsítva — az offline lista + bizonylat internet nélkül
      // is meg tudja jeleníteni a kódokat (a backend TransferLineDto fogadja a mezőt).
      const enrichedLines = effLines?.map((l) => ({
        ...l,
        currencyCode: currencies.find((c) => c.id === l.currencyId)?.code,
      }))
      // A.1: a bizonylaton minden valuta-sor megjelenik (egysorosnál a fejléc-mezők maradnak).
      const receiptTransferLines =
        enrichedLines && enrichedLines.length > 1
          ? enrichedLines.map((l) => ({
              currencyCode: l.currencyCode ?? `#${l.currencyId}`,
              amount: l.amount,
            }))
          : undefined

      // Batch2-E + FK05 FR-5: deviza-átadólapon a forintosított érték + árfolyam a bizonylatra.
      // Egyvalutás deviza-sornál az aktuális publikált ELSZÁMOLÓ árfolyammal számolunk;
      // több-valutás lapnál (soronként eltérő valuták) a fejléc-szintű forintosítás
      // nem értelmezhető — ott kimarad (dokumentált korlát).
      const effCurrencyCode = currencies.find((c) => c.id === effCurrencyId)?.code
      const transferRate =
        effCurrencyCode && (!effLines || effLines.length <= 1)
          ? await resolveTransferRate(effCurrencyCode)
          : null
      // Codex P1 #1111: a forintosított érték 5 Ft-os MAGYAR kerekítéssel (roundHuf) —
      // a bizonylat roundedHufAmount mezője és az app HUF-invariánsa is ezt várja.
      const transferHufValue = transferRate != null ? roundHuf(effAmountValue * transferRate) : null

      const request: CreateTransferRequest = {
        toBranchId,
        currencyId: effCurrencyId!,
        amount: effAmountValue,
        hufValue: transferHufValue ?? undefined,
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
      const transferDocType: 'handover' | 'receipt' =
        transferDirection === 'in' ? 'receipt' : 'handover'
      // FR-17..19: a bizonylaton megjelenő címletezési sorok (lineTotal a frontend számolja az előnézethez).
      const receiptDenominations = effDenominations?.map((d) => ({
        quantity: d.quantity,
        faceValue: d.faceValue,
        currencyCode: currencies.find((c) => c.id === effCurrencyId)?.code,
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
          hufValue: transferHufValue, // Batch2-E: deviza forintosított érték (sync küldi a backendre)
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
        const { address: offlineVaultAddress, phone: offlineVaultPhone } =
          await loadOwnVaultContact(worker?.branchId)
        const now = new Date()
        setPrintReceiptData({
          type: 'transfer',
          companyType: getCompanyType(worker),
          // A bizonylatszám a TÉNYLEGES, rögzített átadólap-sorszám (local_reference_number, pl.
          // AT105000042) — ezt szinkronizáljuk a backendre is, így a kinyomtatott szállítólevél
          // EGYEZIK a rögzített átadással. Ha hiányzik (régi telepítő / null), fallback a queue-sor
          // ID-jére, végső soron a fabrikált időbélyegre.
          receiptNumber:
            outcome.localReferenceNumbers?.[0] ??
            (outcome.savedIds[0] != null
              ? `LOCAL-${localIsoDate()}-#${outcome.savedIds[0]}`
              : `LOCAL-${localIsoDate()}-${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}${String(now.getSeconds()).padStart(2, '0')}`),
          // FR-3/4: átadásnál Kérő=értéktár (vaultLabel), Cél=másik; átvételnél fordítva.
          branchCode: transferDirection === 'in' ? `${branch.code} - ${branch.name}` : vaultLabel,
          cashierName: worker?.fullName ?? '',
          date: localIsoDate(),
          time: now.toTimeString().slice(0, 8),
          currencyCode: currency.code,
          foreignAmount: effAmountValue,
          // Batch2-E: árfolyam + forintosított érték a deviza-bizonylaton (ha feloldható).
          rate: transferRate ?? undefined,
          roundedHufAmount: transferHufValue ?? undefined,
          transferTarget:
            transferDirection === 'in' ? vaultLabel : `${branch.code} - ${branch.name}`,
          transferNote: notes || undefined,
          carrierName: carrierName.trim(),
          sealNumber: sealNumber.trim(),
          vaultAddress: offlineVaultAddress, // FR-1 (offline: cached_cash_desks mirrorból)
          vaultPhone: offlineVaultPhone, // FR-2 (offline)
          vaultBranchLabel: vaultLabel, // Batch2-E: kiállító értéktár kód+név a fejlécben
          transferDocType, // FR-2
          denominations: receiptDenominations, // FR-17..19 (offline: lokális adatokból)
          transferLines: receiptTransferLines, // A.1: több-valutás sorok a bizonylaton
        })
      } else {
        const result = await transferApi.create(request)
        setSuccess(
          `${transferDirection === 'out' ? 'Átadás' : 'Átvétel'} létrehozva: ${result.transferNumber}`,
        )
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
            rate: transferRate ?? undefined, // Batch2-E: árfolyam a deviza-bizonylaton
            transferNote: result.notes,
            carrierName: result.carrierName,
            sealNumber: result.sealNumber,
            vaultAddress: result.vaultAddress, // FR-1
            vaultPhone: result.vaultPhone, // FR-2 (fejléc-javítás): branch.phone a szerver-válaszból
            vaultBranchLabel: vaultLabel, // Batch2-E: kiállító értéktár kód+név a fejlécben
            transferDocType, // FR-2
            denominations: result.denominations ?? receiptDenominations, // FR-17..19
            // A.1: a szerver-válasz sorai (currencyCode-dal), fallback a kérés soraira.
            transferLines:
              result.lines && result.lines.length > 1
                ? result.lines.map((l) => ({
                    currencyCode: l.currencyCode ?? `#${l.currencyId}`,
                    amount: l.amount,
                  }))
                : receiptTransferLines,
          })
        }
      }

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
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      submittingRef.current = false
      setLoading(false)
    }
  }

  // FK05 FR-5 (2026-06-12): árfolyam-feloldás a deviza-átadólap forintosított értékéhez —
  // az ELSZÁMOLÓ árfolyammal (J oszlop, officialRate), a vételi helyett. A pénztár↔értéktár
  // átadás/átvétel a legacy-ban is az ELSZAMOLASIARFOLYAM-on számolt forintértéket
  // (atadvet/unit2.pas 825/1147/1706). Régi adatnál (officialRate null/0) fallback a
  // vételire; árfolyam-hiány NEM blokkolja a rögzítést — ilyenkor a bizonylat
  // árfolyam/forint sor nélkül készül (a korábbi viselkedés).
  const resolveTransferRate = useCallback(async (currencyCode: string): Promise<number | null> => {
    if (currencyCode === 'HUF') return null
    try {
      if (isElectron()) {
        const cached = await getElectronCachedRates()
        const row = cached.find((r) => r.currency_code === currencyCode)
        if (row?.official_rate != null && row.official_rate > 0) return row.official_rate
        if (row && row.buy_rate > 0) return row.buy_rate
      }
      const rates = await exchangeRateApi.list()
      const row = rates.find((r) => r.currencyCode === currencyCode)
      if (row?.officialRate != null && row.officialRate > 0) return row.officialRate
      if (row && row.baseBuyRate > 0) return row.baseBuyRate
    } catch {
      /* árfolyam-cache/API hiánya nem blokkolja a rögzítést */
    }
    return null
  }, [])

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <ArrowRightLeft />
          {t('transfers.ujAtadasAtvetelRogzitese')}
        </h1>
        <Link to="/transfers" className="form-button">
          {t('transfers.visszaAVisszaigazolashoz')}
        </Link>
      </div>

      {/* 2026-04-29 v2.3.12 (E-B8): info-banner — banki workflow vs pénztári átadás-átvétel */}
      <div className="bg-blue-50 border border-blue-200 rounded p-3 text-sm text-blue-800 flex items-start gap-2">
        <Building2 size={16} className="flex-shrink-0 mt-0.5" />
        <div>
          <strong>{t('transfers.bankiKiBeszallitasEsErtektarErtektarKozottiMozgas')}</strong>
          {t('transfers.aPenztarakFele')}
          {t('transfers.szervezettAtadasAtvetelhezHasznaljaAz')}
          <Link to="/shipments" className="underline font-semibold">
            {t('transfers.atadasAtvetelPenztaraknak')}
          </Link>
          {t('transfers.menupontot')}
          {t(
            'transfers.aTeljesBankiWorkflowBankiRendelesWesternUnionNapiKereteSurgossegiKivetSkeletonJeMegnezhetoA',
          )}
          <Link to="/bank-orders" className="underline font-semibold">
            {t('transfers.bankiRendelesek')}
          </Link>
          {t('transfers.menupontbanTeljesImplementacioV240')}
        </div>
      </div>

      {/* Error/Success messages */}
      {error && (
        <div className="form-panel bg-red-50 border-red-200 flex items-center gap-2 text-red-700">
          <AlertCircle size={18} />
          <span>{error}</span>
          <button type="button" onClick={() => setError(null)} className="ml-auto text-red-500">
            ×
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
              <Printer size={14} /> Nyomtatás
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
            ×
          </button>
        </div>
      )}

      <div className="form-panel max-w-md p-4">
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

          {/* Batch2-E (Fabulya-teszt 2026-06-12): a saját oldal auto-kitöltött, READ-ONLY
              mezőként is látszik a formban — átadásnál ez a Kérő iroda, átvételnél a Cél
              iroda (a bizonylaton eddig is így szerepelt, de a formból hiányzott). */}
          <div>
            <label className="form-label">
              {transferDirection === 'out'
                ? 'Kérő iroda (saját értéktár)'
                : 'Cél iroda (saját értéktár)'}
            </label>
            <input
              type="text"
              value={vaultLabel}
              readOnly
              disabled
              className="form-input w-full bg-gray-50 text-gray-600"
              aria-label="Saját értéktár (automatikusan kitöltve)"
            />
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
                const candidates = branches.filter((b) =>
                  transferDirection === 'out' ? b.id !== worker?.branchId : true,
                )
                return filterTransferTargetBranches(candidates, ownBranch).map((b) => {
                  const isTH =
                    b.branchTypeCode === 'TH' || /\bTH\b/i.test(b.code) || /\bTH\b/i.test(b.name)
                  const isVault = b.isVault === true
                  const badge = isVault ? ' (értéktár)' : isTH ? ' (TH)' : ''
                  return (
                    <option key={b.id} value={b.id}>
                      {b.code} - {b.name}
                      {badge}
                    </option>
                  )
                })
              })()}
            </select>
          </div>

          <div>
            <label htmlFor="transfer-type" className="form-label">
              {t('circulars.tipus')}
            </label>
            <select
              id="transfer-type"
              value={transferType}
              onChange={(e) =>
                setTransferType(e.target.value as CreateTransferRequest['transferType'])
              }
              className="form-input w-full"
            >
              {availableTransferTypes.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
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
                      {filteredCurrencies.map((c) => (
                        <option key={c.id} value={c.id}>
                          {c.code} - {c.name}
                        </option>
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
                <label htmlFor="currency" className="form-label">
                  {t('transfers.valuta')}
                </label>
                <select
                  id="currency"
                  value={currencyId ?? ''}
                  onChange={(e) => setCurrencyId(e.target.value ? Number(e.target.value) : null)}
                  className="form-input w-full"
                >
                  {/* FT/kez.ktg típusnál nincs üres opció — a HUF kötelezően kiválasztva marad. */}
                  {!isHufOnlyType && <option value="">{t('transfers.valasszonValutat')}</option>}
                  {filteredCurrencies.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.code} - {c.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label htmlFor="amount" className="form-label">
                  {t('transfers.osszeg')}
                </label>
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
              <label htmlFor="carrier-name" className="form-label">
                Szállító neve <span className="text-red-500">*</span>
              </label>
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
              <label htmlFor="seal-number" className="form-label">
                Plombaszám <span className="text-red-500">*</span>
              </label>
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
            <label htmlFor="notes" className="form-label">
              {t('common.note')}
            </label>
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
                    A(z) {denomPresetCode} címletei betöltve — csak a darabszámot adja meg (a sorok
                    szabadon szerkeszthetők, az üresen hagyott címlet kimarad).
                  </p>
                )}
                {denominationLines.map((line, idx) => {
                  const q = parseInt(line.quantity, 10)
                  const fv = parseFloat(line.faceValue.replace(',', '.').replace(/\s/g, ''))
                  const lineTotal = Number.isFinite(q) && Number.isFinite(fv) ? q * fv : 0
                  return (
                    <div
                      key={line.id}
                      className="grid grid-cols-[1fr_1fr_1fr_auto] gap-2 items-end"
                    >
                      <div>
                        {idx === 0 && <label className="form-label text-xs">Darab</label>}
                        <NumberInput
                          value={line.quantity}
                          onChange={(v) =>
                            setDenominationLines((prev) =>
                              prev.map((r, i) => (i === idx ? { ...r, quantity: v } : r)),
                            )
                          }
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
                          onChange={(v) =>
                            setDenominationLines((prev) =>
                              prev.map((r, i) => (i === idx ? { ...r, faceValue: v } : r)),
                            )
                          }
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
                        onClick={() =>
                          setDenominationLines((prev) =>
                            prev.length > 1 ? prev.filter((_, i) => i !== idx) : prev,
                          )
                        }
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
                  onClick={() =>
                    setDenominationLines((prev) => [
                      ...prev,
                      { id: denomIdRef.current++, quantity: '', faceValue: '' },
                    ])
                  }
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
            onClick={() => void handleCreateTransfer()}
            className="form-button-primary"
            disabled={loading}
          >
            {loading ? (
              <RefreshCw size={16} className="animate-spin" />
            ) : transferDirection === 'out' ? (
              <Send size={16} />
            ) : (
              <Download size={16} />
            )}
            {transferDirection === 'out' ? 'Átadás létrehozása' : 'Átvétel igénylése'}
          </button>
        </div>
      </div>

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

      <TransferReceiptModal
        isOpen={showReceiptModal}
        onClose={() => setShowReceiptModal(false)}
        receiptData={printReceiptData}
      />
    </div>
  )
}
