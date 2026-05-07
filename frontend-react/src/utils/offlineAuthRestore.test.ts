import { describe, expect, it } from 'vitest'
import { resolveOfflineRestoreProfile } from './offlineAuthRestore'

describe('resolveOfflineRestoreProfile', () => {
  it('restores an ertektar profile in ertektar app mode', () => {
    const profile = resolveOfflineRestoreProfile({
      workerId: 7,
      workerCode: 'VAULT1',
      workerName: 'Vault User',
      activeRole: 'ertektar',
      roles: ['ertektar'],
      branchCode: 'KOZPONT',
      companyCode: 'EBC',
    }, 'ertektar')

    expect(profile?.activeRole).toBe('ertektar')
    expect(profile?.roles).toEqual(['ertektar'])
    expect(profile?.worker.role).toBe('ertektar')
    expect(profile?.worker.workerCode).toBe('VAULT1')
  })

  it('restores an ertekszallito profile in ertekszallito app mode', () => {
    const profile = resolveOfflineRestoreProfile({
      workerId: 9,
      workerCode: 'COURIER1',
      workerName: 'Courier User',
      activeRole: 'ertekszallito',
      roles: ['ertekszallito'],
    }, 'ertekszallito')

    expect(profile?.activeRole).toBe('ertekszallito')
    expect(profile?.roles).toEqual(['ertekszallito'])
    expect(profile?.worker.role).toBe('ertekszallito')
  })

  it('rejects a role that is not selectable for the local app mode', () => {
    const profile = resolveOfflineRestoreProfile({
      activeRole: 'ertekszallito',
      roles: ['ertekszallito'],
    }, 'penztar')

    expect(profile).toBeNull()
  })

  it('keeps legacy CASHIER restore limited to cashier app mode', () => {
    expect(resolveOfflineRestoreProfile({ activeRole: 'CASHIER', roles: ['CASHIER'] }, 'penztar'))
      .toMatchObject({ activeRole: 'CASHIER', roles: ['CASHIER'] })

    expect(resolveOfflineRestoreProfile({ activeRole: 'CASHIER', roles: ['CASHIER'] }, 'ertektar'))
      .toBeNull()
  })
})
