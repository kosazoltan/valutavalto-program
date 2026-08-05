/**
 * printReceiptWithStoredConfig — a print-receipt IPC út config-feloldásának tesztje.
 *
 * Kontraktus: a main.ts print-receipt handlerében ma inline élő feloldás
 * (getConfig(PRINTER_CONFIG_KEY/SERIAL_PORT_CONFIG_KEY) → trim → fail-closed →
 * printReceipt) a printer.ts-be kerül exportált, tesztelhető függvényként, és a
 * handler ezt hívja. Így bizonyítható, hogy a most már ténylegesen beállítható
 * config-értékkel a fail-closed logika sikeresen nyomtat (mock szinten).
 */
import { describe, it, expect, vi, beforeEach, type Mock } from 'vitest';

const { printMock, getPrintersMock, configStore } = vi.hoisted(() => ({
  printMock: vi.fn((_opts: unknown, cb: (success: boolean, reason?: string) => void) => cb(true)),
  getPrintersMock: vi.fn().mockResolvedValue([
    {
      name: 'Star SP500',
      displayName: 'Star SP500',
      description: '',
      status: 0,
      isDefault: false,
    },
  ]),
  configStore: new Map<string, string>(),
}));

// FONTOS: `function` kell (nem arrow), mert a printer `new BrowserWindow(...)`-t hív.
vi.mock('electron', () => ({
  BrowserWindow: vi.fn().mockImplementation(function () {
    return {
      loadURL: vi.fn().mockResolvedValue(undefined),
      webContents: {
        print: printMock,
        getPrintersAsync: getPrintersMock,
      },
      isDestroyed: vi.fn(() => false),
      close: vi.fn(),
      show: false,
    };
  }),
}));

vi.mock('electron-log/main', () => ({
  default: {
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
  },
}));

vi.mock('../serial-printer', () => ({
  printReceiptToSerial: vi.fn().mockResolvedValue(false),
}));

// In-memory config store — a valós sqlite getConfig/setConfig szerződését követi
// (string | null vissza, kulcs-érték felülírás).
vi.mock('../sqlite', () => ({
  getConfig: (key: string): string | null => configStore.get(key) ?? null,
  setConfig: (key: string, value: string): void => {
    configStore.set(key, value);
  },
}));

import { printReceiptToSerial } from '../serial-printer';
import { setConfig } from '../sqlite';
import {
  printReceiptWithStoredConfig,
  PRINTER_CONFIG_KEY,
  SERIAL_PORT_CONFIG_KEY,
  type PrintReceiptData,
} from '../printer';

const baseData: PrintReceiptData = {
  type: 'sell',
  companyType: 'BEST_CHANGE',
  receiptNumber: 'BC-2026-001',
  branchCode: 'SZG-01',
  cashierName: 'Teszt Erika',
  date: '2026.03.24',
  time: '14:30',
  currencyCode: 'EUR',
  foreignAmount: 100,
  rate: 400,
  hufAmount: 40000,
  roundedHufAmount: 40000,
};

describe('printer — printReceiptWithStoredConfig (tárolt konfigból nyomtatás)', () => {
  beforeEach(() => {
    configStore.clear();
    vi.clearAllMocks();
    (printReceiptToSerial as Mock).mockResolvedValue(false);
  });

  it('konfig nélkül fail-closed: nem nyomtat', async () => {
    const result = await printReceiptWithStoredConfig(baseData);

    expect(result).toBe(false);
    expect(printMock).not.toHaveBeenCalled();
    expect(printReceiptToSerial).not.toHaveBeenCalled();
  });

  it('üres/whitespace tárolt értékek = nincs konfig (fail-closed)', async () => {
    setConfig(PRINTER_CONFIG_KEY, '');
    setConfig(SERIAL_PORT_CONFIG_KEY, '   ');

    const result = await printReceiptWithStoredConfig(baseData);

    expect(result).toBe(false);
    expect(printMock).not.toHaveBeenCalled();
  });

  it('tárolt printer.deviceName-mel silent Electron-nyomtatás sikeres', async () => {
    setConfig(PRINTER_CONFIG_KEY, 'Star SP500');

    const result = await printReceiptWithStoredConfig(baseData);

    expect(result).toBe(true);
    expect(printMock.mock.calls[0]![0]).toMatchObject({
      silent: true,
      deviceName: 'Star SP500',
    });
  });

  it('tárolt printer.serialPort-tal a soros út nyomtat, Electron-út nem indul', async () => {
    (printReceiptToSerial as Mock).mockResolvedValue(true);
    setConfig(SERIAL_PORT_CONFIG_KEY, 'COM3');

    const result = await printReceiptWithStoredConfig(baseData);

    expect(result).toBe(true);
    expect(printReceiptToSerial).toHaveBeenCalled();
    expect(printMock).not.toHaveBeenCalled();
  });

  it('a tárolt érték trimelve jut a nyomtatási rétegbe', async () => {
    setConfig(PRINTER_CONFIG_KEY, '  Star SP500  ');

    const result = await printReceiptWithStoredConfig(baseData);

    expect(result).toBe(true);
    expect(printMock.mock.calls[0]![0]).toMatchObject({ deviceName: 'Star SP500' });
  });
});
