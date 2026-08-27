import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import UserPage from './UserPage'

const mocks = vi.hoisted(() => ({
  userList: vi.fn(),
  userGetById: vi.fn(),
  roleList: vi.fn(),
  mfaDisable: vi.fn(),
  toastSuccess: vi.fn(),
  toastWarning: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  userApi: {
    list: mocks.userList,
    getById: mocks.userGetById,
    create: vi.fn(),
    update: vi.fn(),
    changePassword: vi.fn(),
    delete: vi.fn(),
    toggleActive: vi.fn(),
    archive: vi.fn(),
  },
  roleApi: {
    list: mocks.roleList,
  },
  mfaAdminApi: {
    disable: mocks.mfaDisable,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: mocks.toastSuccess,
    warning: mocks.toastWarning,
    error: vi.fn(),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: mocks.loggerError,
  },
}))

describe('UserPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    mocks.userList.mockResolvedValue([
      {
        id: '1',
        workerId: '42',
        username: 'teszt.worker',
        name: 'Teszt Worker',
        email: 'teszt@example.com',
        isActive: true,
        roles: ['ADMIN'],
        createdAt: '2026-06-19T00:00:00',
      },
    ])
    mocks.userGetById.mockResolvedValue({
      id: '1',
      workerId: '42',
      username: 'teszt.worker',
      name: 'Backend Detail Worker',
      email: 'detail@example.com',
      isActive: true,
      roles: ['ADMIN'],
      defaultBranchId: 'branch-1',
      defaultBranchName: 'Szeged',
      createdAt: '2026-06-19T00:00:00',
    })
    mocks.roleList.mockResolvedValue([
      { id: 'role-admin', code: 'ADMIN', name: 'ADMIN', isActive: true },
    ])
    mocks.mfaDisable.mockResolvedValue({ workerId: 42, message: 'MFA letiltva' })
  })

  it('szerkesztéskor a backend felhasználó detail endpointból nyitja meg az űrlapot', async () => {
    const user = userEvent.setup()
    render(<UserPage />)

    await screen.findByText('teszt.worker')
    await user.click(screen.getByRole('button', { name: 'common.edit' }))

    await waitFor(() => {
      expect(mocks.userGetById).toHaveBeenCalledWith('1')
    })
    expect(await screen.findByDisplayValue('Backend Detail Worker')).toBeInTheDocument()
    expect(screen.getByDisplayValue('detail@example.com')).toBeInTheDocument()
    expect(screen.getByRole('combobox')).toHaveValue('role-admin')
  })

  it('a felhasználó sorából meghívja az admin MFA disable backend szerződést', async () => {
    const user = userEvent.setup()
    render(<UserPage />)

    await screen.findByText('teszt.worker')
    await user.click(screen.getByRole('button', { name: /MFA letiltás/i }))

    await waitFor(() => {
      expect(mocks.mfaDisable).toHaveBeenCalledWith('42')
    })
    expect(mocks.toastSuccess).toHaveBeenCalledWith('MFA letiltva', 'MFA letiltva')
    expect(mocks.userList).toHaveBeenCalledTimes(2)
  })
})
