/**
 * FK-048 — Országos dashboard készlet-riasztás logika tesztjei.
 * Lefedi: FR-1 (alertCount csak valódi riasztás), FR-2 (STOCK UNKNOWN semleges, nem alert),
 * FR-3 (valódi riasztás piros + alertCount), FR-4 (snapshot-hiba látható banner),
 * FR-5 (hibajelzés ≠ STOCK UNKNOWN), és hogy az OFFLINE/devices logika változatlan.
 */
import { render, screen, waitFor } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import CentralVaultDashboard from './CentralVaultDashboard'

const mockGet = vi.fn()
vi.mock('../../services/api/client', () => ({
  api: { get: (...args: unknown[]) => mockGet(...args) },
}))
vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (k: string) => k }),
}))

// Segéd: a három párhuzamos hívás (/branches, /cash-register/devices, /stock-snapshot) válaszait állítja be.
function setupApi(opts: {
  branches: unknown[]
  devices?: unknown[]
  devicesFail?: boolean
  stock?: unknown
  stockFail?: boolean
}) {
  mockGet.mockImplementation((url: string) => {
    if (url === '/branches') return Promise.resolve({ data: opts.branches })
    if (url === '/cash-register/devices') {
      return opts.devicesFail
        ? Promise.reject(new Error('devices 403'))
        : Promise.resolve({ data: opts.devices ?? [] })
    }
    if (url === '/stock-snapshot') {
      return opts.stockFail
        ? Promise.reject(new Error('snapshot 500'))
        : Promise.resolve({ data: opts.stock ?? { regions: [] } })
    }
    return Promise.resolve({ data: null })
  })
}

const BRANCH_A = {
  id: 'a1',
  code: 'P01',
  name: 'Pénztár 1',
  city: 'Szeged',
  isActive: true,
  region: 'SZEGED',
}
const BRANCH_B = {
  id: 'b2',
  code: 'P02',
  name: 'Pénztár 2',
  city: 'Pécs',
  isActive: true,
  region: 'PECS',
}

// stock-snapshot válasz: A fióknak van EUR készlete (küszöb alatt → valódi riasztás),
// B fióknak NINCS semmi (STOCK UNKNOWN).
function snapshotWithLowEurForA() {
  return {
    regions: [
      {
        regionCode: 'SZEGED',
        branches: [{ branchId: 'a1', currencies: [{ currencyCode: 'EUR', stock: 100, hasBalance: true }] }],
      },
    ],
  }
}

describe('CentralVaultDashboard — FK-048 készlet-riasztás', () => {
  beforeEach(() => {
    mockGet.mockReset()
  })

  it('FR-3: valódi, küszöb alatti fiók riasztásként, az alertCount-ban számolva jelenik meg', async () => {
    setupApi({ branches: [BRANCH_A], stock: snapshotWithLowEurForA() })
    render(<CentralVaultDashboard />)
    await waitFor(() => expect(screen.getByText('P01')).toBeInTheDocument())
    // EUR 100 < 500 → riasztás-szöveg látszik
    expect(screen.getByText(/EUR <\s?500/)).toBeInTheDocument()
  })

  it('FR-1/FR-2: STOCK UNKNOWN fiók NEM növeli az alertCount-ot és semleges jelzéssel jelenik meg', async () => {
    // B fióknak nincs készletadata, és nincs más fiók → alertCount = 0
    setupApi({ branches: [BRANCH_B], stock: { regions: [] } })
    render(<CentralVaultDashboard />)
    await waitFor(() => expect(screen.getByText('P02')).toBeInTheDocument())
    // semleges "nincs készletadat" jelzés a riasztás-oszlopban, NEM piros riasztás
    expect(screen.getByText('nincs készletadat')).toBeInTheDocument()
    // a Készlet-riasztás összesítő 0 (a STOCK UNKNOWN nem riasztás) — célzott data-testid assert
    expect(screen.getByTestId('stock-alert-count').textContent).toBe('0')
  })

  it('FR-1: vegyes eset — a Készlet-riasztás szám CSAK a valódit számolja (STOCK UNKNOWN-t nem)', async () => {
    // A: valódi riasztás (EUR<500), B: STOCK UNKNOWN → alertCount = 1
    setupApi({ branches: [BRANCH_A, BRANCH_B], stock: snapshotWithLowEurForA() })
    render(<CentralVaultDashboard />)
    await waitFor(() => expect(screen.getByText('P01')).toBeInTheDocument())
    expect(screen.getByText('P02')).toBeInTheDocument()
    expect(screen.getByText('nincs készletadat')).toBeInTheDocument() // B semleges
    expect(screen.getByText(/EUR <\s?500/)).toBeInTheDocument() // A riasztás
  })

  it('FR-4/FR-5: /stock-snapshot hiba esetén látható hibabanner jelenik meg (≠ STOCK UNKNOWN)', async () => {
    setupApi({ branches: [BRANCH_A], stockFail: true })
    render(<CentralVaultDashboard />)
    await waitFor(() =>
      expect(screen.getByText(/A készletadatok betöltése sikertelen/)).toBeInTheDocument(),
    )
  })

  it('FR-4 (edge): /stock-snapshot hiba esetén a Készlet-riasztás kártya NEM félrevezető 0-t, hanem „—”-t mutat', async () => {
    setupApi({ branches: [BRANCH_A], stockFail: true })
    render(<CentralVaultDashboard />)
    await waitFor(() =>
      expect(screen.getByText(/A készletadatok betöltése sikertelen/)).toBeInTheDocument(),
    )
    // a spec edge case: hiba esetén a táblázat/összesítő NE mutasson félrevezető adatot →
    // a kártya „—” (nem tudjuk), nem magabiztos 0
    expect(screen.getByTestId('stock-alert-count').textContent).toBe('—')
  })

  it('FR-4: sikeres snapshot esetén NINCS hibabanner', async () => {
    setupApi({ branches: [BRANCH_A], stock: snapshotWithLowEurForA() })
    render(<CentralVaultDashboard />)
    await waitFor(() => expect(screen.getByText('P01')).toBeInTheDocument())
    expect(screen.queryByText(/A készletadatok betöltése sikertelen/)).not.toBeInTheDocument()
  })

  it('stock-snapshot hiba esetén az OFFLINE kártya és a devices logika változatlan (Scope OUT)', async () => {
    // devices üres → minden offline; a snapshot hiba NEM befolyásolja az offline-számítást
    setupApi({ branches: [BRANCH_A], devices: [], stockFail: true })
    render(<CentralVaultDashboard />)
    await waitFor(() => expect(screen.getByText('Offline (>10 perc)')).toBeInTheDocument())
    // A fiók offline (nincs device/heartbeat) — a státusz oszlopban "sosem"
    expect(await screen.findByText('foertektar.sosem')).toBeInTheDocument()
  })
})

// FK-085 — KÉSZLET oszlop: GBP/CHF cellák + 5-devizás fejléc (FR-1/FR-2).
const FIVE_CCY_SNAPSHOT = {
  regions: [
    {
      regionCode: 'SZEGED',
      branches: [
        {
          branchId: 'a1',
          currencies: [
            { currencyCode: 'EUR', stock: 1000, hasBalance: true },
            { currencyCode: 'USD', stock: 1000, hasBalance: true },
            { currencyCode: 'GBP', stock: 1000, hasBalance: true },
            { currencyCode: 'CHF', stock: 1000, hasBalance: true },
            { currencyCode: 'HUF', stock: 1_000_000, hasBalance: true },
          ],
        },
      ],
    },
  ],
}

describe('CentralVaultDashboard — FK-085 GBP/CHF készlet + devices-hibakezelés', () => {
  beforeEach(() => {
    mockGet.mockReset()
  })

  it('FK-085 FR-1: a KÉSZLET oszlop mind az 5 devizát rendereli (EUR, USD, GBP, CHF, HUF)', async () => {
    setupApi({ branches: [BRANCH_A], stock: FIVE_CCY_SNAPSHOT })
    render(<CentralVaultDashboard />)
    await waitFor(() => expect(screen.getByText('P01')).toBeInTheDocument())
    expect(screen.getByText('EUR')).toBeInTheDocument()
    expect(screen.getByText('USD')).toBeInTheDocument()
    expect(screen.getByText('GBP')).toBeInTheDocument()
    expect(screen.getByText('CHF')).toBeInTheDocument()
    expect(screen.getByText('HUF')).toBeInTheDocument()
  })

  it('FK-085 FR-1: GBP és CHF küszöb alatti riasztása megjelenik', async () => {
    setupApi({
      branches: [BRANCH_A],
      stock: {
        regions: [
          {
            regionCode: 'SZEGED',
            branches: [
              {
                branchId: 'a1',
                currencies: [
                  { currencyCode: 'EUR', stock: 1000, hasBalance: true },
                  { currencyCode: 'USD', stock: 1000, hasBalance: true },
                  { currencyCode: 'GBP', stock: 100, hasBalance: true },
                  { currencyCode: 'CHF', stock: 100, hasBalance: true },
                  { currencyCode: 'HUF', stock: 1_000_000, hasBalance: true },
                ],
              },
            ],
          },
        ],
      },
    })
    render(<CentralVaultDashboard />)
    await waitFor(() => expect(screen.getByText('P01')).toBeInTheDocument())
    expect(screen.getByText(/GBP <\s?300/)).toBeInTheDocument()
    expect(screen.getByText(/CHF <\s?300/)).toBeInTheDocument()
  })

  it('FK-085 FR-2: a fejléc az új 5-devizás i18n kulcsot használja', async () => {
    setupApi({ branches: [BRANCH_A], stock: FIVE_CCY_SNAPSHOT })
    render(<CentralVaultDashboard />)
    await waitFor(() => expect(screen.getByText('P01')).toBeInTheDocument())
    expect(screen.getByText('foertektar.keszletOtDeviza')).toBeInTheDocument()
  })

  it('FK-085 FR-4: devices-hiba esetén figyelmeztető banner jelenik meg', async () => {
    setupApi({ branches: [BRANCH_A], devicesFail: true })
    render(<CentralVaultDashboard />)
    await waitFor(() =>
      expect(screen.getByText(/A pénztárgép-állapot betöltése sikertelen/)).toBeInTheDocument(),
    )
  })

  it('FK-085 FR-4: devices-hiba esetén NINCS hamis Soha/Offline státusz, az Offline kártya és a státusz-cella „—”', async () => {
    setupApi({ branches: [BRANCH_A], devicesFail: true })
    render(<CentralVaultDashboard />)
    await waitFor(() =>
      expect(screen.getByText(/A pénztárgép-állapot betöltése sikertelen/)).toBeInTheDocument(),
    )
    // Nincs hamis „Soha”/„Offline” státusz
    expect(screen.queryByText('foertektar.sosem')).not.toBeInTheDocument()
    expect(screen.queryByText('foertektar.offline')).not.toBeInTheDocument()
    // A Státusz oszlop cellája „—” (a span-szelektor a státusz-cellára szűkít;
    // a heartbeat-oszlop „—”-je span nélküli td-szöveg)
    expect(screen.getByText('—', { selector: 'span' })).toBeInTheDocument()
    // Az Offline összesítő kártya értéke „—”, nem magabiztosan hibás szám
    expect(screen.getByTestId('offline-count').textContent).toBe('—')
  })

  it('FK-085 FR-4: devices + snapshot egyszerre hibázik → mindkét banner látszik', async () => {
    setupApi({ branches: [BRANCH_A], devicesFail: true, stockFail: true })
    render(<CentralVaultDashboard />)
    await waitFor(() =>
      expect(screen.getByText(/A pénztárgép-állapot betöltése sikertelen/)).toBeInTheDocument(),
    )
    expect(screen.getByText(/A készletadatok betöltése sikertelen/)).toBeInTheDocument()
  })

  it('FK-085 FR-4: sikeres devices-hívás esetén NINCS devices-banner', async () => {
    setupApi({ branches: [BRANCH_A], devices: [] })
    render(<CentralVaultDashboard />)
    await waitFor(() => expect(screen.getByText('P01')).toBeInTheDocument())
    expect(screen.queryByText(/A pénztárgép-állapot betöltése sikertelen/)).not.toBeInTheDocument()
  })
})

// FK-093 — nem-forgalmazott deviza (hasBalance:false) ne generáljon hamis riasztást.
describe('CentralVaultDashboard — FK-093 hasBalance riasztás-szűrés', () => {
  beforeEach(() => {
    mockGet.mockReset()
  })

  it('FK-093 FR-5: EUR/USD/HUF forgalmazott, GBP/CHF nem — nincs GBP/CHF riasztás', async () => {
    setupApi({
      branches: [BRANCH_A],
      stock: {
        regions: [
          {
            regionCode: 'SZEGED',
            branches: [
              {
                branchId: 'a1',
                currencies: [
                  { currencyCode: 'EUR', stock: 1000, hasBalance: true },
                  { currencyCode: 'USD', stock: 1000, hasBalance: true },
                  { currencyCode: 'GBP', stock: 0, hasBalance: false },
                  { currencyCode: 'CHF', stock: 0, hasBalance: false },
                  { currencyCode: 'HUF', stock: 1_000_000, hasBalance: true },
                ],
              },
            ],
          },
        ],
      },
    })
    render(<CentralVaultDashboard />)
    await waitFor(() => expect(screen.getByText('P01')).toBeInTheDocument())
    expect(screen.queryByText(/GBP <\s?300/)).not.toBeInTheDocument()
    expect(screen.queryByText(/CHF <\s?300/)).not.toBeInTheDocument()
  })

  it('FK-093 FR-4: forgalmazott GBP alacsony egyenleggel továbbra is riaszt', async () => {
    setupApi({
      branches: [BRANCH_A],
      stock: {
        regions: [
          {
            regionCode: 'SZEGED',
            branches: [
              {
                branchId: 'a1',
                currencies: [
                  { currencyCode: 'EUR', stock: 1000, hasBalance: true },
                  { currencyCode: 'USD', stock: 1000, hasBalance: true },
                  { currencyCode: 'GBP', stock: 50, hasBalance: true },
                  { currencyCode: 'CHF', stock: 1000, hasBalance: true },
                  { currencyCode: 'HUF', stock: 1_000_000, hasBalance: true },
                ],
              },
            ],
          },
        ],
      },
    })
    render(<CentralVaultDashboard />)
    await waitFor(() => expect(screen.getByText('P01')).toBeInTheDocument())
    expect(screen.getByText(/GBP <\s?300/)).toBeInTheDocument()
  })
})
