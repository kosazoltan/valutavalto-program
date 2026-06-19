import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import WorkerPasswordSettingsPanel from './WorkerPasswordSettingsPanel'

const mocks = vi.hoisted(() => ({
  getCurrentUser: vi.fn(),
  changeOwn: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({ worker: { id: 77, fullName: 'Teszt Dolgozó' } }),
}))

vi.mock('../../services/api/index', () => ({
  userApi: {
    getCurrentUser: mocks.getCurrentUser,
  },
}))

vi.mock('../../services/api/settings', () => ({
  workerPasswordApi: {
    changeOwn: mocks.changeOwn,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: mocks.loggerError,
  },
}))

describe('WorkerPasswordSettingsPanel', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getCurrentUser.mockResolvedValue({
      id: '77',
      workerId: '77',
      username: 'TESZT',
      name: 'Teszt Dolgozó',
      email: 'teszt@example.com',
      role: 'ADMIN',
      roles: ['ADMIN'],
      isActive: true,
      defaultBranchName: 'Szeged',
      lastLoginAt: '2026-06-19T10:00:00',
      createdAt: '2026-06-18T10:00:00',
    })
    mocks.changeOwn.mockResolvedValue(undefined)
  })

  it('betölti a saját user profilt a GET /users/me wrapperen keresztül', async () => {
    render(<WorkerPasswordSettingsPanel />)

    await waitFor(() => {
      expect(mocks.getCurrentUser).toHaveBeenCalledTimes(1)
    })
    expect(await screen.findByText('TESZT')).toBeInTheDocument()
    expect(screen.getByText('teszt@example.com')).toBeInTheDocument()
    expect(screen.getByText('Szeged')).toBeInTheDocument()
  })

  it('a bejelentkezett worker id-val meghívja a WorkerController jelszóváltó szerződést', async () => {
    const user = userEvent.setup()
    render(<WorkerPasswordSettingsPanel />)

    await user.type(screen.getByLabelText('Jelenlegi jelszó'), 'old-password')
    await user.type(screen.getByLabelText('Új jelszó'), 'NewPass123')
    await user.type(screen.getByLabelText('Új jelszó ismét'), 'NewPass123')
    await user.click(screen.getByRole('button', { name: 'Jelszó módosítása' }))

    await waitFor(() => {
      expect(mocks.changeOwn).toHaveBeenCalledWith(77, 'old-password', 'NewPass123')
    })
    expect(await screen.findByText('Saját jelszó módosítva.')).toBeInTheDocument()
  })

  it('rövid új jelszó esetén nem hív backend műveletet', async () => {
    const user = userEvent.setup()
    render(<WorkerPasswordSettingsPanel />)

    await user.type(screen.getByLabelText('Jelenlegi jelszó'), 'old-password')
    await user.type(screen.getByLabelText('Új jelszó'), 'short')
    await user.type(screen.getByLabelText('Új jelszó ismét'), 'short')
    await user.click(screen.getByRole('button', { name: 'Jelszó módosítása' }))

    expect(mocks.changeOwn).not.toHaveBeenCalled()
    expect(screen.getByText('Az új jelszó 8-128 karakter legyen.')).toBeInTheDocument()
  })
})
