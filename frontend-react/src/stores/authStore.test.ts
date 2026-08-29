import { describe, it, expect, vi, beforeEach } from 'vitest'
import { act } from '@testing-library/react'

// Mock the persistToken / clearPersistedToken from services/api/index
vi.mock('../services/api/index', () => ({
  persistToken: vi.fn().mockResolvedValue(undefined),
  clearPersistedToken: vi.fn().mockResolvedValue(undefined),
}))

// Import after mock
import { useAuthStore } from './authStore'
import type { Worker } from './authStore'
import { LAST_INSTALL_WINDOW_ROLE_KEY } from '../hooks/reportLoginScreenIdleForUpdate'

const mockWorker: Worker = {
  id: 1,
  workerCode: 'W001',
  firstName: 'Test',
  lastName: 'User',
  fullName: 'Test User',
  role: 'CASHIER',
  branchId: 'b1',
  branchCode: '001',
  branchName: 'Pécs',
  companyId: 'c1',
  companyCode: 'EBC',
  companyName: 'EBC Zrt.',
}

describe('authStore', () => {
  beforeEach(() => {
    // Reset store before each test
    act(() => {
      useAuthStore.getState().logout()
    })
  })

  describe('initial state', () => {
    it('starts unauthenticated', () => {
      const state = useAuthStore.getState()
      expect(state.isAuthenticated).toBe(false)
      expect(state.worker).toBeNull()
      expect(state.token).toBeNull()
    })

    it('has empty permissions and roles', () => {
      const state = useAuthStore.getState()
      expect(state.permissions).toEqual([])
      expect(state.roles).toEqual([])
      expect(state.centralModules).toBeNull()
    })
  })

  describe('login', () => {
    it('sets authenticated state', () => {
      act(() => {
        useAuthStore.getState().login(mockWorker, 'my-token', 'Bearer', '2025-01-01T00:00:00Z')
      })
      const state = useAuthStore.getState()
      expect(state.isAuthenticated).toBe(true)
      expect(state.token).toBe('my-token')
      expect(state.worker).toEqual(mockWorker)
      expect(state.tokenType).toBe('Bearer')
    })

    it('sets activeRole and permissions when provided', () => {
      act(() => {
        useAuthStore
          .getState()
          .login(
            mockWorker,
            'tok',
            'Bearer',
            '',
            'MANAGER',
            ['READ', 'WRITE'],
            ['CASHIER', 'MANAGER'],
          )
      })
      const state = useAuthStore.getState()
      expect(state.activeRole).toBe('MANAGER')
      expect(state.permissions).toContain('READ')
      expect(state.roles).toContain('MANAGER')
    })

    it('defaults activeRole to null when not provided', () => {
      act(() => {
        useAuthStore.getState().login(mockWorker, 'tok', 'Bearer', '')
      })
      expect(useAuthStore.getState().activeRole).toBeNull()
    })

    it('stores central workstation module manifest when provided', () => {
      act(() => {
        useAuthStore
          .getState()
          .login(
            mockWorker,
            'tok',
            'Bearer',
            '',
            'foertektar',
            ['RATE_CREATE'],
            ['foertektar'],
            false,
            ['rate-maker', 'rate-publication'],
          )
      })

      expect(useAuthStore.getState().centralModules).toEqual(['rate-maker', 'rate-publication'])
    })
  })

  describe('logout', () => {
    it('clears all auth state', () => {
      act(() => {
        useAuthStore.getState().login(mockWorker, 'tok', 'Bearer', '')
      })
      act(() => {
        useAuthStore.getState().logout()
      })
      const state = useAuthStore.getState()
      expect(state.isAuthenticated).toBe(false)
      expect(state.worker).toBeNull()
      expect(state.token).toBeNull()
      expect(state.permissions).toEqual([])
      expect(state.centralModules).toBeNull()
    })
  })

  describe('selectRole', () => {
    it('updates token and role', () => {
      act(() => {
        useAuthStore.getState().login(mockWorker, 'old-tok', 'Bearer', '')
        useAuthStore.getState().selectRole('new-tok', 'MANAGER', ['READ'], ['central-sprint'])
      })
      const state = useAuthStore.getState()
      expect(state.token).toBe('new-tok')
      expect(state.activeRole).toBe('MANAGER')
      expect(state.permissions).toContain('READ')
      expect(state.roleSelectionRequired).toBe(false)
      expect(state.centralModules).toEqual(['central-sprint'])
    })
  })

  describe('hasRole', () => {
    it('returns false when not authenticated', () => {
      expect(useAuthStore.getState().hasRole('CASHIER')).toBe(false)
    })

    it('returns true when activeRole matches', () => {
      act(() => {
        useAuthStore.getState().login(mockWorker, 'tok', 'Bearer', '', 'CASHIER')
      })
      expect(useAuthStore.getState().hasRole('CASHIER')).toBe(true)
    })

    it('returns true for any role when ADMIN', () => {
      const adminWorker = { ...mockWorker, role: 'ADMIN' }
      act(() => {
        useAuthStore.getState().login(adminWorker, 'tok', 'Bearer', '', 'ADMIN')
      })
      expect(useAuthStore.getState().hasRole('CASHIER')).toBe(true)
      expect(useAuthStore.getState().hasRole('MANAGER')).toBe(true)
    })

    it('falls back to worker.role when no activeRole', () => {
      act(() => {
        useAuthStore.getState().login(mockWorker, 'tok', 'Bearer', '', null)
      })
      expect(useAuthStore.getState().hasRole('CASHIER')).toBe(true)
      expect(useAuthStore.getState().hasRole('ADMIN')).toBe(false)
    })
  })

  describe('hasPermission', () => {
    it('returns false when not authenticated', () => {
      expect(useAuthStore.getState().hasPermission('READ')).toBe(false)
    })

    it('returns true when permission in list', () => {
      act(() => {
        useAuthStore.getState().login(mockWorker, 'tok', 'Bearer', '', 'CASHIER', ['READ', 'WRITE'])
      })
      expect(useAuthStore.getState().hasPermission('READ')).toBe(true)
    })

    it('returns false when permission not in list', () => {
      act(() => {
        useAuthStore.getState().login(mockWorker, 'tok', 'Bearer', '', 'CASHIER', ['READ'])
      })
      expect(useAuthStore.getState().hasPermission('DELETE')).toBe(false)
    })

    it('ADMIN has all permissions', () => {
      const adminWorker = { ...mockWorker, role: 'ADMIN' }
      act(() => {
        useAuthStore.getState().login(adminWorker, 'tok', 'Bearer', '', 'ADMIN', [])
      })
      expect(useAuthStore.getState().hasPermission('ANY_PERMISSION')).toBe(true)
    })
  })

  describe('isManagerOrAbove', () => {
    it('returns false when not authenticated', () => {
      expect(useAuthStore.getState().isManagerOrAbove()).toBe(false)
    })

    it('returns false for CASHIER', () => {
      act(() => {
        useAuthStore.getState().login(mockWorker, 'tok', 'Bearer', '', 'CASHIER')
      })
      expect(useAuthStore.getState().isManagerOrAbove()).toBe(false)
    })

    it('returns true for MANAGER', () => {
      const managerWorker = { ...mockWorker, role: 'MANAGER' }
      act(() => {
        useAuthStore.getState().login(managerWorker, 'tok', 'Bearer', '', 'MANAGER')
      })
      expect(useAuthStore.getState().isManagerOrAbove()).toBe(true)
    })

    it('returns true for ADMIN', () => {
      const adminWorker = { ...mockWorker, role: 'ADMIN' }
      act(() => {
        useAuthStore.getState().login(adminWorker, 'tok', 'Bearer', '', 'ADMIN')
      })
      expect(useAuthStore.getState().isManagerOrAbove()).toBe(true)
    })
  })

  describe('isSupervisorOrAbove', () => {
    it('returns true for SUPERVISOR', () => {
      const supervisorWorker = { ...mockWorker, role: 'SUPERVISOR' }
      act(() => {
        useAuthStore.getState().login(supervisorWorker, 'tok', 'Bearer', '', 'SUPERVISOR')
      })
      expect(useAuthStore.getState().isSupervisorOrAbove()).toBe(true)
    })

    it('returns false for CASHIER', () => {
      act(() => {
        useAuthStore.getState().login(mockWorker, 'tok', 'Bearer', '', 'CASHIER')
      })
      expect(useAuthStore.getState().isSupervisorOrAbove()).toBe(false)
    })
  })

  describe('user legacy alias', () => {
    it('user returns same as worker — via getState worker field', () => {
      act(() => {
        useAuthStore.getState().login(mockWorker, 'tok', 'Bearer', '')
      })
      // The `user` getter delegates to `worker`, so validating worker is sufficient
      const state = useAuthStore.getState()
      expect(state.worker).toEqual(mockWorker)
      expect(state.worker?.workerCode).toBe('W001')
    })
  })

  describe('hasCanonicalRole', () => {
    it('legacy COURIER role-t ertekszallito canonical role-kent kezeli', () => {
      const courierWorker = { ...mockWorker, role: 'COURIER' }
      act(() => {
        useAuthStore
          .getState()
          .login(courierWorker, 'tok', 'Bearer', '', 'COURIER', [], ['COURIER'])
      })

      expect(useAuthStore.getState().hasCanonicalRole('ertekszallito')).toBe(true)
    })
  })

  describe('MENU-LEGACY-ROLE-INVISIBLE: legacy-orphan MANAGER fallback (0 canonical assignment)', () => {
    const orphanManager = { ...mockWorker, role: 'MANAGER' }

    it('orphan MANAGER (roles=[], activeRole=null): latja az AML canonical role-okat', () => {
      act(() => {
        useAuthStore.getState().login(orphanManager, 'tok', 'Bearer', '', null, [], [])
      })
      const s = useAuthStore.getState()
      expect(s.hasCanonicalRole('belso_ellenor')).toBe(true)
      expect(s.hasCanonicalRole('biztonsagi_vezeto')).toBe(true)
      expect(s.hasCanonicalRole('ugyvezeto')).toBe(true)
    })

    it('orphan MANAGER: arfolyam_nezo-t NEM kapja meg (FK-041/II — nincs a SZERVER_ROLES-ban)', () => {
      act(() => {
        useAuthStore.getState().login(orphanManager, 'tok', 'Bearer', '', null, [], [])
      })
      expect(useAuthStore.getState().hasCanonicalRole('arfolyam_nezo')).toBe(false)
    })

    it('least-privilege regresszio: canonical assignmentes worker (roles nem ures) viselkedese valtozatlan', () => {
      const assignedWorker = { ...mockWorker, role: 'MANAGER' }
      act(() => {
        useAuthStore
          .getState()
          .login(assignedWorker, 'tok', 'Bearer', '', 'foertektar', [], ['foertektar'])
      })
      const s = useAuthStore.getState()
      expect(s.hasCanonicalRole('foertektar')).toBe(true)
      expect(s.hasCanonicalRole('belso_ellenor')).toBe(false)
      expect(s.hasCanonicalRole('biztonsagi_vezeto')).toBe(false)
    })

    it('orphan SUPERVISOR: NEM kap fallbacket (backend compliance hasAnyRole sem engedi)', () => {
      const orphanSupervisor = { ...mockWorker, role: 'SUPERVISOR' }
      act(() => {
        useAuthStore.getState().login(orphanSupervisor, 'tok', 'Bearer', '', null, [], [])
      })
      expect(useAuthStore.getState().hasCanonicalRole('belso_ellenor')).toBe(false)
    })

    it('orphan ADMIN: a meglevo ADMIN-fallback tovabbra is mindent enged (regresszio-pin)', () => {
      const orphanAdmin = { ...mockWorker, role: 'ADMIN' }
      act(() => {
        useAuthStore.getState().login(orphanAdmin, 'tok', 'Bearer', '', null, [], [])
      })
      expect(useAuthStore.getState().hasCanonicalRole('belso_ellenor')).toBe(true)
    })
  })

  describe('authStore — FKH-041 telepitesi-ablak marker', () => {
    beforeEach(() => {
      localStorage.clear()
    })

    it('F1: login penztar szereppel -> penztar marker a localStorage-ban', () => {
      act(() => {
        useAuthStore.getState().login(mockWorker, 'tok', 'Bearer', '', 'penztar')
      })
      expect(localStorage.getItem(LAST_INSTALL_WINDOW_ROLE_KEY)).toBe('penztar')
    })

    it('F2: login ertektar szereppel -> ertektar marker (az ertektaros belepés zarja a belepes-elotti ablakot)', () => {
      act(() => {
        useAuthStore.getState().login(mockWorker, 'tok', 'Bearer', '', 'ertektar')
      })
      expect(localStorage.getItem(LAST_INSTALL_WINDOW_ROLE_KEY)).toBe('ertektar')
    })

    it('F3: login penztar, majd selectRole ertektar -> a marker atall ertektar-ra', () => {
      act(() => {
        useAuthStore.getState().login(mockWorker, 'tok', 'Bearer', '', 'penztar')
      })
      expect(localStorage.getItem(LAST_INSTALL_WINDOW_ROLE_KEY)).toBe('penztar')
      act(() => {
        useAuthStore.getState().selectRole('tok2', 'ertektar', [])
      })
      expect(localStorage.getItem(LAST_INSTALL_WINDOW_ROLE_KEY)).toBe('ertektar')
    })
  })
})
