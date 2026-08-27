import { render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import RateGroupPage from './RateGroupPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  remove: vi.fn(),
  getBranches: vi.fn(),
  updateWorkgroupBranches: vi.fn(),
  currencyList: vi.fn(),
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  apiPut: vi.fn(),
  apiDelete: vi.fn(),
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: mocks.apiGet,
    post: mocks.apiPost,
    put: mocks.apiPut,
    delete: mocks.apiDelete,
  },
  rateWorkgroupApi: {
    list: mocks.list,
    create: mocks.create,
    update: mocks.update,
    remove: mocks.remove,
  },
  rateCreationApi: {
    getBranches: mocks.getBranches,
    updateWorkgroupBranches: mocks.updateWorkgroupBranches,
  },
  currencyApi: {
    list: mocks.currencyList,
  },
}))

vi.mock('../../utils/logger', () => ({ logger: mocks.logger }))

describe('RateGroupPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue([
      {
        id: 'wg1',
        code: 'WG01',
        name: 'Budapest központ',
        legacyGroupNumber: 1,
        active: true,
        tileColor: 'sky',
      },
    ])
    mocks.getBranches.mockResolvedValue([])
    mocks.currencyList.mockResolvedValue([])
    mocks.apiGet.mockResolvedValue({ data: [] })
  })

  it('a régi /rates/groups route-ot a valós rate-management munkacsoport UI-ra köti', async () => {
    render(<RateGroupPage />)

    await waitFor(() => expect(screen.getByText('Budapest központ')).toBeInTheDocument())
    expect(screen.getByRole('button', { name: /Munkacsoportok/i })).toBeInTheDocument()
    expect(screen.queryByText(/nincs azonos szerződésű backend/i)).not.toBeInTheDocument()
    expect(mocks.list).toHaveBeenCalledTimes(1)
  })
})
