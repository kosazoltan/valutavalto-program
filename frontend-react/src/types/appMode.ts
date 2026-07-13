// 2026-07-13: az 'ertekszallito' önálló appMode kivezetve. Az isAppMode guard
// a régi telepítések tárolt app_mode-ját elutasítja, így useAppMode penztar módra esik vissza.
export const APP_MODES = ['full', 'penztar', 'ertektar', 'rate-maker'] as const

export type AppMode = (typeof APP_MODES)[number]

export type ElectronAppMode = Exclude<AppMode, 'full'>

export const CASHIER_APP_MODE: ElectronAppMode = 'penztar'

export function isAppMode(value: unknown): value is AppMode {
  return typeof value === 'string' && (APP_MODES as readonly string[]).includes(value)
}
