import { render, screen, waitFor, fireEvent, act } from '@testing-library/react'
import { vi, describe, beforeEach, afterEach, it, expect } from 'vitest'
import InventoryPage from './InventoryPage'

// FR-1..6 (2026-06-17): KÜLÖNBSÉG + FRISSÍTVE oszlop eltávolítva; nyomtatás; automatikus
// frissítés (WebSocket-invalidáció + change-detection). A WS-hookot mockoljuk, és elkapjuk a
// callbacket, hogy az invalidációt vezérelten tudjuk kiváltani.
const mocks = vi.hoisted(() => ({
  apiGet: vi.fn(),
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
  wsCallback: { current: null as null | (() => void | Promise<void>) },
}))

vi.mock('../../services/api/index', () => ({ api: { get: mocks.apiGet } }))
vi.mock('../../utils/logger', () => ({ logger: mocks.logger }))
vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (s: unknown) => unknown) =>
    selector({
      worker: { branchName: 'Szekszárd Értéktár', branchCode: 'SZEK', companyId: 'c-1' },
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

describe('InventoryPage – Értéktári készlet (FR-1..6)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.wsCallback.current = null
    mocks.apiGet.mockResolvedValue({ data: ROWS })
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('FR-1/FR-2: a KÜLÖNBSÉG és FRISSÍTVE oszlop NEM jelenik meg; pontosan 6 oszlop van', async () => {
    render(<InventoryPage />)
    await waitFor(() => expect(screen.getByText('HUF')).toBeInTheDocument())

    // A két eltávolított oszlopfejléc nem szerepel.
    expect(screen.queryByText('Különbség')).not.toBeInTheDocument()
    expect(screen.queryByText('Frissítve')).not.toBeInTheDocument()

    // A megmaradó 6 oszlop fejléce látható, és pontosan 6 columnheader van.
    const headers = screen.getAllByRole('columnheader')
    expect(headers).toHaveLength(6)
    expect(screen.getByText('Nyitókészlet')).toBeInTheDocument()
    expect(screen.getByText('Zárókészlet')).toBeInTheDocument()
  })

  it('FR-6: a "Nyomtatás" gomb meghívja a window.print-et', async () => {
    const printSpy = vi.spyOn(window, 'print').mockImplementation(() => {})
    render(<InventoryPage />)
    await waitFor(() => expect(screen.getByText('HUF')).toBeInTheDocument())

    fireEvent.click(screen.getByRole('button', { name: /Nyomtatás/i }))
    expect(printSpy).toHaveBeenCalledTimes(1)
  })

  it('FR-3: WS-invalidációra a megVÁLTOZOTT értéktári adat automatikusan frissül', async () => {
    render(<InventoryPage />)
    await waitFor(() => expect(screen.getByText('500')).toBeInTheDocument())

    // Háttér-szinkron: az EUR zárókészlet 500 → 650 változik.
    mocks.apiGet.mockResolvedValue({
      data: [ROWS[0], { ...ROWS[1], closing: 650 }],
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
})
