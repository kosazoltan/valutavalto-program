import type { PoliticallyExposedPerson } from '../hooks/usePepData'
import { pepCategoryColors, pepCategoryLabels, positionTypeLabels } from '../constants'

interface PepDetailProps {
  pep: PoliticallyExposedPerson
  onClose: () => void
}

export default function PepDetail({ pep, onClose }: PepDetailProps) {
  return (
    <div className="space-y-3">
      <div className="grid grid-cols-3 gap-4">
        <div>
          <p className="text-gray-500 text-sm">Ügyfél neve</p>
          <p className="font-medium">{pep.customerName}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Okmányszám</p>
          <p className="font-mono">{pep.documentNumber}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Kategória</p>
          <span className={`px-2 py-1 text-xs text-white rounded ${pepCategoryColors[pep.pepCategory]}`}>
            {pepCategoryLabels[pep.pepCategory]}
          </span>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Pozíció típusa</p>
          <p>{positionTypeLabels[pep.positionType]}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Pozíció leírása</p>
          <p>{pep.positionDescription || '-'}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Ország</p>
          <p>{pep.country}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Kinevezés kezdete</p>
          <p>{pep.appointmentStartDate ? new Date(pep.appointmentStartDate).toLocaleDateString('hu-HU') : '-'}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Kinevezés vége</p>
          <p>{pep.appointmentEndDate ? new Date(pep.appointmentEndDate).toLocaleDateString('hu-HU') : '-'}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Következő felülvizsgálat</p>
          <p className={pep.reviewDate && new Date(pep.reviewDate) < new Date() ? 'text-red-500 font-semibold' : ''}>
            {pep.reviewDate ? new Date(pep.reviewDate).toLocaleDateString('hu-HU') : '-'}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <p className="text-gray-500 text-sm">Vagyon eredete</p>
          <p className="whitespace-pre-wrap">{pep.sourceOfWealth || '-'}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Pénzeszközök forrása</p>
          <p className="whitespace-pre-wrap">{pep.sourceOfFunds || '-'}</p>
        </div>
      </div>

      <div className="flex gap-4">
        <div className="flex items-center gap-2">
          <p className="text-gray-500 text-sm">EDD szükséges:</p>
          {pep.requiresEdd ? (
            <span className="px-2 py-1 text-xs text-white rounded bg-orange-500">Igen</span>
          ) : (
            <span className="px-2 py-1 text-xs border rounded">Nem</span>
          )}
        </div>
        <div className="flex items-center gap-2">
          <p className="text-gray-500 text-sm">Jóváhagyás szükséges:</p>
          {pep.requiresApproval ? (
            <span className="px-2 py-1 text-xs text-white rounded bg-red-500">Igen</span>
          ) : (
            <span className="px-2 py-1 text-xs border rounded">Nem</span>
          )}
        </div>
        {pep.requiresApproval && pep.maxAmountWithoutApproval && (
          <div className="flex items-center gap-2">
            <p className="text-gray-500 text-sm">Limit nélküli max:</p>
            <span>{pep.maxAmountWithoutApproval.toLocaleString()} Ft</span>
          </div>
        )}
      </div>

      {pep.notes && (
        <div>
          <p className="text-gray-500 text-sm">Megjegyzések</p>
          <p className="whitespace-pre-wrap">{pep.notes}</p>
        </div>
      )}

      <div className="text-sm text-gray-500">
        Létrehozva: {new Date(pep.createdAt).toLocaleString('hu-HU')}
      </div>

      <div className="flex justify-end">
        <button
          type="button"
          onClick={onClose}
          className="px-4 py-2 border rounded hover:bg-gray-50"
        >
          Bezárás
        </button>
      </div>
    </div>
  )
}
