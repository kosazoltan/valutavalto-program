import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CameraPlaybackPage from './CameraPlaybackPage'
import { api, branchApi } from '../../services/api/index'

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: vi.fn(),
  },
  branchApi: {
    listActive: vi.fn(),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('./CameraReviewPanel', () => ({
  default: ({
    branchId,
    date,
    cameraIds,
  }: {
    branchId: string
    date: string
    cameraIds: string[]
  }) => (
    <div data-testid="camera-review-panel">
      {branchId}:{date}:{cameraIds.join(',')}
    </div>
  ),
}))

const mockApi = api as unknown as {
  get: ReturnType<typeof vi.fn>
}

const mockBranchApi = branchApi as unknown as {
  listActive: ReturnType<typeof vi.fn>
}

const recording = {
  id: 'rec-1',
  branchId: '11111111-1111-1111-1111-111111111111',
  cameraId: 'CAM-01',
  startTime: '2026-06-18T08:00:00',
  endTime: '2026-06-18T08:10:00',
  fileSizeBytes: 1024,
  uploadedToServer: true,
  expiresAt: '2026-08-01',
  status: 'COMPLETED',
  linkedTransactions: 1,
}

const recording2 = {
  ...recording,
  id: 'rec-2',
  cameraId: 'CAM-02',
  linkedTransactions: 0,
}

describe('CameraPlaybackPage backend kapcsolatok', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockBranchApi.listActive.mockResolvedValue([
      { id: '11111111-1111-1111-1111-111111111111', code: 'BUD01', name: 'Budapest 01' },
      { id: '22222222-2222-2222-2222-222222222222', code: 'BUD02', name: 'Budapest 02' },
    ])
    mockApi.get.mockImplementation((url: string) => {
      if (url.startsWith('/camera/recordings?')) {
        return Promise.resolve({
          data: [recording, recording2],
        })
      }
      if (url.startsWith('/camera/review/overview?')) {
        return Promise.resolve({
          data: [
            {
              branchId: '22222222-2222-2222-2222-222222222222',
              branchCode: 'BUD02',
              branchName: 'Budapest 02',
              date: '2026-06-19',
              recordingCount: 2,
              markCount: 1,
              reviewed: false,
              problematic: true,
            },
          ],
        })
      }
      if (url === '/camera/recordings/rec-1') {
        return Promise.resolve({ data: recording })
      }
      if (url === '/camera/admin/access-logs/rec-1') {
        return Promise.resolve({
          data: [
            { id: 'log-1', workerId: 77, action: 'VIEW', createdAt: '2026-06-18T08:11:00' },
            { id: 'log-2', workerId: 78, action: 'VIEW', createdAt: '2026-06-18T08:12:00' },
          ],
        })
      }
      if (url === '/camera/recordings/by-receipt/V0001') {
        return Promise.resolve({
          data: [
            {
              id: 'link-receipt-1',
              recording,
              transactionId: 123,
              receiptNumber: 'V0001',
              transactionTime: '2026-06-18T08:05:00',
              frameOffsetSeconds: 300,
            },
          ],
        })
      }
      if (url === '/camera/recordings/by-transaction/123') {
        return Promise.resolve({
          data: [
            {
              id: 'link-transaction-1',
              recording,
              transactionId: 123,
              receiptNumber: 'V0001',
              transactionTime: '2026-06-18T08:05:00',
              frameOffsetSeconds: 300,
            },
          ],
        })
      }
      return Promise.resolve({ data: [] })
    })
  })

  it('branchId-val keres szerver oldali felvételeket, majd részletet és access logot tölt', async () => {
    const user = userEvent.setup()
    render(<CameraPlaybackPage />)

    await waitFor(() => {
      expect(mockBranchApi.listActive).toHaveBeenCalled()
    })

    await user.selectOptions(
      screen.getByTestId('camera-playback-branch'),
      '11111111-1111-1111-1111-111111111111',
    )
    await user.type(screen.getByLabelText('common.startDate'), '2026-06-18')
    await user.type(screen.getByLabelText('camera.zaroDatum'), '2026-06-18')
    await user.click(screen.getByRole('button', { name: /common.search/i }))

    await waitFor(() => {
      const call = mockApi.get.mock.calls.find(([url]) =>
        String(url).startsWith('/camera/recordings?'),
      )
      expect(call?.[0]).toContain('branchId=11111111-1111-1111-1111-111111111111')
    })

    await user.click(await screen.findByTestId('camera-server-recording-rec-1'))

    await waitFor(() => {
      expect(mockApi.get).toHaveBeenCalledWith('/camera/recordings/rec-1')
      expect(mockApi.get).toHaveBeenCalledWith('/camera/admin/access-logs/rec-1')
    })
    expect(screen.getByTestId('camera-access-log-count')).toHaveTextContent('2')
  })

  it('bizonylatszám és tranzakció ID alapján is a kapcsolt kamera végpontokat hívja', async () => {
    const user = userEvent.setup()
    render(<CameraPlaybackPage />)

    await user.type(await screen.findByLabelText('camera.bizonylatszam'), 'V0001')
    await user.click(screen.getByRole('button', { name: 'camera.bizonylatKereses' }))

    await waitFor(() => {
      expect(mockApi.get).toHaveBeenCalledWith('/camera/recordings/by-receipt/V0001')
    })
    await user.click(await screen.findByTestId('camera-linked-recording-link-receipt-1'))
    await waitFor(() => {
      expect(mockApi.get).toHaveBeenCalledWith('/camera/recordings/rec-1')
      expect(mockApi.get).toHaveBeenCalledWith('/camera/admin/access-logs/rec-1')
    })

    await user.type(screen.getByLabelText('camera.tranzakcioId'), '123')
    await user.click(screen.getByRole('button', { name: 'camera.tranzakcioKereses' }))

    await waitFor(() => {
      expect(mockApi.get).toHaveBeenCalledWith('/camera/recordings/by-transaction/123')
    })
    expect(
      await screen.findByTestId('camera-linked-recording-link-transaction-1'),
    ).toBeInTheDocument()
  })
})

describe('CameraPlaybackPage FS-14 review integráció', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockBranchApi.listActive.mockResolvedValue([
      { id: '11111111-1111-1111-1111-111111111111', code: 'BUD01', name: 'Budapest 01' },
      { id: '22222222-2222-2222-2222-222222222222', code: 'BUD02', name: 'Budapest 02' },
    ])
    mockApi.get.mockImplementation((url: string) => {
      if (url.startsWith('/camera/recordings?')) {
        return Promise.resolve({ data: [recording, recording2] })
      }
      if (url.startsWith('/camera/review/overview?')) {
        return Promise.resolve({
          data: [
            {
              branchId: '22222222-2222-2222-2222-222222222222',
              branchCode: 'BUD02',
              branchName: 'Budapest 02',
              date: '2026-06-19',
              recordingCount: 2,
              markCount: 1,
              reviewed: false,
              problematic: true,
            },
          ],
        })
      }
      return Promise.resolve({ data: [] })
    })
  })

  it('kamera-váltóval kamerára szűri a szerver oldali felvételeket', async () => {
    const user = userEvent.setup()
    render(<CameraPlaybackPage />)

    await user.selectOptions(
      await screen.findByTestId('camera-playback-branch'),
      '11111111-1111-1111-1111-111111111111',
    )
    await user.type(screen.getByLabelText('common.startDate'), '2026-06-18')
    await user.type(screen.getByLabelText('camera.zaroDatum'), '2026-06-18')
    await user.click(screen.getByRole('button', { name: /common.search/i }))

    expect(await screen.findByTestId('camera-server-recording-rec-1')).toBeInTheDocument()
    expect(screen.getByTestId('camera-server-recording-rec-2')).toBeInTheDocument()

    await user.click(screen.getByTestId('camera-switch-CAM-02'))

    expect(screen.queryByTestId('camera-server-recording-rec-1')).not.toBeInTheDocument()
    expect(screen.getByTestId('camera-server-recording-rec-2')).toBeInTheDocument()
  })

  it('overview problémás-szűrővel kérdez, majd sor-kattintás részletkeresést indít', async () => {
    const user = userEvent.setup()
    render(<CameraPlaybackPage />)

    await user.type(screen.getByLabelText('common.startDate'), '2026-06-18')
    await user.type(screen.getByLabelText('camera.zaroDatum'), '2026-06-20')
    await user.click(screen.getByTestId('review-overview-only-problematic'))
    await user.click(screen.getByTestId('review-overview-fetch'))

    await waitFor(() => {
      const overviewCall = mockApi.get.mock.calls.find(([url]) =>
        String(url).startsWith('/camera/review/overview?'),
      )
      expect(overviewCall?.[0]).toContain('onlyProblematic=true')
    })

    await user.click(
      await screen.findByTestId(
        'review-overview-row-22222222-2222-2222-2222-222222222222-2026-06-19',
      ),
    )

    await waitFor(() => {
      const recordingCall = mockApi.get.mock.calls.find(([url]) =>
        String(url).includes('branchId=22222222-2222-2222-2222-222222222222'),
      )
      expect(recordingCall?.[0]).toContain('start=2026-06-19T00%3A00%3A00')
      expect(recordingCall?.[0]).toContain('end=2026-06-19T23%3A59%3A59')
    })
  })
})
