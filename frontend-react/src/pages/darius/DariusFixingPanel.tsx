import { useCallback, useEffect, useRef, useState, type FormEvent } from 'react'
import { AlertTriangle, Plus, Trash2 } from 'lucide-react'
import {
  currencyApi,
  dariusFixingApi,
  type DariusBankBranch,
  type DariusFixingRequest,
  type DariusFixingRequestCreate,
  type DariusFixingRequestStatus,
} from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import i18n from '../../i18n'

interface DariusFixingPanelProps {
  date: string
}

interface DraftLine {
  currencyCode: string
  deliveredAmount: string
  collectedAmount: string
}

const emptyLine = (): DraftLine => ({
  currencyCode: '',
  deliveredAmount: '',
  collectedAmount: '',
})

const STATUS: Record<DariusFixingRequestStatus, { label: string; color: string }> = {
  DRAFT: { label: 'Vázlat', color: 'bg-yellow-100 text-yellow-800' },
  APPROVED: { label: 'Jóváhagyva', color: 'bg-blue-100 text-blue-800' },
  INCLUDED: { label: 'Beemelve', color: 'bg-green-100 text-green-800' },
  CANCELLED: { label: 'Visszavonva', color: 'bg-gray-100 text-gray-700' },
}

function parseAmount(value: string): number | null {
  const trimmed = value.trim()
  if (!trimmed) return 0
  if (!/^\d+$/.test(trimmed)) return null
  const parsed = Number.parseInt(trimmed, 10)
  return Number.isSafeInteger(parsed) ? parsed : null
}

export default function DariusFixingPanel({ date }: DariusFixingPanelProps) {
  const [branches, setBranches] = useState<DariusBankBranch[]>([])
  const [requests, setRequests] = useState<DariusFixingRequest[]>([])
  const [currencyCodes, setCurrencyCodes] = useState<string[]>([])
  const [loading, setLoading] = useState(true)
  const [mutationPending, setMutationPending] = useState(false)
  const mutationPendingRef = useRef(false)
  const [error, setError] = useState('')

  const [branchCode, setBranchCode] = useState('')
  const [branchName, setBranchName] = useState('')
  const [editingId, setEditingId] = useState<string | null>(null)
  const [bankBranchId, setBankBranchId] = useState('')
  const [note, setNote] = useState('')
  const [lines, setLines] = useState<DraftLine[]>([emptyLine()])

  const loadData = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const [branchResponse, requestResponse, currencies] = await Promise.all([
        dariusFixingApi.bankBranches(false),
        dariusFixingApi.list(date),
        currencyApi.getActive(),
      ])
      setBranches(
        (Array.isArray(branchResponse.data) ? branchResponse.data : []).filter(
          (branch) => branch.active,
        ),
      )
      setRequests(Array.isArray(requestResponse.data) ? requestResponse.data : [])
      setCurrencyCodes(
        (Array.isArray(currencies) ? currencies : [])
          .filter((currency) => currency.active !== false)
          .slice()
          .sort((left, right) => (left.displayOrder ?? 0) - (right.displayOrder ?? 0))
          .map((currency) => currency.code),
      )
    } catch (err) {
      setError(getErrorMessage(err))
      setBranches([])
      setRequests([])
      setCurrencyCodes([])
    } finally {
      setLoading(false)
    }
  }, [date])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const runMutation = async (operation: () => Promise<void>) => {
    if (mutationPendingRef.current) return
    mutationPendingRef.current = true
    setMutationPending(true)
    setError('')
    try {
      await operation()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      mutationPendingRef.current = false
      setMutationPending(false)
    }
  }

  const resetRequestForm = () => {
    setEditingId(null)
    setBankBranchId('')
    setNote('')
    setLines([emptyLine()])
  }

  const handleBranchCreate = (event: FormEvent) => {
    event.preventDefault()
    const code = branchCode.trim()
    const name = branchName.trim()
    if (!code || !name) {
      setError('A bankfiók kódja és neve kötelező.')
      return
    }
    void runMutation(async () => {
      await dariusFixingApi.createBankBranch({ bankBranchCode: code, name })
      setBranchCode('')
      setBranchName('')
      await loadData()
    })
  }

  const handleDeactivate = (branch: DariusBankBranch) => {
    if (!window.confirm(`Biztosan deaktiválja ezt a bankfiókot: ${branch.bankBranchCode}?`)) return
    void runMutation(async () => {
      await dariusFixingApi.deactivateBankBranch(branch.id)
      if (bankBranchId === branch.id) resetRequestForm()
      await loadData()
    })
  }

  const updateLine = (index: number, patch: Partial<DraftLine>) => {
    setLines((current) =>
      current.map((line, lineIndex) => (lineIndex === index ? { ...line, ...patch } : line)),
    )
  }

  const buildRequestBody = (): DariusFixingRequestCreate | null => {
    if (!bankBranchId) {
      setError('Válasszon bankfiókot.')
      return null
    }
    if (lines.length === 0) {
      setError('Legalább egy valutasor kötelező.')
      return null
    }

    const parsedLines = []
    for (const line of lines) {
      const deliveredAmount = parseAmount(line.deliveredAmount)
      const collectedAmount = parseAmount(line.collectedAmount)
      if (!line.currencyCode || deliveredAmount == null || collectedAmount == null) {
        setError('Minden valutasorhoz valutanem és nem negatív egész összegek szükségesek.')
        return null
      }
      if (deliveredAmount === 0 && collectedAmount === 0) {
        setError('Valutasoronként legalább az egyik összegnek nullánál nagyobbnak kell lennie.')
        return null
      }
      parsedLines.push({ currencyCode: line.currencyCode, deliveredAmount, collectedAmount })
    }

    return {
      bankBranchId,
      requestDate: date,
      note: note.trim(),
      lines: parsedLines,
    }
  }

  const handleRequestSubmit = (event: FormEvent) => {
    event.preventDefault()
    if (branches.length === 0) {
      setError('Bankfiók-azonosító nélkül fixing-igény nem rögzíthető.')
      return
    }
    if (editingId && requests.find((request) => request.id === editingId)?.status !== 'DRAFT') {
      setError('Csak vázlat státuszú igény szerkeszthető.')
      return
    }
    const body = buildRequestBody()
    if (!body) return

    void runMutation(async () => {
      if (editingId) await dariusFixingApi.updateLines(editingId, body)
      else await dariusFixingApi.create(body)
      resetRequestForm()
      await loadData()
    })
  }

  const handleEdit = (request: DariusFixingRequest) => {
    if (request.status !== 'DRAFT') return
    setEditingId(request.id)
    setBankBranchId(request.bankBranchId)
    setNote(request.note ?? '')
    setLines(
      request.lines.map((line) => ({
        currencyCode: line.currencyCode,
        deliveredAmount: String(line.deliveredAmount),
        collectedAmount: String(line.collectedAmount),
      })),
    )
    setError('')
  }

  const handleApprove = (id: string) => {
    void runMutation(async () => {
      await dariusFixingApi.approve(id)
      await loadData()
    })
  }

  const handleCancel = (id: string) => {
    void runMutation(async () => {
      await dariusFixingApi.cancel(id)
      if (editingId === id) resetRequestForm()
      await loadData()
    })
  }

  if (loading)
    return (
      <div className="py-6 text-center text-sm text-gray-500">{i18n.t('literals.betoltes')}</div>
    )

  return (
    <div className="space-y-4">
      {error && (
        <div className="flex items-center gap-2 rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          <AlertTriangle size={16} />
          {error}
        </div>
      )}

      <section className="rounded border p-4">
        <h2 className="mb-3 font-semibold">{i18n.t('literals.bankfiok-torzs')}</h2>
        {branches.length === 0 ? (
          <div className="mb-3 text-sm text-gray-500">
            {i18n.t('literals.nincs-aktiv-bankfiok')}
          </div>
        ) : (
          <div className="mb-3 space-y-1">
            {branches.map((branch) => (
              <div
                key={branch.id}
                className="flex items-center justify-between rounded bg-gray-50 px-3 py-2 text-sm"
              >
                <span>
                  <strong>{branch.bankBranchCode}</strong>
                  {i18n.t('literals.lit-18')}
                  {branch.name}
                </span>
                <button
                  type="button"
                  className="btn-secondary text-xs"
                  disabled={mutationPending}
                  onClick={() => handleDeactivate(branch)}
                >
                  {i18n.t('literals.deaktivalas')}
                </button>
              </div>
            ))}
          </div>
        )}
        <form className="flex flex-wrap items-end gap-2" onSubmit={handleBranchCreate}>
          <label className="text-xs text-gray-600">
            {i18n.t('literals.bankfiok-kodja')}
            <input
              className="input-field mt-1 block text-sm"
              value={branchCode}
              onChange={(event) => setBranchCode(event.target.value)}
            />
          </label>
          <label className="text-xs text-gray-600">
            {i18n.t('literals.bankfiok-neve')}
            <input
              className="input-field mt-1 block text-sm"
              value={branchName}
              onChange={(event) => setBranchName(event.target.value)}
            />
          </label>
          <button type="submit" className="btn-primary text-sm" disabled={mutationPending}>
            {i18n.t('literals.uj-bankfiok')}
          </button>
        </form>
      </section>

      {branches.length === 0 && (
        <div className="flex items-center gap-2 rounded border border-yellow-300 bg-yellow-50 p-3 text-sm text-yellow-800">
          <AlertTriangle size={16} />
          {i18n.t('literals.nincs-bankfiok-azonosito-konfiguralva-fi')}
        </div>
      )}

      <section className="rounded border p-4">
        <h2 className="mb-3 font-semibold">
          {editingId ? 'Fixing-igény szerkesztése' : 'Új fixing-igény'}
        </h2>
        <form className="space-y-3" onSubmit={handleRequestSubmit}>
          <div className="grid gap-3 md:grid-cols-2">
            <label className="text-xs text-gray-600">
              {i18n.t('literals.bankfiok')}
              <select
                className="input-field mt-1 block w-full text-sm"
                value={bankBranchId}
                onChange={(event) => setBankBranchId(event.target.value)}
              >
                <option value="">{i18n.t('literals.valasszon-2')}</option>
                {branches.map((branch) => (
                  <option key={branch.id} value={branch.id}>
                    {branch.bankBranchCode}
                    {i18n.t('literals.lit-18')}
                    {branch.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="text-xs text-gray-600">
              {i18n.t('literals.megjegyzes')}
              <input
                className="input-field mt-1 block w-full text-sm"
                value={note}
                onChange={(event) => setNote(event.target.value)}
              />
            </label>
          </div>

          <div className="space-y-2">
            {lines.map((line, index) => (
              <div key={index} className="grid grid-cols-[1fr_1fr_1fr_auto] items-end gap-2">
                <label className="text-xs text-gray-600">
                  {i18n.t('literals.valutanem-2')}
                  {index + 1}
                  <select
                    aria-label={`Valutanem ${index + 1}`}
                    className="input-field mt-1 block w-full text-sm"
                    value={line.currencyCode}
                    onChange={(event) => updateLine(index, { currencyCode: event.target.value })}
                  >
                    <option value="">{i18n.t('literals.valasszon-2')}</option>
                    {currencyCodes.map((code) => (
                      <option key={code} value={code}>
                        {code}
                      </option>
                    ))}
                  </select>
                </label>
                <label className="text-xs text-gray-600">
                  {i18n.t('literals.beszallitott')}
                  <input
                    aria-label={`Beszállított összeg ${index + 1}`}
                    type="number"
                    min={0}
                    step={1}
                    className="input-field mt-1 block w-full text-sm"
                    value={line.deliveredAmount}
                    onChange={(event) => updateLine(index, { deliveredAmount: event.target.value })}
                  />
                </label>
                <label className="text-xs text-gray-600">
                  {i18n.t('literals.elvitt')}
                  <input
                    aria-label={`Elvitt összeg ${index + 1}`}
                    type="number"
                    min={0}
                    step={1}
                    className="input-field mt-1 block w-full text-sm"
                    value={line.collectedAmount}
                    onChange={(event) => updateLine(index, { collectedAmount: event.target.value })}
                  />
                </label>
                {lines.length > 1 && (
                  <button
                    type="button"
                    className="btn-secondary p-2"
                    aria-label={`Valutasor ${index + 1} törlése`}
                    onClick={() =>
                      setLines((current) => current.filter((_, lineIndex) => lineIndex !== index))
                    }
                  >
                    <Trash2 size={16} />
                  </button>
                )}
              </div>
            ))}
          </div>

          <div className="flex gap-2">
            <button
              type="button"
              className="btn-secondary text-sm"
              onClick={() => setLines((current) => [...current, emptyLine()])}
            >
              <Plus size={14} />
              {i18n.t('literals.sor-hozzaadasa')}
            </button>
            <button
              type="submit"
              className="btn-primary text-sm"
              disabled={mutationPending || branches.length === 0}
            >
              {editingId ? 'Módosítás mentése' : 'Igény rögzítése'}
            </button>
            {editingId && (
              <button type="button" className="btn-secondary text-sm" onClick={resetRequestForm}>
                {i18n.t('literals.szerkesztes-megszakitasa')}
              </button>
            )}
          </div>
        </form>
      </section>

      <section className="rounded border p-4">
        <h2 className="mb-3 font-semibold">
          {i18n.t('literals.fixing-igenyek')}
          {date}
        </h2>
        {requests.length === 0 ? (
          <div className="text-sm text-gray-500">
            {i18n.t('literals.nincs-fixing-igeny-a-kivalasztott-napra')}
          </div>
        ) : (
          <div className="space-y-2">
            {requests.map((request) => {
              const status = STATUS[request.status as DariusFixingRequestStatus] ?? {
                label: String(request.status),
                color: 'bg-gray-100 text-gray-700',
              }
              return (
                <div
                  key={request.id}
                  data-testid={`fixing-request-${request.id}`}
                  className="rounded border p-3 text-sm"
                >
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <div>
                      <strong>{request.bankBranchCode}</strong>
                      {i18n.t('literals.lit-18')}
                      {request.bankBranchName}
                    </div>
                    <span
                      className={`rounded-full px-2 py-0.5 text-xs font-medium ${status.color}`}
                    >
                      {status.label}
                    </span>
                  </div>
                  <div className="mt-2 space-y-1 text-xs text-gray-600">
                    {request.lines.map((line, index) => (
                      <div key={`${line.currencyCode}-${index}`}>
                        {line.currencyCode}
                        {i18n.t('literals.beszallitott-2')}{' '}
                        {line.deliveredAmount.toLocaleString('hu-HU')}
                        {i18n.t('literals.elvitt-2')} {line.collectedAmount.toLocaleString('hu-HU')}
                      </div>
                    ))}
                    {request.note && (
                      <div>
                        {i18n.t('literals.megjegyzes-3')}
                        {request.note}
                      </div>
                    )}
                  </div>
                  {(request.status === 'DRAFT' || request.status === 'APPROVED') && (
                    <div className="mt-3 flex gap-2 border-t pt-2">
                      {request.status === 'DRAFT' && (
                        <>
                          <button
                            type="button"
                            className="btn-primary text-xs"
                            disabled={mutationPending}
                            onClick={() => handleApprove(request.id)}
                          >
                            {i18n.t('literals.jovahagy')}
                          </button>
                          <button
                            type="button"
                            className="btn-secondary text-xs"
                            disabled={mutationPending}
                            onClick={() => handleEdit(request)}
                          >
                            {i18n.t('literals.szerkeszt')}
                          </button>
                        </>
                      )}
                      <button
                        type="button"
                        className="btn-secondary text-xs"
                        disabled={mutationPending}
                        onClick={() => handleCancel(request.id)}
                      >
                        {i18n.t('literals.visszavon')}
                      </button>
                    </div>
                  )}
                </div>
              )
            })}
          </div>
        )}
      </section>
    </div>
  )
}
