import type { AppMode } from '../hooks/useAppMode'

const SERVER_ALLOWED_CANONICAL_ROLES = [
  'ugyvezeto', 'foertektar', 'irodavezeto', 'belso_ellenor',
  'berszamfejto', 'penzugyi_vezeto', 'irodai_dolgozo',
  'csoportvezeto', 'arfolyam_nezo',
]
const SERVER_ALLOWED_LEGACY_ROLES = ['SUPERVISOR', 'MANAGER', 'ADMIN']
export const OFFLINE_RESTORE_ROLE = 'CASHIER'
const LEGACY_PENZTAR_ROLES = [OFFLINE_RESTORE_ROLE]
const LEGACY_ERTEKTAR_ROLES = ['MANAGER', 'TREASURY_MANAGER']

function isServerRole(roleCode: string): boolean {
  return SERVER_ALLOWED_CANONICAL_ROLES.includes(roleCode.toLowerCase())
    || SERVER_ALLOWED_LEGACY_ROLES.includes(roleCode.toUpperCase())
}

export function isRoleSelectableForAppMode(
  roleCode: string | null | undefined,
  appMode: AppMode,
): boolean {
  if (!roleCode) return false
  const canonical = roleCode.toLowerCase()
  const legacy = roleCode.toUpperCase()
  const serverRole = isServerRole(roleCode)

  if (appMode === 'full') return serverRole
  if (appMode === 'penztar') {
    return serverRole || canonical === 'penztar' || LEGACY_PENZTAR_ROLES.includes(legacy)
  }
  if (appMode === 'ertektar') {
    return serverRole || canonical === 'ertektar' || LEGACY_ERTEKTAR_ROLES.includes(legacy)
  }
  return false
}

export function appModeLabel(appMode: AppMode): string {
  if (appMode === 'penztar') return 'Valutaváltó Pénztár'
  if (appMode === 'ertektar') return 'Értéktár'
  return 'Szerver'
}
