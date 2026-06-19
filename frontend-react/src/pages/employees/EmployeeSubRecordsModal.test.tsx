import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import EmployeeSubRecordsModal from './EmployeeSubRecordsModal'
import { api } from '../../services/api/index'

vi.mock('../../services/api/index', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({ worker: { companyCode: 'EBC' } }),
}))

const mockApi = api as unknown as {
  get: ReturnType<typeof vi.fn>
  post: ReturnType<typeof vi.fn>
  put: ReturnType<typeof vi.fn>
  delete: ReturnType<typeof vi.fn>
}

describe('EmployeeSubRecordsModal backend kapcsolatok', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockImplementation((url: string) => {
      if (url === '/employees/42/occupational-health') {
        return Promise.resolve({ data: [{ id: 1, status: 'Érvényes', examDate: '2026-06-18', result: 'Alkalmas' }] })
      }
      if (url === '/employees/42/vacations') {
        return Promise.resolve({ data: [{ id: 2, year: 2026, vacationDays: 20, takenVacation: 4 }] })
      }
      if (url === '/employees/42/children') {
        return Promise.resolve({ data: [{ id: 3, name: 'Teszt Gyermek', birthDate: '2020-01-01' }] })
      }
      if (url === '/employees/42') {
        return Promise.resolve({ data: { workerId: 77 } })
      }
      if (url === '/workers/77') {
        return Promise.resolve({ data: { id: 77, workerCode: 'BORSI', fullName: 'Borsi Teszt' } })
      }
      if (url === '/worker-management/42/attendance') {
        return Promise.resolve({ data: { content: [{ id: 'att-1', loginAt: '2026-06-18T08:00:00', logoutAt: null }] } })
      }
      if (url === '/workers/42/roles') {
        return Promise.resolve({ data: ['penztaros'] })
      }
      return Promise.resolve({ data: [] })
    })
    mockApi.post.mockResolvedValue({ data: {} })
  })

  it('betölti a munkavállalói alrekordokat és mobil kártyákat renderel', async () => {
    render(<EmployeeSubRecordsModal employeeId={42} employeeName="Teszt Elek" onClose={vi.fn()} />)

    await waitFor(() => {
      expect(mockApi.get).toHaveBeenCalledWith('/employees/42/occupational-health')
      expect(mockApi.get).toHaveBeenCalledWith('/employees/42/vacations')
      expect(mockApi.get).toHaveBeenCalledWith('/employees/42/children')
      expect(mockApi.get).toHaveBeenCalledWith('/worker-management/42/attendance')
      expect(mockApi.get).toHaveBeenCalledWith('/workers/42/roles')
    })

    expect(await screen.findByText('Vezetői dolgozókezelés')).toBeInTheDocument()
    expect(screen.getByText('2026-06-18 08:00')).toBeInTheDocument()
    expect(screen.getByTestId('worker-role-list')).toHaveTextContent('penztaros')
    expect(await screen.findByTestId('occ-health-mobile-card')).toHaveTextContent('Alkalmas')
    expect(screen.getByTestId('vacation-mobile-card')).toHaveTextContent('2026')
    expect(screen.getByTestId('child-mobile-card')).toHaveTextContent('Teszt Gyermek')
  })

  it('a dolgozókezelő műveleteket a worker-management backend endpointokra köti', async () => {
    const user = userEvent.setup()
    render(<EmployeeSubRecordsModal employeeId={42} employeeName="Teszt Elek" onClose={vi.fn()} />)

    await screen.findByText('Vezetői dolgozókezelés')
    await user.type(screen.getByTestId('worker-break-reason'), 'Ebédszünet')
    await user.click(screen.getByTestId('worker-break-start'))
    await user.click(screen.getByTestId('worker-break-end'))
    await user.type(screen.getByTestId('worker-new-password'), 'Teszt1234')
    await user.click(screen.getByTestId('worker-reset-password'))

    await waitFor(() => {
      expect(mockApi.post).toHaveBeenCalledWith('/worker-management/42/break-start', { reason: 'Ebédszünet' })
      expect(mockApi.post).toHaveBeenCalledWith('/worker-management/42/break-end')
      expect(mockApi.post).toHaveBeenCalledWith('/worker-management/42/reset-password', { newPassword: 'Teszt1234' })
    })
  })

  it('a worker szerepkör és login unlock műveleteket a WorkerController endpointokra köti', async () => {
    const user = userEvent.setup()
    render(<EmployeeSubRecordsModal employeeId={42} employeeName="Teszt Elek" onClose={vi.fn()} />)

    await screen.findByText('Vezetői dolgozókezelés')
    await user.type(screen.getByTestId('worker-role-code'), 'foertektar')
    await user.click(screen.getByTestId('worker-role-add'))
    await user.click(screen.getByTestId('worker-role-remove-penztaros'))
    await user.click(screen.getByTestId('worker-unlock-login'))

    await waitFor(() => {
      expect(mockApi.post).toHaveBeenCalledWith('/workers/42/roles/foertektar')
      expect(mockApi.delete).toHaveBeenCalledWith('/workers/42/roles/penztaros')
      expect(mockApi.post).toHaveBeenCalledWith('/workers/42/unlock-login')
    })
  })

  it('admin setup-tokent állít ki a dolgozóhoz kapcsolt WorkerDto alapján', async () => {
    const user = userEvent.setup()
    mockApi.post.mockImplementation((url: string, body?: unknown) => {
      if (url === '/auth/worker-setup-token') {
        return Promise.resolve({
          data: {
            success: true,
            companyCode: (body as { companyCode?: string }).companyCode,
            workerCode: (body as { workerCode?: string }).workerCode,
            token: 'setup-token-123',
            expiresAt: '2026-06-21T10:00:00Z',
          },
        })
      }
      return Promise.resolve({ data: {} })
    })

    render(<EmployeeSubRecordsModal employeeId={42} employeeName="Teszt Elek" onClose={vi.fn()} />)

    await screen.findByText('Vezetői dolgozókezelés')
    await user.click(screen.getByTestId('worker-setup-token-issue'))

    await waitFor(() => {
      expect(mockApi.get).toHaveBeenCalledWith('/workers/77')
      expect(mockApi.post).toHaveBeenCalledWith('/auth/worker-setup-token', {
        companyCode: 'EBC',
        workerCode: 'BORSI',
      })
    })
    expect(screen.getByTestId('worker-setup-token-result')).toHaveTextContent('setup-token-123')
  })
})
