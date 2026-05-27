/**
 * Munkacsoport árfolyamlap (FK-03) — képlet-motor.
 *
 * A 0-s lap (FK-01, mainSheetFormula.ts) szintaxisának kiterjesztése a munkacsoportos
 * hivatkozásokkal. NINCS `=` prefix. Magyar tizedesvessző (`0,97`) és pont is elfogadott.
 *
 * Hivatkozás-típusok:
 *  - `A`–`I`         → a 0-s lap adott oszlopa, az AKTUÁLIS valuta sorában (self, sheet 0).
 *                      (A `D` az ISO-kód címke, nem hivatkozható numerikusan.)
 *  - `J`–`S`         → az AKTUÁLIS munkacsoport adott oszlopa, az aktuális valuta sorában (self, wg).
 *                      (A `K` az ISO-kód, nem hivatkozható numerikusan.)
 *  - `!<oszlop><KÓD>`→ másik valuta adott oszlopa a 0-s lapon. Pl. `!FEUR` = EUR F oszlopa.
 *  - `#<NN><oszlop>` → másik munkacsoport (NN = kétjegyű sorszám) J–S oszlopa, az aktuális
 *                      valuta sorában. Pl. `#01L` = a 01-es csoport L oszlopa.
 *  - Műveletek: `+ - * /` és zárójel.
 *
 * Pure, izoláltan tesztelhető (workgroupSheetFormula.test.ts). Hibára NEM dob, hanem
 * `{ error }`-t ad. A ciklus-detektálás a lap-szintű iteratív újraszámításé
 * (extractWorkgroupDependencies adja a függőség-gráfot, ami munkacsoportok között is átível).
 */

/** localStorage kulcs-prefix a munkacsoport-lap képleteihez (csoportonként külön kulcs). */
export const WORKGROUP_FORMULA_STORAGE_PREFIX = 'arfolyamkeszito.workgroupSheet.formulas.v1'

/**
 * A 0-s lap NUMERIKUSAN hivatkozható oszlopai. A `D` az ISO-valutakód címke (string),
 * ezért — a 0-s lap motorjával (mainSheetFormula.FORMULA_COL_LETTERS) egyezően — kizárt;
 * `D` / `!D<KÓD>` érvénytelen hivatkozás, nem ad numerikus értéket (Codex FK-03 P2).
 */
export const SHEET0_COLS = ['A', 'B', 'C', 'E', 'F', 'G', 'H', 'I'] as const
export type Sheet0Col = typeof SHEET0_COLS[number]

/** A munkacsoport-lap hivatkozható oszlopai (J–S). A K (ISO kód) nem ad numerikus értéket. */
export const WG_COLS = ['J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S'] as const
export type WgCol = typeof WG_COLS[number]

export type Sheet0Values = Partial<Record<Sheet0Col, number>>
export type WgValues = Partial<Record<WgCol, number>>

export interface WorkgroupFormulaContext {
  /** Aktuális valuta 0-s lap oszlop-értékei (A–I) — self sheet0 hivatkozásokhoz. */
  sheet0Self: Sheet0Values
  /** Valutakód → 0-s lap oszlop-értékek — a `!<oszlop><KÓD>` kereszt-hivatkozásokhoz. */
  sheet0ByCurrency: Map<string, Sheet0Values>
  /** Aktuális munkacsoport, aktuális valuta J–S oszlop-értékei — self wg hivatkozásokhoz. */
  workgroupSelf: WgValues
  /** Csoportsorszám → aktuális valuta J–S oszlop-értékei — a `#NN<oszlop>` hivatkozásokhoz. */
  workgroupsByNumber: Map<number, WgValues>
}

export type WorkgroupFormulaRef =
  | { kind: 'sheet0Self'; col: Sheet0Col }
  | { kind: 'sheet0Cross'; currency: string; col: Sheet0Col }
  | { kind: 'wgSelf'; col: WgCol }
  | { kind: 'wgCross'; group: number; col: WgCol }

export type EvalResult = { value: number } | { error: string }

const NUMBER_RE = /^-?(?:\d+(?:[.,]\d+)?|[.,]\d+)$/

function isSheet0Col(ch: string): ch is Sheet0Col {
  return (SHEET0_COLS as readonly string[]).includes(ch)
}
function isWgCol(ch: string): ch is WgCol {
  return (WG_COLS as readonly string[]).includes(ch)
}

/** Igaz, ha a beírt szöveg KÉPLET (nem tiszta szám). Üres → false (auto). */
export function isFormula(input: string): boolean {
  const t = input.trim()
  if (t.length === 0) return false
  return !NUMBER_RE.test(t)
}

/** Magyar tizedesvessző (vagy pont) → szám. NaN-ra `null`. */
export function parseNumber(token: string): number | null {
  const n = Number(token.trim().replace(',', '.'))
  return Number.isFinite(n) ? n : null
}

// --- Tokenizer ---

type Token =
  | { kind: 'num'; value: number }
  | { kind: 'sheet0Self'; col: Sheet0Col }
  | { kind: 'sheet0Cross'; currency: string; col: Sheet0Col }
  | { kind: 'wgSelf'; col: WgCol }
  | { kind: 'wgCross'; group: number; col: WgCol }
  | { kind: 'op'; op: '+' | '-' | '*' | '/' }
  | { kind: 'lparen' }
  | { kind: 'rparen' }

class TokenizeError extends Error {}
class ParseError extends Error {}

function tokenize(input: string): Token[] {
  const tokens: Token[] = []
  const s = input.trim()
  let i = 0
  const isDigit = (c: string | undefined): boolean => c !== undefined && c >= '0' && c <= '9'
  while (i < s.length) {
    const ch = s[i]!
    if (ch === ' ' || ch === '\t') { i++; continue }
    if (ch === '+' || ch === '-' || ch === '*' || ch === '/') { tokens.push({ kind: 'op', op: ch }); i++; continue }
    if (ch === '(') { tokens.push({ kind: 'lparen' }); i++; continue }
    if (ch === ')') { tokens.push({ kind: 'rparen' }); i++; continue }
    // szám — egész vagy vezető-tizedes (magyar `,97` / `.97`) operandus is (Codex P2)
    if (isDigit(ch) || ((ch === ',' || ch === '.') && isDigit(s[i + 1]))) {
      let j = i + 1
      while (j < s.length && (isDigit(s[j]) || s[j] === ',' || s[j] === '.')) j++
      const num = parseNumber(s.slice(i, j))
      if (num === null) throw new TokenizeError(`Érvénytelen szám: ${s.slice(i, j)}`)
      tokens.push({ kind: 'num', value: num })
      i = j
      continue
    }
    // kereszt-valuta a 0-s lapon: !<oszlop A–I><VALUTAKÓD>
    if (ch === '!') {
      const colCh = s[i + 1]?.toUpperCase()
      if (!colCh || !isSheet0Col(colCh)) {
        throw new TokenizeError(`Érvénytelen kereszt-hivatkozás (oszlop A–I, a D ISO-kód kizárva): ${s.slice(i, i + 2)}`)
      }
      let j = i + 2
      while (j < s.length && /[A-Za-z0-9]/.test(s[j]!)) j++
      const currency = s.slice(i + 2, j).toUpperCase()
      if (currency.length === 0) throw new TokenizeError(`Hiányzó valutakód: ${s.slice(i, j)}`)
      tokens.push({ kind: 'sheet0Cross', currency, col: colCh })
      i = j
      continue
    }
    // kereszt-munkacsoport: #<NN kétjegyű><oszlop J–S>
    if (ch === '#') {
      const d1 = s[i + 1], d2 = s[i + 2], colCh = s[i + 3]?.toUpperCase()
      if (!isDigit(d1) || !isDigit(d2)) {
        throw new TokenizeError(`Érvénytelen csoport-hivatkozás (kétjegyű szám kell): ${s.slice(i, i + 3)}`)
      }
      if (colCh && isDigit(colCh)) {
        throw new TokenizeError(`A csoport-hivatkozás kétjegyű sorszámot vár (#NN<oszlop>): ${s.slice(i, i + 4)}`)
      }
      if (!colCh || !isWgCol(colCh)) {
        throw new TokenizeError(`Érvénytelen csoport-oszlop (J–S): ${s.slice(i, i + 4)}`)
      }
      tokens.push({ kind: 'wgCross', group: Number(`${d1}${d2}`), col: colCh })
      i += 4
      continue
    }
    // self oszlop-hivatkozás: egyetlen betű. A–I → 0-s lap, J–S → munkacsoport.
    if (/[A-Za-z]/.test(ch)) {
      const up = ch.toUpperCase()
      const nextCh = s[i + 1]
      if (nextCh && /[A-Za-z]/.test(nextCh)) {
        throw new TokenizeError(`Ismeretlen azonosító (másik valutát '!' előzze meg): ${s.slice(i)}`)
      }
      if (isSheet0Col(up)) tokens.push({ kind: 'sheet0Self', col: up })
      else if (isWgCol(up)) tokens.push({ kind: 'wgSelf', col: up })
      else throw new TokenizeError(`Érvénytelen oszlop-hivatkozás: ${ch}`)
      i++
      continue
    }
    throw new TokenizeError(`Érvénytelen karakter: ${ch}`)
  }
  return tokens
}

function resolveRef(
  token: Extract<Token, { kind: 'sheet0Self' | 'sheet0Cross' | 'wgSelf' | 'wgCross' }>,
  ctx: WorkgroupFormulaContext,
): number {
  switch (token.kind) {
    case 'sheet0Self': {
      const v = ctx.sheet0Self[token.col]
      if (v === undefined || v === null) throw new ParseError(`Nincs érték a 0-s lap ${token.col} oszlopában`)
      return v
    }
    case 'sheet0Cross': {
      const row = ctx.sheet0ByCurrency.get(token.currency)
      if (!row) throw new ParseError(`Ismeretlen valuta: ${token.currency}`)
      const v = row[token.col]
      if (v === undefined || v === null) throw new ParseError(`Nincs érték: !${token.col}${token.currency}`)
      return v
    }
    case 'wgSelf': {
      if (token.col === 'K') throw new ParseError('A K oszlop (ISO kód) nem hivatkozható')
      const v = ctx.workgroupSelf[token.col]
      if (v === undefined || v === null) throw new ParseError(`Nincs érték a(z) ${token.col} oszlopban`)
      return v
    }
    case 'wgCross': {
      if (token.col === 'K') throw new ParseError('A K oszlop (ISO kód) nem hivatkozható')
      const row = ctx.workgroupsByNumber.get(token.group)
      if (!row) throw new ParseError(`Ismeretlen munkacsoport: #${String(token.group).padStart(2, '0')}`)
      const v = row[token.col]
      if (v === undefined || v === null) {
        throw new ParseError(`Nincs érték: #${String(token.group).padStart(2, '0')}${token.col}`)
      }
      return v
    }
  }
}

function evalTokens(tokens: Token[], ctx: WorkgroupFormulaContext): number {
  let pos = 0
  const peek = () => tokens[pos]
  const next = () => tokens[pos++]

  function parseExpr(): number {
    let val = parseTerm()
    for (;;) {
      const t = peek()
      if (!t || t.kind !== 'op' || (t.op !== '+' && t.op !== '-')) break
      next()
      const rhs = parseTerm()
      val = t.op === '+' ? val + rhs : val - rhs
    }
    return val
  }
  function parseTerm(): number {
    let val = parseFactor()
    for (;;) {
      const t = peek()
      if (!t || t.kind !== 'op' || (t.op !== '*' && t.op !== '/')) break
      next()
      const rhs = parseFactor()
      if (t.op === '/') {
        if (rhs === 0) throw new ParseError('Nullával osztás')
        val = val / rhs
      } else val = val * rhs
    }
    return val
  }
  function parseFactor(): number {
    const t = peek()
    if (!t) throw new ParseError('Váratlan képlet-vég')
    if (t.kind === 'op' && t.op === '-') { next(); return -parseFactor() }
    if (t.kind === 'op' && t.op === '+') { next(); return parseFactor() }
    if (t.kind === 'num') { next(); return t.value }
    if (t.kind === 'sheet0Self' || t.kind === 'sheet0Cross' || t.kind === 'wgSelf' || t.kind === 'wgCross') {
      next(); return resolveRef(t, ctx)
    }
    if (t.kind === 'lparen') {
      next()
      const v = parseExpr()
      const close = next()
      if (!close || close.kind !== 'rparen') throw new ParseError('Hiányzó záró zárójel')
      return v
    }
    throw new ParseError('Érvénytelen kifejezés')
  }

  const result = parseExpr()
  if (pos !== tokens.length) throw new ParseError('Felesleges tokenek a képlet végén')
  return result
}

/** Kiértékeli a munkacsoport-lap képletét. Hibára `{ error }`. */
export function evaluateWorkgroupFormula(formula: string, ctx: WorkgroupFormulaContext): EvalResult {
  try {
    const tokens = tokenize(formula)
    if (tokens.length === 0) return { error: 'Üres képlet' }
    const value = evalTokens(tokens, ctx)
    if (!Number.isFinite(value)) return { error: 'Nem véges eredmény' }
    return { value }
  } catch (e) {
    if (e instanceof TokenizeError || e instanceof ParseError) return { error: e.message }
    return { error: 'Képlet-kiértékelési hiba' }
  }
}

/** A képlet által hivatkozott cellák (reaktív újraszámításhoz / ciklus-detektáláshoz). */
export function extractWorkgroupDependencies(formula: string): WorkgroupFormulaRef[] {
  let tokens: Token[]
  try {
    tokens = tokenize(formula)
  } catch {
    return []
  }
  const refs: WorkgroupFormulaRef[] = []
  for (const t of tokens) {
    if (t.kind === 'sheet0Self') refs.push({ kind: 'sheet0Self', col: t.col })
    else if (t.kind === 'sheet0Cross') refs.push({ kind: 'sheet0Cross', currency: t.currency, col: t.col })
    else if (t.kind === 'wgSelf') refs.push({ kind: 'wgSelf', col: t.col })
    else if (t.kind === 'wgCross') refs.push({ kind: 'wgCross', group: t.group, col: t.col })
  }
  return refs
}
