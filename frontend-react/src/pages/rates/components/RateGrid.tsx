import { AlertTriangle } from 'lucide-react'
import { formatDecimal } from '../../../utils/numberFormat'
import { useGridNavigation } from '../../../hooks/useGridNavigation'
import type { WorkgroupDetailDTO } from '../../../services/api'
import { fmtAmount, parseNum, type EditableRate } from '../types'

const EDITABLE_FIELDS = ['buyRate', 'sellRate', 'limit1BuyRate', 'limit1SellRate', 'limit2BuyRate', 'limit2SellRate', 'limit3BuyRate', 'limit3SellRate'] as const

interface RateGridProps {
  rates: EditableRate[]
  selectedWg: WorkgroupDetailDTO | null
  updateRate: (index: number, field: keyof EditableRate, value: string) => void
  validationErrors?: Record<number, string[]>
}

export default function RateGrid({ rates, selectedWg, updateRate, validationErrors = {} }: RateGridProps) {
  const { containerRef, activeCell, getCellProps } = useGridNavigation({
    rows: rates.length,
    cols: EDITABLE_FIELDS.length,
  })

  return (
    <div ref={containerRef} className="flex-1 bg-white rounded shadow-sm border overflow-hidden flex flex-col min-w-0">
      <div className="overflow-auto flex-1">
        <table className="w-full text-xs border-collapse">
          <thead className="sticky top-0 z-20">
            <tr className="bg-green-800 text-white text-[10px]">
              <th colSpan={2} className="px-1 py-0.5 text-left border-r border-green-600">Elsz.árf.</th>
              <th className="px-1 py-0.5 border-r border-green-600">Valuta</th>
              <th colSpan={2} className="px-1 py-0.5 border-r border-green-600 text-center">
                0 - {fmtAmount(selectedWg?.limit1Boundary)}
              </th>
              <th colSpan={2} className="px-1 py-0.5 border-r border-green-600 text-center">
                {fmtAmount(selectedWg?.limit1Boundary)} - {fmtAmount(selectedWg?.limit2Boundary)}
              </th>
              <th colSpan={2} className="px-1 py-0.5 border-r border-green-600 text-center">
                {fmtAmount(selectedWg?.limit2Boundary)} - {fmtAmount(selectedWg?.limit3Boundary)}
              </th>
              <th colSpan={2} className="px-1 py-0.5 text-center border-r border-green-600">Saját hat.</th>
              <th className="px-1 py-0.5 text-center w-28">Ellenőrzés</th>
            </tr>
            <tr className="bg-green-700 text-white text-[10px]">
              <th className="px-1 py-0.5 text-left w-14 border-r border-green-500">MNB</th>
              <th className="px-1 py-0.5 w-4 border-r border-green-500"></th>
              <th className="px-1 py-0.5 w-10 border-r border-green-500 font-bold">Kód</th>
              <th className="px-1 py-0.5 w-[72px] text-green-200 border-r border-green-500">Vet</th>
              <th className="px-1 py-0.5 w-[72px] text-red-200 border-r border-green-500">Elad</th>
              <th className="px-1 py-0.5 w-[72px] text-green-200 border-r border-green-500">V+</th>
              <th className="px-1 py-0.5 w-[72px] text-red-200 border-r border-green-500">E-</th>
              <th className="px-1 py-0.5 w-[72px] text-green-200 border-r border-green-500">V+</th>
              <th className="px-1 py-0.5 w-[72px] text-red-200 border-r border-green-500">E-</th>
              <th className="px-1 py-0.5 w-[72px] text-green-200 border-r border-green-500">Vmax</th>
              <th className="px-1 py-0.5 w-[72px] text-red-200 border-r border-green-500">Emin</th>
              <th className="px-1 py-0.5 text-yellow-200">Hiba</th>
            </tr>
            <tr className="bg-gray-200 text-gray-500 text-[9px] font-bold">
              <th className="px-1 py-0 border-r">J</th>
              <th className="px-1 py-0 border-r"></th>
              <th className="px-1 py-0 border-r">K</th>
              <th className="px-1 py-0 border-r">L</th>
              <th className="px-1 py-0 border-r">M</th>
              <th className="px-1 py-0 border-r">N</th>
              <th className="px-1 py-0 border-r">O</th>
              <th className="px-1 py-0 border-r">P</th>
              <th className="px-1 py-0 border-r">Q</th>
              <th className="px-1 py-0">R</th>
              <th className="px-1 py-0 border-r">S</th>
              <th className="px-1 py-0">✓</th>
            </tr>
          </thead>
          <tbody>
            {rates.map((r, idx) => {
              const buy = parseNum(r.buyRate)
              const sell = parseNum(r.sellRate)
              const isInvalid = buy > 0 && sell > 0 && buy >= sell
              const rowBg = r.modified
                ? 'bg-yellow-50'
                : !r.hasRate
                  ? 'bg-gray-50'
                  : idx % 2 === 0 ? 'bg-white' : 'bg-gray-50/50'

              return (
                <tr key={r.currencyId} className={`${rowBg} border-b border-gray-100 hover:bg-blue-50/30`}>
                  <td className="px-1 py-0 text-right font-mono text-blue-800 font-bold border-r text-[11px]">
                    {r.officialRate ? formatDecimal(r.officialRate, 2, 4) : '0'}
                  </td>
                  <td className="px-0 py-0 text-center border-r w-4">
                    {r.modified && <span className="inline-block w-1.5 h-1.5 rounded-full bg-orange-400" />}
                    {isInvalid && <AlertTriangle size={9} className="text-red-500 inline" />}
                  </td>
                  <td className="px-1 py-0 text-center font-bold text-blue-700 border-r text-[11px]">
                    {r.currencyCode}
                  </td>
                  {EDITABLE_FIELDS.map((field, colIdx) => {
                    const isBuy = field.includes('buy') || field === 'buyRate'
                    const colorClass = isBuy ? 'text-green-700' : 'text-red-700'
                    const focusBg = isBuy ? 'focus:bg-green-50' : 'focus:bg-red-50'
                    const isActive = activeCell?.row === idx && activeCell?.col === colIdx
                    const activeBorder = isActive ? 'ring-2 ring-blue-500 ring-inset' : ''
                    return (
                      <td key={field} className="px-0 py-0 border-r">
                        <input type="text" value={r[field]}
                          {...getCellProps(idx, colIdx)}
                          onChange={e => updateRate(idx, field, e.target.value)}
                          className={`w-full px-0.5 py-0 text-right font-mono text-[11px] ${colorClass} font-bold border-0 bg-transparent ${focusBg} focus:outline-none ${activeBorder}`}
                        />
                      </td>
                    )
                  })}
                  <td className="px-1 py-0 text-[9px]">
                    {validationErrors[r.currencyId]?.map((err, ei) => (
                      <div key={ei} className="text-red-600 flex items-center gap-0.5">
                        <AlertTriangle size={8} className="flex-shrink-0" />
                        {err}
                      </div>
                    ))}
                    {!validationErrors[r.currencyId] && r.hasRate && (
                      <span className="text-green-600">✓</span>
                    )}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
