import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, it, expect, beforeEach } from 'vitest'
import DashboardPage from './DashboardPage'

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mocks.navigate,
  }
})

function renderDashboardPage() {
  render(
    <MemoryRouter>
      <DashboardPage />
    </MemoryRouter>,
  )
}

describe('DashboardPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('oldal renderelésének ellenőrzése', () => {
    renderDashboardPage()
    expect(screen.getByText('Irányítópult')).toBeInTheDocument()
    expect(screen.getByText('Áttekintés és gyorsműveletek')).toBeInTheDocument()
  })

  it('KPI kártyákat jeleníti meg', () => {
    renderDashboardPage()
    expect(screen.getByText('Mai tranzakciók')).toBeInTheDocument()
    expect(screen.getByText('Mai forgalom')).toBeInTheDocument()
    expect(screen.getByText('Aktív ügyfelek')).toBeInTheDocument()
    expect(screen.getByText('Függő foglalók')).toBeInTheDocument()
  })

  it('KPI értékeket helyesen jeleníti meg', () => {
    renderDashboardPage()
    expect(screen.getByText('47')).toBeInTheDocument() // todayTransactions
    expect(screen.getByText('12.5M Ft')).toBeInTheDocument() // todayVolume
    expect(screen.getByText('23')).toBeInTheDocument() // activeCustomers
    expect(screen.getByText('3')).toBeInTheDocument() // pendingDeposits
  })

  it('árfolyam táblázatot jeleníti meg', () => {
    renderDashboardPage()
    expect(screen.getByText('Aktuális árfolyamok')).toBeInTheDocument()
    expect(screen.getAllByText('EUR').length).toBeGreaterThan(0)
    expect(screen.getAllByText('USD').length).toBeGreaterThan(0)
    expect(screen.getAllByText('GBP').length).toBeGreaterThan(0)
    expect(screen.getAllByText('CHF').length).toBeGreaterThan(0)
  })

  it('árfolyamok vétel és eladási értékeket helyesen mutatja', () => {
    renderDashboardPage()
    // EUR sorban a vétel ár 391.50, eladás 398.50
    expect(screen.getByText('391.50')).toBeInTheDocument()
    expect(screen.getByText('398.50')).toBeInTheDocument()
  })

  it('gyorsműveletek linkeket jeleníti meg', () => {
    renderDashboardPage()
    expect(screen.getByText('Új tranzakció')).toBeInTheDocument()
    expect(screen.getByText('Új ügyfél')).toBeInTheDocument()
    expect(screen.getByText('Árfolyam módosítás')).toBeInTheDocument()
    expect(screen.getByText('Napi zárás')).toBeInTheDocument()
  })

  it('legutóbbi tranzakciók táblázatot jeleníti meg', () => {
    renderDashboardPage()
    expect(screen.getByText('Legutóbbi tranzakciók')).toBeInTheDocument()
    expect(screen.getByText('Kiss János')).toBeInTheDocument()
    expect(screen.getByText('Nagy Péter')).toBeInTheDocument()
    expect(screen.getByText('Szabó Anna')).toBeInTheDocument()
  })

  it('tranzakciók státuszát helyesen jelöli meg', () => {
    renderDashboardPage()
    const badges = screen.getAllByText('Befejezve')
    expect(badges.length).toBeGreaterThan(0)
    expect(screen.getByText('Folyamatban')).toBeInTheDocument()
  })

  it('utolsó frissítést az aktuális idővel jeleníti meg', () => {
    renderDashboardPage()
    expect(screen.getByText(/Utolsó frissítés:/)).toBeInTheDocument()
  })

  it('árfolyam részletek linkre kattintás navigál', () => {
    renderDashboardPage()
    const ratesLink = screen.getAllByText(/Részletek/)[0]
    expect(ratesLink).toBeInTheDocument()
  })

  it('összes tranzakciók linkre kattintás navigál', () => {
    renderDashboardPage()
    const allTransactionsLink = screen.getAllByText(/Összes/)[0]
    expect(allTransactionsLink).toBeInTheDocument()
  })
})
