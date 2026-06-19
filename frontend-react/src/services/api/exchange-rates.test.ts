import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('./client', () => ({
  api: {
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
  },
}))

import { api } from './client'
import { exchangeRateApi, exchangeRateDisplayApi, exchangeRatePollingApi, rateApprovalApi, rateCreationApi, roundingRuleApi } from './exchange-rates'

const mockApi = vi.mocked(api)

describe('exchangeRateApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('a GETARF árfolyamfájl előnézetet multipart upload-rate-file végpontra küldi', async () => {
    const parsed = {
      rates: [{ currencyCode: 'EUR', buyRate: 390, sellRate: 399, mnbRate: 394 }],
      parsedAt: '2026-06-18T10:00:00',
      parsedLineCount: 1,
      skippedLineCount: 0,
    }
    const file = new File(['EUR'], 'GETARF.DAT', { type: 'text/plain' })
    mockApi.post.mockResolvedValueOnce({ data: parsed })

    await expect(exchangeRateApi.uploadRateFile(file)).resolves.toBe(parsed)

    expect(mockApi.post).toHaveBeenCalledWith('/exchange-rates/upload-rate-file', expect.any(FormData), {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
    const formData = mockApi.post.mock.calls[0]?.[1] as FormData
    expect(formData.get('file')).toBe(file)
  })

  it('a GETARF árfolyamfájl importot multipart import-rate-file végpontra küldi', async () => {
    const imported = [
      {
        id: 1,
        currencyId: 1,
        currencyCode: 'EUR',
        currencyName: 'Euró',
        validDate: '2026-06-18',
        validTime: '10:00',
        baseBuyRate: 390,
        baseSellRate: 399,
        active: true,
        createdAt: '2026-06-18T10:00:00',
      },
    ]
    const file = new File(['EUR'], 'GETARF.DAT', { type: 'text/plain' })
    mockApi.post.mockResolvedValueOnce({ data: imported })

    await expect(exchangeRateApi.importRateFile(file)).resolves.toBe(imported)

    expect(mockApi.post).toHaveBeenCalledWith('/exchange-rates/import-rate-file', expect.any(FormData), {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
    const formData = mockApi.post.mock.calls[0]?.[1] as FormData
    expect(formData.get('file')).toBe(file)
  })
})

describe('rateCreationApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('a local rate-maker bootstrap dedikalt szervercsatornat hasznalja', async () => {
    const bootstrap = {
      generatedAt: '2026-05-12T10:00:00',
      mode: 'LOCAL_RATE_MAKER',
      publishEndpoint: '/api/v1/local-rate-maker/packages/publish',
      idempotencyRequired: true,
      overview: { generatedAt: '2026-05-12T10:00:00', currencies: [] },
      workgroups: [],
    }
    mockApi.get.mockResolvedValueOnce({ data: bootstrap })

    await expect(rateCreationApi.getLocalRateMakerBootstrap()).resolves.toBe(bootstrap)
    expect(mockApi.get).toHaveBeenCalledWith('/local-rate-maker/bootstrap')
  })

  it('a local rate-maker szerveroldali munkaívet 204 esetén nullként kezeli', async () => {
    mockApi.get.mockResolvedValueOnce({ status: 204, data: '' })

    await expect(rateCreationApi.getLocalRateMakerSheet()).resolves.toBeNull()
    expect(mockApi.get).toHaveBeenCalledWith('/local-rate-maker/sheet', {
      validateStatus: expect.any(Function),
    })
  })

  it('a local rate-maker szerveroldali munkaívet dedikált GET végpontról kéri', async () => {
    const sheet = {
      sheetJson: '{"version":1,"entries":{}}',
      version: 7,
      source: 'rate-maker',
      deviceId: 'device-1',
      updatedBy: 1,
      updatedAt: '2026-06-18T10:00:00',
    }
    mockApi.get.mockResolvedValueOnce({ status: 200, data: sheet })

    await expect(rateCreationApi.getLocalRateMakerSheet()).resolves.toBe(sheet)
    expect(mockApi.get).toHaveBeenCalledWith('/local-rate-maker/sheet', {
      validateStatus: expect.any(Function),
    })
  })

  it('a local rate-maker munkaívet dedikált PUT végpontra tölti fel', async () => {
    const sheet = {
      sheetJson: '{"version":1,"entries":{}}',
      version: 8,
      source: 'rate-maker',
      deviceId: 'device-1',
      updatedBy: 1,
      updatedAt: '2026-06-18T10:01:00',
    }
    mockApi.put.mockResolvedValueOnce({ data: sheet })

    await expect(rateCreationApi.putLocalRateMakerSheet(sheet.sheetJson, {
      source: 'rate-maker',
      deviceId: 'device-1',
      baseVersion: 7,
    })).resolves.toBe(sheet)
    expect(mockApi.put).toHaveBeenCalledWith('/local-rate-maker/sheet', {
      sheetJson: sheet.sheetJson,
      source: 'rate-maker',
      deviceId: 'device-1',
      baseVersion: 7,
    })
  })

  it('a banki árfolyamokat a rate-creation listázó végpontról kéri', async () => {
    const bankRates = [
      {
        id: 'bank-rate-1',
        bankCode: 'EBC',
        bankName: 'EBC',
        currencyCode: 'EUR',
        buyRate: 390.5,
        sellRate: 399.5,
        middleRate: 395,
        validFrom: '2026-06-18T08:00:00',
        source: 'MNB',
      },
    ]
    mockApi.get.mockResolvedValueOnce({ data: bankRates })

    await expect(rateCreationApi.getBankRates()).resolves.toBe(bankRates)
    expect(mockApi.get).toHaveBeenCalledWith('/rate-creation/bank-rates')
  })

  it('a versenytárs árfolyamokat a rate-creation listázó végpontról kéri', async () => {
    const competitorRates = [
      {
        id: 'competitor-rate-1',
        competitorCode: 'RIV',
        competitorName: 'Rivális Change',
        currencyCode: 'EUR',
        buyRate: 391,
        sellRate: 400,
        middleRate: 395.5,
        recordedAt: '2026-06-18T08:05:00',
        source: 'WEBSITE',
      },
    ]
    mockApi.get.mockResolvedValueOnce({ data: competitorRates })

    await expect(rateCreationApi.getCompetitorRates()).resolves.toBe(competitorRates)
    expect(mockApi.get).toHaveBeenCalledWith('/rate-creation/competitor-rates')
  })

  it('az összes árfolyam tervezet generálását a backend POST prepare/all szerződésre köti', async () => {
    const result = {
      generatedCount: 12,
      skippedCount: 1,
      status: 'OK',
    }
    mockApi.post.mockResolvedValueOnce({ data: result })

    await expect(rateCreationApi.prepareAllCurrencies()).resolves.toBe(result)
    expect(mockApi.post).toHaveBeenCalledWith('/rate-creation/prepare/all')
  })
})

describe('rateApprovalApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('az árfolyam módosítási kérelmet a rate-approvals request végpontra küldi', async () => {
    const approval = {
      id: 'approval-1',
      branchId: 'branch-1',
      currencyCode: 'EUR',
      newBuyRate: 392,
      newSellRate: 401,
      status: 'PENDING',
    }
    const request = {
      branchId: 'branch-1',
      currencyCode: 'EUR',
      newBuyRate: 392,
      newSellRate: 401,
      reason: 'Árfolyam módosítási kérelem: EUR',
    }
    mockApi.post.mockResolvedValueOnce({ data: approval })

    await expect(rateApprovalApi.request(request)).resolves.toBe(approval)
    expect(mockApi.post).toHaveBeenCalledWith('/rate-approvals/request', request)
  })
})

describe('exchangeRatePollingApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('a polling státuszt a dedikált backend végpontról kéri', async () => {
    const status = {
      lastPollTime: '2026-06-18T08:00:00',
      lastPollSuccess: true,
      lastPollError: null,
      lastPollUpdatedCount: 12,
      lastPollSource: 'MNB',
    }
    mockApi.get.mockResolvedValueOnce({ data: status })

    await expect(exchangeRatePollingApi.status()).resolves.toBe(status)
    expect(mockApi.get).toHaveBeenCalledWith('/rates/polling/status')
  })

  it('a polling forrásokat a dedikált backend végpontról kéri', async () => {
    const sources = [
      { id: 1, name: 'MNB', active: true, pollIntervalMinutes: 60 },
      { id: 2, name: 'ECB', active: false, pollIntervalMinutes: 1440 },
    ]
    mockApi.get.mockResolvedValueOnce({ data: sources })

    await expect(exchangeRatePollingApi.sources()).resolves.toBe(sources)
    expect(mockApi.get).toHaveBeenCalledWith('/rates/polling/sources')
  })

  it('az ECB snapshotot a dedikált backend végpontról kéri', async () => {
    const ecbRates = {
      USD: 358.2,
      CHF: 412.4,
    }
    mockApi.get.mockResolvedValueOnce({ data: ecbRates })

    await expect(exchangeRatePollingApi.ecbRates()).resolves.toBe(ecbRates)
    expect(mockApi.get).toHaveBeenCalledWith('/rates/polling/ecb')
  })

  it('a kézi polling indítást a dedikált backend végpontra küldi', async () => {
    const result = { message: 'MNB árfolyam polling elindítva' }
    mockApi.post.mockResolvedValueOnce({ data: result })

    await expect(exchangeRatePollingApi.trigger()).resolves.toBe(result)
    expect(mockApi.post).toHaveBeenCalledWith('/rates/polling/trigger')
  })

  it('a margin alkalmazást currencyId és spread payload-dal küldi', async () => {
    const result = { message: 'Margin sikeresen alkalmazva' }
    mockApi.post.mockResolvedValueOnce({ data: result })

    await expect(exchangeRatePollingApi.applyMargins({ currencyId: 1, spread: 2.5 })).resolves.toBe(result)
    expect(mockApi.post).toHaveBeenCalledWith('/rates/polling/apply-margins', { currencyId: 1, spread: 2.5 })
  })

  it('a polling forrás módosítást a forrás azonosítójára küldi', async () => {
    const result = { id: 2, name: 'ECB', active: true, pollIntervalMinutes: 60 }
    mockApi.put.mockResolvedValueOnce({ data: result })

    await expect(exchangeRatePollingApi.updateSource(2, { active: true, pollIntervalMinutes: 60 })).resolves.toBe(result)
    expect(mockApi.put).toHaveBeenCalledWith('/rates/polling/sources/2', { active: true, pollIntervalMinutes: 60 })
  })
})

describe('exchangeRateDisplayApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('a current-rates backend objektum rates tömbjét kijelző előnézeti sorokká alakítja', async () => {
    mockApi.get.mockResolvedValueOnce({
      data: {
        displayId: 'display-1',
        displayName: 'Pénztári kijelző',
        refreshInterval: 30,
        generatedAt: '2026-06-18T10:00:00',
        rates: [
          {
            currencyId: 1,
            currencyCode: 'EUR',
            currencyName: 'Euró',
            baseBuyRate: 390,
            baseSellRate: 402.5,
          },
        ],
      },
    })

    await expect(exchangeRateDisplayApi.getCurrentRates('display-1')).resolves.toEqual([
      {
        currency: 'EUR',
        buyRate: '390.00',
        sellRate: '402.50',
      },
    ])
    expect(mockApi.get).toHaveBeenCalledWith('/exchange-rate-display/display-1/current-rates')
  })
})

describe('roundingRuleApi', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('a kerekítési szabálylistát a dedikált backend végpontról kéri', async () => {
    const rules = [
      {
        id: 1,
        currencyCode: 'EUR',
        precisionValue: 0.01,
        smallThreshold: 100,
        largeThreshold: 10000,
        smallRounding: 'UP',
        largeRounding: 'DOWN',
      },
    ]
    mockApi.get.mockResolvedValueOnce({ data: rules })

    await expect(roundingRuleApi.list()).resolves.toBe(rules)
    expect(mockApi.get).toHaveBeenCalledWith('/rounding-rules')
  })

  it('a devizanem szerinti szabályt amount query paraméterrel kéri', async () => {
    const rule = {
      id: 1,
      currencyCode: 'EUR',
      precisionValue: 0.01,
      smallThreshold: 100,
      largeThreshold: 10000,
      smallRounding: 'UP',
      largeRounding: 'DOWN',
    }
    mockApi.get.mockResolvedValueOnce({ data: rule })

    await expect(roundingRuleApi.getByCurrencyCode('EUR', 123.456)).resolves.toBe(rule)
    expect(mockApi.get).toHaveBeenCalledWith('/rounding-rules/EUR', {
      params: { amount: 123.456 },
    })
  })

  it('a próbakerekítést POST végponton, query paraméterekkel hívja', async () => {
    const result = { original: 123.456, rounded: 123.46 }
    mockApi.post.mockResolvedValueOnce({ data: result })

    await expect(roundingRuleApi.round('EUR', 123.456, 'BUY')).resolves.toBe(result)
    expect(mockApi.post).toHaveBeenCalledWith('/rounding-rules/round', null, {
      params: { currencyCode: 'EUR', amount: 123.456, direction: 'BUY' },
    })
  })
})
