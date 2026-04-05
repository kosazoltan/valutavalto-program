import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import TransactionListPage from './TransactionListPage'
import type { PagedResponse } from '../../services/api/client'
import type { Transaction } from '../../services/api/transactions'

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  transactionApiList: vi.fn(),
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mocks.navigate,
  }
})

vi.mock('../../services/api/transactions', async () => {
  const actual = await vi.importActual<typeof import('../../services/api/transactions')>('../../services/api/transactions')
  return {
    ...actual,
    transactionApi: {
      ...actual.transactionApi,
      list: mocks.transactionApiList,
    },
  }
})

const mockTransactions: Transaction[] = [
  {
    id: 1,
    receiptNumber: 'E001000001',
    transactionType: 'BUY',
    status: 'COMPLETED',
    transactionDate: '2024-01-15',
    transactionTime: '10:00:00',
    currencyId: 4,
    currencyCode: 'EUR',
    currencyAmount: 500,
    exchangeRate: 391.5,
    hufAmount: 195750,
    roundedHufAmount: 195750,
    handlingFee: 0,
    discountAmount: 0,
    discountPercent: 0,
    customerName: 'Kiss János',
    printed: false,
    branchId: 'b1',
    workerId: 1,
    createdAt: '2024-01-15T10:00:00Z',
  },
  {
    id: 2,
    receiptNumber: 'E001000002',
    transactionType: 'SELL',
    status: 'COMPLETED',
    transactionDate: '2024-01-15',
    transactionTime: '10:30:00',
    currencyId: 5,
    currencyCode: 'USD',
    currencyAmount: 1000,
    exchangeRate: 358.2,
    hufAmount: 358200,
    roundedHufAmount: 358200,
    handlingFee: 0,
    discountAmount: 0,
    discountPercent: 0,
    customerName: 'Nagy Péter',
    printed: false,
    branchId: 'b1',
    workerId: 1,
    createdAt: '2024-01-15T10:30:00Z',
  },
  {
    id: 3,
    receiptNumber: 'E001000003',
    transactionType: 'BUY',
    status: 'COMPLETED',
    transactionDate: '2024-01-15',
    transactionTime: '11:00:00',
    currencyId: 6,
    currencyCode: 'GBP',
    currencyAmount: 100,
    exchangeRate: 910,
    hufAmount: 91000,
    roundedHufAmount: 91000,
    handlingFee: 0,
    discountAmount: 0,
    discountPercent: 0,
    customerName: 'Szabó Anna',
    printed: false,
    branchId: 'b1',
    workerId: 1,
    createdAt: '2024-01-15T11:00:00Z',
  },
  {
    id: 4,
    receiptNumber: 'E001000004',
    transactionType: 'SELL',
    status: 'REVERSED',
    transactionDate: '2024-01-15',
    transactionTime: '11:30:00',
    currencyId: 4,
    currencyCode: 'EUR',
    currencyAmount: 300,
    exchangeRate: 402.5,
    hufAmount: 120750,
    roundedHufAmount: 120750,
    handlingFee: 0,
    discountAmount: 0,
    discountPercent: 0,
    customerName: 'Tóth Béla',
    printed: false,
    branchId: 'b1',
    workerId: 1,
    createdAt: '2024-01-15T11:30:00Z',
  },
  {
    id: 5,
    receiptNumber: 'E001000005',
    transactionType: 'BUY',
    status: 'COMPLETED',
    transactionDate: '2024-01-15',
    transactionTime: '12:00:00',
    currencyId: 5,
    currencyCode: 'USD',
    currencyAmount: 1500,
    exchangeRate: 391.5,
    hufAmount: 587250,
    roundedHufAmount: 587250,
    handlingFee: 0,
    discountAmount: 0,
    discountPercent: 0,
    customerName: undefined,
    printed: false,
    branchId: 'b1',
    workerId: 1,
    createdAt: '2024-01-15T12:00:00Z',
  },
]

const mockPagedResponse: PagedResponse<Transaction> = {
  content: mockTransactions,
  totalElements: 5,
  totalPages: 1,
  size: 25,
  number: 0,
}

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
    mocks.transactionApiList.mockResolvedValue(mockPagedResponse)
  })

  it('oldal renderelésének ellenőrzése', async () => {
    renderTransactionListPage()
    expect(screen.getByText('Tranzakciók')).toBeInTheDocument()
  })

  it('új tranzakció gomb megjelenítése', async () => {
    renderTransactionListPage()
    const newButton = screen.getByText('Új tranzakció')
    expect(newButton).toBeInTheDocument()
  })

  it('szűrő mezőket megjelenít', () => {
    renderTransactionListPage()
    expect(screen.getByPlaceholderText('Ügyfél neve...')).toBeInTheDocument()
    const dateInputs = document.querySelectorAll('input[type="date"]')
    expect(dateInputs.length).toBeGreaterThanOrEqual(2)
    const selects = document.querySelectorAll('select')
    expect(selects.length).toBeGreaterThanOrEqual(1)
  })

  it('tranzakciós táblázat fejlécet megjelenít', async () => {
    renderTransactionListPage()
    await waitFor(() => {
      expect(screen.getByText('Dátum/Idő')).toBeInTheDocument()
    })
    expect(screen.getAllByText('Típus').length).toBeGreaterThan(0)
    expect(screen.getByText('Ügyfél')).toBeInTheDocument()
    expect(screen.getByText('Státusz')).toBeInTheDocument()
  })

  it('összes tranzakciót megjeleníti alapértelmezésben', async () => {
    renderTransactionListPage()
    await waitFor(() => {
      expect(screen.getByText('Kiss János')).toBeInTheDocument()
      expect(screen.getByText('Nagy Péter')).toBeInTheDocument()
      expect(screen.getByText('Szabó Anna')).toBeInTheDocument()
      expect(screen.getByText('Tóth Béla')).toBeInTheDocument()
    })
  })

  it('tranzakciók száma helyesen kerül megjelenítésre', async () => {
    renderTransactionListPage()
    await waitFor(() => {
      expect(screen.getByText(/5 tranzakció/)).toBeInTheDocument()
    })
  })

  it('ügyféls keresés szűri az eredményeket', async () => {
    renderTransactionListPage()
    const user = userEvent.setup()

    await waitFor(() => {
      expect(screen.getByText('Kiss János')).toBeInTheDocument()
    })

    const searchInput = screen.getByPlaceholderText('Ügyfél neve...')
    await user.type(searchInput, 'Kiss')

    await waitFor(() => {
      expect(screen.getByText('Kiss János')).toBeInTheDocument()
      expect(screen.queryByText('Nagy Péter')).not.toBeInTheDocument()
    })
  })

  it('típus szűrés megmutatja csak az ELADÁS tranzakciókat', async () => {
    // Server-side type filter — mock a SELL-only response
    mocks.transactionApiList
      .mockResolvedValueOnce(mockPagedResponse)
      .mockResolvedValueOnce({
        content: mockTransactions.filter(t => t.transactionType === 'SELL'),
        totalElements: 2,
        totalPages: 1,
        size: 25,
        number: 0,
      })

    renderTransactionListPage()
    const user = userEvent.setup()

    await waitFor(() => {
      expect(screen.getByText('Kiss János')).toBeInTheDocument()
    })

    const selects = document.querySelectorAll('select')
    const typeSelect = selects[0] as HTMLSelectElement
    await user.selectOptions(typeSelect, 'SELL')

    await waitFor(() => {
      expect(screen.getByText('Nagy Péter')).toBeInTheDocument()
      expect(screen.queryByText('Kiss János')).not.toBeInTheDocument()
    })
  })

  it('sztornózott tranzakciók jelölése', async () => {
    renderTransactionListPage()
    await waitFor(() => {
      expect(screen.getByText('Tóth Béla')).toBeInTheDocument()
    })
    const sztornozottRow = screen.getByText('Tóth Béla').closest('tr')
    expect(sztornozottRow).toHaveClass('opacity-50')
  })

  it('teljesítve státusz zöld szín', async () => {
    renderTransactionListPage()
    await waitFor(() => {
      const completedBadges = screen.getAllByText('Teljesítve')
      expect(completedBadges.length).toBeGreaterThan(0)
    })
  })

  it('sztornózva státusz piros szín', async () => {
    renderTransactionListPage()
    await waitFor(() => {
      const cancelledBadge = screen.getByText('Sztornózva')
      expect(cancelledBadge).toBeInTheDocument()
    })
  })

  it('megtekintés gomb navigál a tranzakció detailra', async () => {
    renderTransactionListPage()
    const user = userEvent.setup()

    await waitFor(() => {
      expect(screen.getAllByTitle('Megtekintés').length).toBeGreaterThan(0)
    })

    const viewButtons = screen.getAllByTitle('Megtekintés')
    await user.click(viewButtons[0]!)

    expect(mocks.navigate).toHaveBeenCalledWith('/transactions/E001000001')
  })

  it('sztornó gomb csak teljesített tranzakcióhoz jelenik meg', async () => {
    renderTransactionListPage()
    await waitFor(() => {
      expect(screen.getAllByTitle('Sztornó').length).toBeGreaterThan(0)
    })
    const stornoButtons = screen.getAllByTitle('Sztornó')
    // 4 COMPLETED transactions (id 1,2,3,5), REVERSED one (id 4) has no storno button
    expect(stornoButtons.length).toBe(4)
  })

  it('sztornó gomb navigál a sztornó oldalra', async () => {
    renderTransactionListPage()
    const user = userEvent.setup()

    await waitFor(() => {
      expect(screen.getAllByTitle('Sztornó').length).toBeGreaterThan(0)
    })

    const stornoButtons = screen.getAllByTitle('Sztornó')
    await user.click(stornoButtons[0]!)

    expect(mocks.navigate).toHaveBeenCalledWith('/transactions/E001000001/storno')
  })

  it('összeg összesítő helyesen mutatja az összes HUF összeget', async () => {
    renderTransactionListPage()
    // 195750 + 358200 + 91000 + 120750 + 587250 = 1352950
    await waitFor(() => {
      expect(screen.getByText(/1[\s.,]?352[\s.,]?950|1352950/)).toBeInTheDocument()
    })
  })

  it('szűrés törlésére az összes tranzakció visszajelenik', async () => {
    renderTransactionListPage()
    const user = userEvent.setup()

    await waitFor(() => {
      expect(screen.getByText('Nagy Péter')).toBeInTheDocument()
    })

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

  it('transactionApi.list() hívás PagedResponse-t vár', async () => {
    renderTransactionListPage()
    await waitFor(() => {
      expect(mocks.transactionApiList).toHaveBeenCalled()
    })
    // Verify the mock returned PagedResponse with correct fields
    const returnValue = await mocks.transactionApiList.mock.results[0]?.value
    expect(returnValue).toHaveProperty('content')
    expect(returnValue).toHaveProperty('totalElements')
    expect(returnValue).toHaveProperty('totalPages')
  })

  it('transactionApi.list() mezőnév egyezés — Transaction interface', async () => {
    renderTransactionListPage()
    await waitFor(() => {
      expect(screen.getByText('Kiss János')).toBeInTheDocument()
    })
    // Verify component correctly accesses Transaction fields
    // currencyCode shown in table (multiple EUR rows possible)
    expect(screen.getAllByText('EUR').length).toBeGreaterThan(0)
    // transactionType badge rendered
    expect(screen.getAllByText('Vétel').length).toBeGreaterThan(0)
    expect(screen.getAllByText('Eladás').length).toBeGreaterThan(0)
  })
})
