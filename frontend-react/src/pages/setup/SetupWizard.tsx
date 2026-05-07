import { useCallback, useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import {
  Building2,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  Globe,
  KeyRound,
  Loader2,
  Rocket,
  Search,
  Server,
  ShieldCheck,
  Wifi,
  WifiOff,
  XCircle,
} from 'lucide-react'
import { publicApi } from '../../services/api/index'

// ---------------------------------------------------------------------------
// Típusok
// ---------------------------------------------------------------------------

interface Branch {
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

export function resolveSelectedWorkerForSetup(params: {
  offlineMode: boolean
  workerCode: string
  availableWorkers: SetupWorkerOption[]
}): SetupWorkerOption | null {
  if (params.offlineMode) return null
  const normalizedWorkerCode = params.workerCode.trim().toUpperCase()
  if (!normalizedWorkerCode) return null
  return params.availableWorkers.find((worker) => worker.code.trim().toUpperCase() === normalizedWorkerCode) ?? null
}

export function shouldLoadSetupWorkers(selectedBranchCode: string, offlineMode: boolean): boolean {
  return selectedBranchCode.trim().length > 0 && !offlineMode
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
  { id: 'welcome', title: 'Üdvözöljük',    subtitle: 'A telepítés véghezvitele',     icon: Rocket },
  { id: 'program', title: 'Program típus',       subtitle: 'Milyen szerepben indul ez a gép', icon: Server },
  { id: 'branch',  title: 'Fiók kiválasztása', subtitle: 'Ezen a gépen dolgozó iroda', icon: Building2 },
  { id: 'server',  title: 'Szerver kapcsolat', subtitle: 'Központi backend elérése',   icon: Server },
  { id: 'admin',   title: 'Admin jelszó',      subtitle: 'Első belépéshez',            icon: KeyRound },
]

// Produkciós központi backend (Hetzner CPX31, DNS: excvaluta.com (api. aldomain nem letezik)).
// Ha változik a hosting, csak itt cseréld — a wizard ezt használja default-nak
// és a helyettesítő szövegnek is. A felhasználó felülírhatja kézzel.
const DEFAULT_API_URL = 'https://excvaluta.com/api/v1'
const DEFAULT_COMPANY_CODE = 'EBC'

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
  const [availableWorkers, setAvailableWorkers] = useState<SetupWorkerOption[]>([])
  const [offlineMode, setOfflineMode] = useState(false)
  const [appModeChoice, setAppModeChoice] = useState<'penztar' | 'ertektar'>('penztar')
  const [connectionTest, setConnectionTest] = useState<
    { state: 'idle' | 'testing' | 'ok' | 'fail'; message?: string }
  >({ state: 'idle' })

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
  useEffect(() => {
    const load = async () => {
      if (window.electronAPI?.setupGetBranches) {
        try {
          const list = await window.electronAPI.setupGetBranches({
            apiUrl,
            companyCode,
          })
          setBranches(list)
        } catch {
          setBranches([])
        }
      } else {
        // v2.1.4: Web mode (no Electron) — direct HTTP fetch via publicApi
        try {
          const list = await publicApi.getBranchesByCompany(companyCode)
          setBranches(list.map((b) => ({ code: b.code, name: b.name, city: b.city ?? '', address: b.address, isVault: b.isVault })))
        } catch {
          setBranches([])
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
    let list = branches
    if (appModeChoice === 'ertektar') {
      list = list.filter((b) => b.isVault === true)
    }
    const q = branchSearch.trim().toLowerCase()
    if (!q) return list
    return list.filter((b) =>
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
  }, [branchSearch])

  // --- Lépés-validáció: engedélyezett-e a tovább ---
  const canAdvance = useMemo(() => {
    switch (currentStep) {
      case 'welcome':
        return true
      case 'branch':
        return !!selectedBranch
      case 'program':
        return !!appModeChoice
      case 'server':
        if (offlineMode) return true
        return connectionTest.state === 'ok'
      case 'admin':
        return adminPassword.length >= 8 && adminPassword === adminPasswordConfirm && adminUsername.length > 0
      default:
        return false
    }
  }, [currentStep, selectedBranch, offlineMode, connectionTest.state, adminPassword, adminPasswordConfirm, adminUsername, appModeChoice])

  // --- v2.3.0: Auto connection test a server step belepeskor ---
  // No manualis gomb: ha a user a server step-re lep, auto fut a teszt
  // (ha offline mode off). Ha siker - zold banner. Ha fail - piros + retry gomb.
  useEffect(() => {
    if (currentStep !== 'server' || offlineMode) return
    if (connectionTest.state === 'testing') return
    if (connectionTest.state === 'ok') return // mar sikeres — ne fusson ujra
    // csak akkor indul, ha van apiUrl + companyCode
    if (!apiUrl.trim() || !companyCode.trim()) return
    // ne fusson ha a user meg nem tesztelt + semmi input sincs
    if (!bootstrapUsername.trim() && !bootstrapPassword) {
      // elso alkalommal az auto-test a bootstrap-status endpoint-ra megy
      // (nem kell a user kod/jelszo)
      setConnectionTest({ state: 'testing' })
      if (window.electronAPI?.setupTestConnection) {
        window.electronAPI.setupTestConnection({
          apiUrl: apiUrl.trim(),
          companyCode: companyCode.trim(),
          username: '',
          password: '',
        })
          .then((result) => {
            if (result.success) {
              setConnectionTest({
                state: 'ok',
                message: `Kapcsolodva (HTTP ${result.httpStatus ?? '?'}${
                  result.latencyMs !== undefined ? `, ${result.latencyMs} ms` : ''
                })`,
              })
            } else {
              setConnectionTest({ state: 'fail', message: result.errorMessage || 'Ismeretlen hiba.' })
            }
          })
          .catch((err: unknown) => {
            setConnectionTest({ state: 'fail', message: err instanceof Error ? err.message : String(err) })
          })
        return
      }
      const normalized = apiUrl.trim().replace(/\/+$/, '').replace(/\/api\/v1$/, '')
      const url = `${normalized}/api/v1/auth/bootstrap-status`
      const started = performance.now()
      fetch(url, { method: 'GET' })
        .then((resp) => {
          const latency = Math.round(performance.now() - started)
          if (resp.ok) {
            setConnectionTest({ state: 'ok', message: `Kapcsolodva (HTTP ${resp.status}, ${latency} ms)` })
          } else {
            setConnectionTest({ state: 'fail', message: `Szerver hiba: HTTP ${resp.status}` })
          }
        })
        .catch((err: unknown) => {
          setConnectionTest({ state: 'fail', message: err instanceof Error ? err.message : String(err) })
        })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentStep, apiUrl, companyCode, offlineMode])

  // --- Kapcsolat teszt (kezi, retry gombnak) ---
  const runConnectionTest = useCallback(async () => {
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
      const normalized = apiUrl.trim().replace(/\/+$/, '').replace(/\/api\/v1$/, '')
      const url = `${normalized}/api/v1/auth/bootstrap-status`
      const resp = await fetch(url, { method: 'GET' })
      const latency = Math.round(performance.now() - started)
      if (resp.ok) {
        setConnectionTest({ state: 'ok', message: `Sikeres (HTTP ${resp.status}, ${latency} ms)` })
      } else {
        setConnectionTest({ state: 'fail', message: `Szerver hiba: HTTP ${resp.status}` })
      }
    } catch (err: unknown) {
      setConnectionTest({ state: 'fail', message: err instanceof Error ? err.message : String(err) })
    }
  }, [apiUrl, companyCode, bootstrapUsername, bootstrapPassword])

  // --- Telepítés befejezése ---
  const handleFinish = async () => {
    if (!selectedBranch) return
    setIsSaving(true)
    setSaveError(null)
    try {
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
          adminUsername: adminUsername.trim(),
          adminPassword,
          bootstrapUsername: bootstrapUsername.trim(),
          bootstrapPassword,
          offlineMode,
          appMode: appModeChoice,
          // v2.3.0: worker identity atadasa az electron-nak ha van kivalasztott dolgozo
          ...(selectedWorker ? {
            selectedWorkerCode: selectedWorker.code.trim().toUpperCase(),
            selectedWorkerName: selectedWorker.name,
          } : {}),
        })
        if (!result.success) {
          setSaveError(result.errorMessage || 'Ismeretlen hiba a telepites soran.')
          setIsSaving(false)
        }
        return
      }
      const normalized = apiUrl.trim().replace(/\/+$/, '').replace(/\/api\/v1$/, '')

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
      const useWorkerSetup = selectedWorker !== null
      let workerIdentity: { workerCode: string; workerName?: string; workerRole?: string; branchCode?: string } | null = null

      if (useWorkerSetup) {
        const setupUrl = `${normalized}/api/v1/auth/first-time-worker-setup`
        const setupResp = await fetch(setupUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            companyCode: companyCode.trim(),
            workerCode: selectedWorkerCode,
            newPassword: adminPassword,
            currentPassword: bootstrapPassword || undefined,
          }),
        })
        if (!setupResp.ok) {
          const body = await setupResp.json().catch(() => ({} as Record<string, unknown>))
          const msg = (body as { message?: string }).message || `HTTP ${setupResp.status}`
          setSaveError(`Dolgozoi jelszo beallitas hiba: ${msg}`)
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
          const body = await resp.json().catch(() => ({} as Record<string, unknown>))
          const msg = (body as { message?: string }).message || `HTTP ${resp.status}`
          if (resp.status !== 400 || !msg.toLowerCase().includes('lezajlott')) {
            setSaveError(`Admin letrehozasi hiba: ${msg}`)
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

      localStorage.setItem('valuta-setup-config', JSON.stringify({
        branchCode: selectedBranch.code,
        branchName: selectedBranch.name,
        apiUrl: apiUrl.trim(),
        companyCode: companyCode.trim(),
        appMode: appModeChoice,
        workerCode: workerIdentity?.workerCode,
        workerName: workerIdentity?.workerName,
        workerRole: workerIdentity?.workerRole,
        installedAt: new Date().toISOString(),
      }))
      window.location.href = '/login'
    } catch (err: unknown) {
      setSaveError(err instanceof Error ? err.message : String(err))
      setIsSaving(false)
    }
  }

  // --- Lépés navigáció ---
  const goNext = () => {
    if (!canAdvance) return
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
          {currentStep === 'welcome' && <WelcomeStep />}
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
              <h2 className="text-xl font-bold text-slate-800 mb-2">{t('setup.programTipusKivalasztasa')}</h2>
              <p className="text-sm text-slate-600 mb-6">
                {t('setup.mitFuttatEzAGepEzHatarozzaMegMilyenMenupontokJelennekMegEsHogyKiTudBejelentkezni')}
                {t('setup.aValasztasATelepitesUtanIsModosithatoABeallitasokban')}
              </p>
              <div className="space-y-3">
                {([
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
                ]).map((opt) => (
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
                {t('setup.aBejelentkezettDolgozoMunkakoreAlapjanASzerverEllenorziHogyJogosultEErreAProgramTipusra')}
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
              bootstrapPassword={bootstrapPassword}
              onBootstrapPasswordChange={setBootstrapPassword}
              offlineMode={offlineMode}
              onOfflineModeChange={setOfflineMode}
              connectionTest={connectionTest}
              onTestConnection={runConnectionTest}
              selectedBranchCode={selectedBranch?.code ?? null}
              onWorkerListChange={setAvailableWorkers}
            />
          )}
          {currentStep === 'admin' && (
            <AdminStep
              adminUsername={adminUsername}
              onAdminUsernameChange={setAdminUsername}
              adminPassword={adminPassword}
              onAdminPasswordChange={setAdminPassword}
              adminPasswordConfirm={adminPasswordConfirm}
              onAdminPasswordConfirmChange={setAdminPasswordConfirm}
              selectedBranch={selectedBranch}
              apiUrl={apiUrl}
              companyCode={companyCode}
              offlineMode={offlineMode}
            />
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
            <ChevronLeft className="w-4 h-4" />{t('common.back')}
          </button>

          <div className="text-sm text-slate-500">
            {t('setup.lepes')}{currentIndex + 1} / {STEPS.length}
          </div>

          {currentIndex < STEPS.length - 1 ? (
            <button
              type="button"
              onClick={goNext}
              disabled={!canAdvance || isSaving}
              className="inline-flex items-center gap-2 px-5 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700 disabled:bg-slate-300 disabled:cursor-not-allowed transition"
            >
              {t('common.next')}<ChevronRight className="w-4 h-4" />
            </button>
          ) : (
            <button
              type="button"
              onClick={handleFinish}
              disabled={!canAdvance || isSaving}
              className="inline-flex items-center gap-2 px-5 py-2 rounded-lg bg-green-600 text-white hover:bg-green-700 disabled:bg-slate-300 disabled:cursor-not-allowed transition"
            >
              {isSaving ? (
                <><Loader2 className="w-4 h-4 animate-spin" /> Telepítés...</>
              ) : (
                <><Rocket className="w-4 h-4" />{t('setup.telepitesBefejezese')}</>
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
                  done ? 'bg-green-500 text-white'
                    : active ? 'bg-white text-blue-700'
                    : 'bg-blue-800/50 text-blue-100',
                ].join(' ')}
              >
                {done ? <CheckCircle2 className="w-5 h-5" /> : idx + 1}
              </div>
              <div className="hidden sm:block min-w-0">
                <div className={['text-xs font-medium truncate', active ? 'text-white' : 'text-blue-100'].join(' ')}>
                  {step.title}
                </div>
              </div>
              {idx < STEPS.length - 1 && (
                <div className={['flex-1 h-0.5', done ? 'bg-green-500' : 'bg-blue-800/50'].join(' ')} />
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

function WelcomeStep() {
  const { t } = useTranslation()
  return (
    <div className="max-w-2xl mx-auto text-center py-8">
      <div className="inline-flex items-center justify-center w-20 h-20 rounded-full bg-blue-100 text-blue-600 mb-6">
        <Rocket className="w-10 h-10" />
      </div>
      <h2 className="text-3xl font-bold text-slate-900 mb-3">{t('setup.udvozoljukAValutaPenztarban')}</h2>
      <p className="text-slate-600 mb-8">
        {t('setup.ezAVarazsloVegigvezetiAzElsoInditasBeallitasain4RovidLepesben')}
        {t('setup.elkeszitjukATelepitestUtanaAProgramAzonnalHasznalatraKeszLesz')}
      </p>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-left">
        <InfoTile
          icon={<Building2 className="w-5 h-5" />}
          title="1. Fiók kiválasztása"
          description="A pénztáros iroda, amelyikben ez a számítógép működik."
        />
        <InfoTile
          icon={<Server className="w-5 h-5" />}
          title="2. Szerver beállítás"
          description="A központi backend elérése — online módban szinkronizálunk."
        />
        <InfoTile
          icon={<KeyRound className="w-5 h-5" />}
          title="3. Admin jelszó"
          description="Az első belépéshez szükséges biztonságos jelszó."
        />
        <InfoTile
          icon={<ShieldCheck className="w-5 h-5" />}
          title="4. Telepítés"
          description="Kriptográfiai kulcsokat generálunk és konfigurálunk mindent."
        />
      </div>
    </div>
  )
}

function InfoTile({ icon, title, description }: { icon: React.ReactNode; title: string; description: string }) {
  return (
    <div className="p-4 rounded-lg border border-slate-200 bg-slate-50">
      <div className="flex items-center gap-2 mb-1 text-blue-600">{icon}<span className="font-semibold text-slate-800">{title}</span></div>
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
  const { branches, totalFiltered, page, totalPages, onPageChange, search, onSearchChange, selected, onSelect } = props
  return (
    <div>
      <h2 className="text-2xl font-bold text-slate-900 mb-2">{t('setup.valasszaKiAzIrodat')}</h2>
      <p className="text-slate-600 mb-5">
        {t('setup.ezAFiokIrodaAmelyikbenASzamitogepFizikailagTalalhatoOsszesen')}{totalFiltered} {t('setup.irodaKozul')}
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
              <div className="text-xs font-mono text-slate-500">#{branch.code}</div>
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
            {page + 1} / {totalPages} {t('common.oldal')}
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
            <div className="text-sm font-semibold text-blue-900">{t('setup.kivalasztva')}{selected.name}</div>
            <div className="text-xs text-blue-700">{t('setup.kod')}{selected.code} • {selected.city}</div>
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
  bootstrapPassword: string
  onBootstrapPasswordChange: (value: string) => void
  offlineMode: boolean
  onOfflineModeChange: (value: boolean) => void
  connectionTest: { state: 'idle' | 'testing' | 'ok' | 'fail'; message?: string }
  onTestConnection: () => void
  selectedBranchCode: string | null
  onWorkerListChange: (workers: SetupWorkerOption[]) => void
}

function ServerStep(props: ServerStepProps) {
  const { t } = useTranslation()
  // v2.5.24: a `bootstrapPassword` + `onBootstrapPasswordChange` mar nem hasznalt
  // a UI-n (eltavolitottuk a "Teszt jelszo" mezot), de a parent komponens meg
  // atadja a propsban — ezert a destructuring-bol kihagyjuk, de a parent meg
  // mukodik, mert a `setupSave`-be `bootstrapPassword` ures string mar.
  const {
    apiUrl,
    companyCode, onCompanyCodeChange,
    bootstrapUsername, onBootstrapUsernameChange,
    offlineMode, onOfflineModeChange,
    connectionTest, onTestConnection,
    selectedBranchCode,
    onWorkerListChange,
  } = props

  const [workerList, setWorkerList] = useState<SetupWorkerOption[]>([])
  const [workerListLoading, setWorkerListLoading] = useState(false)

  useEffect(() => {
    const branchCode = selectedBranchCode?.trim() ?? ''
    if (!shouldLoadSetupWorkers(branchCode, offlineMode)) {
      setWorkerListLoading(false)
      setWorkerList([])
      onWorkerListChange([])
      return
    }
    let cancelled = false
    setWorkerListLoading(true)
    publicApi.getWorkersByBranch(branchCode)
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
      .finally(() => { if (!cancelled) setWorkerListLoading(false) })
    return () => { cancelled = true }
  }, [selectedBranchCode, offlineMode, onWorkerListChange])

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
          <p className="text-xs text-slate-500 mt-1">{t('setup.kozpontiHetznerBackendAutomatikusanBeallitva')}</p>
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
                <option key={w.code} value={w.code}>{w.name} ({w.code})</option>
              ))}
            </select>
          ) : (
            <input
              type="text"
              value={bootstrapUsername}
              onChange={(e) => onBootstrapUsernameChange(e.target.value)}
              disabled={offlineMode}
              placeholder={workerListLoading ? "Pénztárosok betöltése..." : "Pénztáros kód (pl. ADMIN)"}
              className="w-full px-3 py-2 rounded-lg border border-slate-300 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none disabled:bg-slate-100"
            />
          )}
          <span className="text-xs text-slate-500 mt-1 block">
            {t('setup.azIttKivalasztottPenztarosKodjahozAz5LepesenAllitjaBeAzUjJelszot')}
          </span>
        </FieldLabel>
      </div>

      {/* v2.5.24 UX: a "Teszt jelszó" mezőt eltávolítottuk — felesleges volt és zavaró.
          A connection test most kizarolag a `bootstrap-status` endpoint-tal megy
          (auth nélkül), így a wizard 4. lépésén a felhasználónak SEMMI jelszót
          nem kell beírnia. A LOGIN-jelszót az 5. lépésen állítja be — egyszer. */}

      <div className="mt-5 flex flex-wrap items-center gap-3">
        <button
          type="button"
          onClick={onTestConnection}
          disabled={offlineMode || connectionTest.state === 'testing'}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-blue-600 bg-blue-50 text-blue-700 hover:bg-blue-100 disabled:opacity-50 transition"
        >
          {connectionTest.state === 'testing'
            ? <><Loader2 className="w-4 h-4 animate-spin" /> Tesztelés...</>
            : <><Wifi className="w-4 h-4" />{t('setup.kapcsolatTesztelese')}</>}
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
  label, icon, children,
}: { label: string; icon?: React.ReactNode; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="text-sm font-medium text-slate-700 mb-1.5 flex items-center gap-1.5">
        {icon}{label}
      </span>
      {children}
    </label>
  )
}

// ---------------------------------------------------------------------------
// 4. Admin jelszó + összefoglaló
// ---------------------------------------------------------------------------

interface AdminStepProps {
  adminUsername: string
  onAdminUsernameChange: (v: string) => void
  adminPassword: string
  onAdminPasswordChange: (v: string) => void
  adminPasswordConfirm: string
  onAdminPasswordConfirmChange: (v: string) => void
  selectedBranch: Branch | null
  apiUrl: string
  companyCode: string
  offlineMode: boolean
}

function AdminStep(props: AdminStepProps) {
  const { t } = useTranslation()
  // v2.5.21: az `onAdminUsernameChange` mar nem hasznalt — a felhasznalonev
  // automatikusan a step 4-en valasztott pénztáros kodot tukrozi (read-only field).
  const {
    adminUsername,
    adminPassword, onAdminPasswordChange,
    adminPasswordConfirm, onAdminPasswordConfirmChange,
    selectedBranch, apiUrl, companyCode, offlineMode,
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
            // v2.5.21: a felhasznalonev NEM editalhato — automatikusan a step 4-en
            // valasztott pénztáros kod, hogy a wizard veg utan tényleg ezzel lépjen be.
          />
          <span className="text-xs text-slate-500 mt-1 block">
            {t('setup.eztAKodotKellBeirniaABejelentkezesnelIs')}
          </span>
        </FieldLabel>
        <div /> {/* spacer */}
        <FieldLabel label="Új jelszó">
          <input
            type="password"
            value={adminPassword}
            onChange={(e) => onAdminPasswordChange(e.target.value)}
            className={[
              'w-full px-3 py-2 rounded-lg border focus:ring-2 outline-none',
              pwTooShort ? 'border-red-400 focus:border-red-500 focus:ring-red-200'
                : 'border-slate-300 focus:border-blue-500 focus:ring-blue-200',
            ].join(' ')}
          />
          {pwTooShort && <span className="text-xs text-red-600 mt-1 block">{t('setup.minimum8Karakter')}</span>}
        </FieldLabel>
        <FieldLabel label="Jelszó megerősítése">
          <input
            type="password"
            value={adminPasswordConfirm}
            onChange={(e) => onAdminPasswordConfirmChange(e.target.value)}
            className={[
              'w-full px-3 py-2 rounded-lg border focus:ring-2 outline-none',
              pwMismatch ? 'border-red-400 focus:border-red-500 focus:ring-red-200'
                : 'border-slate-300 focus:border-blue-500 focus:ring-blue-200',
            ].join(' ')}
          />
          {pwMismatch && <span className="text-xs text-red-600 mt-1 block">{t('resetPassword.mismatchError')}</span>}
        </FieldLabel>
      </div>

      <div className="p-5 rounded-lg bg-slate-50 border border-slate-200">
        <h3 className="text-sm font-semibold text-slate-900 mb-3 inline-flex items-center gap-2">
          <ShieldCheck className="w-4 h-4 text-blue-600" />{t('setup.osszefoglalo')}
        </h3>
        <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-2 text-sm">
          <SummaryRow label="Iroda" value={selectedBranch ? `${selectedBranch.name} (#${selectedBranch.code})` : '—'} />
          <SummaryRow label="Város" value={selectedBranch?.city || '—'} />
          <SummaryRow label="Szerver" value={offlineMode ? 'Offline mód' : apiUrl || '—'} />
          <SummaryRow label="Cégkód" value={offlineMode ? '—' : companyCode || '—'} />
          <SummaryRow label="Pénztáros kód (login)" value={adminUsername || '— (nincs kiválasztva)'} />
          <SummaryRow label="Jelszó (login)" value={adminPassword ? '•'.repeat(Math.min(adminPassword.length, 12)) : '—'} />
        </dl>
      </div>

      <div className="mt-5 p-4 rounded-lg bg-blue-50 border border-blue-200 text-sm text-blue-900">
        <strong className="block mb-1">{t('setup.bejelentkezeskorIgyHasznalja')}</strong>
        {t('setup.cegkod')}<code className="px-1 bg-white rounded">{companyCode}</code>{' · '}
        {t('setup.penztarosKod')}<code className="px-1 bg-white rounded">{adminUsername || '...'}</code>{' · '}
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
      <dt className="w-36 flex-shrink-0 text-slate-500">{label}:</dt>
      <dd className="font-medium text-slate-900">{value}</dd>
    </div>
  )
}
