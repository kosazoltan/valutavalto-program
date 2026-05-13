/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL?: string
  readonly VITE_GOOGLE_CLIENT_ID?: string
  readonly VITE_WS_URL?: string
  readonly VITE_APP_VERSION?: string
  readonly VITE_APP_FLAVOR?: string
  readonly VITE_DISABLE_GOOGLE_OAUTH?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}

// package.json-ból injektált build idejű konstans (lásd vite.config.ts → define).
// A LoginPage és más UI-komponensek a verzió megjelenítéséhez használják.
declare const __APP_VERSION__: string
