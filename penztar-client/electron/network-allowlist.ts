export function isStaticAllowedHost(hostname: string, allowedHosts: readonly string[]): boolean {
  const host = hostname.toLowerCase();
  return allowedHosts.some((allowedHost) => {
    const allowed = allowedHost.toLowerCase();
    return host === allowed || host.endsWith(`.${allowed}`);
  });
}

export function isPrivateOrLoopbackHost(hostname: string): boolean {
  const host = hostname.toLowerCase();
  if (host === 'localhost' || host === '127.0.0.1' || host === '::1' || host === '[::1]') {
    return true;
  }
  const parts = host.split('.').map((part) => Number.parseInt(part, 10));
  if (parts.length !== 4 || parts.some((part) => Number.isNaN(part) || part < 0 || part > 255)) {
    return false;
  }
  const a = parts[0] ?? -1;
  const b = parts[1] ?? -1;
  return a === 10
    || (a === 172 && b >= 16 && b <= 31)
    || (a === 192 && b === 168)
    || a === 127;
}

export function isConfiguredPrivateOrLoopbackTarget(target: URL, configuredBaseUrl?: string | null): boolean {
  if (!isPrivateOrLoopbackHost(target.hostname)) {
    return false;
  }
  if (!configuredBaseUrl?.trim()) {
    return false;
  }
  try {
    const configured = new URL(configuredBaseUrl);
    return isPrivateOrLoopbackHost(configured.hostname) && configured.origin === target.origin;
  } catch {
    return false;
  }
}

export function isAllowedNetworkUrl(
  raw: string,
  allowedHosts: readonly string[],
  configuredBaseUrl?: string | null,
): boolean {
  try {
    const parsed = new URL(raw);
    return isStaticAllowedHost(parsed.hostname, allowedHosts)
      || isConfiguredPrivateOrLoopbackTarget(parsed, configuredBaseUrl);
  } catch {
    return false;
  }
}
