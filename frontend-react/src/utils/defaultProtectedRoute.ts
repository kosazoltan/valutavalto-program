import type { AppFlavor } from './clientEnv'
import type { AppMode } from '../types/appMode'
import { getDefaultRouteForRoles } from '../layouts/menuGroups'
import { isRoleSelectableForAppMode } from './appModeRoles'

/**
 * FKH-041 FR-1: a lokál terminál (penztar/ertektar mód) belépés utáni kezdő útvonala
 * SZEREPKÖR-alapú, nem mód-alapú. Enélkül a config-ból visszatöltött `penztar` appMode
 * miatt az értéktáros is `/dashboard`-ra, majd a napi-session kapun át
 * `/cashdesk/day-open`-re került (MainLayout.tsx:215-217).
 *
 * Tiszta függvény: a flavor/appMode/roles/activeRole paramétereket a hívó adja
 * (App.tsx), ezért az `import.meta.env` közvetlen olvasása nélkül, flavoronként
 * unit-tesztelhető. A route-precedencia egyetlen forrása a `getDefaultRouteForRoles`.
 */
export function resolveDefaultProtectedRoute(params: {
  flavor: AppFlavor
  appMode: AppMode
  roles?: readonly string[] | null
  activeRole?: string | null
}): string {
  const { flavor, appMode, roles, activeRole } = params

  // 1-2. A kliens-flavor build-időben rögzített, mindent felülír.
  if (flavor === 'central-workstation') return '/central-workstation'
  if (flavor === 'rate-maker') return '/rates/main'

  // 3-4. Nem lokál terminál appMode-ok saját kezdő oldala.
  if (appMode === 'full') return '/central-workstation'
  if (appMode === 'rate-maker') return '/rates/main'

  // 5. Lokál terminál (penztar | ertektar): SZEREPKÖR-alapú útvonal.
  // Csak az aktuális módban választható szerepek számítanak (minta: RateWatcherGuard
  // az App.tsx-ben) — így a penztar módban is választható ertektar szerep nem esik ki,
  // és a `getDefaultRouteForRoles` penztar-precedenciája (multiszerep) is megmarad.
  const filteredRoles = (roles ?? []).filter((role) => isRoleSelectableForAppMode(role, appMode))
  const filteredActiveRole =
    activeRole && isRoleSelectableForAppMode(activeRole, appMode) ? activeRole : null

  if (filteredRoles.length === 0 && !filteredActiveRole) {
    // Restore előtti / üres szerepállapot: a FKH-041 előtti default marad.
    return '/dashboard'
  }

  return getDefaultRouteForRoles(filteredRoles, filteredActiveRole)
}
