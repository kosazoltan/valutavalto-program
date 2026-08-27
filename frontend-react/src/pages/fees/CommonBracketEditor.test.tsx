import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CommonBracketEditor from './CommonBracketEditor'

const mocks = vi.hoisted(() => ({
  get: vi.fn(),
  saveDraft: vi.fn(),
  publish: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../services/api/settings', () => ({
  handlingFeeBracketApi: { get: mocks.get, saveDraft: mocks.saveDraft, publish: mocks.publish },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: mocks.loggerError },
}))

const LIVE = [{ bracketOrder: 1, upperLimit: 100000, feeAmount: 200, active: true }]
const DRAFT = [{ bracketOrder: 1, upperLimit: 100000, feeAmount: 999, active: true }]

describe('CommonBracketEditor', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.get.mockResolvedValue({ live: LIVE, draft: [] })
  })

  it('megjeleníti a LIVE és (ha van) a DRAFT sáv-táblát', async () => {
    mocks.get.mockResolvedValue({ live: LIVE, draft: DRAFT })
    render(<CommonBracketEditor />)

    expect(await screen.findByText('Éles (LIVE) sávok')).toBeInTheDocument()
    expect(screen.getByText('Piszkozat (DRAFT) sávok')).toBeInTheDocument()
  })

  it('a Mentés (piszkozat) saveDraft-ot hív, és NEM publish-t', async () => {
    const user = userEvent.setup()
    mocks.saveDraft.mockResolvedValue({ live: LIVE, draft: LIVE })
    render(<CommonBracketEditor />)
    await screen.findByText('Éles (LIVE) sávok')

    await user.click(screen.getByRole('button', { name: 'Mentés (piszkozat)' }))

    await waitFor(() => {
      expect(mocks.saveDraft).toHaveBeenCalledTimes(1)
    })
    expect(mocks.publish).not.toHaveBeenCalled()
  })

  it('a Küldés megerősítéssel hív publish-t; megerősítés nélkül nem', async () => {
    const user = userEvent.setup()
    mocks.publish.mockResolvedValue({ live: LIVE, draft: [] })
    render(<CommonBracketEditor />)
    await screen.findByText('Éles (LIVE) sávok')

    await user.click(screen.getByRole('button', { name: 'Küldés' }))
    expect(mocks.publish).not.toHaveBeenCalled()

    const dialog = await screen.findByRole('alertdialog')
    expect(
      within(dialog).getByText('Biztosan elküldöd? Minden sávos irodára azonnal érvényes lesz.'),
    ).toBeInTheDocument()
    await user.click(within(dialog).getByRole('button', { name: 'Küldés megerősítése' }))

    await waitFor(() => {
      expect(mocks.publish).toHaveBeenCalledTimes(1)
    })
  })
})
