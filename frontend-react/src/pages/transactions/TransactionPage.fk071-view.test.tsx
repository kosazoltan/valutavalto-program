/**
 * FK-071 FR-4 — RED-fázis specifikációs teszt (implementáció nélkül, buknia kell).
 *
 * Given: bármely tranzakció sor a Tranzakciólistában.
 * When:  a pénztáros a 👁 (Megtekintés) gombra kattint — ami az App.tsx szerint a
 *        `/transactions/:id` route-ra navigál (a route eleme jelenleg a TransactionPage).
 * Then:  az adott tranzakció TÉNYLEGES adatai (deviza, összeg, árfolyam, dátum,
 *        bizonylatszám) jelennek meg read-only nézetben — nem üres, új tranzakció
 *        felviteli űrlap.
 *
 * Jelenlegi (bukó) viselkedés: a TransactionPage nem olvassa a :id paramétert
 * (nincs useParams), így a 👁 gomb egy üres, új felviteli űrlapot nyit.
 *
 * Szerződés, amit a teszt rögzít (review tárgya):
 *  - a `/transactions/:id` route-on megjelenő komponens a paraméterben kapott
 *    bizonylatszám/id alapján betölti a tranzakciót (transactionApi.getById), és
 *  - az adatokat megjeleníti (szövegként vagy read-only mezőértékként), és
 *  - NEM kínál mentést (nincs `tx-save-print` gomb).
 *
 * Megjegyzés: ha a GREEN-fázis külön nézet-komponenst vezet be és átköti a
 * route-ot, ennek a tesztnek a route-viselkedést kell követnie (a teszt route-on
 * keresztül renderel) — az import célpontja ekkor a route új eleme lesz; ez
 * spec-szintű döntés, a review-n rögzítendő.
 */
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import TransactionPage from './TransactionPage'
import type { Transaction } from '../../services/api/transactions'

const mocks = vi.hoisted(() => ({
  transactionApiBuy: vi.fn(),
  transactionApiSell: vi.fn(),
  transactionApiGetById: vi.fn(),
  apiPost: vi.fn(),
  apiGet: vi.fn(),
  toast: {
    success: vi.fn(),
    info: vi.fn(),
    warning: vi.fn(),
    error: vi.fn(),
  },
  saveAndSyncPendingBuySell: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  transactionApi: {
    buy: mocks.transactionApiBuy,
    sell: mocks.transactionApiSell,
    getById: mocks.transactionApiGetById,
  },
  receiptApi: {},
}))

vi.mock('../../services/api/client', () => ({
  api: {
    post: mocks.apiPost,
    get: mocks.apiGet,
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector?: (state: unknown) => unknown) => {
    const worker = {
      id: 7,
      workerCode: 'PENZTAR-7',
      firstName: 'Teszt',
      lastName: 'Pénztáros',
      fullName: 'Teszt Pénztáros',
      role: 'CASHIER',
      branchId: 'branch-1',
      branchCode: 'BUD-01',
      branchName: 'Budapest 01',
      companyId: 'company-1',
      companyCode: 'EBC',
      companyName: 'Exclusive Best Change Zrt.',
    }
    const state = { worker, user: worker }
    return typeof selector === 'function' ? selector(state) : state
  },
}))

vi.mock('../../components/auth/AmlApproverModal', () => ({
  default: () => null,
  toApprovalCustomer: (c: unknown) => c,
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

vi.mock('../../utils/electronTransactions', () => ({
  saveAndSyncPendingBuySell: mocks.saveAndSyncPendingBuySell,
}))

vi.mock('./hooks/useTransactionRates', () => ({
  useTransactionRates: () => ({
    currencyRates: [
      { id: '1', code: 'EUR', name: 'Euró', buyRate: 391.5, sellRate: 398.5, unit: 1 },
    ],
    rawExchangeRates: [
      {
        currencyId: 1,
        currencyCode: 'EUR',
        currencyName: 'Euró',
        baseBuyRate: 391.5,
        baseSellRate: 398.5,
        active: true,
        officialRate: 395,
      },
    ],
    electronQueueAvailable: false,
  }),
}))

vi.mock('./hooks/useIdentificationLevel', () => ({
  useIdentificationLevel: () => ({
    identificationLevel: 'SIMPLE',
    minimumLevel: 'SIMPLE',
    setIdentificationLevel: vi.fn(),
    requiresSourceVerification: false,
  }),
}))

vi.mock('./components/CurrencySelector', () => ({
  default: () => <div data-testid="currency-selector" />,
}))

vi.mock('./components/CustomerPanel', () => ({
  default: () => <div data-testid="customer-panel" />,
}))

const viewedTransaction: Transaction = {
  id: 9001,
  receiptNumber: 'E001000777',
  transactionType: 'SELL',
  status: 'COMPLETED',
  transactionDate: '2026-07-29',
  transactionTime: '09:30:00',
  currencyId: 4,
  currencyCode: 'EUR',
  currencyAmount: 350,
  exchangeRate: 398.5,
  hufAmount: 139475,
  roundedHufAmount: 139475,
  handlingFee: 0,
  discountAmount: 0,
  discountPercent: 0,
  customerName: 'Kiss János',
  printed: false,
  branchId: 'b1',
  workerId: 7,
  createdAt: '2026-07-29T09:30:00Z',
}

/**
 * Igaz, ha az érték a lapon LÁTHATÓ — akár szövegként, akár (read-only)
 * input-mezőértékként. A megjelenítés formátumát nem kényszeríti.
 */
function pageShows(fragment: string): boolean {
  if ((document.body.textContent ?? '').includes(fragment)) return true
  return Array.from(document.querySelectorAll('input, textarea')).some((el) =>
    ((el as HTMLInputElement).value ?? '').includes(fragment),
  )
}

function renderViewRoute(receiptNumber: string) {
  render(
    <MemoryRouter initialEntries={[`/transactions/${receiptNumber}`]}>
      <Routes>
        <Route path="/transactions/:id" element={<TransactionPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('FK-071 FR-4 — Megtekintés (👁): read-only tranzakció-nézet a /transactions/:id route-on', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.apiPost.mockResolvedValue({ data: { requiresApproval: false } })
    mocks.apiGet.mockResolvedValue({ data: {} })
    mocks.transactionApiGetById.mockResolvedValue(viewedTransaction)
  })

  it('FR-4: a :id paraméter alapján betölti a tranzakciót (nem üres űrlapot nyit)', async () => {
    renderViewRoute('E001000777')

    await waitFor(() => expect(mocks.transactionApiGetById).toHaveBeenCalledWith('E001000777'))
  })

  it('FR-4: a tranzakció tényleges adatai láthatók — deviza, összeg, árfolyam, dátum, bizonylatszám', async () => {
    renderViewRoute('E001000777')

    await waitFor(() => expect(mocks.transactionApiGetById).toHaveBeenCalled())

    await waitFor(() => {
      // bizonylatszám
      expect(pageShows('E001000777')).toBe(true)
      // deviza
      expect(pageShows('EUR')).toBe(true)
      // összeg (formátum-független: 350 mint rész-szöveg)
      expect(pageShows('350')).toBe(true)
      // árfolyam (398,5 vagy 398.5)
      expect(pageShows('398,5') || pageShows('398.5')).toBe(true)
      // dátum (ISO vagy magyar formátum)
      expect(pageShows('2026-07-29') || pageShows('2026. 07. 29')).toBe(true)
    })
  })

  it('FR-4: a nézet read-only — nincs mentés/rögzítés akció', async () => {
    renderViewRoute('E001000777')

    await waitFor(() => expect(mocks.transactionApiGetById).toHaveBeenCalled())

    expect(screen.queryByTestId('tx-save-print')).not.toBeInTheDocument()
  })

  // FK-071 HIGH-D utókövetés: a backend a scope-on kívüli bizonylatra 404-et ad
  // (létezés-maszkolás) — a nézetnek hibapanelt kell mutatnia, adatok nélkül.
  // A 403-as ág ugyanazt a hibapanel-utat futtatja (védekező eset, ha a backend
  // konvenció később változna).
  it('HIGH-D: 404-es válasz (más fiók bizonylata) → hibapanel, adatpanel nélkül', async () => {
    mocks.transactionApiGetById.mockRejectedValue(new Error('Request failed with status code 404'))

    renderViewRoute('E001000777')

    expect(await screen.findByText('Request failed with status code 404')).toBeInTheDocument()
    expect(screen.queryByTestId('tx-view-panel')).not.toBeInTheDocument()
    expect(screen.queryByTestId('tx-save-print')).not.toBeInTheDocument()
    expect(screen.getByTestId('tx-view-back')).toBeInTheDocument()
  })

  it('HIGH-D: 403-as válasz esetén ugyanaz a hibapanel-ág fut, mint 404-nél', async () => {
    mocks.transactionApiGetById.mockRejectedValue(new Error('Request failed with status code 403'))

    renderViewRoute('E001000777')

    expect(await screen.findByText('Request failed with status code 403')).toBeInTheDocument()
    expect(screen.queryByTestId('tx-view-panel')).not.toBeInTheDocument()
    expect(screen.getByTestId('tx-view-back')).toBeInTheDocument()
  })
})
