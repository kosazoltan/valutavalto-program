/**
 * FK05 (FR-1, FR-2, FR-3, FR-8, NFR-2) — Egységes árfolyam-szétküldés: az ÖSSZES
 * munkacsoport teljes árfolyamát (L/M alap, J elszámoló, N–S sávok, összeghatárok)
 * publikálja a meglévő `POST /rate-creation/publish-group-rate` végponton, csoportonként
 * külön hívással (batch végpont NINCS a backenden — TBD-3 tényfeltárás, 2026-06-12).
 *
 * Csoportonkénti adatforrás (TBD-4 tényfeltárás):
 *  - szerver-baseline: `GET /rate-creation/overview` (utolsó publikált exchange_rate / valuta),
 *  - csoport-overlay: `loadGroupRateValues(groupId)` (localStorage + Electron SQLite, FK02-B),
 *  - képletek: `loadGroupFormulas(groupId)` → pure `recomputeWorkgroupSheet` (FK-04/C motor).
 * Ez PONTOSAN az az állapot, amit a munkacsoport-lap megnyitáskor megjelenít és publikálna.
 *
 * NFR-2: részleges hiba NEM állítja le a többi csoportot — `Promise.allSettled`, a hibák
 * csoportonként gyűlnek és a hívó visszajelzésében jelennek meg (FR-8).
 */

import {
  rateCreationApi,
  type PublishGroupRateRequest,
  type RateOverviewItem,
  type WorkgroupDetailDTO,
} from '../../services/api/exchange-rates'
import { parseNum } from './types'
import { validateWorkgroupProtection, workgroupProtectionLabel, type ProtectionRow } from './workgroupProtection'
import { recomputeWorkgroupSheet, type WgComputeRow, type WgField } from './workgroupSheetCompute'
import type { WgValues } from './workgroupSheetFormula'
import {
  loadSheet0ByCurrency,
  loadAllGroupValueSnapshots,
  loadGroupFormulas,
  loadGroupRateValues,
  loadGroupRateValuesFromOfflineDb,
  persistGroupRateValues,
} from './workgroupSheetStorage'

export interface GroupPublishOutcome {
  groupId: string
  code: string
  name: string
  status: 'published' | 'skipped' | 'failed'
  message?: string
  acceptedRates?: number
}

export interface PublishAllResult {
  total: number
  published: number
  outcomes: GroupPublishOutcome[]
}

export interface PublishAllOptions {
  /** FR-8: folyamat-visszajelzés — hányadik csoportnál tart az összesből. */
  onProgress?: (done: number, total: number) => void
  /**
   * Az épp megnyitott csoport FRISS, memóriabeli payloadja (a munkacsoport-lap
   * képernyő-állapota) — erre a csoportra ez megy ki, nem a tárolt overlay-ből számolt.
   */
  inMemoryGroupRates?: { groupId: string; rates: PublishGroupRateRequest['rates'] }
  /** Ha a hívó már betöltötte (RateCreationPage), nem kérjük le újra. */
  preloaded?: { overview: RateOverviewItem[]; workgroups: WorkgroupDetailDTO[] }
}

/** Egy csoport publikálandó rátáinak headless összeállítása (baseline + overlay + képletek). */
async function buildGroupRates(
  group: WorkgroupDetailDTO,
  overview: RateOverviewItem[],
  sheet0ByCurrency: ReturnType<typeof loadSheet0ByCurrency>,
  otherGroupsByCurrency: ReturnType<typeof loadAllGroupValueSnapshots>,
): Promise<{ rates: PublishGroupRateRequest['rates']; protectionRows: ProtectionRow[]; error?: string }> {
  // FK02-B overlay: SQLite-first (tartós), localStorage fallback — a lap betöltési sorrendjével egyezően.
  const localValues = loadGroupRateValues(group.id)
  const dbValues = await loadGroupRateValuesFromOfflineDb(group.id)
  const overlay: Record<string, string> = { ...localValues, ...dbValues }
  const formulas = loadGroupFormulas(group.id)

  const numOrNull = (s: string | undefined): number | null => {
    if (s == null || s.trim() === '') return null
    const n = parseNum(s)
    return Number.isFinite(n) && n !== 0 ? n : null
  }

  // Sor-állapot: overlay-érték ha van, különben szerver-baseline (a lap reset-logikájával egyezően).
  const computeRows: WgComputeRow[] = overview.map((c) => {
    const baseline: Record<Exclude<WgField, 'officialRate'>, number | null> = {
      buyRate: c.currentBuyRate,
      sellRate: c.currentSellRate,
      limit1BuyRate: c.limit1BuyRate,
      limit1SellRate: c.limit1SellRate,
      limit2BuyRate: c.limit2BuyRate,
      limit2SellRate: c.limit2SellRate,
      limit3BuyRate: c.limit3BuyRate,
      limit3SellRate: c.limit3SellRate,
    }
    const field = (f: Exclude<WgField, 'officialRate'>): number | null => {
      const o = overlay[`${c.currencyId}.${f}`]
      return o != null ? numOrNull(o) : baseline[f]
    }
    const values: WgComputeRow['values'] = {
      officialRate: overlay[`${c.currencyId}.officialRate`] != null
        ? numOrNull(overlay[`${c.currencyId}.officialRate`])
        : c.officialRate,
      buyRate: field('buyRate'),
      sellRate: field('sellRate'),
      limit1BuyRate: field('limit1BuyRate'),
      limit1SellRate: field('limit1SellRate'),
      limit2BuyRate: field('limit2BuyRate'),
      limit2SellRate: field('limit2SellRate'),
      limit3BuyRate: field('limit3BuyRate'),
      limit3SellRate: field('limit3SellRate'),
    }
    return { currencyId: c.currencyId, currencyCode: c.currencyCode, values }
  })

  // Képletek alkalmazása (pure motor) — csak ha vannak; divergencia = csoport-hiba.
  let rows = computeRows
  if (Object.keys(formulas).length > 0) {
    const result = recomputeWorkgroupSheet({
      rows: computeRows,
      formulas,
      sheet0ByCurrency,
      otherGroupsByCurrency,
    })
    if (result.diverged) {
      return { rates: [], protectionRows: [], error: 'képlet-újraszámítás nem konvergált (körhivatkozás-gyanú)' }
    }
    rows = result.rows
  }

  const valid = rows.filter((r) => (r.values.buyRate ?? 0) > 0 && (r.values.sellRate ?? 0) > 0)
  const wrongDirection = valid.find((r) => (r.values.buyRate ?? 0) >= (r.values.sellRate ?? 0))
  if (wrongDirection) {
    return {
      rates: [],
      protectionRows: [],
      error: `${wrongDirection.currencyCode}: vétel (${wrongDirection.values.buyRate}) >= eladás (${wrongDirection.values.sellRate})`,
    }
  }

  // Codex P2 #1118: a kedvezménysáv-párok iránya is kötelező (a munkacsoport-lap
  // validációjával azonosan — a backend publishGroupRateInternal csak az alap-párt nézi).
  for (const r of valid) {
    const bands: Array<[string, number | null, number | null]> = [
      ['L1', r.values.limit1BuyRate ?? null, r.values.limit1SellRate ?? null],
      ['L2', r.values.limit2BuyRate ?? null, r.values.limit2SellRate ?? null],
      ['L3', r.values.limit3BuyRate ?? null, r.values.limit3SellRate ?? null],
    ]
    for (const [label, b, sRate] of bands) {
      if (b != null && b > 0 && sRate != null && sRate > 0 && b >= sRate) {
        return {
          rates: [],
          protectionRows: [],
          error: `${r.currencyCode} ${label}: sáv-vétel (${b}) >= sáv-eladás (${sRate})`,
        }
      }
    }
  }

  const rates: PublishGroupRateRequest['rates'] = valid.map((r) => ({
    currencyId: r.currencyId,
    buyRate: r.values.buyRate!,
    sellRate: r.values.sellRate!,
    officialRate: r.values.officialRate ?? null,
    limit1Amount: group.limit1Boundary || null,
    limit1BuyRate: r.values.limit1BuyRate ?? null,
    limit1SellRate: r.values.limit1SellRate ?? null,
    limit2Amount: group.limit2Boundary || null,
    limit2BuyRate: r.values.limit2BuyRate ?? null,
    limit2SellRate: r.values.limit2SellRate ?? null,
    limit3Amount: group.limit3Boundary || null,
    limit3BuyRate: r.values.limit3BuyRate ?? null,
    limit3SellRate: r.values.limit3SellRate ?? null,
  }))

  const protectionRows: ProtectionRow[] = valid.map((r) => ({
    currencyCode: r.currencyCode,
    official: r.values.officialRate ?? null,
    buy: r.values.buyRate ?? 0,
    sell: r.values.sellRate ?? 0,
    limit1Buy: r.values.limit1BuyRate ?? 0,
    limit1Sell: r.values.limit1SellRate ?? 0,
    limit2Buy: r.values.limit2BuyRate ?? 0,
    limit2Sell: r.values.limit2SellRate ?? 0,
    limit3Buy: r.values.limit3BuyRate ?? 0,
    limit3Sell: r.values.limit3SellRate ?? 0,
  }))

  return { rates, protectionRows }
}

export async function publishAllWorkgroups(opts: PublishAllOptions = {}): Promise<PublishAllResult> {
  // Adatbetöltés: bootstrap (egy kör), fallback overview+workgroups (a RateCreationPage.loadData mintája).
  let overview: RateOverviewItem[]
  let workgroups: WorkgroupDetailDTO[]
  if (opts.preloaded) {
    overview = opts.preloaded.overview
    workgroups = opts.preloaded.workgroups
  } else {
    try {
      const bootstrap = await rateCreationApi.getLocalRateMakerBootstrap()
      overview = bootstrap.overview.currencies
      workgroups = bootstrap.workgroups
    } catch {
      const [overviewResponse, workgroupResponse] = await Promise.all([
        rateCreationApi.getOverview(),
        rateCreationApi.getWorkgroupDetails(),
      ])
      overview = overviewResponse.currencies
      workgroups = workgroupResponse
    }
  }

  const activeGroups = workgroups.filter((g) => g.active)
  const total = activeGroups.length
  const outcomes: GroupPublishOutcome[] = []
  let done = 0

  // A képlet-kontextus egyszer töltődik (0-s lap A–I + más csoportok J–S pillanatképei).
  const sheet0ByCurrency = loadSheet0ByCurrency()
  const otherGroupsByCurrency = loadAllGroupValueSnapshots()

  // Codex P1 #1118: az épp nyitott csoport FRISS, memóriabeli értékeit beültetjük a
  // `#NN` kereszt-hivatkozási kontextusba — különben a rá hivatkozó csoportok a
  // perzisztált (elavult / fix-csoportnál hiányzó) pillanatképpel számolnának.
  if (opts.inMemoryGroupRates) {
    const memGroup = activeGroups.find((g) => g.id === opts.inMemoryGroupRates!.groupId)
    if (memGroup?.legacyGroupNumber != null) {
      const codeById = new Map(overview.map((c) => [c.currencyId, c.currencyCode.toUpperCase()]))
      const byCurrency = new Map<string, WgValues>()
      for (const r of opts.inMemoryGroupRates.rates) {
        const code = codeById.get(r.currencyId)
        if (!code) continue
        const wgv: WgValues = { L: r.buyRate, M: r.sellRate }
        if (r.officialRate != null) wgv.J = r.officialRate
        if (r.limit1BuyRate != null) wgv.N = r.limit1BuyRate
        if (r.limit1SellRate != null) wgv.O = r.limit1SellRate
        if (r.limit2BuyRate != null) wgv.P = r.limit2BuyRate
        if (r.limit2SellRate != null) wgv.Q = r.limit2SellRate
        if (r.limit3BuyRate != null) wgv.R = r.limit3BuyRate
        if (r.limit3SellRate != null) wgv.S = r.limit3SellRate
        byCurrency.set(code, wgv)
      }
      otherGroupsByCurrency.set(memGroup.legacyGroupNumber, byCurrency)
    }
  }

  // NFR-2: csoportonként független publikálás — egy csoport hibája nem állítja le a többit.
  await Promise.allSettled(activeGroups.map(async (group) => {
    const outcome: GroupPublishOutcome = {
      groupId: group.id, code: group.code, name: group.name, status: 'failed',
    }
    try {
      let rates: PublishGroupRateRequest['rates']
      if (opts.inMemoryGroupRates && opts.inMemoryGroupRates.groupId === group.id) {
        rates = opts.inMemoryGroupRates.rates
      } else {
        const built = await buildGroupRates(group, overview, sheet0ByCurrency, otherGroupsByCurrency)
        if (built.error) {
          outcome.message = built.error
          outcomes.push(outcome)
          return
        }
        if (built.rates.length === 0) {
          outcome.status = 'skipped'
          outcome.message = 'nincs érvényes árfolyam a csoportban'
          outcomes.push(outcome)
          return
        }
        // FK-04/E árfolyamvédelem: a lap-oldali publish-sal AZONOS szabály (a backend
        // RatePublishService.validateRateProtection a kiküldéskor ugyanígy véd).
        if (group.protectionEnabled ?? true) {
          const violations = validateWorkgroupProtection(
            built.protectionRows, true, workgroupProtectionLabel(group.legacyGroupNumber, group.code),
          )
          if (violations.length > 0) {
            outcome.message = `árfolyamvédelem: ${violations[0]!.message}`
            outcomes.push(outcome)
            return
          }
        }
        rates = built.rates
      }

      const result = await rateCreationApi.publishGroupRate({ groupId: group.id, rates })
      outcome.status = 'published'
      if (result && 'acceptedRates' in result) outcome.acceptedRates = result.acceptedRates
      // FK02-B: publikálás után a szerver az authority — a csoport overlay-ét töröljük
      // (localStorage + SQLite), ahogy a munkacsoport-lap publish-a is teszi.
      persistGroupRateValues(group.id, {})
      outcomes.push(outcome)
    } catch (err: unknown) {
      outcome.message = err instanceof Error ? err.message : 'ismeretlen publikálási hiba'
      outcomes.push(outcome)
    } finally {
      done += 1
      opts.onProgress?.(done, total)
    }
  }))

  return {
    total,
    published: outcomes.filter((o) => o.status === 'published').length,
    outcomes,
  }
}

/** FR-8: emberi összefoglaló a toast-okhoz — "X/Y elküldve" + első hibák. */
export function summarizePublishAll(result: PublishAllResult): { title: string; detail: string; ok: boolean } {
  const failed = result.outcomes.filter((o) => o.status === 'failed')
  const skipped = result.outcomes.filter((o) => o.status === 'skipped')
  const parts: string[] = [`${result.published}/${result.total} munkacsoport elküldve`]
  if (skipped.length > 0) parts.push(`${skipped.length} kihagyva (nincs árfolyam)`)
  if (failed.length > 0) {
    const first = failed.slice(0, 3).map((f) => `${f.name}: ${f.message ?? 'hiba'}`)
    parts.push(`HIBA: ${first.join('; ')}${failed.length > 3 ? ` (+${failed.length - 3} további)` : ''}`)
  }
  return {
    title: failed.length === 0 ? 'Szétküldve' : 'Részben sikeres szétküldés',
    detail: parts.join(' — '),
    ok: failed.length === 0,
  }
}
