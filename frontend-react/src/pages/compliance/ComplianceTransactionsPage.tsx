import { Fragment, type FormEvent, useCallback, useEffect, useState } from 'react'
import { Download, RefreshCw, Search } from 'lucide-react'
import {
  complianceSearchAuditApi,
  complianceSearchTemplatesApi,
  complianceTransactionsApi,
  PAYMENT_METHOD_LABELS,
  TRANSACTION_TYPE_LABELS,
  type CompliancePaymentMethod,
  type ComplianceSearchAuditDto,
  type ComplianceSearchTemplateDto,
  type ComplianceTransactionRowDto,
  type ComplianceTransactionSearchCriteria,
  type ComplianceTransactionType,
} from '../../services/api/complianceTransactions'
import { branchApi, type BranchInfo } from '../../services/api/settings'
import { currencyApi, type Currency } from '../../services/api/exchange-rates'
import { toast } from '../../components/ui/toaster'
import { getBlobErrorMessage, getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import { formatDecimal, formatInteger } from '../../utils/numberFormat'
import { downloadBlob } from '../../utils/downloadBlob'
import i18n from '../../i18n'

const PAGE_SIZE = 50
const AUDIT_TITLE_MAX_LENGTH = 200
const AUDIT_DESCRIPTION_MAX_LENGTH = 2000

const CRITERIA_LABELS: Record<keyof ComplianceTransactionSearchCriteria, string> = {
  branchId: 'Iroda',
  startDate: 'Kezdő dátum',
  endDate: 'Záró dátum',
  type: 'Típus',
  minHufAmount: 'Min. HUF',
  maxHufAmount: 'Max. HUF',
  currencyIds: 'Valuták',
  paymentMethod: 'Fizetési mód',
  customRateOnly: 'Csak egyedi árfolyam',
  kkDiscountOnly: 'Csak KK-kedvezmény',
  onBehalfOfOtherOnly: 'Csak más nevében',
  pepOnly: 'Csak PEP',
  customerName: 'Ügyfél neve',
  customerBirthDate: 'Születési dátum',
  customerNationality: 'Állampolgárság',
  customerDocumentNumber: 'Okmányszám',
  legalEntityOnly: 'Csak jogi személy',
  legalEntityName: 'Jogi személy neve',
  legalEntityTaxNumber: 'Adószám',
  legalDeedNumber: 'Okirat száma',
  legalEntitySeat: 'Székhely',
  beneficialOwnerName: 'Tényleges tulajdonos neve',
  customerCountry: 'Ügyfél országa',
  customerBirthName: 'Születési név',
  relatedMinCount: 'Min. összefüggő tranzakció (db)',
}

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
  beneficialOwnerName: string
  customerCountry: string
  customerBirthName: string
  relatedMinCount: string
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
  beneficialOwnerName: '',
  customerCountry: '',
  customerBirthName: '',
  relatedMinCount: '',
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
  if (form.beneficialOwnerName.trim())
    criteria.beneficialOwnerName = form.beneficialOwnerName.trim()
  if (form.customerCountry.trim()) criteria.customerCountry = form.customerCountry.trim()
  if (form.customerBirthName.trim()) criteria.customerBirthName = form.customerBirthName.trim()
  if (form.relatedMinCount.trim()) {
    const n = Number(form.relatedMinCount.trim())
    if (Number.isInteger(n) && n > 0) criteria.relatedMinCount = n
  }
  return criteria
}

function criteriaString(
  criteria: ComplianceTransactionSearchCriteria & Record<string, unknown>,
  key: keyof ComplianceTransactionSearchCriteria,
): string {
  const value = criteria[key]
  return value == null ? '' : String(value)
}

function criteriaToForm(
  criteria: ComplianceTransactionSearchCriteria & Record<string, unknown>,
): FilterFormState {
  return {
    ...EMPTY_FILTERS,
    branchId: criteriaString(criteria, 'branchId'),
    startDate: criteriaString(criteria, 'startDate'),
    endDate: criteriaString(criteria, 'endDate'),
    type: (criteriaString(criteria, 'type') as FilterFormState['type']) || '',
    minHufAmount: criteriaString(criteria, 'minHufAmount'),
    maxHufAmount: criteriaString(criteria, 'maxHufAmount'),
    currencyIds: Array.isArray(criteria.currencyIds)
      ? criteria.currencyIds.map(Number).filter(Number.isFinite)
      : [],
    paymentMethod:
      (criteriaString(criteria, 'paymentMethod') as FilterFormState['paymentMethod']) || '',
    customRateOnly: criteria.customRateOnly === true,
    kkDiscountOnly: criteria.kkDiscountOnly === true,
    onBehalfOfOtherOnly: criteria.onBehalfOfOtherOnly === true,
    pepOnly: criteria.pepOnly === true,
    customerName: criteriaString(criteria, 'customerName'),
    customerBirthDate: criteriaString(criteria, 'customerBirthDate'),
    customerNationality: criteriaString(criteria, 'customerNationality'),
    customerDocumentNumber: criteriaString(criteria, 'customerDocumentNumber'),
    legalEntityOnly: criteria.legalEntityOnly === true,
    legalEntityName: criteriaString(criteria, 'legalEntityName'),
    legalEntityTaxNumber: criteriaString(criteria, 'legalEntityTaxNumber'),
    legalDeedNumber: criteriaString(criteria, 'legalDeedNumber'),
    legalEntitySeat: criteriaString(criteria, 'legalEntitySeat'),
    beneficialOwnerName: criteriaString(criteria, 'beneficialOwnerName'),
    customerCountry: criteriaString(criteria, 'customerCountry'),
    customerBirthName: criteriaString(criteria, 'customerBirthName'),
    relatedMinCount: criteriaString(criteria, 'relatedMinCount'),
  }
}

function logAndToastError(title: string, action: string, err: unknown): void {
  const message = getErrorMessage(err)
  logger.error('ComplianceTransactionsPage', action, message)
  toast.error(title, message)
}

async function logAndToastBlobError(title: string, action: string, err: unknown): Promise<void> {
  const message = await getBlobErrorMessage(err)
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

function formatDateTime(value: string): string {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString('hu-HU')
}

function isCriteriaValueSet(value: unknown): boolean {
  if (value == null || value === '' || value === false) return false
  if (Array.isArray(value)) return value.length > 0
  return true
}

function getCriteriaDisplayValue(
  key: keyof ComplianceTransactionSearchCriteria,
  value: unknown,
  branches: BranchInfo[],
  currencies: Currency[],
): string {
  if (typeof value === 'boolean') return value ? 'igen' : 'nem'
  if (Array.isArray(value)) {
    if (key === 'currencyIds') {
      return value
        .map((currencyId) => {
          const currency = currencies.find((item) => String(item.id) === String(currencyId))
          return currency?.code ?? String(currencyId)
        })
        .join(', ')
    }
    return value.map(String).join(', ')
  }
  if (key === 'branchId') {
    const branch = branches.find((item) => String(item.id) === String(value))
    return branch ? buildBranchLabel(branch) : String(value)
  }
  if (key === 'type' && typeof value === 'string') return getTransactionLabel(value)
  if (key === 'paymentMethod' && typeof value === 'string') return getPaymentMethodLabel(value)
  return String(value)
}

function getCriteriaDisplayEntries(
  criteria: ComplianceTransactionSearchCriteria & Record<string, unknown>,
  branches: BranchInfo[],
  currencies: Currency[],
): { key: string; label: string; value: string }[] {
  return (Object.keys(CRITERIA_LABELS) as Array<keyof ComplianceTransactionSearchCriteria>)
    .map((key) => ({ key, rawValue: criteria[key] }))
    .filter(({ rawValue }) => isCriteriaValueSet(rawValue))
    .map(({ key, rawValue }) => ({
      key,
      label: CRITERIA_LABELS[key],
      value: getCriteriaDisplayValue(key, rawValue, branches, currencies),
    }))
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
  const [templates, setTemplates] = useState<ComplianceSearchTemplateDto[]>([])
  const [selectedTemplateId, setSelectedTemplateId] = useState('')
  const [showTemplateModal, setShowTemplateModal] = useState(false)
  const [templateName, setTemplateName] = useState('')
  const [templateSaving, setTemplateSaving] = useState(false)
  const [templateDeleting, setTemplateDeleting] = useState(false)
  const [showAuditModal, setShowAuditModal] = useState(false)
  const [auditTitle, setAuditTitle] = useState('')
  const [auditDescription, setAuditDescription] = useState('')
  const [auditSaving, setAuditSaving] = useState(false)
  const [showAuditList, setShowAuditList] = useState(false)
  const [auditListLoaded, setAuditListLoaded] = useState(false)
  const [auditList, setAuditList] = useState<ComplianceSearchAuditDto[]>([])
  const [auditListLoading, setAuditListLoading] = useState(false)
  const [expandedAuditIds, setExpandedAuditIds] = useState<Set<string>>(() => new Set())
  const [pdfDownloadingId, setPdfDownloadingId] = useState<string | null>(null)

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

  const loadTemplates = useCallback(async () => {
    try {
      const templateList = await complianceSearchTemplatesApi.list()
      setTemplates(safeArray<ComplianceSearchTemplateDto>(templateList))
    } catch (err) {
      logAndToastError('Sablon betöltési hiba', 'Sablonok betöltése sikertelen:', err)
      setTemplates([])
    }
  }, [])

  const loadAuditList = useCallback(async () => {
    setAuditListLoading(true)
    try {
      const audits = await complianceSearchAuditApi.list()
      setAuditList(safeArray<ComplianceSearchAuditDto>(audits))
      setAuditListLoaded(true)
    } catch (err) {
      logAndToastError('Audit napló hiba', 'Audit napló betöltése sikertelen:', err)
      setAuditList([])
      setAuditListLoaded(false)
    } finally {
      setAuditListLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadMasterData()
    void loadTemplates()
  }, [loadMasterData, loadTemplates])

  const runSearch = useCallback(
    async (criteria: ComplianceTransactionSearchCriteria, targetPage: number) => {
      setLoading(true)
      try {
        const result = await complianceTransactionsApi.search(criteria, targetPage, PAGE_SIZE)
        setRows(safeArray<ComplianceTransactionRowDto>(result.content))
        setTotalPages(result.totalPages ?? 0)
        setTotalElements(result.totalElements ?? 0)
        setPage(targetPage)
        setActiveCriteria(criteria)
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
      await logAndToastBlobError('Export sikertelen', 'Export sikertelen:', err)
    } finally {
      setExporting(null)
    }
  }

  const handleTemplateChange = (templateId: string) => {
    setSelectedTemplateId(templateId)
    const template = templates.find((item) => item.id === templateId)
    if (template) setForm(criteriaToForm(template.criteria))
  }

  const handleSaveTemplate = async () => {
    if (!activeCriteria || templateSaving) return
    setTemplateSaving(true)
    try {
      const template = await complianceSearchTemplatesApi.create(templateName, activeCriteria)
      toast.success('Sablon mentve')
      setTemplateName('')
      setShowTemplateModal(false)
      await loadTemplates()
      setSelectedTemplateId(template.id)
    } catch (err) {
      logAndToastError('Sablon mentési hiba', 'Sablon mentése sikertelen:', err)
    } finally {
      setTemplateSaving(false)
    }
  }

  const handleDeleteTemplate = async () => {
    if (!selectedTemplateId || templateDeleting) return
    setTemplateDeleting(true)
    try {
      await complianceSearchTemplatesApi.remove(selectedTemplateId)
      toast.success('Sablon törölve')
      setSelectedTemplateId('')
      await loadTemplates()
    } catch (err) {
      logAndToastError('Sablon törlési hiba', 'Sablon törlése sikertelen:', err)
    } finally {
      setTemplateDeleting(false)
    }
  }

  const handleSaveAudit = async () => {
    if (!activeCriteria || auditSaving || !auditTitle.trim()) return
    setAuditSaving(true)
    try {
      await complianceSearchAuditApi.create(auditTitle, auditDescription, activeCriteria)
      toast.success('Keresés mentve az audit naplóba')
      setAuditTitle('')
      setAuditDescription('')
      setShowAuditModal(false)
      await loadAuditList()
    } catch (err) {
      logAndToastError('Audit mentési hiba', 'Audit mentése sikertelen:', err)
    } finally {
      setAuditSaving(false)
    }
  }

  const handleToggleAuditList = () => {
    const nextShow = !showAuditList
    setShowAuditList(nextShow)
    if (nextShow && !auditListLoaded) void loadAuditList()
  }

  const toggleAuditCriteria = (id: string) => {
    setExpandedAuditIds((current) => {
      const next = new Set(current)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  const handleAuditPdf = async (auditId: string) => {
    if (pdfDownloadingId) return
    setPdfDownloadingId(auditId)
    try {
      const data = await complianceSearchAuditApi.downloadPdf(auditId)
      downloadBlob(data, `compliance_kereses_audit_${auditId}.pdf`, 'application/pdf')
    } catch (err) {
      await logAndToastBlobError('Audit PDF hiba', 'Audit PDF letöltése sikertelen:', err)
    } finally {
      setPdfDownloadingId(null)
    }
  }

  const exportDisabled = !activeCriteria || loading || exporting !== null
  const templateActionDisabled = !activeCriteria || loading
  const auditSaveDisabled = !activeCriteria || loading

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between gap-4">
        <h1 className="form-title flex items-center gap-2">
          <Search className="h-6 w-6" />
          {i18n.t('literals.compliance-tranzakciok')}
        </h1>
        <button
          type="button"
          onClick={() => void loadMasterData()}
          className="form-button flex items-center gap-2"
          disabled={masterLoading}
        >
          <RefreshCw className={`h-4 w-4 ${masterLoading ? 'animate-spin' : ''}`} />
          {i18n.t('literals.torzsadat-frissites')}
        </button>
      </div>

      <div className="rounded-md border border-blue-200 bg-blue-50 p-3 text-sm text-blue-900">
        {i18n.t('literals.a-lista-cegszintu-compliance-keresest-ve')}
      </div>

      <form
        className="grid grid-cols-12 gap-3 rounded-md border border-gray-200 p-4"
        onSubmit={handleSearch}
      >
        <div className="col-span-12 rounded border border-blue-100 bg-blue-50 p-3">
          <div className="grid grid-cols-12 gap-3">
            <div className="col-span-12 md:col-span-6">
              <label className="form-label" htmlFor="template-select">
                {i18n.t('literals.mentett-szuro-sablon')}
              </label>
              <select
                id="template-select"
                data-testid="template-select"
                className="form-input"
                value={selectedTemplateId}
                onChange={(event) => handleTemplateChange(event.target.value)}
              >
                <option value="">{i18n.t('literals.valasszon-sablont')}</option>
                {templates.map((template) => (
                  <option key={template.id} value={template.id}>
                    {template.name}
                  </option>
                ))}
              </select>
            </div>
            <div className="col-span-12 flex flex-wrap items-end gap-2 md:col-span-6">
              <button
                type="button"
                className="form-button"
                onClick={() => setShowTemplateModal(true)}
                disabled={templateActionDisabled}
              >
                {i18n.t('literals.sablon-mentese')}
              </button>
              <button
                type="button"
                data-testid="delete-template"
                className="form-button"
                onClick={() => void handleDeleteTemplate()}
                disabled={!selectedTemplateId || templateDeleting}
              >
                {templateDeleting ? 'Törlés...' : 'Sablon törlése'}
              </button>
              <span className="text-xs text-blue-800">
                {i18n.t('literals.betolteskor-csak-az-urlap-toltodik-keres')}
              </span>
            </div>
          </div>
        </div>

        <fieldset className="col-span-12 grid grid-cols-12 gap-3 rounded border border-gray-100 p-3">
          <legend className="px-1 text-sm font-semibold text-gray-700">
            {i18n.t('literals.tranzakcio')}
          </legend>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-branchId">
              {i18n.t('literals.iroda')}
            </label>
            <select
              id="filter-branchId"
              data-testid="filter-branchId"
              className="form-input"
              value={form.branchId}
              onChange={(event) => updateField('branchId', event.target.value)}
            >
              <option value="">{i18n.t('literals.osszes-iroda')}</option>
              {branches.map((branch) => (
                <option key={branch.id} value={branch.id}>
                  {buildBranchLabel(branch)}
                </option>
              ))}
            </select>
          </div>
          <div className="col-span-12 md:col-span-2">
            <label className="form-label" htmlFor="filter-startDate">
              {i18n.t('literals.kezdo-datum')}
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
              {i18n.t('literals.zaro-datum')}
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
              {i18n.t('literals.tipus')}
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
              <option value="">{i18n.t('literals.osszes-tipus')}</option>
              {Object.entries(TRANSACTION_TYPE_LABELS).map(([type, label]) => (
                <option key={type} value={type}>
                  {label}
                </option>
              ))}
            </select>
          </div>
          <div className="col-span-12 md:col-span-2">
            <label className="form-label" htmlFor="filter-paymentMethod">
              {i18n.t('literals.fizetesi-mod')}
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
              <option value="">{i18n.t('literals.osszes-mod')}</option>
              {Object.entries(PAYMENT_METHOD_LABELS).map(([method, label]) => (
                <option key={method} value={method}>
                  {label}
                </option>
              ))}
            </select>
          </div>
        </fieldset>

        <fieldset className="col-span-12 grid grid-cols-12 gap-3 rounded border border-gray-100 p-3">
          <legend className="px-1 text-sm font-semibold text-gray-700">
            {i18n.t('literals.osszeg-es-valuta')}
          </legend>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-minHufAmount">
              {i18n.t('literals.min-huf')}
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
              {i18n.t('literals.max-huf')}
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
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-relatedMinCount">
              {i18n.t('literals.min-osszefuggo-tranzakcio-db')}
            </label>
            <input
              id="filter-relatedMinCount"
              data-testid="filter-relatedMinCount"
              type="number"
              min="1"
              step="1"
              title="Ügyfelek, akik az időszakban legalább ennyi tranzakciót bonyolítottak"
              className="form-input"
              value={form.relatedMinCount}
              onChange={(event) => updateField('relatedMinCount', event.target.value)}
            />
          </div>
          <div className="col-span-12 md:col-span-6">
            <label className="form-label" htmlFor="filter-currencyIds">
              {i18n.t('literals.valutak-fo-vagy-tetelsor')}
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
          <legend className="px-1 text-sm font-semibold text-gray-700">
            {i18n.t('literals.ugyfel-2')}
          </legend>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-customerName">
              {i18n.t('literals.ugyfel-neve')}
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
              {i18n.t('literals.szuletesi-datum')}
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
              {i18n.t('literals.allampolgarsag')}
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
            <label className="form-label" htmlFor="filter-customerCountry">
              {i18n.t('literals.ugyfel-orszaga')}
            </label>
            <input
              id="filter-customerCountry"
              data-testid="filter-customerCountry"
              className="form-input"
              value={form.customerCountry}
              onChange={(event) => updateField('customerCountry', event.target.value)}
            />
          </div>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-customerBirthName">
              {i18n.t('literals.szuletesi-nev')}
            </label>
            <input
              id="filter-customerBirthName"
              data-testid="filter-customerBirthName"
              className="form-input"
              value={form.customerBirthName}
              onChange={(event) => updateField('customerBirthName', event.target.value)}
            />
          </div>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-customerDocumentNumber">
              {i18n.t('literals.okmanyszam')}
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
          <legend className="px-1 text-sm font-semibold text-gray-700">
            {i18n.t('literals.jogi-szemely')}
          </legend>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-legalEntityName">
              {i18n.t('literals.jogi-szemely-neve')}
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
              {i18n.t('literals.adoszam')}
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
              {i18n.t('literals.okirat-szama')}
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
              {i18n.t('literals.szekhely')}
            </label>
            <input
              id="filter-legalEntitySeat"
              data-testid="filter-legalEntitySeat"
              className="form-input"
              value={form.legalEntitySeat}
              onChange={(event) => updateField('legalEntitySeat', event.target.value)}
            />
          </div>
          <div className="col-span-12 md:col-span-3">
            <label className="form-label" htmlFor="filter-beneficialOwnerName">
              {i18n.t('literals.tenyleges-tulajdonos-neve')}
            </label>
            <input
              id="filter-beneficialOwnerName"
              data-testid="filter-beneficialOwnerName"
              className="form-input"
              value={form.beneficialOwnerName}
              onChange={(event) => updateField('beneficialOwnerName', event.target.value)}
            />
          </div>
        </fieldset>

        <fieldset className="col-span-12 rounded border border-gray-100 p-3">
          <legend className="px-1 text-sm font-semibold text-gray-700">
            {i18n.t('literals.jelolok')}
          </legend>
          <div className="grid grid-cols-12 gap-3">
            <label className="col-span-12 flex items-center gap-2 text-sm md:col-span-3">
              <input
                data-testid="filter-customRateOnly"
                type="checkbox"
                checked={form.customRateOnly}
                onChange={(event) => updateField('customRateOnly', event.target.checked)}
              />
              {i18n.t('literals.csak-egyedi-arfolyam')}
            </label>
            <label className="col-span-12 flex items-center gap-2 text-sm md:col-span-3">
              <input
                data-testid="filter-kkDiscountOnly"
                type="checkbox"
                checked={form.kkDiscountOnly}
                onChange={(event) => updateField('kkDiscountOnly', event.target.checked)}
              />
              {i18n.t('literals.csak-kk-kedvezmeny')}
            </label>
            <label className="col-span-12 flex items-center gap-2 text-sm md:col-span-3">
              <input
                data-testid="filter-onBehalfOfOtherOnly"
                type="checkbox"
                checked={form.onBehalfOfOtherOnly}
                onChange={(event) => updateField('onBehalfOfOtherOnly', event.target.checked)}
              />
              {i18n.t('literals.csak-mas-neveben')}
            </label>
            <label className="col-span-12 flex items-center gap-2 text-sm md:col-span-3">
              <input
                data-testid="filter-pepOnly"
                type="checkbox"
                checked={form.pepOnly}
                onChange={(event) => updateField('pepOnly', event.target.checked)}
              />
              {i18n.t('literals.csak-pep')}
            </label>
            <label className="col-span-12 flex items-center gap-2 text-sm md:col-span-3">
              <input
                data-testid="filter-legalEntityOnly"
                type="checkbox"
                checked={form.legalEntityOnly}
                onChange={(event) => updateField('legalEntityOnly', event.target.checked)}
              />
              {i18n.t('literals.csak-jogi-szemely')}
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
            {i18n.t('literals.szurok-torlese')}
          </button>
          <button
            type="button"
            data-testid="export-csv"
            className="form-button flex items-center gap-2"
            onClick={() => void handleExport('csv')}
            disabled={exportDisabled}
          >
            <Download className="h-4 w-4" />
            {i18n.t('literals.csv-export-2')}
          </button>
          <button
            type="button"
            data-testid="export-xlsx"
            className="form-button flex items-center gap-2"
            onClick={() => void handleExport('xlsx')}
            disabled={exportDisabled}
          >
            <Download className="h-4 w-4" />
            {i18n.t('literals.xlsx-export')}
          </button>
          <button
            type="button"
            data-testid="save-audit"
            className="form-button"
            title="A legutóbb futtatott keresést menti."
            onClick={() => setShowAuditModal(true)}
            disabled={auditSaveDisabled}
          >
            {i18n.t('literals.mentes-az-audit-naploba')}
          </button>
        </div>
      </form>

      <div className="data-grid overflow-x-auto" data-testid="results-table">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.datum-2')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.bizonylat')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.tipus')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.iroda')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.valuta')}
              </th>
              <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.osszeg')}
              </th>
              <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.arfolyam')}
              </th>
              <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.huf')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.fizetes')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.ugyfel-2')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.jelolok')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.dolgozo-2')}
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {loading && (
              <tr>
                <td colSpan={12} className="px-3 py-4 text-center text-gray-400">
                  {i18n.t('literals.kereses-folyamatban')}
                </td>
              </tr>
            )}
            {!loading && activeCriteria === null && (
              <tr>
                <td colSpan={12} className="px-3 py-4 text-center text-gray-400">
                  {i18n.t('literals.allitsa-be-a-szuroket-majd-inditsa-a-ker')}
                </td>
              </tr>
            )}
            {!loading && activeCriteria !== null && rows.length === 0 && (
              <tr>
                <td colSpan={12} className="px-3 py-4 text-center text-gray-400">
                  {i18n.t('literals.nincs-a-szuroknek-megfelelo-tranzakcio')}
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
                          {i18n.t('literals.eredeti')}
                          {row.originalReceiptNumber}
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
                        <span className="text-gray-400">{i18n.t('literals.lit-8')}</span>
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
        <div>
          {i18n.t('literals.osszesen-2')}
          {formatInteger(totalElements)}
          {i18n.t('literals.tranzakcio-2')}
        </div>
        <div className="flex items-center gap-2">
          <button
            type="button"
            data-testid="prev-page"
            className="form-button"
            onClick={() => goToPage(page - 1)}
            disabled={page === 0 || loading}
          >
            {i18n.t('literals.elozo-2')}
          </button>
          <span>
            {page + 1}
            {i18n.t('literals.lit-10')}
            {Math.max(totalPages, 1)}
          </span>
          <button
            type="button"
            data-testid="next-page"
            className="form-button"
            onClick={() => goToPage(page + 1)}
            disabled={page >= totalPages - 1 || loading}
          >
            {i18n.t('literals.kovetkezo-2')}
          </button>
        </div>
      </div>

      <section className="rounded-md border border-gray-200">
        <button
          type="button"
          data-testid="toggle-audit-list"
          className="flex w-full items-center justify-between px-4 py-3 text-left font-semibold text-gray-800"
          onClick={handleToggleAuditList}
        >
          <span>{i18n.t('literals.kereses-audit-naplo')}</span>
          <span>{showAuditList ? 'Bezárás' : 'Megnyitás'}</span>
        </button>
        {showAuditList && (
          <div className="border-t border-gray-200 p-4">
            {auditListLoading ? (
              <div className="py-4 text-center text-sm text-gray-500">
                {i18n.t('literals.audit-naplo-betoltese')}
              </div>
            ) : auditList.length === 0 ? (
              <div className="py-4 text-center text-sm text-gray-500">
                {i18n.t('literals.nincs-mentett-audit-bejegyzes')}
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                        {i18n.t('literals.idopont')}
                      </th>
                      <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                        {i18n.t('literals.cim')}
                      </th>
                      <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                        {i18n.t('literals.leiras')}
                      </th>
                      <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                        {i18n.t('literals.talalat')}
                      </th>
                      <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                        {i18n.t('literals.rogzito')}
                      </th>
                      <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                        {i18n.t('literals.muveletek')}
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {auditList.map((audit) => {
                      const expanded = expandedAuditIds.has(audit.id)
                      const criteriaEntries = getCriteriaDisplayEntries(
                        audit.criteria,
                        branches,
                        currencies,
                      )
                      return (
                        <Fragment key={audit.id}>
                          <tr>
                            <td className="px-3 py-2 text-sm">{formatDateTime(audit.createdAt)}</td>
                            <td className="px-3 py-2 text-sm font-medium">{audit.title}</td>
                            <td className="px-3 py-2 text-sm">{audit.description ?? '—'}</td>
                            <td className="px-3 py-2 text-right text-sm">
                              {audit.resultCount == null ? '—' : formatInteger(audit.resultCount)}
                            </td>
                            <td className="px-3 py-2 text-sm font-mono">
                              {audit.createdByWorkerCode ?? '—'}
                            </td>
                            <td className="px-3 py-2 text-sm">
                              <div className="flex flex-wrap gap-2">
                                <button
                                  type="button"
                                  data-testid={`audit-criteria-${audit.id}`}
                                  className="form-button"
                                  onClick={() => toggleAuditCriteria(audit.id)}
                                >
                                  {i18n.t('literals.szurok')}
                                </button>
                                <button
                                  type="button"
                                  data-testid={`audit-pdf-${audit.id}`}
                                  className="form-button flex items-center gap-1"
                                  onClick={() => void handleAuditPdf(audit.id)}
                                  disabled={pdfDownloadingId !== null}
                                >
                                  <Download className="h-4 w-4" />
                                  {i18n.t('literals.pdf-2')}
                                </button>
                              </div>
                            </td>
                          </tr>
                          {expanded && (
                            <tr>
                              <td colSpan={6} className="bg-gray-50 px-3 py-3 text-sm">
                                {criteriaEntries.length === 0 ? (
                                  <span className="text-gray-500">
                                    {i18n.t('literals.nincs-rogzitett-szuro')}
                                  </span>
                                ) : (
                                  <dl className="grid grid-cols-1 gap-2 md:grid-cols-2">
                                    {criteriaEntries.map((entry) => (
                                      <div key={entry.key}>
                                        <dt className="font-semibold text-gray-600">
                                          {entry.label}
                                        </dt>
                                        <dd>{entry.value}</dd>
                                      </div>
                                    ))}
                                  </dl>
                                )}
                              </td>
                            </tr>
                          )}
                        </Fragment>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}
      </section>

      {showTemplateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-md bg-white p-5 shadow-lg">
            <h2 className="mb-3 text-lg font-semibold">
              {i18n.t('literals.szuro-sablon-mentese')}
            </h2>
            <label className="form-label" htmlFor="save-template">
              {i18n.t('literals.sablon-neve')}
            </label>
            <input
              id="save-template"
              data-testid="save-template"
              className="form-input"
              value={templateName}
              onChange={(event) => setTemplateName(event.target.value)}
              maxLength={200}
              autoFocus
            />
            <div className="mt-4 flex justify-end gap-2">
              <button
                type="button"
                className="form-button"
                onClick={() => {
                  setTemplateName('')
                  setShowTemplateModal(false)
                }}
                disabled={templateSaving}
              >
                {i18n.t('literals.megse')}
              </button>
              <button
                type="button"
                data-testid="confirm-save-template"
                className="form-button-primary"
                onClick={() => void handleSaveTemplate()}
                disabled={!templateName.trim() || templateSaving}
              >
                {templateSaving ? 'Mentés...' : 'Mentés'}
              </button>
            </div>
          </div>
        </div>
      )}

      {showAuditModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-lg rounded-md bg-white p-5 shadow-lg">
            <h2 className="mb-3 text-lg font-semibold">
              {i18n.t('literals.kereses-mentese-az-audit-naploba')}
            </h2>
            <label className="form-label" htmlFor="audit-title">
              {i18n.t('literals.cim')}
            </label>
            <input
              id="audit-title"
              data-testid="audit-title"
              className="form-input"
              value={auditTitle}
              onChange={(event) => setAuditTitle(event.target.value)}
              maxLength={AUDIT_TITLE_MAX_LENGTH}
              required
              autoFocus
            />
            <label className="form-label mt-3" htmlFor="audit-description">
              {i18n.t('literals.leiras')}
            </label>
            <textarea
              id="audit-description"
              data-testid="audit-description"
              className="form-input min-h-28"
              value={auditDescription}
              onChange={(event) => setAuditDescription(event.target.value)}
              maxLength={AUDIT_DESCRIPTION_MAX_LENGTH}
            />
            <p className="mt-2 text-xs text-gray-500">
              {i18n.t('literals.a-legutobb-futtatott-keresest-menti')}
            </p>
            <div className="mt-4 flex justify-end gap-2">
              <button
                type="button"
                className="form-button"
                onClick={() => {
                  setAuditTitle('')
                  setAuditDescription('')
                  setShowAuditModal(false)
                }}
                disabled={auditSaving}
              >
                {i18n.t('literals.megse')}
              </button>
              <button
                type="button"
                className="form-button-primary"
                onClick={() => void handleSaveAudit()}
                disabled={!auditTitle.trim() || auditSaving}
              >
                {auditSaving ? 'Mentés...' : 'Mentés'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
