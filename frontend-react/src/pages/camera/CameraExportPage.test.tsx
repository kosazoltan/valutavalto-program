import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import CameraExportPage from './CameraExportPage'

const mocks = vi.hoisted(() => ({
  branchListActive: vi.fn(),
  getPending: vi.fn(),
  getByBranch: vi.fn(),
  getById: vi.fn(),
  getCustody: vi.fn(),
  approve: vi.fn(),
  approveSecond: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  branchApi: {
    listActive: mocks.branchListActive,
  },
  cameraExportApi: {
    getPending: mocks.getPending,
    getByBranch: mocks.getByBranch,
    getById: mocks.getById,
    getCustody: mocks.getCustody,
    approve: mocks.approve,
    approveSecond: mocks.approveSecond,
  },
}))

describe('CameraExportPage dual approval contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.branchListActive.mockResolvedValue([
      { id: 'branch-1', code: 'BUD01', name: 'Budapest 01' },
    ])
    mocks.getCustody.mockResolvedValue({ data: [] })
    mocks.getByBranch.mockResolvedValue({
      data: [
        {
          id: 'export-1',
          branchId: 'branch-1',
          cameraId: 'CAM-01',
          periodFrom: '2026-06-18T08:00:00',
          periodTo: '2026-06-18T09:00:00',
          reason: 'Lista indok',
          status: 'REQUESTED',
          requestedBy: 'REQUESTER',
          createdAt: '2026-06-18T09:05:00',
        },
      ],
    })
    mocks.getById.mockResolvedValue({
      data: {
        id: 'export-1',
        branchId: 'branch-1',
        cameraId: 'CAM-01',
        periodFrom: '2026-06-18T08:00:00',
        periodTo: '2026-06-18T09:00:00',
        reason: 'Backend részlet indok',
        status: 'REQUESTED',
        requestedBy: 'REQUESTER',
        createdAt: '2026-06-18T09:05:00',
        exportPath: 'D:/exports/export-1.zip',
      },
    })
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

  it('export kérelem kiválasztásakor a GET /camera/export/{id} backend részletet tölti be', async () => {
    const user = userEvent.setup()
    render(<CameraExportPage />)

    await user.click(await screen.findByRole('button', { name: /camera\.ujExportKerelem/i }))
    await user.selectOptions(await screen.findByRole('combobox'), 'branch-1')
    await user.click(await screen.findByTestId('camera-export-request-export-1'))

    await waitFor(() => {
      expect(mocks.getById).toHaveBeenCalledWith('export-1')
      expect(mocks.getCustody).toHaveBeenCalledWith('export-1')
    })
    expect(await screen.findByText(/Backend részlet indok/)).toBeInTheDocument()
    expect(screen.getByText(/D:\/exports\/export-1\.zip/)).toBeInTheDocument()
  })
})
