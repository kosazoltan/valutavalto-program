import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CameraReviewPanel from './CameraReviewPanel'
import { api } from '../../services/api/index'

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
    delete: vi.fn(),
    put: vi.fn(),
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: { worker: { id: number } }) => unknown) =>
    selector({ worker: { id: 42 } }),
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: vi.fn(),
  },
}))

const mockApi = api as unknown as {
  get: ReturnType<typeof vi.fn>
  post: ReturnType<typeof vi.fn>
  delete: ReturnType<typeof vi.fn>
  put: ReturnType<typeof vi.fn>
}

const ownMark = {
  id: 'mark-own',
  branchId: 'branch-1',
  reviewDate: '2026-07-10',
  cameraId: 'CAM-01',
  markTime: '08:05:07',
  openingClosingOk: true,
  invoicesOk: true,
  breaksOk: true,
  boardOk: true,
  curtainOk: false,
  note: 'függöny nyitva',
  createdByWorkerId: 42,
  createdByWorkerCode: 'W42',
  createdAt: '2026-07-10T08:06:00',
  problematic: true,
}

const foreignMark = {
  ...ownMark,
  id: 'mark-foreign',
  markTime: '08:07:00',
  curtainOk: true,
  note: null,
  createdByWorkerId: 43,
  createdByWorkerCode: 'W43',
  problematic: false,
}

const transaction = {
  id: 'tx-1',
  transactionId: 1001,
  receiptNumber: 'V0001',
  transactionTime: '2026-07-10T08:04:00',
  frameOffsetSeconds: 240,
  cameraId: 'CAM-01',
  recordingId: 'rec-1',
}

function mockInitialReviewData() {
  mockApi.get.mockImplementation((url: string) => {
    if (url.startsWith('/camera/review/marks?')) {
      return Promise.resolve({ data: [foreignMark, ownMark] })
    }
    if (url.startsWith('/camera/review/status?')) {
      return Promise.resolve({ data: { reviewed: false } })
    }
    if (url.startsWith('/camera/review/transactions?')) {
      return Promise.resolve({ data: [transaction] })
    }
    return Promise.resolve({ data: [] })
  })
}

describe('CameraReviewPanel', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockInitialReviewData()
    mockApi.post.mockResolvedValue({ data: ownMark })
    mockApi.delete.mockResolvedValue({ data: undefined })
    mockApi.put.mockResolvedValue({ data: { reviewed: true, reviewedByWorkerCode: 'W42' } })
  })

  it('betöltéskor lekéri és időrendben rendereli a tranzakciókat és megjelöléseket', async () => {
    render(<CameraReviewPanel branchId="branch-1" date="2026-07-10" cameraIds={['CAM-01']} />)

    expect(await screen.findByTestId('review-tx-row-tx-1')).toBeInTheDocument()
    expect(await screen.findByTestId('review-mark-row-mark-own')).toBeInTheDocument()
    expect(screen.getByTestId('review-mark-row-mark-foreign')).toBeInTheDocument()

    expect(mockApi.get).toHaveBeenCalledWith(
      '/camera/review/marks?branchId=branch-1&date=2026-07-10',
    )
    expect(mockApi.get).toHaveBeenCalledWith(
      '/camera/review/status?branchId=branch-1&date=2026-07-10',
    )
    expect(mockApi.get).toHaveBeenCalledWith(
      '/camera/review/transactions?branchId=branch-1&date=2026-07-10',
    )
  })

  it('megjelölést hoz létre másodperces idővel és öt feltétel-flaggel', async () => {
    const user = userEvent.setup()
    render(<CameraReviewPanel branchId="branch-1" date="2026-07-10" cameraIds={['CAM-01']} />)

    fireEvent.change(await screen.findByTestId('review-mark-form-time'), {
      target: { value: '08:05:07' },
    })
    await user.selectOptions(screen.getByLabelText('camera.feltetelFuggony'), 'bad')
    await user.click(screen.getByTestId('review-mark-submit'))

    await waitFor(() => {
      expect(mockApi.post).toHaveBeenCalledWith('/camera/review/marks', {
        branchId: 'branch-1',
        reviewDate: '2026-07-10',
        cameraId: 'CAM-01',
        markTime: '08:05:07',
        openingClosingOk: true,
        invoicesOk: true,
        breaksOk: true,
        boardOk: true,
        curtainOk: false,
        note: null,
      })
    })
  })

  it('csak saját markon mutat törlés-gombot, törlés után frissíti a listát', async () => {
    const user = userEvent.setup()
    render(<CameraReviewPanel branchId="branch-1" date="2026-07-10" cameraIds={['CAM-01']} />)

    const ownRow = await screen.findByTestId('review-mark-row-mark-own')
    const foreignRow = await screen.findByTestId('review-mark-row-mark-foreign')
    expect(within(ownRow).getByTestId('review-mark-delete-mark-own')).toBeInTheDocument()
    expect(
      within(foreignRow).queryByTestId('review-mark-delete-mark-foreign'),
    ).not.toBeInTheDocument()

    await user.click(screen.getByTestId('review-mark-delete-mark-own'))

    await waitFor(() => {
      expect(mockApi.delete).toHaveBeenCalledWith('/camera/review/marks/mark-own')
    })
    expect(mockApi.get).toHaveBeenCalledWith(
      '/camera/review/marks?branchId=branch-1&date=2026-07-10',
    )
  })

  it('problémás badge-et jelenít meg a problémás marknál', async () => {
    render(<CameraReviewPanel branchId="branch-1" date="2026-07-10" cameraIds={['CAM-01']} />)

    expect(await screen.findByTestId('review-mark-problem-mark-own')).toBeInTheDocument()
    expect(screen.queryByTestId('review-mark-problem-mark-foreign')).not.toBeInTheDocument()
  })

  it('átnézve checkbox pipálásakor PUT státuszt ment', async () => {
    const user = userEvent.setup()
    render(<CameraReviewPanel branchId="branch-1" date="2026-07-10" cameraIds={['CAM-01']} />)

    await user.click(await screen.findByTestId('review-status-checkbox'))

    await waitFor(() => {
      expect(mockApi.put).toHaveBeenCalledWith('/camera/review/status', {
        branchId: 'branch-1',
        reviewDate: '2026-07-10',
        reviewed: true,
      })
    })
  })
})
