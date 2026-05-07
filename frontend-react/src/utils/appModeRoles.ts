export type LoginAppMode = 'full' | 'penztar' | 'ertektar'

const SERVER_ALLOWED_CANONICAL_ROLES = [
  'ugyvezeto', 'foertektar', 'irodavezeto', 'belso_ellenor',
  'berszamfejto', 'penzugyi_vezeto', 'irodai_dolgozo',
  'csoportvezeto', 'arfolyam_nezo',
]
const SERVER_ALLOWED_LEGACY_ROLES = ['SUPERVISOR', 'MANAGER', 'ADMIN']
const LEGACY_PENZTAR_ROLES = ['CASHIER']
const LEGACY_ERTEKTAR_ROLES = ['MANAGER', 'TREASURY_MANAGER']

function isServerRole(roleCode: string): boolean {
  return SERVER_ALLOWED_CANONICAL_ROLES.includes(roleCode.toLowerCase())
    || SERVER_ALLOWED_LEGACY_ROLES.includes(roleCode.toUpperCase())
}

export function isRoleSelectableForAppMode(
  roleCode: string | null | undefined,
  appMode: LoginAppMode,
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

export function appModeLabel(appMode: LoginAppMode): string {
  if (appMode === 'penztar') return 'Valutaváltó Pénztár'
  if (appMode === 'ertektar') return 'Értéktár'
  return 'Szerver'
}
