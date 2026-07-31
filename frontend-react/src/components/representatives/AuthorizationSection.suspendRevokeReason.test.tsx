import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import AuthorizationSection from './AuthorizationSection'

// FKH-027 PR C (RED) — FR-C1..FR-C4: a handleAction a natív prompt() helyett a közös
// TextReasonModal-lal kéri be a felfüggesztés / visszavonás okát.
//
// Forrásból igazolt viselkedés (AuthorizationSection.tsx:75-100):
//   const reason =
//     action === 'suspend' || action === 'revoke'
//       ? prompt(`${action === 'suspend' ? 'Felfüggesztés' : 'Visszavonás'} oka:`)
//       : undefined
//   if ((action === 'suspend' || action === 'revoke') && !reason) return
//
// - FR-C1: EGYETLEN handler (handleAction), négy action-értékkel; a suspend és a revoke
//   ugyanannak a ternárnak és ugyanannak az őrfeltételnek a két ága → EGY tesztfájl.
// - FR-C4: az őr `!reason`, trim NÉLKÜL — a null ÉS az üres string egyaránt a
//   "nincs API-hívás" ágba tartozik (a pilot / BankOrderPage.handleCancel mintája,
//   NEM a BankOrderPage.handleExecute üres→undefined mintája).
// - Az API-argumentumok formája változatlan: (authId, workerId, reason).

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

vi.mock('../ui/toaster', () => ({
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

// ACTIVE státusz: a Felfüggesztés ÉS a Visszavonás gomb is renderelődik
const activeAuthorization = {
  id: 'auth-001',
  representativeId: 'rep-1',
  authorizationTypeDid: 'CURRENCY_EXCHANGE',
  startDate: '2024-01-01',
  expiryDate: '2025-01-01',
  statusDid: 'ACTIVE',
  maxAmount: 500000,
  maxTransactionCount: 10,
  usedTransactionCount: 2,
}

function renderComponent() {
  mocks.useAuthStore.mockImplementation(
    (selector: (state: { worker: typeof mockWorker }) => unknown) =>
      selector({ worker: mockWorker }),
  )
  return render(<AuthorizationSection representativeId="rep-1" />)
}

/** Megnyitja a modált a megadott sor-gombbal, és ellenőrzi a címet + a prompt-tilalmat. */
async function openReasonModal(
  user: ReturnType<typeof userEvent.setup>,
  buttonTitle: 'Felfüggesztés' | 'Visszavonás',
  expectedTitle: string,
) {
  renderComponent()
  await user.click(await screen.findByTitle(buttonTitle))
  const dialog = await screen.findByRole('alertdialog')
  // A modal címe szó szerint az eddigi prompt-szöveg
  expect(dialog).toHaveAccessibleName(expectedTitle)
  expect(window.prompt).not.toHaveBeenCalled()
  return dialog
}

describe('AuthorizationSection — FR-C1..C4: felfüggesztés/visszavonás oka a TextReasonModal-lal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.findAuthorizations.mockResolvedValue([activeAuthorization])
    mocks.suspendAuthorization.mockResolvedValue({
      ...activeAuthorization,
      statusDid: 'SUSPENDED',
    })
    mocks.revokeAuthorization.mockResolvedValue({ ...activeAuthorization, statusDid: 'REVOKED' })
    vi.spyOn(window, 'prompt').mockReturnValue(null)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  describe('FR-C2 — suspend ág', () => {
    it('string-ág: a megadott okkal pontosan egyszer hívódik a suspendAuthorization', async () => {
      const user = userEvent.setup()
      const dialog = await openReasonModal(user, 'Felfüggesztés', 'Felfüggesztés oka:')

      await user.type(within(dialog).getByRole('textbox'), 'Gyanús aktivitás')
      await user.click(within(dialog).getByRole('button', { name: 'OK' }))

      await waitFor(() =>
        expect(mocks.suspendAuthorization).toHaveBeenCalledWith('auth-001', 42, 'Gyanús aktivitás'),
      )
      expect(mocks.suspendAuthorization).toHaveBeenCalledTimes(1)
      expect(mocks.toast.success).toHaveBeenCalledWith('Művelet sikeres')
      await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
      expect(window.prompt).not.toHaveBeenCalled()
    })

    it('null-ág: Mégse után nem hívódik a suspendAuthorization', async () => {
      const user = userEvent.setup()
      const dialog = await openReasonModal(user, 'Felfüggesztés', 'Felfüggesztés oka:')

      await user.click(within(dialog).getByRole('button', { name: 'Mégse' }))

      await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
      expect(mocks.suspendAuthorization).not.toHaveBeenCalled()
      expect(window.prompt).not.toHaveBeenCalled()
    })

    it('FR-C4 üres string: az `!reason` őr trim nélkül is fog — nincs suspendAuthorization-hívás', async () => {
      const user = userEvent.setup()
      const dialog = await openReasonModal(user, 'Felfüggesztés', 'Felfüggesztés oka:')

      await user.click(within(dialog).getByRole('button', { name: 'OK' }))

      await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
      expect(mocks.suspendAuthorization).not.toHaveBeenCalled()
      expect(window.prompt).not.toHaveBeenCalled()
    })
  })

  describe('FR-C3 — revoke ág', () => {
    it('string-ág: a megadott okkal pontosan egyszer hívódik a revokeAuthorization', async () => {
      const user = userEvent.setup()
      const dialog = await openReasonModal(user, 'Visszavonás', 'Visszavonás oka:')

      await user.type(within(dialog).getByRole('textbox'), 'Meghatalmazás lejárt')
      await user.click(within(dialog).getByRole('button', { name: 'OK' }))

      await waitFor(() =>
        expect(mocks.revokeAuthorization).toHaveBeenCalledWith(
          'auth-001',
          42,
          'Meghatalmazás lejárt',
        ),
      )
      expect(mocks.revokeAuthorization).toHaveBeenCalledTimes(1)
      expect(mocks.suspendAuthorization).not.toHaveBeenCalled()
      await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
      expect(window.prompt).not.toHaveBeenCalled()
    })

    it('null-ág: Mégse után nem hívódik a revokeAuthorization', async () => {
      const user = userEvent.setup()
      const dialog = await openReasonModal(user, 'Visszavonás', 'Visszavonás oka:')

      await user.click(within(dialog).getByRole('button', { name: 'Mégse' }))

      await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
      expect(mocks.revokeAuthorization).not.toHaveBeenCalled()
      expect(window.prompt).not.toHaveBeenCalled()
    })

    it('FR-C4 üres string: az `!reason` őr trim nélkül is fog — nincs revokeAuthorization-hívás', async () => {
      const user = userEvent.setup()
      const dialog = await openReasonModal(user, 'Visszavonás', 'Visszavonás oka:')

      await user.click(within(dialog).getByRole('button', { name: 'OK' }))

      await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
      expect(mocks.revokeAuthorization).not.toHaveBeenCalled()
      expect(window.prompt).not.toHaveBeenCalled()
    })
  })

  it('FR-C1 negatív kontroll: a verify/resume ág továbbra sem kér okot (nincs modal, nincs prompt)', async () => {
    const user = userEvent.setup()
    mocks.findAuthorizations.mockResolvedValue([{ ...activeAuthorization, statusDid: 'SUSPENDED' }])
    mocks.resumeAuthorization.mockResolvedValue({ ...activeAuthorization, statusDid: 'ACTIVE' })
    renderComponent()

    await user.click(await screen.findByTitle('Újraaktiválás'))

    await waitFor(() => expect(mocks.resumeAuthorization).toHaveBeenCalledWith('auth-001', 42))
    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
    expect(window.prompt).not.toHaveBeenCalled()
  })
})
