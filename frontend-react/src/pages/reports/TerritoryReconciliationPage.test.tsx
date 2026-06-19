import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import TerritoryReconciliationPage from './TerritoryReconciliationPage'

const mocks = vi.hoisted(() => ({
  listTerritories: vi.fn(),
  getTerritory: vi.fn(),
  createTerritory: vi.fn(),
  getTerritoryProfit: vi.fn(),
  get: vi.fn(),
}))

vi.mock('../../services/api/territoryReconciliation', () => ({
  territoryReconciliationApi: mocks,
}))

describe('TerritoryReconciliationPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.listTerritories.mockResolvedValue([
      {
        id: 20,
        companyId: 'company-1',
        name: 'Szeged terület',
        baseCapital: 1_000_000,
        baseCapitalApprovedAt: '2026-06-01',
        active: true,
      },
    ])
    mocks.getTerritory.mockResolvedValue({
      id: 20,
      companyId: 'company-1',
      name: 'Szeged terület',
      baseCapital: 1_000_000,
      baseCapitalApprovedAt: '2026-06-01',
      active: true,
    })
    mocks.getTerritoryProfit.mockResolvedValue({
      totalProfit: 123_000,
      transactionCount: 12,
      sellCount: 7,
      buyCount: 5,
      profitByCurrency: { EUR: 80_000, USD: 43_000 },
    })
    mocks.get.mockResolvedValue({
      territoryId: 20,
      fromDate: '2026-06-01',
      toDate: '2026-06-30',
      territoryRealizedMargin: 100_000,
      territoryRevaluation: 23_000,
      territoryTotalProfit: 123_000,
      reconciliationOk: true,
      cashiers: [
        {
          branchId: 'branch-1',
          branchCode: 'SZEGED',
          branchName: 'Szeged Értéktár',
          realizedMargin: 100_000,
          allocatedRevaluation: 23_000,
          totalProfit: 123_000,
        },
      ],
      currencyRevaluations: [
        {
          currencyCode: 'EUR',
          vaultHeldQty: 500,
          weightedAvgCost: 390,
          mnbRate: 394,
          revaluation: 2_000,
        },
      ],
    })
    mocks.createTerritory.mockResolvedValue({
      id: 21,
      companyId: 'company-1',
      name: 'Új terület',
      baseCapital: 250_000,
      baseCapitalApprovedAt: '2026-06-18',
      active: true,
    })
  })

  it('betölti a területeket, részletet és profit összesítőt a backend szerződésből', async () => {
    render(<TerritoryReconciliationPage />)

    await waitFor(() => {
      expect(mocks.listTerritories).toHaveBeenCalled()
      expect(mocks.getTerritory).toHaveBeenCalledWith(20)
      expect(mocks.getTerritoryProfit).toHaveBeenCalledWith(20, expect.stringMatching(/^\d{4}-\d{2}-01$/), expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/))
    })

    expect(await screen.findByText('Szeged terület (#20)')).toBeInTheDocument()
    expect(screen.getByText('Területi WAC profit összesítő')).toBeInTheDocument()
    expect(screen.getByText('123 000 Ft')).toBeInTheDocument()
    expect(screen.getByText('EUR')).toBeInTheDocument()
  })

  it('lekérdezéskor a reconciliation riportot és a terület profit endpointot is hívja', async () => {
    const user = userEvent.setup()
    render(<TerritoryReconciliationPage />)

    await screen.findByText('Szeged terület (#20)')
    await user.clear(screen.getByLabelText('Hónap'))
    await user.type(screen.getByLabelText('Hónap'), '2026-06')
    await user.click(screen.getByRole('button', { name: 'Lekérdez' }))

    await waitFor(() => {
      expect(mocks.get).toHaveBeenCalledWith(20, '2026-06')
      expect(mocks.getTerritoryProfit).toHaveBeenCalledWith(20, '2026-06-01', '2026-06-30')
    })

    expect(await screen.findByText('Reconciliation OK: Σ pénztár összhaszon = terület összhaszon')).toBeInTheDocument()
    expect(screen.getAllByText('SZEGED - Szeged Értéktár').length).toBeGreaterThan(0)
  })

  it('új terület létrehozását a POST /territories szerződésre köti', async () => {
    const user = userEvent.setup()
    render(<TerritoryReconciliationPage />)

    await screen.findByText('Szeged terület (#20)')
    await user.type(screen.getByLabelText('Név'), 'Új terület')
    await user.type(screen.getByLabelText('Alaptőke'), '250000')
    await user.type(screen.getByLabelText('Jóváhagyás dátuma'), '2026-06-18')
    await user.click(screen.getByRole('button', { name: 'Terület létrehozása' }))

    await waitFor(() => {
      expect(mocks.createTerritory).toHaveBeenCalledWith({
        name: 'Új terület',
        baseCapital: 250000,
        baseCapitalApprovedAt: '2026-06-18',
      })
      expect(mocks.getTerritory).toHaveBeenCalledWith(21)
    })
  })
})
