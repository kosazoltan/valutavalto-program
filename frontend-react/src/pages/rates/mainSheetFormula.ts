/**
 * Árfolyamkészítő Főlap (0-s lap) — legacy képlet-motor.
 *
 * A régi programból ismert szintaxis (NINCS `=` prefix):
 *  - Saját sor oszlop-hivatkozás: oszlopbetű (A/B/C/E/F) → az aktuális valuta adott oszlopa.
 *    Pl. `C*0,97`.
 *  - Kereszt-valuta: `!<OSZLOP><VALUTAKÓD>` → másik valuta sorának oszlopa. Pl. `!FEUR`.
 *  - Műveletek: `+ - * /` és zárójel.
 *  - Tizedeselválasztó: magyar vessző (`0,97`); a pont is elfogadott.
 *
 * Pure, izoláltan tesztelhető (mainSheetFormula.test.ts). Hibára NEM dob, hanem
 * `{ error }`-t ad (a hívó dönt a megjelenítésről). A ciklus-detektálás a lap-szintű
 * iteratív újraszámításé (extractDependencies adja hozzá a függőség-gráfot).
 */

/**
 * localStorage kulcs a Főlap-képletekhez. **v2** (2026-05-26): a szintaxis Excel-szerű
 * `=A1` (HyperFormula) → legacy `C*0,97`/`!FEUR`-ra váltott, ami inkompatibilis. Az új kulcs
 * eldobja a régi (parse-olhatatlan) `=A1` képleteket upgrade-kor — különben azok csendben
 * stale numerikus értékeket hagynának (Codex P1 / Copilot #863).
 */
export const FORMULA_STORAGE_KEY = 'arfolyamkeszito.mainSheet.formulas.v2'

/** A képletben hivatkozható érték-oszlopok (D=ISO-címke, G/H=kereszt-auto, I=nagybani — kizárva). */
export const FORMULA_COL_LETTERS = ['A', 'B', 'C', 'E', 'F'] as const
export type ColLetter = (typeof FORMULA_COL_LETTERS)[number]

export type ColValues = Partial<Record<ColLetter, number>>

export interface FormulaContext {
  /** Az aktuális valuta sorának oszlop-értékei (saját sor hivatkozásokhoz). */
  self: ColValues
  /** Valutakód → oszlop-értékek (kereszt-hivatkozásokhoz). Kulcs nagybetűs valutakód. */
  byCurrency: Map<string, ColValues>
}

export interface FormulaRef {
  /** undefined = saját sor; egyébként a hivatkozott valuta kódja (nagybetűs). */
  currency?: string
  col: ColLetter
}

export type EvalResult = { value: number } | { error: string }

// Tiszta szám: opcionális előjel + (egész[.tizedes] VAGY vezető-tizedes `,97`/`.97`).
const NUMBER_RE = /^-?(?:\d+(?:[.,]\d+)?|[.,]\d+)$/

function isColLetter(ch: string): ch is ColLetter {
  return (FORMULA_COL_LETTERS as readonly string[]).includes(ch)
}

/**
 * Igaz, ha a beírt szöveg KÉPLET (nem tiszta szám). Üres → false (auto). A magyar
 * tizedesvesszős tiszta szám (pl. `0,97`, `-5`, `100`) ÉRTÉK, nem képlet.
 */
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
  | { kind: 'self'; col: ColLetter }
  | { kind: 'cross'; currency: string; col: ColLetter }
  | { kind: 'op'; op: '+' | '-' | '*' | '/' }
  | { kind: 'lparen' }
  | { kind: 'rparen' }

class TokenizeError extends Error {}

function tokenize(input: string): Token[] {
  const tokens: Token[] = []
  const s = input.trim()
  let i = 0
  const isDigit = (c: string | undefined): boolean => c !== undefined && c >= '0' && c <= '9'
  while (i < s.length) {
    const ch = s[i]!
    if (ch === ' ' || ch === '\t') {
      i++
      continue
    }
    if (ch === '+' || ch === '-' || ch === '*' || ch === '/') {
      tokens.push({ kind: 'op', op: ch })
      i++
      continue
    }
    if (ch === '(') {
      tokens.push({ kind: 'lparen' })
      i++
      continue
    }
    if (ch === ')') {
      tokens.push({ kind: 'rparen' })
      i++
      continue
    }
    // szám (vessző VAGY pont tizedessel)
    if (isDigit(ch)) {
      let j = i + 1
      while (j < s.length && (isDigit(s[j]) || s[j] === ',' || s[j] === '.')) j++
      const num = parseNumber(s.slice(i, j))
      if (num === null) throw new TokenizeError(`Érvénytelen szám: ${s.slice(i, j)}`)
      tokens.push({ kind: 'num', value: num })
      i = j
      continue
    }
    // kereszt-hivatkozás: !<OSZLOP><VALUTAKÓD>
    if (ch === '!') {
      const colCh = s[i + 1]
      if (!colCh || !isColLetter(colCh.toUpperCase())) {
        throw new TokenizeError(`Érvénytelen kereszt-hivatkozás (oszlop): ${s.slice(i, i + 2)}`)
      }
      let j = i + 2
      while (j < s.length && /[A-Za-z0-9]/.test(s[j]!)) j++
      const currency = s.slice(i + 2, j).toUpperCase()
      if (currency.length === 0) throw new TokenizeError(`Hiányzó valutakód: ${s.slice(i, j)}`)
      tokens.push({ kind: 'cross', currency, col: colCh.toUpperCase() as ColLetter })
      i = j
      continue
    }
    // saját sor oszlop-hivatkozás: egyetlen érvényes oszlopbetű
    if (/[A-Za-z]/.test(ch)) {
      const up = ch.toUpperCase()
      const nextCh = s[i + 1]
      if (nextCh && /[A-Za-z]/.test(nextCh)) {
        throw new TokenizeError(`Ismeretlen azonosító (a valutát '!' előzze meg): ${s.slice(i)}`)
      }
      if (!isColLetter(up)) {
        throw new TokenizeError(`Érvénytelen oszlop-hivatkozás: ${ch}`)
      }
      tokens.push({ kind: 'self', col: up })
      i++
      continue
    }
    throw new TokenizeError(`Érvénytelen karakter: ${ch}`)
  }
  return tokens
}

// --- Recursive-descent parser + evaluator ---
// expr := term (('+'|'-') term)*
// term := factor (('*'|'/') factor)*
// factor := num | self | cross | '(' expr ')' | '-' factor

class ParseError extends Error {}

function resolveRef(
  token: { kind: 'self'; col: ColLetter } | { kind: 'cross'; currency: string; col: ColLetter },
  ctx: FormulaContext,
): number {
  if (token.kind === 'self') {
    const v = ctx.self[token.col]
    if (v === undefined || v === null)
      throw new ParseError(`Nincs érték a(z) ${token.col} oszlopban`)
    return v
  }
  const row = ctx.byCurrency.get(token.currency)
  if (!row) throw new ParseError(`Ismeretlen valuta: ${token.currency}`)
  const v = row[token.col]
  if (v === undefined || v === null)
    throw new ParseError(`Nincs érték: !${token.col}${token.currency}`)
  return v
}

function evalTokens(tokens: Token[], ctx: FormulaContext): number {
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
      } else {
        val = val * rhs
      }
    }
    return val
  }
  function parseFactor(): number {
    const t = peek()
    if (!t) throw new ParseError('Váratlan képlet-vég')
    if (t.kind === 'op' && t.op === '-') {
      next()
      return -parseFactor()
    }
    if (t.kind === 'op' && t.op === '+') {
      next()
      return parseFactor()
    }
    if (t.kind === 'num') {
      next()
      return t.value
    }
    if (t.kind === 'self' || t.kind === 'cross') {
      next()
      return resolveRef(t, ctx)
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

/** Kiértékeli a legacy képletet. Hibára `{ error }`. */
export function evaluateFormula(formula: string, ctx: FormulaContext): EvalResult {
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
export function extractDependencies(formula: string): FormulaRef[] {
  let tokens: Token[]
  try {
    tokens = tokenize(formula)
  } catch {
    return []
  }
  const refs: FormulaRef[] = []
  for (const t of tokens) {
    if (t.kind === 'self') refs.push({ col: t.col })
    else if (t.kind === 'cross') refs.push({ currency: t.currency, col: t.col })
  }
  return refs
}
