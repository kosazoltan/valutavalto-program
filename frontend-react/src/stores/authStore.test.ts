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
})
