import { render, screen, fireEvent } from '@testing-library/react'
import { vi, describe, it, expect } from 'vitest'
import RateGrid from './RateGrid'
import type { EditableRate } from '../types'

/**
 * FK02-E (FR-5, FR-7, FR-10, FR-13, FR-14): a csoport árfolyamlap rács fókuszált viselkedései.
 * A teljes RateCreationPage túl nehéz egységként — itt a RateGrid prezentációs/interakciós
 * szerződését rögzítjük (J szerkeszthetőség, tizedes-megjelenítés, szinkron-zárolás).
 */
const row = (over: Partial<EditableRate> = {}): EditableRate => ({
  currencyId: 1,
  currencyCode: 'EUR',
  currencyName: 'Euró',
  officialRate: 400,
  buyRate: '',
  sellRate: '',
  limit1BuyRate: '',
  limit1SellRate: '',
  limit2BuyRate: '',
  limit2SellRate: '',
  limit3BuyRate: '',
  limit3SellRate: '',
  hasRate: true,
  modified: false,
  ...over,
})

function renderGrid(rates: EditableRate[], props: Record<string, unknown> = {}) {
  const onCommitCell = vi.fn()
  const updateRate = vi.fn()
  render(
    <RateGrid
      rates={rates}
      selectedWg={null}
      updateRate={updateRate}
      onCommitCell={onCommitCell}
      canEdit={true}
      {...props}
    />,
  )
  return { onCommitCell, updateRate }
}

describe('RateGrid (FK02-E)', () => {
  it('FR-5/FR-7: a J (elszámoló) cella szerkeszthető és onBlur commitol officialRate-ként', () => {
    const { onCommitCell } = renderGrid([row({ officialRate: 400 })])
    const jInput = screen.getByTitle(/Elszámoló árfolyam \(J\)/) as HTMLInputElement
    expect(jInput).not.toBeDisabled()
    fireEvent.focus(jInput)
    fireEvent.change(jInput, { target: { value: '353' } })
    fireEvent.blur(jInput)
    expect(onCommitCell).toHaveBeenCalledWith(0, 'officialRate', '353')
  })

  it('FR-10: a megjelenítés JPY-nél 4, minden más valutánál 2 tizedes', () => {
    renderGrid([
      row({ currencyId: 1, currencyCode: 'EUR', buyRate: '388,1267' }),
      row({ currencyId: 7, currencyCode: 'JPY', buyRate: '2,1611' }),
    ])
    // EUR L (vétel) cella 2 tizedesre kerekítve jelenik meg.
    expect(screen.getByDisplayValue('388,13')).toBeInTheDocument()
    // JPY L cella 4 tizedessel.
    expect(screen.getByDisplayValue('2,1611')).toBeInTheDocument()
  })

  it('FR-13: szinkron NÉLKÜL nincs zároló overlay (a cellák szerkeszthetők)', () => {
    renderGrid([row()], { syncing: false })
    expect(screen.queryByText(/Szinkronizálás folyamatban/)).toBeNull()
  })

  it('FR-14: szinkron alatt zároló overlay + üzenet jelenik meg', () => {
    renderGrid([row()], { syncing: true })
    expect(screen.getByText(/Szinkronizálás folyamatban, kérjük várjon/)).toBeInTheDocument()
  })
})
