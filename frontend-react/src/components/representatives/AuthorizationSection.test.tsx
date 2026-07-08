import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import AuthorizationSection from './AuthorizationSection'

const mocks = vi.hoisted(() => ({
  findAuthorizations: vi.fn(),
  createAuthorization: vi.fn(),
  verifyAuthorization: vi.fn(),
  suspendAuthorization: vi.fn(),
  resumeAuthorization: vi.fn(),
  revokeAuthorization: vi.fn(),
  toast: {
    success: vi.fn(),
    error: vi.fn(),
    warning: vi.fn(),
  },
  useAuthStore: vi.fn(),
}))

vi.mock('../../services/api/transactions', () => ({
  authorizedRepresentativeApi: {
    findAuthorizations: (...args: unknown[]) => mocks.findAuthorizations(...args),
    createAuthorization: (...args: unknown[]) => mocks.createAuthorization(...args),
    verifyAuthorization: (...args: unknown[]) => mocks.verifyAuthorization(...args),
    suspendAuthorization: (...args: unknown[]) => mocks.suspendAuthorization(...args),
    resumeAuthorization: (...args: unknown[]) => mocks.resumeAuthorization(...args),
    revokeAuthorization: (...args: unknown[]) => mocks.revokeAuthorization(...args),
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: mocks.useAuthStore,
}))

const mockWorker = {
  id: 42,
  workerCode: 'TT01',
  firstName: 'Teszt',
  lastName: 'Tamás',
  fullName: 'Teszt Tamás',
  role: 'CASHIER',
  branchId: 'b1',
  branchCode: 'KORUT',
  branchName: 'Korut',
  companyId: 'c1',
}

const mockAuthorization = {
  id: 'auth-001',
  representativeId: 'rep-1',
  authorizationTypeDid: 'CURRENCY_EXCHANGE',
  startDate: '2024-01-01',
  expiryDate: '2025-01-01',
  statusDid: 'PENDING',
  maxAmount: 500000,
  maxTransactionCount: 10,
  usedTransactionCount: 2,
}

function renderComponent(representativeId = 'rep-1') {
  mocks.useAuthStore.mockImplementation(
    (selector: (state: { worker: typeof mockWorker }) => unknown) =>
      selector({ worker: mockWorker }),
  )
  return render(<AuthorizationSection representativeId={representativeId} />)
}

describe('AuthorizationSection', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.findAuthorizations.mockResolvedValue([])
  })

  it('betöltés közben spinner látható', () => {
    mocks.findAuthorizations.mockReturnValue(new Promise(() => {}))
    renderComponent()
    expect(screen.getByText('Betöltés...')).toBeDefined()
  })

  it('üres lista esetén "Nincs meghatalmazás" szöveg jelenik meg', async () => {
    mocks.findAuthorizations.mockResolvedValue([])
    renderComponent()
    await waitFor(() => {
      expect(screen.getByText('Nincs meghatalmazás')).toBeDefined()
    })
  })

  it('betöltés után meghatalmazás lista megjelenik', async () => {
    mocks.findAuthorizations.mockResolvedValue([mockAuthorization])
    renderComponent()
    await waitFor(() => {
      expect(screen.getByText('CURRENCY_EXCHANGE')).toBeDefined()
      expect(screen.getByText('Függőben')).toBeDefined()
    })
  })

  it('API hiba esetén hibaüzenet jelenik meg', async () => {
    mocks.findAuthorizations.mockRejectedValue(new Error('Kapcsolódási hiba'))
    renderComponent()
    await waitFor(() => {
      expect(screen.getByText('Kapcsolódási hiba')).toBeDefined()
    })
  })

  it('"Új meghatalmazás" gombra kattintva form megjelenik', async () => {
    renderComponent()
    await waitFor(() => screen.getByText('Nincs meghatalmazás'))
    await userEvent.click(screen.getByText('Új meghatalmazás'))
    expect(screen.getByText('Létrehozás')).toBeDefined()
    expect(screen.getByText('Mégse')).toBeDefined()
  })

  it('form sikeres submit meghívja a createAuthorization API-t', async () => {
    mocks.createAuthorization.mockResolvedValue({ ...mockAuthorization, statusDid: 'PENDING' })
    renderComponent()
    await waitFor(() => screen.getByText('Nincs meghatalmazás'))

    await userEvent.click(screen.getByText('Új meghatalmazás'))
    await waitFor(() => screen.getByText('Létrehozás'))

    await userEvent.click(screen.getByText('Létrehozás'))

    await waitFor(() => {
      expect(mocks.createAuthorization).toHaveBeenCalledWith(
        'rep-1',
        expect.objectContaining({ operationDid: 'CURRENCY_EXCHANGE' }),
        42,
      )
      expect(mocks.toast.success).toHaveBeenCalledWith('Meghatalmazás létrehozva')
    })
  })

  it('Mégse gombra kattintva form bezáródik', async () => {
    renderComponent()
    await waitFor(() => screen.getByText('Nincs meghatalmazás'))

    await userEvent.click(screen.getByText('Új meghatalmazás'))
    await waitFor(() => screen.getByText('Mégse'))

    await userEvent.click(screen.getByText('Mégse'))
    expect(screen.queryByText('Létrehozás')).toBeNull()
  })

  it('PENDING státuszú meghatalmazásnál Jóváhagyás gomb látható és működik', async () => {
    mocks.findAuthorizations.mockResolvedValue([{ ...mockAuthorization, statusDid: 'PENDING' }])
    mocks.verifyAuthorization.mockResolvedValue({ ...mockAuthorization, statusDid: 'ACTIVE' })
    renderComponent()

    await waitFor(() => screen.getByTitle('Jóváhagyás'))
    await userEvent.click(screen.getByTitle('Jóváhagyás'))

    await waitFor(() => {
      expect(mocks.verifyAuthorization).toHaveBeenCalledWith('auth-001', 42)
      expect(mocks.toast.success).toHaveBeenCalledWith('Művelet sikeres')
    })
  })

  it('ACTIVE státuszú meghatalmazásnál Felfüggesztés gomb látható', async () => {
    mocks.findAuthorizations.mockResolvedValue([{ ...mockAuthorization, statusDid: 'ACTIVE' }])
    renderComponent()

    await waitFor(() => {
      expect(screen.getByTitle('Felfüggesztés')).toBeDefined()
    })
  })

  it('SUSPENDED státuszú meghatalmazásnál Újraaktiválás gomb látható és működik', async () => {
    mocks.findAuthorizations.mockResolvedValue([{ ...mockAuthorization, statusDid: 'SUSPENDED' }])
    mocks.resumeAuthorization.mockResolvedValue({ ...mockAuthorization, statusDid: 'ACTIVE' })
    renderComponent()

    await waitFor(() => screen.getByTitle('Újraaktiválás'))
    await userEvent.click(screen.getByTitle('Újraaktiválás'))

    await waitFor(() => {
      expect(mocks.resumeAuthorization).toHaveBeenCalledWith('auth-001', 42)
    })
  })

  it('REVOKED státuszú meghatalmazásnál nincs Visszavonás gomb', async () => {
    mocks.findAuthorizations.mockResolvedValue([{ ...mockAuthorization, statusDid: 'REVOKED' }])
    renderComponent()

    await waitFor(() => screen.getByText('Visszavonva'))
    expect(screen.queryByTitle('Visszavonás')).toBeNull()
  })

  it('státusz badge-ek helyesen jelennek meg', async () => {
    const statuses = [
      { statusDid: 'PENDING', label: 'Függőben' },
      { statusDid: 'ACTIVE', label: 'Aktív' },
      { statusDid: 'SUSPENDED', label: 'Felfüggesztve' },
      { statusDid: 'REVOKED', label: 'Visszavonva' },
    ]
    for (const s of statuses) {
      mocks.findAuthorizations.mockResolvedValue([{ ...mockAuthorization, statusDid: s.statusDid }])
      const { unmount } = renderComponent()
      await waitFor(() => expect(screen.getByText(s.label)).toBeDefined())
      unmount()
      vi.clearAllMocks()
    }
  })

  it('limit összeg forintban jelenik meg', async () => {
    mocks.findAuthorizations.mockResolvedValue([{ ...mockAuthorization, maxAmount: 500000 }])
    renderComponent()
    await waitFor(() => {
      expect(screen.getByText(/500\s*000\s*Ft/)).toBeDefined()
    })
  })

  it('Korlátlan jelenik meg ha nincs maxAmount', async () => {
    mocks.findAuthorizations.mockResolvedValue([{ ...mockAuthorization, maxAmount: undefined }])
    renderComponent()
    await waitFor(() => {
      expect(screen.getAllByText('Korlátlan').length).toBeGreaterThan(0)
    })
  })
})
