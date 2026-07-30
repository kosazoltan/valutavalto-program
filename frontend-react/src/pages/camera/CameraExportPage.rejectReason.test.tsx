import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import CameraExportPage from './CameraExportPage'

// FKH-027 PR A (RED) — FR-7: a handleReject a natív prompt() helyett a közös
// TextReasonModal-lal kéri be az elutasítás indokát, "Elutasítás indoka" title-lel.

const mocks = vi.hoisted(() => ({
  createRequest: vi.fn(),
  approve: vi.fn(),
  approveSecond: vi.fn(),
  reject: vi.fn(),
  execute: vi.fn(),
  getById: vi.fn(),
  getPending: vi.fn(),
  getByBranch: vi.fn(),
  getCustody: vi.fn(),
  verifyChain: vi.fn(),
  listActive: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  cameraExportApi: {
    createRequest: mocks.createRequest,
    approve: mocks.approve,
    approveSecond: mocks.approveSecond,
    reject: mocks.reject,
    execute: mocks.execute,
    getById: mocks.getById,
    getPending: mocks.getPending,
    getByBranch: mocks.getByBranch,
    getCustody: mocks.getCustody,
    verifyChain: mocks.verifyChain,
  },
  branchApi: { listActive: mocks.listActive },
}))

const pendingRequest = {
  id: 'req-1',
  branchId: 'branch-1',
  cameraId: 'CAM-01',
  status: 'REQUESTED',
  periodFrom: '2026-07-29T08:00:00',
  periodTo: '2026-07-29T10:00:00',
  requestedBy: 'Kiss Anna',
  reason: 'Rendőrségi megkeresés',
  createdAt: '2026-07-29T11:00:00',
}

describe('CameraExportPage — FR-7: elutasítási indok a TextReasonModal-lal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getPending.mockResolvedValue({ data: [pendingRequest] })
    mocks.listActive.mockResolvedValue([])
    mocks.getCustody.mockResolvedValue({ data: [] })
    mocks.reject.mockResolvedValue({ data: { ...pendingRequest, status: 'REJECTED' } })
    // A natív promptot lecseréljük, hogy assertálható legyen: az új folyamat NEM hívja
    vi.spyOn(window, 'prompt').mockReturnValue(null)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  async function openRejectModal(user: ReturnType<typeof userEvent.setup>) {
    render(<CameraExportPage />)
    await user.click(await screen.findByRole('button', { name: 'Elutasítás' }))
    const dialog = await screen.findByRole('alertdialog')
    expect(dialog).toHaveAccessibleName('Elutasítás indoka')
    expect(window.prompt).not.toHaveBeenCalled()
    return dialog
  }

  it('string-ág: a megadott indokkal pontosan egyszer hívódik a cameraExportApi.reject', async () => {
    const user = userEvent.setup()
    const dialog = await openRejectModal(user)
    await user.type(within(dialog).getByRole('textbox'), 'Nem indokolt kérelem')
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() => expect(mocks.reject).toHaveBeenCalledWith('req-1', 'Nem indokolt kérelem'))
    expect(mocks.reject).toHaveBeenCalledTimes(1)
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
  })

  it('null-ág: Mégse után nem hívódik a cameraExportApi.reject', async () => {
    const user = userEvent.setup()
    const dialog = await openRejectModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'Mégse' }))
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.reject).not.toHaveBeenCalled()
  })

  it('üres string: a hívó-oldali validáció megmarad — üres indokkal nincs API-hívás', async () => {
    const user = userEvent.setup()
    const dialog = await openRejectModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.reject).not.toHaveBeenCalled()
  })
})
