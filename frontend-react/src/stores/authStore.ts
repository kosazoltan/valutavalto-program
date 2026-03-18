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
  // V57: Operatív szerepkör + jogosultságok
  activeRole: string | null
  permissions: string[]
  roles: string[]
  roleSelectionRequired: boolean
  login: (worker: Worker, token: string, tokenType: string, expiresAt: string,
          activeRole?: string | null, permissions?: string[], roles?: string[],
          roleSelectionRequired?: boolean) => void
  selectRole: (token: string, activeRole: string, permissions: string[]) => void
  logout: () => void
  hasRole: (role: string) => boolean
  hasPermission: (permission: string) => boolean
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
  activeRole: null,
  permissions: [],
  roles: [],
  roleSelectionRequired: false,

  login: (worker: Worker, token: string, tokenType: string, expiresAt: string,
          activeRole?: string | null, permissions?: string[], roles?: string[],
          roleSelectionRequired?: boolean) => {
    set({
      worker,
      token,
      tokenType,
      expiresAt,
      isAuthenticated: true,
      activeRole: activeRole ?? null,
      permissions: permissions ?? [],
      roles: roles ?? [],
      roleSelectionRequired: roleSelectionRequired ?? false,
    })
    // Electron: token mentése SQLite-ba (offline login restore-hoz)
    void persistToken(token)
  },

  selectRole: (token: string, activeRole: string, permissions: string[]) => {
    set({
      token,
      activeRole,
      permissions,
      roleSelectionRequired: false,
    })
    // Electron: új token mentése
    void persistToken(token)
  },

  logout: () => {
    set({
      worker: null,
      token: null,
      tokenType: null,
      expiresAt: null,
      isAuthenticated: false,
      activeRole: null,
      permissions: [],
      roles: [],
      roleSelectionRequired: false,
    })
    // Electron: token törlése SQLite-ból
    void clearPersistedToken()
  },

  hasRole: (role: string) => {
    const { worker } = get()
    if (!worker) return false
    return worker.role === role || worker.role === 'ADMIN'
  },

  hasPermission: (permission: string) => {
    const { permissions, worker } = get()
    if (!worker) return false
    // ADMIN-nak mindenhez van jogosultsága
    if (worker.role === 'ADMIN') return true
    return permissions.includes(permission)
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
