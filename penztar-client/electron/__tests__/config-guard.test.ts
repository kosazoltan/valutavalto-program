import { describe, expect, it } from 'vitest';
import {
  CONFIG_READ_ALLOWLIST,
  CONFIG_WRITE_ALLOWLIST,
  SENSITIVE_READ_KEY_PATTERN,
  SENSITIVE_WRITE_KEY_PATTERN,
  isConfigKeyReadable,
  isConfigKeyWritable,
  sanitizeStoredServerUrl,
} from '../config-guard';

describe('config-guard — read access', () => {
  it.each([
    'app_mode',
    'offline_mode',
    'branch_code',
    'server_url',
    'camera_configs',
    'rate_maker_device_id',
  ])('allows the renderer key `%s`', (key) => {
    expect(isConfigKeyReadable(key)).toBe(true);
  });

  it.each([
    'bootstrap_password',
    'bootstrap_password_encrypted',
    'auth_token',
    'server_url_fallback_primary',
    'google_sub',
    'install_uuid',
    'unknown_key',
  ])('rejects the renderer key `%s`', (key) => {
    expect(isConfigKeyReadable(key)).toBe(false);
  });
});

describe('config-guard — write access', () => {
  it.each(['camera_configs', 'rate_maker_device_id'])('allows the renderer key `%s`', (key) => {
    expect(isConfigKeyWritable(key)).toBe(true);
  });

  it.each([
    'server_url',
    'server_url_fallback_primary',
    'server_url_fallback',
    'server_url_fallback_secondary',
    'bootstrap_password',
    'auth_token',
    'app_mode',
    'unknown_key',
  ])('rejects the renderer key `%s`', (key) => {
    expect(isConfigKeyWritable(key)).toBe(false);
  });
});

describe('config-guard — allowlist and deny-pattern consistency', () => {
  it('does not let either direction-specific deny pattern cancel its own allowlist', () => {
    expect(CONFIG_READ_ALLOWLIST.every(isConfigKeyReadable)).toBe(true);
    expect(CONFIG_WRITE_ALLOWLIST.every(isConfigKeyWritable)).toBe(true);
  });

  it('keeps server_url readable but never renderer-writable', () => {
    expect(SENSITIVE_READ_KEY_PATTERN.test('server_url')).toBe(false);
    expect(SENSITIVE_WRITE_KEY_PATTERN.test('server_url')).toBe(true);
  });

  it('keeps deny-pattern matches blocked before allowlist consideration', () => {
    const readAllowlistWithSecret = [...CONFIG_READ_ALLOWLIST, 'my_token_cache'];
    const writeAllowlistWithServerUrl = [...CONFIG_WRITE_ALLOWLIST, 'server_url_fallback_primary'];

    expect(
      readAllowlistWithSecret.some(
        (key) => SENSITIVE_READ_KEY_PATTERN.test(key) && !isConfigKeyReadable(key),
      ),
    ).toBe(true);
    expect(
      writeAllowlistWithServerUrl.some(
        (key) => SENSITIVE_WRITE_KEY_PATTERN.test(key) && !isConfigKeyWritable(key),
      ),
    ).toBe(true);
  });
});

describe('config-guard — printer kulcsok (SP500 nyomtató-konfiguráció)', () => {
  it.each(['printer.deviceName', 'printer.serialPort'])('renderer-ből írható: `%s`', (key) => {
    expect(isConfigKeyWritable(key)).toBe(true);
  });

  it.each(['printer.deviceName', 'printer.serialPort'])(
    'renderer-ből olvasható (mentés utáni visszaolvasáshoz): `%s`',
    (key) => {
      expect(isConfigKeyReadable(key)).toBe(true);
    },
  );

  it('a printer-bővítés nem nyit meg más kulcsot', () => {
    expect(isConfigKeyWritable('printer.unknown')).toBe(false);
    expect(isConfigKeyWritable('printer')).toBe(false);
    expect(isConfigKeyWritable('app_mode')).toBe(false);
    expect(isConfigKeyWritable('bootstrap_password')).toBe(false);
    expect(isConfigKeyWritable('auth_token')).toBe(false);
    expect(isConfigKeyWritable('server_url')).toBe(false);
  });
});

describe('config-guard — stored server URL', () => {
  it.each([
    ['  https://backend.local/api/v1  ', 'https://backend.local/api/v1'],
    ['http://192.168.1.10:8080/api/v1', 'http://192.168.1.10:8080/api/v1'],
    ['http://user:pass@backend.local/api/v1', 'http://backend.local/api/v1'],
    ['https://backend.local/api/v1?x=1#frag', 'https://backend.local/api/v1'],
    ['https://backend.local/api/v1/', 'https://backend.local/api/v1'],
    ['https://backend.local', 'https://backend.local'],
  ])('accepts `%s`', (raw, expected) => {
    expect(sanitizeStoredServerUrl(raw)).toBe(expected);
  });

  it.each(['', '   ', 'ftp://x', 'javascript:alert(1)', 'not a url', null])(
    'rejects `%s`',
    (raw) => {
      expect(sanitizeStoredServerUrl(raw)).toBeNull();
    },
  );
});
