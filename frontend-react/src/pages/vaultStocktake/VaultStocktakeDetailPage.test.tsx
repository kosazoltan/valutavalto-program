import { render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import VaultStocktakeDetailPage from './VaultStocktakeDetailPage'

const mocks = vi.hoisted(() => ({
  get: vi.fn(),
  summary: vi.fn(),
  countItem: vi.fn(),
  review: vi.fn(),
  close: vi.fn(),
  cancel: vi.fn(),
}))

vi.mock('../../services/api/vaultStocktake', () => ({
  vaultStocktakeApi: {
    get: mocks.get,
    summary: mocks.summary,
    countItem: mocks.countItem,
    review: mocks.review,
    close: mocks.close,
    cancel: mocks.cancel,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/vault-stocktake/session-1']}>
      <Routes>
        <Route path="/vault-stocktake/:id" element={<VaultStocktakeDetailPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('VaultStocktakeDetailPage backend kapcsolatok', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.get.mockResolvedValue({
      id: 'session-1',
      companyId: 'company-1',
      branchId: 'branch-1',
      territoryId: null,
      sessionName: 'Napi értéktár leltár',
      status: 'OPEN',
      startedAt: '2026-06-18T08:00:00',
      completedAt: null,
      startedBy: 'ADMIN',
      reviewedBy: null,
      approvedBy: null,
      note: null,
      discrepancyTotalHuf: 0,
      items: [
        {
          id: 'item-1',
          sessionId: 'session-1',
          currencyId: 1,
          currencyCode: 'EUR',
          faceValue: 100,
          expectedQuantity: 2,
          actualQuantity: 1,
          discrepancy: -1,
          discrepancyValue: -40000,
          countedBy: 'ADMIN',
          countedAt: '2026-06-18T08:30:00',
          note: null,
        },
      ],
    })
    mocks.summary.mockResolvedValue({
      sessionId: 'session-1',
      sessionName: 'Napi értéktár leltár',
      status: 'OPEN',
      totalItems: 12,
      countedItems: 10,
      discrepancyItems: 2,
      totalDiscrepancyHuf: -40000,
      discrepancies: [],
    })
  })

  it('betölti és megjeleníti a backend stocktake summary endpoint eredményét', async () => {
    renderPage()

    await screen.findByText('Napi értéktár leltár')

    await waitFor(() => {
      expect(mocks.get).toHaveBeenCalledWith('session-1')
      expect(mocks.summary).toHaveBeenCalledWith('session-1')
    })
    const backendSummary = screen.getByLabelText('Backend összesítő')
    expect(backendSummary).toBeInTheDocument()
    expect(within(backendSummary).getByText('12')).toBeInTheDocument()
    expect(within(backendSummary).getByText('-40 000')).toBeInTheDocument()
  })
})
