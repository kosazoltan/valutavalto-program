import { useState } from 'react'
import { RefreshCw } from 'lucide-react'
import { synchronizationApi } from '../../services/api'
import { getErrorMessage } from '../../utils/errorHandling'

interface SyncResult {
  recordsSynced: number
  success: boolean
  message?: string
}

export default function SynchronizationPage() {
  const [branchId, setBranchId] = useState('')
  const [workerId, setWorkerId] = useState('')
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<SyncResult | null>(null)

  const handleSync = async (): Promise<void> => {
    if (!branchId || !workerId) {
      alert('Kérjük, adja meg a fiók és dolgozó ID-t')
      return
    }
    try {
      setLoading(true)
      const res = await synchronizationApi.synchronize(branchId, workerId)
      setResult(res as SyncResult)
      alert(`Szinkronizáció kész: ${res.recordsSynced} rekord`)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      alert(`Hiba történt: ${errorMessage}`)
      console.error('Failed to synchronize:', err)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2"><RefreshCw />Szinkronizáció</h1>
      <div className="form-panel space-y-4">
        <div>
          <label className="form-label">Fiók ID</label>
          <input className="form-input" value={branchId} onChange={e => setBranchId(e.target.value)} />
        </div>
        <div>
          <label className="form-label">Dolgozó ID</label>
          <input className="form-input" value={workerId} onChange={e => setWorkerId(e.target.value)} />
        </div>
        <button onClick={handleSync} disabled={loading} className="form-button-primary">
          {loading ? 'Szinkronizálás...' : 'Szinkronizálás indítása'}
        </button>
        {result && (
          <div className="bg-green-50 p-4 rounded">
            <p>Sikeres: {result.success ? 'Igen' : 'Nem'}</p>
            <p>Rekordok: {result.recordsSynced}</p>
          </div>
        )}
      </div>
    </div>
  )
}

