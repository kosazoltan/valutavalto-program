import { useState, useEffect, useCallback, useMemo, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { Send, LogOut, Globe, Save, ArrowRight, Info } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useAuthStore } from '../../stores/authStore'

/**
 * Főlap (0-s lap) — Árfolyamkészítő program ALAP felülete.
 *
 * Spec forrás: "Áfolyamkészítő program működése" (Kósa Zoltán, 2026-05-13).
 *
 * <p>A 0-s lap az elszámoló árfolyamok beállítására, valamint az alap vételi/eladási
 * árfolyamok meghatározására szolgál. Ez a lap NEM tartozik pénztárhoz. A pénztárak,
 * árképzésüktől függően, külön munkacsoportokba vannak elhelyezve.</p>
 *
 * <p>Oszlopok (A-I):
 * <ul>
 *   <li>A — Elszámoló árfolyam (4 főváluta kézzel: EUR/USD/GBP/CHF, többi képlettel)</li>
 *   <li>B — OTP segéd (vételi)</li>
 *   <li>C — Segéd</li>
 *   <li>D — Valuta nem (ISO kód, VÉDETT)</li>
 *   <li>E — Gyenge multis vétel</li>
 *   <li>F — Gyenge multis eladás</li>
 *   <li>G — EUR/USD keresztárfolyam alapú elszámoló (számolt)</li>
 *   <li>H — Kereszt árfolyam (forrás, EUR-tartozó CZK,PLN,RON,RSD,BGN,BAM,TRY; USD-tartozó ILS,UAH,RUB,CNY,THB,BRL,MXN,NZD)</li>
 *   <li>I — Nagybani (jelenleg nem használt)</li>
 * </ul></p>
 *
 * <p>Adatfolyam:
 * <ul>
 *   <li>A oszlop érték → minden munkacsoport J oszlopába (Elszámoló) örökítve</li>
 *   <li>E/F oszlop → bizonyos munkacsoportok L/M oszlop képlet alapja</li>
 *   <li>G oszlop → automatikusan az A oszlopba kerülhet (kereszt-képletes valuták)</li>
 * </ul></p>
 *
 * <p><b>Phase 1 (MVP):</b> client-side state + localStorage perzisztencia.
 * Phase 2: backend persistence + reaktív data flow munkacsoportokhoz.</p>
 */

interface MainRateRow {
  currency: string         // D oszlop (VÉDETT)
  settlement: number       // A oszlop (Elszámoló)
  otp: number              // B oszlop (OTP segéd)
  helper: number           // C oszlop (Segéd)
  weakMultiBuy: number     // E oszlop (Gyenge multis vétel)
  weakMultiSell: number    // F oszlop (Gyenge multis eladás)
  crossSettlement: number  // G oszlop (EUR/USD kereszt alapú elszámoló — számolt)
  crossRate: number        // H oszlop (kereszt forrás, 6 tizedes)
  wholesale: number        // I oszlop (Nagybani)
  crossBase: 'EUR' | 'USD' | null  // melyik főváluta a kereszt alapja (NULL ha nem kereszt)
}

// Default 19 valuta + EUA (eurázsiai egyezmény) per spec screenshot
const DEFAULT_CURRENCIES: Array<Pick<MainRateRow, 'currency' | 'crossBase'>> = [
  { currency: 'EUR', crossBase: null }, // főváluta
  { currency: 'USD', crossBase: null }, // főváluta
  { currency: 'GBP', crossBase: null }, // főváluta
  { currency: 'CHF', crossBase: null }, // főváluta
  { currency: 'AUD', crossBase: null }, // OTP-ből (B oszlop)
  { currency: 'CAD', crossBase: null }, // OTP-ből (B oszlop)
  { currency: 'DKK', crossBase: null },
  { currency: 'JPY', crossBase: null }, // 3 tizedes
  { currency: 'NOK', crossBase: null },
  { currency: 'SEK', crossBase: null },
  { currency: 'CZK', crossBase: 'EUR' },
  { currency: 'HRK', crossBase: null },
  { currency: 'PLN', crossBase: 'EUR' },
  { currency: 'RON', crossBase: 'EUR' },
  { currency: 'RSD', crossBase: 'EUR' },
  { currency: 'BGN', crossBase: 'EUR' },
  { currency: 'ILS', crossBase: 'USD' },
  { currency: 'UAH', crossBase: 'USD' },
  { currency: 'RUB', crossBase: 'USD' },
  { currency: 'EUA', crossBase: null }, // Eurázsiai egyezmény (spec szerint)
  { currency: 'TRY', crossBase: 'EUR' },
  { currency: 'CNY', crossBase: 'USD' },
  { currency: 'BAM', crossBase: 'EUR' },
  { currency: 'THB', crossBase: 'USD' },
  { currency: 'BRL', crossBase: 'USD' },
  { currency: 'MXN', crossBase: 'USD' },
  { currency: 'NZD', crossBase: 'USD' },
  { currency: 'RCH', crossBase: null },
]

const STORAGE_KEY = 'arfolyamkeszito.mainSheet.v1'

const emptyRow = (currency: string, crossBase: MainRateRow['crossBase']): MainRateRow => ({
  currency,
  settlement: 0,
  otp: 0,
  helper: 0,
  weakMultiBuy: 0,
  weakMultiSell: 0,
  crossSettlement: 0,
  crossRate: 0,
  wholesale: 0,
  crossBase,
})

function loadFromStorage(): MainRateRow[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return DEFAULT_CURRENCIES.map(c => emptyRow(c.currency, c.crossBase))
    const parsed = JSON.parse(raw) as MainRateRow[]
    // Defensive: ha új valuta jött a default listába, hozzáadjuk
    const existingCurrencies = new Set(parsed.map(r => r.currency))
    for (const def of DEFAULT_CURRENCIES) {
      if (!existingCurrencies.has(def.currency)) {
        parsed.push(emptyRow(def.currency, def.crossBase))
      }
    }
    return parsed
  } catch (e) {
    logger.error('MainRateSheetPage', 'Storage load failed', e)
    return DEFAULT_CURRENCIES.map(c => emptyRow(c.currency, c.crossBase))
  }
}

/**
 * G oszlop számítás: kereszt árfolyam alapú elszámoló.
 *
 * <p>Példa CZK: H oszlop / EUR A oszlop értéke (ezzel ha az EUR elszámoló változik,
 * a CZK G oszlopa követi a változást, és onnan az A-ba kerül).</p>
 */
function computeCrossSettlement(row: MainRateRow, eurSettlement: number, usdSettlement: number): number {
  if (!row.crossBase || !row.crossRate) return 0
  const base = row.crossBase === 'EUR' ? eurSettlement : usdSettlement
  if (!base) return 0
  // Spec: A oszlop = H oszlop / A oszlop EUR (vagy USD) értéke
  // Pontosabban: a base elszámoló * 1 egység más-valuta = base / crossRate
  // Pl. EUR=400, EUR/CZK kereszt = 24.5 → CZK A = 400/24.5 = 16.32
  return base / row.crossRate
}

export default function MainRateSheetPage() {
  const navigate = useNavigate()
  const isLocalRateMakerApp = import.meta.env.VITE_APP_FLAVOR === 'rate-maker'
  const canEdit = useAuthStore((state) =>
    isLocalRateMakerApp && (state.hasRole('ADMIN') || state.hasCanonicalRole(['foertektar', 'ugyvezeto', 'admin'])),
  )
  const [rows, setRows] = useState<MainRateRow[]>(() => loadFromStorage())
  const [dirty, setDirty] = useState(false)
  const [activeCell, setActiveCell] = useState<{ rowIdx: number; col: keyof MainRateRow } | null>(null)
  // Codex P1 #581 fix: editBuffer őrzi a felhasználó RAW input-ját az aktív cella szerkesztésekor.
  // Anélkül a parseFloat minden billentyűzéskor felülírná a megjelenített értéket — pl. nem tudna
  // beírni "3." vagy "3,5"-öt, mert parsed=3 vs raw="3." különbözik. Csak blur-on commitálunk.
  const [editBuffer, setEditBuffer] = useState<string>('')
  const [showHelp, setShowHelp] = useState(false)
  const [publishing, setPublishing] = useState(false)
  const lastSavedAt = useRef<string | null>(null)

  // Computed cross settlement for G column
  const eurRow = useMemo(() => rows.find(r => r.currency === 'EUR'), [rows])
  const usdRow = useMemo(() => rows.find(r => r.currency === 'USD'), [rows])
  const eurSettlement = eurRow?.settlement ?? 0
  const usdSettlement = usdRow?.settlement ?? 0

  // Codex P1 #581 fix: A oszlop érték crossBase-row-okra automatikusan a G oszlopból
  // (computeCrossSettlement) — spec szerint "A többi valuta elszámoló árfolyama a 'G'
  // oszlopban szereplő érték (képletes számítással)". A user által beállított settlement
  // értéket figyelmen kívül hagyjuk crossBase row esetén.
  const enrichedRows = useMemo<MainRateRow[]>(() => {
    return rows.map((r) => {
      const computedG = r.crossBase ? computeCrossSettlement(r, eurSettlement, usdSettlement) : 0
      return {
        ...r,
        crossSettlement: computedG,
        // A column auto-derive cross-base row-okra (spec §3 "G oszlop értékei módosítás nélkül A-ba kerülnek")
        settlement: r.crossBase ? computedG : r.settlement,
      }
    })
  }, [rows, eurSettlement, usdSettlement])

  // Codex P1 #581 fix: A column for crossBase rows is DERIVED, NOT user-editable.
  // Spec: "A többi valuta elszámoló árfolyama a 'G' oszlopban szereplő érték (képletes számítással)."
  // → Settlement column read-only ha crossBase != null. A renderelés `aIsAuto = !!row.crossBase`
  //   alapján dönt span vs. input között a render-loop-ban.

  // Codex P1 #581 fix: commit only on blur with parsed value (preserve raw input while typing).
  // Codex P2 #581 iter-3 fix: skip marking dirty if value unchanged (no-op).
  const commitCell = useCallback((rowIdx: number, col: keyof MainRateRow, raw: string) => {
    if (!canEdit) return
    if (col === 'currency' || col === 'crossBase' || col === 'crossSettlement') return
    if (col === 'settlement' && rows[rowIdx]?.crossBase) return
    const trimmed = raw.trim()
    let nextValue: number
    if (trimmed === '') {
      nextValue = 0
    } else {
      const parsed = Number.parseFloat(trimmed.replace(/\s/g, '').replace(',', '.'))
      if (Number.isNaN(parsed)) return
      nextValue = parsed
    }
    const currentValue = rows[rowIdx]?.[col]
    if (typeof currentValue === 'number' && currentValue === nextValue) {
      // Codex P2 #581: no-op — value unchanged, NE marka dirty-nek.
      return
    }
    setRows(prev => {
      const next = [...prev]
      next[rowIdx] = { ...next[rowIdx]!, [col]: nextValue }
      return next
    })
    setDirty(true)
  }, [canEdit, rows])

  const focusCell = useCallback((rowIdx: number, col: keyof MainRateRow, currentValue: number, decimals: number) => {
    setActiveCell({ rowIdx, col })
    setEditBuffer(currentValue ? currentValue.toFixed(decimals) : '')
  }, [])

  const blurCell = useCallback((rowIdx: number, col: keyof MainRateRow) => {
    commitCell(rowIdx, col, editBuffer)
    setActiveCell(null)
    setEditBuffer('')
  }, [commitCell, editBuffer])

  // Codex P1 #581 iter-3 fix: ha a user beír egy cellába és AZONNAL kattint a Mentés/Szétküldés
  // gombra (mielőtt blur futna), az editBuffer még NEM commitált. Ezért minden olyan akció előtt
  // ami a rows-t mentésre küldi, először a aktív cella editBuffer-ét commitálni kell.
  const flushActiveCell = useCallback(() => {
    if (activeCell) {
      commitCell(activeCell.rowIdx, activeCell.col, editBuffer)
      setActiveCell(null)
      setEditBuffer('')
    }
  }, [activeCell, commitCell, editBuffer])

  const saveLocally = useCallback(() => {
    // Codex P1 #581 iter-3: aktív cella editBuffer-ét commitalni mentés előtt.
    flushActiveCell()
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(rows))
      lastSavedAt.current = new Date().toISOString()
      setDirty(false)
      toast.success('Mentve', 'Főlap helyileg mentve (localStorage)')
    } catch (e) {
      logger.error('MainRateSheetPage', 'Storage save failed', e)
      toast.error('Hiba', 'Helyi mentés sikertelen')
    }
  }, [rows, flushActiveCell])

  // Auto-save on dirty + 1 sec debounce
  useEffect(() => {
    if (!dirty) return
    const timer = setTimeout(() => {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(rows))
        lastSavedAt.current = new Date().toISOString()
        setDirty(false)
      } catch (e) {
        logger.error('MainRateSheetPage', 'Auto-save failed', e)
      }
    }, 1000)
    return () => clearTimeout(timer)
  }, [dirty, rows])

  const dispatchToServer = useCallback(async () => {
    if (!canEdit) {
      toast.warning('Olvasás-csak', 'Csak főértéktáros / ügyvezető küldhet ki árfolyamot')
      return
    }
    // Codex P1 #581 iter-3: aktív cella editBuffer-ét commitalni szétküldés előtt.
    flushActiveCell()
    setPublishing(true)
    try {
      // Phase 2: backend POST /api/v1/rates/main-sheet/publish
      // Most csak helyileg mentünk + szimulált siker
      saveLocally()
      await new Promise(r => setTimeout(r, 800))
      toast.success('Szétküldve', 'Főlap árfolyamok szétküldve (Phase 1: lokális mentés)')
    } catch (e) {
      logger.error('MainRateSheetPage', 'Dispatch failed', e)
      toast.error('Hiba', 'Szerverre küldés sikertelen')
    } finally {
      setPublishing(false)
    }
  }, [canEdit, saveLocally, flushActiveCell])

  const formatCell = (val: number, decimals = 2): string => {
    if (!val || val === 0) return '0'
    return val.toFixed(decimals)
  }

  const isJpy = (currency: string) => currency === 'JPY'

  return (
    <div className="h-[calc(100vh-8rem)] flex flex-col bg-slate-50">
      {/* === HEADER === */}
      <div className="flex items-center justify-between bg-white px-4 py-2 border-b border-slate-200 shadow-sm">
        <div className="flex items-center gap-3">
          <h1 className="text-base font-bold text-slate-900">Főlap — Elszámoló árfolyamok</h1>
          <span className="text-xs text-slate-500 px-2 py-0.5 bg-slate-100 rounded">0-s lap (Alap)</span>
          {dirty && <span className="text-xs text-orange-600 font-medium">● módosítva</span>}
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowHelp(true)}
            className="flex items-center gap-1 px-2 py-1 text-xs border border-slate-300 rounded hover:bg-slate-100"
            title="Kitöltési segítség"
          >
            <Info size={13} /> Segítség
          </button>
          <button
            onClick={saveLocally}
            disabled={!dirty || !canEdit}
            className="flex items-center gap-1 px-2 py-1 text-xs border border-slate-300 rounded hover:bg-slate-100 disabled:opacity-40"
          >
            <Save size={13} /> Mentés
          </button>
        </div>
      </div>

      {/* === MENU BAR (felső sor menüpontok) === */}
      <div className="flex items-center gap-1 bg-slate-200 border-b border-slate-300 px-2 py-1">
        <button
          onClick={() => navigate('/rates/groups')}
          className="px-3 py-1 text-xs font-medium bg-white border border-slate-400 rounded hover:bg-slate-50 flex items-center gap-1"
        >
          <ArrowRight size={12} /> CSOPORTOK KARBANTARTÁSA
        </button>
        <button
          onClick={() => void dispatchToServer()}
          disabled={publishing || !canEdit}
          className="px-3 py-1 text-xs font-medium bg-green-600 text-white border border-green-700 rounded hover:bg-green-700 disabled:opacity-40 flex items-center gap-1"
        >
          <Send size={12} /> ÁRFOLYAMOK SZÉTKÜLDÉSE
        </button>
        <button
          onClick={() => toast.info('Internet címek', 'Phase 2: Internet linkek karbantartása')}
          className="px-3 py-1 text-xs font-medium bg-white border border-slate-400 rounded hover:bg-slate-50 flex items-center gap-1"
        >
          <Globe size={12} /> INTERNET CÍMEK KARBANTARTÁSA
        </button>
        <div className="flex-1" />
        <button
          onClick={() => {
            if (dirty && !confirm('Vannak nem mentett módosítások. Biztosan kilépsz?')) return
            window.close()
          }}
          className="px-3 py-1 text-xs font-medium bg-white border border-slate-400 rounded hover:bg-red-50 hover:border-red-300 flex items-center gap-1"
        >
          <LogOut size={12} /> KILÉPÉS
        </button>
      </div>

      {/* === RATE TABLE === */}
      <div className="flex-1 overflow-auto px-2 py-2">
        <table className="w-full text-xs border-collapse bg-white shadow-sm rounded overflow-hidden">
          <thead className="sticky top-0 bg-slate-200 border-b-2 border-slate-400">
            <tr className="text-[10px] uppercase font-bold text-slate-700">
              <th className="border border-slate-300 px-2 py-1 bg-orange-100" colSpan={1}>A — Elszámoló</th>
              <th className="border border-slate-300 px-2 py-1 bg-blue-50">B — OTP</th>
              <th className="border border-slate-300 px-2 py-1 bg-blue-50">C — Segéd</th>
              <th className="border border-slate-300 px-2 py-1 bg-slate-300">D — Valuta</th>
              <th className="border border-slate-300 px-2 py-1 bg-yellow-100" colSpan={2}>E-F — Gyenge multis (vét/elad)</th>
              <th className="border border-slate-300 px-2 py-1 bg-amber-50">G — Kereszt számolt</th>
              <th className="border border-slate-300 px-2 py-1 bg-pink-50">H — Kereszt forrás</th>
              <th className="border border-slate-300 px-2 py-1 bg-slate-100">I — Nagybani</th>
            </tr>
          </thead>
          <tbody>
            {enrichedRows.map((row, idx) => {
              const decimals = isJpy(row.currency) ? 3 : 2
              const aIsAuto = !!row.crossBase
              const isActive = (col: keyof MainRateRow) => activeCell?.rowIdx === idx && activeCell.col === col
              const cellClass = (col: keyof MainRateRow, baseClass: string) =>
                `${baseClass} ${isActive(col) ? 'ring-2 ring-blue-500' : ''}`
              // EditableInput closure: while focused, show editBuffer (raw user input);
              // when blurred, parse + commit. Codex P1 #581 fix.
              const renderInput = (col: keyof MainRateRow, currentVal: number, decimalsFor: number, classes: string, placeholder?: string) => (
                <input
                  type="text"
                  value={isActive(col) ? editBuffer : (currentVal ? currentVal.toFixed(decimalsFor) : '0')}
                  onChange={(e) => setEditBuffer(e.target.value)}
                  onFocus={() => focusCell(idx, col, currentVal, decimalsFor)}
                  onBlur={() => blurCell(idx, col)}
                  className={classes}
                  disabled={!canEdit}
                  placeholder={placeholder}
                />
              )
              return (
                <tr key={row.currency} className="hover:bg-slate-50">
                  {/* A — Elszámoló (piros, módosítható HA NEM cross-base) */}
                  <td className={cellClass('settlement', `border border-slate-300 px-2 py-1 text-right font-mono font-bold ${aIsAuto ? 'text-amber-700 bg-amber-50/40 italic' : 'text-red-700 bg-orange-50/50'}`)}>
                    {aIsAuto ? (
                      <span title="Auto-derived from G column (cross calculation)">
                        {formatCell(row.settlement, decimals)}
                      </span>
                    ) : renderInput('settlement', row.settlement, decimals, 'w-full bg-transparent text-right font-mono font-bold text-red-700 focus:outline-none')}
                  </td>
                  {/* B — OTP (kék segéd) */}
                  <td className={cellClass('otp', 'border border-slate-300 px-2 py-1 text-right font-mono text-blue-800 bg-blue-50/30')}>
                    {renderInput('otp', row.otp, decimals, 'w-full bg-transparent text-right font-mono text-blue-800 focus:outline-none')}
                  </td>
                  {/* C — Segéd (kék) */}
                  <td className={cellClass('helper', 'border border-slate-300 px-2 py-1 text-right font-mono text-blue-700 bg-blue-50/20')}>
                    {renderInput('helper', row.helper, decimals, 'w-full bg-transparent text-right font-mono text-blue-700 focus:outline-none')}
                  </td>
                  {/* D — Valuta (VÉDETT, fekete bold) */}
                  <td className="border border-slate-300 px-2 py-1 text-center font-mono font-bold text-slate-900 bg-slate-100">
                    {row.currency}
                  </td>
                  {/* E — Gyenge multis vétel (sárga) */}
                  <td className={cellClass('weakMultiBuy', 'border border-slate-300 px-2 py-1 text-right font-mono text-amber-900 bg-yellow-50')}>
                    {renderInput('weakMultiBuy', row.weakMultiBuy, decimals, 'w-full bg-transparent text-right font-mono text-amber-900 focus:outline-none')}
                  </td>
                  {/* F — Gyenge multis eladás (sárga) */}
                  <td className={cellClass('weakMultiSell', 'border border-slate-300 px-2 py-1 text-right font-mono text-amber-900 bg-yellow-50')}>
                    {renderInput('weakMultiSell', row.weakMultiSell, decimals, 'w-full bg-transparent text-right font-mono text-amber-900 focus:outline-none')}
                  </td>
                  {/* G — Kereszt számolt (read-only, barna) */}
                  <td className="border border-slate-300 px-2 py-1 text-right font-mono text-amber-700 bg-amber-50/40 italic">
                    {row.crossBase ? formatCell(row.crossSettlement, decimals) : '—'}
                  </td>
                  {/* H — Kereszt forrás (rózsa, 6 tizedes) — csak crossBase row */}
                  <td className={cellClass('crossRate', 'border border-slate-300 px-2 py-1 text-right font-mono text-pink-800 bg-pink-50/40')}>
                    {row.crossBase
                      ? renderInput('crossRate', row.crossRate, 6, 'w-full bg-transparent text-right font-mono text-pink-800 focus:outline-none', `${row.crossBase}/${row.currency}`)
                      : <span className="text-slate-400">—</span>}
                  </td>
                  {/* I — Nagybani (szürke, opcionális) */}
                  <td className={cellClass('wholesale', 'border border-slate-300 px-2 py-1 text-right font-mono text-slate-600 bg-slate-50')}>
                    {renderInput('wholesale', row.wholesale, decimals, 'w-full bg-transparent text-right font-mono text-slate-600 focus:outline-none')}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>

        {/* === LEGEND / INFO === */}
        <div className="mt-4 p-3 bg-white border border-slate-300 rounded text-xs text-slate-700 space-y-1">
          <div className="font-bold text-slate-900 mb-1">Oszlop magyarázatok:</div>
          <div><b>A — Elszámoló:</b> Itt állítjuk az elszámoló árfolyamokat. Minden munkalapon ugyanazok az értékek a J oszlopban. EUR/USD/GBP/CHF (4 főváluta) napközben kézzel állítva, többi képlettel.</div>
          <div><b>B — OTP:</b> OTP közzétett vételi árfolyamok (segédérték az alap vételi/eladási árfolyamok megállapítására). Forrás: <a href="https://www.otpbank.hu/portal/hu/Arfolyamok/OTP" target="_blank" rel="noopener noreferrer" className="text-blue-600 underline">otpbank.hu</a></div>
          <div><b>D — Valuta nem:</b> ISO kód (VÉDETT, nem módosítható).</div>
          <div><b>E-F — Gyenge multis árfolyamok:</b> Pár munkacsoportban módosítás nélkül áthívva, pár helyen képlet alapja.</div>
          <div><b>G — Kereszt számolt:</b> Az EUR/USD keresztárfolyam alapú elszámoló (számolt: A oszlop EUR vagy USD értéke / H oszlop érték). Pl. CZK A = EUR settlement / EUR/CZK kereszt. Read-only, automatikusan követi az A oszlop EUR/USD változását.</div>
          <div><b>H — Kereszt forrás:</b> Reggel/napközben beírt EUR vagy USD kereszt árfolyam (forrás: <a href="https://www.xe.com/currencyconverter/" target="_blank" rel="noopener noreferrer" className="text-blue-600 underline">xe.com</a>). Min. 6 tizedes pontosság. EUR-tartozó: CZK, PLN, RON, RSD, BGN, BAM, TRY. USD-tartozó: ILS, UAH, RUB, CNY, THB, BRL, MXN, NZD.</div>
          <div><b>I — Nagybani:</b> Jelenleg nem használt (Phase 2).</div>
          <div className="mt-2 text-slate-500"><b>Phase 1 (MVP):</b> Lokális mentés (localStorage). <b>Phase 2:</b> Backend persistence + reaktív adatfolyam munkacsoportokhoz (A → minden mcs J oszlopa).</div>
        </div>
      </div>

      {/* === HELP MODAL === */}
      {showHelp && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4" onClick={() => setShowHelp(false)}>
          <div className="bg-emerald-50 border-2 border-emerald-700 rounded-lg p-6 max-w-2xl w-full" onClick={(e) => e.stopPropagation()}>
            <h2 className="text-xl font-bold text-emerald-900 text-center mb-4">SEGÍTSÉG AZ ÁRFOLYAM SZERKESZTŐ PROGRAMHOZ</h2>
            <div className="bg-white border border-emerald-300 rounded p-3 mb-4">
              <div className="font-bold text-sm mb-2 text-center">FÜGGVÉNYEK KEZELÉSE</div>
              <table className="w-full text-xs">
                <tbody>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300 w-24">A — I</td><td className="py-1 px-2 italic">Azonos valutanem oszlopa az alap-árfolyam táblázatban (0-s lap)</td></tr>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300">J — Q</td><td className="py-1 px-2 italic">Azonos valutanem oszlopa az aktuális munkacsoportban</td></tr>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300">!Axxx</td><td className="py-1 px-2 italic">Más valutanem bármely oszlopa (A=oszlop, xxx=valutanem). Pl. !AEUR = A oszlop EUR sora</td></tr>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300">#CCA</td><td className="py-1 px-2 italic">Azonos valutanem egy másik csoportból (A=oszlop, xxx=valutanem)</td></tr>
                  <tr><td className="py-1 px-2 font-mono font-bold border-r border-slate-300">Műveletek</td><td className="py-1 px-2 italic">+ - * / és zárójel (a zárójel kötelező eltérő prioritású műveletek esetén)</td></tr>
                </tbody>
              </table>
            </div>
            <div className="bg-white border border-emerald-300 rounded p-3 mb-4 text-xs space-y-2">
              <div><b>Adatmásolás:</b> CTRL + bal egér gomb a másolandó terület első adatának kijelöléséhez (LILA KERET) → kijelölés befejezése bal egér gomb lenyomásával (ZÖLD KERET)</div>
              <div><b>Adatlehúzás:</b> Az alap-árfolyam táblán egy, a munkacsoportoknál több oszlop adata húzható le. (Phase 2)</div>
              <div><b>Felbukkanó menük:</b> jobb egér gomb (Phase 2)</div>
            </div>
            <div className="text-center">
              <button
                onClick={() => setShowHelp(false)}
                className="px-4 py-2 bg-emerald-700 text-white rounded hover:bg-emerald-800 font-medium"
              >
                Vissza a munkához
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
