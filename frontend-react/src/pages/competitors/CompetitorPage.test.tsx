import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CompetitorPage from './CompetitorPage'

const mocks = vi.hoisted(() => ({
  competitorList: vi.fn(),
  competitorGetById: vi.fn(),
  competitorCreate: vi.fn(),
  competitorUpdate: vi.fn(),
  competitorRemove: vi.fn(),
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  toast: {
    success: vi.fn(),
    error: vi.fn(),
  },
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: mocks.apiGet,
    post: mocks.apiPost,
  },
  competitorApi: {
    list: mocks.competitorList,
    getById: mocks.competitorGetById,
    create: mocks.competitorCreate,
    update: mocks.competitorUpdate,
    remove: mocks.competitorRemove,
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({ worker: { branchId: 'branch-1' } }),
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

describe('CompetitorPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.competitorList.mockResolvedValue([
      {
        id: 'competitor-1',
        name: 'Lista szerinti versenytárs',
        website: 'https://lista.example',
        branchId: 'branch-list',
        isActive: true,
      },
    ])
    mocks.competitorGetById.mockResolvedValue({
      id: 'competitor-1',
      name: 'Backend részlet versenytárs',
      website: 'https://detail.example',
      branchId: 'branch-detail',
      isActive: false,
    })
    mocks.apiGet.mockImplementation(async (path: string) => {
      if (path === '/competitions') return { data: [] }
      return { data: [] }
    })
  })

  it('szerkesztés előtt lekéri a versenytárs backend detail reprezentációját', async () => {
    render(<CompetitorPage />)

    await screen.findByText('Lista szerinti versenytárs')
    fireEvent.click(screen.getByTitle('Szerkesztés'))

    await waitFor(() => {
      expect(mocks.competitorGetById).toHaveBeenCalledWith('competitor-1')
      expect(screen.getByDisplayValue('Backend részlet versenytárs')).toBeInTheDocument()
      expect(screen.getByDisplayValue('https://detail.example')).toBeInTheDocument()
      expect(screen.getByDisplayValue('branch-detail')).toBeInTheDocument()
    })
  })
})
