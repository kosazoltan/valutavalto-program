import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ReportsPage from './ReportsPage'

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

describe('ReportsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('oldal renderelésének ellenőrzése', () => {
    render(<ReportsPage />)
    expect(screen.getByText('Riportok')).toBeInTheDocument()
  })

  it('riport kártyákat megjelenít', () => {
    render(<ReportsPage />)
    const reportButtons = screen.getAllByRole('button')
    expect(reportButtons.length).toBeGreaterThanOrEqual(6)
  })

  it('napi forgalom kártya megjelenik', () => {
    render(<ReportsPage />)
    expect(screen.getByText('Napi forgalom')).toBeInTheDocument()
  })

  it('napló kártya megjelenik', () => {
    render(<ReportsPage />)
    expect(screen.getByText('Napló (DayBook)')).toBeInTheDocument()
  })

  it('dekádzárás kártya megjelenik', () => {
    render(<ReportsPage />)
    expect(screen.getByText('Dekádzárás')).toBeInTheDocument()
  })

  it('eredmény kimutatás kártya megjelenik', () => {
    render(<ReportsPage />)
    expect(screen.getByText('Eredmény kimutatás')).toBeInTheDocument()
  })

  it('MNB jelentés kártya megjelenik', () => {
    render(<ReportsPage />)
    expect(screen.getByText('MNB jelentés')).toBeInTheDocument()
  })

  it('havi zárás kártya megjelenik', () => {
    render(<ReportsPage />)
    expect(screen.getByText('Havi zárás')).toBeInTheDocument()
  })

  it('kibővített riportok kártya megjelenik', () => {
    render(<ReportsPage />)
    expect(screen.getByText('Kibővített riportok')).toBeInTheDocument()
  })

  it('névtelen bejelentés kártya megjelenik', () => {
    render(<ReportsPage />)
    expect(screen.getByText('Névtelen bejelentés')).toBeInTheDocument()
  })

  it('gyanús tranzakciók kártya megjelenik', () => {
    render(<ReportsPage />)
    expect(screen.getByText('Gyanús tranzakciók')).toBeInTheDocument()
  })

  it('minden kártyának van leírása', () => {
    render(<ReportsPage />)
    expect(screen.getByText('Napi tranzakciók és forgalom összesítése')).toBeInTheDocument()
    expect(screen.getByText('Hatósági (MNB) jelentés generálás')).toBeInTheDocument()
  })

  it('napi forgalom kártyára kattintás navigál', async () => {
    render(<ReportsPage />)
    const user = userEvent.setup()
    const button = screen.getByTestId('report-link-daily-turnover')
    await user.click(button)
    expect(mocks.navigate).toHaveBeenCalledWith('/daily-turnover')
  })

  it('MNB jelentés kártyára kattintás navigál', async () => {
    render(<ReportsPage />)
    const user = userEvent.setup()
    const button = screen.getByTestId('report-link-mnb')
    await user.click(button)
    expect(mocks.navigate).toHaveBeenCalledWith('/reports/mnb')
  })

  it('kibővített riportok kártyára kattintás navigál', async () => {
    render(<ReportsPage />)
    const user = userEvent.setup()
    const button = screen.getByTestId('report-link-extended')
    await user.click(button)
    expect(mocks.navigate).toHaveBeenCalledWith('/reports/extended')
  })

  it('havi zárás kártyára kattintás navigál', async () => {
    render(<ReportsPage />)
    const user = userEvent.setup()
    const button = screen.getByTestId('report-link-monthly')
    await user.click(button)
    expect(mocks.navigate).toHaveBeenCalledWith('/closing/monthly')
  })

  it('darius riport kártyára kattintás navigál', async () => {
    render(<ReportsPage />)
    const user = userEvent.setup()
    const button = screen.getByTestId('report-link-darius')
    await user.click(button)
    expect(mocks.navigate).toHaveBeenCalledWith('/darius')
  })

  it('névtelen bejelentés kártyára kattintás navigál', async () => {
    render(<ReportsPage />)
    const user = userEvent.setup()
    const button = screen.getByTestId('report-link-anonymous')
    await user.click(button)
    expect(mocks.navigate).toHaveBeenCalledWith('/anonymous-reports')
  })

  it('14 riport kártya szerepel összesen (G9 + G17 + G23)', () => {
    render(<ReportsPage />)
    const buttons = screen.getAllByRole('button')
    expect(buttons.length).toBe(14)
  })
})
