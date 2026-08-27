import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import PermissionPage from './PermissionPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  getByModule: vi.fn(),
  getById: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  delete: vi.fn(),
  toggleActive: vi.fn(),
  toast: {
    error: vi.fn(),
  },
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  permissionApi: {
    list: mocks.list,
    getByModule: mocks.getByModule,
    getById: mocks.getById,
    create: mocks.create,
    update: mocks.update,
    delete: mocks.delete,
    toggleActive: mocks.toggleActive,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

vi.mock('../../utils/logger', () => ({
  logger: mocks.logger,
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

const allPermissions = [
  {
    id: '11111111-1111-1111-1111-111111111111',
    code: 'TRANSACTION_CREATE',
    name: 'Tranzakció létrehozás',
    description: 'Lista tranzakció',
    module: 'TRANSACTION',
    isSystemPermission: true,
    isActive: true,
    createdAt: '2026-06-01T00:00:00',
  },
  {
    id: '22222222-2222-2222-2222-222222222222',
    code: 'REPORT_READ',
    name: 'Riport olvasás',
    description: 'Lista riport',
    module: 'REPORT',
    isSystemPermission: true,
    isActive: true,
    createdAt: '2026-06-01T00:00:00',
  },
]

describe('PermissionPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue(allPermissions)
    mocks.getByModule.mockResolvedValue([
      {
        ...allPermissions[0],
        description: 'Backend module result',
      },
    ])
    mocks.getById.mockResolvedValue({
      ...allPermissions[0],
      name: 'Backend Detail Jogosultság',
      description: 'Backend detail result',
    })
    mocks.create.mockResolvedValue(allPermissions[0])
    mocks.update.mockResolvedValue(allPermissions[0])
    mocks.delete.mockResolvedValue(undefined)
    mocks.toggleActive.mockResolvedValue(allPermissions[0])
  })

  it('modul szűréskor a backend modul endpointot hívja', async () => {
    const user = userEvent.setup()
    render(<PermissionPage />)

    await screen.findByText('TRANSACTION_CREATE')
    await user.selectOptions(screen.getByLabelText('settings.modul'), 'TRANSACTION')

    await waitFor(() => {
      expect(mocks.getByModule).toHaveBeenCalledWith('TRANSACTION')
      expect(screen.getByText('Backend module result')).toBeInTheDocument()
    })
  })

  it('szerkesztéskor a backend jogosultság detail endpointból nyitja meg az űrlapot', async () => {
    const user = userEvent.setup()
    render(<PermissionPage />)

    const codeCell = await screen.findByText('TRANSACTION_CREATE')
    const row = codeCell.closest('tr')
    expect(row).not.toBeNull()
    await user.click(
      within(row as HTMLTableRowElement).getByRole('button', { name: 'common.edit' }),
    )

    await waitFor(() => {
      expect(mocks.getById).toHaveBeenCalledWith('11111111-1111-1111-1111-111111111111')
    })
    expect(await screen.findByDisplayValue('Backend Detail Jogosultság')).toBeInTheDocument()
    expect(screen.getByDisplayValue('Backend detail result')).toBeInTheDocument()
  })
})
