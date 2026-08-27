import { useState, useRef, useCallback, useEffect, useMemo } from 'react'
import {
  User,
  Search,
  CheckCircle,
  Loader2,
  AlertTriangle,
  X,
  Shield,
  ShieldCheck,
  ShieldAlert,
} from 'lucide-react'
import type { IdentificationLevel } from '../hooks/useIdentificationLevel'
import { customerApi, amlApi, dictionaryApi } from '../../../services/api/index'
import type { DictionaryEntry } from '../../../services/api/settings'
import type {
  Customer as ApiCustomer,
  CustomerCreateRequest,
  AmlCheckResultDto,
} from '../../../services/api/transactions'
import { logger } from '../../../utils/logger'
import { toast } from '../../../components/ui/toaster'
import { getErrorMessage } from '../../../utils/errorHandling'
import { useTranslation } from 'react-i18next'
import {
  PRIVACY_NOTICE_VERSION,
  appendPrivacyNoticeAcknowledgement,
} from '../../../utils/privacyNotice'
import i18n from '../../../i18n'

/**
 * V235 (2026-05-19 HIBA #15): a Pmt. szerinti "kiemelt kozszereplo" 6 minoseg-
 * kategoriaja. Ha az ugyfel PEP, kotelezo megjelolni hogy MILYEN minosegben.
 *
 * - CSALADTAG          — kozszereplo csaladtagja (hazastars, gyermek, szulo, testver)
 * - KOZELI_MUNKATARS   — kozszereplo kozeli munkatarsa, uzleti partnere
 * - KORMANYFO          — miniszterelnok, miniszter, allamtitkar
 * - PARLAMENTI         — orszaggyulesi kepviselo, helyi onkormanyzati kepviselo
 * - NAV_VEZETO         — NAV felsovezetes, allami-tulajdonu vallalat felsovezetes
 * - EGYEB              — egyeb kiemelt kozszereploi minoseg
 */
export type PepKind =
  | 'CSALADTAG'
  | 'KOZELI_MUNKATARS'
  | 'KORMANYFO'
  | 'PARLAMENTI'
  | 'NAV_VEZETO'
  | 'EGYEB'

/**
 * V235 (2026-05-19 HIBA #17): actor (kepviselt fel) teljes azonositasi adatai.
 * Pmt. tv. 6.§ (2): ha az ugyfel mas neveben jar el, a kepviselt felre is
 * teljes azonositast kell vegezni. A bizonylaton mindkettonek meg kell jelennie.
 */
export interface ActorIdentity {
  name: string
  birthPlace?: string
  birthDate?: string
  motherName?: string
  nationality?: string
  documentType?: string
  documentNumber?: string
  address?: string
}

export interface CustomerPanelData {
  id?: number
  name: string
  documentType: string
  documentNumber: string
  nationality: string
  birthPlace?: string
  birthDate?: string
  birthName?: string
  motherName?: string
  address?: string
  residence?: string
  addressCardNumber?: string
  amlVerified?: boolean
  // V229 (2026-05-15 HIBA #8): 300k+ JOGCIM nyilatkozat mezok
  isPep?: boolean
  sourceOfFunds?: string
  // AML 50M (Pmt./MNB 14/2025, V.2.5/V.2.8): strukturált forrás-dokumentum az 50M Ft feletti ügylethez.
  // Elfogadható: közjegyző/ügyvéd ellenjegyzésű magánokirat VAGY max. 3 éves banki bizonylat (szlip).
  sourceOfFundsDocType?: string
  sourceOfFundsDocDate?: string
  onOwnBehalf?: boolean
  actorName?: string
  // V235 NEW (HIBA #15): PEP minoseg, ha isPep=true
  pepKind?: PepKind | null
  // V235 NEW (HIBA #17): actor teljes azonositas, ha onOwnBehalf=false
  actorIdentity?: ActorIdentity | null
  // V325 (Batch3-C): jogi szemely ugyfel (legacy JOGISZEMELY) — a pultnal allo
  // szemely (megbizott) a fenti customer-mezokben.
  isLegalEntity?: boolean
  legalEntityName?: string
  legalEntitySeat?: string
  legalEntityTaxNumber?: string
  legalDeedNumber?: string
  /** V325: tenyleges tulajdonosok (Pmt. 9.§, legacy UJTULAJOK) — max 4. */
  beneficialOwners?: BeneficialOwnerForm[]
}

/** V325 (Batch3-C): egy tenyleges tulajdonos a formon (legacy UJTULAJOK mezok). */
export interface BeneficialOwnerForm {
  name: string
  address: string
  birthPlace: string
  birthDate: string
  nationality: string
  residenceAbroad: string
  interestNature: string
  interestExtent: string
  isPep: boolean
}

const EMPTY_OWNER: BeneficialOwnerForm = {
  name: '',
  address: '',
  birthPlace: '',
  birthDate: '',
  nationality: '',
  residenceAbroad: '',
  interestNature: '',
  interestExtent: '',
  isPep: false,
}

interface CustomerPanelProps {
  identificationLevel: IdentificationLevel
  minimumLevel: IdentificationLevel
  onLevelChange: (level: IdentificationLevel) => void
  requiresSourceVerification: boolean
  hufTotal: number
  onCustomerReady: (data: CustomerPanelData | null) => void
  onAmlResult?: (result: AmlCheckResultDto | null) => void
}

const LEVEL_ORDER: IdentificationLevel[] = ['SIMPLE', 'SIMPLIFIED', 'FULL']

const LEVEL_LABELS: Record<IdentificationLevel, string> = {
  SIMPLE: 'Nem azonosit',
  SIMPLIFIED: 'Egyszerusitett',
  FULL: 'Teljes azonositas',
}

const LEVEL_DESCRIPTIONS: Record<IdentificationLevel, string> = {
  SIMPLE: 'Csak allampolgarsag',
  SIMPLIFIED: 'Nev, szuletesi adatok',
  FULL: 'Teljes szemelyes adatok',
}

/**
 * Codex P1 #586 iter-4 fix: a degradalt-mod kvalifikalo helper.
 *
 * <p>Visszater TRUE ha az axios error halozati / szerver-elerhetetlen hibara utal:
 * <ul>
 *   <li>NINCS response (fail-no-response) ES NEM canceled/client-error: network down, timeout, dns.</li>
 *   <li>5xx response: 500-599 — intermittens backend hibak, ujraprobalhatok.</li>
 * </ul>
 * Auth (401/403), validation (4xx) -> fail-closed.
 * Cancellation (ERR_CANCELED, AbortController) -> fail-closed (NEM tenyleges halozati hiba).</p>
 */
// Codex P2 #586 iter-5: whitelist approach (volt: blacklist).
// Csak az ismert tranziens halozati hibakod-ok kapnak degradalt modot. Ismeretlen
// vagy uj axios error code (pl. ERR_INVALID_URL, adapter/config errors) -> fail-closed.
const RETRYABLE_AXIOS_CODES = new Set([
  'ERR_NETWORK', // network unavailable (offline, dns)
  'ECONNREFUSED', // server not running on port
  'ECONNABORTED', // axios timeout
  'ECONNRESET', // connection dropped
  'ETIMEDOUT', // os-level timeout
  'ENOTFOUND', // dns resolution failed
  'EAI_AGAIN', // dns temporary failure
])

function isRetryableAmlError(err: unknown): boolean {
  const axErr = err as { response?: { status?: number }; code?: string; isAxiosError?: boolean }
  if (!axErr?.response && axErr?.code !== undefined) {
    // fail-no-response: CSAK ismert network/timeout code-ok engedhetok degradalt modba
    return RETRYABLE_AXIOS_CODES.has(axErr.code)
  }
  const status = axErr?.response?.status
  if (status === undefined) return false
  return status >= 500 && status <= 599 // 5xx: server-side fail (intermittens) -> degradalt
}

export default function CustomerPanel({
  identificationLevel,
  minimumLevel,
  onLevelChange,
  requiresSourceVerification,
  hufTotal,
  onCustomerReady,
  onAmlResult,
}: CustomerPanelProps) {
  const { t } = useTranslation()
  const [searchQuery, setSearchQuery] = useState('')
  const [searchResults, setSearchResults] = useState<ApiCustomer[]>([])
  const [isSearching, setIsSearching] = useState(false)
  const [showResults, setShowResults] = useState(false)
  const searchTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const [selectedCustomer, setSelectedCustomer] = useState<ApiCustomer | null>(null)
  // TD9: az auto-propagate effekt utoljára propagált payloadjának szerializált alakja.
  // null = még nem propagált, vagy a selectedCustomer-fázis resetelte (restart-garancia).
  const lastAutoPropagatedRef = useRef<string | null>(null)

  // Form fields
  const [customerName, setCustomerName] = useState('')
  const [customerDocType, setCustomerDocType] = useState('ID_CARD')
  const [customerDocNumber, setCustomerDocNumber] = useState('')
  const [customerNationality, setCustomerNationality] = useState('Magyar')
  // FK-ÁLLAMPOLGÁRSÁG (2026-06-02): a teljes nemzetiség-törzs (NATIONALITY dictionary). Eddig CSAK
  // 3 fix opció volt; most az összes állampolgárság választható. Betöltési hiba esetén üres → a
  // render a régi 3-opciós fallbackra esik vissza (sose törjön a pénztári képernyő).
  const [nationalities, setNationalities] = useState<DictionaryEntry[]>([])
  useEffect(() => {
    let cancelled = false
    dictionaryApi
      .getByCategory('NATIONALITY')
      .then((list) => {
        if (!cancelled) setNationalities(list ?? [])
      })
      .catch(() => {
        if (!cancelled) setNationalities([])
      })
    return () => {
      cancelled = true
    }
  }, [])
  const [customerBirthPlace, setCustomerBirthPlace] = useState('')
  const [customerBirthDate, setCustomerBirthDate] = useState('')
  const [customerBirthName, setCustomerBirthName] = useState('')
  const [customerMotherName, setCustomerMotherName] = useState('')
  const [customerAddress, setCustomerAddress] = useState('')
  const [customerResidence, setCustomerResidence] = useState('')
  const [customerAddressCardNumber, setCustomerAddressCardNumber] = useState('')
  // V229 (2026-05-15 HIBA #8): 300k+ JOGCIM nyilatkozat mezok
  const [isPep, setIsPep] = useState<boolean>(false)
  const [privacyNoticeAccepted, setPrivacyNoticeAccepted] = useState<boolean>(false)
  const [sourceOfFunds, setSourceOfFunds] = useState<string>('')
  // AML 50M (Pmt./MNB 14/2025): strukturált forrás-dokumentum az 50M Ft feletti ügylethez.
  const [sourceOfFundsDocType, setSourceOfFundsDocType] = useState<string>('')
  const [sourceOfFundsDocDate, setSourceOfFundsDocDate] = useState<string>('')
  const [onOwnBehalf, setOnOwnBehalf] = useState<boolean>(true)
  const [actorName, setActorName] = useState<string>('')
  // V235 NEW (2026-05-19 HIBA #15): PEP minoseg — csak ha isPep=true
  const [pepKind, setPepKind] = useState<PepKind | ''>('')
  // V235 NEW (2026-05-19 HIBA #17): actor teljes azonositasa — csak ha !onOwnBehalf
  const [actorBirthPlace, setActorBirthPlace] = useState<string>('')
  const [actorBirthDate, setActorBirthDate] = useState<string>('')
  const [actorMotherName, setActorMotherName] = useState<string>('')
  const [actorNationality, setActorNationality] = useState<string>('Magyar')
  const [actorDocumentType, setActorDocumentType] = useState<string>('ID_CARD')
  const [actorDocumentNumber, setActorDocumentNumber] = useState<string>('')
  const [actorAddress, setActorAddress] = useState<string>('')

  // V325 (Batch3-C): jogi szemely ugyfel + tenyleges tulajdonosok (legacy
  // JOGISZEMELY + UJTULAJOK). A pultnal allo szemely (megbizott) adatai a
  // fenti customer-mezokben maradnak.
  const [isLegalEntity, setIsLegalEntity] = useState<boolean>(false)
  const [legalEntityName, setLegalEntityName] = useState<string>('')
  const [legalEntitySeat, setLegalEntitySeat] = useState<string>('')
  const [legalEntityTaxNumber, setLegalEntityTaxNumber] = useState<string>('')
  const [legalDeedNumber, setLegalDeedNumber] = useState<string>('')
  const [beneficialOwners, setBeneficialOwners] = useState<BeneficialOwnerForm[]>([])

  // V325: a jogi szemely mezok kozos csomagja MINDKET adat-osszeallitasi ponthoz
  // (kivalasztott + kezi ugyfel) — kikapcsolt allapotban ures (stale-data vedelem,
  // a Copilot #695 actorName-mintajaval azonosan).
  const legalEntityData = useCallback(
    (): Partial<CustomerPanelData> =>
      isLegalEntity
        ? {
            isLegalEntity: true,
            legalEntityName: legalEntityName.trim() || undefined,
            legalEntitySeat: legalEntitySeat.trim() || undefined,
            legalEntityTaxNumber: legalEntityTaxNumber.trim() || undefined,
            legalDeedNumber: legalDeedNumber.trim() || undefined,
            beneficialOwners: beneficialOwners.filter((o) => o.name.trim() !== ''),
          }
        : { isLegalEntity: false },
    [
      isLegalEntity,
      legalEntityName,
      legalEntitySeat,
      legalEntityTaxNumber,
      legalDeedNumber,
      beneficialOwners,
    ],
  )

  const [amlResult, setAmlResult] = useState<AmlCheckResultDto | null>(null)
  const [amlChecking, setAmlChecking] = useState(false)
  const [isSaving, setIsSaving] = useState(false)

  // Debounced search
  const handleSearchInput = useCallback((value: string) => {
    setSearchQuery(value)
    if (searchTimeoutRef.current) clearTimeout(searchTimeoutRef.current)
    if (value.trim().length < 2) {
      setSearchResults([])
      setShowResults(false)
      return
    }
    searchTimeoutRef.current = setTimeout(async () => {
      setIsSearching(true)
      try {
        const results = await customerApi.search(value.trim())
        setSearchResults(results.slice(0, 10))
        setShowResults(true)
      } catch (err) {
        logger.warn('CustomerPanel', 'Customer search failed, continuing with manual entry', err)
        setSearchResults([])
      } finally {
        setIsSearching(false)
      }
    }, 400)
  }, [])

  const runAmlCheck = useCallback(
    async (customerId: number, data: CustomerPanelData) => {
      if (!customerId || hufTotal <= 0) return data
      setAmlChecking(true)
      try {
        const result = await amlApi.checkAllThresholds(String(customerId), hufTotal)
        setAmlResult(result)
        onAmlResult?.(result)
        return { ...data, amlVerified: true }
      } catch (err) {
        // Codex P1 #586 iter-3 fix: HTTP 500 (intermittens backend hiba) is degradalt mod-kepes,
        // mint az 502/503/504. Az isRetryableAmlError helper egyseges 5xx + no-response logika.
        if (!isRetryableAmlError(err)) {
          // Auth (401/403), validation (4xx) — fail-closed.
          logger.warn(
            'CustomerPanel',
            'AML check failed with non-retryable error — fail-closed',
            err,
          )
          const blockedResult: AmlCheckResultDto = {
            transactionType: 0,
            weeklyTotal: 0,
            yearlyMax: 0,
            quarterlyCount: 0,
            quarterlyTotal: 0,
            requiresId: true,
            requiresEnhanced: false,
            blocked: true,
            warnings: [
              'AML ellenőrzés szerver-oldali hibával elutasitva (auth / validation). A tranzakció blokkolt.',
            ],
          }
          setAmlResult(blockedResult)
          onAmlResult?.(blockedResult)
          return data
        }
        // Local-first: network/5xx -> degradalt mod a CashierTransactionPage confirm-javal.
        logger.warn('CustomerPanel', 'AML check failed — degraded mode (network/5xx)', err)
        const degradedResult: AmlCheckResultDto = {
          transactionType: 0,
          weeklyTotal: 0,
          yearlyMax: 0,
          quarterlyCount: 0,
          quarterlyTotal: 0,
          requiresId: true,
          requiresEnhanced: false,
          blocked: false,
          warnings: [
            '[OFFLINE_DEGRADED] AML ellenőrzés nem sikerült (hálózati/szerver hiba).',
            'A tranzakció folytatható megerősítéssel, de utólagos központi ellenőrzésre kerül.',
          ],
        }
        setAmlResult(degradedResult)
        onAmlResult?.(degradedResult)
        return { ...data, amlVerified: false }
      } finally {
        setAmlChecking(false)
      }
    },
    [hufTotal, onAmlResult],
  )

  const handleSelectCustomer = useCallback(
    async (customer: ApiCustomer) => {
      // V325 (Batch3-C, Codex P2 #1116): a kivalasztott-ugyfel utvonal nem megy at a
      // missingRequiredFields kapun, ezert itt kulon guard — jogi szemely jelolesnel
      // az entitas-torzsadat + legalabb egy tenyleges tulajdonos nelkul nem mehet tovabb.
      if (
        isLegalEntity &&
        (!legalEntityName.trim() ||
          !legalEntitySeat.trim() ||
          !beneficialOwners.some((o) => o.name.trim()))
      ) {
        toast.warning(
          'Hiányzó jogi személy adatok',
          'Jogi személy nevében eljárásnál a jogi személy neve, székhelye és legalább egy tényleges tulajdonos megadása kötelező.',
        )
        return
      }
      setSelectedCustomer(customer)
      setShowResults(false)
      setSearchQuery('')

      let data: CustomerPanelData = {
        id: customer.id,
        name: customer.name,
        documentType: customer.documentType ?? 'ID_CARD',
        documentNumber: customer.documentNumber ?? '',
        nationality: customer.nationality ?? 'Magyar',
        birthPlace: customer.birthPlace,
        birthDate: customer.birthDate,
        birthName: customer.birthName,
        motherName: customer.motherName,
        address: customer.address,
        residence: customer.residence,
        addressCardNumber: customer.addressCardNumber,
        amlVerified: false,
        // V229 (HIBA #8): 300k+ JOGCIM nyilatkozat mezok a state-bol
        isPep,
        sourceOfFunds: sourceOfFunds.trim() || undefined,
        sourceOfFundsDocType: sourceOfFundsDocType || undefined,
        sourceOfFundsDocDate: sourceOfFundsDocDate || undefined,
        onOwnBehalf,
        actorName: actorName.trim() || undefined,
        // V235 (HIBA #15 + #17): PEP minoseg + actor teljes azonositasa
        pepKind: isPep && pepKind ? (pepKind as PepKind) : null,
        actorIdentity: !onOwnBehalf
          ? {
              name: actorName.trim(),
              birthPlace: actorBirthPlace.trim() || undefined,
              birthDate: actorBirthDate || undefined,
              motherName: actorMotherName.trim() || undefined,
              nationality: actorNationality.trim() || undefined,
              documentType: actorDocumentType,
              documentNumber: actorDocumentNumber.trim() || undefined,
              address: actorAddress.trim() || undefined,
            }
          : null,
        // V325 (Batch3-C): jogi szemely + tenyleges tulajdonosok
        ...legalEntityData(),
      }

      if (customer.id && hufTotal > 0) {
        data = await runAmlCheck(customer.id, data)
      }
      onCustomerReady(data)
    },
    [
      hufTotal,
      onCustomerReady,
      runAmlCheck,
      isPep,
      sourceOfFunds,
      sourceOfFundsDocType,
      sourceOfFundsDocDate,
      onOwnBehalf,
      actorName,
      pepKind,
      actorBirthPlace,
      actorBirthDate,
      actorMotherName,
      actorNationality,
      actorDocumentType,
      actorDocumentNumber,
      actorAddress,
      legalEntityData,
      isLegalEntity,
      legalEntityName,
      legalEntitySeat,
      beneficialOwners,
    ],
  )

  // Collect missing required fields per identification level. Empty array = form OK.
  // 2026-05-15 user-direktíva: SIMPLIFIED (100-300k) szinthez Pmt. 2017. évi LIII. tv.
  // szerint név + szül.hely + szül.idő elég — okmány NEM kötelező. FULL (300k+) szinthez
  // jön az okmány + anyja neve + lakcím.
  const missingRequiredFields = useMemo<string[]>(() => {
    if (identificationLevel === 'SIMPLE') return []
    const missing: string[] = []
    if (!customerName.trim()) missing.push('Név')
    if (!customerBirthPlace.trim()) missing.push('Születési hely')
    if (!customerBirthDate) missing.push('Születési idő')
    if (identificationLevel === 'FULL') {
      if (!customerDocNumber.trim()) missing.push('Okmányszám')
      if (!customerMotherName.trim()) missing.push('Anyja neve')
      if (!customerAddress.trim()) missing.push('Lakcím')
    }
    // Sourcery #614: 300k+ JOGCIM nyilatkozat kotelezo mezok
    if (hufTotal >= 300_000) {
      if (!sourceOfFunds.trim()) missing.push('Pénzeszközök forrása')
      // V235 (HIBA #17 2026-05-19): ha mas neveben jar el, az actor teljes
      // azonositasa is kotelezo (Pmt. tv. 6.§ (2)). NEM eleg csak a nev!
      if (!onOwnBehalf) {
        if (!actorName.trim()) missing.push('Képviselt fél neve')
        if (!actorBirthPlace.trim()) missing.push('Képviselt fél szül. helye')
        if (!actorBirthDate) missing.push('Képviselt fél szül. ideje')
        if (!actorMotherName.trim()) missing.push('Képviselt fél anyja neve')
        if (!actorDocumentNumber.trim()) missing.push('Képviselt fél okmányszáma')
        if (!actorAddress.trim()) missing.push('Képviselt fél lakcíme')
      }
      // V235 (HIBA #15 2026-05-19): ha PEP, a minoseget is meg kell jelolni
      if (isPep && !pepKind) missing.push('PEP minőség')
    }
    // V325 (Batch3-C, Codex P2 #1116): jogi szemely eseten az entitas-torzsadat
    // + legalabb egy tenyleges tulajdonos kotelezo (Pmt. 8-9.§, legacy JOGISZEMELY/
    // UJTULAJOK) — kulonben a 300k+ bizonylat jogi blokkja hianyosan nyomtatodna.
    if (isLegalEntity) {
      if (!legalEntityName.trim()) missing.push('Jogi személy neve')
      if (!legalEntitySeat.trim()) missing.push('Jogi személy székhelye')
      if (!beneficialOwners.some((o) => o.name.trim()))
        missing.push('Tényleges tulajdonos (legalább egy)')
    }
    if (!privacyNoticeAccepted) missing.push('Adatkezelési tájékoztató')
    return missing
  }, [
    identificationLevel,
    customerName,
    customerDocNumber,
    customerBirthPlace,
    customerBirthDate,
    customerMotherName,
    customerAddress,
    hufTotal,
    sourceOfFunds,
    onOwnBehalf,
    actorName,
    isPep,
    pepKind,
    actorBirthPlace,
    actorBirthDate,
    actorMotherName,
    actorDocumentNumber,
    actorAddress,
    privacyNoticeAccepted,
    isLegalEntity,
    legalEntityName,
    legalEntitySeat,
    beneficialOwners,
  ])

  const handleSaveManualCustomer = useCallback(async () => {
    // Replace silent `return` with explicit toast — user-visible feedback per #581 bug report
    // (user reported "100k HUF felett nem lehet ügyfelet regisztrálni").
    if (missingRequiredFields.length > 0) {
      toast.warning(
        'Hiányzó kötelező mezők',
        `${missingRequiredFields.join(', ')} kitöltése kötelező a ${identificationLevel === 'FULL' ? 'teljes' : 'egyszerűsített'} azonosításhoz.`,
      )
      return
    }

    setIsSaving(true)
    try {
      const createData: CustomerCreateRequest = {
        name: customerName.trim(),
        documentType: customerDocType,
        documentNumber: customerDocNumber.trim() || undefined,
        nationality: customerNationality,
        birthPlace: customerBirthPlace.trim() || undefined,
        birthDate: customerBirthDate || undefined,
        birthName: customerBirthName.trim() || undefined,
        motherName: customerMotherName.trim() || undefined,
        address: customerAddress.trim() || undefined,
        residence: customerResidence.trim() || undefined,
        addressCardNumber: customerAddressCardNumber.trim() || undefined,
        isPep,
        notes: appendPrivacyNoticeAcknowledgement(),
      }

      let savedCustomer: ApiCustomer | null = null
      let createError: unknown = null
      try {
        savedCustomer = await customerApi.create(createData)
      } catch (err) {
        createError = err
        logger.warn('CustomerPanel', 'Customer create failed, trying doc number lookup', err)
        try {
          if (customerDocNumber.trim()) {
            savedCustomer = await customerApi.getByDocumentNumber(customerDocNumber.trim())
          }
        } catch {
          /* proceed without ID */
        }
      }

      // 2026-05-15 user-direktíva (HIBA #9): ha a create + fallback IS sikertelen,
      // a tényleges backend hibát mutassuk meg a felhasználónak, NE megtévesztő
      // AML-warningot. A pénztáros tudja meg, hogy duplikált doc# / validáció /
      // 500 hiba volt.
      if (!savedCustomer?.id && createError) {
        const msg = getErrorMessage(createError)
        toast.error('Ügyfél rögzítése sikertelen', msg)
      }

      let data: CustomerPanelData = {
        id: savedCustomer?.id,
        name: customerName.trim(),
        documentType: customerDocType,
        documentNumber: customerDocNumber.trim(),
        nationality: customerNationality,
        birthPlace: customerBirthPlace.trim() || undefined,
        birthDate: customerBirthDate || undefined,
        birthName: customerBirthName.trim() || undefined,
        motherName: customerMotherName.trim() || undefined,
        address: customerAddress.trim() || undefined,
        residence: customerResidence.trim() || undefined,
        addressCardNumber: customerAddressCardNumber.trim() || undefined,
        amlVerified: false,
        // V229 (HIBA #8): 300k+ JOGCIM nyilatkozat
        isPep,
        sourceOfFunds: sourceOfFunds.trim() || undefined,
        sourceOfFundsDocType: sourceOfFundsDocType || undefined,
        sourceOfFundsDocDate: sourceOfFundsDocDate || undefined,
        onOwnBehalf,
        // Copilot P2 (PR #695): csak akkor adjuk at az actorName-et ha
        // tenyleg "mas neveben" jar el — egyebkent stale data maradhatna
        // a kliensben (user kitoltotte, majd visszakapcsolt "Sajat nevben"-re).
        actorName: !onOwnBehalf ? actorName.trim() || undefined : undefined,
        // V235 (HIBA #15): PEP minoseg, ha isPep=true
        pepKind: isPep && pepKind ? (pepKind as PepKind) : null,
        // V235 (HIBA #17): actor teljes azonositasa, ha !onOwnBehalf
        actorIdentity: !onOwnBehalf
          ? {
              name: actorName.trim(),
              birthPlace: actorBirthPlace.trim() || undefined,
              birthDate: actorBirthDate || undefined,
              motherName: actorMotherName.trim() || undefined,
              nationality: actorNationality.trim() || undefined,
              documentType: actorDocumentType,
              documentNumber: actorDocumentNumber.trim() || undefined,
              address: actorAddress.trim() || undefined,
            }
          : null,
        // V325 (Batch3-C): jogi szemely + tenyleges tulajdonosok
        ...legalEntityData(),
      }
      setSelectedCustomer(savedCustomer)

      if (savedCustomer?.id && hufTotal > 0) {
        data = await runAmlCheck(savedCustomer.id, data)
      } else if (hufTotal >= 100_000) {
        const warnResult: AmlCheckResultDto = {
          transactionType: 0,
          weeklyTotal: 0,
          yearlyMax: 0,
          quarterlyCount: 0,
          quarterlyTotal: 0,
          requiresId: true,
          requiresEnhanced: false,
          blocked: false,
          warnings: [
            'Ugyfel mentese nem sikerult — AML ellenorzes korlátozott, az adatok kézi rögzítéssel kerülnek a tranzakcióba',
          ],
        }
        setAmlResult(warnResult)
        onAmlResult?.(warnResult)
      }

      onCustomerReady(data)
    } catch (err) {
      logger.error('CustomerPanel', 'Save customer failed', err)
    } finally {
      setIsSaving(false)
    }
  }, [
    missingRequiredFields,
    customerName,
    customerDocType,
    customerDocNumber,
    customerNationality,
    customerBirthPlace,
    customerBirthDate,
    customerBirthName,
    customerMotherName,
    customerAddress,
    customerResidence,
    customerAddressCardNumber,
    isPep,
    hufTotal,
    identificationLevel,
    onCustomerReady,
    onAmlResult,
    runAmlCheck,
    // Lint-audit 2026-08-09 (react-hooks/exhaustive-deps): ezek mind a mentett
    // ugyfel-/AML-payload reszei (Pmt. adatrogzites), de hianyoztak a deps-bol.
    // Ha a penztaros UTOLJARA ezek valamelyiket allitja be — tipikusan a "mas
    // neveben eljaro" (actor) azonositast vagy a penzeszkoz forrasat —, a
    // memoizalt closure a REGI erteket menti el: hianyos vagy teves AML-adat
    // kerulne a tranzakciohoz. `legalEntityData` `useCallback` (:265), stabil.
    onOwnBehalf,
    actorName,
    actorBirthDate,
    actorBirthPlace,
    actorMotherName,
    actorNationality,
    actorDocumentType,
    actorDocumentNumber,
    actorAddress,
    pepKind,
    sourceOfFunds,
    sourceOfFundsDocType,
    sourceOfFundsDocDate,
    legalEntityData,
  ])

  const handleClearCustomer = useCallback(() => {
    setSelectedCustomer(null)
    setCustomerName('')
    setCustomerDocType('ID_CARD')
    setCustomerDocNumber('')
    setCustomerNationality('Magyar')
    setCustomerBirthPlace('')
    setCustomerBirthDate('')
    setCustomerBirthName('')
    setCustomerMotherName('')
    setCustomerAddress('')
    setCustomerResidence('')
    setCustomerAddressCardNumber('')
    setPrivacyNoticeAccepted(false)
    setAmlResult(null)
    setSearchQuery('')
    setSearchResults([])
    onCustomerReady(null)
    onAmlResult?.(null)
  }, [onCustomerReady, onAmlResult])

  // Auto-propagate form data so the transaction can proceed even without explicit save.
  // SIMPLE mode: only nationality; SIMPLIFIED/FULL: all filled fields.
  useEffect(() => {
    if (selectedCustomer) {
      // TD9: kiválasztott ügyfélnél nincs auto-propagate; a ref reset garantálja,
      // hogy clear után az effekt akkor is újra propagál, ha a payload megegyezik
      // a kiválasztás előtti utolsóval.
      lastAutoPropagatedRef.current = null
      return
    }
    const payload: CustomerPanelData =
      identificationLevel === 'SIMPLE'
        ? {
            name: '',
            documentType: '',
            documentNumber: '',
            nationality: customerNationality,
          }
        : {
            name: customerName.trim(),
            documentType: customerDocType,
            documentNumber: customerDocNumber.trim(),
            nationality: customerNationality,
            birthPlace: customerBirthPlace.trim() || undefined,
            birthDate: customerBirthDate || undefined,
            birthName: customerBirthName.trim() || undefined,
            motherName: customerMotherName.trim() || undefined,
            address: customerAddress.trim() || undefined,
            residence: customerResidence.trim() || undefined,
            addressCardNumber: customerAddressCardNumber.trim() || undefined,
          }
    // TD9 change-guard: idempotens re-render / trim-ekvivalens state-változás
    // ne triggereljen redundáns onCustomerReady-t. A kulcssorrend literál-fix,
    // az undefined mezőket a JSON.stringify kihagyja → stabil kanonikus alak.
    const serialized = JSON.stringify(payload)
    if (serialized === lastAutoPropagatedRef.current) return
    lastAutoPropagatedRef.current = serialized
    onCustomerReady(payload)
  }, [
    identificationLevel,
    customerNationality,
    customerName,
    customerDocType,
    customerDocNumber,
    customerBirthPlace,
    customerBirthDate,
    customerBirthName,
    customerMotherName,
    customerAddress,
    customerResidence,
    customerAddressCardNumber,
    selectedCustomer,
    onCustomerReady,
  ])

  // Re-run AML when hufTotal changes. Codex P1 #586 fix: isRetryableAmlError helper
  // egyseges no-response + 5xx kvalifikalas (HTTP 500 is degradalt mod-kepes).
  useEffect(() => {
    if (selectedCustomer?.id && hufTotal > 0) {
      const timer = setTimeout(async () => {
        try {
          const result = await amlApi.checkAllThresholds(String(selectedCustomer.id), hufTotal)
          setAmlResult(result)
          onAmlResult?.(result)
        } catch (err) {
          if (!isRetryableAmlError(err)) {
            const blockedResult: AmlCheckResultDto = {
              transactionType: 0,
              weeklyTotal: 0,
              yearlyMax: 0,
              quarterlyCount: 0,
              quarterlyTotal: 0,
              requiresId: true,
              requiresEnhanced: false,
              blocked: true,
              warnings: [
                'AML újraellenőrzés szerver-oldali hibával elutasitva. A tranzakció blokkolt.',
              ],
            }
            setAmlResult(blockedResult)
            onAmlResult?.(blockedResult)
            return
          }
          const degradedResult: AmlCheckResultDto = {
            transactionType: 0,
            weeklyTotal: 0,
            yearlyMax: 0,
            quarterlyCount: 0,
            quarterlyTotal: 0,
            requiresId: true,
            requiresEnhanced: false,
            blocked: false,
            warnings: [
              '[OFFLINE_DEGRADED] AML újraellenőrzés nem sikerült (hálózati/szerver hiba).',
              'A tranzakció folytatható megerősítéssel, de utólagos központi ellenőrzésre kerül.',
            ],
          }
          setAmlResult(degradedResult)
          onAmlResult?.(degradedResult)
        }
      }, 1000)
      return () => clearTimeout(timer)
    }
  }, [hufTotal, selectedCustomer?.id, onAmlResult])

  const showFull = identificationLevel === 'FULL'
  const isFormValid = missingRequiredFields.length === 0

  const fieldClass =
    'w-full h-9 px-2 text-sm rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white focus:ring-2 focus:border-transparent'
  const fieldStyle = { '--tw-ring-color': 'var(--primary)' } as React.CSSProperties

  return (
    <div className="space-y-3">
      <h3 className="text-lg font-bold flex items-center gap-2 text-gray-900 dark:text-white">
        <User className="w-5 h-5" />
        {t('transactions.ugyfelAdatok')}
      </h3>

      {/* Identification level selector */}
      <div className="flex gap-1">
        {LEVEL_ORDER.map((level) => {
          const minIdx = LEVEL_ORDER.indexOf(minimumLevel)
          const levelIdx = LEVEL_ORDER.indexOf(level)
          const disabled = levelIdx < minIdx
          const active = level === identificationLevel

          const IconComponent =
            level === 'SIMPLE' ? Shield : level === 'SIMPLIFIED' ? ShieldCheck : ShieldAlert

          return (
            <button
              key={level}
              onClick={() => !disabled && onLevelChange(level)}
              disabled={disabled}
              className={`flex-1 py-2 px-1 rounded-lg text-xs font-semibold border-2 transition-all flex flex-col items-center gap-1 ${
                active
                  ? 'border-blue-500 bg-blue-50 dark:bg-blue-950/30 text-blue-700 dark:text-blue-300'
                  : disabled
                    ? 'border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900/30 text-gray-400 dark:text-gray-600 cursor-not-allowed'
                    : 'border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:border-blue-300 cursor-pointer'
              }`}
            >
              <IconComponent className="w-4 h-4" />
              <span>{LEVEL_LABELS[level]}</span>
              <span className="font-normal text-[10px] opacity-70">
                {LEVEL_DESCRIPTIONS[level]}
              </span>
            </button>
          )
        })}
      </div>

      {/* Level indicator */}
      {identificationLevel !== 'SIMPLE' && (
        <div className="bg-amber-50 dark:bg-amber-950/30 border-2 border-amber-400 dark:border-amber-600 rounded-lg p-3 flex items-start gap-2">
          <AlertTriangle className="w-5 h-5 text-amber-600 dark:text-amber-400 mt-0.5 shrink-0" />
          <div className="text-sm">
            <p className="font-semibold text-amber-900 dark:text-amber-200">
              {identificationLevel === 'SIMPLIFIED'
                ? 'Egyszerusitett azonositas (100.000 — 300.000 Ft)'
                : 'Teljes azonositas KOTELEZO (300.000 Ft felett)'}
            </p>
            {requiresSourceVerification && (
              <p className="text-amber-700 dark:text-amber-300 mt-1">
                {t('transactions.penzEredetenekIgazolasaKotelezo3500000FtFelett')}
              </p>
            )}
          </div>
        </div>
      )}

      {/* AML warnings */}
      {amlResult && (amlResult.blocked || amlResult.warnings.length > 0) && (
        <div
          className={`border-2 rounded-lg p-3 text-sm ${
            amlResult.blocked
              ? 'bg-red-50 dark:bg-red-950/30 border-red-500 text-red-800 dark:text-red-200'
              : 'bg-yellow-50 dark:bg-yellow-950/30 border-yellow-400 text-yellow-800 dark:text-yellow-200'
          }`}
        >
          <p className="font-bold mb-1">
            {amlResult.blocked
              ? 'TRANZAKCIO BLOKKOLT — AML szabalysertes'
              : 'AML figyelmeztetesek:'}
          </p>
          {amlResult.warnings.map((w, i) => (
            <p key={i}>
              {i18n.t('literals.lit-26')}
              {w}
            </p>
          ))}
          {amlChecking && <Loader2 className="w-4 h-4 animate-spin inline ml-2" />}
        </div>
      )}

      {amlChecking && !amlResult && (
        <div className="flex items-center gap-2 text-sm text-gray-500">
          <Loader2 className="w-4 h-4 animate-spin" />
          {i18n.t('literals.aml-ellenorzes')}
        </div>
      )}

      {selectedCustomer ? (
        /* SELECTED CUSTOMER VIEW */
        <div className="space-y-2">
          <div className="p-3 bg-green-50 dark:bg-green-950/30 border border-green-200 dark:border-green-700 rounded-lg flex items-center justify-between">
            <div className="flex items-center gap-2">
              <CheckCircle size={18} className="text-green-600 dark:text-green-400" />
              <span className="text-green-700 dark:text-green-300 font-semibold">
                {t('transactions.ugyfelKivalasztva')}
              </span>
            </div>
            <button
              onClick={handleClearCustomer}
              className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200"
            >
              <X size={18} />
            </button>
          </div>
          <div className="grid grid-cols-2 gap-2 text-sm">
            <div>
              <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">
                {t('competitors.nev')}
              </label>
              <div className="font-semibold text-gray-900 dark:text-white">
                {selectedCustomer.name}
              </div>
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">
                {t('transactions.allampolgarsag')}
              </label>
              <div className="text-gray-900 dark:text-white">
                {selectedCustomer.nationality ?? 'Magyar'}
              </div>
            </div>
            {selectedCustomer.documentType && (
              <div>
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">
                  {t('sanction.okmany')}
                </label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.documentType}</div>
              </div>
            )}
            {selectedCustomer.documentNumber && (
              <div>
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">
                  {t('transactions.okmanySzam')}
                </label>
                <div className="font-mono text-gray-900 dark:text-white">
                  {selectedCustomer.documentNumber}
                </div>
              </div>
            )}
            {selectedCustomer.birthPlace && (
              <div>
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">
                  {t('transactions.szuletesiHely')}
                </label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.birthPlace}</div>
              </div>
            )}
            {selectedCustomer.birthDate && (
              <div>
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">
                  {t('transactions.szuletesiIdo')}
                </label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.birthDate}</div>
              </div>
            )}
            {selectedCustomer.birthName && (
              <div className="col-span-2">
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">
                  {t('transactions.elozoNev')}
                </label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.birthName}</div>
              </div>
            )}
            {selectedCustomer.motherName && (
              <div className="col-span-2">
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">
                  {t('common.motherName')}
                </label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.motherName}</div>
              </div>
            )}
            {selectedCustomer.address && (
              <div className="col-span-2">
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">
                  {t('transactions.lakcim')}
                </label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.address}</div>
              </div>
            )}
            {selectedCustomer.residence && (
              <div className="col-span-2">
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">
                  {t('transactions.tartozkodasiHely')}
                </label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.residence}</div>
              </div>
            )}
            {selectedCustomer.addressCardNumber && (
              <div>
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">
                  {t('transactions.lakcimkartyaSzam')}
                </label>
                <div className="font-mono text-gray-900 dark:text-white">
                  {selectedCustomer.addressCardNumber}
                </div>
              </div>
            )}
          </div>
        </div>
      ) : identificationLevel === 'SIMPLE' ? (
        /* SIMPLE — only nationality */
        <div className="p-3 bg-gray-50 dark:bg-gray-900/50 border border-gray-200 dark:border-gray-700 rounded-lg space-y-2">
          <div>
            <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">
              {t('transactions.allampolgarsag')}
            </label>
            <select
              className={fieldClass}
              style={fieldStyle}
              value={customerNationality}
              onChange={(e) => setCustomerNationality(e.target.value)}
            >
              {nationalities.length > 0 ? (
                nationalities.map((n) => (
                  <option key={n.code} value={n.nameHu || n.name}>
                    {n.nameHu || n.name}
                  </option>
                ))
              ) : (
                <>
                  <option>{t('settings.magyar')}</option>
                  <option>{t('transactions.euAllampolgarsag')}</option>
                  <option>{t('transactions.egyeb')}</option>
                </>
              )}
            </select>
          </div>
          <div className="text-center text-gray-500 dark:text-gray-400 py-2">
            <User size={32} className="mx-auto mb-1 text-gray-300 dark:text-gray-600" />
            <div className="text-sm">
              {t('transactions.100000FtAlattTovabbiAzonositasNemSzukseges')}
            </div>
          </div>
        </div>
      ) : (
        /* SIMPLIFIED or FULL — search + manual entry */
        <div className="space-y-3">
          {/* Search */}
          <div className="relative">
            <div className="relative">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => handleSearchInput(e.target.value)}
                onFocus={() => searchResults.length > 0 && setShowResults(true)}
                className={`${fieldClass} h-10 pl-9 pr-3`}
                style={fieldStyle}
                placeholder="Nev vagy okmanyszam kereses..."
              />
              <Search className="absolute left-3 top-2.5 w-4 h-4 text-gray-400" />
              {isSearching && (
                <Loader2 className="absolute right-3 top-2.5 w-4 h-4 animate-spin text-gray-400" />
              )}
            </div>

            {showResults && searchResults.length > 0 && (
              <div className="absolute z-50 w-full mt-1 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-xl max-h-60 overflow-y-auto">
                {searchResults.map((c) => (
                  <button
                    key={c.id}
                    onClick={() => void handleSelectCustomer(c)}
                    className="w-full text-left px-3 py-2 hover:bg-gray-50 dark:hover:bg-gray-700 border-b border-gray-100 dark:border-gray-700 last:border-0"
                  >
                    <div className="font-medium text-sm text-gray-900 dark:text-white">
                      {c.name}
                    </div>
                    <div className="text-xs text-gray-500 dark:text-gray-400">
                      {c.documentType}
                      {i18n.t('literals.lit-22')}
                      {c.documentNumber}
                      {i18n.t('literals.lit-52')}
                      {c.nationality ?? 'Magyar'}
                    </div>
                  </button>
                ))}
              </div>
            )}
            {showResults &&
              searchResults.length === 0 &&
              !isSearching &&
              searchQuery.trim().length >= 2 && (
                <div className="absolute z-50 w-full mt-1 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-xl p-3 text-sm text-gray-500">
                  {t('transactions.nemTalalhatoUgyfelAdjaMegAzAdatokatKezzel')}
                </div>
              )}
          </div>

          {/* Manual entry */}
          <div className="p-3 bg-gray-50 dark:bg-gray-900/50 border border-gray-200 dark:border-gray-700 rounded-lg space-y-2">
            <p className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide">
              {t('transactions.kezzelMegadas')}
            </p>
            <div className="grid grid-cols-2 gap-2">
              {/* --- Always shown for SIMPLIFIED+ --- */}
              <div className="col-span-2">
                <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">
                  {t('transactions.nev')}
                </label>
                <input
                  type="text"
                  className={fieldClass}
                  style={fieldStyle}
                  data-testid="customer-name-input"
                  value={customerName}
                  onChange={(e) => setCustomerName(e.target.value)}
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">
                  {t('transactions.szuletesiIdo2')}
                </label>
                <input
                  type="date"
                  className={fieldClass}
                  style={fieldStyle}
                  data-testid="customer-birth-date-input"
                  value={customerBirthDate}
                  onChange={(e) => setCustomerBirthDate(e.target.value)}
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">
                  {t('transactions.szuletesiHely2')}
                </label>
                <input
                  type="text"
                  className={fieldClass}
                  style={fieldStyle}
                  data-testid="customer-birth-place-input"
                  value={customerBirthPlace}
                  onChange={(e) => setCustomerBirthPlace(e.target.value)}
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">
                  {t('transactions.allampolgarsag2')}
                </label>
                <select
                  className={fieldClass}
                  style={fieldStyle}
                  value={customerNationality}
                  onChange={(e) => setCustomerNationality(e.target.value)}
                >
                  {nationalities.length > 0 ? (
                    nationalities.map((n) => (
                      <option key={n.code} value={n.nameHu || n.name}>
                        {n.nameHu || n.name}
                      </option>
                    ))
                  ) : (
                    <>
                      <option>{t('settings.magyar')}</option>
                      <option>{t('transactions.euAllampolgarsag')}</option>
                      <option>{t('transactions.egyeb')}</option>
                    </>
                  )}
                </select>
              </div>

              {/* HIBA #12 (2026-05-19): Pmt. szerint SIMPLIFIED (100-300k) szinten az
                  okmány típus + szám NEM kötelező — csak FULL (300k+) szinten. A
                  korábbi UI mindkettőt mutatta SIMPLIFIED-nél is, ami megzavarta a
                  pénztárosokat. Most csak FULL módban jelennek meg. */}
              {showFull && (
                <>
                  <div>
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">
                      {t('transactions.okmanyTipus')}
                    </label>
                    <select
                      className={fieldClass}
                      style={fieldStyle}
                      value={customerDocType}
                      onChange={(e) => setCustomerDocType(e.target.value)}
                    >
                      <option value="ID_CARD">{t('transactions.szemelyiIgazolvany')}</option>
                      <option value="PASSPORT">{t('transactions.utlevel')}</option>
                      <option value="DRIVING_LICENSE">{t('transactions.vezetoiEngedely')}</option>
                      <option value="RESIDENCE_PERMIT">
                        {t('transactions.tartozkodasiEngedely')}
                      </option>
                      <option value="OTHER">{t('transactions.egyeb')}</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">
                      {t('transactions.okmanyszam')}
                    </label>
                    <input
                      type="text"
                      className={`${fieldClass} font-mono`}
                      style={fieldStyle}
                      data-testid="customer-doc-number-input"
                      value={customerDocNumber}
                      onChange={(e) => setCustomerDocNumber(e.target.value)}
                    />
                  </div>
                </>
              )}

              {/* --- FULL only fields --- */}
              {showFull && (
                <>
                  <div>
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">
                      {t('transactions.elozoNevSzulNev')}
                    </label>
                    <input
                      type="text"
                      className={fieldClass}
                      style={fieldStyle}
                      value={customerBirthName}
                      onChange={(e) => setCustomerBirthName(e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">
                      {t('transactions.anyjaNeve')}
                    </label>
                    <input
                      type="text"
                      className={fieldClass}
                      style={fieldStyle}
                      data-testid="customer-mother-name-input"
                      value={customerMotherName}
                      onChange={(e) => setCustomerMotherName(e.target.value)}
                    />
                  </div>
                  <div className="col-span-2">
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">
                      {t('transactions.lakcimEsIranyitoszam')}
                    </label>
                    <input
                      type="text"
                      className={fieldClass}
                      style={fieldStyle}
                      data-testid="customer-address-input"
                      value={customerAddress}
                      onChange={(e) => setCustomerAddress(e.target.value)}
                      placeholder="pl. 1234 Budapest, Fo utca 1."
                    />
                  </div>
                  <div className="col-span-2">
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">
                      {t('transactions.tartozkodasiHely')}
                    </label>
                    <input
                      type="text"
                      className={fieldClass}
                      style={fieldStyle}
                      value={customerResidence}
                      onChange={(e) => setCustomerResidence(e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">
                      {t('transactions.lakcimkartyaSzama')}
                    </label>
                    <input
                      type="text"
                      className={`${fieldClass} font-mono`}
                      style={fieldStyle}
                      value={customerAddressCardNumber}
                      onChange={(e) => setCustomerAddressCardNumber(e.target.value)}
                    />
                  </div>
                </>
              )}
            </div>

            {/* V229 + V235 (2026-05-15/-19 HIBA #8 + #15 + #17): 300k+ Pmt. JOGCIM nyilatkozat block */}
            {hufTotal >= 300_000 && (
              <div className="mt-3 p-3 rounded-md border border-amber-300 dark:border-amber-700 bg-amber-50/60 dark:bg-amber-950/20 space-y-2">
                <div className="text-xs font-semibold text-amber-900 dark:text-amber-200">
                  {i18n.t('literals.pmt-jogcim-nyilatkozat-300-000-ft-felett')}
                </div>
                {/* HIBA #15 (2026-05-19): a PEP minoseg 7-utas dropdown — nem csak Igen/Nem.
                    A bizonylaton kotelezo megjelolni MILYEN minosegben kiemelt kozszereplo. */}
                <div>
                  <label className="text-xs block mb-0.5">
                    {i18n.t('literals.kiemelt-kozszereplo-pep-2')}
                  </label>
                  <select
                    className={fieldClass}
                    style={fieldStyle}
                    data-testid="customer-pep-kind-select"
                    value={isPep ? pepKind || 'EGYEB' : 'NEM'}
                    onChange={(e) => {
                      const v = e.target.value
                      if (v === 'NEM') {
                        setIsPep(false)
                        setPepKind('')
                      } else {
                        setIsPep(true)
                        setPepKind(v as PepKind)
                      }
                    }}
                  >
                    <option value="NEM">{i18n.t('literals.nem-kozszereplo')}</option>
                    <option value="CSALADTAG">
                      {i18n.t('literals.igen-kiemelt-kozszereplo-csaladtagja')}
                    </option>
                    <option value="KOZELI_MUNKATARS">
                      {i18n.t('literals.igen-kozeli-munkatars-uzleti-partner')}
                    </option>
                    <option value="KORMANYFO">
                      {i18n.t('literals.igen-miniszter-allamtitkar-kormanyfo')}
                    </option>
                    <option value="PARLAMENTI">
                      {i18n.t('literals.igen-orszaggyulesi-onkormanyzati-kepvise')}
                    </option>
                    <option value="NAV_VEZETO">
                      {i18n.t('literals.igen-nav-allami-vallalat-felsovezetes')}
                    </option>
                    <option value="EGYEB">
                      {i18n.t('literals.igen-egyeb-kiemelt-kozszereplo')}
                    </option>
                  </select>
                </div>
                <div className="flex items-center gap-4">
                  <label className="text-xs flex items-center gap-1.5">
                    <span>{i18n.t('literals.sajat-neveben-jar-el')}</span>
                    <label className="inline-flex items-center gap-1">
                      <input
                        type="radio"
                        name="onOwnBehalf"
                        checked={onOwnBehalf}
                        onChange={() => setOnOwnBehalf(true)}
                      />
                      <span>{i18n.t('literals.igen')}</span>
                    </label>
                    <label className="inline-flex items-center gap-1">
                      <input
                        type="radio"
                        name="onOwnBehalf"
                        checked={!onOwnBehalf}
                        onChange={() => setOnOwnBehalf(false)}
                      />
                      <span>{i18n.t('literals.nem')}</span>
                    </label>
                  </label>
                </div>
                {/* HIBA #17 (2026-05-19): ha mas neveben jar el, a kepviselt felre is
                    teljes azonositast kell vegezni (Pmt. tv. 6.§ (2)). A bizonylaton
                    mindkettonek meg kell jelennie. */}
                {!onOwnBehalf && (
                  <div className="ml-4 p-2 rounded border border-amber-400 dark:border-amber-600 bg-amber-100/50 dark:bg-amber-900/30 space-y-2">
                    <div className="text-xs font-semibold text-amber-900 dark:text-amber-200">
                      {i18n.t('literals.kepviselt-fel-teljes-azonositasa-kotelez')}
                    </div>
                    <div>
                      <label className="text-xs block">{i18n.t('literals.nev-2')}</label>
                      <input
                        type="text"
                        className={fieldClass}
                        style={fieldStyle}
                        data-testid="actor-name-input"
                        value={actorName}
                        onChange={(e) => setActorName(e.target.value)}
                        placeholder="A képviselt fél teljes neve"
                      />
                    </div>
                    <div className="grid grid-cols-2 gap-2">
                      <div>
                        <label className="text-xs block">{i18n.t('literals.szuletesi-hely')}</label>
                        <input
                          type="text"
                          className={fieldClass}
                          style={fieldStyle}
                          data-testid="actor-birth-place-input"
                          value={actorBirthPlace}
                          onChange={(e) => setActorBirthPlace(e.target.value)}
                        />
                      </div>
                      <div>
                        <label className="text-xs block">{i18n.t('literals.szuletesi-ido')}</label>
                        <input
                          type="date"
                          className={fieldClass}
                          style={fieldStyle}
                          data-testid="actor-birth-date-input"
                          value={actorBirthDate}
                          onChange={(e) => setActorBirthDate(e.target.value)}
                        />
                      </div>
                      <div>
                        <label className="text-xs block">{i18n.t('literals.anyja-neve')}</label>
                        <input
                          type="text"
                          className={fieldClass}
                          style={fieldStyle}
                          data-testid="actor-mother-name-input"
                          value={actorMotherName}
                          onChange={(e) => setActorMotherName(e.target.value)}
                        />
                      </div>
                      <div>
                        <label className="text-xs block">{i18n.t('literals.allampolgarsag')}</label>
                        <select
                          className={fieldClass}
                          style={fieldStyle}
                          value={actorNationality}
                          onChange={(e) => setActorNationality(e.target.value)}
                        >
                          {nationalities.length > 0 ? (
                            nationalities.map((n) => (
                              <option key={n.code} value={n.nameHu || n.name}>
                                {n.nameHu || n.name}
                              </option>
                            ))
                          ) : (
                            <>
                              <option>{i18n.t('literals.magyar')}</option>
                              <option>{i18n.t('literals.eu-allampolgarsag')}</option>
                              <option>{i18n.t('literals.egyeb')}</option>
                            </>
                          )}
                        </select>
                      </div>
                      <div>
                        <label className="text-xs block">{i18n.t('literals.okmany-tipus')}</label>
                        <select
                          className={fieldClass}
                          style={fieldStyle}
                          value={actorDocumentType}
                          onChange={(e) => setActorDocumentType(e.target.value)}
                        >
                          <option value="ID_CARD">{i18n.t('literals.szemelyi-igazolvany')}</option>
                          <option value="PASSPORT">{i18n.t('literals.utlevel')}</option>
                          <option value="DRIVING_LICENSE">
                            {i18n.t('literals.vezetoi-engedely')}
                          </option>
                          <option value="RESIDENCE_PERMIT">
                            {i18n.t('literals.tartozkodasi-engedely')}
                          </option>
                          <option value="OTHER">{i18n.t('literals.egyeb')}</option>
                        </select>
                      </div>
                      <div>
                        <label className="text-xs block">{i18n.t('literals.okmanyszam-3')}</label>
                        <input
                          type="text"
                          className={`${fieldClass} font-mono`}
                          style={fieldStyle}
                          data-testid="actor-doc-number-input"
                          value={actorDocumentNumber}
                          onChange={(e) => setActorDocumentNumber(e.target.value)}
                        />
                      </div>
                    </div>
                    <div>
                      <label className="text-xs block">{i18n.t('literals.lakcim')}</label>
                      <input
                        type="text"
                        className={fieldClass}
                        style={fieldStyle}
                        data-testid="actor-address-input"
                        value={actorAddress}
                        onChange={(e) => setActorAddress(e.target.value)}
                        placeholder="pl. 1234 Budapest, Fo utca 1."
                      />
                    </div>
                  </div>
                )}
                {/* V325 (Batch3-C): JOGI SZEMÉLY nevében jár el — legacy BLOKNYOM
                    jogi ág (JOGISZEMELY + UJTULAJOK). A pultnál álló személy
                    (megbízott) adatai a fenti ügyfél-mezőkben. */}
                <div className="flex items-center gap-4">
                  <label className="text-xs flex items-center gap-1.5">
                    <input
                      type="checkbox"
                      data-testid="legal-entity-checkbox"
                      checked={isLegalEntity}
                      onChange={(e) => setIsLegalEntity(e.target.checked)}
                    />
                    <span>{i18n.t('literals.jogi-szemely-neveben-jar-el')}</span>
                  </label>
                </div>
                {isLegalEntity && (
                  <div className="ml-4 p-2 rounded border border-indigo-400 dark:border-indigo-600 bg-indigo-100/50 dark:bg-indigo-900/30 space-y-2">
                    <div className="text-xs font-semibold text-indigo-900 dark:text-indigo-200">
                      {i18n.t('literals.jogi-szemely-adatai-pmt-8-9')}
                    </div>
                    <div>
                      <label className="text-xs block">
                        {i18n.t('literals.jogi-szemely-neve-2')}
                      </label>
                      <input
                        type="text"
                        className={fieldClass}
                        style={fieldStyle}
                        data-testid="legal-entity-name-input"
                        value={legalEntityName}
                        onChange={(e) => setLegalEntityName(e.target.value)}
                        placeholder="pl. Példa Kft."
                      />
                    </div>
                    <div>
                      <label className="text-xs block">{i18n.t('literals.szekhely-2')}</label>
                      <input
                        type="text"
                        className={fieldClass}
                        style={fieldStyle}
                        data-testid="legal-entity-seat-input"
                        value={legalEntitySeat}
                        onChange={(e) => setLegalEntitySeat(e.target.value)}
                        placeholder="pl. 6722 Szeged, Tisza L. krt 57."
                      />
                    </div>
                    <div className="grid grid-cols-2 gap-2">
                      <div>
                        <label className="text-xs block">{i18n.t('literals.adoszam')}</label>
                        <input
                          type="text"
                          className={`${fieldClass} font-mono`}
                          style={fieldStyle}
                          data-testid="legal-entity-tax-input"
                          value={legalEntityTaxNumber}
                          onChange={(e) => setLegalEntityTaxNumber(e.target.value)}
                          placeholder="12345678-2-06"
                        />
                      </div>
                      <div>
                        <label className="text-xs block">
                          {i18n.t('literals.okiratszam-cegjegyzekszam')}
                        </label>
                        <input
                          type="text"
                          className={`${fieldClass} font-mono`}
                          style={fieldStyle}
                          data-testid="legal-deed-number-input"
                          value={legalDeedNumber}
                          onChange={(e) => setLegalDeedNumber(e.target.value)}
                          placeholder="06-09-123456"
                        />
                      </div>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-semibold text-indigo-900 dark:text-indigo-200">
                        {i18n.t('literals.tenyleges-tulajdonosok-max-4')}
                      </span>
                      <button
                        type="button"
                        data-testid="add-owner-button"
                        disabled={beneficialOwners.length >= 4}
                        onClick={() => setBeneficialOwners((prev) => [...prev, { ...EMPTY_OWNER }])}
                        className="text-xs px-2 py-0.5 rounded border border-indigo-400 hover:bg-indigo-200/50 disabled:opacity-40"
                      >
                        {i18n.t('literals.tulajdonos')}
                      </button>
                    </div>
                    {beneficialOwners.map((o, idx) => {
                      const upd = (patch: Partial<BeneficialOwnerForm>) =>
                        setBeneficialOwners((prev) =>
                          prev.map((x, i) => (i === idx ? { ...x, ...patch } : x)),
                        )
                      return (
                        <div
                          key={idx}
                          className="p-2 rounded border border-indigo-300 dark:border-indigo-700 space-y-1.5"
                        >
                          <div className="flex items-center justify-between">
                            <span className="text-xs font-semibold">
                              {idx + 1}
                              {i18n.t('literals.tulajdonos-2')}
                            </span>
                            <button
                              type="button"
                              className="text-xs text-red-600 hover:underline"
                              onClick={() =>
                                setBeneficialOwners((prev) => prev.filter((_, i) => i !== idx))
                              }
                            >
                              {i18n.t('literals.eltavolitas')}
                            </button>
                          </div>
                          <div className="grid grid-cols-2 gap-2">
                            <div>
                              <label className="text-xs block">{i18n.t('literals.nev-2')}</label>
                              <input
                                type="text"
                                className={fieldClass}
                                style={fieldStyle}
                                value={o.name}
                                onChange={(e) => upd({ name: e.target.value })}
                              />
                            </div>
                            <div>
                              <label className="text-xs block">{i18n.t('literals.lakcim-2')}</label>
                              <input
                                type="text"
                                className={fieldClass}
                                style={fieldStyle}
                                value={o.address}
                                onChange={(e) => upd({ address: e.target.value })}
                              />
                            </div>
                            <div>
                              <label className="text-xs block">
                                {i18n.t('literals.szuletesi-hely-2')}
                              </label>
                              <input
                                type="text"
                                className={fieldClass}
                                style={fieldStyle}
                                value={o.birthPlace}
                                onChange={(e) => upd({ birthPlace: e.target.value })}
                              />
                            </div>
                            <div>
                              <label className="text-xs block">
                                {i18n.t('literals.szuletesi-ido-2')}
                              </label>
                              <input
                                type="date"
                                className={fieldClass}
                                style={fieldStyle}
                                value={o.birthDate}
                                onChange={(e) => upd({ birthDate: e.target.value })}
                              />
                            </div>
                            <div>
                              <label className="text-xs block">
                                {i18n.t('literals.allampolgarsag')}
                              </label>
                              <input
                                type="text"
                                className={fieldClass}
                                style={fieldStyle}
                                value={o.nationality}
                                onChange={(e) => upd({ nationality: e.target.value })}
                              />
                            </div>
                            <div>
                              <label className="text-xs block">
                                {i18n.t('literals.kulfoldi-tartozkodasi-hely')}
                              </label>
                              <input
                                type="text"
                                className={fieldClass}
                                style={fieldStyle}
                                value={o.residenceAbroad}
                                onChange={(e) => upd({ residenceAbroad: e.target.value })}
                              />
                            </div>
                            <div>
                              <label className="text-xs block">
                                {i18n.t('literals.erdekeltseg-jellege')}
                              </label>
                              <input
                                type="text"
                                className={fieldClass}
                                style={fieldStyle}
                                value={o.interestNature}
                                onChange={(e) => upd({ interestNature: e.target.value })}
                                placeholder="pl. tulajdonos"
                              />
                            </div>
                            <div>
                              <label className="text-xs block">
                                {i18n.t('literals.reszesedes-merteke')}
                              </label>
                              <input
                                type="text"
                                className={fieldClass}
                                style={fieldStyle}
                                value={o.interestExtent}
                                onChange={(e) => upd({ interestExtent: e.target.value })}
                                placeholder="pl. 50%"
                              />
                            </div>
                          </div>
                          <label className="text-xs flex items-center gap-1.5">
                            <input
                              type="checkbox"
                              checked={o.isPep}
                              onChange={(e) => upd({ isPep: e.target.checked })}
                            />
                            <span>{i18n.t('literals.kiemelt-kozszereplo')}</span>
                          </label>
                        </div>
                      )
                    })}
                  </div>
                )}
                <div>
                  <label className="text-xs block">{i18n.t('literals.penzeszkozok-forrasa')}</label>
                  <input
                    type="text"
                    className={fieldClass}
                    style={fieldStyle}
                    value={sourceOfFunds}
                    onChange={(e) => setSourceOfFunds(e.target.value)}
                    placeholder="pl. munkabér, megtakarítás, vállalkozási bevétel"
                  />
                </div>
                {/* AML 50M (Pmt./MNB 14/2025 V.2.5): 50M Ft feletti ügyletnél KÖTELEZŐ strukturált
                    forrás-dokumentum — közjegyző/ügyvéd ellenjegyzésű teljes bizonyító erejű magánokirat
                    VAGY max. 3 éves banki bizonylat (szlip). Két tanús magánnyilatkozat TILOS. */}
                {hufTotal >= 50_000_000 && (
                  <>
                    <div>
                      <label className="text-xs block">
                        {i18n.t('literals.forras-dokumentum-50m-felett-kotelezo')}
                      </label>
                      <select
                        className={fieldClass}
                        style={fieldStyle}
                        data-testid="source-of-funds-doctype"
                        value={sourceOfFundsDocType}
                        onChange={(e) => setSourceOfFundsDocType(e.target.value)}
                      >
                        <option value="">{i18n.t('literals.valassz-2')}</option>
                        <option value="MAGANOKIRAT_KOZJEGYZO">
                          {i18n.t('literals.kozjegyzo-altal-ellenjegyzett-maganokira')}
                        </option>
                        <option value="MAGANOKIRAT_UGYVED">
                          {i18n.t('literals.ugyved-altal-ellenjegyzett-maganokirat')}
                        </option>
                        <option value="BANK_SZLIP">
                          {i18n.t('literals.banki-bizonylat-szlip-max-3-eves')}
                        </option>
                      </select>
                    </div>
                    {sourceOfFundsDocType === 'BANK_SZLIP' && (
                      <div>
                        <label className="text-xs block">
                          {i18n.t('literals.banki-bizonylat-kiallitasi-datuma-max-3')}
                        </label>
                        <input
                          type="date"
                          className={fieldClass}
                          style={fieldStyle}
                          data-testid="source-of-funds-docdate"
                          value={sourceOfFundsDocDate}
                          onChange={(e) => setSourceOfFundsDocDate(e.target.value)}
                        />
                      </div>
                    )}
                  </>
                )}
              </div>
            )}

            <label className="flex items-start gap-2 rounded-md border border-slate-300 dark:border-slate-700 bg-white dark:bg-gray-900 px-2 py-2 text-xs text-slate-700 dark:text-slate-300">
              <input
                type="checkbox"
                className="mt-0.5"
                checked={privacyNoticeAccepted}
                onChange={(e) => setPrivacyNoticeAccepted(e.target.checked)}
                data-testid="customer-privacy-notice-checkbox"
              />
              <span>
                {i18n.t('literals.az-ugyfel-megkapta-az-adatkezelesi-tajek-2')}
                {PRIVACY_NOTICE_VERSION}
                {i18n.t('literals.lit-5')}
              </span>
            </label>

            <button
              onClick={() => void handleSaveManualCustomer()}
              disabled={isSaving}
              className={`w-full py-2 rounded-lg text-white font-semibold text-sm transition-all disabled:opacity-50 disabled:cursor-not-allowed ${
                isFormValid ? '' : 'bg-slate-400 opacity-70'
              }`}
              style={isFormValid ? { backgroundColor: 'var(--primary)' } : undefined}
              data-action="save-customer"
            >
              {isSaving ? 'Mentés...' : 'Ügyfél rögzítése'}
            </button>
            {!isFormValid && (
              <div
                className="text-xs text-amber-700 dark:text-amber-300 bg-amber-50 dark:bg-amber-950/30 border border-amber-300 dark:border-amber-700 rounded-md px-2 py-1.5 flex items-start gap-1.5"
                data-testid="customer-missing-fields-hint"
              >
                <AlertTriangle className="w-3.5 h-3.5 mt-0.5 shrink-0" />
                <span>
                  <strong>{i18n.t('literals.hianyzo-mezok')}</strong>{' '}
                  {missingRequiredFields.join(', ')}
                </span>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
