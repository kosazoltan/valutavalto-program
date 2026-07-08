import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import PackagingPage from './PackagingPage'

const mocks = vi.hoisted(() => ({
  branchListActive: vi.fn(),
  currencyGetActive: vi.fn(),
  packagingList: vi.fn(),
  packagingCreate: vi.fn(),
  packagingDelete: vi.fn(),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({ worker: { id: 77, branchId: 'branch-1', branchCode: 'BUD01' } }),
}))

vi.mock('../../services/api/index', () => ({
  branchApi: { listActive: mocks.branchListActive },
  currencyApi: { getActive: mocks.currencyGetActive },
  packagingApi: {
    list: mocks.packagingList,
    create: mocks.packagingCreate,
    delete: mocks.packagingDelete,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

const branches = [{ id: 'branch-1', code: 'BUD01', name: 'Budapest 01' }]
const currencies = [{ id: 1, code: 'EUR', name: 'Euró', decimals: 2, active: true }]
const records = [
  {
    id: 'pack-1',
    branchId: 'branch-1',
    currencyCode: 'EUR',
    packagingDate: '2026-06-18',
    bundleCount: 2,
    denomination: 100,
    bundleSize: 100,
    notes: 'Teszt',
  },
]

describe('PackagingPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.branchListActive.mockResolvedValue(branches)
    mocks.currencyGetActive.mockResolvedValue(currencies)
    mocks.packagingList.mockResolvedValue(records)
    mocks.packagingCreate.mockResolvedValue({ ...records[0], id: 'pack-2' })
    mocks.packagingDelete.mockResolvedValue(undefined)
    vi.spyOn(window, 'confirm').mockReturnValue(true)
  })

  it('branch alapján listázza a göngyöleg rekordokat', async () => {
    render(<PackagingPage />)

    await waitFor(() => {
      expect(mocks.packagingList).toHaveBeenCalledWith('branch-1', '', '')
      expect(screen.getByText('Teszt')).toBeInTheDocument()
    })
  })

  it('rögzítéskor POST /packaging szerződést hív', async () => {
    const user = userEvent.setup()
    render(<PackagingPage />)

    await waitFor(() => expect(screen.getByText('Teszt')).toBeInTheDocument())
    await user.clear(screen.getByTestId('packaging-denomination'))
    await user.type(screen.getByTestId('packaging-denomination'), '200')
    await user.clear(screen.getByTestId('packaging-bundle-count'))
    await user.type(screen.getByTestId('packaging-bundle-count'), '3')
    await user.clear(screen.getByTestId('packaging-notes'))
    await user.type(screen.getByTestId('packaging-notes'), 'Új rekord')
    await user.click(screen.getByTestId('packaging-create'))

    await waitFor(() => {
      expect(mocks.packagingCreate).toHaveBeenCalledWith(
        expect.objectContaining({
          branchId: 'branch-1',
          currencyCode: 'EUR',
          bundleCount: 3,
          denomination: 200,
          bundleSize: 100,
          notes: 'Új rekord',
        }),
      )
    })
  })

  it('törléskor DELETE /packaging/{id} szerződést hív', async () => {
    const user = userEvent.setup()
    render(<PackagingPage />)

    await waitFor(() => expect(screen.getByText('Teszt')).toBeInTheDocument())
    await user.click(screen.getByTitle('Törlés'))

    await waitFor(() => {
      expect(mocks.packagingDelete).toHaveBeenCalledWith('pack-1')
    })
  })
})
