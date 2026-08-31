import { useEffect, useRef } from 'react'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'
import type {
  TransactionLevyRate,
  TransactionLevyRateCreateRequest,
} from '../../services/api/index'

interface Props {
  title: string
  current: TransactionLevyRate
  pending: TransactionLevyRateCreateRequest
  onConfirm: () => void
  onCancel: () => void
}

/**
 * FK-100 FR-4 — local copy of the FeeConfirmDialog shape (role="alertdialog",
 * focus trap, Esc / backdrop = cancel). Shows current-vs-new rate fields
 * plus the irreversible-decision sentence. Do not import FeeConfirmDialog
 * across pages.
 */
export default function TransactionLevyRateConfirmDialog({
  title,
  current,
  pending,
  onConfirm,
  onCancel,
}: Props) {
  const { t } = useTranslation()
  const fmt = new Intl.NumberFormat('hu-HU')
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
      aria-labelledby="levy-rate-confirm-title"
      aria-describedby="levy-rate-confirm-description"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      onKeyDown={handleKeyDown}
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onCancel()
      }}
    >
      <div className="w-full max-w-lg rounded-lg bg-white p-6 shadow-xl">
        <h2 id="levy-rate-confirm-title" className="text-lg font-bold text-amber-900">
          {title}
        </h2>
        <p id="levy-rate-confirm-description" className="mt-3 text-sm text-gray-700">
          {t('reports.transactionLevyRates.confirmText')}
        </p>
        <dl className="mt-4 grid grid-cols-[1fr_auto_auto] gap-x-4 gap-y-1 text-sm">
          <dt />
          <dd className="font-medium">{t('reports.transactionLevyRates.confirmCurrent')}</dd>
          <dd className="font-medium">{t('reports.transactionLevyRates.confirmNew')}</dd>
          <dt>{t('reports.transactionLevyRates.baseRate')}</dt>
          <dd>{current.baseRatePercent}</dd>
          <dd>{pending.baseRatePercent}</dd>
          <dt>{t('reports.transactionLevyRates.baseCap')}</dt>
          <dd>{fmt.format(current.baseRateCapHuf)}</dd>
          <dd>{fmt.format(pending.baseRateCapHuf)}</dd>
          <dt>{t('reports.transactionLevyRates.supplementRate')}</dt>
          <dd>{current.supplementRatePercent}</dd>
          <dd>{pending.supplementRatePercent}</dd>
          <dt>{t('reports.transactionLevyRates.supplementCap')}</dt>
          <dd>{fmt.format(current.supplementRateCapHuf)}</dd>
          <dd>{fmt.format(pending.supplementRateCapHuf)}</dd>
          <dt>{t('reports.transactionLevyRates.singleSide')}</dt>
          <dd>{current.conversionSingleSideFlag ? '✓' : '–'}</dd>
          <dd>{pending.conversionSingleSideFlag ? '✓' : '–'}</dd>
          <dt>{t('reports.transactionLevyRates.effectiveFrom')}</dt>
          <dd>{current.effectiveFrom}</dd>
          <dd>{pending.effectiveFrom}</dd>
        </dl>
        <p className="mt-4 text-sm font-medium text-amber-900">
          {t('reports.transactionLevyRates.confirmIrreversible')}
        </p>
        <div className="mt-6 flex justify-end gap-3">
          <button
            ref={cancelRef}
            type="button"
            onClick={onCancel}
            className="rounded border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            {i18n.t('literals.megse')}
          </button>
          <button
            ref={confirmRef}
            type="button"
            onClick={onConfirm}
            className="rounded bg-amber-600 px-4 py-2 text-sm font-medium text-white hover:bg-amber-700"
          >
            {i18n.t('literals.kuldes-megerositese')}
          </button>
        </div>
      </div>
    </div>
  )
}
