import { describe, expect, it } from 'vitest'
import {
  buildConnectionTestResetKey,
  filterBranchesForAppMode,
  isBranchSelectableForAppMode,
  preferredAppModeFromGoogleSetup,
  resolveSelectedWorkerForSetup,
} from './SetupWizard'

describe('isBranchSelectableForAppMode', () => {
  it('barmely nem-null branch valaszthato barmely modban (vault preferencia a filterben)', () => {
    // isBranchSelectableForAppMode alapszintu ellenorzes: van-e branch.
    // Az ertektar vault-preferencia a filterBranchesForAppMode fallback-jeben van.
    expect(
      isBranchSelectableForAppMode(
        {
          code: 'VAULT',
          name: 'Ertektar',
          city: 'Szeged',
          isVault: true,
        },
        'ertektar',
      ),
    ).toBe(true)

    expect(
      isBranchSelectableForAppMode(
        {
          code: 'KORUT',
          name: 'Korut',
          city: 'Szeged',
          isVault: false,
        },
        'ertektar',
      ),
    ).toBe(true)

    expect(
      isBranchSelectableForAppMode(
        {
          code: 'LEGACY',
          name: 'Legacy',
          city: 'Szeged',
        },
        'ertektar',
      ),
    ).toBe(true)

    expect(isBranchSelectableForAppMode(null, 'ertektar')).toBe(false)
    expect(isBranchSelectableForAppMode(undefined, 'penztar')).toBe(false)
  })

  it('penztar modban a nem ertektari fiok is valaszthato', () => {
    expect(
      isBranchSelectableForAppMode(
        {
          code: 'KORUT',
          name: 'Korut',
          city: 'Szeged',
          isVault: false,
        },
        'penztar',
      ),
    ).toBe(true)
  })

  it('filter: ertektar modban vault branch-eket preferalja', () => {
    const branches = [
      { code: 'VAULT', name: 'Ertektar', city: 'Szeged', isVault: true },
      { code: 'KORUT', name: 'Korut', city: 'Szeged', isVault: false },
      { code: 'LEGACY', name: 'Legacy', city: 'Szeged' },
    ]

    // Ha van vault branch → csak azokat mutatja
    expect(filterBranchesForAppMode(branches, 'ertektar').map((b) => b.code)).toEqual(['VAULT'])
    expect(filterBranchesForAppMode(branches, 'penztar').map((b) => b.code)).toEqual([
      'VAULT',
      'KORUT',
      'LEGACY',
    ])
  })

  it('filter: ertektar fallback — ha nincs vault branch, mindent mutat', () => {
    const branchesWithoutVault = [
      { code: 'KORUT', name: 'Korut', city: 'Szeged', isVault: false },
      { code: 'LEGACY', name: 'Legacy', city: 'Szeged' },
    ]

    // Fallback: admin meg nem jelolte meg a vault branch-eket → minden selectable
    expect(filterBranchesForAppMode(branchesWithoutVault, 'ertektar').map((b) => b.code)).toEqual([
      'KORUT',
      'LEGACY',
    ])
  })
})

describe('preferredAppModeFromGoogleSetup', () => {
  it('legacy ertekszallito-only response falls back to penztar', () => {
    expect(
      preferredAppModeFromGoogleSetup(
        {
          matchType: 'WORKER_EMAIL',
          requiresWorkerSelection: false,
          googleIdentity: { email: 'courier@example.com', googleSub: 'sub-1' },
          validAppModes: ['ertekszallito'],
        },
        'ertektar',
      ),
    ).toBe('penztar')
  })
})

describe('resolveSelectedWorkerForSetup', () => {
  const workers = [
    { code: 'BORSI', name: 'Borsi Tamas' },
    { code: 'KASZA', name: 'Kasza Helga' },
  ]

  it('online modban a valodi worker-listabol valasztott kodot worker setup-kent kezeli', () => {
    expect(
      resolveSelectedWorkerForSetup({
        offlineMode: false,
        workerCode: ' borsi ',
        availableWorkers: workers,
      }),
    ).toEqual({ code: 'BORSI', name: 'Borsi Tamas' })
  })

  it('offline modban nem indit worker-first-time setupot', () => {
    expect(
      resolveSelectedWorkerForSetup({
        offlineMode: true,
        workerCode: 'BORSI',
        availableWorkers: workers,
      }),
    ).toBeNull()
  })

  it('manualisan beirt, de listaban nem szereplo kodnal legacy bootstrap ag marad', () => {
    expect(
      resolveSelectedWorkerForSetup({
        offlineMode: false,
        workerCode: 'ADMIN',
        availableWorkers: workers,
      }),
    ).toBeNull()
  })
})

describe('buildConnectionTestResetKey', () => {
  const base = {
    apiUrl: 'https://excvaluta.com/api/v1',
    companyCode: 'EBC',
    offlineMode: false,
  }

  it('changes when connection parameters change', () => {
    const original = buildConnectionTestResetKey(base)

    expect(buildConnectionTestResetKey({ ...base, apiUrl: 'https://other.com/api/v1' })).not.toBe(
      original,
    )
    expect(buildConnectionTestResetKey({ ...base, companyCode: 'OTHER' })).not.toBe(original)
    expect(buildConnectionTestResetKey({ ...base, offlineMode: true })).not.toBe(original)
  })

  it('normalizes case and surrounding whitespace for stable identity fields', () => {
    expect(
      buildConnectionTestResetKey({
        ...base,
        companyCode: ' ebc ',
      }),
    ).toBe(buildConnectionTestResetKey(base))
  })
})
