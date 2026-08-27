import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import WorkerPage from './WorkerPage'

const mockGet = vi.fn()
const mockPost = vi.fn()
const mockPut = vi.fn()

vi.mock('../../services/api/index', () => ({
  api: {
    get: (...args: unknown[]) => mockGet(...args),
    post: (...args: unknown[]) => mockPost(...args),
    put: (...args: unknown[]) => mockPut(...args),
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({ worker: { branchId: 'branch-123', branchName: 'Szeged Értéktár' } }),
}))

vi.mock('../../components/BulkEmailModal', () => ({
  default: () => null,
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    warning: vi.fn(),
    success: vi.fn(),
    error: vi.fn(),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

const allWorkers = [
  {
    id: 1,
    workerCode: 'ALL',
    firstName: 'Összes',
    lastName: 'Anna',
    fullName: 'Összes Anna',
    email: 'all@example.test',
    phone: '+361111111',
    branchId: 'branch-999',
    branchName: 'Másik fiók',
    active: true,
  },
]

const branchWorkers = [
  {
    id: 2,
    workerCode: 'BR',
    firstName: 'Branch',
    lastName: 'Béla',
    fullName: 'Branch Béla',
    email: 'branch@example.test',
    phone: '+362222222',
    branchId: 'branch-123',
    branchName: 'Szeged Értéktár',
    active: true,
  },
]

describe('WorkerPage backend contract', () => {
  beforeEach(() => {
    mockGet.mockReset()
    mockPost.mockReset()
    mockPut.mockReset()
    mockGet.mockImplementation((url: string) => {
      if (url === '/workers/branch/branch-123') return Promise.resolve({ data: branchWorkers })
      if (url === '/workers') return Promise.resolve({ data: allWorkers })
      return Promise.resolve({ data: [] })
    })
  })

  it('saját fiók szűrésnél meghívja a /workers/branch/{branchId} backend endpointot', async () => {
    render(<WorkerPage />)

    await waitFor(() => expect(mockGet).toHaveBeenCalledWith('/workers'))
    expect(screen.getAllByText('Összes Anna').length).toBeGreaterThan(0)

    fireEvent.click(screen.getByRole('button', { name: /Saját fiók/i }))

    await waitFor(() => {
      expect(mockGet).toHaveBeenCalledWith('/workers/branch/branch-123')
      expect(screen.getAllByText('Branch Béla').length).toBeGreaterThan(0)
    })
    expect(screen.queryByText('Összes Anna')).not.toBeInTheDocument()
  })
})
