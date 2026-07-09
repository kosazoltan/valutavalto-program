import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import WorkerPasswordSettingsPanel from './WorkerPasswordSettingsPanel'

const mocks = vi.hoisted(() => ({
  getCurrentUser: vi.fn(),
  updatePassword: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  userApi: {
    getCurrentUser: mocks.getCurrentUser,
    updatePassword: mocks.updatePassword,
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
    mocks.updatePassword.mockResolvedValue(undefined)
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

  it('meghívja a saját user jelszóváltó szerződést', async () => {
    const user = userEvent.setup()
    render(<WorkerPasswordSettingsPanel />)

    await user.type(screen.getByLabelText('Jelenlegi jelszó'), 'old-password')
    await user.type(screen.getByLabelText('Új jelszó'), 'NewPass123')
    await user.type(screen.getByLabelText('Új jelszó ismét'), 'NewPass123')
    await user.click(screen.getByRole('button', { name: 'Jelszó módosítása' }))

    await waitFor(() => {
      expect(mocks.updatePassword).toHaveBeenCalledWith('old-password', 'NewPass123')
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

    expect(mocks.updatePassword).not.toHaveBeenCalled()
    expect(screen.getByText('Az új jelszó 8-128 karakter legyen.')).toBeInTheDocument()
  })

  it('jelszóváltási hiba: a logolt argumentumok nem tartalmazzák az új jelszót', async () => {
    const user = userEvent.setup()
    mocks.updatePassword.mockRejectedValue(
      Object.assign(new Error('Request failed with status code 401'), {
        isAxiosError: true,
        config: {
          url: '/users/me/password',
          data: JSON.stringify({ oldPassword: 'Regi-Jelszo-1', newPassword: 'Uj-Jelszo-9' }),
        },
        response: { status: 401 },
      }),
    )
    render(<WorkerPasswordSettingsPanel />)

    await user.type(screen.getByLabelText('Jelenlegi jelszó'), 'Regi-Jelszo-1')
    await user.type(screen.getByLabelText('Új jelszó'), 'Uj-Jelszo-9')
    await user.type(screen.getByLabelText('Új jelszó ismét'), 'Uj-Jelszo-9')
    await user.click(screen.getByRole('button', { name: 'Jelszó módosítása' }))

    await waitFor(() => expect(mocks.loggerError).toHaveBeenCalled())
    const logged = JSON.stringify(mocks.loggerError.mock.calls)
    expect(logged).not.toContain('Uj-Jelszo-9')
    expect(logged).not.toContain('Regi-Jelszo-1')
  })
})
