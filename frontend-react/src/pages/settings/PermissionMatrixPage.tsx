import { useCallback, useEffect, useMemo, useState } from 'react'
import { Grid3x3, Save, RefreshCw, AlertTriangle, CheckCircle2, Shield, Search } from 'lucide-react'
import { permissionApi, roleApi, type Permission, type Role } from '../../services/api/users'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

// Role.permissions backend-ben string[] (permission NEV-ek), a matrix edit-hez
// permission ID-kra kell valtanunk. Ezt a rolePermissionMap tartja.

type RolePermissionMap = Record<string /* roleId */, Set<string> /* permissionIds */>

export default function PermissionMatrixPage() {
  const { t } = useTranslation()
  const [permissions, setPermissions] = useState<Permission[]>([])
  const [roles, setRoles] = useState<Role[]>([])
  const [rolePermMap, setRolePermMap] = useState<RolePermissionMap>({})
  const [originalRolePermMap, setOriginalRolePermMap] = useState<RolePermissionMap>({})
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [err, setErr] = useState<string | null>(null)
  const [msg, setMsg] = useState<string | null>(null)
  const [filter, setFilter] = useState('')
  const [reloadTick, setReloadTick] = useState(0)

  const load = useCallback(() => setReloadTick((t) => t + 1), [])

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    setErr(null)
    Promise.all([permissionApi.getActive(), roleApi.list()])
      .then(([permsRaw, rolesRaw]) => {
        if (cancelled) return
        setPermissions(permsRaw)
        setRoles(rolesRaw)
        // Build map: role.permissions (names) -> permission IDs
        const nameToId = new Map(permsRaw.map((p) => [p.name, p.id]))
        const newMap: RolePermissionMap = {}
        for (const r of rolesRaw) {
          newMap[r.id] = new Set(
            (r.permissions ?? [])
              .map((name) => nameToId.get(name))
              .filter((id): id is string => !!id),
          )
        }
        setRolePermMap(newMap)
        // Deep clone for diff
        const clone: RolePermissionMap = {}
        for (const [k, v] of Object.entries(newMap)) clone[k] = new Set(v)
        setOriginalRolePermMap(clone)
      })
      .catch((e) => {
        if (!cancelled) {
          logger.error('PermissionMatrix', 'load err', e)
          setErr(e instanceof Error ? e.message : String(e))
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [reloadTick])

  // Permissions grouped by module
  const permissionsByModule = useMemo(() => {
    const groups: Record<string, Permission[]> = {}
    for (const p of permissions) {
      if (
        filter &&
        !p.name.toLowerCase().includes(filter.toLowerCase()) &&
        !p.code.toLowerCase().includes(filter.toLowerCase()) &&
        !p.module.toLowerCase().includes(filter.toLowerCase())
      )
        continue
      if (!groups[p.module]) groups[p.module] = []
      groups[p.module]!.push(p)
    }
    return Object.entries(groups).sort(([a], [b]) => a.localeCompare(b))
  }, [permissions, filter])

  // Toggle single cell
  const toggle = (roleId: string, permId: string) => {
    setRolePermMap((prev) => {
      const next = { ...prev }
      const set = new Set(next[roleId] ?? [])
      if (set.has(permId)) set.delete(permId)
      else set.add(permId)
      next[roleId] = set
      return next
    })
  }

  // Count changes per role
  const dirtyRoles = useMemo(() => {
    const dirty = new Set<string>()
    for (const r of roles) {
      const orig = originalRolePermMap[r.id] ?? new Set<string>()
      const curr = rolePermMap[r.id] ?? new Set<string>()
      if (orig.size !== curr.size) {
        dirty.add(r.id)
        continue
      }
      for (const id of curr)
        if (!orig.has(id)) {
          dirty.add(r.id)
          break
        }
    }
    return dirty
  }, [rolePermMap, originalRolePermMap, roles])

  const hasChanges = dirtyRoles.size > 0

  // Save: bulk update every dirty role
  const handleSave = async () => {
    if (!hasChanges || saving) return
    setSaving(true)
    setErr(null)
    setMsg(null)
    try {
      const updates: Promise<unknown>[] = []
      for (const roleId of dirtyRoles) {
        const permIds = Array.from(rolePermMap[roleId] ?? [])
        updates.push(roleApi.update(roleId, { permissionIds: permIds }))
      }
      await Promise.all(updates)
      setMsg(`${dirtyRoles.size} szerepkor modositas sikeresen mentve.`)
      // Re-sync with server
      load()
    } catch (e) {
      logger.error('PermissionMatrix', 'save err', e)
      setErr(e instanceof Error ? e.message : String(e))
    } finally {
      setSaving(false)
    }
  }

  const handleDiscard = () => {
    const clone: RolePermissionMap = {}
    for (const [k, v] of Object.entries(originalRolePermMap)) clone[k] = new Set(v)
    setRolePermMap(clone)
    setMsg(null)
  }

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-base font-bold text-secondary-900 flex items-center gap-2">
            <Grid3x3 className="text-primary-600" size={18} />
            {t('settings.jogosultsagMatrix')}
          </h1>
          <p className="text-xs text-secondary-500">
            {t('settings.szerepkorJogosultsagMatrixEgyszerreSzerkeszthetoAzOsszesKombinacio')}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={load} disabled={loading || saving} className="form-button">
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
            <span>{t('common.refresh')}</span>
          </button>
          {hasChanges && (
            <button
              type="button"
              onClick={handleDiscard}
              disabled={saving}
              className="form-button text-orange-600"
            >
              {t('settings.elvetes')}
            </button>
          )}
          <button
            type="button"
            onClick={() => void handleSave()}
            disabled={!hasChanges || saving}
            className="form-button-primary"
          >
            <Save size={14} />
            <span>
              {saving ? 'Mentes...' : hasChanges ? `Mentes (${dirtyRoles.size})` : 'Nincs változás'}
            </span>
          </button>
        </div>
      </div>

      {/* Messages */}
      {err && (
        <div className="p-4 rounded-lg bg-red-50 border border-red-200 text-red-800 flex items-center gap-2">
          <AlertTriangle size={18} />
          <span className="text-sm">{err}</span>
        </div>
      )}
      {msg && (
        <div className="p-4 rounded-lg bg-green-50 border border-green-200 text-green-800 flex items-center gap-2">
          <CheckCircle2 size={18} />
          <span className="text-sm">{msg}</span>
        </div>
      )}

      {/* Filter */}
      <div className="form-panel p-3 flex items-center gap-2">
        <Search size={14} className="text-secondary-400" />
        <input
          type="text"
          className="form-input h-8 text-xs flex-1"
          placeholder="Szures permission nev / code / modul szerint..."
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
        />
        <span className="text-xs text-secondary-500">
          {permissions.length} {t('settings.permission')} {roles.length} {t('settings.role')}
        </span>
      </div>

      {/* Matrix */}
      <div className="form-panel overflow-x-auto">
        {loading ? (
          <div className="p-8 text-center text-secondary-400">{i18n.t('literals.betoltes-4')}</div>
        ) : (
          <table className="w-full">
            <thead className="bg-secondary-50 sticky top-0">
              <tr>
                <th className="text-left px-3 py-2 border-b border-secondary-200 sticky left-0 bg-secondary-50 z-10 min-w-[180px]">
                  {t('settings.szerepkor')}
                </th>
                {permissionsByModule.map(([module, perms]) =>
                  perms.map((p) => (
                    <th
                      key={p.id}
                      className="text-center px-2 py-2 border-b border-secondary-200 text-xs min-w-[60px] max-w-[80px]"
                      title={`${p.name}\n${p.description ?? ''}`}
                    >
                      <div className="font-semibold writing-mode-vertical">{p.code}</div>
                      <div className="text-[9px] text-secondary-400 mt-1">{module}</div>
                    </th>
                  )),
                )}
              </tr>
            </thead>
            <tbody>
              {roles.map((r, rowIdx) => {
                const isDirty = dirtyRoles.has(r.id)
                return (
                  <tr key={r.id} className={rowIdx % 2 === 0 ? 'bg-white' : 'bg-gray-50'}>
                    <td
                      className={`px-3 py-2 sticky left-0 border-r border-secondary-200 ${rowIdx % 2 === 0 ? 'bg-white' : 'bg-gray-50'} ${isDirty ? 'border-l-4 border-l-amber-500' : ''}`}
                    >
                      <div className="flex items-center gap-2">
                        {r.isSystemRole && (
                          <span title="Rendszer role">
                            <Shield size={12} className="text-blue-600" />
                          </span>
                        )}
                        <div>
                          <div className="font-semibold text-sm">{r.name}</div>
                          <div className="text-xs text-secondary-500 font-mono">{r.code}</div>
                        </div>
                        {isDirty && (
                          <span className="badge badge-orange text-[10px] ml-auto">
                            {t('settings.modified')}
                          </span>
                        )}
                      </div>
                    </td>
                    {permissionsByModule.map(([_module, perms]) =>
                      perms.map((p) => {
                        const checked = rolePermMap[r.id]?.has(p.id) ?? false
                        return (
                          <td
                            key={p.id}
                            className="text-center px-2 py-2 border-b border-secondary-100"
                          >
                            <input
                              type="checkbox"
                              checked={checked}
                              onChange={() => toggle(r.id, p.id)}
                              className="w-4 h-4 cursor-pointer"
                              aria-label={`${r.name} - ${p.name}`}
                            />
                          </td>
                        )
                      }),
                    )}
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
      </div>

      {/* Legend */}
      <div className="text-xs text-secondary-500 flex gap-4 flex-wrap">
        <span>
          <Shield size={10} className="inline text-blue-600" />
          {t('settings.rendszerRoleNemTorolheto')}
        </span>
        <span className="text-amber-600">{t('settings.narancsKeretModositasFuggoben')}</span>
        <span>{t('settings.mentesUtanASzerverOsszesValidaljaAPermissionOsszefuggeseket')}</span>
      </div>
    </div>
  )
}
