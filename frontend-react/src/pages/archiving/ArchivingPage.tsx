import { useState, useEffect } from 'react'
import { Archive, Play } from 'lucide-react'
import { archivingApi, ArchiveTask } from '../../services/api'
import { getErrorMessage } from '../../utils/errorHandling'

export default function ArchivingPage() {
  const [tasks, setTasks] = useState<ArchiveTask[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let mounted = true

    const load = async (): Promise<void> => {
      await loadData()
    }

    load().catch(err => {
      if (mounted) {
        console.error('Failed to load archiving tasks:', err)
      }
    })

    return () => {
      mounted = false
    }
  }, [])

  const loadData = async (): Promise<void> => {
    try {
      setLoading(true)
      setTasks(await archivingApi.listTasks())
    } catch (err) {
      console.error('Failed to load tasks:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleExecute = async (id: string): Promise<void> => {
    try {
      await archivingApi.executeTask(id)
      await loadData()
      alert('Archiválás elindítva')
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      alert(`Hiba történt: ${errorMessage}`)
      console.error('Failed to execute task:', err)
    }
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2"><Archive />Archiválás</h1>
      {loading ? <div>Betöltés...</div> : (
        <div className="form-panel">
          <table className="data-grid w-full">
            <thead><tr><th>Típus</th><th>Entitás típus</th><th>Státusz</th><th>Kezdés</th><th>Befejezés</th><th>Műveletek</th></tr></thead>
            <tbody>
              {tasks.map(t => (
                <tr key={t.id}>
                  <td>{t.taskType}</td>
                  <td>{t.entityType}</td>
                  <td><span className={`badge ${t.status === 'COMPLETED' ? 'badge-green' : 'badge-yellow'}`}>{t.status}</span></td>
                  <td>{t.startedAt ? new Date(t.startedAt).toLocaleString('hu-HU') : '-'}</td>
                  <td>{t.completedAt ? new Date(t.completedAt).toLocaleString('hu-HU') : '-'}</td>
                  <td>{t.status !== 'COMPLETED' && <button onClick={() => handleExecute(t.id)} className="form-button text-xs"><Play size={12} />Futtatás</button>}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

