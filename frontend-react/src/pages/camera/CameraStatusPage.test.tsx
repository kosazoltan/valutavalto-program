import { render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CameraStatusPage from './CameraStatusPage'
import { api } from '../../services/api/index'

vi.mock('react-i18next', () => ({
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
})
