import { useEffect, useState } from 'react'
import { branchFeeConfigApi, type BranchFeeConfigLive } from '../../services/api/settings'
import { logger } from '../../utils/logger'
import i18n from '../../i18n'

const formatHuf = (value: number) => `${value.toLocaleString('hu-HU')} Ft`

const MODE_LABEL: Record<BranchFeeConfigLive['feeMode'], string> = {
  NONE: 'Nincs kezelési díj',
  BRACKET: 'Sávos',
  PER_MILLE: 'Ezrelékes',
}

/**
 * FK-096 FR-14 — pénztáros read-only saját-iroda kártya.
 *
 * FONTOS (spec §2 OUT, FK-097 §2 OUT, pitfall #15): a kártya ÉLŐ HTTP-n kérdezi
 * a /branch-fee-config/own végpontot, SOHA nem cache-ből — ez tájékoztató nézet,
 * nem a tranzakció-számítás offline tükre (az a loadHandlingFeeConfig dolga).
 */
export default function CashierFeeCard() {
  const [live, setLive] = useState<BranchFeeConfigLive | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    branchFeeConfigApi
      .own()
      .then((data) => {
        if (!cancelled) setLive(data)
      })
      .catch((err) => {
        if (!cancelled) {
          setError('A kezelési díj konfiguráció nem tölthető be. Kérj segítséget az ügyvezetőtől.')
          logger.error('CashierFeeCard', 'own() betöltési hiba', err)
        }
      })
    return () => {
      cancelled = true
    }
  }, [])

  if (error) {
    return (
      <div className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-800">
        {error}
      </div>
    )
  }

  if (!live) {
    return (
      <div className="text-sm text-gray-500">
        {i18n.t('literals.kezelesi-dij-konfiguracio-betoltese')}
      </div>
    )
  }

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-4 shadow-sm">
      <h2 className="text-base font-semibold text-gray-800">
        {i18n.t('literals.kezelesi-dij-2')}
        {live.branchCode}
        {i18n.t('literals.iroda-read-only')}
      </h2>
      <dl className="mt-3 grid grid-cols-2 gap-2 text-sm">
        <dt className="text-gray-500">{i18n.t('literals.mod-2')}</dt>
        <dd className="font-medium">{MODE_LABEL[live.feeMode]}</dd>
        {live.feeMode === 'PER_MILLE' && (
          <>
            <dt className="text-gray-500">{i18n.t('literals.mertek-2')}</dt>
            <dd className="font-medium">
              {live.perMilleRate ?? 0}
              {i18n.t('literals.lit-35')}
            </dd>
            <dt className="text-gray-500">{i18n.t('literals.maximum')}</dt>
            <dd className="font-medium">
              {live.perMilleCap != null && live.perMilleCap > 0
                ? formatHuf(live.perMilleCap)
                : 'Nincs'}
            </dd>
          </>
        )}
        {live.feeMode === 'BRACKET' && (
          <>
            <dt className="text-gray-500">{i18n.t('literals.savok')}</dt>
            <dd className="font-medium">
              {live.brackets.length}
              {i18n.t('literals.db')}
            </dd>
          </>
        )}
        <dt className="text-gray-500">{i18n.t('literals.ervenyes')}</dt>
        <dd className="font-medium">{live.validFrom}</dd>
      </dl>
      {live.feeMode === 'BRACKET' && live.brackets.length > 0 && (
        <table className="mt-3 w-full text-left text-xs">
          <thead>
            <tr className="border-b text-gray-500">
              <th className="py-1 pr-2 font-medium">{i18n.t('literals.sav')}</th>
              <th className="py-1 pr-2 font-medium">{i18n.t('literals.felso-hatar')}</th>
              <th className="py-1 font-medium">{i18n.t('literals.dij')}</th>
            </tr>
          </thead>
          <tbody>
            {live.brackets.map((bracket) => (
              <tr key={bracket.bracketOrder} className="border-b last:border-0">
                <td className="py-1 pr-2">{bracket.bracketOrder}</td>
                <td className="py-1 pr-2">{formatHuf(bracket.upperLimit)}</td>
                <td className="py-1">{formatHuf(bracket.feeAmount)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  )
}
