import { AxiosError } from 'axios'
import { describe, expect, it } from 'vitest'
import { classifyPublishFailure, resolveDispatchSyncDecision } from './publishFailureClassification'
import type { PublishAllResult } from './publishAllWorkgroups'

const axiosErrorWithStatus = (status: number) => {
  const error = new AxiosError(`Request failed with status code ${status}`)
  error.response = {
    status,
    data: { message: 'spread-gate' },
  } as AxiosError['response']
  return error
}

const networkError = () => {
  const error = new AxiosError('Network Error')
  error.code = 'ERR_NETWORK'
  return error
}

const timeoutError = () => {
  const error = new AxiosError('timeout of 15000ms exceeded')
  error.code = 'ECONNABORTED'
  return error
}

const result = (overrides: Partial<PublishAllResult>): PublishAllResult => ({
  total: 0,
  published: 0,
  outcomes: [],
  ...overrides,
})

describe('classifyPublishFailure — FK09 4xx/üzleti vs transport kontrakt', () => {
  it('4xx (400/403/409/422) → business', () => {
    for (const status of [400, 403, 409, 422]) {
      expect(classifyPublishFailure(axiosErrorWithStatus(status))).toBe('business')
    }
  })

  it('5xx → transport', () => {
    expect(classifyPublishFailure(axiosErrorWithStatus(500))).toBe('transport')
    expect(classifyPublishFailure(axiosErrorWithStatus(503))).toBe('transport')
  })

  it('network error / timeout (nincs response) → transport', () => {
    expect(classifyPublishFailure(networkError())).toBe('transport')
    expect(classifyPublishFailure(timeoutError())).toBe('transport')
  })

  it('nem-axios hiba (helyi validáció / kód-hiba) → business (fail-safe online)', () => {
    expect(classifyPublishFailure(new Error('képlet-divergencia'))).toBe('business')
    expect(classifyPublishFailure('valami')).toBe('business')
  })
})

describe('resolveDispatchSyncDecision — aggregált döntés', () => {
  const failed = (failureKind?: 'business' | 'transport') => ({
    groupId: 'g',
    code: 'WG',
    name: 'csoport',
    status: 'failed' as const,
    failureKind,
  })

  it('published > 0 → online (részleges siker is)', () => {
    expect(
      resolveDispatchSyncDecision(
        result({ total: 5, published: 3, outcomes: [failed('transport')] }),
      ),
    ).toBe('online')
  })

  it('total === 0 → online', () => {
    expect(resolveDispatchSyncDecision(result({ total: 0 }))).toBe('online')
  })

  it('0 siker, minden hiba business → online', () => {
    expect(
      resolveDispatchSyncDecision(
        result({ total: 2, outcomes: [failed('business'), failed('business')] }),
      ),
    ).toBe('online')
  })

  it('0 siker, legalább egy transport hiba → offline', () => {
    expect(
      resolveDispatchSyncDecision(
        result({ total: 2, outcomes: [failed('business'), failed('transport')] }),
      ),
    ).toBe('offline')
  })

  it('0 siker, failureKind nélküli legacy failed outcome → offline', () => {
    expect(resolveDispatchSyncDecision(result({ total: 1, outcomes: [failed()] }))).toBe('offline')
  })
})
