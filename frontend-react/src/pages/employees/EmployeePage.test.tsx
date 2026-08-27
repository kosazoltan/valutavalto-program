import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import EmployeePage from './EmployeePage'
import { api } from '../../services/api/index'

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('./EmployeeSubRecordsModal', () => ({
  default: () => <div data-testid="employee-sub-records-modal" />,
}))

const mockApi = api as unknown as {
  get: ReturnType<typeof vi.fn>
  post: ReturnType<typeof vi.fn>
  put: ReturnType<typeof vi.fn>
  delete: ReturnType<typeof vi.fn>
}

describe('EmployeePage backend kapcsolatok', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    mockApi.get.mockImplementation((url: string) => {
      if (url === '/employees/feor-codes') {
        return Promise.resolve({
          data: [{ id: 1, code: '4211', title: 'Banki pénztáros' }],
        })
      }
      return Promise.resolve({
        data: [
          {
            id: 42,
            lastName: 'Teszt',
            firstName: 'Elek',
            organizationUnit: 'Szeged',
            jobTitle: 'Pénztáros',
            feorCode: '4211',
            employmentStartDate: '2026-06-19',
            active: true,
          },
        ],
      })
    })
    mockApi.post.mockResolvedValue({
      data: { imported: 1, message: '1 dolgozó sikeresen importálva' },
    })
  })

  it('betölti és megjeleníti a FEOR referencia endpointot', async () => {
    render(<EmployeePage />)

    expect((await screen.findAllByText('Teszt Elek')).length).toBeGreaterThan(0)
    expect(mockApi.get).toHaveBeenCalledWith('/employees/feor-codes')
    expect(screen.getByTestId('employee-feor-summary')).toHaveTextContent(
      'employees.feorReferenciaKodok: 1',
    )
    expect(screen.getAllByText('employees.feorPrefix: 4211').length).toBeGreaterThan(0)
  })

  it('új dolgozó mentésekor elküldi a kiválasztott FEOR kódot', async () => {
    const user = userEvent.setup()
    render(<EmployeePage />)

    expect((await screen.findAllByText('Teszt Elek')).length).toBeGreaterThan(0)
    await user.click(screen.getByRole('button', { name: /common.new/ }))
    await user.type(screen.getByLabelText('Vezetéknév'), 'Új')
    await user.type(screen.getByLabelText('Keresztnév'), 'Dolgozó')
    await user.selectOptions(screen.getByLabelText('employees.feorKod'), '4211')
    await user.click(screen.getByRole('button', { name: 'Mentés' }))

    await waitFor(() => {
      expect(mockApi.post).toHaveBeenCalledWith(
        '/employees',
        expect.objectContaining({
          lastName: 'Új',
          firstName: 'Dolgozó',
          feorCode: '4211',
        }),
      )
    })
  })

  it('a dolgozói JSON importot a /employees/import backend szerződésre köti', async () => {
    const user = userEvent.setup()
    render(<EmployeePage />)

    expect((await screen.findAllByText('Teszt Elek')).length).toBeGreaterThan(0)

    const json = JSON.stringify([{ lastName: 'Import', firstName: 'Elek' }])
    await user.upload(
      screen.getByLabelText('Dolgozói JSON import'),
      new File([json], 'ebc_employees.json', { type: 'application/json' }),
    )

    await waitFor(() => {
      expect(mockApi.post).toHaveBeenCalledWith('/employees/import', json, {
        headers: { 'Content-Type': 'application/json' },
      })
    })
    expect(mockApi.get).toHaveBeenCalledTimes(3)
    expect(await screen.findByText('1 dolgozó sikeresen importálva')).toBeInTheDocument()
  })
})
