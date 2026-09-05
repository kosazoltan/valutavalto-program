/**
 * FKH-050 (FR-4): prominent amber banner shown on every retroactive closing screen.
 * The date is the PAST business day being closed — it is rendered verbatim so the
 * operator always sees which day the simplified flow applies to.
 */
export default function RetroactiveClosingBanner({ date }: { date: string }) {
  return (
    <div
      data-testid="retroactive-closing-banner"
      className="mb-4 rounded-lg border-2 border-amber-500 bg-amber-100 px-4 py-3 text-center"
    >
      <span className="text-lg font-bold text-amber-900">UTÓLAGOS ZÁRÁS - {date}</span>
    </div>
  )
}
