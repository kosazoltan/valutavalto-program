import { useState, useEffect } from 'react'
import { Settings } from 'lucide-react'
import { organizationalSystemParameterApi, OrganizationalSystemParameter } from '../../services/api'

export default function OrganizationalSystemParameterPage() {
  const [params, setParams] = useState<OrganizationalSystemParameter[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    void loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      setParams(await organizationalSystemParameterApi.list())
    } catch (error) {
      console.error('Hiba:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2"><Settings />Szervezeti rendszerparaméterek</h1>
      {loading ? <div>Betöltés...</div> : (
        <div className="form-panel">
          <table className="data-grid w-full">
            <thead><tr><th>Szervezet</th><th>Kulcs</th><th>Érték</th><th>Valuta</th><th>Érvényesség</th></tr></thead>
            <tbody>
              {params.map(p => (
                <tr key={p.id}>
                  <td>{p.organizationName || '-'}</td>
                  <td className="font-mono text-sm">{p.parameterKey}</td>
                  <td>{p.parameterValue}</td>
                  <td>{p.currencyCode || '-'}</td>
                  <td>{p.validFrom} - {p.validTo || 'jelenleg'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

