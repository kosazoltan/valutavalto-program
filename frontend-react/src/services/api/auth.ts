import { api, REFRESH_ENDPOINT } from './client'

// ================== AUTH API ==================

export interface LoginRequest {
  companyCode: string
  workerCode: string
  password: string
  appMode?: string
}

export interface GoogleLoginRequest {
  idToken: string
  appMode?: string
  // FK-ÉRTÉKTÁR (V285): a kliens támogatja a kétlépcsős értéktári belépést (dolgozóválasztó).
  supportsVaultWorkerSelection?: boolean
}

/** FK-ÉRTÉKTÁR (V285): a dolgozóválasztó egy eleme. */
export interface VaultWorkerOption {
  id: number
  name: string
}

/** FK-ÉRTÉKTÁR (V285): a kétlépcsős belépés 2. fázisának request-je. */
export interface VaultWorkerSelectRequest {
  idToken: string
  workerId: number
  password: string
  appMode?: string
}

/** FK-ÉRTÉKTÁR (V285): új értéktári dolgozó felvétele. */
export interface VaultWorkerCreateRequest {
  name: string
  password: string
  passwordConfirm: string
}

export interface LoginResponse {
  token: string
  tokenType: string
  expiresAt: string
  worker: {
    id: number
    workerCode: string
    firstName: string
    lastName: string
    fullName: string
    role: string
    branchId: string
    branchCode: string
    branchName: string
    companyId: string
    companyCode: string
    companyName: string
  }
  roles?: string[]
  activeRole?: string | null
  permissions?: string[]
  roleSelectionRequired?: boolean
  validAppModes?: string[]
  centralModules?: string[]
  mfaRequired?: boolean
  // FK-ÉRTÉKTÁR (V285): intézményi fiók → dolgozóválasztó (nincs token, amíg nincs jelszavas 2. fázis).
  vaultWorkerSelectionRequired?: boolean
  vaultWorkers?: VaultWorkerOption[]
  vaultBranchName?: string
}

export interface MfaVerifyResponse {
  verified: boolean
  message: string
}

const refreshCookie = async (): Promise<{ token: string }> => {
  const response = await api.post<{ token: string }>(REFRESH_ENDPOINT)
  return response.data
}

export const authApi = {
  login: async (data: LoginRequest): Promise<LoginResponse> => {
    const response = await api.post<LoginResponse>('/auth/login', data)
    return response.data
  },
  googleLogin: async (data: GoogleLoginRequest): Promise<LoginResponse> => {
    const response = await api.post<LoginResponse>('/auth/google-login', data)
    return response.data
  },
  /**
   * FK-ÉRTÉKTÁR (V285): a kétlépcsős értéktári belépés 2. fázisa — a kiválasztott személyes
   * dolgozó jelszavas hitelesítése (a Google ID tokent újraküldjük az intézményi fiók igazolásához).
   */
  googleVaultSelectWorker: async (data: VaultWorkerSelectRequest): Promise<LoginResponse> => {
    const response = await api.post<LoginResponse>('/auth/google-vault/select-worker', data)
    return response.data
  },
  logout: async (): Promise<void> => {
    await api.post('/auth/logout')
  },
  refreshCookie,
  selectRole: async (data: { token: string; roleCode: string; appMode?: string }): Promise<LoginResponse> => {
    const response = await api.post<LoginResponse>('/auth/login/select-role', data)
    return response.data
  },
  verifyMfa: async (token: string, code: string, tokenType = 'Bearer'): Promise<MfaVerifyResponse> => {
    const response = await api.post<MfaVerifyResponse>('/mfa/verify', { code }, {
      headers: { Authorization: `${tokenType} ${token}` },
    })
    return response.data
  },
  verifyMfaBackup: async (token: string, code: string, tokenType = 'Bearer'): Promise<MfaVerifyResponse> => {
    const response = await api.post<MfaVerifyResponse>('/mfa/verify-backup', { code }, {
      headers: { Authorization: `${tokenType} ${token}` },
    })
    return response.data
  },
  /**
   * v2.3.0: Elfelejtett jelszo — token igenyles.
   * Dev modban a response tartalmazza a token-t (testing). Production-ban
   * csak email-ben megy ki.
   */
  forgotPassword: async (email: string): Promise<{ message: string; token?: string }> => {
    const response = await api.post<{ message: string; token?: string }>('/auth/forgot-password', { email })
    return response.data
  },
  /**
   * v2.3.0: Uj jelszo beallitas reset token + uj jelszo alapjan.
   */
  resetPassword: async (token: string, newPassword: string): Promise<{ message: string }> => {
    const response = await api.post<{ message: string }>('/auth/reset-password', { token, newPassword })
    return response.data
  }
}

/**
 * FK-ÉRTÉKTÁR (V285): értéktári személyes dolgozók kezelése (felvétel + listázás).
 * A bejelentkezett értéktáros a SAJÁT értéktárába vehet fel munkatársat — a backend a
 * company/branch-et a SecurityContextből veszi.
 */
export const vaultWorkerApi = {
  list: async (): Promise<VaultWorkerOption[]> => {
    const response = await api.get<VaultWorkerOption[]>('/vault-workers')
    return response.data
  },
  create: async (data: VaultWorkerCreateRequest): Promise<VaultWorkerOption> => {
    const response = await api.post<VaultWorkerOption>('/vault-workers', data)
    return response.data
  },
}
