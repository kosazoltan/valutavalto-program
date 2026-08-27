import { useEffect, useState, useCallback } from 'react'
import { api } from '@/services/api/index'
import { safeArray } from '@/utils/safeArray'
import i18n from '../../i18n'

interface CurrencyLine {
  currencyCode: string
  currencyName: string
  openingStock: number
  closingStock: number
  totalBuyAmount: number
  totalSellAmount: number
  totalBuyHuf: number
  totalSellHuf: number
  avgBuyRate: number
  avgSellRate: number
  mnbRate?: number
}

interface TransferLine {
  currencyCode: string
  currencyName: string
  receivedAmount: number
  sentAmount: number
  netAmount: number
}

interface MonthlyReportFull {
  yearMonth: string
  branchCode: string
  branchName: string
  closingBalanceHuf: number
  closingBalanceForeign: number
  closingBalanceTotal: number
  currencyLines: CurrencyLine[]
  totalBuyHuf: number
  totalSellHuf: number
  cashTurnoverHuf: number
  cardTurnoverHuf: number
  transactionCount: number
  buyCount: number
  sellCount: number
  reversalCount: number
  wuHufBalance: number
  afaBalance: number
  handlingFeeBalance: number
  ecommerceBalance: number
  transferLines: TransferLine[]
  workingDays: number
  closedDays: number
}

const fmt = (n: number) => n.toLocaleString('hu-HU')

// Helyi (nem UTC) dátumból képzett YYYY-MM, hogy a hónap első óráiban
// időzóna miatt ne az előző hónapot adja vissza (Sourcery/Copilot bug_risk).
const currentMonth = () => {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
}

export default function MonthlyTabloPage() {
  const [yearMonth, setYearMonth] = useState(currentMonth())
  const [data, setData] = useState<MonthlyReportFull | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    const branchId = localStorage.getItem('branchId') || ''
    if (!branchId) {
      setError('Hiányzó iroda azonosító.')
      return
    }
    setLoading(true)
    setError(null)
    try {
      const response = await api.get(`/closing/monthly/${branchId}/${yearMonth}/full`)
      setData(response?.data ?? null)
    } catch {
      setError('A havi tabló lekérése sikertelen.')
      setData(null)
    } finally {
      setLoading(false)
    }
  }, [yearMonth])

  useEffect(() => {
    void load()
  }, [load])

  const lines = safeArray<CurrencyLine>(data?.currencyLines)
  const transfers = safeArray<TransferLine>(data?.transferLines)

  return (
    <div className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-3 print:hidden">
        <h1 className="text-lg font-bold">{i18n.t('literals.havi-tablo')}</h1>
        <div className="flex gap-2 items-center">
          <input
            type="month"
            value={yearMonth}
            onChange={(e) => setYearMonth(e.target.value)}
            className="p-2 border rounded"
          />
          <button
            onClick={() => window.print()}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            {i18n.t('literals.nyomtatas')}
          </button>
        </div>
      </div>

      {loading ? (
        <div className="text-center py-8">{i18n.t('literals.betoltes')}</div>
      ) : error ? (
        <div className="p-4 bg-red-50 border border-red-200 text-red-700 rounded">{error}</div>
      ) : !data ? (
        <div className="text-center py-8 text-gray-500">{i18n.t('literals.nincs-adat-3')}</div>
      ) : (
        <div className="space-y-4">
          <div className="text-sm text-gray-600">
            {data.branchCode}
            {i18n.t('literals.lit-32')}
            {data.branchName}
            {i18n.t('literals.lit-52')}
            {data.yearMonth}
            {i18n.t('literals.munkanapok')} {data.workingDays}
            {i18n.t('literals.lezart')}
            {data.closedDays}
            {i18n.t('literals.lit-2')}
          </div>

          {/* Valutánkénti forgalom */}
          <div className="bg-white rounded border">
            <table className="w-full text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <th className="p-2 text-left">{i18n.t('literals.vnem')}</th>
                  <th className="p-2 text-right">{i18n.t('literals.nyito')}</th>
                  <th className="p-2 text-right">{i18n.t('literals.vetel')}</th>
                  <th className="p-2 text-right">{i18n.t('literals.eladas')}</th>
                  <th className="p-2 text-right">{i18n.t('literals.zaro-2')}</th>
                  <th className="p-2 text-right">{i18n.t('literals.vetel-ft')}</th>
                  <th className="p-2 text-right">{i18n.t('literals.eladas-ft')}</th>
                  <th className="p-2 text-right">{i18n.t('literals.mnb')}</th>
                </tr>
              </thead>
              <tbody>
                {lines.map((l) => (
                  <tr key={l.currencyCode} className="border-t">
                    <td className="p-2 font-mono">{l.currencyCode}</td>
                    <td className="p-2 text-right">{fmt(l.openingStock)}</td>
                    <td className="p-2 text-right">{fmt(l.totalBuyAmount)}</td>
                    <td className="p-2 text-right">{fmt(l.totalSellAmount)}</td>
                    <td className="p-2 text-right">{fmt(l.closingStock)}</td>
                    <td className="p-2 text-right">{fmt(l.totalBuyHuf)}</td>
                    <td className="p-2 text-right">{fmt(l.totalSellHuf)}</td>
                    <td className="p-2 text-right">{l.mnbRate?.toFixed(4)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Összesítők */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <div className="p-3 bg-white border rounded">
              <div className="text-xs text-gray-500">{i18n.t('literals.osszes-vetel-ft')}</div>
              <div className="font-bold">{fmt(data.totalBuyHuf)}</div>
            </div>
            <div className="p-3 bg-white border rounded">
              <div className="text-xs text-gray-500">{i18n.t('literals.osszes-eladas-ft')}</div>
              <div className="font-bold">{fmt(data.totalSellHuf)}</div>
            </div>
            <div className="p-3 bg-white border rounded">
              <div className="text-xs text-gray-500">{i18n.t('literals.keszpenzes-forgalom')}</div>
              <div className="font-bold">{fmt(data.cashTurnoverHuf)}</div>
            </div>
            <div className="p-3 bg-white border rounded">
              <div className="text-xs text-gray-500">{i18n.t('literals.bankkartyas-forgalom')}</div>
              <div className="font-bold">{fmt(data.cardTurnoverHuf)}</div>
            </div>
            <div className="p-3 bg-white border rounded">
              <div className="text-xs text-gray-500">{i18n.t('literals.tranzakciok')}</div>
              <div className="font-bold">
                {data.transactionCount}
                {i18n.t('literals.v-5')}
                {data.buyCount}
                {i18n.t('literals.e-5')}
                {data.sellCount}
                {i18n.t('literals.s-3')}
                {data.reversalCount}
                {i18n.t('literals.lit-2')}
              </div>
            </div>
            <div className="p-3 bg-white border rounded">
              <div className="text-xs text-gray-500">{i18n.t('literals.kezelesi-dij')}</div>
              <div className="font-bold">
                {fmt(data.handlingFeeBalance)}
                {i18n.t('literals.ft')}
              </div>
            </div>
            <div className="p-3 bg-white border rounded">
              <div className="text-xs text-gray-500">{i18n.t('literals.wu-egyenleg')}</div>
              <div className="font-bold">
                {fmt(data.wuHufBalance)}
                {i18n.t('literals.ft')}
              </div>
            </div>
            <div className="p-3 bg-white border rounded">
              <div className="text-xs text-gray-500">{i18n.t('literals.afa-e-ker')}</div>
              <div className="font-bold">
                {fmt(data.afaBalance)}
                {i18n.t('literals.lit-10')}
                {fmt(data.ecommerceBalance)}
                {i18n.t('literals.ft')}
              </div>
            </div>
          </div>

          {/* Pénztárak közötti mozgás */}
          {transfers.length > 0 && (
            <div className="bg-white rounded border">
              <div className="p-2 font-semibold bg-gray-50">
                {i18n.t('literals.penztarak-kozotti-mozgas')}
              </div>
              <table className="w-full text-sm">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="p-2 text-left">{i18n.t('literals.vnem')}</th>
                    <th className="p-2 text-right">{i18n.t('literals.atvett')}</th>
                    <th className="p-2 text-right">{i18n.t('literals.atadott')}</th>
                    <th className="p-2 text-right">{i18n.t('literals.netto')}</th>
                  </tr>
                </thead>
                <tbody>
                  {transfers.map((tr) => (
                    <tr key={tr.currencyCode} className="border-t">
                      <td className="p-2 font-mono">{tr.currencyCode}</td>
                      <td className="p-2 text-right">{fmt(tr.receivedAmount)}</td>
                      <td className="p-2 text-right">{fmt(tr.sentAmount)}</td>
                      <td className="p-2 text-right">{fmt(tr.netAmount)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          <div className="p-3 bg-gray-50 border rounded text-right text-sm">
            {i18n.t('literals.zaro-keszlet-huf')}
            <strong>{fmt(data.closingBalanceHuf)}</strong>
            {i18n.t('literals.deviza-huf-ban')} {fmt(data.closingBalanceForeign)}
            {i18n.t('literals.lit-53')}
            <strong>
              {fmt(data.closingBalanceTotal)}
              {i18n.t('literals.ft')}
            </strong>
          </div>
        </div>
      )}
    </div>
  )
}
