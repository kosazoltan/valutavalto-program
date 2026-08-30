import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { AxiosError, type AxiosResponse } from 'axios'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import TransactionLevyReportPage from './TransactionLevyReportPage'

/**
 * FK-099 F1–F11 — tranzakciós illeték riport oldal (WU7 RED → WU8 GREEN;
 * round-3: F8–F11 — D2 stale-response guard, D3 metric-wrapper, D4 overflow).
 * Mock: `../../services/api/index` + react-i18next (PosHandlingFeePage minta).
 * Szám-elvárások `new Intl.NumberFormat('hu-HU')`-val épülnek — a hu-HU
 * ezres-elválasztója U+00A0, nem ASCII szóköz (pitfall 9).
 */

const translations: Record<string, string> = vi.hoisted(() => ({
  'reports.transactionLevy.title': 'Tranzakciós díjak jelentése',
  'reports.transactionLevy.month': 'Hónap',
  'reports.transactionLevy.loading': 'Betöltés...',
  'reports.transactionLevy.emptyState': 'Nincs adat a kiválasztott hónapra.',
  'reports.transactionLevy.threshold': 'Küszöb',
  'reports.transactionLevy.multiRateNote': 'Több ráta is hatályban volt ebben az időszakban.',
  'reports.transactionLevy.totalRow': 'ÖSSZESEN',
  'reports.transactionLevy.monthly.title': 'Havi összesítő',
  'reports.transactionLevy.monthly.buyCount': 'Vételek száma',
  'reports.transactionLevy.monthly.sellCount': 'Eladások száma',
  'reports.transactionLevy.monthly.customerCount': 'Ügyfelek száma',
  'reports.transactionLevy.monthly.belowBuy': 'Küszöb alatti vétel forgalom',
  'reports.transactionLevy.monthly.belowSell': 'Küszöb alatti eladás forgalom',
  'reports.transactionLevy.monthly.aboveBuy': 'Küszöb feletti vétel forgalom',
  'reports.transactionLevy.monthly.aboveSell': 'Küszöb feletti eladás forgalom',
  'reports.transactionLevy.table.date': 'Dátum',
  'reports.transactionLevy.table.branch': 'Pénztár',
  'reports.transactionLevy.table.buy': 'Vétel',
  'reports.transactionLevy.table.sell': 'Eladás',
  'reports.transactionLevy.table.conversion': 'Konverzió',
  'reports.transactionLevy.table.normalBase': 'Alap illeték',
  'reports.transactionLevy.table.normalSupplement': 'Kieg. illeték',
  'reports.transactionLevy.table.aboveCount': 'Küszöb feletti db',
  'reports.transactionLevy.table.aboveBase': 'Alap (küszöb felett)',
  'reports.transactionLevy.table.aboveSupplement': 'Kieg. (küszöb felett)',
  'reports.transactionLevy.table.largeBase': 'Nagy-alap',
  'reports.transactionLevy.table.levyTotal': 'Tranz.díj',
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({
    t: (key: string) => translations[key] ?? key,
  }),
}))

const mockGetReport = vi.fn()

vi.mock('../../services/api/index', () => ({
  transactionLevyApi: {
    getReport: (...args: unknown[]) => mockGetReport(...args),
    listRates: vi.fn().mockResolvedValue([]),
    createRate: vi.fn(),
  },
}))

const fmt = new Intl.NumberFormat('hu-HU')
// testing-library a DOM-szöveget normalizálja (NBSP → ASCII szóköz), ezért a
// elvárt értékeket ugyanazzal a normalizálással képezzük le (az elvárás továbbra
// is Intl.NumberFormat('hu-HU')-val épül, nem kézzel írt szóközzel — pitfall 9).
const fmtText = (n: number) => fmt.format(n).replace(/\s+/g, ' ')

const zeroGroup = {
  normalBaseLevy: 0,
  normalSupplementLevy: 0,
  aboveThresholdCount: 0,
  aboveThresholdBaseLevy: 0,
  aboveThresholdSupplementLevy: 0,
}

function emptyReport() {
  return {
    from: '2026-08-01',
    to: '2026-08-31',
    appliedRates: [
      {
        effectiveFrom: '2013-01-01',
        baseRatePercent: 0.45,
        baseRateCapHuf: 20000,
        supplementRatePercent: 0.45,
        supplementRateCapHuf: 20000,
        conversionSingleSideFlag: true,
        thresholdHuf: 4444445,
      },
    ],
    rows: [],
    totals: {
      date: null,
      branchId: null,
      branchCode: null,
      branchName: null,
      buy: { ...zeroGroup },
      sell: { ...zeroGroup },
      conversion: { ...zeroGroup },
      largeBaseHuf: 0,
      levyTotal: 0,
    },
    monthlySummary: {
      buyCount: 0,
      sellCount: 0,
      customerCount: 0,
      belowThresholdBuyHuf: 0,
      belowThresholdSellHuf: 0,
      aboveThresholdBuyHuf: 0,
      aboveThresholdSellHuf: 0,
    },
  }
}

function reportWithBranch(branchCode: string) {
  return {
    from: '2026-08-01',
    to: '2026-08-31',
    appliedRates: [],
    rows: [
      {
        date: '2026-08-03',
        branchId: `b-${branchCode}`,
        branchCode,
        branchName: '',
        buy: { ...zeroGroup, normalBaseLevy: 1 },
        sell: { ...zeroGroup },
        conversion: { ...zeroGroup },
        largeBaseHuf: 0,
        levyTotal: 2,
      },
    ],
    totals: {
      date: null,
      branchId: null,
      branchCode: null,
      branchName: null,
      buy: { ...zeroGroup },
      sell: { ...zeroGroup },
      conversion: { ...zeroGroup },
      largeBaseHuf: 0,
      levyTotal: 0,
    },
    monthlySummary: {
      buyCount: 0,
      sellCount: 0,
      customerCount: 0,
      belowThresholdBuyHuf: 0,
      belowThresholdSellHuf: 0,
      aboveThresholdBuyHuf: 0,
      aboveThresholdSellHuf: 0,
    },
  }
}

function fixtureReport(totalsLevyTotal = 67000) {
  return {
    from: '2026-08-01',
    to: '2026-08-31',
    appliedRates: [
      {
        effectiveFrom: '2013-01-01',
        baseRatePercent: 0.45,
        baseRateCapHuf: 20000,
        supplementRatePercent: 0.45,
        supplementRateCapHuf: 20000,
        conversionSingleSideFlag: true,
        thresholdHuf: 4444445,
      },
    ],
    rows: [
      {
        date: '2026-08-03',
        branchId: 'b1',
        branchCode: '001',
        branchName: 'Fő utca',
        buy: {
          normalBaseLevy: 13500,
          normalSupplementLevy: 13500,
          aboveThresholdCount: 0,
          aboveThresholdBaseLevy: 0,
          aboveThresholdSupplementLevy: 0,
        },
        sell: { ...zeroGroup },
        conversion: { ...zeroGroup },
        largeBaseHuf: 0,
        levyTotal: 27000,
      },
      {
        date: '2026-08-04',
        branchId: 'b2',
        branchCode: '002',
        branchName: 'Mellék',
        buy: { ...zeroGroup },
        sell: {
          normalBaseLevy: 0,
          normalSupplementLevy: 0,
          aboveThresholdCount: 1,
          aboveThresholdBaseLevy: 20000,
          aboveThresholdSupplementLevy: 20000,
        },
        conversion: { ...zeroGroup },
        largeBaseHuf: 5000000,
        levyTotal: 40000,
      },
    ],
    totals: {
      date: null,
      branchId: null,
      branchCode: null,
      branchName: null,
      buy: {
        normalBaseLevy: 13500,
        normalSupplementLevy: 13500,
        aboveThresholdCount: 0,
        aboveThresholdBaseLevy: 0,
        aboveThresholdSupplementLevy: 0,
      },
      sell: {
        normalBaseLevy: 0,
        normalSupplementLevy: 0,
        aboveThresholdCount: 1,
        aboveThresholdBaseLevy: 20000,
        aboveThresholdSupplementLevy: 20000,
      },
      conversion: { ...zeroGroup },
      largeBaseHuf: 5000000,
      levyTotal: totalsLevyTotal,
    },
    monthlySummary: {
      buyCount: 12,
      sellCount: 7,
      customerCount: 5,
      belowThresholdBuyHuf: 3000000,
      belowThresholdSellHuf: 1000000,
      aboveThresholdBuyHuf: 5000000,
      aboveThresholdSellHuf: 4444445,
    },
  }
}

describe('TransactionLevyReportPage — FK-099', () => {
  beforeEach(() => {
    mockGetReport.mockReset()
  })

  it('F1/FR-8: üres hónap → empty-state szöveg és minden ÖSSZESEN cella 0', async () => {
    mockGetReport.mockResolvedValue(emptyReport())

    render(<TransactionLevyReportPage />)

    await waitFor(() =>
      expect(screen.getByText('Nincs adat a kiválasztott hónapra.')).toBeInTheDocument(),
    )
    // Az ÖSSZESEN sor megjelenik, minden értéke 0.
    expect(screen.getByText('ÖSSZESEN')).toBeInTheDocument()
    expect(screen.getAllByText(fmtText(0)).length).toBeGreaterThan(0)
  })

  it('F2/FR-8/10: fixture hónap → sorok pénztárkóddal, dátummal, 5 alkomponenssel, Nagy-alappal és Tranz.díjjal', async () => {
    mockGetReport.mockResolvedValue(fixtureReport())

    render(<TransactionLevyReportPage />)

    await waitFor(() => expect(screen.getByText('001 – Fő utca')).toBeInTheDocument())
    expect(screen.getByText('002 – Mellék')).toBeInTheDocument()
    expect(screen.getByText('2026-08-03')).toBeInTheDocument()
    expect(screen.getByText('2026-08-04')).toBeInTheDocument()
    // Soronkénti Tranz.díj: 27 000 és 40 000 (hu-HU formázás).
    expect(screen.getByText(fmtText(27000))).toBeInTheDocument()
    expect(screen.getByText(fmtText(40000))).toBeInTheDocument()
    // Normál illetékek és Nagy-alap (több cellában is előfordulnak — getAllByText).
    expect(screen.getAllByText(fmtText(13500)).length).toBeGreaterThan(0)
    expect(screen.getAllByText(fmtText(20000)).length).toBeGreaterThan(0)
    expect(screen.getAllByText(fmtText(5000000)).length).toBeGreaterThan(0)
  })

  it('F3/FR-11: az ÖSSZESEN sor a backend totals-ból jön — a kliens NEM számolja újra', async () => {
    // Szándékosan eltérő totals.levyTotal (99 999 ≠ sor-összeg 67 000): ha a
    // komponens újraszámolná, a 67 000 jelenne meg.
    mockGetReport.mockResolvedValue(fixtureReport(99999))

    render(<TransactionLevyReportPage />)

    await waitFor(() => expect(screen.getByText('ÖSSZESEN')).toBeInTheDocument())
    expect(screen.getByText(fmtText(99999))).toBeInTheDocument()
    expect(screen.queryByText(fmtText(67000))).not.toBeInTheDocument()
  })

  it('F4/FR-12/13/14: a havi panel megjeleníti a darabszámokat és forgalmakat; konverziós érték nincs', async () => {
    mockGetReport.mockResolvedValue(fixtureReport())

    render(<TransactionLevyReportPage />)

    await waitFor(() => expect(screen.getByText('Havi összesítő')).toBeInTheDocument())
    const panel = screen.getByText('Havi összesítő').closest('section') as HTMLElement
    expect(panel).not.toBeNull()
    expect(panel).toHaveTextContent(fmtText(12))
    expect(panel).toHaveTextContent(fmtText(7))
    expect(panel).toHaveTextContent(fmtText(5))
    expect(panel).toHaveTextContent(fmtText(3000000))
    expect(panel).toHaveTextContent(fmtText(1000000))
    expect(panel).toHaveTextContent(fmtText(5000000))
    expect(panel).toHaveTextContent(fmtText(4444445))
    expect(panel).not.toHaveTextContent('Konverzió')
  })

  it('F5/FR-7 UI: a küszöb-badge a hatályos ráta küszöbét mutatja (4 444 445)', async () => {
    mockGetReport.mockResolvedValue(fixtureReport())

    render(<TransactionLevyReportPage />)

    // A küszöb-érték a havi panelben is előfordul (aboveThresholdSellHuf) — a
    // badge-t ezért a dedikált testid-ján keresztül pineljük (getByText 2 találatra
    // hibás lenne). A lefedettség ugyanaz: a badge a hatályos ráta küszöbét mutatja.
    await waitFor(() => {
      expect(screen.getByTestId('threshold-badge')).toHaveTextContent(fmtText(4444445))
    })
  })

  it('F6: hónapváltás 2026-02-re → getReport("2026-02-01","2026-02-28"), nincs UTC-shift', async () => {
    mockGetReport.mockResolvedValue(emptyReport())

    render(<TransactionLevyReportPage />)
    await waitFor(() => expect(mockGetReport).toHaveBeenCalled())
    mockGetReport.mockClear()

    fireEvent.change(screen.getByLabelText('Hónap'), { target: { value: '2026-02' } })

    await waitFor(() => expect(mockGetReport).toHaveBeenCalledWith('2026-02-01', '2026-02-28'))
  })

  it('F7: getReport hiba → a szerver üzenet jelenik meg, a táblázat nem', async () => {
    // D5: valódi AxiosError (nem plain objektum) — a szerver-üzenet elsőbbsége
    // (`response.data.message`) a getErrorMessage AxiosError-ágán megy át.
    mockGetReport.mockRejectedValue(
      new AxiosError('Request failed with status code 400', 'ERR_BAD_REQUEST', undefined, undefined, {
        data: { message: 'A lekérdezett időszak nem haladhatja meg a 62 napot.' },
        status: 400,
        statusText: 'Bad Request',
        headers: {},
        config: {},
      } as AxiosResponse),
    )

    render(<TransactionLevyReportPage />)

    await waitFor(() =>
      expect(
        screen.getByText('A lekérdezett időszak nem haladhatja meg a 62 napot.'),
      ).toBeInTheDocument(),
    )
    expect(screen.queryByText('ÖSSZESEN')).not.toBeInTheDocument()
  })

  // ============================ F8–F11: round-3 PR-bot defektek ============================

  it('F8/D2: gyors dupla hónapváltás — a későn érkező ELSŐ válasz nem írhatja felül az újat', async () => {
    let resolveFirst!: (report: unknown) => void
    const firstPending = new Promise((resolve) => {
      resolveFirst = resolve
    })
    mockGetReport.mockReturnValueOnce(firstPending).mockResolvedValueOnce(reportWithBranch('FRESH1'))

    render(<TransactionLevyReportPage />)
    await waitFor(() => expect(mockGetReport).toHaveBeenCalledTimes(1))

    fireEvent.change(screen.getByLabelText('Hónap'), { target: { value: '2026-09' } })
    await waitFor(() => expect(mockGetReport).toHaveBeenCalledTimes(2))
    await waitFor(() => expect(screen.getByText('FRESH1')).toBeInTheDocument())

    // A második (ÚJABB) hónap már renderelt; most érkezik meg a lassú első válasz.
    resolveFirst(reportWithBranch('STALE1'))

    await waitFor(() => expect(screen.queryByText('STALE1')).not.toBeInTheDocument())
    expect(screen.getByText('FRESH1')).toBeInTheDocument()
  })

  it('F9/D2: újabb siker UTÁN érkező elavult hiba → nincs banner, tábla ép, loading nem ragad', async () => {
    let rejectFirst!: (err: unknown) => void
    const firstPending = new Promise((_, reject) => {
      rejectFirst = reject
    })
    mockGetReport.mockReturnValueOnce(firstPending).mockResolvedValueOnce(reportWithBranch('FRESH2'))

    render(<TransactionLevyReportPage />)
    await waitFor(() => expect(mockGetReport).toHaveBeenCalledTimes(1))

    fireEvent.change(screen.getByLabelText('Hónap'), { target: { value: '2026-09' } })
    await waitFor(() => expect(mockGetReport).toHaveBeenCalledTimes(2))
    await waitFor(() => expect(screen.getByText('FRESH2')).toBeInTheDocument())

    // Az elavult hiba most érkezik — guard nélkül törölné a friss táblát és banner-t tenne ki.
    rejectFirst(new AxiosError('Request failed with status code 500', 'ERR_BAD_RESPONSE'))

    await waitFor(() => expect(screen.getByText('FRESH2')).toBeInTheDocument())
    expect(screen.queryByText('Betöltés...')).not.toBeInTheDocument()
    expect(screen.queryByText('Request failed with status code 500')).not.toBeInTheDocument()
    expect(document.querySelector('.bg-red-50')).toBeNull()
  })

  it('F10/D3: mind a 7 havi metrika dt-címkéje és dd-értéke EGY wrapperben van (dl > div > dt+dd)', async () => {
    mockGetReport.mockResolvedValue(fixtureReport())

    render(<TransactionLevyReportPage />)

    await waitFor(() => expect(screen.getByText('Havi összesítő')).toBeInTheDocument())

    const expected: [string, string][] = [
      ['Vételek száma', fmtText(12)],
      ['Eladások száma', fmtText(7)],
      ['Ügyfelek száma', fmtText(5)],
      ['Küszöb alatti vétel forgalom', `${fmtText(3000000)} Ft`],
      ['Küszöb alatti eladás forgalom', `${fmtText(1000000)} Ft`],
      ['Küszöb feletti vétel forgalom', `${fmtText(5000000)} Ft`],
      ['Küszöb feletti eladás forgalom', `${fmtText(4444445)} Ft`],
    ]
    expect(expected).toHaveLength(7)
    expected.forEach(([label, value]) => {
      const dt = screen.getByText(label)
      expect(dt.tagName).toBe('DT')
      const wrapper = dt.parentElement as HTMLElement
      // Fragment-alakban a parent maga a DL — a wrappernek DIV-nek kell lennie.
      expect(wrapper.tagName).toBe('DIV')
      const dd = wrapper.querySelector('dd')
      expect(dd).not.toBeNull()
      expect(dd?.textContent?.replace(/\s+/g, ' ')).toBe(value)
    })
  })

  it('F11/D4: a fő tábla overflow-x-auto scroll-konténerben van', async () => {
    mockGetReport.mockResolvedValue(fixtureReport())

    render(<TransactionLevyReportPage />)

    await waitFor(() => expect(screen.getByText('ÖSSZESEN')).toBeInTheDocument())

    const table = document.querySelector('table') as HTMLTableElement
    expect(table).not.toBeNull()
    expect(table.closest('.overflow-x-auto')).not.toBeNull()
  })
})
