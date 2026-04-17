import '@testing-library/jest-dom/vitest'
import { afterEach } from 'vitest'
import { cleanup } from '@testing-library/react'

// Build-idejű konstans polyfill a test environment számára.
// A vite.config.ts define-ja csak a tényleges bundle-re érvényes,
// a Vitest pedig ESBuild transform-on keresztül fut, így itt
// explicit setter kell, különben a LoginPage ReferenceError-t dob.
;(globalThis as unknown as { __APP_VERSION__: string }).__APP_VERSION__ = 'test'

afterEach(() => {
  cleanup()
})
