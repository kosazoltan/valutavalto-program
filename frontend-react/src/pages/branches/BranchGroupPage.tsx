import { useState, useEffect } from 'react'
import { Building2 } from 'lucide-react'
import { branchGroupApi, BranchGroup } from '../../services/api'

export default function BranchGroupPage() {
  const [groups, setGroups] = useState<BranchGroup[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    void loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      setGroups(await branchGroupApi.list())
    } catch (error) {
      console.error('Hiba:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2"><Building2 />Fiókcsoportok</h1>
      {loading ? <div>Betöltés...</div> : (
        <div className="form-panel">
          <table className="data-grid w-full">
            <thead><tr><th>Kód</th><th>Név</th><th>Szülő csoport</th><th>Főkok száma</th><th>Státusz</th></tr></thead>
            <tbody>
              {groups.map(g => (
                <tr key={g.id}>
                  <td className="font-mono text-sm">{g.code}</td>
                  <td>{g.name}</td>
                  <td>{g.parentGroupName || '-'}</td>
                  <td>{g.branchIds?.length || 0}</td>
                  <td><span className={`badge ${g.isActive ? 'badge-green' : 'badge-red'}`}>{g.isActive ? 'Aktív' : 'Inaktív'}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

