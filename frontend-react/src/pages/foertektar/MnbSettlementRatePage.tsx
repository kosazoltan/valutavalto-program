import { useCallback, useEffect, useMemo, useState } from 'react'
import { Download, Send, Save, TrendingUp } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { mnbSettlementRateApi, type MnbSettlementRateRow } from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import i18n from '../../i18n'

type RateRowState = MnbSettlementRateRow & {
  current: number | null
  input: string
}

function toNumber(value: number | string | null | undefined): number | null {
  if (value == null) return null
  const n = typeof value === 'number' ? value : Number(value)
  return Number.isFinite(n) ? n : null
}

function formatRate(value: number | null | undefined): string {
  return (value ?? 0).toLocaleString('hu-HU', {
    minimumFractionDigits: 4,
    maximumFractionDigits: 4,
  })
}

function formatInput(value: number | null | undefined): string {
  const n = value ?? 0
  return Number.isFinite(n) ? n.toFixed(4) : '0.0000'
}

function parseRateInput(value: string): number | null {
  const normalized = value.trim().replace(',', '.')
  if (!normalized) return null
  const n = Number(normalized)
  return Number.isFinite(n) ? n : null
}

function hasLargeDeviation(previous: number | null, next: number | null): boolean {
  if (previous == null || previous <= 0 || next == null) return false
  return Math.abs(next - previous) / previous > 0.1
}

function toStateRows(rows: MnbSettlementRateRow[]): RateRowState[] {
  return rows.map((row) => {
    const current = row.currencyCode === 'HUF' ? 1 : toNumber(row.officialRate)
    return {
      ...row,
      officialRate: current ?? 0,
      current,
      input: formatInput(current),
    }
  })
}

export default function MnbSettlementRatePage() {
  const canEdit = useAuthStore((s) => s.hasCanonicalRole('foertektar'))
  const [rows, setRows] = useState<RateRowState[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [querying, setQuerying] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadRows = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const list = await mnbSettlementRateApi.list()
      setRows(toStateRows(list || []))
    } catch (err) {
      logger.error('MnbSettlementRatePage', 'MNB árfolyam-lista betöltési hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadRows()
  }, [loadRows])

  const changedPayload = useMemo(
    () =>
      rows
        .filter((row) => row.currencyCode !== 'HUF')
        .map((row) => ({ row, parsed: parseRateInput(row.input) }))
        .filter(
          ({ row, parsed }) =>
            parsed != null && parsed > 0 && Math.abs(parsed - (row.current ?? 0)) > 0.00005,
        )
        .map(({ row, parsed }) => ({ currencyCode: row.currencyCode, officialRate: parsed! })),
    [rows],
  )

  const updateInput = (currencyCode: string, input: string) => {
    setRows((current) =>
      current.map((row) => (row.currencyCode === currencyCode ? { ...row, input } : row)),
    )
  }

  const handleMnbDownload = async () => {
    try {
      setQuerying(true)
      const preview = await mnbSettlementRateApi.mnbQuery()
      const byCode = new Map(
        preview.map((rate) => [rate.currencyCode, toNumber(rate.officialRate)]),
      )
      setRows((current) =>
        current.map((row) => {
          if (row.currencyCode === 'HUF') return row
          const next = byCode.get(row.currencyCode)
          return next == null ? row : { ...row, input: formatInput(next) }
        }),
      )
      toast.success('MNB árfolyamok letöltve')
    } catch (err) {
      logger.error('MnbSettlementRatePage', 'MNB árfolyam-letöltési hiba:', err)
      toast.error('MNB letöltés sikertelen', getErrorMessage(err))
    } finally {
      setQuerying(false)
    }
  }

  const handleSave = async (publish: boolean) => {
    try {
      setSaving(true)
      if (publish) {
        await mnbSettlementRateApi.publish(changedPayload)
        toast.success('MNB árfolyamok rögzítve és kiküldve az irodáknak')
      } else {
        await mnbSettlementRateApi.update(changedPayload)
        toast.success('MNB árfolyamok rögzítve')
      }
      await loadRows()
    } catch (err) {
      logger.error('MnbSettlementRatePage', 'MNB árfolyam-rögzítési hiba:', err)
      toast.error('Rögzítés sikertelen', getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2">
        <TrendingUp />
        {i18n.t('literals.mnb-arfolyamok-rogzitese')}
      </h1>

      <div className="form-panel flex flex-wrap gap-3 items-center">
        <button
          className="form-button-secondary"
          disabled={!canEdit || querying || loading}
          onClick={() => void handleMnbDownload()}
          type="button"
        >
          <Download size={16} className={querying ? 'animate-spin' : ''} />
          {i18n.t('literals.mnb-letoltes')}
        </button>
        <button
          className="form-button-primary"
          disabled={!canEdit || saving || loading}
          onClick={() => void handleSave(false)}
          type="button"
        >
          <Save size={16} />
          {i18n.t('literals.rogzites')}
        </button>
        <button
          className="form-button-primary"
          disabled={!canEdit || saving || loading}
          onClick={() => void handleSave(true)}
          type="button"
        >
          <Send size={16} />
          {i18n.t('literals.rogzites-kuldes-irodaknak')}
        </button>
        {!canEdit && (
          <span className="text-sm text-gray-600">
            {i18n.t('literals.olvasasi-mod-a-rogzites-csak-foertektaro')}
          </span>
        )}
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <div className="form-panel overflow-x-auto">
        {loading ? (
          <div className="text-center text-gray-500 py-4">{i18n.t('literals.betoltes')}</div>
        ) : rows.length === 0 ? (
          <div className="text-center text-gray-500 py-4">
            {i18n.t('literals.nincs-aktiv-valuta')}
          </div>
        ) : (
          <table className="data-grid w-full text-sm" data-testid="mnb-settlement-grid">
            <thead>
              <tr>
                <th>{i18n.t('literals.kod-3')}</th>
                <th>{i18n.t('literals.nev')}</th>
                <th className="text-right">{i18n.t('literals.mnb-arfolyam')}</th>
                <th>{i18n.t('literals.figyelmeztetes')}</th>
                <th>{i18n.t('literals.kikuldve')}</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => {
                const parsed = parseRateInput(row.input)
                const warn = row.currencyCode !== 'HUF' && hasLargeDeviation(row.current, parsed)
                return (
                  <tr key={row.currencyCode}>
                    <td className="font-mono font-bold">{row.currencyCode}</td>
                    <td>{row.currencyName}</td>
                    <td className="text-right">
                      {row.currencyCode === 'HUF' ? (
                        <span className="font-mono" data-testid="huf-rate">
                          {formatRate(1)}
                        </span>
                      ) : (
                        <input
                          aria-label={`${row.currencyCode} árfolyam`}
                          className={`form-input text-right font-mono ${warn ? 'bg-yellow-50 border-yellow-400' : ''}`}
                          disabled={!canEdit}
                          inputMode="decimal"
                          onBlur={() => updateInput(row.currencyCode, row.input.trim())}
                          onChange={(e) => updateInput(row.currencyCode, e.target.value)}
                          value={row.input}
                        />
                      )}
                    </td>
                    <td>
                      {warn ? (
                        <span
                          className="inline-flex items-center rounded bg-yellow-100 px-2 py-1 text-yellow-800"
                          data-testid={`rate-warning-${row.currencyCode}`}
                          title="10%-nál nagyobb eltérés az előző árfolyamhoz képest"
                        >
                          {i18n.t('literals.10-elteres')}
                        </span>
                      ) : (
                        <span className="text-gray-400">{i18n.t('literals.lit-36')}</span>
                      )}
                    </td>
                    <td>
                      {row.availableToOfficesAt
                        ? new Date(row.availableToOfficesAt).toLocaleString('hu-HU')
                        : 'Nincs kiküldve'}
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
