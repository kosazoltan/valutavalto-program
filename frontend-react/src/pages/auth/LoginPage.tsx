import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { CredentialResponse, GoogleLogin, GoogleOAuthProvider } from '@react-oauth/google'
import { useAuthStore } from '../../stores/authStore'
import { authApi, publicApi, type LoginResponse, type PublicWorker } from '../../services/api/index'
import { Eye, EyeOff, User, Lock, Building2, Shield, RefreshCw, ChevronDown } from 'lucide-react'
import { getErrorMessage, humanizeIpcError } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { useAppMode } from '../../hooks/useAppMode'
import {
  appModeLabel,
  canonicalizeRoleForAppMode,
  isRoleSelectableForAppMode,
  roleDisplayName,
  selectableLocalAppModes,
  preferredRoleForAppMode,
} from '../../utils/appModeRoles'
import {
  setSessionAppMode,
  clearSessionAppMode,
  getSessionAppMode,
} from '../../utils/sessionAppMode'
import {
  isLocalTerminalClient,
  isCentralWorkstationFlavor,
  isRateMakerFlavor,
} from '../../utils/clientEnv'
import type { AppMode } from '../../types/appMode'
import { useTranslation } from 'react-i18next'
import { useLoginScreenUpdateWindow } from '../../hooks/useLoginScreenUpdateWindow'
import i18n from '../../i18n'

/**
 * Setup wizard altal elmentett config (localStorage / Electron config).
 * Amit a LoginPage pre-fill-hez hasznal.
 */
function readSetupConfig(): { companyCode?: string; workerCode?: string; workerName?: string } {
  try {
    const raw = localStorage.getItem('valuta-setup-config')
    if (!raw) return {}
    const parsed = JSON.parse(raw) as {
      companyCode?: string
      workerCode?: string
      workerName?: string
    }
    return parsed
  } catch {
    return {}
  }
}

export default function LoginPage() {
  const { t } = useTranslation()

  // FKH-041 D8: az appMode a jelentés ELŐTT kell feloldódjon (useAppMode Electronban
  // aszinkron tölt az SQLite config store-ból) — ezért a hook-hívás az effekt ELŐTT áll.
  const { mode: appMode, isLoading: appModeLoading } = useAppMode()

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
  const configuredBranchCode = String(import.meta.env.VITE_BRANCH_CODE ?? '')
    .trim()
    .toUpperCase()
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
  const [pendingLoginResponse, setPendingLoginResponse] = useState<Awaited<
    ReturnType<typeof authApi.login>
  > | null>(null)
  const [selectedRole, setSelectedRole] = useState<string | null>(null)
  const [roleLoading, setRoleLoading] = useState(false)

  // MFA login 2. lépés: a token még nem kerülhet a perzisztált auth store-ba.
  const [showMfaChallenge, setShowMfaChallenge] = useState(false)
  const [pendingMfaResponse, setPendingMfaResponse] = useState<LoginResponse | null>(null)
  const [pendingMfaGoogleIdToken, setPendingMfaGoogleIdToken] = useState<string | undefined>(
    undefined,
  )
  const [mfaCode, setMfaCode] = useState('')
  const [mfaBackupMode, setMfaBackupMode] = useState(false)
  const [mfaLoading, setMfaLoading] = useState(false)
  const [mfaError, setMfaError] = useState('')

  // HIBA 2026-05-26: program-mód választó (értéktáros/vezető több módba is beléphet)
  const [showModeSelector, setShowModeSelector] = useState(false)
  const [pendingModeResponse, setPendingModeResponse] = useState<Awaited<
    ReturnType<typeof authApi.login>
  > | null>(null)
  const [modeSelectorOptions, setModeSelectorOptions] = useState<AppMode[]>([])
  const [modeLoading, setModeLoading] = useState(false)

  // FK-ÉRTÉKTÁR (V285): kétlépcsős értéktári belépés — Google után dolgozóválasztó + jelszó.
  const [showVaultWorkerSelect, setShowVaultWorkerSelect] = useState(false)
  const [vaultWorkers, setVaultWorkers] = useState<
    import('../../services/api/auth').VaultWorkerOption[]
  >([])
  const [vaultBranchName, setVaultBranchName] = useState<string>('')
  const [vaultIdToken, setVaultIdToken] = useState<string>('')
  const [selectedVaultWorkerId, setSelectedVaultWorkerId] = useState<number | null>(null)
  const [vaultPassword, setVaultPassword] = useState('')
  const [vaultLoading, setVaultLoading] = useState(false)
  const [vaultError, setVaultError] = useState<string | null>(null)
  const [showVaultForgot, setShowVaultForgot] = useState(false)

  const login = useAuthStore((state) => state.login)
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
  const googleOAuthDisabled = import.meta.env.VITE_DISABLE_GOOGLE_OAUTH === '1'
  const googleClientId =
    !googleOAuthDisabled &&
    rawGoogleClientId &&
    rawGoogleClientId !== 'none' &&
    rawGoogleClientId.trim().length > 0
      ? rawGoogleClientId.trim()
      : null

  const isElectron =
    typeof window !== 'undefined' &&
    Boolean(window.electronAPI?.googleOAuthFlow) &&
    !googleOAuthDisabled
  const [googleLoadingElectron, setGoogleLoadingElectron] = useState(false)

  // A belépés BÁRMELY lépése alatt tilos telepítési ablakot jelenteni (Google OTP 2-3 perc).
  const loginInteractionInFlight =
    googleLoadingElectron ||
    loading ||
    mfaLoading ||
    roleLoading ||
    modeLoading ||
    vaultLoading ||
    showMfaChallenge ||
    showRoleSelector ||
    showModeSelector ||
    showVaultWorkerSelect ||
    showForgotPassword

  useLoginScreenUpdateWindow({
    appMode,
    appModeLoading,
    interactionInFlight: loginInteractionInFlight,
  })

  /**
   * v2.1.4: Penztarosok lekerese a penztar regioja alapjan (no cache, mindig friss).
   */
  const fetchWorkers = async () => {
    if (!configuredBranchCode) return
    setWorkersLoading(true)
    setWorkersError(null)
    try {
      const list = await publicApi.getWorkersByBranch(
        configuredBranchCode,
        companyCode.trim().toUpperCase(),
      )
      setWorkers(list)
      if (list.length === 0) {
        setWorkersError(
          `Nincs aktiv dolgozo a ${configuredBranchCode} penztar regiojahoz rendelve.`,
        )
      }
    } catch (err) {
      setWorkersError('A dolgozo-lista lekerese nem sikerult a szerverrol. Kezi bevitel.')
      logger.warn('LoginPage', 'publicApi.getWorkersByBranch failed', err)
    } finally {
      setWorkersLoading(false)
    }
  }

  useEffect(() => {
    if (configuredBranchCode) fetchWorkers()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [configuredBranchCode, companyCode])

  /**
   * v2.1.4: EBCiroda kanonikus role-alapu default route.
   * - penztar -> /cashier (Lokal Valutavalto)
   * - ertekszallito role -> /transfers (atadas-atvetel bizonylat-alairas)
   * - ertektar -> /treasury (Lokal Ertektar)
   * - egyeb szerver role (ugyvezeto, foertektar, stb.) -> /dashboard
   */
  const getDefaultRouteForRole = (role?: string | null): string => {
    if (isCentralWorkstationFlavor()) return '/central-workstation'
    // Codex/Copilot #581 fix: rate-maker app default landing /rates/main (Főlap, 0-s lap)
    // — konzisztens az App.tsx-ben definiált defaultProtectedRoute-tal.
    if (appMode === 'rate-maker' || isRateMakerFlavor()) return '/rates/main'
    // FK-041/II: az árfolyam néző (full/Szerver mód, böngészőből) a versenytárs-árfolyam beíró oldalra
    // landol — ez az egyetlen feladata (mobil/PWA). A /central-workstation általános full-landing elé.
    if (canonicalizeRoleForAppMode(role) === 'arfolyam_nezo') return '/competitor-rates'
    if (appMode === 'full') return '/central-workstation'
    const canonical = canonicalizeRoleForAppMode(role)
    if (canonical === 'penztar') return '/cashier'
    if (canonical === 'ertekszallito') return '/transfers'
    if (canonical === 'ertektar') return '/treasury'
    return '/dashboard'
  }

  // HIBA 2026-05-26: csak a lokál terminál (penztar-client, nincs flavor + Electron) ajánl
  // program-mód választót. Böngészőben (full) és a kozponti/rate-maker flavor-buildekben nem.
  // A detektálás a központi clientEnv util-ban (Sourcery #860: nincs szétszórt flavor-check).
  const localTerminalClient = isLocalTerminalClient()

  /** Mód-választó eredménye: a választott módra select-role → megfelelő role+token, majd navigáció. */
  const handleModeSelect = async (mode: AppMode) => {
    if (!pendingModeResponse) return
    setModeLoading(true)
    setError('')
    try {
      const roleCode = preferredRoleForAppMode(
        pendingModeResponse.roles,
        mode,
        pendingModeResponse.activeRole ?? pendingModeResponse.worker.role,
      )
      if (!roleCode) {
        setError('Nincs a választott programhoz használható szerepkör.')
        return
      }
      setSessionAppMode(mode)
      const response = await authApi.selectRole({
        token: pendingModeResponse.token,
        roleCode,
        appMode: mode,
      })
      login(
        response.worker,
        response.token,
        response.tokenType,
        response.expiresAt,
        response.activeRole,
        response.permissions,
        response.roles,
        false,
        response.centralModules ?? null,
      )
      setShowModeSelector(false)
      setPendingModeResponse(null)
      navigate(getDefaultRouteForMode(mode, response.activeRole))
    } catch (err: unknown) {
      clearSessionAppMode()
      setError(getErrorMessage(err))
    } finally {
      setModeLoading(false)
    }
  }

  /** Mód-specifikus default route (a session appMode még nem frissült a hívás pillanatában). */
  const getDefaultRouteForMode = (mode: AppMode, role?: string | null): string => {
    if (mode === 'penztar') return '/cashier'
    if (mode === 'ertektar') return '/treasury'
    return getDefaultRouteForRole(role)
  }

  const resetMfaChallenge = () => {
    setShowMfaChallenge(false)
    setPendingMfaResponse(null)
    setPendingMfaGoogleIdToken(undefined)
    setMfaCode('')
    setMfaBackupMode(false)
    setMfaLoading(false)
    setMfaError('')
  }

  /** Login eredmény feldolgozása — MFA, multi-role és mód-választó szerint. */
  const handleLoginResponse = (
    response: Awaited<ReturnType<typeof authApi.login>>,
    googleIdToken?: string,
    mfaVerified = false,
  ) => {
    // FK-ÉRTÉKTÁR (V285): intézményi (közös) Google-fiók → a backend dolgozóválasztót kért.
    // NINCS token; a felhasználó kiválasztja a SAJÁT nevét, majd jelszót ad (2. fázis).
    if (response.vaultWorkerSelectionRequired) {
      if (!googleIdToken) {
        setError('A személyes belépéshez újra be kell jelentkezni Google-fiókkal.')
        return
      }
      setVaultWorkers(response.vaultWorkers ?? [])
      setVaultBranchName(response.vaultBranchName ?? '')
      setVaultIdToken(googleIdToken)
      setSelectedVaultWorkerId(
        response.vaultWorkers && response.vaultWorkers.length === 1
          ? response.vaultWorkers[0]!.id
          : null,
      )
      setVaultPassword('')
      setVaultError(null)
      setShowVaultWorkerSelect(true)
      return
    }

    if (response.mfaRequired && !mfaVerified) {
      if (!response.token) {
        setError('A szerver MFA ellenőrzést kért, de nem adott ellenőrizhető login tokent.')
        return
      }
      setPendingMfaResponse(response)
      setPendingMfaGoogleIdToken(googleIdToken)
      setMfaCode('')
      setMfaBackupMode(false)
      setMfaError('')
      setShowMfaChallenge(true)
      return
    }

    // HIBA 2026-05-26: ha a dolgozó több lokál módba is beléphet (pl. értéktáros, aki a
    // pénztárt is ellenőrizheti), a lokál terminálon mód-választót mutatunk — KIVÉVE ha
    // már választott a munkamenetben. Tiszta pénztáros (1 mód) → nincs választó, megy egyből.
    if (localTerminalClient && !getSessionAppMode()) {
      const localModes = selectableLocalAppModes(response.validAppModes)
      if (localModes.length > 1) {
        setPendingModeResponse(response)
        setModeSelectorOptions(localModes)
        setShowModeSelector(true)
        return
      }
    }

    // Szerver (full mód) whitelist: a kozponti admin/felugyeleti role-ok kozos allowlistaja.
    const effectiveRole = response.activeRole ?? response.worker.role
    const serverAllowed = isRoleSelectableForAppMode(effectiveRole, 'full')

    // v2.1.4: Backend adta validAppModes ellenorzese (robusztusabb mint egyedi role-check)
    if (response.validAppModes && response.validAppModes.length > 0) {
      const hasFullAccess = response.validAppModes.includes('full')
      const hasRequestedAppAccess = response.validAppModes.includes(appMode)
      if (!hasRequestedAppAccess && !(appMode !== 'rate-maker' && hasFullAccess)) {
        const allowedProgs = response.validAppModes
          .map((m) => {
            if (m === 'penztar') return 'Valutaváltó Pénztár (lokál)'
            if (m === 'ertektar') return 'Értéktár (lokál)'
            if (m === 'rate-maker') return 'Árfolyamkészítő (lokál)'
            if (m === 'full') return 'Szerver (böngésző)'
            return m
          })
          .join(', ')
        setError(
          'Hozzáférés megtagadva. A munkaköröd alapján ezekbe a programokba léphetsz be: ' +
            allowedProgs +
            '. Most "' +
            appMode +
            '" módban próbálsz belépni.',
        )
        return
      }
    } else if (appMode === 'full' && !serverAllowed) {
      setError(
        'Hozzáférés megtagadva. A szerverre csak főértéktáros, belső ellenőr, irodavezető, ügyvezető és egyéb szerver-oldali munkakörök léphetnek be. Pénztárosok és értéktárosok a lokál alkalmazást használják.',
      )
      return
    }

    if (response.roleSelectionRequired) {
      if (!response.roles || response.roles.length < 1) {
        setError(
          'A bejelentkezés szerepkör-választást kér, de a szerver nem adott választható szerepköröket.',
        )
        return
      }
      const selectableRoles = response.roles
      if (selectableRoles.length === 0) {
        setError(
          `Hozzáférés megtagadva. Egyik választható szerepkör sem használható ebben a programban: ${appModeLabel(appMode)}.`,
        )
        return
      }
      // Multi-role worker: a session itt meg ideiglenes. Nem mentjuk a tokent
      // es nem jeloljuk authenticated-nek, amig a /login/select-role nem ad
      // vegleges, activeRole-lal ellatott tokent es refresh cookie-t.
      setPendingLoginResponse(response)
      setSelectedRole(selectableRoles.length === 1 ? selectableRoles[0]! : null)
      setShowRoleSelector(true)
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
      false,
      response.centralModules ?? null,
    )
    navigate(getDefaultRouteForRole(response.activeRole ?? response.worker.role))
  }

  const handleMfaChallengeSubmit = async () => {
    if (!pendingMfaResponse) return
    const submittedCode = mfaCode.trim()
    const requiredLength = mfaBackupMode ? 8 : 6
    if (!new RegExp(`^\\d{${requiredLength}}$`).test(submittedCode)) {
      setMfaError(
        mfaBackupMode ? 'A backup kód pontosan 8 számjegyű.' : 'A TOTP kód pontosan 6 számjegyű.',
      )
      return
    }

    setMfaLoading(true)
    setMfaError('')
    try {
      const tokenType = pendingMfaResponse.tokenType ?? 'Bearer'
      const result = mfaBackupMode
        ? await authApi.verifyMfaBackup(pendingMfaResponse.token, submittedCode, tokenType)
        : await authApi.verifyMfa(pendingMfaResponse.token, submittedCode, tokenType)
      if (!result.verified) {
        setMfaError(result.message || 'MFA ellenőrzés sikertelen.')
        return
      }
      const verifiedResponse = pendingMfaResponse
      const verifiedGoogleIdToken = pendingMfaGoogleIdToken
      resetMfaChallenge()
      handleLoginResponse(verifiedResponse, verifiedGoogleIdToken, true)
    } catch (err: unknown) {
      setMfaError(getErrorMessage(err))
    } finally {
      setMfaLoading(false)
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
        appMode,
      })

      // Új, végleges token a kiválasztott role-lal. Itt kezdődik a kliens oldali
      // authenticated session; a pre-role token nem kerül perzisztálásra.
      login(
        response.worker,
        response.token,
        response.tokenType,
        response.expiresAt,
        response.activeRole,
        response.permissions,
        response.roles,
        false,
        response.centralModules ?? null,
      )
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
    if (appModeLoading) {
      setError('A program mód betöltése még folyamatban van. Próbáld újra pár másodperc múlva.')
      return
    }
    setLoading(true)

    try {
      const normalizedCompanyCode = companyCode.trim().toUpperCase()
      const normalizedWorkerCode = workerCode.trim().toUpperCase()
      // v2.5.21 ALTALANOS BEJELENTKEZESI FIX: ha az electron passwordLogin IPC elerheto,
      // azt hasznaljuk (main-process net.request, ESET MITM-tolerans, 3x retry).
      // Fallback: renderer axios (web modra es regi Penztar.exe-re).
      if (window.electronAPI?.passwordLogin) {
        const result = await window.electronAPI.passwordLogin({
          companyCode: normalizedCompanyCode,
          workerCode: normalizedWorkerCode,
          password,
          appMode,
        })
        if (!result.ok) {
          setError(humanizeIpcError(result.code, result.message))
          return
        }
        handleLoginResponse(result.response as Awaited<ReturnType<typeof authApi.login>>)
        return
      }
      const response = await authApi.login({
        companyCode: normalizedCompanyCode,
        workerCode: normalizedWorkerCode,
        password,
        appMode,
      })
      handleLoginResponse(response)
    } catch (err: unknown) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  /**
   * FK-ÉRTÉKTÁR (V285): a kétlépcsős értéktári belépés 2. fázisa — a kiválasztott személyes
   * dolgozó jelszavas hitelesítése. A Google ID tokent (1. fázisból) újraküldjük.
   */
  const handleVaultWorkerLogin = async () => {
    if (!selectedVaultWorkerId) {
      setVaultError('Válaszd ki a neved a listából!')
      return
    }
    if (!vaultPassword) {
      setVaultError('Add meg a jelszavad!')
      return
    }
    setVaultError(null)
    setVaultLoading(true)
    try {
      const response = await authApi.googleVaultSelectWorker({
        idToken: vaultIdToken,
        workerId: selectedVaultWorkerId,
        password: vaultPassword,
        appMode,
      })
      setShowVaultWorkerSelect(false)
      setVaultPassword('')
      handleLoginResponse(response)
    } catch (err: unknown) {
      setVaultError(getErrorMessage(err))
    } finally {
      setVaultLoading(false)
    }
  }

  const handleGoogleSuccess = async (credentialResponse: CredentialResponse) => {
    if (!credentialResponse.credential) {
      setError('Google bejelentkezés sikertelen: hiányzó token')
      return
    }
    if (appModeLoading) {
      setError('A program mód betöltése még folyamatban van. Próbáld újra pár másodperc múlva.')
      return
    }

    setError('')
    setLoading(true)

    try {
      const response = await authApi.googleLogin({
        idToken: credentialResponse.credential,
        appMode,
        supportsVaultWorkerSelection: true,
      })
      handleLoginResponse(response, credentialResponse.credential)
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
    setError('')
    if (appModeLoading) {
      setError('A program mód betöltése még folyamatban van. Próbáld újra pár másodperc múlva.')
      return
    }
    setGoogleLoadingElectron(true)
    setLoading(true)
    try {
      // v2.5.20 Borsi-fix: ha a main-process backend-login flow elerheto, AZT hasznaljuk
      // (megbizhatobb mint a renderer axios.post az ESET MITM-mel terhelt gepeken).
      // Fallback: regi 2-step flow (idToken IPC -> renderer axios.post backend).
      if (window.electronAPI?.googleOAuthFlowWithBackend) {
        // FK-ÉRTÉKTÁR (V285): kétlépcsős-támogatás jelzése; a main process az idTokent is visszaadja.
        const result = await window.electronAPI.googleOAuthFlowWithBackend(appMode, true)
        if (!result.ok) {
          if (result.code !== 'USER_CANCELLED') {
            setError(humanizeIpcError(result.code, result.message))
          }
          return
        }
        // A backend `/auth/google-login` JSON-t explicit `response` mezoben adjuk at,
        // hogy az IPC ok/email boritek ne keveredjen a LoginResponse mezoi koze.
        handleLoginResponse(
          result.response as Awaited<ReturnType<typeof authApi.googleLogin>>,
          result.idToken,
        )
        return
      }
      if (!window.electronAPI?.googleOAuthFlow) {
        setError('Electron Google OAuth API nem elerheto.')
        return
      }
      const result = await window.electronAPI.googleOAuthFlow()
      if (!result.ok) {
        if (result.code !== 'USER_CANCELLED') {
          setError(humanizeIpcError(result.code, result.message))
        }
        return
      }
      const response = await authApi.googleLogin({
        idToken: result.idToken,
        appMode,
        supportsVaultWorkerSelection: true,
      })
      handleLoginResponse(response, result.idToken)
    } catch (err: unknown) {
      setError(getErrorMessage(err))
    } finally {
      setGoogleLoadingElectron(false)
      setLoading(false)
    }
  }

  // V57: Role-választó modal
  // FK-ÉRTÉKTÁR (V285): kétlépcsős értéktári belépés — dolgozóválasztó + jelszó.
  if (showVaultWorkerSelect) {
    return (
      <div className="w-[380px]">
        <div className="bg-form-bg border border-form-border shadow-lg">
          <div className="header-bar flex items-center gap-2 h-8">
            <Shield size={16} />
            <span>
              {i18n.t('literals.ki-dolgozik-most')}
              {vaultBranchName || 'Értéktár'}
            </span>
          </div>
          <div className="p-4">
            <p className="text-sm text-gray-600 mb-3">
              {i18n.t('literals.valaszd-ki-a-neved-a-listabol-majd-add-m')}
            </p>
            {vaultError && (
              <div className="bg-red-50 border border-red-200 text-red-700 text-sm p-2 rounded mb-3">
                {vaultError}
              </div>
            )}

            {vaultWorkers.length === 0 ? (
              <div className="text-sm text-gray-600 mb-4">
                {i18n.t('literals.ehhez-az-ertektarhoz-meg-nincs-felvett-s')}
              </div>
            ) : (
              <div className="space-y-1.5 mb-3 max-h-52 overflow-auto">
                {vaultWorkers.map((w) => (
                  <button
                    key={w.id}
                    type="button"
                    disabled={vaultLoading}
                    onClick={() => {
                      setSelectedVaultWorkerId(w.id)
                      setVaultError(null)
                    }}
                    className={`w-full text-left p-2.5 border rounded text-sm disabled:opacity-50 ${
                      selectedVaultWorkerId === w.id
                        ? 'border-primary bg-blue-50 font-semibold'
                        : 'border-form-border hover:bg-blue-50 hover:border-primary'
                    }`}
                  >
                    {w.name}
                  </button>
                ))}
              </div>
            )}

            {vaultWorkers.length > 0 && (
              <form
                onSubmit={(e) => {
                  e.preventDefault()
                  void handleVaultWorkerLogin()
                }}
              >
                <label className="block mb-3">
                  <span className="form-label">{i18n.t('literals.jelszo')}</span>
                  <input
                    type="password"
                    className="form-input"
                    value={vaultPassword}
                    disabled={vaultLoading || !selectedVaultWorkerId}
                    autoFocus
                    placeholder="Saját jelszó..."
                    onChange={(e) => setVaultPassword(e.target.value)}
                  />
                </label>

                <div className="flex items-center justify-between">
                  <button
                    type="button"
                    className="text-xs text-primary hover:underline"
                    onClick={() => setShowVaultForgot(true)}
                  >
                    {i18n.t('literals.elfelejtett-jelszo')}
                  </button>
                  <button
                    type="submit"
                    className="form-button"
                    disabled={vaultLoading || !selectedVaultWorkerId}
                  >
                    {vaultLoading ? 'Belépés...' : 'Belépés'}
                  </button>
                </div>
              </form>
            )}

            {showVaultForgot && (
              <div className="mt-3 bg-amber-50 border border-amber-200 text-amber-800 text-xs p-2.5 rounded">
                {i18n.t('literals.az-elfelejtett-jelszo-visszaallitasat-az')}
                <button
                  type="button"
                  className="block mt-1.5 text-primary hover:underline"
                  onClick={() => setShowVaultForgot(false)}
                >
                  {i18n.t('literals.ertem')}
                </button>
              </div>
            )}

            <div className="flex justify-end mt-4">
              <button
                type="button"
                className="text-sm text-gray-500 hover:underline"
                disabled={vaultLoading}
                onClick={() => {
                  setShowVaultWorkerSelect(false)
                  setVaultWorkers([])
                  setVaultIdToken('')
                  setSelectedVaultWorkerId(null)
                  setVaultPassword('')
                  setVaultError(null)
                  setShowVaultForgot(false)
                }}
              >
                {i18n.t('literals.megse-vissza')}
              </button>
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (showModeSelector && pendingModeResponse) {
    return (
      <div className="w-[360px]">
        <div className="bg-form-bg border border-form-border shadow-lg">
          <div className="header-bar flex items-center gap-2 h-8">
            <Shield size={16} />
            <span>{i18n.t('literals.melyik-programba-lep-be')}</span>
          </div>
          <div className="p-4">
            <p className="text-sm text-gray-600 mb-3">
              {i18n.t('literals.a-munkakorod-alapjan-tobb-programba-is-b')}
            </p>
            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 text-sm p-2 rounded mb-3">
                {error}
              </div>
            )}

            <div className="space-y-2 mb-4">
              {modeSelectorOptions.map((m) => (
                <button
                  key={m}
                  type="button"
                  disabled={modeLoading}
                  onClick={() => void handleModeSelect(m)}
                  className="w-full text-left p-3 border rounded text-sm border-form-border hover:bg-blue-50 hover:border-primary disabled:opacity-50"
                >
                  <span className="font-semibold">{appModeLabel(m)}</span>
                  {m === 'penztar' && (
                    <span className="block text-xs text-gray-500">
                      {i18n.t('literals.valutavalto-penztar-vetel-eladas-konverz')}
                    </span>
                  )}
                  {m === 'ertektar' && (
                    <span className="block text-xs text-gray-500">
                      {i18n.t('literals.ertektar-keszletek-atadas-atvetel-zaraso')}
                    </span>
                  )}
                </button>
              ))}
            </div>

            <div className="flex justify-end">
              <button
                type="button"
                className="form-button"
                disabled={modeLoading}
                onClick={() => {
                  setShowModeSelector(false)
                  setPendingModeResponse(null)
                  clearSessionAppMode()
                  useAuthStore.getState().logout()
                }}
              >
                {t('common.cancel')}
              </button>
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (showMfaChallenge && pendingMfaResponse) {
    return (
      <div className="w-[340px]">
        <div className="bg-form-bg border border-form-border shadow-lg">
          <div className="header-bar flex items-center gap-2 h-8">
            <Shield size={16} />
            <span>{i18n.t('literals.mfa-ellenorzes')}</span>
          </div>
          <div className="p-4">
            <p className="text-sm text-gray-600 mb-3">
              {i18n.t('literals.add-meg-az-authenticator-app-6-szamjegyu')}
            </p>
            {mfaError && (
              <div
                className="bg-red-50 border border-red-200 text-red-700 text-sm p-2 rounded mb-3"
                data-testid="login-mfa-error"
              >
                {mfaError}
              </div>
            )}

            <div className="space-y-3">
              <div className="form-group-box pt-4">
                <span className="form-group-box-title">
                  {mfaBackupMode ? 'Backup kód' : 'TOTP kód'}
                </span>
                <input
                  type="text"
                  inputMode="numeric"
                  pattern="[0-9]*"
                  maxLength={mfaBackupMode ? 8 : 6}
                  className="form-input w-full text-center font-mono text-lg"
                  value={mfaCode}
                  onChange={(event) =>
                    setMfaCode(
                      event.target.value.replace(/\D/g, '').slice(0, mfaBackupMode ? 8 : 6),
                    )
                  }
                  placeholder={mfaBackupMode ? '12345678' : '123456'}
                  data-testid="login-mfa-code"
                  autoFocus
                />
              </div>

              <button
                type="button"
                className="text-xs text-primary-600 hover:text-primary-700 hover:underline"
                onClick={() => {
                  setMfaBackupMode((prev) => !prev)
                  setMfaCode('')
                  setMfaError('')
                }}
              >
                {mfaBackupMode ? 'Authenticator kód használata' : 'Backup kód használata'}
              </button>

              <div className="flex justify-end gap-2 pt-2">
                <button
                  type="button"
                  className="form-button"
                  disabled={mfaLoading}
                  onClick={resetMfaChallenge}
                >
                  {t('common.cancel')}
                </button>
                <button
                  type="button"
                  className="form-button-primary px-4"
                  disabled={mfaLoading || mfaCode.length !== (mfaBackupMode ? 8 : 6)}
                  onClick={() => void handleMfaChallengeSubmit()}
                >
                  {mfaLoading ? 'Ellenőrzés...' : 'MFA ellenőrzés'}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (showRoleSelector && pendingLoginResponse) {
    const selectableRoles = pendingLoginResponse.roles ?? []
    return (
      <div className="w-[340px]">
        <div className="bg-form-bg border border-form-border shadow-lg">
          <div className="header-bar flex items-center gap-2 h-8">
            <Shield size={16} />
            <span>{t('auth.szerepkorKivalasztasa')}</span>
          </div>
          <div className="p-4">
            <p className="text-sm text-gray-600 mb-3">
              {t('auth.tobbSzerepkoreIsVanKerjukValasszaKiMelyikkelSzeretneBelepni')}
            </p>
            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 text-sm p-2 rounded mb-3">
                {error}
              </div>
            )}

            <div className="space-y-2 mb-4">
              {selectableRoles.map((role) => (
                <button
                  key={role}
                  onClick={() => setSelectedRole(role)}
                  className={`w-full text-left p-2 border rounded text-sm ${
                    selectedRole === role
                      ? 'border-primary bg-blue-50 font-semibold'
                      : 'border-form-border hover:bg-gray-50'
                  }`}
                >
                  {roleDisplayName(role)}
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
                {t('common.cancel')}
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
          <span>{t('auth.exclusiveBestChangeBejelentkezes')}</span>
        </div>

        {/* Content */}
        <div className="p-4">
          {/* Logo/Company info */}
          <div className="text-center mb-4">
            <div className="text-lg font-bold text-primary">{t('auth.exclusiveBestChange')}</div>
            <div className="text-xs text-gray-500">
              {t('auth.penzvaltoRendszerV')}
              {import.meta.env.VITE_APP_VERSION ?? __APP_VERSION__}
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
                disabled={googleLoadingElectron || loading || appModeLoading}
                className="w-full h-10 flex items-center justify-center gap-2 bg-white border border-gray-300 rounded shadow-sm hover:bg-gray-50 disabled:opacity-50 transition"
                data-testid="login-google-electron"
              >
                <svg width="18" height="18" viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg">
                  <path
                    fill="#4285F4"
                    d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844c-.209 1.125-.843 2.078-1.796 2.717v2.258h2.908c1.702-1.567 2.684-3.875 2.684-6.615z"
                  />
                  <path
                    fill="#34A853"
                    d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332C2.438 15.983 5.482 18 9 18z"
                  />
                  <path
                    fill="#FBBC05"
                    d="M3.964 10.71c-.18-.54-.282-1.117-.282-1.71s.102-1.17.282-1.71V4.958H.957C.347 6.173 0 7.548 0 9s.348 2.827.957 4.042l3.007-2.332z"
                  />
                  <path
                    fill="#EA4335"
                    d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0 5.482 0 2.438 2.017.957 4.958L3.964 7.29C4.672 5.163 6.656 3.58 9 3.58z"
                  />
                </svg>
                <span className="text-sm text-gray-700 font-medium">
                  {googleLoadingElectron
                    ? 'Bejelentkezés folyamatban...'
                    : 'Belépés Google fiókkal'}
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
            <span className="text-xs text-gray-400">{t('auth.vagyKoddal')}</span>
            <div className="flex-1 border-t border-form-border" />
          </div>

          {/* Error message */}
          {error && (
            <div
              className="bg-red-50 border border-red-200 text-red-700 text-sm p-2 rounded mb-3"
              data-testid="login-error"
            >
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-3">
            {/* Company code field */}
            <div className="form-group-box pt-4">
              <span className="form-group-box-title">{t('auth.companyCode')}</span>
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
                {t('components.penztaros2')}
                {configuredBranchCode ? `(${configuredBranchCode} régió)` : 'kód'}
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
                        <option value="">{t('auth.valasszonPenztarost')}</option>
                        {workers.map((w) => (
                          <option key={w.code} value={w.code}>
                            {w.name}
                          </option>
                        ))}
                      </select>
                      <ChevronDown
                        size={14}
                        className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none"
                      />
                    </div>
                    <button
                      type="button"
                      onClick={fetchWorkers}
                      disabled={workersLoading}
                      className="p-1 hover:bg-gray-100 rounded"
                      title="Dolgozó-lista frissítése a szerverről"
                    >
                      <RefreshCw
                        size={14}
                        className={workersLoading ? 'animate-spin text-gray-300' : 'text-gray-500'}
                      />
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
                    placeholder={
                      workersLoading
                        ? 'Dolgozók betöltése...'
                        : configuredBranchCode
                          ? 'Pénztáros kód vagy név'
                          : 'Pénztáros kód'
                    }
                  />
                )}
              </div>
              {workersError && <div className="text-xs text-amber-600 mt-1">{workersError}</div>}
              {prefilledWorkerName && workerCode === (setupConfig.workerCode || '') && (
                <div className="text-xs text-green-600 mt-1">
                  {t('auth.ATelepitobenKivalasztottDolgozo')}
                  <strong>{prefilledWorkerName}</strong>
                </div>
              )}
            </div>

            {/* Password field */}
            <div className="form-group-box pt-4">
              <span className="form-group-box-title">{t('auth.password')}</span>
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
                  {t('auth.forgotPassword')}
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
                {t('common.cancel')}
              </button>
              <button
                type="submit"
                className="form-button-primary px-6"
                disabled={loading || appModeLoading || !companyCode || !workerCode || !password}
                data-testid="login-submit"
              >
                {loading ? 'Bejelentkezés...' : 'Bejelentkezés'}
              </button>
            </div>
          </form>

          {/* Footer info */}
          <div className="mt-4 pt-3 border-t border-form-border text-xs text-gray-500 text-center">
            <div>{t('auth.2026ExclusiveBestChangeZrt')}</div>
            <div>{t('auth.mindenJogFenntartva')}</div>
          </div>
        </div>
      </div>

      {/* v2.3.0: Elfelejtett jelszo modal */}
      {showForgotPassword && (
        <div
          className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
          onClick={() => setShowForgotPassword(false)}
        >
          <div
            className="bg-white rounded-lg shadow-xl max-w-md w-full p-6"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="text-xl font-bold text-secondary-900 mb-4">
              {t('auth.elfelejtettJelszo')}
            </h2>
            {!forgotMessage ? (
              <>
                <p className="text-sm text-secondary-600 mb-4">
                  {t(
                    'auth.addMegAzEmailCimedHaRegisztralvaVanEgyResetTokenTKapszVisszaDevModbanIttJelenikMegElesbenEmailBenErkezik',
                  )}
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
                    onClick={() => {
                      setShowForgotPassword(false)
                      setForgotEmail('')
                      setForgotMessage(null)
                    }}
                  >
                    {t('common.cancel')}
                  </button>
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
                        logger.debug(
                          'LoginPage',
                          'forgotPassword request failed (dev-only):',
                          err instanceof Error ? err.message : String(err),
                        )
                        setForgotMessage('Ha az email regisztrált, a reset tokent elküldtük.')
                      } finally {
                        setForgotLoading(false)
                      }
                    }}
                  >
                    {forgotLoading ? 'Küldés...' : 'Küldés'}
                  </button>
                </div>
              </>
            ) : (
              <>
                <div className="mb-4 p-3 rounded-lg bg-blue-50 text-sm text-blue-800 break-all">
                  {forgotMessage}
                </div>
                {resetToken && (
                  <>
                    <label className="block text-sm font-semibold mb-1">
                      {t('auth.ujJelszoMin8Kar')}
                    </label>
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
                        onClick={() => {
                          setShowForgotPassword(false)
                          setForgotEmail('')
                          setForgotMessage(null)
                          setResetToken('')
                          setNewPasswordInput('')
                        }}
                      >
                        {t('common.cancel')}
                      </button>
                      <button
                        type="button"
                        className="form-button-primary"
                        disabled={!newPasswordInput || newPasswordInput.length < 8 || resetLoading}
                        onClick={async () => {
                          setResetLoading(true)
                          try {
                            await authApi.resetPassword(resetToken, newPasswordInput)
                            setForgotMessage(
                              'Jelszó sikeresen beállítva. Most már bejelentkezhetsz.',
                            )
                            setResetToken('')
                            setNewPasswordInput('')
                            setTimeout(() => {
                              setShowForgotPassword(false)
                              setForgotEmail('')
                              setForgotMessage(null)
                            }, 2000)
                          } catch (err) {
                            setForgotMessage(
                              err instanceof Error ? err.message : 'Hiba a jelszó beállításakor.',
                            )
                          } finally {
                            setResetLoading(false)
                          }
                        }}
                      >
                        {resetLoading ? 'Mentés...' : 'Új jelszó beállítása'}
                      </button>
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
