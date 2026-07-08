import { describe, it, expect } from 'vitest'
import { getCompanyType } from './localQueue'
import type { Worker } from '../stores/authStore'

function worker(partial: Partial<Worker>): Worker {
  return {
    id: 1,
    workerCode: 'W1',
    firstName: 'Teszt',
    lastName: 'Elek',
    fullName: 'Teszt Elek',
    role: 'CASHIER',
    branchId: 'b1',
    branchCode: 'BR001',
    branchName: 'Teszt fiók',
    companyId: 'c1',
    companyCode: '',
    companyName: '',
    ...partial,
  }
}

describe('getCompanyType — tenant azonosítás a bizonylat-fejléchez', () => {
  it('EBC tenant (code="EBC", name="Exclusive Best Change Zrt.") → BEST_CHANGE', () => {
    // Regresszió: a korábbi `companyCode.includes("BEST")` tévesen EXPRESSZ-re esett,
    // mert az EBC cégkód nem tartalmazza a "BEST"-et — tenant-keveredés a bizonylaton.
    expect(
      getCompanyType(worker({ companyCode: 'EBC', companyName: 'Exclusive Best Change Zrt.' })),
    ).toBe('BEST_CHANGE')
  })

  it('EBC tenant csak a kód alapján (üres companyName) → BEST_CHANGE', () => {
    expect(getCompanyType(worker({ companyCode: 'EBC', companyName: '' }))).toBe('BEST_CHANGE')
  })

  it('Best Change a névben (eltérő kód) → BEST_CHANGE', () => {
    expect(getCompanyType(worker({ companyCode: 'BC', companyName: 'BEST CHANGE' }))).toBe(
      'BEST_CHANGE',
    )
  })

  it('Expressz Ékszerház (nincs BEST/EBC jel) → EXPRESSZ', () => {
    expect(
      getCompanyType(
        worker({ companyCode: 'EXP', companyName: 'Expressz Ékszerház és Minibank Kft.' }),
      ),
    ).toBe('EXPRESSZ')
  })

  it('null worker → EXPRESSZ (alapértelmezett, nincs pozitív BEST/EBC jel)', () => {
    expect(getCompanyType(null)).toBe('EXPRESSZ')
  })
})
