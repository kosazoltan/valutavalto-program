import { useState, useEffect } from 'react'
import { Users, Plus, Save } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'

interface Workgroup {
  id?: string
  name: string
  code: string
  legacyGroupNumber?: number
  active: boolean
}

export default function WorkgroupManager() {
  const [workgroups, setWorkgroups] = useState<Workgroup[]>([])
  const [editing, setEditing] = useState<Workgroup | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchWorkgroups()
  }, [])

  const fetchWorkgroups = async () => {
    try {
      const res = await api.get<Workgroup[]>('/rate-management/workgroups')
      const workgroupsData = safeArray<Workgroup>(res?.data)
      setWorkgroups(workgroupsData)
    } catch (err) {
      logger.error('WorkgroupManager', 'Lekérés sikertelen:', err)
    } finally {
      setLoading(false)
    }
  }

  const saveWorkgroup = async () => {
    if (!editing) return
    try {
      if (editing.id) {
        await api.put(`/rate-management/workgroups/${editing.id}`, editing)
      } else {
        await api.post('/rate-management/workgroups', editing)
      }
      setEditing(null)
      fetchWorkgroups()
    } catch (err) {
      logger.error('WorkgroupManager', 'Mentés sikertelen:', err)
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold flex items-center gap-2">
          <Users className="h-5 w-5" />
          Munkacsoportok
        </h2>
        <button
          className="inline-flex items-center justify-center rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
          onClick={() => setEditing({ name: '', code: '', active: true })}
        >
          <Plus className="h-4 w-4 mr-1" />
          Uj munkacsoport
        </button>
      </div>

      {editing && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4">
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="text-sm font-medium">Nev</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.name}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, name: e.target.value })}
                  placeholder="pl. Budapest kozpont"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Kod</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.code}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, code: e.target.value })}
                  placeholder="pl. WG01"
                  disabled={!!editing.id}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Legacy csoport szam</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  type="number"
                  value={editing.legacyGroupNumber || ''}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, legacyGroupNumber: parseInt(e.target.value, 10) || undefined })}
                />
              </div>
            </div>
            <div className="flex gap-2 mt-4">
              <button
                className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                onClick={saveWorkgroup}
              >
                <Save className="h-4 w-4 mr-2" />
                Mentés
              </button>
              <button
                className="inline-flex items-center justify-center rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
                onClick={() => setEditing(null)}
              >
                Mégse
              </button>
            </div>
          </div>
        </div>
      )}

      {loading ? (
        <p>Betöltés...</p>
      ) : (
        <div className="space-y-2">
          {workgroups.map((wg) => (
            <div key={wg.id} className="rounded-lg border bg-card shadow-sm">
              <div className="p-3 flex items-center justify-between">
                <div>
                  <span className="font-medium">{wg.name}</span>
                  <span className="text-muted-foreground ml-2">({wg.code})</span>
                  {wg.legacyGroupNumber && (
                    <span className="text-xs text-muted-foreground ml-2">Legacy: #{wg.legacyGroupNumber}</span>
                  )}
                </div>
                <div className="flex items-center gap-2">
                  <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                    wg.active ? 'bg-primary text-primary-foreground' : 'bg-secondary text-secondary-foreground'
                  }`}>
                    {wg.active ? 'Aktív' : 'Inaktív'}
                  </span>
                  <button
                    className="inline-flex items-center justify-center rounded-md border px-3 py-1.5 text-xs font-medium hover:bg-muted disabled:opacity-50"
                    onClick={() => setEditing(wg)}
                  >
                    Szerkesztés
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
