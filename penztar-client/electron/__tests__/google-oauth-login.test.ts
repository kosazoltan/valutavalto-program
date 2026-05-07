import { describe, expect, it, vi, beforeEach } from 'vitest';
import { EventEmitter } from 'node:events';

vi.mock('electron-log/main', () => ({
  default: { warn: vi.fn(), info: vi.fn(), error: vi.fn() },
}));

const mockSetHeader = vi.fn();
const mockWrite = vi.fn();
const mockEnd = vi.fn();
const mockAbort = vi.fn();

let mockRequestEmitter: EventEmitter & {
  setHeader: typeof mockSetHeader;
  write: typeof mockWrite;
  end: typeof mockEnd;
  abort: typeof mockAbort;
};

function createMockRequest() {
  const emitter = new EventEmitter() as typeof mockRequestEmitter;
  emitter.setHeader = mockSetHeader;
  emitter.write = mockWrite;
  emitter.end = mockEnd;
  emitter.abort = mockAbort;
  return emitter;
}

vi.mock('electron', () => ({
  BrowserWindow: vi.fn(),
  net: {
    request: vi.fn(() => {
      mockRequestEmitter = createMockRequest();
      return mockRequestEmitter;
    }),
  },
}));

import { net as electronNet } from 'electron';
import { performPasswordLoginMainProcess } from '../google-oauth';

function triggerJsonResponse(body = '{"token":"ok"}') {
  const response = new EventEmitter() as EventEmitter & {
    statusCode: number;
    statusMessage: string;
  };
  response.statusCode = 200;
  response.statusMessage = 'OK';
  process.nextTick(() => {
    mockRequestEmitter.emit('response', response);
    response.emit('data', Buffer.from(body));
    response.emit('end');
  });
}

describe('performPasswordLoginMainProcess URL handling', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('engedelyezi a helyi/LAN backend URL-t a telepito altal beallitott server_url-hoz', async () => {
    const promise = performPasswordLoginMainProcess({
      apiBaseUrl: 'http://192.168.1.20:8080/api/v1',
      companyCode: 'EBC',
      workerCode: 'BORSI',
      password: 'Secret123!',
    });
    triggerJsonResponse();

    await expect(promise).resolves.toEqual({ token: 'ok' });
    expect(electronNet.request).toHaveBeenCalledWith({
      method: 'POST',
      url: 'http://192.168.1.20:8080/api/v1/auth/login',
    });
  });

  it('tetszoleges kulso backend hostot tovabbra is blokkol', async () => {
    await expect(performPasswordLoginMainProcess({
      apiBaseUrl: 'https://example.com/api/v1',
      companyCode: 'EBC',
      workerCode: 'BORSI',
      password: 'Secret123!',
    })).rejects.toMatchObject({ code: 'INVALID_URL' });
  });
});
