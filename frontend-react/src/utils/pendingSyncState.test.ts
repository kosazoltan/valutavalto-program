/**
 * FKH-031 NFR-1: a 7 napos automatikus retry-ablak lejarta utan a tetel mar NEM
 * kerul ujra automatikus szinkronra (`isBusinessRetryWithheld` veglegesen visszatartja),
 * ezert a felhasznalonak latnia kell, hogy kezi beavatkozas szukseges.
 *
 * A hiba, amit ez a teszt rogzit: a bizonylat-vazlat lista minden hibas tetelre
 * ugyanazt a "Szinkronizalas sikertelen" feliratot adta, igy a penztaros nem tudta
 * megkulonboztetni a "majd ujraprobalja" es a "mar sosem probalja ujra" allapotot.
 * Egy penzugyi tetel igy 7 nap utan nemaan elveszhet.
 */
import { describe, expect, it } from 'vitest'

import { classifyPendingSyncState } from './pendingSyncState'

const DAY_MS = 24 * 60 * 60 * 1000
const NOW = Date.parse('2026-08-09T12:00:00.000Z')

describe('classifyPendingSyncState (FKH-031 NFR-1)', () => {
  it('hiba nelkuli tetel: normal "szinkronra var" allapot', () => {
    const state = classifyPendingSyncState(
      { syncError: null, createdAt: new Date(NOW - DAY_MS).toISOString() },
      NOW,
    )
    expect(state.kind).toBe('PENDING')
    expect(state.needsManualIntervention).toBe(false)
    expect(state.label).toBe('Helyben mentve, szinkronra vár')
  })

  it('friss hiba: automatikus ujraprobalkozas van hatra', () => {
    const state = classifyPendingSyncState(
      {
        syncError: 'HTTP 422: lejárt árfolyam',
        createdAt: new Date(NOW - 2 * DAY_MS).toISOString(),
      },
      NOW,
    )
    expect(state.kind).toBe('RETRYING')
    expect(state.needsManualIntervention).toBe(false)
    expect(state.label).toBe('Szinkronizálás sikertelen — automatikus újrapróbálkozás')
  })

  it('7 napnal regebbi hibas tetel: KEZI beavatkozas szukseges', () => {
    const state = classifyPendingSyncState(
      {
        syncError: 'HTTP 422: lejárt árfolyam',
        createdAt: new Date(NOW - 8 * DAY_MS).toISOString(),
      },
      NOW,
    )
    expect(state.kind).toBe('MANUAL_REQUIRED')
    expect(state.needsManualIntervention).toBe(true)
    expect(state.label).toBe('Kézi beavatkozás szükséges — nem próbálkozik újra')
  })

  it('pontosan a 7 napos hataron mar kezi beavatkozast igenyel', () => {
    const state = classifyPendingSyncState(
      {
        syncError: 'HTTP 400',
        createdAt: new Date(NOW - 7 * DAY_MS).toISOString(),
      },
      NOW,
    )
    expect(state.kind).toBe('MANUAL_REQUIRED')
  })

  it('hiba NELKUL a 7 napos kor onmagaban nem valt kezi allapotot', () => {
    // Egy regi, de sosem hibazott tetel (pl. tartos offline) tovabbra is
    // normal szinkronra varo — az ablak csak az uzleti hibas agra vonatkozik.
    const state = classifyPendingSyncState(
      { syncError: null, createdAt: new Date(NOW - 30 * DAY_MS).toISOString() },
      NOW,
    )
    expect(state.kind).toBe('PENDING')
    expect(state.needsManualIntervention).toBe(false)
  })

  it('hianyzo/ervenytelen createdAt eseten NEM jelolunk kezi allapotot (fail-open)', () => {
    // Serult idobelyeg miatt egy penzugyi tetel nem eshet "feladott" allapotba.
    for (const createdAt of [null, undefined, '', 'nem-datum']) {
      const state = classifyPendingSyncState({ syncError: 'HTTP 409', createdAt }, NOW)
      expect(state.kind).toBe('RETRYING')
      expect(state.needsManualIntervention).toBe(false)
    }
  })
})
