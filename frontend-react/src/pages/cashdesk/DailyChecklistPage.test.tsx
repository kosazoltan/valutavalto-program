import { render, screen, waitFor } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import DailyChecklistPage from './DailyChecklistPage'

const mockGet = vi.fn()
const mockStatus = vi.fn()

vi.mock('../../services/api/index', () => ({
  api: { get: (...args: unknown[]) => mockGet(...args) },
  dailyChecklistApi: {
    status: (...args: unknown[]) => mockStatus(...args),
    get: vi.fn(),
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (s: unknown) => unknown) =>
    selector({ worker: { branchId: 'id-BR010', branchName: 'Szekszárd Értéktár' } }),
}))

describe('DailyChecklistPage – FK-014 banki partner kiszűrés (FR-2)', () => {
  beforeEach(() => {
    mockGet.mockReset()
    mockStatus.mockReset()
    mockStatus.mockResolvedValue({ completed: false })
  })

  it('a Központi státusz csak valódi irodákat mutat; banki partnerek nem', async () => {
    mockGet.mockResolvedValue({
      data: [
        { id: 'id-BR010', code: 'BR010', name: 'Szekszárd Értéktár', isActive: true },
        { id: 'id-BR100', code: 'BR100', name: 'Kalocsa Belváros', isActive: true },
        { id: 'id-ERB', code: 'ERB', name: 'Egyedi Raiffeisen Bank', isActive: true },
        { id: 'id-MNB', code: 'MNB', name: 'Magyar Nemzeti Bank', isActive: true },
        { id: 'id-FOP1', code: 'FOP1', name: '1-es főpénztár', isActive: true },
      ],
    })

    render(<DailyChecklistPage />)

    // Valódi iroda megjelenik a státusz-gridben
    await waitFor(() => expect(screen.getByText('Szekszárd Értéktár')).toBeInTheDocument())
    expect(screen.getByText('Kalocsa Belváros')).toBeInTheDocument()

    // Banki/speciális partnerek nevei NEM jelennek meg (sem gridben, sem a Fiók-választóban)
    for (const name of ['Egyedi Raiffeisen Bank', 'Magyar Nemzeti Bank', '1-es főpénztár']) {
      expect(screen.queryByText(name)).not.toBeInTheDocument()
    }
    // és a kódjaik sem
    for (const code of ['ERB', 'MNB', 'FOP1']) {
      expect(screen.queryByText(code)).not.toBeInTheDocument()
    }
  })
})
