import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import DocumentPairCapture from './DocumentPairCapture'

const mocks = vi.hoisted(() => ({
  scanSaveDocument: vi.fn(),
  queueScannedDocument: vi.fn(),
  getCustomerDocuments: vi.fn(),
  toast: { success: vi.fn(), error: vi.fn(), warning: vi.fn() },
  logger: { warn: vi.fn(), error: vi.fn() },
}))

vi.mock('../ui/toaster', () => ({ toast: mocks.toast }))
vi.mock('../../utils/logger', () => ({ logger: mocks.logger }))
vi.mock('../../services/api/index', () => ({
  documentScannerApi: { getCustomerDocuments: mocks.getCustomerDocuments },
}))
vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

// --- helpers ---
function setElectronAvailable(available: boolean) {
  if (available) {
    Object.defineProperty(window, 'electronAPI', {
      value: {
        scanSaveDocument: mocks.scanSaveDocument,
        queueScannedDocument: mocks.queueScannedDocument,
      },
      writable: true,
      configurable: true,
    })
  } else {
    Object.defineProperty(window, 'electronAPI', {
      value: undefined,
      writable: true,
      configurable: true,
    })
  }
}

function mockGetUserMedia() {
  const track = { stop: vi.fn() }
  const stream = { getTracks: () => [track] }
  Object.defineProperty(navigator, 'mediaDevices', {
    value: { getUserMedia: vi.fn().mockResolvedValue(stream) },
    configurable: true,
    writable: true,
  })
  return { track, stream }
}

function mockVideoAndCanvas() {
  const drawImage = vi.fn()
  const ctx = { drawImage }
  const toDataURL = vi.fn().mockReturnValue('data:image/png;base64,ZmFrZS1iYXNlNjQtZGF0YQ==')
  // canvas
  const canvasProto = HTMLCanvasElement.prototype
  vi.spyOn(canvasProto, 'getContext').mockReturnValue(ctx as unknown as CanvasRenderingContext2D)
  vi.spyOn(canvasProto, 'toDataURL').mockReturnValue(toDataURL())
  // video element
  Object.defineProperty(HTMLVideoElement.prototype, 'videoWidth', {
    configurable: true,
    get: () => 640,
  })
  Object.defineProperty(HTMLVideoElement.prototype, 'videoHeight', {
    configurable: true,
    get: () => 480,
  })
  Object.defineProperty(HTMLVideoElement.prototype, 'srcObject', {
    configurable: true,
    set: () => {},
    get: () => null,
  })
  return { drawImage, toDataURL, ctx }
}

beforeEach(() => {
  vi.clearAllMocks()
  setElectronAvailable(true)
  mockGetUserMedia()
  mockVideoAndCanvas()
  mocks.getCustomerDocuments.mockResolvedValue([])
  mocks.scanSaveDocument.mockResolvedValue({ path: '/mock/encrypted.enc', encrypted: true })
  mocks.queueScannedDocument.mockResolvedValue(1)
})

afterEach(() => {
  vi.restoreAllMocks()
  // restore electronAPI
  Object.defineProperty(window, 'electronAPI', { value: undefined, configurable: true })
})

describe('DocumentPairCapture', () => {
  it('renders fallback when not in Electron', async () => {
    setElectronAvailable(false)
    render(<DocumentPairCapture customerId={1} />)
    expect(screen.getByText('documents.okmanyCaptureNemElectron')).toBeInTheDocument()
    // camera IPC must never be called
    expect(mocks.scanSaveDocument).not.toHaveBeenCalled()
    // allow any pending microtasks to settle (camera init is Electron-guarded away)
    await new Promise((r) => setTimeout(r, 0))
  })

  it('capturing a side calls scanSaveDocument with NON-EMPTY base64', async () => {
    render(<DocumentPairCapture customerId={1} />)

    const captureBtns = await screen.findAllByRole('button', { name: /okmanyCaptureElolap/i })
    fireEvent.click(captureBtns[0]!)

    await waitFor(() => {
      expect(mocks.scanSaveDocument).toHaveBeenCalled()
    })

    const args = mocks.scanSaveDocument.mock.calls[0]!
    const base64Arg = args[2]
    // NEVER empty — the regression that caused 0-byte files
    expect(typeof base64Arg).toBe('string')
    expect(base64Arg.length).toBeGreaterThan(0)
    expect(base64Arg).not.toBe('')
  })

  it('upload calls queueScannedDocument with {customerId, documentType, frontPath, backPath}', async () => {
    render(<DocumentPairCapture customerId={7} />)

    // Capture front
    const frontBtns = await screen.findAllByRole('button', { name: /okmanyCaptureElolap/i })
    fireEvent.click(frontBtns[0]!)
    await waitFor(() => expect(mocks.scanSaveDocument).toHaveBeenCalled())

    // Capture back
    const backBtns = screen.getAllByRole('button', { name: /okmanyCaptureHatlap/i })
    fireEvent.click(backBtns[0]!)
    await waitFor(() => expect(mocks.scanSaveDocument).toHaveBeenCalledTimes(2))

    // Upload
    const uploadBtn = await screen.findByRole('button', { name: /okmanyCaptureFeltoltes/i })
    await waitFor(() => expect(uploadBtn).not.toBeDisabled())
    fireEvent.click(uploadBtn)

    await waitFor(() => {
      expect(mocks.queueScannedDocument).toHaveBeenCalledTimes(1)
    })

    const payload = mocks.queueScannedDocument.mock.calls[0]![0]
    expect(payload).toMatchObject({
      customerId: 7,
      documentType: 'szemelyi',
      frontPath: '/mock/encrypted.enc',
      backPath: '/mock/encrypted.enc',
    })
  })

  it('error path shows a toast and logs a sanitized message (no raw axios body)', async () => {
    // scanSaveDocument rejects with an axios-shaped error whose config.data contains a PIN
    mocks.scanSaveDocument.mockRejectedValueOnce({
      message: 'boom',
      config: { data: '{"pin":"123456"}' },
      response: { data: { error: 'Szerver hiba' } },
    })

    render(<DocumentPairCapture customerId={1} />)

    const frontBtns = await screen.findAllByRole('button', { name: /okmanyCaptureElolap/i })
    fireEvent.click(frontBtns[0]!)

    await waitFor(() => {
      expect(mocks.toast.error).toHaveBeenCalledWith(
        'documents.okmanyCaptureHiba',
        expect.any(String),
      )
    })

    // Logger must be called with a string (sanitized), not the raw axios error object
    expect(mocks.logger.error).toHaveBeenCalled()
    const logArgs = mocks.logger.error.mock.calls[0]!
    const thirdArg = logArgs[2]
    expect(typeof thirdArg).toBe('string')
    // MUST NOT contain the raw PIN-bearing config body
    expect(thirdArg).not.toContain('123456')
    expect(thirdArg).not.toContain('config')
  })
})
