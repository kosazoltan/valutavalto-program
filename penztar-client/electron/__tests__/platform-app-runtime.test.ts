/**
 * Platform app-runtime modul — BIZTONSAGI jellemzo-tesztek.
 *
 * MIERT KELL: a media-permission szabaly (F-006: non-media = default DENY,
 * media = explicit origin-allowlist) es az `app:` protokoll path-traversal
 * vedelme korabban HAROM masolatban elt a kliensekben. A kiemeles utan egy
 * forras van — ezert a szabalyt itt kell gepileg rogziteni, kulonben egy
 * kesobbi "egyszerusites" csendben default-allow-ra valthatna.
 *
 * A modul `electron`-t importal (`net`, `protocol`), ezert az mockolva van.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';

const netFetchMock = vi.fn((url: string) => Promise.resolve({ url } as unknown as Response));

vi.mock('electron', () => ({
  net: { fetch: (url: string) => netFetchMock(url) },
  protocol: { handle: vi.fn() },
}));

const { createMediaPermissionHandler, createAppProtocolHandler, promoteUserDataEnv } = await import(
  '../../../packages/electron-platform/src/app-runtime'
);

function makeLogger() {
  return { info: vi.fn(), warn: vi.fn(), error: vi.fn() };
}

/** A handlert szinkron callback-kel hivja, es visszaadja a dontest. */
function askPermission(
  handler: ReturnType<typeof createMediaPermissionHandler>,
  permission: string,
  requestingUrl?: string,
): boolean {
  let granted: boolean | undefined;
  handler(
    {} as never,
    permission as never,
    (allowed: boolean) => {
      granted = allowed;
    },
    { requestingUrl } as never,
  );
  if (granted === undefined) throw new Error('a handler nem hivta meg a callbacket');
  return granted;
}

describe('createMediaPermissionHandler — F-006 default-deny', () => {
  const logger = makeLogger();
  const handler = createMediaPermissionHandler(logger);

  it.each(['notifications', 'geolocation', 'midi', 'clipboard-read', 'openExternal'])(
    'elutasitja a non-media permission-t: %s',
    (permission) => {
      expect(askPermission(handler, permission, 'https://excvaluta.com/app')).toBe(false);
    },
  );

  it.each([
    'app://localhost/index.html',
    'http://localhost:3000/',
    'https://excvaluta.com/cashier',
  ])('engedelyezi a media permission-t megbizhato originrol: %s', (url) => {
    expect(askPermission(handler, 'media', url)).toBe(true);
  });

  it.each([
    // A klasszikus startsWith-tamadas: NEM mehet at (Codex P1 + CodeQL + Copilot).
    'https://excvaluta.com.attacker.example/evil',
    'https://evil.example/excvaluta.com',
    // Helyes hostname, de nem-https sema.
    'ftp://excvaluta.com/',
    // app: sema idegen hosttal.
    'app://evil/index.html',
    // localhost, de https (nem szerepel az allowlistan).
    'https://localhost/',
  ])('elutasitja a media permission-t idegen originrol: %s', (url) => {
    expect(askPermission(handler, 'media', url)).toBe(false);
  });

  it('elutasit, ha a requestingUrl hianyzik vagy nem parse-olhato', () => {
    expect(askPermission(handler, 'media', undefined)).toBe(false);
    expect(askPermission(handler, 'media', 'nem-egy-url')).toBe(false);
  });
});

describe('createAppProtocolHandler — path traversal', () => {
  const distPath = '/app/dist';
  let logger: ReturnType<typeof makeLogger>;

  beforeEach(() => {
    netFetchMock.mockClear();
    logger = makeLogger();
  });

  /** Visszaadja a `net.fetch`-nek atadott file URL-t. */
  async function servedUrl(requestUrl: string): Promise<string> {
    const handler = createAppProtocolHandler(distPath, logger);
    await handler({ url: requestUrl } as never);
    expect(netFetchMock).toHaveBeenCalledTimes(1);
    return String(netFetchMock.mock.calls[0]?.[0]);
  }

  it('a gyoker-kerest az index.html-re vezeti', async () => {
    expect(await servedUrl('app://localhost/')).toMatch(/index\.html$/);
  });

  it('SPA fallback: kiterjesztes nelkuli utvonal -> index.html', async () => {
    expect(await servedUrl('app://localhost/cashier/transactions')).toMatch(/index\.html$/);
  });

  it('a kiterjesztessel rendelkezo assetet kiszolgalja', async () => {
    expect(await servedUrl('app://localhost/assets/app.js')).toMatch(/assets\/app\.js$/);
  });

  it('BIZTONSAG: a KODOLT SLASH (%2f) az egyetlen valos traversal-vektor — a guard fogja el', async () => {
    // MIERT EPPEN EZ:
    //   - a nyers `../` szegmenst a WHATWG `new URL(...)` MAR A PARSE SORAN
    //     normalizalja (`/../../etc/x` -> pathname `/etc/x`),
    //   - a `%2e%2e`-t szinten szegmenskent ismeri fel es normalizalja,
    //   - a `%2f` viszont NEM szegmens-elvalaszto a parser szamara, ezert
    //     erintetlenul atjut a pathname-be, es csak a KESOBBI
    //     `decodeURIComponent` alakitja `/`-ra. Igy a `path.join` mar a
    //     distPath-on KIVULRE mutat.
    // Empirikusan igazolva (node): pathname `/%2e%2e%2f%2e%2e%2fetc%2fpasswd.txt`
    //   -> join('/app/dist', '../../etc/passwd.txt') = '/etc/passwd.txt'.
    const served = await servedUrl('app://localhost/%2e%2e%2f%2e%2e%2fetc%2fpasswd.txt');
    expect(served).toMatch(/index\.html$/);
    expect(served).not.toMatch(/passwd/);
    expect(logger.warn).toHaveBeenCalledWith(
      '[Protocol] Path traversal blokkolva:',
      expect.stringContaining('%2e%2e%2f'),
    );
  });

  it('BIZTONSAG: sibling-prefix konyvtar (dist-evil) sem szolgalhato ki', async () => {
    // A `startsWith(resolvedDist)` onmagaban ATENGEDNE a `/app/dist-evil`-t,
    // mert az a `/app/dist` szoveges prefixe. A kezelo ezert
    // `resolvedDist + path.sep`-pel hasonlit — ezt rogziti ez a teszt.
    const served = await servedUrl('app://localhost/%2e%2e%2fdist-evil%2fsecret.txt');
    expect(served).toMatch(/index\.html$/);
    expect(served).not.toMatch(/dist-evil/);
  });

  it('a nyers `../` szegmenst mar a URL-parse felemeszti (dokumentalt viselkedes)', async () => {
    // NEM sebezhetoseg: a keres a distPath ALATT marad, ezert a guard nem is
    // szolal meg. Ez a jellemzo-teszt azert van itt, hogy egy kesobbi olvaso ne
    // higgye tevesen kilepesnek — es hogy a valos vektor (fent) ne keveredjen ossze vele.
    const served = await servedUrl('app://localhost/../../../etc/passwd.txt');
    expect(served).toMatch(/dist\/etc\/passwd\.txt$/);
    expect(logger.warn).not.toHaveBeenCalled();
  });
});

describe('promoteUserDataEnv', () => {
  it('hianyzo .env eseten a KLIENS-SPECIFIKUS uzenettel figyelmeztet', () => {
    const logger = makeLogger();
    promoteUserDataEnv({
      userDataPath: '/nem/letezik/userdata-' + Date.now(),
      logger,
      missingEnvMessage: 'EGYEDI-UZENET',
    });
    expect(logger.warn).toHaveBeenCalledWith('EGYEDI-UZENET');
    expect(logger.error).not.toHaveBeenCalled();
  });
});
