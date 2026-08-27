import { describe, it, expect } from 'vitest'
import { computeHandlingFee } from './handlingFee'
import type { HandlingFeeConfig } from '../services/api/settings'

/**
 * FK-KEZDIJ B.1 (2026-06-12): a kliens-oldali díj-tükör BIT-PONTOS paritása a backend
 * HandlingFeeService (PER_MILLE/BRACKET) + HandlingFeeCalculator (roundToFive) számításával.
 */
const perMille = (rate: number, max: number | null = null): HandlingFeeConfig => ({
  feeType: 'PER_MILLE',
  perMilleRate: rate,
  perMilleMaxAmount: max,
  brackets: [],
})

const bracket = (rows: Array<[number, number, number]>): HandlingFeeConfig => ({
  feeType: 'BRACKET',
  perMilleRate: 0,
  perMilleMaxAmount: null,
  brackets: rows.map(([bracketOrder, upperLimit, feeAmount]) => ({
    bracketOrder,
    upperLimit,
    feeAmount,
    active: true,
  })),
})

// FK-097 WU-15 (FR-4/FR-5): cache-first loadHandlingFeeConfig — RED before implementation.
import { loadHandlingFeeConfig, mapCachedHandlingFeeConfig } from './handlingFee'
import type { ElectronCachedHandlingFeeConfig } from './handlingFee'
import { vi, beforeEach } from 'vitest'

// Mock the two data sources (electronTransactions for the cache, settings for the HTTP API)
vi.mock('./electronTransactions', () => ({
  isElectronQueueAvailable: vi.fn(() => false),
  getElectronCachedHandlingFeeConfig: vi.fn(async () => null),
}))
vi.mock('../services/api/settings', async () => {
  const actual = await vi.importActual<typeof import('../services/api/settings')>(
    '../services/api/settings',
  )
  return { ...actual, branchFeeConfigApi: { own: vi.fn(async () => null) } }
})
import {
  isElectronQueueAvailable,
  getElectronCachedHandlingFeeConfig,
} from './electronTransactions'
import { branchFeeConfigApi } from '../services/api/settings'

describe('loadHandlingFeeConfig — cache-first olvasas (FK-097 FR-4/FR-5)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('FR-4: van cache -> a helyi SQLite-bol olvas, NEM hiv HTTP-t', async () => {
    vi.mocked(isElectronQueueAvailable).mockReturnValue(true)
    vi.mocked(getElectronCachedHandlingFeeConfig).mockResolvedValue({
      branch_id: 'b-1',
      branch_code: '001',
      company_id: 'c-1',
      fee_mode: 'PER_MILLE',
      per_mille_rate: 3,
      per_mille_cap: null,
      bracket_json: null,
      valid_from: '2026-08-26',
      synced_at: '2026-08-26T19:00:00Z',
    })
    const cfg = await loadHandlingFeeConfig()
    expect(cfg).not.toBeNull()
    expect(cfg?.feeType).toBe('PER_MILLE')
    expect(cfg?.perMilleRate).toBe(3)
    expect(branchFeeConfigApi.own).not.toHaveBeenCalled()
  })

  it('FR-5: ures cache -> HTTP-fallback a /branch-fee-config/own vegzetre', async () => {
    vi.mocked(isElectronQueueAvailable).mockReturnValue(true)
    vi.mocked(getElectronCachedHandlingFeeConfig).mockResolvedValue(null)
    vi.mocked(branchFeeConfigApi.own).mockResolvedValue({
      branchId: 'b-1',
      branchCode: '001',
      feeMode: 'PER_MILLE',
      perMilleRate: 4,
      perMilleCap: 500,
      validFrom: '2026-08-26',
      brackets: [],
    })
    const cfg = await loadHandlingFeeConfig()
    expect(branchFeeConfigApi.own).toHaveBeenCalledTimes(1)
    expect(cfg?.feeType).toBe('PER_MILLE')
    expect(cfg?.perMilleRate).toBe(4)
  })

  it('mindketto hibas -> null (a regi .catch(() => setFeeConfig(null)) viselkedes)', async () => {
    vi.mocked(isElectronQueueAvailable).mockReturnValue(true)
    vi.mocked(getElectronCachedHandlingFeeConfig).mockRejectedValue(new Error('db'))
    vi.mocked(branchFeeConfigApi.own).mockRejectedValue(new Error('http'))
    const cfg = await loadHandlingFeeConfig()
    expect(cfg).toBeNull()
  })

  it('web modban (nincs Electron) -> egyenesen HTTP', async () => {
    vi.mocked(isElectronQueueAvailable).mockReturnValue(false)
    vi.mocked(branchFeeConfigApi.own).mockResolvedValue({
      branchId: 'b-1',
      branchCode: '001',
      feeMode: 'BRACKET',
      perMilleRate: null,
      perMilleCap: null,
      validFrom: '2026-08-26',
      brackets: [{ bracketOrder: 1, upperLimit: 100000, feeAmount: 500, active: true }],
    })
    const cfg = await loadHandlingFeeConfig()
    expect(isElectronQueueAvailable).toHaveBeenCalled()
    expect(branchFeeConfigApi.own).toHaveBeenCalledTimes(1)
    expect(cfg?.feeType).toBe('BRACKET')
    expect(cfg?.brackets).toHaveLength(1)
  })

  it('NFR-3 korpusz: cached PER_MILLE sor a tukor-keplet szerint szamol (hatarertekekkel)', async () => {
    vi.mocked(isElectronQueueAvailable).mockReturnValue(true)
    vi.mocked(getElectronCachedHandlingFeeConfig).mockResolvedValue({
      branch_id: 'b-1',
      branch_code: '001',
      company_id: 'c-1',
      fee_mode: 'PER_MILLE',
      per_mille_rate: 18.4,
      per_mille_cap: null,
      bracket_json: null,
      valid_from: '2026-08-26',
      synced_at: '2026-08-26T19:00:00Z',
    })
    const cfg = await loadHandlingFeeConfig()
    expect(cfg).not.toBeNull()
    // Ellenor2 W7 merese: 3125 * 18.4 / 1000 double-ben 57.5 alatti -> 57 -> roundHuf 55,
    // mig a BigDecimal-pontos szerver 57500 -> HALF_UP 58 -> 60. A tukor a SAJAT kepletet
    // reprodukalja (dokumentalt maradvanykockazat, plan rework W7 dontes); ez a teszt a
    // tukor-konzisztenciat rogziti, nem a BigDecimal-paritast allitja.
    expect(computeHandlingFee(3125, cfg)).toBe(55)
    expect(computeHandlingFee(100000, cfg)).toBe(1840)
    expect(computeHandlingFee(5000, cfg)).toBe(90)
  })

  it('torott bracket_json nem dob hibat (ures savlista)', () => {
    const row: ElectronCachedHandlingFeeConfig = {
      branch_id: 'b-1',
      branch_code: '001',
      company_id: 'c-1',
      fee_mode: 'BRACKET',
      per_mille_rate: null,
      per_mille_cap: null,
      bracket_json: '{not json',
      valid_from: '2026-08-26',
      synced_at: '2026-08-26T19:00:00Z',
    }
    expect(() => mapCachedHandlingFeeConfig(row)).not.toThrow()
    const cfg = mapCachedHandlingFeeConfig(row)
    expect(cfg.feeType).toBe('BRACKET')
    expect(cfg.brackets).toEqual([])
  })
})

describe('computeHandlingFee — PER_MILLE (backend-paritás)', () => {
  it('összeg × ezrelék / 1000, HALF_UP egészre, majd 5 Ft-szabály', () => {
    // 123 456 × 3 / 1000 = 370.368 → HALF_UP 370 → roundToFive 370
    expect(computeHandlingFee(123456, perMille(3))).toBe(370)
    // 100 000 × 3 / 1000 = 300 → 300
    expect(computeHandlingFee(100000, perMille(3))).toBe(300)
    // 111 111 × 3 / 1000 = 333.333 → 333 → 5-szabály (3→5): 335
    expect(computeHandlingFee(111111, perMille(3))).toBe(335)
    // 110 600 × 3 / 1000 = 331.8 → HALF_UP 332 → 5-szabály (2→0): 330
    expect(computeHandlingFee(110600, perMille(3))).toBe(330)
    // 112 600 × 3 / 1000 = 337.8 → 338 → 5-szabály (8→10): 340
    expect(computeHandlingFee(112600, perMille(3))).toBe(340)
  })

  it('max-sapka érvényesül (ha > 0), a sapkázott érték is 5 Ft-ra kerekül', () => {
    expect(computeHandlingFee(10_000_000, perMille(3, 5000))).toBe(5000)
    expect(computeHandlingFee(10_000_000, perMille(3, 0))).toBe(30000) // 0 sapka = nincs sapka
    expect(computeHandlingFee(10_000_000, perMille(3, null))).toBe(30000)
  })
})

describe('computeHandlingFee — BRACKET (backend-paritás)', () => {
  const cfg = bracket([
    [1, 50000, 200],
    [2, 150000, 500],
    [3, 400000, 1000],
  ])

  it('az első sáv, ahol összeg <= upperLimit (határérték a sávhoz tartozik)', () => {
    expect(computeHandlingFee(30000, cfg)).toBe(200)
    expect(computeHandlingFee(50000, cfg)).toBe(200) // pontosan a határon: <= → ez a sáv
    expect(computeHandlingFee(50001, cfg)).toBe(500)
    expect(computeHandlingFee(150000, cfg)).toBe(500)
    expect(computeHandlingFee(400000, cfg)).toBe(1000)
  })

  it('az utolsó sáv felett az utolsó sáv díja érvényesül', () => {
    expect(computeHandlingFee(9_999_999, cfg)).toBe(1000)
  })

  it('inaktív sávok kiszűrve; üres sávtábla → 0 (backend-paritás)', () => {
    const withInactive = bracket([[1, 50000, 200]])
    withInactive.brackets.push({
      bracketOrder: 2,
      upperLimit: 999999999,
      feeAmount: 7777,
      active: false,
    })
    expect(computeHandlingFee(100000, withInactive)).toBe(200) // utolsó AKTÍV sáv díja
    expect(computeHandlingFee(100000, bracket([]))).toBe(0)
  })
})

describe('computeHandlingFee — szélek', () => {
  it('NONE → 0; null konfig → null (nincs tükör-számítás); 0/negatív összeg → 0', () => {
    expect(
      computeHandlingFee(100000, {
        feeType: 'NONE',
        perMilleRate: 0,
        perMilleMaxAmount: null,
        brackets: [],
      }),
    ).toBe(0)
    expect(computeHandlingFee(100000, null)).toBeNull()
    expect(computeHandlingFee(0, perMille(3))).toBe(0)
    expect(computeHandlingFee(-5, perMille(3))).toBe(0)
  })
})
