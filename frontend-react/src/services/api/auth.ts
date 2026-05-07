import { api, REFRESH_ENDPOINT } from './client'

// ================== AUTH API ==================

export interface LoginRequest {
  companyCode: string
  workerCode: string
  password: string
}

export interface GoogleLoginRequest {
  idToken: string
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
  logout: async (): Promise<void> => {
    await api.post('/auth/logout')
  },
  refreshCookie,
  refreshToken: refreshCookie,
  selectRole: async (data: { token: string; roleCode: string }): Promise<LoginResponse> => {
    const response = await api.post<LoginResponse>('/auth/login/select-role', data)
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
