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
  shell: { openExternal: vi.fn() },
  net: {
    request: vi.fn(() => {
      mockRequestEmitter = createMockRequest();
      return mockRequestEmitter;
    }),
  },
}));

import { net as electronNet, shell } from 'electron';
import { cancelActiveGoogleOAuthFlow, performGoogleOAuthFlow, performPasswordLoginMainProcess } from '../google-oauth';

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
    vi.mocked(shell.openExternal).mockResolvedValue(undefined);
    cancelActiveGoogleOAuthFlow();
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

async function waitForOpenExternalCall() {
  for (let i = 0; i < 20; i += 1) {
    if (vi.mocked(shell.openExternal).mock.calls.length > 0) {
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, 5));
  }
  throw new Error('shell.openExternal was not called');
}

describe('performGoogleOAuthFlow', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(shell.openExternal).mockResolvedValue(undefined);
    cancelActiveGoogleOAuthFlow();
  });

  it('Google OAuth flow-t rendszerbongeszoben inditja, nem beagyazott Electron ablakban', async () => {
    await expect(performGoogleOAuthFlow({
      clientId: 'desktop-client-id',
      clientSecret: 'desktop-secret',
      timeoutMs: 1,
    })).rejects.toMatchObject({
      code: 'TIMEOUT',
      message: expect.stringContaining('bezarhatta a bongeszot'),
    });

    expect(shell.openExternal).toHaveBeenCalledWith(expect.stringContaining('https://accounts.google.com/o/oauth2/v2/auth'));
  });

  it('kulon hibakoddal jelzi, ha a rendszerbongeszo nem nyithato meg', async () => {
    vi.mocked(shell.openExternal).mockRejectedValueOnce(new Error('no browser'));

    await expect(performGoogleOAuthFlow({
      clientId: 'desktop-client-id',
      clientSecret: 'desktop-secret',
      timeoutMs: 30_000,
    })).rejects.toMatchObject({
      code: 'BROWSER_OPEN_FAILED',
      message: expect.stringContaining('no browser'),
    });

    expect(cancelActiveGoogleOAuthFlow()).toBe(false);
  });

  it('az aktiv rendszerbongeszős OAuth flow explicit megszakithato', async () => {
    const promise = performGoogleOAuthFlow({
      clientId: 'desktop-client-id',
      clientSecret: 'desktop-secret',
      timeoutMs: 30_000,
    });

    await waitForOpenExternalCall();

    expect(cancelActiveGoogleOAuthFlow()).toBe(true);
    await expect(promise).rejects.toMatchObject({ code: 'USER_CANCELLED' });
  });
});
