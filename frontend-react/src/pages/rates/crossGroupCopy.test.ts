import { describe, it, expect } from 'vitest'
import { applyCrossGroupCopy, type CrossGroupCopyCell } from './crossGroupCopy'

/** FK02-D — FR-13: a kijelölt cellák tartalma a célcsoport azonos pozícióiba (érték/képlet). */
describe('applyCrossGroupCopy (FR-13)', () => {
  it('képlet-cella → a cél formula-tárolójába, a fix érték törlődik', () => {
    const cells: CrossGroupCopyCell[] = [{ key: '1.buyRate', formula: '!EAUD*0.97' }]
    const res = applyCrossGroupCopy({}, { '1.buyRate': '380' }, cells)
    expect(res.formulas['1.buyRate']).toBe('!EAUD*0.97')
    expect(res.values['1.buyRate']).toBeUndefined()
  })

  it('fix érték-cella → a cél group_rate_values-be, a képlet törlődik', () => {
    const cells: CrossGroupCopyCell[] = [{ key: '1.buyRate', value: '395' }]
    const res = applyCrossGroupCopy({ '1.buyRate': 'régi képlet' }, {}, cells)
    expect(res.values['1.buyRate']).toBe('395')
    expect(res.formulas['1.buyRate']).toBeUndefined()
  })

  it('üres forrás-cella → a cél mindkét tárolójából törlődik', () => {
    const cells: CrossGroupCopyCell[] = [{ key: '1.buyRate', formula: '', value: '' }]
    const res = applyCrossGroupCopy({ '1.buyRate': 'f' }, { '1.buyRate': 'v' }, cells)
    expect(res.formulas['1.buyRate']).toBeUndefined()
    expect(res.values['1.buyRate']).toBeUndefined()
  })

  it('a cél korábbi, NEM érintett kulcsai megmaradnak', () => {
    const cells: CrossGroupCopyCell[] = [{ key: '1.buyRate', value: '100' }]
    const res = applyCrossGroupCopy({ '2.sellRate': 'megmarad' }, { '3.buyRate': '999' }, cells)
    expect(res.formulas['2.sellRate']).toBe('megmarad')
    expect(res.values['3.buyRate']).toBe('999')
    expect(res.values['1.buyRate']).toBe('100')
  })

  it('több cella egyszerre (vegyes képlet + érték)', () => {
    const cells: CrossGroupCopyCell[] = [
      { key: '1.buyRate', formula: 'F+1' },
      { key: '1.sellRate', value: '410' },
    ]
    const res = applyCrossGroupCopy({}, {}, cells)
    expect(res.formulas['1.buyRate']).toBe('F+1')
    expect(res.values['1.sellRate']).toBe('410')
  })

  it('nem mutálja a bemenő térképeket', () => {
    const tf = { '1.buyRate': 'orig' }
    const tv = { '1.sellRate': '1' }
    applyCrossGroupCopy(tf, tv, [{ key: '1.buyRate', value: '2' }])
    expect(tf).toEqual({ '1.buyRate': 'orig' })
    expect(tv).toEqual({ '1.sellRate': '1' })
  })
})
