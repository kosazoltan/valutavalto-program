import { useEffect } from 'react'
// NOTE: @stomp/stompjs and sockjs-client must be installed:
//   npm install @stomp/stompjs sockjs-client
//   npm install --save-dev @types/sockjs-client
import { Client, type IStompSocket } from '@stomp/stompjs'
import SockJS from 'sockjs-client'
import { useAuthStore } from '../stores/authStore'
import { useRateStore } from '../stores/rateStore'
import type { RateUpdateEntry } from '../stores/rateStore'

type RateUpdatePayload = {
  workgroupId?: string
  branchCodes?: string[]
  publishedAt?: string
  rates?: RateUpdateEntry[]
}

/**
 * A WebSocket STOMP endpoint URL feloldása.
 * - Ha VITE_API_URL meg van adva, az alapján számolja ki a /ws útvonalat.
 * - Electron-ban (isElectron()) ugyanaz a logika, a lokális szerverre mutat.
 * - Browser dev: window.location alapján.
 */
function resolveWsEndpoint(): string {
  const explicitWsUrl = import.meta.env.VITE_WS_URL as string | undefined
  if (explicitWsUrl?.trim()) {
    return explicitWsUrl
  }

  const apiBase = import.meta.env.VITE_API_URL as string | undefined
  if (apiBase) {
    try {
      const parsed = new URL(apiBase)
      return `${parsed.protocol}//${parsed.host}/ws`
    } catch {
      // Fall back to same-origin websocket endpoint.
    }
  }

  if (typeof window !== 'undefined') {
    return `${window.location.protocol}//${window.location.host}/ws`
  }

  return '/ws'
}

/**
 * Árfolyam WebSocket STOMP feliratkozás.
 *
 * Automatikusan feliratkozik a `/topic/rate-updates/branch/{branchCode}` topicra
 * amint a felhasználó be van jelentkezve. Reconnect-et a STOMP kliens kezeli
 * (5 mp-enként újrapróbálkozik). Disconnect a komponens unmountkor automatikusan
 * megtörténik.
 *
 * Működik böngészőben és Electron-ban egyaránt — az endpoint feloldása
 * a VITE_API_URL env var alapján, vagy window.location alapján történik.
 *
 * Szükséges npm csomagok (ha még nincsenek telepítve):
 *   npm install @stomp/stompjs sockjs-client
 *   npm install --save-dev @types/sockjs-client
 */
export function useRateUpdates(): void {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const branchCode = useAuthStore((s) => s.worker?.branchCode ?? null)
  const token = useAuthStore((s) => s.token)
  const applyPublishedRates = useRateStore((s) => s.applyPublishedRates)
  const fetchRates = useRateStore((s) => s.fetchRates)

  useEffect(() => {
    if (!isAuthenticated || !branchCode) {
      return
    }

    const endpoint = resolveWsEndpoint()
    const stompClient = new Client({
      webSocketFactory: () => new SockJS(endpoint) as IStompSocket,
      reconnectDelay: 5000,
      connectHeaders: token ? { Authorization: `Bearer ${token}` } : undefined,
      onConnect: () => {
        stompClient.subscribe(`/topic/rate-updates/branch/${branchCode}`, (message) => {
          try {
            const payload = JSON.parse(message.body) as RateUpdatePayload
            if (payload.rates?.length) {
              applyPublishedRates(payload.rates)
            }
          } catch {
            // Ignore malformed realtime payload and keep the client running.
          }
        })
      },
      onStompError: (_frame) => {
        // Connection retry is handled by reconnectDelay.
      },
      onWebSocketError: (_event) => {
        // Connection retry is handled by reconnectDelay.
      },
    })

    // Always refresh once on connect lifecycle to avoid stale view on reopen/login.
    void fetchRates()
    stompClient.activate()

    return () => {
      void stompClient.deactivate()
    }
  }, [isAuthenticated, branchCode, token, applyPublishedRates, fetchRates])
}
