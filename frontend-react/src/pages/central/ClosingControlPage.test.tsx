import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ClosingControlPage from './ClosingControlPage'

const mockList = vi.fn()
const mockGetBranch = vi.fn()

vi.mock('../../services/api', () => ({
  closingControlApi: {
    list: (...args: unknown[]) => mockList(...args),
    getBranch: (...args: unknown[]) => mockGetBranch(...args),
    sendAlert: vi.fn(),
  },
}))

function row(branchCode: string, branchName: string) {
  return {
    branchId: `id-${branchCode}`,
    branchCode,
    branchName,
    controlDate: '2026-06-01',
    dailyClosingDone: false,
    eveningClosingDone: false,
    navClosingDone: false,
    alertLevel: 'NONE',
  }
}

describe('ClosingControlPage – FK-014 banki partner kiszűrés (FR-1)', () => {
  beforeEach(() => {
    mockList.mockReset()
    mockGetBranch.mockReset()
  })

  it('csak a valódi irodák (pénztár/értéktár) jelennek meg; a banki partnerek nem', async () => {
    mockList.mockResolvedValue([
      row('BR010', 'Szekszárd Értéktár'),
      row('BR100', 'Kalocsa Belváros'),
      row('ERB', 'Egyedi Raiffeisen Bank'),
      row('MNB', 'Magyar Nemzeti Bank'),
      row('TH', 'Többlet/Hiány pénztár'),
      row('FOP1', '1-es főpénztár'),
      row('UPT', 'Úton lévő pénztár'),
    ])

    render(
      <MemoryRouter>
        <ClosingControlPage />
      </MemoryRouter>,
    )

    // Valódi irodák megjelennek
    await waitFor(() => expect(screen.getByText('BR010')).toBeInTheDocument())
    expect(screen.getByText('BR100')).toBeInTheDocument()

    // Banki/speciális partnerek NEM jelennek meg
    for (const code of ['ERB', 'MNB', 'TH', 'FOP1', 'UPT']) {
      expect(screen.queryByText(code)).not.toBeInTheDocument()
    }
  })

  it('részletezéskor a backend branch detail reprezentációját jeleníti meg', async () => {
    mockList.mockResolvedValue([row('BR010', 'Lista Szekszárd')])
    mockGetBranch.mockResolvedValue({
      ...row('BR010', 'Backend Szekszárd'),
      branchCity: 'Szekszárd',
      dailyClosingDone: true,
      eveningClosingDone: false,
      navClosingDone: true,
      lastTransactionAt: '2026-06-01T18:40:00',
      notes: 'Backend detail megjegyzés',
    })

    render(
      <MemoryRouter>
        <ClosingControlPage />
      </MemoryRouter>,
    )

    await screen.findByText('BR010')
    fireEvent.click(screen.getByRole('button', { name: /Részletek lekérése/i }))

    await waitFor(() => {
      expect(mockGetBranch).toHaveBeenCalledWith(
        'id-BR010',
        expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/),
      )
      expect(screen.getByText('Backend Szekszárd, Szekszárd')).toBeInTheDocument()
      expect(screen.getByText('Napi zárás: rendben')).toBeInTheDocument()
      expect(screen.getByText('Esti zárás: hiányzik')).toBeInTheDocument()
      expect(screen.getByText('NAV zárás: rendben')).toBeInTheDocument()
      expect(screen.getByText(/Backend detail megjegyzés/)).toBeInTheDocument()
    })
  })
})
