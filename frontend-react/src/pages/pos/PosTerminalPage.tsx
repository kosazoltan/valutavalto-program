import { useState, useEffect } from 'react'
import { CreditCard } from 'lucide-react'
import { posTerminalApi, PosTerminal } from '../../services/api'

export default function PosTerminalPage() {
  const [terminals, setTerminals] = useState<PosTerminal[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    void loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      setTerminals(await posTerminalApi.list())
    } catch {
      // Hiba
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2"><CreditCard />POS terminálok</h1>
      {loading ? <div>Betöltés...</div> : (
        <div className="form-panel">
          <table className="data-grid w-full">
            <thead><tr><th>Terminál ID</th><th>Név</th><th>Fők</th><th>Utolsó tranzakció</th><th>Státusz</th></tr></thead>
            <tbody>
              {terminals.map(t => (
                <tr key={t.id}>
                  <td className="font-mono">{t.terminalId}</td>
                  <td>{t.terminalName}</td>
                  <td>{t.branchName || '-'}</td>
                  <td>{t.lastTransactionAt ? new Date(t.lastTransactionAt).toLocaleString('hu-HU') : '-'}</td>
                  <td><span className={`badge ${t.isActive ? 'badge-green' : 'badge-gray'}`}>{t.isActive ? 'Aktív' : 'Inaktív'}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

