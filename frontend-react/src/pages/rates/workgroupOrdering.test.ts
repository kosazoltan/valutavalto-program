import { describe, it, expect } from 'vitest'
import { sortWorkgroupsBySequence } from './workgroupOrdering'

/** FK02-D — FR-14: csempék mindig sorszám (legacyGroupNumber) szerint növekvő. */
describe('sortWorkgroupsBySequence (FR-14)', () => {
  it('sorszám szerint növekvő, az API-sorrendtől függetlenül', () => {
    const input = [
      { id: 'c', legacyGroupNumber: 3, name: 'Harmadik' },
      { id: 'a', legacyGroupNumber: 1, name: 'Első' },
      { id: 'b', legacyGroupNumber: 2, name: 'Második' },
    ]
    const out = sortWorkgroupsBySequence(input)
    expect(out.map((w) => w.legacyGroupNumber)).toEqual([1, 2, 3])
    expect(out.map((w) => w.id)).toEqual(['a', 'b', 'c'])
  })

  it('sorszám nélküli (null/undefined) csoportok a lista végére kerülnek', () => {
    const input = [
      { id: 'x', legacyGroupNumber: null },
      { id: 'a', legacyGroupNumber: 2 },
      { id: 'y', legacyGroupNumber: undefined },
      { id: 'b', legacyGroupNumber: 1 },
    ]
    const out = sortWorkgroupsBySequence(input)
    expect(out.map((w) => w.id)).toEqual(['b', 'a', 'x', 'y'])
  })

  it('nem mutálja az eredeti tömböt (tiszta)', () => {
    const input = [{ legacyGroupNumber: 2 }, { legacyGroupNumber: 1 }]
    const out = sortWorkgroupsBySequence(input)
    expect(input.map((w) => w.legacyGroupNumber)).toEqual([2, 1]) // változatlan
    expect(out.map((w) => w.legacyGroupNumber)).toEqual([1, 2])
  })
})
