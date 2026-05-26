import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import {
  getAppFlavor,
  isElectronClient,
  isLocalTerminalClient,
  isCentralWorkstationFlavor,
  isRateMakerFlavor,
  flavorDefaultAppMode,
} from './clientEnv'

function setFlavor(value: string | undefined) {
  vi.stubEnv('VITE_APP_FLAVOR', value as string)
}

describe('clientEnv', () => {
  const originalWindow = globalThis.window

  beforeEach(() => {
    vi.unstubAllEnvs()
  })

  afterEach(() => {
    vi.unstubAllEnvs()
    // window visszaállítása, ha a teszt módosította
    if (originalWindow) {
      ;(globalThis as { window?: unknown }).window = originalWindow
    }
  })

  describe('getAppFlavor', () => {
    it('üres flavor → ""', () => {
      setFlavor('')
      expect(getAppFlavor()).toBe('')
    })

    it('undefined flavor → ""', () => {
      setFlavor(undefined)
      expect(getAppFlavor()).toBe('')
    })

    it('körülvágja a whitespace-t', () => {
      setFlavor('  central-workstation  ')
      expect(getAppFlavor()).toBe('central-workstation')
    })

    it('ismeretlen flavor → "" (defenzív)', () => {
      setFlavor('valami-mas')
      expect(getAppFlavor()).toBe('')
    })

    it('rate-maker felismerése', () => {
      setFlavor('rate-maker')
      expect(getAppFlavor()).toBe('rate-maker')
    })
  })

  describe('isElectronClient', () => {
    it('igaz, ha window.electronAPI létezik', () => {
      ;(window as unknown as { electronAPI: unknown }).electronAPI = {}
      expect(isElectronClient()).toBe(true)
    })

    it('hamis, ha window.electronAPI nincs', () => {
      ;(window as unknown as { electronAPI?: unknown }).electronAPI = undefined
      expect(isElectronClient()).toBe(false)
    })
  })

  describe('isLocalTerminalClient', () => {
    it('Electron + üres flavor → igaz', () => {
      setFlavor('')
      ;(window as unknown as { electronAPI: unknown }).electronAPI = {}
      expect(isLocalTerminalClient()).toBe(true)
    })

    it('Electron + central-workstation flavor → hamis', () => {
      setFlavor('central-workstation')
      ;(window as unknown as { electronAPI: unknown }).electronAPI = {}
      expect(isLocalTerminalClient()).toBe(false)
    })

    it('nincs Electron (böngésző) → hamis', () => {
      setFlavor('')
      ;(window as unknown as { electronAPI?: unknown }).electronAPI = undefined
      expect(isLocalTerminalClient()).toBe(false)
    })
  })

  describe('flavor predikátumok', () => {
    it('isCentralWorkstationFlavor', () => {
      setFlavor('central-workstation')
      expect(isCentralWorkstationFlavor()).toBe(true)
      expect(isRateMakerFlavor()).toBe(false)
    })

    it('isRateMakerFlavor', () => {
      setFlavor('rate-maker')
      expect(isRateMakerFlavor()).toBe(true)
      expect(isCentralWorkstationFlavor()).toBe(false)
    })
  })

  describe('flavorDefaultAppMode', () => {
    it('central-workstation → full', () => {
      setFlavor('central-workstation')
      expect(flavorDefaultAppMode()).toBe('full')
    })

    it('rate-maker → rate-maker', () => {
      setFlavor('rate-maker')
      expect(flavorDefaultAppMode()).toBe('rate-maker')
    })

    it('üres flavor → null', () => {
      setFlavor('')
      expect(flavorDefaultAppMode()).toBeNull()
    })
  })
})
