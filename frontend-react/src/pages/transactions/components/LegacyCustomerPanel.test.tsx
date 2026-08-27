import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import LegacyCustomerPanel from './LegacyCustomerPanel'

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}))

function renderPanel(onCustomerChange = vi.fn()) {
  const onCustomerAddressChange = vi.fn()
  const view = render(
    <LegacyCustomerPanel
      customer={null}
      onCustomerChange={onCustomerChange}
      identificationLevel="FULL"
      selectedCurrencyCode="EUR"
      onCustomerAddressChange={onCustomerAddressChange}
    />,
  )
  return { ...view, onCustomerChange, onCustomerAddressChange }
}

function field(container: HTMLElement, dataField: string): HTMLInputElement {
  const input = container.querySelector<HTMLInputElement>(`[data-field="${dataField}"]`)
  if (!input) throw new Error(`Missing field: ${dataField}`)
  return input
}

describe('LegacyCustomerPanel', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('manuális ügyfél mentésekor nem fabrikál customer id-t', async () => {
    const user = userEvent.setup()
    const onCustomerChange = vi.fn()
    const { container } = renderPanel(onCustomerChange)

    await user.type(field(container, 'customer-name'), 'Kiss János')
    await user.type(field(container, 'customer-doc-number'), 'AB123456')
    await user.click(screen.getByRole('button', { name: 'transactions.ugyfelMentese' }))

    expect(onCustomerChange).toHaveBeenCalledWith({
      id: undefined,
      name: 'Kiss János',
      documentType: 'Személyi igazolvány',
      documentNumber: 'AB123456',
      nationality: 'Magyar',
    })
  })

  it('a beírt ügyféladatokat változatlanul menti fake fallback nélkül', async () => {
    const user = userEvent.setup()
    const onCustomerChange = vi.fn()
    const { container } = renderPanel(onCustomerChange)

    await user.type(field(container, 'customer-name'), 'Nagy Éva')
    await user.type(field(container, 'customer-doc-number'), 'CD987654')
    await user.click(screen.getByRole('button', { name: 'transactions.ugyfelMentese' }))

    const savedCustomer = onCustomerChange.mock.calls[0]?.[0]
    expect(savedCustomer).toMatchObject({
      name: 'Nagy Éva',
      documentNumber: 'CD987654',
    })
    expect(savedCustomer?.name).not.toBe('Teszt Ügyfél')
    expect(savedCustomer?.documentNumber).not.toBe('123456AB')
  })

  it('üres név vagy üres okmányszám mellett a mentés gomb disabled', async () => {
    const user = userEvent.setup()
    const { container } = renderPanel()

    const saveButton = screen.getByRole('button', { name: 'transactions.ugyfelMentese' })
    expect(saveButton).toBeDisabled()

    await user.type(field(container, 'customer-name'), 'Kiss János')
    expect(saveButton).toBeDisabled()

    await user.clear(field(container, 'customer-name'))
    await user.type(field(container, 'customer-doc-number'), 'AB123456')
    expect(saveButton).toBeDisabled()
  })
})
