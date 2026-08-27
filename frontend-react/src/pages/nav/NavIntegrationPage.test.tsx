import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import NavIntegrationPage from './NavIntegrationPage'

const mocks = vi.hoisted(() => ({
  sendTransaction: vi.fn(),
  receiveReceiptNumber: vi.fn(),
  sendQrCode: vi.fn(),
  toastWarning: vi.fn(),
  toastSuccess: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  navIntegrationApi: {
    sendTransaction: mocks.sendTransaction,
    receiveReceiptNumber: mocks.receiveReceiptNumber,
    sendQrCode: mocks.sendQrCode,
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    warning: mocks.toastWarning,
    success: mocks.toastSuccess,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: mocks.loggerError,
  },
}))

describe('NavIntegrationPage receipt number backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.receiveReceiptNumber.mockResolvedValue('REC-20260618')
    mocks.sendQrCode.mockResolvedValue(true)
  })

  it('a Nyugtaszám fogadása gomb a GET /nav-integration/receive-receipt-number wrapperre köt', async () => {
    const user = userEvent.setup()
    render(<NavIntegrationPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'COM3')
    await user.click(screen.getByRole('button', { name: /Nyugtaszám fogadása/i }))

    await waitFor(() => {
      expect(mocks.receiveReceiptNumber).toHaveBeenCalledWith('COM3')
    })
    expect(await screen.findAllByText(/REC-20260618/)).toHaveLength(2)
    expect(mocks.toastSuccess).toHaveBeenCalledWith(
      'Nyugtaszám fogadva',
      'Bizonylatszám: REC-20260618',
    )
  })

  it('a QR kód küldése gomb a POST /nav-integration/send-qr-code wrapperre köt', async () => {
    const user = userEvent.setup()
    render(<NavIntegrationPage />)

    await user.selectOptions(screen.getByRole('combobox'), 'COM3')
    await user.type(screen.getByLabelText('QR kód'), 'NAV-QR-001')
    await user.click(screen.getByRole('button', { name: /QR kód küldése/i }))

    await waitFor(() => {
      expect(mocks.sendQrCode).toHaveBeenCalledWith('NAV-QR-001', 'COM3')
    })
    expect(mocks.toastSuccess).toHaveBeenCalledWith('QR kód elküldve', 'Port: COM3')
  })
})
