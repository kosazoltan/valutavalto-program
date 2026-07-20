import { useEffect, useRef } from 'react'
import type { ShipmentRequest } from '../../services/api/index'

interface Props {
  shipment: ShipmentRequest
  onConfirm: () => void
  onCancel: () => void
}

function formatAmount(amount: number, currencyCode?: string): string {
  return `${amount.toLocaleString('hu-HU')} ${currencyCode || 'ismeretlen valutanem'}`
}

function formatRequestedAt(value: string): string {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString('hu-HU')
}

export default function StaleShipmentConfirmDialog({ shipment, onConfirm, onCancel }: Props) {
  const cancelRef = useRef<HTMLButtonElement>(null)
  const confirmRef = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    cancelRef.current?.focus()
  }, [])

  const handleKeyDown = (event: React.KeyboardEvent<HTMLDivElement>) => {
    if (event.key === 'Escape') {
      event.preventDefault()
      onCancel()
      return
    }
    if (event.key !== 'Tab') return

    const activeElement = document.activeElement
    if (event.shiftKey && activeElement === cancelRef.current) {
      event.preventDefault()
      confirmRef.current?.focus()
    } else if (!event.shiftKey && activeElement === confirmRef.current) {
      event.preventDefault()
      cancelRef.current?.focus()
    }
  }

  return (
    <div
      role="alertdialog"
      aria-modal="true"
      aria-labelledby="stale-shipment-dialog-title"
      aria-describedby="stale-shipment-dialog-description"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      onKeyDown={handleKeyDown}
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onCancel()
      }}
    >
      <div className="w-full max-w-lg rounded-lg bg-white p-6 shadow-xl">
        <h2 id="stale-shipment-dialog-title" className="text-lg font-bold text-amber-900">
          Régi szállítmány átvételének megerősítése
        </h2>
        <div
          id="stale-shipment-dialog-description"
          className="mt-3 space-y-3 text-sm text-gray-700"
        >
          <p>Ez a tétel több mint {shipment.staleThresholdHours ?? 48} órája vár átvételre.</p>
          <dl className="grid grid-cols-[max-content_1fr] gap-x-3 gap-y-1 rounded border border-amber-200 bg-amber-50 p-3">
            <dt className="font-semibold">Bizonylatszám:</dt>
            <dd className="font-mono font-semibold">{shipment.requestNumber}</dd>
            <dt className="font-semibold">Létrehozva:</dt>
            <dd>{formatRequestedAt(shipment.requestedAt)}</dd>
            <dt className="font-semibold">Összeg:</dt>
            <dd>
              <ul>
                {(shipment.items ?? []).map((item) => (
                  <li key={item.id}>
                    {formatAmount(item.requestedAmount ?? item.amount ?? 0, item.currencyCode)}
                  </li>
                ))}
              </ul>
            </dd>
          </dl>
          <p className="font-semibold text-amber-900">
            A tétel nincs már más módon (például kézi kasszabevéttel) rendezve?
          </p>
        </div>
        <div className="mt-5 flex justify-end gap-2">
          <button
            ref={cancelRef}
            type="button"
            onClick={onCancel}
            className="rounded border border-gray-300 px-4 py-2 text-sm font-semibold hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            Mégse
          </button>
          <button
            ref={confirmRef}
            type="button"
            onClick={onConfirm}
            className="rounded bg-amber-700 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-800 focus:outline-none focus:ring-2 focus:ring-amber-500"
          >
            Igen, folytatás
          </button>
        </div>
      </div>
    </div>
  )
}
