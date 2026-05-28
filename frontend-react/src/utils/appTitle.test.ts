import { describe, it, expect } from 'vitest'
import { appTitleForFlavor } from './appTitle'

describe('appTitleForFlavor (v2.5.54 #6)', () => {
  it('rate-maker → Árfolyam Készítő', () => {
    expect(appTitleForFlavor('rate-maker')).toBe('Árfolyam Készítő — Best Change')
  })
  it('central-workstation → Központi Munkaállomás', () => {
    expect(appTitleForFlavor('central-workstation')).toBe('Központi Munkaállomás — Best Change')
  })
  it('penztar / ismeretlen / üres → Valuta Pénztár (default)', () => {
    expect(appTitleForFlavor('penztar')).toBe('Valuta Pénztár — Best Change')
    expect(appTitleForFlavor(undefined)).toBe('Valuta Pénztár — Best Change')
    expect(appTitleForFlavor(null)).toBe('Valuta Pénztár — Best Change')
    expect(appTitleForFlavor('xyz')).toBe('Valuta Pénztár — Best Change')
  })
  it('mindhárom flavor különböző címet ad (megkülönböztethetőség)', () => {
    const titles = new Set([
      appTitleForFlavor('penztar'),
      appTitleForFlavor('central-workstation'),
      appTitleForFlavor('rate-maker'),
    ])
    expect(titles.size).toBe(3)
  })
})
