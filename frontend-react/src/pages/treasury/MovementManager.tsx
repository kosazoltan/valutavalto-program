import { useState, useEffect, useCallback } from 'react'
import {
  Plus,
  Clock,
  CheckCircle,
  XCircle,
  Eye,
  Save,
  ArrowLeftRight,
  Building2,
  Banknote,
  PenLine,
  RefreshCw,
  Wand2,
} from 'lucide-react'
import { useHotkeys } from 'react-hotkeys-hook'
import { transferApi, currencyApi, branchApi, sealNumberApi } from '../../services/api/index'
import type {
  Transfer,
  Currency,
  CreateTransferRequest,
  BranchInfo,
} from '../../services/api/index'
import {
  formatInteger,
  formatDateTime,
  currencyColorClass,
  MOVEMENT_TYPE_LABELS,
  MOVEMENT_STATUS_LABELS,
  movementDirectionLabel,
} from './treasuryUtils'
import { TableSkeleton } from './LoadingSkeleton'
import {
  isElectronQueueAvailable,
  recordLocalAuditEvent,
  saveAndSyncPendingTransfer,
} from '../../utils/electronTransactions'
import { getLocalPendingTransfers } from '../../utils/localQueue'
import { validateCarrierSeal } from '../transfers/transferRules'
import { useAuthStore } from '../../stores/authStore'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import { getErrorMessage } from '../../utils/errorHandling'
import { localIsoDate } from '../../utils/dateFormat'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

const MOVEMENT_TYPES = [
  {
    value: 'VAULT_WITHDRAW' as const,
    label: 'Bank kivét',
    description: 'Értéktárból bankba szállítás',
    icon: Banknote,
  },
  {
    value: 'VAULT_DEPOSIT' as const,
    label: 'Bank befizetés',
    description: 'Bankból értéktárba befizetés',
    icon: Banknote,
  },
  {
    value: 'CURRENCY' as const,
    label: 'Iroda szállítás',
    description: 'Irodák közti készletmozgatás',
    icon: ArrowLeftRight,
  },
  {
    value: 'CORRECTION' as const,
    label: 'Korrekció',
    description: 'Leltárkülönbözet rendezés',
    icon: PenLine,
  },
] as const

export default function MovementManager() {
  const { t } = useTranslation()
  const electronQueueAvailable = isElectronQueueAvailable()
  const worker = useAuthStore((state) => state.worker)
  const [loading, setLoading] = useState(true)
  const [pendingTransfers, setPendingTransfers] = useState<Transfer[]>([])
  const [allTransfers, setAllTransfers] = useState<Transfer[]>([])
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [showNewModal, setShowNewModal] = useState(false)
  const [showDetailModal, setShowDetailModal] = useState<Transfer | null>(null)
  const [statusFilter, setStatusFilter] = useState('all')
  const [typeFilter, setTypeFilter] = useState('all')
  // FKH-037 FR-2: az előzmény dátumszűrője — alapértelmezés a MAI lokális nap (localIsoDate,
  // NEM a UTC-alapú todayISO). Lazy initializer: mountonként egyszer számolódik.
  const [historyStartDate, setHistoryStartDate] = useState(() => localIsoDate())
  const [historyEndDate, setHistoryEndDate] = useState(() => localIsoDate())

  // New movement form state
  const [movementType, setMovementType] =
    useState<CreateTransferRequest['transferType']>('CURRENCY')
  const [toBranchId, setToBranchId] = useState('')
  const [currencyId, setCurrencyId] = useState<number>(0)
  const [amount, setAmount] = useState('')
  const [notes, setNotes] = useState('')
  // FR-1..3 (átadás-átvétel): szállító neve + plombaszám — minden /transfers létrehozásnál kötelező.
  const [carrierName, setCarrierName] = useState('')
  const [sealNumber, setSealNumber] = useState('')
  const [sealGenerating, setSealGenerating] = useState(false)
  const [formError, setFormError] = useState<string | null>(null)
  // FK-013 follow-up (2026-06-01): a "Cél iroda" legördülő tartalma — a /branches/vault-counterparties
  // 3 csoportja (saját terület pénztárai / társ értéktárak / banki és speciális partnerek), mint a
  // ShipmentNewPage egységesített átadás-átvételében. A treasury dashboard értéktáros-kontextus.
  const [vaultCounterparties, setVaultCounterparties] = useState<{
    territorialCashiers: BranchInfo[]
    peerVaults: BranchInfo[]
    fixedCounterparties: BranchInfo[]
  } | null>(null)
  const [counterpartiesError, setCounterpartiesError] = useState(false)

  const fetchData = useCallback(async () => {
    try {
      const [pendingRaw, allRaw, currDataRaw, localPending] = await Promise.all([
        transferApi.getPending().catch(() => []),
        transferApi
          // FKH-037 FR-3/FR-4: az előzmény-keresés a kiválasztott dátumtartományra szűkül.
          .search({ page: 0, size: 50, startDate: historyStartDate, endDate: historyEndDate })
          .catch(() => ({ content: [], totalElements: 0, totalPages: 0, size: 50, number: 0 })),
        currencyApi.list().catch(() => []),
        electronQueueAvailable
          ? getLocalPendingTransfers(worker)
          : Promise.resolve([] as Transfer[]),
      ])
      const pending = safeArray<Transfer>(pendingRaw)
      const allTransfersData = safeArray<Transfer>(allRaw?.content)
      const currData = safeArray<Currency>(currDataRaw)
      setPendingTransfers([...localPending, ...pending])
      setAllTransfers([...localPending, ...allTransfersData])
      setCurrencies(currData)
    } catch (err) {
      logger.error('MovementManager', 'MovementManager fetch error:', err)
    } finally {
      setLoading(false)
    }
    // FKH-037 FR-4: a dátumok a dependency-listában — a 15s poll useEffect a fetchData
    // identitás-változásán keresztül IRATKOZIK ÚJRA, tehát dátumváltásnál frissül a lista.
  }, [electronQueueAvailable, worker, historyStartDate, historyEndDate])

  useEffect(() => {
    void fetchData()
    const interval = setInterval(() => void fetchData(), 15_000) // 15s polling for pending
    return () => clearInterval(interval)
  }, [fetchData])

  // FK-013 follow-up: a partner-lista statikus → egyszer töltjük (nem a 15s poll-ban).
  // Codex P2: betöltés-hibát FELSZÍNRE hozzuk (counterpartiesError) + retry — különben a
  // user csapdába esik (select használhatatlan), és az üres toBranchId-submitet a guard tiltja.
  const loadCounterparties = useCallback(() => {
    setCounterpartiesError(false)
    return branchApi
      .listVaultCounterparties()
      .then((cp) => setVaultCounterparties(cp))
      .catch((err) => {
        logger.warn('MovementManager', 'vault-counterparties betöltési hiba:', err)
        setCounterpartiesError(true)
      })
  }, [])

  useEffect(() => {
    void loadCounterparties()
  }, [loadCounterparties])

  // Hotkeys
  useHotkeys('n', () => setShowNewModal(true), { enableOnFormTags: false })
  useHotkeys(
    'escape',
    () => {
      setShowNewModal(false)
      setShowDetailModal(null)
    },
    { enableOnFormTags: true },
  )

  const handleApprove = useCallback(
    async (id: number) => {
      try {
        const transfer =
          pendingTransfers.find((t) => t.id === id) ?? allTransfers.find((t) => t.id === id)
        const receivedAmount = transfer?.amount ?? 0
        await transferApi.receive(id, { receivedAmount })
        await recordLocalAuditEvent({
          entityType: 'TREASURY_MOVEMENT',
          eventType: 'RECEIVE',
          entityId: String(id),
          referenceNumber: transfer?.transferNumber ?? null,
          payload: { transferId: id, receivedAmount },
          status: 'SERVER_FORWARDED',
        })
        void fetchData()
      } catch (err) {
        logger.error('MovementManager', 'Approve error:', err)
      }
    },
    [fetchData, pendingTransfers, allTransfers],
  )

  const handleReject = useCallback(
    async (id: number) => {
      try {
        await transferApi.reject(id, 'Értéktáros által elutasítva')
        await recordLocalAuditEvent({
          entityType: 'TREASURY_MOVEMENT',
          eventType: 'REJECT',
          entityId: String(id),
          payload: { transferId: id, reason: 'Értéktáros által elutasítva' },
          status: 'SERVER_FORWARDED',
        })
        void fetchData()
      } catch (err) {
        logger.error('MovementManager', 'Reject error:', err)
      }
    },
    [fetchData],
  )

  const handleSubmitNew = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault()
      // Codex P2: cél-iroda KÖTELEZŐ — különben (üres toBranchId) az offline-út rossz célhellyel
      // (targetBranchId=null, targetBranchCode='TREASURY') mentene, a backend-út pedig UUID-hibát dobna.
      if (!currencyId || !amount || !toBranchId) return
      setFormError(null)
      // FR-1..3 / NFR-1,2: szállító + plombaszám kötelező + hossz/formátum (a backend Bean Validationnel egyezően).
      const carrier = carrierName.trim()
      const seal = sealNumber.trim()
      const carrierSealError = validateCarrierSeal(carrierName, sealNumber)
      if (carrierSealError) {
        setFormError(carrierSealError)
        return
      }
      try {
        const parsedAmount = parseFloat(amount)
        const selectedCurrency = currencies.find((currency) => currency.id === currencyId)
        if (!selectedCurrency) {
          return
        }

        // FK-013 follow-up: a kiválasztott cél-iroda KÓDJÁT a partner-listából oldjuk fel
        // (a toBranchId most UUID, nem kód) — különben a targetBranchCode hibásan UUID lenne.
        const allCounterparties = vaultCounterparties
          ? [
              ...(vaultCounterparties.territorialCashiers ?? []),
              ...(vaultCounterparties.peerVaults ?? []),
              ...(vaultCounterparties.fixedCounterparties ?? []),
            ]
          : []
        const targetBranchCode =
          allCounterparties.find((b) => b.id === toBranchId)?.code ?? 'TREASURY'

        if (electronQueueAvailable) {
          await saveAndSyncPendingTransfer({
            targetBranchId: toBranchId || null,
            targetBranchCode,
            currencyId,
            currencyCode: selectedCurrency.code,
            amount: parsedAmount,
            hufValue: null,
            transferType: movementType,
            denominations: null,
            note: notes || null,
            carrierName: carrier,
            sealNumber: seal,
          })
        } else {
          await transferApi.create({
            toBranchId,
            currencyId,
            amount: parsedAmount,
            transferType: movementType,
            notes: notes || undefined,
            carrierName: carrier,
            sealNumber: seal,
          })
        }
        setShowNewModal(false)
        setAmount('')
        setNotes('')
        setCarrierName('')
        setSealNumber('')
        setFormError(null)
        void fetchData()
      } catch (err) {
        logger.error('MovementManager', 'Create movement error:', err)
      }
    },
    [
      toBranchId,
      currencyId,
      amount,
      movementType,
      notes,
      carrierName,
      sealNumber,
      fetchData,
      currencies,
      electronQueueAvailable,
      vaultCounterparties,
    ],
  )

  const generateSealNumber = useCallback(async () => {
    const branchCode = worker?.branchCode?.trim()
    if (!branchCode) {
      setFormError('A plombaszám generálásához hiányzik a telephely kódja.')
      return
    }
    try {
      setSealGenerating(true)
      setFormError(null)
      const preview = await sealNumberApi.getNext(branchCode)
      setSealNumber(preview.sealNumber)
    } catch (err) {
      setFormError(getErrorMessage(err))
      logger.warn('MovementManager', 'Plombaszám generálási hiba:', err)
    } finally {
      setSealGenerating(false)
    }
  }, [worker?.branchCode])

  // Filtered history
  const filteredTransfers = allTransfers.filter((t) => {
    if (statusFilter !== 'all' && t.status !== statusFilter) return false
    if (typeFilter !== 'all' && t.transferType !== typeFilter) return false
    return true
  })

  if (loading) return <TableSkeleton rows={6} cols={7} />

  const approvedToday = allTransfers.filter(
    (t) => t.status === 'COMPLETED' || t.status === 'RECEIVED',
  ).length

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <h1 className="text-xl font-bold text-secondary-900">{t('treasury.keszletMozgasok')}</h1>
          <span className="badge badge-yellow">
            {t('treasury.Fuggo')}
            {pendingTransfers.length}
          </span>
          <span className="badge badge-green">
            {t('treasury.JovahagyvaMa')}
            {approvedToday}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={() => void fetchData()} className="form-button h-8 text-xs">
            <RefreshCw size={14} />
          </button>
          <button onClick={() => setShowNewModal(true)} className="form-button-primary h-8 text-xs">
            <Plus size={16} />
            <span>{t('treasury.ujMozgas')}</span>
          </button>
        </div>
      </div>

      {/* Pending movements */}
      {pendingTransfers.length > 0 && (
        <div className="form-panel">
          <h2 className="text-lg font-bold text-secondary-900 mb-4 flex items-center gap-2">
            <Clock size={20} className="text-warning-500" />
            {t('treasury.fuggoMozgasok')}
            {pendingTransfers.length}
            {i18n.t('literals.lit-2')}
          </h2>
          <div className="space-y-3">
            {pendingTransfers.map((mov) => (
              <div
                key={mov.id}
                className="p-4 rounded-lg border border-warning-200 bg-warning-50 hover:bg-warning-100 transition-colors"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <span className="font-bold text-secondary-900">
                        {i18n.t('literals.lit-12')}
                        {mov.transferNumber}
                      </span>
                      <span className="badge badge-yellow">
                        {MOVEMENT_TYPE_LABELS[mov.transferType] ?? mov.transferTypeDisplay}
                      </span>
                      <span className="text-sm text-secondary-600">
                        {mov.fromBranchName}
                        {mov.toBranchName && ` → ${mov.toBranchName}`}
                      </span>
                    </div>
                    <div className="text-sm text-secondary-700 mb-2">
                      <span className={`font-bold ${currencyColorClass(mov.currencyCode)}`}>
                        {mov.currencyCode}
                      </span>{' '}
                      <span className="font-mono font-semibold">{formatInteger(mov.amount)}</span>{' '}
                      <span className="text-secondary-500">
                        {t('treasury.kerte')} {mov.fromWorkerName}
                      </span>
                    </div>
                    <div className="text-xs text-secondary-500">
                      {formatDateTime(mov.createdAt)}
                    </div>
                  </div>
                  <div className="flex items-center gap-2 ml-4">
                    <button
                      className="form-button-success h-8 text-xs"
                      onClick={() => void handleApprove(mov.id)}
                    >
                      <CheckCircle size={16} />
                      {t('common.approve')}
                    </button>
                    <button
                      className="form-button-danger h-8 text-xs"
                      onClick={() => void handleReject(mov.id)}
                    >
                      <XCircle size={16} />
                      {t('common.reject')}
                    </button>
                    <button
                      className="form-button h-8 text-xs"
                      onClick={() => setShowDetailModal(mov)}
                    >
                      <Eye size={16} />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Movement History */}
      <div className="form-panel">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-bold text-secondary-900">{t('treasury.mozgasTortenet')}</h2>
          <div className="flex items-center gap-2">
            {/* FKH-037 FR-2: dátumszűrő — két date-input, alapértelmezés a mai nap. */}
            <input
              type="date"
              data-testid="movement-history-start-date"
              aria-label="Dátum -tól"
              className="form-input w-36 h-8 text-xs"
              value={historyStartDate}
              onChange={(e) => setHistoryStartDate(e.target.value)}
            />
            <input
              type="date"
              data-testid="movement-history-end-date"
              aria-label="Dátum -ig"
              className="form-input w-36 h-8 text-xs"
              value={historyEndDate}
              onChange={(e) => setHistoryEndDate(e.target.value)}
            />
            <select
              className="form-input w-40 h-8 text-xs"
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
            >
              <option value="all">{t('treasury.mindenTipus2')}</option>
              <option value="VAULT_WITHDRAW">{t('treasury.bankKivet')}</option>
              <option value="VAULT_DEPOSIT">{t('treasury.bankBefizetes')}</option>
              <option value="CURRENCY">{t('treasury.szallitas')}</option>
              <option value="CORRECTION">{t('treasury.korrekcio')}</option>
            </select>
            <select
              className="form-input w-40 h-8 text-xs"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <option value="all">{t('treasury.mindenStatusz')}</option>
              <option value="PENDING">{t('common.pending')}</option>
              <option value="COMPLETED">{t('shipments.jovahagyva')}</option>
              <option value="REJECTED">{t('treasury.elutasitva')}</option>
            </select>
          </div>
        </div>
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th className="w-20">{i18n.t('literals.id')}</th>
              <th className="w-20">{t('misc.ido')}</th>
              <th className="w-32">{t('common.type')}</th>
              <th className="w-48">{t('common.office')}</th>
              <th className="w-20">{t('common.currency')}</th>
              <th className="text-right w-28">{t('common.amount')}</th>
              <th className="w-32">{t('common.status')}</th>
              <th className="w-12"></th>
            </tr>
          </thead>
          <tbody>
            {filteredTransfers.length === 0 && (
              <tr>
                <td colSpan={8} className="text-center text-sm text-secondary-400 py-8">
                  {t('common.noResult')}
                </td>
              </tr>
            )}
            {filteredTransfers.map((mov) => (
              <tr key={mov.id}>
                <td className="font-mono text-xs">
                  {i18n.t('literals.lit-12')}
                  {mov.transferNumber}
                </td>
                {/* FKH-037 FR-6: teljes dátum-idő (nem csak óra:perc). */}
                <td className="text-xs">{formatDateTime(mov.createdAt)}</td>
                <td className="text-xs">
                  {/* FKH-037 FR-5: irány a bejelentkezett értéktár szemszögéből; ha egyik vég
                      sem a saját fiók (vagy a worker még nem hydrált), marad a technikai címke. */}
                  {movementDirectionLabel(mov, worker?.branchId) ??
                    MOVEMENT_TYPE_LABELS[mov.transferType] ??
                    mov.transferTypeDisplay}
                </td>
                <td className="text-xs">
                  {mov.fromBranchName}
                  {mov.toBranchName && (
                    <span className="text-secondary-400">
                      {i18n.t('literals.lit-56')}
                      {mov.toBranchName}
                    </span>
                  )}
                </td>
                <td className={`font-bold ${currencyColorClass(mov.currencyCode)}`}>
                  {mov.currencyCode}
                </td>
                <td className="text-right font-mono font-semibold">{formatInteger(mov.amount)}</td>
                <td>
                  <span
                    className={`badge ${
                      mov.status === 'PENDING'
                        ? 'badge-yellow'
                        : mov.status === 'COMPLETED' || mov.status === 'RECEIVED'
                          ? 'badge-green'
                          : mov.status === 'REJECTED'
                            ? 'badge-red'
                            : 'badge-gray'
                    }`}
                  >
                    {MOVEMENT_STATUS_LABELS[mov.status] ?? mov.statusDisplay}
                  </span>
                </td>
                <td className="text-center">
                  <button
                    className="text-primary-600 hover:text-primary-700"
                    onClick={() => setShowDetailModal(mov)}
                  >
                    <Eye size={16} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* New Movement Modal */}
      {showNewModal && (
        <ModalOverlay onClose={() => setShowNewModal(false)}>
          <div className="bg-white rounded-lg shadow-xl p-4 max-w-2xl w-full mx-4">
            <h2 className="text-xl font-bold text-secondary-900 mb-3">
              {t('treasury.ujKeszletMozgas')}
            </h2>
            <form onSubmit={(e) => void handleSubmitNew(e)} className="space-y-4">
              {/* Movement type */}
              <div>
                <label className="form-label">{t('treasury.mozgasTipusa')}</label>
                <div className="grid grid-cols-2 gap-3">
                  {MOVEMENT_TYPES.map((type) => (
                    <button
                      type="button"
                      key={type.value}
                      onClick={() => setMovementType(type.value)}
                      className={`p-4 rounded-lg border-2 transition-all text-left ${
                        movementType === type.value
                          ? 'border-primary-600 bg-primary-50'
                          : 'border-secondary-200 bg-white hover:border-secondary-400'
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <type.icon
                          size={24}
                          className={
                            movementType === type.value ? 'text-primary-600' : 'text-secondary-400'
                          }
                        />
                        <div>
                          <div className="font-semibold text-secondary-900">{type.label}</div>
                          <div className="text-xs text-secondary-500">{type.description}</div>
                        </div>
                      </div>
                    </button>
                  ))}
                </div>
              </div>

              {/* Branch */}
              <div>
                <label className="form-label">
                  <Building2 size={14} className="inline mr-1" />
                  {t('treasury.celIroda')}
                </label>
                <select
                  className="form-input w-full"
                  value={toBranchId}
                  onChange={(e) => setToBranchId(e.target.value)}
                >
                  <option value="">{t('treasury.valasszonCelIrodat')}</option>
                  {vaultCounterparties ? (
                    <>
                      {(vaultCounterparties.territorialCashiers ?? []).filter(
                        (b) => b.isActive !== false,
                      ).length > 0 && (
                        <optgroup label="Helyi Pénztárak">
                          {(vaultCounterparties.territorialCashiers ?? [])
                            .filter((b) => b.isActive !== false)
                            .map((b) => (
                              <option key={b.id} value={b.id}>
                                {b.code}
                                {i18n.t('literals.lit-17')}
                                {b.name}
                              </option>
                            ))}
                        </optgroup>
                      )}
                      {(vaultCounterparties.peerVaults ?? []).filter((b) => b.isActive !== false)
                        .length > 0 && (
                        <optgroup label="Társ értéktárak">
                          {(vaultCounterparties.peerVaults ?? [])
                            .filter((b) => b.isActive !== false)
                            .map((b) => (
                              <option key={b.id} value={b.id}>
                                {b.code}
                                {i18n.t('literals.lit-17')}
                                {b.name}
                              </option>
                            ))}
                        </optgroup>
                      )}
                      {(vaultCounterparties.fixedCounterparties ?? []).filter(
                        (b) => b.isActive !== false,
                      ).length > 0 && (
                        <optgroup label="Banki és speciális partnerek">
                          {(vaultCounterparties.fixedCounterparties ?? [])
                            .filter((b) => b.isActive !== false)
                            .map((b) => (
                              <option key={b.id} value={b.id}>
                                {b.code}
                                {i18n.t('literals.lit-17')}
                                {b.name}
                              </option>
                            ))}
                        </optgroup>
                      )}
                    </>
                  ) : (
                    <option value="" disabled>
                      {i18n.t('literals.partnerek-betoltese')}
                    </option>
                  )}
                </select>
                {counterpartiesError && (
                  <div className="mt-1 flex items-center gap-2 text-xs text-red-600">
                    <span>{t('treasury.celIrodakBetoltesHiba')}</span>
                    <button
                      type="button"
                      onClick={() => void loadCounterparties()}
                      className="font-semibold underline"
                    >
                      {t('treasury.ujra')}
                    </button>
                  </div>
                )}
              </div>

              {/* Currency + Amount */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">{t('common.currency')}</label>
                  <select
                    className="form-input w-full"
                    value={currencyId}
                    onChange={(e) => setCurrencyId(Number(e.target.value))}
                  >
                    <option value={0}>{t('treasury.valasszValutat2')}</option>
                    {currencies.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.code}
                        {i18n.t('literals.lit-18')}
                        {c.name}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="form-label">{t('cashdesk.mennyiseg')}</label>
                  <input
                    type="number"
                    className="form-input w-full font-mono"
                    placeholder="0"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                  />
                </div>
              </div>

              {/* Notes */}
              <div>
                <label className="form-label">{t('blacklist.indoklas')}</label>
                <textarea
                  className="form-input w-full min-h-[80px]"
                  placeholder="Miért szükséges ez a mozgás?"
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                />
              </div>

              {/* FR-1..3: Szállító neve + Plombaszám (kötelező) */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="form-label">
                    {i18n.t('literals.szallito-neve')}
                    <span className="text-red-500">{i18n.t('literals.lit-3')}</span>
                  </label>
                  <input
                    type="text"
                    maxLength={128}
                    className="form-input w-full"
                    placeholder="Szállító neve..."
                    value={carrierName}
                    onChange={(e) => setCarrierName(e.target.value)}
                  />
                </div>
                <div>
                  <label className="form-label">
                    {i18n.t('literals.plombaszam-2')}
                    <span className="text-red-500">{i18n.t('literals.lit-3')}</span>
                  </label>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      maxLength={64}
                      className="form-input w-full"
                      placeholder="Plombaszám..."
                      value={sealNumber}
                      onChange={(e) => setSealNumber(e.target.value)}
                    />
                    <button
                      type="button"
                      className="form-button shrink-0"
                      onClick={() => void generateSealNumber()}
                      disabled={sealGenerating || !worker?.branchCode}
                    >
                      {sealGenerating ? (
                        <RefreshCw size={16} className="animate-spin" />
                      ) : (
                        <Wand2 size={16} />
                      )}
                      <span>{i18n.t('literals.generalas')}</span>
                    </button>
                  </div>
                </div>
              </div>

              {formError && (
                <div className="rounded border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
                  {formError}
                </div>
              )}

              {/* Buttons */}
              <div className="flex items-center justify-end gap-3 pt-4 border-t border-secondary-200">
                <button
                  type="button"
                  className="form-button"
                  onClick={() => setShowNewModal(false)}
                >
                  {t('common.cancel')}
                </button>
                <button
                  type="submit"
                  className="form-button-primary disabled:opacity-50 disabled:cursor-not-allowed"
                  disabled={!toBranchId || !currencyId || !amount}
                >
                  <Save size={18} />
                  <span>{t('common.create')}</span>
                </button>
              </div>
            </form>
          </div>
        </ModalOverlay>
      )}

      {/* Detail Modal */}
      {showDetailModal && (
        <ModalOverlay onClose={() => setShowDetailModal(null)}>
          <div className="bg-white rounded-lg shadow-xl p-4 max-w-lg w-full mx-4">
            <h2 className="text-xl font-bold text-secondary-900 mb-4">
              {t('treasury.mozgasReszletei')}
              {showDetailModal.transferNumber}
            </h2>
            <div className="space-y-3 text-sm">
              <DetailRow
                label="Típus"
                value={
                  MOVEMENT_TYPE_LABELS[showDetailModal.transferType] ??
                  showDetailModal.transferTypeDisplay
                }
              />
              <DetailRow label="Forrás" value={showDetailModal.fromBranchName} />
              <DetailRow label="Cél" value={showDetailModal.toBranchName} />
              <DetailRow label="Valuta" value={showDetailModal.currencyCode} />
              <DetailRow label="Összeg" value={formatInteger(showDetailModal.amount)} mono />
              <DetailRow
                label="Státusz"
                value={
                  MOVEMENT_STATUS_LABELS[showDetailModal.status] ?? showDetailModal.statusDisplay
                }
              />
              <DetailRow label="Kérte" value={showDetailModal.fromWorkerName} />
              <DetailRow label="Létrehozva" value={formatDateTime(showDetailModal.createdAt)} />
              {showDetailModal.notes && (
                <DetailRow label="Megjegyzés" value={showDetailModal.notes} />
              )}
            </div>
            <button
              onClick={() => setShowDetailModal(null)}
              className="form-button-primary w-full mt-6"
            >
              {t('common.close')}
            </button>
          </div>
        </ModalOverlay>
      )}
    </div>
  )
}

// ---- Helper components ----

function ModalOverlay({ children, onClose }: { children: React.ReactNode; onClose: () => void }) {
  return (
    <div
      className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center"
      onClick={onClose}
    >
      <div onClick={(e) => e.stopPropagation()}>{children}</div>
    </div>
  )
}

function DetailRow({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex justify-between py-1 border-b border-secondary-100">
      <span className="text-secondary-600">{label}</span>
      <span className={`font-semibold text-secondary-900 ${mono ? 'font-mono' : ''}`}>{value}</span>
    </div>
  )
}
