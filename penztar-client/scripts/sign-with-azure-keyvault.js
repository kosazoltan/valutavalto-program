/**
 * Azure Key Vault Premium HSM code signing hook for electron-builder.
 *
 * Production signing hook — AKTIVÁLÓDIK ha a CODE_SIGN_ENABLED=1 env var be van állítva
 * ÉS a következő AZURE_* secrets jelen vannak a process env-ben:
 *   - AZURE_KEY_VAULT_URI: pl. "https://kv-valuta-codesign.vault.azure.net/"
 *   - AZURE_KEY_VAULT_CERT_NAME: a Key Vault Certificate neve (pl. "valuta-codesign-cert")
 *   - AZURE_TENANT_ID: Microsoft Entra Tenant ID
 *   - AZURE_CLIENT_ID: App Registration (Service Principal) Application ID
 *   - AZURE_CLIENT_SECRET: a Service Principal client secret
 *
 * Ha CODE_SIGN_ENABLED nincs vagy NEM "1", a hook hibával leáll. Ezzel a `npm run package`
 * nem tud véletlenül aláíratlan production telepítőt kiadni.
 *
 * Ha CODE_SIGN_ENABLED=1 de a secrets hiányoznak, a hook EXPLICIT HIBÁVAL kilép —
 * NEM ad ki "néma" non-signed build-et.
 *
 * Telepítési követelmény (Windows build-gép vagy GitHub Actions runner):
 *   - .NET SDK 6+ telepítve
 *   - `dotnet tool install --global AzureSignTool`
 *   - PATH-on legyen az `azuresigntool`
 *
 * A script generic: a Key Vault-on lévő cert-tel működik (bármilyen CA-tól), nem
 * hardcoded a vendor. Csak az env var-okat kell beállítani:
 *   - AZURE_KEY_VAULT_URI
 *   - AZURE_KEY_VAULT_CERT_NAME
 *   - AZURE_TENANT_ID / AZURE_CLIENT_ID / AZURE_CLIENT_SECRET
 *   - AZURE_TIMESTAMP_URL (opcionalis, default: http://timestamp.digicert.com)
 *
 * Aktualis cert vendor + audit-status + migracio-historia:
 *   -> vault/operations/code-signing-setup-path.md
 *
 * Hivatkozás:
 *   - https://github.com/vcsjones/azuresigntool
 */

'use strict';

const { execFileSync } = require('child_process');

/**
 * Ezt a függvényt hívja az electron-builder a `signtoolOptions.sign` config-ból.
 *
 * @param {object} configuration - electron-builder által átadott config
 * @param {string} configuration.path - az aláírandó .exe path-ja
 * @returns {Promise<void>}
 */
exports.default = async function signWithAzureKeyVault(configuration) {
  const filePath = configuration.path;

  // 1. Fail-closed: production package csak bekapcsolt kódaláírással készülhet.
  if (process.env.CODE_SIGN_ENABLED !== '1') {
    throw new Error(
      `[sign-with-azure-keyvault] CODE_SIGN_ENABLED=${process.env.CODE_SIGN_ENABLED || '(unset)'}. ` +
        `Production packaging requires CODE_SIGN_ENABLED=1 and Azure Key Vault AZURE_* env vars.`,
    );
  }

  console.log(`[sign-with-azure-keyvault] CODE_SIGN_ENABLED=1, signing ${filePath}...`);

  // 2. Required env vars validáció — explicit error ha bármi hiányzik
  const requiredEnvVars = [
    'AZURE_KEY_VAULT_URI',
    'AZURE_KEY_VAULT_CERT_NAME',
    'AZURE_TENANT_ID',
    'AZURE_CLIENT_ID',
    'AZURE_CLIENT_SECRET',
  ];
  const missingVars = requiredEnvVars.filter((v) => !process.env[v]);
  if (missingVars.length > 0) {
    throw new Error(
      `[sign-with-azure-keyvault] CODE_SIGN_ENABLED=1 but required env vars missing: ${missingVars.join(', ')}. ` +
        `Setup: see vault/operations/code-signing-setup-path.md section "Azure Key Vault Premium HSM setup".`,
    );
  }

  // 3. AzureSignTool elérhetőség ellenőrzése (early-fail jobb mint cryptic execFileSync error)
  try {
    execFileSync('azuresigntool', ['--version'], { stdio: 'pipe' });
  } catch (err) {
    throw new Error(
      `[sign-with-azure-keyvault] 'azuresigntool' nem található PATH-on. Telepítés: ` +
        `\`dotnet tool install --global AzureSignTool\`. Error: ${err.message}`,
    );
  }

  // 4. AzureSignTool sign parancs felépítése
  //
  //    Flag-ek (https://github.com/vcsjones/azuresigntool):
  //      -kvu / --azure-key-vault-url      Key Vault URI
  //      -kvc / --azure-key-vault-certificate  Certificate name (NEM key name!)
  //      -kvi / --azure-key-vault-client-id    Service Principal App ID
  //      -kvs / --azure-key-vault-client-secret  Service Principal client secret
  //      -kvt / --azure-key-vault-tenant-id    Microsoft Entra Tenant ID
  //      -tr / --timestamp-rfc3161         RFC 3161 timestamp URL (DigiCert)
  //      -td / --timestamp-digest          Timestamp digest algorithm (SHA256)
  //      -fd / --file-digest               File digest algorithm (SHA256)
  //
  //    Kód-aláírás Authenticode formátumban — az -tr (RFC 3161) JOBB mint a régi -t (Authenticode-only).
  const signArgs = [
    'sign',
    '-kvu',
    process.env.AZURE_KEY_VAULT_URI,
    '-kvc',
    process.env.AZURE_KEY_VAULT_CERT_NAME,
    '-kvi',
    process.env.AZURE_CLIENT_ID,
    '-kvs',
    process.env.AZURE_CLIENT_SECRET,
    '-kvt',
    process.env.AZURE_TENANT_ID,
    '-tr',
    process.env.AZURE_TIMESTAMP_URL || 'http://timestamp.digicert.com',
    '-td',
    'sha256',
    '-fd',
    'sha256',
    '-v',
    filePath,
  ];

  // 5. Sign végrehajtás (env-ben NEM mutatjuk a secret-eket — execFileSync NEM print-eli)
  console.log(
    `[sign-with-azure-keyvault] Running: azuresigntool sign -kvu ${process.env.AZURE_KEY_VAULT_URI} -kvc ${process.env.AZURE_KEY_VAULT_CERT_NAME} -tr ${process.env.AZURE_TIMESTAMP_URL || 'http://timestamp.digicert.com'} ... ${filePath}`,
  );
  try {
    execFileSync('azuresigntool', signArgs, { stdio: 'inherit' });
    console.log(`[sign-with-azure-keyvault] Signing COMPLETE for ${filePath}`);
  } catch (err) {
    throw new Error(
      `[sign-with-azure-keyvault] azuresigntool sign FAILED for ${filePath}. ` +
        `Ellenőrizd:\n` +
        `  - AZURE_CLIENT_ID Service Principal-nak van Key Vault hozzáférése (Sign + Get)\n` +
        `  - Cert még nem járt le (Sectigo OV CS = max 460 nap policy 2026 Feb óta)\n` +
        `  - Network: a runner el tudja érni az Azure Key Vault URI-t\n` +
        `Error: ${err.message}`,
    );
  }
};
