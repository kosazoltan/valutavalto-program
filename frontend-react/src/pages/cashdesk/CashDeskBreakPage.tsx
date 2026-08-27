import { useState, useEffect, useCallback } from 'react'
import { Clock, Play, Square } from 'lucide-react'
import { cashDeskBreakApi, CashDeskBreak, cashDeskApi, CashDesk } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import { useTextReasonModal } from '../../components/TextReasonModal'
import i18n from '../../i18n'

export default function CashDeskBreakPage() {
  const { t } = useTranslation()
  const [breaks, setBreaks] = useState<CashDeskBreak[]>([])
  const [cashDesks, setCashDesks] = useState<CashDesk[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedCashDeskId, setSelectedCashDeskId] = useState<string>('')
  const [activeBreak, setActiveBreak] = useState<CashDeskBreak | null>(null)
  const [error, setError] = useState<string | null>(null)

  // FKH-027 C-csoport: a natív window.prompt() kiváltása (Electronban silent no-op)
  const { modal: reasonModal, requestReason } = useTextReasonModal()

  const loadBreaks = useCallback(async () => {
    if (!selectedCashDeskId) return
    try {
      setLoading(true)
      setError(null)
      const [data, active] = await Promise.all([
        cashDeskBreakApi.list(selectedCashDeskId),
        cashDeskBreakApi.getActive(selectedCashDeskId).catch(() => null),
      ])
      setBreaks(data)
      setActiveBreak(active ?? data.find((b) => !b.breakEnd && b.isActive) ?? null)
    } catch (err) {
      logger.error('CashDeskBreakPage', 'Szünetek betöltési hiba:', err)
      setError('Hiba a szünetek betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [selectedCashDeskId])

  useEffect(() => {
    void loadCashDesks()
  }, [])

  useEffect(() => {
    if (selectedCashDeskId) {
      void loadBreaks()
    }
  }, [selectedCashDeskId, loadBreaks])

  const loadCashDesks = async () => {
    try {
      const data = await cashDeskApi.list()
      setCashDesks(data)
      if (data.length > 0) {
        setSelectedCashDeskId(data[0]?.id ?? '')
      }
    } catch (err) {
      logger.error('CashDeskBreakPage', 'Pénztárak betöltési hiba:', err)
      setError('Hiba a pénztárak betöltésekor')
    }
  }

  const handleStartBreak = async () => {
    if (!selectedCashDeskId) {
      toast.warning('Hiányzó adat', 'Kérjük, válasszon pénztárat')
      return
    }
    // Szigorúan szekvenciális: a hook egyszerre egy aktív kérést kezel, ezért a
    // második kérdés csak az első teljesülése után indulhat.
    const breakType = await requestReason({ title: 'Szünet típusa (pl: LUNCH, BREAK):' })
    // Kötelező mező: a null (Mégse) ÉS az üres string egyaránt teljes megszakítás,
    // a második kérdésig el sem jut a művelet.
    if (!breakType) return
    // Opcionális: a null és az üres string egyaránt undefined-ként megy tovább,
    // a szünet indítása ettől függetlenül megtörténik.
    const reason = (await requestReason({ title: 'Ok (opcionális):' })) || undefined
    try {
      setError(null)
      await cashDeskBreakApi.start(selectedCashDeskId, breakType, reason)
      await loadBreaks()
    } catch (err) {
      logger.error('CashDeskBreakPage', 'Szünet indítási hiba:', err)
      setError('Hiba történt a szünet indítása során')
    }
  }

  const handleEndBreak = async (breakId: string) => {
    try {
      setError(null)
      await cashDeskBreakApi.end(breakId)
      await loadBreaks()
    } catch (err) {
      logger.error('CashDeskBreakPage', 'Szünet befejezési hiba:', err)
      setError('Hiba történt a szünet befejezése során')
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">{i18n.t('literals.betoltes')}</div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Clock />
          {t('cashdesk.penztarSzunetek')}
        </h1>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="form-panel space-y-4">
        <div>
          <label className="form-label">{t('branch.branch')}</label>
          <select
            className="form-input"
            value={selectedCashDeskId}
            onChange={(e) => setSelectedCashDeskId(e.target.value)}
          >
            {cashDesks.map((cd) => (
              <option key={cd.id} value={cd.id}>
                {cd.name}
              </option>
            ))}
          </select>
        </div>

        {activeBreak ? (
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
            <div className="flex justify-between items-center">
              <div>
                <h3 className="font-bold text-yellow-800">{t('cashdesk.aktivSzunet')}</h3>
                <p className="text-sm text-yellow-600">
                  {t('cashdesk.kezdes')}
                  {new Date(activeBreak.breakStart).toLocaleString('hu-HU')}
                </p>
                <p className="text-sm text-yellow-600">
                  {t('cashdesk.tipus')}
                  {activeBreak.breakType}
                </p>
                {activeBreak.reason && (
                  <p className="text-sm text-yellow-600">
                    {t('cashdesk.ok')} {activeBreak.reason}
                  </p>
                )}
              </div>
              <button
                onClick={() => handleEndBreak(activeBreak.id)}
                className="form-button-primary flex items-center gap-2"
              >
                <Square size={16} />
                {t('cashdesk.szunetBefejezese')}
              </button>
            </div>
          </div>
        ) : (
          <button
            onClick={handleStartBreak}
            className="form-button-primary flex items-center gap-2"
          >
            <Play size={16} />
            {t('cashdesk.szunetInditasa')}
          </button>
        )}
      </div>

      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('archiving.kezdes')}</th>
              <th>{t('cashdesk.veg')}</th>
              <th>{t('common.type')}</th>
              <th>{t('cashdesk.ok')}</th>
              <th>{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {breaks.length === 0 ? (
              <tr>
                <td colSpan={5} className="text-center text-gray-500 py-4">
                  {t('cashdesk.nincsSzunet')}
                </td>
              </tr>
            ) : (
              breaks.map((b) => (
                <tr key={b.id}>
                  <td>{new Date(b.breakStart).toLocaleString('hu-HU')}</td>
                  <td>{b.breakEnd ? new Date(b.breakEnd).toLocaleString('hu-HU') : '-'}</td>
                  <td>{b.breakType}</td>
                  <td>{b.reason || '-'}</td>
                  <td>
                    {!b.breakEnd && (
                      <button onClick={() => handleEndBreak(b.id)} className="form-button text-xs">
                        <Square size={12} />
                        {t('archiving.befejezes')}
                      </button>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
      {reasonModal}
    </div>
  )
}
