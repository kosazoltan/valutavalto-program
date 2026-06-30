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
      return opts.devicesFail ? Promise.reject(new Error('devices 403')) : Promise.resolve({ data: opts.devices ?? [] })
    }
    if (url === '/stock-snapshot') {
      return opts.stockFail ? Promise.reject(new Error('snapshot 500')) : Promise.resolve({ data: opts.stock ?? { regions: [] } })
    }
    return Promise.resolve({ data: null })
  })
}

const BRANCH_A = { id: 'a1', code: 'P01', name: 'Pénztár 1', city: 'Szeged', isActive: true, region: 'SZEGED' }
const BRANCH_B = { id: 'b2', code: 'P02', name: 'Pénztár 2', city: 'Pécs', isActive: true, region: 'PECS' }

// stock-snapshot válasz: A fióknak van EUR készlete (küszöb alatt → valódi riasztás),
// B fióknak NINCS semmi (STOCK UNKNOWN).
function snapshotWithLowEurForA() {
  return { regions: [{ regionCode: 'SZEGED', branches: [{ branchId: 'a1', currencies: [{ currencyCode: 'EUR', stock: 100 }] }] }] }
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
    // a Készlet-riasztás összesítő 0 (a STOCK UNKNOWN nem riasztás)
    const alertCard = screen.getByText('Készlet-riasztás').closest('div')?.parentElement
    expect(alertCard?.textContent).toContain('0')
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
    await waitFor(() => expect(screen.getByText(/A készletadatok betöltése sikertelen/)).toBeInTheDocument())
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
    expect(screen.getByText('foertektar.sosem')).toBeInTheDocument()
  })
})
