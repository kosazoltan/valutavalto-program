import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { CredentialResponse, GoogleLogin, GoogleOAuthProvider } from '@react-oauth/google'
import { useAuthStore } from '../../stores/authStore'
import { authApi } from '../../services/api/index'
import { Eye, EyeOff, User, Lock, Building2, Shield } from 'lucide-react'
import { getErrorMessage } from '../../utils/errorHandling'

export default function LoginPage() {
  const [companyCode, setCompanyCode] = useState('EBC')
  const [workerCode, setWorkerCode] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  // V57: Role-választó modal state
  const [showRoleSelector, setShowRoleSelector] = useState(false)
  const [pendingLoginResponse, setPendingLoginResponse] = useState<Awaited<ReturnType<typeof authApi.login>> | null>(null)
  const [selectedRole, setSelectedRole] = useState<string | null>(null)
  const [roleLoading, setRoleLoading] = useState(false)

  const login = useAuthStore((state) => state.login)
  const selectRole = useAuthStore((state) => state.selectRole)
  const navigate = useNavigate()
  const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID

  /** Role-alapú default route meghatározása */
  const getDefaultRouteForRole = (role?: string | null): string => {
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

  /** Login eredmény feldolgozása — ha multi-role, role-választó megjelenítése */
  const handleLoginResponse = (response: Awaited<ReturnType<typeof authApi.login>>) => {
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
            <div className="text-2xl font-bold text-primary">RepZtecH Exclusive Best Change</div>
            <div className="text-xs text-gray-500">Pénzváltó Rendszer v2.0</div>
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

            {/* Worker code field */}
            <div className="form-group-box pt-4">
              <span className="form-group-box-title">Pénztáros kód</span>
              <div className="flex items-center gap-2">
                <User size={18} className="text-gray-400" />
                <input
                  type="text"
                  value={workerCode}
                  onChange={(e) => setWorkerCode(e.target.value.toUpperCase())}
                  className="form-input flex-1"
                  autoFocus
                  data-testid="login-worker-code"
                />
              </div>
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
