import { useState, useEffect } from 'react'
import { FileText, Plus, Printer, CheckCircle, Search } from 'lucide-react'
import { handoverSheetApi, HandoverSheet, cashDeskApi, CashDesk } from '../../services/api'

export default function HandoverSheetPage() {
  const [sheets, setSheets] = useState<HandoverSheet[]>([])
  const [cashDesks, setCashDesks] = useState<CashDesk[]>([])
  const [filteredSheets, setFilteredSheets] = useState<HandoverSheet[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [formData, setFormData] = useState({
    fromCashDeskId: '',
    toCashDeskId: '',
    transferDate: new Date().toISOString().split('T')[0],
    amounts: {}
  })

  useEffect(() => {
    void loadData()
    void loadCashDesks()
  }, [])

  useEffect(() => {
    filterSheets()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sheets, searchTerm])

  const loadData = async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await handoverSheetApi.list()
      setSheets(data)
    } catch (err) {
      console.error('Átadó lapok betöltési hiba:', err)
      setError('Hiba az átadó lapok betöltésekor')
    } finally {
      setLoading(false)
    }
  }

  const loadCashDesks = async () => {
    try {
      const data = await cashDeskApi.list()
      setCashDesks(data)
    } catch (err) {
      console.error('Pénztárak betöltési hiba:', err)
      setError('Hiba a pénztárak betöltésekor')
    }
  }

  const filterSheets = () => {
    let filtered = sheets
    if (searchTerm) {
      filtered = filtered.filter(s =>
        s.sheetNumber?.toLowerCase().includes(searchTerm.toLowerCase())
      )
    }
    setFilteredSheets(filtered)
  }

  const handleGenerate = async () => {
    try {
      setError(null)
      await handoverSheetApi.generate(
        formData.fromCashDeskId || '',
        formData.toCashDeskId || '',
        (formData.transferDate || new Date().toISOString().split('T')[0]) as string,
        formData.amounts
      )
      await loadData()
      setShowForm(false)
      alert('Átadó lap sikeresen létrehozva')
    } catch (err) {
      console.error('Generálási hiba:', err)
      setError('Hiba történt a generálás során')
    }
  }

  const handlePrint = async (id: string) => {
    try {
      setError(null)
      await handoverSheetApi.print(id)
      alert('Átadó lap nyomtatása elindítva')
    } catch (err) {
      console.error('Nyomtatási hiba:', err)
      setError('Hiba történt a nyomtatás során')
    }
  }

  const handleComplete = async (id: string) => {
    try {
      setError(null)
      await handoverSheetApi.complete(id)
      await loadData()
      alert('Átadó lap sikeresen befejezve')
    } catch (err) {
      console.error('Befejezési hiba:', err)
      setError('Hiba történt a befejezés során')
    }
  }

  if (loading) {
    return <div className="flex items-center justify-center h-64">Betöltés...</div>
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileText />
          Átadó Lapok
        </h1>
        <button type="button" onClick={() => setShowForm(true)} className="form-button-primary flex items-center gap-2">
          <Plus size={16} />
          Új átadó lap
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="form-panel">
        <div>
          <label className="form-label">Keresés</label>
          <div className="relative">
            <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
            <input type="text" className="form-input pl-8" placeholder="Lapszám..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
          </div>
        </div>
      </div>

      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">Új átadó lap</h2>
              <button type="button" onClick={() => setShowForm(false)} className="text-gray-500">X</button>
            </div>
            <div className="space-y-4">
              <div>
                <label htmlFor="fromCashDesk" className="form-label">Küldő pénztár</label>
                <select id="fromCashDesk" title="Küldő pénztár kiválasztása" className="form-input" value={formData.fromCashDeskId} onChange={(e) => setFormData({ ...formData, fromCashDeskId: e.target.value })}>
                  <option value="">Válasszon...</option>
                  {cashDesks.map(cd => <option key={cd.id} value={cd.id}>{cd.name}</option>)}
                </select>
              </div>
              <div>
                <label htmlFor="toCashDesk" className="form-label">Fogadó pénztár</label>
                <select id="toCashDesk" title="Fogadó pénztár kiválasztása" className="form-input" value={formData.toCashDeskId} onChange={(e) => setFormData({ ...formData, toCashDeskId: e.target.value })}>
                  <option value="">Válasszon...</option>
                  {cashDesks.map(cd => <option key={cd.id} value={cd.id}>{cd.name}</option>)}
                </select>
              </div>
              <div>
                <label htmlFor="transferDate" className="form-label">Átadás dátuma</label>
                <input id="transferDate" type="date" className="form-input" placeholder="éééé-hh-nn" value={formData.transferDate} onChange={(e) => setFormData({ ...formData, transferDate: e.target.value })} />
              </div>
              <div className="flex justify-end gap-2 pt-4 border-t">
                <button type="button" onClick={() => setShowForm(false)} className="form-button">Mégse</button>
                <button type="button" onClick={handleGenerate} className="form-button-primary">Generálás</button>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr><th>Lapszám</th><th>Küldő</th><th>Fogadó</th><th>Dátum</th><th>Státusz</th><th>Műveletek</th></tr>
          </thead>
          <tbody>
            {filteredSheets.length === 0 ? (
              <tr><td colSpan={6} className="text-center text-gray-500 py-4">Nincs találat</td></tr>
            ) : (
              filteredSheets.map((s) => (
                <tr key={s.id}>
                  <td className="font-mono">{s.sheetNumber}</td>
                  <td>{s.fromCashDeskName}</td>
                  <td>{s.toCashDeskName}</td>
                  <td>{new Date(s.transferDate).toLocaleDateString('hu-HU')}</td>
                  <td><span className={`badge ${s.status === 'COMPLETED' ? 'badge-green' : 'badge-yellow'}`}>{s.status}</span></td>
                  <td>
                    <div className="flex gap-2">
                      <button type="button" onClick={() => handlePrint(s.id)} className="form-button text-xs"><Printer size={12} />Nyomtatás</button>
                      {s.status !== 'COMPLETED' && <button type="button" onClick={() => handleComplete(s.id)} className="form-button text-xs"><CheckCircle size={12} />Befejezés</button>}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
