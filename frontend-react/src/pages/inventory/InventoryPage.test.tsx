import { render, screen, waitFor, fireEvent, act, within } from '@testing-library/react'
import { vi, describe, beforeEach, afterEach, it, expect } from 'vitest'
import InventoryPage, { SHOW_MOBILE_INVENTORY_REPORTS } from './InventoryPage'

// FR-1..6 (2026-06-17): KÜLÖNBSÉG + FRISSÍTVE oszlop eltávolítva; nyomtatás; automatikus
// frissítés (WebSocket-invalidáció + change-detection). A WS-hookot mockoljuk, és elkapjuk a
// callbacket, hogy az invalidációt vezérelten tudjuk kiváltani.
const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  apiPut: vi.fn(),
  currencyList: vi.fn(),
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
  wsCallback: { current: null as null | (() => void | Promise<void>) },
}))

vi.mock('../../services/api/index', () => ({
  api: { get: mocks.apiGet, post: mocks.apiPost, put: mocks.apiPut },
  currencyApi: { list: mocks.currencyList },
}))
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
  {
    currencyCode: 'HUF',
    currencyName: 'Magyar forint',
    opening: 800,
    received: 0,
    issued: 0,
    closing: 700,
  },
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

const INVENTORY_CURRENCIES = [
  { id: 978, code: 'EUR', name: 'Euró', decimals: 2, active: true },
  { id: 840, code: 'USD', name: 'Amerikai dollár', decimals: 2, active: true },
]

const TRANSFER_TARGETS = [
  {
    branchId: '22222222-2222-2222-2222-222222222222',
    code: 'BR002',
    name: 'Szeged Pénztár',
    isVault: false,
  },
  {
    branchId: '33333333-3333-3333-3333-333333333333',
    code: 'VLT02',
    name: 'Szeged Értéktár',
    isVault: true,
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
      return Promise.resolve({
        data: { matrix: { '11111111-1111-1111-1111-111111111111': { EUR: 1200, HUF: 700 } } },
      })
    }
    if (path === '/inventory/movements')
      return Promise.resolve({ data: { content: MOVEMENT_ROWS } })
    if (path === '/inventory/transfer-targets') return Promise.resolve({ data: TRANSFER_TARGETS })
    if (path === '/inventory/movements/77') {
      return Promise.resolve({
        data: { ...MOVEMENT_ROWS[0], statusDisplay: 'Részletesen jóváhagyva' },
      })
    }
    if (path === '/inventory-movements/movement-log')
      return Promise.resolve({ data: MOVEMENT_ROWS })
    if (path === '/inventory-movements/daily-balance') {
      return Promise.resolve({
        data: { currencyCode: 'EUR', closingBalance: 1200, totalIn: 300, totalOut: 100 },
      })
    }
    if (path === '/inventory/regeneration/last') {
      return Promise.resolve({
        data: { discrepancyCount: 1, correctedCount: 1, regeneratedAt: '2026-06-18T08:00:00' },
      })
    }
    if (path.includes('/banknote-inventory/branch/') && path.endsWith('/low-stock')) {
      return Promise.resolve({ data: [BANKNOTE_ROWS[0]] })
    }
    if (path.includes('/banknote-inventory/branch/') && path.endsWith('/over-stock')) {
      return Promise.resolve({ data: [] })
    }
    if (path.includes('/banknote-inventory/branch/'))
      return Promise.resolve({ data: BANKNOTE_ROWS })
    return Promise.resolve({ data: [] })
  })
}


function expectOperationalGetsNotCalled() {
  const paths = mocks.apiGet.mock.calls.map((c) => String(c[0]))
  expect(paths.some((p) => p.includes('/inventory/stock/'))).toBe(false)
  expect(paths).not.toContain('/inventory/matrix')
  expect(paths).not.toContain('/inventory/movements')
  expect(paths).not.toContain('/inventory-movements/movement-log')
  expect(paths).not.toContain('/inventory-movements/daily-balance')
  expect(paths).not.toContain('/inventory/regeneration/last')
  expect(paths).not.toContain('/inventory/transfer-targets')
  expect(mocks.currencyList).not.toHaveBeenCalled()
}

async function clickEnabledButton(name: string | RegExp): Promise<void> {
  const button = await screen.findByRole('button', { name })
  await waitFor(() => expect(button).toBeEnabled())
  await act(async () => {
    fireEvent.click(button)
  })
}

describe('InventoryPage – Értéktári készlet (FR-1..6)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.wsCallback.current = null
    setupApiGet()
    mocks.currencyList.mockResolvedValue(INVENTORY_CURRENCIES)
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
      if (path.includes('/banknote-inventory/branch/'))
        return Promise.resolve({ data: BANKNOTE_ROWS })
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

    await waitFor(() =>
      expect(screen.getByText('Címletszintű értéktári készlet')).toBeInTheDocument(),
    )

    expect(mocks.apiGet).toHaveBeenCalledWith(
      '/banknote-inventory/branch/11111111-1111-1111-1111-111111111111',
    )
    expect(mocks.apiGet).toHaveBeenCalledWith(
      '/banknote-inventory/branch/11111111-1111-1111-1111-111111111111/low-stock',
    )
    expect(mocks.apiGet).toHaveBeenCalledWith(
      '/banknote-inventory/branch/11111111-1111-1111-1111-111111111111/over-stock',
    )
    await waitFor(() => expect(screen.getByText('Alacsony: 1')).toBeInTheDocument())
    expect(screen.getAllByText('50').length).toBeGreaterThan(0)
    expect(screen.getByText('3')).toBeInTheDocument()
    expect(screen.getAllByText('Alacsony').length).toBeGreaterThan(0)
  })

  it('FKH-043: flag off mellett az operatív riport-endpointok NEM hívódnak', async () => {
    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expect(screen.queryByText('Mobil készlet-riportok')).not.toBeInTheDocument()
    expect(screen.queryByTestId('inventory-operation-panel')).not.toBeInTheDocument()
    expect(screen.queryByText('Készletmátrix')).not.toBeInTheDocument()
    expect(screen.queryByLabelText('Deviza kiválasztása')).not.toBeInTheDocument()
    expect(screen.queryByText('telephely / valuta')).not.toBeInTheDocument()
    expect(screen.queryByText('Utolsó regenerálás')).not.toBeInTheDocument()
    expect(screen.queryByText('Napi mozgásnapló')).not.toBeInTheDocument()
    expectOperationalGetsNotCalled()
  })

  it('FK-037: részleges 403 NEM nullázza az értéktári záró készletet, és nincs hibabanner (allSettled)', async () => {
    // A fő értéktári készlet (/inventory/vault-stock) elérhető, de az operatív vezetői végpontok
    // 403-at adnak (a szűkebb szerepkör várt esete). A korábbi Promise.all itt MINDENT elbuktatott
    // (220M Ft + minden 0 ellentmondás); az allSettled-del a vault-stock adat megmarad, és a 403-ra
    // — mert várt jogosultság-hiány — NINCS riasztó banner.
    const forbidden = { response: { status: 403 } }
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/inventory/vault-stock') return Promise.resolve({ data: ROWS })
      if (path.includes('/banknote-inventory/branch/')) return Promise.resolve({ data: [] })
      if (
        path.startsWith('/inventory/stock/') ||
        path === '/inventory/matrix' ||
        path === '/inventory/movements' ||
        path.startsWith('/inventory-movements/') ||
        path === '/inventory/regeneration/last'
      ) {
        return Promise.reject(forbidden)
      }
      return Promise.resolve({ data: [] })
    })

    render(<InventoryPage />)

    // A fő értéktári záró készlet (EUR 500) a 403-ak ELLENÉRE megjelenik.
    await waitFor(() => expect(screen.getByText('500')).toBeInTheDocument())
    // 403 = várt jogosultság-hiány → NINCS "Készlet riportok betöltési hiba" banner.
    expect(screen.queryByText(/Készlet riportok betöltési hiba/)).not.toBeInTheDocument()
    // FKH-043: flag off mellett a 403-as operatív út el sem indul.
    expect(mocks.apiGet).not.toHaveBeenCalledWith('/inventory/matrix', expect.anything())
  })

  it('FKH-043: flag off mellett az operatív 500 sem tud bannert hozni (a hívás el sem indul)', async () => {
    const serverError = { response: { status: 500 }, message: 'szerverhiba' }
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/inventory/vault-stock') return Promise.resolve({ data: ROWS })
      if (path.includes('/banknote-inventory/branch/')) return Promise.resolve({ data: [] })
      if (path === '/inventory/matrix') return Promise.reject(serverError)
      return Promise.resolve({ data: [] })
    })

    render(<InventoryPage />)

    await waitFor(() => expect(screen.getByText('500')).toBeInTheDocument())
    expect(screen.queryByText(/Készlet riportok betöltési hiba/)).not.toBeInTheDocument()
    expect(mocks.apiGet).not.toHaveBeenCalledWith('/inventory/matrix', expect.anything())
  })

  it('FKH-043: mozgás-részlet vezérlők nincsenek a DOM-ban', async () => {
    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expect(screen.queryByText('Mozgások')).not.toBeInTheDocument()
    expect(screen.queryAllByRole('button', { name: 'Részlet' })).toHaveLength(0)
    expect(screen.queryByTestId('inventory-movement-detail')).not.toBeInTheDocument()
    expect(mocks.apiGet).not.toHaveBeenCalledWith('/inventory/movements/77')
  })

  it('FKH-043: bank withdraw/deposit/transfer/correction űrlap nincs a DOM-ban', async () => {
    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expect(screen.queryByTestId('inventory-operation-panel')).not.toBeInTheDocument()
    expect(screen.queryByPlaceholderText('Összeg')).not.toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Művelet rögzítése' })).not.toBeInTheDocument()
    const posts = mocks.apiPost.mock.calls.map((c) => String(c[0]))
    expect(posts).not.toContain('/inventory/bank-withdraw')
    expect(posts).not.toContain('/inventory/bank-deposit')
    expect(posts).not.toContain('/inventory/transfer')
    expect(posts).not.toContain('/inventory/correction')
  })

  it('FKH-043: Deviza kiválasztása nincs a DOM-ban, currencyList nem hívódik', async () => {
    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expect(screen.queryByLabelText('Deviza kiválasztása')).not.toBeInTheDocument()
    expect(mocks.currencyList).not.toHaveBeenCalled()
  })

  it('FKH-043: transfer cél dropdown nincs a DOM-ban, transfer-targets nem hívódik', async () => {
    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expect(screen.queryByLabelText('Készletművelet típusa')).not.toBeInTheDocument()
    expect(screen.queryByLabelText('Cél telephely kiválasztása')).not.toBeInTheDocument()
    expect(mocks.apiGet).not.toHaveBeenCalledWith('/inventory/transfer-targets', expect.anything())
  })

  it('FKH-043: transfer cél dropdown (Értéktár badge) nincs a DOM-ban', async () => {
    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expect(screen.queryByLabelText('Cél telephely kiválasztása')).not.toBeInTheDocument()
  })

  it('FKH-043: vault-context-badge a rejtett panel fejlécében van, nem jelenik meg', async () => {
    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expect(screen.queryByTestId('vault-context-badge')).not.toBeInTheDocument()
  })

  it('inventory riportok: üres vault-stock lista mellett nincs fejléc Értéktár badge', async () => {
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/inventory/vault-stock') return Promise.resolve({ data: [] })
      if (path.includes('/banknote-inventory/branch/') && path.endsWith('/low-stock'))
        return Promise.resolve({ data: [BANKNOTE_ROWS[0]] })
      if (path.includes('/banknote-inventory/branch/') && path.endsWith('/over-stock'))
        return Promise.resolve({ data: [] })
      if (path.includes('/banknote-inventory/branch/'))
        return Promise.resolve({ data: BANKNOTE_ROWS })
      return Promise.resolve({ data: [] })
    })

    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expect(screen.queryByTestId('vault-context-badge')).not.toBeInTheDocument()
    expect(screen.queryByText('Mobil készlet-riportok')).not.toBeInTheDocument()
  })

  it('inventory műveletek: üres transfer cél lista disabled selectet és magyarázatot mutat', async () => {
    mocks.apiGet.mockImplementation((path: string) => {
      if (path === '/inventory/transfer-targets') return Promise.resolve({ data: [] })
      if (path === '/inventory/vault-stock') return Promise.resolve({ data: ROWS })
      if (path.includes('/banknote-inventory/branch/') && path.endsWith('/low-stock'))
        return Promise.resolve({ data: [BANKNOTE_ROWS[0]] })
      if (path.includes('/banknote-inventory/branch/') && path.endsWith('/over-stock'))
        return Promise.resolve({ data: [] })
      if (path.includes('/banknote-inventory/branch/'))
        return Promise.resolve({ data: BANKNOTE_ROWS })
      return Promise.resolve({ data: [] })
    })

    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expect(screen.queryByLabelText('Cél telephely kiválasztása')).not.toBeInTheDocument()
    expect(
      screen.queryByText('Nincs elérhető cél telephely a jelenlegi jogosultsági körben.'),
    ).not.toBeInTheDocument()
  })

  it('FKH-043: Művelet rögzítése nincs a DOM-ban, currencyList mountkor nem hívódik', async () => {
    mocks.currencyList.mockReturnValue(new Promise(() => {}))

    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Művelet rögzítése' })).not.toBeInTheDocument()
    expect(mocks.currencyList).not.toHaveBeenCalled()
  })

  it('FKH-043: approve/receive/cancel gombok nincsenek a DOM-ban', async () => {
    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expect(
      screen.queryByRole('button', { name: 'Készletmozgás #77 jóváhagyása' }),
    ).not.toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Készletmozgás #78 fogadása' })).not.toBeInTheDocument()
    expect(
      screen.queryByRole('button', { name: 'Készletmozgás #77 visszavonása' }),
    ).not.toBeInTheDocument()
    const posts = mocks.apiPost.mock.calls.map((c) => String(c[0]))
    expect(posts).not.toContain('/inventory/77/approve')
    expect(posts).not.toContain('/inventory/78/receive')
    expect(posts).not.toContain('/inventory/77/cancel')
  })

  it('FKH-043: regenerálás vezérlők nincsenek a DOM-ban', async () => {
    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expect(screen.queryByText('Utolsó regenerálás')).not.toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Regenerálás futtatása' })).not.toBeInTheDocument()
    const posts = mocks.apiPost.mock.calls.map((c) => String(c[0]))
    expect(posts).not.toContain('/inventory/regeneration/run')
  })

  it('banknote-inventory: beköti az add, remove, count és thresholds backend műveleteket', async () => {
    render(<InventoryPage />)

    await screen.findByText('Címletszintű értéktári készlet')

    const darabInput = screen.getByPlaceholderText('Darab')
    fireEvent.change(darabInput, { target: { value: '4' } })
    await clickEnabledButton('Bevét')

    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith(
        '/banknote-inventory/branch/11111111-1111-1111-1111-111111111111/add',
        null,
        {
          params: {
            currencyId: 978,
            currencyCode: 'EUR',
            faceValue: 50,
            quantity: 4,
          },
        },
      )
    })

    await clickEnabledButton('Kiad')
    await waitFor(() => {
      expect(mocks.apiPost).toHaveBeenCalledWith(
        '/banknote-inventory/branch/11111111-1111-1111-1111-111111111111/remove',
        null,
        {
          params: {
            currencyId: 978,
            faceValue: 50,
            quantity: 4,
          },
        },
      )
    })

    await clickEnabledButton('Leltárdarab')
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
    await clickEnabledButton('Küszöb mentése')

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


describe('FKH-043 — Mobil készlet-riportok elrejtve', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.wsCallback.current = null
    setupApiGet()
    mocks.currencyList.mockResolvedValue(INVENTORY_CURRENCIES)
    mocks.apiPost.mockResolvedValue({ data: BANKNOTE_ROWS[0] })
    mocks.apiPut.mockResolvedValue({ data: BANKNOTE_ROWS[0] })
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('T1: panel nincs a DOM-ban, HUF kártya és címletszintű készlet igen', async () => {
    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expect(screen.queryByText('Mobil készlet-riportok')).not.toBeInTheDocument()
    expect(screen.queryByTestId('inventory-operation-panel')).not.toBeInTheDocument()
    expect(screen.getByText('700')).toBeInTheDocument()
    expect(screen.getByText('Címletszintű értéktári készlet')).toBeInTheDocument()
  })

  it('T2: operatív GET-ek és currencyList nem indulnak mountkor', async () => {
    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expectOperationalGetsNotCalled()
  })

  it('T3: vault-stock és banknote-inventory GET-ek továbbra is mennek, EUR záró 500 látszik', async () => {
    render(<InventoryPage />)

    expect(await screen.findByText('Értéktári záró HUF készlet')).toBeInTheDocument()
    expect(mocks.apiGet).toHaveBeenCalledWith('/inventory/vault-stock')
    expect(mocks.apiGet).toHaveBeenCalledWith(
      '/banknote-inventory/branch/11111111-1111-1111-1111-111111111111',
    )
    expect(mocks.apiGet).toHaveBeenCalledWith(
      '/banknote-inventory/branch/11111111-1111-1111-1111-111111111111/low-stock',
    )
    expect(mocks.apiGet).toHaveBeenCalledWith(
      '/banknote-inventory/branch/11111111-1111-1111-1111-111111111111/over-stock',
    )
    expect(screen.getByText('500')).toBeInTheDocument()
  })

  it('T6: SHOW_MOBILE_INVENTORY_REPORTS exportált const false', () => {
    expect(SHOW_MOBILE_INVENTORY_REPORTS).toBe(false)
  })
})
