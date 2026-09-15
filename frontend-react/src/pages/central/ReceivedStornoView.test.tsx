import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ReceivedStornoView from './ReceivedStornoView'
import hu from '../../i18n/hu.json'

const mockLoad = vi.fn()

vi.mock('../../services/api/received-storno', () => ({
  receivedStornoApi: {
    load: (...args: unknown[]) => mockLoad(...args),
  },
}))

const payload = {
  fromDate: '2026-09-10',
  toDate: '2026-09-12',
  branchId: null,
  vaultTerritoryId: null,
  branches: [
    {
      id: '20000000-0000-0000-0000-00000000000a',
      code: 'ET1',
      name: 'Szeged Értéktár',
      isVault: true,
      vaultTerritoryId: 2,
      region: 'Szeged',
    },
  ],
  territories: [{ id: 2, name: 'Szeged' }],
  rows: [
    {
      type: 'TRANSFER',
      officeCode: 'ET1',
      officeName: 'Szeged Értéktár',
      date: '2026-09-12',
      time: '15:00:00',
      originalDocumentNumber: 'AT-9',
      stornoDocumentNumber: 'AT-9-SZ',
      workerName: 'Nagy Péter',
      reason: 'hibás összeg',
      lines: [{ currencyCode: 'HUF', amount: 5000, hufValue: 5000, rateMissing: false }],
    },
    {
      type: 'SALE_PURCHASE',
      officeCode: 'BR001',
      officeName: 'Dombóvár',
      date: '2026-09-10',
      time: '10:00:00',
      originalDocumentNumber: 'V-100',
      stornoDocumentNumber: 'V-100-SZ',
      workerName: 'Kovács Anna',
      reason: 'ügyfél kérése',
      lines: [{ currencyCode: 'EUR', amount: 100, hufValue: 38000, rateMissing: false }],
    },
  ],
}

describe('ReceivedStornoView — FK-115', () => {
  beforeEach(() => {
    mockLoad.mockReset()
  })

  it('nem kérdez le automatikusan betöltéskor', () => {
    render(<ReceivedStornoView />)
    expect(mockLoad).not.toHaveBeenCalled()
    expect(screen.getByText(hu.centralReceivedData.stornoPrompt)).toBeInTheDocument()
  })

  it('Lekérdezés gombra megjeleníti az egyesített listát, drill-down a sorokra', async () => {
    mockLoad.mockResolvedValue(payload)
    render(<ReceivedStornoView />)
    await userEvent.click(screen.getByTestId('storno-load-button'))

    expect(await screen.findByTestId('storno-row-AT-9-SZ')).toBeInTheDocument()
    expect(screen.getByText('AT-9 → AT-9-SZ')).toBeInTheDocument()
    expect(screen.getByText('V-100 → V-100-SZ')).toBeInTheDocument()
    expect(screen.queryByTestId('storno-lines-AT-9-SZ')).not.toBeInTheDocument()

    await userEvent.click(screen.getByTestId('storno-expand-AT-9-SZ'))
    expect(screen.getByTestId('storno-lines-AT-9-SZ')).toBeInTheDocument()
    expect(screen.getByText(hu.centralReceivedData.stornoAmount)).toBeInTheDocument()
    await waitFor(() => {
      expect(mockLoad).toHaveBeenCalledTimes(1)
    })
  })

  it('terület-szűrő a vault_territory_id-t küldi, nem a region_code-ot', async () => {
    mockLoad.mockResolvedValue(payload)
    render(<ReceivedStornoView />)
    await userEvent.click(screen.getByTestId('storno-load-button'))
    await screen.findByTestId('storno-row-AT-9-SZ')

    await userEvent.selectOptions(screen.getByTestId('storno-unit-select'), 'territory:2')
    await userEvent.click(screen.getByTestId('storno-load-button'))

    expect(mockLoad).toHaveBeenLastCalledWith(
      expect.any(String),
      expect.any(String),
      expect.objectContaining({ vaultTerritoryId: 2, branchId: null }),
    )
  })
})
