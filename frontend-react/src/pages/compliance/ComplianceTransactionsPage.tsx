import { type FormEvent, useCallback, useEffect, useState } from 'react'
import { Download, RefreshCw, Search } from 'lucide-react'
import {
  complianceTransactionsApi,
  PAYMENT_METHOD_LABELS,
  TRANSACTION_TYPE_LABELS,
  type CompliancePaymentMethod,
  type ComplianceTransactionRowDto,
  type ComplianceTransactionSearchCriteria,
  type ComplianceTransactionType,
} from '../../services/api/complianceTransactions'
import { branchApi, type BranchInfo } from '../../services/api/settings'
import { currencyApi, type Currency } from '../../services/api/exchange-rates'
import { toast } from '../../components/ui/toaster'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import { formatDecimal, formatInteger } from '../../utils/numberFormat'
import { downloadBlob } from '../../utils/downloadBlob'

const PAGE_SIZE = 50

interface FilterFormState {
  branchId: string
  startDate: string
  endDate: string
  type: ComplianceTransactionType | ''
  minHufAmount: string
  maxHufAmount: string
  currencyIds: number[]
  paymentMethod: CompliancePaymentMethod | ''
  customRateOnly: boolean
  kkDiscountOnly: boolean
  onBehalfOfOtherOnly: boolean
  pepOnly: boolean
  customerName: string
  customerBirthDate: string
  customerNationality: string
  customerDocumentNumber: string
  legalEntityOnly: boolean
  legalEntityName: string
  legalEntityTaxNumber: string
  legalDeedNumber: string
  legalEntitySeat: string
}

const EMPTY_FILTERS: FilterFormState = {
  branchId: '',
  startDate: '',
  endDate: '',
  type: '',
  minHufAmount: '',
  maxHufAmount: '',
  currencyIds: [],
  paymentMethod: '',
  customRateOnly: false,
  kkDiscountOnly: false,
  onBehalfOfOtherOnly: false,
  pepOnly: false,
  customerName: '',
  customerBirthDate: '',
  customerNationality: '',
  customerDocumentNumber: '',
  legalEntityOnly: false,
  legalEntityName: '',
  legalEntityTaxNumber: '',
  legalDeedNumber: '',
  legalEntitySeat: '',
}

function toCriteria(form: FilterFormState): ComplianceTransactionSearchCriteria {
  const criteria: ComplianceTransactionSearchCriteria = {}
  if (form.branchId) criteria.branchId = form.branchId
  if (form.startDate) criteria.startDate = form.startDate
  if (form.endDate) criteria.endDate = form.endDate
  if (form.type) criteria.type = form.type
  if (form.minHufAmount.trim()) criteria.minHufAmount = form.minHufAmount.trim()
  if (form.maxHufAmount.trim()) criteria.maxHufAmount = form.maxHufAmount.trim()
  if (form.currencyIds.length > 0) criteria.currencyIds = form.currencyIds
  if (form.paymentMethod) criteria.paymentMethod = form.paymentMethod
  if (form.customRateOnly) criteria.customRateOnly = true
  if (form.kkDiscountOnly) criteria.kkDiscountOnly = true
  if (form.onBehalfOfOtherOnly) criteria.onBehalfOfOtherOnly = true
  if (form.pepOnly) criteria.pepOnly = true
  if (form.customerName.trim()) criteria.customerName = form.customerName.trim()
  if (form.customerBirthDate) criteria.customerBirthDate = form.customerBirthDate
  if (form.customerNationality.trim())
    criteria.customerNationality = form.customerNationality.trim()
  if (form.customerDocumentNumber.trim()) {
    criteria.customerDocumentNumber = form.customerDocumentNumber.trim()
  }
  if (form.legalEntityOnly) criteria.legalEntityOnly = true
  if (form.legalEntityName.trim()) criteria.legalEntityName = form.legalEntityName.trim()
  if (form.legalEntityTaxNumber.trim()) {
    criteria.legalEntityTaxNumber = form.legalEntityTaxNumber.trim()
  }
  if (form.legalDeedNumber.trim()) criteria.legalDeedNumber = form.legalDeedNumber.trim()
  if (form.legalEntitySeat.trim()) criteria.legalEntitySeat = form.legalEntitySeat.trim()
  return criteria
}

function logAndToastError(title: string, action: string, err: unknown): void {
  const message = getErrorMessage(err)
  logger.error('ComplianceTransactionsPage', action, message)
  toast.error(title, message)
}

function buildBranchLabel(branch: BranchInfo): string {
  return `${branch.code} — ${branch.name}`
}

function buildCurrencyLabel(currency: Currency): string {
  return `${currency.code} — ${currency.name}`
}

function getTransactionLabel(type: string): string {
  return TRANSACTION_TYPE_LABELS[type] ?? type
}

function getPaymentMethodLabel(method: string | null): string {
  if (!method) return '—'
  return PAYMENT_METHOD_LABELS[method] ?? method
}

function flagBadges(row: ComplianceTransactionRowDto): string[] {
  const badges: string[] = []
  if (row.customerIsPep) badges.push('PEP')
  if (row.cashierCustomRate) badges.push('Egyedi árf.')
  if (row.kkDiscount) badges.push('KK')
  if (row.customerOnOwnBehalf === false) badges.push('Más nevében')
  if (row.amlSuspicious) badges.push('AML')
  return badges
}

export default function ComplianceTransactionsPage() {
  const [form, setForm] = useState<FilterFormState>(EMPTY_FILTERS)
  const [activeCriteria, setActiveCriteria] = useState<ComplianceTransactionSearchCriteria | null>(
    null,
  )
  const [rows, setRows] = useState<ComplianceTransactionRowDto[]>([])
  const [page, setPage] = useState(0)
  const [totalPages, setTotalPages] = useState(0)
  const [totalElements, setTotalElements] = useState(0)
  const [branches, setBranches] = useState<BranchInfo[]>([])
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [loading, setLoading] = useState(false)
  const [masterLoading, setMasterLoading] = useState(false)
  const [exporting, setExporting] = useState<'csv' | 'xlsx' | null>(null)

  const loadMasterData = useCallback(async () => {
    setMasterLoading(true)
    try {
      const [branchList, currencyList] = await Promise.all([
        branchApi.listActive(),
        currencyApi.list(),
      ])
      setBranches(safeArray<BranchInfo>(branchList))
      setCurrencies(safeArray<Currency>(currencyList))
    } catch (err) {
      logAndToastError('Törzsadat betöltési hiba', 'Törzsadatok betöltése sikertelen:', err)
      setBranches([])
      setCurrencies([])
    } finally {
      setMasterLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadMasterData()
  }, [loadMasterData])

  const runSearch = useCallback(
    async (criteria: ComplianceTransactionSearchCriteria, targetPage: number) => {
      setLoading(true)
      try {
        const result = await complianceTransactionsApi.search(criteria, targetPage, PAGE_SIZE)
        setRows(safeArray<ComplianceTransactionRowDto>(result.content))
        setTotalPages(result.totalPages ?? 0)
        setTotalElements(result.totalElements ?? 0)
        setPage(targetPage)
      } catch (err) {
        logAndToastError('Keresési hiba', 'Keresés sikertelen:', err)
        setRows([])
        setTotalPages(0)
        setTotalElements(0)
      } finally {
        setLoading(false)
      }
    },
    [],
  )

  function updateField<K extends keyof FilterFormState>(key: K, value: FilterFormState[K]): void {
    setForm((current) => ({ ...current, [key]: value }))
  }

  const handleSearch = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const criteria = toCriteria(form)
    setActiveCriteria(criteria)
    void runSearch(criteria, 0)
  }

  const goToPage = (targetPage: number) => {
    if (!activeCriteria || loading) return
    void runSearch(activeCriteria, targetPage)
  }

  const handleExport = async (kind: 'csv' | 'xlsx') => {
    if (!activeCriteria || exporting) return
    setExporting(kind)
    try {
      const today = new Date().toISOString().slice(0, 10)
      if (kind === 'csv') {
        const data = await complianceTransactionsApi.exportCsv(activeCriteria)
        downloadBlob(data, `compliance_tranzakciok_${today}.csv`, 'text/csv;charset=utf-8')
      } else {
        const data = await complianceTransactionsApi.exportXlsx(activeCriteria)
        downloadBlob(
          data,
          `compliance_tranzakciok_${today}.xlsx`,
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        )
      }
      toast.success('Export letöltve')
    } catch (err) {
      logAndToastError('Export sikertelen', 'Export sikertelen:', err)
    } finally {
      setExporting(null)
    }
  }

  const exportDisabled = !activeCriteria || loading || exporting !== null

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between gap-4">
        <h1 className="form-title flex items-center gap-2">
          <Search className="h-6 w-6" /> Compliance tranzakciók
        </h1>
        <button
          type="button"
          onClick={() => void loadMasterData()}
          className="form-button flex items-center gap-2"
          disabled={masterLoading}
        >
          <RefreshCw className={`h-4 w-4 ${masterLoading ? 'animate-spin' : ''}`} /> Törzsadat
          frissítés
        </button>
      </div>

      <div className="rounded-md border border-blue-200 bg-blue-50 p-3 text-sm text-blue-900">
        A lista cégszintű compliance keresést végez. A lekérdezés csak a Keresés gombbal indul,
        exportálni pedig a legutóbb futtatott keresés szűrőivel lehet.
      </div>

      <form
        className="grid grid-cols-12 gap-3 rounded-md border border-gray-200 p-4"
        onSubmit={handleSearch}
      >
        <fieldset className="col-span-12 grid grid-cols-12 gap-3 rounded border border-gray-100 p-3">
          <legend className="px-1 text-sm font-semibold text-gray-700">Tranzakció</legend>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-branchId">
              Iroda
            </label>
            <select
              id="filter-branchId"
              data-testid="filter-branchId"
              className="form-input"
              value={form.branchId}
              onChange={(event) => updateField('branchId', event.target.value)}
            >
              <option value="">Összes iroda</option>
              {branches.map((branch) => (
                <option key={branch.id} value={branch.id}>
                  {buildBranchLabel(branch)}
                </option>
              ))}
            </select>
          </div>
          <div className="col-span-12 md:col-span-2">
            <label className="form-label" htmlFor="filter-startDate">
              Kezdő dátum
            </label>
            <input
              id="filter-startDate"
              data-testid="filter-startDate"
              type="date"
              className="form-input"
              value={form.startDate}
              onChange={(event) => updateField('startDate', event.target.value)}
            />
          </div>
          <div className="col-span-12 md:col-span-2">
            <label className="form-label" htmlFor="filter-endDate">
              Záró dátum
            </label>
            <input
              id="filter-endDate"
              data-testid="filter-endDate"
              type="date"
              className="form-input"
              value={form.endDate}
              onChange={(event) => updateField('endDate', event.target.value)}
            />
          </div>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-type">
              Típus
            </label>
            <select
              id="filter-type"
              data-testid="filter-type"
              className="form-input"
              value={form.type}
              onChange={(event) =>
                updateField('type', event.target.value as FilterFormState['type'])
              }
            >
              <option value="">Összes típus</option>
              {Object.entries(TRANSACTION_TYPE_LABELS).map(([type, label]) => (
                <option key={type} value={type}>
                  {label}
                </option>
              ))}
            </select>
          </div>
          <div className="col-span-12 md:col-span-2">
            <label className="form-label" htmlFor="filter-paymentMethod">
              Fizetési mód
            </label>
            <select
              id="filter-paymentMethod"
              data-testid="filter-paymentMethod"
              className="form-input"
              value={form.paymentMethod}
              onChange={(event) =>
                updateField('paymentMethod', event.target.value as FilterFormState['paymentMethod'])
              }
            >
              <option value="">Összes mód</option>
              {Object.entries(PAYMENT_METHOD_LABELS).map(([method, label]) => (
                <option key={method} value={method}>
                  {label}
                </option>
              ))}
            </select>
          </div>
        </fieldset>

        <fieldset className="col-span-12 grid grid-cols-12 gap-3 rounded border border-gray-100 p-3">
          <legend className="px-1 text-sm font-semibold text-gray-700">Összeg és valuta</legend>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-minHufAmount">
              Min. HUF
            </label>
            <input
              id="filter-minHufAmount"
              data-testid="filter-minHufAmount"
              type="number"
              className="form-input"
              value={form.minHufAmount}
              onChange={(event) => updateField('minHufAmount', event.target.value)}
            />
          </div>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-maxHufAmount">
              Max. HUF
            </label>
            <input
              id="filter-maxHufAmount"
              data-testid="filter-maxHufAmount"
              type="number"
              className="form-input"
              value={form.maxHufAmount}
              onChange={(event) => updateField('maxHufAmount', event.target.value)}
            />
          </div>
          <div className="col-span-12 md:col-span-6">
            <label className="form-label" htmlFor="filter-currencyIds">
              Valuták
            </label>
            <select
              id="filter-currencyIds"
              data-testid="filter-currencyIds"
              multiple
              size={5}
              className="form-input"
              value={form.currencyIds.map(String)}
              onChange={(event) =>
                updateField(
                  'currencyIds',
                  Array.from(event.target.selectedOptions, (option) => Number(option.value)),
                )
              }
            >
              {currencies.map((currency) => (
                <option key={currency.id} value={currency.id}>
                  {buildCurrencyLabel(currency)}
                </option>
              ))}
            </select>
          </div>
        </fieldset>

        <fieldset className="col-span-12 grid grid-cols-12 gap-3 rounded border border-gray-100 p-3">
          <legend className="px-1 text-sm font-semibold text-gray-700">Ügyfél</legend>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-customerName">
              Ügyfél neve
            </label>
            <input
              id="filter-customerName"
              data-testid="filter-customerName"
              className="form-input"
              value={form.customerName}
              onChange={(event) => updateField('customerName', event.target.value)}
            />
          </div>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-customerBirthDate">
              Születési dátum
            </label>
            <input
              id="filter-customerBirthDate"
              data-testid="filter-customerBirthDate"
              type="date"
              className="form-input"
              value={form.customerBirthDate}
              onChange={(event) => updateField('customerBirthDate', event.target.value)}
            />
          </div>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-customerNationality">
              Állampolgárság
            </label>
            <input
              id="filter-customerNationality"
              data-testid="filter-customerNationality"
              className="form-input"
              value={form.customerNationality}
              onChange={(event) => updateField('customerNationality', event.target.value)}
            />
          </div>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-customerDocumentNumber">
              Okmányszám
            </label>
            <input
              id="filter-customerDocumentNumber"
              data-testid="filter-customerDocumentNumber"
              className="form-input"
              value={form.customerDocumentNumber}
              onChange={(event) => updateField('customerDocumentNumber', event.target.value)}
            />
          </div>
        </fieldset>

        <fieldset className="col-span-12 grid grid-cols-12 gap-3 rounded border border-gray-100 p-3">
          <legend className="px-1 text-sm font-semibold text-gray-700">Jogi személy</legend>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-legalEntityName">
              Jogi személy neve
            </label>
            <input
              id="filter-legalEntityName"
              data-testid="filter-legalEntityName"
              className="form-input"
              value={form.legalEntityName}
              onChange={(event) => updateField('legalEntityName', event.target.value)}
            />
          </div>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-legalEntityTaxNumber">
              Adószám
            </label>
            <input
              id="filter-legalEntityTaxNumber"
              data-testid="filter-legalEntityTaxNumber"
              className="form-input"
              value={form.legalEntityTaxNumber}
              onChange={(event) => updateField('legalEntityTaxNumber', event.target.value)}
            />
          </div>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-legalDeedNumber">
              Okirat száma
            </label>
            <input
              id="filter-legalDeedNumber"
              data-testid="filter-legalDeedNumber"
              className="form-input"
              value={form.legalDeedNumber}
              onChange={(event) => updateField('legalDeedNumber', event.target.value)}
            />
          </div>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-legalEntitySeat">
              Székhely
            </label>
            <input
              id="filter-legalEntitySeat"
              data-testid="filter-legalEntitySeat"
              className="form-input"
              value={form.legalEntitySeat}
              onChange={(event) => updateField('legalEntitySeat', event.target.value)}
            />
          </div>
        </fieldset>

        <fieldset className="col-span-12 rounded border border-gray-100 p-3">
          <legend className="px-1 text-sm font-semibold text-gray-700">Jelölők</legend>
          <div className="grid grid-cols-12 gap-3">
            <label className="col-span-12 flex items-center gap-2 text-sm md:col-span-3">
              <input
                data-testid="filter-customRateOnly"
                type="checkbox"
                checked={form.customRateOnly}
                onChange={(event) => updateField('customRateOnly', event.target.checked)}
              />
              Csak egyedi árfolyam
            </label>
            <label className="col-span-12 flex items-center gap-2 text-sm md:col-span-3">
              <input
                data-testid="filter-kkDiscountOnly"
                type="checkbox"
                checked={form.kkDiscountOnly}
                onChange={(event) => updateField('kkDiscountOnly', event.target.checked)}
              />
              Csak KK-kedvezmény
            </label>
            <label className="col-span-12 flex items-center gap-2 text-sm md:col-span-3">
              <input
                data-testid="filter-onBehalfOfOtherOnly"
                type="checkbox"
                checked={form.onBehalfOfOtherOnly}
                onChange={(event) => updateField('onBehalfOfOtherOnly', event.target.checked)}
              />
              Csak más nevében
            </label>
            <label className="col-span-12 flex items-center gap-2 text-sm md:col-span-3">
              <input
                data-testid="filter-pepOnly"
                type="checkbox"
                checked={form.pepOnly}
                onChange={(event) => updateField('pepOnly', event.target.checked)}
              />
              Csak PEP
            </label>
            <label className="col-span-12 flex items-center gap-2 text-sm md:col-span-3">
              <input
                data-testid="filter-legalEntityOnly"
                type="checkbox"
                checked={form.legalEntityOnly}
                onChange={(event) => updateField('legalEntityOnly', event.target.checked)}
              />
              Csak jogi személy
            </label>
          </div>
        </fieldset>

        <div className="col-span-12 flex flex-wrap items-center gap-2">
          <button
            type="submit"
            data-testid="search-button"
            className="form-button-primary flex items-center gap-2"
            disabled={loading}
          >
            <Search className="h-4 w-4" /> {loading ? 'Keresés...' : 'Keresés'}
          </button>
          <button
            type="button"
            className="form-button"
            onClick={() => setForm(EMPTY_FILTERS)}
            disabled={loading}
          >
            Szűrők törlése
          </button>
          <button
            type="button"
            data-testid="export-csv"
            className="form-button flex items-center gap-2"
            onClick={() => void handleExport('csv')}
            disabled={exportDisabled}
          >
            <Download className="h-4 w-4" /> CSV export
          </button>
          <button
            type="button"
            data-testid="export-xlsx"
            className="form-button flex items-center gap-2"
            onClick={() => void handleExport('xlsx')}
            disabled={exportDisabled}
          >
            <Download className="h-4 w-4" /> XLSX export
          </button>
        </div>
      </form>

      <div className="data-grid overflow-x-auto" data-testid="results-table">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                Dátum
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                Bizonylat
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                Típus
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                Iroda
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                Valuta
              </th>
              <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                Összeg
              </th>
              <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                Árfolyam
              </th>
              <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                HUF
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                Fizetés
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                Ügyfél
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                Jelölők
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                Dolgozó
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {loading && (
              <tr>
                <td colSpan={12} className="px-3 py-4 text-center text-gray-400">
                  Keresés folyamatban...
                </td>
              </tr>
            )}
            {!loading && activeCriteria === null && (
              <tr>
                <td colSpan={12} className="px-3 py-4 text-center text-gray-400">
                  Állítsa be a szűrőket, majd indítsa a keresést.
                </td>
              </tr>
            )}
            {!loading && activeCriteria !== null && rows.length === 0 && (
              <tr>
                <td colSpan={12} className="px-3 py-4 text-center text-gray-400">
                  Nincs a szűrőknek megfelelő tranzakció.
                </td>
              </tr>
            )}
            {!loading &&
              rows.map((row) => {
                const badges = flagBadges(row)
                const customerPrimary = row.isLegalEntityCustomer
                  ? (row.legalEntityName ?? row.customerName ?? '—')
                  : (row.customerName ?? '—')
                const customerSecondary = row.isLegalEntityCustomer
                  ? row.legalEntityTaxNumber
                  : row.customerDocumentNumber
                return (
                  <tr key={row.id} data-testid={`tx-row-${row.id}`}>
                    <td className="px-3 py-2 text-sm">
                      <div>{row.transactionDate}</div>
                      {row.transactionTime && (
                        <div className="text-xs text-gray-500">{row.transactionTime}</div>
                      )}
                    </td>
                    <td className="px-3 py-2 text-sm">
                      <div>{row.receiptNumber ?? '—'}</div>
                      {row.originalReceiptNumber && (
                        <div className="text-xs text-gray-500">
                          Eredeti: {row.originalReceiptNumber}
                        </div>
                      )}
                    </td>
                    <td className="px-3 py-2 text-sm">
                      {getTransactionLabel(row.transactionType)}
                    </td>
                    <td className="px-3 py-2 text-sm">
                      <div>{row.branchCode ?? '—'}</div>
                      {row.branchName && (
                        <div className="text-xs text-gray-500">{row.branchName}</div>
                      )}
                    </td>
                    <td className="px-3 py-2 text-sm font-mono">{row.currencyCode ?? '—'}</td>
                    <td className="px-3 py-2 text-right text-sm font-mono">
                      {formatDecimal(row.currencyAmount, 0, 2)}
                    </td>
                    <td className="px-3 py-2 text-right text-sm font-mono">
                      {formatDecimal(row.exchangeRate, 2, 4)}
                    </td>
                    <td className="px-3 py-2 text-right text-sm font-mono">
                      {formatDecimal(row.hufAmount, 0, 2)}
                    </td>
                    <td className="px-3 py-2 text-sm">
                      {getPaymentMethodLabel(row.paymentMethod)}
                    </td>
                    <td className="px-3 py-2 text-sm">
                      <div>{customerPrimary}</div>
                      {customerSecondary && (
                        <div className="text-xs text-gray-500">{customerSecondary}</div>
                      )}
                    </td>
                    <td className="px-3 py-2 text-sm">
                      {badges.length === 0 ? (
                        <span className="text-gray-400">—</span>
                      ) : (
                        <div className="flex flex-wrap gap-1">
                          {badges.map((badge) => (
                            <span
                              key={badge}
                              className="rounded-full bg-blue-100 px-2 py-1 text-xs font-medium text-blue-700"
                            >
                              {badge}
                            </span>
                          ))}
                        </div>
                      )}
                    </td>
                    <td className="px-3 py-2 text-sm font-mono">{row.workerCode ?? '—'}</td>
                  </tr>
                )
              })}
          </tbody>
        </table>
      </div>

      <div className="flex flex-wrap items-center justify-between gap-3 text-sm text-gray-700">
        <div>Összesen: {formatInteger(totalElements)} tranzakció</div>
        <div className="flex items-center gap-2">
          <button
            type="button"
            data-testid="prev-page"
            className="form-button"
            onClick={() => goToPage(page - 1)}
            disabled={page === 0 || loading}
          >
            Előző
          </button>
          <span>
            {page + 1} / {Math.max(totalPages, 1)}
          </span>
          <button
            type="button"
            data-testid="next-page"
            className="form-button"
            onClick={() => goToPage(page + 1)}
            disabled={page >= totalPages - 1 || loading}
          >
            Következő
          </button>
        </div>
      </div>
    </div>
  )
}
