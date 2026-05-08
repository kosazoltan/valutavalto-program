import type { AppMode } from '../types/appMode'

export type LoginAppMode = AppMode

const SERVER_ALLOWED_CANONICAL_ROLES = [
  'ugyvezeto', 'foertektar', 'irodavezeto', 'belso_ellenor',
  'berszamfejto', 'penzugyi_vezeto', 'irodai_dolgozo',
  'csoportvezeto', 'arfolyam_nezo',
]
const SERVER_ALLOWED_LEGACY_ROLES = ['SUPERVISOR', 'MANAGER', 'ADMIN']
export const OFFLINE_RESTORE_ROLE = 'CASHIER'
const LEGACY_PENZTAR_ROLES = [OFFLINE_RESTORE_ROLE]
const LEGACY_ERTEKTAR_ROLES = ['MANAGER', 'TREASURY_MANAGER']
const LEGACY_ERTEKSZALLITO_ROLES = ['COURIER']

function isServerRole(roleCode: string): boolean {
  const trimmed = roleCode.trim()
  if (!trimmed) return false
  return SERVER_ALLOWED_CANONICAL_ROLES.includes(trimmed.toLowerCase())
    || SERVER_ALLOWED_LEGACY_ROLES.includes(trimmed.toUpperCase())
}

export function canonicalizeRoleForAppMode(roleCode: string | null | undefined): string {
  const trimmed = roleCode?.trim()
  if (!trimmed) return ''

  const canonical = trimmed.toLowerCase()
  const legacy = trimmed.toUpperCase()

  if (LEGACY_PENZTAR_ROLES.includes(legacy)) return 'penztar'
  if (LEGACY_ERTEKTAR_ROLES.includes(legacy)) return 'ertektar'
  if (LEGACY_ERTEKSZALLITO_ROLES.includes(legacy)) return 'ertekszallito'
  return canonical
}

export function isRoleSelectableForAppMode(
  roleCode: string | null | undefined,
  appMode: AppMode,
): boolean {
  if (!roleCode) return false
  const canonical = canonicalizeRoleForAppMode(roleCode)
  const serverRole = isServerRole(roleCode)

  if (appMode === 'full') return serverRole
  if (appMode === 'penztar') {
    return serverRole || canonical === 'penztar'
  }
  if (appMode === 'ertektar') {
    return serverRole || canonical === 'ertektar'
  }
  if (appMode === 'ertekszallito') {
    return serverRole || canonical === 'ertekszallito'
  }
  return false
}

export function appModeLabel(appMode: AppMode): string {
  if (appMode === 'penztar') return 'Valutaváltó Pénztár'
  if (appMode === 'ertektar') return 'Értéktár'
  if (appMode === 'ertekszallito') return 'Értékszállító'
  return 'Szerver'
}

const ROLE_DISPLAY_NAMES: Record<string, string> = {
  penztar: 'Pénztáros',
  ertektar: 'Értéktáros',
  foertektar: 'Főértéktáros',
  ugyvezeto: 'Ügyvezető',
  belso_ellenor: 'Belső ellenőr',
  irodavezeto: 'Irodavezető',
  berszamfejto: 'Bérszámfejtő',
  penzugyi_vezeto: 'Pénzügyi vezető',
  irodai_dolgozo: 'Irodai dolgozó',
  csoportvezeto: 'Csoportvezető',
  arfolyam_nezo: 'Árfolyam néző',
  ertekszallito: 'Értékszállító',
}

export function roleDisplayName(roleCode: string): string {
  return ROLE_DISPLAY_NAMES[roleCode.toLowerCase()] ?? roleCode
}
