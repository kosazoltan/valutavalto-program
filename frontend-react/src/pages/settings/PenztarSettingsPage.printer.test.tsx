/**
 * SP500 nyomtató-konfiguráció komponens-tesztek (RED → GREEN).
 *
 * Kontraktus: a PenztarSettingsPage a meglévő háromrétegű machine_config mintát
 * követve (localStorage + backend PUT /machine-config/{code}) KIEGÉSZÜL az
 * Electron SQLite config írásával (printer.deviceName / printer.serialPort),
 * mert a main-process print-receipt handler (main.ts:390-403) onnan olvas.
 *
 * - nyomtatólista: window.electronAPI.getPrinters()
 * - soros portok: window.electronAPI.listSerialPorts()
 * - mentés: setConfig('printer.deviceName', ...) + setConfig('printer.serialPort', ...)
 * - visszaolvasás (újraindítás-túlélés): getConfig(...) értéke jelenik meg
 */
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { MemoryRouter } from 'react-router-dom'
import PenztarSettingsPage from './PenztarSettingsPage'

const mocks = vi.hoisted(() => ({
  machineGet: vi.fn(),
  machinePut: vi.fn(),
  resolveWorkstationCode: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
}))

vi.mock('../../services/api/machineConfig', () => ({
  machineConfigApi: {
    get: mocks.machineGet,
    put: mocks.machinePut,
  },
  resolveWorkstationCode: mocks.resolveWorkstationCode,
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: mocks.toastSuccess,
    error: mocks.toastError,
  },
}))

const electronAPI = {
  getPrinters: vi.fn(),
  listSerialPorts: vi.fn(),
  getConfig: vi.fn(),
  setConfig: vi.fn(),
}

function renderPage() {
  return render(
    <MemoryRouter>
      <PenztarSettingsPage />
    </MemoryRouter>,
  )
}

describe('PenztarSettingsPage — SP500 nyomtató-konfiguráció', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    mocks.resolveWorkstationCode.mockResolvedValue('BR001')
    mocks.machineGet.mockResolvedValue(null)
    mocks.machinePut.mockResolvedValue({
      workstationCode: 'BR001',
      dailyReportPasswordSet: false,
      updatedAt: null,
    })
    electronAPI.getPrinters.mockResolvedValue([
      {
        name: 'Star SP500',
        displayName: 'Star SP500',
        description: '',
        status: 0,
        isDefault: false,
      },
      {
        name: 'Microsoft Print to PDF',
        displayName: 'Microsoft Print to PDF',
        description: '',
        status: 0,
        isDefault: true,
      },
    ])
    electronAPI.listSerialPorts.mockResolvedValue([
      { path: 'COM3', friendlyName: 'USB Serial Port (COM3)' },
    ])
    electronAPI.getConfig.mockResolvedValue(null)
    electronAPI.setConfig.mockResolvedValue(undefined)
    ;(window as unknown as { electronAPI?: unknown }).electronAPI = electronAPI
  })

  afterEach(() => {
    delete (window as unknown as { electronAPI?: unknown }).electronAPI
  })

  it('nyomtatólistát és soros portokat tölt; kiválasztás után mindkét printer-kulcsot menti', async () => {
    const user = userEvent.setup()
    renderPage()

    const printerSelect = await screen.findByLabelText(/Windows-nyomtató/)
    await screen.findByRole('option', { name: /Star SP500/ })
    await user.selectOptions(printerSelect, 'Star SP500')

    const serialSelect = await screen.findByLabelText(/Soros port/)
    await screen.findByRole('option', { name: /COM3/ })
    await user.selectOptions(serialSelect, 'COM3')

    await user.click(screen.getByRole('button', { name: /Rögzítés és kilépés/ }))

    // Operatív réteg: Electron SQLite config (ebből olvas a print-receipt handler)
    await waitFor(() => {
      expect(electronAPI.setConfig).toHaveBeenCalledWith('printer.deviceName', 'Star SP500')
      expect(electronAPI.setConfig).toHaveBeenCalledWith('printer.serialPort', 'COM3')
    })

    // Háromrétegű minta: a machine_config JSON-ban is utaznak a printer-mezők
    await waitFor(() => expect(mocks.machinePut).toHaveBeenCalled())
    const putBody = mocks.machinePut.mock.calls[0]![1] as { configJson: string }
    const cfg = JSON.parse(putBody.configJson) as {
      printerDeviceName: string
      printerSerialPort: string
    }
    expect(cfg.printerDeviceName).toBe('Star SP500')
    expect(cfg.printerSerialPort).toBe('COM3')
  })

  it('mentés utáni visszaolvasás: a SQLite-ban tárolt érték jelenik meg (újraindítás-túlélés)', async () => {
    electronAPI.getConfig.mockImplementation(async (key: string) => {
      if (key === 'printer.deviceName') return 'Star SP500'
      if (key === 'printer.serialPort') return 'COM3'
      if (key === 'branch_code') return 'BR001'
      return null
    })

    renderPage()

    const printerSelect = await screen.findByLabelText(/Windows-nyomtató/)
    await waitFor(() => expect(printerSelect).toHaveValue('Star SP500'))
    const serialSelect = await screen.findByLabelText(/Soros port/)
    await waitFor(() => expect(serialSelect).toHaveValue('COM3'))
  })

  it('kiválasztás nélkül üres értéket ír (a fail-closed állapot megmarad)', async () => {
    const user = userEvent.setup()
    renderPage()

    await screen.findByLabelText(/Windows-nyomtató/)
    await user.click(screen.getByRole('button', { name: /Rögzítés és kilépés/ }))

    await waitFor(() => {
      expect(electronAPI.setConfig).toHaveBeenCalledWith('printer.deviceName', '')
      expect(electronAPI.setConfig).toHaveBeenCalledWith('printer.serialPort', '')
    })
  })
})
