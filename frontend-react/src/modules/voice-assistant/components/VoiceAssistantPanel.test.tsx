import { render, screen } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import { VoiceAssistantPanel } from './VoiceAssistantPanel'
import type { VoiceAssistantContextValue } from '../context/VoiceAssistantProvider'

/**
 * VoiceAssistantPanel UI-label tesztek.
 *
 * <p>Copilot PR #691 P2 finding: a felhasznalo-baart status-sor regression
 * (technikai `unified` string a UI-ban) nincs RTL coverage-szel vedve.
 *
 * <p>Mockoljuk a `useVoiceAssistant` hookot dinamikus mode/isActive/etc.
 * ertekekkel hogy a 4 mode label-jet es az idle/connecting states-eket
 * direkt teszteljuk.
 */

vi.mock('../context/VoiceAssistantProvider', () => ({
  useVoiceAssistant: vi.fn(),
}))

import { useVoiceAssistant } from '../context/VoiceAssistantProvider'
const mockedUseVoiceAssistant = useVoiceAssistant as ReturnType<typeof vi.fn>

function setUseVoiceAssistant(overrides: Partial<VoiceAssistantContextValue> = {}) {
  mockedUseVoiceAssistant.mockReturnValue({
    mode: 'idle',
    isActive: false,
    isConnecting: false,
    error: null,
    start: vi.fn(),
    stop: vi.fn(),
    ...overrides,
  })
}

describe('VoiceAssistantPanel', () => {
  it('idle: "Indítsd a beszélgetést." prompt es "Beszélgetés indítása" gomb lathato', () => {
    setUseVoiceAssistant({ mode: 'idle', isActive: false })
    render(<VoiceAssistantPanel />)
    expect(screen.getByText('Indítsd a beszélgetést.')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Beszélgetés indítása' })).toBeInTheDocument()
  })

  it('isConnecting: "Kapcsolódás…" + gomb disabled', () => {
    setUseVoiceAssistant({ mode: 'idle', isActive: false, isConnecting: true })
    render(<VoiceAssistantPanel />)
    expect(screen.getByText('Kapcsolódás…')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Beszélgetés indítása' })).toBeDisabled()
  })

  it('active unified: "Aktív — Beszélgetés" label + "Beszélgetés befejezése" gomb', () => {
    setUseVoiceAssistant({ mode: 'unified', isActive: true })
    render(<VoiceAssistantPanel />)
    expect(screen.getByText('Aktív — Beszélgetés')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Beszélgetés befejezése' })).toBeInTheDocument()
  })

  it('active install: "Aktív — Telepítés" label', () => {
    setUseVoiceAssistant({ mode: 'install', isActive: true })
    render(<VoiceAssistantPanel />)
    expect(screen.getByText('Aktív — Telepítés')).toBeInTheDocument()
  })

  it('active test: "Aktív — Tesztelés" label', () => {
    setUseVoiceAssistant({ mode: 'test', isActive: true })
    render(<VoiceAssistantPanel />)
    expect(screen.getByText('Aktív — Tesztelés')).toBeInTheDocument()
  })

  it('active support: "Aktív — Hibajelzés" label', () => {
    setUseVoiceAssistant({ mode: 'support', isActive: true })
    render(<VoiceAssistantPanel />)
    expect(screen.getByText('Aktív — Hibajelzés')).toBeInTheDocument()
  })

  it('error uzenet megjelenik a piros sav-on', () => {
    setUseVoiceAssistant({ mode: 'idle', isActive: false, error: 'Test error üzenet' })
    render(<VoiceAssistantPanel />)
    expect(screen.getByText('Test error üzenet')).toBeInTheDocument()
  })

  it('aria-label: "EBC Hangsegéd" dialog role-on', () => {
    setUseVoiceAssistant()
    render(<VoiceAssistantPanel />)
    expect(screen.getByRole('dialog', { name: 'EBC Hangsegéd' })).toBeInTheDocument()
  })

  it('NEM jelenit meg a technikai "unified" stringet a UI-ban (regression #689)', () => {
    setUseVoiceAssistant({ mode: 'unified', isActive: true })
    render(<VoiceAssistantPanel />)
    // A label sornak "Beszélgetés" szovegnek kell lennie - NEM "(unified)" formaban
    expect(screen.queryByText(/\(unified\)/)).not.toBeInTheDocument()
    expect(screen.queryByText('Aktív — unified')).not.toBeInTheDocument()
  })
})
