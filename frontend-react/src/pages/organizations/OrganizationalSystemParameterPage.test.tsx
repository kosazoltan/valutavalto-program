import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import OrganizationalSystemParameterPage from './OrganizationalSystemParameterPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  getById: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  delete: vi.fn(),
  toast: {
    warning: vi.fn(),
    success: vi.fn(),
    error: vi.fn(),
  },
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  organizationalSystemParameterApi: {
    list: mocks.list,
    getById: mocks.getById,
    create: mocks.create,
    update: mocks.update,
    delete: mocks.delete,
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

const listParameter = {
  id: 'param-1',
  organizationId: 'org-1',
  organizationName: 'Szeged',
  parameterKey: 'LIMIT',
  parameterValue: '1000',
  currencyCode: 'EUR',
  validFrom: '2026-06-01',
  validTo: '',
  isActive: true,
  description: 'Lista verzió',
}

describe('OrganizationalSystemParameterPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue([listParameter])
    mocks.getById.mockResolvedValue({
      ...listParameter,
      parameterValue: '2500',
      description: 'Backend detail description',
    })
    mocks.create.mockResolvedValue(listParameter)
    mocks.update.mockResolvedValue(listParameter)
    mocks.delete.mockResolvedValue(undefined)
  })

  it('szerkesztéskor a backend részlet reprezentációját tölti az űrlapba', async () => {
    const user = userEvent.setup()
    render(<OrganizationalSystemParameterPage />)

    await screen.findByText('LIMIT')
    await user.click(screen.getByRole('button', { name: /Szerkesztés/i }))

    await waitFor(() => {
      expect(mocks.getById).toHaveBeenCalledWith('param-1')
      expect(screen.getByDisplayValue('2500')).toBeInTheDocument()
      expect(screen.getByDisplayValue('Backend detail description')).toBeInTheDocument()
    })
  })
})
