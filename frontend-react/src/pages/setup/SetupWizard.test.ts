import { describe, expect, it } from 'vitest'
import { resolveSelectedWorkerForSetup } from './SetupWizard'

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
