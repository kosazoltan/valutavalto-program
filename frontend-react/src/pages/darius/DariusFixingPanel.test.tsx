import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { AxiosError } from 'axios'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import DariusFixingPanel from './DariusFixingPanel'

const mocks = vi.hoisted(() => ({
  bankBranches: vi.fn(),
  createBankBranch: vi.fn(),
  deactivateBankBranch: vi.fn(),
  list: vi.fn(),
  create: vi.fn(),
  updateLines: vi.fn(),
  approve: vi.fn(),
  cancel: vi.fn(),
  getActiveCurrencies: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  dariusFixingApi: {
    bankBranches: mocks.bankBranches,
    createBankBranch: mocks.createBankBranch,
    deactivateBankBranch: mocks.deactivateBankBranch,
    list: mocks.list,
    create: mocks.create,
    updateLines: mocks.updateLines,
    approve: mocks.approve,
    cancel: mocks.cancel,
  },
  currencyApi: {
    getActive: mocks.getActiveCurrencies,
  },
}))

const branch = {
  id: 'branch-1',
  bankBranchCode: 'RFBUD01',
  name: 'Raiffeisen Budapest',
  active: true,
}

const draftRequest = {
  id: 'draft-1',
  bankBranchId: branch.id,
  bankBranchCode: branch.bankBranchCode,
  bankBranchName: branch.name,
  requestDate: '2026-07-11',
  status: 'DRAFT',
  note: 'Napi fixing',
  createdBy: 'ADMIN',
  createdAt: '2026-07-11T08:00:00',
  lines: [{ currencyCode: 'EUR', deliveredAmount: 100, collectedAmount: 20 }],
}

const includedRequest = {
  ...draftRequest,
  id: 'included-1',
  status: 'INCLUDED',
}

describe('DariusFixingPanel', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.bankBranches.mockResolvedValue({ data: [branch] })
    mocks.list.mockResolvedValue({ data: [] })
    mocks.getActiveCurrencies.mockResolvedValue([
      { id: 1, code: 'EUR', name: 'Euró', displayOrder: 1 },
      { id: 2, code: 'USD', name: 'USA dollár', displayOrder: 2 },
    ])
    mocks.create.mockResolvedValue({ data: draftRequest })
    mocks.updateLines.mockResolvedValue({ data: draftRequest })
    mocks.approve.mockResolvedValue({ data: { ...draftRequest, status: 'APPROVED' } })
    mocks.cancel.mockResolvedValue({ data: { ...draftRequest, status: 'CANCELLED' } })
    mocks.createBankBranch.mockResolvedValue({ data: branch })
    mocks.deactivateBankBranch.mockResolvedValue({ data: { ...branch, active: false } })
  })

  it('aktív bankfiók nélkül figyelmeztet és letiltja az igény rögzítését', async () => {
    mocks.bankBranches.mockResolvedValue({ data: [] })

    render(<DariusFixingPanel date="2026-07-11" />)

    expect(
      await screen.findByText(
        'Nincs bankfiók-azonosító konfigurálva — fixing-igény nem rögzíthető',
      ),
    ).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Igény rögzítése' })).toBeDisabled()
  })

  it('érvényes űrlappal a kiválasztott bankfiókra és napra hozza létre az igényt', async () => {
    const user = userEvent.setup()
    render(<DariusFixingPanel date="2026-07-11" />)

    await user.selectOptions(await screen.findByLabelText('Bankfiók'), branch.id)
    await user.selectOptions(screen.getByLabelText('Valutanem 1'), 'EUR')
    await user.type(screen.getByLabelText('Beszállított összeg 1'), '100')
    await user.type(screen.getByLabelText('Megjegyzés'), ' Napi fixing ')
    await user.click(screen.getByRole('button', { name: 'Igény rögzítése' }))

    await waitFor(() => {
      expect(mocks.create).toHaveBeenCalledWith({
        bankBranchId: branch.id,
        requestDate: '2026-07-11',
        note: 'Napi fixing',
        lines: [{ currencyCode: 'EUR', deliveredAmount: 100, collectedAmount: 0 }],
      })
    })
  })

  it('csak a módosítható státuszokhoz jelenít meg műveleteket', async () => {
    mocks.list.mockResolvedValue({ data: [draftRequest, includedRequest] })
    render(<DariusFixingPanel date="2026-07-11" />)

    const draftRow = await screen.findByTestId('fixing-request-draft-1')
    expect(within(draftRow).getByRole('button', { name: 'Jóváhagy' })).toBeInTheDocument()
    expect(within(draftRow).getByRole('button', { name: 'Szerkeszt' })).toBeInTheDocument()
    expect(within(draftRow).getByRole('button', { name: 'Visszavon' })).toBeInTheDocument()

    const includedRow = screen.getByTestId('fixing-request-included-1')
    expect(within(includedRow).queryByRole('button')).not.toBeInTheDocument()
  })

  it('ismeretlen backend státuszt biztonságos szürke badge-ként jelenít meg', async () => {
    mocks.list.mockResolvedValue({
      data: [{ ...draftRequest, id: 'unknown-1', status: 'UNKNOWN' }],
    })

    render(<DariusFixingPanel date="2026-07-11" />)

    const row = await screen.findByTestId('fixing-request-unknown-1')
    const badge = within(row).getByText('UNKNOWN')
    expect(badge).toHaveClass('bg-gray-100', 'text-gray-700')
    expect(within(row).queryByRole('button')).not.toBeInTheDocument()
  })

  it('a jóváhagyási hibát sanitizált üzenetként jeleníti meg és duplakattintásra sem dupláz', async () => {
    let rejectApprove: ((reason?: unknown) => void) | undefined
    mocks.list.mockResolvedValue({ data: [draftRequest] })
    mocks.approve.mockReturnValue(
      new Promise((_resolve, reject) => {
        rejectApprove = reject
      }),
    )
    render(<DariusFixingPanel date="2026-07-11" />)

    const approveButton = await screen.findByRole('button', { name: 'Jóváhagy' })
    fireEvent.click(approveButton)
    fireEvent.click(approveButton)
    expect(mocks.approve).toHaveBeenCalledTimes(1)

    const approveError = new AxiosError('Request failed')
    Object.assign(approveError, {
      response: { data: { message: 'A jóváhagyás nem engedélyezett.' } },
    })
    rejectApprove?.(approveError)
    expect(await screen.findByText('A jóváhagyás nem engedélyezett.')).toBeInTheDocument()
  })
})
