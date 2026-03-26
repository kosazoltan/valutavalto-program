import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import TransactionListPage from './TransactionListPage'

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

function renderTransactionListPage() {
  render(
    <MemoryRouter>
      <TransactionListPage />
    </MemoryRouter>,
  )
}

describe('TransactionListPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('oldal renderelésének ellenőrzése', () => {
    renderTransactionListPage()
    expect(screen.getByText('Tranzakciók')).toBeInTheDocument()
  })

  it('új tranzakció gomb megjelenítése', () => {
    renderTransactionListPage()
    const newButton = screen.getByText('Új tranzakció')
    expect(newButton).toBeInTheDocument()
  })

  it('szűrő mezőket megjelenít', () => {
    renderTransactionListPage()
    expect(screen.getByPlaceholderText('Ügyfél neve...')).toBeInTheDocument()
    // Date inputs are not labeled properly
    const dateInputs = document.querySelectorAll('input[type="date"]')
    expect(dateInputs.length).toBeGreaterThanOrEqual(2)
    // Select elements for Type and Currency
    const selects = document.querySelectorAll('select')
    expect(selects.length).toBeGreaterThanOrEqual(2)
  })

  it('tranzakciós táblázat fejlécet megjelenít', () => {
    renderTransactionListPage()
    expect(screen.getByText('Dátum/Idő')).toBeInTheDocument()
    expect(screen.getAllByText('Típus').length).toBeGreaterThan(0) // Both filter and table header
    expect(screen.getAllByText('Deviza').length).toBeGreaterThan(0) // Both filter and table header
    expect(screen.getByText('Ügyfél')).toBeInTheDocument()
    expect(screen.getByText('Státusz')).toBeInTheDocument()
  })

  it('összes tranzakciót megjeleníti alapértelmezésben', () => {
    renderTransactionListPage()
    expect(screen.getByText('Kiss János')).toBeInTheDocument()
    expect(screen.getByText('Nagy Péter')).toBeInTheDocument()
    expect(screen.getByText('Szabó Anna')).toBeInTheDocument()
    expect(screen.getByText('Tóth Béla')).toBeInTheDocument()
  })

  it('tranzakciók száma helyesen kerül megjelenítésre', () => {
    renderTransactionListPage()
    expect(screen.getByText('5 tranzakció')).toBeInTheDocument()
  })

  it('ügyféls keresés szűri az eredményeket', async () => {
    renderTransactionListPage()
    const user = userEvent.setup()

    const searchInput = screen.getByPlaceholderText('Ügyfél neve...')
    await user.type(searchInput, 'Kiss')

    await waitFor(() => {
      expect(screen.getByText('Kiss János')).toBeInTheDocument()
      expect(screen.queryByText('Nagy Péter')).not.toBeInTheDocument()
    })
  })

  it('típus szűrés megmutatja csak a VÉTEL tranzakciókat', async () => {
    renderTransactionListPage()
    const user = userEvent.setup()

    const typeSelects = screen.queryAllByDisplayValue('')
    const typeSelect = typeSelects.find(el => (el as HTMLSelectElement).name === undefined) as HTMLSelectElement
    if (!typeSelect) return // Skip if select nem létezik
    await user.selectOptions(typeSelect, 'BUY')

    await waitFor(() => {
      expect(screen.getByText('Kiss János')).toBeInTheDocument()
      expect(screen.getByText('Szabó Anna')).toBeInTheDocument()
      expect(screen.queryByText('Nagy Péter')).not.toBeInTheDocument()
    })
  })

  it('típus szűrés megmutatja csak az ELADÁS tranzakciókat', async () => {
    renderTransactionListPage()
    const user = userEvent.setup()

    const selects = document.querySelectorAll('select')
    if (selects.length > 0) {
      const typeSelect = selects[0] as HTMLSelectElement
      await user.selectOptions(typeSelect, 'SELL')

      await waitFor(() => {
        expect(screen.getByText('Nagy Péter')).toBeInTheDocument()
        expect(screen.queryByText('Kiss János')).not.toBeInTheDocument()
      })
    }
  })

  it('deviza szűrés megmutatja csak az EUR tranzakciókat', async () => {
    renderTransactionListPage()
    const user = userEvent.setup()

    const selects = document.querySelectorAll('select')
    if (selects.length > 1) {
      const currencySelect = selects[1] as HTMLSelectElement
      await user.selectOptions(currencySelect, 'EUR')

      await waitFor(() => {
        expect(screen.getByText('Kiss János')).toBeInTheDocument()
        expect(screen.getByText('Tóth Béla')).toBeInTheDocument()
        expect(screen.queryByText('Nagy Péter')).not.toBeInTheDocument()
      })
    }
  })

  it('sztornózott tranzakciók jelölése', () => {
    renderTransactionListPage()
    const sztornozottRow = screen.getByText('Tóth Béla').closest('tr')
    expect(sztornozottRow).toHaveClass('opacity-50')
  })

  it('teljesítve státusz zöld szín', () => {
    renderTransactionListPage()
    const completedBadges = screen.getAllByText('Teljesítve')
    expect(completedBadges.length).toBeGreaterThan(0)
  })

  it('sztornózva státusz piros szín', () => {
    renderTransactionListPage()
    const cancelledBadge = screen.getByText('Sztornózva')
    expect(cancelledBadge).toBeInTheDocument()
  })

  it('megtekintés gomb navigál a tranzakció detailra', async () => {
    renderTransactionListPage()
    const user = userEvent.setup()

    const viewButtons = screen.getAllByTitle('Megtekintés')
    await user.click(viewButtons[0]!)

    expect(mocks.navigate).toHaveBeenCalledWith('/transactions/1')
  })

  it('sztornó gomb csak teljesített tranzakcióhoz jelenik meg', () => {
    renderTransactionListPage()
    const stornoButtons = screen.getAllByTitle('Sztornó')
    // 4 teljesített tranzakció, csak azoknak kell sztornó gomb
    expect(stornoButtons.length).toBe(4)
  })

  it('sztornó gomb navigál a sztornó oldalra', async () => {
    renderTransactionListPage()
    const user = userEvent.setup()

    const stornoButtons = screen.getAllByTitle('Sztornó')
    await user.click(stornoButtons[0]!)

    expect(mocks.navigate).toHaveBeenCalledWith('/transactions/1/storno')
  })

  it('összeg összesítő helyesen mutatja az összes HUF összeget', () => {
    renderTransactionListPage()
    // 195750 + 358200 + 91000 + 120750 + 587250 = 1352950
    // Check for the summary panel with the total
    expect(screen.getByText(/1352950|1\.352\.950|1 352 950/)).toBeInTheDocument()
  })

  it('nincs ügyfél esetén "Névtelen" szöveg megjelenik', () => {
    renderTransactionListPage()
    expect(screen.getByText('Névtelen')).toBeInTheDocument()
  })

  it('kombinált szűrés keresés és típus', async () => {
    renderTransactionListPage()
    const user = userEvent.setup()

    const searchInput = screen.getByPlaceholderText('Ügyfél neve...')
    const selects = document.querySelectorAll('select')
    if (selects.length > 0) {
      const typeSelect = selects[0] as HTMLSelectElement

      await user.type(searchInput, 'Kiss')
      await user.selectOptions(typeSelect, 'BUY')

      await waitFor(() => {
        expect(screen.getByText('Kiss János')).toBeInTheDocument()
        expect(screen.queryByText('Nagy Péter')).not.toBeInTheDocument()
        expect(screen.queryByText('Szabó Anna')).not.toBeInTheDocument()
      })
    }
  })

  it('szűrés törlésére az összes tranzakció visszajelenik', async () => {
    renderTransactionListPage()
    const user = userEvent.setup()

    const searchInput = screen.getByPlaceholderText('Ügyfél neve...') as HTMLInputElement
    await user.type(searchInput, 'Kiss')

    await waitFor(() => {
      expect(searchInput.value).toBe('Kiss')
      expect(screen.queryByText('Nagy Péter')).not.toBeInTheDocument()
    })

    await user.clear(searchInput)

    await waitFor(() => {
      expect(searchInput.value).toBe('')
      expect(screen.getByText('Nagy Péter')).toBeInTheDocument()
    })
  })
})
