import axios, { type AxiosInstance, type InternalAxiosRequestConfig } from 'axios';
import axiosRetry, { exponentialDelay, isNetworkOrIdempotentRequestError } from 'axios-retry';

let API_BASE_URL = import.meta.env.VITE_API_URL;
if (!API_BASE_URL) {
  if (import.meta.env.DEV) {
    API_BASE_URL = 'http://localhost:8080/api/v1';
  } else {
    throw new Error('VITE_API_URL environment variable is not set!');
  }
}

let authToken: string | null = null;

const IDEMPOTENT_METHODS = new Set(['post', 'put', 'patch', 'delete']);

function generateIdempotencyKey(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }

  const random = Math.random().toString(36).slice(2, 14);
  return `${Date.now()}-${random}`;
}

export function shouldAttachIdempotencyKey(config: InternalAxiosRequestConfig): boolean {
  const method = (config.method ?? '').toLowerCase();
  return IDEMPOTENT_METHODS.has(method);
}

export function setAuthToken(token: string | null): void {
  authToken = token;
}

export function getAuthToken(): string | null {
  return authToken;
}

/** M1: Token persist — mentés Electron config store-ba */
export async function persistToken(token: string): Promise<void> {
  if (window.electronAPI) {
    await window.electronAPI.setConfig('auth_token', token);
  }
}

/** M1: Token persist — törlés Electron config store-ból */
export async function clearPersistedToken(): Promise<void> {
  if (window.electronAPI) {
    await window.electronAPI.deleteConfig('auth_token');
  }
}

/** M1: Token persist — betöltés Electron config store-ból */
export async function loadPersistedToken(): Promise<string | null> {
  if (window.electronAPI) {
    return window.electronAPI.getConfig('auth_token');
  }
  return null;
}

const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  timeout: 15_000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// M3: Retry logika — 3 próbálkozás exponenciális késleltetéssel
axiosRetry(apiClient, {
  retries: 3,
  retryDelay: exponentialDelay,
  retryCondition: (error) => {
    return isNetworkOrIdempotentRequestError(error) || error.code === 'ECONNABORTED';
  },
});

// JWT interceptor — automatikusan csatolja a tokent minden kéréshez
apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig): InternalAxiosRequestConfig => {
    if (authToken) {
      config.headers.Authorization = `Bearer ${authToken}`;
    }

    if (shouldAttachIdempotencyKey(config) && !config.headers['Idempotency-Key']) {
      config.headers['Idempotency-Key'] = generateIdempotencyKey();
    }

    return config;
  },
);

// Válasz interceptor — 401 → kijelentkezés
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (axios.isAxiosError(error) && error.response?.status === 401) {
      setAuthToken(null);
      // Az authStore-ban kezeljük a redirect-et
      window.dispatchEvent(new CustomEvent('auth:unauthorized'));
    }
    return Promise.reject(error);
  },
);

export default apiClient;
