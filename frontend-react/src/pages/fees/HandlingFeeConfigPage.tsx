import { useCallback, useEffect, useMemo, useState } from 'react'
import { Wallet } from 'lucide-react'
import {
  branchFeeConfigApi,
  type BranchFeeConfigList,
  type BranchFeeConfigRow,
} from '../../services/api/settings'
import { useAuthStore } from '../../stores/authStore'
import { useAppMode } from '../../hooks/useAppMode'
import { logger } from '../../utils/logger'
import CashierFeeCard from './CashierFeeCard'
import BranchFeeEditorModal from './BranchFeeEditorModal'
import CommonBracketEditor from './CommonBracketEditor'
import i18n from '../../i18n'

const formatHuf = (value: number) => `${value.toLocaleString('hu-HU')} Ft`

const MODE_LABEL: Record<string, string> = {
  NONE: 'Nincs',
  BRACKET: 'Sávos',
  PER_MILLE: 'Ezrelékes',
}

/**
 * FK-096 WU-10 — „Kezelési költség beállítások" képernyő (TARTALOM CSERÉJE).
 * Ugyanaz a fájl, ugyanaz a default export, ugyanaz a route (App.tsx érintetlen).
 *
 * - pénztár mód (useAppMode) → read-only saját-iroda kártya (FR-14, élő HTTP, pitfall #15);
 * - egyébként → admin nézet: összefoglaló kártyák, régió-szűrő, iroda-tábla, modal;
 *   szerkesztés CSAK ugyvezeto/foertektar/admin (D10, szűkítve az 5 szereplős listáról).
 * - a korábbi probe-panelek (discount-threshold probe, backend díjpróba) ELTÁVOLÍTVA —
 *   a discountThresholdApi / handlingFeeTransactionApi más fogyasztói megmaradnak.
 */
export default function HandlingFeeConfigPage() {
  const { mode } = useAppMode()
  const canEdit = useAuthStore((s) => s.hasCanonicalRole)(['ugyvezeto', 'foertektar', 'admin'])

  // FR-14: pénztár módban CSAK a saját-iroda kártya jelenik meg.
  if (mode === 'penztar') {
    return (
      <div className="mx-auto max-w-2xl p-6">
        <CashierFeeCard />
      </div>
    )
  }

  return <AdminView canEdit={canEdit} />
}

function AdminView({ canEdit }: { canEdit: boolean }) {
  const [data, setData] = useState<BranchFeeConfigList | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [regionFilter, setRegionFilter] = useState<string>('all')
  const [selected, setSelected] = useState<BranchFeeConfigRow | null>(null)

  const load = useCallback(async () => {
    try {
      setData(await branchFeeConfigApi.list())
      setError(null)
    } catch (err) {
      setError('Az iroda-konfigurációk betöltése nem sikerült.')
      logger.error('HandlingFeeConfigPage', 'list hiba', err)
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const regions = useMemo(() => {
    if (!data) return []
    const values = new Set<string>()
    for (const row of data.rows) {
      if (row.region) values.add(row.region)
    }
    return [...values].sort()
  }, [data])

  const rows = useMemo(() => {
    if (!data) return []
    return regionFilter === 'all'
      ? data.rows
      : data.rows.filter((row) => row.region === regionFilter)
  }, [data, regionFilter])

  const handleChanged = (updated: BranchFeeConfigRow) => {
    setData((current) =>
      current
        ? {
            ...current,
            rows: current.rows.map((row) =>
              row.branchId === updated.branchId ? { ...row, ...updated } : row,
            ),
          }
        : current,
    )
    setSelected(null)
  }

  return (
    <div className="p-6">
      <div className="flex items-center gap-2">
        <Wallet size={20} />
        <h1 className="text-lg font-semibold text-gray-900">
          {i18n.t('literals.kezelesi-koltseg-beallitasok')}
        </h1>
      </div>

      {error && (
        <div className="mt-3 rounded border border-red-200 bg-red-50 p-3 text-sm text-red-800">
          {error}
        </div>
      )}

      {data && (
        <div className="mt-4 grid grid-cols-2 gap-3 md:grid-cols-4">
          <SummaryCard label="Összes pénztár" value={data.summary.totalBranches} />
          <SummaryCard label="KK beállítva" value={data.summary.configuredBranches} />
          <SummaryCard label="Sávos" value={data.summary.bracketBranches} />
          <SummaryCard label="Ezrelékes" value={data.summary.perMilleBranches} />
        </div>
      )}

      <div className="mt-4 flex items-center gap-3">
        <label className="text-sm text-gray-600" htmlFor="region-filter">
          {i18n.t('literals.terulet')}
        </label>
        <select
          id="region-filter"
          value={regionFilter}
          onChange={(event) => setRegionFilter(event.target.value)}
          className="rounded border border-gray-300 px-2 py-1 text-sm"
        >
          <option value="all">{i18n.t('literals.mind')}</option>
          {regions.map((region) => (
            <option key={region} value={region}>
              {region}
            </option>
          ))}
        </select>
      </div>

      <table className="mt-4 w-full text-left text-sm">
        <thead>
          <tr className="border-b text-gray-500">
            <th className="py-2 pr-3 font-medium">{i18n.t('literals.kod-3')}</th>
            <th className="py-2 pr-3 font-medium">{i18n.t('literals.penztar-neve')}</th>
            <th className="py-2 pr-3 font-medium">{i18n.t('literals.terulet')}</th>
            <th className="py-2 pr-3 font-medium">{i18n.t('literals.kk-tipus')}</th>
            <th className="py-2 pr-3 font-medium">{i18n.t('literals.mertek-2')}</th>
            <th className="py-2 pr-3 font-medium">{i18n.t('literals.maximum')}</th>
            <th className="py-2 font-medium">{i18n.t('literals.piszkozat')}</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr
              key={row.branchId}
              onClick={() => canEdit && setSelected(row)}
              className={
                canEdit
                  ? 'cursor-pointer border-b last:border-0 hover:bg-amber-50'
                  : 'border-b last:border-0'
              }
            >
              <td className="py-2 pr-3 font-medium">{row.branchCode}</td>
              <td className="py-2 pr-3">{row.branchName}</td>
              <td className="py-2 pr-3">{row.region ?? '—'}</td>
              <td className="py-2 pr-3">
                {row.liveFeeMode ? (MODE_LABEL[row.liveFeeMode] ?? row.liveFeeMode) : 'Nincs'}
              </td>
              <td className="py-2 pr-3">
                {row.liveFeeMode === 'PER_MILLE' && row.livePerMilleRate != null
                  ? `${row.livePerMilleRate} ‰`
                  : '—'}
              </td>
              <td className="py-2 pr-3">
                {row.liveFeeMode === 'PER_MILLE' && row.livePerMilleCap != null
                  ? formatHuf(row.livePerMilleCap)
                  : '—'}
              </td>
              <td className="py-2">{row.hasDraft ? '✎ van' : ''}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {canEdit && (
        <div className="mt-6">
          <CommonBracketEditor />
        </div>
      )}

      {selected && (
        <BranchFeeEditorModal
          row={selected}
          onClose={() => setSelected(null)}
          onChanged={handleChanged}
        />
      )}
    </div>
  )
}

function SummaryCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-lg border border-gray-200 bg-white p-3 shadow-sm">
      <div className="text-xs text-gray-500">{label}</div>
      <div className="text-xl font-semibold text-gray-900">{value}</div>
    </div>
  )
}
