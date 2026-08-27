import { useCallback, useEffect, useState } from 'react'
import { AlertTriangle, ArrowDownToLine, Eraser, Trash2, Copy, RefreshCw } from 'lucide-react'
import { formatDecimal } from '../../../utils/numberFormat'
import { useGridNavigation } from '../../../hooks/useGridNavigation'
import type { WorkgroupDetailDTO } from '../../../services/api/index'
import { fmtAmount, parseNum, type EditableRate } from '../types'
import type { WgField } from '../workgroupSheetCompute'
import { replaceFormulaCurrency } from '../workgroupSheetFormula'
import { useTranslation } from 'react-i18next'
import i18n from '../../../i18n'

// FK03-fix (FR-6..8): a J (officialRate) a rács TELJES JOGÚ 0. oszlopa lett — a
// `useGridNavigation` rácson belül van (nyilas navigáció eléri, dupla kattintásra
// szerkeszthető, Escape revertál), a korábbi külön jBuffer/jRow útvonal megszűnt.
// A parent commit-útvonalai (RateCreationPage commitCell + applyBulkCells) az
// officialRate-et eddig is kezelték.
type GridField = WgField
const EDITABLE_FIELDS: GridField[] = [
  'officialRate',
  'buyRate',
  'sellRate',
  'limit1BuyRate',
  'limit1SellRate',
  'limit2BuyRate',
  'limit2SellRate',
  'limit3BuyRate',
  'limit3SellRate',
]

// FK02-B / FR-6..10: a kedvezménysáv-oszlopok indexei az EDITABLE_FIELDS-ben (N–S, azaz limit1–3
// vétel/eladás) — a „Sávok törlése" toolbar-művelet ezeket üríti, a fő L/M (buy/sell) érintetlenül.
// FK03-fix: a J beszúrása miatt az indexek +1-gyel tolódtak ([2..7] → [3..8]).
const BAND_COL_INDICES = [3, 4, 5, 6, 7, 8] as const

/**
 * FK03-fix: a cella perzisztált nyers értéke stringként — a J (`officialRate`)
 * number|null, az összes többi mező string; a buffer/másolás/lehúzás közös
 * útvonalai stringgel dolgoznak.
 */
function rawFieldValue(r: EditableRate, field: GridField): string {
  return field === 'officialRate'
    ? r.officialRate != null
      ? String(r.officialRate)
      : ''
    : r[field]
}

// FK02-E (FR-10 / NFR-3): megjelenítési tizedesek — JPY 4, minden más valuta 2 tizedes.
const decimalsForDisplay = (code: string): number => (code.toUpperCase() === 'JPY' ? 4 : 2)

/**
 * FK02-E (FR-10): egy fix (nem-fókuszált) cella megjelenítése a valuta tizedes-szabálya szerint.
 * A tárolt nyers értéket (string, magyar vagy pontos tizedes) számra alakítja, majd a megjelenítési
 * tizedesekre formázza. Üres marad üres. A fókuszált cellát a hívó a (teljes precizitású) bufferrel
 * mutatja, hogy a szerkesztés ne veszítsen pontosságot.
 */
function formatCellDisplay(raw: string, code: string): string {
  const t = raw.trim()
  if (t === '') return ''
  const dd = decimalsForDisplay(code)
  return formatDecimal(parseNum(t), dd, dd)
}

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
  /**
   * FK02-D (FR-9..13): cross-csoport másolás — a kijelölt cellák tartalmát (érték/képlet)
   * a parent (RateCreationPage) csempe-választóval más munkacsoport(ok)ba másolja.
   */
  onCopyToGroups?: (cells: Array<{ currencyId: number; field: WgField; raw: string }>) => void
  /** FK02-B: szerkesztési jog — a kijelölés-toolbar csak írásjoggal jelenik meg. */
  canEdit?: boolean
  /** Read-only backend előkészítő/javaslat lekérése az adott valutára. */
  onPrepareRate?: (rate: EditableRate) => void
  preparingCurrencyId?: number | null
  /**
   * FK02-E (FR-13, FR-14): a szétküldés (szinkron) AKTÍV idejére zárolja a táblázatot — egy
   * overlay blokkolja a szerkesztést és visszajelez. A zárolás KIZÁRÓLAG a szinkron műveletre
   * korlátozódik; annak befejeztével (publishing → false) azonnal feloldódik (a cellák szerkeszthetők).
   */
  syncing?: boolean
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
  onCopyToGroups,
  canEdit = true,
  onPrepareRate,
  preparingCurrencyId = null,
  syncing = false,
}: RateGridProps) {
  const { t } = useTranslation()
  // FK03-fix (FR-1, FR-2): editOnFocus=false — kattintás/nyilas navigáció csak KIJELÖL,
  // szerkesztő módba dupla kattintás / Enter / gépelés visz (Főlap-referencia viselkedés).
  const { containerRef, activeCell, editing, setEditing, isEscapingRef, getCellProps } =
    useGridNavigation({
      rows: rates.length,
      cols: EDITABLE_FIELDS.length,
      editOnFocus: false,
    })

  // FK-04/C szerkesztő-buffer: a fókuszált cella nyers szövege (képlet vagy szám). A többi
  // cella a `rates[field]` SZÁMÍTOTT értékét mutatja; a fókuszált cella SZERKESZTŐ MÓDBAN
  // a buffert, hogy a felhasználó a KÉPLETET lássa/szerkessze (0-s lap minta); kijelölt
  // (nem szerkesztő) állapotban a formázott értéket (FK03 FR-9). Commit blur/Enter-kor.
  // FK03-fix: a J (officialRate) korábbi külön jBuffer/jRow útvonala megszűnt — a J a
  // rács 0. oszlopaként ugyanezt a buffert használja.
  const [buffer, setBuffer] = useState('')

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

  const isCellSelected = useCallback(
    (row: number, col: number) => {
      const b = selBounds()
      return !!b && row >= b.r0 && row <= b.r1 && col >= b.c0 && col <= b.c1
    },
    [selBounds],
  )

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
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') clearSelection()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [clearSelection])

  // FR-HL-07 (hibalista): a kijelölt CELLATARTOMÁNY vágólapra másolása TSV-ként (tab-elválasztott
  // oszlop, sor-törés), így Excelbe/másik csoportba illeszthető. Egycellás kijelölésnél a natív
  // input-másolás marad (a böngésző Ctrl+C-je a fókuszált cella szövegét másolja).
  const copySelectedRange = useCallback(async (): Promise<boolean> => {
    const b = selBounds()
    if (!b) return false
    const lines: string[] = []
    for (let row = b.r0; row <= b.r1; row++) {
      const cells: string[] = []
      for (let col = b.c0; col <= b.c1; col++) {
        const field = EDITABLE_FIELDS[col]
        const r = rates[row]
        // FK03-fix: rawFieldValue — a J (number|null) is stringként másolódik.
        cells.push(field && r ? rawFieldValue(r, field) : '')
      }
      lines.push(cells.join('\t'))
    }
    try {
      await navigator.clipboard.writeText(lines.join('\n'))
      return true
    } catch {
      return false
    }
  }, [selBounds, rates])

  useEffect(() => {
    const onCopy = (e: KeyboardEvent) => {
      if (!(e.ctrlKey || e.metaKey) || (e.key !== 'c' && e.key !== 'C')) return
      // Copilot review: a globális handler NE térítse el a Ctrl+C-t, ha a fókusz a rácson KÍVÜL van
      // (pl. a felhasználó máshol másol szöveget, miközben egy korábbi rács-kijelölés még él).
      const focusInGrid = containerRef.current?.contains(document.activeElement) ?? false
      if (!focusInGrid) return
      const b = selBounds()
      // Csak TÖBB cellás tartománynál vesszük át; egycellásnál a natív input-másolás működik.
      if (b && (b.r0 !== b.r1 || b.c0 !== b.c1)) {
        e.preventDefault()
        void copySelectedRange()
      }
    }
    window.addEventListener('keydown', onCopy)
    return () => window.removeEventListener('keydown', onCopy)
  }, [selBounds, copySelectedRange, containerRef])

  const showToolbarIfMulti = useCallback(
    (start: GridCoord, end: GridCoord, clientX: number, clientY: number) => {
      const multi = start.row !== end.row || start.col !== end.col
      if (multi && canEdit) setToolbarPos({ top: clientY + 10, left: clientX + 10 })
      else {
        setSelStart(null)
        setSelEnd(null)
        setToolbarPos(null)
      }
    },
    [canEdit],
  )

  const onCellMouseDown = useCallback(
    (e: React.MouseEvent, row: number, col: number) => {
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
    },
    [selStart, showToolbarIfMulti],
  )

  const onCellMouseEnter = useCallback(
    (row: number, col: number) => {
      if (isDragging) setSelEnd({ row, col })
    },
    [isDragging],
  )

  const onCellMouseUp = useCallback(
    (e: React.MouseEvent, row: number, col: number) => {
      if (!isDragging) return
      setIsDragging(false)
      const start = selStart ?? { row, col }
      const end = { row, col }
      setSelEnd(end)
      showToolbarIfMulti(start, end, e.clientX, e.clientY)
    },
    [isDragging, selStart, showToolbarIfMulti],
  )

  // --- Toolbar műveletek (kizárólag a kijelölt tartományra hatnak) ---

  const bulkClearSelected = useCallback(() => {
    const b = selBounds()
    if (!b || !onBulkApply) return
    const cells: Array<{ row: number; field: WgField; raw: string }> = []
    for (let row = b.r0; row <= b.r1; row++) {
      for (let col = b.c0; col <= b.c1; col++)
        cells.push({ row, field: EDITABLE_FIELDS[col]!, raw: '' })
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
      const srcRaw = formulas[`${src.currencyId}.${field}`] ?? rawFieldValue(src, field)
      for (let row = b.r0 + 1; row <= b.r1; row++) {
        // FK02-D (FR-1..4): relatív valutakód-csere — a `!<oszlop><KÓD>` hivatkozás kódja a
        // célsor valutájára cserélődik, ha megegyezik a forrássor valutájával (TBD-4).
        const tgt = rates[row]
        const raw =
          tgt && typeof srcRaw === 'string'
            ? replaceFormulaCurrency(srcRaw, src.currencyCode, tgt.currencyCode)
            : srcRaw
        cells.push({ row, field, raw })
      }
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

  // FK02-D (FR-9..13): a kijelölt cellák átadása a parentnek cross-csoport másoláshoz.
  // A tartalom: a KÉPLET (ha van), különben a megjelenített fix érték. A kijelölést NEM
  // töröljük (a felhasználó a csempe-választó modalban dönt; mégse esetén marad a kijelölés).
  const copyToGroupsSelected = useCallback(() => {
    const b = selBounds()
    if (!b || !onCopyToGroups) return
    const cells: Array<{ currencyId: number; field: WgField; raw: string }> = []
    for (let row = b.r0; row <= b.r1; row++) {
      const r = rates[row]
      if (!r) continue
      for (let col = b.c0; col <= b.c1; col++) {
        const field = EDITABLE_FIELDS[col]!
        const raw = formulas[`${r.currencyId}.${field}`] ?? rawFieldValue(r, field)
        cells.push({ currencyId: r.currencyId, field, raw })
      }
    }
    onCopyToGroups(cells)
  }, [selBounds, onCopyToGroups, rates, formulas])

  // Buffer seed: a fókuszált cellába a képlet-string (ha van), egyébként a megjelenített érték.
  useEffect(() => {
    if (!activeCell) return
    const r = rates[activeCell.row]
    const field = EDITABLE_FIELDS[activeCell.col]
    if (!r || !field) return
    const key = `${r.currencyId}.${field}`
    setBuffer(formulas[key] ?? rawFieldValue(r, field))
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
    setBuffer(formulas[key] ?? rawFieldValue(r, field))
    // eslint-disable-next-line react-hooks/exhaustive-deps -- kizárólag a revert-jelzésre futunk
  }, [revertSignal])

  // FK02-B (Copilot): a `select-none` CSAK több-cellás tartomány-drag alatt aktív — egy cellán belüli
  // egér-drag (input-szöveg kijelölése) így nem tiltott. Egycellás (selStart==selEnd) drag esetén nincs.
  const isRangeDrag =
    isDragging &&
    !!selStart &&
    !!selEnd &&
    (selStart.row !== selEnd.row || selStart.col !== selEnd.col)

  // 2026-04-29 v2.3.13 (Árfolyamkészítés zoom-fit): 17 valuta sor scrollozás nélkül.
  return (
    <div
      ref={containerRef}
      className="relative flex-1 bg-white rounded shadow-sm border overflow-hidden flex flex-col min-w-0"
    >
      {/* FK02-E (FR-14): a szétküldés (szinkron) idejére zároló overlay — blokkolja a szerkesztést
          és egyértelmű visszajelzést ad. A szinkron befejeztével (FR-13) azonnal eltűnik. */}
      {syncing && (
        <div className="absolute inset-0 z-40 bg-white/60 backdrop-blur-[1px] flex items-center justify-center">
          <div className="flex items-center gap-2 bg-blue-700 text-white px-4 py-2 rounded-md shadow-lg text-sm font-semibold">
            <RefreshCw size={16} className="animate-spin" />
            {i18n.t('literals.szinkronizalas-folyamatban-kerjuk-varjon')}
          </div>
        </div>
      )}
      <div className="overflow-auto flex-1">
        <table className={`w-full text-xs border-collapse ${isRangeDrag ? 'select-none' : ''}`}>
          <thead className="sticky top-0 z-20">
            <tr className="bg-green-800 text-white text-[10px] leading-none">
              <th colSpan={2} className="px-1 py-0 text-left border-r border-green-600">
                {t('rates.elszArf')}
              </th>
              <th className="px-1 py-0 border-r border-green-600">{t('common.currency')}</th>
              { }
              <th colSpan={2} className="px-1 py-0 border-r border-green-600 text-center">
                {i18n.t('literals.0')}
                {fmtAmount(selectedWg?.limit1Boundary)}
              </th>
              <th colSpan={2} className="px-1 py-0 border-r border-green-600 text-center">
                {fmtAmount(selectedWg?.limit1Boundary)}
                {i18n.t('literals.lit-17')}
                {fmtAmount(selectedWg?.limit2Boundary)}
              </th>
              <th colSpan={2} className="px-1 py-0 border-r border-green-600 text-center">
                {fmtAmount(selectedWg?.limit2Boundary)}
                {i18n.t('literals.lit-17')}
                {fmtAmount(selectedWg?.limit3Boundary)}
              </th>
              <th colSpan={2} className="px-1 py-0 text-center border-r border-green-600">
                {t('rates.sajatHat')}
              </th>
              <th className="px-1 py-0 text-center w-28">{t('rates.ellenorzes')}</th>
            </tr>
            <tr className="bg-green-700 text-white text-[10px] leading-none">
              {/* FK-04/C: oszlop-betűk (J–S) a fejlécben — a képletírás ezekre hivatkozik (pl. "L", "#02M", "!FEUR"). */}
              <th className="px-1 py-0 text-left w-16 border-r border-green-500">
                <span className="text-yellow-300 font-bold">{i18n.t('literals.j')}</span>
                {i18n.t('literals.mnb-2')}
              </th>
              <th className="px-1 py-0 w-4 border-r border-green-500"></th>
              <th className="px-1 py-0 w-12 border-r border-green-500 font-bold">
                <span className="text-yellow-300">{i18n.t('literals.k')}</span> {t('common.code')}
              </th>
              <th className="px-1 py-0 w-[86px] text-green-200 border-r border-green-500">
                <span className="text-yellow-300 font-bold">{i18n.t('literals.l')}</span>{' '}
                {t('rates.vet')}
              </th>
              <th className="px-1 py-0 w-[86px] text-red-200 border-r border-green-500">
                <span className="text-yellow-300 font-bold">{i18n.t('literals.m')}</span>{' '}
                {t('rates.elad')}
              </th>
              <th className="px-1 py-0 w-[86px] text-green-200 border-r border-green-500">
                <span className="text-yellow-300 font-bold">{i18n.t('literals.n')}</span>{' '}
                {t('rates.v')}
              </th>
              <th className="px-1 py-0 w-[86px] text-red-200 border-r border-green-500">
                <span className="text-yellow-300 font-bold">{i18n.t('literals.o')}</span>
                {i18n.t('literals.e-4')}
              </th>
              <th className="px-1 py-0 w-[86px] text-green-200 border-r border-green-500">
                <span className="text-yellow-300 font-bold">{i18n.t('literals.p')}</span>{' '}
                {t('rates.v')}
              </th>
              <th className="px-1 py-0 w-[86px] text-red-200 border-r border-green-500">
                <span className="text-yellow-300 font-bold">{i18n.t('literals.q')}</span>
                {i18n.t('literals.e-4')}
              </th>
              <th className="px-1 py-0 w-[86px] text-green-200 border-r border-green-500">
                <span className="text-yellow-300 font-bold">{i18n.t('literals.r')}</span>{' '}
                {t('rates.vmax')}
              </th>
              <th className="px-1 py-0 w-[86px] text-red-200 border-r border-green-500">
                <span className="text-yellow-300 font-bold">{i18n.t('literals.s-2')}</span>{' '}
                {t('rates.emin')}
              </th>
              <th className="px-1 py-0 text-yellow-200">{t('common.error')}</th>
            </tr>
          </thead>
          {/* FK02-E (FR-11): nagyobb, olvashatóbb cella-betűméret (~+20%). A táblázat scrollozható
              (overflow-auto), így a megnövelt méret nem töri a layoutot. */}
          <tbody className="text-[12.5px] leading-tight">
            {rates.map((r, idx) => {
              const buy = parseNum(r.buyRate)
              const sell = parseNum(r.sellRate)
              const isInvalid = buy > 0 && sell > 0 && buy >= sell
              const rowBg = r.modified
                ? 'bg-yellow-50'
                : !r.hasRate
                  ? 'bg-gray-50'
                  : idx % 2 === 0
                    ? 'bg-white'
                    : 'bg-gray-50'

              // FK03-fix: a sor-szintű cella-render — a J (officialRate, colIdx=0) a többi
              // oszloppal AZONOS útvonalon megy (kijelölés/szerkesztés/Escape/commit),
              // csak a megjelenítése és a stílusa tér el.
              const renderCell = (field: GridField, colIdx: number) => {
                const isJ = field === 'officialRate'
                const isBuy = field.includes('Buy') || field === 'buyRate'
                const colorClass = isJ ? 'text-blue-800' : isBuy ? 'text-green-700' : 'text-red-700'
                const focusBg = isJ
                  ? 'focus:bg-blue-50'
                  : isBuy
                    ? 'focus:bg-green-50'
                    : 'focus:bg-red-50'
                const isActive = activeCell?.row === idx && activeCell?.col === colIdx
                // FK03-fix (FR-3, FR-9): kijelölt állapotban a FORMÁZOTT érték látszik;
                // a buffert (képlet/nyers) csak SZERKESZTŐ módban mutatjuk.
                const isEditingCell = isActive && editing
                const activeBorder = isActive ? 'ring-2 ring-blue-500 ring-inset' : ''
                const selected = isCellSelected(idx, colIdx)
                const key = `${r.currencyId}.${field}`
                const hasFormula = !!formulas[key]
                const cellError = cellErrors[key]
                // FK02-E (FR-10): megjelenítés a valuta tizedes-szabálya szerint (JPY 4, többi 2);
                // a J-nél a number|null mező formázása (Copilot: null-ellenőrzés, a 0 is érték).
                const jDd = decimalsForDisplay(r.currencyCode)
                const display = isEditingCell
                  ? buffer
                  : isJ
                    ? r.officialRate != null
                      ? formatDecimal(r.officialRate, jDd, jDd)
                      : ''
                    : formatCellDisplay(rawFieldValue(r, field), r.currencyCode)
                const formulaBg = hasFormula && !isEditingCell ? 'bg-indigo-50' : ''
                const errorRing = cellError ? 'ring-2 ring-red-400 ring-inset' : ''
                const commit = (raw: string) => {
                  if (onCommitCell) onCommitCell(idx, field, raw)
                  else updateRate(idx, field, raw) // visszafelé-kompatibilis fallback
                }
                const title = isJ
                  ? hasFormula
                    ? `Elszámoló (J) képlet: ${formulas[key]}${cellError ? ` — HIBA: ${cellError}` : ''}`
                    : 'Elszámoló árfolyam (J) — felülírható; üres = a 0-s lap A oszlopa'
                  : hasFormula
                    ? `Képlet: ${formulas[key]}${cellError ? ` — HIBA: ${cellError}` : ''}`
                    : cellError
                return (
                  <td
                    key={field}
                    className={`px-0 py-0 border-r relative ${selected ? 'bg-blue-200/70 ring-1 ring-blue-400 ring-inset' : ''}`}
                    onMouseDown={(e) => onCellMouseDown(e, idx, colIdx)}
                    onMouseEnter={() => onCellMouseEnter(idx, colIdx)}
                    onMouseUp={(e) => onCellMouseUp(e, idx, colIdx)}
                  >
                    <input
                      type="text"
                      value={display}
                      {...getCellProps(idx, colIdx)}
                      // FK03-fix (FR-3, FR-7): dupla kattintás → szerkesztő mód (a képlet látszik).
                      onDoubleClick={() => {
                        if (isActive) setEditing(true)
                      }}
                      onChange={(e) => {
                        // Megj.: szándékosan NEM kapuzzuk `editing`-re — gépelésnél a hook
                        // keydown-kezelője állítja a szerkesztő módot, de az onChange még az
                        // újrarender ELŐTT fut (az első karakter különben elveszne).
                        if (isActive) setBuffer(e.target.value)
                        else if (!onCommitCell) updateRate(idx, field, e.target.value)
                      }}
                      onBlur={() => {
                        if (!isActive) return
                        // FK03-fix (FR-5, FR-8): Escape-blur → revert, commit NÉLKÜL. TBD-2
                        // döntés: az Escape a commit ELŐTT történik, a perzisztált állapot
                        // változatlan — a lokális buffer-reset elég, parent-revert
                        // (rateRevertSignal) nem szükséges.
                        if (isEscapingRef.current) {
                          isEscapingRef.current = false
                          setBuffer(formulas[key] ?? rawFieldValue(r, field))
                          return
                        }
                        // Kijelölt (nem szerkesztő) állapotból távozva nincs mit commitolni.
                        // Copilot #1112: commit után KILÉPÜNK a szerkesztő módból — különben a
                        // fókuszát vesztett cella továbbra is a nyers buffert mutatná.
                        if (editing) {
                          commit(buffer)
                          setEditing(false)
                        }
                      }}
                      title={title}
                      className={`w-full px-0.5 py-0.5 text-right font-mono text-[13px] ${colorClass} font-bold border-0 bg-transparent ${focusBg} focus:outline-none ${activeBorder} ${formulaBg} ${errorRing}`}
                    />
                    {hasFormula && !isEditingCell && (
                      <span
                        className={`absolute ${isJ ? 'left-0' : 'left-0.5'} top-0 text-[7px] text-indigo-500 font-bold pointer-events-none`}
                        title={`Képlet: ${formulas[key]}`}
                      >
                        {i18n.t('literals.lit-50')}
                      </span>
                    )}
                  </td>
                )
              }

              return (
                <tr
                  key={r.currencyId}
                  className={`${rowBg} border-b border-gray-100 hover:bg-blue-50/30`}
                >
                  {renderCell('officialRate', 0)}
                  <td className="px-0 py-0 text-center border-r w-4">
                    {r.modified && (
                      <span className="inline-block w-1.5 h-1.5 rounded-full bg-orange-400" />
                    )}
                    {isInvalid && <AlertTriangle size={9} className="text-red-500 inline" />}
                  </td>
                  <td className="px-1 py-0 text-center font-bold text-blue-700 border-r text-[12.5px]">
                    {r.currencyCode}
                  </td>
                  {EDITABLE_FIELDS.slice(1).map((field, i) => renderCell(field, i + 1))}
                  <td className="px-1 py-0 text-[9px]">
                    {onPrepareRate && (
                      <button
                        type="button"
                        data-testid={`rate-prepare-${r.currencyId}`}
                        onClick={() => onPrepareRate(r)}
                        disabled={preparingCurrencyId === r.currencyId}
                        className="mb-0.5 rounded border border-blue-200 bg-blue-50 px-1 py-0.5 text-[9px] font-semibold text-blue-700 hover:bg-blue-100 disabled:opacity-60"
                        title={`${r.currencyCode} backend árfolyam-előkészítés és ajánlás lekérése`}
                      >
                        {preparingCurrencyId === r.currencyId ? 'Betöltés...' : 'Javaslat'}
                      </button>
                    )}
                    {validationErrors[r.currencyId]?.map((err, ei) => (
                      <div key={ei} className="text-red-600 flex items-center gap-0.5">
                        <AlertTriangle size={8} className="flex-shrink-0" />
                        {err}
                      </div>
                    ))}
                    {!validationErrors[r.currencyId] && r.hasRate && (
                       
                      <span className="text-green-600">{i18n.t('literals.lit-6')}</span>
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
          onMouseDown={(e) => e.stopPropagation()}
        >
          <button
            type="button"
            onClick={bulkFillDownSelected}
            className="flex items-center gap-1 px-1.5 py-1 rounded bg-amber-50 hover:bg-amber-100 text-amber-800 border border-amber-300 text-[10px] font-semibold"
            title="A kijelölés legfelső sorának értékét/képletét lemásolja oszloponként a kijelölt tartomány összes többi cellájába"
          >
            <ArrowDownToLine size={11} />
            {i18n.t('literals.lehuzas-mind-2')}
          </button>
          <button
            type="button"
            onClick={bulkClearSelected}
            className="flex items-center gap-1 px-1.5 py-1 rounded bg-gray-50 hover:bg-gray-100 text-gray-700 border border-gray-300 text-[10px] font-semibold"
            title="A kijelölt cellák értékének/képletének KIÜRÍTÉSE (a cellák üresre állnak)"
          >
            <Eraser size={11} />
            {i18n.t('literals.urites-2')}
          </button>
          {onCopyToGroups && (
            <button
              type="button"
              onClick={copyToGroupsSelected}
              className="flex items-center gap-1 px-1.5 py-1 rounded bg-sky-50 hover:bg-sky-100 text-sky-800 border border-sky-300 text-[10px] font-semibold"
              title="A kijelölt cellák tartalmának (érték vagy képlet) másolása más munkacsoport(ok) azonos pozícióiba"
            >
              <Copy size={11} />
              {i18n.t('literals.masolas-mas-csoportba')}
            </button>
          )}
          <button
            type="button"
            onClick={bulkClearBandsSelected}
            className="flex items-center gap-1 px-1.5 py-1 rounded bg-red-50 hover:bg-red-100 text-red-700 border border-red-300 text-[10px] font-semibold"
            title="A kijelölt sorok kedvezménysáv-oszlopainak (N–S) kiürítése; a fő vétel/eladás érintetlen"
          >
            <Trash2 size={11} />
            {i18n.t('literals.savok-torlese-2')}
          </button>
        </div>
      )}
    </div>
  )
}
