import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import {
  Building2,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  Globe,
  KeyRound,
  Loader2,
  RefreshCw,
  Rocket,
  Search,
  Server,
  ShieldCheck,
  Wifi,
  WifiOff,
  XCircle,
} from 'lucide-react'
import { publicApi, type GoogleConfigStatus } from '../../services/api/index'
import { humanizeError } from '../../utils/errorHandling'
import type { ElectronAppMode } from '../../types/appMode'
import { appModeLabel } from '../../utils/appModeRoles'
import i18n from '../../i18n'

// ---------------------------------------------------------------------------
// Típusok
// ---------------------------------------------------------------------------

export interface Branch {
  code: string
  name: string
  city: string
  address?: string
  /** v2.5.1-E B6: ÉRTÉKTÁRI fiók-e? Az ertektar módú telepítéskor kell. */
  isVault?: boolean
}

interface SetupWorkerOption {
  code: string
  name: string
}

interface SetupGoogleWorker {
  code: string
  name: string
  role?: string | null
  roles?: string[]
  validAppModes?: string[]
}

interface SetupGoogleBranch {
  code: string
  name: string
  city?: string
  address?: string
  isVault?: boolean
}

interface SetupGoogleIdentifyResponse {
  matchType: 'WORKER_EMAIL' | 'HQ_EMAIL' | 'BRANCH_SHARED_EMAIL'
  requiresWorkerSelection: boolean
  message?: string
  googleIdentity: {
    email: string
    googleSub: string
    name?: string | null
    picture?: string | null
  }
  branch?: SetupGoogleBranch | null
  worker?: SetupGoogleWorker | null
  workerOptions?: SetupGoogleWorker[]
  validAppModes?: string[]
  requestedAppModeAllowed?: boolean
}

export function isBranchSelectableForAppMode(
  branch: Branch | null | undefined,
  _appMode: ElectronAppMode,
): boolean {
  if (!branch) return false
  // Az ertektar vault-preferencia a filterBranchesForAppMode() fallback-jeben van.
  // canAdvance a branch step-nel ezt hasznalja — ha a filter megmutatta a branch-et,
  // akkor a user kivalaszthatta, tehat ervenyes. (Copilot #552 P1 finding fix)
  return true
}

export function filterBranchesForAppMode(branches: Branch[], appMode: ElectronAppMode): Branch[] {
  // Először mindig alkalmazzuk az alap szűrést (pl. inaktív/soft-deleted kizárása)
  const selectable = branches.filter((branch) => isBranchSelectableForAppMode(branch, appMode))
  if (appMode === 'ertektar') {
    // v2.5.2: Ha vannak is_vault=TRUE fióktelepek → csak azokat mutatjuk.
    // Ha EGYETLEN vault-branch sincs (admin még nem jelölte meg) → az összes
    // selectable branch-et visszaadjuk, hogy a telepítés ne akadjon el 0 találattal.
    const vaultOnly = selectable.filter((b) => b.isVault === true)
    if (vaultOnly.length > 0) return vaultOnly
    return selectable
  }
  return selectable
}

export function resolveSelectedWorkerForSetup(params: {
  offlineMode: boolean
  workerCode: string
  availableWorkers: SetupWorkerOption[]
}): SetupWorkerOption | null {
  if (params.offlineMode) return null
  const normalizedWorkerCode = params.workerCode.trim().toUpperCase()
  if (!normalizedWorkerCode) return null
  return (
    params.availableWorkers.find(
      (worker) => worker.code.trim().toUpperCase() === normalizedWorkerCode,
    ) ?? null
  )
}

export function buildConnectionTestResetKey(params: {
  apiUrl: string
  companyCode: string
  offlineMode: boolean
}): string {
  return [
    params.apiUrl.trim(),
    params.companyCode.trim().toUpperCase(),
    params.offlineMode ? 'offline' : 'online',
  ].join('\x1f')
}

type StepId = 'welcome' | 'branch' | 'program' | 'server' | 'admin'

interface StepDef {
  id: StepId
  title: string
  subtitle: string
  icon: typeof Rocket
}

// v2.5.1-E B6: program (penztar/ertektar) lépés a fiók-választás ELŐTT, hogy a
// SetupWizard csak az adott módnak megfelelő fiókokat ajánlja. Értéktár módban
// CSAK az is_vault=TRUE fiókok látsszanak.
const STEPS: readonly StepDef[] = [
  { id: 'welcome', title: 'Üdvözöljük', subtitle: 'A telepítés véghezvitele', icon: Rocket },
  {
    id: 'program',
    title: 'Program típus',
    subtitle: 'Milyen szerepben indul ez a gép',
    icon: Server,
  },
  {
    id: 'branch',
    title: 'Fiók kiválasztása',
    subtitle: 'Ezen a gépen dolgozó iroda',
    icon: Building2,
  },
  { id: 'server', title: 'Szerver kapcsolat', subtitle: 'Központi backend elérése', icon: Server },
  { id: 'admin', title: 'Admin jelszó', subtitle: 'Első belépéshez', icon: KeyRound },
]

// Produkciós központi backend (Hetzner CPX31, DNS: excvaluta.com (api. aldomain nem letezik)).
// Ha változik a hosting, csak itt cseréld — a wizard ezt használja default-nak
// és a helyettesítő szövegnek is. A felhasználó felülírhatja kézzel.
const DEFAULT_API_URL = 'https://excvaluta.com/api/v1'
const DEFAULT_COMPANY_CODE = 'EBC'

function normalizeApiBase(apiUrl: string): string {
  let normalized = apiUrl.trim().replace(/\/+$/, '')
  if (!normalized.endsWith('/api/v1')) {
    normalized = `${normalized}/api/v1`
  }
  return normalized
}

function branchFromGoogleSetup(branch: SetupGoogleBranch | null | undefined): Branch | null {
  if (!branch) return null
  return {
    code: branch.code,
    name: branch.name,
    city: branch.city ?? '',
    address: branch.address,
    isVault: branch.isVault,
  }
}

export function preferredAppModeFromGoogleSetup(
  response: SetupGoogleIdentifyResponse,
  fallback: ElectronAppMode,
): ElectronAppMode {
  const modes = response.validAppModes ?? response.worker?.validAppModes ?? []
  if (modes.includes(fallback)) return fallback
  if (modes.includes('rate-maker')) return 'rate-maker'
  if (modes.includes('ertektar')) return 'ertektar'
  return 'penztar'
}

function isCashierPasswordSetup(response: SetupGoogleIdentifyResponse | null): boolean {
  const roles = (response?.worker?.roles ?? [])
    .map((role) => role.trim().toLowerCase())
    .filter(Boolean)
  if (roles.length === 0 && response?.worker?.role) {
    roles.push(response.worker.role.trim().toLowerCase())
  }
  const cashierRole = roles.includes('penztar') || roles.includes('cashier')
  const nonCashierRole = roles.some((role) =>
    [
      'ertektar',
      'ertekszallito',
      'foertektar',
      'ugyvezeto',
      'irodavezeto',
      'belso_ellenor',
      'teruleti_vezeto',
      'biztonsagi_vezeto',
      'berszamfejto',
      'penzugyi_vezeto',
      'irodai_dolgozo',
      'csoportvezeto',
      'arfolyam_nezo',
      'manager',
      'supervisor',
      'admin',
    ].includes(role),
  )
  return cashierRole && !nonCashierRole
}

// ---------------------------------------------------------------------------
// SetupWizard
// ---------------------------------------------------------------------------

export default function SetupWizard() {
  const { t } = useTranslation()
  const [currentStep, setCurrentStep] = useState<StepId>('welcome')
  const currentIndex = STEPS.findIndex((s) => s.id === currentStep)

  // --- Adatállapotok ---
  const [branches, setBranches] = useState<Branch[]>([])
  const [branchSearch, setBranchSearch] = useState('')
  const [selectedBranch, setSelectedBranch] = useState<Branch | null>(null)
  const [branchPage, setBranchPage] = useState(0)

  const [apiUrl, setApiUrl] = useState(DEFAULT_API_URL)
  const [companyCode, setCompanyCode] = useState(DEFAULT_COMPANY_CODE)
  const [bootstrapUsername, setBootstrapUsername] = useState('')
  const [bootstrapPassword, setBootstrapPassword] = useState('')
  // F-001: admin által kiállított, egyszer használatos setup-token. Lezárt bootstrap utáni
  // teljes reset (null-hash) workernél a backend ezt kéri — enélkül a publikus endpointon
  // fiókátvétel lenne. Üres marad a kezdeti telepítéskor / seed-jelszavas workernél.
  const [setupToken, setSetupToken] = useState('')
  const [availableWorkers, setAvailableWorkers] = useState<SetupWorkerOption[]>([])
  const [googleIdToken, setGoogleIdToken] = useState<string | null>(null)
  const [googleSetup, setGoogleSetup] = useState<SetupGoogleIdentifyResponse | null>(null)
  const [googleSetupLoading, setGoogleSetupLoading] = useState(false)
  const [googleSetupError, setGoogleSetupError] = useState<string | null>(null)
  const [googleConfigStatus, setGoogleConfigStatus] = useState<GoogleConfigStatus | null>(null)
  const [googleConfigStatusLoading, setGoogleConfigStatusLoading] = useState(false)
  const [googleConfigStatusError, setGoogleConfigStatusError] = useState<string | null>(null)
  const [selectedSharedWorkerCode, setSelectedSharedWorkerCode] = useState('')
  const [offlineMode, setOfflineMode] = useState(false)
  const [appModeChoice, setAppModeChoice] = useState<ElectronAppMode>('penztar')
  const [connectionTest, setConnectionTest] = useState<{
    state: 'idle' | 'testing' | 'ok' | 'fail'
    message?: string
  }>({ state: 'idle' })
  const connectionTestResetKey = useMemo(
    () =>
      buildConnectionTestResetKey({
        apiUrl,
        companyCode,
        offlineMode,
      }),
    [apiUrl, companyCode, offlineMode],
  )
  const connectionTestResetKeyRef = useRef(connectionTestResetKey)
  const autoConnectionTestKeyRef = useRef<string | null>(null)

  const [adminUsername, setAdminUsername] = useState('')
  const [adminPassword, setAdminPassword] = useState('')
  const [adminPasswordConfirm, setAdminPasswordConfirm] = useState('')

  // v2.5.21 REGI ADOSSAG FIX: az `adminUsername` AUTOMATIKUSAN tukrozze a step 4-en
  // valasztott `bootstrapUsername`-et (azaz a tenyleges workerCode-ot). Igy NINCS
  // confusion a wizardban: a user a 4. lepesen valasztott pénztáros koddal +
  // az 5. lepesen beirt új jelszoval lép be a Penztar-ba. Korábban az `adminUsername`
  // alapertelmezett "admin" volt, és a user nem értette, hogy ez NEM az ő login-credential-je.
  useEffect(() => {
    setAdminUsername(bootstrapUsername.trim().toUpperCase())
  }, [bootstrapUsername])

  // --- Telepítés állapot ---
  const [isSaving, setIsSaving] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)

  // --- Iroda törzs betöltése ---
  // 2.1.1: a backend-driven branches lekérés megpróbálja a szervert, és
  // ha elérhető, a DB-ből vett valós branch-listát adja. Ha nem — pl. a
  // user még nem érte el a 3. lépést, offline, vagy a backend indul —,
  // a main process fallback-el a statikus DEFAULT_BRANCHES-re. Így a
  // wizard sosem akad el, és amint a user megadja a helyes URL + cégkódot,
  // a friss adat megjelenik (lásd reloadBranches hívást lejjebb).
  const prevCompanyCodeRef = useRef(companyCode)
  useEffect(() => {
    // Sourcery P2: companyCode valtozaskor toroljuk a regi (stale) branch-eket,
    // hogy ne a korabbi ceg irodai maradjanak lathatoan.
    if (prevCompanyCodeRef.current !== companyCode) {
      prevCompanyCodeRef.current = companyCode
      setBranches([])
      setSelectedBranch(null)
    }

    const load = async () => {
      if (window.electronAPI?.setupGetBranches) {
        try {
          const list = await window.electronAPI.setupGetBranches({
            apiUrl,
            companyCode,
          })
          if (Array.isArray(list) && list.length > 0) {
            setBranches(list)
          }
        } catch {
          // Transiens hiba eseten NE toroljuk a korabban betoltott branch-eket
        }
      } else {
        // v2.1.4: Web mode (no Electron) — direct HTTP fetch via publicApi
        try {
          const list = await publicApi.getBranchesByCompany(companyCode)
          if (Array.isArray(list) && list.length > 0) {
            setBranches(
              list.map((b) => ({
                code: b.code,
                name: b.name,
                city: b.city ?? '',
                address: b.address,
                isVault: b.isVault,
              })),
            )
          }
        } catch {
          // Transiens hiba eseten NE toroljuk a korabban betoltott branch-eket
        }
      }
    }
    void load()
  }, [apiUrl, companyCode])

  // --- Iroda lista szűrés ---
  // v2.5.1-E B6: értéktár módú telepítéskor csak az is_vault=TRUE fiókokat
  // engedjük kiválasztani — különben a felhasználó tévedésből pénztárt
  // választhatna értéktárhoz, és a területi szűrés is rosszul mutatna.
  const filteredBranches = useMemo(() => {
    const list = filterBranchesForAppMode(branches, appModeChoice)
    const q = branchSearch.trim().toLowerCase()
    if (!q) return list
    return list.filter(
      (b) =>
        b.code.toLowerCase().includes(q) ||
        b.name.toLowerCase().includes(q) ||
        b.city.toLowerCase().includes(q),
    )
  }, [branches, branchSearch, appModeChoice])

  const pageSize = 16 // 2×8 rács
  const totalPages = Math.max(1, Math.ceil(filteredBranches.length / pageSize))
  const clampedPage = Math.min(branchPage, totalPages - 1)
  const pageBranches = filteredBranches.slice(
    clampedPage * pageSize,
    clampedPage * pageSize + pageSize,
  )

  useEffect(() => {
    setBranchPage(0)
  }, [branchSearch, appModeChoice])

  useEffect(() => {
    if (selectedBranch && !isBranchSelectableForAppMode(selectedBranch, appModeChoice)) {
      setSelectedBranch(null)
    }
  }, [appModeChoice, selectedBranch])

  const postSetupGoogleIdentify = useCallback(
    async (payload: {
      idToken: string
      selectedWorkerCode?: string
      bindGoogleSubject?: boolean
    }): Promise<SetupGoogleIdentifyResponse> => {
      const apiBase = normalizeApiBase(apiUrl)
      const request = {
        idToken: payload.idToken,
        companyCode: companyCode.trim(),
        appMode: appModeChoice,
        selectedWorkerCode: payload.selectedWorkerCode,
        bindGoogleSubject: payload.bindGoogleSubject === true,
      }
      // Idempotency-Key: a google-identify ugyanazzal az id_token-nel termeszetszeruleg idempotens
      // (ugyanazt a dolgozot azonositja / ugyanazt a subjectet koti). A kulcs jelzi az api-proxy-nak,
      // hogy ez a POST retry-biztos (ESET-MITM reset ellen ujraprobalhato, duplikacio-kockazat nelkul).
      const idempotencyKey = crypto.randomUUID()

      if (window.electronAPI?.apiRequest) {
        const url = `${apiBase}/public/setup/google-identify`
        const result = await window.electronAPI.apiRequest({
          method: 'POST',
          url,
          headers: {
            'Content-Type': 'application/json',
            Accept: 'application/json',
            'Idempotency-Key': idempotencyKey,
          },
          body: JSON.stringify(request),
          timeoutMs: 15000,
        })
        const parsed = result.body
          ? (JSON.parse(result.body) as SetupGoogleIdentifyResponse & {
              message?: string
              error?: string
            })
          : null
        if (!result.ok || !parsed) {
          const reason = parsed?.message || parsed?.error
          // status 0 = az api-proxy hálózati szintű hibát adott vissza (nincs HTTP válasz).
          // A nem-informatikus kollégának értelmezhető, actionable üzenet kell — NEM "HTTP 0".
          if (result.status === 0) {
            throw new Error(
              'Nem sikerült csatlakozni a szerverhez (hálózati hiba). Gyakori ok: a vírusirtó ' +
                '(pl. ESET) blokkolja a biztonságos kapcsolatot, vagy nincs internet. ' +
                (reason ? `Részletek: ${reason}` : ''),
            )
          }
          throw new Error(reason || `HTTP ${result.status}`)
        }
        return parsed
      }

      return publicApi.identifyGoogleSetup(request, { apiBase, idempotencyKey })
    },
    [apiUrl, appModeChoice, companyCode],
  )

  useEffect(() => {
    let cancelled = false
    const loadGoogleConfigStatus = async () => {
      try {
        setGoogleConfigStatusLoading(true)
        setGoogleConfigStatusError(null)
        const status = await publicApi.getGoogleConfigStatus(normalizeApiBase(apiUrl))
        if (!cancelled) setGoogleConfigStatus(status)
      } catch (err: unknown) {
        if (!cancelled) {
          setGoogleConfigStatus(null)
          setGoogleConfigStatusError(humanizeError(err))
        }
      } finally {
        if (!cancelled) setGoogleConfigStatusLoading(false)
      }
    }
    void loadGoogleConfigStatus()
    return () => {
      cancelled = true
    }
  }, [apiUrl])

  const applyGoogleSetup = useCallback(
    (response: SetupGoogleIdentifyResponse) => {
      setGoogleSetup(response)
      setGoogleSetupError(null)
      const branch = branchFromGoogleSetup(response.branch)
      if (branch) {
        setSelectedBranch(branch)
        setBranches((existing) =>
          existing.some((item) => item.code === branch.code) ? existing : [branch, ...existing],
        )
      }
      if (response.workerOptions && response.workerOptions.length > 0) {
        setAvailableWorkers(
          response.workerOptions.map((worker) => ({
            code: worker.code,
            name: worker.name,
          })),
        )
      }
      if (response.worker) {
        setBootstrapUsername(response.worker.code)
        setAdminUsername(response.worker.code)
        setAvailableWorkers((existing) =>
          existing.some((worker) => worker.code === response.worker?.code)
            ? existing
            : [{ code: response.worker!.code, name: response.worker!.name }, ...existing],
        )
        if (!isCashierPasswordSetup(response)) {
          setAdminPassword('')
          setAdminPasswordConfirm('')
          setBootstrapPassword('')
        }
        setCurrentStep('server')
      }
      setAppModeChoice(preferredAppModeFromGoogleSetup(response, appModeChoice))
    },
    [appModeChoice],
  )

  const handleGoogleSetupLogin = useCallback(async () => {
    setGoogleSetupLoading(true)
    setGoogleSetupError(null)
    try {
      if (!window.electronAPI?.googleOAuthFlow) {
        throw new Error('A Google OAuth csak az Electron telepítőben érhető el.')
      }
      const oauth = await window.electronAPI.googleOAuthFlow()
      if (!oauth.ok) {
        throw new Error(oauth.message)
      }
      setGoogleIdToken(oauth.idToken)
      const response = await postSetupGoogleIdentify({ idToken: oauth.idToken })
      applyGoogleSetup(response)
    } catch (err: unknown) {
      setGoogleSetupError(humanizeError(err))
    } finally {
      setGoogleSetupLoading(false)
    }
  }, [applyGoogleSetup, postSetupGoogleIdentify])

  // ESET-MITM reset után: ha az OAuth már sikerült (van id_token), CSAK a backend-azonosítást
  // ismételjük (nincs újabb Google-popup). Ha még nincs token, a teljes login fut újra.
  const handleRetryGoogleIdentify = useCallback(async () => {
    if (!googleIdToken) {
      await handleGoogleSetupLogin()
      return
    }
    setGoogleSetupLoading(true)
    setGoogleSetupError(null)
    try {
      const response = await postSetupGoogleIdentify({ idToken: googleIdToken })
      applyGoogleSetup(response)
    } catch (err: unknown) {
      setGoogleSetupError(humanizeError(err))
    } finally {
      setGoogleSetupLoading(false)
    }
  }, [googleIdToken, handleGoogleSetupLogin, postSetupGoogleIdentify, applyGoogleSetup])

  const handleSharedWorkerConfirm = useCallback(async () => {
    if (!googleIdToken || !selectedSharedWorkerCode.trim()) return
    setGoogleSetupLoading(true)
    setGoogleSetupError(null)
    try {
      const response = await postSetupGoogleIdentify({
        idToken: googleIdToken,
        selectedWorkerCode: selectedSharedWorkerCode.trim(),
      })
      applyGoogleSetup(response)
    } catch (err: unknown) {
      setGoogleSetupError(humanizeError(err))
    } finally {
      setGoogleSetupLoading(false)
    }
  }, [applyGoogleSetup, googleIdToken, postSetupGoogleIdentify, selectedSharedWorkerCode])

  useEffect(() => {
    connectionTestResetKeyRef.current = connectionTestResetKey
    autoConnectionTestKeyRef.current = null
    setConnectionTest({ state: 'idle' })
  }, [connectionTestResetKey])

  const isCurrentConnectionTestRequest = useCallback(
    (requestKey: string) => connectionTestResetKeyRef.current === requestKey,
    [],
  )

  const googlePasswordSetupRequired = isCashierPasswordSetup(googleSetup)
  const googleAuthSetupReady = Boolean(googleSetup?.worker && !googlePasswordSetupRequired)

  // --- Lépés-validáció: engedélyezett-e a tovább ---
  const canAdvance = useMemo(() => {
    switch (currentStep) {
      case 'welcome':
        return true
      case 'branch':
        return isBranchSelectableForAppMode(selectedBranch, appModeChoice)
      case 'program':
        return !!appModeChoice
      case 'server':
        if (offlineMode) return true
        return connectionTest.state === 'ok'
      case 'admin':
        if (googleAuthSetupReady) return true
        return (
          adminPassword.length >= 8 &&
          adminPassword === adminPasswordConfirm &&
          adminUsername.length > 0
        )
      default:
        return false
    }
  }, [
    currentStep,
    selectedBranch,
    offlineMode,
    connectionTest.state,
    googleAuthSetupReady,
    adminPassword,
    adminPasswordConfirm,
    adminUsername,
    appModeChoice,
  ])

  // --- v2.5.41: Auto connection test a server step belepeskor ---
  // AUTOMATIKUSAN fut a bootstrap-status teszt amikor a user a server step-re lep.
  // Nem fugg a penztaros-kivalasztastol — csak apiUrl + companyCode kell.
  // A "Kapcsolat tesztelese" gomb kezi retry-hoz marad.
  useEffect(() => {
    if (currentStep !== 'server' || offlineMode) return
    if (!apiUrl.trim() || !companyCode.trim()) return
    if (autoConnectionTestKeyRef.current === connectionTestResetKey) return
    autoConnectionTestKeyRef.current = connectionTestResetKey
    const requestKey = connectionTestResetKey
    setConnectionTest({ state: 'testing' })
    if (window.electronAPI?.setupTestConnection) {
      window.electronAPI
        .setupTestConnection({
          apiUrl: apiUrl.trim(),
          companyCode: companyCode.trim(),
          username: '',
          password: '',
        })
        .then((result) => {
          if (!isCurrentConnectionTestRequest(requestKey)) return
          if (result.success) {
            setConnectionTest({
              state: 'ok',
              message: `Kapcsolódva (HTTP ${result.httpStatus ?? '?'}${
                result.latencyMs !== undefined ? `, ${result.latencyMs} ms` : ''
              })`,
            })
          } else {
            setConnectionTest({ state: 'fail', message: result.errorMessage || 'Ismeretlen hiba.' })
          }
        })
        .catch((err: unknown) => {
          if (!isCurrentConnectionTestRequest(requestKey)) return
          setConnectionTest({ state: 'fail', message: humanizeError(err) })
        })
      return
    }
    const normalized = apiUrl
      .trim()
      .replace(/\/+$/, '')
      .replace(/\/api\/v1$/, '')
    const url = `${normalized}/api/v1/auth/bootstrap-status`
    const started = performance.now()
    fetch(url, { method: 'GET' })
      .then((resp) => {
        if (!isCurrentConnectionTestRequest(requestKey)) return
        const latency = Math.round(performance.now() - started)
        if (resp.ok) {
          setConnectionTest({
            state: 'ok',
            message: `Kapcsolódva (HTTP ${resp.status}, ${latency} ms)`,
          })
        } else {
          setConnectionTest({ state: 'fail', message: `Szerver hiba: HTTP ${resp.status}` })
        }
      })
      .catch((err: unknown) => {
        if (!isCurrentConnectionTestRequest(requestKey)) return
        setConnectionTest({ state: 'fail', message: humanizeError(err) })
      })
  }, [
    currentStep,
    apiUrl,
    companyCode,
    offlineMode,
    connectionTestResetKey,
    isCurrentConnectionTestRequest,
  ])

  // --- Kapcsolat teszt (kezi, retry gombnak) ---
  const runConnectionTest = useCallback(async () => {
    const requestKey = connectionTestResetKey
    connectionTestResetKeyRef.current = requestKey
    setConnectionTest({ state: 'testing' })
    const started = performance.now()
    try {
      if (window.electronAPI?.setupTestConnection) {
        const result = await window.electronAPI.setupTestConnection({
          apiUrl: apiUrl.trim(),
          companyCode: companyCode.trim(),
          username: bootstrapUsername.trim(),
          password: bootstrapPassword,
        })
        if (!isCurrentConnectionTestRequest(requestKey)) return
        if (result.success) {
          setConnectionTest({
            state: 'ok',
            message: `Sikeres (HTTP ${result.httpStatus ?? '?'}${
              result.latencyMs !== undefined ? `, ${result.latencyMs} ms` : ''
            })`,
          })
        } else {
          setConnectionTest({ state: 'fail', message: result.errorMessage || 'Ismeretlen hiba.' })
        }
        return
      }
      const normalized = apiUrl
        .trim()
        .replace(/\/+$/, '')
        .replace(/\/api\/v1$/, '')
      const url = `${normalized}/api/v1/auth/bootstrap-status`
      const resp = await fetch(url, { method: 'GET' })
      if (!isCurrentConnectionTestRequest(requestKey)) return
      const latency = Math.round(performance.now() - started)
      if (resp.ok) {
        setConnectionTest({ state: 'ok', message: `Sikeres (HTTP ${resp.status}, ${latency} ms)` })
      } else {
        setConnectionTest({ state: 'fail', message: `Szerver hiba: HTTP ${resp.status}` })
      }
    } catch (err: unknown) {
      if (!isCurrentConnectionTestRequest(requestKey)) return
      setConnectionTest({ state: 'fail', message: humanizeError(err) })
    }
  }, [
    apiUrl,
    companyCode,
    bootstrapUsername,
    bootstrapPassword,
    connectionTestResetKey,
    isCurrentConnectionTestRequest,
  ])

  // --- Telepítés befejezése ---
  const handleFinish = async () => {
    if (!selectedBranch) return
    setIsSaving(true)
    setSaveError(null)
    try {
      let finalizedGoogleSetup = googleSetup
      if (googleAuthSetupReady) {
        if (!googleIdToken || !googleSetup?.worker) {
          setSaveError('A Google azonosítás nem véglegesíthető. Jelentkezzen be újra Google-lel.')
          setIsSaving(false)
          return
        }
        finalizedGoogleSetup = await postSetupGoogleIdentify({
          idToken: googleIdToken,
          selectedWorkerCode: googleSetup.worker.code,
          bindGoogleSubject: true,
        })
        applyGoogleSetup(finalizedGoogleSetup)
      }
      if (window.electronAPI?.setupSave) {
        // v2.3.0: kereses a worker listaban a kivalasztott dolgozo neve + role szerint
        // A ServerStep-bol a bootstrapUsername = a workerCode (pl. BORSI).
        // A workerList elemeiben a name megvan. A role nincs a public endpoint-on,
        // de az optional; a backend /first-time-worker-setup visszaadja.
        const selectedWorker = resolveSelectedWorkerForSetup({
          offlineMode,
          workerCode: bootstrapUsername,
          availableWorkers,
        })
        const result = await window.electronAPI.setupSave({
          branchCode: selectedBranch.code,
          branchName: selectedBranch.name,
          apiUrl: apiUrl.trim(),
          companyCode: companyCode.trim(),
          authMode: googleAuthSetupReady ? 'google' : 'password',
          adminUsername: googleAuthSetupReady
            ? (finalizedGoogleSetup?.worker?.code ?? bootstrapUsername).trim()
            : adminUsername.trim(),
          adminPassword: googleAuthSetupReady ? '' : adminPassword,
          bootstrapUsername: googleAuthSetupReady
            ? (finalizedGoogleSetup?.worker?.code ?? bootstrapUsername).trim()
            : bootstrapUsername.trim(),
          bootstrapPassword: googleAuthSetupReady ? '' : bootstrapPassword,
          offlineMode,
          appMode: appModeChoice,
          ...(googleAuthSetupReady && finalizedGoogleSetup?.googleIdentity
            ? {
                googleEmail: finalizedGoogleSetup.googleIdentity.email,
                googleSub: finalizedGoogleSetup.googleIdentity.googleSub,
                googleName: finalizedGoogleSetup.googleIdentity.name ?? undefined,
                googlePicture: finalizedGoogleSetup.googleIdentity.picture ?? undefined,
              }
            : {}),
          // v2.3.0: worker identity atadasa az electron-nak ha van kivalasztott dolgozo
          ...(googleAuthSetupReady && finalizedGoogleSetup?.worker
            ? {
                selectedWorkerCode: finalizedGoogleSetup.worker.code.trim().toUpperCase(),
                selectedWorkerName: finalizedGoogleSetup.worker.name,
                selectedWorkerRole:
                  finalizedGoogleSetup.worker.roles?.[0] ??
                  finalizedGoogleSetup.worker.role ??
                  undefined,
              }
            : selectedWorker
              ? {
                  selectedWorkerCode: selectedWorker.code.trim().toUpperCase(),
                  selectedWorkerName: selectedWorker.name,
                }
              : {}),
        })
        if (!result.success) {
          setSaveError(
            result.errorMessage ||
              'Ismeretlen hiba a telepítés során. Ellenőrizze a szerver kapcsolatot.',
          )
          setIsSaving(false)
        }
        return
      }
      const normalized = apiUrl
        .trim()
        .replace(/\/+$/, '')
        .replace(/\/api\/v1$/, '')

      if (googleAuthSetupReady && finalizedGoogleSetup?.worker) {
        localStorage.setItem(
          'valuta-setup-config',
          JSON.stringify({
            branchCode: selectedBranch.code,
            branchName: selectedBranch.name,
            apiUrl: apiUrl.trim(),
            companyCode: companyCode.trim(),
            appMode: appModeChoice,
            authMode: 'google',
            googleEmail: finalizedGoogleSetup.googleIdentity.email,
            googleSub: finalizedGoogleSetup.googleIdentity.googleSub,
            workerCode: finalizedGoogleSetup.worker.code,
            workerName: finalizedGoogleSetup.worker.name,
            workerRole: finalizedGoogleSetup.worker.roles?.[0] ?? finalizedGoogleSetup.worker.role,
            installedAt: new Date().toISOString(),
          }),
        )
        window.location.href = '/login'
        return
      }

      // Eldontes: csak akkor megyunk worker-first-time setup uton, ha a kod
      // a szerverrol betoltott worker-listaban szerepel. Igy a wizardban beallitott
      // jelszo a letezo worker globalis jelszava lesz, kezzel beirt admin kodnal
      // pedig megmarad a regi bootstrap-admin flow.
      const selectedWorkerCode = bootstrapUsername.trim().toUpperCase()
      const selectedWorker = resolveSelectedWorkerForSetup({
        offlineMode,
        workerCode: selectedWorkerCode,
        availableWorkers,
      })
      let bootstrapCompleted = false
      try {
        const statusResp = await fetch(`${normalized}/api/v1/auth/bootstrap-status`, {
          method: 'GET',
          credentials: 'include',
        })
        const statusBody = await statusResp.json().catch(() => ({}) as { completed?: boolean })
        bootstrapCompleted = statusBody.completed === true
      } catch {
        bootstrapCompleted = false
      }
      const useWorkerSetup =
        selectedWorker !== null || (bootstrapCompleted && selectedWorkerCode.trim().length > 0)
      let workerIdentity: {
        workerCode: string
        workerName?: string
        workerRole?: string
        branchCode?: string
      } | null = null

      if (useWorkerSetup) {
        const setupUrl = `${normalized}/api/v1/auth/first-time-worker-setup`
        const setupResp = await fetch(setupUrl, {
          method: 'POST',
          credentials: 'include',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            companyCode: companyCode.trim(),
            workerCode: selectedWorkerCode,
            newPassword: adminPassword,
            currentPassword: bootstrapPassword || undefined,
            setupToken: setupToken.trim() || undefined,
            appMode: appModeChoice,
          }),
        })
        if (!setupResp.ok) {
          const body = await setupResp.json().catch(() => ({}) as Record<string, unknown>)
          const msg = (body as { message?: string }).message || `HTTP ${setupResp.status}`
          setSaveError(`A dolgozói jelszó beállítása nem sikerült: ${msg}`)
          setIsSaving(false)
          return
        }
        const setupBody = await setupResp.json().catch(() => ({}))
        workerIdentity = {
          workerCode: setupBody.workerCode || selectedWorkerCode,
          workerName: setupBody.workerName || selectedWorker?.name,
          workerRole: setupBody.workerRole,
          branchCode: setupBody.branchCode,
        }
      } else {
        const bootstrapUrl = `${normalized}/api/v1/auth/bootstrap-admin`
        const resp = await fetch(bootstrapUrl, {
          method: 'POST',
          credentials: 'include',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            companyCode: companyCode.trim(),
            workerCode: adminUsername.trim().toUpperCase(),
            workerName: 'Rendszer Admin',
            email: '',
            newPassword: adminPassword,
          }),
        })
        if (!resp.ok) {
          const body = await resp.json().catch(() => ({}) as Record<string, unknown>)
          const msg = (body as { message?: string }).message || `HTTP ${resp.status}`
          if (resp.status !== 400 || !msg.toLowerCase().includes('lezajlott')) {
            setSaveError(`Admin létrehozási hiba: ${msg}`)
            setIsSaving(false)
            return
          }
        }
        workerIdentity = {
          workerCode: adminUsername.trim().toUpperCase(),
          workerName: 'Rendszer Admin',
          workerRole: 'ADMIN',
        }
      }

      localStorage.setItem(
        'valuta-setup-config',
        JSON.stringify({
          branchCode: selectedBranch.code,
          branchName: selectedBranch.name,
          apiUrl: apiUrl.trim(),
          companyCode: companyCode.trim(),
          appMode: appModeChoice,
          workerCode: workerIdentity?.workerCode,
          workerName: workerIdentity?.workerName,
          workerRole: workerIdentity?.workerRole,
          installedAt: new Date().toISOString(),
        }),
      )
      window.location.href = '/login'
    } catch (err: unknown) {
      setSaveError(humanizeError(err))
      setIsSaving(false)
    }
  }

  // --- Lépés navigáció ---
  const goNext = () => {
    if (!canAdvance) return
    if (
      googleSetup?.worker &&
      (currentStep === 'welcome' || currentStep === 'program' || currentStep === 'branch')
    ) {
      setCurrentStep('server')
      return
    }
    const next = STEPS[currentIndex + 1]
    if (next) setCurrentStep(next.id)
  }
  const goPrev = () => {
    const prev = STEPS[currentIndex - 1]
    if (prev) setCurrentStep(prev.id)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-100 via-slate-50 to-slate-100 flex items-center justify-center p-4">
      <div className="w-full max-w-3xl max-h-[98vh] bg-white rounded-2xl shadow-xl overflow-hidden flex flex-col">
        {/* Fejléc + progress */}
        <div className="shrink-0">
          <SetupHeader currentIndex={currentIndex} />
        </div>

        {/* Tartalom — scroll-os, hogy a nav footer mindig lathato maradjon */}
        <div className="flex-1 overflow-y-auto px-10 py-8">
          {currentStep === 'welcome' && (
            <WelcomeStep
              googleSetup={googleSetup}
              googleSetupLoading={googleSetupLoading}
              googleSetupError={googleSetupError}
              googleConfigStatus={googleConfigStatus}
              googleConfigStatusLoading={googleConfigStatusLoading}
              googleConfigStatusError={googleConfigStatusError}
              selectedSharedWorkerCode={selectedSharedWorkerCode}
              onSelectedSharedWorkerCodeChange={setSelectedSharedWorkerCode}
              onGoogleLogin={handleGoogleSetupLogin}
              onRetryGoogleIdentify={handleRetryGoogleIdentify}
              onSharedWorkerConfirm={handleSharedWorkerConfirm}
            />
          )}
          {currentStep === 'branch' && (
            <BranchStep
              branches={pageBranches}
              totalFiltered={filteredBranches.length}
              page={clampedPage}
              totalPages={totalPages}
              onPageChange={setBranchPage}
              search={branchSearch}
              onSearchChange={setBranchSearch}
              selected={selectedBranch}
              onSelect={setSelectedBranch}
            />
          )}
          {currentStep === 'program' && (
            <div>
              <h2 className="text-xl font-bold text-slate-800 mb-2">
                {t('setup.programTipusKivalasztasa')}
              </h2>
              <p className="text-sm text-slate-600 mb-6">
                {t(
                  'setup.mitFuttatEzAGepEzHatarozzaMegMilyenMenupontokJelennekMegEsHogyKiTudBejelentkezni',
                )}
                {t('setup.aValasztasATelepitesUtanIsModosithatoABeallitasokban')}
              </p>
              <div className="space-y-3">
                {[
                  {
                    id: 'penztar' as const,
                    title: 'Valutaváltó Pénztár',
                    desc: 'Pénztárosi munka: valuta vétel / eladás / konverzió, napnyitás, napzárás, ügyfélkezelés, címletezés. Local-first.',
                  },
                  {
                    id: 'ertektar' as const,
                    title: 'Értéktár',
                    desc: 'Értéktáros munka: pénztárak ellátása / átadás-átvétel bank és más értéktárak felé, napi + havi + dekádzárás. Local-first.',
                  },
                  {
                    id: 'rate-maker' as const,
                    title: 'Árfolyamkészítő',
                    desc: 'Főértéktárosi árfolyamkészítés: helyi Electron alkalmazásból publikálás a központi szerveren keresztül.',
                  },
                ].map((opt) => (
                  <button
                    key={opt.id}
                    type="button"
                    onClick={() => setAppModeChoice(opt.id)}
                    className={`w-full text-left p-4 border-2 rounded-lg transition ${appModeChoice === opt.id ? 'border-blue-500 bg-blue-50' : 'border-slate-200 hover:border-slate-300'}`}
                  >
                    <div className="font-bold text-slate-800 mb-1">{opt.title}</div>
                    <div className="text-sm text-slate-600">{opt.desc}</div>
                  </button>
                ))}
              </div>
              <p className="mt-4 text-xs text-slate-500">
                {t(
                  'setup.aBejelentkezettDolgozoMunkakoreAlapjanASzerverEllenorziHogyJogosultEErreAProgramTipusra',
                )}
                {t('setup.haNemHibauzenetetKapALoginNal')}
              </p>
            </div>
          )}
          {currentStep === 'server' && (
            <ServerStep
              apiUrl={apiUrl}
              onApiUrlChange={setApiUrl}
              companyCode={companyCode}
              onCompanyCodeChange={setCompanyCode}
              bootstrapUsername={bootstrapUsername}
              onBootstrapUsernameChange={setBootstrapUsername}
              offlineMode={offlineMode}
              onOfflineModeChange={setOfflineMode}
              connectionTest={connectionTest}
              onTestConnection={runConnectionTest}
              selectedBranchCode={selectedBranch?.code ?? null}
              onWorkerListChange={setAvailableWorkers}
              appMode={appModeChoice}
              googleAuthSetupReady={googleAuthSetupReady}
              googleSetupWorker={
                googleSetup?.worker
                  ? { code: googleSetup.worker.code ?? '', name: googleSetup.worker.name ?? '' }
                  : null
              }
            />
          )}
          {currentStep === 'admin' && googleAuthSetupReady && googleSetup?.worker ? (
            <GoogleAdminStep
              googleSetup={googleSetup}
              selectedBranch={selectedBranch}
              appMode={appModeChoice}
            />
          ) : (
            currentStep === 'admin' && (
              <AdminStep
                adminUsername={adminUsername}
                onAdminUsernameChange={setAdminUsername}
                adminPassword={adminPassword}
                onAdminPasswordChange={setAdminPassword}
                adminPasswordConfirm={adminPasswordConfirm}
                onAdminPasswordConfirmChange={setAdminPasswordConfirm}
                bootstrapPassword={bootstrapPassword}
                onBootstrapPasswordChange={setBootstrapPassword}
                selectedBranch={selectedBranch}
                apiUrl={apiUrl}
                companyCode={companyCode}
                offlineMode={offlineMode}
                setupToken={setupToken}
                onSetupTokenChange={setSetupToken}
              />
            )
          )}
        </div>

        {/* Láb: navigációs gombok — shrink-0, hogy sose tunjon el a footer */}
        <div className="shrink-0 px-10 py-5 border-t border-slate-200 bg-slate-50 flex items-center justify-between">
          <button
            type="button"
            onClick={goPrev}
            disabled={currentIndex === 0 || isSaving}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-slate-300 bg-white text-slate-700 hover:bg-slate-100 disabled:opacity-50 disabled:cursor-not-allowed transition"
          >
            <ChevronLeft className="w-4 h-4" />
            {t('common.back')}
          </button>

          <div className="text-sm text-slate-500">
            {t('setup.lepes')} {currentIndex + 1}
            {i18n.t('literals.lit-10')}
            {STEPS.length}
          </div>

          {currentIndex < STEPS.length - 1 ? (
            <button
              type="button"
              onClick={goNext}
              disabled={!canAdvance || isSaving}
              className="inline-flex items-center gap-2 px-5 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700 disabled:bg-slate-300 disabled:cursor-not-allowed transition"
            >
              {t('common.next')}
              <ChevronRight className="w-4 h-4" />
            </button>
          ) : (
            <button
              type="button"
              onClick={handleFinish}
              disabled={!canAdvance || isSaving}
              className="inline-flex items-center gap-2 px-5 py-2 rounded-lg bg-green-600 text-white hover:bg-green-700 disabled:bg-slate-300 disabled:cursor-not-allowed transition"
            >
              {isSaving ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  {i18n.t('literals.telepites')}
                </>
              ) : (
                <>
                  <Rocket className="w-4 h-4" />
                  {t('setup.telepitesBefejezese')}
                </>
              )}
            </button>
          )}
        </div>

        {saveError && (
          <div className="mx-10 mb-6 p-3 rounded-lg bg-red-50 border border-red-200 text-red-700 text-sm flex items-start gap-2">
            <XCircle className="w-5 h-5 flex-shrink-0 mt-0.5" />
            <span>{saveError}</span>
          </div>
        )}
      </div>
    </div>
  )
}

// ---------------------------------------------------------------------------
// Header + progress
// ---------------------------------------------------------------------------

function SetupHeader({ currentIndex }: { currentIndex: number }) {
  const { t } = useTranslation()
  return (
    <div className="px-10 py-6 bg-gradient-to-r from-blue-600 to-indigo-700 text-white">
      <div className="flex items-center gap-3 mb-5">
        <ShieldCheck className="w-7 h-7" />
        <div>
          <h1 className="text-xl font-semibold">{t('setup.valutaPenztarElsoInditas')}</h1>
          <p className="text-xs text-blue-100">{t('setup.aTelepites4LepesbenElkeszul')}</p>
        </div>
      </div>

      <ol className="flex items-center gap-2">
        {STEPS.map((step, idx) => {
          const done = idx < currentIndex
          const active = idx === currentIndex
          return (
            <li key={step.id} className="flex-1 flex items-center gap-2">
              <div
                className={[
                  'flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center text-sm font-semibold',
                  done
                    ? 'bg-green-500 text-white'
                    : active
                      ? 'bg-white text-blue-700'
                      : 'bg-blue-800/50 text-blue-100',
                ].join(' ')}
              >
                {done ? <CheckCircle2 className="w-5 h-5" /> : idx + 1}
              </div>
              <div className="hidden sm:block min-w-0">
                <div
                  className={[
                    'text-xs font-medium truncate',
                    active ? 'text-white' : 'text-blue-100',
                  ].join(' ')}
                >
                  {step.title}
                </div>
              </div>
              {idx < STEPS.length - 1 && (
                <div
                  className={['flex-1 h-0.5', done ? 'bg-green-500' : 'bg-blue-800/50'].join(' ')}
                />
              )}
            </li>
          )
        })}
      </ol>
    </div>
  )
}

// ---------------------------------------------------------------------------
// 1. Üdvözlő lépés
// ---------------------------------------------------------------------------

function WelcomeStep(props: {
  googleSetup: SetupGoogleIdentifyResponse | null
  googleSetupLoading: boolean
  googleSetupError: string | null
  googleConfigStatus: GoogleConfigStatus | null
  googleConfigStatusLoading: boolean
  googleConfigStatusError: string | null
  selectedSharedWorkerCode: string
  onSelectedSharedWorkerCodeChange: (value: string) => void
  onGoogleLogin: () => void
  onRetryGoogleIdentify: () => void
  onSharedWorkerConfirm: () => void
}) {
  const {
    googleSetup,
    googleSetupLoading,
    googleSetupError,
    googleConfigStatus,
    googleConfigStatusLoading,
    googleConfigStatusError,
    selectedSharedWorkerCode,
    onSelectedSharedWorkerCodeChange,
    onGoogleLogin,
    onRetryGoogleIdentify,
    onSharedWorkerConfirm,
  } = props
  const sharedWorkerOptions = googleSetup?.requiresWorkerSelection
    ? (googleSetup.workerOptions ?? [])
    : []
  return (
    <div className="max-w-2xl mx-auto text-center py-8">
      <div className="inline-flex items-center justify-center w-20 h-20 rounded-full bg-blue-100 text-blue-600 mb-6">
        <Rocket className="w-10 h-10" />
      </div>
      <h2 className="text-3xl font-bold text-slate-900 mb-3">
        {i18n.t('literals.udvozoljuk-a-valuta-penzvalto-rendszerbe')}
      </h2>
      <p className="text-slate-600 mb-6">
        {i18n.t('literals.jelentkezzen-be-google-fiokkal-a-rendsze')}
      </p>

      <div className="mb-5 rounded-lg border border-slate-200 bg-slate-50 px-4 py-3 text-left text-sm text-slate-700">
        <div className="flex items-center justify-between gap-2">
          <span className="font-semibold text-slate-900">
            {i18n.t('literals.google-oauth-konfiguracio')}
          </span>
          {googleConfigStatusLoading && <Loader2 className="h-4 w-4 animate-spin text-slate-500" />}
        </div>
        {googleConfigStatus ? (
          <div className="mt-2 grid grid-cols-1 gap-2 sm:grid-cols-2">
            <div>
              {i18n.t('literals.web-kliens')}{' '}
              <span className="font-semibold">
                {googleConfigStatus.webConfigured ? 'beállítva' : 'nincs beállítva'}
              </span>
              {googleConfigStatus.webPrefix && (
                <span className="ml-1 text-slate-500">
                  {i18n.t('literals.lit-19')}
                  {googleConfigStatus.webPrefix}
                  {i18n.t('literals.lit-2')}
                </span>
              )}
            </div>
            <div>
              {i18n.t('literals.desktop-kliens')}{' '}
              <span className="font-semibold">
                {googleConfigStatus.desktopConfigured ? 'beállítva' : 'nincs beállítva'}
              </span>
              {googleConfigStatus.desktopPrefix && (
                <span className="ml-1 text-slate-500">
                  {i18n.t('literals.lit-19')}
                  {googleConfigStatus.desktopPrefix}
                  {i18n.t('literals.lit-2')}
                </span>
              )}
            </div>
          </div>
        ) : (
          <div className="mt-2 text-slate-500">
            {googleConfigStatusError || 'A konfiguráció státusza még nem érhető el.'}
          </div>
        )}
      </div>

      <button
        type="button"
        onClick={onGoogleLogin}
        disabled={googleSetupLoading}
        className="mx-auto mb-5 inline-flex items-center justify-center gap-3 rounded-lg bg-blue-600 px-6 py-3 text-base font-semibold text-white hover:bg-blue-700 disabled:bg-slate-300 disabled:cursor-not-allowed transition"
      >
        {googleSetupLoading ? (
          <Loader2 className="w-5 h-5 animate-spin" />
        ) : (
          <span className="text-lg font-bold">{i18n.t('literals.g')}</span>
        )}
        {i18n.t('literals.bejelentkezes-google-lel')}
      </button>

      {googleSetupError && (
        <div className="mb-5 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-left text-sm text-red-700">
          <div>{googleSetupError}</div>
          <button
            type="button"
            onClick={onRetryGoogleIdentify}
            disabled={googleSetupLoading}
            className="mt-3 inline-flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700 disabled:bg-slate-300 disabled:cursor-not-allowed transition"
          >
            {googleSetupLoading ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <RefreshCw className="w-4 h-4" />
            )}
            {i18n.t('literals.probald-ujra-a-kapcsolatot')}
          </button>
        </div>
      )}

      {googleSetup?.worker && (
        <div className="mb-5 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-left text-sm text-green-800">
          <div className="font-semibold">
            {i18n.t('literals.azonositva')}
            {googleSetup.worker.name}
          </div>
          <div>
            {googleSetup.branch?.code}
            {i18n.t('literals.lit-17')}
            {googleSetup.branch?.name}
            {i18n.t('literals.lit-29')} {googleSetup.worker.roles?.[0] ?? googleSetup.worker.role}
          </div>
        </div>
      )}

      {sharedWorkerOptions.length > 0 && (
        <div className="mb-5 rounded-lg border border-blue-200 bg-blue-50 px-4 py-4 text-left">
          <div className="mb-3 text-sm font-semibold text-slate-800">
            {i18n.t('literals.megosztott-fiok-email-ki-on')}
          </div>
          <select
            value={selectedSharedWorkerCode}
            onChange={(event) => onSelectedSharedWorkerCodeChange(event.target.value)}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-200"
          >
            <option value="">{i18n.t('literals.valasszon-dolgozot')}</option>
            {sharedWorkerOptions.map((worker) => (
              <option key={worker.code} value={worker.code}>
                {worker.name}
                {i18n.t('literals.lit')}
                {worker.code}
                {i18n.t('literals.lit-2')}
              </option>
            ))}
          </select>
          <button
            type="button"
            onClick={onSharedWorkerConfirm}
            disabled={!selectedSharedWorkerCode || googleSetupLoading}
            className="mt-3 inline-flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:bg-slate-300 disabled:cursor-not-allowed"
          >
            {googleSetupLoading && <Loader2 className="w-4 h-4 animate-spin" />}
            {i18n.t('literals.ez-vagyok-tovabb')}
          </button>
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-left">
        <InfoTile
          icon={<Building2 className="w-5 h-5" />}
          title="1. Automatikus fiók"
          description="A dolgozói törzs email mezői alapján áll be."
        />
        <InfoTile
          icon={<Server className="w-5 h-5" />}
          title="2. Szerver kapcsolat"
          description="A központi backend elérését ellenőrizzük."
        />
        <InfoTile
          icon={<KeyRound className="w-5 h-5" />}
          title="3. Jelszó csak pénztárnál"
          description="Vezetői és központi szerepköröknél Google-belépés marad."
        />
        <InfoTile
          icon={<ShieldCheck className="w-5 h-5" />}
          title="4. Biztonságos telepítés"
          description="Egyedi kulcsok, helyi konfiguráció és szinkron."
        />
      </div>
    </div>
  )
}

function InfoTile({
  icon,
  title,
  description,
}: {
  icon: React.ReactNode
  title: string
  description: string
}) {
  return (
    <div className="p-4 rounded-lg border border-slate-200 bg-slate-50">
      <div className="flex items-center gap-2 mb-1 text-blue-600">
        {icon}
        <span className="font-semibold text-slate-800">{title}</span>
      </div>
      <p className="text-sm text-slate-600">{description}</p>
    </div>
  )
}

// ---------------------------------------------------------------------------
// 2. Iroda lépés
// ---------------------------------------------------------------------------

interface BranchStepProps {
  branches: Branch[]
  totalFiltered: number
  page: number
  totalPages: number
  onPageChange: (page: number) => void
  search: string
  onSearchChange: (value: string) => void
  selected: Branch | null
  onSelect: (branch: Branch) => void
}

function BranchStep(props: BranchStepProps) {
  const { t } = useTranslation()
  const {
    branches,
    totalFiltered,
    page,
    totalPages,
    onPageChange,
    search,
    onSearchChange,
    selected,
    onSelect,
  } = props
  return (
    <div>
      <h2 className="text-2xl font-bold text-slate-900 mb-2">{t('setup.valasszaKiAzIrodat')}</h2>
      <p className="text-slate-600 mb-5">
        {t('setup.ezAFiokIrodaAmelyikbenASzamitogepFizikailagTalalhatoOsszesen')} {totalFiltered}{' '}
        {t('setup.irodaKozul')}
      </p>

      <div className="relative mb-5">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
        <input
          type="text"
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          placeholder="Keresés kód, név vagy város szerint..."
          className="w-full pl-9 pr-3 py-2 rounded-lg border border-slate-300 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none transition"
        />
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-8 gap-3">
        {branches.map((branch) => {
          const isSelected = selected?.code === branch.code
          return (
            <button
              key={branch.code}
              type="button"
              onClick={() => onSelect(branch)}
              className={[
                'p-3 rounded-lg border text-left transition min-h-[82px] flex flex-col justify-between',
                isSelected
                  ? 'border-blue-600 bg-blue-50 ring-2 ring-blue-200'
                  : 'border-slate-200 hover:border-blue-400 hover:bg-slate-50',
              ].join(' ')}
            >
              <div className="text-xs font-mono text-slate-500">
                {i18n.t('literals.lit-12')}
                {branch.code}
              </div>
              <div className="text-sm font-semibold text-slate-900 truncate">{branch.name}</div>
              <div className="text-xs text-slate-500 truncate">{branch.city}</div>
            </button>
          )
        })}
        {branches.length === 0 && (
          <div className="col-span-full text-center py-8 text-slate-500">
            {t('setup.nincsTalalatAKeresesre')}
          </div>
        )}
      </div>

      {totalPages > 1 && (
        <div className="mt-5 flex items-center justify-center gap-2">
          <button
            type="button"
            onClick={() => onPageChange(Math.max(0, page - 1))}
            disabled={page === 0}
            className="p-2 rounded-lg border border-slate-300 bg-white disabled:opacity-40"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>
          <span className="text-sm text-slate-600 px-2">
            {page + 1}
            {i18n.t('literals.lit-10')}
            {totalPages} {t('common.oldal')}
          </span>
          <button
            type="button"
            onClick={() => onPageChange(Math.min(totalPages - 1, page + 1))}
            disabled={page >= totalPages - 1}
            className="p-2 rounded-lg border border-slate-300 bg-white disabled:opacity-40"
          >
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      )}

      {selected && (
        <div className="mt-5 p-3 rounded-lg bg-blue-50 border border-blue-200 flex items-center gap-3">
          <CheckCircle2 className="w-5 h-5 text-blue-600 flex-shrink-0" />
          <div>
            <div className="text-sm font-semibold text-blue-900">
              {t('setup.kivalasztva')}
              {selected.name}
            </div>
            <div className="text-xs text-blue-700">
              {t('setup.kod')}
              {selected.code}
              {i18n.t('literals.lit-58')}
              {selected.city}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

// ---------------------------------------------------------------------------
// 3. Szerver lépés
// ---------------------------------------------------------------------------

interface ServerStepProps {
  apiUrl: string
  onApiUrlChange: (value: string) => void
  companyCode: string
  onCompanyCodeChange: (value: string) => void
  bootstrapUsername: string
  onBootstrapUsernameChange: (value: string) => void
  offlineMode: boolean
  onOfflineModeChange: (value: boolean) => void
  connectionTest: { state: 'idle' | 'testing' | 'ok' | 'fail'; message?: string }
  onTestConnection: () => void
  selectedBranchCode: string | null
  onWorkerListChange: (workers: SetupWorkerOption[]) => void
  // PR #686: appMode + googleAuthSetupReady, hogy az ertektar/foertektar/admin
  // modu telepiteseknel a "Penztaros kivalasztasa" dropdown elrejtodjon -
  // ertektaroknak a Step 1 Google OAuth mar azonositotta a worker-t.
  appMode: ElectronAppMode
  googleAuthSetupReady: boolean
  googleSetupWorker: SetupWorkerOption | null
}

function ServerStep(props: ServerStepProps) {
  const { t } = useTranslation()
  const {
    apiUrl,
    companyCode,
    onCompanyCodeChange,
    bootstrapUsername,
    onBootstrapUsernameChange,
    offlineMode,
    onOfflineModeChange,
    connectionTest,
    onTestConnection,
    selectedBranchCode,
    onWorkerListChange,
    appMode,
    googleAuthSetupReady,
    googleSetupWorker,
  } = props

  // PR #686 (kosa@bestchange.hu bug): a "Penztaros kivalasztasa" mezo CSAK
  // a `penztar` modnal jelenik meg ES csak ha a Step 1 Google OAuth nem
  // azonositotta meg a worker-t. Ertektarosok / arfolyamkeszito / admin
  // mar a Step 1 Google OAuth-on at azonositva van - itt nincs dolguk.
  const showCashierDropdown = appMode === 'penztar' && !googleAuthSetupReady
  const hasGoogleIdentity = googleAuthSetupReady && googleSetupWorker !== null

  const [workerList, setWorkerList] = useState<SetupWorkerOption[]>([])
  const [workerListLoading, setWorkerListLoading] = useState(false)

  useEffect(() => {
    const normalizedCompanyCode = companyCode.trim()
    const normalizedBranchCode = selectedBranchCode?.trim() ?? ''

    if (!normalizedBranchCode || !normalizedCompanyCode || offlineMode) {
      setWorkerList([])
      onWorkerListChange([])
      return
    }
    let cancelled = false
    setWorkerListLoading(true)
    const loadWorkers = window.electronAPI?.setupGetWorkers
      ? window.electronAPI.setupGetWorkers({
          apiUrl: apiUrl.trim(),
          companyCode: normalizedCompanyCode,
          branchCode: normalizedBranchCode,
        })
      : publicApi.getWorkersByBranch(normalizedBranchCode, normalizedCompanyCode)

    loadWorkers
      .then((list) => {
        if (cancelled) return
        const workers = list.map((w) => ({ code: w.code, name: w.name }))
        setWorkerList(workers)
        onWorkerListChange(workers)
      })
      .catch(() => {
        if (!cancelled) {
          setWorkerList([])
          onWorkerListChange([])
        }
      })
      .finally(() => {
        if (!cancelled) setWorkerListLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [apiUrl, companyCode, selectedBranchCode, offlineMode, onWorkerListChange])

  return (
    <div>
      <h2 className="text-2xl font-bold text-slate-900 mb-2">{t('setup.szerverKapcsolat')}</h2>
      <p className="text-slate-600 mb-5">
        {t('setup.adjaMegAKozpontiBackendUrlJetEsATesztelesHitelesitoAdatait')}
      </p>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-5 max-w-3xl">
        <FieldLabel label="Szerver URL (rögzített)" icon={<Globe className="w-4 h-4" />}>
          <input
            type="url"
            value={apiUrl}
            readOnly
            title="A központi backend URL-je — telepítéskor rögzített, csak szervizélra módosítható."
            className="w-full px-3 py-2 rounded-lg border border-slate-200 bg-slate-50 text-slate-600 cursor-not-allowed outline-none"
          />
          <p className="text-xs text-slate-500 mt-1">
            {t('setup.kozpontiHetznerBackendAutomatikusanBeallitva')}
          </p>
        </FieldLabel>
        <FieldLabel label="Cégkód" icon={<Building2 className="w-4 h-4" />}>
          <input
            type="text"
            value={companyCode}
            onChange={(e) => onCompanyCodeChange(e.target.value.toUpperCase())}
            disabled={offlineMode}
            placeholder="EBC"
            className="w-full px-3 py-2 rounded-lg border border-slate-300 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none disabled:bg-slate-100 disabled:text-slate-500"
          />
        </FieldLabel>
        {showCashierDropdown ? (
          <FieldLabel label="Pénztáros kiválasztása">
            {workerList.length > 0 ? (
              <select
                value={bootstrapUsername}
                onChange={(e) => onBootstrapUsernameChange(e.target.value)}
                disabled={offlineMode || workerListLoading}
                className="w-full px-3 py-2 rounded-lg border border-slate-300 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none disabled:bg-slate-100 bg-white"
              >
                <option value="">{t('auth.valasszonPenztarost')}</option>
                {workerList.map((w) => (
                  <option key={w.code} value={w.code}>
                    {w.name}
                    {i18n.t('literals.lit')}
                    {w.code}
                    {i18n.t('literals.lit-2')}
                  </option>
                ))}
              </select>
            ) : (
              <input
                type="text"
                value={bootstrapUsername}
                onChange={(e) => onBootstrapUsernameChange(e.target.value)}
                disabled={offlineMode}
                placeholder={workerListLoading ? 'Pénztárosok betöltése...' : 'Pénztáros kód'}
                className="w-full px-3 py-2 rounded-lg border border-slate-300 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none disabled:bg-slate-100"
              />
            )}
            <span className="text-xs text-slate-500 mt-1 block">
              {t('setup.azIttKivalasztottPenztarosKodjahozAz5LepesenAllitjaBeAzUjJelszot')}
            </span>
          </FieldLabel>
        ) : hasGoogleIdentity && googleSetupWorker ? (
          // PR #686: Google OAuth mar azonositott - csak informacios kartya,
          // NEM enged tovabbi penztaros-valasztast (ertektaros / arfolyamkeszito / admin).
          <FieldLabel label="Azonosított dolgozó (Google OAuth)">
            <div className="w-full px-3 py-2 rounded-lg border border-green-200 bg-green-50 text-green-900">
              <div className="font-semibold">{googleSetupWorker.name}</div>
              <div className="text-xs text-green-700">
                {i18n.t('literals.kod-4')}
                {googleSetupWorker.code}
              </div>
            </div>
            <span className="text-xs text-slate-500 mt-1 block">
              {appMode === 'ertektar'
                ? 'Értéktárosként a Google OAuth már bejelentkeztette — nincs pénztáros-kódra vagy jelszóra szükség.'
                : 'A Google OAuth már azonosította Önt — nincs további pénztáros-kódra vagy jelszóra szükség.'}
            </span>
          </FieldLabel>
        ) : (
          // Nincs meg Google OAuth — figyelmezteto, BARMELY non-penztar mode-nal
          // (illetve penztar mod-ban ha valami miatt a Step 1 nem futott le).
          <FieldLabel label="Bejelentkezés">
            <div className="w-full px-3 py-2 rounded-lg border border-blue-200 bg-blue-50 text-blue-900 text-sm">
              {i18n.t('literals.terjen-vissza-az-1-lepesre-udvozoljuk-es')}
              {appMode === 'ertektar' && ' Értéktárosként ezzel azonosul.'}
            </div>
          </FieldLabel>
        )}
        <div /> {/* spacer — a jelszo mezo az Admin lepesre kerult */}
      </div>

      <div className="mt-5 flex flex-wrap items-center gap-3">
        <button
          type="button"
          onClick={onTestConnection}
          disabled={offlineMode || connectionTest.state === 'testing'}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-blue-600 bg-blue-50 text-blue-700 hover:bg-blue-100 disabled:opacity-50 transition"
        >
          {connectionTest.state === 'testing' ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              {i18n.t('literals.teszteles')}
            </>
          ) : (
            <>
              <Wifi className="w-4 h-4" />
              {t('setup.kapcsolatTesztelese')}
            </>
          )}
        </button>

        {connectionTest.state === 'ok' && (
          <span className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-green-50 border border-green-200 text-green-700 text-sm">
            <CheckCircle2 className="w-4 h-4" /> {connectionTest.message}
          </span>
        )}
        {connectionTest.state === 'fail' && (
          <span className="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-red-50 border border-red-200 text-red-700 text-sm">
            <XCircle className="w-4 h-4" /> {connectionTest.message}
          </span>
        )}
      </div>

      {/* Audit P1.7: a "Offline mod" checkbox CSAK akkor enabled, ha a connection test FAIL-elt
          (vagy mar offline-on van a wizard). Korabban barmikor pipalhato volt — de a vault
          feedback szerint a penztar telepites ELSO lepese online regisztracio kell legyen,
          offline csak degraded fallback. Ez kikenyszeriti, hogy a user megprobalja az
          online kapcsolatot, mielott offline-ot valaszt.
          MEGJEGYZES: ha mar offline van pipalva (offlineMode=true), engedjuk uncheck-elni —
          egyebkent a user beragadhatna offline modban. */}
      {(() => {
        const offlineCheckboxDisabled = connectionTest.state !== 'fail' && !offlineMode
        return (
          <div
            className={`mt-6 p-4 rounded-lg border flex items-start gap-3 ${
              connectionTest.state === 'fail' || offlineMode
                ? 'border-amber-300 bg-amber-50'
                : 'border-slate-200 bg-slate-50 opacity-50'
            }`}
          >
            <input
              id="offline-mode"
              type="checkbox"
              checked={offlineMode}
              onChange={(e) => onOfflineModeChange(e.target.checked)}
              // P1.7: csak akkor checkable, ha connection test mar fail-elt VAGY mar offline a state
              disabled={offlineCheckboxDisabled}
              className="mt-1"
            />
            <label
              htmlFor="offline-mode"
              // Copilot review #383 P2: a label cursor-ja kovesse a checkbox tenyleges
              // interaktivitasat (cursor-not-allowed disabled-eseten — UX/a11y konzisztencia).
              aria-disabled={offlineCheckboxDisabled}
              className={`flex-1 text-sm text-slate-700 select-none ${offlineCheckboxDisabled ? 'cursor-not-allowed' : 'cursor-pointer'}`}
            >
              <span className="font-semibold text-slate-900 inline-flex items-center gap-1.5">
                <WifiOff className="w-4 h-4" /> {t('setupWizard.offlineModeTitle')}
              </span>
              <br />
              {connectionTest.state === 'fail' ? (
                <span className="text-amber-800">{t('setupWizard.offlineModeFail')}</span>
              ) : offlineMode ? (
                <span className="text-amber-800">{t('setupWizard.offlineModeActive')}</span>
              ) : (
                <span>{t('setupWizard.offlineModeDisabled')}</span>
              )}
            </label>
          </div>
        )
      })()}
    </div>
  )
}

function FieldLabel({
  label,
  icon,
  children,
}: {
  label: string
  icon?: React.ReactNode
  children: React.ReactNode
}) {
  return (
    <label className="block">
      <span className="text-sm font-medium text-slate-700 mb-1.5 flex items-center gap-1.5">
        {icon}
        {label}
      </span>
      {children}
    </label>
  )
}

// ---------------------------------------------------------------------------
// 4. Admin jelszó + összefoglaló
// ---------------------------------------------------------------------------

function GoogleAdminStep(props: {
  googleSetup: SetupGoogleIdentifyResponse
  selectedBranch: Branch | null
  appMode: ElectronAppMode
}) {
  const { googleSetup, selectedBranch, appMode } = props
  const worker = googleSetup.worker
  return (
    <div>
      <h2 className="text-2xl font-bold text-slate-900 mb-2">
        {i18n.t('literals.google-belepes-veglegesitese')}
      </h2>
      <p className="text-slate-600 mb-6">
        {i18n.t('literals.ehhez-a-telepiteshez-nem-keszitunk-helyi')}
      </p>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
          <div className="text-xs uppercase text-slate-500 mb-1">
            {i18n.t('literals.dolgozo-2')}
          </div>
          <div className="font-semibold text-slate-900">{worker?.name}</div>
          <div className="text-sm text-slate-600">
            {worker?.code}
            {i18n.t('literals.lit-9')}
            {worker?.roles?.[0] ?? worker?.role}
          </div>
        </div>
        <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
          <div className="text-xs uppercase text-slate-500 mb-1">
            {i18n.t('literals.google-email')}
          </div>
          <div className="font-semibold text-slate-900 break-all">
            {googleSetup.googleIdentity.email}
          </div>
          <div className="text-sm text-slate-600">{googleSetup.matchType}</div>
        </div>
        <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
          <div className="text-xs uppercase text-slate-500 mb-1">{i18n.t('literals.fiok')}</div>
          <div className="font-semibold text-slate-900">
            {selectedBranch?.code}
            {i18n.t('literals.lit-17')}
            {selectedBranch?.name}
          </div>
          <div className="text-sm text-slate-600">{selectedBranch?.city}</div>
        </div>
        <div className="rounded-lg border border-slate-200 bg-slate-50 p-4">
          <div className="text-xs uppercase text-slate-500 mb-1">{i18n.t('literals.program')}</div>
          <div className="font-semibold text-slate-900">{appModeLabel(appMode)}</div>
          <div className="text-sm text-slate-600">{i18n.t('literals.automatikusan-beallitva')}</div>
        </div>
      </div>

      <div className="rounded-lg border border-green-200 bg-green-50 p-4 text-sm text-green-800">
        {i18n.t('literals.a-befejezeskor-a-telepito-egyedi-jwt-es')}
      </div>
    </div>
  )
}

interface AdminStepProps {
  adminUsername: string
  onAdminUsernameChange: (v: string) => void
  adminPassword: string
  onAdminPasswordChange: (v: string) => void
  adminPasswordConfirm: string
  onAdminPasswordConfirmChange: (v: string) => void
  bootstrapPassword: string
  onBootstrapPasswordChange: (v: string) => void
  selectedBranch: Branch | null
  apiUrl: string
  companyCode: string
  offlineMode: boolean
  setupToken: string
  onSetupTokenChange: (v: string) => void
}

function AdminStep(props: AdminStepProps) {
  const { t } = useTranslation()
  const {
    adminUsername,
    adminPassword,
    onAdminPasswordChange,
    adminPasswordConfirm,
    onAdminPasswordConfirmChange,
    bootstrapPassword,
    onBootstrapPasswordChange,
    selectedBranch,
    apiUrl,
    companyCode,
    offlineMode,
    setupToken,
    onSetupTokenChange,
  } = props

  const pwTooShort = adminPassword.length > 0 && adminPassword.length < 8
  const pwMismatch = adminPasswordConfirm.length > 0 && adminPassword !== adminPasswordConfirm

  return (
    <div>
      <h2 className="text-2xl font-bold text-slate-900 mb-2">{t('resetPassword.submit')}</h2>
      <p className="text-slate-600 mb-5">
        {t('setup.adjonMegEgyBiztonsagosJelszotLegalabb8KarakterEzzelAJelszovalEsA')}
        {t('setup.lentLathatoPenztarosKoddalLepMajdBeAProgramba')}
      </p>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-5 max-w-3xl mb-8">
        <FieldLabel label="Pénztáros kód (a 4. lépésben választott)">
          <input
            type="text"
            value={adminUsername}
            readOnly
            className="w-full px-3 py-2 rounded-lg border border-slate-300 bg-slate-100 text-slate-700 cursor-not-allowed outline-none"
          />
          <span className="text-xs text-slate-500 mt-1 block">
            {t('setup.eztAKodotKellBeirniaABejelentkezesnelIs')}
          </span>
        </FieldLabel>
        <FieldLabel label="Jelenlegi jelszó (opcionális)">
          <input
            type="password"
            value={bootstrapPassword}
            onChange={(e) => onBootstrapPasswordChange(e.target.value)}
            disabled={offlineMode}
            autoComplete="current-password"
            placeholder="Csak újratelepítéskor szükséges"
            className={[
              'w-full px-3 py-2 rounded-lg border focus:ring-2 outline-none',
              offlineMode
                ? 'border-slate-200 bg-slate-100 text-slate-400 cursor-not-allowed'
                : 'border-slate-300 focus:border-blue-500 focus:ring-blue-200',
            ].join(' ')}
          />
          <span className="text-xs text-slate-500 mt-1 block">
            {i18n.t('literals.csak-akkor-toltse-ki-ha-ennek-a-penztaro')}
          </span>
        </FieldLabel>
        <FieldLabel label="Setup-token (opcionális)">
          <input
            type="text"
            value={setupToken}
            onChange={(e) => onSetupTokenChange(e.target.value)}
            disabled={offlineMode}
            autoComplete="off"
            placeholder="Csak ha az adminisztrátor adott egyet"
            className={[
              'w-full px-3 py-2 rounded-lg border focus:ring-2 outline-none font-mono text-sm',
              offlineMode
                ? 'border-slate-200 bg-slate-100 text-slate-400 cursor-not-allowed'
                : 'border-slate-300 focus:border-blue-500 focus:ring-blue-200',
            ].join(' ')}
          />
          <span className="text-xs text-slate-500 mt-1 block">
            {i18n.t('literals.ujratelepites-jelszo-reset-eseten-az-adm')}
          </span>
        </FieldLabel>
        <FieldLabel label="Új jelszó">
          <input
            type="password"
            value={adminPassword}
            onChange={(e) => onAdminPasswordChange(e.target.value)}
            className={[
              'w-full px-3 py-2 rounded-lg border focus:ring-2 outline-none',
              pwTooShort
                ? 'border-red-400 focus:border-red-500 focus:ring-red-200'
                : 'border-slate-300 focus:border-blue-500 focus:ring-blue-200',
            ].join(' ')}
          />
          {pwTooShort && (
            <span className="text-xs text-red-600 mt-1 block">{t('setup.minimum8Karakter')}</span>
          )}
        </FieldLabel>
        <FieldLabel label="Jelszó megerősítése">
          <input
            type="password"
            value={adminPasswordConfirm}
            onChange={(e) => onAdminPasswordConfirmChange(e.target.value)}
            className={[
              'w-full px-3 py-2 rounded-lg border focus:ring-2 outline-none',
              pwMismatch
                ? 'border-red-400 focus:border-red-500 focus:ring-red-200'
                : 'border-slate-300 focus:border-blue-500 focus:ring-blue-200',
            ].join(' ')}
          />
          {pwMismatch && (
            <span className="text-xs text-red-600 mt-1 block">
              {t('resetPassword.mismatchError')}
            </span>
          )}
        </FieldLabel>
      </div>

      <div className="p-5 rounded-lg bg-slate-50 border border-slate-200">
        <h3 className="text-sm font-semibold text-slate-900 mb-3 inline-flex items-center gap-2">
          <ShieldCheck className="w-4 h-4 text-blue-600" />
          {t('setup.osszefoglalo')}
        </h3>
        <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-2 text-sm">
          <SummaryRow
            label="Iroda"
            value={selectedBranch ? `${selectedBranch.name} (#${selectedBranch.code})` : '—'}
          />
          <SummaryRow label="Város" value={selectedBranch?.city || '—'} />
          <SummaryRow label="Szerver" value={offlineMode ? 'Offline mód' : apiUrl || '—'} />
          <SummaryRow label="Cégkód" value={offlineMode ? '—' : companyCode || '—'} />
          <SummaryRow
            label="Pénztáros kód (login)"
            value={adminUsername || '— (nincs kiválasztva)'}
          />
          <SummaryRow
            label="Jelszó (login)"
            value={adminPassword ? '•'.repeat(Math.min(adminPassword.length, 12)) : '—'}
          />
        </dl>
      </div>

      <div className="mt-5 p-4 rounded-lg bg-blue-50 border border-blue-200 text-sm text-blue-900">
        <strong className="block mb-1">{t('setup.bejelentkezeskorIgyHasznalja')}</strong>
        {t('setup.cegkod')}
        <code className="px-1 bg-white rounded">{companyCode}</code>
        {' · '}
        {t('setup.penztarosKod')}
        <code className="px-1 bg-white rounded">{adminUsername || '...'}</code>
        {' · '}
        {t('setup.jelszoAzIttMegadottUjJelszo')}
      </div>

      <p className="mt-3 text-xs text-slate-500">
        {t('setup.aTelepitesBefejezeseGombMegnyomasakorAProgramKriptografiaiKulcsokatGeneral')}
        {t('setup.elmentiAKonfiguraciotAHelyiEnvFajlbaMajdAutomatikusanUjraindul')}
      </p>
    </div>
  )
}

function SummaryRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex">
      <dt className="w-36 flex-shrink-0 text-slate-500">
        {label}
        {i18n.t('literals.lit-7')}
      </dt>
      <dd className="font-medium text-slate-900">{value}</dd>
    </div>
  )
}
