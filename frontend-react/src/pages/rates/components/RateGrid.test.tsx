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
    // FK03-fix: szerkesztő módba dupla kattintás visz (a fókusz csak kijelöl).
    const { onCommitCell } = renderGrid([row({ officialRate: 400 })])
    const jInput = screen.getByTitle(/Elszámoló árfolyam \(J\)/) as HTMLInputElement
    expect(jInput).not.toBeDisabled()
    fireEvent.focus(jInput)
    fireEvent.doubleClick(jInput)
    fireEvent.change(jInput, { target: { value: '353' } })
    fireEvent.blur(jInput)
    expect(onCommitCell).toHaveBeenCalledWith(0, 'officialRate', '353')
  })

  it('Copilot: érvényes 0 officialRate is megjelenik (nem truthy-szűrt)', () => {
    renderGrid([row({ officialRate: 0 })])
    const jInput = screen.getByTitle(/Elszámoló árfolyam \(J\)/) as HTMLInputElement
    expect(jInput.value).toBe('0,00')
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

/**
 * FK03-fix (FR-1..9): kijelölt állapot vs szerkesztő mód szétválasztása,
 * Escape-revert, J oszlop teljes rácsbeli integrációja.
 */
describe('RateGrid (FK03-fix cellaszerkesztés)', () => {
  it('single_click_does_not_enter_edit_mode: kattintás után a FORMÁZOTT érték látszik, nem a nyers/képlet', () => {
    renderGrid([row({ buyRate: '388,1267' })])
    const lInput = screen.getByDisplayValue('388,13') as HTMLInputElement
    fireEvent.focus(lInput)
    // Kijelölt állapot: továbbra is a formázott érték, NEM a nyers '388,1267'.
    expect(lInput.value).toBe('388,13')
  })

  it('double_click_enters_edit_mode_shows_formula: dupla kattintásra a képlet látszik és szerkeszthető', () => {
    renderGrid([row({ buyRate: '388,1267' })], { formulas: { '1.buyRate': '!FEUR' } })
    // Megj.: a title szerint az input ÉS az ƒ-badge is egyezne — display-value szerint választunk.
    const lInput = screen.getByDisplayValue('388,13') as HTMLInputElement
    fireEvent.focus(lInput)
    expect(lInput.value).toBe('388,13')
    fireEvent.doubleClick(lInput)
    expect(lInput.value).toBe('!FEUR')
  })

  it('escape_reverts_to_persisted_value + escape_does_not_commit', () => {
    const { onCommitCell } = renderGrid([row({ buyRate: '388,1267' })])
    const lInput = screen.getByDisplayValue('388,13') as HTMLInputElement
    fireEvent.focus(lInput)
    fireEvent.doubleClick(lInput)
    fireEvent.change(lInput, { target: { value: '999' } })
    expect(lInput.value).toBe('999')
    // Escape: a hook keydown-kezelője (container-szintű listener) blur-t hív;
    // a beírt érték elveszik, commit NINCS, a formázott perzisztált érték áll vissza.
    fireEvent.keyDown(lInput, { key: 'Escape' })
    expect(onCommitCell).not.toHaveBeenCalled()
    expect(lInput.value).toBe('388,13')
  })

  it('blur_commit_exits_edit_mode: commit után a cella visszavált formázott megjelenítésre (Copilot #1112)', () => {
    const { onCommitCell } = renderGrid([row({ buyRate: '388,1267' })])
    const lInput = screen.getByDisplayValue('388,13') as HTMLInputElement
    fireEvent.focus(lInput)
    fireEvent.doubleClick(lInput)
    fireEvent.change(lInput, { target: { value: '400' } })
    fireEvent.blur(lInput)
    expect(onCommitCell).toHaveBeenCalledWith(0, 'buyRate', '400')
    // A szerkesztő mód lezárult: a (mockolt parent miatt változatlan) perzisztált
    // érték formázott alakja látszik, nem a nyers buffer.
    expect(lInput.value).toBe('388,13')
  })

  it('selected_state_blur_does_not_commit: kijelölt (nem szerkesztő) cella elhagyása nem commitol', () => {
    const { onCommitCell } = renderGrid([row({ buyRate: '388,1267' })])
    const lInput = screen.getByDisplayValue('388,13') as HTMLInputElement
    fireEvent.focus(lInput)
    fireEvent.blur(lInput)
    expect(onCommitCell).not.toHaveBeenCalled()
  })

  it('j_column_reachable_by_arrow_navigation: a J cella nyilas navigációval elérhető a rácsban', () => {
    renderGrid([row({ officialRate: 400, buyRate: '388,1267' })])
    const lInput = screen.getByDisplayValue('388,13') as HTMLInputElement
    const jInput = screen.getByTitle(/Elszámoló árfolyam \(J\)/) as HTMLInputElement
    fireEvent.focus(lInput)
    fireEvent.keyDown(lInput, { key: 'ArrowLeft' })
    expect(document.activeElement).toBe(jInput)
  })

  it('j_column_escape_reverts: a J oszlop Escape-je revertál, nem commitol (FR-8)', () => {
    const { onCommitCell } = renderGrid([row({ officialRate: 400 })])
    const jInput = screen.getByTitle(/Elszámoló árfolyam \(J\)/) as HTMLInputElement
    fireEvent.focus(jInput)
    fireEvent.doubleClick(jInput)
    fireEvent.change(jInput, { target: { value: '777' } })
    fireEvent.keyDown(jInput, { key: 'Escape' })
    expect(onCommitCell).not.toHaveBeenCalled()
    expect(jInput.value).toBe('400,00')
  })

  it('drag_select_still_works_with_new_click_handling: tartomány-kijelölésre megjelenik a lebegő toolbar (FK02-B regresszió)', () => {
    renderGrid([
      row({ currencyId: 1, currencyCode: 'EUR', buyRate: '388' }),
      row({ currencyId: 2, currencyCode: 'USD', buyRate: '350' }),
    ])
    const eurL = screen.getByDisplayValue('388,00') as HTMLInputElement
    const usdL = screen.getByDisplayValue('350,00') as HTMLInputElement
    const eurTd = eurL.closest('td')!
    const usdTd = usdL.closest('td')!
    fireEvent.mouseDown(eurTd)
    fireEvent.mouseEnter(usdTd)
    fireEvent.mouseUp(usdTd)
    expect(screen.getByText(/Lehúzás \(mind\)/)).toBeInTheDocument()
  })
})
