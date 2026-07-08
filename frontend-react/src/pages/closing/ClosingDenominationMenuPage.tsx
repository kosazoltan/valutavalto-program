import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { ArrowLeft, LogOut } from 'lucide-react'
import {
  CLOSING_DENOMINATION_MENU,
  CLOSING_DENOMINATION_EXIT_ROUTE,
  type ClosingDenominationMenuItem,
} from './closingDenominationMenu'

/**
 * EXCMD b5 FR-KC-05 — „Címletezés – zárások" választó-menü. Az inaktív (a forrás-képernyőn
 * szürkített) pontok kattintásra nem indulnak el (disabled gomb, route nélkül).
 * VISSZA: előző képernyő; KILÉPÉS: pénztáros főmenü.
 */
export default function ClosingDenominationMenuPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-lg font-bold text-secondary-900">
          {t('closingDenominationMenu.title')}
        </h1>
        <p className="text-sm text-secondary-500 mt-1">{t('closingDenominationMenu.subtitle')}</p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        {CLOSING_DENOMINATION_MENU.map((item) => (
          <DenominationMenuCard
            key={item.id}
            item={item}
            onClick={() => {
              // FR-KC-05 kényszer: inaktív pont nem indulhat el.
              if (!item.disabled && item.route) navigate(item.route)
            }}
          />
        ))}
      </div>

      <div className="flex gap-3">
        <button
          onClick={() => navigate(-1)}
          data-testid="closing-denomination-back"
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-secondary-700
            bg-white border border-secondary-300 rounded-lg hover:bg-secondary-50"
        >
          <ArrowLeft size={16} /> {t('closingDenominationMenu.back')}
        </button>
        <button
          onClick={() => navigate(CLOSING_DENOMINATION_EXIT_ROUTE)}
          data-testid="closing-denomination-exit"
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-secondary-700
            bg-white border border-secondary-300 rounded-lg hover:bg-secondary-50"
        >
          <LogOut size={16} /> {t('closingDenominationMenu.exit')}
        </button>
      </div>
    </div>
  )
}

function DenominationMenuCard({
  item,
  onClick,
}: {
  item: ClosingDenominationMenuItem
  onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      disabled={item.disabled}
      data-testid={`closing-denomination-${item.id}`}
      className={
        item.disabled
          ? 'flex flex-col items-start p-4 bg-secondary-50 border border-secondary-200 rounded-lg text-left cursor-not-allowed opacity-60'
          : `flex flex-col items-start p-4 bg-white border border-secondary-200 rounded-lg text-left
             hover:border-primary-300 hover:bg-primary-50 hover:shadow-sm
             focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-1 transition-all duration-150`
      }
    >
      <span className="text-sm font-semibold text-secondary-900">{item.label}</span>
      <p className="text-xs text-secondary-500 mt-0.5">{item.description}</p>
    </button>
  )
}
