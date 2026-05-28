import { useEffect, useState } from 'react'
import { AlertTriangle } from 'lucide-react'
import { formatDecimal } from '../../../utils/numberFormat'
import { useGridNavigation } from '../../../hooks/useGridNavigation'
import type { WorkgroupDetailDTO } from '../../../services/api/index'
import { fmtAmount, parseNum, type EditableRate } from '../types'
import type { WgField } from '../workgroupSheetCompute'
import { useTranslation } from 'react-i18next'

// FK-04/C: a 8 képletezhető oszlop (J=elszámoló read-only, K=ISO kód read-only).
// A `officialRate` (J) read-only auto, ezért kizárt — így r[field] mindig string.
type GridField = Exclude<WgField, 'officialRate'>
const EDITABLE_FIELDS: GridField[] = [
  'buyRate', 'sellRate',
  'limit1BuyRate', 'limit1SellRate',
  'limit2BuyRate', 'limit2SellRate',
  'limit3BuyRate', 'limit3SellRate',
]

interface RateGridProps {
  rates: EditableRate[]
  selectedWg: WorkgroupDetailDTO | null
  updateRate: (index: number, field: keyof EditableRate, value: string) => void
  validationErrors?: Record<number, string[]>
  /** FK-04/C: cellánkénti képletek (kulcs `${currencyId}.${field}`). */
  formulas?: Record<string, string>
  /** FK-04/C: cellánkénti képlet-hibák (kulcs `${currencyId}.${field}`). */
  cellErrors?: Record<string, string>
  /** FK-04/C: cella-commit blur/Enter-kor (képlet vagy fix érték). */
  onCommitCell?: (index: number, field: WgField, raw: string) => void
}

export default function RateGrid({
  rates,
  selectedWg,
  updateRate,
  validationErrors = {},
  formulas = {},
  cellErrors = {},
  onCommitCell,
}: RateGridProps) {
  const { t } = useTranslation()
  const { containerRef, activeCell, getCellProps } = useGridNavigation({
    rows: rates.length,
    cols: EDITABLE_FIELDS.length,
  })

  // FK-04/C szerkesztő-buffer: a fókuszált cella nyers szövege (képlet vagy szám). A többi
  // cella a `rates[field]` SZÁMÍTOTT értékét mutatja; a fókuszált cella a buffert, hogy a
  // felhasználó a KÉPLETET lássa/szerkessze (0-s lap minta). Commit blur/Enter-kor.
  const [buffer, setBuffer] = useState('')

  // Buffer seed: a fókuszált cellába a képlet-string (ha van), egyébként a megjelenített érték.
  useEffect(() => {
    if (!activeCell) return
    const r = rates[activeCell.row]
    const field = EDITABLE_FIELDS[activeCell.col]
    if (!r || !field) return
    const key = `${r.currencyId}.${field}`
    setBuffer(formulas[key] ?? r[field])
  // eslint-disable-next-line react-hooks/exhaustive-deps -- csak a cella-fókusz váltáskor seed-elünk
  }, [activeCell])

  // 2026-04-29 v2.3.13 (Árfolyamkészítés zoom-fit): 17 valuta sor scrollozás nélkül.
  return (
    <div ref={containerRef} className="flex-1 bg-white rounded shadow-sm border overflow-hidden flex flex-col min-w-0">
      <div className="overflow-auto flex-1">
        <table className="w-full text-xs border-collapse">
          <thead className="sticky top-0 z-20">
            <tr className="bg-green-800 text-white text-[10px] leading-none">
              <th colSpan={2} className="px-1 py-0 text-left border-r border-green-600">{t('rates.elszArf')}</th>
              <th className="px-1 py-0 border-r border-green-600">{t('common.currency')}</th>
              {/* eslint-disable-next-line i18next/no-literal-string */}
              <th colSpan={2} className="px-1 py-0 border-r border-green-600 text-center">
                0 - {fmtAmount(selectedWg?.limit1Boundary)}
              </th>
              <th colSpan={2} className="px-1 py-0 border-r border-green-600 text-center">
                {fmtAmount(selectedWg?.limit1Boundary)} - {fmtAmount(selectedWg?.limit2Boundary)}
              </th>
              <th colSpan={2} className="px-1 py-0 border-r border-green-600 text-center">
                {fmtAmount(selectedWg?.limit2Boundary)} - {fmtAmount(selectedWg?.limit3Boundary)}
              </th>
              <th colSpan={2} className="px-1 py-0 text-center border-r border-green-600">{t('rates.sajatHat')}</th>
              <th className="px-1 py-0 text-center w-28">{t('rates.ellenorzes')}</th>
            </tr>
            <tr className="bg-green-700 text-white text-[10px] leading-none">
              <th className="px-1 py-0 text-left w-14 border-r border-green-500">MNB</th>
              <th className="px-1 py-0 w-4 border-r border-green-500"></th>
              <th className="px-1 py-0 w-10 border-r border-green-500 font-bold">{t('common.code')}</th>
              <th className="px-1 py-0 w-[72px] text-green-200 border-r border-green-500">{t('rates.vet')}</th>
              <th className="px-1 py-0 w-[72px] text-red-200 border-r border-green-500">{t('rates.elad')}</th>
              <th className="px-1 py-0 w-[72px] text-green-200 border-r border-green-500">{t('rates.v')}</th>
              <th className="px-1 py-0 w-[72px] text-red-200 border-r border-green-500">E-</th>
              <th className="px-1 py-0 w-[72px] text-green-200 border-r border-green-500">{t('rates.v')}</th>
              <th className="px-1 py-0 w-[72px] text-red-200 border-r border-green-500">E-</th>
              <th className="px-1 py-0 w-[72px] text-green-200 border-r border-green-500">{t('rates.vmax')}</th>
              <th className="px-1 py-0 w-[72px] text-red-200 border-r border-green-500">{t('rates.emin')}</th>
              <th className="px-1 py-0 text-yellow-200">{t('common.error')}</th>
            </tr>
          </thead>
          <tbody className="text-[10.5px] leading-none">
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
                    const isBuy = field.includes('Buy') || field === 'buyRate'
                    const colorClass = isBuy ? 'text-green-700' : 'text-red-700'
                    const focusBg = isBuy ? 'focus:bg-green-50' : 'focus:bg-red-50'
                    const isActive = activeCell?.row === idx && activeCell?.col === colIdx
                    const activeBorder = isActive ? 'ring-2 ring-blue-500 ring-inset' : ''
                    const key = `${r.currencyId}.${field}`
                    const hasFormula = !!formulas[key]
                    const cellError = cellErrors[key]
                    // A fókuszált cella a buffert (képlet/nyers) mutatja; a többi a számított értéket.
                    const display = isActive ? buffer : r[field]
                    const formulaBg = hasFormula && !isActive ? 'bg-indigo-50' : ''
                    const errorRing = cellError ? 'ring-2 ring-red-400 ring-inset' : ''
                    const commit = (raw: string) => {
                      if (onCommitCell) onCommitCell(idx, field, raw)
                      else updateRate(idx, field, raw) // visszafelé-kompatibilis fallback
                    }
                    return (
                      <td key={field} className="px-0 py-0 border-r relative">
                        <input
                          type="text"
                          value={display}
                          {...getCellProps(idx, colIdx)}
                          onChange={e => {
                            if (isActive) setBuffer(e.target.value)
                            else if (!onCommitCell) updateRate(idx, field, e.target.value)
                          }}
                          onBlur={() => { if (isActive) commit(buffer) }}
                          title={hasFormula ? `Képlet: ${formulas[key]}${cellError ? ` — HIBA: ${cellError}` : ''}` : cellError}
                          className={`w-full px-0.5 py-0 text-right font-mono text-[11px] ${colorClass} font-bold border-0 bg-transparent ${focusBg} focus:outline-none ${activeBorder} ${formulaBg} ${errorRing}`}
                        />
                        {hasFormula && !isActive && (
                          <span className="absolute left-0.5 top-0 text-[7px] text-indigo-500 font-bold pointer-events-none" title={`Képlet: ${formulas[key]}`}>ƒ</span>
                        )}
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
                      // eslint-disable-next-line i18next/no-literal-string
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
