import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CameraExportPage from './CameraExportPage'

const mocks = vi.hoisted(() => ({
  branchListActive: vi.fn(),
  getPending: vi.fn(),
  getCustody: vi.fn(),
  approve: vi.fn(),
  approveSecond: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  branchApi: {
    listActive: mocks.branchListActive,
  },
  cameraExportApi: {
    getPending: mocks.getPending,
    getCustody: mocks.getCustody,
    approve: mocks.approve,
    approveSecond: mocks.approveSecond,
  },
}))

describe('CameraExportPage dual approval contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.branchListActive.mockResolvedValue([])
    mocks.getCustody.mockResolvedValue({ data: [] })
    mocks.getPending.mockResolvedValue({
      data: [
        {
          id: 'export-1',
          branchId: 'branch-1',
          cameraId: 'CAM-01',
          periodFrom: '2026-06-18T08:00:00',
          periodTo: '2026-06-18T09:00:00',
          reason: 'Rendőrségi megkeresés',
          status: 'AWAITING_SECOND_APPROVAL',
          requestedBy: 'REQUESTER',
          createdAt: '2026-06-18T09:05:00',
          approvedBy: 'APPROVER-1',
          approvedAt: '2026-06-18T09:10:00',
          requiresDualApproval: true,
        },
      ],
    })
    mocks.approveSecond.mockResolvedValue({
      data: {
        id: 'export-1',
        branchId: 'branch-1',
        status: 'APPROVED',
        requestedBy: 'REQUESTER',
        createdAt: '2026-06-18T09:05:00',
        periodFrom: '2026-06-18T08:00:00',
        periodTo: '2026-06-18T09:00:00',
        reason: 'Rendőrségi megkeresés',
        secondApprovedBy: 'APPROVER-2',
        secondApprovedAt: '2026-06-18T09:20:00',
      },
    })
  })

  it('AWAITING_SECOND_APPROVAL státusznál a második jóváhagyás endpointot hívja', async () => {
    const user = userEvent.setup()
    render(<CameraExportPage />)

    await user.click(await screen.findByRole('button', { name: /Második jóváhagyás/i }))

    await waitFor(() => {
      expect(mocks.approveSecond).toHaveBeenCalledWith('export-1')
      expect(mocks.approve).not.toHaveBeenCalled()
    })
  })
})
