import { api } from './client'

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
  refreshToken: async (): Promise<{ token: string }> => {
    const response = await api.post<{ token: string }>('/auth/refresh')
    return response.data
  },
  selectRole: async (data: { token: string; roleCode: string }): Promise<LoginResponse> => {
    const response = await api.post<LoginResponse>('/auth/login/select-role', data)
    return response.data
  }
}
