import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { CredentialResponse, GoogleLogin, GoogleOAuthProvider } from '@react-oauth/google'
import { useAuthStore } from '../../stores/authStore'
import { authApi, publicApi, type PublicWorker } from '../../services/api/index'
import { Eye, EyeOff, User, Lock, Building2, Shield, RefreshCw, ChevronDown } from 'lucide-react'
import { getErrorMessage } from '../../utils/errorHandling'
import { useAppMode } from '../../hooks/useAppMode'

/** Szerver (full mód) whitelist: csak ezek a role-ok léphetnek be böngészőben */
const SERVER_ALLOWED_CANONICAL_ROLES = [
  'ugyvezeto', 'foertektar', 'irodavezeto', 'belso_ellenor', 'teruleti_vezeto',
  'biztonsagi_vezeto', 'berszamfejto', 'penzugyi_vezeto', 'irodai_dolgozo',
  'csoportvezeto', 'arfolyam_nezo',
]
// Legacy enum fallback
const SERVER_ALLOWED_LEGACY_ROLES = ['SUPERVISOR', 'MANAGER', 'ADMIN']

export default function LoginPage() {
  const [companyCode, setCompanyCode] = useState('EBC')
  const [workerCode, setWorkerCode] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  // v2.1.4: Branch-alapu dolgozo dropdown. VITE_BRANCH_CODE a Setup Wizard altal kiirt
  // .env-bol jon; ha nincs (webes, offline), text input fallback marad.
  const configuredBranchCode = String(import.meta.env.VITE_BRANCH_CODE ?? '').trim().toUpperCase()
  const [workers, setWorkers] = useState<PublicWorker[]>([])
  const [workersLoading, setWorkersLoading] = useState(false)
  const [workersError, setWorkersError] = useState<string | null>(null)

  // V57: Role-választó modal state
  const [showRoleSelector, setShowRoleSelector] = useState(false)
  const [pendingLoginResponse, setPendingLoginResponse] = useState<Awaited<ReturnType<typeof authApi.login>> | null>(null)
  const [selectedRole, setSelectedRole] = useState<string | null>(null)
  const [roleLoading, setRoleLoading] = useState(false)

  const login = useAuthStore((state) => state.login)
  const selectRole = useAuthStore((state) => state.selectRole)
  const navigate = useNavigate()
  const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID

  /**
   * v2.1.4: Penztarosok lekerese a penztar regioja alapjan (no cache, mindig friss).
   */
  const fetchWorkers = async () => {
    if (!configuredBranchCode) return
    setWorkersLoading(true)
    setWorkersError(null)
    try {
      const list = await publicApi.getWorkersByBranch(configuredBranchCode)
      setWorkers(list)
      if (list.length === 0) {
        setWorkersError(`Nincs aktiv dolgozo a ${configuredBranchCode} penztar regiojahoz rendelve.`)
      }
    } catch (err) {
      setWorkersError('A dolgozo-lista lekerese nem sikerult a szerverrol. Kezi bevitel.')
      console.warn('[LoginPage] publicApi.getWorkersByBranch failed:', err)
    } finally {
      setWorkersLoading(false)
    }
  }

  useEffect(() => {
    if (configuredBranchCode) fetchWorkers()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [configuredBranchCode])

  /**
   * v2.1.4: EBCiroda kanonikus role-alapu default route.
   * - penztar -> /cashier (Lokal Valutavalto)
   * - ertekszallito -> /transfers (atadas-atvetel bizonylat-alairas)
   * - ertektar -> /treasury (Lokal Ertektar)
   * - egyeb szerver role (ugyvezeto, foertektar, stb.) -> /dashboard
   */
  const getDefaultRouteForRole = (role?: string | null): string => {
    const canonical = (role ?? '').toLowerCase()
    if (canonical === 'penztar') return '/cashier'
    if (canonical === 'ertekszallito') return '/transfers'
    if (canonical === 'ertektar') return '/treasury'
    // Legacy enum fallback (CASHIER/MANAGER/ADMIN)
    switch (role) {
      case 'MANAGER':
      case 'TREASURY_MANAGER':
        return '/treasury'
      case 'CASHIER':
        return '/cashier'
      default:
        return '/dashboard'
    }
  }

  const { mode: appMode } = useAppMode()

  /** Login eredmény feldolgozása — ha multi-role, role-választó megjelenítése */
  const handleLoginResponse = (response: Awaited<ReturnType<typeof authApi.login>>) => {
    // Szerver (full mód) whitelist: csak főértéktáros / belső ellenőr / ügyvezető
    const effectiveRole = response.activeRole ?? response.worker.role
    const canonicalAllowed = SERVER_ALLOWED_CANONICAL_ROLES.includes(effectiveRole.toLowerCase())
    const legacyAllowed = SERVER_ALLOWED_LEGACY_ROLES.includes(effectiveRole)

    // v2.1.4: Backend adta validAppModes ellenorzese (robusztusabb mint egyedi role-check)
    if (response.validAppModes && response.validAppModes.length > 0) {
      // A 'full' (szerver admin - ugyvezeto, foertektar, belso_ellenor, irodavezeto)
      // minden appMode-ba belep (supervisory hozzaferes a penztar/ertektar gepekhez is).
      const hasFullAccess = response.validAppModes.includes('full')
      if (!hasFullAccess && !response.validAppModes.includes(appMode)) {
        const allowedProgs = response.validAppModes.map((m) => {
          if (m === 'penztar') return 'Valutaváltó Pénztár (lokál)'
          if (m === 'ertektar') return 'Értéktár (lokál)'
          if (m === 'full') return 'Szerver (böngésző)'
          return m
        }).join(', ')
        setError('Hozzáférés megtagadva. A munkaköröd alapján ezekbe a programokba léphetsz be: ' + allowedProgs + '. Most "' + appMode + '" módban próbálsz belépni.')
        return
      }
    } else if (appMode === 'full' && !canonicalAllowed && !legacyAllowed) {
      setError('Hozzáférés megtagadva. A szerverre csak főértéktáros, belső ellenőr, irodavezető, ügyvezető és egyéb szerver-oldali munkakörök léphetnek be. Pénztárosok és értéktárosok a lokál alkalmazást használják.')
      return
    }

    login(
      response.worker,
      response.token,
      response.tokenType,
      response.expiresAt,
      response.activeRole,
      response.permissions,
      response.roles,
      response.roleSelectionRequired,
    )

    if (response.roleSelectionRequired && response.roles && response.roles.length > 1) {
      // Multi-role worker → role-választó modal megjelenítése
      setPendingLoginResponse(response)
      setShowRoleSelector(true)
    } else {
      navigate(getDefaultRouteForRole(response.activeRole ?? response.worker.role))
    }
  }

  /** Role kiválasztása a modalból */
  const handleRoleSelect = async () => {
    if (!selectedRole || !pendingLoginResponse) return

    setRoleLoading(true)
    setError('')

    try {
      const response = await authApi.selectRole({
        token: pendingLoginResponse.token,
        roleCode: selectedRole,
      })

      // Új token a kiválasztott role-lal
      selectRole(response.token, response.activeRole!, response.permissions ?? [])
      setShowRoleSelector(false)
      setPendingLoginResponse(null)
      navigate(getDefaultRouteForRole(response.activeRole))
    } catch (err: unknown) {
      setError(getErrorMessage(err))
    } finally {
      setRoleLoading(false)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      const response = await authApi.login({
        companyCode,
        workerCode,
        password
      })
      handleLoginResponse(response)
    } catch (err: unknown) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  const handleGoogleSuccess = async (credentialResponse: CredentialResponse) => {
    if (!credentialResponse.credential) {
      setError('Google bejelentkezés sikertelen: hiányzó token')
      return
    }

    setError('')
    setLoading(true)

    try {
      const response = await authApi.googleLogin({
        idToken: credentialResponse.credential
      })
      handleLoginResponse(response)
    } catch (err: unknown) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  // V57: Role-választó modal
  if (showRoleSelector && pendingLoginResponse) {
    return (
      <div className="w-[340px]">
        <div className="bg-form-bg border border-form-border shadow-lg">
          <div className="header-bar flex items-center gap-2 h-8">
            <Shield size={16} />
            <span>Szerepkör kiválasztása</span>
          </div>
          <div className="p-4">
            <p className="text-sm text-gray-600 mb-3">
              Több szerepköre is van. Kérjük válassza ki, melyikkel szeretne belépni:
            </p>

            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 text-sm p-2 rounded mb-3">
                {error}
              </div>
            )}

            <div className="space-y-2 mb-4">
              {pendingLoginResponse.roles?.map((role) => (
                <button
                  key={role}
                  onClick={() => setSelectedRole(role)}
                  className={`w-full text-left p-2 border rounded text-sm ${
                    selectedRole === role
                      ? 'border-primary bg-blue-50 font-semibold'
                      : 'border-form-border hover:bg-gray-50'
                  }`}
                >
                  {role}
                </button>
              ))}
            </div>

            <div className="flex justify-end gap-2">
              <button
                type="button"
                className="form-button"
                onClick={() => {
                  setShowRoleSelector(false)
                  setPendingLoginResponse(null)
                  useAuthStore.getState().logout()
                }}
              >
                Mégsem
              </button>
              <button
                type="button"
                className="form-button-primary px-4"
                disabled={!selectedRole || roleLoading}
                onClick={handleRoleSelect}
              >
                {roleLoading ? 'Betöltés...' : 'Belépés'}
              </button>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="w-[340px]">
      {/* Windows-style login window */}
      <div className="bg-form-bg border border-form-border shadow-lg">
        {/* Title bar */}
        <div className="header-bar flex items-center gap-2 h-8">
          <Lock size={16} />
          <span>RepZtecH Exclusive Best Change - Bejelentkezés</span>
        </div>

        {/* Content */}
        <div className="p-4">
          {/* Logo/Company info */}
          <div className="text-center mb-4">
            <div className="text-lg font-bold text-primary">RepZtecH Exclusive Best Change</div>
            <div className="text-xs text-gray-500">
              Pénzváltó Rendszer v{import.meta.env.VITE_APP_VERSION ?? __APP_VERSION__}
            </div>
          </div>

          {/* Google OAuth — elsődleges belépés */}
          {googleClientId && (
            <div className="mb-3">
              <GoogleOAuthProvider clientId={googleClientId}>
                <div className="flex justify-center">
                  <GoogleLogin
                    onSuccess={handleGoogleSuccess}
                    onError={() => setError('Google bejelentkezés sikertelen')}
                    useOneTap={false}
                    width="300"
                  />
                </div>
              </GoogleOAuthProvider>
            </div>
          )}

          {/* Elválasztó */}
          <div className="flex items-center gap-2 my-3">
            <div className="flex-1 border-t border-form-border" />
            <span className="text-xs text-gray-400">vagy kóddal</span>
            <div className="flex-1 border-t border-form-border" />
          </div>

          {/* Error message */}
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 text-sm p-2 rounded mb-3" data-testid="login-error">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-3">
            {/* Company code field */}
            <div className="form-group-box pt-4">
              <span className="form-group-box-title">Cég kód</span>
              <div className="flex items-center gap-2">
                <Building2 size={18} className="text-gray-400" />
                <input
                  type="text"
                  value={companyCode}
                  onChange={(e) => setCompanyCode(e.target.value.toUpperCase())}
                  className="form-input flex-1"
                  data-testid="login-company-code"
                />
              </div>
            </div>

            {/* Worker code - v2.1.4 dropdown (regio-alapu) + szoveges fallback */}
            <div className="form-group-box pt-4">
              <span className="form-group-box-title">
                Pénztáros {configuredBranchCode ? `(${configuredBranchCode} régió)` : 'kód'}
              </span>
              <div className="flex items-center gap-2">
                <User size={18} className="text-gray-400" />
                {configuredBranchCode && workers.length > 0 ? (
                  <div className="flex-1 flex items-center gap-1">
                    <div className="relative flex-1">
                      <select
                        value={workerCode}
                        onChange={(e) => setWorkerCode(e.target.value.toUpperCase())}
                        className="form-input flex-1 w-full pr-8 appearance-none"
                        data-testid="login-worker-code"
                        autoFocus
                      >
                        <option value="">-- Válasszon pénztárost --</option>
                        {workers.map((w) => (
                          <option key={w.code} value={w.code}>
                            {w.name}
                          </option>
                        ))}
                      </select>
                      <ChevronDown size={14} className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                    </div>
                    <button
                      type="button"
                      onClick={fetchWorkers}
                      disabled={workersLoading}
                      className="p-1 hover:bg-gray-100 rounded"
                      title="Dolgozó-lista frissítése a szerverről"
                    >
                      <RefreshCw size={14} className={workersLoading ? 'animate-spin text-gray-300' : 'text-gray-500'} />
                    </button>
                  </div>
                ) : (
                  <input
                    type="text"
                    value={workerCode}
                    onChange={(e) => setWorkerCode(e.target.value.toUpperCase())}
                    className="form-input flex-1"
                    autoFocus
                    data-testid="login-worker-code"
                    placeholder={workersLoading ? 'Dolgozók betöltése...' : configuredBranchCode ? 'Pénztáros kód vagy név' : 'Pénztáros kód'}
                  />
                )}
              </div>
              {workersError && (
                <div className="text-xs text-amber-600 mt-1">{workersError}</div>
              )}
            </div>

            {/* Password field */}
            <div className="form-group-box pt-4">
              <span className="form-group-box-title">Jelszó</span>
              <div className="flex items-center gap-2">
                <Lock size={18} className="text-gray-400" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="form-input flex-1"
                  data-testid="login-password"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="p-1 hover:bg-gray-100 rounded"
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            {/* Buttons */}
            <div className="flex justify-end gap-2 pt-2">
              <button
                type="button"
                className="form-button"
                onClick={() => {
                  setWorkerCode('')
                  setPassword('')
                }}
              >
                Mégsem
              </button>
              <button
                type="submit"
                className="form-button-primary px-6"
                disabled={loading || !companyCode || !workerCode || !password}
                data-testid="login-submit"
              >
                {loading ? 'Bejelentkezés...' : 'Bejelentkezés'}
              </button>
            </div>
          </form>

          {/* Footer info */}
          <div className="mt-4 pt-3 border-t border-form-border text-xs text-gray-500 text-center">
            <div>© 2026 RepZtecH Exclusive Best Change Zrt.</div>
            <div>Minden jog fenntartva.</div>
          </div>
        </div>
      </div>
    </div>
  )
}
