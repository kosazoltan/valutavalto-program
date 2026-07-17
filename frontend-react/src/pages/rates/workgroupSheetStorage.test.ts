import { describe, it, expect, afterEach } from 'vitest'
import {
  sheet0RowToValues,
  loadSheet0ByCurrency,
  loadGroupFormulas,
  saveGroupFormulas,
  loadAllGroupValueSnapshots,
  saveGroupValueSnapshot,
  loadGroupRateValues,
  saveGroupRateValues,
  saveGroupRateValuesToOfflineDb,
  loadGroupRateValuesFromOfflineDb,
  persistGroupRateValues,
  exportRateMakerSheetSnapshot,
  importRateMakerSheetSnapshot,
} from './workgroupSheetStorage'
import type { WgValues } from './workgroupSheetFormula'

const LOCAL_EDITS_KEY = 'arfolyamkeszito.mainSheet.localEdits.v1'
const MAIN_SHEET_KEY = 'arfolyamkeszito.mainSheet.v1'
const FORMULAS_KEY = 'arfolyamkeszito.mainSheet.formulas.v2'

function snapshotJson(savedAt: string, entries: Record<string, string>): string {
  return JSON.stringify({ version: 1, savedAt, entries })
}

const sheetRow = (currency: string, weakMultiBuy: number, weakMultiSell: number) => ({
  currency,
  settlement: 400,
  otp: 0,
  helper: 0,
  weakMultiBuy,
  weakMultiSell,
  crossSettlement: 0,
  crossRate: 0,
  wholesale: 0,
  crossBase: null,
})

const eurRow = (weakMultiBuy: number, weakMultiSell: number) =>
  sheetRow('EUR', weakMultiBuy, weakMultiSell)

/** Minimál in-memory Storage stub a teszthez (jsdom localStorage helyett, izolált). */
function memStorage(): Storage {
  const m = new Map<string, string>()
  return {
    get length() {
      return m.size
    },
    clear: () => m.clear(),
    getItem: (k: string) => (m.has(k) ? m.get(k)! : null),
    key: (i: number) => Array.from(m.keys())[i] ?? null,
    removeItem: (k: string) => void m.delete(k),
    setItem: (k: string, v: string) => void m.set(k, v),
  } as Storage
}

describe('sheet0RowToValues', () => {
  it('A–I mezőket mappolja, a D/currency címkét kihagyja', () => {
    const v = sheet0RowToValues({
      currency: 'EUR',
      settlement: 400,
      otp: 401,
      helper: 402,
      weakMultiBuy: 395,
      weakMultiSell: 405,
      crossSettlement: 399,
      crossRate: 1.08,
      wholesale: 398,
    })
    expect(v).toEqual({ A: 400, B: 401, C: 402, E: 395, F: 405, G: 399, H: 1.08, I: 398 })
  })

  it('hiányzó mezőket kihagy', () => {
    expect(sheet0RowToValues({ currency: 'USD', settlement: 360 })).toEqual({ A: 360 })
  })

  it('0 forrásérték kimarad (nincs érték)', () => {
    expect(sheet0RowToValues({ currency: 'RUB', weakMultiSell: 0 })).toEqual({})
  })

  it('negatív és nem-véges érték kimarad', () => {
    expect(
      sheet0RowToValues({
        currency: 'RUB',
        weakMultiSell: -1,
        helper: NaN,
        settlement: Infinity,
      }),
    ).toEqual({})
  })

  it('pozitív érték változatlan, a 0-s mező mellett', () => {
    expect(sheet0RowToValues({ currency: 'EUR', settlement: 400, weakMultiSell: 0 })).toEqual({
      A: 400,
    })
  })
})

describe('loadSheet0ByCurrency', () => {
  it('valutakód → A–I map a 0-s lap localStorage-ból', () => {
    const s = memStorage()
    s.setItem(
      'arfolyamkeszito.mainSheet.v1',
      JSON.stringify([
        { currency: 'EUR', settlement: 400, weakMultiSell: 405 },
        { currency: 'usd', settlement: 360 },
      ]),
    )
    const map = loadSheet0ByCurrency(s)
    expect(map.get('EUR')).toEqual({ A: 400, F: 405 })
    expect(map.get('USD')).toEqual({ A: 360 }) // upper-case kulcs
  })

  it('hiányzó / hibás JSON → üres map', () => {
    expect(loadSheet0ByCurrency(memStorage()).size).toBe(0)
    const s = memStorage()
    s.setItem('arfolyamkeszito.mainSheet.v1', '{nem json')
    expect(loadSheet0ByCurrency(s).size).toBe(0)
  })
})

describe('rate-maker szerveroldali munkaív snapshot', () => {
  it('csak az árfolyamkészítő localStorage kulcsokat exportálja', () => {
    const s = memStorage()
    s.setItem('arfolyamkeszito.mainSheet.v1', '[{"currency":"EUR"}]')
    s.setItem('arfolyamkeszito.workgroupSheet.rates.v1.g-1', '{"1.buyRate":"400"}')
    s.setItem('mainRateSheet.bandBase', 'settlement')
    s.setItem('auth_token', 'nem-exportalhato')

    const snapshot = exportRateMakerSheetSnapshot(s)

    expect(snapshot.version).toBe(1)
    expect(snapshot.entries).toEqual({
      'arfolyamkeszito.mainSheet.v1': '[{"currency":"EUR"}]',
      'arfolyamkeszito.workgroupSheet.rates.v1.g-1': '{"1.buyRate":"400"}',
      'mainRateSheet.bandBase': 'settlement',
    })
  })

  it('importnál eldobja az idegen kulcsokat és a hibás snapshotot', () => {
    const s = memStorage()
    const imported = importRateMakerSheetSnapshot(
      JSON.stringify({
        version: 1,
        savedAt: '2026-06-18T10:00:00',
        entries: {
          'arfolyamkeszito.mainSheet.v1': '[{"currency":"EUR"}]',
          auth_token: 'tilos',
          'arfolyamkeszito.workgroupSheet.formulas.v1.g-1': '{"1.buyRate":"J-1"}',
        },
      }),
      s,
    )

    expect(imported).toBe(2)
    expect(s.getItem('arfolyamkeszito.mainSheet.v1')).toBe('[{"currency":"EUR"}]')
    expect(s.getItem('arfolyamkeszito.workgroupSheet.formulas.v1.g-1')).toBe('{"1.buyRate":"J-1"}')
    expect(s.getItem('auth_token')).toBeNull()
    expect(importRateMakerSheetSnapshot('{nem json', s)).toBe(0)
  })
})

describe('FK07-fix-2 — marker-védett snapshot-import', () => {
  const savedAt = '2026-07-16T10:00:00.000Z'
  const savedAtTs = Date.parse(savedAt)

  it.each([
    ['üres', '{}'],
    ['idegen', JSON.stringify({ 'USD.otp': 1 })],
  ])('nem írja felül a lokális marker-store-t szerveroldali %s markerrel', (_, serverMarker) => {
    const s = memStorage()
    const localMarker = JSON.stringify({ 'EUR.weakMultiBuy': savedAtTs + 1 })
    s.setItem(LOCAL_EDITS_KEY, localMarker)

    const imported = importRateMakerSheetSnapshot(
      snapshotJson(savedAt, {
        [LOCAL_EDITS_KEY]: serverMarker,
        'arfolyamkeszito.workgroupSheet.rates.v1.g-1': '{"1.buyRate":"400"}',
      }),
      s,
    )

    expect(s.getItem(LOCAL_EDITS_KEY)).toBe(localMarker)
    expect(imported).toBe(1)
  })

  it('csak a snapshotnál frissebb markerrel védett cellát tartja meg', () => {
    const s = memStorage()
    s.setItem(MAIN_SHEET_KEY, JSON.stringify([eurRow(396, 405)]))
    s.setItem(LOCAL_EDITS_KEY, JSON.stringify({ 'EUR.weakMultiBuy': savedAtTs + 1 }))

    const imported = importRateMakerSheetSnapshot(
      snapshotJson(savedAt, { [MAIN_SHEET_KEY]: JSON.stringify([eurRow(390, 410)]) }),
      s,
    )

    expect(imported).toBe(1)
    expect(JSON.parse(s.getItem(MAIN_SHEET_KEY)!)[0]).toMatchObject({
      weakMultiBuy: 396,
      weakMultiSell: 410,
    })
  })

  it.each([
    ['string', '396'],
    ['null', null],
  ])('érvényes marker mellett is a szerver számértéke nyer, ha a lokális sor mezője %s', (_, value) => {
    const s = memStorage()
    const localMarker = JSON.stringify({ 'EUR.weakMultiBuy': savedAtTs + 1 })
    s.setItem(MAIN_SHEET_KEY, JSON.stringify([{ ...eurRow(396, 405), weakMultiBuy: value }]))
    s.setItem(LOCAL_EDITS_KEY, localMarker)

    importRateMakerSheetSnapshot(
      snapshotJson(savedAt, { [MAIN_SHEET_KEY]: JSON.stringify([eurRow(390, 410)]) }),
      s,
    )

    expect(JSON.parse(s.getItem(MAIN_SHEET_KEY)!)[0].weakMultiBuy).toBe(390)
    expect(s.getItem(LOCAL_EDITS_KEY)).toBe(localMarker)
  })

  it('a snapshotnál régebbi marker nem védi a lokális cellát', () => {
    const s = memStorage()
    s.setItem(MAIN_SHEET_KEY, JSON.stringify([eurRow(396, 405)]))
    s.setItem(LOCAL_EDITS_KEY, JSON.stringify({ 'EUR.weakMultiBuy': savedAtTs - 3_600_000 }))

    importRateMakerSheetSnapshot(
      snapshotJson(savedAt, { [MAIN_SHEET_KEY]: JSON.stringify([eurRow(390, 410)]) }),
      s,
    )

    expect(JSON.parse(s.getItem(MAIN_SHEET_KEY)!)[0]).toMatchObject({
      weakMultiBuy: 390,
      weakMultiSell: 410,
    })
  })

  it.each([
    ['egyenlő', 0, 390],
    ['1 ms-mal frissebb', 1, 396],
  ])('%s marker timestampnél a megfelelő oldal nyer', (_, markerOffset, expectedBuy) => {
    const s = memStorage()
    s.setItem(MAIN_SHEET_KEY, JSON.stringify([eurRow(396, 405)]))
    s.setItem(LOCAL_EDITS_KEY, JSON.stringify({ 'EUR.weakMultiBuy': savedAtTs + markerOffset }))

    importRateMakerSheetSnapshot(
      snapshotJson(savedAt, { [MAIN_SHEET_KEY]: JSON.stringify([eurRow(390, 410)]) }),
      s,
    )

    expect(JSON.parse(s.getItem(MAIN_SHEET_KEY)!)[0].weakMultiBuy).toBe(expectedBuy)
  })

  it.each([
    ['üres', ''],
    ['hibás', 'nem-dátum'],
    ['hiányzó', undefined],
  ])('%s savedAt esetén fail-closed módon minden érvényes marker véd', (_, serverSavedAt) => {
    const s = memStorage()
    s.setItem(MAIN_SHEET_KEY, JSON.stringify([eurRow(396, 405)]))
    s.setItem(LOCAL_EDITS_KEY, JSON.stringify({ 'EUR.weakMultiBuy': 1 }))
    const snapshot = JSON.stringify({
      version: 1,
      ...(serverSavedAt === undefined ? {} : { savedAt: serverSavedAt }),
      entries: { [MAIN_SHEET_KEY]: JSON.stringify([eurRow(390, 410)]) },
    })

    importRateMakerSheetSnapshot(snapshot, s)

    expect(JSON.parse(s.getItem(MAIN_SHEET_KEY)!)[0].weakMultiBuy).toBe(396)
  })

  it.each(['{nem json', '{"nem":"tömb"}'])(
    'hibás szerver mainSheet entryt kihagy, de a többi érvényes kulcsot importálja: %s',
    (serverMainSheet) => {
      const s = memStorage()
      const localMainSheet = JSON.stringify([eurRow(396, 405)])
      const localMarker = JSON.stringify({ 'EUR.weakMultiBuy': savedAtTs + 1 })
      s.setItem(MAIN_SHEET_KEY, localMainSheet)
      s.setItem(LOCAL_EDITS_KEY, localMarker)

      const imported = importRateMakerSheetSnapshot(
        snapshotJson(savedAt, {
          [MAIN_SHEET_KEY]: serverMainSheet,
          'arfolyamkeszito.workgroupSheet.rates.v1.g-1': '{"1.buyRate":"401"}',
        }),
        s,
      )

      expect(s.getItem(MAIN_SHEET_KEY)).toBe(localMainSheet)
      expect(s.getItem(LOCAL_EDITS_KEY)).toBe(localMarker)
      expect(s.getItem('arfolyamkeszito.workgroupSheet.rates.v1.g-1')).toBe('{"1.buyRate":"401"}')
      expect(imported).toBe(1)
    },
  )

  it('valutánként és cellánként külön alkalmazza a védelmet', () => {
    const s = memStorage()
    s.setItem(MAIN_SHEET_KEY, JSON.stringify([eurRow(396, 405), sheetRow('USD', 350, 370)]))
    s.setItem(LOCAL_EDITS_KEY, JSON.stringify({ 'EUR.weakMultiBuy': savedAtTs + 1 }))

    importRateMakerSheetSnapshot(
      snapshotJson(savedAt, {
        [MAIN_SHEET_KEY]: JSON.stringify([eurRow(390, 410), sheetRow('USD', 340, 380)]),
      }),
      s,
    )

    expect(JSON.parse(s.getItem(MAIN_SHEET_KEY)!)).toEqual([
      eurRow(396, 410),
      sheetRow('USD', 340, 380),
    ])
  })

  it('megtartja a csak lokálisan létező, védett számértékű valuta sort', () => {
    const s = memStorage()
    const chf = sheetRow('CHF', 420, 440)
    s.setItem(MAIN_SHEET_KEY, JSON.stringify([eurRow(396, 405), chf]))
    s.setItem(LOCAL_EDITS_KEY, JSON.stringify({ 'CHF.weakMultiBuy': savedAtTs + 1 }))

    importRateMakerSheetSnapshot(
      snapshotJson(savedAt, { [MAIN_SHEET_KEY]: JSON.stringify([eurRow(390, 410)]) }),
      s,
    )

    expect(JSON.parse(s.getItem(MAIN_SHEET_KEY)!)).toEqual([eurRow(390, 410), chf])
  })

  it('védett settlementtel együtt a settlementManual jelzőt is átveszi', () => {
    const s = memStorage()
    const local = { ...eurRow(396, 405), settlement: 402, settlementManual: true }
    const server = { ...eurRow(390, 410), settlement: 400, settlementManual: false }
    s.setItem(MAIN_SHEET_KEY, JSON.stringify([local]))
    s.setItem(LOCAL_EDITS_KEY, JSON.stringify({ 'EUR.settlement': savedAtTs + 1 }))

    importRateMakerSheetSnapshot(
      snapshotJson(savedAt, { [MAIN_SHEET_KEY]: JSON.stringify([server]) }),
      s,
    )

    expect(JSON.parse(s.getItem(MAIN_SHEET_KEY)!)[0]).toMatchObject({
      settlement: 402,
      settlementManual: true,
      weakMultiBuy: 390,
    })
  })

  it('védett formula-celláknál a lokális képletet megtartja, a lokálisan töröltet nem támasztja fel', () => {
    const s = memStorage()
    s.setItem(
      FORMULAS_KEY,
      JSON.stringify({ 'EUR.weakMultiBuy': 'C*0,99', 'EUR.weakMultiSell': 'C*1,01' }),
    )
    s.setItem(
      LOCAL_EDITS_KEY,
      JSON.stringify({
        'EUR.weakMultiBuy': savedAtTs + 1,
        'USD.weakMultiBuy': savedAtTs + 1,
      }),
    )

    importRateMakerSheetSnapshot(
      snapshotJson(savedAt, {
        [FORMULAS_KEY]: JSON.stringify({
          'EUR.weakMultiBuy': 'C*0,95',
          'EUR.weakMultiSell': 'C*1,05',
          'USD.weakMultiBuy': 'C*0,90',
        }),
      }),
      s,
    )

    expect(JSON.parse(s.getItem(FORMULAS_KEY)!)).toEqual({
      'EUR.weakMultiBuy': 'C*0,99',
      'EUR.weakMultiSell': 'C*1,05',
    })
  })

  it.each([
    ['null', null],
    ['szám', 123],
    ['tömb', ['C*0,99']],
    ['objektum', { formula: 'C*0,99' }],
  ])('védett cellánál a nem string lokális formulaértéket törölt képletként kezeli: %s', (_, value) => {
    const s = memStorage()
    s.setItem(
      FORMULAS_KEY,
      JSON.stringify({
        'EUR.weakMultiBuy': value,
        'EUR.weakMultiSell': 'C*1,01',
      }),
    )
    s.setItem(LOCAL_EDITS_KEY, JSON.stringify({ 'EUR.weakMultiBuy': savedAtTs + 1 }))

    importRateMakerSheetSnapshot(
      snapshotJson(savedAt, {
        [FORMULAS_KEY]: JSON.stringify({
          'EUR.weakMultiBuy': 'C*0,95',
          'EUR.weakMultiSell': 'C*1,05',
        }),
      }),
      s,
    )

    expect(JSON.parse(s.getItem(FORMULAS_KEY)!)).toEqual({
      'EUR.weakMultiSell': 'C*1,05',
    })
  })

  it.each(['{nem json', '["nem", "objektum"]'])(
    'hibás szerver formulas entrynél a lokális formula-store változatlan: %s',
    (serverFormulas) => {
      const s = memStorage()
      const localFormulas = JSON.stringify({ 'EUR.weakMultiBuy': 'C*0,99' })
      s.setItem(FORMULAS_KEY, localFormulas)
      s.setItem(LOCAL_EDITS_KEY, JSON.stringify({ 'EUR.weakMultiBuy': savedAtTs + 1 }))

      const imported = importRateMakerSheetSnapshot(
        snapshotJson(savedAt, { [FORMULAS_KEY]: serverFormulas }),
        s,
      )

      expect(s.getItem(FORMULAS_KEY)).toBe(localFormulas)
      expect(imported).toBe(0)
    },
  )

  it('érvénytelen marker-érték nem véd, de a marker-store bájtra változatlan marad', () => {
    const s = memStorage()
    const localMarker = '{"EUR.weakMultiBuy":"x","EUR.weakMultiSell":null,"EUR.otp":400}'
    s.setItem(MAIN_SHEET_KEY, JSON.stringify([eurRow(396, 405)]))
    s.setItem(LOCAL_EDITS_KEY, localMarker)

    importRateMakerSheetSnapshot(
      snapshotJson(savedAt, {
        [LOCAL_EDITS_KEY]: '{}',
        [MAIN_SHEET_KEY]: JSON.stringify([eurRow(390, 410)]),
      }),
      s,
    )

    expect(JSON.parse(s.getItem(MAIN_SHEET_KEY)!)[0]).toMatchObject({
      weakMultiBuy: 390,
      weakMultiSell: 410,
    })
    expect(s.getItem(LOCAL_EDITS_KEY)).toBe(localMarker)
  })

  it('storage írási hiba esetén is a ténylegesen sikeres setItem hívások számát adja vissza', () => {
    const s = memStorage()
    const realSetItem = s.setItem.bind(s)
    s.setItem = (key: string, value: string) => {
      if (key.endsWith('g-2')) throw new Error('quota')
      realSetItem(key, value)
    }

    const imported = importRateMakerSheetSnapshot(
      snapshotJson(savedAt, {
        'arfolyamkeszito.workgroupSheet.rates.v1.g-1': '{"1.buyRate":"401"}',
        'arfolyamkeszito.workgroupSheet.rates.v1.g-2': '{"1.buyRate":"402"}',
      }),
      s,
    )

    expect(s.getItem('arfolyamkeszito.workgroupSheet.rates.v1.g-1')).toBe('{"1.buyRate":"401"}')
    expect(s.getItem('arfolyamkeszito.workgroupSheet.rates.v1.g-2')).toBeNull()
    expect(imported).toBe(1)
  })

  it('explicit localBaseline esetén nem olvassa vissza az időközben megváltozott storage-ot', () => {
    const s = memStorage()
    const baselineMainSheet = JSON.stringify([eurRow(396, 405)])
    const baselineMarker = JSON.stringify({ 'EUR.weakMultiBuy': savedAtTs + 1 })
    const baseline = {
      version: 1 as const,
      savedAt: '2026-07-16T11:00:00.000Z',
      entries: {
        [MAIN_SHEET_KEY]: baselineMainSheet,
        [LOCAL_EDITS_KEY]: baselineMarker,
      },
    }
    s.setItem(MAIN_SHEET_KEY, JSON.stringify([eurRow(397, 405)]))
    s.setItem(LOCAL_EDITS_KEY, '{}')

    importRateMakerSheetSnapshot(
      snapshotJson(savedAt, { [MAIN_SHEET_KEY]: JSON.stringify([eurRow(390, 410)]) }),
      s,
      baseline,
    )

    expect(JSON.parse(s.getItem(MAIN_SHEET_KEY)!)[0]).toMatchObject({
      weakMultiBuy: 396,
      weakMultiSell: 410,
    })
    expect(s.getItem(LOCAL_EDITS_KEY)).toBe('{}')
  })
})

describe('group formulas round-trip', () => {
  it('mentés → betöltés ugyanazt adja, csoportonként külön kulcs', () => {
    const s = memStorage()
    saveGroupFormulas('g-1', { '1.buyRate': 'J - 5' }, s)
    saveGroupFormulas('g-2', { '2.sellRate': '#01L + 1' }, s)
    expect(loadGroupFormulas('g-1', s)).toEqual({ '1.buyRate': 'J - 5' })
    expect(loadGroupFormulas('g-2', s)).toEqual({ '2.sellRate': '#01L + 1' })
    expect(loadGroupFormulas('g-3', s)).toEqual({})
  })
})

describe('group value snapshots (#NN)', () => {
  it('több csoport pillanatképe round-trip', () => {
    const s = memStorage()
    const g1: Map<string, WgValues> = new Map([['EUR', { L: 390, M: 410 }]])
    const g3: Map<string, WgValues> = new Map([['eur', { L: 392 }]])
    saveGroupValueSnapshot(1, g1, s)
    saveGroupValueSnapshot(3, g3, s)
    const all = loadAllGroupValueSnapshots(s)
    expect(all.get(1)!.get('EUR')).toEqual({ L: 390, M: 410 })
    expect(all.get(3)!.get('EUR')).toEqual({ L: 392 }) // upper-case kulcs
  })

  it('ugyanazon csoport újramentése felülírja', () => {
    const s = memStorage()
    saveGroupValueSnapshot(1, new Map([['EUR', { L: 390 }]]), s)
    saveGroupValueSnapshot(1, new Map([['EUR', { L: 400 }]]), s)
    expect(loadAllGroupValueSnapshots(s).get(1)!.get('EUR')).toEqual({ L: 400 })
  })
})

describe('group fix rátaértékek round-trip (FK02-B / FR-11, FR-12)', () => {
  it('üres/hiányzó csoport → üres objektum (nem dob)', () => {
    expect(loadGroupRateValues('wg-1', memStorage())).toEqual({})
  })

  it('mentés → betöltés ugyanazt adja, csoportonként izolált', () => {
    const s = memStorage()
    saveGroupRateValues('wg-1', { 'cur-1.buyRate': '400.5', 'cur-2.limit1SellRate': '0.85' }, s)
    saveGroupRateValues('wg-2', { 'cur-1.buyRate': '999' }, s)
    expect(loadGroupRateValues('wg-1', s)).toEqual({
      'cur-1.buyRate': '400.5',
      'cur-2.limit1SellRate': '0.85',
    })
    expect(loadGroupRateValues('wg-2', s)).toEqual({ 'cur-1.buyRate': '999' })
  })

  it('üres store mentése ELTÁVOLÍTJA a localStorage entryt (publikálás után)', () => {
    const s = memStorage()
    const key = 'arfolyamkeszito.workgroupSheet.rates.v1.wg-1'
    saveGroupRateValues('wg-1', { 'cur-1.buyRate': '400' }, s)
    expect(s.getItem(key)).not.toBeNull()
    saveGroupRateValues('wg-1', {}, s)
    expect(s.getItem(key)).toBeNull() // nem „{}" entry, hanem ténylegesen törölve
    expect(loadGroupRateValues('wg-1', s)).toEqual({})
  })

  it('hibás JSON → üres objektum (defenzív)', () => {
    const s = memStorage()
    s.setItem('arfolyamkeszito.workgroupSheet.rates.v1.wg-1', '{nem json')
    expect(loadGroupRateValues('wg-1', s)).toEqual({})
  })
})

describe('tartós offline SQLite réteg (FK02-B / FR-11, FR-12)', () => {
  const g = globalThis as { electronAPI?: unknown }
  afterEach(() => {
    delete g.electronAPI
  })

  it('böngészőben (nincs electronAPI) → save no-op, load üres (nem dob)', async () => {
    saveGroupRateValuesToOfflineDb('wg-1', { 'cur-1.buyRate': '400' })
    await expect(loadGroupRateValuesFromOfflineDb('wg-1')).resolves.toEqual({})
  })

  it('Electronban: save átadja a groupId+values payloadot a localFirst IPC-nek', () => {
    const calls: Array<{ groupId: string; values: Record<string, string> }> = []
    g.electronAPI = {
      localFirst: {
        saveGroupRateValues: (p: { groupId: string; values: Record<string, string> }) => {
          calls.push(p)
          return Promise.resolve({ ok: true })
        },
      },
    }
    saveGroupRateValuesToOfflineDb('wg-7', {
      'cur-1.buyRate': '400',
      'cur-2.limit1SellRate': '0.9',
    })
    expect(calls).toEqual([
      { groupId: 'wg-7', values: { 'cur-1.buyRate': '400', 'cur-2.limit1SellRate': '0.9' } },
    ])
  })

  it('Electronban: load a localFirst IPC válaszát adja vissza', async () => {
    g.electronAPI = {
      localFirst: {
        getGroupRateValues: (id: string) =>
          Promise.resolve(id === 'wg-7' ? { 'cur-1.buyRate': '400' } : {}),
      },
    }
    await expect(loadGroupRateValuesFromOfflineDb('wg-7')).resolves.toEqual({
      'cur-1.buyRate': '400',
    })
  })

  it('IPC-hiba esetén save nem dob, load üreset ad (best-effort)', async () => {
    g.electronAPI = {
      localFirst: {
        saveGroupRateValues: () => Promise.reject(new Error('ipc fail')),
        getGroupRateValues: () => Promise.reject(new Error('ipc fail')),
      },
    }
    expect(() => saveGroupRateValuesToOfflineDb('wg-1', { 'cur-1.buyRate': '1' })).not.toThrow()
    await expect(loadGroupRateValuesFromOfflineDb('wg-1')).resolves.toEqual({})
  })

  it('persistGroupRateValues dual-write: localStorage ÉS SQLite IPC is megkapja (review P0/P1 fix)', () => {
    localStorage.clear()
    const calls: Array<{ groupId: string; values: Record<string, string> }> = []
    g.electronAPI = {
      localFirst: {
        saveGroupRateValues: (p: { groupId: string; values: Record<string, string> }) => {
          calls.push(p)
          return Promise.resolve({ ok: true })
        },
      },
    }
    persistGroupRateValues('wg-9', { 'cur-1.buyRate': '410' })
    // localStorage szinkron út
    expect(loadGroupRateValues('wg-9')).toEqual({ 'cur-1.buyRate': '410' })
    // tartós SQLite út
    expect(calls).toEqual([{ groupId: 'wg-9', values: { 'cur-1.buyRate': '410' } }])
    localStorage.clear()
  })
})
