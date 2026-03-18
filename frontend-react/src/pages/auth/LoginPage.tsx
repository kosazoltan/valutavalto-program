import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { CredentialResponse, GoogleLogin, GoogleOAuthProvider } from '@react-oauth/google'
import { useAuthStore } from '../../stores/authStore'
import { authApi } from '../../services/api'
import { Eye, EyeOff, User, Lock, Building2 } from 'lucide-react'
import { getErrorMessage } from '../../utils/errorHandling'

export default function LoginPage() {
  const [companyCode, setCompanyCode] = useState('EBC')
  const [workerCode, setWorkerCode] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const login = useAuthStore((state) => state.login)
  const navigate = useNavigate()
  const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID

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
      // TODO: ha roleSelectionRequired, akkor role-választó oldalra irányítás
      navigate('/dashboard')
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
      navigate('/dashboard')
    } catch (err: unknown) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
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
            <div className="bg-red-50 border border-red-200 text-red-700 text-sm p-2 rounded mb-3">
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
