import { useEffect, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { api, cashBalanceApi, type DetailedCashPosition } from '@/services/api/index'
import { safeArray } from '@/utils/safeArray'
import i18n from '../../i18n'

interface CurrencyLine {
  currencyCode: string
  currencyName: string
  opening: number
  income: number
  expense: number
  closing: number
}

interface LiveCashPosition {
  branchId: string
  date: string
  lines: CurrencyLine[]
  handlingFeeHuf: number
}

const fmt = (n: number) => (n ?? 0).toLocaleString('hu-HU')

export default function LiveCashPositionPage() {
  const navigate = useNavigate()
  const [data, setData] = useState<LiveCashPosition | null>(null)
  const [position, setPosition] = useState<DetailedCashPosition | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  // FR-PA-04: külön "Kezelési díj nyomtatása" — ilyenkor csak a díj-blokk nyomtatódik (CSS print-mód).
  const [feePrintOnly, setFeePrintOnly] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const [response, detailedPosition] = await Promise.all([
        api.get('/reports/live-cash-position'),
        cashBalanceApi.getDetailedPosition().catch(() => null),
      ])
      setData(response?.data ?? null)
      setPosition(detailedPosition)
    } catch {
      setError('A pillanatnyi pénztárállás lekérése sikertelen.')
      setData(null)
      setPosition(null)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  // FR-PA-04: a díj-only nyomtatás a state beállítása UTÁN fut (a CSS print-osztály már érvényes), majd
  // visszaáll. Codex P2: csak akkor nyomtatunk, ha a friss adat MÁR betöltött (különben 0 Ft-os fals díj).
  useEffect(() => {
    if (!feePrintOnly) return
    if (data) window.print()
    setFeePrintOnly(false)
  }, [feePrintOnly, data])

  // FR-PA-04: "VISSZA A FŐMENÜRE (Escape)". Codex P2 (#1033): explicit FIX route a pénztáros-főmenühöz
  // (/cashier, ld. DayOpenPage konvenció), NEM navigate(-1) — a history-alapú vissza a riport-listára (vagy
  // közvetlen/bookmark-látogatásnál idegen bejegyzésre) vinne, nem a spec által ígért főmenüre.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/cashier')
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [navigate])

  const lines = safeArray<CurrencyLine>(data?.lines)
  const feeHuf = data?.handlingFeeHuf ?? 0
  const totalHufValue = position?.totalHufValue ?? 0
  const totalDailyChangeHuf = position?.totalDailyChangeHuf ?? 0
  const alertCount = (position?.lowBalanceAlerts ?? 0) + (position?.highBalanceAlerts ?? 0)

  return (
    <div className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-3 print:hidden">
        <h1 className="text-lg font-bold">
          {i18n.t('literals.a-pillanatnyi-penztarallas-kimutatasa')}
        </h1>
        <div className="flex gap-2">
          <button
            onClick={() => void load()}
            className="px-3 py-2 bg-gray-100 rounded hover:bg-gray-200"
          >
            {i18n.t('literals.frissites')}
          </button>
          <button
            onClick={() => window.print()}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            {i18n.t('literals.pillanatnyi-allas-kinyomtatasa')}
          </button>
          <button
            onClick={() => setFeePrintOnly(true)}
            disabled={loading || !data}
            className="px-4 py-2 bg-emerald-600 text-white rounded hover:bg-emerald-700 disabled:opacity-50"
          >
            {i18n.t('literals.kezelesi-dij-nyomtatasa')}
          </button>
          <button
            onClick={() => navigate('/cashier')}
            className="px-4 py-2 bg-gray-200 rounded hover:bg-gray-300"
          >
            {i18n.t('literals.vissza-esc')}
          </button>
        </div>
      </div>

      {data?.date && (
        <div className="mb-2 text-sm text-gray-600">
          {i18n.t('literals.datum-3')}
          {data.date}
        </div>
      )}

      {position && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-3 print:hidden">
          <div className="bg-white rounded border p-3">
            <div className="text-xs text-gray-500">{i18n.t('literals.keszlet-huf-egyenertek')}</div>
            <div className="text-lg font-bold text-gray-900">
              {fmt(totalHufValue)}
              {i18n.t('literals.ft')}
            </div>
          </div>
          <div className="bg-white rounded border p-3">
            <div className="text-xs text-gray-500">{i18n.t('literals.napi-valtozas-huf')}</div>
            <div
              className={`text-lg font-bold ${totalDailyChangeHuf >= 0 ? 'text-green-700' : 'text-red-700'}`}
            >
              {fmt(totalDailyChangeHuf)}
              {i18n.t('literals.ft')}
            </div>
          </div>
          <div className="bg-white rounded border p-3">
            <div className="text-xs text-gray-500">{i18n.t('literals.valutak')}</div>
            <div className="text-lg font-bold text-gray-900">{position.currencyCount}</div>
          </div>
          <div className="bg-white rounded border p-3">
            <div className="text-xs text-gray-500">{i18n.t('literals.keszlet-riasztasok')}</div>
            <div
              className={`text-lg font-bold ${alertCount > 0 ? 'text-amber-700' : 'text-gray-900'}`}
            >
              {alertCount}
            </div>
          </div>
        </div>
      )}

      {/* FR-PA-04: külön kezelési-díj bizonylat — csak fee-print módban látszik (egyébként a teljes táblázat). */}
      {feePrintOnly ? (
        <div className="bg-white rounded border p-4">
          <h2 className="text-base font-bold mb-2">{i18n.t('literals.kezelesi-dij-kimutatas')}</h2>
          {data?.date && (
            <div className="text-sm text-gray-600 mb-2">
              {i18n.t('literals.datum-3')}
              {data.date}
            </div>
          )}
          <div className="text-right text-sm">
            {i18n.t('literals.kezelesi-dij-mai-egyenleg')}
            <strong>
              {fmt(feeHuf)}
              {i18n.t('literals.ft')}
            </strong>
          </div>
        </div>
      ) : loading ? (
        <div className="text-center py-8">{i18n.t('literals.betoltes')}</div>
      ) : error ? (
        <div className="p-4 bg-red-50 border border-red-200 text-red-700 rounded">{error}</div>
      ) : lines.length === 0 && feeHuf === 0 ? (
        // Codex P2 (#1033): csak akkor "nincs mozgás", ha SEM készlet-sor, SEM kezelési díj nincs. A backend
        // a lines-t a DailyBalance-ből, a feeHuf-ot a DailySubledgerSnapshot-ból FÜGGETLENÜL építi, így lehet
        // nonzero díj nulla készlet-sor mellett — ekkor a táblázat-ág a dedikált díj-sort rendereli.
        <div className="text-center py-8 text-gray-500">
          {i18n.t('literals.nincs-mai-napi-penztarmozgas')}
        </div>
      ) : (
        <div className="bg-white rounded border">
          <table className="w-full text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-2 text-left">{i18n.t('literals.vnem')}</th>
                <th className="p-2 text-left">{i18n.t('literals.valuta-neve')}</th>
                <th className="p-2 text-right">{i18n.t('literals.nyito-2')}</th>
                <th className="p-2 text-right">{i18n.t('literals.bevetel-2')}</th>
                <th className="p-2 text-right">{i18n.t('literals.kiadas')}</th>
                <th className="p-2 text-right">{i18n.t('literals.kez-i-dij')}</th>
                <th className="p-2 text-right">{i18n.t('literals.zaro')}</th>
              </tr>
            </thead>
            <tbody>
              {lines.map((l) => {
                const isHuf = l.currencyCode === 'HUF'
                return (
                  // FR-PA-03: a HUF sort zölddel kiemeljük, a deviza-sorok ZÁRÓ értékét pirossal formázzuk.
                  <tr key={l.currencyCode} className={`border-t ${isHuf ? 'bg-green-50' : ''}`}>
                    <td className="p-2 font-mono">{l.currencyCode}</td>
                    <td className="p-2">{l.currencyName}</td>
                    <td className="p-2 text-right">{fmt(l.opening)}</td>
                    <td className="p-2 text-right">{fmt(l.income)}</td>
                    <td className="p-2 text-right">{fmt(l.expense)}</td>
                    {/* KEZ-I DÍJ: a kezelési díj HUF-alapú subledger-egyenleg, ezért a HUF soron jelenik meg
                        (a devizasorokon nincs külön per-valuta díj-attribúció az adatmodellben). */}
                    <td className="p-2 text-right">{isHuf ? fmt(feeHuf) : ''}</td>
                    <td
                      className={`p-2 text-right font-semibold ${isHuf ? 'text-green-700' : 'text-red-600'}`}
                    >
                      {fmt(l.closing)}
                    </td>
                  </tr>
                )
              })}
              {/* Codex P2: ha NINCS HUF készlet-sor (pl. csak deviza pozíció), a kezelési díj akkor is
                  látszódjon a KEZ-I DÍJ oszlopban — egy dedikált díj-sorral. */}
              {feeHuf !== 0 && !lines.some((l) => l.currencyCode === 'HUF') && (
                <tr className="border-t bg-green-50">
                  <td className="p-2 font-mono">{i18n.t('literals.huf')}</td>
                  <td className="p-2">{i18n.t('literals.kezelesi-dij')}</td>
                  <td className="p-2 text-right">{i18n.t('literals.lit-8')}</td>
                  <td className="p-2 text-right">{i18n.t('literals.lit-8')}</td>
                  <td className="p-2 text-right">{i18n.t('literals.lit-8')}</td>
                  <td className="p-2 text-right">{fmt(feeHuf)}</td>
                  <td className="p-2 text-right">{i18n.t('literals.lit-8')}</td>
                </tr>
              )}
            </tbody>
          </table>
          <div className="p-3 border-t bg-gray-50 text-sm">
            <div className="text-right">
              {i18n.t('literals.kezelesi-dij-mai-egyenleg')}
              <strong>
                {fmt(feeHuf)}
                {i18n.t('literals.ft')}
              </strong>
            </div>
            {/* Codex P2 (#1033): a KEZ-I DÍJ a kezelési-díj alszámla (DailySubledgerSnapshot) napi egyenlege,
                amit a backend a per-valuta készlet-mérlegtől (DailyBalance) FÜGGETLENÜL épít. NEM a
                készpénz-mozgás egyik tagja: a per-valuta NYITÓ + BEVÉTEL − KIADÁS = ZÁRÓ egyenlet a
                díj NÉLKÜL áll fenn; a KEZ-I DÍJ külön, tájékoztató figura (ezért a "*"). */}
            <div className="mt-1 text-left text-xs text-gray-500">
              {i18n.t('literals.a-kez-i-dij-a-kezelesi-dij-alszamla-napi')}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
