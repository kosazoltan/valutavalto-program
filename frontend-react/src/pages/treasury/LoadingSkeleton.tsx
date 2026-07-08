/**
 * Treasury loading skeletons — Bloomberg Terminal-style shimmer placeholders
 */

function Skeleton({ className = '' }: { className?: string }) {
  return <div className={`animate-pulse bg-secondary-200 rounded ${className}`} />
}

export function KpiCardSkeleton() {
  return (
    <div className="form-panel">
      <div className="flex items-start justify-between mb-3">
        <Skeleton className="w-10 h-10 rounded-lg" />
        <Skeleton className="w-16 h-4" />
      </div>
      <Skeleton className="w-24 h-3 mb-2" />
      <Skeleton className="w-20 h-6" />
    </div>
  )
}

export function TableSkeleton({ rows = 5, cols = 6 }: { rows?: number; cols?: number }) {
  return (
    <div className="form-panel">
      <div className="flex items-center justify-between mb-4">
        <Skeleton className="w-48 h-5" />
        <Skeleton className="w-24 h-8 rounded-md" />
      </div>
      <div className="space-y-3">
        {/* Header */}
        <div className="flex gap-4">
          {Array.from({ length: cols }).map((_, i) => (
            <Skeleton key={i} className="h-4 flex-1" />
          ))}
        </div>
        {/* Rows */}
        {Array.from({ length: rows }).map((_, rowIdx) => (
          <div key={rowIdx} className="flex gap-4">
            {Array.from({ length: cols }).map((_, colIdx) => (
              <Skeleton key={colIdx} className="h-4 flex-1" />
            ))}
          </div>
        ))}
      </div>
    </div>
  )
}

export function DashboardSkeleton() {
  return (
    <div className="space-y-3">
      {/* KPI cards */}
      <div className="grid grid-cols-4 gap-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <KpiCardSkeleton key={i} />
        ))}
      </div>
      {/* Charts + tables */}
      <div className="grid grid-cols-2 gap-4">
        <TableSkeleton rows={5} cols={3} />
        <TableSkeleton rows={5} cols={4} />
      </div>
    </div>
  )
}
