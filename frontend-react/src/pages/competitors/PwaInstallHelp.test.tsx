import { describe, it, expect } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import PwaInstallHelp from './PwaInstallHelp'

describe('PwaInstallHelp (FK-041/II)', () => {
  it('lenyitható telepítési segéd: a lépések + URL csak nyitás után látszanak', () => {
    render(<PwaInstallHelp url="https://excvaluta.com" />)

    // A cím mindig látszik, a részletek zárva.
    expect(screen.getByText('Telepítés a telefonra')).toBeInTheDocument()
    expect(screen.queryByText(/Megosztás ikonra/)).not.toBeInTheDocument()
    expect(screen.queryByText('https://excvaluta.com')).not.toBeInTheDocument()

    // Nyitás → iOS/Android lépések + a megnyitandó URL megjelenik.
    fireEvent.click(screen.getByTestId('pwa-install-toggle'))
    expect(screen.getByText(/Megosztás ikonra/)).toBeInTheDocument()
    expect(screen.getByText(/Alkalmazás telepítése/)).toBeInTheDocument()
    expect(screen.getByText('https://excvaluta.com')).toBeInTheDocument()
  })

  it('url prop nélkül a window.location.origin-ra esik vissza (a fallback szerződés rögzítése)', () => {
    // Electronban a window.location.origin = app://localhost (a telefon nem tudja megnyitni), ezért
    // adnak a hívók getPublicWebUrl()-t. Ez a teszt a komponens dokumentált fallback-viselkedését
    // rögzíti, hogy a jövőben ne regresszáljon észrevétlenül (jsdom-ban az origin = http://localhost).
    render(<PwaInstallHelp />)
    fireEvent.click(screen.getByTestId('pwa-install-toggle'))
    expect(screen.getByText(window.location.origin)).toBeInTheDocument()
  })
})
