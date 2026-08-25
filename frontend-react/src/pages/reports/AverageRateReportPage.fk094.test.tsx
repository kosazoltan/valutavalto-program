/**
 * FK-094 — Átlag árfolyam riport: látható export-tájékoztató + értéktár-mentes Iroda lista.
 * A védett `AverageRateReportPage.test.tsx` byte-azonos marad; az új esetek külön fájlban élnek.
 */
import { render, screen, waitFor } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import AverageRateReportPage from './AverageRateReportPage'

const mockGetPivot = vi.fn()
const mockExportExcel = vi.fn()
const mockListActive = vi.fn()

vi.mock('../../services/api/index', () => ({
  averageRateApi: {
    getPivot: (...args: unknown[]) => mockGetPivot(...args),
    exportExcel: (...args: unknown[]) => mockExportExcel(...args),
  },
  branchApi: {
    listActive: (...args: unknown[]) => mockListActive(...args),
  },
}))

function renderPage() {
  return render(<AverageRateReportPage />)
}

describe('AverageRateReportPage — FK-094', () => {
  beforeEach(() => {
    mockGetPivot.mockReset()
    mockExportExcel.mockReset()
    mockListActive.mockReset()
    mockListActive.mockResolvedValue([])
  })

  it('FR-1/2: az export-struktúra tájékoztató hover nélkül is látszik', async () => {
    renderPage()

    // A tájékoztató a lekérdezés ELŐTT, bármely Iroda-választásnál megjelenik.
    const notice = await screen.findByTestId('average-rate-export-notice')
    await waitFor(() => expect(notice).toBeVisible())
    expect(notice).toHaveTextContent(/teljes/i)
    expect(mockGetPivot).not.toHaveBeenCalled()
  })

  it('FR-3/4: az Iroda lista kihagyja az értéktári fiókokat', async () => {
    mockListActive.mockResolvedValue([
      { id: 'b1', code: '001', name: 'Fő utca', isVault: false },
      { id: 'b2', code: '002', name: 'Központi értéktár', isVault: true },
      { id: 'b3', code: '003', name: 'Régi rekord' },
    ])

    renderPage()

    await waitFor(() =>
      expect(screen.getByRole('option', { name: /001/ })).toBeInTheDocument(),
    )
    expect(screen.queryByRole('option', { name: /Központi értéktár/ })).not.toBeInTheDocument()
    // Hiányzó isVault (= nem értéktár) → listázva marad.
    expect(screen.getByRole('option', { name: /003/ })).toBeInTheDocument()
    expect(screen.getByRole('option', { name: 'Összes iroda' })).toBeInTheDocument()
  })

  it('FK-094: az export gomb tooltipje megmarad', () => {
    renderPage()

    expect(screen.getByText('Excel export').closest('button')).toHaveAttribute(
      'title',
      expect.stringContaining('8 terület'),
    )
  })
})
