import { useCallback, useEffect, useState } from 'react'
import { AlertTriangle, ArrowDownToLine, Eraser, Trash2 } from 'lucide-react'
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

// FK02-B / FR-6..10: a kedvezménysáv-oszlopok indexei az EDITABLE_FIELDS-ben (N–S, azaz limit1–3
// vétel/eladás) — a „Sávok törlése" toolbar-művelet ezeket üríti, a fő L/M (buy/sell) érintetlenül.
const BAND_COL_INDICES = [2, 3, 4, 5, 6, 7] as const

interface GridCoord {
  row: number
  col: number
}

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
  /**
   * FK02-B / FR-2..5: revert-jelzés. Ha a szám változása minden lépésnél nő, a parent
   * (RateCreationPage) megerősítést kérhet; "Mégse" esetén ezt a számlálót növeli, mire
   * a fókuszált cella buffere visszaáll a perzisztált értékre (a blur nem törli az
   * activeCell-t, ezért a `display = buffer` egyébként a beírt, nem mentett értéket mutatná).
   */
  revertSignal?: number
  /**
   * FK02-B / FR-6..10: kötegelt cella-alkalmazás a lebegő toolbarhoz (Lehúzás / Sávok törlése).
   * A parent (RateCreationPage) egyetlen undo-lépésben, modal nélkül, perzisztálva alkalmazza.
   */
  onBulkApply?: (cells: Array<{ row: number; field: WgField; raw: string }>) => void
  /** FK02-B: szerkesztési jog — a kijelölés-toolbar csak írásjoggal jelenik meg. */
  canEdit?: boolean
}

export default function RateGrid({
  rates,
  selectedWg,
  updateRate,
  validationErrors = {},
  formulas = {},
  cellErrors = {},
  onCommitCell,
  revertSignal = 0,
  onBulkApply,
  canEdit = true,
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

  // FK-04/C: a J (Elszámoló / officialRate) oszlop felülírható (spec: "alapból a 0-s lap A oszlopa,
  // felülírható"). Külön szerkesztő-buffer, mert a J a táblázat ELSŐ oszlopa (a 8 sávoszlop-rácstól
  // elkülönül), és a `r.officialRate` szám (a többi mező string). Üres = auto (0-s lap A).
  const [jBuffer, setJBuffer] = useState('')
  const [jRow, setJRow] = useState<number | null>(null)

  // FK02-B / FR-6..10: Excel-szerű tartomány-kijelölés (egér-drag + Shift+kattintás) és lebegő toolbar.
  const [selStart, setSelStart] = useState<GridCoord | null>(null)
  const [selEnd, setSelEnd] = useState<GridCoord | null>(null)
  const [isDragging, setIsDragging] = useState(false)
  const [toolbarPos, setToolbarPos] = useState<{ top: number; left: number } | null>(null)

  const selBounds = useCallback(() => {
    if (!selStart || !selEnd) return null
    return {
      r0: Math.min(selStart.row, selEnd.row),
      r1: Math.max(selStart.row, selEnd.row),
      c0: Math.min(selStart.col, selEnd.col),
      c1: Math.max(selStart.col, selEnd.col),
    }
  }, [selStart, selEnd])

  const isCellSelected = useCallback((row: number, col: number) => {
    const b = selBounds()
    return !!b && row >= b.r0 && row <= b.r1 && col >= b.c0 && col <= b.c1
  }, [selBounds])

  const clearSelection = useCallback(() => {
    setSelStart(null)
    setSelEnd(null)
    setToolbarPos(null)
  }, [])

  // Drag vége bárhol az ablakban → drag leáll (a toolbar megjelenítését a cella-onMouseUp intézi,
  // mert ahhoz kell a cella-koordináta; ez csak biztonsági leállítás, ha a kurzor cellán kívül enged fel).
  useEffect(() => {
    if (!isDragging) return
    const onUp = () => setIsDragging(false)
    window.addEventListener('mouseup', onUp)
    return () => window.removeEventListener('mouseup', onUp)
  }, [isDragging])

  // Escape → kijelölés + toolbar elrejtése.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') clearSelection() }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [clearSelection])

  const showToolbarIfMulti = useCallback((start: GridCoord, end: GridCoord, clientX: number, clientY: number) => {
    const multi = start.row !== end.row || start.col !== end.col
    if (multi && canEdit) setToolbarPos({ top: clientY + 10, left: clientX + 10 })
    else { setSelStart(null); setSelEnd(null); setToolbarPos(null) }
  }, [canEdit])

  const onCellMouseDown = useCallback((e: React.MouseEvent, row: number, col: number) => {
    if (e.shiftKey && selStart) {
      const end = { row, col }
      setSelEnd(end)
      showToolbarIfMulti(selStart, end, e.clientX, e.clientY)
      return
    }
    setSelStart({ row, col })
    setSelEnd({ row, col })
    setIsDragging(true)
    setToolbarPos(null)
  }, [selStart, showToolbarIfMulti])

  const onCellMouseEnter = useCallback((row: number, col: number) => {
    if (isDragging) setSelEnd({ row, col })
  }, [isDragging])

  const onCellMouseUp = useCallback((e: React.MouseEvent, row: number, col: number) => {
    if (!isDragging) return
    setIsDragging(false)
    const start = selStart ?? { row, col }
    const end = { row, col }
    setSelEnd(end)
    showToolbarIfMulti(start, end, e.clientX, e.clientY)
  }, [isDragging, selStart, showToolbarIfMulti])

  // --- Toolbar műveletek (kizárólag a kijelölt tartományra hatnak) ---

  const bulkClearSelected = useCallback(() => {
    const b = selBounds()
    if (!b || !onBulkApply) return
    const cells: Array<{ row: number; field: WgField; raw: string }> = []
    for (let row = b.r0; row <= b.r1; row++) {
      for (let col = b.c0; col <= b.c1; col++) cells.push({ row, field: EDITABLE_FIELDS[col]!, raw: '' })
    }
    onBulkApply(cells)
    clearSelection()
  }, [selBounds, onBulkApply, clearSelection])

  const bulkFillDownSelected = useCallback(() => {
    const b = selBounds()
    if (!b || !onBulkApply) return
    const cells: Array<{ row: number; field: WgField; raw: string }> = []
    for (let col = b.c0; col <= b.c1; col++) {
      const field = EDITABLE_FIELDS[col]!
      const src = rates[b.r0]
      if (!src) continue
      // A forrás a kijelölés legfelső sora: a KÉPLET (ha van), különben a megjelenített érték.
      const srcRaw = formulas[`${src.currencyId}.${field}`] ?? src[field]
      for (let row = b.r0 + 1; row <= b.r1; row++) cells.push({ row, field, raw: srcRaw })
    }
    onBulkApply(cells)
    clearSelection()
  }, [selBounds, onBulkApply, clearSelection, rates, formulas])

  const bulkClearBandsSelected = useCallback(() => {
    const b = selBounds()
    if (!b || !onBulkApply) return
    const cells: Array<{ row: number; field: WgField; raw: string }> = []
    for (let row = b.r0; row <= b.r1; row++) {
      for (const col of BAND_COL_INDICES) cells.push({ row, field: EDITABLE_FIELDS[col]!, raw: '' })
    }
    onBulkApply(cells)
    clearSelection()
  }, [selBounds, onBulkApply, clearSelection])

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

  // FK02-B / FR-2..5: ha a parent revert-et kér (megerősítő modal "Mégse"), a fókuszált cella
  // buffere visszaáll a PERZISZTÁLT értékre — különben a (nem törölt) activeCell miatt a beírt,
  // el nem mentett érték maradna láthatóan a cellában.
  useEffect(() => {
    if (revertSignal === 0 || !activeCell) return
    const r = rates[activeCell.row]
    const field = EDITABLE_FIELDS[activeCell.col]
    if (!r || !field) return
    const key = `${r.currencyId}.${field}`
    setBuffer(formulas[key] ?? r[field])
  // eslint-disable-next-line react-hooks/exhaustive-deps -- kizárólag a revert-jelzésre futunk
  }, [revertSignal])

  // 2026-04-29 v2.3.13 (Árfolyamkészítés zoom-fit): 17 valuta sor scrollozás nélkül.
  return (
    <div ref={containerRef} className="flex-1 bg-white rounded shadow-sm border overflow-hidden flex flex-col min-w-0">
      <div className="overflow-auto flex-1">
        <table className={`w-full text-xs border-collapse ${isDragging ? 'select-none' : ''}`}>
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
              {/* FK-04/C: oszlop-betűk (J–S) a fejlécben — a képletírás ezekre hivatkozik (pl. "L", "#02M", "!FEUR"). */}
              <th className="px-1 py-0 text-left w-14 border-r border-green-500"><span className="text-yellow-300 font-bold">J</span> MNB</th>
              <th className="px-1 py-0 w-4 border-r border-green-500"></th>
              <th className="px-1 py-0 w-10 border-r border-green-500 font-bold"><span className="text-yellow-300">K</span> {t('common.code')}</th>
              <th className="px-1 py-0 w-[72px] text-green-200 border-r border-green-500"><span className="text-yellow-300 font-bold">L</span> {t('rates.vet')}</th>
              <th className="px-1 py-0 w-[72px] text-red-200 border-r border-green-500"><span className="text-yellow-300 font-bold">M</span> {t('rates.elad')}</th>
              <th className="px-1 py-0 w-[72px] text-green-200 border-r border-green-500"><span className="text-yellow-300 font-bold">N</span> {t('rates.v')}</th>
              <th className="px-1 py-0 w-[72px] text-red-200 border-r border-green-500"><span className="text-yellow-300 font-bold">O</span> E-</th>
              <th className="px-1 py-0 w-[72px] text-green-200 border-r border-green-500"><span className="text-yellow-300 font-bold">P</span> {t('rates.v')}</th>
              <th className="px-1 py-0 w-[72px] text-red-200 border-r border-green-500"><span className="text-yellow-300 font-bold">Q</span> E-</th>
              <th className="px-1 py-0 w-[72px] text-green-200 border-r border-green-500"><span className="text-yellow-300 font-bold">R</span> {t('rates.vmax')}</th>
              <th className="px-1 py-0 w-[72px] text-red-200 border-r border-green-500"><span className="text-yellow-300 font-bold">S</span> {t('rates.emin')}</th>
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
                  {(() => {
                    const jKey = `${r.currencyId}.officialRate`
                    const jHasFormula = !!formulas[jKey]
                    const jErr = cellErrors[jKey]
                    const jActive = jRow === idx
                    const jDisplay = jActive ? jBuffer : (r.officialRate ? formatDecimal(r.officialRate, 2, 4) : '')
                    return (
                      <td className="px-0 py-0 text-right border-r relative">
                        <input
                          type="text"
                          value={jDisplay}
                          onFocus={() => { setJRow(idx); setJBuffer(formulas[jKey] ?? (r.officialRate ? String(r.officialRate) : '')) }}
                          onChange={e => setJBuffer(e.target.value)}
                          onBlur={() => { if (onCommitCell) onCommitCell(idx, 'officialRate', jBuffer); setJRow(null) }}
                          title={jHasFormula ? `Elszámoló (J) képlet: ${formulas[jKey]}${jErr ? ` — HIBA: ${jErr}` : ''}` : 'Elszámoló árfolyam (J) — felülírható; üres = a 0-s lap A oszlopa'}
                          className={`w-full px-0.5 py-0 text-right font-mono text-[11px] text-blue-800 font-bold border-0 bg-transparent focus:bg-blue-50 focus:outline-none ${jHasFormula && !jActive ? 'bg-indigo-50' : ''} ${jErr ? 'ring-2 ring-red-400 ring-inset' : ''}`}
                        />
                        {jHasFormula && !jActive && (
                          <span className="absolute left-0 top-0 text-[7px] text-indigo-500 font-bold pointer-events-none">ƒ</span>
                        )}
                      </td>
                    )
                  })()}
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
                    const selected = isCellSelected(idx, colIdx)
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
                      <td
                        key={field}
                        className={`px-0 py-0 border-r relative ${selected ? 'bg-blue-200/70 ring-1 ring-blue-400 ring-inset' : ''}`}
                        onMouseDown={e => onCellMouseDown(e, idx, colIdx)}
                        onMouseEnter={() => onCellMouseEnter(idx, colIdx)}
                        onMouseUp={e => onCellMouseUp(e, idx, colIdx)}
                      >
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

      {/* FK02-B / FR-6..10: lebegő toolbar a kijelölt tartomány mellett — kizárólag a kijelölésre hat. */}
      {toolbarPos && canEdit && selBounds() && (
        <div
          className="fixed z-50 flex gap-1 bg-white border border-gray-300 rounded-md shadow-lg p-1"
          style={{ top: toolbarPos.top, left: toolbarPos.left }}
          // a toolbaron belüli mousedown ne indítson új cella-kijelölést
          onMouseDown={e => e.stopPropagation()}
        >
          <button
            type="button"
            onClick={bulkFillDownSelected}
            className="flex items-center gap-1 px-1.5 py-1 rounded bg-amber-50 hover:bg-amber-100 text-amber-800 border border-amber-300 text-[10px] font-semibold"
            title="A kijelölés legfelső sorának értékét/képletét lemásolja oszloponként a kijelölt tartomány összes többi cellájába"
          >
            <ArrowDownToLine size={11} /> Lehúzás (mind)
          </button>
          <button
            type="button"
            onClick={bulkClearSelected}
            className="flex items-center gap-1 px-1.5 py-1 rounded bg-gray-50 hover:bg-gray-100 text-gray-700 border border-gray-300 text-[10px] font-semibold"
            title="A kijelölt cellák értékének/képletének kiürítése"
          >
            <Eraser size={11} /> Lehúzás (üres)
          </button>
          <button
            type="button"
            onClick={bulkClearBandsSelected}
            className="flex items-center gap-1 px-1.5 py-1 rounded bg-red-50 hover:bg-red-100 text-red-700 border border-red-300 text-[10px] font-semibold"
            title="A kijelölt sorok kedvezménysáv-oszlopainak (N–S) kiürítése; a fő vétel/eladás érintetlen"
          >
            <Trash2 size={11} /> Sávok törlése
          </button>
        </div>
      )}
    </div>
  )
}
