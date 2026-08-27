import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import BranchGroupPage from './BranchGroupPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  getRoots: vi.fn(),
  getById: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  delete: vi.fn(),
  toast: {
    error: vi.fn(),
    success: vi.fn(),
    warning: vi.fn(),
  },
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  branchGroupApi: {
    list: mocks.list,
    getRoots: mocks.getRoots,
    getById: mocks.getById,
    create: mocks.create,
    update: mocks.update,
    delete: mocks.delete,
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: { worker: { id: number } }) => unknown) =>
    selector({ worker: { id: 77 } }),
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

const branchGroupId = '11111111-1111-1111-1111-111111111111'

const branchGroups = [
  {
    id: branchGroupId,
    code: 'ROOT',
    name: 'Lista körzet',
    parentGroupId: undefined,
    isActive: true,
    branchIds: ['branch-1'],
  },
]

describe('BranchGroupPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue(branchGroups)
    mocks.getRoots.mockResolvedValue(branchGroups)
    mocks.getById.mockResolvedValue({
      ...branchGroups[0],
      name: 'Backend detail körzet',
      isActive: false,
    })
    mocks.create.mockResolvedValue(branchGroups[0])
    mocks.update.mockResolvedValue(branchGroups[0])
    mocks.delete.mockResolvedValue(undefined)
  })

  it('szerkesztéskor a backend fiókcsoport detail endpointból tölti az űrlapot', async () => {
    const user = userEvent.setup()
    render(<BranchGroupPage />)

    await screen.findByText('ROOT')
    await user.click(screen.getByRole('button', { name: 'Szerkesztés: Lista körzet' }))

    await waitFor(() => {
      expect(mocks.getById).toHaveBeenCalledWith(branchGroupId)
    })
    expect(await screen.findByDisplayValue('Backend detail körzet')).toBeInTheDocument()
    expect(screen.queryByDisplayValue('Lista körzet')).not.toBeInTheDocument()
  })
})
