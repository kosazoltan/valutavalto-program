import { SZERVER_ROLES, type MenuItem, type MenuGroup, type FeatureFlagKey } from './menuGroups'
import type { AppMode } from '../types/appMode'

/**
 * Menü-láthatóság tiszta (renderelés-mentes) logikája — RBAC-audit (2026-06-05).
 *
 * Modell ("konzisztens szigorítás"):
 * - A központi (`full`) admin felületen a menü-láthatóság SZIGORÚAN a dokumentált
 *   canonicalRoles-t követi (least-privilege), öröklődéssel: az item effektív szerepköre a
 *   saját canonicalRoles, különben a csoporté.
 * - A lokál kliensekben (penztar/ertektar/rate-maker) a felügyeleti userek SZÁNDÉKOSAN
 *   látják a teljes (mód szerint engedett) menüt az oversighthoz (`supervisoryMenuBypass`).
 * - Egy csoport akkor látszik, ha van legalább egy látható itemje — így a foertektar látja az
 *   Adminisztráció-csoportot a /admin/branches item miatt, holott a csoport-roles kizárná.
 *
 * Ugyanezt a route-szintű `RoleGate` SZIGORÚAN (bypass nélkül) érvényesíti minden módban,
 * így a menü-láthatóság (full módban) egyezik a route-hozzáféréssel.
 */
export interface MenuVisibilityContext {
  appMode: AppMode
  hasCanonicalRole: (role: string) => boolean
  hasRole: (role: string) => boolean
  featureFlags: Partial<Record<FeatureFlagKey, boolean>>
}

export function hasSupervisoryAccess(hasCanonicalRole: (role: string) => boolean): boolean {
  return SZERVER_ROLES.some((r) => hasCanonicalRole(r))
}

/** A lokál (nem-`full`) appMode-okban a felügyeleti user a teljes menüt látja (oversight). */
function isSupervisoryMenuBypass(ctx: MenuVisibilityContext): boolean {
  return ctx.appMode !== 'full' && hasSupervisoryAccess(ctx.hasCanonicalRole)
}

/**
 * Item effektív szerepkör-megszorítása: saját canonicalRoles, különben a csoporté (öröklés).
 *
 * Sorrend (Sourcery #1059): a `modes` és a `minRole` a felügyeleti bypass ELŐTT érvényesül —
 * azaz a bypass KIZÁRÓLAG a canonicalRoles-ellenőrzést írja felül (a mód- és minRole-szűrést
 * NEM). Ez szándékos és egyezik az audit előtti viselkedéssel (a `hasSupervisoryAccess` ott is
 * csak a role-szűrőt rövidzárta, a külön mód- és minRole-szűrőt nem).
 */
export function isMenuItemVisible(
  item: MenuItem,
  group: MenuGroup,
  ctx: MenuVisibilityContext,
): boolean {
  if (item.modes && !item.modes.includes(ctx.appMode)) return false
  if (item.minRole && !ctx.hasRole(item.minRole)) return false
  if (isSupervisoryMenuBypass(ctx)) return true
  // FKH-026 v3: a `hidden` bejegyzés a standard menüből rejtett — a felügyeleti
  // bypass szándékosan ELŐBB fut (Főértéktáros/helyettes oversightként látja, §3
  // mátrix), a szerepkör-alapú láthatóság viszont itt megáll.
  if (item.hidden) return false
  const roles = item.canonicalRoles ?? group.canonicalRoles
  return !roles || roles.some((r) => ctx.hasCanonicalRole(r))
}

/** Csoport láthatóság: mód + feature-flag + van legalább egy látható item. */
export function isMenuGroupVisible(group: MenuGroup, ctx: MenuVisibilityContext): boolean {
  if (group.modes && !group.modes.includes(ctx.appMode)) return false
  if (group.featureFlagKey && !ctx.featureFlags[group.featureFlagKey]) return false
  return group.items.some((item) => isMenuItemVisible(item, group, ctx))
}

/**
 * kanban #8: az appMode szerinti alapértelmezett csoport címkéje a zero-visible
 * fallbackhez. `full` SZÁNDÉKOSAN nincs a térképben: a központi admin felület
 * least-privilege szigorítása megmarad (üres menü = nincs jogosultság).
 */
export const FALLBACK_GROUP_LABEL_BY_MODE: Partial<Record<AppMode, string>> = {
  penztar: 'Pénztár (Valutaváltó)',
  ertektar: 'Értéktár (lokál)',
}

export interface ResolvedMenuGroups {
  groups: MenuGroup[]
  fallbackApplied: boolean
}

/**
 * kanban #8: a látható csoportok feloldása zero-visible fallbackkel.
 *
 * Ha egy hitelesített dolgozónak EGY látható csoport sincs (sérült
 * szerep-hozzárendelés, legacy-orphan worker), a sidebar az appMode
 * alapértelmezett operatív csoportját mutatja üres navigáció helyett —
 * a fallback items-jei CSAK modes/hidden szerint szűröttek (a szerep-szűrő
 * bypassolt, különben a nav üres maradna), a rejtett felügyeleti bejegyzések
 * rejtve maradnak. A fallback-csoport másolata friss items-tömbbel tér vissza
 * (a közös `menuGroups` definíció nem mutálódik).
 */
export function resolveVisibleMenuGroups(
  groups: MenuGroup[],
  ctx: MenuVisibilityContext,
): ResolvedMenuGroups {
  const visible = groups.filter((group) => isMenuGroupVisible(group, ctx))
  if (visible.length > 0) return { groups: visible, fallbackApplied: false }
  const fallbackLabel = FALLBACK_GROUP_LABEL_BY_MODE[ctx.appMode]
  const fallback = fallbackLabel ? groups.find((g) => g.label === fallbackLabel) : undefined
  if (!fallback) return { groups: [], fallbackApplied: false }
  const items = fallback.items.filter((item) => {
    if (item.modes && !item.modes.includes(ctx.appMode)) return false
    if (item.hidden) return false
    return true
  })
  return { groups: [{ ...fallback, items }], fallbackApplied: true }
}

/**
 * Egy útvonal effektív canonicalRoles-a a menüből (a route-szintű RoleGate-hez, single source
 * of truth). Ha az útvonal több csoportban szerepel, a szerepkörök UNIÓJA. Ha bármely előfordulása
 * korlátlan (nincs item- és csoport-szintű canonicalRoles), `undefined` (nem gateljük szerepkörrel).
 * `undefined`, ha az útvonal nincs a menüben.
 */
export function effectiveCanonicalRolesForPath(
  groups: MenuGroup[],
  path: string,
): readonly string[] | undefined {
  const union = new Set<string>()
  let found = false
  let unrestricted = false
  for (const group of groups) {
    for (const item of group.items) {
      if (item.path !== path) continue
      found = true
      const roles = item.canonicalRoles ?? group.canonicalRoles
      if (!roles) unrestricted = true
      else roles.forEach((r) => union.add(r))
    }
  }
  if (!found || unrestricted) return undefined
  return Array.from(union)
}
