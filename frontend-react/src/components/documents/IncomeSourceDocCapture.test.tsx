import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import IncomeSourceDocCapture from './IncomeSourceDocCapture'

const mocks = vi.hoisted(() => ({
  scanSaveDocument: vi.fn(),
  queueScannedDocument: vi.fn(),
  toast: { success: vi.fn(), error: vi.fn(), warning: vi.fn() },
  logger: { warn: vi.fn(), error: vi.fn() },
}))

vi.mock('../ui/toaster', () => ({ toast: mocks.toast }))
vi.mock('../../utils/logger', () => ({ logger: mocks.logger }))
vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

function setElectronSpies() {
  Object.defineProperty(window, 'electronAPI', {
    value: {
      scanSaveDocument: mocks.scanSaveDocument,
      queueScannedDocument: mocks.queueScannedDocument,
    },
    writable: true,
    configurable: true,
  })
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

function mockVideoAndCanvas(dataUrl = 'data:image/jpeg;base64,am92ZWRlbGVtLWZvcnJhcy1rZXA=') {
  const drawImage = vi.fn()
  const ctx = { drawImage }
  vi.spyOn(HTMLCanvasElement.prototype, 'getContext').mockReturnValue(
    ctx as unknown as CanvasRenderingContext2D,
  )
  vi.spyOn(HTMLCanvasElement.prototype, 'toDataURL').mockReturnValue(dataUrl)
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
  return { drawImage, ctx }
}

beforeEach(() => {
  vi.clearAllMocks()
  setElectronSpies()
  mockGetUserMedia()
  mockVideoAndCanvas()
})

afterEach(() => {
  vi.restoreAllMocks()
  Object.defineProperty(window, 'electronAPI', { value: undefined, configurable: true })
})

describe('IncomeSourceDocCapture', () => {
  it('capture calls onCaptured with NON-EMPTY base64', async () => {
    const onCaptured = vi.fn()
    render(<IncomeSourceDocCapture onCaptured={onCaptured} onClear={vi.fn()} />)

    fireEvent.click(await screen.findByRole('button', { name: /incomeProof.capture/i }))

    await waitFor(() => expect(onCaptured).toHaveBeenCalledWith('am92ZWRlbGVtLWZvcnJhcy1rZXA='))
    expect(onCaptured.mock.calls[0]![0].length).toBeGreaterThan(0)
  })

  it('empty canvas shows error toast and does NOT call onCaptured', async () => {
    vi.restoreAllMocks()
    mockGetUserMedia()
    mockVideoAndCanvas('data:image/jpeg;base64,')
    const onCaptured = vi.fn()
    render(<IncomeSourceDocCapture onCaptured={onCaptured} onClear={vi.fn()} />)

    fireEvent.click(await screen.findByRole('button', { name: /incomeProof.capture/i }))

    await waitFor(() => expect(mocks.toast.error).toHaveBeenCalled())
    expect(onCaptured).not.toHaveBeenCalled()
  })

  it('does not call Electron scan or queue IPC during capture', async () => {
    const onCaptured = vi.fn()
    render(<IncomeSourceDocCapture onCaptured={onCaptured} onClear={vi.fn()} />)

    fireEvent.click(await screen.findByRole('button', { name: /incomeProof.capture/i }))

    await waitFor(() => expect(onCaptured).toHaveBeenCalled())
    expect(mocks.scanSaveDocument).not.toHaveBeenCalled()
    expect(mocks.queueScannedDocument).not.toHaveBeenCalled()
  })
})
