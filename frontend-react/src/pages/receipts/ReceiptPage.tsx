import { useState, useEffect } from 'react'
import { Receipt as ReceiptIcon, Search, Printer, Eye } from 'lucide-react'
import { receiptApi, Receipt } from '../../services/api'
import { getErrorMessage } from '../../utils/errorHandling'

export default function ReceiptPage() {
  const [receipts, setReceipts] = useState<Receipt[]>([])
  const [filteredReceipts, setFilteredReceipts] = useState<Receipt[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedReceipt, setSelectedReceipt] = useState<Receipt | null>(null)

  useEffect(() => {
    let mounted = true

    const load = async (): Promise<void> => {
      await loadData()
    }

    load().catch(err => {
      if (mounted) {
        console.error('Failed to load receipts:', err)
      }
    })

    return () => {
      mounted = false
    }
  }, [])

  useEffect(() => {
    filterReceipts()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [receipts, searchTerm])

  const loadData = async (): Promise<void> => {
    try {
      setLoading(true)
      const data = await receiptApi.list()
      setReceipts(data)
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      console.error('Failed to load receipts:', err)
      alert(`Hiba történt a betöltés során: ${errorMessage}`)
    } finally {
      setLoading(false)
    }
  }

  const filterReceipts = (): void => {
    let filtered = receipts
    if (searchTerm) {
      filtered = filtered.filter(r =>
        r.receiptNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.navReceiptNumber?.toLowerCase().includes(searchTerm.toLowerCase())
      )
    }
    setFilteredReceipts(filtered)
  }

  const handlePrint = async (id: string): Promise<void> => {
    try {
      await receiptApi.print(id)
      await loadData()
      alert('Bizonylat nyomtatása elindítva')
    } catch (err) {
      const errorMessage = getErrorMessage(err)
      alert(`Hiba történt a nyomtatás során: ${errorMessage}`)
      console.error('Failed to print receipt:', err)
    }
  }

  if (loading) {
    return <div className="flex items-center justify-center h-64">Betöltés...</div>
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <ReceiptIcon />
          Bizonylatok
        </h1>
      </div>

      <div className="form-panel">
        <div>
          <label className="form-label">Keresés</label>
          <div className="relative">
            <Search className="absolute left-2 top-1/2 transform -translate-y-1/2 text-gray-400" size={16} />
            <input type="text" className="form-input pl-8" placeholder="Bizonylatszám..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
          </div>
        </div>
      </div>

      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr><th>Bizonylatszám</th><th>NAV bizonylatszám</th><th>Típus</th><th>Kiadás dátuma</th><th>Nyomtatva</th><th>Műveletek</th></tr>
          </thead>
          <tbody>
            {filteredReceipts.length === 0 ? (
              <tr><td colSpan={6} className="text-center text-gray-500 py-4">Nincs találat</td></tr>
            ) : (
              filteredReceipts.map((r) => (
                <tr key={r.id}>
                  <td className="font-mono">{r.receiptNumber}</td>
                  <td className="font-mono">{r.navReceiptNumber || '-'}</td>
                  <td>{r.receiptType}</td>
                  <td>{new Date(r.issueDate).toLocaleDateString('hu-HU')}</td>
                  <td><span className={`badge ${r.isPrinted ? 'badge-green' : 'badge-yellow'}`}>{r.isPrinted ? 'Igen' : 'Nem'}</span></td>
                  <td>
                    <div className="flex gap-2">
                      <button onClick={() => setSelectedReceipt(r)} className="form-button text-xs"><Eye size={12} />Részletek</button>
                      {!r.isPrinted && <button onClick={() => handlePrint(r.id)} className="form-button text-xs"><Printer size={12} />Nyomtatás</button>}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {selectedReceipt && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">Bizonylat részletek</h2>
              <button onClick={() => setSelectedReceipt(null)} className="text-gray-500">X</button>
            </div>
            <div className="space-y-2">
              <div><strong>Bizonylatszám:</strong> {selectedReceipt.receiptNumber}</div>
              <div><strong>NAV bizonylatszám:</strong> {selectedReceipt.navReceiptNumber || '-'}</div>
              <div><strong>Típus:</strong> {selectedReceipt.receiptType}</div>
              <div><strong>Kiadás dátuma:</strong> {new Date(selectedReceipt.issueDate).toLocaleString('hu-HU')}</div>
              <div><strong>Nyomtatva:</strong> {selectedReceipt.isPrinted ? 'Igen' : 'Nem'}</div>
              {selectedReceipt.content && (
                <div className="mt-4 p-4 bg-gray-50 rounded">
                  <strong>Tartalom:</strong>
                  <pre className="mt-2 text-sm">{selectedReceipt.content}</pre>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

