import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import { 
  ArrowLeftRight, 
  Search, 
  User, 
  Calculator,
  Printer,
  Save,
  X,
  AlertCircle,
  CheckCircle
} from 'lucide-react'
import { NumberInput } from '../../components/NumberInput'
import { formatDecimal } from '../../utils/numberFormat'

// Mock data
const mockRates = [
  { id: '1', code: 'EUR', name: 'Euró', buyRate: 391.50, sellRate: 398.50 },
  { id: '2', code: 'USD', name: 'US Dollár', buyRate: 358.20, sellRate: 365.80 },
  { id: '3', code: 'GBP', name: 'Angol Font', buyRate: 455.00, sellRate: 468.00 },
  { id: '4', code: 'CHF', name: 'Svájci Frank', buyRate: 402.50, sellRate: 412.50 },
  { id: '5', code: 'CZK', name: 'Cseh Korona', buyRate: 15.20, sellRate: 16.40 },
  { id: '6', code: 'PLN', name: 'Lengyel Zloty', buyRate: 91.50, sellRate: 96.50 },
  { id: '7', code: 'RON', name: 'Román Lej', buyRate: 78.50, sellRate: 82.50 },
  { id: '8', code: 'HRK', name: 'Horvát Kuna', buyRate: 52.00, sellRate: 55.00 },
]

interface Customer {
  id: string
  name: string
  documentType: string
  documentNumber: string
  nationality: string
}

export default function TransactionPage() {
  const navigate = useNavigate()
  
  // Refs for keyboard navigation
  const foreignAmountRef = useRef<HTMLInputElement>(null)
  const hufAmountRef = useRef<HTMLInputElement>(null)
  const customerSearchRef = useRef<HTMLInputElement>(null)
  const currencyListRef = useRef<HTMLDivElement>(null)
  const currencySelectedIndex = useRef(0)
  
  // Transaction state
  const [transactionType, setTransactionType] = useState<'BUY' | 'SELL'>('BUY')
  const [selectedCurrency, setSelectedCurrency] = useState(mockRates[0])
  const [foreignAmount, setForeignAmount] = useState('')
  const [hufAmount, setHufAmount] = useState('')
  const [lastEdited, setLastEdited] = useState<'foreign' | 'huf'>('foreign')
  
  // Customer state
  const [customer, setCustomer] = useState<Customer | null>(null)
  const [customerSearch, setCustomerSearch] = useState('')
  
  // Customer form state
  const [customerName, setCustomerName] = useState('')
  const [customerDocType, setCustomerDocType] = useState('Személyi igazolvány')
  const [customerDocNumber, setCustomerDocNumber] = useState('')
  const [customerNationality, setCustomerNationality] = useState('Magyar')
  const [customerBirthPlace, setCustomerBirthPlace] = useState('')
  const [customerBirthDate, setCustomerBirthDate] = useState('')
  const [customerMotherName, setCustomerMotherName] = useState('')
  const [customerAddress, setCustomerAddress] = useState('')
  
  // Identification
  const [identificationLevel, setIdentificationLevel] = useState<'SIMPLE' | 'SIMPLIFIED' | 'FULL'>('SIMPLE')
  const [requiresSourceVerification, setRequiresSourceVerification] = useState(false)

  // Focus on foreign amount input on mount
  useEffect(() => {
    // Small delay to ensure DOM is ready
    setTimeout(() => {
      foreignAmountRef.current?.focus()
    }, 100)
  }, [])

  // Calculate amounts
  useEffect(() => {
    if (!selectedCurrency) return
    
    const rate = transactionType === 'BUY' 
      ? selectedCurrency.buyRate 
      : selectedCurrency.sellRate
    
    if (lastEdited === 'foreign' && foreignAmount) {
      const amount = parseFloat(foreignAmount.replace(',', '.'))
      if (!isNaN(amount)) {
        setHufAmount(Math.round(amount * rate).toString())
      }
    } else if (lastEdited === 'huf' && hufAmount) {
      const amount = parseFloat(hufAmount.replace(',', '.').replace(/\s/g, ''))
      if (!isNaN(amount)) {
        const result = (amount / rate).toFixed(2).replace('.', ',')
        setForeignAmount(result)
      }
    }
  }, [foreignAmount, hufAmount, selectedCurrency, transactionType, lastEdited])

  // Check identification requirements
  useEffect(() => {
    const huf = parseFloat(hufAmount.replace(/\s/g, '').replace(',', '.')) || 0
    
    if (huf <= 100000) {
      setIdentificationLevel('SIMPLE')
    } else if (huf <= 300000) {
      setIdentificationLevel('SIMPLIFIED')
    } else {
      setIdentificationLevel('FULL')
    }
    
    setRequiresSourceVerification(huf >= 3500000)
  }, [hufAmount])

  // Keyboard shortcuts (only Escape and number keys for currency, no Ctrl combinations)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Escape - Cancel
      if (e.key === 'Escape') {
        navigate('/transactions')
      }
      // Number keys 1-8 for currency selection (only when not in input field)
      if (e.key >= '1' && e.key <= '8' && !e.ctrlKey && !e.altKey) {
        const target = e.target as HTMLElement
        // Only handle if not typing in an input field
        if (target.tagName !== 'INPUT' && target.tagName !== 'TEXTAREA' && !target.isContentEditable) {
          const index = parseInt(e.key) - 1
          if (mockRates[index]) {
            setSelectedCurrency(mockRates[index])
            // Focus on foreign amount after currency selection
            setTimeout(() => foreignAmountRef.current?.focus(), 50)
          }
        }
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Currency navigation is now handled directly in the onKeyDown of the currency list div

  // Update selected index when currency changes
  useEffect(() => {
    if (!selectedCurrency) return
    const index = mockRates.findIndex(c => c.id === selectedCurrency.id)
    if (index !== -1) {
      currencySelectedIndex.current = index
    }
  }, [selectedCurrency])

  const handleCurrencyClick = (currency: typeof mockRates[0]) => {
    setSelectedCurrency(currency)
    // Focus on foreign amount after currency selection
    setTimeout(() => foreignAmountRef.current?.focus(), 50)
  }

  const handleForeignAmountChange = (value: string) => {
    setForeignAmount(value)
    setLastEdited('foreign')
  }

  const handleHufAmountChange = (value: string) => {
    setHufAmount(value)
    setLastEdited('huf')
  }

  // Handle Enter key in input fields
  const handleForeignAmountKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      hufAmountRef.current?.focus()
    }
  }

  const handleHufAmountKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      // If customer identification is needed, focus on customer search or name field
      if (identificationLevel !== 'SIMPLE') {
        if (customer) {
          // Customer already selected, focus on save button so Enter will trigger save
          setTimeout(() => {
            document.querySelector<HTMLButtonElement>('[data-action="save"]')?.focus()
          }, 50)
        } else {
          // Focus on customer search or name field
          const customerNameInput = document.querySelector<HTMLInputElement>('[data-field="customer-name"]')
          if (customerNameInput) {
            customerNameInput.focus()
          } else {
            customerSearchRef.current?.focus()
          }
        }
      } else {
        // No customer needed, focus on save button so Enter will trigger save
        setTimeout(() => {
          document.querySelector<HTMLButtonElement>('[data-action="save"]')?.focus()
        }, 50)
      }
    }
  }

  const handleCustomerSearchKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      // Trigger search or move to customer name field if identification needed
      if (identificationLevel !== 'SIMPLE' && !customer) {
        const customerNameInput = document.querySelector<HTMLInputElement>('[data-field="customer-name"]')
        customerNameInput?.focus()
      }
    }
  }

  const handleSubmit = () => {
    // TODO: API call to save transaction
    alert('Tranzakció mentve!')
    navigate('/transactions')
  }

  const handlePrint = () => {
    // TODO: Print receipt
    alert('Bizonylat nyomtatása...')
  }

  const currentRate = selectedCurrency 
    ? (transactionType === 'BUY' ? selectedCurrency.buyRate : selectedCurrency.sellRate)
    : 0

  return (
    <div className="space-y-3">
      {/* Page header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <ArrowLeftRight />
          Új tranzakció
        </h1>
        <div className="flex gap-2">
          <button 
            onClick={() => navigate('/transactions')} 
            className="form-button flex items-center gap-1"
            title="Mégsem (Esc)"
          >
            <X size={16} />
            Mégsem
          </button>
          <button 
            onClick={handlePrint} 
            className="form-button flex items-center gap-1"
            title="Nyomtatás"
          >
            <Printer size={16} />
            Nyomtatás
          </button>
          <button 
            onClick={handleSubmit} 
            className="form-button-primary flex items-center gap-1"
            data-action="save"
            title="Mentés (Enter gombról)"
          >
            <Save size={16} />
            Mentés
          </button>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-3">
        {/* Left panel - Currency selection */}
        <div className="form-panel">
          <h2 className="font-semibold mb-2 pb-1 border-b">Deviza választás</h2>
          <div 
            ref={currencyListRef}
            className="space-y-1 max-h-[400px] overflow-auto focus:outline-none focus:ring-2 focus:ring-primary rounded"
            tabIndex={0}
            role="listbox"
            aria-label="Deviza választás"
            onKeyDown={(e) => {
              if (e.key === 'ArrowUp') {
                e.preventDefault()
                currencySelectedIndex.current = Math.max(0, currencySelectedIndex.current - 1)
                setSelectedCurrency(mockRates[currencySelectedIndex.current])
                // Scroll into view
                const currencyButton = currencyListRef.current?.children[currencySelectedIndex.current] as HTMLElement
                currencyButton?.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
              } else if (e.key === 'ArrowDown') {
                e.preventDefault()
                currencySelectedIndex.current = Math.min(mockRates.length - 1, currencySelectedIndex.current + 1)
                setSelectedCurrency(mockRates[currencySelectedIndex.current])
                // Scroll into view
                const currencyButton = currencyListRef.current?.children[currencySelectedIndex.current] as HTMLElement
                currencyButton?.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
              } else if (e.key === 'Enter') {
                e.preventDefault()
                // After selecting currency, focus on foreign amount
                setTimeout(() => foreignAmountRef.current?.focus(), 50)
              }
            }}
          >
            {mockRates.map((currency, index) => (
              <button
                key={currency.id}
                onClick={() => handleCurrencyClick(currency)}
                className={`w-full text-left p-2 border rounded transition-colors focus:outline-none ${
                  selectedCurrency?.id === currency.id
                    ? 'bg-primary text-white border-primary ring-2 ring-primary ring-offset-2'
                    : 'bg-white hover:bg-gray-50 border-form-border'
                }`}
                title={`Választás: ${index + 1} billentyű`}
              >
                <div className="flex justify-between items-center">
                  <div>
                    <span className="font-bold text-lg">
                      {currency.code}
                      {index < 9 && (
                        <span className="ml-2 text-xs opacity-75">({index + 1})</span>
                      )}
                    </span>
                    <span className={`ml-2 text-sm ${
                      selectedCurrency?.id === currency.id ? 'text-primary-100' : 'text-gray-500'
                    }`}>
                      {currency.name}
                    </span>
                  </div>
                  <div className="text-right text-sm font-mono">
                    <div>V: {formatDecimal(currency.buyRate, 2, 2)}</div>
                    <div>E: {formatDecimal(currency.sellRate, 2, 2)}</div>
                  </div>
                </div>
              </button>
            ))}
          </div>
          <div className="mt-2 text-xs text-gray-500">
            <div>Navigáció: Nyilak ↑↓ vagy számok 1-8</div>
            <div>Választás: Enter</div>
          </div>
        </div>

        {/* Center panel - Transaction details */}
        <div className="form-panel">
          <h2 className="font-semibold mb-2 pb-1 border-b flex items-center gap-2">
            <Calculator size={18} />
            Tranzakció adatok
          </h2>

          {/* Transaction type toggle */}
          <div className="flex gap-1 mb-3">
            <button
              onClick={() => setTransactionType('BUY')}
              onKeyDown={(e) => {
                if (e.key === 'ArrowRight' || e.key === ' ') {
                  e.preventDefault()
                  setTransactionType('SELL')
                }
              }}
              className={`flex-1 py-2 text-center font-semibold border rounded-l focus:outline-none focus:ring-2 focus:ring-primary ${
                transactionType === 'BUY'
                  ? 'bg-green-600 text-white border-green-700'
                  : 'bg-gray-100 border-form-border hover:bg-gray-200'
              }`}
              title="Vétel (vagy jobbra nyíl)"
            >
              VÉTEL
              <div className="text-xs font-normal">
                (Ügyfél elad {selectedCurrency?.code || 'devizát'})
              </div>
            </button>
            <button
              onClick={() => setTransactionType('SELL')}
              onKeyDown={(e) => {
                if (e.key === 'ArrowLeft' || e.key === ' ') {
                  e.preventDefault()
                  setTransactionType('BUY')
                }
              }}
              className={`flex-1 py-2 text-center font-semibold border rounded-r focus:outline-none focus:ring-2 focus:ring-primary ${
                transactionType === 'SELL'
                  ? 'bg-blue-600 text-white border-blue-700'
                  : 'bg-gray-100 border-form-border hover:bg-gray-200'
              }`}
              title="Eladás (vagy balra nyíl)"
            >
              ELADÁS
              <div className="text-xs font-normal">
                (Ügyfél vesz {selectedCurrency?.code || 'devizát'})
              </div>
            </button>
          </div>

          {/* Current rate display */}
          <div className="form-group-box pt-4 mb-3">
            <span className="form-group-box-title">Alkalmazott árfolyam</span>
            <div className="text-center">
              <span className="text-3xl font-bold font-mono text-primary">{formatDecimal(currentRate, 2, 2)}</span>
              <span className="ml-2 text-gray-500">HUF / 1 {selectedCurrency?.code || ''}</span>
            </div>
          </div>

          {/* Amount inputs */}
          <div className="space-y-3">
            <div className="form-group-box pt-4">
              <span className="form-group-box-title">{selectedCurrency?.code || 'Deviza'} összeg</span>
              <NumberInput
                ref={foreignAmountRef}
                value={foreignAmount}
                onChange={handleForeignAmountChange}
                onKeyDown={handleForeignAmountKeyDown}
                className="form-input w-full text-xl text-right h-12 focus:ring-2 focus:ring-primary"
                placeholder="0,00"
                allowDecimals={true}
                allowNegative={false}
                title="Idegen deviza összeg (Enter: következő mező)"
                autoFocus
                step="0.01"
              />
            </div>

            <div className="text-center text-gray-400">
              <ArrowLeftRight size={24} className="mx-auto" />
            </div>

            <div className="form-group-box pt-4">
              <span className="form-group-box-title">HUF összeg</span>
              <NumberInput
                ref={hufAmountRef}
                value={hufAmount}
                onChange={handleHufAmountChange}
                onKeyDown={handleHufAmountKeyDown}
                className="form-input w-full text-xl text-right h-12 focus:ring-2 focus:ring-primary"
                placeholder="0,00"
                allowDecimals={true}
                allowNegative={false}
                title="HUF összeg (Enter: következő mező)"
                min={0}
                step="0.01"
              />
            </div>
          </div>

          {/* Identification warning */}
          {identificationLevel !== 'SIMPLE' && (
            <div className={`mt-3 p-2 rounded text-sm flex items-start gap-2 ${
              identificationLevel === 'FULL' 
                ? 'bg-red-50 border border-red-200 text-red-700' 
                : 'bg-yellow-50 border border-yellow-200 text-yellow-700'
            }`}>
              <AlertCircle size={18} className="flex-shrink-0 mt-0.5" />
              <div>
                <strong>
                  {identificationLevel === 'FULL' ? 'Teljes azonosítás szükséges!' : 'Egyszerűsített azonosítás szükséges!'}
                </strong>
                <div className="text-xs mt-1">
                  {identificationLevel === 'FULL' 
                    ? '300.000 Ft feletti tranzakció' 
                    : '100.000 - 300.000 Ft közötti tranzakció'}
                </div>
              </div>
            </div>
          )}

          {requiresSourceVerification && (
            <div className="mt-2 p-2 rounded bg-red-100 border border-red-300 text-red-800 text-sm flex items-start gap-2">
              <AlertCircle size={18} className="flex-shrink-0 mt-0.5" />
              <div>
                <strong>Források igazolása szükséges!</strong>
                <div className="text-xs mt-1">3.500.000 Ft feletti tranzakció</div>
              </div>
            </div>
          )}
        </div>

        {/* Right panel - Customer */}
        <div className="form-panel">
          <h2 className="font-semibold mb-2 pb-1 border-b flex items-center gap-2">
            <User size={18} />
            Ügyfél adatok
          </h2>

          {/* Customer search */}
          <div className="form-group-box pt-4 mb-3">
            <span className="form-group-box-title">Ügyfél keresés</span>
            <div className="flex gap-1">
              <input
                ref={customerSearchRef}
                type="text"
                value={customerSearch}
                onChange={(e) => setCustomerSearch(e.target.value)}
                onKeyDown={handleCustomerSearchKeyDown}
                className="form-input flex-1 focus:ring-2 focus:ring-primary"
                placeholder="Név vagy okmányszám..."
                title="Ügyfél keresés (Enter: következő mező)"
              />
              <button 
                className="form-button focus:ring-2 focus:ring-primary"
                title="Keresés"
              >
                <Search size={16} />
              </button>
            </div>
          </div>

          {/* Customer info or form */}
          {customer ? (
            <div className="space-y-2">
              <div className="p-2 bg-green-50 border border-green-200 rounded flex items-center gap-2">
                <CheckCircle size={18} className="text-green-600" />
                <span className="text-green-700 font-semibold">Ügyfél kiválasztva</span>
              </div>
              
              <div className="grid grid-cols-2 gap-2 text-sm">
                <div>
                  <label className="form-label">Név</label>
                  <div className="font-semibold">{customer.name}</div>
                </div>
                <div>
                  <label className="form-label">Állampolgárság</label>
                  <div>{customer.nationality}</div>
                </div>
                <div>
                  <label className="form-label">Okmány típus</label>
                  <div>{customer.documentType}</div>
                </div>
                <div>
                  <label className="form-label">Okmányszám</label>
                  <div className="font-mono">{customer.documentNumber}</div>
                </div>
              </div>

              <button
                onClick={() => setCustomer(null)}
                className="form-button w-full mt-2 focus:ring-2 focus:ring-primary"
                title="Másik ügyfél (Enter)"
              >
                Másik ügyfél
              </button>
            </div>
          ) : identificationLevel === 'SIMPLE' ? (
            <div className="text-center text-gray-500 py-8">
              <User size={48} className="mx-auto mb-2 text-gray-300" />
              <div>100.000 Ft alatt</div>
              <div className="text-sm">ügyfél azonosítás nem szükséges</div>
            </div>
          ) : (
            <div className="space-y-2">
              <div className="p-2 bg-yellow-50 border border-yellow-200 rounded text-yellow-700 text-sm">
                Kérjük válasszon ügyfelet vagy adja meg az adatokat!
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div className="col-span-2">
                  <label className="form-label">Név *</label>
                  <input 
                    type="text" 
                    className="form-input w-full focus:ring-2 focus:ring-primary" 
                    value={customerName}
                    onChange={(e) => setCustomerName(e.target.value)}
                    data-field="customer-name"
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault()
                        const nextField = e.currentTarget.parentElement?.parentElement?.querySelector<HTMLInputElement | HTMLSelectElement>('[data-field="customer-doc-type"]')
                        nextField?.focus()
                      }
                    }}
                  />
                </div>
                <div>
                  <label className="form-label">Okmány típus *</label>
                  <select 
                    className="form-input w-full focus:ring-2 focus:ring-primary"
                    value={customerDocType}
                    onChange={(e) => setCustomerDocType(e.target.value)}
                    data-field="customer-doc-type"
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault()
                        const nextField = e.currentTarget.parentElement?.parentElement?.querySelector<HTMLInputElement>('[data-field="customer-doc-number"]')
                        nextField?.focus()
                      }
                    }}
                  >
                    <option>Személyi igazolvány</option>
                    <option>Útlevél</option>
                    <option>Vezetői engedély</option>
                  </select>
                </div>
                <div>
                  <label className="form-label">Okmányszám *</label>
                  <input 
                    type="text" 
                    className="form-input w-full focus:ring-2 focus:ring-primary" 
                    value={customerDocNumber}
                    onChange={(e) => setCustomerDocNumber(e.target.value)}
                    data-field="customer-doc-number"
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault()
                        const nextField = e.currentTarget.parentElement?.parentElement?.querySelector<HTMLSelectElement>('[data-field="customer-nationality"]')
                        nextField?.focus()
                      }
                    }}
                  />
                </div>
                <div>
                  <label className="form-label">Állampolgárság *</label>
                  <select 
                    className="form-input w-full focus:ring-2 focus:ring-primary"
                    value={customerNationality}
                    onChange={(e) => setCustomerNationality(e.target.value)}
                    data-field="customer-nationality"
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault()
                        if (identificationLevel === 'FULL') {
                          const nextField = e.currentTarget.parentElement?.parentElement?.querySelector<HTMLInputElement>('[data-field="customer-birth-place"]')
                          nextField?.focus()
                        } else {
                          document.querySelector<HTMLButtonElement>('[data-action="save-customer"]')?.focus()
                        }
                      }
                    }}
                  >
                    <option>Magyar</option>
                    <option>EU állampolgár</option>
                    <option>Egyéb</option>
                  </select>
                </div>
                {identificationLevel === 'FULL' && (
                  <>
                    <div>
                      <label className="form-label">Születési hely *</label>
                      <input 
                        type="text" 
                        className="form-input w-full focus:ring-2 focus:ring-primary" 
                        value={customerBirthPlace}
                        onChange={(e) => setCustomerBirthPlace(e.target.value)}
                        data-field="customer-birth-place"
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') {
                            e.preventDefault()
                            const nextField = e.currentTarget.parentElement?.parentElement?.querySelector<HTMLInputElement>('[data-field="customer-birth-date"]')
                            nextField?.focus()
                          }
                        }}
                      />
                    </div>
                    <div>
                      <label className="form-label">Születési idő *</label>
                      <input 
                        type="date" 
                        className="form-input w-full focus:ring-2 focus:ring-primary" 
                        value={customerBirthDate}
                        onChange={(e) => setCustomerBirthDate(e.target.value)}
                        data-field="customer-birth-date"
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') {
                            e.preventDefault()
                            const nextField = e.currentTarget.parentElement?.parentElement?.querySelector<HTMLInputElement>('[data-field="customer-mother-name"]')
                            nextField?.focus()
                          }
                        }}
                      />
                    </div>
                    <div>
                      <label className="form-label">Anyja neve *</label>
                      <input 
                        type="text" 
                        className="form-input w-full focus:ring-2 focus:ring-primary" 
                        value={customerMotherName}
                        onChange={(e) => setCustomerMotherName(e.target.value)}
                        data-field="customer-mother-name"
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') {
                            e.preventDefault()
                            const nextField = e.currentTarget.parentElement?.parentElement?.querySelector<HTMLInputElement>('[data-field="customer-address"]')
                            nextField?.focus()
                          }
                        }}
                      />
                    </div>
                    <div className="col-span-2">
                      <label className="form-label">Lakcím *</label>
                      <input 
                        type="text" 
                        className="form-input w-full focus:ring-2 focus:ring-primary" 
                        value={customerAddress}
                        onChange={(e) => setCustomerAddress(e.target.value)}
                        data-field="customer-address"
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') {
                            e.preventDefault()
                            document.querySelector<HTMLButtonElement>('[data-action="save-customer"]')?.focus()
                          }
                        }}
                      />
                    </div>
                  </>
                )}
              </div>

              <button
                onClick={() => setCustomer({
                  id: '1',
                  name: customerName || 'Teszt Ügyfél',
                  documentType: customerDocType,
                  documentNumber: customerDocNumber || '123456AB',
                  nationality: customerNationality
                })}
                className="form-button-primary w-full mt-2 focus:ring-2 focus:ring-primary"
                data-action="save-customer"
                title="Ügyfél mentése (Enter)"
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault()
                    document.querySelector<HTMLButtonElement>('[data-action="save"]')?.focus()
                  }
                }}
              >
                Ügyfél mentése
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Keyboard shortcuts help */}
      <div className="text-xs text-gray-500 p-2 bg-gray-50 rounded border">
        <div className="font-semibold mb-1">Billentyűzet használat:</div>
        <div className="grid grid-cols-3 gap-2">
          <div>Esc - Mégsem</div>
          <div>1-8 - Deviza választás</div>
          <div>↑↓ - Deviza navigáció</div>
          <div>Enter - Következő mező</div>
          <div>Enter (gombról) - Művelet végrehajtás</div>
          <div>Tab - Mezők közötti lépés</div>
        </div>
      </div>
    </div>
  )
}