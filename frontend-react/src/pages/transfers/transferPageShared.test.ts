import { describe, expect, it } from 'vitest'
import { buildVaultLabel } from './transferPageShared'

describe('buildVaultLabel', () => {
  it('a régiókóddal rendelkező értéktár nevét régiókódos formában adja vissza', () => {
    expect(
      buildVaultLabel(
        { code: 'BR076', name: 'Szeged Értéktár', isVault: true, regionCode: '20' },
        null,
      ),
    ).toBe('20. Szeged Értéktár')
  })

  it('régiókód nélkül az iroda kódját és nevét adja vissza', () => {
    expect(buildVaultLabel({ code: 'BR076', name: 'Pécsi értéktár', isVault: true }, null)).toBe(
      'BR076 - Pécsi értéktár',
    )
  })

  it('saját iroda nélkül a dolgozó irodanevét adja vissza', () => {
    expect(
      buildVaultLabel(undefined, { branchName: 'Budapesti pénztár', branchCode: 'BR001' }),
    ).toBe('Budapesti pénztár')
  })

  it('irodaadat nélkül gondolatjelet ad vissza', () => {
    expect(buildVaultLabel(undefined, null)).toBe('—')
  })
})
