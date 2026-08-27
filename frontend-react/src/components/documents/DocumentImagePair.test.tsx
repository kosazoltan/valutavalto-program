import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import DocumentImagePair from './DocumentImagePair'
import { toast } from '../ui/toaster'

const mockGetThumbnail = vi.fn()
const mockIssueViewGrant = vi.fn()
const mockGetFullImage = vi.fn()
const mockWorkersGet = vi.fn()

vi.mock('../../services/api/index', () => ({
  documentScannerApi: {
    getThumbnail: (...args: unknown[]) => mockGetThumbnail(...args),
    issueViewGrant: (...args: unknown[]) => mockIssueViewGrant(...args),
    getFullImage: (...args: unknown[]) => mockGetFullImage(...args),
  },
}))

vi.mock('../../services/api/client', () => ({
  api: {
    get: (...args: unknown[]) => mockWorkersGet(...args),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: { warn: vi.fn(), error: vi.fn() },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

const FRONT_BLOB = new Blob(['front-bytes'], { type: 'image/jpeg' })
const BACK_BLOB = new Blob(['back-bytes'], { type: 'image/jpeg' })
const FULL_BLOB = new Blob(['full-bytes'], { type: 'image/jpeg' })

beforeEach(() => {
  vi.clearAllMocks()
  mockGetThumbnail.mockImplementation(async (_id: string, side: 'FRONT' | 'BACK') =>
    side === 'FRONT' ? FRONT_BLOB : BACK_BLOB,
  )
  mockIssueViewGrant.mockResolvedValue(undefined)
  mockGetFullImage.mockResolvedValue(FULL_BLOB)
  mockWorkersGet.mockResolvedValue({
    data: [{ id: 42, role: 'SUPERVISOR', fullName: 'Vezető Vera' }],
  })
  vi.spyOn(toast, 'error')
})

afterEach(() => {
  vi.restoreAllMocks()
})

describe('DocumentImagePair', () => {
  it('renders front and back thumbnails on mount', async () => {
    render(<DocumentImagePair documentId="doc-1" hasFront={true} hasBack={true} />)

    await waitFor(() => {
      expect(mockGetThumbnail).toHaveBeenCalledWith('doc-1', 'FRONT')
      expect(mockGetThumbnail).toHaveBeenCalledWith('doc-1', 'BACK')
    })

    const imgs = screen.getAllByRole('img')
    expect(imgs.length).toBeGreaterThanOrEqual(2)
    for (const img of imgs) {
      expect((img as HTMLImageElement).src).toMatch(/^blob:/)
    }
  })

  it('opens grant modal on "Nagyítás" and does NOT fetch full-res before PIN success', async () => {
    render(<DocumentImagePair documentId="doc-1" hasFront={true} hasBack={true} />)

    await waitFor(() => expect(mockGetThumbnail).toHaveBeenCalled())

    // Click the FRONT "Nagyítás" button.
    const magnifyButtons = screen.getAllByRole('button', { name: /nagyitas/i })
    expect(magnifyButtons.length).toBeGreaterThanOrEqual(1)
    fireEvent.click(magnifyButtons[0]!)

    // Modal is open (dialog role), full-res fetch has NOT happened yet.
    await waitFor(() => {
      expect(screen.getByRole('dialog')).toBeInTheDocument()
    })
    expect(mockGetFullImage).not.toHaveBeenCalled()
  })

  it('successful PIN issues view-grant then fetches full image and shows it', async () => {
    render(<DocumentImagePair documentId="doc-1" hasFront={true} hasBack={true} />)

    await waitFor(() => expect(mockGetThumbnail).toHaveBeenCalled())

    const magnifyButtons = screen.getAllByRole('button', { name: /nagyitas/i })
    fireEvent.click(magnifyButtons[0]!)

    await waitFor(() => expect(screen.getByRole('dialog')).toBeInTheDocument())

    // Select approver (Vezető Vera, id=42).
    const approverSelect = (await screen.findByLabelText(/engedelyezo/i)) as HTMLSelectElement
    fireEvent.change(approverSelect, { target: { value: '42' } })

    // Enter PIN.
    const pinInput = (await screen.findByLabelText(/PIN/i)) as HTMLInputElement
    fireEvent.change(pinInput, { target: { value: '123456' } })

    // Submit.
    const submitBtn = screen.getByRole('button', { name: /engedelyezes/i })
    fireEvent.click(submitBtn)

    await waitFor(() => {
      expect(mockIssueViewGrant).toHaveBeenCalledWith('doc-1', 42, '123456')
    })

    // Full-res fetch happens AFTER the grant succeeds, for the FRONT side.
    await waitFor(() => {
      expect(mockGetFullImage).toHaveBeenCalledWith('doc-1', 'FRONT')
    })

    // The full-res image is rendered (the modal shows the big image).
    await waitFor(() => {
      const bigImgs = screen.getAllByRole('img')
      expect(bigImgs.some((img) => (img as HTMLImageElement).src.startsWith('blob:'))).toBe(true)
    })
  })

  it('grant error (400) shows error message and does NOT fetch full image', async () => {
    mockIssueViewGrant.mockRejectedValueOnce({
      response: { status: 400, data: { error: 'Hibás PIN' } },
    })

    render(<DocumentImagePair documentId="doc-1" hasFront={true} hasBack={true} />)

    await waitFor(() => expect(mockGetThumbnail).toHaveBeenCalled())

    const magnifyButtons = screen.getAllByRole('button', { name: /nagyitas/i })
    fireEvent.click(magnifyButtons[0]!)

    await waitFor(() => expect(screen.getByRole('dialog')).toBeInTheDocument())

    const approverSelect = (await screen.findByLabelText(/engedelyezo/i)) as HTMLSelectElement
    fireEvent.change(approverSelect, { target: { value: '42' } })

    const pinInput = (await screen.findByLabelText(/PIN/i)) as HTMLInputElement
    fireEvent.change(pinInput, { target: { value: '000000' } })

    const submitBtn = screen.getByRole('button', { name: /engedelyezes/i })
    fireEvent.click(submitBtn)

    await waitFor(() => {
      expect(screen.getByText(/Hibás PIN/)).toBeInTheDocument()
    })
    expect(mockGetFullImage).not.toHaveBeenCalled()
  })

  it('post-grant image fetch failure shows distinct error (NOT "Hibás PIN") and closes modal', async () => {
    // Grant succeeds (PIN valid), but getFullImage rejects.
    // Must NOT show the misleading "Hibás PIN" error; must surface a distinct
    // image-download error and close the modal.
    mockGetFullImage.mockRejectedValueOnce(new Error('network down'))

    render(<DocumentImagePair documentId="doc-1" hasFront={true} hasBack={true} />)

    await waitFor(() => expect(mockGetThumbnail).toHaveBeenCalled())

    const magnifyButtons = screen.getAllByRole('button', { name: /nagyitas/i })
    fireEvent.click(magnifyButtons[0]!)

    await waitFor(() => expect(screen.getByRole('dialog')).toBeInTheDocument())

    const approverSelect = (await screen.findByLabelText(/engedelyezo/i)) as HTMLSelectElement
    fireEvent.change(approverSelect, { target: { value: '42' } })

    const pinInput = (await screen.findByLabelText(/PIN/i)) as HTMLInputElement
    fireEvent.change(pinInput, { target: { value: '123456' } })

    const submitBtn = screen.getByRole('button', { name: /engedelyezes/i })
    fireEvent.click(submitBtn)

    // Grant succeeded — getFullImage was called.
    await waitFor(() => {
      expect(mockIssueViewGrant).toHaveBeenCalledWith('doc-1', 42, '123456')
      expect(mockGetFullImage).toHaveBeenCalledWith('doc-1', 'FRONT')
    })

    // Distinct image-download error toast, NOT the PIN error message.
    await waitFor(() => {
      expect(toast.error).toHaveBeenCalledWith(
        'documents.okmanyCaptureHiba',
        'documents.nagyitasKepLetoltesHiba',
      )
    })

    // Modal is closed (no dialog present) — setGrantSide(null) reached.
    await waitFor(() => {
      expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
    })

    // The misleading "Hibás PIN" error message must NOT appear.
    expect(screen.queryByText(/Hibás PIN/)).not.toBeInTheDocument()
  })

  it('includes the current worker in the approver list (D5: self-approval megengedett)', async () => {
    // D5: self-approval megengedett — a kérelmező is választható.
    // The active workers list includes id=42 (SUPERVISOR). The current worker is
    // also id=42, and per the documented contract (D5) they MUST appear in the
    // approver list (view-grant is a VIEW, not a money movement; 4-eyes does not apply).
    mockWorkersGet.mockResolvedValueOnce({
      data: [
        { id: 42, role: 'SUPERVISOR', fullName: 'Vezető Vera' },
        { id: 7, role: 'MANAGER', fullName: 'Műszakos Mihály' },
      ],
    })

    render(<DocumentImagePair documentId="doc-1" hasFront={true} hasBack={false} />)

    await waitFor(() => expect(mockGetThumbnail).toHaveBeenCalled())

    const magnifyButtons = screen.getAllByRole('button', { name: /nagyitas/i })
    fireEvent.click(magnifyButtons[0]!)

    await waitFor(() => expect(screen.getByRole('dialog')).toBeInTheDocument())

    // The approver select must include the current worker (id=42).
    const approverSelect = (await screen.findByLabelText(/engedelyezo/i)) as HTMLSelectElement
    const optionValues = Array.from(approverSelect.options)
      .map((o) => o.value)
      .filter(Boolean)
    expect(optionValues).toContain('42')
    expect(optionValues).toContain('7')
    expect(optionValues).toHaveLength(2)
  })
})
