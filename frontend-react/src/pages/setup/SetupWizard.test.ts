import { describe, expect, it } from 'vitest'
import { resolveSelectedWorkerForSetup, shouldLoadSetupWorkers } from './SetupWizard'

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

describe('shouldLoadSetupWorkers', () => {
  it('nem tolt worker-listat offline modban vagy ures branch kodnal', () => {
    expect(shouldLoadSetupWorkers('BR001', true)).toBe(false)
    expect(shouldLoadSetupWorkers('   ', false)).toBe(false)
  })

  it('csak online modban es valodi branch kodnal indit worker-lista betoltest', () => {
    expect(shouldLoadSetupWorkers(' BR001 ', false)).toBe(true)
  })
})
