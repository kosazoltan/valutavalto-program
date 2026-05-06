import type { PoliticallyExposedPerson } from '../hooks/usePepData'
import { pepCategoryColors, pepCategoryLabels, positionTypeLabels } from '../constants'
import { useTranslation } from 'react-i18next'

interface PepDetailProps {
  pep: PoliticallyExposedPerson
  onClose: () => void
}

export default function PepDetail({ pep, onClose }: PepDetailProps) {
  const { t } = useTranslation()
  return (
    <div className="space-y-3">
      <div className="grid grid-cols-3 gap-4">
        <div>
          <p className="text-gray-500 text-sm">{t('pep.ugyfelNeve')}</p>
          <p className="font-medium">{pep.customerName}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">{t('common.documentNumber')}</p>
          <p className="font-mono">{pep.documentNumber}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">{t('common.category')}</p>
          <span className={`px-2 py-1 text-xs text-white rounded ${pepCategoryColors[pep.pepCategory]}`}>
            {pepCategoryLabels[pep.pepCategory]}
          </span>
        </div>
        <div>
          <p className="text-gray-500 text-sm">{t('pep.pozicioTipusa')}</p>
          <p>{positionTypeLabels[pep.positionType]}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">{t('pep.pozicioLeirasa')}</p>
          <p>{pep.positionDescription || '-'}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">{t('common.country')}</p>
          <p>{pep.country}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">{t('pep.kinevezesKezdete')}</p>
          <p>{pep.appointmentStartDate ? new Date(pep.appointmentStartDate).toLocaleDateString('hu-HU') : '-'}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">{t('pep.kinevezesVege')}</p>
          <p>{pep.appointmentEndDate ? new Date(pep.appointmentEndDate).toLocaleDateString('hu-HU') : '-'}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">{t('pep.kovetkezoFelulvizsgalat')}</p>
          <p className={pep.reviewDate && new Date(pep.reviewDate) < new Date() ? 'text-red-500 font-semibold' : ''}>
            {pep.reviewDate ? new Date(pep.reviewDate).toLocaleDateString('hu-HU') : '-'}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <p className="text-gray-500 text-sm">{t('pep.vagyonEredete')}</p>
          <p className="whitespace-pre-wrap">{pep.sourceOfWealth || '-'}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">{t('pep.penzeszkozokForrasa')}</p>
          <p className="whitespace-pre-wrap">{pep.sourceOfFunds || '-'}</p>
        </div>
      </div>

      <div className="flex gap-4">
        <div className="flex items-center gap-2">
          <p className="text-gray-500 text-sm">{t('pep.eddSzukseges2')}</p>
          {pep.requiresEdd ? (
            <span className="px-2 py-1 text-xs text-white rounded bg-orange-500">{t('common.yes')}</span>
          ) : (
            <span className="px-2 py-1 text-xs border rounded">{t('common.no')}</span>
          )}
        </div>
        <div className="flex items-center gap-2">
          <p className="text-gray-500 text-sm">{t('pep.jovahagyasSzukseges')}</p>
          {pep.requiresApproval ? (
            <span className="px-2 py-1 text-xs text-white rounded bg-red-500">{t('common.yes')}</span>
          ) : (
            <span className="px-2 py-1 text-xs border rounded">{t('common.no')}</span>
          )}
        </div>
        {pep.requiresApproval && pep.maxAmountWithoutApproval && (
          <div className="flex items-center gap-2">
            <p className="text-gray-500 text-sm">{t('pep.limitNelkuliMax')}</p>
            <span>{pep.maxAmountWithoutApproval.toLocaleString()} {t('components.ft')}</span>
          </div>
        )}
      </div>

      {pep.notes && (
        <div>
          <p className="text-gray-500 text-sm">{t('pep.megjegyzesek')}</p>
          <p className="whitespace-pre-wrap">{pep.notes}</p>
        </div>
      )}

      <div className="text-sm text-gray-500">
        {t('customers.letrehozva')}{new Date(pep.createdAt).toLocaleString('hu-HU')}
      </div>

      <div className="flex justify-end">
        <button
          type="button"
          onClick={onClose}
          className="px-4 py-2 border rounded hover:bg-gray-50"
        >
          {t('common.close')}
        </button>
      </div>
    </div>
  )
}
