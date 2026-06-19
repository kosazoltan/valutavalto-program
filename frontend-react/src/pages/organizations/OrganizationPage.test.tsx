import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import OrganizationPage from './OrganizationPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  getActive: vi.fn(),
  getRoots: vi.fn(),
  getById: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  delete: vi.fn(),
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  organizationApi: {
    list: mocks.list,
    getActive: mocks.getActive,
    getRoots: mocks.getRoots,
    getById: mocks.getById,
    create: mocks.create,
    update: mocks.update,
    delete: mocks.delete,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: mocks.logger,
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (key: string) => key }),
}))

const baseOrganizations = [
  {
    id: 'org-1',
    code: 'ROOT',
    name: 'Lista root',
    description: 'Lista verzió',
    isActive: true,
  },
  {
    id: 'org-2',
    code: 'CHILD',
    name: 'Lista child',
    parentName: 'Lista root',
    isActive: false,
  },
]

describe('OrganizationPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue(baseOrganizations)
    mocks.getActive.mockResolvedValue([baseOrganizations[0]])
    mocks.getRoots.mockResolvedValue([baseOrganizations[0]])
    mocks.getById.mockResolvedValue({
      ...baseOrganizations[0],
      name: 'Backend root részlet',
      description: 'Backend detail description',
    })
    mocks.create.mockResolvedValue(baseOrganizations[0])
    mocks.update.mockResolvedValue(baseOrganizations[0])
    mocks.delete.mockResolvedValue(undefined)
  })

  it('betöltéskor lekéri az aktív és gyökér szervezet backend listákat', async () => {
    render(<OrganizationPage />)

    await waitFor(() => {
      expect(mocks.list).toHaveBeenCalled()
      expect(mocks.getActive).toHaveBeenCalled()
      expect(mocks.getRoots).toHaveBeenCalled()
    })

    expect(screen.getByText('Összes szervezet')).toBeInTheDocument()
    expect(screen.getByText('Aktív szervezet')).toBeInTheDocument()
    expect(screen.getByText('Gyökér szervezet')).toBeInTheDocument()
    expect(screen.getByText('ROOT')).toBeInTheDocument()
  })

  it('szerkesztéskor a backend részlet reprezentációját tölti az űrlapba', async () => {
    const user = userEvent.setup()
    render(<OrganizationPage />)

    await screen.findByText('ROOT')
    await user.click(screen.getAllByRole('button', { name: /common.edit/i })[0]!)

    await waitFor(() => {
      expect(mocks.getById).toHaveBeenCalledWith('org-1')
      expect(screen.getByDisplayValue('Backend root részlet')).toBeInTheDocument()
      expect(screen.getByDisplayValue('Backend detail description')).toBeInTheDocument()
    })
  })
})
