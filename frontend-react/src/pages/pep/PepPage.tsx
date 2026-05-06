import { useMemo, useState } from 'react'
import PepForm from './components/PepForm'
import PepDetail from './components/PepDetail'
import { pepCategoryColors, pepCategoryLabels, positionTypeLabels } from './constants'
import type { PepFormData, PoliticallyExposedPerson } from './hooks/usePepData'
import { usePepData } from './hooks/usePepData'
import { useTranslation } from 'react-i18next'

export default function PepPage() {
  const { t } = useTranslation()
  const [searchTerm, setSearchTerm] = useState('')
  const [showCreateDialog, setShowCreateDialog] = useState(false)
  const [selectedPep, setSelectedPep] = useState<PoliticallyExposedPerson | null>(null)
  const [showDetailDialog, setShowDetailDialog] = useState(false)
  const [editingPep, setEditingPep] = useState<PoliticallyExposedPerson | null>(null)

  const {
    pepList,
    loading,
    activeTab,
    setActiveTab,
    reviewDue,
    savePep,
  } = usePepData()

  const filteredPepList = useMemo(() => {
    const term = searchTerm.toLowerCase()
    return pepList.filter(p =>
      p.customerName?.toLowerCase().includes(term) ||
      p.documentNumber?.toLowerCase().includes(term),
    )
  }, [pepList, searchTerm])

  const handleSave = async (formData: PepFormData) => {
    try {
      await savePep(formData, editingPep)
      setShowCreateDialog(false)
      setEditingPep(null)
    } catch {
      // Intentional noop: form state remains visible for correction.
    }
  }

  return (
    <div className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-3">
        <div>
          <h1 className="text-lg font-bold">{t('pep.pepNyilvantartas')}</h1>
          <p className="text-gray-500">{t('pep.politikailagKitettSzemelyekKezelesePmt41D')}</p>
        </div>
        <button
          type="button"
          onClick={() => {
            setEditingPep(null)
            setShowCreateDialog(true)
          }}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          {t('pep.ujPepRegisztracio')}
        </button>
      </div>

      {reviewDue.length > 0 && (
        <div className="mb-3 p-4 border border-orange-500 rounded bg-orange-50">
          <h3 className="font-semibold text-orange-700 mb-2">
            {t('pep.felulvizsgalatSzukseges')}{reviewDue.length})
          </h3>
          <div className="space-y-1">
            {reviewDue.slice(0, 3).map(pep => (
              <div key={pep.id} className="text-sm">
                <span className="font-medium">{pep.customerName}</span>
                <span className="text-gray-500 ml-2">
                  - {pep.reviewDate && new Date(pep.reviewDate).toLocaleDateString('hu-HU')}
                </span>
              </div>
            ))}
            {reviewDue.length > 3 && (
              <div className="text-sm text-gray-500">
                {t('pep.esTovabbi')}{reviewDue.length - 3} személy...
              </div>
            )}
          </div>
        </div>
      )}

      <div className="grid grid-cols-4 gap-4 mb-3">
        <div className="p-4 bg-white rounded border">
          <p className="text-sm text-gray-500">{t('pep.osszesPep')}</p>
          <p className="text-lg font-bold">{pepList.length}</p>
        </div>
        <div className="p-4 bg-white rounded border">
          <p className="text-sm text-gray-500">{t('pep.kozvetlenPep')}</p>
          <p className="text-lg font-bold text-red-600">
            {pepList.filter(p => p.pepCategory === 'DIRECT').length}
          </p>
        </div>
        <div className="p-4 bg-white rounded border">
          <p className="text-sm text-gray-500">{t('pep.eddSzukseges')}</p>
          <p className="text-lg font-bold text-orange-600">
            {pepList.filter(p => p.requiresEdd).length}
          </p>
        </div>
        <div className="p-4 bg-white rounded border">
          <p className="text-sm text-gray-500">{t('pep.felulvizsgalando')}</p>
          <p className="text-lg font-bold text-yellow-600">{reviewDue.length}</p>
        </div>
      </div>

      <div className="mb-3">
        <input
          type="text"
          placeholder="Keresés név vagy okmányszám alapján..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full p-2 border rounded"
        />
      </div>

      <div className="mb-4 flex gap-2">
        {['active', 'direct', 'family', 'associate'].map((tab) => (
          <button
            key={tab}
            type="button"
            onClick={() => setActiveTab(tab)}
            className={`px-4 py-2 rounded ${activeTab === tab ? 'bg-blue-600 text-white' : 'bg-gray-100 hover:bg-gray-200'}`}
          >
            {tab === 'active' ? 'Aktív' : tab === 'direct' ? 'Közvetlen PEP' : tab === 'family' ? 'Családtag' : 'Közeli kapcsolat'}
          </button>
        ))}
      </div>

      <div className="bg-white rounded border">
        {loading ? (
          <div className="text-center py-8">Betöltés...</div>
        ) : filteredPepList.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            {t('pep.nincsenekPepSzemelyekEbbenAKategoriaban')}
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-3 text-left">{t('common.name')}</th>
                <th className="p-3 text-left">{t('common.documentNumber')}</th>
                <th className="p-3 text-left">{t('common.category')}</th>
                <th className="p-3 text-left">{t('pep.pozicio')}</th>
                <th className="p-3 text-left">{t('common.country')}</th>
                <th className="p-3 text-left">EDD</th>
                <th className="p-3 text-left">{t('common.approve')}</th>
                <th className="p-3 text-left">{t('pep.felulvizsgalat')}</th>
                <th className="p-3 text-left">{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {filteredPepList.map((pep) => (
                <tr key={pep.id} className="border-t hover:bg-gray-50">
                  <td className="p-3 font-medium">{pep.customerName}</td>
                  <td className="p-3 font-mono">{pep.documentNumber}</td>
                  <td className="p-3">
                    <span className={`px-2 py-1 text-xs text-white rounded ${pepCategoryColors[pep.pepCategory]}`}>
                      {pepCategoryLabels[pep.pepCategory] || pep.pepCategory}
                    </span>
                  </td>
                  <td className="p-3">
                    <div className="max-w-[200px] truncate" title={positionTypeLabels[pep.positionType]}>
                      {positionTypeLabels[pep.positionType] || pep.positionType}
                    </div>
                  </td>
                  <td className="p-3">{pep.country}</td>
                  <td className="p-3">
                    {pep.requiresEdd ? (
                      <span className="px-2 py-1 text-xs text-white rounded bg-orange-500">{t('pep.szukseges')}</span>
                    ) : (
                      <span className="px-2 py-1 text-xs border rounded">{t('common.no')}</span>
                    )}
                  </td>
                  <td className="p-3">
                    {pep.requiresApproval ? (
                      <div>
                        <span className="px-2 py-1 text-xs text-white rounded bg-red-500">{t('common.yes')}</span>
                        {pep.maxAmountWithoutApproval && (
                          <div className="text-xs text-gray-500 mt-1">
                            {t('pep.lt')}{pep.maxAmountWithoutApproval?.toLocaleString()} {t('common.ft')}
                          </div>
                        )}
                      </div>
                    ) : (
                      <span className="px-2 py-1 text-xs border rounded">{t('common.no')}</span>
                    )}
                  </td>
                  <td className="p-3">
                    {pep.reviewDate && (
                      <div className={new Date(pep.reviewDate) < new Date() ? 'text-red-500' : ''}>
                        {new Date(pep.reviewDate).toLocaleDateString('hu-HU')}
                      </div>
                    )}
                  </td>
                  <td className="p-3">
                    <div className="flex gap-2">
                      <button
                        type="button"
                        onClick={() => {
                          setSelectedPep(pep)
                          setShowDetailDialog(true)
                        }}
                        className="px-2 py-1 text-xs border rounded hover:bg-gray-50"
                      >
                        {t('common.details')}
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setEditingPep(pep)
                          setShowCreateDialog(true)
                        }}
                        className="px-2 py-1 text-xs border rounded hover:bg-gray-50"
                      >
                        {t('common.edit')}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {showDetailDialog && selectedPep && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 max-w-3xl w-full max-h-[80vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">{t('pep.pepReszletei')}{selectedPep.customerName}</h2>
            <PepDetail pep={selectedPep} onClose={() => setShowDetailDialog(false)} />
          </div>
        </div>
      )}

      {showCreateDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 max-w-3xl w-full max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">
              {editingPep ? 'PEP szerkesztése' : 'Új PEP személy regisztrálása'}
            </h2>
            <PepForm
              pep={editingPep}
              onSubmit={handleSave}
              onCancel={() => {
                setShowCreateDialog(false)
                setEditingPep(null)
              }}
            />
          </div>
        </div>
      )}
    </div>
  )
}
