/**
 * G20 (EXCMD b6-beallitasok): pénztárgép lokális beállítások — tipizált modell,
 * localStorage-perzisztencia és validáció.
 *
 * Pure, izoláltan tesztelhető (penztarSettings.test.ts). A tényleges hardver-kötés
 * (szkenner-driver, nyomtató-port, futófény COM, IP-kapcsolat) runtime-feladat az
 * Electron main folyamatban — itt csak a kiválasztott értékek perzisztálódnak
 * (a spec AC-je: "az érték perzisztens 'Rögzítés és kilépés' után").
 */

export type MachineRole = 'PENZTARI' | 'ERTEKTARI' | 'AFAS'
export type DisplayColor = 'ZOLD' | 'SARGA' | 'PIROS'
export type PrinterPort = 'LPT1' | 'USB'
export type HandlingFeeMode = 'NINCS' | 'EZRELEKES' | 'SAVOS'
export type FutofenyMode = 'ARFOLYAM' | 'SZOVEG' | 'VALTAKOZO'

export interface PenztarSettings {
  machineRole: MachineRole                 // FR-02
  applications: string[]                   // FR-03 (VALUTAVALTAS, WESTERN_UNION, ...)
  displayColor: DisplayColor               // FR-04
  serverIp: [number, number, number, number] // FR-05
  dailyReportEmail: string                 // FR-06
  saturdayOpen: boolean                    // FR-06
  dataSendFrequencyMin: number             // FR-07 (0–25)
  printerPort: PrinterPort                 // FR-08
  scannerDriver: string                    // FR-09 (driver neve)
  handlingFeeMode: HandlingFeeMode         // FR-10
  cardPaymentEnabled: boolean              // FR-12
  adOnDisplay: boolean                     // FR-13
}

export const FREQUENCY_MIN = 0
export const FREQUENCY_MAX = 25

export const DEFAULT_PENZTAR_SETTINGS: PenztarSettings = {
  machineRole: 'PENZTARI',
  applications: ['VALUTAVALTAS'],
  displayColor: 'PIROS',
  serverIp: [0, 0, 0, 0],
  dailyReportEmail: '',
  saturdayOpen: false,
  dataSendFrequencyMin: 2,
  printerPort: 'LPT1',
  scannerDriver: '',
  handlingFeeMode: 'EZRELEKES',
  cardPaymentEnabled: false,
  adOnDisplay: false,
}

const STORAGE_KEY = 'penztar-settings'

/** IP-oktett érvényes-e (0–255 egész). */
export function isValidOctet(value: number): boolean {
  return Number.isInteger(value) && value >= 0 && value <= 255
}

/** Adatküldés-gyakoriság a skálatartományba szorítva (0–25). */
export function clampFrequency(value: number): number {
  if (!Number.isFinite(value)) return DEFAULT_PENZTAR_SETTINGS.dataSendFrequencyMin
  return Math.min(FREQUENCY_MAX, Math.max(FREQUENCY_MIN, Math.round(value)))
}

/** A teljes szerver-IP érvényes-e (mind a 4 oktett 0–255). */
export function isValidServerIp(ip: number[]): boolean {
  return Array.isArray(ip) && ip.length === 4 && ip.every(isValidOctet)
}

/**
 * Beállítások betöltése localStorage-ból; hiányzó/hibás mezőkre a default érték.
 * Sosem dob — sérült tárolásnál a teljes default tér vissza.
 */
export function loadPenztarSettings(): PenztarSettings {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return { ...DEFAULT_PENZTAR_SETTINGS }
    const parsed = JSON.parse(raw) as Partial<PenztarSettings>
    return normalize(parsed)
  } catch {
    return { ...DEFAULT_PENZTAR_SETTINGS }
  }
}

/** Beállítások mentése (normalizálva + validálva). */
export function savePenztarSettings(settings: PenztarSettings): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(normalize(settings)))
}

/** Hiányzó mezők kitöltése default-tal + tartomány-szorítás. */
export function normalize(s: Partial<PenztarSettings>): PenztarSettings {
  const d = DEFAULT_PENZTAR_SETTINGS
  const ip = Array.isArray(s.serverIp) && s.serverIp.length === 4
    ? (s.serverIp.map((o) => (isValidOctet(o as number) ? o : 0)) as [number, number, number, number])
    : [...d.serverIp] as [number, number, number, number]
  return {
    machineRole: s.machineRole ?? d.machineRole,
    applications: Array.isArray(s.applications) ? s.applications : [...d.applications],
    displayColor: s.displayColor ?? d.displayColor,
    serverIp: ip,
    dailyReportEmail: typeof s.dailyReportEmail === 'string' ? s.dailyReportEmail : d.dailyReportEmail,
    saturdayOpen: typeof s.saturdayOpen === 'boolean' ? s.saturdayOpen : d.saturdayOpen,
    dataSendFrequencyMin: clampFrequency(s.dataSendFrequencyMin ?? d.dataSendFrequencyMin),
    printerPort: s.printerPort ?? d.printerPort,
    scannerDriver: typeof s.scannerDriver === 'string' ? s.scannerDriver : d.scannerDriver,
    handlingFeeMode: s.handlingFeeMode ?? d.handlingFeeMode,
    cardPaymentEnabled: typeof s.cardPaymentEnabled === 'boolean' ? s.cardPaymentEnabled : d.cardPaymentEnabled,
    adOnDisplay: typeof s.adOnDisplay === 'boolean' ? s.adOnDisplay : d.adOnDisplay,
  }
}
