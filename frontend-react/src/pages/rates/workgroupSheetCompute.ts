/**
 * FK-04/C — Munkacsoport árfolyamlap reaktív képlet-újraszámítás.
 *
 * A `workgroupSheetFormula` (FK-03) képletmotor LAP-szintű bekötése: a felhasználói
 * képlet-stringeket (J–S cellánként) feloldja numerikus értékekre, kezelve a
 * cellák közötti függőségeket (self J–S, 0-s lap A–I, `!<oszlop><KÓD>` kereszt-valuta,
 * `#NN<oszlop>` kereszt-csoport).
 *
 * A 0-s lap (`MainRateSheetPage`) bevált Jacobi-fixpont mintáját általánosítja:
 * minden passzban a passz-eleji pillanatképből számolunk minden képlet-cellát, majd
 * alkalmazunk. Aciklikus gráfon ≤ mélység lépésben konvergál; körhivatkozásnál a
 * `maxIter` cap megállít és a részeredményt ELVETJÜK (a korábbi stabil érték marad).
 *
 * Pure, izoláltan tesztelhető (workgroupSheetCompute.test.ts).
 */

import {
  evaluateWorkgroupFormula,
  type Sheet0Values,
  type WgValues,
  type WgCol,
  type WorkgroupFormulaContext,
} from './workgroupSheetFormula'

/** A munkacsoport-lap szerkeszthető (képletezhető) mezői — a K (ISO kód) kivételével. */
export type WgField =
  | 'officialRate' // J — elszámoló
  | 'buyRate' // L — alap vétel
  | 'sellRate' // M — alap eladás
  | 'limit1BuyRate' // N
  | 'limit1SellRate' // O
  | 'limit2BuyRate' // P
  | 'limit2SellRate' // Q
  | 'limit3BuyRate' // R
  | 'limit3SellRate' // S

/** Mező → munkacsoport-oszlopbetű (a képletmotor WgCol-jaihoz). */
export const FIELD_TO_WGCOL: Record<WgField, Exclude<WgCol, 'K'>> = {
  officialRate: 'J',
  buyRate: 'L',
  sellRate: 'M',
  limit1BuyRate: 'N',
  limit1SellRate: 'O',
  limit2BuyRate: 'P',
  limit2SellRate: 'Q',
  limit3BuyRate: 'R',
  limit3SellRate: 'S',
}

export const WG_FIELDS = Object.keys(FIELD_TO_WGCOL) as WgField[]

/** Egy munkacsoport valuta-sora az újraszámításhoz: numerikus J–S értékek. */
export interface WgComputeRow {
  currencyId: number
  currencyCode: string
  /** A 9 szerkeszthető mező aktuális (fix vagy korábban kiszámolt) numerikus értéke. */
  values: Record<WgField, number | null>
}

export interface WorkgroupComputeInput {
  /** Az aktuális csoport valuta-sorai. */
  rows: WgComputeRow[]
  /** Felhasználói képletek, kulcs = `${currencyId}.${field}`. Üres → nincs képlet. */
  formulas: Record<string, string>
  /** 0-s lap A–I oszlop-értékek valutánként (a `A`–`I` és `!<oszlop><KÓD>` hivatkozásokhoz). */
  sheet0ByCurrency: Map<string, Sheet0Values>
  /** Más csoportok J–S értékei: csoportsorszám → (valutakód → J–S), a `#NN<oszlop>`-hez. */
  otherGroupsByCurrency: Map<number, Map<string, WgValues>>
  /** JPY-szerű 0-tizedes vs 2-tizedes kerekítés (alapért. 2). */
  decimalsFor?: (currencyCode: string) => number
}

export interface WorkgroupComputeResult {
  /** A feloldott numerikus értékek soronként (a képlet-cellák kiszámolva). */
  rows: WgComputeRow[]
  /** Cellánkénti képlet-hiba, kulcs = `${currencyId}.${field}` → hibaüzenet. */
  errors: Record<string, string>
  /** TRUE, ha a fixpont nem konvergált (körhivatkozás-gyanú) — a részeredmény elvetve. */
  diverged: boolean
}

/** A sor numerikus J–S értékeiből WgValues (a motor self/kereszt kontextusához). */
function rowToWgValues(values: Record<WgField, number | null>): WgValues {
  const out: WgValues = {}
  for (const field of WG_FIELDS) {
    const col = FIELD_TO_WGCOL[field]
    const v = values[field]
    if (v != null) out[col] = v
  }
  return out
}

const fmtKey = (currencyId: number, field: WgField): string => `${currencyId}.${field}`

/**
 * Reaktív újraszámítás: a képlet-cellákat feloldja, a fix cellák változatlanok.
 *
 * @returns feloldott sorok + cellánkénti hibák + konvergencia-jelző.
 */
export function recomputeWorkgroupSheet(input: WorkgroupComputeInput): WorkgroupComputeResult {
  const { rows, formulas, sheet0ByCurrency, otherGroupsByCurrency } = input
  // A 0-s lap (MainRateSheetPage) képlet-újraszámítója JPY-re 3, egyébként 2 tizedessel
  // kerekít — a munkacsoport-lap KÖVESSE ezt (Codex FK-04/C P1: a JPY-rátáknak 3 tizedes
  // a precizitása, a 0-ra kerekítés elveszítené a tört-fillért).
  const decimalsFor = input.decimalsFor ?? ((code: string) => (code.toUpperCase() === 'JPY' ? 3 : 2))

  const formulaKeys = Object.keys(formulas)
  const errors: Record<string, string> = {}

  // Nincs képlet → a fix értékek változatlanok (gyors út).
  if (formulaKeys.length === 0) {
    return { rows: rows.map((r) => ({ ...r, values: { ...r.values } })), errors, diverged: false }
  }

  // Working copy — minden passz ezt frissíti.
  let working: WgComputeRow[] = rows.map((r) => ({ ...r, values: { ...r.values } }))
  const maxIter = formulaKeys.length + 2
  let converged = false

  for (let iter = 0; iter < maxIter; iter++) {
    // Passz-eleji pillanatkép: az aktuális csoport J–S értékei valutakód szerint.
    const selfByCurrency = new Map<string, WgValues>()
    for (const r of working) selfByCurrency.set(r.currencyCode.toUpperCase(), rowToWgValues(r.values))

    let changedThisPass = false
    const passErrors: Record<string, string> = {}

    const next: WgComputeRow[] = working.map((row) => {
      const code = row.currencyCode.toUpperCase()
      // #NN kontextus: csoportsorszám → ENNEK a valutának a J–S értékei az adott csoportban.
      const workgroupsByNumber = new Map<number, WgValues>()
      for (const [groupNum, byCur] of otherGroupsByCurrency) {
        const wgv = byCur.get(code)
        if (wgv) workgroupsByNumber.set(groupNum, wgv)
      }
      const ctx: WorkgroupFormulaContext = {
        sheet0Self: sheet0ByCurrency.get(code) ?? {},
        sheet0ByCurrency,
        workgroupSelf: selfByCurrency.get(code) ?? {},
        workgroupsByNumber,
      }

      let nextValues = row.values
      for (const field of WG_FIELDS) {
        const f = formulas[fmtKey(row.currencyId, field)]
        if (!f) continue
        // FK02-D (FR-8): a 0-s lap egybetűs rövidített hivatkozása (E/F/C) csak a vételi (L) és
        // eladási (M) oszlopnál érvényes; a többi mezőnél a kiértékelő hibát ad (VV-VALID-004).
        const col = FIELD_TO_WGCOL[field]
        const res = evaluateWorkgroupFormula(f, ctx, { allowSheet0Shorthand: col === 'L' || col === 'M' })
        if ('error' in res) {
          passErrors[fmtKey(row.currencyId, field)] = res.error
          continue // hibás képlet → érték marad (a hover/edit jelzi a képletet)
        }
        const val = Number(res.value.toFixed(decimalsFor(row.currencyCode)))
        if (nextValues[field] !== val) {
          if (nextValues === row.values) nextValues = { ...row.values }
          nextValues[field] = val
          changedThisPass = true
        }
      }
      return nextValues === row.values ? row : { ...row, values: nextValues }
    })

    working = next
    // Az utolsó passz hibái a mérvadók (a konvergált állapoté).
    Object.assign(errors, passErrors)
    for (const k of Object.keys(errors)) if (!(k in passErrors)) delete errors[k]

    if (!changedThisPass) {
      converged = true
      break
    }
  }

  if (!converged) {
    // Körhivatkozás-gyanú: a tetszőleges nem-konvergált részeredményt NEM commitoljuk
    // (mint a 0-s lapnál) — az eredeti fix értékek maradnak.
    return {
      rows: rows.map((r) => ({ ...r, values: { ...r.values } })),
      errors,
      diverged: true,
    }
  }

  return { rows: working, errors, diverged: false }
}
