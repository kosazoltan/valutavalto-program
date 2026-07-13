import type { Worker } from '../stores/authStore'
import type { AppMode } from '../types/appMode'

export interface OfflineJwtPayload {
  workerId?: unknown
  workerCode?: unknown
  workerName?: unknown
  branchId?: unknown
  branchCode?: unknown
  branchName?: unknown
  companyId?: unknown
  companyCode?: unknown
  companyName?: unknown
  activeRole?: unknown
  roles?: unknown
}

export interface OfflineRestoreProfile {
  worker: Worker
  activeRole: string
  roles: string[]
}

export function resolveOfflineRestoreProfile(
  payload: OfflineJwtPayload,
  appMode: AppMode,
): OfflineRestoreProfile | null {
  const candidateRoles = collectCandidateRoles(payload)
  const activeRole = candidateRoles.find((role) => isOfflineLocalRoleForAppMode(role, appMode))
  if (!activeRole) {
    return null
  }

  return {
    worker: {
      id: Number(payload.workerId) || 0,
      workerCode: stringValue(payload.workerCode),
      firstName: '',
      lastName: '',
      fullName: stringValue(payload.workerName),
      role: activeRole,
      branchId: stringValue(payload.branchId),
      branchCode: stringValue(payload.branchCode),
      branchName: stringValue(payload.branchName),
      companyId: stringValue(payload.companyId),
      companyCode: stringValue(payload.companyCode),
      companyName: stringValue(payload.companyName),
    },
    activeRole,
    roles: [activeRole],
  }
}

function isOfflineLocalRoleForAppMode(roleCode: string, appMode: AppMode): boolean {
  const canonical = roleCode.trim().toLowerCase()
  const legacy = roleCode.trim().toUpperCase()

  if (appMode === 'penztar') {
    return canonical === 'penztar' || legacy === 'CASHIER'
  }
  if (appMode === 'ertektar') {
    return canonical === 'ertektar' || legacy === 'TREASURY_MANAGER'
  }
  return false
}

function collectCandidateRoles(payload: OfflineJwtPayload): string[] {
  const rolesFromClaim = Array.isArray(payload.roles) ? payload.roles : []
  const rawRoles = [payload.activeRole, ...rolesFromClaim]
  const seen = new Set<string>()
  const roles: string[] = []

  for (const rawRole of rawRoles) {
    if (typeof rawRole !== 'string') continue
    const role = rawRole.trim()
    if (!role) continue
    const key = role.toLowerCase()
    if (seen.has(key)) continue
    seen.add(key)
    roles.push(role)
  }

  return roles
}

function stringValue(value: unknown): string {
  return value == null ? '' : String(value)
}
