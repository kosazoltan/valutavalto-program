import { render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CameraStatusPage from './CameraStatusPage'
import { api } from '../../services/api/index'

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: vi.fn(),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: vi.fn(),
    warn: vi.fn(),
  },
}))

const mockApi = api as unknown as {
  get: ReturnType<typeof vi.fn>
  post: ReturnType<typeof vi.fn>
}

describe('CameraStatusPage backend kapcsolatok', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockApi.get.mockImplementation((url: string) => {
      if (url === '/camera/admin/storage-stats') {
        return Promise.resolve({
          data: {
            totalUsageBytes: 1024 * 1024 * 500,
            availableSpaceBytes: 1024 * 1024 * 1500,
            totalRecordings: 12,
            oldestDate: '2026-06-01',
            newestDate: '2026-06-18',
          },
        })
      }
      if (url === '/camera/admin/upload-status') {
        return Promise.resolve({ data: { pendingUploads: 7 } })
      }
      if (url === '/camera/status') {
        return Promise.resolve({
          data: [
            {
              cameraId: 'cam1',
              recording: true,
              connected: true,
              frozen: true,
              lastFreshFrameAt: '2026-07-10T09:58:00',
            },
            {
              cameraId: 'cam2',
              recording: true,
              connected: true,
              frozen: false,
              lastFreshFrameAt: '2026-07-10T10:00:00',
            },
          ],
        })
      }
      return Promise.resolve({ data: {} })
    })
  })

  it('a storage és upload státuszt is a kamera admin backend endpointokról tölti', async () => {
    render(<CameraStatusPage />)

    await waitFor(() => {
      expect(mockApi.get).toHaveBeenCalledWith('/camera/admin/storage-stats')
      expect(mockApi.get).toHaveBeenCalledWith('/camera/admin/upload-status')
    })

    expect(screen.getByText('12')).toBeInTheDocument()
    expect(screen.getByTestId('camera-pending-uploads')).toHaveTextContent('7')
  })

  it('befagyott kamerát piros badge-dzsel jelzi, ép kamerát nem', async () => {
    render(<CameraStatusPage />)

    const badge = await screen.findByTestId('camera-frozen-badge-cam1')
    expect(badge).toHaveTextContent('camera.befagyott')
    expect(screen.queryByTestId('camera-frozen-badge-cam2')).not.toBeInTheDocument()
  })

  it('a kamera státusz fetch hibája nem töri el a tárolási státusz oldalt', async () => {
    mockApi.get.mockImplementation((url: string) => {
      if (url === '/camera/admin/storage-stats') {
        return Promise.resolve({
          data: {
            totalUsageBytes: 1024 * 1024 * 500,
            availableSpaceBytes: 1024 * 1024 * 1500,
            totalRecordings: 12,
            oldestDate: '2026-06-01',
            newestDate: '2026-06-18',
          },
        })
      }
      if (url === '/camera/admin/upload-status') {
        return Promise.resolve({ data: { pendingUploads: 7 } })
      }
      if (url === '/camera/status') {
        return Promise.reject(new Error('camera disabled'))
      }
      return Promise.resolve({ data: {} })
    })

    render(<CameraStatusPage />)

    await waitFor(() => expect(screen.getByTestId('camera-pending-uploads')).toHaveTextContent('7'))
    expect(screen.queryByTestId('camera-frozen-badge-cam1')).not.toBeInTheDocument()
  })

  it('nyugodt információs állapotot mutat, ha a kamera admin endpointok ki vannak kapcsolva', async () => {
    mockApi.get.mockImplementation((url: string) => {
      if (url === '/camera/admin/storage-stats') {
        return Promise.reject(new Error('camera subsystem disabled'))
      }
      if (url === '/camera/admin/upload-status') {
        return Promise.reject(new Error('camera subsystem disabled'))
      }
      if (url === '/camera/status') {
        return Promise.resolve({ data: [{ cameraId: 'cam1', recording: true, connected: true }] })
      }
      return Promise.resolve({ data: {} })
    })

    render(<CameraStatusPage />)

    expect(
      await screen.findByText('A kamera-alrendszer nincs engedélyezve ezen a szerveren.'),
    ).toBeInTheDocument()
    expect(screen.queryByTestId('camera-pending-uploads')).not.toBeInTheDocument()
    expect(mockApi.get).not.toHaveBeenCalledWith('/camera/status')
  })
})
