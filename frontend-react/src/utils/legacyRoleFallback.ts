import { SZERVER_ROLES } from '../layouts/menuGroups'

/**
 * MENU-LEGACY-ROLE-INVISIBLE (2026-07-12): legacy-orphan fallback a `full` admin-felulet
 * szerepkor-egyeztetesehez.
 *
 * Kizarolag arra a workerre vonatkozik, akinek NINCS canonical role assignment-je
 * (`roles` ures — a WorkerService.login 0-assignment eseten ures roleCodes-t es null
 * activeRole-t ad), es a legacy `worker.role` MANAGER. Ilyenkor a backend legacy
 * authority-javal (hasAnyRole(...,'MANAGER',...) minden AML/Compliance endpointon,
 * LEGACY_SERVER_ROLES az AppModeRoleConstants-ban) szinkronban a SZERVER_ROLES teljes
 * halmazat teljesiti.
 *
 * SZANDEKOSAN NEM erinti:
 * - az ADMIN-t (a hasCanonicalRole ADMIN-aga mar mindent enged),
 * - a SUPERVISOR-t (a backend compliance hasAnyRole sem engedi),
 * - a canonical assignmenttel biro workereket (least-privilege — `roles` nem ures eseten
 *   a fallback tilos),
 * - a canonicalizeRoleForAppMode lokal (penztar/ertektar/ertekszallito) lekepezest.
 */
const LEGACY_FULL_MENU_FALLBACK_ROLE_SET = new Set<string>(SZERVER_ROLES)

export function legacyOrphanFallbackMatches(
  effectiveRole: string | null | undefined,
  assignedRoles: readonly string[] | null | undefined,
  requestedCanonicalRoles: readonly string[],
): boolean {
  if ((assignedRoles ?? []).length > 0) return false
  if (effectiveRole?.trim().toUpperCase() !== 'MANAGER') return false
  return requestedCanonicalRoles.some((r) =>
    LEGACY_FULL_MENU_FALLBACK_ROLE_SET.has(r.trim().toLowerCase()),
  )
}
