import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import StaleShipmentConfirmDialog from './StaleShipmentConfirmDialog'

const shipment = {
  id: 'shipment-1',
  requestNumber: 'FF-000123',
  requestingBranchId: 'from-branch',
  requestingBranchName: 'Szeged Értéktár',
  targetBranchId: 'to-branch',
  targetBranchName: 'Szeged Pénztár',
  shipmentType: 'TRANSFER',
  requestedDeliveryDate: '2026-07-10',
  requestStatus: 'SUBMITTED',
  requestedByWorkerId: '77',
  requestedByWorkerName: 'Teszt Dolgozó',
  requestedAt: '2026-07-10T08:15:00',
  staleForDelivery: true,
  staleThresholdHours: 48,
  items: [
    { id: 'item-1', currencyId: 1, currencyCode: 'EUR', requestedAmount: 1250.5 },
    { id: 'item-2', currencyId: 2, currencyCode: 'USD', requestedAmount: 200 },
  ],
}

describe('StaleShipmentConfirmDialog', () => {
  it('magyarul, minden azonosító adattal és akadálymentes alertdialogként jelenik meg', () => {
    render(
      <StaleShipmentConfirmDialog shipment={shipment} onConfirm={vi.fn()} onCancel={vi.fn()} />,
    )

    const dialog = screen.getByRole('alertdialog')
    expect(dialog).toHaveAttribute('aria-modal', 'true')
    expect(dialog).toHaveAccessibleName('Régi szállítmány átvételének megerősítése')
    expect(dialog).toHaveTextContent('FF-000123')
    expect(dialog).toHaveTextContent(`${(1250.5).toLocaleString('hu-HU')} EUR`)
    expect(dialog).toHaveTextContent('200 USD')
    expect(dialog).toHaveTextContent(new Date(shipment.requestedAt).toLocaleString('hu-HU'))
    expect(dialog).toHaveTextContent('nincs már más módon')
    expect(screen.getByRole('button', { name: 'Igen, folytatás' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Mégse' })).toHaveFocus()
  })

  it('az Igen és a Mégse pontosan a megfelelő callbacket hívja', async () => {
    const user = userEvent.setup()
    const onConfirm = vi.fn()
    const onCancel = vi.fn()
    render(
      <StaleShipmentConfirmDialog shipment={shipment} onConfirm={onConfirm} onCancel={onCancel} />,
    )

    await user.click(screen.getByRole('button', { name: 'Igen, folytatás' }))
    expect(onConfirm).toHaveBeenCalledTimes(1)
    expect(onCancel).not.toHaveBeenCalled()

    await user.click(screen.getByRole('button', { name: 'Mégse' }))
    expect(onCancel).toHaveBeenCalledTimes(1)
  })

  it('Escape a biztonságos Mégse ágat választja és a Tab fókuszt a dialógusban tartja', async () => {
    const user = userEvent.setup()
    const onCancel = vi.fn()
    render(
      <StaleShipmentConfirmDialog shipment={shipment} onConfirm={vi.fn()} onCancel={onCancel} />,
    )

    const cancel = screen.getByRole('button', { name: 'Mégse' })
    const confirm = screen.getByRole('button', { name: 'Igen, folytatás' })
    expect(cancel).toHaveFocus()

    await user.tab({ shift: true })
    expect(confirm).toHaveFocus()
    await user.tab()
    expect(cancel).toHaveFocus()
    await user.keyboard('{Escape}')
    expect(onCancel).toHaveBeenCalledTimes(1)
  })
})
