/**
 * DigiCert KeyLocker code signing hook for electron-builder.
 *
 * v2.5.25 SKELETON — AKTIVÁLÓDIK ha a CODE_SIGN_ENABLED=1 env var be van állítva
 * ÉS a következő SM_* secrets jelen vannak a process env-ben:
 *   - SM_HOST: pl. "https://clientauth.one.digicert.com"
 *   - SM_API_KEY: a DigiCert ONE → KeyLocker → API Key
 *   - SM_CLIENT_CERT_FILE: path a kliens authentication PKCS#12 fájlhoz (.p12)
 *     (CI-en: SM_CLIENT_CERT_FILE_B64 base64 → fájlra dekódolva, lásd lent)
 *   - SM_CLIENT_CERT_PASSWORD: a .p12 fájl jelszava
 *   - SM_KEYPAIR_ALIAS: a KeyLocker-ben definiált keypair alias (pl. "valuta-penztar-sign")
 *
 * Ha CODE_SIGN_ENABLED nincs vagy NEM "1", a hook silently skip-el (a build folytatódik
 * NEM aláírtan). Ezzel a fejlesztői build-ek továbbra is működnek cert nélkül.
 *
 * Ha CODE_SIGN_ENABLED=1 de a secrets hiányoznak, a hook EXPLICIT HIBÁVAL kilép —
 * NEM ad ki "néma" non-signed build-et.
 *
 * Hivatkozás:
 *   - https://docs.digicert.com/en/digicert-keylocker.html
 *   - https://www.electronjs.org/docs/latest/tutorial/code-signing
 *   - https://github.com/electron-userland/electron-builder/issues/4265
 *
 * Készült: 2026-05-05 (v2.5.25 sprint, cert még nem érkezett meg).
 */

'use strict';

const { execSync, execFileSync } = require('child_process');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');

/**
 * Ezt a függvényt hívja az electron-builder a `signtoolOptions.sign` config-ból.
 *
 * @param {object} configuration - electron-builder által átadott config
 * @param {string} configuration.path - az aláírandó .exe path-ja
 * @returns {Promise<void>}
 */
exports.default = async function signWithKeyLocker(configuration) {
  const filePath = configuration.path;

  // 1. SKIP feltétel: CODE_SIGN_ENABLED nincs / nem "1"
  if (process.env.CODE_SIGN_ENABLED !== '1') {
    console.log(`[sign-with-keylocker] CODE_SIGN_ENABLED=${process.env.CODE_SIGN_ENABLED || '(unset)'} → signing SKIPPED for ${filePath}`);
    return;
  }

  console.log(`[sign-with-keylocker] CODE_SIGN_ENABLED=1, signing ${filePath}...`);

  // 2. Required env vars validáció — explicit error ha bármi hiányzik
  const requiredEnvVars = ['SM_HOST', 'SM_API_KEY', 'SM_CLIENT_CERT_PASSWORD', 'SM_KEYPAIR_ALIAS'];
  const missingVars = requiredEnvVars.filter((v) => !process.env[v]);
  if (missingVars.length > 0) {
    throw new Error(
      `[sign-with-keylocker] CODE_SIGN_ENABLED=1 but required env vars missing: ${missingVars.join(', ')}. ` +
      `Setup: see code-signing-cert-beszerzes-csomag.md section 4 (GitHub Actions secrets).`,
    );
  }

  // 3. Client cert file resolution:
  //    - Lokális build: SM_CLIENT_CERT_FILE pontosan a .p12 fájl path-ja
  //    - CI build: SM_CLIENT_CERT_FILE_B64 base64-elt tartalom → temp file-ra dekódolva
  let clientCertFile = process.env.SM_CLIENT_CERT_FILE;
  let tempCertFile = null;

  if (!clientCertFile && process.env.SM_CLIENT_CERT_FILE_B64) {
    tempCertFile = path.join(os.tmpdir(), `keylocker-client-${Date.now()}.p12`);
    fs.writeFileSync(tempCertFile, Buffer.from(process.env.SM_CLIENT_CERT_FILE_B64, 'base64'), {
      mode: 0o600,
    });
    clientCertFile = tempCertFile;
    console.log(`[sign-with-keylocker] Client cert decoded from SM_CLIENT_CERT_FILE_B64 → ${tempCertFile}`);
  }

  if (!clientCertFile || !fs.existsSync(clientCertFile)) {
    throw new Error(
      `[sign-with-keylocker] Client cert file not found. Set SM_CLIENT_CERT_FILE (path) or SM_CLIENT_CERT_FILE_B64 (base64 content).`,
    );
  }

  // 4. smctl CLI invocation
  //    Az smctl egy DigiCert KeyLocker tool — Windows-on telepítve a build-gépre.
  //    https://docs.digicert.com/en/digicert-keylocker/client-tools/keylocker-tools.html
  //    A signtool-tal ekvivalens, de a private key a KeyLocker-ben marad (FIPS HSM).
  const smctlEnv = {
    ...process.env,
    SM_HOST: process.env.SM_HOST,
    SM_API_KEY: process.env.SM_API_KEY,
    SM_CLIENT_CERT_FILE: clientCertFile,
    SM_CLIENT_CERT_PASSWORD: process.env.SM_CLIENT_CERT_PASSWORD,
  };

  // smctl healthcheck (preflight) — ha nincs hálózat vagy hibás credential, korán bukik
  try {
    execFileSync('smctl', ['healthcheck'], { stdio: 'inherit', env: smctlEnv });
  } catch (err) {
    if (tempCertFile) fs.unlinkSync(tempCertFile);
    throw new Error(`[sign-with-keylocker] smctl healthcheck FAILED. Check SM_* env vars + network. ${err.message}`);
  }

  // Tényleges aláírás — execFileSync (no shell) to prevent command injection via env vars
  const keypairAlias = process.env.SM_KEYPAIR_ALIAS;
  const timestampServer = process.env.SM_TIMESTAMP_SERVER || 'http://timestamp.digicert.com';
  const signArgs = ['sign', '--keypair-alias', keypairAlias, '--input', filePath, '--tsa-server', timestampServer];

  console.log(`[sign-with-keylocker] Running: smctl ${signArgs.join(' ')}`);
  try {
    execFileSync('smctl', signArgs, { stdio: 'inherit', env: smctlEnv });
  } catch (err) {
    if (tempCertFile) fs.unlinkSync(tempCertFile);
    throw new Error(`[sign-with-keylocker] smctl sign FAILED for ${filePath}. ${err.message}`);
  }

  // Cleanup temp cert (CI esetén)
  if (tempCertFile) {
    try { fs.unlinkSync(tempCertFile); } catch { /* ignore */ }
  }

  // 5. Verifikáció — signtool verify
  try {
    execSync(`signtool verify /pa /v "${filePath}"`, { stdio: 'inherit' });
    console.log(`[sign-with-keylocker] ✅ ${filePath} signed and verified successfully.`);
  } catch (err) {
    throw new Error(`[sign-with-keylocker] signtool verify FAILED for ${filePath}. The file was signed but verification failed: ${err.message}`);
  }
};
