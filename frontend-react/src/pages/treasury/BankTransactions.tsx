import { useState, useEffect, useCallback, useMemo, useRef } from 'react'
import {
  Plus,
  Building2,
  TrendingUp,
  TrendingDown,
  RefreshCw,
  CheckCircle,
  Eye,
  Package,
  Banknote,
  Trash2,
} from 'lucide-react'
import { useHotkeys } from 'react-hotkeys-hook'
import { ertektarApi, currencyApi, bankApi } from '../../services/api/index'
import { resolveDefaultBankName } from './bankDefaults'
import type {
  BankTransaction,
  BankTransactionRequest,
  Currency,
  BankInfo,
} from '../../services/api/index'
import { formatInteger, formatDateTime, currencyColorClass } from './treasuryUtils'
import { TableSkeleton } from './LoadingSkeleton'
import {
  isElectronQueueAvailable,
  saveAndSyncPendingBankTransaction,
} from '../../utils/electronTransactions'
import { getLocalPendingBankTransactions } from '../../utils/localQueue'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

export default function BankTransactions() {
  const { t } = useTranslation()
  const electronQueueAvailable = isElectronQueueAvailable()
  const [loading, setLoading] = useState(true)
  const [transactions, setTransactions] = useState<BankTransaction[]>([])
  const [currencies, setCurrencies] = useState<Currency[]>([])
  // FK-005/C1: a banki tranzakció bank-választója a területileg szűrt Bank-törzsből.
  const [banks, setBanks] = useState<BankInfo[]>([])
  const [bankMasterName, setBankMasterName] = useState('')
  const [bankMasterRegionCode, setBankMasterRegionCode] = useState('')
  const [bankMasterSaving, setBankMasterSaving] = useState(false)
  const [bankMasterError, setBankMasterError] = useState<string | null>(null)
  const [showNewModal, setShowNewModal] = useState(false)
  const [showDetailModal, setShowDetailModal] = useState<BankTransaction | null>(null)
  const [typeFilter, setTypeFilter] = useState('all')

  // Form state
  const [txType, setTxType] = useState<'BUY' | 'SELL'>('BUY')
  const [currencyCode, setCurrencyCode] = useState('')
  const [amount, setAmount] = useState('')
  const [exchangeRate, setExchangeRate] = useState('')
  const [bankName, setBankName] = useState('')
  const [bankRef, setBankRef] = useState('')
  const [note, setNote] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [workflowSubmitting, setWorkflowSubmitting] = useState(false)

  const fetchData = useCallback(async () => {
    try {
      const [txDataRaw, currDataRaw, localPending] = await Promise.all([
        ertektarApi.getBankTransactions().catch(() => []),
        currencyApi.list().catch(() => []),
        electronQueueAvailable
          ? getLocalPendingBankTransactions()
          : Promise.resolve([] as BankTransaction[]),
      ])
      const txData = safeArray<BankTransaction>(txDataRaw)
      const currData = safeArray<Currency>(currDataRaw)
      setTransactions([...localPending, ...txData])
      setCurrencies(currData)
    } catch (err) {
      logger.error('BankTransactions', 'BankTransactions fetch error:', err)
    } finally {
      setLoading(false)
    }
  }, [electronQueueAvailable])

  useEffect(() => {
    void fetchData()
  }, [fetchData])

  const loadBanks = useCallback(async () => {
    try {
      setBankMasterError(null)
      setBanks(await bankApi.list())
    } catch (err) {
      logger.error('BankTransactions', 'Bank master load error:', err)
      setBanks([])
      setBankMasterError('A bank-törzs nem tölthető be.')
    }
  }, [])

  // FK-005/C1: a Bank-törzs betöltése (területileg szűrt — a backend AccessScopeService dönt).
  // Hiba esetén üres lista marad → a bank-mező szabad-szövegként továbbra is használható.
  useEffect(() => {
    void loadBanks()
  }, [loadBanks])

  const handleCreateBank = useCallback(
    async (event: React.FormEvent) => {
      event.preventDefault()
      const name = bankMasterName.trim()
      if (!name) {
        setBankMasterError('Banknév megadása kötelező.')
        return
      }
      setBankMasterSaving(true)
      setBankMasterError(null)
      try {
        await bankApi.create({
          name,
          regionCode: bankMasterRegionCode.trim() || undefined,
        })
        setBankMasterName('')
        setBankMasterRegionCode('')
        await loadBanks()
      } catch (err) {
        logger.error('BankTransactions', 'Bank master create error:', err)
        setBankMasterError('A bank felvétele sikertelen.')
      } finally {
        setBankMasterSaving(false)
      }
    },
    [bankMasterName, bankMasterRegionCode, loadBanks],
  )

  const handleDeactivateBank = useCallback(
    async (bank: BankInfo) => {
      if (!confirm(`Biztosan deaktiválja ezt a bankot: ${bank.name}?`)) return
      setBankMasterSaving(true)
      setBankMasterError(null)
      try {
        await bankApi.deactivate(bank.id)
        await loadBanks()
      } catch (err) {
        logger.error('BankTransactions', 'Bank master deactivate error:', err)
        setBankMasterError('A bank deaktiválása sikertelen.')
      } finally {
        setBankMasterSaving(false)
      }
    },
    [loadBanks],
  )

  // Üzleti szabály: az értéktárak kizárólag a Raiffeisennel szerződnek → a banki átadás
  // célja minden esetben a Raiffeisen. A kollégának ne kelljen választania: legyen ez az
  // alapértelmezett. (A datalist a kézi felülírást továbbra is megengedi.)
  const defaultBankName = useMemo(() => resolveDefaultBankName(banks), [banks])

  // Az utoljára automatikusan beírt default — ehhez képest tudjuk eldönteni, hogy a mező
  // még „auto-vezérelt" (frissíthető), vagy a felhasználó kézzel írt bele (nem nyúlunk hozzá).
  const autoAppliedBankRef = useRef('')

  // A Bank-törzs aszinkron töltődik: kezdetben a kanonikus „Raiffeisen Bank" fallback megy be,
  // majd amikor megjön a törzs (pl. pontos „RAIFFEISEN BANK Zrt." név), frissítjük — DE csak ha
  // a mező üres VAGY még a korábbi auto-default-ot tartalmazza (kézi felülírást megőrzünk).
  useEffect(() => {
    setBankName((prev) => (!prev || prev === autoAppliedBankRef.current ? defaultBankName : prev))
    autoAppliedBankRef.current = defaultBankName
  }, [defaultBankName])

  useHotkeys('n', () => setShowNewModal(true), { enableOnFormTags: false })
  useHotkeys(
    'escape',
    () => {
      setShowNewModal(false)
      setShowDetailModal(null)
    },
    { enableOnFormTags: true },
  )

  const resetForm = useCallback(() => {
    setCurrencyCode('')
    setAmount('')
    setExchangeRate('')
    setBankName(defaultBankName)
    setBankRef('')
    setNote('')
  }, [defaultBankName])

  const handleSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault()
      if (!currencyCode || !amount || !exchangeRate) return
      setSubmitting(true)
      try {
        const computedHufAmount = parseFloat(amount) * parseFloat(exchangeRate) || 0
        // Üzleti szabály: a banki átadás célja minden esetben a Raiffeisen → ha a mezőt
        // kiürítették, a default (Raiffeisen) megy ki, sose üres/undefined bankName.
        const effectiveBankName = bankName.trim() || defaultBankName
        const request: BankTransactionRequest = {
          transactionType: txType,
          currencyCode,
          amount: parseFloat(amount),
          exchangeRate: parseFloat(exchangeRate),
          bankName: effectiveBankName,
          bankReference: bankRef || undefined,
          note: note || undefined,
        }

        if (electronQueueAvailable) {
          await saveAndSyncPendingBankTransaction({
            transactionType: txType,
            currencyCode,
            amount: parseFloat(amount),
            exchangeRate: parseFloat(exchangeRate),
            hufAmount: computedHufAmount,
            vaultTerritoryId: null,
            bankName: effectiveBankName,
            bankReference: bankRef || null,
            note: note || null,
          })
        } else {
          await ertektarApi.createBankTransaction(request)
        }

        setShowNewModal(false)
        resetForm()
        void fetchData()
      } catch (err) {
        logger.error('BankTransactions', 'Create bank transaction error:', err)
      } finally {
        setSubmitting(false)
      }
    },
    [
      txType,
      currencyCode,
      amount,
      exchangeRate,
      bankName,
      defaultBankName,
      bankRef,
      note,
      fetchData,
      electronQueueAvailable,
      resetForm,
    ],
  )

  const handleConfirmReceived = useCallback(
    async (id: number) => {
      setWorkflowSubmitting(true)
      try {
        const updated = await ertektarApi.confirmBankTransactionReceived(id)
        setShowDetailModal(updated)
        void fetchData()
      } catch (err) {
        logger.error('BankTransactions', 'confirmReceived error:', err)
      } finally {
        setWorkflowSubmitting(false)
      }
    },
    [fetchData],
  )

  const handleConfirmPaid = useCallback(
    async (id: number) => {
      setWorkflowSubmitting(true)
      try {
        const updated = await ertektarApi.confirmBankTransactionPaid(id)
        setShowDetailModal(updated)
        void fetchData()
      } catch (err) {
        logger.error('BankTransactions', 'confirmPaid error:', err)
      } finally {
        setWorkflowSubmitting(false)
      }
    },
    [fetchData],
  )

  const hufAmount =
    amount && exchangeRate ? (parseFloat(amount) * parseFloat(exchangeRate)).toFixed(0) : ''

  const filtered = transactions.filter(
    (t) => typeFilter === 'all' || t.transactionType === typeFilter,
  )

  if (loading) return <TableSkeleton rows={6} cols={7} />

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <h1 className="text-xl font-bold text-secondary-900">{t('treasury.bankiTranzakciok')}</h1>
          <span className="badge badge-blue">
            <TrendingUp size={12} />
            {t('darius.vetel')}
            {transactions.filter((t) => t.transactionType === 'BUY').length}
          </span>
          <span className="badge badge-orange">
            <TrendingDown size={12} />
            {t('darius.eladas')}
            {transactions.filter((t) => t.transactionType === 'SELL').length}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <select
            className="form-input w-36 h-8 text-xs"
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
          >
            <option value="all">{t('treasury.mindenTipus')}</option>
            <option value="BUY">{t('cashier.buy')}</option>
            <option value="SELL">{t('cashier.sell')}</option>
          </select>
          <button onClick={() => void fetchData()} className="form-button h-8 text-xs">
            <RefreshCw size={14} />
          </button>
          <button onClick={() => setShowNewModal(true)} className="form-button-primary h-8 text-xs">
            <Plus size={16} />
            <span>{t('treasury.ujTranzakcio')}</span>
          </button>
        </div>
      </div>

      {/* Transaction table */}
      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th className="w-16">{i18n.t('literals.id')}</th>
              <th className="w-20">{t('common.type')}</th>
              <th className="w-16">{t('common.currency')}</th>
              <th className="text-right w-28">{t('cashdesk.mennyiseg')}</th>
              <th className="text-right w-24">{t('cashier.exchangeRate')}</th>
              <th className="text-right w-28">{t('stockSnapshot.hufValue')}</th>
              <th className="w-32">{t('sync.bank')}</th>
              <th className="w-24">{t('common.status')}</th>
              <th className="w-32">{t('common.date')}</th>
              <th className="w-8"></th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 && (
              <tr>
                <td colSpan={10} className="text-center text-sm text-secondary-400 py-8">
                  {t('treasury.nincsTalalat')}
                </td>
              </tr>
            )}
            {filtered.map((tx) => (
              <tr key={tx.id}>
                <td className="font-mono text-xs">
                  {i18n.t('literals.lit-12')}
                  {tx.id}
                </td>
                <td>
                  <span
                    className={`badge ${tx.transactionType === 'BUY' ? 'badge-blue' : 'badge-orange'}`}
                  >
                    {tx.transactionType === 'BUY' ? 'Vétel' : 'Eladás'}
                  </span>
                </td>
                <td className={`font-bold ${currencyColorClass(tx.currencyCode)}`}>
                  {tx.currencyCode}
                </td>
                <td className="text-right font-mono font-semibold">{formatInteger(tx.amount)}</td>
                <td className="text-right font-mono text-xs">{tx.exchangeRate?.toFixed(2)}</td>
                <td className="text-right font-mono font-semibold">
                  {formatInteger(tx.hufAmount)} {t('common.ft')}
                </td>
                <td className="text-xs text-secondary-600">{tx.bankName || '-'}</td>
                <td>
                  <span
                    className={`badge ${tx.status === 'COMPLETED' ? 'badge-green' : 'badge-yellow'}`}
                  >
                    {tx.status === 'COMPLETED' ? 'Teljesitett' : tx.status}
                  </span>
                </td>
                <td className="text-xs">{formatDateTime(tx.createdAt)}</td>
                <td>
                  <button
                    className="text-primary-600 hover:text-primary-700"
                    onClick={() => setShowDetailModal(tx)}
                  >
                    <Eye size={16} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <section className="form-panel space-y-3">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-sm font-semibold text-secondary-900">
              {i18n.t('literals.bank-torzs')}
            </h2>
            <p className="text-xs text-secondary-500">
              {i18n.t('literals.banki-atadas-atvetel-celbankjai-teruleti')}
            </p>
          </div>
          <button
            type="button"
            onClick={() => void loadBanks()}
            className="form-button h-8 text-xs"
          >
            <RefreshCw size={14} />
            {i18n.t('literals.frissit')}
          </button>
        </div>

        {bankMasterError && (
          <div className="rounded border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
            {bankMasterError}
          </div>
        )}

        <form
          onSubmit={(event) => void handleCreateBank(event)}
          className="grid grid-cols-1 gap-2 sm:grid-cols-[minmax(0,1fr)_10rem_auto]"
        >
          <label className="block text-sm">
            <span className="mb-1 block text-xs font-semibold text-secondary-600">
              {i18n.t('literals.bank-neve')}
            </span>
            <input
              value={bankMasterName}
              onChange={(event) => setBankMasterName(event.target.value)}
              className="form-input w-full"
              placeholder="Raiffeisen Bank"
            />
          </label>
          <label className="block text-sm">
            <span className="mb-1 block text-xs font-semibold text-secondary-600">
              {i18n.t('literals.teruletkod')}
            </span>
            <input
              value={bankMasterRegionCode}
              onChange={(event) => setBankMasterRegionCode(event.target.value)}
              className="form-input w-full"
              placeholder="20"
            />
          </label>
          <button
            type="submit"
            disabled={bankMasterSaving}
            className="form-button-primary self-end"
          >
            <Plus size={16} />
            {i18n.t('literals.felvetel-2')}
          </button>
        </form>

        <div className="overflow-x-auto">
          <table className="data-grid w-full">
            <thead>
              <tr>
                <th>{i18n.t('literals.bank-5')}</th>
                <th className="w-28">{i18n.t('literals.terulet')}</th>
                <th className="w-20"></th>
              </tr>
            </thead>
            <tbody>
              {banks.length === 0 && (
                <tr>
                  <td colSpan={3} className="py-4 text-center text-sm text-secondary-400">
                    {i18n.t('literals.nincs-bank-torzs-adat')}
                  </td>
                </tr>
              )}
              {banks.map((bank) => (
                <tr key={bank.id}>
                  <td>{bank.name}</td>
                  <td className="font-mono text-xs">{bank.regionCode || '-'}</td>
                  <td className="text-right">
                    <button
                      type="button"
                      disabled={bankMasterSaving}
                      onClick={() => void handleDeactivateBank(bank)}
                      className="inline-flex items-center justify-center rounded border border-red-200 p-1 text-red-600 hover:bg-red-50 disabled:opacity-50"
                      title="Deaktiválás"
                    >
                      <Trash2 size={14} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {/* New Transaction Modal */}
      {showNewModal && (
        <div
          className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center"
          onClick={() => setShowNewModal(false)}
        >
          <div
            className="bg-white rounded-lg shadow-xl p-4 max-w-lg w-full mx-4"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="text-xl font-bold text-secondary-900 mb-3 flex items-center gap-2">
              <Building2 size={24} className="text-primary-600" />
              {t('treasury.ujBankiTranzakcio')}
            </h2>
            <form onSubmit={(e) => void handleSubmit(e)} className="space-y-4">
              {/* Type selector */}
              <div className="grid grid-cols-2 gap-3">
                <button
                  type="button"
                  onClick={() => setTxType('BUY')}
                  className={`p-3 rounded-lg border-2 transition-all flex items-center gap-2 ${
                    txType === 'BUY'
                      ? 'border-blue-500 bg-blue-50'
                      : 'border-secondary-200 hover:border-secondary-400'
                  }`}
                >
                  <TrendingUp
                    size={20}
                    className={txType === 'BUY' ? 'text-blue-600' : 'text-secondary-400'}
                  />
                  <div className="text-left">
                    <div className="font-semibold">{t('cashier.buy')}</div>
                    <div className="text-xs text-secondary-500">{t('treasury.bankbolValuta')}</div>
                  </div>
                </button>
                <button
                  type="button"
                  onClick={() => setTxType('SELL')}
                  className={`p-3 rounded-lg border-2 transition-all flex items-center gap-2 ${
                    txType === 'SELL'
                      ? 'border-orange-500 bg-orange-50'
                      : 'border-secondary-200 hover:border-secondary-400'
                  }`}
                >
                  <TrendingDown
                    size={20}
                    className={txType === 'SELL' ? 'text-orange-600' : 'text-secondary-400'}
                  />
                  <div className="text-left">
                    <div className="font-semibold">{t('cashier.sell')}</div>
                    <div className="text-xs text-secondary-500">{t('treasury.banknakValuta')}</div>
                  </div>
                </button>
              </div>

              {/* Currency */}
              <div>
                <label className="form-label">{t('common.currency')}</label>
                <select
                  className="form-input w-full"
                  value={currencyCode}
                  onChange={(e) => setCurrencyCode(e.target.value)}
                  required
                >
                  <option value="">{t('treasury.valasszValutat')}</option>
                  {currencies
                    .filter((c) => c.code !== 'HUF')
                    .map((c) => (
                      <option key={c.code} value={c.code}>
                        {c.code}
                        {i18n.t('literals.lit-18')}
                        {c.name}
                      </option>
                    ))}
                </select>
              </div>

              {/* Amount + Rate */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">{t('treasury.mennyiseg')}</label>
                  <input
                    type="number"
                    className="form-input w-full font-mono"
                    placeholder="0"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    required
                    min="0.01"
                    step="0.01"
                  />
                </div>
                <div>
                  <label className="form-label">{t('treasury.arfolyamHuf1Egyseg')}</label>
                  <input
                    type="number"
                    className="form-input w-full font-mono"
                    placeholder="0.00"
                    value={exchangeRate}
                    onChange={(e) => setExchangeRate(e.target.value)}
                    required
                    min="0.0001"
                    step="0.0001"
                  />
                </div>
              </div>

              {/* HUF preview */}
              {hufAmount && (
                <div className="p-3 rounded-lg bg-secondary-50 border border-secondary-200">
                  <div className="text-sm text-secondary-600">{t('treasury.hufEllenerteke')}</div>
                  <div className="text-lg font-bold font-mono text-secondary-900">
                    {parseInt(hufAmount).toLocaleString('hu-HU')} {t('common.ft')}
                  </div>
                </div>
              )}

              {/* Bank details */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="form-label">{t('treasury.bankNeve')}</label>
                  {/* FK-005/C1: az értéktárak kizárólag a Raiffeisennel szerződnek → a bank
                      alapból Raiffeisen. A datalist a területileg szűrt Bank-törzsből engedi
                      a kézi felülírást is, ha kivételesen más bankhoz adnánk át. */}
                  <input
                    type="text"
                    list="bank-master-list"
                    className="form-input w-full"
                    placeholder="Raiffeisen Bank"
                    value={bankName}
                    onChange={(e) => setBankName(e.target.value)}
                  />
                  <datalist id="bank-master-list">
                    {banks.map((b) => (
                      <option key={b.id} value={b.name} />
                    ))}
                  </datalist>
                </div>
                <div>
                  <label className="form-label">{t('treasury.bankiHivatkozas')}</label>
                  <input
                    type="text"
                    className="form-input w-full"
                    placeholder="Referenciaszam"
                    value={bankRef}
                    onChange={(e) => setBankRef(e.target.value)}
                  />
                </div>
              </div>

              {/* Note */}
              <div>
                <label className="form-label">{t('treasury.megjegyzes')}</label>
                <textarea
                  className="form-input w-full min-h-[60px]"
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                />
              </div>

              {/* Buttons */}
              <div className="flex justify-end gap-3 pt-4 border-t">
                <button
                  type="button"
                  className="form-button"
                  onClick={() => setShowNewModal(false)}
                >
                  {t('common.cancel')}
                </button>
                <button type="submit" className="form-button-primary" disabled={submitting}>
                  <CheckCircle size={18} />
                  <span>{submitting ? 'Feldolgozás...' : 'Végrehajtás'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Detail Modal */}
      {showDetailModal && (
        <div
          className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center"
          onClick={() => setShowDetailModal(null)}
        >
          <div
            className="bg-white rounded-lg shadow-xl p-4 max-w-md w-full mx-4"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="text-xl font-bold text-secondary-900 mb-4">
              {t('treasury.tranzakcio')}
              {showDetailModal.id}
            </h2>
            <div className="space-y-2 text-sm">
              <Row
                label="Típus"
                value={showDetailModal.transactionType === 'BUY' ? 'Banki vétel' : 'Banki eladás'}
              />
              <Row label="Valuta" value={showDetailModal.currencyCode} />
              <Row label="Mennyiség" value={formatInteger(showDetailModal.amount)} mono />
              <Row label="Árfolyam" value={showDetailModal.exchangeRate?.toFixed(4)} mono />
              <Row
                label="HUF érték"
                value={`${formatInteger(showDetailModal.hufAmount)} Ft`}
                mono
              />
              <Row label="Bank" value={showDetailModal.bankName || '-'} />
              <Row label="Ref." value={showDetailModal.bankReference || '-'} />
              <Row label="Státusz" value={showDetailModal.status} />
              <Row label="Dátum" value={formatDateTime(showDetailModal.createdAt)} />
              {showDetailModal.receivedAt && (
                <Row label="Deviza beerkezett" value={formatDateTime(showDetailModal.receivedAt)} />
              )}
              {showDetailModal.paidAt && (
                <Row label="HUF atutalva" value={formatDateTime(showDetailModal.paidAt)} />
              )}
              {showDetailModal.completedAt && (
                <Row label="Teljesitve" value={formatDateTime(showDetailModal.completedAt)} />
              )}
              {showDetailModal.note && <Row label="Megjegyzes" value={showDetailModal.note} />}
            </div>

            {/* Workflow gombok — csak amig nem COMPLETED */}
            {showDetailModal.status !== 'COMPLETED' && (
              <div className="mt-4 space-y-2 border-t pt-4">
                <div className="text-xs font-semibold text-secondary-600 mb-2">
                  {t('treasury.workflowLepesek')}
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    type="button"
                    className={
                      showDetailModal.receivedAt
                        ? 'form-button cursor-default opacity-60'
                        : 'form-button-primary'
                    }
                    disabled={!!showDetailModal.receivedAt || workflowSubmitting}
                    onClick={() => void handleConfirmReceived(showDetailModal.id)}
                  >
                    <Package size={16} />
                    <span>{showDetailModal.receivedAt ? 'Deviza ok' : 'Deviza beerkezett'}</span>
                  </button>
                  <button
                    type="button"
                    className={
                      showDetailModal.paidAt
                        ? 'form-button cursor-default opacity-60'
                        : 'form-button-primary'
                    }
                    disabled={!!showDetailModal.paidAt || workflowSubmitting}
                    onClick={() => void handleConfirmPaid(showDetailModal.id)}
                  >
                    <Banknote size={16} />
                    <span>{showDetailModal.paidAt ? 'HUF ok' : 'HUF atutalva'}</span>
                  </button>
                </div>
                <div className="text-xs text-secondary-500">
                  {t(
                    'treasury.haMindketOldalMegerositveATranzakcioAutomatikusanCompletedAllapotbaKerul',
                  )}
                </div>
              </div>
            )}

            <button
              onClick={() => setShowDetailModal(null)}
              className="form-button-primary w-full mt-6"
            >
              {t('components.bezaras')}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

function Row({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex justify-between py-1 border-b border-secondary-100">
      <span className="text-secondary-600">{label}</span>
      <span className={`font-semibold text-secondary-900 ${mono ? 'font-mono' : ''}`}>{value}</span>
    </div>
  )
}
