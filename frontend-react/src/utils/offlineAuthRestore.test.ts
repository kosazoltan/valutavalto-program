import { describe, expect, it } from 'vitest'
import { resolveOfflineRestoreProfile } from './offlineAuthRestore'

describe('resolveOfflineRestoreProfile', () => {
  it('restores an ertektar profile in ertektar app mode', () => {
    const profile = resolveOfflineRestoreProfile(
      {
        workerId: 7,
        workerCode: 'VAULT1',
        workerName: 'Vault User',
        activeRole: 'ertektar',
        roles: ['ertektar'],
        branchCode: 'KOZPONT',
        companyCode: 'EBC',
      },
      'ertektar',
    )

    expect(profile?.activeRole).toBe('ertektar')
    expect(profile?.roles).toEqual(['ertektar'])
    expect(profile?.worker.role).toBe('ertektar')
    expect(profile?.worker.workerCode).toBe('VAULT1')
  })

  it('courier-only legacy token is not restored offline in ertektar mode', () => {
    const profile = resolveOfflineRestoreProfile(
      {
        workerId: 9,
        workerCode: 'COURIER1',
        workerName: 'Courier User',
        activeRole: 'COURIER',
        roles: ['COURIER'],
      },
      'ertektar',
    )

    expect(profile).toBeNull()
  })

  it('rejects a role that is not selectable for the local app mode', () => {
    const profile = resolveOfflineRestoreProfile(
      {
        activeRole: 'ertekszallito',
        roles: ['ertekszallito'],
      },
      'penztar',
    )

    expect(profile).toBeNull()
  })

  it('keeps legacy CASHIER restore limited to cashier app mode', () => {
    expect(
      resolveOfflineRestoreProfile({ activeRole: 'CASHIER', roles: ['CASHIER'] }, 'penztar'),
    ).toMatchObject({ activeRole: 'CASHIER', roles: ['CASHIER'] })

    expect(
      resolveOfflineRestoreProfile({ activeRole: 'CASHIER', roles: ['CASHIER'] }, 'ertektar'),
    ).toBeNull()
  })

  it('rejects supervisory/server roles during local offline restore', () => {
    expect(
      resolveOfflineRestoreProfile(
        {
          activeRole: 'ugyvezeto',
          roles: ['ugyvezeto', 'ADMIN', 'MANAGER'],
        },
        'penztar',
      ),
    ).toBeNull()

    expect(
      resolveOfflineRestoreProfile(
        {
          activeRole: 'MANAGER',
          roles: ['MANAGER'],
        },
        'ertektar',
      ),
    ).toBeNull()
  })

  it('strips untrusted supervisory roles when a local offline role is available', () => {
    const profile = resolveOfflineRestoreProfile(
      {
        activeRole: 'ugyvezeto',
        roles: ['ugyvezeto', 'penztar', 'ADMIN'],
      },
      'penztar',
    )

    expect(profile?.activeRole).toBe('penztar')
    expect(profile?.roles).toEqual(['penztar'])
    expect(profile?.worker.role).toBe('penztar')
  })

  it('allows legacy local treasury role in its own offline app mode', () => {
    expect(
      resolveOfflineRestoreProfile({ activeRole: 'TREASURY_MANAGER' }, 'ertektar'),
    ).toMatchObject({ activeRole: 'TREASURY_MANAGER', roles: ['TREASURY_MANAGER'] })
  })

  it('preserves non-string JWT identity claims as strings', () => {
    const profile = resolveOfflineRestoreProfile(
      {
        workerId: '12',
        workerCode: 1234,
        workerName: 5678,
        branchId: 42,
        branchCode: 100,
        companyId: 77,
        companyCode: 88,
        activeRole: 'penztar',
        roles: ['penztar'],
      },
      'penztar',
    )

    expect(profile?.worker).toMatchObject({
      id: 12,
      workerCode: '1234',
      fullName: '5678',
      branchId: '42',
      branchCode: '100',
      companyId: '77',
      companyCode: '88',
    })
  })
})
