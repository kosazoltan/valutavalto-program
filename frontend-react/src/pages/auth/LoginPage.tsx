import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { CredentialResponse, GoogleLogin, GoogleOAuthProvider } from '@react-oauth/google'
import { useAuthStore } from '../../stores/authStore'
import { authApi, publicApi, type PublicWorker } from '../../services/api/index'
import { Eye, EyeOff, User, Lock, Building2, Shield, RefreshCw, ChevronDown } from 'lucide-react'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { useAppMode } from '../../hooks/useAppMode'

/**
 * Szerver (full mód) whitelist: csak ezek a role-ok léphetnek be böngészőben.
 *
 * V181 (2026-05-03): teruleti_vezeto + biztonsagi_vezeto KIVEVE — ezek a kamera
 * canonical role-ok (lokal penztar modul kameraszoftver), NEM a szerver-admin felulet.
 * A backend `validAppModes` "kamera"-t ad vissza nekik (NEM "full"-t).
 */
const SERVER_ALLOWED_CANONICAL_ROLES = [
  'ugyvezeto', 'foertektar', 'irodavezeto', 'belso_ellenor',
  'berszamfejto', 'penzugyi_vezeto', 'irodai_dolgozo',
  'csoportvezeto', 'arfolyam_nezo',
]
// Legacy enum fallback
const SERVER_ALLOWED_LEGACY_ROLES = ['SUPERVISOR', 'MANAGER', 'ADMIN']

/**
 * Setup wizard altal elmentett config (localStorage / Electron config).
 * Amit a LoginPage pre-fill-hez hasznal.
 */
function readSetupConfig(): { companyCode?: string; workerCode?: string; workerName?: string } {
  try {
    const raw = localStorage.getItem('valuta-setup-config')
    if (!raw) return {}
    const parsed = JSON.parse(raw) as { companyCode?: string; workerCode?: string; workerName?: string }
    return parsed
  } catch {
    return {}
  }
}

export default function LoginPage() {
  // v2.3.0: pre-fill a setup wizard altal beallitott kivalasztott dolgozoval
  const setupConfig = readSetupConfig()
  const [companyCode, setCompanyCode] = useState(setupConfig.companyCode || 'EBC')
  const [workerCode, setWorkerCode] = useState(setupConfig.workerCode || '')
  const prefilledWorkerName = setupConfig.workerName
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

  // v2.3.0: Elfelejtett jelszo modal state
  const [showForgotPassword, setShowForgotPassword] = useState(false)
  const [forgotEmail, setForgotEmail] = useState('')
  const [forgotLoading, setForgotLoading] = useState(false)
  const [forgotMessage, setForgotMessage] = useState<string | null>(null)
  const [resetToken, setResetToken] = useState('')
  const [newPasswordInput, setNewPasswordInput] = useState('')
  const [resetLoading, setResetLoading] = useState(false)

  // V57: Role-választó modal state
  const [showRoleSelector, setShowRoleSelector] = useState(false)
  const [pendingLoginResponse, setPendingLoginResponse] = useState<Awaited<ReturnType<typeof authApi.login>> | null>(null)
  const [selectedRole, setSelectedRole] = useState<string | null>(null)
  const [roleLoading, setRoleLoading] = useState(false)

  const login = useAuthStore((state) => state.login)
  const selectRole = useAuthStore((state) => state.selectRole)
  const navigate = useNavigate()
  // V178/V179 Google OAuth audit (2026-05-03 + Electron Desktop OAuth refactor 2026-05-04):
  // - Web (browser): `<GoogleLogin>` Web SDK popup ID token flow. Mukodik `https://excvaluta.com` origin-en.
  // - Electron (penztar/ertektar): a Web SDK NEM mukodik (`app://localhost` origin reject — `idpiframe_initialization_failed`).
  //   Ezert az Electron a hivatalos Google Desktop OAuth mintat hasznalja: `window.electronAPI.googleOAuthFlow()`
  //   meghivasara a main process indit egy Authorization Code Flow + loopback redirect (RFC 8252) flow-t,
  //   PKCE-vel + Desktop client secret-tel. A vegeredmeny ugyanaz az ID token, amit a backend
  //   `/api/v1/auth/google-login` endpointja validal (a backend audience-listanak mind a Web mind a Desktop
  //   client ID-t fogadnia kell — `GoogleLoginConfig.googleIdTokenVerifier`).
  const rawGoogleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID
  const googleClientId = rawGoogleClientId && rawGoogleClientId !== 'none' && rawGoogleClientId.trim().length > 0
    ? rawGoogleClientId.trim()
    : null

  const isElectron = typeof window !== 'undefined' && Boolean(window.electronAPI?.googleOAuthFlow)
  const [googleLoadingElectron, setGoogleLoadingElectron] = useState(false)

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

  /**
   * Electron Desktop OAuth flow — `window.electronAPI.googleOAuthFlow()` indit egy
   * Authorization Code Flow + loopback redirect (RFC 8252) flow-t a main process-ben.
   * A flow vegen az ID tokent ugyanugy elkuldjuk a backend `/api/v1/auth/google-login`
   * endpointnak, mint a webes `<GoogleLogin>` flow.
   */
  const handleElectronGoogleLogin = async () => {
    if (!window.electronAPI?.googleOAuthFlow) {
      setError('Electron Google OAuth API nem elerheto.')
      return
    }
    setError('')
    setGoogleLoadingElectron(true)
    setLoading(true)
    try {
      const result = await window.electronAPI.googleOAuthFlow()
      if (!result.ok) {
        if (result.code === 'USER_CANCELLED') {
          // User maga megszakitotta — silent (no error message).
        } else {
          setError(`Google bejelentkezés sikertelen: ${result.message}`)
        }
        return
      }
      const response = await authApi.googleLogin({ idToken: result.idToken })
      handleLoginResponse(response)
    } catch (err: unknown) {
      setError(getErrorMessage(err))
    } finally {
      setGoogleLoadingElectron(false)
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
          <span>Exclusive Best Change - Bejelentkezés</span>
        </div>

        {/* Content */}
        <div className="p-4">
          {/* Logo/Company info */}
          <div className="text-center mb-4">
            <div className="text-lg font-bold text-primary">Exclusive Best Change</div>
            <div className="text-xs text-gray-500">
              Pénzváltó Rendszer v{import.meta.env.VITE_APP_VERSION ?? __APP_VERSION__}
            </div>
          </div>

          {/* Google OAuth — elsődleges belépés.
              - Electron: custom "Belépés Google-lel" gomb -> window.electronAPI.googleOAuthFlow()
                (RFC 8252 Desktop Authorization Code Flow + loopback redirect, PKCE-vel)
              - Browser (excvaluta.com): @react-oauth/google `<GoogleLogin>` Web SDK popup ID token flow */}
          {isElectron ? (
            <div className="mb-3">
              <button
                type="button"
                onClick={handleElectronGoogleLogin}
                disabled={googleLoadingElectron || loading}
                className="w-full h-10 flex items-center justify-center gap-2 bg-white border border-gray-300 rounded shadow-sm hover:bg-gray-50 disabled:opacity-50 transition"
                data-testid="login-google-electron"
              >
                <svg width="18" height="18" viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg">
                  <path fill="#4285F4" d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844c-.209 1.125-.843 2.078-1.796 2.717v2.258h2.908c1.702-1.567 2.684-3.875 2.684-6.615z"/>
                  <path fill="#34A853" d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332C2.438 15.983 5.482 18 9 18z"/>
                  <path fill="#FBBC05" d="M3.964 10.71c-.18-.54-.282-1.117-.282-1.71s.102-1.17.282-1.71V4.958H.957C.347 6.173 0 7.548 0 9s.348 2.827.957 4.042l3.007-2.332z"/>
                  <path fill="#EA4335" d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0 5.482 0 2.438 2.017.957 4.958L3.964 7.29C4.672 5.163 6.656 3.58 9 3.58z"/>
                </svg>
                <span className="text-sm text-gray-700 font-medium">
                  {googleLoadingElectron ? 'Bejelentkezés folyamatban...' : 'Belépés Google fiókkal'}
                </span>
              </button>
            </div>
          ) : (
            googleClientId && (
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
            )
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
              {prefilledWorkerName && workerCode === (setupConfig.workerCode || '') && (
                <div className="text-xs text-green-600 mt-1">
                  ✓ A telepitoben kivalasztott dolgozo: <strong>{prefilledWorkerName}</strong>
                </div>
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
              {/* v2.3.0: Elfelejtett jelszo link */}
              <div className="flex justify-end mt-1">
                <button
                  type="button"
                  onClick={() => setShowForgotPassword(true)}
                  className="text-xs text-primary-600 hover:text-primary-700 hover:underline"
                >
                  Elfelejtett jelszó?
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
            <div>© 2026 Exclusive Best Change Zrt.</div>
            <div>Minden jog fenntartva.</div>
          </div>
        </div>
      </div>

      {/* v2.3.0: Elfelejtett jelszo modal */}
      {showForgotPassword && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => setShowForgotPassword(false)}>
          <div className="bg-white rounded-lg shadow-xl max-w-md w-full p-6" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-xl font-bold text-secondary-900 mb-4">Elfelejtett jelszó</h2>
            {!forgotMessage ? (
              <>
                <p className="text-sm text-secondary-600 mb-4">
                  Add meg az email címed. Ha regisztrálva van, egy reset token-t kapsz vissza (dev módban itt jelenik meg, élesben email-ben érkezik).
                </p>
                <input
                  type="email"
                  value={forgotEmail}
                  onChange={(e) => setForgotEmail(e.target.value)}
                  placeholder="user@example.com"
                  className="form-input w-full mb-4"
                  autoFocus
                />
                <div className="flex justify-end gap-2">
                  <button
                    type="button"
                    className="form-button"
                    onClick={() => { setShowForgotPassword(false); setForgotEmail(''); setForgotMessage(null); }}
                  >Mégse</button>
                  <button
                    type="button"
                    className="form-button-primary"
                    disabled={!forgotEmail || forgotLoading}
                    onClick={async () => {
                      setForgotLoading(true)
                      try {
                        const resp = await authApi.forgotPassword(forgotEmail)
                        if (resp.token) {
                          setResetToken(resp.token)
                          setForgotMessage(`Dev-token: ${resp.token}. Add meg az új jelszót.`)
                        } else {
                          setForgotMessage('Ha az email regisztrált, a reset tokent elküldtük.')
                        }
                      } catch (err) {
                        // Anti-enumeration: a user-nek megjelenő üzenet EGYSÉGES (sikeres + fail + network
                        // error ugyanazt mutatja). A hiba-reszleteket CSAK dev mode-ban logoljuk
                        // (logger.debug production-ban suppressed), hogy ne szivargjon info a networkon.
                        // Sourcery PR #223 P3 fix: non-user-visible error capture dev-only log-gal.
                        logger.debug('LoginPage', 'forgotPassword request failed (dev-only):',
                          err instanceof Error ? err.message : String(err))
                        setForgotMessage('Ha az email regisztrált, a reset tokent elküldtük.')
                      } finally {
                        setForgotLoading(false)
                      }
                    }}
                  >{forgotLoading ? 'Küldés...' : 'Küldés'}</button>
                </div>
              </>
            ) : (
              <>
                <div className="mb-4 p-3 rounded-lg bg-blue-50 text-sm text-blue-800 break-all">
                  {forgotMessage}
                </div>
                {resetToken && (
                  <>
                    <label className="block text-sm font-semibold mb-1">Új jelszó (min 8 kar)</label>
                    <input
                      type="password"
                      value={newPasswordInput}
                      onChange={(e) => setNewPasswordInput(e.target.value)}
                      className="form-input w-full mb-4"
                      autoFocus
                    />
                    <div className="flex justify-end gap-2">
                      <button
                        type="button"
                        className="form-button"
                        onClick={() => { setShowForgotPassword(false); setForgotEmail(''); setForgotMessage(null); setResetToken(''); setNewPasswordInput(''); }}
                      >Mégse</button>
                      <button
                        type="button"
                        className="form-button-primary"
                        disabled={!newPasswordInput || newPasswordInput.length < 8 || resetLoading}
                        onClick={async () => {
                          setResetLoading(true)
                          try {
                            await authApi.resetPassword(resetToken, newPasswordInput)
                            setForgotMessage('Jelszó sikeresen beállítva. Most már bejelentkezhetsz.')
                            setResetToken('')
                            setNewPasswordInput('')
                            setTimeout(() => {
                              setShowForgotPassword(false)
                              setForgotEmail('')
                              setForgotMessage(null)
                            }, 2000)
                          } catch (err) {
                            setForgotMessage(err instanceof Error ? err.message : 'Hiba a jelszó beállításakor.')
                          } finally {
                            setResetLoading(false)
                          }
                        }}
                      >{resetLoading ? 'Mentés...' : 'Új jelszó beállítása'}</button>
                    </div>
                  </>
                )}
              </>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
