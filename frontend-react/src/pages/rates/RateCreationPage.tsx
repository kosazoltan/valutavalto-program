import { useState, useEffect } from 'react'
import { TrendingUp, RefreshCw, Save, Calculator, CheckCircle, AlertCircle } from 'lucide-react'
import {
  rateCreationApi,
  RateCreationDTO,
  currencyGroupApi,
  CurrencyGroupDTO,
  currencyApi,
  Currency
} from '../../services/api'
import { NumberInput } from '../../components/NumberInput'
import { formatDecimal } from '../../utils/numberFormat'

export default function RateCreationPage() {
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [currencyGroups, setCurrencyGroups] = useState<CurrencyGroupDTO[]>([])
  const [selectedCurrencyId, setSelectedCurrencyId] = useState<number | null>(null)
  const [rateData, setRateData] = useState<RateCreationDTO | null>(null)
  const [loading, setLoading] = useState(false)
  const [editingBuyRate, setEditingBuyRate] = useState<number>(0)
  const [editingSellRate, setEditingSellRate] = useState<number>(0)
  const [selectedGroupId, setSelectedGroupId] = useState<string>('')

  useEffect(() => {
    void loadCurrencies()
    void loadCurrencyGroups()
  }, [])

  useEffect(() => {
    if (selectedCurrencyId) {
      void loadRateCreation(String(selectedCurrencyId))
    }
  }, [selectedCurrencyId])

  const loadCurrencies = async () => {
    try {
      const data = await currencyApi.getActive()
      setCurrencies(data)
      if (data.length > 0) {
        setSelectedCurrencyId(data[0]?.id ?? null)
      }
    } catch {
      // Valúták betöltése sikertelen
      // Ha nincs válasz, üres tömböt állítunk be, hogy ne legyen hiba
      setCurrencies([])
    }
  }

  const loadCurrencyGroups = async () => {
    try {
      const data = await currencyGroupApi.list()
      setCurrencyGroups(data)
    } catch {
      // Csoportok betöltése sikertelen
      // Ha nincs válasz, üres tömböt állítunk be
      setCurrencyGroups([])
    }
  }

  const loadRateCreation = async (currencyId: string) => {
    if (!currencyId) return
    
    setLoading(true)
    try {
      const data = await rateCreationApi.prepareRateCreation(currencyId)
      setRateData(data)
      setEditingBuyRate(data.recommendedBuyRate || 0)
      setEditingSellRate(data.recommendedSellRate || 0)
    } catch {
      // Árfolyamkészítés adatok betöltése sikertelen
      // Ha hiba van, töröljük a rateData-t
      setRateData(null)
    } finally {
      setLoading(false)
    }
  }

  const handleRefresh = () => {
    if (selectedCurrencyId) {
      void loadRateCreation(String(selectedCurrencyId))
    }
  }

  const handlePublish = async () => {
    if (!selectedGroupId || !rateData) {
      alert('Kérjük, válasszon ki egy valutát és egy csoportot!')
      return
    }
    
    if (editingBuyRate <= 0 || editingSellRate <= 0) {
      alert('Az árfolyamoknak pozitív számnak kell lenniük!')
      return
    }
    
    if (editingBuyRate >= editingSellRate) {
      alert('A vételi árfolyamnak kisebbnek kell lennie az eladásinál!')
      return
    }
    
    try {
      setLoading(true)
      await rateCreationApi.publishGroupRate({
        currencyGroupId: selectedGroupId,
        currencyId: rateData.currencyId,
        buyRate: editingBuyRate,
        sellRate: editingSellRate
      })
      alert('Árfolyam sikeresen publikálva!')
      handleRefresh()
    } catch (error: unknown) {
      const errorMessage = error instanceof Error && 'response' in error && 
                          typeof error.response === 'object' && error.response !== null &&
                          'data' in error.response && 
                          typeof error.response.data === 'object' && error.response.data !== null &&
                          'message' in error.response.data && typeof error.response.data.message === 'string'
                          ? error.response.data.message 
                          : error instanceof Error ? error.message : 'Hiba történt a publikálás során'
      alert(`Hiba: ${errorMessage}`)
    } finally {
      setLoading(false)
    }
  }

  const getSpread = (buy: number, sell: number) => {
    return ((sell - buy) / buy * 100).toFixed(2)
  }

  if (loading && !rateData) {
    return (
      <div className="flex items-center justify-center h-64">
        <RefreshCw className="animate-spin text-blue-600" size={32} />
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Calculator />
          Árfolyamkészítés
        </h1>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={handleRefresh}
            className="form-button-primary flex items-center gap-1"
            disabled={loading}
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            Frissítés
          </button>
        </div>
      </div>

      {/* Currency Selector */}
      <div className="form-panel">
        <label htmlFor="rate-currency-select" className="form-label">Valuta kiválasztása</label>
        <select
          id="rate-currency-select"
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

      {rateData && (
        <>
          {/* Recommended Rates Card */}
          <div className="form-panel bg-gradient-to-r from-blue-50 to-green-50 border-2 border-blue-200">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
                <TrendingUp className="text-blue-600" />
                Ajánlott saját árfolyam - {rateData.currencyCode}
              </h2>
            </div>

            <div className="grid grid-cols-3 gap-4 mb-4">
              <div>
                <label className="form-label text-sm">Ajánlott vételi árfolyam</label>
                <NumberInput
                  value={editingBuyRate.toString().replace('.', ',')}
                  onChange={(val) => setEditingBuyRate(parseFloat(val.replace(',', '.')) || 0)}
                  className="form-input text-lg text-green-600 font-bold"
                  allowDecimals={true}
                  allowNegative={false}
                  step="0.0001"
                />
                <div className="text-xs text-gray-500 mt-1 font-mono">
                  Min: {formatDecimal(rateData.minBuyRate, 4, 4)} | 
                  Max: {formatDecimal(rateData.maxBuyRate, 4, 4)} | 
                  Átl: {formatDecimal(rateData.avgBuyRate, 4, 4)}
                </div>
              </div>

              <div>
                <label className="form-label text-sm">Ajánlott eladási árfolyam</label>
                <NumberInput
                  value={editingSellRate.toString().replace('.', ',')}
                  onChange={(val) => setEditingSellRate(parseFloat(val.replace(',', '.')) || 0)}
                  className="form-input text-lg text-red-600 font-bold"
                  allowDecimals={true}
                  allowNegative={false}
                  step="0.0001"
                />
                <div className="text-xs text-gray-500 mt-1 font-mono">
                  Min: {formatDecimal(rateData.minSellRate, 4, 4)} | 
                  Max: {formatDecimal(rateData.maxSellRate, 4, 4)} | 
                  Átl: {formatDecimal(rateData.avgSellRate, 4, 4)}
                </div>
              </div>

              <div>
                <label className="form-label text-sm">Középárfolyam</label>
                <div className="form-input font-mono text-lg text-gray-700 font-bold bg-gray-50">
                  {formatDecimal((editingBuyRate + editingSellRate) / 2, 4, 4)}
                </div>
                <div className="text-xs text-gray-500 mt-1">
                  Spread: {getSpread(editingBuyRate, editingSellRate)}%
                </div>
              </div>
            </div>

            {rateData.notes && (
              <div className="bg-white p-2 rounded text-sm text-gray-600 border border-gray-200">
                <AlertCircle className="inline mr-2" size={14} />
                {rateData.notes}
              </div>
            )}

            <div className="mt-4 flex gap-2">
              <select
                id="group-select"
                title="Válassz csoportot"
                value={selectedGroupId}
                onChange={(e) => setSelectedGroupId(e.target.value)}
                className="form-input flex-1"
              >
                <option value="">-- Válassz csoportot publikáláshoz --</option>
                {currencyGroups.map((group) => (
                  <option key={group.id} value={group.id}>
                    {group.code} - {group.name}
                  </option>
                ))}
              </select>
              <button
                type="button"
                onClick={handlePublish}
                disabled={!selectedGroupId}
                className="form-button-primary flex items-center gap-2"
              >
                <Save size={16} />
                Publikálás
              </button>
            </div>
          </div>

          {/* Bank Rates Section */}
          {rateData.bankRates.length > 0 && (
            <div className="form-panel">
              <h3 className="font-semibold mb-3 flex items-center gap-2">
                <CheckCircle className="text-blue-600" size={18} />
                Banki referencia árfolyamok
              </h3>
              <div className="overflow-x-auto">
                <table className="data-grid w-full text-sm">
                  <thead>
                    <tr>
                      <th>Bank</th>
                      <th className="text-right">Vételi</th>
                      <th className="text-right">Eladási</th>
                      <th className="text-right">Közép</th>
                      <th>Frissítve</th>
                      <th>Forrás</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rateData.bankRates.map((bank) => (
                      <tr key={bank.id}>
                        <td>
                          <span className="font-semibold">{bank.bankName}</span>
                          <span className="text-xs text-gray-500 ml-2">({bank.bankCode})</span>
                        </td>
                        <td className="text-right font-mono text-green-600">{formatDecimal(bank.buyRate, 4, 4)}</td>
                        <td className="text-right font-mono text-red-600">{formatDecimal(bank.sellRate, 4, 4)}</td>
                        <td className="text-right font-mono text-gray-600">
                          {bank.middleRate ? formatDecimal(bank.middleRate, 4, 4) : '-'}
                        </td>
                        <td className="text-sm text-gray-500">
                          {new Date(bank.validFrom).toLocaleString('hu-HU')}
                        </td>
                        <td className="text-xs text-gray-500">{bank.source || '-'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Competitor Rates Section */}
          {rateData.competitorRates.length > 0 && (
            <div className="form-panel">
              <h3 className="font-semibold mb-3 flex items-center gap-2">
                <TrendingUp className="text-orange-600" size={18} />
                Konkurens árfolyamok ({rateData.competitorRates.length} db)
              </h3>
              <div className="overflow-x-auto">
                <table className="data-grid w-full text-sm">
                  <thead>
                    <tr>
                      <th>Konkurens</th>
                      <th className="text-right">Vételi</th>
                      <th className="text-right">Eladási</th>
                      <th className="text-right">Közép</th>
                      <th>Rögzítve</th>
                      <th>Forrás</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rateData.competitorRates.map((comp) => (
                      <tr key={comp.id}>
                        <td>
                          <span className="font-semibold">{comp.competitorName}</span>
                          <span className="text-xs text-gray-500 ml-2">({comp.competitorCode})</span>
                        </td>
                        <td className="text-right font-mono text-green-600">{formatDecimal(comp.buyRate, 4, 4)}</td>
                        <td className="text-right font-mono text-red-600">{formatDecimal(comp.sellRate, 4, 4)}</td>
                        <td className="text-right font-mono text-gray-600">{formatDecimal(comp.middleRate, 4, 4)}</td>
                        <td className="text-sm text-gray-500">
                          {new Date(comp.recordedAt).toLocaleString('hu-HU')}
                        </td>
                        <td className="text-xs text-gray-500">{comp.source || '-'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Statistics Summary */}
          <div className="grid grid-cols-2 gap-4">
            <div className="form-panel bg-gray-50">
              <h4 className="font-semibold mb-2 text-sm">Vételi árfolyam statisztikák</h4>
              <div className="space-y-1 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-600">Minimum:</span>
                  <span className="font-mono font-semibold text-green-600">{formatDecimal(rateData.minBuyRate, 4, 4)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Maximum:</span>
                  <span className="font-mono font-semibold text-green-600">{formatDecimal(rateData.maxBuyRate, 4, 4)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Átlag:</span>
                  <span className="font-mono font-semibold text-green-600">{formatDecimal(rateData.avgBuyRate, 4, 4)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Ajánlott:</span>
                  <span className="font-mono font-bold text-blue-600">{formatDecimal(editingBuyRate, 4, 4)}</span>
                </div>
              </div>
            </div>

            <div className="form-panel bg-gray-50">
              <h4 className="font-semibold mb-2 text-sm">Eladási árfolyam statisztikák</h4>
              <div className="space-y-1 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-600">Minimum:</span>
                  <span className="font-mono font-semibold text-red-600">{formatDecimal(rateData.minSellRate, 4, 4)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Maximum:</span>
                  <span className="font-mono font-semibold text-red-600">{formatDecimal(rateData.maxSellRate, 4, 4)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Átlag:</span>
                  <span className="font-mono font-semibold text-red-600">{formatDecimal(rateData.avgSellRate, 4, 4)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Ajánlott:</span>
                  <span className="font-mono font-bold text-blue-600">{formatDecimal(editingSellRate, 4, 4)}</span>
                </div>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  )
}

