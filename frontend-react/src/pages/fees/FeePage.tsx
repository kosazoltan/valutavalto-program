import { useState, useEffect } from 'react'
import { DollarSign, Plus } from 'lucide-react'
import { feeApi, FeeType, FeeRate, FeeDiscount } from '../../services/api'

export default function FeePage() {
  const [activeTab, setActiveTab] = useState<'types' | 'rates' | 'discounts'>('types')
  const [types, setTypes] = useState<FeeType[]>([])
  const [rates, setRates] = useState<FeeRate[]>([])
  const [discounts, setDiscounts] = useState<FeeDiscount[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [formData, setFormData] = useState<Partial<FeeType & FeeRate & FeeDiscount>>({})

  useEffect(() => {
    void loadData()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab])

  const loadData = async () => {
    try {
      setLoading(true)
      setError(null)
      if (activeTab === 'types') {
        setTypes(await feeApi.getTypes())
      } else if (activeTab === 'rates') {
        setRates(await feeApi.getRates())
      } else {
        setDiscounts(await feeApi.getDiscounts())
      }
    } catch (err) {
      console.error('Díjadatok betöltési hiba:', err)
      setError('Hiba a díjadatok betöltésekor')
    } finally {
      setLoading(false)
    }
  }

  const handleSave = async () => {
    try {
      setError(null)
      if (activeTab === 'types') {
        if (formData.id) await feeApi.updateType(formData.id, formData)
        else await feeApi.createType(formData)
      } else if (activeTab === 'rates') {
        if (formData.id) await feeApi.updateRate(formData.id, formData)
        else await feeApi.createRate(formData)
      } else {
        if (formData.id) await feeApi.updateDiscount(formData.id, formData)
        else await feeApi.createDiscount(formData)
      }
      await loadData()
      setShowForm(false)
    } catch (err) {
      console.error('Díj mentési hiba:', err)
      setError('Hiba történt a mentés során')
    }
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2"><DollarSign />Díjkezelés</h1>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="flex gap-2 border-b">
        {(['types', 'rates', 'discounts'] as const).map(tab => (
          <button type="button" key={tab} onClick={() => setActiveTab(tab)} className={`px-4 py-2 ${activeTab === tab ? 'border-b-2 border-blue-500' : ''}`}>
            {tab === 'types' ? 'Díjtípusok' : tab === 'rates' ? 'Díj mértékek' : 'Kedvezmények'}
          </button>
        ))}
      </div>
      <div className="flex justify-end">
        <button type="button" onClick={() => { setFormData({}); setShowForm(true) }} className="form-button-primary"><Plus size={16} />Új</button>
      </div>
      {loading ? <div>Betöltés...</div> : (
        <div className="form-panel">
          {activeTab === 'types' && (
            <table className="data-grid w-full">
              <thead><tr><th>Kód</th><th>Név</th><th>Számítás</th><th>Műveletek</th></tr></thead>
              <tbody>
                {types.map(t => (
                  <tr key={t.id}>
                    <td>{t.code}</td><td>{t.name}</td><td>{t.calculationMethod}</td>
                    <td><button type="button" onClick={() => { setFormData(t); setShowForm(true) }} className="form-button text-xs">Szerkesztés</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          {activeTab === 'rates' && (
            <table className="data-grid w-full">
              <thead><tr><th>Díjtípus</th><th>Valuta</th><th>Mérték</th><th>Műveletek</th></tr></thead>
              <tbody>
                {rates.map(r => (
                  <tr key={r.id}>
                    <td>{r.feeTypeName}</td><td>{r.currencyCode}</td><td>{r.rate}</td>
                    <td><button type="button" onClick={() => { setFormData(r); setShowForm(true) }} className="form-button text-xs">Szerkesztés</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          {activeTab === 'discounts' && (
            <table className="data-grid w-full">
              <thead><tr><th>Kód</th><th>Név</th><th>Típus</th><th>Érték</th><th>Műveletek</th></tr></thead>
              <tbody>
                {discounts.map(d => (
                  <tr key={d.id}>
                    <td>{d.code}</td><td>{d.name}</td><td>{d.discountType}</td><td>{d.discountValue}</td>
                    <td><button type="button" onClick={() => { setFormData(d); setShowForm(true) }} className="form-button text-xs">Szerkesztés</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl">
            <h2 className="text-lg font-bold mb-4">{formData.id ? 'Szerkesztés' : 'Új'}</h2>
            <div className="space-y-4">
              {activeTab === 'types' && (
                <>
                  <div><label className="form-label">Kód</label><input className="form-input" value={formData.code || ''} onChange={e => setFormData({...formData, code: e.target.value})} /></div>
                  <div><label className="form-label">Név</label><input className="form-input" value={formData.name || ''} onChange={e => setFormData({...formData, name: e.target.value})} /></div>
                </>
              )}
              <div className="flex gap-2">
                <button type="button" onClick={() => setShowForm(false)} className="form-button">Mégse</button>
                <button type="button" onClick={handleSave} className="form-button-primary">Mentés</button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

