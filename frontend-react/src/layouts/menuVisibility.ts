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

/** Item effektív szerepkör-megszorítása: saját canonicalRoles, különben a csoporté (öröklés). */
export function isMenuItemVisible(item: MenuItem, group: MenuGroup, ctx: MenuVisibilityContext): boolean {
  if (item.modes && !item.modes.includes(ctx.appMode)) return false
  if (item.minRole && !ctx.hasRole(item.minRole)) return false
  if (isSupervisoryMenuBypass(ctx)) return true
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
