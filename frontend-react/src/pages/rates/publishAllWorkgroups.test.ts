import { AxiosError } from 'axios'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import { publishAllWorkgroups, summarizePublishAll } from './publishAllWorkgroups'
import type { RateOverviewItem, WorkgroupDetailDTO } from '../../services/api/exchange-rates'

/**
 * FK05 (FR-1, FR-2, FR-3, FR-8, NFR-2) — egységes szétküldés: minden aktív munkacsoport
 * publikálódik a publish-group-rate végponton, teljes payloaddal (L/M, J, N–S, limitek);
 * részleges hiba nem állítja le a többi csoportot.
 */

const mocks = vi.hoisted(() => ({
  publishGroupRate: vi.fn(),
  getLocalRateMakerBootstrap: vi.fn(),
  getOverview: vi.fn(),
  getWorkgroupDetails: vi.fn(),
}))

vi.mock('../../services/api/exchange-rates', () => ({
  rateCreationApi: {
    publishGroupRate: mocks.publishGroupRate,
    getLocalRateMakerBootstrap: mocks.getLocalRateMakerBootstrap,
    getOverview: mocks.getOverview,
    getWorkgroupDetails: mocks.getWorkgroupDetails,
  },
}))

const item = (over: Partial<RateOverviewItem> = {}): RateOverviewItem => ({
  currencyId: 1,
  currencyCode: 'EUR',
  currencyName: 'Euró',
  displayOrder: 1,
  currentBuyRate: 390,
  currentSellRate: 400,
  officialRate: 395,
  limit1Amount: 50000,
  limit1BuyRate: 391,
  limit1SellRate: 399,
  limit2Amount: 300000,
  limit2BuyRate: 392,
  limit2SellRate: 398,
  limit3Amount: 1000000,
  limit3BuyRate: 393,
  limit3SellRate: 397,
  buyMarginPercent: null,
  sellMarginPercent: null,
  spreadPercent: null,
  middleRate: null,
  lastUpdated: null,
  hasRate: true,
  ...over,
})

const group = (over: Partial<WorkgroupDetailDTO> = {}): WorkgroupDetailDTO => ({
  id: 'g1',
  code: 'WG1',
  name: '1. csoport',
  legacyGroupNumber: 1,
  active: true,
  branches: [],
  limit1Boundary: 50000,
  limit2Boundary: 300000,
  limit3Boundary: 1000000,
  protectionEnabled: false,
  ...over,
})

describe('publishAllWorkgroups — FK05 egységes szétküldés', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    mocks.publishGroupRate.mockResolvedValue({ acceptedRates: 1 })
  })

  it('FR-2: minden aktív munkacsoport publikálódik (inaktív kimarad), egy hívás/csoport', async () => {
    const result = await publishAllWorkgroups({
      preloaded: {
        overview: [item()],
        workgroups: [
          group({ id: 'g1', code: 'WG1' }),
          group({ id: 'g2', code: 'WG2', name: '2. csoport', legacyGroupNumber: 2 }),
          group({ id: 'g3', code: 'WG3', name: 'inaktív', active: false }),
        ],
      },
    })

    expect(mocks.publishGroupRate).toHaveBeenCalledTimes(2)
    const groupIds = mocks.publishGroupRate.mock.calls
      .map((c) => (c[0] as { groupId: string }).groupId)
      .sort()
    expect(groupIds).toEqual(['g1', 'g2'])
    expect(result.total).toBe(2)
    expect(result.published).toBe(2)
  })

  it('FR-3: a payload a TELJES oszlopkészletet viszi (L/M, J elszámoló, N–S sávok, limit-összegek)', async () => {
    await publishAllWorkgroups({
      preloaded: { overview: [item()], workgroups: [group()] },
    })

    expect(mocks.publishGroupRate.mock.calls[0]![0]).toEqual({
      groupId: 'g1',
      rates: [
        {
          currencyId: 1,
          buyRate: 390,
          sellRate: 400,
          officialRate: 395,
          limit1Amount: 50000,
          limit1BuyRate: 391,
          limit1SellRate: 399,
          limit2Amount: 300000,
          limit2BuyRate: 392,
          limit2SellRate: 398,
          limit3Amount: 1000000,
          limit3BuyRate: 393,
          limit3SellRate: 397,
        },
      ],
    })
  })

  it('NFR-2: egy csoport hibája NEM állítja le a többit — a hiba az eredményben jelenik meg', async () => {
    mocks.publishGroupRate.mockImplementation(({ groupId }: { groupId: string }) =>
      groupId === 'g1'
        ? Promise.reject(new Error('szerver-hiba'))
        : Promise.resolve({ acceptedRates: 1 }),
    )

    const result = await publishAllWorkgroups({
      preloaded: {
        overview: [item()],
        workgroups: [group({ id: 'g1' }), group({ id: 'g2', code: 'WG2', legacyGroupNumber: 2 })],
      },
    })

    expect(mocks.publishGroupRate).toHaveBeenCalledTimes(2)
    expect(result.published).toBe(1)
    const failed = result.outcomes.find((o) => o.groupId === 'g1')
    expect(failed?.status).toBe('failed')
    expect(failed?.message).toContain('szerver-hiba')
    const summary = summarizePublishAll(result)
    expect(summary.ok).toBe(false)
    expect(summary.detail).toContain('1/2 munkacsoport elküldve')
  })

  it('weakMultiSell=0 miatti F képlethiba csak az érintett csoportot blokkolja, a tiszta testvér publikálódik', async () => {
    localStorage.setItem(
      'arfolyamkeszito.mainSheet.v1',
      JSON.stringify([{ currency: 'EUR', weakMultiSell: 0 }]),
    )
    localStorage.setItem(
      'arfolyamkeszito.workgroupSheet.formulas.v1.g1',
      JSON.stringify({ '1.sellRate': 'F' }),
    )

    const result = await publishAllWorkgroups({
      preloaded: {
        overview: [item({ currentSellRate: 400 })],
        workgroups: [
          group({ id: 'g1' }),
          group({ id: 'g2', code: 'WG2', name: '2. csoport', legacyGroupNumber: 2 }),
        ],
      },
    })

    expect(mocks.publishGroupRate).toHaveBeenCalledTimes(1)
    expect(mocks.publishGroupRate).toHaveBeenCalledWith(expect.objectContaining({ groupId: 'g2' }))
    expect(result.published).toBe(1)
    expect(result.outcomes).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          groupId: 'g1',
          status: 'failed',
          failureKind: 'business',
          message: expect.stringContaining('képlet-hiba: Nincs érték a 0-s lap F oszlopában'),
        }),
        expect.objectContaining({ groupId: 'g2', status: 'published' }),
      ]),
    )
  })

  it('csoport-overlay felülírja a szerver-baseline-t (FK02-B tárolt szerkesztés megy ki)', async () => {
    localStorage.setItem(
      'arfolyamkeszito.workgroupSheet.rates.v1.g1',
      JSON.stringify({ '1.buyRate': '385,5' }),
    )

    await publishAllWorkgroups({
      preloaded: { overview: [item()], workgroups: [group()] },
    })

    const sent = mocks.publishGroupRate.mock.calls[0]![0] as { rates: Array<{ buyRate: number }> }
    expect(sent.rates[0]!.buyRate).toBe(385.5)
  })

  it('sikeres publikálás után a csoport overlay-e törlődik (server-authority)', async () => {
    localStorage.setItem(
      'arfolyamkeszito.workgroupSheet.rates.v1.g1',
      JSON.stringify({ '1.buyRate': '385,5' }),
    )

    await publishAllWorkgroups({
      preloaded: { overview: [item()], workgroups: [group()] },
    })

    expect(localStorage.getItem('arfolyamkeszito.workgroupSheet.rates.v1.g1')).toBeNull()
  })

  it('érvényes árfolyam nélküli csoport kihagyva (skipped), nem hívunk publish-t rá', async () => {
    const result = await publishAllWorkgroups({
      preloaded: {
        overview: [item({ currentBuyRate: null, currentSellRate: null, hasRate: false })],
        workgroups: [group()],
      },
    })

    expect(mocks.publishGroupRate).not.toHaveBeenCalled()
    expect(result.outcomes[0]!.status).toBe('skipped')
  })

  it('vétel >= eladás → a csoport hibára fut, a publish nem hívódik rá', async () => {
    const result = await publishAllWorkgroups({
      preloaded: {
        overview: [item({ currentBuyRate: 410, currentSellRate: 400 })],
        workgroups: [group()],
      },
    })

    expect(mocks.publishGroupRate).not.toHaveBeenCalled()
    expect(result.outcomes[0]!.status).toBe('failed')
    expect(result.outcomes[0]!.message).toContain('vétel')
  })

  it('inMemoryGroupRates: az épp nyitott csoport a képernyő-állapotból megy, a többi a tárolt útról', async () => {
    const inMemory = [
      {
        currencyId: 1,
        buyRate: 391.5,
        sellRate: 401.5,
        officialRate: 396,
        limit1Amount: null,
        limit1BuyRate: null,
        limit1SellRate: null,
        limit2Amount: null,
        limit2BuyRate: null,
        limit2SellRate: null,
        limit3Amount: null,
        limit3BuyRate: null,
        limit3SellRate: null,
      },
    ]

    await publishAllWorkgroups({
      inMemoryGroupRates: { groupId: 'g1', rates: inMemory },
      preloaded: {
        overview: [item()],
        workgroups: [group({ id: 'g1' }), group({ id: 'g2', code: 'WG2', legacyGroupNumber: 2 })],
      },
    })

    const byGroup = new Map(
      mocks.publishGroupRate.mock.calls.map((c) => {
        const req = c[0] as { groupId: string; rates: Array<{ buyRate: number }> }
        return [req.groupId, req.rates[0]!.buyRate]
      }),
    )
    expect(byGroup.get('g1')).toBe(391.5)
    expect(byGroup.get('g2')).toBe(390)
  })

  it('Codex P2 #1118: fordított kedvezménysáv-pár (L1 vétel >= eladás) → failed, publish nélkül', async () => {
    const result = await publishAllWorkgroups({
      preloaded: {
        overview: [item({ limit1BuyRate: 399.5, limit1SellRate: 399 })],
        workgroups: [group()],
      },
    })

    expect(mocks.publishGroupRate).not.toHaveBeenCalled()
    expect(result.outcomes[0]!.status).toBe('failed')
    expect(result.outcomes[0]!.message).toContain('L1')
  })

  it('Codex P1 #1118: a #NN kereszt-hivatkozás az épp nyitott csoport FRISS in-memory értékét látja', async () => {
    // g2 képlete az 1-es csoport L oszlopára hivatkozik (#01L) — a perzisztált pillanatkép
    // elavult (380), az in-memory friss érték 391,5: a publikált g2-vétel a frisset követi.
    localStorage.setItem(
      'arfolyamkeszito.workgroupSheet.values.v1',
      JSON.stringify({ '1': { EUR: { L: 380 } } }),
    )
    localStorage.setItem(
      'arfolyamkeszito.workgroupSheet.formulas.v1.g2',
      JSON.stringify({ '1.buyRate': '#01L' }),
    )

    const inMemory = [
      {
        currencyId: 1,
        buyRate: 391.5,
        sellRate: 401.5,
        officialRate: 396,
        limit1Amount: null,
        limit1BuyRate: null,
        limit1SellRate: null,
        limit2Amount: null,
        limit2BuyRate: null,
        limit2SellRate: null,
        limit3Amount: null,
        limit3BuyRate: null,
        limit3SellRate: null,
      },
    ]

    await publishAllWorkgroups({
      inMemoryGroupRates: { groupId: 'g1', rates: inMemory },
      preloaded: {
        overview: [item()],
        workgroups: [
          group({ id: 'g1' }),
          group({ id: 'g2', code: 'WG2', name: '2. csoport', legacyGroupNumber: 2 }),
        ],
      },
    })

    const g2Call = mocks.publishGroupRate.mock.calls
      .map((c) => c[0] as { groupId: string; rates: Array<{ buyRate: number }> })
      .find((req) => req.groupId === 'g2')
    expect(g2Call?.rates[0]!.buyRate).toBe(391.5)
  })

  it('FK-04/E árfolyamvédelem: védett csoportban a J-t sértő ráta → failed, publish nélkül', async () => {
    const result = await publishAllWorkgroups({
      preloaded: {
        // vétel (398) < eladás (400), de a vétel a J (395) FÖLÖTT van → védelem-sértés.
        overview: [item({ currentBuyRate: 398, currentSellRate: 400, officialRate: 395 })],
        workgroups: [group({ protectionEnabled: true })],
      },
    })

    expect(mocks.publishGroupRate).not.toHaveBeenCalled()
    expect(result.outcomes[0]!.status).toBe('failed')
    expect(result.outcomes[0]!.message).toContain('árfolyamvédelem')
  })

  it('preloaded nélkül bootstrap-ból tölt; bootstrap-hiba esetén overview+workgroups fallback', async () => {
    mocks.getLocalRateMakerBootstrap.mockRejectedValue(new Error('régi szerver'))
    mocks.getOverview.mockResolvedValue({ generatedAt: '', currencies: [item()] })
    mocks.getWorkgroupDetails.mockResolvedValue([group()])

    const result = await publishAllWorkgroups()

    expect(mocks.getOverview).toHaveBeenCalledTimes(1)
    expect(mocks.getWorkgroupDetails).toHaveBeenCalledTimes(1)
    expect(result.published).toBe(1)
  })

  it('FK09: 400-as publish-hiba → outcome.failureKind business és backend-üzenet', async () => {
    const error = new AxiosError('Request failed with status code 400')
    error.response = {
      status: 400,
      data: { message: 'Spread-szabály sértés' },
    } as AxiosError['response']
    mocks.publishGroupRate.mockRejectedValue(error)

    const result = await publishAllWorkgroups({
      preloaded: { overview: [item()], workgroups: [group()] },
    })

    expect(result.published).toBe(0)
    expect(result.outcomes[0]!.status).toBe('failed')
    expect(result.outcomes[0]!.failureKind).toBe('business')
    expect(result.outcomes[0]!.message).toBe('Spread-szabály sértés')
  })

  it('FK09: network error publish-hiba → outcome.failureKind transport', async () => {
    const error = new AxiosError('Network Error')
    error.code = 'ERR_NETWORK'
    mocks.publishGroupRate.mockRejectedValue(error)

    const result = await publishAllWorkgroups({
      preloaded: { overview: [item()], workgroups: [group()] },
    })

    expect(result.outcomes[0]!.failureKind).toBe('transport')
  })

  it('FK09: helyi validációs csoport-hiba → outcome.failureKind business', async () => {
    const result = await publishAllWorkgroups({
      preloaded: {
        overview: [item({ currentBuyRate: 405, currentSellRate: 400 })],
        workgroups: [group()],
      },
    })

    expect(result.outcomes[0]!.status).toBe('failed')
    expect(result.outcomes[0]!.failureKind).toBe('business')
    expect(mocks.publishGroupRate).not.toHaveBeenCalled()
  })
})
