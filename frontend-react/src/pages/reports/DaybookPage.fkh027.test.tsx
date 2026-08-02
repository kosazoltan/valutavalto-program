import { render, screen, fireEvent, waitFor, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, afterEach, describe, expect, it, vi } from 'vitest'
import DaybookPage from './DaybookPage'

// ─────────────────────────────────────────────────────────────────────────────
// FKH-027 — Naplókönyv nyomtatási kép (RED-fázis, 2026-08-02)
//
// ⛔ TEST-FREEZE (2026-08-02): ez a fájl a szerződés. A GREEN-fázisban TILOS
// bármely assertiont gyengíteni, tesztet törölni/skippelni a zöld eredményért.
// Spec: fejlesztesi-keres-ertektar-fkh027-naplokonyv-nyomtatasi-kep-v3.md
//
// A tesztek az ELVÁRT (még nem implementált) képernyős nyomtatási képet rögzítik:
//  - FR-1/2/3: Nyitó / Forgalom (Átadás+Átvétel) / Záró egyenleg dobozok,
//  - FR-4: cégfejléc (cégnév + fióknév + fiókcím) a lista fölött,
//  - FR-5: aláírás-sor ("Pénztáros aláírása" / "Ellenőrző aláírása"),
//  - FR-6: "Nyomtatás" gomb → window.print(), a gomb maga `no-print`,
//  - FR-7: dátumválasztó + "Lekérdezés" gomb `no-print` konténerben,
//  - FR-8: a régi "PDF" gomb és a dailyReportApi.downloadPdf hívás megszűnt,
//  - FR-9: a lista pontosan a backend sorait mutatja (KK-regresszió-őr),
//  - FR-10: sztornó-sor félkövér, SZÍN NÉLKÜLI "SZTORNÓ" felirattal, és a
//    bizonylatszám NEM csonkolódik (18 karakternél hosszabb esetben sem).
//
// Minta: TransferDocumentPage.tsx:204-206 (`no-print` + window.print()), a
// fejléc-tartalom forrása HufDaybookPdfService.java:93-107 (renderHeader).
// A globális @media print (index.css:310-343) változatlan — jsdom nem alkalmaz
// media query-t, ezért itt a `no-print` OSZTÁLY jelenlétét ellenőrizzük; a
// tényleges elrejtést a Playwright e2e (emulateMedia 'print') bizonyítja.
// ─────────────────────────────────────────────────────────────────────────────

const mocks = vi.hoisted(() => ({
  get: vi.fn(),
  downloadPdf: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  dailyReportApi: {
    get: mocks.get,
    downloadPdf: mocks.downloadPdf,
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: { worker: { branchId: string } }) => unknown) =>
    selector({ worker: { branchId: 'branch-1' } }),
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: { warning: vi.fn(), error: vi.fn(), success: vi.fn(), info: vi.fn() },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

/** 18 karakternél HOSSZABB bizonylatszám — a PDF-oldali truncate(…, 18) csapdája (FR-10). */
const LONG_RECEIPT = 'UF-2026-000000101'
const LONG_STORNO_RECEIPT = 'UF-2026-000000101-SZ' // 20 karakter

const DAYBOOK_FIXTURE = {
  branchId: 'branch-1',
  branchName: 'Szeged Értéktár',
  branchAddress: '6720 Szeged, Kárász utca 1.',
  date: '2026-07-01',
  rows: [
    {
      annualSequence: 2,
      receiptNumber: 'FF-000002',
      partnerCode: '076',
      timestamp: '09:15:00',
      atadasHuf: 250000,
      storno: false,
    },
    {
      annualSequence: 3,
      receiptNumber: LONG_RECEIPT,
      partnerCode: 'PRB',
      timestamp: '10:30:00',
      atvetelHuf: 100000,
      storno: false,
    },
    {
      annualSequence: 4,
      receiptNumber: LONG_STORNO_RECEIPT,
      partnerCode: 'PRB',
      timestamp: '11:00:00',
      atvetelHuf: -100000,
      storno: true,
    },
  ],
  totalAtadasHuf: 250000,
  totalAtvetelHuf: 0,
  openingBalanceHuf: 1500000,
  closingBalanceHuf: 1250000,
}

/** Üres nap (9.1 edge case): Nyitó = Záró, Forgalom = 0, de a nyomtatási kép teljes. */
const EMPTY_DAYBOOK_FIXTURE = {
  ...DAYBOOK_FIXTURE,
  rows: [],
  totalAtadasHuf: 0,
  totalAtvetelHuf: 0,
  openingBalanceHuf: 1500000,
  closingBalanceHuf: 1500000,
}

/**
 * A hu-HU ezres elválasztó ICU-verziótól függően sima szóköz / nbsp / narrow-nbsp
 * lehet — a szöveg-összehasonlítás előtt minden whitespace-t sima szóközre normalizálunk.
 */
function normalize(value: string | null | undefined): string {
  return (value ?? '').replace(/\s+/g, ' ').trim()
}

function printSpy() {
  const spy = vi.fn()
  Object.defineProperty(window, 'print', { value: spy, writable: true, configurable: true })
  return spy
}

async function renderLoaded(fixture: unknown = DAYBOOK_FIXTURE) {
  mocks.get.mockResolvedValue(fixture)
  const view = render(
    <MemoryRouter>
      <DaybookPage />
    </MemoryRouter>,
  )
  fireEvent.click(screen.getByText('Lekérdezés'))
  await waitFor(() => {
    expect(mocks.get).toHaveBeenCalledWith('branch-1', expect.any(String))
  })
  return view
}

beforeEach(() => {
  vi.clearAllMocks()
})

afterEach(() => {
  vi.restoreAllMocks()
})

// ============================ FR-4: cégfejléc ============================

describe('FKH-027 FR-4 — cégfejléc a képernyőn (RED)', () => {
  it('a lista fölött megjelenik a cégnév, a fióknév és a fiókcím', async () => {
    await renderLoaded()

    const header = await screen.findByTestId('daybook-print-header')
    const text = normalize(header.textContent)

    // A tartalom a HufDaybookPdfService.renderHeader-rel egyezik (94-101. sor):
    // COMPANY_HEADER + branchName + branchAddress.
    expect(text).toContain('Exclusive Best Change Zrt.')
    expect(text).toContain('Szeged Értéktár')
    expect(text).toContain('6720 Szeged, Kárász utca 1.')
    // A nyomtatvány-cím a dátummal (PDF: "NAPLOKONYV (HUF) - Datum: …").
    expect(text).toContain('Naplókönyv (HUF)')
    expect(text).toContain('2026-07-01')

    // FR-4/FR-7: a fejléc NYOMTATÁSKOR IS látszik — nem kaphat `no-print` jelölést.
    expect(header.closest('.no-print')).toBeNull()
  })

  it('fiókcím nélküli válasznál a fejléc a többi mezővel megjelenik (defenzív)', async () => {
    await renderLoaded({ ...DAYBOOK_FIXTURE, branchAddress: undefined })

    const header = await screen.findByTestId('daybook-print-header')
    const text = normalize(header.textContent)
    expect(text).toContain('Exclusive Best Change Zrt.')
    expect(text).toContain('Szeged Értéktár')
  })
})

// ================== FR-1 / FR-2 / FR-3: összegző dobozok ==================

describe('FKH-027 FR-1/2/3 — Nyitó / Forgalom / Záró dobozok (RED)', () => {
  it('megjeleníti a Nyitó egyenleget az openingBalanceHuf értékkel', async () => {
    await renderLoaded()

    const box = await screen.findByTestId('daybook-opening-balance')
    expect(normalize(box.textContent)).toContain('Nyitó egyenleg')
    expect(normalize(box.textContent)).toContain('1 500 000 Ft')
    expect(box.closest('.no-print')).toBeNull()
  })

  it('megjeleníti az Átadás/Átvétel összesen forgalom-dobozt', async () => {
    await renderLoaded()

    const atadas = await screen.findByTestId('daybook-total-atadas')
    expect(normalize(atadas.textContent)).toContain('Átadás összesen')
    expect(normalize(atadas.textContent)).toContain('250 000 Ft')

    const atvetel = await screen.findByTestId('daybook-total-atvetel')
    expect(normalize(atvetel.textContent)).toContain('Átvétel összesen')
    expect(normalize(atvetel.textContent)).toContain('0 Ft')
  })

  it('megjeleníti a Záró egyenleget a closingBalanceHuf értékkel', async () => {
    await renderLoaded()

    const box = await screen.findByTestId('daybook-closing-balance')
    expect(normalize(box.textContent)).toContain('Záró egyenleg')
    expect(normalize(box.textContent)).toContain('1 250 000 Ft')
    expect(box.closest('.no-print')).toBeNull()
  })

  it('üres napon is teljes a nyomtatási kép: fejléc + dobozok + aláírás, Nyitó = Záró, Forgalom = 0', async () => {
    await renderLoaded(EMPTY_DAYBOOK_FIXTURE)

    expect(await screen.findByTestId('daybook-print-header')).toBeInTheDocument()
    expect(normalize((await screen.findByTestId('daybook-opening-balance')).textContent)).toContain(
      '1 500 000 Ft',
    )
    expect(normalize((await screen.findByTestId('daybook-closing-balance')).textContent)).toContain(
      '1 500 000 Ft',
    )
    expect(normalize((await screen.findByTestId('daybook-total-atadas')).textContent)).toContain(
      '0 Ft',
    )
    expect(normalize((await screen.findByTestId('daybook-total-atvetel')).textContent)).toContain(
      '0 Ft',
    )
    expect(await screen.findByTestId('daybook-signatures')).toBeInTheDocument()
    // A meglévő üres-állapot üzenet változatlanul megmarad.
    expect(screen.getByText('Nincs tétel erre a napra.')).toBeInTheDocument()
  })
})

// ============================ FR-5: aláírás-sor ============================

describe('FKH-027 FR-5 — aláírás-sor (RED)', () => {
  it('két aláírás-vonal jelenik meg a Pénztáros és az Ellenőrző felirattal, a lista alatt', async () => {
    await renderLoaded()

    const signatures = await screen.findByTestId('daybook-signatures')
    const text = normalize(signatures.textContent)
    expect(text).toContain('Pénztáros aláírása')
    expect(text).toContain('Ellenőrző aláírása')

    // FR-5/FR-7: az aláírás-sor a NYOMTATOTT képen kell legyen.
    expect(signatures.closest('.no-print')).toBeNull()
  })
})

// ==================== FR-6 / FR-7: Nyomtatás gomb + no-print ====================

describe('FKH-027 FR-6/FR-7 — "Nyomtatás" gomb és a csak-képernyős elemek (RED)', () => {
  it('a "Nyomtatás" gomb window.print()-et hív, és maga `no-print` jelölésű', async () => {
    const spy = printSpy()
    await renderLoaded()

    const button = await screen.findByRole('button', { name: /Nyomtatás/ })
    // FR-6: a gomb nyomtatáskor nem jelenhet meg (TransferDocumentPage:204 minta).
    expect(button.closest('.no-print')).not.toBeNull()

    fireEvent.click(button)
    expect(spy).toHaveBeenCalledTimes(1)
  })

  it('a dátumválasztó és a "Lekérdezés" gomb `no-print` konténerben van', async () => {
    const { container } = await renderLoaded()

    const dateInput = container.querySelector('input[type="date"]')
    expect(dateInput).not.toBeNull()
    // FR-7: a dátumválasztó csak képernyőn látszik.
    expect(dateInput!.closest('.no-print')).not.toBeNull()

    const queryButton = screen.getByText('Lekérdezés')
    expect(queryButton.closest('.no-print')).not.toBeNull()
  })
})

// ==================== FR-8: PDF gomb és letöltés megszűnése ====================

describe('FKH-027 FR-8 — a "PDF" gomb és a letöltési logika megszűnt (RED)', () => {
  it('betöltött napló mellett sincs "PDF" gomb az oldalon', async () => {
    await renderLoaded()
    await screen.findByText('FF-000002')

    expect(screen.queryByRole('button', { name: /^PDF$/ })).toBeNull()
    expect(screen.queryByText('PDF')).toBeNull()
  })

  it('semmilyen interakció nem hívja a dailyReportApi.downloadPdf-et', async () => {
    printSpy()
    await renderLoaded()

    fireEvent.click(await screen.findByRole('button', { name: /Nyomtatás/ }))
    expect(mocks.downloadPdf).not.toHaveBeenCalled()
  })
})

// ==================== FR-9: csak a backend sorai (KK-regresszió-őr) ====================

describe('FKH-027 FR-9 — a lista pontosan a backend FF/UF sorait mutatja (regresszió-őr)', () => {
  it('a táblázat törzse pontosan annyi sort tartalmaz, amennyit a backend küldött', async () => {
    const { container } = await renderLoaded()
    await screen.findByText('FF-000002')

    const tbody = container.querySelector('tbody')
    expect(tbody).not.toBeNull()
    const bodyRows = within(tbody as HTMLElement).getAllByRole('row')
    expect(bodyRows).toHaveLength(DAYBOOK_FIXTURE.rows.length)
  })
})

// ==================== FR-10: sztornó-jelölés és teljes bizonylatszám ====================

describe('FKH-027 FR-10 — sztornó-jelölés félkövéren, szín nélkül (RED)', () => {
  it('a sztornó-sorban félkövér "SZTORNÓ" felirat áll, szín-osztály NÉLKÜL', async () => {
    await renderLoaded()

    const badge = await screen.findByTestId('daybook-storno-badge')
    expect(normalize(badge.textContent)).toBe('SZTORNÓ')

    // Félkövér — a nyomtatvány fekete-fehér, a kiemelés a betűvastagság.
    expect(badge.className).toMatch(/font-(bold|semibold)/)

    // SZÍN NÉLKÜLI: sem Tailwind szöveg-szín, sem inline szín nem lehet rajta.
    expect(badge.className).not.toMatch(
      /\btext-(red|rose|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink)-\d{2,3}\b/,
    )
    expect(badge.getAttribute('style') ?? '').not.toMatch(/color/i)
  })

  it('pontosan egy SZTORNÓ jelölés van — a nem sztornó sorok jelöletlenek', async () => {
    await renderLoaded()
    await screen.findByText('FF-000002')

    expect(screen.getAllByTestId('daybook-storno-badge')).toHaveLength(1)
  })

  it('a 18 karakternél hosszabb bizonylatszámot teljes hosszban jeleníti meg (nincs csonkolás)', async () => {
    await renderLoaded()

    // A "-SZ" utótagnak is látszania kell — a PDF truncate(…, 18) levágná.
    expect(await screen.findByText(LONG_STORNO_RECEIPT)).toBeInTheDocument()
    expect(screen.getByText(LONG_RECEIPT)).toBeInTheDocument()
  })
})
