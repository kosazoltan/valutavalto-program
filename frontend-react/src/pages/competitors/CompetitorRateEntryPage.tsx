import { useEffect, useRef, useState, type FormEvent } from 'react'
import { useTranslation } from 'react-i18next'
import { Store } from 'lucide-react'
import {
  competitorRatesApi,
  getPublicWebUrl,
  type CompetitorWatchBootstrap,
  type CompetitorRateLine,
} from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import PwaInstallHelp from './PwaInstallHelp'

type RateInput = { buy: string; sell: string }

/**
 * FK-041/II — versenytárs-árfolyam BEVITEL oldal az „árfolyam néző" szerepkörnek (mobil/PWA-barát).
 * A hívó a területén (régió) lévő versenyhelyek vétel/eladás árfolyamait rögzíti a figyelt
 * valutakosárra; a bevitt adat a főértéktáros konkurencia-árfolyam adatlapján jelenik meg.
 */
export default function CompetitorRateEntryPage() {
  const { t } = useTranslation()
  const [bootstrap, setBootstrap] = useState<CompetitorWatchBootstrap | null>(null)
  const [loading, setLoading] = useState(true)
  const [competitorId, setCompetitorId] = useState('')
  const [rows, setRows] = useState<Record<number, RateInput>>({})
  const [saving, setSaving] = useState(false)
  // FK-041/II race-guard: a legutóbb kiválasztott versenyhely id-je. A today() prefill async válasza
  // CSAK akkor kerül alkalmazásra, ha még mindig ez a kiválasztott versenyhely — gyors A→B váltásnál
  // a késve beérkező A-válasz NE írja felül B sorait (különben A árfolyamai mehetnének B-hez).
  const latestCompetitorRef = useRef<string>('')

  useEffect(() => {
    void (async () => {
      try {
        setBootstrap(await competitorRatesApi.bootstrap())
      } catch (err) {
        logger.error('CompetitorRateEntryPage', 'Bootstrap betöltési hiba:', err)
        toast.error(t('competitorRates.betoltesiHiba'), getErrorMessage(err))
      } finally {
        setLoading(false)
      }
    })()
  }, [t])

  const onSelectCompetitor = async (id: string) => {
    setCompetitorId(id)
    latestCompetitorRef.current = id
    setRows({})
    if (!id) return
    try {
      const today = await competitorRatesApi.today(id)
      // Stale válasz eldobása: időközben másik (vagy üres) versenyhelyre váltottak.
      if (latestCompetitorRef.current !== id) return
      const next: Record<number, RateInput> = {}
      today.forEach((r) => {
        next[r.currencyId] = {
          buy: r.buyRate != null ? String(r.buyRate) : '',
          sell: r.sellRate != null ? String(r.sellRate) : '',
        }
      })
      setRows(next)
    } catch (err) {
      // A már nem aktuális kiválasztás hibáját elnyeljük (a user továbblépett).
      if (latestCompetitorRef.current !== id) return
      logger.error('CompetitorRateEntryPage', 'Mai árfolyamok betöltési hiba:', err)
      toast.error(t('competitorRates.betoltesiHiba'), getErrorMessage(err))
    }
  }

  const patchRow = (currencyId: number, patch: Partial<RateInput>) =>
    setRows((current) => ({
      ...current,
      [currencyId]: { buy: '', sell: '', ...current[currencyId], ...patch },
    }))

  const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (!competitorId) {
      toast.warning(t('competitorRates.valasszVersenyhelyetFigyelmeztetes'))
      return
    }
    const allRows = (bootstrap?.currencies ?? []).map((c) => ({
      currencyId: c.id,
      buy: rows[c.id]?.buy?.trim().replace(',', '.') ?? '',
      sell: rows[c.id]?.sell?.trim().replace(',', '.') ?? '',
    }))

    // Részlegesen kitöltött sor (csak vétel VAGY csak eladás) NE vesszen el némán — jelezzük.
    if (allRows.some((l) => (l.buy !== '') !== (l.sell !== ''))) {
      toast.warning(t('competitorRates.felKitoltottSor'))
      return
    }

    const lines: CompetitorRateLine[] = allRows
      .filter((l) => l.buy !== '' && l.sell !== '')
      .map((l) => ({ currencyId: l.currencyId, buyRate: Number(l.buy), sellRate: Number(l.sell) }))

    if (lines.length === 0) {
      toast.warning(t('competitorRates.toltsKiLegalabbEgyet'))
      return
    }
    if (lines.some((l) => !Number.isFinite(l.buyRate) || !Number.isFinite(l.sellRate))) {
      toast.warning(t('competitorRates.ervenytelenSzam'))
      return
    }

    setSaving(true)
    try {
      await competitorRatesApi.submit({ competitorId, rates: lines })
      toast.success(t('competitorRates.mentve'))
    } catch (err) {
      logger.error('CompetitorRateEntryPage', 'Beküldési hiba:', err)
      toast.error(t('competitorRates.hiba'), getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  const currencies = bootstrap?.currencies ?? []
  const competitors = bootstrap?.competitors ?? []

  return (
    <div
      className="mx-auto flex w-full max-w-2xl flex-col gap-4 p-4"
      data-testid="competitor-rate-entry"
    >
      <header className="flex items-center gap-2">
        <Store className="text-blue-700" size={22} />
        <div>
          <h1 className="text-lg font-bold text-gray-800">{t('competitorRates.cim')}</h1>
          <p className="text-xs text-gray-500">{t('competitorRates.leiras')}</p>
        </div>
      </header>

      {loading ? (
        <div className="form-panel text-center text-sm text-gray-500">
          {t('competitorRates.betoltes')}
        </div>
      ) : competitors.length === 0 ? (
        <div className="form-panel text-center text-sm text-gray-500" data-testid="no-competitors">
          {t('competitorRates.nincsVersenyhely')}
        </div>
      ) : (
        <form onSubmit={onSubmit} className="flex flex-col gap-4">
          <label className="block">
            <span className="form-label">{t('competitorRates.versenyhely')}</span>
            <select
              className="form-input w-full"
              value={competitorId}
              disabled={saving}
              onChange={(e) => void onSelectCompetitor(e.target.value)}
              data-testid="competitor-select"
            >
              <option value="">{t('competitorRates.valasszVersenyhelyet')}</option>
              {competitors.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                  {c.branchName ? ` — ${c.branchName}` : ''}
                </option>
              ))}
            </select>
          </label>

          {competitorId && (
            <div className="form-panel flex flex-col gap-3 p-3">
              {currencies.map((c) => (
                <div key={c.id} className="flex items-center gap-2">
                  <span className="w-14 font-mono text-base font-bold text-blue-800">{c.code}</span>
                  <label className="flex-1">
                    <span className="form-label text-[11px] text-green-700">
                      {t('competitorRates.vetel')}
                    </span>
                    <input
                      type="number"
                      inputMode="decimal"
                      step="0.0001"
                      className="form-input w-full"
                      value={rows[c.id]?.buy ?? ''}
                      disabled={saving}
                      onChange={(e) => patchRow(c.id, { buy: e.target.value })}
                      data-testid={`buy-${c.code}`}
                    />
                  </label>
                  <label className="flex-1">
                    <span className="form-label text-[11px] text-red-700">
                      {t('competitorRates.eladas')}
                    </span>
                    <input
                      type="number"
                      inputMode="decimal"
                      step="0.0001"
                      className="form-input w-full"
                      value={rows[c.id]?.sell ?? ''}
                      disabled={saving}
                      onChange={(e) => patchRow(c.id, { sell: e.target.value })}
                      data-testid={`sell-${c.code}`}
                    />
                  </label>
                </div>
              ))}
            </div>
          )}

          <button
            type="submit"
            disabled={saving || !competitorId}
            className="form-button-primary w-full py-3 text-base font-semibold"
            data-testid="submit-competitor-rates"
          >
            {saving ? t('competitorRates.mentes') : t('competitorRates.rogzites')}
          </button>
        </form>
      )}

      {/* FK-041/II: Electron kliensben a window.location.origin = app://localhost lokális lenne, amit a
          telefon nem tud megnyitni — a QR/URL a PUBLIKUS web-origint kell mutassa (mint a TreasuryDashboard). */}
      <PwaInstallHelp url={getPublicWebUrl()} />
    </div>
  )
}
