import { useState, useEffect, useCallback } from 'react'
import { Banknote, Plus, AlertCircle, Loader2 } from 'lucide-react'
import { transactionBanknoteApi, TransactionBanknote, TransactionBanknoteCreateRequest } from '../../services/api/transactions'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../ui/toaster'

interface Props {
  transactionId: number
  currencyCode: string
  direction: 'IN' | 'OUT'
  readOnly?: boolean
}

const COMMON_DENOMINATIONS: Record<string, number[]> = {
  HUF: [500, 1000, 2000, 5000, 10000, 20000],
  EUR: [5, 10, 20, 50, 100, 200, 500],
  USD: [1, 5, 10, 20, 50, 100],
  GBP: [5, 10, 20, 50],
  CHF: [10, 20, 50, 100, 200, 1000],
}

export default function BanknoteBreakdown({ transactionId, currencyCode, direction, readOnly }: Props) {
  const [banknotes, setBanknotes] = useState<TransactionBanknote[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [newRow, setNewRow] = useState<TransactionBanknoteCreateRequest>({
    currencyCode,
    faceValue: 0,
    quantity: 1,
    direction,
  })

  const loadBanknotes = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const all = await transactionBanknoteApi.getByTransaction(transactionId)
      setBanknotes(all.filter(b => b.direction === direction))
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [transactionId, direction])

  useEffect(() => { void loadBanknotes() }, [loadBanknotes])

  const handleAdd = async () => {
    if (newRow.faceValue <= 0 || newRow.quantity <= 0) {
      toast.warning('Érvénytelen adat', 'Névérték és darabszám pozitív kell legyen')
      return
    }
    try {
      await transactionBanknoteApi.create(transactionId, { ...newRow, currencyCode })
      setNewRow({ currencyCode, faceValue: 0, quantity: 1, direction })
      void loadBanknotes()
      toast.success('Címlet hozzáadva')
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const denominations = COMMON_DENOMINATIONS[currencyCode] || []
  const total = banknotes.reduce((sum, b) => sum + b.totalValue, 0)
  const totalPieces = banknotes.reduce((sum, b) => sum + b.quantity, 0)

  return (
    <div className="border rounded p-3 bg-gray-50">
      <h3 className="text-sm font-semibold text-gray-700 flex items-center gap-2 mb-2">
        <Banknote size={14} />
        Címletezés ({direction === 'IN' ? 'Beérkező' : 'Kiadandó'})
      </h3>

      {error && (
        <div className="flex items-center gap-1 text-red-600 text-xs mb-2">
          <AlertCircle size={12} /> {error}
        </div>
      )}

      {loading ? (
        <div className="flex items-center justify-center py-3 text-gray-400 gap-1 text-sm">
          <Loader2 size={14} className="animate-spin" /> Betöltés...
        </div>
      ) : (
        <>
          {banknotes.length > 0 && (
            <table className="w-full text-sm mb-2">
              <thead>
                <tr className="text-left text-gray-500 text-xs">
                  <th className="pb-1">Névérték</th>
                  <th className="pb-1">Darab</th>
                  <th className="pb-1 text-right">Összeg</th>
                </tr>
              </thead>
              <tbody>
                {banknotes.map(b => (
                  <tr key={b.id} className="border-t border-gray-200">
                    <td className="py-1 font-mono">{b.faceValue.toLocaleString('hu-HU')} {currencyCode}</td>
                    <td className="py-1">{b.quantity} db</td>
                    <td className="py-1 text-right font-mono">{b.totalValue.toLocaleString('hu-HU')} {currencyCode}</td>
                  </tr>
                ))}
                <tr className="border-t-2 border-gray-400 font-semibold">
                  <td className="pt-1">Összesen</td>
                  <td className="pt-1">{totalPieces} db</td>
                  <td className="pt-1 text-right font-mono">{total.toLocaleString('hu-HU')} {currencyCode}</td>
                </tr>
              </tbody>
            </table>
          )}

          {!readOnly && (
            <div className="flex gap-2 items-end">
              <div>
                <label className="text-xs text-gray-500">Névérték</label>
                {denominations.length > 0 ? (
                  <select
                    value={newRow.faceValue}
                    onChange={e => setNewRow({ ...newRow, faceValue: Number(e.target.value) })}
                    className="form-input w-28 text-sm"
                  >
                    <option value={0}>Válassz...</option>
                    {denominations.map(d => (
                      <option key={d} value={d}>{d.toLocaleString('hu-HU')}</option>
                    ))}
                  </select>
                ) : (
                  <input
                    type="number"
                    value={newRow.faceValue || ''}
                    onChange={e => setNewRow({ ...newRow, faceValue: Number(e.target.value) })}
                    className="form-input w-28 text-sm"
                    placeholder="Névérték"
                  />
                )}
              </div>
              <div>
                <label className="text-xs text-gray-500">Darab</label>
                <input
                  type="number"
                  min={1}
                  value={newRow.quantity}
                  onChange={e => setNewRow({ ...newRow, quantity: Number(e.target.value) })}
                  className="form-input w-20 text-sm"
                />
              </div>
              <button onClick={handleAdd} className="form-button flex items-center gap-1 text-sm">
                <Plus size={12} /> Hozzáad
              </button>
            </div>
          )}
        </>
      )}
    </div>
  )
}
