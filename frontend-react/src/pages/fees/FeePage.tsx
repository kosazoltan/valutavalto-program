import { useState, useEffect, useCallback } from 'react'
import { DollarSign, Plus, Trash2 } from 'lucide-react'
import { feeApi, FeeType, FeeRate, FeeDiscount } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

export default function FeePage() {
  const { t } = useTranslation()
  const [activeTab, setActiveTab] = useState<'types' | 'rates' | 'discounts'>('types')
  const [types, setTypes] = useState<FeeType[]>([])
  const [rates, setRates] = useState<FeeRate[]>([])
  const [discounts, setDiscounts] = useState<FeeDiscount[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [formData, setFormData] = useState<Partial<FeeType & FeeRate & FeeDiscount>>({})

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      if (activeTab === 'types') {
        setTypes(await feeApi.getTypes())
      } else if (activeTab === 'rates') {
        setRates(await feeApi.getRates())
      } else {
        setDiscounts(await feeApi.getDiscounts())
      }
    } catch (err) {
      logger.error('FeePage', 'Díjadatok betöltési hiba:', err)
      setError('Hiba a díjadatok betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [activeTab])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const handleSave = async () => {
    try {
      setError(null)
      if (activeTab === 'types') {
        if (formData.id) await feeApi.updateType(formData.id, formData)
        else await feeApi.createType(formData)
      } else if (activeTab === 'rates') {
        if (formData.id) await feeApi.updateRate(formData.id, formData)
        else await feeApi.createRate(formData)
      } else if (formData.id) await feeApi.updateDiscount(formData.id, formData)
      else await feeApi.createDiscount(formData)
      await loadData()
      setShowForm(false)
    } catch (err) {
      logger.error('FeePage', 'Díj mentési hiba:', err)
      setError('Hiba történt a mentés során')
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törli a kiválasztott díjbeállítást?')) return
    try {
      setError(null)
      if (activeTab === 'types') {
        await feeApi.deleteType(id)
      } else if (activeTab === 'rates') {
        await feeApi.deleteRate(id)
      } else {
        await feeApi.deleteDiscount(id)
      }
      await loadData()
    } catch (err) {
      logger.error('FeePage', 'Díj törlési hiba:', err)
      setError('Hiba történt a törlés során')
    }
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2">
        <DollarSign />
        {t('fees.dijkezeles')}
      </h1>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="flex gap-2 border-b">
        {(['types', 'rates', 'discounts'] as const).map((tab) => (
          <button
            type="button"
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-4 py-2 ${activeTab === tab ? 'border-b-2 border-blue-500' : ''}`}
          >
            {tab === 'types' ? 'Díjtípusok' : tab === 'rates' ? 'Díj mértékek' : 'Kedvezmények'}
          </button>
        ))}
      </div>
      <div className="flex justify-end">
        <button
          type="button"
          onClick={() => {
            setFormData({})
            setShowForm(true)
          }}
          className="form-button-primary"
        >
          <Plus size={16} />
          {t('common.new')}
        </button>
      </div>
      {loading ? (
        <div>{i18n.t('literals.betoltes')}</div>
      ) : (
        <div className="form-panel">
          {activeTab === 'types' && (
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th>{t('common.code')}</th>
                  <th>{t('common.name')}</th>
                  <th>{t('fees.szamitas')}</th>
                  <th>{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {types.map((ft) => (
                  <tr key={ft.id}>
                    <td>{ft.code}</td>
                    <td>{ft.name}</td>
                    <td>{ft.calculationMethod}</td>
                    <td className="flex gap-2">
                      <button
                        type="button"
                        onClick={() => {
                          setFormData(ft)
                          setShowForm(true)
                        }}
                        className="form-button text-xs"
                      >
                        {t('common.edit')}
                      </button>
                      <button
                        type="button"
                        onClick={() => void handleDelete(ft.id)}
                        className="form-button text-xs text-red-700"
                        title={t('common.delete')}
                      >
                        <Trash2 size={14} /> {t('common.delete')}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          {activeTab === 'rates' && (
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th>{t('fees.dijtipus')}</th>
                  <th>{t('common.currency')}</th>
                  <th>{t('fees.mertek')}</th>
                  <th>{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {rates.map((r) => (
                  <tr key={r.id}>
                    <td>{r.feeTypeName}</td>
                    <td>{r.currencyCode}</td>
                    <td>{r.rate}</td>
                    <td className="flex gap-2">
                      <button
                        type="button"
                        onClick={() => {
                          setFormData(r)
                          setShowForm(true)
                        }}
                        className="form-button text-xs"
                      >
                        {t('common.edit')}
                      </button>
                      <button
                        type="button"
                        onClick={() => void handleDelete(r.id)}
                        className="form-button text-xs text-red-700"
                        title={t('common.delete')}
                      >
                        <Trash2 size={14} /> {t('common.delete')}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          {activeTab === 'discounts' && (
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th>{t('common.code')}</th>
                  <th>{t('common.name')}</th>
                  <th>{t('common.type')}</th>
                  <th>{t('fees.ertek')}</th>
                  <th>{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {discounts.map((d) => (
                  <tr key={d.id}>
                    <td>{d.code}</td>
                    <td>{d.name}</td>
                    <td>{d.discountType}</td>
                    <td>{d.discountValue}</td>
                    <td className="flex gap-2">
                      <button
                        type="button"
                        onClick={() => {
                          setFormData(d)
                          setShowForm(true)
                        }}
                        className="form-button text-xs"
                      >
                        {t('common.edit')}
                      </button>
                      <button
                        type="button"
                        onClick={() => void handleDelete(d.id)}
                        className="form-button text-xs text-red-700"
                        title={t('common.delete')}
                      >
                        <Trash2 size={14} /> {t('common.delete')}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 w-full max-w-2xl">
            <h2 className="text-lg font-bold mb-4">{formData.id ? 'Szerkesztés' : 'Új'}</h2>
            <div className="space-y-4">
              {activeTab === 'types' && (
                <>
                  <div>
                    <label className="form-label">{t('common.code')}</label>
                    <input
                      className="form-input"
                      value={formData.code || ''}
                      onChange={(e) => setFormData({ ...formData, code: e.target.value })}
                    />
                  </div>
                  <div>
                    <label className="form-label">{t('common.name')}</label>
                    <input
                      className="form-input"
                      value={formData.name || ''}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    />
                  </div>
                </>
              )}
              <div className="flex gap-2">
                <button type="button" onClick={() => setShowForm(false)} className="form-button">
                  {t('common.cancel')}
                </button>
                <button type="button" onClick={handleSave} className="form-button-primary">
                  {t('common.save')}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
