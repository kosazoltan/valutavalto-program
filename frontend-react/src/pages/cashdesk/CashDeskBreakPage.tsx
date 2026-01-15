import { useState, useEffect, useCallback } from 'react'
import { Clock, Play, Square } from 'lucide-react'
import { cashDeskBreakApi, CashDeskBreak, cashDeskApi, CashDesk } from '../../services/api'

export default function CashDeskBreakPage() {
  const [breaks, setBreaks] = useState<CashDeskBreak[]>([])
  const [cashDesks, setCashDesks] = useState<CashDesk[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedCashDeskId, setSelectedCashDeskId] = useState<string>('')
  const [error, setError] = useState<string | null>(null)

  const loadBreaks = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await cashDeskBreakApi.list(selectedCashDeskId)
      setBreaks(data)
    } catch (err) {
      console.error('Szünetek betöltési hiba:', err)
      setError('Hiba a szünetek betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [selectedCashDeskId])

  useEffect(() => {
    void loadCashDesks()
  }, [])

  useEffect(() => {
    if (selectedCashDeskId) {
      void loadBreaks()
    }
  }, [selectedCashDeskId, loadBreaks])

  const loadCashDesks = async () => {
    try {
      const data = await cashDeskApi.list()
      setCashDesks(data)
      if (data.length > 0) {
        setSelectedCashDeskId(data[0]?.id ?? '')
      }
    } catch (err) {
      console.error('Pénztárak betöltési hiba:', err)
      setError('Hiba a pénztárak betöltésekor')
    }
  }

  const handleStartBreak = async () => {
    if (!selectedCashDeskId) {
      alert('Kérjük, válasszon pénztárat')
      return
    }
    const breakType = prompt('Szünet típusa (pl: LUNCH, BREAK):')
    if (!breakType) return
    const reason = prompt('Ok (opcionális):') || undefined
    try {
      setError(null)
      await cashDeskBreakApi.start(selectedCashDeskId, breakType, reason)
      await loadBreaks()
    } catch (err) {
      console.error('Szünet indítási hiba:', err)
      setError('Hiba történt a szünet indítása során')
    }
  }

  const handleEndBreak = async (breakId: string) => {
    try {
      setError(null)
      await cashDeskBreakApi.end(breakId)
      await loadBreaks()
    } catch (err) {
      console.error('Szünet befejezési hiba:', err)
      setError('Hiba történt a szünet befejezése során')
    }
  }

  const activeBreak = breaks.find(b => !b.breakEnd && b.isActive)

  if (loading) {
    return <div className="flex items-center justify-center h-64">Betöltés...</div>
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Clock />
          Pénztár Szünetek
        </h1>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="form-panel space-y-4">
        <div>
          <label className="form-label">Pénztár</label>
          <select className="form-input" value={selectedCashDeskId} onChange={(e) => setSelectedCashDeskId(e.target.value)}>
            {cashDesks.map(cd => (
              <option key={cd.id} value={cd.id}>{cd.name}</option>
            ))}
          </select>
        </div>

        {activeBreak ? (
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
            <div className="flex justify-between items-center">
              <div>
                <h3 className="font-bold text-yellow-800">Aktív szünet</h3>
                <p className="text-sm text-yellow-600">Kezdés: {new Date(activeBreak.breakStart).toLocaleString('hu-HU')}</p>
                <p className="text-sm text-yellow-600">Típus: {activeBreak.breakType}</p>
                {activeBreak.reason && <p className="text-sm text-yellow-600">Ok: {activeBreak.reason}</p>}
              </div>
              <button
                onClick={() => handleEndBreak(activeBreak.id)}
                className="form-button-primary flex items-center gap-2"
              >
                <Square size={16} />
                Szünet befejezése
              </button>
            </div>
          </div>
        ) : (
          <button
            onClick={handleStartBreak}
            className="form-button-primary flex items-center gap-2"
          >
            <Play size={16} />
            Szünet indítása
          </button>
        )}
      </div>

      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>Kezdés</th>
              <th>Vég</th>
              <th>Típus</th>
              <th>Ok</th>
              <th>Műveletek</th>
            </tr>
          </thead>
          <tbody>
            {breaks.length === 0 ? (
              <tr><td colSpan={5} className="text-center text-gray-500 py-4">Nincs szünet</td></tr>
            ) : (
              breaks.map((b) => (
                <tr key={b.id}>
                  <td>{new Date(b.breakStart).toLocaleString('hu-HU')}</td>
                  <td>{b.breakEnd ? new Date(b.breakEnd).toLocaleString('hu-HU') : '-'}</td>
                  <td>{b.breakType}</td>
                  <td>{b.reason || '-'}</td>
                  <td>
                    {!b.breakEnd && (
                      <button
                        onClick={() => handleEndBreak(b.id)}
                        className="form-button text-xs"
                      >
                        <Square size={12} /> Befejezés
                      </button>
                    )}
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

