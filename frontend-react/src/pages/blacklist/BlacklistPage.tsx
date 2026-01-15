import { useState, useEffect, useCallback } from 'react'
import { Ban, Upload } from 'lucide-react'
import { blacklistApi, ProhibitedPerson, ProhibitedCompany } from '../../services/api'

export default function BlacklistPage() {
  const [activeTab, setActiveTab] = useState<'persons' | 'companies'>('persons')
  const [persons, setPersons] = useState<ProhibitedPerson[]>([])
  const [companies, setCompanies] = useState<ProhibitedCompany[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      if (activeTab === 'persons') {
        setPersons(await blacklistApi.getPersons())
      } else {
        setCompanies(await blacklistApi.getCompanies())
      }
    } catch (err) {
      console.error('Tiltólista betöltési hiba:', err)
      setError('Hiba a tiltólista betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [activeTab])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const handleImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    try {
      setError(null)
      if (activeTab === 'persons') {
        await blacklistApi.importPersons(file)
      } else {
        await blacklistApi.importCompanies(file)
      }
      await loadData()
      alert('Importálás sikeres')
    } catch (err) {
      console.error('Importálási hiba:', err)
      setError('Hiba az importálásnál. Kérjük ellenőrizze a fájl formátumát.')
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2"><Ban />Tiltólista</h1>
        <label className="form-button-primary cursor-pointer">
          <Upload size={16} /> Importálás
          <input type="file" className="hidden" onChange={handleImport} />
        </label>
      </div>
      <div className="flex gap-2 border-b">
        <button onClick={() => setActiveTab('persons')} className={`px-4 py-2 ${activeTab === 'persons' ? 'border-b-2 border-blue-500' : ''}`}>Személyek</button>
        <button onClick={() => setActiveTab('companies')} className={`px-4 py-2 ${activeTab === 'companies' ? 'border-b-2 border-blue-500' : ''}`}>Cégek</button>
      </div>
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}
      {loading ? <div>Betöltés...</div> : (
        <div className="form-panel">
          {activeTab === 'persons' ? (
            <table className="data-grid w-full">
              <thead><tr><th>Név</th><th>Dokumentum</th><th>Lista típus</th><th>Státusz</th></tr></thead>
              <tbody>
                {persons.map(p => (
                  <tr key={p.id}><td>{p.fullName}</td><td>{p.documentNumber || '-'}</td><td>{p.listType}</td><td><span className={`badge ${p.isActive ? 'badge-red' : 'badge-gray'}`}>{p.isActive ? 'Aktív' : 'Inaktív'}</span></td></tr>
                ))}
              </tbody>
            </table>
          ) : (
            <table className="data-grid w-full">
              <thead><tr><th>Cégnév</th><th>Adószám</th><th>Lista típus</th><th>Státusz</th></tr></thead>
              <tbody>
                {companies.map(c => (
                  <tr key={c.id}><td>{c.companyName}</td><td>{c.taxNumber || '-'}</td><td>{c.listType}</td><td><span className={`badge ${c.isActive ? 'badge-red' : 'badge-gray'}`}>{c.isActive ? 'Aktív' : 'Inaktív'}</span></td></tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  )
}

