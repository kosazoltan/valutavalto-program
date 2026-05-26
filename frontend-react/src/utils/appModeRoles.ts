import type { AppMode } from '../types/appMode'

export type LoginAppMode = AppMode

const SERVER_ALLOWED_CANONICAL_ROLES = [
  'ugyvezeto', 'foertektar', 'irodavezeto', 'belso_ellenor',
  'teruleti_vezeto', 'biztonsagi_vezeto',
  'berszamfejto', 'penzugyi_vezeto', 'irodai_dolgozo',
  'csoportvezeto', 'arfolyam_nezo',
]
const SERVER_ALLOWED_LEGACY_ROLES = ['SUPERVISOR', 'MANAGER', 'ADMIN']
const RATE_MAKER_ALLOWED_CANONICAL_ROLES = ['foertektar', 'ugyvezeto']
const RATE_MAKER_ALLOWED_LEGACY_ROLES = ['ADMIN']
export const OFFLINE_RESTORE_ROLE = 'CASHIER'
const LEGACY_PENZTAR_ROLES = [OFFLINE_RESTORE_ROLE]
const LEGACY_ERTEKTAR_ROLES = ['MANAGER', 'TREASURY_MANAGER']
const LEGACY_ERTEKSZALLITO_ROLES = ['COURIER']

// Kis irodákban egy dolgozó több módban is dolgozhat (pl. értéktáros a pénztár
// módban is belép), ezért bármely lokális módban mindhárom lokális role választható.
const LOCAL_CANONICAL_ROLES = ['penztar', 'ertektar', 'ertekszallito']

function isLocalRole(roleCode: string): boolean {
  return LOCAL_CANONICAL_ROLES.includes(canonicalizeRoleForAppMode(roleCode))
}

function isServerRole(roleCode: string): boolean {
  const trimmed = roleCode.trim()
  if (!trimmed) return false
  return SERVER_ALLOWED_CANONICAL_ROLES.includes(trimmed.toLowerCase())
    || SERVER_ALLOWED_LEGACY_ROLES.includes(trimmed.toUpperCase())
}

function isRateMakerRole(roleCode: string): boolean {
  const trimmed = roleCode.trim()
  if (!trimmed) return false
  return RATE_MAKER_ALLOWED_CANONICAL_ROLES.includes(trimmed.toLowerCase())
    || RATE_MAKER_ALLOWED_LEGACY_ROLES.includes(trimmed.toUpperCase())
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
  const serverRole = isServerRole(roleCode)

  const localRole = isLocalRole(roleCode)

  if (appMode === 'full') return serverRole
  if (appMode === 'penztar') {
    return serverRole || localRole
  }
  if (appMode === 'ertektar') {
    return serverRole || localRole
  }
  if (appMode === 'ertekszallito') {
    return serverRole || localRole
  }
  if (appMode === 'rate-maker') {
    return isRateMakerRole(roleCode)
  }
  return false
}

/**
 * A penztar-client (lokál terminál) által renderelhető üzleti módok.
 * A kozponti-client a full + rate-maker módokat csomagolja — más a támogatott halmaza.
 */
export const PENZTAR_CLIENT_LOCAL_MODES: AppMode[] = ['penztar', 'ertektar', 'ertekszallito']

/**
 * HIBA 2026-05-26 (mód-választó): a belépő dolgozó által ténylegesen választható módok
 * az AKTUÁLIS kliensen — a backend `validAppModes`-ának metszete a kliens által
 * támogatott módokkal. Ha >1, a belépés után mód-választót kell mutatni.
 *
 * A `supported` sorrendje adja a megjelenítési sorrendet.
 */
export function selectableLocalAppModes(
  validAppModes: string[] | null | undefined,
  supported: AppMode[] = PENZTAR_CLIENT_LOCAL_MODES,
): AppMode[] {
  if (!validAppModes || validAppModes.length === 0) return []
  const allowed = new Set(validAppModes)
  return supported.filter((m) => allowed.has(m))
}

function isLocalAppMode(appMode: AppMode): boolean {
  return PENZTAR_CLIENT_LOCAL_MODES.includes(appMode)
}

/**
 * A kiválasztott módhoz a legmegfelelőbb szerepkód a dolgozó szerepkörei közül
 * (a /auth/login/select-role hívásnak kell egy appMode-ra érvényes roleCode).
 * Preferencia (least-privilege):
 *   1. a módra kanonikusan illeszkedő role;
 *   2. lokál módnál egy LOKÁL role (Codex P1 #860: a generikus „selectable" fallback
 *      lokál módnál szerver-role-t is elfogad, így a lista-sorrend miatt egy magasabb jogú
 *      szerver-role kerülhetne be — pl. `foertektar` a `penztar` ellenőrzéshez. Előbb a
 *      lokál role-t választjuk, hogy ne emeljünk jogot a sorrend miatt determinisztikusan);
 *   3. bármely, a módban választható role (pl. inspection-role, ha nincs lokál role);
 *   4. a jelenlegi aktív/worker role (fallback).
 */
export function preferredRoleForAppMode(
  roles: string[] | null | undefined,
  appMode: AppMode,
  fallbackRole: string | null | undefined,
): string | null {
  const list = (roles ?? []).filter((r) => r && r.trim().length > 0)
  const canonicalMatch = list.find((r) => canonicalizeRoleForAppMode(r) === appMode)
  if (canonicalMatch) return canonicalMatch
  if (isLocalAppMode(appMode)) {
    const localSelectable = list.find((r) => isLocalRole(r) && isRoleSelectableForAppMode(r, appMode))
    if (localSelectable) return localSelectable
  }
  const selectable = list.find((r) => isRoleSelectableForAppMode(r, appMode))
  if (selectable) return selectable
  const fb = fallbackRole?.trim()
  return fb && fb.length > 0 ? fb : null
}

export function appModeLabel(appMode: AppMode): string {
  if (appMode === 'penztar') return 'Valutaváltó Pénztár'
  if (appMode === 'ertektar') return 'Értéktár'
  if (appMode === 'ertekszallito') return 'Értékszállító'
  if (appMode === 'rate-maker') return 'Árfolyamkészítő'
  return 'Szerver'
}

const ROLE_DISPLAY_NAMES: Record<string, string> = {
  penztar: 'Pénztáros',
  ertektar: 'Értéktáros',
  foertektar: 'Főértéktáros',
  ugyvezeto: 'Ügyvezető',
  belso_ellenor: 'Belső ellenőr',
  irodavezeto: 'Irodavezető',
  teruleti_vezeto: 'Területi vezető',
  biztonsagi_vezeto: 'Biztonsági vezető',
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
