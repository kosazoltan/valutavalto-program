import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ReceivedDenominationsView from './ReceivedDenominationsView'
import hu from '../../i18n/hu.json'

const mockLoad = vi.fn()

vi.mock('../../services/api/received-denominations', () => ({
  receivedDenominationsApi: {
    load: (...args: unknown[]) => mockLoad(...args),
  },
}))

const BRANCH_A = '20000000-0000-0000-0000-00000000000a'

const payload = {
  date: '2026-09-10',
  branchId: null,
  branches: [
    { id: BRANCH_A, code: 'BR001', name: 'Deák tér' },
    { id: '20000000-0000-0000-0000-00000000000b', code: 'BR002', name: 'Szeged' },
  ],
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
    },
  ],
  hufTotalValue: 100000,
  currencyCount: 2,
  totalQuantity: 11,
  dataQualityIssueCount: 1,
}

describe('ReceivedDenominationsView (FK-111 FR-2)', () => {
  beforeEach(() => {
    mockLoad.mockReset()
  })

  it('nem fut automatikusan — a prompt látszik, lekérdezés nélkül', () => {
    render(<ReceivedDenominationsView />)
    expect(screen.getByText(hu.centralReceivedData.denominationsPrompt)).toBeInTheDocument()
    expect(mockLoad).not.toHaveBeenCalled()
  })

  it('a Lekérdezés gomb mátrixot rajzol: valutánként egy sor, címlet-cellák nagytól kicsiig', async () => {
    mockLoad.mockResolvedValue(payload)
    render(<ReceivedDenominationsView />)

    await userEvent.click(screen.getByTestId('denominations-load-button'))

    await waitFor(() => expect(mockLoad).toHaveBeenCalledTimes(1))
    expect(screen.getByTestId('denom-row-HUF')).toBeInTheDocument()
    const eurRow = screen.getByTestId('denom-row-EUR')
    const eurCells = eurRow.querySelectorAll('td[data-testid^="denom-cell-"]')
    expect(Array.from(eurCells).map((cell) => cell.getAttribute('data-testid'))).toEqual([
      'denom-cell-EUR-100',
      'denom-cell-EUR-0.5',
    ])
  })

  it('a hibás (törtrészes névértékű) cella vizuálisan jelölve van, a többi nem', async () => {
    mockLoad.mockResolvedValue(payload)
    render(<ReceivedDenominationsView />)
    await userEvent.click(screen.getByTestId('denominations-load-button'))

    const flagged = await screen.findByTestId('denom-cell-EUR-0.5')
    expect(flagged.className).toContain('bg-red-50')
    expect(flagged).toHaveAttribute('title', 'FRACTIONAL_FACE_VALUE')
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
        },
      ],
    })
    render(<ReceivedDenominationsView />)
    await userEvent.click(screen.getByTestId('denominations-load-button'))

    // A 0,5 nem jelenhet meg 1-ként, a 0,2 pedig 0-ként — az a tárolt hibás
    // értéket rejtené el pont ott, ahol a jelölés hibát állít.
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
        },
      ],
    })
    render(<ReceivedDenominationsView />)
    await userEvent.click(screen.getByTestId('denominations-load-button'))

    const cell = await screen.findByTestId('denom-cell-EUR-0')
    expect(cell.className).toContain('bg-red-50')
    expect(screen.getByTestId('denominations-issue-hint')).toHaveTextContent(
      hu.centralReceivedData.denominationsIssueHint,
    )
    expect(hu.centralReceivedData.denominationsIssueHint).toMatch(/nem pozitív|nempozitív/i)
  })

  it('az összesítő sáv a HUF-készletet mutatja, átváltott „összes érték” nélkül', async () => {
    mockLoad.mockResolvedValue(payload)
    render(<ReceivedDenominationsView />)
    await userEvent.click(screen.getByTestId('denominations-load-button'))

    const summary = await screen.findByTestId('denominations-summary')
    expect(summary).toHaveTextContent(hu.centralReceivedData.denominationsHufValue)
    expect(summary).toHaveTextContent(hu.centralReceivedData.denominationsNoConversionNote)
    expect(summary).toHaveTextContent('100 000,00')
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
      currencyCount: 0,
      totalQuantity: 0,
      dataQualityIssueCount: 0,
    })
    render(<ReceivedDenominationsView />)

    await userEvent.click(screen.getByTestId('denominations-load-button'))

    expect(await screen.findByText(hu.centralReceivedData.denominationsEmpty)).toBeInTheDocument()
  })
})
