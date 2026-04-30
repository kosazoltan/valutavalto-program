import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import ShipmentNewPage from './ShipmentNewPage'

/**
 * v2.4.7 Bug #1 fix — placeholder /shipments/new route smoke test.
 * Cel: 404 megszunes, az "Uj szallitmanyigeny" Link mukodik.
 */
describe('ShipmentNewPage (v2.4.7 placeholder)', () => {
  it('renders without crashing', () => {
    render(
      <MemoryRouter>
        <ShipmentNewPage />
      </MemoryRouter>,
    )
    expect(screen.getByRole('heading', { name: /Új szállítmányigény/i })).toBeInTheDocument()
  })

  it('shows "v2.5.0-ban érkezik" placeholder message', () => {
    render(
      <MemoryRouter>
        <ShipmentNewPage />
      </MemoryRouter>,
    )
    expect(screen.getByText(/v2\.5\.0-ban érkezik/i)).toBeInTheDocument()
  })

  it('has back-to-list button', () => {
    render(
      <MemoryRouter>
        <ShipmentNewPage />
      </MemoryRouter>,
    )
    expect(screen.getByRole('button', { name: /Vissza a listához/i })).toBeInTheDocument()
  })
})
