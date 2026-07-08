import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import App from './App'
// Inter font (P2-3, 2026-05-06) — fontsource async betöltés a 4 fő súllyal
import '@fontsource/inter/400.css'
import '@fontsource/inter/500.css'
import '@fontsource/inter/600.css'
import '@fontsource/inter/700.css'
import './index.css'
import ErrorBoundary from './components/ErrorBoundary'
import { CompanyThemeProvider } from './contexts/CompanyThemeContext'
import { appTitleForFlavor } from './utils/appTitle'
import './components/ErrorReporter' // auto-registers global error listeners
import './i18n' // v2.4.0 (F): i18next setup — initReactI18next + hu.json resource
// Polyfill: crypto.randomUUID a NEM secure context-ekre (HTTP non-localhost).
// RFC4122 v4 uuid implementacio fallback-kent, ha a Web Crypto API nem elerheto.
if (!globalThis.crypto || typeof globalThis.crypto.randomUUID !== 'function') {
  const cryptoObj: Crypto = globalThis.crypto ?? ({} as Crypto)
  const fallbackRandomUUID = (): string => {
    if (typeof cryptoObj.getRandomValues === 'function') {
      const bytes = new Uint8Array(16)
      cryptoObj.getRandomValues(bytes)
      bytes[6] = ((bytes[6] ?? 0) & 0x0f) | 0x40
      bytes[8] = ((bytes[8] ?? 0) & 0x3f) | 0x80
      const hex: string[] = []
      for (let i = 0; i < 16; i++) hex.push((bytes[i] ?? 0).toString(16).padStart(2, '0'))
      return [
        hex.slice(0, 4).join(''),
        hex.slice(4, 6).join(''),
        hex.slice(6, 8).join(''),
        hex.slice(8, 10).join(''),
        hex.slice(10).join(''),
      ].join('-')
    }
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = (Math.random() * 16) | 0
      return (c === 'x' ? r : (r & 0x3) | 0x8).toString(16)
    })
  }
  // Explicit cast unknown-on keresztul, mert a template literal type-ok miatt a TS szigorubb
  ;(cryptoObj as unknown as { randomUUID: () => string }).randomUUID = fallbackRandomUUID
  if (!globalThis.crypto) {
    ;(globalThis as unknown as { crypto: Crypto }).crypto = cryptoObj
  }
}
// v2.5.54 #6/#20: az ablak-cím a kliens build-time flavor-ja szerint (a 3 kliens
// elkülönüljön a tálcán/ablakváltón). Az Electron-ablak címe a document.title-t követi.
document.title = appTitleForFlavor(import.meta.env.VITE_APP_FLAVOR)

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      retry: 1,
    },
  },
})

// Remove or hide vite-error-overlay element from DOM
// This ensures it doesn't appear even if it's created by Vite
const removeViteErrorOverlay = () => {
  const overlay = document.querySelector('vite-error-overlay')
  if (overlay) {
    overlay.remove()
  }
}

// Run immediately and also on DOMContentLoaded
removeViteErrorOverlay()
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', removeViteErrorOverlay)
} else {
  removeViteErrorOverlay()
}

// Also use MutationObserver to catch dynamically added overlays
const observer = new MutationObserver(() => {
  removeViteErrorOverlay()
})
observer.observe(document.body || document.documentElement, {
  childList: true,
  subtree: true,
})

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <CompanyThemeProvider>
          <BrowserRouter>
            <App />
          </BrowserRouter>
        </CompanyThemeProvider>
      </QueryClientProvider>
    </ErrorBoundary>
  </React.StrictMode>,
)
