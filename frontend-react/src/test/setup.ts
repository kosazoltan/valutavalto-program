import '@testing-library/jest-dom/vitest'
import { afterEach, vi } from 'vitest'
import { cleanup } from '@testing-library/react'
import huJson from '../i18n/hu.json'

// i18n mock — t('ns.key') returns the Hungarian text from hu.json
const flatKeys: Record<string, string> = {}
for (const [ns, entries] of Object.entries(huJson)) {
  for (const [key, value] of Object.entries(entries as Record<string, string>)) {
    flatKeys[`${ns}.${key}`] = value
  }
}

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => flatKeys[key] ?? key,
    i18n: { language: 'hu', changeLanguage: vi.fn() },
  }),
  Trans: ({ children }: { children: React.ReactNode }) => children,
  initReactI18next: { type: '3rdParty', init: vi.fn() },
}))

// Build-idejű konstans polyfill a test environment számára.
// A vite.config.ts define-ja csak a tényleges bundle-re érvényes,
// a Vitest pedig ESBuild transform-on keresztül fut, így itt
// explicit setter kell, különben a LoginPage ReferenceError-t dob.
;(globalThis as unknown as { __APP_VERSION__: string }).__APP_VERSION__ = 'test'

afterEach(() => {
  cleanup()
})
