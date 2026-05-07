export const APP_MODES = ['full', 'penztar', 'ertektar', 'ertekszallito'] as const

export type AppMode = (typeof APP_MODES)[number]

export const CASHIER_APP_MODE: AppMode = 'penztar'

export function isAppMode(value: unknown): value is AppMode {
  return typeof value === 'string' && (APP_MODES as readonly string[]).includes(value)
}
