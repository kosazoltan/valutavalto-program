import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import DaybookPage from './DaybookPage'

// FKH-022 kiegészítés FR-K3 (RED-fázis): a Naplókönyv oldal Partner oszlopa.
// A backend-kontraktus (HufDaybookRowDto.partnerCode) tesztjei:
// backend HufDaybookPartnerCodeFrK3PostgresTest. Ez a teszt a megjelenítést rögzíti:
// numerikus pénztárszám (076) és counterparty betűkód (PRB) egyaránt látszik.

const mocks = vi.hoisted(() => ({
  get: vi.fn(),
  downloadPdf: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  dailyReportApi: {
    get: mocks.get,
    downloadPdf: mocks.downloadPdf,
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: { worker: { branchId: string } }) => unknown) =>
    selector({ worker: { branchId: 'branch-1' } }),
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: { warning: vi.fn(), error: vi.fn(), success: vi.fn(), info: vi.fn() },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

describe('DaybookPage — FKH-022 FR-K3 partner oszlop (RED)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.get.mockResolvedValue({
      branchId: 'branch-1',
      branchName: 'Szeged Értéktár',
      date: '2026-07-01',
      rows: [
        {
          annualSequence: 2,
          receiptNumber: 'FF-000002',
          timestamp: '09:15:00',
          atadasHuf: 250000,
          storno: false,
          partnerCode: '076',
        },
        {
          annualSequence: 3,
          receiptNumber: 'UF-000101',
          timestamp: '10:30:00',
          atvetelHuf: 100000,
          storno: false,
          partnerCode: 'PRB',
        },
      ],
      totalAtadasHuf: 250000,
      totalAtvetelHuf: 100000,
    })
  })

  it('a táblázat Partner oszlopban mutatja a numerikus (076) és a counterparty betűkódos (PRB) partner-azonosítót', async () => {
    render(
      <MemoryRouter>
        <DaybookPage />
      </MemoryRouter>,
    )

    fireEvent.click(screen.getByText('Lekérdezés'))
    await waitFor(() => {
      expect(mocks.get).toHaveBeenCalledWith('branch-1', expect.any(String))
    })
    expect(await screen.findByText('FF-000002')).toBeInTheDocument()

    // RED: a jelenlegi táblázatban nincs Partner oszlop és partner-cella.
    expect(screen.getByRole('columnheader', { name: 'Partner' })).toBeInTheDocument()
    expect(screen.getByText('076')).toBeInTheDocument()
    expect(screen.getByText('PRB')).toBeInTheDocument()
  })
})
