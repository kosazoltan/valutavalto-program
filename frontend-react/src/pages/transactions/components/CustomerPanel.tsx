import { useState, useRef, useCallback, useEffect } from 'react'
import { User, Search, CheckCircle, Loader2, AlertTriangle, X } from 'lucide-react'
import type { IdentificationLevel } from '../hooks/useIdentificationLevel'
import { customerApi, amlApi } from '../../../services/api/index'
import type { Customer as ApiCustomer, CustomerCreateRequest, AmlCheckResultDto } from '../../../services/api/transactions'
import { logger } from '../../../utils/logger'

export interface CustomerPanelData {
  id?: number
  name: string
  documentType: string
  documentNumber: string
  nationality: string
  birthPlace?: string
  birthDate?: string
  motherName?: string
  address?: string
  /** true only if AML check completed successfully */
  amlVerified?: boolean
}

interface CustomerPanelProps {
  identificationLevel: IdentificationLevel
  requiresSourceVerification: boolean
  hufTotal: number
  onCustomerReady: (data: CustomerPanelData | null) => void
  onAmlResult?: (result: AmlCheckResultDto | null) => void
}

export default function CustomerPanel({
  identificationLevel,
  requiresSourceVerification,
  hufTotal,
  onCustomerReady,
  onAmlResult,
}: CustomerPanelProps) {
  // Search state
  const [searchQuery, setSearchQuery] = useState('')
  const [searchResults, setSearchResults] = useState<ApiCustomer[]>([])
  const [isSearching, setIsSearching] = useState(false)
  const [showResults, setShowResults] = useState(false)
  const searchTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  // Selected customer from API
  const [selectedCustomer, setSelectedCustomer] = useState<ApiCustomer | null>(null)

  // Manual entry fields (used when no API match found)
  const [customerName, setCustomerName] = useState('')
  const [customerDocType, setCustomerDocType] = useState('Személyi igazolvány')
  const [customerDocNumber, setCustomerDocNumber] = useState('')
  const [customerNationality, setCustomerNationality] = useState('Magyar')
  const [customerBirthPlace, setCustomerBirthPlace] = useState('')
  const [customerBirthDate, setCustomerBirthDate] = useState('')
  const [customerMotherName, setCustomerMotherName] = useState('')
  const [customerAddress, setCustomerAddress] = useState('')

  // AML state
  const [amlResult, setAmlResult] = useState<AmlCheckResultDto | null>(null)
  const [amlChecking, setAmlChecking] = useState(false)

  // Save/create state
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
        // Try document number first, then name search
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

  // Select customer from search results
  const handleSelectCustomer = useCallback(async (customer: ApiCustomer) => {
    setSelectedCustomer(customer)
    setShowResults(false)
    setSearchQuery('')

    const data: CustomerPanelData = {
      id: customer.id,
      name: customer.name,
      documentType: customer.documentType ?? 'Személyi igazolvány',
      documentNumber: customer.documentNumber ?? '',
      nationality: customer.nationality ?? 'Magyar',
      birthPlace: customer.birthPlace,
      birthDate: customer.birthDate,
      motherName: customer.motherName,
      address: customer.address,
      amlVerified: false,
    }

    // Run AML check — fail-closed
    if (customer.id && hufTotal > 0) {
      setAmlChecking(true)
      try {
        const result = await amlApi.checkAllThresholds(String(customer.id), hufTotal)
        setAmlResult(result)
        onAmlResult?.(result)
        data.amlVerified = true
      } catch (err) {
        logger.warn('CustomerPanel', 'AML check failed — fail-closed', err)
        const blockedResult: AmlCheckResultDto = {
          transactionType: 0, weeklyTotal: 0, yearlyMax: 0, quarterlyCount: 0, quarterlyTotal: 0,
          requiresId: true, requiresEnhanced: false, blocked: true,
          warnings: ['AML ellenorzes nem sikerult — tranzakcio blokkolt biztonsagi okbol'],
        }
        setAmlResult(blockedResult)
        onAmlResult?.(blockedResult)
      } finally {
        setAmlChecking(false)
      }
    }

    onCustomerReady(data)
  }, [hufTotal, onCustomerReady, onAmlResult])

  // Save manually entered customer
  const handleSaveManualCustomer = useCallback(async () => {
    if (!customerName.trim() || !customerDocNumber.trim()) return
    // FULL level: require complete data set at panel level (fail-fast)
    if (identificationLevel === 'FULL' && (!customerBirthPlace.trim() || !customerBirthDate || !customerMotherName.trim() || !customerAddress.trim())) {
          return // button is already disabled, but double-guard
    }

    setIsSaving(true)
    try {
      const createData: CustomerCreateRequest = {
        name: customerName.trim(),
        documentType: customerDocType,
        documentNumber: customerDocNumber.trim(),
        nationality: customerNationality,
        birthPlace: customerBirthPlace.trim() || undefined,
        birthDate: customerBirthDate || undefined,
        motherName: customerMotherName.trim() || undefined,
        address: customerAddress.trim() || undefined,
      }

      let savedCustomer: ApiCustomer | null = null
      try {
        savedCustomer = await customerApi.create(createData)
      } catch (err) {
        // If create fails (e.g. already exists), try search by doc number
        logger.warn('CustomerPanel', 'Customer create failed, trying doc number lookup', err)
        try {
          savedCustomer = await customerApi.getByDocumentNumber(customerDocNumber.trim())
        } catch {
          // If both fail, proceed without backend ID
        }
      }

      const data: CustomerPanelData = {
        id: savedCustomer?.id,
        name: customerName.trim(),
        documentType: customerDocType,
        documentNumber: customerDocNumber.trim(),
        nationality: customerNationality,
        birthPlace: customerBirthPlace.trim() || undefined,
        birthDate: customerBirthDate || undefined,
        motherName: customerMotherName.trim() || undefined,
        address: customerAddress.trim() || undefined,
        amlVerified: false,
      }
      setSelectedCustomer(savedCustomer)

      // AML check — fail-closed: if no backend ID, AML stays unverified
      if (savedCustomer?.id && hufTotal > 0) {
        setAmlChecking(true)
        try {
          const result = await amlApi.checkAllThresholds(String(savedCustomer.id), hufTotal)
          setAmlResult(result)
          onAmlResult?.(result)
          data.amlVerified = true
        } catch (err) {
          logger.warn('CustomerPanel', 'AML check failed — transaction will be blocked (fail-closed)', err)
          // Fail-closed: create a synthetic blocked result
          const blockedResult: AmlCheckResultDto = {
            transactionType: 0,
            weeklyTotal: 0,
            yearlyMax: 0,
            quarterlyCount: 0,
            quarterlyTotal: 0,
            requiresId: true,
            requiresEnhanced: false,
            blocked: true,
            warnings: ['AML ellenorzes nem sikerult — tranzakcio blokkolt biztonsagi okbol'],
          }
          setAmlResult(blockedResult)
          onAmlResult?.(blockedResult)
        } finally {
          setAmlChecking(false)
        }
      } else if (hufTotal >= 100_000) {
        // No backend ID + above threshold → fail-closed
        const blockedResult: AmlCheckResultDto = {
          transactionType: 0,
          weeklyTotal: 0,
          yearlyMax: 0,
          quarterlyCount: 0,
          quarterlyTotal: 0,
          requiresId: true,
          requiresEnhanced: false,
          blocked: true,
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
  }, [customerName, customerDocType, customerDocNumber, customerNationality, customerBirthPlace, customerBirthDate, customerMotherName, customerAddress, hufTotal, identificationLevel, onCustomerReady, onAmlResult])

  // Clear customer
  const handleClearCustomer = useCallback(() => {
    setSelectedCustomer(null)
    setCustomerName('')
    setCustomerDocType('Személyi igazolvány')
    setCustomerDocNumber('')
    setCustomerNationality('Magyar')
    setCustomerBirthPlace('')
    setCustomerBirthDate('')
    setCustomerMotherName('')
    setCustomerAddress('')
    setAmlResult(null)
    setSearchQuery('')
    setSearchResults([])
    onCustomerReady(null)
    onAmlResult?.(null)
  }, [onCustomerReady, onAmlResult])

  // Re-run AML check when hufTotal changes significantly
  useEffect(() => {
    if (selectedCustomer?.id && hufTotal > 0) {
      const timer = setTimeout(async () => {
        try {
          const result = await amlApi.checkAllThresholds(String(selectedCustomer.id), hufTotal)
          setAmlResult(result)
          onAmlResult?.(result)
        } catch {
          // Fail-closed: if AML re-check fails, block transaction
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

  const focusNextField = (currentField: string) => {
    const fieldOrder: Record<string, string> = {
      'customer-name': 'customer-doc-type',
      'customer-doc-type': 'customer-doc-number',
      'customer-doc-number': 'customer-nationality',
      'customer-nationality': identificationLevel === 'FULL' ? 'customer-birth-place' : '',
      'customer-birth-place': 'customer-birth-date',
      'customer-birth-date': 'customer-mother-name',
      'customer-mother-name': 'customer-address',
      'customer-address': '',
    }
    const next = fieldOrder[currentField]
    if (next) {
      const el = document.querySelector<HTMLElement>(`[data-field="${next}"]`)
      el?.focus()
    } else {
      document.querySelector<HTMLButtonElement>('[data-action="save-customer"]')?.focus()
    }
  }

  const handleFieldKeyDown = (e: React.KeyboardEvent, field: string) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      focusNextField(field)
    }
  }

  // --- RENDER ---

  return (
    <div className="space-y-3">
      <h3 className="text-lg font-bold flex items-center gap-2 text-gray-900 dark:text-white">
        <User className="w-5 h-5" />
        UGYFEL ADATOK
      </h3>

      {/* Identification level indicator */}
      {identificationLevel !== 'SIMPLE' && (
        <div className="bg-amber-50 dark:bg-amber-950/30 border-2 border-amber-400 dark:border-amber-600 rounded-lg p-3 flex items-start gap-2">
          <AlertTriangle className="w-5 h-5 text-amber-600 dark:text-amber-400 mt-0.5 shrink-0" />
          <div className="text-sm">
            <p className="font-semibold text-amber-900 dark:text-amber-200">
              {identificationLevel === 'SIMPLIFIED'
                ? 'Egyszerusitett azonositas KOTELEZO (100.000 — 300.000 Ft)'
                : 'Teljes azonositas KOTELEZO (300.000 Ft felett)'}
            </p>
            {requiresSourceVerification && (
              <p className="text-amber-700 dark:text-amber-300 mt-1">
                Penz eredetenek igazolasa KOTELEZO (3.500.000 Ft felett)
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

      {/* AML checking indicator */}
      {amlChecking && !amlResult && (
        <div className="flex items-center gap-2 text-sm text-gray-500">
          <Loader2 className="w-4 h-4 animate-spin" /> AML ellenorzes...
        </div>
      )}

      {selectedCustomer ? (
        // SELECTED CUSTOMER VIEW
        <div className="space-y-2">
          <div className="p-3 bg-green-50 dark:bg-green-950/30 border border-green-200 dark:border-green-700 rounded-lg flex items-center justify-between">
            <div className="flex items-center gap-2">
              <CheckCircle size={18} className="text-green-600 dark:text-green-400" />
              <span className="text-green-700 dark:text-green-300 font-semibold">Ugyfel kivalasztva</span>
            </div>
            <button onClick={handleClearCustomer} className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
              <X size={18} />
            </button>
          </div>
          <div className="grid grid-cols-2 gap-2 text-sm">
            <div>
              <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">Nev</label>
              <div className="font-semibold text-gray-900 dark:text-white">{selectedCustomer.name}</div>
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">Allampolgarsag</label>
              <div className="text-gray-900 dark:text-white">{selectedCustomer.nationality ?? 'Magyar'}</div>
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">Okmany</label>
              <div className="text-gray-900 dark:text-white">{selectedCustomer.documentType ?? '—'}</div>
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">Okmany szam</label>
              <div className="font-mono text-gray-900 dark:text-white">{selectedCustomer.documentNumber ?? '—'}</div>
            </div>
            {selectedCustomer.address && (
              <div className="col-span-2">
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">Cim</label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.address}</div>
              </div>
            )}
            {selectedCustomer.birthPlace && (
              <div>
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">Szuletesi hely</label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.birthPlace}</div>
              </div>
            )}
            {selectedCustomer.birthDate && (
              <div>
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">Szuletesi ido</label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.birthDate}</div>
              </div>
            )}
            {selectedCustomer.motherName && (
              <div className="col-span-2">
                <label className="block text-xs font-medium text-gray-500 dark:text-gray-400">Anyja neve</label>
                <div className="text-gray-900 dark:text-white">{selectedCustomer.motherName}</div>
              </div>
            )}
          </div>
        </div>
      ) : identificationLevel === 'SIMPLE' ? (
        // NO IDENTIFICATION NEEDED
        <div className="text-center text-gray-500 dark:text-gray-400 py-6">
          <User size={40} className="mx-auto mb-2 text-gray-300 dark:text-gray-600" />
          <div className="font-medium">100.000 Ft alatt</div>
          <div className="text-sm">Ugyfel azonositas nem szukseges</div>
        </div>
      ) : (
        // SEARCH + MANUAL ENTRY
        <div className="space-y-3">
          {/* Search bar */}
          <div className="relative">
            <div className="flex gap-1">
              <div className="relative flex-1">
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => handleSearchInput(e.target.value)}
                  onFocus={() => searchResults.length > 0 && setShowResults(true)}
                  className="w-full h-10 pl-9 pr-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white focus:ring-2 focus:border-transparent text-sm"
                  style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
                  placeholder="Nev vagy okmanyszam kereses..."
                />
                <Search className="absolute left-3 top-2.5 w-4 h-4 text-gray-400" />
                {isSearching && <Loader2 className="absolute right-3 top-2.5 w-4 h-4 animate-spin text-gray-400" />}
              </div>
            </div>

            {/* Dropdown results */}
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
                Nem talalhato ugyfel. Adja meg az adatokat kezzel!
              </div>
            )}
          </div>

          {/* Manual entry form */}
          <div className="p-3 bg-gray-50 dark:bg-gray-900/50 border border-gray-200 dark:border-gray-700 rounded-lg space-y-2">
            <p className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide">Kezzel megadas</p>
            <div className="grid grid-cols-2 gap-2">
              <div className="col-span-2">
                <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">Nev *</label>
                <input
                  type="text"
                  className="w-full h-9 px-2 text-sm rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white focus:ring-2 focus:border-transparent"
                  style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
                  value={customerName}
                  onChange={(e) => setCustomerName(e.target.value)}
                  data-field="customer-name"
                  onKeyDown={(e) => handleFieldKeyDown(e, 'customer-name')}
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">Okmany tipus *</label>
                <select
                  className="w-full h-9 px-2 text-sm rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white focus:ring-2 focus:border-transparent"
                  style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
                  value={customerDocType}
                  onChange={(e) => setCustomerDocType(e.target.value)}
                  data-field="customer-doc-type"
                  onKeyDown={(e) => handleFieldKeyDown(e, 'customer-doc-type')}
                >
                  <option>Személyi igazolvány</option>
                  <option>Útlevél</option>
                  <option>Vezetői engedély</option>
                  <option>Tartózkodási engedély</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">Okmanyszam *</label>
                <input
                  type="text"
                  className="w-full h-9 px-2 text-sm rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent font-mono text-gray-900 dark:text-white focus:ring-2 focus:border-transparent"
                  style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
                  value={customerDocNumber}
                  onChange={(e) => setCustomerDocNumber(e.target.value)}
                  data-field="customer-doc-number"
                  onKeyDown={(e) => handleFieldKeyDown(e, 'customer-doc-number')}
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">Allampolgarsag *</label>
                <select
                  className="w-full h-9 px-2 text-sm rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white focus:ring-2 focus:border-transparent"
                  style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
                  value={customerNationality}
                  onChange={(e) => setCustomerNationality(e.target.value)}
                  data-field="customer-nationality"
                  onKeyDown={(e) => handleFieldKeyDown(e, 'customer-nationality')}
                >
                  <option>Magyar</option>
                  <option>EU állampolgár</option>
                  <option>Egyéb</option>
                </select>
              </div>
              {identificationLevel === 'FULL' && (
                <>
                  <div>
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">Szuletesi hely *</label>
                    <input
                      type="text"
                      className="w-full h-9 px-2 text-sm rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white focus:ring-2 focus:border-transparent"
                      style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
                      value={customerBirthPlace}
                      onChange={(e) => setCustomerBirthPlace(e.target.value)}
                      data-field="customer-birth-place"
                      onKeyDown={(e) => handleFieldKeyDown(e, 'customer-birth-place')}
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">Szuletesi ido *</label>
                    <input
                      type="date"
                      className="w-full h-9 px-2 text-sm rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white focus:ring-2 focus:border-transparent"
                      style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
                      value={customerBirthDate}
                      onChange={(e) => setCustomerBirthDate(e.target.value)}
                      data-field="customer-birth-date"
                      onKeyDown={(e) => handleFieldKeyDown(e, 'customer-birth-date')}
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">Anyja neve *</label>
                    <input
                      type="text"
                      className="w-full h-9 px-2 text-sm rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white focus:ring-2 focus:border-transparent"
                      style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
                      value={customerMotherName}
                      onChange={(e) => setCustomerMotherName(e.target.value)}
                      data-field="customer-mother-name"
                      onKeyDown={(e) => handleFieldKeyDown(e, 'customer-mother-name')}
                    />
                  </div>
                  <div className="col-span-2">
                    <label className="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-0.5">Lakcim *</label>
                    <input
                      type="text"
                      className="w-full h-9 px-2 text-sm rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white focus:ring-2 focus:border-transparent"
                      style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
                      value={customerAddress}
                      onChange={(e) => setCustomerAddress(e.target.value)}
                      data-field="customer-address"
                      onKeyDown={(e) => handleFieldKeyDown(e, 'customer-address')}
                    />
                  </div>
                </>
              )}
            </div>
            <button
              onClick={() => void handleSaveManualCustomer()}
              disabled={
                isSaving
                || !customerName.trim()
                || !customerDocNumber.trim()
                || (identificationLevel === 'FULL' && (!customerBirthPlace.trim() || !customerBirthDate || !customerMotherName.trim() || !customerAddress.trim()))
              }
              className="w-full py-2 rounded-lg text-white font-semibold text-sm transition-all disabled:opacity-50 disabled:cursor-not-allowed"
              style={{ backgroundColor: 'var(--primary)' }}
              data-action="save-customer"
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault()
                  document.querySelector<HTMLButtonElement>('[data-action="save"]')?.focus()
                }
              }}
            >
              {isSaving ? 'Mentes...' : 'Ugyfel rogzitese'}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
