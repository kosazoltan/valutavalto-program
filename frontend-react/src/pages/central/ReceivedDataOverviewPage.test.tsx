import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ReceivedDataOverviewPage from './ReceivedDataOverviewPage'
import { localIsoDate } from '../../utils/dateFormat'
import hu from '../../i18n/hu.json'

const mockRun = vi.fn()

vi.mock('../../services/api', () => ({
  transferReconciliationApi: {
    run: (...args: unknown[]) => mockRun(...args),
  },
}))

const result = {
  startDate: '2026-05-22',
  endDate: '2026-05-22',
  totalRows: 3,
  matchedRows: 1,
  discrepancyRows: 1,
  notifiedBranches: 1,
  generatedAt: '2026-05-23T10:00:00',
  rows: [
    {
      transferId: 1,
      transferNumber: 'AT0001',
      date: '2026-05-22',
      fromBranchCode: 'BR009',
      fromBranchName: 'Dombóvár',
      toBranchCode: 'BR020',
      toBranchName: 'Szeged Értéktár',
      currencyCode: 'EUR',
      sentAmount: 5000,
      receivedAmount: 5000,
      status: 'EGYEZIK',
      discrepancyNote: null,
    },
    {
      transferId: 2,
      transferNumber: 'AT0002',
      date: '2026-05-22',
      fromBranchCode: 'BR010',
      fromBranchName: 'Szekszárd',
      toBranchCode: 'BR020',
      toBranchName: 'Szeged Értéktár',
      currencyCode: 'USD',
      sentAmount: 3000,
      receivedAmount: 2900,
      status: 'ELTERES',
      discrepancyNote: 'Eltérő összeg: küldött 3000, fogadott 2900',
    },
    {
      transferId: 3,
      transferNumber: 'AT0003',
      date: '2026-05-22',
      fromBranchCode: 'BR011',
      fromBranchName: 'Pécs',
      toBranchCode: 'BR020',
      toBranchName: 'Szeged Értéktár',
      currencyCode: 'HUF',
      sentAmount: 10000,
      receivedAmount: null,
      status: 'FOLYAMATBAN',
      discrepancyNote: 'Fogadó megerősítésére vár',
    },
  ],
}

describe('ReceivedDataOverviewPage (FK-003 / FK-090 / FK-089)', () => {
  beforeEach(() => {
    mockRun.mockReset()
  })

  it('alapból nem fut automatikusan — az intervallum-választó prompt jelenik meg', () => {
    render(<ReceivedDataOverviewPage />)
    expect(screen.getByText(/Válasszon intervallumot/i)).toBeInTheDocument()
    expect(mockRun).not.toHaveBeenCalled()
  })

  it('az Ellenőrzés gomb lefuttatja az egyeztetést és a státusz-feliratok hu.json-ból jönnek', async () => {
    mockRun.mockResolvedValue(result)
    render(<ReceivedDataOverviewPage />)

    await userEvent.click(screen.getByRole('button', { name: /Ellenőrzés/i }))

    await waitFor(() => expect(mockRun).toHaveBeenCalledTimes(1))
    expect(screen.getByTestId('recon-status-match')).toHaveTextContent(
      hu.centralReceivedData.statusMatch,
    )
    expect(screen.getByTestId('recon-status-mismatch')).toHaveTextContent(
      hu.centralReceivedData.statusMismatch,
    )
    expect(screen.getByTestId('recon-status-pending')).toHaveTextContent(
      hu.centralReceivedData.statusInProgress,
    )
    expect(screen.getByText(/Eltérő összeg: küldött 3000, fogadott 2900/)).toBeInTheDocument()
    expect(screen.queryByText('Beérkezett jelentés')).not.toBeInTheDocument()
    expect(screen.queryByTestId('central-received-data-status')).not.toBeInTheDocument()
  })

  it('az Eltérés szűrő elrejti az egyező ÉS a folyamatban lévő sorokat', async () => {
    mockRun.mockResolvedValue(result)
    render(<ReceivedDataOverviewPage />)
    await userEvent.click(screen.getByRole('button', { name: /Ellenőrzés/i }))
    await waitFor(() => expect(screen.getByTestId('recon-status-match')).toBeInTheDocument())

    await userEvent.selectOptions(screen.getByRole('combobox'), 'mismatch')

    expect(screen.queryByTestId('recon-status-match')).not.toBeInTheDocument()
    expect(screen.queryByTestId('recon-status-pending')).not.toBeInTheDocument()
    expect(screen.getByTestId('recon-status-mismatch')).toBeInTheDocument()
  })

  it('FK-090 FR-6: a Folyamatban szűrő csak a semleges sorokat listázza', async () => {
    mockRun.mockResolvedValue(result)
    render(<ReceivedDataOverviewPage />)
    await userEvent.click(screen.getByRole('button', { name: /Ellenőrzés/i }))
    await waitFor(() => expect(screen.getByTestId('recon-status-pending')).toBeInTheDocument())

    await userEvent.selectOptions(screen.getByRole('combobox'), 'pending')

    expect(screen.getByTestId('recon-status-pending')).toBeInTheDocument()
    expect(screen.queryByTestId('recon-status-match')).not.toBeInTheDocument()
    expect(screen.queryByTestId('recon-status-mismatch')).not.toBeInTheDocument()
  })

  it('FK-090 FR-5: a folyamatban lévő sor NEM piros hátterű', async () => {
    mockRun.mockResolvedValue(result)
    render(<ReceivedDataOverviewPage />)
    await userEvent.click(screen.getByRole('button', { name: /Ellenőrzés/i }))

    const pendingRow = await screen.findByTestId('recon-row-AT0003')
    expect(pendingRow.className).not.toContain('bg-red-50')
    const mismatchRow = screen.getByTestId('recon-row-AT0002')
    expect(mismatchRow.className).toContain('bg-red-50')
  })

  it('FK-089: az Ellenőrzés NEM hívja a received-data/status végpontot', async () => {
    mockRun.mockResolvedValue(result)
    render(<ReceivedDataOverviewPage />)
    await userEvent.click(screen.getByRole('button', { name: /Ellenőrzés/i }))
    await waitFor(() => expect(mockRun).toHaveBeenCalledTimes(1))
    expect(screen.queryByText('Hiányzó jelentés')).not.toBeInTheDocument()
    expect(screen.queryByText('Kritikus zárás')).not.toBeInTheDocument()
  })

  it('egyeztetési hiba esetén a felső sáv inline hibát mutat', async () => {
    mockRun.mockRejectedValue(new Error('recon 500'))
    render(<ReceivedDataOverviewPage />)

    await userEvent.click(screen.getByRole('button', { name: /Ellenőrzés/i }))

    await waitFor(() => expect(screen.getByTestId('received-data-recon-error')).toBeInTheDocument())
    expect(
      screen.getByText('A pénztárközi egyeztetés adatainak betöltése sikertelen.'),
    ).toBeInTheDocument()
    expect(screen.queryByTestId('received-data-global-error')).not.toBeInTheDocument()
  })

  // A-6 (pótlás d5753273): üres endDate mellett nincs undefined-es felirat.
  // FK-089: a status-caption a törölt alsó panelhez tartozott — hiányzik (null),
  // ezért undefined sem jelenhet meg.
  it('A-6: üres endDate mellett nincs undefined-es felirat', async () => {
    mockRun.mockResolvedValue(result)
    render(<ReceivedDataOverviewPage />)

    const d = new Date()
    d.setDate(d.getDate() - 1)
    const yesterdayIso = localIsoDate(d)
    const inputs = screen.getAllByDisplayValue(yesterdayIso)
    fireEvent.change(inputs[1]!, { target: { value: '' } })

    await userEvent.click(screen.getByRole('button', { name: /Ellenőrzés/i }))

    await waitFor(() => expect(mockRun).toHaveBeenCalled())
    const caption = screen.queryByTestId('received-data-status-caption')
    expect(caption === null || !caption.textContent?.includes('undefined')).toBe(true)
  })
})
