import { Link, useLocation } from 'react-router-dom'
import { FileQuestion, Home, ArrowLeft } from 'lucide-react'
import { useTranslation } from 'react-i18next'

/**
 * PR #116: 404 NotFound oldal.
 *
 * Korábban az ismeretlen URL-ek üres fehér képernyőt adtak (silent failure) —
 * most tiszta 404 + visszanavigálás + home link.
 */
export default function NotFoundPage() {
  const { t } = useTranslation()
  const location = useLocation()

  return (
    <div className="flex items-center justify-center min-h-[60vh] p-8">
      <div className="text-center max-w-md">
        <FileQuestion size={96} className="mx-auto text-gray-400 mb-4" />
        <h1 className="text-4xl font-bold text-gray-800 mb-2">404</h1>
        <h2 className="text-2xl font-semibold text-gray-700 mb-4">
          {t('common.oldalNemTalalhato')}
        </h2>
        <p className="text-gray-600 mb-6">
          {t('common.aKeresettUrl')}
          <code className="bg-gray-100 px-2 py-1 rounded">{location.pathname}</code>
          {t('common.nemLetezik')}
          {t('common.lehetHogy')}
        </p>
        <ul className="text-left text-sm text-gray-600 mb-6 space-y-1">
          <li>{t('common.AHivatkozasElavultVagyHibas')}</li>
          <li>{t('common.AzOldaltAtneveztekAthelyeztek')}</li>
          <li>{t('common.KezzelGepeltedBeEsElirtalValamit')}</li>
        </ul>
        <div className="flex gap-3 justify-center">
          <button
            onClick={() => window.history.back()}
            className="flex items-center gap-2 px-4 py-2 bg-gray-100 hover:bg-gray-200 rounded"
          >
            <ArrowLeft size={16} />
            {t('common.back')}
          </button>
          <Link
            to="/dashboard"
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded"
          >
            <Home size={16} />
            {t('components.fooldal')}
          </Link>
        </div>
      </div>
    </div>
  )
}
