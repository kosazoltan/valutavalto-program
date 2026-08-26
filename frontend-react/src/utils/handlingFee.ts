import type { HandlingFeeConfig } from '../services/api/settings'
import { roundHuf } from './rounding'

/**
 * FK-KEZDIJ B.1 (2026-06-12, penztar-batch): kliens-oldali kezelési díj TÜKÖR-számítás.
 *
 * A szerver AUTORITATÍV (HandlingFeeCalculator.calculate — a kliens által küldött díjat
 * sosem fogadja el vakon); ez a tükör csak azt biztosítja, hogy a pénztáros-képernyő és
 * a helyi bizonylat UGYANAZT az összeget mutassa, amit a szerver könyvel. A matematika
 * BIT-PONTOSAN a backend HandlingFeeService + HandlingFeeCalculator tükre:
 *  - PER_MILLE: összeg × ezrelék / 1000, HALF_UP egészre, majd max-sapka (ha > 0);
 *  - BRACKET: az első sáv, ahol összeg <= upperLimit; az utolsó sáv felett az utolsó díja;
 *  - mindkettő után 5 Ft-ra kerekítés (HungarianRounding.roundToFive == roundHuf szabály:
 *    0-2→0, 3-7→5, 8-9→10).
 *
 * A DiscountThresholdService (BIGARFVALT/KISARFVALT automatikus díj-kedvezmény/felár)
 * nem ebben a tiszta lokális tükörfüggvényben él: a pénztáros UI a baseFee után a
 * `/discount-threshold/apply` backend szerződésen kéri le az autoritatív küszöbhatást.
 */
export function computeHandlingFee(
  hufAmount: number,
  config: HandlingFeeConfig | null,
): number | null {
  if (!config) return null
  if (!Number.isFinite(hufAmount) || hufAmount <= 0) return 0

  let baseFee: number
  switch (config.feeType) {
    case 'NONE':
      return 0
    case 'PER_MILLE': {
      // backend: multiply(perMille).divide(1000, 0, HALF_UP) — pozitív összegre Math.round.
      baseFee = Math.round((hufAmount * (config.perMilleRate ?? 0)) / 1000)
      const max = config.perMilleMaxAmount
      if (max != null && max > 0 && baseFee > max) baseFee = max
      break
    }
    case 'BRACKET': {
      const brackets = [...(config.brackets ?? [])]
        .filter((b) => b.active !== false)
        .sort((a, b) => a.bracketOrder - b.bracketOrder)
      if (brackets.length === 0) return 0
      const hit = brackets.find((b) => hufAmount <= b.upperLimit)
      baseFee = (hit ?? brackets[brackets.length - 1]!).feeAmount
      break
    }
    default:
      return null
  }
  // backend HandlingFeeCalculator: HungarianRounding.roundToFive — a roundHuf-fal azonos szabály.
  return roundHuf(baseFee)
}

// FK-097 WU-15 (FR-4/FR-5/FR-6): cache-first dij-konfig betoltes.
// Elsoszor a helyi SQLite tukor (electron preload IPC), csak URES cache eseten
// HTTP-fallback a /branch-fee-config/own vegzontra (a useTransactionRates mintaja).
// DRAFT soha nem szinkronizalodik (a backend csak LIVE-t ad), es a cache-elt sor
// is kizarolag LIVE allapotu lehet — a szinkronmotor ugyanigy szur.
import {
  isElectronQueueAvailable,
  getElectronCachedHandlingFeeConfig,
  type ElectronCachedHandlingFeeConfig,
} from './electronTransactions'
import { branchFeeConfigApi, type BranchFeeConfigLive } from '../services/api/settings'

export type { ElectronCachedHandlingFeeConfig }

/** SQLite sor -> HandlingFeeConfig tukor (bracket_json defenziven parse-olva). */
export function mapCachedHandlingFeeConfig(
  row: ElectronCachedHandlingFeeConfig,
): HandlingFeeConfig {
  let brackets: HandlingFeeConfig['brackets'] = []
  if (row.bracket_json) {
    try {
      const parsed: unknown = JSON.parse(row.bracket_json)
      if (Array.isArray(parsed)) {
        brackets = parsed.filter(
          (b): b is HandlingFeeConfig['brackets'][number] =>
            typeof b === 'object' && b !== null && 'bracketOrder' in b,
        )
      }
    } catch {
      // torott JSON -> ures savlista (a computeHandlingFee BRACKET aga 0 Ft-t ad, ha
      // tenyleg nincs sav — pont mint ma)
    }
  }
  return {
    feeType: row.fee_mode,
    perMilleRate: row.per_mille_rate ?? 0,
    perMilleMaxAmount: row.per_mille_cap,
    brackets,
  }
}

/** /branch-fee-config/own valasz -> HandlingFeeConfig tukor. */
function mapLiveDto(dto: BranchFeeConfigLive): HandlingFeeConfig {
  return {
    feeType: dto.feeMode,
    perMilleRate: dto.perMilleRate ?? 0,
    perMilleMaxAmount: dto.perMilleCap,
    brackets: dto.brackets ?? [],
  }
}

/**
 * Cache-first dij-konfig: Electron es van cache-sor -> lokalis olvasas;
 * ures cache -> HTTP; mindketto hibas -> null (a regi .catch(null) viselkedes).
 */
export async function loadHandlingFeeConfig(): Promise<HandlingFeeConfig | null> {
  if (isElectronQueueAvailable()) {
    try {
      const cached = await getElectronCachedHandlingFeeConfig()
      if (cached) {
        return mapCachedHandlingFeeConfig(cached)
      }
    } catch {
      // cache-olvasasi hiba -> HTTP-fallback az alabbi agba
    }
  }
  try {
    const live = await branchFeeConfigApi.own()
    return mapLiveDto(live)
  } catch {
    return null
  }
}
