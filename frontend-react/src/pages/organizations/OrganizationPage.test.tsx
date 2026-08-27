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
  archive: vi.fn(),
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
    archive: mocks.archive,
    delete: mocks.delete,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: mocks.logger,
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({
    t: (key: string) => (key === 'archiving.archivalas' ? 'Archiválás' : key),
  }),
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
    vi.restoreAllMocks()
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
    mocks.archive.mockResolvedValue(baseOrganizations[1])
    mocks.delete.mockResolvedValue(undefined)
    vi.spyOn(window, 'confirm').mockReturnValue(true)
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

  it('archiváláskor a POST /organizations/{id}/archive wrapperre köt', async () => {
    const user = userEvent.setup()
    render(<OrganizationPage />)

    await screen.findByText('ROOT')
    await user.click(screen.getAllByRole('button', { name: /Archiválás/i })[0]!)

    await waitFor(() => {
      expect(mocks.archive).toHaveBeenCalledWith('org-1')
    })
    expect(window.confirm).toHaveBeenCalledWith('Biztosan archiválni szeretné ezt a szervezetet?')
  })
})
