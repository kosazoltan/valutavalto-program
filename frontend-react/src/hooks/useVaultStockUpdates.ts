import { useEffect, useRef } from 'react'
import { Client, type IStompSocket } from '@stomp/stompjs'
import SockJS from 'sockjs-client'
import { useAuthStore } from '../stores/authStore'

/**
 * A WebSocket STOMP endpoint URL feloldása (azonos logika a useRateUpdates-szel):
 * VITE_WS_URL → VITE_API_URL `/ws` → window.location `/ws`.
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
 * FR-3 (2026-06-17): "Értéktári készlet" auto-frissítés.
 *
 * Feliratkozik a `/topic/vault-stock/{companyId}` STOMP topicra. Valahányszor egy átadás-átvétel
 * COMPLETED esemény módosítja a cég vault `currency_stock` egyenlegét (a backend
 * `VaultStockFlowService` afterCommit publikál), meghívja az `onInvalidate` callbacket.
 *
 * A hívó feladata a tényleges (territory-scope-olt) re-fetch + change-detection — így "más
 * iroda/értéktár" mozgása, ami a hívó scope-olt nézetét nem változtatja, nem okoz látható frissítést.
 *
 * Reconnect-et a STOMP kliens kezeli (5 mp). Hiba esetén csendben újrapróbál (NFR-5: silent fail).
 * Működik böngészőben és Electronban is.
 */
export function useVaultStockUpdates(onInvalidate: () => void): void {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const companyId = useAuthStore((s) => s.worker?.companyId ?? null)
  const token = useAuthStore((s) => s.token)

  // Stabil callback-referencia, hogy a STOMP kliens ne épüljön újra minden render-nél.
  const callbackRef = useRef(onInvalidate)
  callbackRef.current = onInvalidate

  useEffect(() => {
    if (!isAuthenticated || !companyId) {
      return
    }

    const endpoint = resolveWsEndpoint()
    const stompClient = new Client({
      webSocketFactory: () => new SockJS(endpoint) as IStompSocket,
      reconnectDelay: 5000,
      connectHeaders: token ? { Authorization: `Bearer ${token}` } : undefined,
      onConnect: () => {
        stompClient.subscribe(`/topic/vault-stock/${companyId}`, () => {
          try {
            callbackRef.current()
          } catch {
            // Ne dőljön el a kliens egy callback-hibától.
          }
        })
      },
      onStompError: (_frame) => {
        // Reconnect a reconnectDelay-jel.
      },
      onWebSocketError: (_event) => {
        // Reconnect a reconnectDelay-jel.
      },
    })

    stompClient.activate()

    return () => {
      void stompClient.deactivate()
    }
  }, [isAuthenticated, companyId, token])
}
