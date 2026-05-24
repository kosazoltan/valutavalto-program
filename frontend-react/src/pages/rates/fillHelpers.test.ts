import { describe, it, expect } from 'vitest'
import { currentFunctionCode, fillDownLimitBands, clearLimitBands } from './fillHelpers'
import type { EditableRate } from './types'

function makeRate(over: Partial<EditableRate> = {}): EditableRate {
  return {
    currencyId: 1,
    currencyCode: 'EUR',
    currencyName: 'Euró',
    officialRate: 400,
    buyRate: '',
    sellRate: '',
    limit1BuyRate: '',
    limit1SellRate: '',
    limit2BuyRate: '',
    limit2SellRate: '',
    limit3BuyRate: '',
    limit3SellRate: '',
    hasRate: true,
    modified: false,
    ...over,
  }
}

describe('fillHelpers (FR-RFM-22 / FR-RFM-23)', () => {
  describe('currentFunctionCode (FR-RFM-22, #NNM)', () => {
    it('csoportszámot 2 jegyűre tölti', () => {
      expect(currentFunctionCode(1)).toBe('#01M')
      expect(currentFunctionCode(16)).toBe('#16M')
    })
    it('3+ jegyű csoportszám is megmarad', () => {
      expect(currentFunctionCode(100)).toBe('#100M')
    })
    it('null/0/negatív/NaN → #01M (alapérték)', () => {
      expect(currentFunctionCode(null)).toBe('#01M')
      expect(currentFunctionCode(0)).toBe('#01M')
      expect(currentFunctionCode(-5)).toBe('#01M')
      expect(currentFunctionCode(undefined)).toBe('#01M')
      expect(currentFunctionCode(NaN)).toBe('#01M')
    })
    it('tört csoportszámot levág', () => {
      expect(currentFunctionCode(7.9)).toBe('#07M')
    })
  })

  describe('fillDownLimitBands (FR-RFM-23 — adat lehúzás)', () => {
    it('üres sávokat feltölti a 0-s buy/sell-ből', () => {
      const r = makeRate({ buyRate: '395', sellRate: '405' })
      const out = fillDownLimitBands(r)
      expect(out.limit1BuyRate).toBe('395')
      expect(out.limit2BuyRate).toBe('395')
      expect(out.limit3BuyRate).toBe('395')
      expect(out.limit1SellRate).toBe('405')
      expect(out.limit3SellRate).toBe('405')
      expect(out.modified).toBe(true)
    })
    it('non-destruktív: a kézzel megadott sávot nem írja felül (overwrite nélkül)', () => {
      const r = makeRate({ buyRate: '395', sellRate: '405', limit1BuyRate: '390' })
      const out = fillDownLimitBands(r)
      expect(out.limit1BuyRate).toBe('390') // megmarad
      expect(out.limit2BuyRate).toBe('395') // üres volt → kitöltve
    })
    it('overwrite=true minden sávot felülír', () => {
      const r = makeRate({ buyRate: '395', sellRate: '405', limit1BuyRate: '390' })
      const out = fillDownLimitBands(r, { overwrite: true })
      expect(out.limit1BuyRate).toBe('395')
    })
    it('nincs buy/sell → változatlan referencia (nincs mit lehúzni)', () => {
      const r = makeRate({ buyRate: '', sellRate: '' })
      const out = fillDownLimitBands(r)
      expect(out).toBe(r)
      expect(out.modified).toBe(false)
    })
    it('minden sáv már egyezik → változatlan referencia (nincs modified)', () => {
      const r = makeRate({
        buyRate: '395', sellRate: '405',
        limit1BuyRate: '395', limit1SellRate: '405',
        limit2BuyRate: '395', limit2SellRate: '405',
        limit3BuyRate: '395', limit3SellRate: '405',
      })
      const out = fillDownLimitBands(r)
      expect(out).toBe(r)
    })
    it('csak buy van megadva → csak a vétel-sávok töltődnek', () => {
      const r = makeRate({ buyRate: '395', sellRate: '' })
      const out = fillDownLimitBands(r)
      expect(out.limit1BuyRate).toBe('395')
      expect(out.limit1SellRate).toBe('')
    })
  })

  describe('clearLimitBands (FR-RFM-23 — sávok törlése)', () => {
    it('minden sávmezőt kiürít', () => {
      const r = makeRate({
        limit1BuyRate: '395', limit1SellRate: '405',
        limit2BuyRate: '396', limit3SellRate: '407',
      })
      const out = clearLimitBands(r)
      expect(out.limit1BuyRate).toBe('')
      expect(out.limit1SellRate).toBe('')
      expect(out.limit2BuyRate).toBe('')
      expect(out.limit3SellRate).toBe('')
      expect(out.modified).toBe(true)
    })
    it('a 0-s buy/sell-t NEM törli (csak a sávokat)', () => {
      const r = makeRate({ buyRate: '395', sellRate: '405', limit1BuyRate: '390' })
      const out = clearLimitBands(r)
      expect(out.buyRate).toBe('395')
      expect(out.sellRate).toBe('405')
      expect(out.limit1BuyRate).toBe('')
    })
    it('már üres sávok → változatlan referencia', () => {
      const r = makeRate({ buyRate: '395' })
      const out = clearLimitBands(r)
      expect(out).toBe(r)
      expect(out.modified).toBe(false)
    })
  })
})
