import { describe, expect, it } from 'vitest'
import {
  buildConnectionTestResetKey,
  filterBranchesForAppMode,
  isBranchSelectableForAppMode,
  resolveSelectedWorkerForSetup,
} from './SetupWizard'

describe('isBranchSelectableForAppMode', () => {
  it('ertektar modban csak ertektari fiokot enged', () => {
    expect(isBranchSelectableForAppMode({
      code: 'VAULT',
      name: 'Ertektar',
      city: 'Szeged',
      isVault: true,
    }, 'ertektar')).toBe(true)

    expect(isBranchSelectableForAppMode({
      code: 'KORUT',
      name: 'Korut',
      city: 'Szeged',
      isVault: false,
    }, 'ertektar')).toBe(false)

    expect(isBranchSelectableForAppMode({
      code: 'LEGACY',
      name: 'Legacy',
      city: 'Szeged',
    }, 'ertektar')).toBe(false)
  })

  it('penztar modban a nem ertektari fiok is valaszthato', () => {
    expect(isBranchSelectableForAppMode({
      code: 'KORUT',
      name: 'Korut',
      city: 'Szeged',
      isVault: false,
    }, 'penztar')).toBe(true)
  })

  it('ertekszallito modban a fizikai fiok valaszthato', () => {
    expect(isBranchSelectableForAppMode({
      code: 'KORUT',
      name: 'Korut',
      city: 'Szeged',
      isVault: false,
    }, 'ertekszallito')).toBe(true)
  })

  it('a listaszures ugyanazt az app-mode guardot hasznalja', () => {
    const branches = [
      { code: 'VAULT', name: 'Ertektar', city: 'Szeged', isVault: true },
      { code: 'KORUT', name: 'Korut', city: 'Szeged', isVault: false },
      { code: 'LEGACY', name: 'Legacy', city: 'Szeged' },
    ]

    expect(filterBranchesForAppMode(branches, 'ertektar').map((branch) => branch.code))
      .toEqual(['VAULT'])
    expect(filterBranchesForAppMode(branches, 'penztar').map((branch) => branch.code))
      .toEqual(['VAULT', 'KORUT', 'LEGACY'])
    expect(filterBranchesForAppMode(branches, 'ertekszallito').map((branch) => branch.code))
      .toEqual(['VAULT', 'KORUT', 'LEGACY'])
  })
})

describe('resolveSelectedWorkerForSetup', () => {
  const workers = [
    { code: 'BORSI', name: 'Borsi Tamas' },
    { code: 'KASZA', name: 'Kasza Helga' },
  ]

  it('online modban a valodi worker-listabol valasztott kodot worker setup-kent kezeli', () => {
    expect(resolveSelectedWorkerForSetup({
      offlineMode: false,
      workerCode: ' borsi ',
      availableWorkers: workers,
    })).toEqual({ code: 'BORSI', name: 'Borsi Tamas' })
  })

  it('offline modban nem indit worker-first-time setupot', () => {
    expect(resolveSelectedWorkerForSetup({
      offlineMode: true,
      workerCode: 'BORSI',
      availableWorkers: workers,
    })).toBeNull()
  })

  it('manualisan beirt, de listaban nem szereplo kodnal legacy bootstrap ag marad', () => {
    expect(resolveSelectedWorkerForSetup({
      offlineMode: false,
      workerCode: 'ADMIN',
      availableWorkers: workers,
    })).toBeNull()
  })
})

describe('buildConnectionTestResetKey', () => {
  const base = {
    apiUrl: 'https://excvaluta.com/api/v1',
    companyCode: 'EBC',
    bootstrapUsername: 'BORSI',
    bootstrapPassword: 'old-secret',
    offlineMode: false,
    appMode: 'penztar' as const,
    branchCode: 'KORUT',
  }

  it('changes when setup credentials or app scope changes', () => {
    const original = buildConnectionTestResetKey(base)

    expect(buildConnectionTestResetKey({ ...base, bootstrapUsername: 'KASZA' })).not.toBe(original)
    expect(buildConnectionTestResetKey({ ...base, bootstrapPassword: 'other-secret' })).not.toBe(original)
    expect(buildConnectionTestResetKey({ ...base, appMode: 'ertektar' })).not.toBe(original)
    expect(buildConnectionTestResetKey({ ...base, branchCode: 'VAULT' })).not.toBe(original)
    expect(buildConnectionTestResetKey({ ...base, offlineMode: true })).not.toBe(original)
  })

  it('normalizes case and surrounding whitespace for stable identity fields', () => {
    expect(buildConnectionTestResetKey({
      ...base,
      companyCode: ' ebc ',
      bootstrapUsername: ' borsi ',
      branchCode: ' korut ',
    })).toBe(buildConnectionTestResetKey(base))
  })
})
