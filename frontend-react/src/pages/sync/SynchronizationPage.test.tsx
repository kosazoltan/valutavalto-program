import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import SynchronizationPage from './SynchronizationPage'

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  shouldSync: vi.fn(),
  synchronize: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({
      worker: {
        id: 7,
        role: 'ADMIN',
        branchId: '11111111-1111-1111-1111-111111111111',
      },
      activeRole: 'ADMIN',
    }),
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: vi.fn(),
    warning: vi.fn(),
    error: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: mocks.apiGet,
    post: mocks.apiPost,
  },
  synchronizationApi: {
    shouldSync: mocks.shouldSync,
    synchronize: mocks.synchronize,
  },
}))

const completedRow = {
  id: 'dc-1',
  branchId: '11111111-1111-1111-1111-111111111111',
  collectionDate: '2026-06-18',
  status: 'COMPLETED',
  collectionType: 'DAILY',
  transactionCount: 12,
}
const today = new Date().toISOString().slice(0, 10)

const branchSyncStatus = {
  branchId: '11111111-1111-1111-1111-111111111111',
  status: 'ONLINE',
  lastSuccessfulSyncAt: '2026-06-18T09:00:00',
  pendingUpload: 2,
  pendingDownload: 1,
}

const branchSyncHistory = {
  content: [
    {
      id: 'sync-1',
      syncType: 'FULL',
      status: 'COMPLETED',
      startedAt: '2026-06-18T08:30:00',
      recordsSynced: 44,
    },
  ],
}

const ftpSyncHistory = [
  {
    id: 'ftp-1',
    direction: 'UPLOAD',
    fileName: 'daily_20260618.xml',
    status: 'SUCCESS',
    fileSizeBytes: 2048,
    startedAt: '2026-06-18T09:15:00',
  },
]

describe('SynchronizationPage data collection backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.shouldSync.mockResolvedValue({ shouldSync: true, pendingCount: 3 })
    mocks.synchronize.mockResolvedValue({ recordsSynced: 5 })
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/data-collection/status') return Promise.resolve({ data: [completedRow] })
      if (path === '/sync/status/11111111-1111-1111-1111-111111111111')
        return Promise.resolve({ data: branchSyncStatus })
      if (path === '/sync/history/11111111-1111-1111-1111-111111111111')
        return Promise.resolve({ data: branchSyncHistory })
      if (path === '/ftp-sync/history/11111111-1111-1111-1111-111111111111')
        return Promise.resolve({ data: ftpSyncHistory })
      return Promise.resolve({ data: [] })
    })
    mocks.apiPost.mockImplementation((path: string) => {
      if (path === '/data-collection/collect')
        return Promise.resolve({ status: 200, data: completedRow })
      if (path === '/data-collection/collect-all')
        return Promise.resolve({ status: 200, data: [completedRow] })
      if (path === '/data-collection/retry')
        return Promise.resolve({ status: 200, data: { retriedCount: 2 } })
      if (path === '/ftp-sync/rates/11111111-1111-1111-1111-111111111111')
        return Promise.resolve({ status: 200, data: { success: true, fileName: 'rates.dat' } })
      if (path === '/ftp-sync/daily-report/11111111-1111-1111-1111-111111111111')
        return Promise.resolve({ status: 200, data: { success: true, fileName: 'daily.xml' } })
      if (path === '/ftp-sync/transactions/11111111-1111-1111-1111-111111111111')
        return Promise.resolve({
          status: 200,
          data: { success: true, fileName: 'transactions.xml' },
        })
      if (path === '/sync/rates/11111111-1111-1111-1111-111111111111')
        return Promise.resolve({ status: 200, data: { status: 'COMPLETED', syncType: 'RATES' } })
      if (path === '/sync/transactions/11111111-1111-1111-1111-111111111111')
        return Promise.resolve({
          status: 200,
          data: { status: 'COMPLETED', syncType: 'TRANSACTIONS' },
        })
      if (path === '/sync/inventory/11111111-1111-1111-1111-111111111111')
        return Promise.resolve({
          status: 200,
          data: { status: 'COMPLETED', syncType: 'INVENTORY' },
        })
      if (path === '/sync/full/11111111-1111-1111-1111-111111111111')
        return Promise.resolve({ status: 200, data: { status: 'COMPLETED', syncType: 'FULL' } })
      return Promise.resolve({ status: 200, data: {} })
    })
  })

  it('admin nézetben beköti a data-collection status, collect, collect-all és retry endpointokat', async () => {
    render(<SynchronizationPage />)

    await screen.findByText('Központi adatgyűjtés')

    expect(mocks.apiGet).toHaveBeenCalledWith('/data-collection/status')
    expect(mocks.apiGet).toHaveBeenCalledWith('/sync/status/11111111-1111-1111-1111-111111111111')
    expect(mocks.apiGet).toHaveBeenCalledWith(
      '/sync/history/11111111-1111-1111-1111-111111111111',
      {
        params: { page: 0, size: 5 },
        _preservePaged: true,
      },
    )
    expect(mocks.apiGet).toHaveBeenCalledWith(
      '/ftp-sync/history/11111111-1111-1111-1111-111111111111',
    )
    expect(screen.getAllByText('COMPLETED').length).toBeGreaterThanOrEqual(1)
    expect(screen.getByText('12')).toBeInTheDocument()
    expect(screen.getByTestId('branch-sync-panel')).toHaveTextContent('ONLINE')
    expect(screen.getByTestId('branch-sync-history-row')).toHaveTextContent('44 rekord')
    expect(screen.getByTestId('branch-sync-actions')).toHaveTextContent('Branch sync műveletek')
    expect(screen.getByTestId('ftp-sync-history')).toHaveTextContent('daily_20260618.xml')

    fireEvent.click(screen.getByRole('button', { name: 'Iroda gyűjtése' }))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith(
        '/data-collection/collect',
        {
          branchId: '11111111-1111-1111-1111-111111111111',
          date: today,
        },
        { validateStatus: expect.any(Function) },
      )
    })

    fireEvent.click(screen.getByRole('button', { name: 'Összes iroda gyűjtése' }))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith(
        '/data-collection/collect-all',
        {
          date: today,
        },
        { validateStatus: expect.any(Function) },
      )
    })

    fireEvent.click(screen.getByRole('button', { name: 'Sikertelenek újra' }))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/data-collection/retry')
    })

    fireEvent.click(screen.getByTestId('ftp-sync-rates'))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith(
        '/ftp-sync/rates/11111111-1111-1111-1111-111111111111',
        null,
        {
          validateStatus: expect.any(Function),
        },
      )
    })

    fireEvent.click(screen.getByTestId('ftp-sync-daily-report'))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith(
        '/ftp-sync/daily-report/11111111-1111-1111-1111-111111111111',
        null,
        {
          validateStatus: expect.any(Function),
        },
      )
    })

    fireEvent.click(screen.getByTestId('ftp-sync-transactions'))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith(
        '/ftp-sync/transactions/11111111-1111-1111-1111-111111111111',
        null,
        {
          validateStatus: expect.any(Function),
        },
      )
    })

    fireEvent.click(screen.getByTestId('branch-sync-rates'))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith(
        '/sync/rates/11111111-1111-1111-1111-111111111111',
        null,
        {
          validateStatus: expect.any(Function),
        },
      )
    })

    fireEvent.click(screen.getByTestId('branch-sync-transactions'))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith(
        '/sync/transactions/11111111-1111-1111-1111-111111111111',
        null,
        {
          validateStatus: expect.any(Function),
        },
      )
    })

    fireEvent.click(screen.getByTestId('branch-sync-inventory'))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith(
        '/sync/inventory/11111111-1111-1111-1111-111111111111',
        null,
        {
          validateStatus: expect.any(Function),
        },
      )
    })

    fireEvent.click(screen.getByTestId('branch-sync-full'))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith(
        '/sync/full/11111111-1111-1111-1111-111111111111',
        null,
        {
          validateStatus: expect.any(Function),
        },
      )
    })
  })
})
