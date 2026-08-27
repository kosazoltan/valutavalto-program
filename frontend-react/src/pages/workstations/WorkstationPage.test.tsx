import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import WorkstationPage from './WorkstationPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  getActive: vi.fn(),
  getById: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  delete: vi.fn(),
  toastError: vi.fn(),
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  workstationApi: {
    list: mocks.list,
    getActive: mocks.getActive,
    getById: mocks.getById,
    create: mocks.create,
    update: mocks.update,
    delete: mocks.delete,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    error: mocks.toastError,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: mocks.logger,
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

const baseWorkstations = [
  {
    id: 'workstation-1',
    code: 'WST-1',
    name: 'Lista munkaállomás',
    branchId: 'branch-1',
    machineName: 'LIST-PC',
    ipAddress: '10.0.0.10',
    macAddress: '00:11:22:33:44:55',
    workstationType: 'CASHIER',
    softwareVersion: '2.28.11',
    isOnline: true,
    isActive: true,
  },
]

describe('WorkstationPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue(baseWorkstations)
    mocks.getActive.mockResolvedValue(baseWorkstations)
    mocks.getById.mockResolvedValue({
      ...baseWorkstations[0],
      name: 'Backend detail workstation',
      machineName: 'BACKEND-PC',
    })
    mocks.create.mockResolvedValue(baseWorkstations[0])
    mocks.update.mockResolvedValue(baseWorkstations[0])
    mocks.delete.mockResolvedValue(undefined)
  })

  it('betöltéskor lekéri az aktív munkaállomás backend listát', async () => {
    render(<WorkstationPage />)

    await waitFor(() => {
      expect(mocks.list).toHaveBeenCalled()
      expect(mocks.getActive).toHaveBeenCalled()
    })

    expect(screen.getByText('Összes munkaállomás')).toBeInTheDocument()
    expect(screen.getByText('Aktív munkaállomás')).toBeInTheDocument()
    expect(screen.getByText('WST-1')).toBeInTheDocument()
  })

  it('szerkesztéskor a backend részlet reprezentációját tölti az űrlapba', async () => {
    const user = userEvent.setup()
    render(<WorkstationPage />)

    await screen.findByText('WST-1')
    await user.click(screen.getByRole('button', { name: /common.edit/i }))

    await waitFor(() => {
      expect(mocks.getById).toHaveBeenCalledWith('workstation-1')
      expect(screen.getByDisplayValue('Backend detail workstation')).toBeInTheDocument()
      expect(screen.getByDisplayValue('BACKEND-PC')).toBeInTheDocument()
    })
  })
})
