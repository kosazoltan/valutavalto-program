import { useState, useRef, useCallback, useEffect } from 'react'
import { User, Search, CheckCircle, Loader2, AlertTriangle, X, Shield, ShieldCheck, ShieldAlert } from 'lucide-react'
import type { IdentificationLevel } from '../hooks/useIdentificationLevel'
import { customerApi, amlApi } from '../../../services/api/index'
import type { Customer as ApiCustomer, CustomerCreateRequest, AmlCheckResultDto } from '../../../services/api/transactions'
import { logger } from '../../../utils/logger'
import { useTranslation } from 'react-i18next'

export interface CustomerPanelData {
  id?: number
  name: string
  documentType: string
  documentNumber: string
  nationality: string
  birthPlace?: string
  birthDate?: string
  birthName?: string
  motherName?: string
  address?: string
  residence?: string
  addressCardNumber?: string
  amlVerified?: boolean
}

interface CustomerPanelProps {
  identificationLevel: IdentificationLevel
  minimumLevel: IdentificationLevel
  onLevelChange: (level: IdentificationLevel) => void
  requiresSourceVerification: boolean
  hufTotal: number
  onCustomerReady: (data: CustomerPanelData | null) => void
  onAmlResult?: (result: AmlCheckResultDto | null) => void
}

const LEVEL_ORDER: IdentificationLevel[] = ['SIMPLE', 'SIMPLIFIED', 'FULL']

const LEVEL_LABELS: Record<IdentificationLevel, string> = {
  SIMPLE: 'Nem azonosit',
  SIMPLIFIED: 'Egyszerusitett',
  FULL: 'Teljes azonositas',
}

const LEVEL_DESCRIPTIONS: Record<IdentificationLevel, string> = {
  SIMPLE: 'Csak allampolgarsag',
  SIMPLIFIED: 'Nev, szuletesi adatok, okmany',
  FULL: 'Teljes szemelyes adatok',
}

export default function CustomerPanel({
  identificationLevel,
  minimumLevel,
  onLevelChange,
  requiresSourceVerification,
  hufTotal,
  onCustomerReady,
  onAmlResult,
}: CustomerPanelProps) {
  const { t } = useTranslation()
  const [searchQuery, setSearchQuery] = useState('')
  const [searchResults, setSearchResults] = useState<ApiCustomer[]>([])
  const [isSearching, setIsSearching] = useState(false)
  const [showResults, setShowResults] = useState(false)
  const searchTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const [selectedCustomer, setSelectedCustomer] = useState<ApiCustomer | null>(null)

  // Form fields
  const [customerName, setCustomerName] = useState('')
  const [customerDocType, setCustomerDocType] = useState('ID_CARD')
  const [customerDocNumber, setCustomerDocNumber] = useState('')
  const [customerNationality, setCustomerNationality] = useState('Magyar')
  const [customerBirthPlace, setCustomerBirthPlace] = useState('')
  const [customerBirthDate, setCustomerBirthDate] = useState('')
  const [customerBirthName, setCustomerBirthName] = useState('')
  const [customerMotherName, setCustomerMotherName] = useState('')
  const [customerAddress, setCustomerAddress] = useState('')
  const [customerResidence, setCustomerResidence] = useState('')
  const [customerAddressCardNumber, setCustomerAddressCardNumber] = useState('')

  const [amlResult, setAmlResult] = useState<AmlCheckResultDto | null>(null)
  const [amlChecking, setAmlChecking] = useState(false)
  const [isSaving, setIsSaving] = useState(false)

  // Debounced search
  const handleSearchInput = useCallback((value: string) => {
    setSearchQuery(value)
    if (searchTimeoutRef.current) clearTimeout(searchTimeoutRef.current)
    if (value.trim().length < 2) {
      setSearchResults([])
      setShowResults(false)
      return
    }
    searchTimeoutRef.current = setTimeout(async () => {
      setIsSearching(true)
      try {
        const results = await customerApi.search(value.trim())
        setSearchResults(results.slice(0, 10))
        setShowResults(true)
      } catch (err) {
        logger.warn('CustomerPanel', 'Customer search failed, continuing with manual entry', err)
        setSearchResults([])
      } finally {
        setIsSearching(false)
      }
    }, 400)
  }, [])

  const runAmlCheck = useCallback(async (customerId: number, data: CustomerPanelData) => {
    if (!customerId || hufTotal <= 0) return data
    setAmlChecking(true)
    try {
      const result = await amlApi.checkAllThresholds(String(customerId), hufTotal)
      setAmlResult(result)
      onAmlResult?.(result)
      return { ...data, amlVerified: true }
    } catch (err) {
      logger.warn('CustomerPanel', 'AML check failed — fail-closed', err)
      const blockedResult: AmlCheckResultDto = {
        transactionType: 0, weeklyTotal: 0, yearlyMax: 0, quarterlyCount: 0, quarterlyTotal: 0,
        requiresId: true, requiresEnhanced: false, blocked: true,
        warnings: ['AML ellenorzes nem sikerult — tranzakcio blokkolt biztonsagi okbol'],
      }
      setAmlResult(blockedResult)
      onAmlResult?.(blockedResult)
      return data
    } finally {
      setAmlChecking(false)
    }
  }, [hufTotal, onAmlResult])

  const handleSelectCustomer = useCallback(async (customer: ApiCustomer) => {
    setSelectedCustomer(customer)
    setShowResults(false)
    setSearchQuery('')

    let data: CustomerPanelData = {
      id: customer.id,
      name: customer.name,
      documentType: customer.documentType ?? 'ID_CARD',
      documentNumber: customer.documentNumber ?? '',
      nationality: customer.nationality ?? 'Magyar',
      birthPlace: customer.birthPlace,
      birthDate: customer.birthDate,
      birthName: customer.birthName,
      motherName: customer.motherName,
      address: customer.address,
      residence: customer.residence,
      addressCardNumber: customer.addressCardNumber,
      amlVerified: false,
    }

    if (customer.id && hufTotal > 0) {
      data = await runAmlCheck(customer.id, data)
    }
    onCustomerReady(data)
  }, [hufTotal, onCustomerReady, runAmlCheck])

  const handleSaveManualCustomer = useCallback(async () => {
    if (identificationLevel === 'SIMPLIFIED' && (
      !customerName.trim() || !customerDocNumber.trim() ||
      !customerBirthDate || !customerBirthPlace.trim()
    )) return
    if (identificationLevel === 'FULL' && (
      !customerName.trim() || !customerDocNumber.trim() ||
      !customerBirthPlace.trim() || !customerBirthDate ||
      !customerMotherName.trim() || !customerAddress.trim()
    )) return

    setIsSaving(true)
    try {
      const createData: CustomerCreateRequest = {
        name: customerName.trim(),
        documentType: customerDocType,
        documentNumber: customerDocNumber.trim() || undefined,
        nationality: customerNationality,
        birthPlace: customerBirthPlace.trim() || undefined,
        birthDate: customerBirthDate || undefined,
        birthName: customerBirthName.trim() || undefined,
        motherName: customerMotherName.trim() || undefined,
        address: customerAddress.trim() || undefined,
        residence: customerResidence.trim() || undefined,
        addressCardNumber: customerAddressCardNumber.trim() || undefined,
      }

      let savedCustomer: ApiCustomer | null = null
      try {
        savedCustomer = await customerApi.create(createData)
      } catch (err) {
        logger.warn('CustomerPanel', 'Customer create failed, trying doc number lookup', err)
        try {
          if (customerDocNumber.trim()) {
            savedCustomer = await customerApi.getByDocumentNumber(customerDocNumber.trim())
          }
        } catch { /* proceed without ID */ }
      }

      let data: CustomerPanelData = {
        id: savedCustomer?.id,
        name: customerName.trim(),
        documentType: customerDocType,
        documentNumber: customerDocNumber.trim(),
        nationality: customerNationality,
        birthPlace: customerBirthPlace.trim() || undefined,
        birthDate: customerBirthDate || undefined,
        birthName: customerBirthName.trim() || undefined,
        motherName: customerMotherName.trim() || undefined,
        address: customerAddress.trim() || undefined,
        residence: customerResidence.trim() || undefined,
        addressCardNumber: customerAddressCardNumber.trim() || undefined,
        amlVerified: false,
      }
      setSelectedCustomer(savedCustomer)

      if (savedCustomer?.id && hufTotal > 0) {
        data = await runAmlCheck(savedCustomer.id, data)
      } else if (hufTotal >= 100_000) {
        const blockedResult: AmlCheckResultDto = {
          transactionType: 0, weeklyTotal: 0, yearlyMax: 0, quarterlyCount: 0, quarterlyTotal: 0,
          requiresId: true, requiresEnhanced: false, blocked: true,
          warnings: ['Ugyfel mentese nem sikerult — AML ellenorzes nem lehetseges, tranzakcio blokkolt'],
        }
        setAmlResult(blockedResult)
        onAmlResult?.(blockedResult)
      }

      onCustomerReady(data)
    } catch (err) {
      logger.error('CustomerPanel', 'Save customer failed', err)
    } finally {
      setIsSaving(false)
    }
  }, [customerName, customerDocType, customerDocNumber, customerNationality, customerBirthPlace, customerBirthDate, customerBirthName, customerMotherName, customerAddress, customerResidence, customerAddressCardNumber, hufTotal, identificationLevel, onCustomerReady, onAmlResult, runAmlCheck])

  const handleClearCustomer = useCallback(() => {
    setSelectedCustomer(null)
    setCustomerName('')
    setCustomerDocType('ID_CARD')
    setCustomerDocNumber('')
    setCustomerNationality('Magyar')
    setCustomerBirthPlace('')
    setCustomerBirthDate('')
    setCustomerBirthName('')
    setCustomerMotherName('')
    setCustomerAddress('')
    setCustomerResidence('')
    setCustomerAddressCardNumber('')
    setAmlResult(null)
    setSearchQuery('')
    setSearchResults([])
    onCustomerReady(null)
    onAmlResult?.(null)
  }, [onCustomerReady, onAmlResult])

  // SIMPLE mode: auto-propagate nationality (no save button needed under 100K)
  useEffect(() => {
    if (identificationLevel === 'SIMPLE' && !selectedCustomer) {
      onCustomerReady({
        name: '',
        documentType: '',
        documentNumber: '',
        nationality: customerNationality,
      })
    }
  }, [identificationLevel, customerNationality, selectedCustomer, onCustomerReady])

  // Re-run AML when hufTotal changes
  useEffect(() => {
    if (selectedCustomer?.id && hufTotal > 0) {
      const timer = setTimeout(async () => {
        try {
          const result = await amlApi.checkAllThresholds(String(selectedCustomer.id), hufTotal)
          setAmlResult(result)
          onAmlResult?.(result)
        } catch {
          const blockedResult: AmlCheckResultDto = {
            transactionType: 0, weeklyTotal: 0, yearlyMax: 0, quarterlyCount: 0, quarterlyTotal: 0,
            requiresId: true, requiresEnhanced: false, blocked: true,
            warnings: ['AML ujraellenorzes nem sikerult — tranzakcio blokkolt biztonsagi okbol'],
          }
          setAmlResult(blockedResult)
          onAmlResult?.(blockedResult)
        }
      }, 1000)
      return () => clearTimeout(timer)
    }
  }, [hufTotal, selectedCustomer?.id, onAmlResult])

  const showFull = identificationLevel === 'FULL'

  const isFormValid = () => {
    if (identificationLevel === 'SIMPLE') return true
    if (identificationLevel === 'SIMPLIFIED') return !!(customerName.trim() && customerDocNumber.trim() && customerBirthDate && customerBirthPlace.trim())
    // FULL
    return !!(customerName.trim() && customerDocNumber.trim() &&
      customerBirthPlace.trim() && customerBirthDate && customerMotherName.trim() && customerAddress.trim())
  }

  const fieldClass = "w-full h-9 px-2 text-sm rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white focus:ring-2 focus:border-transparent"
  const fieldStyle = { '--tw-ring-color': 'var(--primary)' } as React.CSSProperties

  return (
    <div className="space-y-3">
      <h3 className="text-lg font-bold flex items-center gap-2 text-gray-900 dark:text-white">
        <User className="w-5 h-5" />
        {t('transactions.ugyfelAdatok')}
      </h3>

      {/* Identification level selector */}
      <div className="flex gap-1">
        {LEVEL_ORDER.map((level) => {
          const minIdx = LEVEL_ORDER.indexOf(minimumLevel)
          const levelIdx = LEVEL_ORDER.indexOf(level)
          const disabled = levelIdx < minIdx
          const active = level === identificationLevel

          const IconComponent = level === 'SIMPLE' ? Shield : level === 'SIMPLIFIED' ? ShieldCheck : ShieldAlert

          return (
            <button
              key={level}
              onClick={() => !disabled && onLevelChange(level)}
              disabled={disabled}
              className={`flex-1 py-2 px-1 rounded-lg text-xs font-semibold border-2 transition-all flex flex-col items-center gap-1 ${
                active
                  ? 'border-blue-500 bg-blue-50 dark:bg-blue-950/30 text-blue-700 dark:text-blue-300'
                  : disabled
                    ? 'border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900/30 text-gray-400 dark:text-gray-600 cursor-not-allowed'
                    : 'border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-400 hover:border-blue-300 cursor-pointer'
              }`}
            >
              <IconComponent className="w-4 h-4" />
              <span>{LEVEL_LABELS[level]}</span>
              <span className="font-normal text-[10px] opacity-70">{LEVEL_DESCRIPTIONS[level]}</span>
            </button>
          )
        })}
      </div>

      {/* Level indicator */}
      {identificationLevel !== 'SIMPLE' && (
        <div className="bg-amber-50 dark:bg-amber-950/30 border-2 border-amber-400 dark:border-amber-600 rounded-lg p-3 flex items-start gap-2">
          <AlertTriangle className="w-5 h-5 text-amber-600 dark:text-amber-400 mt-0.5 shrink-0" />
          <div className="text-sm">
            <p className="font-semibold text-amber-900 dark:text-amber-200">
              {identificationLevel === 'SIMPLIFIED'
                ? 'Egyszerusitett azonositas (100.000 — 300.000 Ft)'
                : 'Teljes azonositas KOTELEZO (300.000 Ft felett)'}
            </p>
            {requiresSourceVerification && (
              <p className="text-amber-700 dark:text-amber-300 mt-1">
                {t('transactions.penzEredetenekIgazolasaKotelezo3500000FtFelett')}
              </p>
            )}
          </div>
        </div>
      )}

      {/* AML warnings */}
      {amlResult && (amlResult.blocked || amlResult.warnings.length > 0) && (
        <div className={`border-2 rounded-lg p-3 text-sm ${
          amlResult.blocked
            ? 'bg-red-50 dark:bg-red-950/30 border-red-500 text-red-800 dark:text-red-200'
            : 'bg-yellow-50 dark:bg-yellow-950/30 border-yellow-400 text-yellow-800 dark:text-yellow-200'
        }`}>
          <p className="font-bold mb-1">
            {amlResult.blocked ? 'TRANZAKCIO BLOKKOLT — AML szabalysertes' : 'AML figyelmeztetesek:'}
          </p>
          {amlResult.warnings.map((w, i) => (
            <p key={i}>- {w}</p>
          ))}
          {amlChecking && <Loader2 className="w-4 h-4 animate-spin inline ml-2" />}
        </div>
      )}

      {amlChecking && !amlResult && (
        <div className="flex items-center gap-2 text-sm text-gray-500">
          <Loader2 className="w-4 h-4 animate-spin" /> AML ellenorzes...
        </div>
      )}

      {selectedCustomer ? (
        /* SELECTED CUSTOMER VIEW */
        <div className="space-y-2">
          <div className="p-3 bg-green-50 dark:bg-green-950/30 border border-green-200 dark:border-green-700 rounded-lg flex items-center justify-between">
            <div className="flex items-center gap-2">
              <CheckCircle size={18} className="text-green-600 dark:text-green-400" />
              <span className="text-green-700 dark:text-green-300 font-semibold">{t('transactions.ugyfelKivalasztva')}</span>
            </div>
            <button onClick={handleClearCustomer} className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
              <X size={18} />
            </button>
          </div>
          <div className="grid grid-cols-2 gap-2 text-sm">
            <div>
              <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">{t('competitors.nev')}</label>
              <div className="font-semibold text-gray-900 dark:text-white">{selectedCustomer.name}</div>
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">{t('transactions.allampolgarsag')}</label>
              <div className="text-gray-900 dark:text-white">{selectedCustomer.nationality ?? 'Magyar'}</div>
            </div>
            {selectedCustomer.documentType && (
              <div>
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">{t('sanction.okmany')}</label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.documentType}</div>
              </div>
            )}
            {selectedCustomer.documentNumber && (
              <div>
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">{t('transactions.okmanySzam')}</label>
                <div className="font-mono text-gray-900 dark:text-white">{selectedCustomer.documentNumber}</div>
              </div>
            )}
            {selectedCustomer.birthPlace && (
              <div>
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">{t('transactions.szuletesiHely')}</label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.birthPlace}</div>
              </div>
            )}
            {selectedCustomer.birthDate && (
              <div>
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">{t('transactions.szuletesiIdo')}</label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.birthDate}</div>
              </div>
            )}
            {selectedCustomer.birthName && (
              <div className="col-span-2">
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">{t('transactions.elozoNev')}</label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.birthName}</div>
              </div>
            )}
            {selectedCustomer.motherName && (
              <div className="col-span-2">
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">{t('common.motherName')}</label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.motherName}</div>
              </div>
            )}
            {selectedCustomer.address && (
              <div className="col-span-2">
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">{t('transactions.lakcim')}</label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.address}</div>
              </div>
            )}
            {selectedCustomer.residence && (
              <div className="col-span-2">
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">{t('transactions.tartozkodasiHely')}</label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.residence}</div>
              </div>
            )}
            {selectedCustomer.addressCardNumber && (
              <div>
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">{t('transactions.lakcimkartyaSzam')}</label>
                <div className="font-mono text-gray-900 dark:text-white">{selectedCustomer.addressCardNumber}</div>
              </div>
            )}
          </div>
        </div>
      ) : identificationLevel === 'SIMPLE' ? (
        /* SIMPLE — only nationality */
        <div className="p-3 bg-gray-50 dark:bg-gray-900/50 border border-gray-200 dark:border-gray-700 rounded-lg space-y-2">
          <div>
            <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">{t('transactions.allampolgarsag')}</label>
            <select
              className={fieldClass}
              style={fieldStyle}
              value={customerNationality}
              onChange={(e) => setCustomerNationality(e.target.value)}
            >
              <option>{t('settings.magyar')}</option>
              <option>{t('transactions.euAllampolgarsag')}</option>
              <option>{t('transactions.egyeb')}</option>
            </select>
          </div>
          <div className="text-center text-gray-500 dark:text-gray-400 py-2">
            <User size={32} className="mx-auto mb-1 text-gray-300 dark:text-gray-600" />
            <div className="text-sm">{t('transactions.100000FtAlattTovabbiAzonositasNemSzukseges')}</div>
          </div>
        </div>
      ) : (
        /* SIMPLIFIED or FULL — search + manual entry */
        <div className="space-y-3">
          {/* Search */}
          <div className="relative">
            <div className="relative">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => handleSearchInput(e.target.value)}
                onFocus={() => searchResults.length > 0 && setShowResults(true)}
                className={`${fieldClass} h-10 pl-9 pr-3`}
                style={fieldStyle}
                placeholder="Nev vagy okmanyszam kereses..."
              />
              <Search className="absolute left-3 top-2.5 w-4 h-4 text-gray-400" />
              {isSearching && <Loader2 className="absolute right-3 top-2.5 w-4 h-4 animate-spin text-gray-400" />}
            </div>

            {showResults && searchResults.length > 0 && (
              <div className="absolute z-50 w-full mt-1 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-xl max-h-60 overflow-y-auto">
                {searchResults.map((c) => (
                  <button
                    key={c.id}
                    onClick={() => void handleSelectCustomer(c)}
                    className="w-full text-left px-3 py-2 hover:bg-gray-50 dark:hover:bg-gray-700 border-b border-gray-100 dark:border-gray-700 last:border-0"
                  >
                    <div className="font-medium text-sm text-gray-900 dark:text-white">{c.name}</div>
                    <div className="text-xs text-gray-500 dark:text-gray-400">
                      {c.documentType}: {c.documentNumber} | {c.nationality ?? 'Magyar'}
                    </div>
                  </button>
                ))}
              </div>
            )}
            {showResults && searchResults.length === 0 && !isSearching && searchQuery.trim().length >= 2 && (
              <div className="absolute z-50 w-full mt-1 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-xl p-3 text-sm text-gray-500">
                {t('transactions.nemTalalhatoUgyfelAdjaMegAzAdatokatKezzel')}
              </div>
            )}
          </div>

          {/* Manual entry */}
          <div className="p-3 bg-gray-50 dark:bg-gray-900/50 border border-gray-200 dark:border-gray-700 rounded-lg space-y-2">
            <p className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide">{t('transactions.kezzelMegadas')}</p>
            <div className="grid grid-cols-2 gap-2">
              {/* --- Always shown for SIMPLIFIED+ --- */}
              <div className="col-span-2">
                <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">{t('transactions.nev')}</label>
                <input type="text" className={fieldClass} style={fieldStyle}
                  value={customerName} onChange={(e) => setCustomerName(e.target.value)} />
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">{t('transactions.szuletesiIdo2')}</label>
                <input type="date" className={fieldClass} style={fieldStyle}
                  value={customerBirthDate} onChange={(e) => setCustomerBirthDate(e.target.value)} />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">{t('transactions.szuletesiHely2')}</label>
                <input type="text" className={fieldClass} style={fieldStyle}
                  value={customerBirthPlace} onChange={(e) => setCustomerBirthPlace(e.target.value)} />
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">{t('transactions.allampolgarsag2')}</label>
                <select className={fieldClass} style={fieldStyle}
                  value={customerNationality} onChange={(e) => setCustomerNationality(e.target.value)}>
                  <option>{t('settings.magyar')}</option>
                  <option>{t('transactions.euAllampolgarsag')}</option>
                  <option>{t('transactions.egyeb')}</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">{t('transactions.okmanyTipus')}</label>
                <select className={fieldClass} style={fieldStyle}
                  value={customerDocType} onChange={(e) => setCustomerDocType(e.target.value)}>
                  <option value="ID_CARD">{t('transactions.szemelyiIgazolvany')}</option>
                  <option value="PASSPORT">{t('transactions.utlevel')}</option>
                  <option value="DRIVING_LICENSE">{t('transactions.vezetoiEngedely')}</option>
                  <option value="RESIDENCE_PERMIT">{t('transactions.tartozkodasiEngedely')}</option>
                  <option value="OTHER">{t('transactions.egyeb')}</option>
                </select>
              </div>

              <div className={showFull ? '' : 'col-span-2'}>
                <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">{t('transactions.okmanyszam')}</label>
                <input type="text" className={`${fieldClass} font-mono`} style={fieldStyle}
                  value={customerDocNumber} onChange={(e) => setCustomerDocNumber(e.target.value)} />
              </div>

              {/* --- FULL only fields --- */}
              {showFull && (
                <>
                  <div>
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">{t('transactions.elozoNevSzulNev')}</label>
                    <input type="text" className={fieldClass} style={fieldStyle}
                      value={customerBirthName} onChange={(e) => setCustomerBirthName(e.target.value)} />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">{t('transactions.anyjaNeve')}</label>
                    <input type="text" className={fieldClass} style={fieldStyle}
                      value={customerMotherName} onChange={(e) => setCustomerMotherName(e.target.value)} />
                  </div>
                  <div className="col-span-2">
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">{t('transactions.lakcimEsIranyitoszam')}</label>
                    <input type="text" className={fieldClass} style={fieldStyle}
                      value={customerAddress} onChange={(e) => setCustomerAddress(e.target.value)}
                      placeholder="pl. 1234 Budapest, Fo utca 1." />
                  </div>
                  <div className="col-span-2">
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">{t('transactions.tartozkodasiHely')}</label>
                    <input type="text" className={fieldClass} style={fieldStyle}
                      value={customerResidence} onChange={(e) => setCustomerResidence(e.target.value)} />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">{t('transactions.lakcimkartyaSzama')}</label>
                    <input type="text" className={`${fieldClass} font-mono`} style={fieldStyle}
                      value={customerAddressCardNumber} onChange={(e) => setCustomerAddressCardNumber(e.target.value)} />
                  </div>
                </>
              )}
            </div>

            <button
              onClick={() => void handleSaveManualCustomer()}
              disabled={isSaving || !isFormValid()}
              className="w-full py-2 rounded-lg text-white font-semibold text-sm transition-all disabled:opacity-50 disabled:cursor-not-allowed"
              style={{ backgroundColor: 'var(--primary)' }}
              data-action="save-customer"
            >
              {isSaving ? 'Mentes...' : 'Ugyfel rogzitese'}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
