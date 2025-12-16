import { useState, useEffect, useCallback } from 'react'
import { Coins, Save, RefreshCw, Calculator, AlertCircle } from 'lucide-react'
import {
  denominationBalanceApi,
  DenominationBalanceDTO,
  denominationApi,
  currencyApi,
  Denomination,
  Currency
} from '../../services/api'
import { NumberInput } from '../../components/NumberInput'
import { formatInteger, formatDecimal } from '../../utils/numberFormat'

interface DenominationQuantityUpdateRequest {
  denominationId: string
  quantity: number
}

export default function DenominationPage() {
  const [selectedCashDeskId] = useState<string>('') // TODO: Get from context/params
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [selectedCurrencyId, setSelectedCurrencyId] = useState<number | null>(null)
  const [denominations, setDenominations] = useState<Denomination[]>([])
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [_denominationBalances, setDenominationBalances] = useState<DenominationBalanceDTO[]>([])
  const [editingQuantities, setEditingQuantities] = useState<Record<number, number>>({})
  const [loading, setLoading] = useState(false)
  const [calculatedTotal, setCalculatedTotal] = useState<number>(0)

  const loadDenominations = useCallback(async () => {
    if (!selectedCurrencyId) return
    try {
      const data = await denominationApi.getByCurrencyId(selectedCurrencyId)
      setDenominations(data)

      // Initialize editing quantities
      const initialQuantities: Record<number, number> = {}
      data.forEach((d: Denomination) => {
        initialQuantities[d.id] = 0
      })
      setEditingQuantities(initialQuantities)
    } catch (error) {
      console.error('Címletek betöltése sikertelen:', error)
    }
  }, [selectedCurrencyId])

  const loadDenominationBalances = useCallback(async () => {
    if (!selectedCashDeskId || !selectedCurrencyId) return
    setLoading(true)
    try {
      const data = await denominationBalanceApi.getCashDeskDenominationsByCurrency(selectedCashDeskId, String(selectedCurrencyId))
      setDenominationBalances(data)

      // Load existing quantities into editing state
      const quantities: Record<number, number> = {}
      data.forEach(balance => {
        quantities[Number(balance.denominationId)] = balance.quantity
      })

      // Also set quantities for denominations that don't have balances yet
      denominations.forEach(denom => {
        if (quantities[denom.id] === undefined) {
          quantities[denom.id] = 0
        }
      })
      setEditingQuantities(quantities)

      // Calculate total
      const total = data.reduce((sum, b) => sum + b.totalValue, 0)
      setCalculatedTotal(total)
    } catch (error) {
      console.error('Címlet egyenlegek betöltése sikertelen:', error)
    } finally {
      setLoading(false)
    }
  }, [selectedCashDeskId, selectedCurrencyId, denominations])

  useEffect(() => {
    void loadCurrencies()
  }, [])

  useEffect(() => {
    if (selectedCurrencyId && selectedCashDeskId) {
      void loadDenominations()
      void loadDenominationBalances()
    }
  }, [selectedCurrencyId, selectedCashDeskId, loadDenominations, loadDenominationBalances])

  const loadCurrencies = async () => {
    try {
      const data = await currencyApi.getActive()
      setCurrencies(data)
      if (data.length > 0) {
        setSelectedCurrencyId(data[0]?.id ?? null)
      }
    } catch (error) {
      console.error('Valuták betöltése sikertelen:', error)
    }
  }

  const handleQuantityChange = (denominationId: number, quantityStr: string) => {
    const quantity = Math.max(0, parseFloat(quantityStr.replace(/\s/g, '').replace(',', '.')) || 0)
    setEditingQuantities({
      ...editingQuantities,
      [denominationId]: quantity
    })

    // Recalculate total
    const denom = denominations.find(d => d.id === denominationId)
    if (denom) {
      const newTotal = Object.entries(editingQuantities)
        .filter(([id]) => denominations.find(d => d.id === Number(id))?.currencyId === selectedCurrencyId)
        .reduce((sum, [id, qty]) => {
          const d = denominations.find(d => d.id === Number(id))
          const qtyValue = typeof qty === 'string' ? parseFloat(String(qty).replace(/\s/g, '').replace(',', '.')) || 0 : qty
          return sum + (d ? d.faceValue * (Number(id) === denominationId ? quantity : qtyValue) : 0)
        }, 0)
      setCalculatedTotal(newTotal)
    }
  }

  const handleSave = async () => {
    if (!selectedCashDeskId) {
      alert('Válassz pénztárat!')
      return
    }

    try {
      const updates: DenominationQuantityUpdateRequest[] = Object.entries(editingQuantities)
        .filter(([, qty]) => qty > 0)
        .map(([denominationId, quantity]) => ({
          denominationId,
          quantity
        }))

      await denominationBalanceApi.setDenominationQuantities(selectedCashDeskId, updates)
      alert('Címletezés sikeresen mentve!')
      void loadDenominationBalances()
    } catch (error) {
      console.error('Mentés sikertelen:', error)
      alert('Hiba történt a mentés során')
    }
  }

  const selectedCurrency = currencies.find(c => c.id === selectedCurrencyId)

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Coins />
          Pénztár címletezés
        </h1>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={loadDenominationBalances}
            className="form-button flex items-center gap-1"
            disabled={loading}
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            Frissítés
          </button>
          <button
            type="button"
            onClick={handleSave}
            className="form-button-primary flex items-center gap-1"
            disabled={!selectedCashDeskId}
          >
            <Save size={16} />
            Mentés
          </button>
        </div>
      </div>

      {/* Currency Selector */}
      <div className="form-panel">
        <label htmlFor="currency-select" className="form-label">Valuta kiválasztása</label>
        <select
          id="currency-select"
          title="Válassz valutát"
          value={selectedCurrencyId ?? ''}
          onChange={(e) => setSelectedCurrencyId(e.target.value ? Number(e.target.value) : null)}
          className="form-input"
        >
          <option value="">-- Válassz valutát --</option>
          {currencies.map((curr) => (
            <option key={curr.id} value={curr.id}>
              {curr.code} - {curr.name}
            </option>
          ))}
        </select>
      </div>

      {/* Info Banner */}
      {selectedCurrency && (
        <div className="form-panel bg-blue-50 border-blue-200 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Calculator className="text-blue-600" size={18} />
            <span className="text-sm font-semibold text-blue-800">
              {selectedCurrency.code} - {selectedCurrency.name}
            </span>
          </div>
          <div className="flex items-center gap-4">
            <div className="text-sm">
              <span className="text-gray-600">Összesített egyenleg:</span>
              <span className="ml-2 font-bold text-lg font-mono text-green-600">
                {formatDecimal(calculatedTotal, 2, 2)} {selectedCurrency.code}
              </span>
            </div>
          </div>
        </div>
      )}

      {/* Denominations Table */}
      {selectedCurrencyId && (
        <div className="form-panel p-0">
          <div className="p-3 border-b bg-gray-50">
            <h3 className="font-semibold">Címletek és mennyiségek</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th className="w-32">Címlet</th>
                  <th className="w-24">Típus</th>
                  <th className="w-32">Mennyiség</th>
                  <th className="text-right w-40">Összeg</th>
                </tr>
              </thead>
              <tbody>
                {denominations
                  .filter(d => d.currencyId === selectedCurrencyId && d.active)
                  .sort((a, b) => b.faceValue - a.faceValue)
                  .map((denomination) => {
                    const quantity = editingQuantities[denomination.id] || 0
                    const total = denomination.faceValue * quantity

                    return (
                      <tr key={denomination.id}>
                        <td>
                          <span className="font-mono font-bold text-lg">
                            {formatInteger(denomination.faceValue)} {selectedCurrency?.code}
                          </span>
                        </td>
                        <td>
                          <span className="text-xs bg-gray-100 px-2 py-1 rounded">
                            {denomination.denominationType === 'BANKNOTE' ? 'Bankjegy' : 'Érme'}
                          </span>
                        </td>
                        <td>
                          <NumberInput
                            value={quantity > 0 ? quantity.toString().replace('.', ',') : ''}
                            onChange={(val) => handleQuantityChange(denomination.id, val)}
                            className="form-input w-24 text-center"
                            placeholder="0,00"
                            allowDecimals={true}
                            allowNegative={false}
                            min={0}
                            step="0.01"
                          />
                        </td>
                        <td className="text-right">
                          <span className="font-mono font-semibold text-green-600">
                            {formatDecimal(total, 2, 2)}
                          </span>
                        </td>
                      </tr>
                    )
                  })}
              </tbody>
              <tfoot className="bg-gray-50 font-bold">
                <tr>
                  <td colSpan={3} className="text-right pr-4">ÖSSZESEN:</td>
                  <td className="text-right">
                    <span className="font-mono text-lg text-blue-600">
                      {formatDecimal(calculatedTotal, 2, 2)} {selectedCurrency?.code}
                    </span>
                  </td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
      )}

      {/* Warning */}
      {!selectedCashDeskId && (
        <div className="form-panel bg-yellow-50 border-yellow-200 flex items-center gap-2">
          <AlertCircle className="text-yellow-600" size={18} />
          <span className="text-sm text-yellow-800">
            Pénztár kiválasztása szükséges a címletezéshez!
          </span>
        </div>
      )}
    </div>
  )
}
