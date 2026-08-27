import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import StockSnapshotPage from './StockSnapshotPage'

/**
 * FK-041: a "Sürgősségi banki kivét" gomb eltávolítva a Készlet-snapshot oldalról.
 * A fejléc sáv (Excel letöltés + frissítés) a loading/data guard ELŐTT renderel, ezért a
 * gomb jelenléte/hiánya akkor is ellenőrizhető, ha a snapshot adat üres.
 */

const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))

vi.mock('../../services/api/index', () => ({ api: { get: mocks.apiGet } }))
vi.mock('../../utils/logger', () => ({ logger: mocks.logger }))
vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

const SNAPSHOT = {
  companyName: 'Exclusive Best Change Zrt.',
  snapshotTime: '2026-06-24T14:07:52',
  regions: [],
}

function renderPage() {
  return render(
    <MemoryRouter>
      <StockSnapshotPage />
    </MemoryRouter>,
  )
}

describe('StockSnapshotPage – FK-041 sürgősségi banki kivét gomb eltávolítás', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.apiGet.mockResolvedValue({ data: SNAPSHOT })
  })

  it('NEM rendereli a "Sürgősségi banki kivét" gombot (FR-1)', async () => {
    renderPage()
    await waitFor(() => expect(mocks.apiGet).toHaveBeenCalledWith('/stock-snapshot'))

    // A gomb felirat-kulcsa nem jelenik meg
    expect(screen.queryByText('bankorders.surgossegiBankiKivet')).toBeNull()
    // Nincs EMERGENCY banki rendelésre mutató link
    expect(document.querySelector('a[href*="urgency=EMERGENCY"]')).toBeNull()
    expect(document.querySelector('a[href*="/bank-orders"]')).toBeNull()
  })

  it('megtartja az "Excel letöltés" gombot (FR-2 regresszió)', async () => {
    renderPage()
    await waitFor(() => expect(mocks.apiGet).toHaveBeenCalled())

    expect(screen.getByText('common.exportExcel')).toBeInTheDocument()
  })
})
