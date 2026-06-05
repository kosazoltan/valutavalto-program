import { Navigate } from 'react-router-dom'
import { useAuthStore } from '../stores/authStore'

/**
 * RoleGate — szerepkör-szintű route-védelem (Codex #1056 P1+P2).
 *
 * A védett route-okat eddig csak a `ProtectedRoute` (auth) védte → bárki, aki belépett,
 * közvetlen URL-lel elérte a korlátozott admin-oldalakat (pl. a Pénztár Törzs Adatbázist).
 * A RoleGate SZIGORÚAN a megadott `canonicalRoles`-ra korlátoz: csak az a felhasználó
 * léphet be, akinek a tényleges szerepköre canonicalizálva szerepel a listában.
 *
 * P2 (Codex #1056): szándékosan NEM használunk `hasSupervisoryAccess` (bármely
 * szerver-szerepkör) rövidzárat — az túl tág hozzáférést adott (pl. arfolyam_nezo,
 * teruleti_vezeto, irodai_dolgozo), eltérve a dokumentált szerepkör-szűkítéstől. A
 * `hasCanonicalRole` ADMIN-fallbackje (ADMIN minden role-t teljesít) megmarad.
 *
 * Megj.: a menü (`MainLayout`) láthatósági szűrője külön réteg; az `isAuthenticated`
 * ellenőrzést a szülő `ProtectedRoute` már elvégzi.
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
  const allowed = canonicalRoles.some((r) => hasCanonicalRole(r))
  if (!allowed) {
    return <Navigate to={redirectTo} replace />
  }
  return <>{children}</>
}
