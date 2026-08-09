/**
 * FK-071 — Offline szinkron-hiba láthatósága — RED-fázis specifikációs tesztek
 * (implementáció nélkül; a jelenlegi kód mellett bukniuk kell).
 *
 * Lefedett követelmények:
 *  - FR-2:  a "Feltöltés hibás" sorban a ténylegesen tárolt (FR-6 szerint szűrt)
 *           szerver-üzenet látszik, nem csak a badge-felirat.
 *  - FR-3:  "Újraküldés" gomb a "Feltöltés hibás" / "Szinkronra vár" (PENDING)
 *           sorokon; siker → hibaüzenet eltűnik; hiba → új üzenet frissül.
 *  - FR-5:  a kísérlet-történet (belső napló) NEM jelenik meg a UI-ban (guard).
 *  - FR-6:  PII-mintázat (e-mail, telefonszám) maszkolva/eltávolítva jelenik meg,
 *           a lényegi tartalom megmarad.
 *  - NFR-1: hálózat nélkül az Újraküldés nem próbálkozik csendben — explicit jelzés.
 *  - NFR-3: az újraküldés aszinkron; a lista nem fagy le várakozás közben.
 *
 * A tesztek által RÖGZÍTETT szerződés (review tárgya a GREEN-fázis előtt):
 *  - data-testid `retry-tx-${tx.id}`: Újraküldés gomb a PENDING sorokon
 *    (tx.id a megjelenített, negatív pending-azonosító: -(1_000_000 + lokális id)).
 *  - data-testid `sync-error-detail-${tx.id}`: a szűrt szerver-üzenetet hordozó
 *    elem (látható szöveg vagy title/aria-label tooltip formában).
 *  - IPC-szerződés: window.electronAPI.retryPendingTransaction(lokálisId) →
 *    Promise<{ success: boolean; error?: string | null }>, és sikeres/sikertelen
 *    újraküldés után a lista frissül (új fetch a pending sorokra).
 *  - Offline állapot: a meglévő useOnlineStatus hook (Fázis 0/C) alapján a gomb
 *    letiltva + magyarázó title (a repo v2.3.36 disabled+tooltip mintája szerint).
 */
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, afterEach, it, expect } from 'vitest'
import TransactionListPage from './TransactionListPage'
import type { PagedResponse } from '../../services/api/client'
import type { Transaction } from '../../services/api/transactions'

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  transactionApiList: vi.fn(),
  transactionApiGetDaily: vi.fn(),
  toastError: vi.fn(),
  toastSuccess: vi.fn(),
  onlineStatus: {
    isOnline: true,
    isNetworkOnline: true,
    isBackendReachable: true,
    lastCheckedAt: null as Date | null,
  },
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mocks.navigate,
  }
})

vi.mock('../../services/api/transactions', async () => {
  const actual = await vi.importActual<typeof import('../../services/api/transactions')>(
    '../../services/api/transactions',
  )
  return {
    ...actual,
    transactionApi: {
      ...actual.transactionApi,
      list: mocks.transactionApiList,
      getDaily: mocks.transactionApiGetDaily,
    },
  }
})

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    error: mocks.toastError,
    success: mocks.toastSuccess,
  },
}))

// FK-071 NFR-1 szerződés: a meglévő useOnlineStatus hook az offline-detektálás
// forrása (Fázis 0/C). A mock mindkét irányba állítható.
vi.mock('../../hooks/useOnlineStatus', () => ({
  useOnlineStatus: () => mocks.onlineStatus,
}))

const PENDING_TX_ID_OFFSET = 1_000_000
const displayId = (localId: number) => -(PENDING_TX_ID_OFFSET + localId)

type PendingRow = {
  id: number
  type: string
  currency_code: string
  foreign_amount: number
  huf_amount: number
  rounded_huf_amount: number
  rate: number
  handling_fee: number | null
  discount_percent: number | null
  customer_name: string | null
  local_reference_number: string
  idempotency_key: string
  created_at: string
  synced: number
  sync_error?: string | null
  sync_attempts?: number | null
  last_attempt_at?: string | null
  // FR-5 belső napló — a UI-nak NEM szabad megjelenítenie (guard-teszt).
  sync_attempt_history?: string | null
}

function makePendingRow(localId: number, overrides: Partial<PendingRow> = {}): PendingRow {
  return {
    id: localId,
    type: 'BUY',
    currency_code: 'EUR',
    foreign_amount: 120,
    huf_amount: 48000,
    rounded_huf_amount: 48000,
    rate: 400,
    handling_fee: null,
    discount_percent: null,
    customer_name: null,
    local_reference_number: `V0350000${localId}`,
    idempotency_key: `ikey-${localId}`,
    // FKH-031 NFR-1: a datum RELATIV, nem fix. Egy beegetett '2026-07-29' fixture
    // az ido mulasaval atlepte a 7 napos automatikus retry-ablakot, es a sor
    // felirata jogosan valtott "Kezi beavatkozas kell"-re — a teszt szandeka
    // viszont a FRISS hibas tetel. A relativ datum ezt idofuggetlenul rogziti.
    created_at: new Date(Date.now() - 24 * 60 * 60 * 1000)
      .toISOString()
      .replace('T', ' ')
      .slice(0, 19),
    synced: 0,
    ...overrides,
  }
}

const serverTransaction: Transaction = {
  id: 1,
  receiptNumber: 'E001000001',
  transactionType: 'BUY',
  status: 'COMPLETED',
  transactionDate: '2026-07-29',
  transactionTime: '09:00:00',
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
  createdAt: '2026-07-29T09:00:00Z',
}

const serverPage: PagedResponse<Transaction> = {
  content: [serverTransaction],
  totalElements: 1,
  totalPages: 1,
  size: 25,
  number: 0,
}

const electronApiMocks = {
  getPendingTransactions: vi.fn<() => Promise<PendingRow[]>>(),
  getPendingConversions: vi.fn(async () => [] as never[]),
  retryPendingTransaction:
    vi.fn<(localId: number) => Promise<{ success: boolean; error?: string | null }>>(),
}

/** A megjelenített hibaüzenet-részlet teljes hozzáférhető szövege (látható + tooltip). */
function detailTextOf(element: HTMLElement): string {
  return [
    element.textContent ?? '',
    element.getAttribute('title') ?? '',
    element.getAttribute('aria-label') ?? '',
  ].join(' ')
}

function renderPage() {
  render(
    <MemoryRouter>
      <TransactionListPage />
    </MemoryRouter>,
  )
}

describe('FK-071 — TransactionListPage offline szinkron-hiba láthatóság', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.onlineStatus.isOnline = true
    mocks.onlineStatus.isNetworkOnline = true
    mocks.onlineStatus.isBackendReachable = true
    mocks.transactionApiList.mockResolvedValue(serverPage)
    mocks.transactionApiGetDaily.mockResolvedValue([serverTransaction])
    electronApiMocks.getPendingTransactions.mockResolvedValue([])
    electronApiMocks.retryPendingTransaction.mockResolvedValue({ success: true })
    ;(window as unknown as { electronAPI?: unknown }).electronAPI = electronApiMocks
  })

  afterEach(() => {
    delete (window as unknown as { electronAPI?: unknown }).electronAPI
  })

  // ─────────────────────────────────────────────────────────────────────────
  // FR-2 — a tárolt szerver-üzenet látható, nem csak a "Feltöltés hibás" felirat
  // ─────────────────────────────────────────────────────────────────────────
  it('FR-2: a "Feltöltés hibás" sor a ténylegesen tárolt szerver-üzenetet is mutatja', async () => {
    const row = makePendingRow(42, {
      sync_error: 'HTTP 400 — Ügyfél neve kötelező 100000 Ft feletti tranzakcióhoz devizavételnél',
    })
    electronApiMocks.getPendingTransactions.mockResolvedValue([row])

    renderPage()

    expect(await screen.findByText('Feltöltés hibás')).toBeInTheDocument()

    const detail = screen.getByTestId(`sync-error-detail-${displayId(42)}`)
    expect(detailTextOf(detail)).toContain('Ügyfél neve kötelező')
  })

  // ─────────────────────────────────────────────────────────────────────────
  // FKH-031 NFR-1 — a 7 napos automatikus retry-ablak lejárta
  // ─────────────────────────────────────────────────────────────────────────
  it('FKH-031 NFR-1: 7 napnál régebbi hibás tétel "Kézi beavatkozás kell" jelzést kap', async () => {
    // A sync-engine (business-retry.ts) ekkor már véglegesen visszatartja a tételt,
    // ezért a listán is meg kell különböztetni a "majd újrapróbálja" állapottól —
    // különben a pénztáros azt hiszi, a rendszer még dolgozik rajta.
    const row = makePendingRow(60, {
      sync_error: 'HTTP 422 — Lejárt árfolyam',
      created_at: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000)
        .toISOString()
        .replace('T', ' ')
        .slice(0, 19),
    })
    electronApiMocks.getPendingTransactions.mockResolvedValue([row])

    renderPage()

    expect(await screen.findByText('Kézi beavatkozás kell')).toBeInTheDocument()
    expect(screen.queryByText('Feltöltés hibás')).not.toBeInTheDocument()
  })

  it('FKH-031 NFR-1: friss hibás tétel marad a "Feltöltés hibás" (automatikus retry) jelzésen', async () => {
    const row = makePendingRow(61, { sync_error: 'HTTP 422 — Lejárt árfolyam' })
    electronApiMocks.getPendingTransactions.mockResolvedValue([row])

    renderPage()

    expect(await screen.findByText('Feltöltés hibás')).toBeInTheDocument()
    expect(screen.queryByText('Kézi beavatkozás kell')).not.toBeInTheDocument()
  })

  // ─────────────────────────────────────────────────────────────────────────
  // FR-6 — PII-szűrés a megjelenített hibaüzenetben
  // ─────────────────────────────────────────────────────────────────────────
  it('FR-6: e-mail-címet tartalmazó szerver-üzenet maszkolva jelenik meg, a lényegi tartalom megmarad', async () => {
    // Valós backend-minta alapján (IncomeSourceDocController: "Érvénytelen címzett email: " + email)
    const row = makePendingRow(43, {
      sync_error: 'HTTP 400 — Érvénytelen címzett email: kovacs.bela@example.com',
    })
    electronApiMocks.getPendingTransactions.mockResolvedValue([row])

    renderPage()

    expect(await screen.findByText('Feltöltés hibás')).toBeInTheDocument()
    const detail = screen.getByTestId(`sync-error-detail-${displayId(43)}`)
    const text = detailTextOf(detail)

    // A lényegi tartalom megmarad…
    expect(text).toContain('Érvénytelen címzett email')
    // …de a PII (e-mail-cím) nem jelenhet meg nyersen.
    expect(text).not.toContain('kovacs.bela@example.com')
  })

  it('FR-6: telefonszám-mintázatú rész maszkolva jelenik meg (konzervatív feltételezett minta)', async () => {
    // Fázis 0/E: telefonszámos VALÓS hibaüzenet-minta nem került elő a backendben;
    // konzervatív, ésszerű feltételezett mintát rögzítünk (magyar mobilformátum).
    const row = makePendingRow(44, {
      sync_error: 'HTTP 400 — Ügyfél telefonszám formátum hibás: +36 20 123 4567',
    })
    electronApiMocks.getPendingTransactions.mockResolvedValue([row])

    renderPage()

    expect(await screen.findByText('Feltöltés hibás')).toBeInTheDocument()
    const detail = screen.getByTestId(`sync-error-detail-${displayId(44)}`)
    const text = detailTextOf(detail)

    expect(text).toContain('telefonszám formátum hibás')
    expect(text).not.toContain('+36 20 123 4567')
  })

  // ─────────────────────────────────────────────────────────────────────────
  // FR-3 — Újraküldés gomb: siker és hiba útvonal
  // ─────────────────────────────────────────────────────────────────────────
  it('FR-3: "Szinkronra vár" (hiba nélküli PENDING) soron is van Újraküldés gomb', async () => {
    const row = makePendingRow(50) // sync_error nélkül — "Szinkronra vár" (FK-071 Döntés 2 felirat)
    electronApiMocks.getPendingTransactions.mockResolvedValue([row])

    renderPage()

    expect(await screen.findByText('Szinkronra vár')).toBeInTheDocument()
    expect(screen.getByTestId(`retry-tx-${displayId(50)}`)).toBeInTheDocument()
  })

  it('Döntés 2 kiegészítés: Electron-módban a COMPLETED sor felirata "Feltöltve"', async () => {
    // Ebben a fájlban a window.electronAPI mock aktív (Electron-mód), így a
    // szerver-oldali COMPLETED sor "Feltöltve" feliratot kap. A web-módú ágat
    // ("Teljesítve" marad) a TransactionListPage.test.tsx fedi, ahol nincs
    // electronAPI.
    renderPage()

    expect(await screen.findByText('E001000001')).toBeInTheDocument()
    expect(screen.getByText('Feltöltve')).toBeInTheDocument()
    expect(screen.queryByText('Teljesítve')).not.toBeInTheDocument()
  })

  it('FR-3: sikeres újraküldés — a retry a lokális tétel-azonosítóval hívódik, a hibaüzenet eltűnik', async () => {
    const failedRow = makePendingRow(42, {
      sync_error: 'HTTP 400 — Ügyfél neve kötelező 100000 Ft feletti tranzakcióhoz',
    })
    // 1. betöltés: hibás pending sor; újraküldés utáni frissítés: már nincs pending sor.
    electronApiMocks.getPendingTransactions.mockResolvedValueOnce([failedRow]).mockResolvedValue([])
    electronApiMocks.retryPendingTransaction.mockResolvedValue({ success: true })

    renderPage()
    expect(await screen.findByText('Feltöltés hibás')).toBeInTheDocument()

    const user = userEvent.setup()
    await user.click(screen.getByTestId(`retry-tx-${displayId(42)}`))

    // Azonnali, explicit újrapróbálkozás ugyanarra a tételre (lokális SQLite id-val)…
    await waitFor(() => expect(electronApiMocks.retryPendingTransaction).toHaveBeenCalledWith(42))

    // …siker után a sor frissül, és a hibaüzenet eltűnik.
    await waitFor(() => expect(screen.queryByText('Feltöltés hibás')).not.toBeInTheDocument())
  })

  it('FR-3: sikertelen újraküldés — a sor "Feltöltés hibás" marad, de az ÚJ hibaüzenet jelenik meg', async () => {
    const oldError = 'HTTP 400 — Ügyfél neve kötelező 100000 Ft feletti tranzakcióhoz'
    const newError = 'HTTP 422 — Fedezethiány: a pénztárban nincs elegendő EUR készlet'
    const failedRow = makePendingRow(42, { sync_error: oldError })
    const refreshedRow = makePendingRow(42, { sync_error: newError, sync_attempts: 2 })

    electronApiMocks.getPendingTransactions
      .mockResolvedValueOnce([failedRow])
      .mockResolvedValue([refreshedRow])
    electronApiMocks.retryPendingTransaction.mockResolvedValue({
      success: false,
      error: newError,
    })

    renderPage()
    expect(await screen.findByText('Feltöltés hibás')).toBeInTheDocument()

    const user = userEvent.setup()
    await user.click(screen.getByTestId(`retry-tx-${displayId(42)}`))

    await waitFor(() => expect(electronApiMocks.retryPendingTransaction).toHaveBeenCalledWith(42))

    // A sor hibás marad…
    expect(await screen.findByText('Feltöltés hibás')).toBeInTheDocument()
    // …és a részletben már az ÚJ hibaüzenet szerepel.
    await waitFor(() => {
      const detail = screen.getByTestId(`sync-error-detail-${displayId(42)}`)
      expect(detailTextOf(detail)).toContain('Fedezethiány')
      expect(detailTextOf(detail)).not.toContain('Ügyfél neve kötelező')
    })
  })

  // ─────────────────────────────────────────────────────────────────────────
  // NFR-1 — offline állapotban nincs csendes próbálkozás
  // ─────────────────────────────────────────────────────────────────────────
  it('NFR-1: hálózat nélkül az Újraküldés gomb letiltott, magyarázó jelzéssel — nem hív retry-t', async () => {
    mocks.onlineStatus.isOnline = false
    mocks.onlineStatus.isNetworkOnline = false
    mocks.onlineStatus.isBackendReachable = false

    const row = makePendingRow(42, {
      sync_error: 'HTTP 400 — Ügyfél neve kötelező 100000 Ft feletti tranzakcióhoz',
    })
    electronApiMocks.getPendingTransactions.mockResolvedValue([row])

    renderPage()
    expect(await screen.findByText('Feltöltés hibás')).toBeInTheDocument()

    const retryButton = screen.getByTestId(`retry-tx-${displayId(42)}`)

    // Explicit jelzés: letiltott gomb + magyarázó tooltip (repo-minta: disabled + title).
    expect(retryButton).toBeDisabled()
    expect(retryButton.getAttribute('title') ?? '').toMatch(/offline|kapcsolat|hálózat/i)

    // Csendes próbálkozás tilos.
    const user = userEvent.setup()
    await user.click(retryButton).catch(() => undefined)
    expect(electronApiMocks.retryPendingTransaction).not.toHaveBeenCalled()
  })

  // ─────────────────────────────────────────────────────────────────────────
  // NFR-3 — aszinkron újraküldés, a lista nem fagy le
  // ─────────────────────────────────────────────────────────────────────────
  it('NFR-3: folyamatban lévő újraküldés alatt a gomb foglalt állapotú, a lista többi része él', async () => {
    const row = makePendingRow(42, {
      sync_error: 'HTTP 400 — Ügyfél neve kötelező 100000 Ft feletti tranzakcióhoz',
    })
    electronApiMocks.getPendingTransactions.mockResolvedValue([row])
    // Soha nem teljesülő promise: a kísérlet "folyamatban" marad.
    electronApiMocks.retryPendingTransaction.mockImplementation(
      () => new Promise<{ success: boolean }>(() => undefined),
    )

    renderPage()
    expect(await screen.findByText('Feltöltés hibás')).toBeInTheDocument()

    const user = userEvent.setup()
    await user.click(screen.getByTestId(`retry-tx-${displayId(42)}`))

    // A gomb jelez, hogy folyamatban van (nem indítható duplán)…
    await waitFor(() => expect(screen.getByTestId(`retry-tx-${displayId(42)}`)).toBeDisabled())

    // …de a lista NEM fagy le: a szerver-tranzakció sora és a frissítés gomb él.
    expect(screen.getByText('E001000001')).toBeInTheDocument()
    expect(screen.getByText('Frissítés')).toBeEnabled()
  })

  // ─────────────────────────────────────────────────────────────────────────
  // FR-5 guard — a kísérlet-történet belső adat, a UI-n nem jelenhet meg
  // ─────────────────────────────────────────────────────────────────────────
  it('FR-5 guard: a kísérlet-történet (belső napló) tartalma nem jelenik meg a rendered DOM-ban', async () => {
    const historyMarker = 'FR5-BELSO-NAPLO-MARKER-2026-07-28T23:59:59'
    const row = makePendingRow(42, {
      sync_error: 'HTTP 400 — Ügyfél neve kötelező 100000 Ft feletti tranzakcióhoz',
      sync_attempts: 3,
      last_attempt_at: '2026-07-29T10:05:00.000Z',
      sync_attempt_history: JSON.stringify([
        { attemptedAt: '2026-07-28T23:59:59', outcome: 'ERROR', message: historyMarker },
      ]),
    })
    electronApiMocks.getPendingTransactions.mockResolvedValue([row])

    renderPage()
    expect(await screen.findByText('Feltöltés hibás')).toBeInTheDocument()

    // Sem látható szövegként…
    expect(document.body.textContent ?? '').not.toContain(historyMarker)
    // …sem tooltip/title formában nem szivároghat ki.
    const titled = Array.from(document.querySelectorAll('[title]'))
    for (const el of titled) {
      expect(el.getAttribute('title') ?? '').not.toContain(historyMarker)
    }
    // Dedikált történet-elem sem jelenhet meg.
    expect(screen.queryByTestId(`sync-attempt-history-${displayId(42)}`)).not.toBeInTheDocument()
  })
})
