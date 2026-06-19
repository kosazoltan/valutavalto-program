import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import OwnCompanyPage from './OwnCompanyPage'

const mocks = vi.hoisted(() => ({
  ownCompanyList: vi.fn(),
  ownCompanyCreate: vi.fn(),
  ownCompanyUpdate: vi.fn(),
  ownCompanyDelete: vi.fn(),
  adminCompanyGetDetails: vi.fn(),
  adminCompanyUpdateCompany: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  ownCompanyApi: {
    list: (...args: unknown[]) => mocks.ownCompanyList(...args),
    create: (...args: unknown[]) => mocks.ownCompanyCreate(...args),
    update: (...args: unknown[]) => mocks.ownCompanyUpdate(...args),
    delete: (...args: unknown[]) => mocks.ownCompanyDelete(...args),
  },
  adminCompanyApi: {
    getDetails: (...args: unknown[]) => mocks.adminCompanyGetDetails(...args),
    updateCompany: (...args: unknown[]) => mocks.adminCompanyUpdateCompany(...args),
  },
}))

describe('OwnCompanyPage admin backend details', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.ownCompanyList.mockResolvedValue([
      {
        id: 'company-1',
        name: 'Exclusive Best Change Zrt.',
        taxNumber: '12345678-2-06',
        registrationNumber: '06-10-000001',
        email: 'info@example.test',
        phone: '+361234567',
        isActive: true,
      },
    ])
    mocks.adminCompanyGetDetails.mockResolvedValue({
      id: 'company-1',
      code: 'EBC',
      name: 'Exclusive Best Change Zrt.',
      active: true,
      activeBranchCount: 7,
      totalWorkerCount: 42,
      dailyTurnoverHuf: 1250000,
      branches: [
        { id: 'branch-1', code: 'SZEGED', name: 'Szeged', city: 'Szeged', active: true },
      ],
    })
    mocks.ownCompanyUpdate.mockResolvedValue({})
    mocks.adminCompanyUpdateCompany.mockResolvedValue(undefined)
  })

  it('lekéri és megjeleníti az admin cégstatisztikát', async () => {
    render(<OwnCompanyPage />)

    await waitFor(() => expect(mocks.adminCompanyGetDetails).toHaveBeenCalledWith('company-1'))
    expect(screen.getByTestId('company-admin-stats-company-1')).toHaveTextContent('7 aktív fiók')
    expect(screen.getByTestId('company-admin-stats-company-1')).toHaveTextContent('42 dolgozó')
  })

  it('szerkesztéskor a CompanyAdminController cég update végpontját is meghívja', async () => {
    const user = userEvent.setup()
    render(<OwnCompanyPage />)

    await waitFor(() => expect(mocks.adminCompanyGetDetails).toHaveBeenCalledWith('company-1'))
    const editButtons = screen.getAllByRole('button', { name: /Szerkesztés/i })
    expect(editButtons.length).toBeGreaterThan(0)
    await user.click(editButtons[0]!)
    const nameInput = screen.getByDisplayValue('Exclusive Best Change Zrt.')
    await user.clear(nameInput)
    await user.type(nameInput, 'Exclusive Best Change Kft.')
    await user.click(screen.getByRole('button', { name: /Mentés/i }))

    await waitFor(() => {
      expect(mocks.ownCompanyUpdate).toHaveBeenCalledWith('company-1', expect.objectContaining({
        name: 'Exclusive Best Change Kft.',
      }))
      expect(mocks.adminCompanyUpdateCompany).toHaveBeenCalledWith('company-1', {
        name: 'Exclusive Best Change Kft.',
        taxNumber: '12345678-2-06',
        registrationNumber: '06-10-000001',
        address: undefined,
        phone: '+361234567',
        email: 'info@example.test',
      })
    })
  })
})
