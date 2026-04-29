import { render, screen, waitFor } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import { CashierHeader } from './CashierHeader'

const mocks = vi.hoisted(() => ({
  useCompanyTheme: vi.fn(),
  useAuthStore: vi.fn(),
}))

vi.mock('../../contexts/CompanyThemeContext', () => ({
  useCompanyTheme: mocks.useCompanyTheme,
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: mocks.useAuthStore,
}))

const mockTheme = {
  primary: '#2563eb',
  secondary: '#64748b',
  success: '#10b981',
  danger: '#ef4444',
  warning: '#f59e0b',
  info: '#3b82f6',
  name: 'Test Company',
}

const mockWorker = {
  id: 1,
  workerCode: 'KJ001',
  firstName: 'Kiss',
  lastName: 'János',
  fullName: 'Kiss János',
  role: 'CASHIER',
  branchId: 'b1',
  branchCode: '202',
  branchName: 'Eger Fiók',
  companyId: 'c1',
  companyCode: 'EBC',
  companyName: 'Test Co',
}

describe('CashierHeader', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.useCompanyTheme.mockReturnValue({ theme: mockTheme })
    // v2.3.33 (B4): a komponens elsodlegesen az useAuthStore-bol toltodik.
    // Selector pattern: useAuthStore((s) => s.worker) — a mock argumentumkent kapja a selectort.
    mocks.useAuthStore.mockImplementation((selector?: (s: { worker: typeof mockWorker | null }) => unknown) => {
      const state = { worker: mockWorker }
      return selector ? selector(state) : state
    })
  })

  it('komponens renderelése (banner role)', () => {
    render(<CashierHeader />)
    expect(screen.getByRole('banner')).toBeInTheDocument()
  })

  it('useAuthStore worker-bol toltodik a branchCode', () => {
    render(<CashierHeader />)
    // "202" matches a header subtitle "Pénztár: 202 | Eger Fiók" — a date is YYYY.MM.DD formatumban,
    // szoval ev=2026 NEM full match. A pontosabb ellenorzes a header.textContent.
    const header = screen.getByRole('banner')
    expect(header.textContent).toMatch(/Pénztár:\s*202/)
  })

  it('useAuthStore worker-bol toltodik a branchName', () => {
    render(<CashierHeader />)
    expect(screen.getByText(/Eger Fiók/)).toBeInTheDocument()
  })

  it('useAuthStore worker-bol toltodik a fullName', () => {
    render(<CashierHeader />)
    expect(screen.getByText(/Kiss János/)).toBeInTheDocument()
  })

  it('useAuthStore worker-bol toltodik a workerCode (ID)', () => {
    render(<CashierHeader />)
    expect(screen.getByText(/KJ001/)).toBeInTheDocument()
  })

  it('worker null eseten "—" placeholder jelenik meg (NEM hardcoded "Admin")', () => {
    mocks.useAuthStore.mockImplementation((selector?: (s: { worker: null }) => unknown) => {
      const state = { worker: null }
      return selector ? selector(state) : state
    })
    render(<CashierHeader />)
    const header = screen.getByRole('banner')
    expect(header.textContent).not.toContain('Admin')
    expect(header.textContent).not.toContain('Kozponti Iroda')
    expect(header.textContent).toContain('—')
  })

  it('explicit prop felulirja az authStore-t (branchCode override)', () => {
    render(<CashierHeader branchCode="999" branchName="Override Branch" workerName="Override Worker" workerId="OVR" />)
    const header = screen.getByRole('banner')
    expect(header.textContent).toMatch(/Pénztár:\s*999/)
    expect(header.textContent).toContain('Override Branch')
    expect(header.textContent).toContain('Override Worker')
    expect(header.textContent).toContain('OVR')
  })

  it('aktuális dátumot megjelenít', async () => {
    render(<CashierHeader />)
    const today = new Date().toLocaleDateString('hu-HU', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    })
    await waitFor(() => {
      expect(screen.getByText(new RegExp(today))).toBeInTheDocument()
    })
  })

  it('aktuális időt másodperc pontossággal megjelenít', async () => {
    render(<CashierHeader />)
    await waitFor(() => {
      expect(screen.getByText(/\d{2}:\d{2}:\d{2}/)).toBeInTheDocument()
    })
  })

  it('Pénztár / Pénztáros ekezetes feliratot mutat (NEM "Penztar" / "Penztaros")', () => {
    render(<CashierHeader />)
    const header = screen.getByRole('banner')
    expect(header.textContent).toContain('Pénztár')
    expect(header.textContent).toContain('Pénztáros')
  })

  it('company theme primary szin border-color-kent megjelenik', () => {
    render(<CashierHeader />)
    const header = screen.getByRole('banner')
    expect(header).toHaveStyle(`border-color: ${mockTheme.primary}`)
  })

  it('Shield ikont megjelenít', () => {
    const { container } = render(<CashierHeader />)
    const svg = container.querySelector('svg')
    expect(svg).toBeInTheDocument()
  })
})
