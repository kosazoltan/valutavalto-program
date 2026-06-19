import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import EmployeePage from './EmployeePage'
import { api } from '../../services/api/index'

vi.mock('react-i18next', () => ({
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
    mockApi.get.mockResolvedValue({
      data: [
        {
          id: 42,
          lastName: 'Teszt',
          firstName: 'Elek',
          organizationUnit: 'Szeged',
          jobTitle: 'Pénztáros',
          employmentStartDate: '2026-06-19',
          active: true,
        },
      ],
    })
    mockApi.post.mockResolvedValue({ data: { imported: 1, message: '1 dolgozó sikeresen importálva' } })
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
    expect(mockApi.get).toHaveBeenCalledTimes(2)
    expect(await screen.findByText('1 dolgozó sikeresen importálva')).toBeInTheDocument()
  })
})
