import { describe, expect, it } from 'vitest'
import type { AppMode } from '../types/appMode'
import { CASHIER_APP_MODE } from '../types/appMode'
import { shouldRequireDailySession } from './MainLayout'

describe('MainLayout daily session gate', () => {
  it('requires day-open session only in cashier app mode', () => {
    const expectations: Array<[AppMode, boolean]> = [
      [CASHIER_APP_MODE, true],
      ['full', false],
      ['ertektar', false],
      ['ertekszallito', false],
    ]

    for (const [appMode, expected] of expectations) {
      expect(shouldRequireDailySession(appMode)).toBe(expected)
    }
  })
})
