import { describe, expect, it } from 'vitest'
import { buildDenominationPayload } from './transferRules'

/**
 * FK-072_v2 FR-4 (frontend): az átadás címletezési sorában az 1 alatti névérték
 * elutasítása. A buildDenominationPayload ma a 0 < faceValue < 1 sort érvényesként
 * elfogadja (csak <= 0-t szűr) — az elvárt új viselkedés: egyértelmű magyar hiba,
 * NEM néma kihagyás (az néma összeg-eltérést okozna).
 */
describe('buildDenominationPayload — FK-072_v2 tört címletek (FR-4, FR-7)', () => {
  it('FR-4: 1 alatti névérték (0,5) → hiba, nincs beküldhető payload', () => {
    const result = buildDenominationPayload(
      true,
      [{ quantity: '200', faceValue: '0,5' }],
      100,
    )

    expect(result.denominations).toBeUndefined()
    expect(result.error).toBeTruthy()
    expect(result.error).toMatch(/1-nél kisebb/)
  })

  it('FR-7 regresszió: egész névértékek (1-es és 2-es is) változatlanul átmennek', () => {
    const result = buildDenominationPayload(
      true,
      [
        { quantity: '50', faceValue: '1' },
        { quantity: '25', faceValue: '2' },
      ],
      100,
    )

    expect(result.error).toBeUndefined()
    expect(result.denominations).toEqual([
      { quantity: 50, faceValue: 1 },
      { quantity: 25, faceValue: 2 },
    ])
  })
})
