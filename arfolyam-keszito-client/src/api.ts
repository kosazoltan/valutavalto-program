import type {
  LocalRateMakerBootstrap,
  LocalRatePackage,
  LocalRatePublishResponse,
} from './types.js'

export interface RateMakerApiConfig {
  serverBaseUrl: string
  accessToken: string
}

function normalizeBaseUrl(serverBaseUrl: string): string {
  const trimmed = serverBaseUrl.trim().replace(/\/$/, '')
  return trimmed.endsWith('/api/v1') ? trimmed : `${trimmed}/api/v1`
}

async function request<T>(
  config: RateMakerApiConfig,
  method: 'GET' | 'POST',
  path: string,
  body?: unknown,
  idempotencyKey?: string,
): Promise<T> {
  const headers: Record<string, string> = {
    Authorization: `Bearer ${config.accessToken}`,
    Accept: 'application/json',
  }
  if (body !== undefined) {
    headers['Content-Type'] = 'application/json'
  }
  if (idempotencyKey) {
    headers['Idempotency-Key'] = idempotencyKey
  }

  const response = await fetch(`${normalizeBaseUrl(config.serverBaseUrl)}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  })

  const text = await response.text()
  const data = text ? (JSON.parse(text) as unknown) : null
  if (!response.ok) {
    const message =
      data && typeof data === 'object' && 'message' in data
        ? String((data as { message?: unknown }).message)
        : `HTTP ${response.status}`
    throw new Error(message)
  }
  return data as T
}

export function fetchBootstrap(config: RateMakerApiConfig): Promise<LocalRateMakerBootstrap> {
  return request<LocalRateMakerBootstrap>(config, 'GET', '/local-rate-maker/bootstrap')
}

export function publishRatePackage(
  config: RateMakerApiConfig,
  ratePackage: LocalRatePackage,
  idempotencyKey = ratePackage.clientPackageId,
): Promise<LocalRatePublishResponse> {
  return request<LocalRatePublishResponse>(
    config,
    'POST',
    '/local-rate-maker/packages/publish',
    ratePackage,
    idempotencyKey,
  )
}
