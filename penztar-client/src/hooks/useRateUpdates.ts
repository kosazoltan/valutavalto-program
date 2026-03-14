import { useEffect } from 'react';
import { Client, IFrame, IMessage } from '@stomp/stompjs';
import SockJS from 'sockjs-client';
import { useAuthStore } from '@/stores/authStore';
import { useRateStore } from '@/stores/rateStore';

type RateUpdatePayload = {
  workgroupId?: string;
  branchCodes?: string[];
  publishedAt?: string;
  rates?: Array<{
    currencyCode?: string;
    buyRate: number | string;
    sellRate: number | string;
  }>;
};

function resolveWsEndpoint(): string {
  const apiBase = import.meta.env.VITE_API_URL;
  if (apiBase) {
    try {
      const parsed = new URL(apiBase);
      return `${parsed.protocol}//${parsed.host}/ws`;
    } catch {
      // Fall back to same-origin websocket endpoint.
    }
  }

  if (typeof window !== 'undefined') {
    return `${window.location.protocol}//${window.location.host}/ws`;
  }

  return 'http://localhost:8080/ws';
}

export function useRateUpdates(): void {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const branchCode = useAuthStore((s) => s.branchCode);
  const token = useAuthStore((s) => s.token);
  const applyPublishedRates = useRateStore((s) => s.applyPublishedRates);
  const fetchRates = useRateStore((s) => s.fetchRates);

  useEffect(() => {
    if (!isAuthenticated || !branchCode) {
      return;
    }

    const endpoint = resolveWsEndpoint();
    const stompClient = new Client({
      webSocketFactory: () => new SockJS(endpoint),
      reconnectDelay: 5000,
      connectHeaders: token ? { Authorization: `Bearer ${token}` } : undefined,
      onConnect: () => {
        stompClient.subscribe(`/topic/rate-updates/branch/${branchCode}`, (message: IMessage) => {
          try {
            const payload = JSON.parse(message.body) as RateUpdatePayload;
            if (payload.rates?.length) {
              applyPublishedRates(payload.rates);
            }
          } catch {
            // Ignore malformed realtime payload and keep the client running.
          }
        });
      },
      onStompError: (_frame: IFrame) => {
        // Connection retry is handled by reconnectDelay.
      },
      onWebSocketError: (_event: Event) => {
        // Connection retry is handled by reconnectDelay.
      },
    });

    // Always refresh once on connect lifecycle to avoid stale view on reopen/login.
    void fetchRates();
    stompClient.activate();

    return () => {
      stompClient.deactivate();
    };
  }, [isAuthenticated, branchCode, token, applyPublishedRates, fetchRates]);
}
