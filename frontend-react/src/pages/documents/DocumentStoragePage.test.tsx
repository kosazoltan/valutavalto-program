import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import DocumentStoragePage from './DocumentStoragePage'

const mockList = vi.fn()
const mockDevices = vi.fn()
const mockScannerScan = vi.fn()
const mockScannerUpload = vi.fn()
const mockUploadScannedDocument = vi.fn()
const mockGetCustomerDocuments = vi.fn()
const mockGetTransactionDocuments = vi.fn()
const mockDeleteScannedDocument = vi.fn()

vi.mock('../../services/api/index', () => ({
  documentStorageApi: {
    list: (...args: unknown[]) => mockList(...args),
    upload: vi.fn(),
    download: vi.fn(),
    delete: vi.fn(),
  },
  documentScannerApi: {
    devices: (...args: unknown[]) => mockDevices(...args),
    scan: (...args: unknown[]) => mockScannerScan(...args),
    upload: (...args: unknown[]) => mockScannerUpload(...args),
    uploadScannedDocument: (...args: unknown[]) => mockUploadScannedDocument(...args),
    getCustomerDocuments: (...args: unknown[]) => mockGetCustomerDocuments(...args),
    getTransactionDocuments: (...args: unknown[]) => mockGetTransactionDocuments(...args),
    deleteScannedDocument: (...args: unknown[]) => mockDeleteScannedDocument(...args),
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: vi.fn(),
    error: vi.fn(),
    warning: vi.fn(),
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: vi.fn(),
  },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

describe('DocumentStoragePage backend contract', () => {
  beforeEach(() => {
    mockList.mockReset()
    mockDevices.mockReset()
    mockScannerScan.mockReset()
    mockScannerUpload.mockReset()
    mockUploadScannedDocument.mockReset()
    mockGetCustomerDocuments.mockReset()
    mockGetTransactionDocuments.mockReset()
    mockDeleteScannedDocument.mockReset()
    mockList.mockResolvedValue([
      {
        id: 'doc-1',
        fileName: 'ugyfel-okmany.pdf',
        fileType: 'pdf',
        fileSize: 2048,
        entityType: 'ID_CARD',
        entityId: 'customer-1',
        uploadedAt: '2026-06-18T08:00:00Z',
        uploadedByName: 'Teszt Admin',
      },
    ])
    mockDevices.mockResolvedValue({
      devices: [],
      mode: 'UPLOAD_BRIDGE',
      message: 'Hardver szkenner lista kliens oldalon érhető el.',
    })
    mockScannerScan.mockResolvedValue({ id: 'scan-1' })
    mockScannerUpload.mockResolvedValue({ id: 'scan-2' })
    mockUploadScannedDocument.mockResolvedValue({ id: 'scanned-2' })
    mockDeleteScannedDocument.mockResolvedValue(undefined)
    mockGetCustomerDocuments.mockResolvedValue([
      {
        id: 'scanned-1',
        documentType: 'ID_CARD',
        fileName: 'szemelyi.pdf',
        mimeType: 'application/pdf',
        fileSizeBytes: 4096,
        scannedAt: '2026-06-18T10:00:00',
        notes: 'Teszt okmány',
      },
    ])
    mockGetTransactionDocuments.mockResolvedValue([])
  })

  it('betölti a dokumentumokat és a /document-scanner/devices státuszt', async () => {
    render(<DocumentStoragePage />)

    await waitFor(() => {
      expect(mockList).toHaveBeenCalledTimes(1)
      expect(mockDevices).toHaveBeenCalledTimes(1)
    })

    expect(screen.getAllByText('ugyfel-okmany.pdf').length).toBeGreaterThan(0)
    expect(screen.getByText('UPLOAD_BRIDGE', { exact: false })).toBeInTheDocument()
    expect(screen.getByText('Hardver szkenner lista kliens oldalon érhető el.')).toBeInTheDocument()
  })

  it('a scanner panel a scan és upload kompatibilitási végpontokat használja', async () => {
    const user = userEvent.setup()
    render(<DocumentStoragePage />)

    await waitFor(() => expect(mockDevices).toHaveBeenCalledTimes(1))
    const scanFile = new File(['scan'], 'scan.pdf', { type: 'application/pdf' })
    const uploadFile = new File(['upload'], 'upload.png', { type: 'image/png' })

    await user.upload(screen.getByTestId('scanner-scan-input'), scanFile)
    await waitFor(() => {
      expect(mockScannerScan).toHaveBeenCalledWith(scanFile, { documentType: 'OTHER' })
    })

    await user.upload(screen.getByTestId('scanner-upload-input'), uploadFile)
    await waitFor(() => {
      expect(mockScannerUpload).toHaveBeenCalledWith(uploadFile, { documentType: 'OTHER' })
    })
  })

  it('a scanned-documents panel customer lista, feltöltés és törlés végpontokat használ', async () => {
    const user = userEvent.setup()
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    render(<DocumentStoragePage />)

    await user.type(screen.getByLabelText('Azonosító'), '12')
    await user.click(screen.getByRole('button', { name: /Lista/i }))

    await waitFor(() => {
      expect(mockGetCustomerDocuments).toHaveBeenCalledWith(12)
    })
    expect(await screen.findByText('szemelyi.pdf')).toBeInTheDocument()
    expect(screen.getByText('Teszt okmány')).toBeInTheDocument()

    const file = new File(['scan'], 'uj.pdf', { type: 'application/pdf' })
    await user.upload(screen.getByTestId('scanned-documents-upload-input'), file)

    await waitFor(() => {
      expect(mockUploadScannedDocument).toHaveBeenCalledWith(file, {
        documentType: 'OTHER',
        notes: undefined,
        customerId: 12,
      })
    })

    await user.click(
      within(await screen.findByTestId('scanned-documents-panel')).getByRole('button', {
        name: /Törlés/i,
      }),
    )
    await waitFor(() => {
      expect(mockDeleteScannedDocument).toHaveBeenCalledWith('scanned-1')
    })
  })
})
