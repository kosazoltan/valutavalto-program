import { useState, useEffect, useCallback, useMemo } from 'react'
import { Coins, Save, RefreshCw, Calculator, AlertCircle } from 'lucide-react'
import {
  denominationBalanceApi,
  DenominationBalanceDTO,
  denominationApi,
  currencyApi,
  Denomination,
  Currency
} from '../../services/api/index'
import { NumberInput } from '../../components/NumberInput'
import { toast } from '../../components/ui/toaster'
import { formatInteger, formatDecimal } from '../../utils/numberFormat'
import { logger } from '../../utils/logger';
import { useAuthStore } from '../../stores/authStore';
import { useTranslation } from 'react-i18next'

interface DenominationQuantityUpdateRequest {
  denominationId: string
  quantity: number
}

export default function DenominationPage() {
  const { t } = useTranslation()
  const selectedCashDeskId = useAuthStore((s: { worker: { branchId: string } | null }) => s.worker?.branchId ?? '')
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [selectedCurrencyId, setSelectedCurrencyId] = useState<number | null>(null)
  const [denominations, setDenominations] = useState<Denomination[]>([])
  const [_denominationBalances, setDenominationBalances] = useState<DenominationBalanceDTO[]>([])
  const [editingQuantities, setEditingQuantities] = useState<Record<number, number>>({})
  const [loading, setLoading] = useState(false)
  // Copilot #1109: az összesítő DERIVÁLT érték a szerkesztett darabszámokból — state-ként
  // tartva versenyhelyzetes/elcsúszó újraszámításokra volt érzékeny.
  const calculatedTotal = useMemo(
    () => denominations
      .filter(d => d.currencyId === selectedCurrencyId)
      .reduce((sum, d) => sum + d.faceValue * (editingQuantities[d.id] ?? 0), 0),
    [denominations, selectedCurrencyId, editingQuantities],
  )

  // Batch2-A (Fabulya-teszt 2026-06-12): a címletek ÉS a mentett egyenlegek betöltése
  // EGY szekvenciális folyamatban. Korábban két párhuzamos hívás versenyzett ugyanazon
  // a state-en (az egyik mindent 0-ra resetelt, a másik a mentett értékeket írta be,
  // teljes-csere set-tel) — ha a 0-reset futott be utoljára, a mentett címletezés
  // 0-ként jelent meg, „nem rögzíthető" tünetet okozva.
  const loadAll = useCallback(async () => {
    if (!selectedCashDeskId || !selectedCurrencyId) return
    setLoading(true)
    try {
      const denoms = await denominationApi.getByCurrencyId(selectedCurrencyId)
      setDenominations(denoms)

      const balances = await denominationBalanceApi.getCashDeskDenominationsByCurrency(
        selectedCashDeskId, String(selectedCurrencyId))
      setDenominationBalances(balances)

      // Egyetlen, determinisztikus state-írás: minden címlet 0, felülírva a mentettekkel.
      // (Az összesítő ebből DERIVÁLT useMemo — külön nem kell beállítani.)
      const quantities: Record<number, number> = {}
      denoms.forEach((d: Denomination) => { quantities[d.id] = 0 })
      balances.forEach(balance => {
        quantities[Number(balance.denominationId)] = balance.quantity
      })
      setEditingQuantities(quantities)
    } catch (error) {
      logger.error('DenominationPage', 'Címletezés betöltése sikertelen:', error)
    } finally {
      setLoading(false)
    }
  }, [selectedCashDeskId, selectedCurrencyId])

  useEffect(() => {
    void loadCurrencies()
  }, [])

  useEffect(() => {
    if (selectedCurrencyId && selectedCashDeskId) {
      void loadAll()
    }
  }, [selectedCurrencyId, selectedCashDeskId, loadAll])

  const loadCurrencies = async () => {
    try {
      const data = await currencyApi.getActive()
      setCurrencies(data)
      if (data.length > 0) {
        setSelectedCurrencyId(data[0]?.id ?? null)
      }
    } catch (error) {
      logger.error('DenominationPage', 'Valuták betöltése sikertelen:', error)
    }
  }

  const handleQuantityChange = (denominationId: number, quantityStr: string) => {
    // Darabszám = egész szám (a backend DTO Integer) — tört darab nem értelmezhető.
    const quantity = Math.max(0, parseInt(quantityStr.replace(/\s/g, ''), 10) || 0)
    // Copilot #1109: funkcionális update — gyors egymás utáni input-eseményeknél a
    // spread-es minta a stale snapshot miatt frissítést veszíthetne. Az összesítő
    // derivált érték (useMemo), külön újraszámítás nem kell.
    setEditingQuantities(prev => ({ ...prev, [denominationId]: quantity }))
  }

  const handleSave = async () => {
    if (!selectedCashDeskId) {
      toast.warning('Hiányzó adat', 'Válassz pénztárat!')
      return
    }

    try {
      // Batch2-A: a 0 darabszámot IS elküldjük — korábban a qty>0 szűrő miatt egy
      // címlet 0-ra állítása (korábbi érték törlése) sosem perzisztálódott.
      // Csak az aktuálisan kiválasztott valuta címleteit küldjük.
      const currentIds = new Set(
        denominations.filter(d => d.currencyId === selectedCurrencyId).map(d => d.id))
      const updates: DenominationQuantityUpdateRequest[] = Object.entries(editingQuantities)
        .filter(([id]) => currentIds.has(Number(id)))
        .map(([denominationId, quantity]) => ({
          denominationId,
          quantity
        }))

      await denominationBalanceApi.setDenominationQuantities(selectedCashDeskId, updates)
      toast.success('Címletezés sikeresen mentve!')
      void loadAll()
    } catch (error) {
      logger.error('DenominationPage', 'Mentés sikertelen:', error)
      toast.error('Hiba történt a mentés során')
    }
  }

  const selectedCurrency = currencies.find(c => c.id === selectedCurrencyId)

  return (
    <div className="space-y-2">
      {/* Header + Currency Selector — egy sorban */}
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <div className="flex items-center gap-3">
          <h1 className="text-lg font-bold text-gray-800 flex items-center gap-2">
            <Coins size={20} />
            {t('cashdesk.penztarCimletezes')}
          </h1>
          <select
            id="currency-select"
            title="Válassz valutát"
            aria-label={t('cashdesk.valutaKivalasztasa')}
            value={selectedCurrencyId ?? ''}
            onChange={(e) => setSelectedCurrencyId(e.target.value ? Number(e.target.value) : null)}
            className="form-input h-8 text-sm w-48"
          >
            <option value="">{t('cashdesk.valasszValutat')}</option>
            {currencies.map((curr) => (
              <option key={curr.id} value={curr.id}>
                {curr.code} - {curr.name}
              </option>
            ))}
          </select>
          {selectedCurrency && (
            <div className="flex items-center gap-2 px-3 py-1 bg-blue-50 border border-blue-200 rounded-lg">
              <Calculator className="text-blue-600" size={14} />
              <span className="text-sm text-gray-600">{t('cashdesk.osszesitettEgyenleg')}</span>
              <span className="font-bold text-base font-mono text-green-600">
                {formatDecimal(calculatedTotal, 2, 2)} {selectedCurrency.code}
              </span>
            </div>
          )}
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={loadAll}
            className="form-button flex items-center gap-1 h-8 text-sm"
            disabled={loading}
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
            {t('common.refresh')}
          </button>
          <button
            type="button"
            onClick={handleSave}
            className="form-button-primary flex items-center gap-1 h-8 text-sm"
            disabled={!selectedCashDeskId}
          >
            <Save size={14} />
            {t('common.save')}
          </button>
        </div>
      </div>

      {/* Denominations Table */}
      {selectedCurrencyId && (
        <div className="form-panel p-0">
          <div className="overflow-x-auto">
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th className="w-32">{t('cashdesk.cimlet')}</th>
                  <th className="w-24">{t('common.type')}</th>
                  <th className="w-32">{t('cashdesk.mennyiseg')}</th>
                  <th className="text-right w-40">{t('common.amount')}</th>
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
                          <span className="font-mono font-bold text-sm">
                            {formatInteger(denomination.faceValue)} {selectedCurrency?.code}
                          </span>
                        </td>
                        <td>
                          <span className="text-[10px] bg-gray-100 px-1.5 py-0.5 rounded">
                            {denomination.denominationType === 'BANKNOTE' ? 'Bankjegy' : 'Érme'}
                          </span>
                        </td>
                        <td>
                          <NumberInput
                            value={quantity > 0 ? String(quantity) : ''}
                            onChange={(val) => handleQuantityChange(denomination.id, val)}
                            className="form-input w-24 text-center"
                            placeholder="0"
                            allowDecimals={false}
                            allowNegative={false}
                            min={0}
                            step="1"
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
                  <td colSpan={3} className="text-right pr-4">{t('cashdesk.osszesen2')}</td>
                  <td className="text-right">
                    <span className="font-mono text-base text-blue-600">
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
            {t('cashdesk.penztarKivalasztasaSzuksegesACimletezeshez')}
          </span>
        </div>
      )}
    </div>
  )
}
