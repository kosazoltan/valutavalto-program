import { useState, useRef } from 'react'
import { User, Search, CheckCircle } from 'lucide-react'
import type { IdentificationLevel } from '../hooks/useIdentificationLevel'
import { useTranslation } from 'react-i18next'

export interface Customer {
  id: string
  name: string
  documentType: string
  documentNumber: string
  nationality: string
}

interface CustomerPanelProps {
  customer: Customer | null
  onCustomerChange: (customer: Customer | null) => void
  identificationLevel: IdentificationLevel
  selectedCurrencyCode: string
  onCustomerAddressChange?: (address: string) => void
}

export default function CustomerPanel({
  customer,
  onCustomerChange,
  identificationLevel,
  selectedCurrencyCode: _selectedCurrencyCode,
  onCustomerAddressChange,
}: CustomerPanelProps) {
  const { t } = useTranslation()
  const customerSearchRef = useRef<HTMLInputElement>(null)
  const [customerSearch, setCustomerSearch] = useState('')
  const [customerName, setCustomerName] = useState('')
  const [customerDocType, setCustomerDocType] = useState('Személyi igazolvány')
  const [customerDocNumber, setCustomerDocNumber] = useState('')
  const [customerNationality, setCustomerNationality] = useState('Magyar')
  const [customerBirthPlace, setCustomerBirthPlace] = useState('')
  const [customerBirthDate, setCustomerBirthDate] = useState('')
  const [customerMotherName, setCustomerMotherName] = useState('')
  const [customerAddress, setCustomerAddress] = useState('')

  const handleSaveCustomer = () => {
    onCustomerChange({
      id: '1',
      name: customerName || 'Teszt Ügyfél',
      documentType: customerDocType,
      documentNumber: customerDocNumber || '123456AB',
      nationality: customerNationality,
    })
    onCustomerAddressChange?.(customerAddress)
  }

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

  return (
    <div className="form-panel">
      <h2 className="font-semibold mb-2 pb-1 border-b flex items-center gap-2">
        <User size={18} />
        {t('transactions.ugyfelAdatok2')}
      </h2>

      <div className="form-group-box pt-4 mb-3">
        <span className="form-group-box-title">{t('transactions.ugyfelKereses')}</span>
        <div className="flex gap-1">
          <input
            ref={customerSearchRef}
            type="text"
            value={customerSearch}
            onChange={(e) => setCustomerSearch(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault()
                if (identificationLevel !== 'SIMPLE' && !customer) {
                  const el = document.querySelector<HTMLInputElement>('[data-field="customer-name"]')
                  el?.focus()
                }
              }
            }}
            className="form-input flex-1 focus:ring-2 focus:ring-primary"
            placeholder="Név vagy okmányszám..."
          />
          <button className="form-button focus:ring-2 focus:ring-primary" title="Keresés">
            <Search size={16} />
          </button>
        </div>
      </div>

      {customer ? (
        <div className="space-y-2">
          <div className="p-2 bg-green-50 border border-green-200 rounded flex items-center gap-2">
            <CheckCircle size={18} className="text-green-600" />
            <span className="text-green-700 font-semibold">{t('transactions.ugyfelKivalasztva2')}</span>
          </div>
          <div className="grid grid-cols-2 gap-2 text-sm">
            <div>
              <label className="form-label">{t('common.name')}</label>
              <div className="font-semibold">{customer.name}</div>
            </div>
            <div>
              <label className="form-label">{t('common.nationality')}</label>
              <div>{customer.nationality}</div>
            </div>
            <div>
              <label className="form-label">{t('customers.okmanyTipus')}</label>
              <div>{customer.documentType}</div>
            </div>
            <div>
              <label className="form-label">{t('common.documentNumber')}</label>
              <div className="font-mono">{customer.documentNumber}</div>
            </div>
          </div>
          <button
            onClick={() => onCustomerChange(null)}
            className="form-button w-full mt-2 focus:ring-2 focus:ring-primary"
          >
            {t('transactions.masikUgyfel')}
          </button>
        </div>
      ) : identificationLevel === 'SIMPLE' ? (
        <div className="text-center text-gray-500 py-8">
          <User size={48} className="mx-auto mb-2 text-gray-300" />
          <div>{t('transactions.100000FtAlatt')}</div>
          <div className="text-sm">{t('transactions.ugyfelAzonositasNemSzukseges')}</div>
        </div>
      ) : (
        <div className="space-y-2">
          <div className="p-2 bg-yellow-50 border border-yellow-200 rounded text-yellow-700 text-sm">
            {t('transactions.kerjukValasszonUgyfeletVagyAdjaMegAzAdatokat')}
          </div>
          <div className="grid grid-cols-2 gap-2">
            <div className="col-span-2">
              <label className="form-label">{t('common.nameRequired')}</label>
              <input
                type="text"
                className="form-input w-full focus:ring-2 focus:ring-primary"
                value={customerName}
                onChange={(e) => setCustomerName(e.target.value)}
                data-field="customer-name"
                onKeyDown={(e) => handleFieldKeyDown(e, 'customer-name')}
              />
            </div>
            <div>
              <label className="form-label">{t('transactions.okmanyTipus2')}</label>
              <select
                className="form-input w-full focus:ring-2 focus:ring-primary"
                value={customerDocType}
                onChange={(e) => setCustomerDocType(e.target.value)}
                data-field="customer-doc-type"
                onKeyDown={(e) => handleFieldKeyDown(e, 'customer-doc-type')}
              >
                <option>{t('customers.szemelyiIgazolvany')}</option>
                <option>{t('customers.utlevel')}</option>
                <option>{t('customers.vezetoiEngedely')}</option>
              </select>
            </div>
            <div>
              <label className="form-label">{t('pep.okmanyszam')}</label>
              <input
                type="text"
                className="form-input w-full focus:ring-2 focus:ring-primary"
                value={customerDocNumber}
                onChange={(e) => setCustomerDocNumber(e.target.value)}
                data-field="customer-doc-number"
                onKeyDown={(e) => handleFieldKeyDown(e, 'customer-doc-number')}
              />
            </div>
            <div>
              <label className="form-label">{t('transactions.allampolgarsag3')}</label>
              <select
                className="form-input w-full focus:ring-2 focus:ring-primary"
                value={customerNationality}
                onChange={(e) => setCustomerNationality(e.target.value)}
                data-field="customer-nationality"
                onKeyDown={(e) => handleFieldKeyDown(e, 'customer-nationality')}
              >
                <option>{t('settings.magyar')}</option>
                <option>{t('transactions.euAllampolgar')}</option>
                <option>{t('common.other')}</option>
              </select>
            </div>
            {identificationLevel === 'FULL' && (
              <>
                <div>
                  <label className="form-label">{t('transactions.szuletesiHely3')}</label>
                  <input
                    type="text"
                    className="form-input w-full focus:ring-2 focus:ring-primary"
                    value={customerBirthPlace}
                    onChange={(e) => setCustomerBirthPlace(e.target.value)}
                    data-field="customer-birth-place"
                    onKeyDown={(e) => handleFieldKeyDown(e, 'customer-birth-place')}
                  />
                </div>
                <div>
                  <label className="form-label">{t('transactions.szuletesiIdo3')}</label>
                  <input
                    type="date"
                    className="form-input w-full focus:ring-2 focus:ring-primary"
                    value={customerBirthDate}
                    onChange={(e) => setCustomerBirthDate(e.target.value)}
                    data-field="customer-birth-date"
                    onKeyDown={(e) => handleFieldKeyDown(e, 'customer-birth-date')}
                  />
                </div>
                <div>
                  <label className="form-label">{t('transactions.anyjaNeve')}</label>
                  <input
                    type="text"
                    className="form-input w-full focus:ring-2 focus:ring-primary"
                    value={customerMotherName}
                    onChange={(e) => setCustomerMotherName(e.target.value)}
                    data-field="customer-mother-name"
                    onKeyDown={(e) => handleFieldKeyDown(e, 'customer-mother-name')}
                  />
                </div>
                <div className="col-span-2">
                  <label className="form-label">{t('transactions.lakcim2')}</label>
                  <input
                    type="text"
                    className="form-input w-full focus:ring-2 focus:ring-primary"
                    value={customerAddress}
                    onChange={(e) => {
                      setCustomerAddress(e.target.value)
                      onCustomerAddressChange?.(e.target.value)
                    }}
                    data-field="customer-address"
                    onKeyDown={(e) => handleFieldKeyDown(e, 'customer-address')}
                  />
                </div>
              </>
            )}
          </div>
          <button
            onClick={handleSaveCustomer}
            className="form-button-primary w-full mt-2 focus:ring-2 focus:ring-primary"
            data-action="save-customer"
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault()
                document.querySelector<HTMLButtonElement>('[data-action="save"]')?.focus()
              }
            }}
          >
            {t('transactions.ugyfelMentese')}
          </button>
        </div>
      )}
    </div>
  )
}
