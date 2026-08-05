/**
 * Renderer-facing config guards for VV-017/VV-004.
 *
 * The exact keys come from the verified renderer caller table in the approved
 * wave 2a plan. Main-process config access does not pass through these guards.
 */

export const SENSITIVE_READ_KEY_PATTERN = /password|token|secret|_sub/i;
export const SENSITIVE_WRITE_KEY_PATTERN =
  /password|token|secret|_sub|^bootstrap_|^server_url|^auth_token/i;

export const CONFIG_READ_ALLOWLIST = [
  'app_mode',
  'offline_mode',
  'branch_code',
  'server_url',
  'camera_configs',
  // Shared bundle — rate-maker flavor uses this (exchange-rates.ts:562); DO NOT REMOVE without verifying tree-shaking doesn't strip the call site in penztar builds.
  'rate_maker_device_id',
  // SP500 nyomtató-konfiguráció: a beállítás-oldal mentés utáni visszaolvasása.
  // A main-process print-receipt handler NEM ezen a guardon át olvas.
  'printer.deviceName',
  'printer.serialPort',
] as const;

export const CONFIG_WRITE_ALLOWLIST = [
  'camera_configs',
  // Shared bundle — rate-maker flavor uses this (exchange-rates.ts:562); DO NOT REMOVE without verifying tree-shaking doesn't strip the call site in penztar builds.
  'rate_maker_device_id',
  // SP500 nyomtató-konfiguráció: üres string = nincs beállítva (fail-closed marad).
  'printer.deviceName',
  'printer.serialPort',
] as const;

export function isConfigKeyReadable(key: string): boolean {
  if (SENSITIVE_READ_KEY_PATTERN.test(key)) return false;
  return (CONFIG_READ_ALLOWLIST as readonly string[]).includes(key);
}

export function isConfigKeyWritable(key: string): boolean {
  if (SENSITIVE_WRITE_KEY_PATTERN.test(key)) return false;
  return (CONFIG_WRITE_ALLOWLIST as readonly string[]).includes(key);
}

/**
 * Validates the stored URL protocol and returns a credential-free normalized
 * form. Userinfo, query, fragment, and trailing slashes are removed. Host
 * allowlisting, including the link-local block, remains centralized in
 * api-proxy.ts `isAllowedUrl`.
 */
export function sanitizeStoredServerUrl(raw: string | null | undefined): string | null {
  const trimmed = raw?.trim() ?? '';
  if (!trimmed) return null;

  try {
    const parsed = new URL(trimmed);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') return null;
    return parsed.origin + parsed.pathname.replace(/\/+$/, '');
  } catch {
    return null;
  }
}
