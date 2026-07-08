import { useState } from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'

/**
 * FK (átadás-átvétel "Korábbi" fül): havi naptár, amelyen CSAK a bizonylatos napok
 * kattinthatók. A bizonylatos napok halmazát (`activeDates`, 'YYYY-MM-DD') a szülő
 * komponens számítja a meglévő lista-response `requestedDeliveryDate` értékeiből —
 * külön API hívás nélkül (NFR-3). A naptár alapból az aktuális (Europe/Budapest)
 * hónapot mutatja, előre/hátra lapozható (FR-6).
 */
interface ShipmentCalendarPanelProps {
  /** Bizonylatos napok 'YYYY-MM-DD' formátumban (legalább egy bizonylat erre a napra). */
  activeDates: Set<string>
  /** A kiválasztott nap 'YYYY-MM-DD' vagy null. */
  selectedDate: string | null
  /** Aktív napra kattintáskor hívódik. */
  onSelectDate: (date: string) => void
  /** A "ma" 'YYYY-MM-DD' (Europe/Budapest) — kezdő hónap + mai nap kiemelés. */
  today: string
}

const WEEKDAY_LABELS = ['H', 'K', 'Sze', 'Cs', 'P', 'Szo', 'V']
const MONTH_LABELS = [
  'Január',
  'Február',
  'Március',
  'Április',
  'Május',
  'Június',
  'Július',
  'Augusztus',
  'Szeptember',
  'Október',
  'November',
  'December',
]

function pad2(n: number): string {
  return String(n).padStart(2, '0')
}

function ymd(year: number, monthIndex: number, day: number): string {
  return `${year}-${pad2(monthIndex + 1)}-${pad2(day)}`
}

export default function ShipmentCalendarPanel({
  activeDates,
  selectedDate,
  onSelectDate,
  today,
}: ShipmentCalendarPanelProps) {
  // 'YYYY-MM-DD' → kezdő év + 0-bázisú hónap. slice() mindig string-et ad (nem undefined).
  const initialYear = Number(today.slice(0, 4))
  const initialMonthIndex = Number(today.slice(5, 7)) - 1
  const [view, setView] = useState({ year: initialYear, monthIndex: initialMonthIndex })

  // Hétfő-első: JS getDay() 0=vasárnap..6=szombat → (g+6)%7 ad 0=hétfő..6=vasárnap.
  // A Date konstruktor helyi időzónás, de itt csak a naptári hétköznap/naphossz kell — időzóna-független.
  const firstWeekdayMondayBased = (new Date(view.year, view.monthIndex, 1).getDay() + 6) % 7
  const daysInMonth = new Date(view.year, view.monthIndex + 1, 0).getDate()

  const goPrev = () =>
    setView(({ year, monthIndex }) =>
      monthIndex === 0 ? { year: year - 1, monthIndex: 11 } : { year, monthIndex: monthIndex - 1 },
    )
  const goNext = () =>
    setView(({ year, monthIndex }) =>
      monthIndex === 11 ? { year: year + 1, monthIndex: 0 } : { year, monthIndex: monthIndex + 1 },
    )

  const cells: Array<number | null> = []
  for (let i = 0; i < firstWeekdayMondayBased; i++) cells.push(null)
  for (let d = 1; d <= daysInMonth; d++) cells.push(d)

  return (
    <div className="form-panel" data-testid="shipment-calendar">
      <div className="mb-2 flex items-center justify-between">
        <button
          type="button"
          className="form-button p-1"
          onClick={goPrev}
          aria-label="Előző hónap"
          title="Előző hónap"
        >
          <ChevronLeft size={16} />
        </button>
        <span className="font-semibold">
          {view.year}. {MONTH_LABELS[view.monthIndex]}
        </span>
        <button
          type="button"
          className="form-button p-1"
          onClick={goNext}
          aria-label="Következő hónap"
          title="Következő hónap"
        >
          <ChevronRight size={16} />
        </button>
      </div>
      <div className="grid grid-cols-7 gap-1 text-center text-xs text-gray-500">
        {WEEKDAY_LABELS.map((w) => (
          <div key={w} className="py-1 font-medium">
            {w}
          </div>
        ))}
      </div>
      <div className="grid grid-cols-7 gap-1 text-center text-sm">
        {cells.map((day, idx) => {
          if (day === null) return <div key={`empty-${idx}`} />
          const dateStr = ymd(view.year, view.monthIndex, day)
          const isActive = activeDates.has(dateStr)
          const isSelected = dateStr === selectedDate
          const isToday = dateStr === today
          const cls = isSelected
            ? 'bg-blue-600 text-white font-semibold'
            : isActive
              ? 'bg-blue-50 text-blue-800 hover:bg-blue-100 font-medium cursor-pointer'
              : 'text-gray-300 cursor-default'
          return (
            <button
              key={dateStr}
              type="button"
              disabled={!isActive}
              onClick={() => onSelectDate(dateStr)}
              data-testid={`calendar-day-${dateStr}${isActive ? '-active' : ''}`}
              className={`rounded py-1.5 ${cls} ${isToday && !isSelected ? 'ring-1 ring-blue-400' : ''}`}
            >
              {day}
            </button>
          )
        })}
      </div>
    </div>
  )
}
