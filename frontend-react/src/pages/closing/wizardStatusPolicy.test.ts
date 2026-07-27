import { describe, it, expect } from 'vitest'
// FK-065 FR-3 SZERZŐDÉS: a frontend WizardStatus-alapú elágazása EGYETLEN közös,
// futásidejű helperbe kerül (wizardStatusPolicy), amit a ClosingWizardPage használ.
// Az import ma bukik, mert a modul még nem létezik — ez a RED-fázis várt állapota.
// Tesztet a bukás elfedésére módosítani TILOS.
import { resolveWizardResumeAction, WIZARD_STATUS_VALUES } from './wizardStatusPolicy'

describe('wizardStatusPolicy — FK-065 enum-exhaustive védelem', () => {
  it('a runtime értéklista az összes backend státuszt tartalmazza (EXPIRED-del)', () => {
    expect(WIZARD_STATUS_VALUES).toEqual(
      expect.arrayContaining(['IN_PROGRESS', 'COMPLETED', 'FAILED', 'CANCELLED', 'EXPIRED']),
    )
  })

  it('minden státusz explicit ágat kap: EXPIRED = restart-only, IN_PROGRESS = resume', () => {
    expect(resolveWizardResumeAction('IN_PROGRESS')).toBe('resume')
    expect(resolveWizardResumeAction('EXPIRED')).toBe('restart-only')
    expect(resolveWizardResumeAction('COMPLETED')).toBe('none')
    expect(resolveWizardResumeAction('CANCELLED')).toBe('none')
    expect(resolveWizardResumeAction('FAILED')).toBe('none')
  })

  it('ismeretlen státusz NEM eshet át néma default/else ágon — kötelező a hiba', () => {
    // Így egy jövőbeli új backend-státusz tesztbukásként jelenik meg, nem néma
    // viselkedésként (ez az exhaustiveness-garancia futásidejű fele).
    expect(() => resolveWizardResumeAction('SOMETHING_NEW' as never)).toThrow()
  })
})
