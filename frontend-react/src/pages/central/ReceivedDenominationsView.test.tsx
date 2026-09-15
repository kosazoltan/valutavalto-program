import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ReceivedDenominationsView, { FIXED_FACE_VALUES } from './ReceivedDenominationsView'
import hu from '../../i18n/hu.json'

const mockLoad = vi.fn()

vi.mock('../../services/api/received-denominations', () => ({
  receivedDenominationsApi: {
    load: (...args: unknown[]) => mockLoad(...args),
  },
}))

const BRANCH_A = '20000000-0000-0000-0000-00000000000a'

function fixedColumns(present: Record<number, number | null>) {
  return FIXED_FACE_VALUES.map((faceValue) => ({
    faceValue,
    quantity: Object.prototype.hasOwnProperty.call(present, faceValue) ? present[faceValue] : null,
    inCatalog: Object.prototype.hasOwnProperty.call(present, faceValue),
    dataQualityFlag: 'OK',
  }))
}

const payload = {
  date: '2026-09-10',
  branchId: null,
  branches: [
    { id: BRANCH_A, code: 'BR001', name: 'Deák tér' },
    { id: '20000000-0000-0000-0000-00000000000b', code: 'BR002', name: 'Szeged' },
  ],
  fixedFaceValues: [...FIXED_FACE_VALUES],
  rows: [
    {
      currencyCode: 'HUF',
      totalValue: 100000,
      totalQuantity: 5,
      hasDataQualityIssue: false,
      cells: [
        {
          faceValue: 20000,
          denominationType: 'BANKNOTE',
          quantity: 5,
          totalValue: 100000,
          dataQualityFlag: 'OK',
        },
      ],
      fixedColumns: fixedColumns({ 20000: 5 }),
      otherCells: [],
      rateMissing: false,
      hufEquivalent: 100000,
    },
    {
      currencyCode: 'EUR',
      totalValue: 202,
      totalQuantity: 6,
      hasDataQualityIssue: true,
      cells: [
        {
          faceValue: 100,
          denominationType: 'BANKNOTE',
          quantity: 2,
          totalValue: 200,
          dataQualityFlag: 'OK',
        },
        {
          faceValue: 0.5,
          denominationType: 'COIN',
          quantity: 4,
          totalValue: 2,
          dataQualityFlag: 'FRACTIONAL_FACE_VALUE',
        },
      ],
      fixedColumns: fixedColumns({ 100: 2, 50: 0 }),
      otherCells: [
        {
          faceValue: 0.5,
          denominationType: 'COIN',
          quantity: 4,
          totalValue: 2,
          dataQualityFlag: 'FRACTIONAL_FACE_VALUE',
        },
      ],
      rate: 400,
      rateDate: '2026-09-10',
      rateSource: 'MNB',
      hufEquivalent: 80800,
      rateMissing: false,
    },
  ],
  hufTotalValue: 100000,
  currencyValueHuf: 80800,
  grandTotalHuf: 180800,
  currencyCount: 2,
  totalQuantity: 11,
  dataQualityIssueCount: 1,
}

describe('ReceivedDenominationsView (FK-111 FR-2 / FK-112)', () => {
  beforeEach(() => {
    mockLoad.mockReset()
  })

  it('nem fut automatikusan — a prompt látszik, lekérdezés nélkül', () => {
    render(<ReceivedDenominationsView />)
    expect(screen.getByText(hu.centralReceivedData.denominationsPrompt)).toBeInTheDocument()
    expect(mockLoad).not.toHaveBeenCalled()
  })

  it('FK-112: a fejlécek a 14 fix névérték + Egyéb, nem pozíció-sorszámok', async () => {
    mockLoad.mockResolvedValue(payload)
    render(<ReceivedDenominationsView />)
    await userEvent.click(screen.getByTestId('denominations-load-button'))

    expect(await screen.findByTestId('denom-header-20000')).toBeInTheDocument()
    expect(screen.getByTestId('denom-header-100')).toBeInTheDocument()
    expect(screen.getByTestId('denom-header-1')).toBeInTheDocument()
    expect(screen.getByTestId('denom-header-other')).toHaveTextContent(
      hu.centralReceivedData.denominationsOther,
    )
    expect(screen.queryByText('1.')).not.toBeInTheDocument()
    expect(screen.getByRole('table')).toHaveClass('data-grid')
  })

  it('a Lekérdezés gomb mátrixot rajzol: valutánként egy sor, 100-as oszlop + Egyéb a törtnek', async () => {
    mockLoad.mockResolvedValue(payload)
    render(<ReceivedDenominationsView />)

    await userEvent.click(screen.getByTestId('denominations-load-button'))

    await waitFor(() => expect(mockLoad).toHaveBeenCalledTimes(1))
    expect(screen.getByTestId('denom-row-HUF')).toBeInTheDocument()
    expect(screen.getByTestId('denom-cell-EUR-100')).toHaveTextContent('2')
    expect(screen.getByTestId('denom-cell-EUR-0.5')).toHaveTextContent('0,5')
    expect(screen.getByTestId('denom-cell-EUR-20')).toHaveTextContent('–')
  })

  it('a hibás (törtrészes névértékű) cella vizuálisan jelölve van, a többi nem', async () => {
    mockLoad.mockResolvedValue(payload)
    render(<ReceivedDenominationsView />)
    await userEvent.click(screen.getByTestId('denominations-load-button'))

    const flagged = await screen.findByTestId('denom-cell-EUR-0.5')
    expect(flagged).toHaveAttribute('title', 'FRACTIONAL_FACE_VALUE')
    expect(screen.getByTestId('denom-cell-EUR-other').className).toContain('bg-red-50')
    expect(screen.getByTestId('denom-cell-EUR-100').className).not.toContain('bg-red-50')
    expect(screen.getByTestId('denominations-issue-hint')).toHaveTextContent('1')
  })

  it('a törtrészes névértéket pontosan mutatja, nem kerekíti egészre', async () => {
    mockLoad.mockResolvedValue({
      ...payload,
      rows: [
        {
          currencyCode: 'EUR',
          totalValue: 2.4,
          totalQuantity: 6,
          hasDataQualityIssue: true,
          cells: [
            {
              faceValue: 0.5,
              denominationType: 'COIN',
              quantity: 4,
              totalValue: 2,
              dataQualityFlag: 'FRACTIONAL_FACE_VALUE',
            },
            {
              faceValue: 0.2,
              denominationType: 'COIN',
              quantity: 2,
              totalValue: 0.4,
              dataQualityFlag: 'FRACTIONAL_FACE_VALUE',
            },
          ],
          fixedColumns: fixedColumns({}),
          otherCells: [
            {
              faceValue: 0.5,
              denominationType: 'COIN',
              quantity: 4,
              totalValue: 2,
              dataQualityFlag: 'FRACTIONAL_FACE_VALUE',
            },
            {
              faceValue: 0.2,
              denominationType: 'COIN',
              quantity: 2,
              totalValue: 0.4,
              dataQualityFlag: 'FRACTIONAL_FACE_VALUE',
            },
          ],
          rateMissing: true,
        },
      ],
    })
    render(<ReceivedDenominationsView />)
    await userEvent.click(screen.getByTestId('denominations-load-button'))

    const half = await screen.findByTestId('denom-cell-EUR-0.5')
    expect(half).toHaveTextContent('0,5')
    expect(screen.getByTestId('denom-cell-EUR-0.2')).toHaveTextContent('0,2')
  })

  it('a NON_POSITIVE_FACE_VALUE cella is jelölve van, és a magyarázat említi ezt az esetet', async () => {
    mockLoad.mockResolvedValue({
      ...payload,
      rows: [
        {
          currencyCode: 'EUR',
          totalValue: 0,
          totalQuantity: 3,
          hasDataQualityIssue: true,
          cells: [
            {
              faceValue: 0,
              denominationType: 'BANKNOTE',
              quantity: 3,
              totalValue: 0,
              dataQualityFlag: 'NON_POSITIVE_FACE_VALUE',
            },
          ],
          fixedColumns: fixedColumns({}),
          otherCells: [
            {
              faceValue: 0,
              denominationType: 'BANKNOTE',
              quantity: 3,
              totalValue: 0,
              dataQualityFlag: 'NON_POSITIVE_FACE_VALUE',
            },
          ],
          rateMissing: true,
        },
      ],
    })
    render(<ReceivedDenominationsView />)
    await userEvent.click(screen.getByTestId('denominations-load-button'))

    const cell = await screen.findByTestId('denom-cell-EUR-0')
    expect(screen.getByTestId('denom-cell-EUR-other').className).toContain('bg-red-50')
    expect(cell).toBeInTheDocument()
    expect(screen.getByTestId('denominations-issue-hint')).toHaveTextContent(
      hu.centralReceivedData.denominationsIssueHint,
    )
    expect(hu.centralReceivedData.denominationsIssueHint).toMatch(/nem pozitív|nempozitív/i)
  })

  it('FK-112: az összesítő sáv Valuta érték / Forint érték / Összesen mezőket mutat', async () => {
    mockLoad.mockResolvedValue(payload)
    render(<ReceivedDenominationsView />)
    await userEvent.click(screen.getByTestId('denominations-load-button'))

    const summary = await screen.findByTestId('denominations-summary')
    expect(summary).toHaveTextContent(hu.centralReceivedData.denominationsCurrencyValue)
    expect(summary).toHaveTextContent(hu.centralReceivedData.denominationsHufValue)
    expect(summary).toHaveTextContent(hu.centralReceivedData.denominationsGrandTotal)
    expect(screen.getByTestId('denominations-summary-huf-value')).toHaveTextContent('100 000,00')
    expect(screen.getByTestId('denominations-summary-currency-value')).toHaveTextContent(
      '80 800,00',
    )
    expect(screen.getByTestId('denominations-summary-grand-total')).toHaveTextContent('180 800,00')
    expect(screen.getByTestId('denom-rate-EUR')).toHaveTextContent('MNB')
    expect(screen.getByTestId('denom-rate-EUR')).toHaveTextContent('2026-09-10')
  })

  it('FK-112: hiányzó árfolyam "nincs adat" jelzést kap, a táblázat megmarad', async () => {
    mockLoad.mockResolvedValue({
      ...payload,
      rows: [
        {
          ...payload.rows[1],
          rateMissing: true,
          rate: null,
          rateDate: null,
          rateSource: null,
          hufEquivalent: null,
        },
      ],
      currencyValueHuf: 0,
      grandTotalHuf: 0,
    })
    render(<ReceivedDenominationsView />)
    await userEvent.click(screen.getByTestId('denominations-load-button'))

    expect(await screen.findByTestId('denom-row-EUR')).toBeInTheDocument()
    expect(screen.getByTestId('denom-rate-EUR')).toHaveTextContent(
      hu.centralReceivedData.denominationsRateMissing,
    )
  })

  it('a „Vizsgált egység” választó a válasz iroda-listájából töltődik, és branchId-t küld', async () => {
    mockLoad.mockResolvedValue(payload)
    render(<ReceivedDenominationsView />)
    await userEvent.click(screen.getByTestId('denominations-load-button'))
    await waitFor(() => expect(mockLoad).toHaveBeenCalledTimes(1))
    expect(mockLoad).toHaveBeenLastCalledWith(expect.any(String), null)

    await userEvent.selectOptions(screen.getByTestId('denominations-unit-select'), BRANCH_A)
    await userEvent.click(screen.getByTestId('denominations-load-button'))

    await waitFor(() => expect(mockLoad).toHaveBeenCalledTimes(2))
    expect(mockLoad).toHaveBeenLastCalledWith(expect.any(String), BRANCH_A)
  })

  it('403 esetén jogosultsági szöveg jelenik meg, nem betöltési hiba', async () => {
    mockLoad.mockRejectedValue({ response: { status: 403 } })
    render(<ReceivedDenominationsView />)

    await userEvent.click(screen.getByTestId('denominations-load-button'))

    await waitFor(() =>
      expect(screen.getByTestId('received-denominations-error')).toBeInTheDocument(),
    )
    expect(screen.getByText(hu.centralReceivedData.denominationsForbidden)).toBeInTheDocument()
    expect(screen.queryByText(hu.centralReceivedData.denominationsError)).not.toBeInTheDocument()
  })

  it('üres eredménynél az üres-állapot felirat jelenik meg', async () => {
    mockLoad.mockResolvedValue({
      ...payload,
      rows: [],
      hufTotalValue: 0,
      currencyValueHuf: 0,
      grandTotalHuf: 0,
      currencyCount: 0,
      totalQuantity: 0,
      dataQualityIssueCount: 0,
    })
    render(<ReceivedDenominationsView />)

    await userEvent.click(screen.getByTestId('denominations-load-button'))

    expect(await screen.findByText(hu.centralReceivedData.denominationsEmpty)).toBeInTheDocument()
  })
})
