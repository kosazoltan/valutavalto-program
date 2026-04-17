import { useCallback, useEffect, useMemo, useState } from 'react'
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

// ---------------------------------------------------------------------------
// Típusok
// ---------------------------------------------------------------------------

interface Branch {
  code: string
  name: string
  city: string
  address?: string
}

type StepId = 'welcome' | 'branch' | 'server' | 'admin'

interface StepDef {
  id: StepId
  title: string
  subtitle: string
  icon: typeof Rocket
}

const STEPS: readonly StepDef[] = [
  { id: 'welcome', title: 'Üdvözöljük',    subtitle: 'A telepítés véghezvitele',     icon: Rocket },
  { id: 'branch',  title: 'Fiók kiválasztása', subtitle: 'Ezen a gépen dolgozó iroda', icon: Building2 },
  { id: 'server',  title: 'Szerver kapcsolat', subtitle: 'Központi backend elérése',   icon: Server },
  { id: 'admin',   title: 'Admin jelszó',      subtitle: 'Első belépéshez',            icon: KeyRound },
]

// ---------------------------------------------------------------------------
// SetupWizard
// ---------------------------------------------------------------------------

export default function SetupWizard() {
  const [currentStep, setCurrentStep] = useState<StepId>('welcome')
  const currentIndex = STEPS.findIndex((s) => s.id === currentStep)

  // --- Adatállapotok ---
  const [branches, setBranches] = useState<Branch[]>([])
  const [branchSearch, setBranchSearch] = useState('')
  const [selectedBranch, setSelectedBranch] = useState<Branch | null>(null)
  const [branchPage, setBranchPage] = useState(0)

  const [apiUrl, setApiUrl] = useState('https://')
  const [companyCode, setCompanyCode] = useState('EBC')
  const [bootstrapUsername, setBootstrapUsername] = useState('')
  const [bootstrapPassword, setBootstrapPassword] = useState('')
  const [offlineMode, setOfflineMode] = useState(false)
  const [connectionTest, setConnectionTest] = useState<
    { state: 'idle' | 'testing' | 'ok' | 'fail'; message?: string }
  >({ state: 'idle' })

  const [adminUsername, setAdminUsername] = useState('admin')
  const [adminPassword, setAdminPassword] = useState('')
  const [adminPasswordConfirm, setAdminPasswordConfirm] = useState('')

  // --- Telepítés állapot ---
  const [isSaving, setIsSaving] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)

  // --- Iroda törzs betöltése ---
  useEffect(() => {
    const load = async () => {
      if (window.electronAPI?.setupGetBranches) {
        try {
          const list = await window.electronAPI.setupGetBranches()
          setBranches(list)
        } catch {
          setBranches([])
        }
      }
    }
    void load()
  }, [])

  // --- Iroda lista szűrés ---
  const filteredBranches = useMemo(() => {
    const q = branchSearch.trim().toLowerCase()
    if (!q) return branches
    return branches.filter((b) =>
      b.code.toLowerCase().includes(q) ||
      b.name.toLowerCase().includes(q) ||
      b.city.toLowerCase().includes(q),
    )
  }, [branches, branchSearch])

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
      case 'server':
        if (offlineMode) return true
        return connectionTest.state === 'ok'
      case 'admin':
        return adminPassword.length >= 8 && adminPassword === adminPasswordConfirm && adminUsername.length > 0
      default:
        return false
    }
  }, [currentStep, selectedBranch, offlineMode, connectionTest.state, adminPassword, adminPasswordConfirm, adminUsername])

  // --- Kapcsolat teszt ---
  const runConnectionTest = useCallback(async () => {
    if (!window.electronAPI?.setupTestConnection) {
      setConnectionTest({ state: 'fail', message: 'Az Electron API nem elérhető.' })
      return
    }
    setConnectionTest({ state: 'testing' })
    try {
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
        setConnectionTest({
          state: 'fail',
          message: result.errorMessage || 'Ismeretlen hiba.',
        })
      }
    } catch (err: unknown) {
      setConnectionTest({
        state: 'fail',
        message: err instanceof Error ? err.message : String(err),
      })
    }
  }, [apiUrl, companyCode, bootstrapUsername, bootstrapPassword])

  // --- Telepítés befejezése ---
  const handleFinish = async () => {
    if (!selectedBranch) return
    if (!window.electronAPI?.setupSave) {
      setSaveError('Az Electron API nem elérhető.')
      return
    }
    setIsSaving(true)
    setSaveError(null)
    try {
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
      })
      if (!result.success) {
        setSaveError(result.errorMessage || 'Ismeretlen hiba a telepítés során.')
        setIsSaving(false)
      }
      // Sikeres mentés után az app automatikusan relaunch-ol, UI frissítésre már nincs szükség.
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
    <div className="min-h-screen bg-gradient-to-br from-slate-100 via-slate-50 to-slate-100 flex items-center justify-center p-6">
      <div className="w-full max-w-5xl bg-white rounded-2xl shadow-xl overflow-hidden flex flex-col">
        {/* Fejléc + progress */}
        <SetupHeader currentIndex={currentIndex} />

        {/* Tartalom */}
        <div className="flex-1 px-10 py-8 min-h-[520px]">
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

        {/* Láb: navigációs gombok */}
        <div className="px-10 py-5 border-t border-slate-200 bg-slate-50 flex items-center justify-between">
          <button
            type="button"
            onClick={goPrev}
            disabled={currentIndex === 0 || isSaving}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-slate-300 bg-white text-slate-700 hover:bg-slate-100 disabled:opacity-50 disabled:cursor-not-allowed transition"
          >
            <ChevronLeft className="w-4 h-4" /> Vissza
          </button>

          <div className="text-sm text-slate-500">
            Lépés {currentIndex + 1} / {STEPS.length}
          </div>

          {currentIndex < STEPS.length - 1 ? (
            <button
              type="button"
              onClick={goNext}
              disabled={!canAdvance || isSaving}
              className="inline-flex items-center gap-2 px-5 py-2 rounded-lg bg-blue-600 text-white hover:bg-blue-700 disabled:bg-slate-300 disabled:cursor-not-allowed transition"
            >
              Tovább <ChevronRight className="w-4 h-4" />
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
                <><Rocket className="w-4 h-4" /> Telepítés befejezése</>
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
  return (
    <div className="px-10 py-6 bg-gradient-to-r from-blue-600 to-indigo-700 text-white">
      <div className="flex items-center gap-3 mb-5">
        <ShieldCheck className="w-7 h-7" />
        <div>
          <h1 className="text-xl font-semibold">Valuta Pénztár — Első indítás</h1>
          <p className="text-xs text-blue-100">A telepítés 4 lépésben elkészül.</p>
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
  return (
    <div className="max-w-2xl mx-auto text-center py-8">
      <div className="inline-flex items-center justify-center w-20 h-20 rounded-full bg-blue-100 text-blue-600 mb-6">
        <Rocket className="w-10 h-10" />
      </div>
      <h2 className="text-3xl font-bold text-slate-900 mb-3">Üdvözöljük a Valuta Pénztárban!</h2>
      <p className="text-slate-600 mb-8">
        Ez a varázsló végigvezeti az első indítás beállításain. 4 rövid lépésben
        elkészítjük a telepítést, utána a program azonnal használatra kész lesz.
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
  const { branches, totalFiltered, page, totalPages, onPageChange, search, onSearchChange, selected, onSelect } = props
  return (
    <div>
      <h2 className="text-2xl font-bold text-slate-900 mb-2">Válassza ki az irodát</h2>
      <p className="text-slate-600 mb-5">
        Ez a fiók / iroda, amelyikben a számítógép fizikailag található. Összesen {totalFiltered} iroda közül.
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
            Nincs találat a keresésre.
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
            {page + 1} / {totalPages} oldal
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
            <div className="text-sm font-semibold text-blue-900">Kiválasztva: {selected.name}</div>
            <div className="text-xs text-blue-700">Kód: {selected.code} • {selected.city}</div>
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
}

function ServerStep(props: ServerStepProps) {
  const {
    apiUrl, onApiUrlChange,
    companyCode, onCompanyCodeChange,
    bootstrapUsername, onBootstrapUsernameChange,
    bootstrapPassword, onBootstrapPasswordChange,
    offlineMode, onOfflineModeChange,
    connectionTest, onTestConnection,
  } = props

  return (
    <div>
      <h2 className="text-2xl font-bold text-slate-900 mb-2">Szerver kapcsolat</h2>
      <p className="text-slate-600 mb-5">
        Adja meg a központi backend URL-jét és a tesztelés hitelesítő adatait.
      </p>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-5 max-w-3xl">
        <FieldLabel label="Szerver URL" icon={<Globe className="w-4 h-4" />}>
          <input
            type="url"
            value={apiUrl}
            onChange={(e) => onApiUrlChange(e.target.value)}
            disabled={offlineMode}
            placeholder="https://valuta.sajatceg.hu"
            className="w-full px-3 py-2 rounded-lg border border-slate-300 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none disabled:bg-slate-100 disabled:text-slate-500"
          />
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

        <FieldLabel label="Teszt felhasználónév">
          <input
            type="text"
            value={bootstrapUsername}
            onChange={(e) => onBootstrapUsernameChange(e.target.value)}
            disabled={offlineMode}
            placeholder="admin"
            className="w-full px-3 py-2 rounded-lg border border-slate-300 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none disabled:bg-slate-100"
          />
        </FieldLabel>

        <FieldLabel label="Teszt jelszó">
          <input
            type="password"
            value={bootstrapPassword}
            onChange={(e) => onBootstrapPasswordChange(e.target.value)}
            disabled={offlineMode}
            className="w-full px-3 py-2 rounded-lg border border-slate-300 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none disabled:bg-slate-100"
          />
        </FieldLabel>
      </div>

      <div className="mt-5 flex flex-wrap items-center gap-3">
        <button
          type="button"
          onClick={onTestConnection}
          disabled={offlineMode || connectionTest.state === 'testing'}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-lg border border-blue-600 bg-blue-50 text-blue-700 hover:bg-blue-100 disabled:opacity-50 transition"
        >
          {connectionTest.state === 'testing'
            ? <><Loader2 className="w-4 h-4 animate-spin" /> Tesztelés...</>
            : <><Wifi className="w-4 h-4" /> Kapcsolat tesztelése</>}
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

      <div className="mt-6 p-4 rounded-lg border border-slate-200 bg-slate-50 flex items-start gap-3">
        <input
          id="offline-mode"
          type="checkbox"
          checked={offlineMode}
          onChange={(e) => onOfflineModeChange(e.target.checked)}
          className="mt-1"
        />
        <label htmlFor="offline-mode" className="flex-1 text-sm text-slate-700 cursor-pointer select-none">
          <span className="font-semibold text-slate-900 inline-flex items-center gap-1.5">
            <WifiOff className="w-4 h-4" /> Offline mód — kihagyás
          </span>
          <br />
          Ezt csak akkor válassza, ha a pénztáros gép most még nem tudja elérni a központi szervert.
          Később a beállításokban konfigurálhatja.
        </label>
      </div>
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
  const {
    adminUsername, onAdminUsernameChange,
    adminPassword, onAdminPasswordChange,
    adminPasswordConfirm, onAdminPasswordConfirmChange,
    selectedBranch, apiUrl, companyCode, offlineMode,
  } = props

  const pwTooShort = adminPassword.length > 0 && adminPassword.length < 8
  const pwMismatch = adminPasswordConfirm.length > 0 && adminPassword !== adminPasswordConfirm

  return (
    <div>
      <h2 className="text-2xl font-bold text-slate-900 mb-2">Admin jelszó beállítása</h2>
      <p className="text-slate-600 mb-5">
        Adjon meg egy biztonságos jelszót (legalább 8 karakter) az első belépéshez.
      </p>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-5 max-w-3xl mb-8">
        <FieldLabel label="Felhasználónév">
          <input
            type="text"
            value={adminUsername}
            onChange={(e) => onAdminUsernameChange(e.target.value)}
            className="w-full px-3 py-2 rounded-lg border border-slate-300 focus:border-blue-500 focus:ring-2 focus:ring-blue-200 outline-none"
          />
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
          {pwTooShort && <span className="text-xs text-red-600 mt-1 block">Minimum 8 karakter.</span>}
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
          {pwMismatch && <span className="text-xs text-red-600 mt-1 block">A két jelszó nem egyezik.</span>}
        </FieldLabel>
      </div>

      <div className="p-5 rounded-lg bg-slate-50 border border-slate-200">
        <h3 className="text-sm font-semibold text-slate-900 mb-3 inline-flex items-center gap-2">
          <ShieldCheck className="w-4 h-4 text-blue-600" /> Összefoglaló
        </h3>
        <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-2 text-sm">
          <SummaryRow label="Iroda" value={selectedBranch ? `${selectedBranch.name} (#${selectedBranch.code})` : '—'} />
          <SummaryRow label="Város" value={selectedBranch?.city || '—'} />
          <SummaryRow label="Szerver" value={offlineMode ? 'Offline mód' : apiUrl || '—'} />
          <SummaryRow label="Cégkód" value={offlineMode ? '—' : companyCode || '—'} />
          <SummaryRow label="Admin felhasználó" value={adminUsername} />
          <SummaryRow label="Jelszó" value={adminPassword ? '•'.repeat(Math.min(adminPassword.length, 12)) : '—'} />
        </dl>
      </div>

      <p className="mt-5 text-xs text-slate-500">
        A „Telepítés befejezése” gomb megnyomásakor a program kriptográfiai kulcsokat generál,
        elmenti a konfigurációt a helyi .env fájlba, majd automatikusan újraindul.
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
