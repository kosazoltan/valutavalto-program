import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import RatesPage from './RatesPage'

// B-csoport (RED) — FR-T5..FR-T7: a natív window.alert() kiváltása a közös toast-tal
// (components/ui/toaster) a /rates oldal szerkesztő-ágán.
//
// Variáns-választás a repo meglévő konvenciója szerint:
//  - beviteli validáció (vételi >= eladási)  → toast.warning
//    (precedens: BanknoteBreakdown.tsx:63 `toast.warning('Érvénytelen adat', ...)`)
//  - API/mentési hiba (catch-ág)             → toast.error
//    (precedens: VaultClosingChecklistPanel.tsx:143 `toast.error('Mentési hiba', ...)`)
//
// Szöveg-szerződés (Tomi jóváhagyása, 2026-07-31): cím/részlet bontás CSAK ott,
// ahol a mai szövegben van natural elválasztó. A /rates oldal MINDHÁROM szövege
// egyetlen, elválasztó nélküli mondat — a `saveEdit` catch-ága is
// ('Hiba az árfolyam mentésekor!', NINCS kettőspont, NINCS err.message a szövegben) —,
// ezért mindhárom hívás EGYARGUMENTUMOS marad. Mesterséges bontást nem vezetünk be,
// és a catch-ágba sem teszünk be ma nem látható `getErrorMessage(err)` részletet.
// A guard-sorrend és a hívó-oldali logika VÁLTOZATLAN.

const mocks = vi.hoisted(() => ({
  exchangeRateApiList: vi.fn(),
  exchangeRateApiCreate: vi.fn(),
  exchangeRateApiUploadRateFile: vi.fn(),
  exchangeRateApiImportRateFile: vi.fn(),
  rateApprovalRequest: vi.fn(),
  currencyApiList: vi.fn(),
  calculatorMatrix: vi.fn(),
  calculatorConvert: vi.fn(),
  calculatorReverse: vi.fn(),
  pollingStatus: vi.fn(),
  pollingSources: vi.fn(),
  pollingEcbRates: vi.fn(),
  pollingTrigger: vi.fn(),
  pollingApplyMargins: vi.fn(),
  pollingUpdateSource: vi.fn(),
  bankRates: vi.fn(),
  competitorRates: vi.fn(),
  territoryWorkgroupRates: vi.fn(),
  roundingRulesList: vi.fn(),
  roundingRuleGet: vi.fn(),
  roundingRuleRound: vi.fn(),
  recordLocalAuditEvent: vi.fn(),
  logger: {
    error: vi.fn(),
    info: vi.fn(),
    warn: vi.fn(),
    debug: vi.fn(),
  },
  useAuthStore: vi.fn(),
  useAppMode: vi.fn(),
  toast: {
    success: vi.fn(),
    error: vi.fn(),
    warning: vi.fn(),
    info: vi.fn(),
    dismiss: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  exchangeRateApi: {
    list: mocks.exchangeRateApiList,
    create: mocks.exchangeRateApiCreate,
    uploadRateFile: mocks.exchangeRateApiUploadRateFile,
    importRateFile: mocks.exchangeRateApiImportRateFile,
  },
  rateApprovalApi: {
    request: mocks.rateApprovalRequest,
  },
  currencyApi: {
    list: mocks.currencyApiList,
  },
  currencyCalculatorApi: {
    matrix: mocks.calculatorMatrix,
    convert: mocks.calculatorConvert,
    reverse: mocks.calculatorReverse,
  },
  exchangeRatePollingApi: {
    status: mocks.pollingStatus,
    sources: mocks.pollingSources,
    ecbRates: mocks.pollingEcbRates,
    trigger: mocks.pollingTrigger,
    applyMargins: mocks.pollingApplyMargins,
    updateSource: mocks.pollingUpdateSource,
  },
  rateCreationApi: {
    getBankRates: mocks.bankRates,
    getCompetitorRates: mocks.competitorRates,
    getTerritoryWorkgroupRates: mocks.territoryWorkgroupRates,
  },
  roundingRuleApi: {
    list: mocks.roundingRulesList,
    getByCurrencyCode: mocks.roundingRuleGet,
    round: mocks.roundingRuleRound,
  },
}))

vi.mock('../../utils/electronTransactions', () => ({
  recordLocalAuditEvent: mocks.recordLocalAuditEvent,
}))

vi.mock('../../utils/logger', () => ({
  logger: mocks.logger,
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: mocks.useAuthStore,
}))

vi.mock('../../hooks/useAppMode', () => ({
  useAppMode: mocks.useAppMode,
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

const eurCurrency = { id: 1, code: 'EUR', name: 'Euró', decimals: 2, displayOrder: 8, active: true }

/** Érvényes pár: vételi (391,50) < eladási (398,50). */
const validEurRate = {
  id: 1,
  currencyCode: 'EUR',
  currencyName: 'Euró',
  baseBuyRate: 391.5,
  baseSellRate: 398.5,
  officialRate: 391.25,
  validTime: '10:30',
  currencyId: 1,
  createdAt: '2026-07-31T08:00:00.000Z',
}

/** Érvénytelen pár: vételi (399,00) >= eladási (398,50) — a szerkesztő ezt tölti be. */
const invalidEurRate = { ...validEurRate, baseBuyRate: 399, baseSellRate: 398.5 }

const VALIDATION_TEXT = 'A vételi árfolyamnak kisebbnek kell lennie az eladásinál!'

async function startEditingEur(user: ReturnType<typeof userEvent.setup>) {
  render(<RatesPage />)
  const editButtons = await screen.findAllByTitle('Szerkesztés')
  await user.click(editButtons[0]!)
  return await screen.findByTitle('Mentés')
}

describe('RatesPage — FR-T5..T7: a natív alert() helyett toast', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.exchangeRateApiList.mockResolvedValue([validEurRate])
    mocks.currencyApiList.mockResolvedValue([eurCurrency])
    mocks.exchangeRateApiCreate.mockResolvedValue(validEurRate)
    mocks.rateApprovalRequest.mockResolvedValue({
      id: 'approval-1',
      branchId: 'branch-1',
      currencyCode: 'EUR',
      newBuyRate: 391.5,
      newSellRate: 398.5,
      status: 'PENDING',
    })
    mocks.recordLocalAuditEvent.mockResolvedValue(undefined)
    mocks.calculatorMatrix.mockResolvedValue({})
    mocks.calculatorConvert.mockResolvedValue(null)
    mocks.calculatorReverse.mockResolvedValue(null)
    mocks.pollingStatus.mockResolvedValue({
      lastPollTime: '2026-07-31T08:00:00',
      lastPollSuccess: true,
      lastPollError: null,
      lastPollUpdatedCount: 0,
      lastPollSource: 'MNB',
    })
    mocks.pollingSources.mockResolvedValue([])
    mocks.pollingEcbRates.mockResolvedValue({})
    mocks.bankRates.mockResolvedValue([])
    mocks.competitorRates.mockResolvedValue([])
    mocks.territoryWorkgroupRates.mockResolvedValue([])
    mocks.roundingRulesList.mockResolvedValue([])
    mocks.roundingRuleGet.mockResolvedValue(null)
    mocks.roundingRuleRound.mockResolvedValue(null)
    mocks.useAppMode.mockReturnValue({ mode: 'full' })
    mocks.useAuthStore.mockImplementation((selector: any) =>
      selector({
        hasCanonicalRole: (roles: readonly string[]) =>
          roles.includes('foertektar') || roles.includes('ugyvezeto'),
        worker: {
          id: 77,
          branchId: 'branch-1',
          workerCode: 'ADMIN',
          firstName: 'Admin',
          lastName: 'Teszt',
          fullName: 'Admin Teszt',
          role: 'ADMIN',
          branchCode: 'BUD01',
          branchName: 'Budapest 01',
          companyId: 'company-1',
          companyCode: 'EBC',
          companyName: 'Exclusive Best Change',
        },
      }),
    )
    vi.spyOn(window, 'alert').mockImplementation(() => {})
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('FR-T5 (RatesPage.tsx:356) — mentési validáció toast.warning-gal, natív alert nélkül', async () => {
    const user = userEvent.setup()
    mocks.exchangeRateApiList.mockResolvedValue([invalidEurRate])

    const saveButton = await startEditingEur(user)
    await user.click(saveButton)

    await waitFor(() => expect(mocks.toast.warning).toHaveBeenCalledWith(VALIDATION_TEXT))
    expect(mocks.toast.warning).toHaveBeenCalledTimes(1)
    expect(window.alert).not.toHaveBeenCalled()
    // A guard változatlan: érvénytelen páron NINCS mentés és NINCS audit-írás.
    expect(mocks.exchangeRateApiCreate).not.toHaveBeenCalled()
    expect(mocks.recordLocalAuditEvent).not.toHaveBeenCalled()
  })

  it('FR-T6 (RatesPage.tsx:391) — mentési hiba toast.error-ral, natív alert nélkül', async () => {
    const user = userEvent.setup()
    mocks.exchangeRateApiCreate.mockRejectedValue(new Error('Szerver hiba'))

    const saveButton = await startEditingEur(user)
    await user.click(saveButton)

    await waitFor(() =>
      expect(mocks.toast.error).toHaveBeenCalledWith('Hiba az árfolyam mentésekor!'),
    )
    expect(mocks.toast.error).toHaveBeenCalledTimes(1)
    expect(window.alert).not.toHaveBeenCalled()
    // A hibanaplózás változatlanul megtörténik.
    expect(mocks.logger.error).toHaveBeenCalled()
  })

  it('FR-T7 (RatesPage.tsx:400) — jóváhagyás-kérés validáció toast.warning-gal, natív alert nélkül', async () => {
    const user = userEvent.setup()
    mocks.exchangeRateApiList.mockResolvedValue([invalidEurRate])

    await startEditingEur(user)
    await user.click(await screen.findByTitle('Jóváhagyás kérés'))

    await waitFor(() => expect(mocks.toast.warning).toHaveBeenCalledWith(VALIDATION_TEXT))
    expect(mocks.toast.warning).toHaveBeenCalledTimes(1)
    expect(window.alert).not.toHaveBeenCalled()
    // A guard változatlan: érvénytelen páron NINCS jóváhagyási kérelem.
    expect(mocks.rateApprovalRequest).not.toHaveBeenCalled()
  })

  it('érvényes páron a sikeres mentés néma marad (se toast, se alert)', async () => {
    const user = userEvent.setup()

    const saveButton = await startEditingEur(user)
    await user.click(saveButton)

    await waitFor(() => expect(mocks.exchangeRateApiCreate).toHaveBeenCalledTimes(1))
    expect(mocks.toast.warning).not.toHaveBeenCalled()
    expect(mocks.toast.error).not.toHaveBeenCalled()
    expect(window.alert).not.toHaveBeenCalled()
  })
})
