/**
 * HorizontalBarChart — függőség-mentes, inline SVG vízszintes oszlopdiagram.
 *
 * Az EXCMD b5-kezeles FR-KC-08 (forgalmi grafikon) gaphez készült: nem
 * adunk új npm-függőséget (chart lib) a 4 kliens-bundle-höz, helyette
 * könnyű, akadálymentes SVG-renderelés. A diagram automatikusan a
 * legnagyobb abszolút értékhez skáláz, és kezeli a negatív értékeket is.
 */

export interface BarDatum {
  /** Tengelyfelirat (pl. valutakód). */
  label: string
  /** Numerikus érték (lehet negatív is). */
  value: number
}

export interface HorizontalBarChartProps {
  data: BarDatum[]
  /** Tailwind szín-osztály az oszlopokhoz (alap: bg-blue-500). */
  barClassName?: string
  /** Negatív értékek szín-osztálya (alap: bg-red-500). */
  negativeBarClassName?: string
  /** Érték-formázó a feliratokhoz. */
  formatValue?: (n: number) => string
  /** Üres-állapot szöveg. */
  emptyText?: string
}

export default function HorizontalBarChart({
  data,
  barClassName = 'bg-blue-500',
  negativeBarClassName = 'bg-red-500',
  formatValue = (n) => n.toLocaleString('hu-HU'),
  emptyText = 'Nincs megjeleníthető adat.',
}: HorizontalBarChartProps) {
  if (!data || data.length === 0) {
    return <div className="text-center text-gray-500 py-4 text-sm">{emptyText}</div>
  }

  // A legnagyobb abszolút érték adja a 100%-os skálát (0-osztás ellen min 1).
  const maxAbs = Math.max(1, ...data.map((d) => Math.abs(d.value)))

  return (
    <div className="space-y-1.5" role="img" aria-label="Forgalmi oszlopdiagram">
      {data.map((d) => {
        const widthPct = (Math.abs(d.value) / maxAbs) * 100
        const isNegative = d.value < 0
        return (
          <div key={d.label} className="flex items-center gap-2 text-sm">
            <div className="w-16 shrink-0 font-mono text-gray-600 text-right">{d.label}</div>
            <div className="flex-1 bg-gray-100 rounded h-5 overflow-hidden">
              <div
                className={`h-5 rounded ${isNegative ? negativeBarClassName : barClassName}`}
                style={{ width: `${widthPct}%`, minWidth: d.value === 0 ? 0 : 2 }}
              />
            </div>
            <div className="w-32 shrink-0 font-mono text-right text-gray-700">
              {formatValue(d.value)}
            </div>
          </div>
        )
      })}
    </div>
  )
}
