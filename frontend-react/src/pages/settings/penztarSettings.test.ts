import { describe, it, expect, beforeEach } from 'vitest'
import {
  loadPenztarSettings,
  savePenztarSettings,
  normalize,
  isValidOctet,
  isValidServerIp,
  clampFrequency,
  DEFAULT_PENZTAR_SETTINGS,
} from './penztarSettings'

describe('penztarSettings (G20)', () => {
  beforeEach(() => localStorage.clear())

  it('isValidOctet: 0–255 egész', () => {
    expect(isValidOctet(0)).toBe(true)
    expect(isValidOctet(255)).toBe(true)
    expect(isValidOctet(256)).toBe(false)
    expect(isValidOctet(-1)).toBe(false)
    expect(isValidOctet(1.5)).toBe(false)
  })

  it('isValidServerIp: mind a 4 oktett 0–255', () => {
    expect(isValidServerIp([192, 168, 1, 10])).toBe(true)
    expect(isValidServerIp([192, 168, 1, 256])).toBe(false)
    expect(isValidServerIp([1, 2, 3])).toBe(false)
  })

  it('clampFrequency: 0–25 tartomány + kerekítés', () => {
    expect(clampFrequency(2)).toBe(2)
    expect(clampFrequency(30)).toBe(25)
    expect(clampFrequency(-5)).toBe(0)
    expect(clampFrequency(2.6)).toBe(3)
    expect(clampFrequency(NaN)).toBe(DEFAULT_PENZTAR_SETTINGS.dataSendFrequencyMin)
  })

  it('loadPenztarSettings: üres tárolásnál default', () => {
    expect(loadPenztarSettings()).toEqual(DEFAULT_PENZTAR_SETTINGS)
  })

  it('save → load körút (perzisztencia, FR AC)', () => {
    const s = {
      ...DEFAULT_PENZTAR_SETTINGS,
      machineRole: 'ERTEKTARI' as const,
      displayColor: 'ZOLD' as const,
      dataSendFrequencyMin: 5,
    }
    savePenztarSettings(s)
    const loaded = loadPenztarSettings()
    expect(loaded.machineRole).toBe('ERTEKTARI')
    expect(loaded.displayColor).toBe('ZOLD')
    expect(loaded.dataSendFrequencyMin).toBe(5)
  })

  it('normalize: tartományon kívüli gyakoriság szorítva, hibás oktett 0', () => {
    const n = normalize({ dataSendFrequencyMin: 99, serverIp: [192, 999, 1, 1] })
    expect(n.dataSendFrequencyMin).toBe(25)
    expect(n.serverIp).toEqual([192, 0, 1, 1])
  })

  it('loadPenztarSettings: sérült JSON → default (nem dob)', () => {
    localStorage.setItem('penztar-settings', '{nem-json')
    expect(loadPenztarSettings()).toEqual(DEFAULT_PENZTAR_SETTINGS)
  })

  it('normalize: hiányzó mezők default-ra állnak', () => {
    const n = normalize({ machineRole: 'AFAS' })
    expect(n.machineRole).toBe('AFAS')
    expect(n.applications).toEqual(DEFAULT_PENZTAR_SETTINGS.applications)
    expect(n.printerPort).toBe(DEFAULT_PENZTAR_SETTINGS.printerPort)
  })

  it('normalize: érvénytelen union-érték → default (Copilot #790)', () => {
    const n = normalize({
      machineRole: 'HACKER' as never,
      displayColor: 'KEK' as never,
      printerPort: 'COM7' as never,
      handlingFeeMode: 'XYZ' as never,
    })
    expect(n.machineRole).toBe(DEFAULT_PENZTAR_SETTINGS.machineRole)
    expect(n.displayColor).toBe(DEFAULT_PENZTAR_SETTINGS.displayColor)
    expect(n.printerPort).toBe(DEFAULT_PENZTAR_SETTINGS.printerPort)
    expect(n.handlingFeeMode).toBe(DEFAULT_PENZTAR_SETTINGS.handlingFeeMode)
  })

  it('savePenztarSettings: sikeres mentésnél true', () => {
    expect(savePenztarSettings(DEFAULT_PENZTAR_SETTINGS)).toBe(true)
  })

  it('printer mezők (SP500): default üres string, normalize átengedi a stringet', () => {
    expect(DEFAULT_PENZTAR_SETTINGS.printerDeviceName).toBe('')
    expect(DEFAULT_PENZTAR_SETTINGS.printerSerialPort).toBe('')
    const n = normalize({ printerDeviceName: 'Star SP500', printerSerialPort: 'COM3' })
    expect(n.printerDeviceName).toBe('Star SP500')
    expect(n.printerSerialPort).toBe('COM3')
  })

  it('printer mezők: nem-string érték → default (üres)', () => {
    const n = normalize({
      printerDeviceName: 42 as never,
      printerSerialPort: { com: 3 } as never,
    })
    expect(n.printerDeviceName).toBe('')
    expect(n.printerSerialPort).toBe('')
  })

  it('printer mezők túlélik a save → load körutat', () => {
    savePenztarSettings({
      ...DEFAULT_PENZTAR_SETTINGS,
      printerDeviceName: 'Star SP500',
      printerSerialPort: 'COM3',
    })
    const loaded = loadPenztarSettings()
    expect(loaded.printerDeviceName).toBe('Star SP500')
    expect(loaded.printerSerialPort).toBe('COM3')
  })
})
