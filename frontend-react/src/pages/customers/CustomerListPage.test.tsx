import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import CustomerListPage from './CustomerListPage'

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

const mockCustomers = [
  {
    id: 1,
    name: 'Kiss János',
    birthDate: '1985-03-15',
    nationality: 'Magyar',
    documentType: 'Személyi ig.',
    documentNumber: '123456AB',
    phone: '+36301234567',
    active: true,
    isVip: false,
  },
  {
    id: 2,
    name: 'Nagy Péter',
    birthDate: '1990-07-22',
    nationality: 'Magyar',
    documentType: 'Útlevél',
    documentNumber: 'AB1234567',
    phone: '+36309876543',
    active: true,
    isVip: false,
  },
  {
    id: 3,
    name: 'Szabó Anna',
    birthDate: '1978-11-30',
    nationality: 'Szlovák',
    documentType: 'Személyi ig.',
    documentNumber: 'SK987654',
    phone: null,
    active: true,
    isVip: false,
  },
  {
    id: 4,
    name: 'Kovács István',
    birthDate: '1965-01-10',
    nationality: 'Magyar',
    documentType: 'Útlevél',
    documentNumber: 'HU5556677',
    phone: '+36201112233',
    active: true,
    isVip: false,
  },
]

const mockGetActive = vi.fn()
const mockSearch = vi.fn()
const mockSearchByName = vi.fn()
const mockGetByCode = vi.fn()
const mockGetVip = vi.fn()
const mockGetFrequent = vi.fn()
const mockGetTop = vi.fn()
const mockGetPendingReview = vi.fn()
const mockDeactivate = vi.fn()
const mockActivate = vi.fn()

vi.mock('../../services/api/transactions', () => ({
  customerApi: {
    getActive: (...args: unknown[]) => mockGetActive(...args),
    search: (...args: unknown[]) => mockSearch(...args),
    searchByName: (...args: unknown[]) => mockSearchByName(...args),
    getByCode: (...args: unknown[]) => mockGetByCode(...args),
    getVip: (...args: unknown[]) => mockGetVip(...args),
    getFrequent: (...args: unknown[]) => mockGetFrequent(...args),
    getTop: (...args: unknown[]) => mockGetTop(...args),
    getPendingReview: (...args: unknown[]) => mockGetPendingReview(...args),
    deactivate: (...args: unknown[]) => mockDeactivate(...args),
    activate: (...args: unknown[]) => mockActivate(...args),
  },
}))

function renderCustomerListPage() {
  return render(
    <MemoryRouter>
      <CustomerListPage />
    </MemoryRouter>,
  )
}

describe('CustomerListPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockGetActive.mockResolvedValue(mockCustomers)
    mockSearch.mockImplementation((q: string) => {
      const lower = q.toLowerCase()
      return Promise.resolve(
        mockCustomers.filter(
          (c) =>
            c.name.toLowerCase().includes(lower) || c.documentNumber.toLowerCase().includes(lower),
        ),
      )
    })
    mockSearchByName.mockResolvedValue([{ ...mockCustomers[1], customerCode: 'U000002' }])
    mockGetByCode.mockResolvedValue({ ...mockCustomers[0], customerCode: 'U000001' })
    mockGetVip.mockResolvedValue([{ ...mockCustomers[2], name: 'VIP Lista Ügyfél', isVip: true }])
    mockGetFrequent.mockResolvedValue([
      {
        customerId: 2,
        customerName: 'Gyakori Lista Ügyfél',
        transactionCount: 9,
        totalVolumeHuf: 2500000,
        rank: 1,
      },
    ])
    mockGetTop.mockResolvedValue([
      {
        customerId: 4,
        customerName: 'Top Lista Ügyfél',
        transactionCount: 7,
        totalVolumeHuf: 3100000,
        rank: 1,
      },
    ])
    mockGetPendingReview.mockResolvedValue([
      { ...mockCustomers[0], id: 9, name: 'Átnézendő Ügyfél', reviewStatus: 'PENDING_REVIEW' },
    ])
    mockDeactivate.mockResolvedValue(undefined)
    mockActivate.mockResolvedValue(undefined)
  })

  it('oldal renderelésének ellenőrzése', async () => {
    renderCustomerListPage()
    expect(screen.getByText('Ügyfelek')).toBeInTheDocument()
    await waitFor(() => expect(mockGetActive).toHaveBeenCalled())
  })

  it('új ügyfél gomb megjelenítése', () => {
    renderCustomerListPage()
    expect(screen.getByText('Új ügyfél')).toBeInTheDocument()
  })

  it('keresési mező megjelenítése', () => {
    renderCustomerListPage()
    expect(screen.getByPlaceholderText(/Keresés név vagy okmányszám alapján/)).toBeInTheDocument()
    expect(screen.getByPlaceholderText(/Ügyfélkód pontos keresése/)).toBeInTheDocument()
  })

  it('ügyfélkód pontos keresése a customerApi.getByCode backend wrapperre köt', async () => {
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Kiss János')).toBeInTheDocument())

    const user = userEvent.setup()
    await user.type(screen.getByPlaceholderText(/Ügyfélkód pontos keresése/), 'U000001')
    await user.click(screen.getByRole('button', { name: 'Ügyfélkód keresés' }))

    await waitFor(() => {
      expect(mockGetByCode).toHaveBeenCalledWith('U000001')
    })
    expect(await screen.findByText('U000001')).toBeInTheDocument()
  })

  it('ügyfél gyorslistákat backend read endpointokról tölti', async () => {
    renderCustomerListPage()

    await waitFor(() => {
      expect(mockGetVip).toHaveBeenCalled()
      expect(mockGetFrequent).toHaveBeenCalledWith({ minTx: 5 })
      expect(mockGetTop).toHaveBeenCalledWith({ limit: 5 })
    })

    expect(await screen.findByTestId('customer-vip-count')).toHaveTextContent('1')
    expect(screen.getByTestId('customer-frequent-count')).toHaveTextContent('1')
    expect(screen.getByTestId('customer-top-count')).toHaveTextContent('1')
    expect(screen.getByText('VIP Lista Ügyfél')).toBeInTheDocument()
    expect(screen.getByText('Gyakori Lista Ügyfél')).toBeInTheDocument()
    expect(screen.getByText('Top Lista Ügyfél')).toBeInTheDocument()
  })

  it('név szerinti legacy keresés a /customers/search wrapperre köt', async () => {
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Kiss János')).toBeInTheDocument())

    const user = userEvent.setup()
    const searchInput = screen.getByPlaceholderText(/Keresés név vagy okmányszám alapján/)
    await user.type(searchInput, 'Nagy')
    await user.click(screen.getByRole('button', { name: 'Név szerinti keresés' }))

    await waitFor(() => expect(mockSearchByName).toHaveBeenCalledWith('Nagy'))
    expect(screen.getByText('Nagy Péter')).toBeInTheDocument()
  })

  it('összes ügyfél megjelenítése alapértelmezésben', async () => {
    renderCustomerListPage()
    await waitFor(() => {
      expect(screen.getByText('Kiss János')).toBeInTheDocument()
      expect(screen.getByText('Nagy Péter')).toBeInTheDocument()
      expect(screen.getByText('Szabó Anna')).toBeInTheDocument()
      expect(screen.getByText('Kovács István')).toBeInTheDocument()
    })
  })

  it('ügyfél nevét megjelenít', async () => {
    renderCustomerListPage()
    await waitFor(() => {
      expect(screen.getByText('Kiss János')).toBeInTheDocument()
    })
  })

  it('születési dátumot megjelenít', async () => {
    renderCustomerListPage()
    await waitFor(() => {
      expect(screen.getByText('1985. 03. 15.')).toBeInTheDocument()
    })
  })

  it('állampolgárságot megjelenít', async () => {
    renderCustomerListPage()
    await waitFor(() => {
      expect(screen.getAllByText('Magyar').length).toBeGreaterThan(0)
      expect(screen.getByText('Szlovák')).toBeInTheDocument()
    })
  })

  it('okmány típusokat megjelenít', async () => {
    renderCustomerListPage()
    await waitFor(() => {
      expect(screen.getAllByText('Személyi ig.').length).toBeGreaterThan(0)
      expect(screen.getAllByText('Útlevél').length).toBeGreaterThan(0)
    })
  })

  it('okmányszámokat megjelenít', async () => {
    renderCustomerListPage()
    await waitFor(() => {
      expect(screen.getByText('123456AB')).toBeInTheDocument()
      expect(screen.getByText('AB1234567')).toBeInTheDocument()
    })
  })

  it('telefonszámokat megjelenít', async () => {
    renderCustomerListPage()
    await waitFor(() => {
      expect(screen.getByText('+36301234567')).toBeInTheDocument()
    })
  })

  it('keresés név alapján szűr', async () => {
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Kiss János')).toBeInTheDocument())

    const user = userEvent.setup()
    const searchInput = screen.getByPlaceholderText(/Keresés név vagy okmányszám alapján/)
    await user.type(searchInput, 'Kiss')

    await waitFor(() => {
      expect(screen.getByText('Kiss János')).toBeInTheDocument()
      expect(screen.queryByText('Nagy Péter')).not.toBeInTheDocument()
    })
  })

  it('keresés okmányszám alapján szűr', async () => {
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Kiss János')).toBeInTheDocument())

    const user = userEvent.setup()
    const searchInput = screen.getByPlaceholderText(/Keresés név vagy okmányszám alapján/)
    await user.type(searchInput, '123456AB')

    await waitFor(() => {
      expect(screen.getByText('Kiss János')).toBeInTheDocument()
      expect(screen.queryByText('Nagy Péter')).not.toBeInTheDocument()
    })
  })

  it('keresés kis/nagybetűre nem érzékeny', async () => {
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Kiss János')).toBeInTheDocument())

    const user = userEvent.setup()
    const searchInput = screen.getByPlaceholderText(/Keresés név vagy okmányszám alapján/)
    await user.type(searchInput, 'kiss')

    await waitFor(() => {
      expect(screen.getByText('Kiss János')).toBeInTheDocument()
    })
  })

  it('megtekintés gomb navigál az ügyfél detailra', async () => {
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Kiss János')).toBeInTheDocument())

    const viewButtons = screen.getAllByTitle('Megtekintés')
    expect(viewButtons.length).toBeGreaterThan(0)
    // Link href ellenőrzés
    expect(viewButtons[0]!.closest('a')).toHaveAttribute('href', '/customers/1')
  })

  it('szerkesztés gomb megjelenít', async () => {
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Kiss János')).toBeInTheDocument())

    const editButtons = screen.getAllByTitle('Szerkesztés')
    expect(editButtons.length).toBeGreaterThan(0)
  })

  it('inaktiválás gomb megjelenít', async () => {
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Kiss János')).toBeInTheDocument())

    const deactivateButtons = screen.getAllByTitle('Inaktiválás')
    expect(deactivateButtons.length).toBeGreaterThan(0)
  })

  it('inaktív ügyfélnél az aktiválás a customerApi.activate backend wrapperre köt', async () => {
    const confirmSpy = vi.spyOn(window, 'confirm').mockReturnValue(true)
    mockGetActive.mockResolvedValue([
      { ...mockCustomers[0], id: 10, name: 'Inaktív Teszt Ügyfél', active: false },
    ])

    const user = userEvent.setup()
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Inaktív Teszt Ügyfél')).toBeInTheDocument())

    await user.click(screen.getByTitle('Aktiválás'))

    await waitFor(() => {
      expect(mockActivate).toHaveBeenCalledWith(10)
    })
    confirmSpy.mockRestore()
  })

  it('üres keresési eredmény kezelése', async () => {
    mockSearch.mockResolvedValue([])
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Kiss János')).toBeInTheDocument())

    const user = userEvent.setup()
    const searchInput = screen.getByPlaceholderText(/Keresés név vagy okmányszám alapján/)
    await user.type(searchInput, 'Nonexistent Customer')

    await waitFor(() => {
      expect(screen.queryByText('Kiss János')).not.toBeInTheDocument()
      expect(screen.getByText('Nincs találat')).toBeInTheDocument()
    })
  })

  it('keresési szűrés törlésére az összes ügyfél visszajelenik', async () => {
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Kiss János')).toBeInTheDocument())

    const user = userEvent.setup()
    const searchInput = screen.getByPlaceholderText(
      /Keresés név vagy okmányszám alapján/,
    ) as HTMLInputElement
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

  it('tábla fejléc megjelenítése', async () => {
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Kiss János')).toBeInTheDocument())

    expect(screen.getByText('Név')).toBeInTheDocument()
    expect(screen.getByText('Születési dátum')).toBeInTheDocument()
    expect(screen.getByText('Állampolgárság')).toBeInTheDocument()
    expect(screen.getByText('Okmány típus')).toBeInTheDocument()
    expect(screen.getByText('Okmányszám')).toBeInTheDocument()
    expect(screen.getByText('Telefon')).toBeInTheDocument()
  })

  it('ügyfél száma megjelenítése', async () => {
    renderCustomerListPage()
    await waitFor(() => {
      expect(screen.getByText('Kiss János')).toBeInTheDocument()
      expect(screen.getByText('Nagy Péter')).toBeInTheDocument()
      expect(screen.getByText('Szabó Anna')).toBeInTheDocument()
      expect(screen.getByText('Kovács István')).toBeInTheDocument()
    })
    expect(screen.getByText('4 ügyfél')).toBeInTheDocument()
  })

  it('több névvel rendelkező ügyfél szűrése', async () => {
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Kiss János')).toBeInTheDocument())

    const user = userEvent.setup()
    const searchInput = screen.getByPlaceholderText(/Keresés név vagy okmányszám alapján/)
    await user.type(searchInput, 'Nagy')

    await waitFor(() => {
      expect(screen.getByText('Nagy Péter')).toBeInTheDocument()
      expect(screen.queryByText('Kiss János')).not.toBeInTheDocument()
    })
  })

  it('Átnézésre váró szűrő a pending-review endpointot hívja és badge-et jelenít meg', async () => {
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Kiss János')).toBeInTheDocument())

    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: 'Átnézésre váró' }))

    await waitFor(() => expect(mockGetPendingReview).toHaveBeenCalled())
    expect(await screen.findByText('Átnézendő Ügyfél')).toBeInTheDocument()
    expect(screen.getByText('Átnézésre vár')).toBeInTheDocument()
  })

  it('pending szűrő után az Összes aktív visszatölti az aktív ügyfeleket', async () => {
    renderCustomerListPage()
    await waitFor(() => expect(screen.getByText('Kiss János')).toBeInTheDocument())

    const user = userEvent.setup()
    await user.click(screen.getByRole('button', { name: 'Átnézésre váró' }))
    expect(await screen.findByText('Átnézendő Ügyfél')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: 'Összes aktív' }))

    await waitFor(() => expect(mockGetActive).toHaveBeenCalledTimes(2))
    expect(await screen.findByText('Kiss János')).toBeInTheDocument()
  })
})
