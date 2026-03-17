import { create } from 'zustand'
import { persistToken, clearPersistedToken } from '../services/api'

export interface Worker {
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

interface AuthState {
  worker: Worker | null
  token: string | null
  tokenType: string | null
  expiresAt: string | null
  isAuthenticated: boolean
  login: (worker: Worker, token: string, tokenType: string, expiresAt: string) => void
  logout: () => void
  hasRole: (role: string) => boolean
  isManagerOrAbove: () => boolean
  isSupervisorOrAbove: () => boolean
  // Legacy compatibility
  user: Worker | null
}

export const useAuthStore = create<AuthState>()((set, get) => ({
  worker: null,
  token: null,
  tokenType: null,
  expiresAt: null,
  isAuthenticated: false,

  login: (worker: Worker, token: string, tokenType: string, expiresAt: string) => {
    set({
      worker,
      token,
      tokenType,
      expiresAt,
      isAuthenticated: true,
    })
    // Electron: token mentése SQLite-ba (offline login restore-hoz)
    void persistToken(token)
  },

  logout: () => {
    set({
      worker: null,
      token: null,
      tokenType: null,
      expiresAt: null,
      isAuthenticated: false,
    })
    // Electron: token törlése SQLite-ból
    void clearPersistedToken()
  },

  hasRole: (role: string) => {
    const { worker } = get()
    if (!worker) return false
    return worker.role === role || worker.role === 'ADMIN'
  },

  isManagerOrAbove: () => {
    const { worker } = get()
    if (!worker) return false
    return ['MANAGER', 'ADMIN'].includes(worker.role)
  },

  isSupervisorOrAbove: () => {
    const { worker } = get()
    if (!worker) return false
    return ['SUPERVISOR', 'MANAGER', 'ADMIN'].includes(worker.role)
  },

  // Legacy compatibility getter
  get user() {
    return get().worker
  },
}))
