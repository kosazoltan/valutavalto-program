/**
 * Google OAuth Authorization Code Flow + loopback redirect (RFC 8252) Electron-hoz.
 *
 * <p>A Google `gsi/client` Web SDK (`<GoogleLogin>`) NEM mukodik Electron-ban, mert a renderer
 * `app://localhost`-ot mond origin-kent, amit a Google `idpiframe_initialization_failed`-del elutasit.
 * Ezert az iparagi standard megoldas: <a href="https://developers.google.com/identity/protocols/oauth2/native-app">
 * Google OAuth 2.0 for Native Apps</a> minta.</p>
 *
 * <p>Flow:
 * <ol>
 *   <li>Ephemeral HTTP server indul `http://127.0.0.1:RANDOM_PORT/callback` cimen.</li>
 *   <li>PKCE: `code_verifier` (43-128 random URL-safe chars) + `code_challenge` (SHA-256 hash).</li>
 *   <li>External `BrowserWindow` nyilik a Google auth_uri-ra Desktop client ID-vel + PKCE-vel.</li>
 *   <li>User belep, Google authorization code-dal redirectel a loopback URL-re.</li>
 *   <li>Az ephemeral server elkapja a code-ot, leallitja onmagat.</li>
 *   <li>POST `https://oauth2.googleapis.com/token` (code + code_verifier + client_secret) -> id_token.</li>
 *   <li>Az `id_token` visszaadva a renderer-nek IPC-n -> backend `/api/v1/auth/google-login`.</li>
 * </ol>
 *
 * <p>Biztonsag:
 * <ul>
 *   <li>PKCE (RFC 7636): a `code_verifier` MINDIG egyedi, igy a client_secret melleklete is biztonsagos.</li>
 *   <li>State parameter: CSRF-veden eml az auth code-ot.</li>
 *   <li>Loopback `127.0.0.1` (NEM `localhost`): RFC 8252 ajanlas — IPv6/DNS spoofing megakadalyozasa.</li>
 *   <li>Random port: konkretan ne szivargjon ki rogzitett portot.</li>
 * </ul>
 *
 * <p>Hivatalos hivatkozasok:
 * <ul>
 *   <li>https://developers.google.com/identity/protocols/oauth2/native-app</li>
 *   <li>https://datatracker.ietf.org/doc/html/rfc8252 (OAuth 2.0 for Native Apps)</li>
 *   <li>https://datatracker.ietf.org/doc/html/rfc7636 (PKCE)</li>
 * </ul>
 */

import { BrowserWindow } from 'electron';
import http from 'node:http';
import crypto from 'node:crypto';
import { net as electronNet } from 'electron';
import log from 'electron-log/main';

// Google OAuth endpoints (RFC + Google Discovery doc)
const GOOGLE_AUTH_URI = 'https://accounts.google.com/o/oauth2/v2/auth';
const GOOGLE_TOKEN_URI = 'https://oauth2.googleapis.com/token';
const GOOGLE_SCOPES = ['openid', 'email', 'profile'].join(' ');

export interface GoogleOAuthResult {
  /** Google ID token (JWT) — a backend `/api/v1/auth/google-login` ezt vegzi validalni. */
  idToken: string;
  /** Az authentikalt user email-je (a Google ID token payload-jabol). NEM authoritative — csak UI-hoz. */
  email?: string;
}

export interface GoogleOAuthError {
  /** Hibakod: USER_CANCELLED, NETWORK, TOKEN_EXCHANGE_FAILED, NO_ID_TOKEN, MISCONFIGURED, TIMEOUT. */
  code: string;
  message: string;
}

export class GoogleOAuthFailedException extends Error {
  public readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
  }
}

/**
 * Generalja a PKCE `code_verifier` + `code_challenge` part.
 *
 * <p>RFC 7636 4.1: `code_verifier` 43-128 URL-safe karakter ([A-Z][a-z][0-9]-._~). Itt 32 byte
 * (256 bit) random base64url-encode-olva = 43 karakter (a max-er).</p>
 *
 * <p>RFC 7636 4.2: `code_challenge_method=S256` -> SHA-256(code_verifier) base64url-encode-olva.</p>
 */
function generatePkce(): { codeVerifier: string; codeChallenge: string } {
  const codeVerifier = crypto.randomBytes(32).toString('base64url');
  const codeChallenge = crypto.createHash('sha256').update(codeVerifier).digest('base64url');
  return { codeVerifier, codeChallenge };
}

/**
 * CSRF-veden state parameter — random 16 byte hex.
 */
function generateState(): string {
  return crypto.randomBytes(16).toString('hex');
}

/**
 * Google ID token payload kicsomagolasa — JWT 3 reszbol all (header.payload.signature),
 * a payload base64url-encoded JSON. A SIGNATURE-T NEM ELLENORZUNK ITT — az a backend
 * `GoogleIdTokenVerifier` feladata. Itt csak az `email`-t hasznalom UI-loghoz.
 */
function decodeIdTokenPayload(idToken: string): { email?: string; sub?: string } {
  try {
    const parts = idToken.split('.');
    if (parts.length !== 3) return {};
    const part1 = parts[1];
    if (!part1) return {};
    // 'base64url' encoding is supported by Node's Buffer at runtime, but the TS
    // BufferEncoding lib type is missing it on some @types/node versions, so we
    // cast to BufferEncoding to avoid the TS2769 overload mismatch.
    const payloadJson = Buffer.from(part1, 'base64url' as BufferEncoding).toString('utf8');
    const payload = JSON.parse(payloadJson) as { email?: string; sub?: string };
    return { email: payload.email, sub: payload.sub };
  } catch {
    return {};
  }
}

/**
 * Eldonti a Google authorization code -> ID token cseret.
 */
async function exchangeCodeForIdToken(params: {
  code: string;
  codeVerifier: string;
  redirectUri: string;
  clientId: string;
  clientSecret: string;
}): Promise<string> {
  const body = new URLSearchParams({
    code: params.code,
    client_id: params.clientId,
    client_secret: params.clientSecret,
    redirect_uri: params.redirectUri,
    grant_type: 'authorization_code',
    code_verifier: params.codeVerifier,
  });

  return new Promise((resolve, reject) => {
    const request = electronNet.request({
      method: 'POST',
      url: GOOGLE_TOKEN_URI,
    });
    request.setHeader('Content-Type', 'application/x-www-form-urlencoded');

    let responseBody = '';
    request.on('response', (response) => {
      response.on('data', (chunk) => {
        responseBody += chunk.toString('utf8');
      });
      response.on('end', () => {
        if (response.statusCode === 200) {
          try {
            const json = JSON.parse(responseBody) as { id_token?: string; error?: string; error_description?: string };
            if (!json.id_token) {
              reject(new GoogleOAuthFailedException('NO_ID_TOKEN',
                  'Google token endpoint nem adott vissza id_token-t.'));
              return;
            }
            resolve(json.id_token);
          } catch (parseErr) {
            reject(new GoogleOAuthFailedException('TOKEN_EXCHANGE_FAILED',
                'Google token response parse hiba: ' + (parseErr as Error).message));
          }
        } else {
          reject(new GoogleOAuthFailedException('TOKEN_EXCHANGE_FAILED',
              `Google token endpoint HTTP ${response.statusCode}: ${responseBody.slice(0, 200)}`));
        }
      });
    });
    request.on('error', (err) => {
      reject(new GoogleOAuthFailedException('NETWORK',
          'Google token endpoint network hiba: ' + err.message));
    });
    request.write(body.toString());
    request.end();
  });
}

/**
 * Google OAuth Authorization Code Flow indito metodus.
 *
 * <p>Hivatkozas: hivatalos Google Desktop apps minta. Az Electron main process indit egy
 * ephemeral HTTP server-t, kinyit egy Google bejelentkezes BrowserWindow-t, elkapja a
 * authorization code-ot, beváltja id_token-re (PKCE + client_secret), visszaadja a renderer-nek.</p>
 *
 * @param config Desktop OAuth client config
 * @returns Google ID token + email (UI-loghoz). Reject GoogleOAuthFailedException-nel.
 */
export async function performGoogleOAuthFlow(config: {
  clientId: string;
  clientSecret: string;
  /** Timeout ms, default 5 perc (a user szabadon belephet/kanyarodhat). */
  timeoutMs?: number;
}): Promise<GoogleOAuthResult> {
  if (!config.clientId || !config.clientSecret) {
    throw new GoogleOAuthFailedException('MISCONFIGURED',
        'Google Desktop OAuth client ID vagy secret hianyzik. ' +
        'Allitsd be a VITE_GOOGLE_DESKTOP_CLIENT_ID es VITE_GOOGLE_DESKTOP_CLIENT_SECRET env-eket.');
  }

  const { codeVerifier, codeChallenge } = generatePkce();
  const state = generateState();
  const timeoutMs = config.timeoutMs ?? 5 * 60 * 1000;

  // 1. Ephemeral HTTP server inditasa loopback redirect-hez (RFC 8252).
  //    A `port: 0` az OS-tol egy szabad portot ker.
  const { server, redirectUri } = await new Promise<{ server: http.Server; redirectUri: string }>((resolve, reject) => {
    const tmpServer = http.createServer();
    tmpServer.on('error', (err) => reject(new GoogleOAuthFailedException('NETWORK',
        'Loopback HTTP server inditasi hiba: ' + err.message)));
    tmpServer.listen(0, '127.0.0.1', () => {
      const address = tmpServer.address();
      if (typeof address === 'string' || address === null) {
        reject(new GoogleOAuthFailedException('NETWORK',
            'Loopback HTTP server portot nem kaptuk meg.'));
        return;
      }
      const uri = `http://127.0.0.1:${address.port}/callback`;
      log.info('[google-oauth] Loopback HTTP server elindult: ' + uri);
      resolve({ server: tmpServer, redirectUri: uri });
    });
  });

  // 2. Auth URL osszeallitasa Google docs alapjan.
  const authUrl = new URL(GOOGLE_AUTH_URI);
  authUrl.searchParams.set('client_id', config.clientId);
  authUrl.searchParams.set('redirect_uri', redirectUri);
  authUrl.searchParams.set('response_type', 'code');
  authUrl.searchParams.set('scope', GOOGLE_SCOPES);
  authUrl.searchParams.set('code_challenge', codeChallenge);
  authUrl.searchParams.set('code_challenge_method', 'S256');
  authUrl.searchParams.set('state', state);
  authUrl.searchParams.set('access_type', 'online');
  // `prompt=select_account` — ha a user mar be van jelentkezve, valaszthat masik fiokot.
  authUrl.searchParams.set('prompt', 'select_account');

  // 3. Promise: vagy a callback eredmenyet vagy a timeout-ot/cancel-t var.
  const authPromise = new Promise<string>((resolve, reject) => {
    const timeoutHandle = setTimeout(() => {
      reject(new GoogleOAuthFailedException('TIMEOUT',
          'Google bejelentkezes timeout (5 perc) — a felhasznalo nem fejezte be a flow-t.'));
    }, timeoutMs);

    server.on('request', (req, res) => {
      try {
        if (!req.url) return;
        const requestUrl = new URL(req.url, redirectUri);
        if (requestUrl.pathname !== '/callback') {
          res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
          res.end('Not Found');
          return;
        }
        const code = requestUrl.searchParams.get('code');
        const returnedState = requestUrl.searchParams.get('state');
        const errorParam = requestUrl.searchParams.get('error');

        if (errorParam) {
          // User megtagadta a hozzaferest (`access_denied`) vagy mas Google-side error.
          res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
          res.end(buildHtmlResponse(false, `Google bejelentkezes hiba: ${errorParam}`));
          clearTimeout(timeoutHandle);
          reject(new GoogleOAuthFailedException('USER_CANCELLED',
              `A felhasznalo megszakitotta a Google bejelentkezest: ${errorParam}`));
          return;
        }
        if (!code) {
          res.writeHead(400, { 'Content-Type': 'text/html; charset=utf-8' });
          res.end(buildHtmlResponse(false, 'Hianyzo authorization code.'));
          clearTimeout(timeoutHandle);
          reject(new GoogleOAuthFailedException('NO_CODE',
              'Google callback nem tartalmazott authorization code-ot.'));
          return;
        }
        if (returnedState !== state) {
          // CSRF vedelem — a state parameternek pontosan egyeznie kell.
          res.writeHead(400, { 'Content-Type': 'text/html; charset=utf-8' });
          res.end(buildHtmlResponse(false, 'CSRF state mismatch — biztonsagi hiba.'));
          clearTimeout(timeoutHandle);
          reject(new GoogleOAuthFailedException('STATE_MISMATCH',
              'CSRF state parameter mismatch — potencialis spoofing.'));
          return;
        }

        // Sikeres callback — sukerlap visszaadva a browser-nek, code propagal.
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        res.end(buildHtmlResponse(true, 'Sikeres bejelentkezes! Visszateres az alkalmazasra...'));
        clearTimeout(timeoutHandle);
        resolve(code);
      } catch (handlerErr) {
        log.error('[google-oauth] callback handler hiba:', handlerErr);
        clearTimeout(timeoutHandle);
        reject(new GoogleOAuthFailedException('CALLBACK_HANDLER_ERROR',
            (handlerErr as Error).message));
      }
    });
  });

  // 4. BrowserWindow nyitasa Google auth_uri-ra.
  const authWindow = new BrowserWindow({
    width: 500,
    height: 700,
    show: true,
    resizable: false,
    minimizable: false,
    maximizable: false,
    title: 'Google bejelentkezes',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true,
    },
  });
  authWindow.removeMenu();
  authWindow.setMenuBarVisibility(false);

  let authCode: string;
  try {
    await authWindow.loadURL(authUrl.toString());

    // Ha a user bezarja az ablakot a callback elott -> USER_CANCELLED
    const closedPromise = new Promise<string>((_, reject) => {
      authWindow.on('closed', () => {
        reject(new GoogleOAuthFailedException('USER_CANCELLED',
            'A felhasznalo bezarta a Google bejelentkezes ablakot.'));
      });
    });

    authCode = await Promise.race([authPromise, closedPromise]);
  } finally {
    if (!authWindow.isDestroyed()) {
      authWindow.close();
    }
    server.close();
    log.info('[google-oauth] Loopback HTTP server leallt + auth window bezarva.');
  }

  // 5. Authorization code -> ID token csere
  log.info('[google-oauth] Authorization code megkapva, token exchange indul.');
  const idToken = await exchangeCodeForIdToken({
    code: authCode,
    codeVerifier,
    redirectUri,
    clientId: config.clientId,
    clientSecret: config.clientSecret,
  });

  const decoded = decodeIdTokenPayload(idToken);
  log.info('[google-oauth] Token exchange sikeres. Email: ' + (decoded.email ?? '(unknown)'));

  return {
    idToken,
    email: decoded.email,
  };
}

/**
 * HTML response a loopback callback-re (a user lat egy "sikerult" / "nem sikerult" lapot).
 * Magyar nyelvu, minimal, no-tracking.
 */
function buildHtmlResponse(success: boolean, message: string): string {
  const bgColor = success ? '#d1fae5' : '#fee2e2';
  const textColor = success ? '#065f46' : '#991b1b';
  const icon = success ? '✓' : '✗';
  return `<!DOCTYPE html>
<html lang="hu">
<head>
<meta charset="UTF-8">
<title>Valutavalto - Google bejelentkezes</title>
<style>
body { font-family: -apple-system, system-ui, sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; background: ${bgColor}; }
.box { text-align: center; padding: 40px; background: white; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); max-width: 400px; }
.icon { font-size: 48px; color: ${textColor}; margin-bottom: 16px; }
.message { color: ${textColor}; font-size: 16px; }
.subtitle { color: #6b7280; font-size: 14px; margin-top: 16px; }
</style>
</head>
<body>
<div class="box">
<div class="icon">${icon}</div>
<div class="message">${message}</div>
<div class="subtitle">Bezarhatja ezt a lapot.</div>
</div>
</body>
</html>`;
}
