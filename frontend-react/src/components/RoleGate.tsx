import { Navigate } from 'react-router-dom'
import { useAuthStore } from '../stores/authStore'
import { SZERVER_ROLES } from '../layouts/menuGroups'

/**
 * RoleGate — szerepkör-szintű route-védelem (Codex #1056 P1).
 *
 * A menü `canonicalRoles`-szal szűri a láthatóságot, de a route-okat eddig csak a
 * `ProtectedRoute` (auth) védte → bárki, aki belépett, közvetlen URL-lel elérte a
 * korlátozott admin-oldalakat (pl. a Pénztár Törzs Adatbázist). A RoleGate pontosan a
 * menü-predikátumot tükrözi: `hasSupervisoryAccess` (bármely szerver-szerepkör) VAGY a
 * megadott canonical role valamelyike. Így nem szűkít a menünél jobban, viszont kizárja a
 * pénztáros (penztaros) közvetlen URL-belépést a felügyeleti oldalakra.
 *
 * Megj.: az `isAuthenticated` ellenőrzést a szülő `ProtectedRoute` már elvégzi.
 */
export default function RoleGate({
  canonicalRoles,
  children,
  redirectTo = '/',
}: {
  canonicalRoles: readonly string[]
  children: React.ReactNode
  redirectTo?: string
}) {
  const hasCanonicalRole = useAuthStore((state) => state.hasCanonicalRole)
  const hasSupervisoryAccess = SZERVER_ROLES.some((r) => hasCanonicalRole(r))
  const allowed = hasSupervisoryAccess || canonicalRoles.some((r) => hasCanonicalRole(r))
  if (!allowed) {
    return <Navigate to={redirectTo} replace />
  }
  return <>{children}</>
}
