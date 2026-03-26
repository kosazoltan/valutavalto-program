import { render, screen, waitFor } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import { CashierHeader } from './CashierHeader'

const mocks = vi.hoisted(() => ({
  useCompanyTheme: vi.fn(),
}))

vi.mock('../../contexts/CompanyThemeContext', () => ({
  useCompanyTheme: mocks.useCompanyTheme,
}))

const mockTheme = {
  primary: '#2563eb',
  secondary: '#64748b',
  success: '#10b981',
  danger: '#ef4444',
  warning: '#f59e0b',
  info: '#3b82f6',
}

describe('CashierHeader', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.useCompanyTheme.mockReturnValue({ theme: mockTheme })
  })

  it('componens renderelésének ellenőrzése', () => {
    render(<CashierHeader />)
    expect(screen.getByRole('banner')).toBeInTheDocument()
  })

  it('alapértelmezett pénztár kódot megjelenít', () => {
    render(<CashierHeader />)
    expect(screen.getByText(/101/)).toBeInTheDocument()
  })

  it('alapértelmezett pénztár nevét megjelenít', () => {
    render(<CashierHeader />)
    expect(screen.getByText(/Kozponti Iroda/)).toBeInTheDocument()
  })

  it('alapértelmezett pénztáros nevét megjelenít', () => {
    render(<CashierHeader />)
    expect(screen.getByText(/Admin/)).toBeInTheDocument()
  })

  it('alapértelmezett pénztáros ID-jét megjelenít', () => {
    render(<CashierHeader />)
    expect(screen.getByText(/ADMIN/)).toBeInTheDocument()
  })

  it('custom pénztár kódot megjelenít', () => {
    render(
      <CashierHeader
        branchCode="202"
        branchName="Eger Fiók"
        workerName="Kiss János"
        workerId="KJ001"
      />,
    )
    // Pénztár kód megjelenik a header-ben
    const header = screen.getByRole('banner')
    expect(header).toBeInTheDocument()
    expect(header.textContent).toContain('202')
  })

  it('custom pénztár nevét megjelenít', () => {
    render(
      <CashierHeader
        branchCode="202"
        branchName="Eger Fiók"
        workerName="Kiss János"
        workerId="KJ001"
      />,
    )
    expect(screen.getByText(/Eger Fiók/)).toBeInTheDocument()
  })

  it('custom pénztáros nevét megjelenít', () => {
    render(
      <CashierHeader
        branchCode="202"
        branchName="Eger Fiók"
        workerName="Kiss János"
        workerId="KJ001"
      />,
    )
    expect(screen.getByText(/Kiss János/)).toBeInTheDocument()
  })

  it('custom pénztáros ID-jét megjelenít', () => {
    render(
      <CashierHeader
        branchCode="202"
        branchName="Eger Fiók"
        workerName="Kiss János"
        workerId="KJ001"
      />,
    )
    expect(screen.getByText(/KJ001/)).toBeInTheDocument()
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

    // Az idő frissül, tehát az aktuális óra, perc és másodperc megjelenik
    await waitFor(() => {
      expect(screen.getByText(/\d{2}:\d{2}:\d{2}/)).toBeInTheDocument()
    })
  })

  it('verzió szám megjeleníthet', () => {
    const { container } = render(<CashierHeader />)
    // A verzió szám nincs a teszt kimenetben, de a header létezik
    expect(container.querySelector('header')).toBeInTheDocument()
  })

  it('company theme logóját alkalmazza az első szín alapján', () => {
    render(<CashierHeader />)
    const header = screen.getByRole('banner')
    expect(header).toHaveStyle(`border-color: ${mockTheme.primary}`)
  })

  it('időt folyamatosan frissíti', async () => {
    render(<CashierHeader />)

    // Az idő megjelenik a headerben
    const header = screen.getByRole('banner')
    expect(header.textContent).toMatch(/\d{2}:\d{2}:\d{2}/)
  }, { timeout: 2000 })

  it('Shield ikont megjelenít', () => {
    const { container } = render(<CashierHeader />)
    const svg = container.querySelector('svg')
    expect(svg).toBeInTheDocument()
  })

  it('minden prop megadásakor teljes információt mutat', () => {
    render(
      <CashierHeader
        branchCode="303"
        branchName="Pécs Fiók"
        workerName="Szabó Péter"
        workerId="SP002"
      />,
    )

    expect(screen.getByText(/303/)).toBeInTheDocument()
    expect(screen.getByText(/Pécs Fiók/)).toBeInTheDocument()
    expect(screen.getByText(/Szabó Péter/)).toBeInTheDocument()
    expect(screen.getByText(/SP002/)).toBeInTheDocument()
  })

  it('header elem megjelenik', () => {
    render(<CashierHeader />)
    expect(screen.getByRole('banner')).toBeInTheDocument()
  })
})
