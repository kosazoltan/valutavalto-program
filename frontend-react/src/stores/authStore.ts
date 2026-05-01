import { create } from 'zustand'
import { persistToken, clearPersistedToken } from '../services/api/index'

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
  hasCanonicalRole: (canonicalRoles: string | string[]) => boolean
  hasPermission: (permission: string) => boolean
  isManagerOrAbove: () => boolean
  isSupervisorOrAbove: () => boolean
  // Legacy compatibility
  user: Worker | null
}

export const useAuthStore = create<AuthState>()((set, get) => ({
  worker: null,
  user: null, // 2026-05-01 fix: legacy compat field, login()-ban tükrözzük worker-t
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
      // 2026-05-01 fix: a `user` field legacy compat — eddig SOSE volt set,
      // ezért a UI (MainLayout `Telephely: {user?.branchName || 'Központi'}`)
      // mindig "Központi" fallback-et mutatott a tényleges branch-név helyett.
      // Most tükrözzük a worker-t user-be.
      user: worker,
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
      user: null,
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
    const { worker, activeRole } = get()
    if (!worker) return false
    // V57: activeRole az elsődleges, fallback worker.role-ra
    const effectiveRole = activeRole || worker.role
    return effectiveRole === role || effectiveRole === 'ADMIN'
  },

  hasPermission: (permission: string) => {
    const { permissions, worker, activeRole } = get()
    if (!worker) return false
    // ADMIN-nak mindenhez van jogosultsága
    const effectiveRole = activeRole || worker.role
    if (effectiveRole === 'ADMIN') return true
    return permissions.includes(permission)
  },

  isManagerOrAbove: () => {
    const { worker, activeRole } = get()
    if (!worker) return false
    const effectiveRole = activeRole || worker.role
    return ['MANAGER', 'ADMIN'].includes(effectiveRole)
  },

  /**
   * v2.1.4: EBCiroda kanonikus role check.
   * A V147 migracio utan minden worker a canonical role kodokkal rendelkezik
   * (penztar, ertekszallito, ertektar, foertektar, ugyvezeto, stb.).
   * Backend response roles lista es activeRole tartalmazza.
   */
  hasCanonicalRole: (canonicalRoles: string | string[]) => {
    const { roles, activeRole, worker } = get()
    // ADMIN fallback: teljes hozzaferes minden canonical role-hoz (konzisztens a tobbi helperrel)
    const effectiveRole = activeRole || worker?.role
    if (effectiveRole === 'ADMIN') return true
    const list = Array.isArray(canonicalRoles) ? canonicalRoles : [canonicalRoles]
    if (activeRole && list.includes(activeRole)) return true
    return (roles ?? []).some((r: string) => list.includes(r))
  },

  isSupervisorOrAbove: () => {
    const { worker, activeRole } = get()
    if (!worker) return false
    const effectiveRole = activeRole || worker.role
    return ['SUPERVISOR', 'MANAGER', 'ADMIN'].includes(effectiveRole)
  },

  // Legacy compat: a `user` field-et a `login`/`logout` set()-ekben tükrözzük worker-re.
  // Korábbi `get user() { return get().worker }` getter NEM reaktív Zustand snapshot-ban
  // (lasd ProfitPage komment 2026-04-29) — emiatt mindig null volt, és a Telephely
  // fejléc 'Központi' fallback-et mutatott a valós branch-név helyett.
}))
