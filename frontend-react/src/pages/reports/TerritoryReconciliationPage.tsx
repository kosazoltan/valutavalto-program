import { useCallback, useEffect, useMemo, useState } from 'react'
import { AlertTriangle, CheckCircle2, Plus, RefreshCw, Scale } from 'lucide-react'
import {
  territoryReconciliationApi,
  type TerritoryProfitSummary,
  type TerritoryReconciliation,
  type VaultTerritory,
} from '../../services/api/territoryReconciliation'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import i18n from '../../i18n'

const fmt = (n: number | string | undefined | null) =>
  `${Number(n ?? 0).toLocaleString('hu-HU', { maximumFractionDigits: 0 })} Ft`

const currentMonth = () => new Date().toISOString().slice(0, 7)

const monthRange = (yearMonth: string) => {
  const [yearText, monthText] = yearMonth.split('-')
  const year = Number(yearText)
  const month = Number(monthText)
  if (!Number.isInteger(year) || !Number.isInteger(month) || month < 1 || month > 12) {
    return null
  }
  const lastDay = new Date(year, month, 0).getDate()
  return {
    from: `${yearText}-${monthText}-01`,
    to: `${yearText}-${monthText}-${String(lastDay).padStart(2, '0')}`,
  }
}

/**
 * Területi reconciliation + értéktári átértékelés lecsorgatása a pénztárakra.
 * terület MNB-összhaszon = Σ(pénztár tiszta WAC-marzs) + Σ(allokált átértékelés).
 */
export default function TerritoryReconciliationPage() {
  const [territoryId, setTerritoryId] = useState('20')
  const [yearMonth, setYearMonth] = useState(currentMonth())
  const [data, setData] = useState<TerritoryReconciliation | null>(null)
  const [territories, setTerritories] = useState<VaultTerritory[]>([])
  const [selectedTerritory, setSelectedTerritory] = useState<VaultTerritory | null>(null)
  const [profitSummary, setProfitSummary] = useState<TerritoryProfitSummary | null>(null)
  const [newTerritoryName, setNewTerritoryName] = useState('')
  const [newBaseCapital, setNewBaseCapital] = useState('')
  const [newApprovedAt, setNewApprovedAt] = useState('')
  const [loading, setLoading] = useState(false)
  const [territoryLoading, setTerritoryLoading] = useState(false)
  const [creating, setCreating] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const selectedId = useMemo(() => {
    const parsed = parseInt(territoryId, 10)
    return Number.isNaN(parsed) ? null : parsed
  }, [territoryId])

  const range = useMemo(() => monthRange(yearMonth), [yearMonth])

  const loadTerritoryContext = useCallback(
    async (id: number, profitRange = range) => {
      try {
        setTerritoryLoading(true)
        const [detail, profit] = await Promise.all([
          territoryReconciliationApi.getTerritory(id),
          profitRange
            ? territoryReconciliationApi.getTerritoryProfit(id, profitRange.from, profitRange.to)
            : Promise.resolve(null),
        ])
        setSelectedTerritory(detail)
        setProfitSummary(profit)
      } catch (err) {
        setSelectedTerritory(null)
        setProfitSummary(null)
        setError(getErrorMessage(err))
        logger.error('TerritoryReconciliationPage', 'loadTerritoryContext', err)
      } finally {
        setTerritoryLoading(false)
      }
    },
    [range],
  )

  const loadTerritories = useCallback(async () => {
    try {
      setTerritoryLoading(true)
      setError(null)
      const rows = await territoryReconciliationApi.listTerritories()
      setTerritories(rows)
      const initialId = selectedId ?? rows[0]?.id
      if (initialId != null) {
        if (selectedId == null) setTerritoryId(String(initialId))
        await loadTerritoryContext(initialId)
      }
    } catch (err) {
      setTerritories([])
      setSelectedTerritory(null)
      setProfitSummary(null)
      setError(getErrorMessage(err))
      logger.error('TerritoryReconciliationPage', 'loadTerritories', err)
    } finally {
      setTerritoryLoading(false)
    }
  }, [loadTerritoryContext, selectedId])

  useEffect(() => {
    void loadTerritories()
  }, [loadTerritories])

  const load = useCallback(async () => {
    if (selectedId == null) {
      setError('Adj meg érvényes terület-azonosítót.')
      return
    }
    if (!range) {
      setError('Adj meg érvényes hónapot.')
      return
    }

    try {
      setLoading(true)
      setError(null)
      const [report] = await Promise.all([
        territoryReconciliationApi.get(selectedId, yearMonth),
        loadTerritoryContext(selectedId, range),
      ])
      setData(report)
    } catch (err) {
      setError(getErrorMessage(err))
      logger.error('TerritoryReconciliationPage', 'load', err)
    } finally {
      setLoading(false)
    }
  }, [loadTerritoryContext, range, selectedId, yearMonth])

  const createTerritory = async () => {
    const name = newTerritoryName.trim()
    const baseCapital = Number(newBaseCapital)
    if (name.length < 2 || !Number.isFinite(baseCapital) || baseCapital < 0) {
      setError('A terület neve legalább 2 karakter, az alaptőke nemnegatív szám legyen.')
      return
    }

    try {
      setCreating(true)
      setError(null)
      const created = await territoryReconciliationApi.createTerritory({
        name,
        baseCapital,
        baseCapitalApprovedAt: newApprovedAt || undefined,
      })
      setNewTerritoryName('')
      setNewBaseCapital('')
      setNewApprovedAt('')
      setTerritoryId(String(created.id))
      await loadTerritories()
      await loadTerritoryContext(created.id)
    } catch (err) {
      setError(getErrorMessage(err))
      logger.error('TerritoryReconciliationPage', 'createTerritory', err)
    } finally {
      setCreating(false)
    }
  }

  const currencyProfitRows = Object.entries(profitSummary?.profitByCurrency ?? {})

  return (
    <div className="space-y-4">
      <div className="form-panel space-y-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <h1 className="form-title flex min-w-0 items-center gap-2 text-base sm:text-xl">
            <Scale className="h-6 w-6 shrink-0" />
            <span>{i18n.t('literals.teruleti-reconciliation')}</span>
          </h1>
          <button
            type="button"
            onClick={() => void loadTerritories()}
            disabled={territoryLoading}
            className="form-button-secondary inline-flex min-h-10 items-center justify-center gap-1"
          >
            <RefreshCw className={`h-4 w-4 ${territoryLoading ? 'animate-spin' : ''}`} />
            {i18n.t('literals.teruletek-frissitese')}
          </button>
        </div>

        <div className="grid gap-3 lg:grid-cols-[minmax(0,1fr)_minmax(280px,360px)]">
          <section className="rounded border border-slate-200 bg-white p-3">
            <h2 className="mb-3 text-sm font-semibold text-slate-800">
              {i18n.t('literals.terulet-kivalasztasa-es-havi-ellenorzes')}
            </h2>
            <div className="grid gap-3 sm:grid-cols-[minmax(0,1fr)_160px_auto] sm:items-end">
              <div>
                <label className="form-label" htmlFor="territory-select">
                  {i18n.t('literals.terulet')}
                </label>
                <select
                  id="territory-select"
                  className="form-input min-w-0"
                  value={territoryId}
                  onChange={(event) => {
                    setTerritoryId(event.target.value)
                    const parsed = Number(event.target.value)
                    if (Number.isInteger(parsed)) void loadTerritoryContext(parsed)
                  }}
                >
                  {territories.length === 0 && (
                    <option value={territoryId}>
                      {i18n.t('literals.lit-12')}
                      {territoryId}
                    </option>
                  )}
                  {territories.map((territory) => (
                    <option key={territory.id} value={territory.id}>
                      {territory.name}
                      {i18n.t('literals.lit-54')}
                      {territory.id}
                      {i18n.t('literals.lit-2')}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="form-label" htmlFor="territory-month">
                  {i18n.t('literals.honap')}
                </label>
                <input
                  id="territory-month"
                  type="month"
                  className="form-input w-full"
                  value={yearMonth}
                  onChange={(event) => setYearMonth(event.target.value)}
                />
              </div>
              <button
                type="button"
                onClick={() => void load()}
                disabled={loading}
                className="form-button-primary inline-flex min-h-10 items-center justify-center gap-1"
              >
                <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
                {i18n.t('literals.lekerdez')}
              </button>
            </div>

            <div className="mt-3 grid gap-2 sm:grid-cols-3">
              <InfoCell
                label="Terület neve"
                value={selectedTerritory?.name ?? 'Nincs betöltve'}
                loading={territoryLoading}
              />
              <InfoCell
                label="Alaptőke"
                value={selectedTerritory ? fmt(selectedTerritory.baseCapital) : '-'}
              />
              <InfoCell
                label="Jóváhagyva"
                value={selectedTerritory?.baseCapitalApprovedAt ?? '-'}
              />
            </div>
          </section>

          <section className="rounded border border-slate-200 bg-white p-3">
            <h2 className="mb-3 text-sm font-semibold text-slate-800">
              {i18n.t('literals.uj-terulet')}
            </h2>
            <div className="space-y-2">
              <div>
                <label className="form-label" htmlFor="new-territory-name">
                  {i18n.t('literals.nev')}
                </label>
                <input
                  id="new-territory-name"
                  className="form-input w-full"
                  value={newTerritoryName}
                  onChange={(event) => setNewTerritoryName(event.target.value)}
                  placeholder="Terület neve"
                />
              </div>
              <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-1">
                <div>
                  <label className="form-label" htmlFor="new-base-capital">
                    {i18n.t('literals.alaptoke')}
                  </label>
                  <input
                    id="new-base-capital"
                    type="number"
                    min="0"
                    className="form-input w-full"
                    value={newBaseCapital}
                    onChange={(event) => setNewBaseCapital(event.target.value)}
                  />
                </div>
                <div>
                  <label className="form-label" htmlFor="new-approved-at">
                    {i18n.t('literals.jovahagyas-datuma')}
                  </label>
                  <input
                    id="new-approved-at"
                    type="date"
                    className="form-input w-full"
                    value={newApprovedAt}
                    onChange={(event) => setNewApprovedAt(event.target.value)}
                  />
                </div>
              </div>
              <button
                type="button"
                onClick={() => void createTerritory()}
                disabled={creating}
                className="form-button-secondary inline-flex min-h-10 w-full items-center justify-center gap-1"
              >
                <Plus className="h-4 w-4" />
                {creating ? 'Mentés...' : 'Terület létrehozása'}
              </button>
            </div>
          </section>
        </div>

        {error && (
          <div className="form-error flex items-center gap-2">
            <AlertTriangle className="h-4 w-4 shrink-0" />
            <span className="min-w-0 break-words">{error}</span>
          </div>
        )}
      </div>

      {profitSummary && (
        <section className="form-panel space-y-3">
          <h2 className="text-sm font-semibold text-slate-800">
            {i18n.t('literals.teruleti-wac-profit-osszesito')}
          </h2>
          <div className="grid gap-3 sm:grid-cols-4">
            <InfoCell label="Összprofit" value={fmt(profitSummary.totalProfit)} />
            <InfoCell label="Tranzakció" value={profitSummary.transactionCount} />
            <InfoCell label="Eladás" value={profitSummary.sellCount} />
            <InfoCell label="Vétel" value={profitSummary.buyCount} />
          </div>
          {currencyProfitRows.length > 0 && (
            <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
              {currencyProfitRows.map(([currencyCode, profit]) => (
                <InfoCell key={currencyCode} label={currencyCode} value={fmt(profit)} />
              ))}
            </div>
          )}
        </section>
      )}

      {data && (
        <div className="form-panel space-y-4">
          <div className="grid gap-3 sm:grid-cols-3">
            <InfoCell label="Σ pénztári WAC-marzs" value={fmt(data.territoryRealizedMargin)} />
            <InfoCell
              label="Értéktári átértékelés (MNB - WAC)"
              value={fmt(data.territoryRevaluation)}
              tone={data.territoryRevaluation < 0 ? 'danger' : 'ok'}
            />
            <InfoCell label="Terület MNB-összhaszon" value={fmt(data.territoryTotalProfit)} />
          </div>

          <div
            className={`flex items-center gap-2 text-sm ${data.reconciliationOk ? 'text-green-700' : 'text-red-600'}`}
          >
            {data.reconciliationOk ? (
              <CheckCircle2 className="h-4 w-4" />
            ) : (
              <AlertTriangle className="h-4 w-4" />
            )}
            {data.reconciliationOk
              ? 'Reconciliation OK: Σ pénztár összhaszon = terület összhaszon'
              : 'Reconciliation eltérés!'}
          </div>

          <div className="grid gap-2 md:hidden">
            {data.cashiers.map((cashier) => (
              <div key={cashier.branchId} className="rounded border border-slate-200 bg-white p-3">
                <div className="text-sm font-semibold text-slate-900">
                  {cashier.branchCode}
                  {i18n.t('literals.lit-17')}
                  {cashier.branchName}
                </div>
                <div className="mt-2 grid grid-cols-2 gap-2 text-sm">
                  <InfoCell label="WAC-marzs" value={fmt(cashier.realizedMargin)} />
                  <InfoCell
                    label="Átértékelés"
                    value={fmt(cashier.allocatedRevaluation)}
                    tone={cashier.allocatedRevaluation < 0 ? 'danger' : 'ok'}
                  />
                  <InfoCell label="Összhaszon" value={fmt(cashier.totalProfit)} />
                </div>
              </div>
            ))}
          </div>

          <div className="data-grid hidden overflow-x-auto md:block">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                    {i18n.t('literals.penztar-2')}
                  </th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                    {i18n.t('literals.tiszta-wac-marzs')}
                  </th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                    {i18n.t('literals.allokalt-atertekeles')}
                  </th>
                  <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                    {i18n.t('literals.osszhaszon')}
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {data.cashiers.map((cashier) => (
                  <tr key={cashier.branchId}>
                    <td className="px-3 py-2 text-sm">
                      {cashier.branchCode}
                      {i18n.t('literals.lit-17')}
                      {cashier.branchName}
                    </td>
                    <td className="px-3 py-2 text-right font-mono text-sm">
                      {fmt(cashier.realizedMargin)}
                    </td>
                    <td
                      className={`px-3 py-2 text-right font-mono text-sm ${cashier.allocatedRevaluation < 0 ? 'text-red-600' : ''}`}
                    >
                      {fmt(cashier.allocatedRevaluation)}
                    </td>
                    <td className="px-3 py-2 text-right font-mono text-sm font-bold">
                      {fmt(cashier.totalProfit)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {data.currencyRevaluations.length > 0 && (
            <div className="data-grid overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.valuta')}
                    </th>
                    <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.ertektari-keszlet')}
                    </th>
                    <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.wac')}
                    </th>
                    <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.mnb')}
                    </th>
                    <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                      {i18n.t('literals.atertekeles')}
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {data.currencyRevaluations.map((row) => (
                    <tr key={row.currencyCode}>
                      <td className="px-3 py-2 font-mono text-sm">{row.currencyCode}</td>
                      <td className="px-3 py-2 text-right font-mono text-sm">
                        {(row.vaultHeldQty ?? 0).toLocaleString('hu-HU')}
                      </td>
                      <td className="px-3 py-2 text-right font-mono text-sm">
                        {row.weightedAvgCost}
                      </td>
                      <td className="px-3 py-2 text-right font-mono text-sm">{row.mnbRate}</td>
                      <td
                        className={`px-3 py-2 text-right font-mono text-sm ${row.revaluation < 0 ? 'text-red-600' : 'text-green-700'}`}
                      >
                        {fmt(row.revaluation)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

function InfoCell({
  label,
  value,
  loading,
  tone,
}: {
  label: string
  value: string | number
  loading?: boolean
  tone?: 'ok' | 'danger'
}) {
  const toneClass =
    tone === 'danger' ? 'text-red-600' : tone === 'ok' ? 'text-green-700' : 'text-slate-900'

  return (
    <div className="rounded border border-slate-200 bg-slate-50 p-3">
      <div className="text-xs text-slate-500">{label}</div>
      <div className={`mt-1 min-w-0 break-words text-sm font-semibold ${toneClass}`}>
        {loading ? 'Betöltés...' : value}
      </div>
    </div>
  )
}
