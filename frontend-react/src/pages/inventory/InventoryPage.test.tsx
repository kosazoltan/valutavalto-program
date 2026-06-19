import { render, screen, waitFor, fireEvent, act, within } from '@testing-library/react'
import { vi, describe, beforeEach, afterEach, it, expect } from 'vitest'
import InventoryPage from './InventoryPage'

// FR-1..6 (2026-06-17): KÜLÖNBSÉG + FRISSÍTVE oszlop eltávolítva; nyomtatás; automatikus
// frissítés (WebSocket-invalidáció + change-detection). A WS-hookot mockoljuk, és elkapjuk a
// callbacket, hogy az invalidációt vezérelten tudjuk kiváltani.
const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  apiPut: vi.fn(),
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
  wsCallback: { current: null as null | (() => void | Promise<void>) },
}))

vi.mock('../../services/api/index', () => ({ api: { get: mocks.apiGet, post: mocks.apiPost, put: mocks.apiPut } }))
vi.mock('../../utils/logger', () => ({ logger: mocks.logger }))
vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (s: unknown) => unknown) =>
    selector({
      worker: {
        branchId: '11111111-1111-1111-1111-111111111111',
        branchName: 'Szekszárd Értéktár',
        branchCode: 'SZEK',
        workerCode: 'W001',
        companyId: 'c-1',
      },
      isAuthenticated: true,
      token: 'tok',
    }),
}))
vi.mock('../../hooks/useVaultStockUpdates', () => ({
  useVaultStockUpdates: (cb: () => void | Promise<void>) => {
    mocks.wsCallback.current = cb
  },
}))

// Szándékosan < 1000 és egyedi értékek (nincs ezres-szeparátor / kártya-ütközés): az EUR
// zárókészletre (500) mérünk, ami CSAK a tábla EUR-sorában jelenik meg (a HUF-összesítő kártya
// a HUF zárót — 700 — mutatja, nem az EUR-t).
const ROWS = [
  { currencyCode: 'HUF', currencyName: 'Magyar forint', opening: 800, received: 0, issued: 0, closing: 700 },
  { currencyCode: 'EUR', currencyName: 'Euró', opening: 300, received: 0, issued: 0, closing: 500 },
]

const BANKNOTE_ROWS = [
  {
    id: 1,
    currencyId: 978,
    currencyCode: 'EUR',
    faceValue: 50,
    quantity: 3,
    totalValue: 150,
    minQuantity: 5,
    maxQuantity: 100,
    lowStock: true,
    overStock: false,
  },
  {
    id: 2,
    currencyId: 348,
    currencyCode: 'HUF',
    faceValue: 10000,
    quantity: 10,
    totalValue: 100000,
    minQuantity: 1,
    maxQuantity: 50,
    lowStock: false,
    overStock: false,
  },
]

const BRANCH_STOCK_ROWS = [
  {
    branchId: '11111111-1111-1111-1111-111111111111',
    branchName: 'Szekszárd Értéktár',
    currencyId: 978,
    currencyCode: 'EUR',
    currencyName: 'Euró',
    currentBalance: 1200,
    openingBalance: 1000,
  },
]

const MOVEMENT_ROWS = [
  {
    id: 77,
    fromBranchName: 'Központ',
    toBranchName: 'Szekszárd Értéktár',
    currencyCode: 'EUR',
    amount: 300,
    movementTypeDisplay: 'Átadás',
    movementType: 'BRANCH_TRANSFER',
    status: 'PENDING',
    statusDisplay: 'Függőben',
  },
  {
    id: 78,
    fromBranchName: 'Központ',
    toBranchName: 'Szekszárd Értéktár',
    currencyCode: 'USD',
    amount: 400,
    movementTypeDisplay: 'Bankból kivét',
    movementType: 'BANK_WITHDRAW',
    status: 'IN_TRANSIT',
    statusDisplay: 'Szállítás alatt',
  },
]

function setupApiGet() {
  mocks.apiGet.mockImplementation((path: string) => {
    if (path === '/inventory/vault-stock') return Promise.resolve({ data: ROWS })
    if (path === '/inventory/stock/11111111-1111-1111-1111-111111111111') {
      return Promise.resolve({ data: BRANCH_STOCK_ROWS })
    }
    if (path === '/inventory/matrix') {
      return Promise.resolve({ data: { matrix: { '11111111-1111-1111-1111-111111111111': { EUR: 1200, HUF: 700 } } } })
    }
    if (path === '/inventory/movements') return Promise.resolve({ data: { content: MOVEMENT_ROWS } })
    if (path === '/inventory/movements/77') {
      return Promise.resolve({ data: { ...MOVEMENT_ROWS[0], statusDisplay: 'Részletesen jóváhagyva' } })
    }
    if (path === '/inventory-movements/movement-log') return Promise.resolve({ data: MOVEMENT_ROWS })
    if (path === '/inventory-movements/daily-balance') {
      return Promise.resolve({ data: { currencyCode: 'EUR', closingBalance: 1200, totalIn: 300, totalOut: 100 } })
    }
    if (path === '/inventory/regeneration/last') {
      return Promise.resolve({ data: { discrepancyCount: 1, correctedCount: 1, regeneratedAt: '2026-06-18T08:00:00' } })
    }
    if (path.includes('/banknote-inventory/branch/') && path.endsWith('/low-stock')) {
      return Promise.resolve({ data: [BANKNOTE_ROWS[0]] })
    }
    if (path.includes('/banknote-inventory/branch/') && path.endsWith('/over-stock')) {
      return Promise.resolve({ data: [] })
    }
    if (path.includes('/banknote-inventory/branch/')) return Promise.resolve({ data: BANKNOTE_ROWS })
    return Promise.resolve({ data: [] })
  })
}

describe('InventoryPage – Értéktári készlet (FR-1..6)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.wsCallback.current = null
    setupApiGet()
    mocks.apiPost.mockResolvedValue({ data: BANKNOTE_ROWS[0] })
    mocks.apiPut.mockResolvedValue({ data: BANKNOTE_ROWS[0] })
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('FR-1/FR-2: a KÜLÖNBSÉG és FRISSÍTVE oszlop NEM jelenik meg; pontosan 6 oszlop van', async () => {
    render(<InventoryPage />)
    await waitFor(() => expect(screen.getAllByText('HUF').length).toBeGreaterThan(0))

    // A két eltávolított oszlopfejléc nem szerepel.
    expect(screen.queryByText('Különbség')).not.toBeInTheDocument()
    expect(screen.queryByText('Frissítve')).not.toBeInTheDocument()

    // A megmaradó 6 oszlop az első, valutánkénti készlettáblában látható.
    const vaultStockTable = screen.getAllByRole('table').at(0)
    if (!vaultStockTable) throw new Error('Vault stock table not found')
    const headers = within(vaultStockTable).getAllByRole('columnheader')
    expect(headers).toHaveLength(6)
    expect(within(vaultStockTable).getByText('Nyitókészlet')).toBeInTheDocument()
    expect(within(vaultStockTable).getByText('Zárókészlet')).toBeInTheDocument()
  })

  it('FR-6: a "Nyomtatás" gomb meghívja a window.print-et', async () => {
    const printSpy = vi.spyOn(window, 'print').mockImplementation(() => {})
    render(<InventoryPage />)
    await waitFor(() => expect(screen.getAllByText('HUF').length).toBeGreaterThan(0))

    fireEvent.click(screen.getByRole('button', { name: /Nyomtatás/i }))
    expect(printSpy).toHaveBeenCalledTimes(1)
  })

  it('FR-3: WS-invalidációra a megVÁLTOZOTT értéktári adat automatikusan frissül', async () => {
    render(<InventoryPage />)
    await waitFor(() => expect(screen.getByText('500')).toBeInTheDocument())

    // Háttér-szinkron: az EUR zárókészlet 500 → 650 változik.
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/inventory/vault-stock') {
        return Promise.resolve({ data: [ROWS[0], { ...ROWS[1], closing: 650 }] })
      }
      if (path.includes('/banknote-inventory/branch/') && path.endsWith('/low-stock')) {
        return Promise.resolve({ data: [BANKNOTE_ROWS[0]] })
      }
      if (path.includes('/banknote-inventory/branch/') && path.endsWith('/over-stock')) {
        return Promise.resolve({ data: [] })
      }
      if (path.includes('/banknote-inventory/branch/')) return Promise.resolve({ data: BANKNOTE_ROWS })
      return Promise.resolve({ data: [] })
    })
    expect(mocks.wsCallback.current).toBeTypeOf('function')

    await act(async () => {
      await mocks.wsCallback.current?.()
    })

    await waitFor(() => expect(screen.getByText('650')).toBeInTheDocument())
    expect(screen.queryByText('500')).not.toBeInTheDocument()
  })

  it('FR-3: WS-invalidációra VÁLTOZATLAN adatnál a nézet nem cserélődik (change-detection)', async () => {
    render(<InventoryPage />)
    await waitFor(() => expect(screen.getByText('500')).toBeInTheDocument())

    // Más iroda mozgása: a scope-olt válasz változatlan (ugyanaz a ROWS) → nincs látható változás.
    await act(async () => {
      await mocks.wsCallback.current?.()
    })

    // Az EUR zárókészlet továbbra is 500 (nem tűnt el / nem cserélődött).
    expect(screen.getByText('500')).toBeInTheDocument()
    expect(screen.queryByText('650')).not.toBeInTheDocument()
  })

  it('banknote-inventory: a saját branch címletszintű készletét és alacsony jelzését megjeleníti', async () => {
    render(<InventoryPage />)

    await waitFor(() => expect(screen.getByText('Címletszintű értéktári készlet')).toBeInTheDocument())

    expect(mocks.apiGet).toHaveBeenCalledWith('/banknote-inventory/branch/11111111-1111-1111-1111-111111111111')
    expect(mocks.apiGet).toHaveBeenCalledWith('/banknote-inventory/branch/11111111-1111-1111-1111-111111111111/low-stock')
    expect(mocks.apiGet).toHaveBeenCalledWith('/banknote-inventory/branch/11111111-1111-1111-1111-111111111111/over-stock')
    await waitFor(() => expect(screen.getByText('Alacsony: 1')).toBeInTheDocument())
    expect(screen.getAllByText('50').length).toBeGreaterThan(0)
    expect(screen.getByText('3')).toBeInTheDocument()
    expect(screen.getAllByText('Alacsony').length).toBeGreaterThan(0)
  })

  it('inventory riportok: beköti a stock, matrix, movements, movement-log, daily-balance és regeneration read endpointokat', async () => {
    render(<InventoryPage />)

    await waitFor(() => expect(screen.getByText('Mobil készlet-riportok')).toBeInTheDocument())

    expect(mocks.apiGet).toHaveBeenCalledWith('/inventory/stock/11111111-1111-1111-1111-111111111111')
    expect(mocks.apiGet).toHaveBeenCalledWith('/inventory/matrix')
    expect(mocks.apiGet).toHaveBeenCalledWith('/inventory/movements', {
      params: {
        branchId: '11111111-1111-1111-1111-111111111111',
        size: 5,
        sort: 'createdAt,desc',
      },
    })
    expect(mocks.apiGet).toHaveBeenCalledWith('/inventory-movements/movement-log', {
      params: {
        branchId: '11111111-1111-1111-1111-111111111111',
        date: expect.any(String),
      },
    })
    expect(mocks.apiGet).toHaveBeenCalledWith('/inventory-movements/daily-balance', {
      params: {
        branchId: '11111111-1111-1111-1111-111111111111',
        date: expect.any(String),
      },
    })
    expect(mocks.apiGet).toHaveBeenCalledWith('/inventory/regeneration/last', {
      params: { branchId: '11111111-1111-1111-1111-111111111111' },
    })
    expect(screen.getByText('Készletmátrix')).toBeInTheDocument()
    expect(screen.getByTestId('inventory-operation-panel')).toBeInTheDocument()
    expect(screen.getByText('telephely / valuta')).toBeInTheDocument()
    expect(screen.getByText('Utolsó regenerálás')).toBeInTheDocument()
    expect(screen.getByText('Napi mozgásnapló')).toBeInTheDocument()
  })

  it('inventory mozgás részlet: a listából lekéri a /inventory/movements/{id} detail endpointot', async () => {
    render(<InventoryPage />)

    await waitFor(() => expect(screen.getByText('Mozgások')).toBeInTheDocument())
    fireEvent.click(screen.getAllByRole('button', { name: 'Részlet' })[0]!)

    await waitFor(() => {
      expect(mocks.apiGet).toHaveBeenCalledWith('/inventory/movements/77')
      expect(screen.getByTestId('inventory-movement-detail')).toHaveTextContent('Mozgás részlete #77')
      expect(screen.getByTestId('inventory-movement-detail')).toHaveTextContent('Részletesen jóváhagyva')
    })
  })

  it('inventory műveletek: beköti a bank withdraw, bank deposit, transfer és correction backend szerződéseket', async () => {
    render(<InventoryPage />)

    await waitFor(() => expect(screen.getByTestId('inventory-operation-panel')).toBeInTheDocument())

    fireEvent.change(screen.getByPlaceholderText('Összeg'), { target: { value: '250' } })
    fireEvent.change(screen.getByPlaceholderText('Opcionális'), { target: { value: 'Teszt bank kivét' } })
    fireEvent.click(screen.getByRole('button', { name: 'Művelet rögzítése' }))

    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/inventory/bank-withdraw', {
        branchId: '11111111-1111-1111-1111-111111111111',
        currencyId: 978,
        amount: 250,
        notes: 'Teszt bank kivét',
      })
    })

    fireEvent.change(screen.getByLabelText('Készletművelet típusa'), { target: { value: 'bankDeposit' } })
    fireEvent.change(screen.getByPlaceholderText('Összeg'), { target: { value: '125' } })
    fireEvent.click(screen.getByRole('button', { name: 'Művelet rögzítése' }))

    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/inventory/bank-deposit', {
        branchId: '11111111-1111-1111-1111-111111111111',
        currencyId: 978,
        amount: 125,
        notes: 'Teszt bank kivét',
      })
    })

    fireEvent.change(screen.getByLabelText('Készletművelet típusa'), { target: { value: 'transfer' } })
    fireEvent.change(screen.getByPlaceholderText('Csak átadásnál'), { target: { value: '22222222-2222-2222-2222-222222222222' } })
    fireEvent.change(screen.getByPlaceholderText('Összeg'), { target: { value: '75' } })
    fireEvent.click(screen.getByRole('button', { name: 'Művelet rögzítése' }))

    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/inventory/transfer', {
        fromBranchId: '11111111-1111-1111-1111-111111111111',
        toBranchId: '22222222-2222-2222-2222-222222222222',
        currencyId: 978,
        amount: 75,
        notes: 'Teszt bank kivét',
      })
    })

    fireEvent.change(screen.getByLabelText('Készletművelet típusa'), { target: { value: 'correction' } })
    fireEvent.change(screen.getByPlaceholderText('Új egyenleg'), { target: { value: '1000' } })
    fireEvent.change(screen.getByPlaceholderText('Kötelező indoklás'), { target: { value: 'Leltár korrekció' } })
    fireEvent.click(screen.getByRole('button', { name: 'Művelet rögzítése' }))

    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/inventory/correction', {
        branchId: '11111111-1111-1111-1111-111111111111',
        currencyId: 978,
        newAmount: 1000,
        reason: 'Leltár korrekció',
      })
    })
  })

  it('inventory mozgás státuszok: beköti az approve, receive és cancel workflow endpointokat', async () => {
    render(<InventoryPage />)

    await waitFor(() => expect(screen.getByText('Mozgások')).toBeInTheDocument())

    fireEvent.click(screen.getByRole('button', { name: 'Készletmozgás #77 jóváhagyása' }))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/inventory/77/approve')
    })

    fireEvent.click(screen.getByRole('button', { name: 'Készletmozgás #78 fogadása' }))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/inventory/78/receive', { receivedAmount: 400 })
    })

    fireEvent.click(screen.getByRole('button', { name: 'Készletmozgás #77 visszavonása' }))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/inventory/77/cancel')
    })
  })

  it('inventory regenerálás: beköti a /inventory/regeneration/run backend műveletet', async () => {
    mocks.apiPost.mockResolvedValueOnce({ data: { discrepancyCount: 2, correctedCount: 2 } })
    render(<InventoryPage />)

    await waitFor(() => expect(screen.getByText('Utolsó regenerálás')).toBeInTheDocument())
    fireEvent.click(screen.getByRole('button', { name: 'Regenerálás futtatása' }))

    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/inventory/regeneration/run', null, {
        params: { branchId: '11111111-1111-1111-1111-111111111111' },
      })
    })
  })

  it('banknote-inventory: beköti az add, remove, count és thresholds backend műveleteket', async () => {
    render(<InventoryPage />)

    await waitFor(() => expect(screen.getByText('Címletszintű értéktári készlet')).toBeInTheDocument())

    fireEvent.change(screen.getByPlaceholderText('Darab'), { target: { value: '4' } })
    fireEvent.click(screen.getByRole('button', { name: 'Bevét' }))

    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/banknote-inventory/branch/11111111-1111-1111-1111-111111111111/add', null, {
        params: {
          currencyId: 978,
          currencyCode: 'EUR',
          faceValue: 50,
          quantity: 4,
        },
      })
    })

    fireEvent.click(screen.getByRole('button', { name: 'Kiad' }))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/banknote-inventory/branch/11111111-1111-1111-1111-111111111111/remove', null, {
        params: {
          currencyId: 978,
          faceValue: 50,
          quantity: 4,
        },
      })
    })

    fireEvent.click(screen.getByRole('button', { name: 'Leltárdarab' }))
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith('/banknote-inventory/1/count', null, {
        params: {
          actualQuantity: 4,
          workerId: 'W001',
        },
      })
    })

    fireEvent.change(screen.getByPlaceholderText('Min.'), { target: { value: '2' } })
    fireEvent.change(screen.getByPlaceholderText('Max.'), { target: { value: '20' } })
    fireEvent.click(screen.getByRole('button', { name: 'Küszöb mentése' }))

    await waitFor(() => {
      expect(mocks.apiPut).toHaveBeenCalledWith('/banknote-inventory/1/thresholds', null, {
        params: {
          minQuantity: 2,
          maxQuantity: 20,
        },
      })
    })
  })
})
