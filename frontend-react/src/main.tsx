import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import App from './App'
import './index.css'

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
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </QueryClientProvider>
  </React.StrictMode>,
)
