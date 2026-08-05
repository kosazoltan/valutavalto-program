/**
 * G20 (EXCMD b6-beallitasok): pénztárgép lokális beállítások — tipizált modell,
 * localStorage-perzisztencia és validáció.
 *
 * Pure, izoláltan tesztelhető (penztarSettings.test.ts). A tényleges hardver-kötés
 * (szkenner-driver, nyomtató-port, futófény COM, IP-kapcsolat) runtime-feladat az
 * Electron main folyamatban — itt csak a kiválasztott értékek perzisztálódnak
 * (a spec AC-je: "az érték perzisztens 'Rögzítés és kilépés' után").
 *
 * FR-14: a settings háromrétegű perzisztenciával mentődik:
 *   1. localStorage (gyors lokális cache, offline-safe)
 *   2. Backend PUT /api/v1/machine-config/{workstationCode} (Postgres, multi-tenant)
 *   Electron SQLite: az általános getConfig/setConfig IPC nincs kibővítve (az Electron main
 *   módosítása kockázatos), a backend-perzisztencia + localStorage elegendő.
 *
 * FR-06 jelszó biztonsági eltérés a spectől:
 *   A spec plain-text jelszó megjelenítést ír le ("<JELSZO>"), de a b9 NFR-02 és a
 *   security-standards alapján a jelszót MASZKOLT formában jelenítjük meg (••••).
 *   A backend BCrypt-tel hash-eli — a hash soha nem kerül vissza a GET válaszba,
 *   csak a `dailyReportPasswordSet` boolean jelző.
 *
 * FR-06 branch mezők kezelése:
 *   Az értéktár e-mail és szombati nyitvatartás a Branch entitáson már létezik (V293,
 *   email + closed_saturday). A beállítások oldalon read-only hivatkozással jelennek meg
 *   (a Pénztár Törzsben szerkeszthetők). Kisebb kockázatú döntés: NEM duplikáljuk a
 *   branch-adatot a machine_config JSON-ban — elkerüljük az inkonzisztenciát.
 *
 * FR-11 futófény konfiguráció:
 *   A soros-port vezérlés (COM-port tényleges nyitása, adatküldés) runtime/hardver-feladat
 *   (spec integration_points szerint a COM-vezérlés külön réteg). A panel a KONFIGURÁCIÓT
 *   rögzíti; a COM-kezelés az Electron main folyamatban fog történni.
 */

export type MachineRole = 'PENZTARI' | 'ERTEKTARI' | 'AFAS'
export type DisplayColor = 'ZOLD' | 'SARGA' | 'PIROS'
export type PrinterPort = 'LPT1' | 'USB'
export type HandlingFeeMode = 'NINCS' | 'EZRELEKES' | 'SAVOS'
export type FutofenyMode = 'ARFOLYAM' | 'SZOVEG' | 'VALTAKOZO'

export interface PenztarSettings {
  machineRole: MachineRole // FR-02
  applications: string[] // FR-03 (VALUTAVALTAS, WESTERN_UNION, ...)
  displayColor: DisplayColor // FR-04
  serverIp: [number, number, number, number] // FR-05
  dailyReportEmail: string // FR-06 (értéktár e-mail — branch adat olvasásához)
  saturdayOpen: boolean // FR-06 (szombati nyitvatartás — branch adat)
  dataSendFrequencyMin: number // FR-07 (0–25)
  printerPort: PrinterPort // FR-08
  scannerDriver: string // FR-09 (driver neve)
  handlingFeeMode: HandlingFeeMode // FR-10
  // FR-11: Futófény beállítások (soros-port vezérlés runtime-feladat, ez csak konfig)
  futofenyDarab: number // hány futófénytábla van
  futofenyCom1: number // első tábla COM-portja
  futofenyCom2: number // második tábla COM-portja
  futofenyMod: FutofenyMode // megjelenítési mód
  futofenyKikapcsolva: boolean // futófény ki/be kapcsolva
  futofenySebesseg: number // 1–10 sebesség-skála
  cardPaymentEnabled: boolean // FR-12
  adOnDisplay: boolean // FR-13
  // SP500 blokknyomtató: az Electron SQLite printer.deviceName / printer.serialPort
  // operatív kulcsok tükre a háromrétegű perzisztenciában; üres string = nincs beállítva.
  printerDeviceName: string
  printerSerialPort: string
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
  // FR-11 futófény defaults (spec szerinti alapértékek)
  futofenyDarab: 0,
  futofenyCom1: 1,
  futofenyCom2: 2,
  futofenyMod: 'ARFOLYAM',
  futofenyKikapcsolva: false,
  futofenySebesseg: 5,
  cardPaymentEnabled: false,
  adOnDisplay: false,
  printerDeviceName: '',
  printerSerialPort: '',
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

/**
 * Beállítások mentése (normalizálva + validálva).
 * @returns true, ha a mentés sikerült; false, ha a localStorage írás meghiúsult
 *          (private mode / quota) — Copilot #790: a save NEM dob, a hívó kezeli.
 */
export function savePenztarSettings(settings: PenztarSettings): boolean {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(normalize(settings)))
    return true
  } catch {
    return false
  }
}

/** Union-érték validálás: ha nincs a megengedettek között, a default. */
function oneOf<T extends string>(value: unknown, allowed: readonly T[], fallback: T): T {
  return allowed.includes(value as T) ? (value as T) : fallback
}

const MACHINE_ROLES: readonly MachineRole[] = ['PENZTARI', 'ERTEKTARI', 'AFAS']
const DISPLAY_COLORS: readonly DisplayColor[] = ['ZOLD', 'SARGA', 'PIROS']
const PRINTER_PORTS: readonly PrinterPort[] = ['LPT1', 'USB']
const HANDLING_FEE_MODES: readonly HandlingFeeMode[] = ['NINCS', 'EZRELEKES', 'SAVOS']
const FUTOFENY_MODES: readonly FutofenyMode[] = ['ARFOLYAM', 'SZOVEG', 'VALTAKOZO']

/** COM-port szám érvényes-e (1–255 egész). */
export function isValidComPort(v: unknown): boolean {
  return typeof v === 'number' && Number.isInteger(v) && v >= 1 && v <= 255
}

/** COM-port érték 1–255 közé szorítva (NaN esetén 1). */
export function clampComPort(v: unknown, fallback = 1): number {
  const n = Number(v)
  if (!Number.isFinite(n)) return fallback
  return Math.min(255, Math.max(1, Math.round(n)))
}

/** Futófény sebesség 1–10 közé szorítva. */
export function clampFutofenySebesseg(v: unknown): number {
  const n = Number(v)
  if (!Number.isFinite(n)) return DEFAULT_PENZTAR_SETTINGS.futofenySebesseg
  return Math.min(10, Math.max(1, Math.round(n)))
}

/** Futófénytáblák száma 0–10 közé szorítva. */
export function clampFutofenyDarab(v: unknown): number {
  const n = Number(v)
  if (!Number.isFinite(n)) return DEFAULT_PENZTAR_SETTINGS.futofenyDarab
  return Math.min(10, Math.max(0, Math.round(n)))
}

/** Hiányzó mezők kitöltése default-tal + tartomány-/union-validáció. */
export function normalize(s: Partial<PenztarSettings>): PenztarSettings {
  const d = DEFAULT_PENZTAR_SETTINGS
  const ip =
    Array.isArray(s.serverIp) && s.serverIp.length === 4
      ? (s.serverIp.map((o) => (isValidOctet(o as number) ? o : 0)) as [
          number,
          number,
          number,
          number,
        ])
      : ([...d.serverIp] as [number, number, number, number])
  return {
    machineRole: oneOf(s.machineRole, MACHINE_ROLES, d.machineRole),
    applications: Array.isArray(s.applications)
      ? s.applications.filter((a) => typeof a === 'string')
      : [...d.applications],
    displayColor: oneOf(s.displayColor, DISPLAY_COLORS, d.displayColor),
    serverIp: ip,
    dailyReportEmail:
      typeof s.dailyReportEmail === 'string' ? s.dailyReportEmail : d.dailyReportEmail,
    saturdayOpen: typeof s.saturdayOpen === 'boolean' ? s.saturdayOpen : d.saturdayOpen,
    dataSendFrequencyMin: clampFrequency(s.dataSendFrequencyMin ?? d.dataSendFrequencyMin),
    printerPort: oneOf(s.printerPort, PRINTER_PORTS, d.printerPort),
    scannerDriver: typeof s.scannerDriver === 'string' ? s.scannerDriver : d.scannerDriver,
    handlingFeeMode: oneOf(s.handlingFeeMode, HANDLING_FEE_MODES, d.handlingFeeMode),
    // FR-11 futófény mezők
    futofenyDarab: clampFutofenyDarab(s.futofenyDarab ?? d.futofenyDarab),
    futofenyCom1: isValidComPort(s.futofenyCom1) ? (s.futofenyCom1 as number) : d.futofenyCom1,
    futofenyCom2: isValidComPort(s.futofenyCom2) ? (s.futofenyCom2 as number) : d.futofenyCom2,
    futofenyMod: oneOf(s.futofenyMod, FUTOFENY_MODES, d.futofenyMod),
    futofenyKikapcsolva:
      typeof s.futofenyKikapcsolva === 'boolean' ? s.futofenyKikapcsolva : d.futofenyKikapcsolva,
    futofenySebesseg: clampFutofenySebesseg(s.futofenySebesseg ?? d.futofenySebesseg),
    cardPaymentEnabled:
      typeof s.cardPaymentEnabled === 'boolean' ? s.cardPaymentEnabled : d.cardPaymentEnabled,
    adOnDisplay: typeof s.adOnDisplay === 'boolean' ? s.adOnDisplay : d.adOnDisplay,
    printerDeviceName:
      typeof s.printerDeviceName === 'string' ? s.printerDeviceName : d.printerDeviceName,
    printerSerialPort:
      typeof s.printerSerialPort === 'string' ? s.printerSerialPort : d.printerSerialPort,
  }
}
