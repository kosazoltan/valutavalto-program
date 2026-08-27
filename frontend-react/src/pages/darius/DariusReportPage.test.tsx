import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import DariusReportPage from './DariusReportPage'

const mocks = vi.hoisted(() => ({
  getRange: vi.fn(),
  getMonthly: vi.fn(),
  getMissingDates: vi.fn(),
  generate: vi.fn(),
  approve: vi.fn(),
  submit: vi.fn(),
  acknowledge: vi.fn(),
  retryFailed: vi.fn(),
  getById: vi.fn(),
  getByDate: vi.fn(),
  downloadImportFile: vi.fn(),
  downloadBlob: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  dariusApi: mocks,
}))

vi.mock('../../utils/downloadBlob', () => ({
  downloadBlob: mocks.downloadBlob,
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

const dailyReport = {
  id: 'darius-1',
  reportDate: '2026-06-19',
  status: 'GENERATED',
  companyId: 'company-1',
  totalBuyHuf: 100000,
  totalSellHuf: 50000,
  totalHandlingFeeHuf: 1200,
  transactionCount: 3,
  branchCount: 1,
  payloadHash: 'abcdef1234567890abcdef',
  retryCount: 0,
  maxRetries: 3,
  lines: [
    {
      id: 'line-1',
      branchId: 'branch-1',
      branchCode: 'BUD01',
      currencyCode: 'EUR',
      buyCount: 2,
      buyCurrencyAmount: 100,
      buyHufAmount: 40000,
      sellCount: 1,
      sellCurrencyAmount: 50,
      sellHufAmount: 20000,
      avgBuyRate: 400,
      avgSellRate: 410,
      handlingFeeHuf: 1200,
    },
  ],
}

describe('DariusReportPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getRange.mockResolvedValue({ data: [] })
    mocks.getMonthly.mockResolvedValue({ data: null })
    mocks.getMissingDates.mockResolvedValue({ data: [] })
    mocks.generate.mockResolvedValue({ data: dailyReport })
    mocks.approve.mockResolvedValue({ data: dailyReport })
    mocks.submit.mockResolvedValue({ data: dailyReport })
    mocks.acknowledge.mockResolvedValue({
      data: { ...dailyReport, status: 'ACKNOWLEDGED', ackReference: 'ACK-2026-0001' },
    })
    mocks.retryFailed.mockResolvedValue({ data: [] })
    mocks.getById.mockResolvedValue({ data: dailyReport })
    mocks.getByDate.mockResolvedValue({ data: dailyReport })
    mocks.downloadImportFile.mockResolvedValue({
      data: new Blob(['import-adat']),
      headers: {
        'content-disposition': 'attachment; filename="raiffeisen_import_BEST_2026-07-01.imp"',
      },
    })
  })

  it('megjeleníti a Fixing igények fület', async () => {
    render(<DariusReportPage />)

    expect(await screen.findByRole('button', { name: 'Fixing igények' })).toBeInTheDocument()
  })

  it('napi lekérdezéskor a backend by-date reprezentációját jeleníti meg', async () => {
    const user = userEvent.setup()
    render(<DariusReportPage />)

    const dateInputs = await screen.findAllByDisplayValue(/\d{4}-\d{2}-\d{2}/)
    await user.clear(dateInputs[2]!)
    await user.type(dateInputs[2]!, '2026-06-19')
    await user.click(screen.getByRole('button', { name: /Napi lekérdezés/i }))

    await waitFor(() => {
      expect(mocks.getByDate).toHaveBeenCalledWith('2026-06-19')
      expect(screen.getByText(/darius.reszletek/)).toBeInTheDocument()
      expect(screen.getByText('EUR')).toBeInTheDocument()
      expect(screen.getByText('BUD01')).toBeInTheDocument()
      expect(screen.getByText(/abcdef1234567890/)).toBeInTheDocument()
    })
  })

  it('listaelem kiválasztásakor a backend detail endpointból tölti be a sorokat', async () => {
    const user = userEvent.setup()
    mocks.getRange.mockResolvedValue({
      data: [
        {
          ...dailyReport,
          payloadHash: undefined,
          lines: undefined,
        },
      ],
    })
    render(<DariusReportPage />)

    await user.click(await screen.findByTestId('darius-report-darius-1'))

    await waitFor(() => {
      expect(mocks.getById).toHaveBeenCalledWith('darius-1')
      expect(screen.getByText('EUR')).toBeInTheDocument()
      expect(screen.getByText('BUD01')).toBeInTheDocument()
      expect(screen.getByText(/abcdef1234567890/)).toBeInTheDocument()
    })
  })

  it('SUBMITTED jelentésnél meghívja a Darius acknowledge backend szerződést', async () => {
    const user = userEvent.setup()
    const submittedReport = { ...dailyReport, status: 'SUBMITTED' }
    mocks.getByDate.mockResolvedValue({ data: submittedReport })

    render(<DariusReportPage />)

    const dateInputs = await screen.findAllByDisplayValue(/\d{4}-\d{2}-\d{2}/)
    await user.clear(dateInputs[2]!)
    await user.type(dateInputs[2]!, '2026-06-19')
    await user.click(screen.getByRole('button', { name: /Napi lekérdezés/i }))

    await user.type(await screen.findByLabelText('Visszaigazolási referencia'), 'ACK-2026-0001')
    await user.click(screen.getByRole('button', { name: 'Visszaigazolás rögzítése' }))

    await waitFor(() => {
      expect(mocks.acknowledge).toHaveBeenCalledWith('darius-1', 'ACK-2026-0001')
    })
  })

  it('a kiválasztott dátummal letölti a Raiffeisen importfájlt', async () => {
    const user = userEvent.setup()
    render(<DariusReportPage />)

    expect(screen.getByRole('button', { name: 'Import fájl letöltése (.imp)' })).toBeInTheDocument()

    const dateInputs = await screen.findAllByDisplayValue(/\d{4}-\d{2}-\d{2}/)
    await user.clear(dateInputs[2]!)
    await user.type(dateInputs[2]!, '2026-07-01')
    await user.click(screen.getByRole('button', { name: 'Import fájl letöltése (.imp)' }))

    await waitFor(() => {
      expect(mocks.downloadImportFile).toHaveBeenCalledWith('2026-07-01', 0)
      expect(mocks.downloadBlob).toHaveBeenCalledWith(
        expect.any(Blob),
        'raiffeisen_import_BEST_2026-07-01.imp',
      )
    })
  })

  it('a megadott értéknappal kéri le az importfájlt', async () => {
    const user = userEvent.setup()
    render(<DariusReportPage />)

    const erteknapInput = screen.getByRole('spinbutton', { name: 'Értéknap (T+N)' })
    expect(erteknapInput).toHaveAttribute('min', '-200')
    expect(erteknapInput).toHaveAttribute('max', '200')
    await user.clear(erteknapInput)
    await user.type(erteknapInput, '1')
    const dateInputs = await screen.findAllByDisplayValue(/\d{4}-\d{2}-\d{2}/)
    await user.clear(dateInputs[2]!)
    await user.type(dateInputs[2]!, '2026-07-01')
    await user.click(screen.getByRole('button', { name: 'Import fájl letöltése (.imp)' }))

    await waitFor(() => {
      expect(mocks.downloadImportFile).toHaveBeenCalledWith('2026-07-01', 1)
    })
  })

  it('Content-Disposition nélkül biztonságos alapértelmezett fájlnevet használ', async () => {
    const user = userEvent.setup()
    mocks.downloadImportFile.mockResolvedValue({
      data: new Blob(['import-adat']),
      headers: {},
    })
    render(<DariusReportPage />)

    const dateInputs = await screen.findAllByDisplayValue(/\d{4}-\d{2}-\d{2}/)
    await user.clear(dateInputs[2]!)
    await user.type(dateInputs[2]!, '2026-07-01')
    await user.click(screen.getByRole('button', { name: 'Import fájl letöltése (.imp)' }))

    await waitFor(() => {
      expect(mocks.downloadBlob).toHaveBeenCalledWith(
        expect.any(Blob),
        'raiffeisen_import_2026-07-01.imp',
      )
    })
  })

  it('megjeleníti a blob hibaválasz szerverüzenetét', async () => {
    const user = userEvent.setup()
    mocks.downloadImportFile.mockRejectedValue({
      response: {
        data: {
          text: async () => JSON.stringify({ message: 'Hiányzik a PV azonosító.' }),
        },
      },
    })
    render(<DariusReportPage />)

    await user.click(screen.getByRole('button', { name: 'Import fájl letöltése (.imp)' }))

    expect(await screen.findByText('Hiányzik a PV azonosító.')).toBeInTheDocument()
    expect(mocks.downloadBlob).not.toHaveBeenCalled()
  })
})
