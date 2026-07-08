import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { useFeatureFlags } from '../../hooks/useFeatureFlags'
import { buildOtherTasksMenu, type OtherTaskMenuItem } from './otherTasksMenu'

/**
 * EXCMD b6b — „Egyéb feladatok" konszolidált menü (FR-EFM-01/02/03/04).
 * A pénztár konfigurációja (szerver-vezérelt `navIntegration` feature-flag) dönti el,
 * hogy a NAV pénztárgépes (Variáns 1) vagy az OTP POS / adatlapos (Variáns 2) menü látszik.
 */
export default function OtherTasksPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const featureFlags = useFeatureFlags()
  const items = buildOtherTasksMenu(featureFlags.navIntegration)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-lg font-bold text-secondary-900">{t('otherTasks.title')}</h1>
        <p className="text-sm text-secondary-500 mt-1">
          {featureFlags.navIntegration ? t('otherTasks.subtitleNav') : t('otherTasks.subtitlePos')}
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
        {items.map((item) => (
          <OtherTaskCard key={item.id} item={item} onClick={() => navigate(item.route)} />
        ))}
      </div>
    </div>
  )
}

function OtherTaskCard({ item, onClick }: { item: OtherTaskMenuItem; onClick: () => void }) {
  const Icon = item.icon
  return (
    <button
      onClick={onClick}
      data-testid={`other-task-${item.id}`}
      className="flex items-start gap-3 p-4 bg-white border border-secondary-200 rounded-lg text-left
        hover:border-primary-300 hover:bg-primary-50 hover:shadow-sm
        focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-1
        transition-all duration-150 group"
    >
      <div
        className="w-10 h-10 bg-secondary-100 rounded-lg flex items-center justify-center shrink-0
        group-hover:bg-primary-100 transition-colors"
      >
        <Icon
          size={20}
          className="text-secondary-600 group-hover:text-primary-600 transition-colors"
        />
      </div>
      <div className="flex-1 min-w-0">
        <span className="text-sm font-semibold text-secondary-900 group-hover:text-primary-700">
          {item.label}
        </span>
        <p className="text-xs text-secondary-500 mt-0.5">{item.description}</p>
      </div>
    </button>
  )
}
