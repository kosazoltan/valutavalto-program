import { render, screen, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import { FormulaSyntaxHelp, FormulaSyntaxHelpButton } from './FormulaSyntaxHelp'

describe('FormulaSyntaxHelp (T9.F)', () => {
  it('zárt állapotban nem renderel semmit', () => {
    const { container } = render(<FormulaSyntaxHelp open={false} onClose={() => {}} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('nyitva dokumentálja mind a 4 hivatkozástípust + a védett K oszlopot', () => {
    render(<FormulaSyntaxHelp open={true} onClose={() => {}} />)
    expect(screen.getByText('A–C, E–I')).toBeInTheDocument()
    expect(screen.getByText('J–S')).toBeInTheDocument()
    expect(screen.getByText('!Fxxx')).toBeInTheDocument()
    expect(screen.getByText('#NNL')).toBeInTheDocument()
    // Cella-módok és a védett K oszlop is szerepel.
    expect(screen.getByText('(üres)')).toBeInTheDocument()
    expect(screen.getByText('K')).toBeInTheDocument()
  })

  it('a „Vissza a munkához" gomb meghívja az onClose-t', () => {
    const onClose = vi.fn()
    render(<FormulaSyntaxHelp open={true} onClose={onClose} />)
    fireEvent.click(screen.getByText('Vissza a munkához'))
    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('a súgó-gomb kattintásra a megadott handlert hívja', () => {
    const onClick = vi.fn()
    render(<FormulaSyntaxHelpButton onClick={onClick} />)
    fireEvent.click(screen.getByText('Képlet-súgó'))
    expect(onClick).toHaveBeenCalledTimes(1)
  })
})
