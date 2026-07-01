import { describe, it, expect } from 'vitest'
import { evaluateDeviationWarning, parseCellNumber } from './mainSheetCommit'

// FK06 — a Főlap E (vétel) / F (eladás) 10%-os eltérés-figyelmeztetésének tiszta döntési logikája.
// A page-komponens `commitCell` ezt hívja; a küszöb a közös deviationCheck.ts (10%).

describe('FK06 — Főlap E/F 10%-os eltérés-figyelmeztetés (evaluateDeviationWarning)', () => {
  it('e_column_over_threshold_prompts_confirm: EUR E 400→450 (12,5%) → figyelmeztet', () => {
    const d = evaluateDeviationWarning('weakMultiBuy', '450', 400)
    expect(d.warn).toBe(true)
    expect(d.previous).toBe(400)
    expect(d.next).toBe(450)
    expect(d.percent).toBe(13) // Math.round(12.5%) = 13
  })

  it('f_column_over_threshold_prompts_confirm: F 420→370 (11,9%) → figyelmeztet', () => {
    // Megj.: a spec FR-2 példája (420→380) valójában 9,52% (<10%), ezért az helyesen NEM riaszt;
    // a küszöb a közös deviationCheck.ts (10%). Itt egy valóban >10%-os F-eltérést tesztelünk.
    const d = evaluateDeviationWarning('weakMultiSell', '370', 420)
    expect(d.warn).toBe(true)
    expect(d.previous).toBe(420)
    expect(d.next).toBe(370)
    expect(d.percent).toBe(12) // |370-420|/420 = 11,9% → round = 12
  })

  it('f_column_just_under_threshold_no_prompt: F 420→380 (9,52%) → NINCS figyelmeztetés', () => {
    // A spec-példa tényellenőrzése: 380 valójában küszöb alatt van.
    expect(evaluateDeviationWarning('weakMultiSell', '380', 420).warn).toBe(false)
  })

  it('under_threshold_no_prompt: 400→410 (2,5%) → NINCS figyelmeztetés', () => {
    expect(evaluateDeviationWarning('weakMultiBuy', '410', 400).warn).toBe(false)
  })

  it('a_b_c_h_columns_no_prompt: nem E/F oszlop → soha nem figyelmeztet (nagy eltérésnél sem)', () => {
    for (const col of ['settlement', 'otp', 'helper', 'crossRate', 'wholesale']) {
      expect(evaluateDeviationWarning(col, '999', 400).warn).toBe(false)
    }
  })

  it('empty_baseline_no_false_alarm: null/0/üres baseline → nincs riasztás (FR-5)', () => {
    expect(evaluateDeviationWarning('weakMultiBuy', '450', null).warn).toBe(false)
    expect(evaluateDeviationWarning('weakMultiBuy', '450', 0).warn).toBe(false)
  })

  it('formula_not_guarded: E oszlopba írt KÉPLET nem korlátozott (csak fix szám)', () => {
    expect(evaluateDeviationWarning('weakMultiBuy', '=C*0,97', 400).warn).toBe(false)
    expect(evaluateDeviationWarning('weakMultiBuy', 'C*2', 400).warn).toBe(false)
  })

  it('empty_or_nonnumeric_input_no_warn: üres / nem-szám input → nincs riasztás', () => {
    expect(evaluateDeviationWarning('weakMultiBuy', '', 400).warn).toBe(false)
    expect(evaluateDeviationWarning('weakMultiBuy', 'abc', 400).warn).toBe(false)
  })

  it('exactly_10_percent_triggers: pontosan 10% eltérés is figyelmeztet (küszöb-paritás)', () => {
    // 400 → 440 = pontosan 10% (a deviationCheck.ts epsilon-tűréssel triggerel)
    expect(evaluateDeviationWarning('weakMultiBuy', '440', 400).warn).toBe(true)
  })

  it('negative_direction_triggers: csökkenő irányú >10% eltérés is figyelmeztet', () => {
    const d = evaluateDeviationWarning('weakMultiSell', '350', 400) // -12,5%
    expect(d.warn).toBe(true)
  })

  it('magyar_tizedesjel_parse: vesszős/szóközös input helyesen parse-ol', () => {
    expect(parseCellNumber('1 234,56')).toBeCloseTo(1234.56)
    expect(parseCellNumber('450')).toBe(450)
    expect(parseCellNumber('')).toBeNull()
    expect(parseCellNumber('xyz')).toBeNull()
  })
})
