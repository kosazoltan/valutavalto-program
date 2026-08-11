import { app, BrowserWindow, dialog, ipcMain, protocol, session } from 'electron'
import log from 'electron-log/main'
import { release as getOsRelease } from 'node:os'
import fs from 'node:fs'
import path from 'node:path'
import { fetchViaElectronNet, type ApiProxyRequest } from './api-proxy'
import {
  GoogleOAuthFailedException,
  performGoogleOAuthFlow,
  performGoogleOAuthFlowWithBackendLogin,
} from './google-oauth'
import {
  initLocalFirst,
  shutdownLocalFirst,
  setAuthToken,
  registerLocalFirstIpcHandlers,
} from './local-first'
import {
  configPath,
  tokenPath,
  readConfig,
  writeConfig,
  deleteConfigKey,
  storeToken,
  loadToken,
  clearToken,
  decideApiUrl,
  parseErrorMessage,
  promoteUserDataEnv,
  createMediaPermissionHandler,
  createAppProtocolHandler,
} from '../../packages/electron-platform/src'

const osBuild = Number.parseInt(getOsRelease().split('.')[2] || '0', 10)
if (osBuild >= 26200) {
  app.commandLine.appendSwitch('no-sandbox')
  app.commandLine.appendSwitch('disable-gpu-sandbox')
}

app.commandLine.appendSwitch('disable-features', 'EncryptedClientHello')
app.commandLine.appendSwitch('disable-http2')

protocol.registerSchemesAsPrivileged([
  {
    scheme: 'app',
    privileges: {
      standard: true,
      secure: true,
      supportFetchAPI: true,
      corsEnabled: true,
      stream: true,
    },
  },
])

log.initialize()
log.transports.file.level = 'info'
log.transports.console.level = app.isPackaged ? 'warn' : 'debug'

const isDev = !app.isPackaged && process.env.ELECTRON_FORCE_PACKAGED !== '1'
const devServerUrl = process.env.ELECTRON_RENDERER_URL ?? 'http://127.0.0.1:3020'
const defaultApiUrl = 'https://excvaluta.com/api/v1'

let mainWindow: BrowserWindow | null = null

/**
 * Az összevont „Központi munkaállomás" két üzemmódja:
 *  - 'full'        → Központi irányítóközpont (a frontend `dist/central` bundle-je)
 *  - 'rate-maker'  → Árfolyamkészítő        (a frontend `dist/rate-maker` bundle-je)
 *
 * A módot induláskor egy magyar nyelvű választó-ablak választatja ki a felhasználóval,
 * a választás perzisztálódik (config.json `app_mode`), és az alapértelmezés a korábban
 * választott mód. A frontend mindkét flavor SAJÁT VITE_APP_FLAVOR-jával fordul → a
 * build-idejű flavor-függő ágak (RFM write-jog, local-rate-maker publish) helyesen működnek.
 */
type WorkstationMode = 'full' | 'rate-maker'

const MODE_DIST_SUBDIR: Record<WorkstationMode, string> = {
  full: 'central',
  'rate-maker': 'rate-maker',
}

const MODE_WINDOW_TITLE: Record<WorkstationMode, string> = {
  full: 'Valutaváltó Központi Irányítóközpont',
  'rate-maker': 'Valutaváltó Árfolyamkészítő',
}

function isWorkstationMode(value: unknown): value is WorkstationMode {
  return value === 'full' || value === 'rate-maker'
}

// Az aktuális session módja — induláskor a választó-ablak állítja be.
let activeAppMode: WorkstationMode = 'full'

// A config/token primitivek (configPath, tokenPath, readConfig, writeConfig,
// deleteConfigKey, storeToken, loadToken, clearToken) a KOZOS platform-retegben
// elnek: packages/electron-platform/src/config-store.ts
//
// FONTOS (#ERR-INST-01): a platform az utvonalat MINDEN HIVASKOR ujra feloldja az
// `app.getPath('userData')`-bol, ezert az alabbi `app.setPath('userData', ...)`
// mod-izolacio VALTOZATLANUL ervenyes marad rajuk.

function getConfig(key: string): string | null {
  // app_mode: a session aktuális módja (a választó-ablak állította be), NEM hardcode.
  if (key === 'app_mode') return activeAppMode
  const config = readConfig()
  if (key === 'server_url') return config.server_url || loadProductionUrls().api_url
  return config[key] ?? null
}

function setConfig(key: string, value: string): void {
  const config = readConfig()
  if (key === 'app_mode') {
    // Csak érvényes munkaállomás-módot fogadunk el; a session-állapotot is frissítjük.
    if (isWorkstationMode(value)) {
      config.app_mode = value
      activeAppMode = value
    } else {
      return
    }
  } else {
    config[key] = value
  }
  writeConfig(config)
}

function deleteConfig(key: string): void {
  // Kliens-specifikus guard: az app_mode kulcs NEM torolheto (a session modjat tarolja).
  if (key === 'app_mode') return
  deleteConfigKey(key)
}

/** A config.json-ben perzisztált korábbi mód (alapértelmezett a választó-ablakban). */
function readPersistedMode(): WorkstationMode {
  const stored = readConfig().app_mode
  return isWorkstationMode(stored) ? stored : 'full'
}

function persistMode(mode: WorkstationMode): void {
  const config = readConfig()
  config.app_mode = mode
  writeConfig(config)
}

/**
 * Induláskori magyar nyelvű mód-választó. A korábban választott mód az alapértelmezett
 * (Enter). A választás perzisztálódik. Kilépés (ablak bezárása) esetén az alapértelmezett
 * módot adja vissza.
 */
async function pickWorkstationMode(): Promise<WorkstationMode> {
  const previous = readPersistedMode()
  // Gombsorrend: 0 = Központi irányítóközpont, 1 = Árfolyamkészítő.
  const defaultId = previous === 'rate-maker' ? 1 : 0
  const { response } = await dialog.showMessageBox({
    type: 'question',
    buttons: ['Központi irányítóközpont', 'Árfolyamkészítő'],
    defaultId,
    cancelId: defaultId,
    noLink: true,
    title: 'Munkaállomás módja',
    message: 'Melyik módban szeretne dolgozni?',
    detail:
      'Központi irányítóközpont: a teljes központi felügyeleti felület.\n' +
      'Árfolyamkészítő: a főértéktárosi árfolyamkészítő (RFM) felület.\n\n' +
      'A választás megjegyződik; legközelebb ez lesz az alapértelmezett. ' +
      'A mód az alkalmazás újraindításával váltható.',
  })
  const mode: WorkstationMode = response === 1 ? 'rate-maker' : 'full'
  persistMode(mode)
  return mode
}

/**
 * Az induló mód meghatározása:
 *  1. `--app-mode=<full|rate-maker>` CLI argumentum (teszt/automatizálás) → felülír.
 *  2. Dev módban nincs dialog → mindig 'full' (a dev:renderer central-workstation flavorjához igazítva).
 *  3. Csomagolt módban a magyar választó-ablak.
 */
async function determineStartupMode(): Promise<WorkstationMode> {
  const arg = process.argv.find((a) => a.startsWith('--app-mode='))
  if (arg) {
    const value = arg.slice('--app-mode='.length)
    if (isWorkstationMode(value)) {
      persistMode(value)
      return value
    }
  }
  if (isDev) {
    // #ERR-INST-05: a dev:renderer fixen a 'central-workstation' flavort szolgálja ki a
    // 3020-as porton, ezért dev módban a main is 'full' → nincs renderer/main eltérés.
    // (Rate-maker dev-hez explicit `--app-mode=rate-maker` + a megfelelő dev szerver kell.)
    return 'full'
  }
  return pickWorkstationMode()
}

function loadProductionUrls(): { api_url: string; base_url: string; domain: string } {
  const packagedPath = path.join(process.resourcesPath, 'production-urls.json')
  const devPath = path.join(__dirname, '..', '..', 'config', 'production-urls.json')
  const configFile = app.isPackaged ? packagedPath : devPath

  try {
    const parsed = JSON.parse(fs.readFileSync(configFile, 'utf8')) as {
      api_url?: string
      base_url?: string
      domain?: string
    }
    return {
      api_url: parsed.api_url ?? defaultApiUrl,
      base_url: parsed.base_url ?? 'https://excvaluta.com',
      domain: parsed.domain ?? 'excvaluta.com',
    }
  } catch (err) {
    log.warn('[CentralWorkstation] production-urls.json nem olvasható, fallback:', err)
    return {
      api_url: defaultApiUrl,
      base_url: 'https://excvaluta.com',
      domain: 'excvaluta.com',
    }
  }
}

/**
 * A hasznalando API base URL.
 *
 * A DONTES a platformban van (`decideApiUrl`), a fallback-URL szamitasa itt
 * marad — igy a `loadProductionUrls()` tovabbra is CSAK akkor fut le, ha
 * tenylegesen fallbackre van szukseg (valtozatlan viselkedes).
 * Ez a kliens szandekosan NEM logol a fallback-agakon (a penztar igen).
 */
function resolveConfiguredApiUrl(): string {
  const decision = decideApiUrl(getConfig('server_url'))
  return decision.kind === 'configured' ? decision.url : loadProductionUrls().api_url
}

function ensureInitialConfig(): void {
  const config = readConfig()
  config.app_mode = activeAppMode
  config.server_url = config.server_url || loadProductionUrls().api_url
  writeConfig(config)
}

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 1440,
    height: 920,
    minWidth: 1180,
    minHeight: 760,
    autoHideMenuBar: true,
    title: MODE_WINDOW_TITLE[activeAppMode],
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: osBuild < 26200,
      webSecurity: true,
      allowRunningInsecureContent: false,
    },
  })

  if (isDev) {
    void mainWindow.loadURL(devServerUrl)
  } else {
    void mainWindow.loadURL('app://localhost/')
  }

  mainWindow.webContents.on(
    'did-fail-load',
    (_event, errorCode, errorDescription, validatedURL) => {
      log.error(`[Renderer] did-fail-load ${errorCode} ${errorDescription} @ ${validatedURL}`)
    },
  )

  mainWindow.webContents.on('render-process-gone', (_event, details) => {
    log.error('[Renderer] process gone:', details.reason)
    dialog.showErrorBox(
      'Megjelenítési hiba',
      `A központi irányítóközpont megjelenítő folyamata leállt.\nOk: ${details.reason}\n\nIndítsa újra az alkalmazást.`,
    )
  })

  mainWindow.webContents.on('will-navigate', (event, url) => {
    const allowed = ['app://localhost', devServerUrl]
    if (!allowed.some((origin) => url.startsWith(origin))) {
      log.warn('[Security] Navigáció blokkolva:', url)
      event.preventDefault()
    }
  })

  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    log.warn('[Security] Popup blokkolva:', url)
    return { action: 'deny' }
  })

  mainWindow.on('closed', () => {
    mainWindow = null
  })
}

function registerProtocol(): void {
  // Dual-bundle: az aktív mód határozza meg, melyik frontend-buildet szolgáljuk ki.
  const distPath = path.join(__dirname, '../dist', MODE_DIST_SUBDIR[activeAppMode])
  // A kiszolgalo (SPA fallback + path-traversal vedelem) a platform-retegben van.
  protocol.handle('app', createAppProtocolHandler(distPath, log))
}

function oauthClientConfig(): { clientId: string; clientSecret: string } {
  return {
    clientId:
      process.env.VITE_GOOGLE_DESKTOP_CLIENT_ID ?? process.env.GOOGLE_DESKTOP_CLIENT_ID ?? '',
    clientSecret:
      process.env.VITE_GOOGLE_DESKTOP_CLIENT_SECRET ??
      process.env.GOOGLE_DESKTOP_CLIENT_SECRET ??
      '',
  }
}

// Keep in sync with penztar-client/electron/config-guard.ts (VV-017).
const CONFIG_READ_ALLOWLIST = [
  'app_mode',
  'offline_mode',
  'branch_code',
  'server_url',
  'camera_configs',
  // Shared bundle — rate-maker flavor uses this (exchange-rates.ts:562); DO NOT REMOVE without verifying tree-shaking doesn't strip the call site in penztar builds.
  'rate_maker_device_id',
] as const
const SENSITIVE_READ_KEY_PATTERN = /password|token|secret|_sub/i

function registerIpcHandlers(): void {
  ipcMain.handle('get-config', (_event, key: string) => {
    if (
      SENSITIVE_READ_KEY_PATTERN.test(key) ||
      !(CONFIG_READ_ALLOWLIST as readonly string[]).includes(key)
    ) {
      log.warn('[IPC] get-config blocked key:', key)
      return null
    }
    return getConfig(key)
  })
  ipcMain.handle('set-config', (_event, key: string, value: string) => setConfig(key, value))
  ipcMain.handle('delete-config', (_event, key: string) => deleteConfig(key))

  ipcMain.handle('secure-store-token', (_event, token: string): boolean => {
    // A perzisztalas a kozos platform-primitivvel tortenik; a `setAuthToken`
    // hivas KLIENS-OLDALI es KOTELEZO: enelkul a token nem jutna el a
    // local-first / sync reteghez (csendes funkcionalis regresszio lenne).
    if (!storeToken(token)) {
      log.warn('[Security] safeStorage nem elérhető, token nincs perzisztálva.')
      return false
    }
    setAuthToken(token)
    return true
  })

  ipcMain.handle('secure-load-token', (): string | null => {
    const token = loadToken()
    if (token === null) {
      log.debug('[Security] nincs visszafejthető perzisztált token.')
    }
    return token
  })

  ipcMain.handle('secure-clear-token', (): void => {
    if (!clearToken()) {
      log.warn('[Security] token törlés sikertelen.')
    }
    setAuthToken(null)
  })

  ipcMain.handle('get-app-version', () => app.getVersion())
  ipcMain.handle('restart-app', () => {
    app.relaunch()
    app.quit()
  })

  ipcMain.handle(
    'diagnostics:report-error',
    (_event, payload: { message?: string; component?: string }) => {
      log.warn('[Renderer diagnostic]', payload.component ?? 'renderer', payload.message ?? '')
      return { ok: true }
    },
  )
  ipcMain.handle('diagnostics:set-user-identifier', () => ({ ok: true }))

  ipcMain.handle('auth:google-oauth-flow', async () => {
    const { clientId, clientSecret } = oauthClientConfig()
    if (!clientId || !clientSecret) {
      log.error('[CentralWorkstation] auth:google-oauth-flow MISCONFIGURED')
      return {
        ok: false,
        code: 'MISCONFIGURED',
        message: 'Google Desktop OAuth client nincs konfiguralva. Kerd az adminisztratort.',
      }
    }

    try {
      const result = await performGoogleOAuthFlow({ clientId, clientSecret })
      return { ok: true, idToken: result.idToken, email: result.email }
    } catch (err) {
      if (err instanceof GoogleOAuthFailedException) {
        log.warn('[CentralWorkstation] Google OAuth flow failed:', err.code, err.message)
        return { ok: false, code: err.code, message: err.message }
      }
      const message = err instanceof Error ? err.message : String(err)
      log.error('[CentralWorkstation] Google OAuth flow unexpected error:', err)
      return { ok: false, code: 'UNEXPECTED', message }
    }
  })

  ipcMain.handle('auth:google-oauth-flow-with-backend', async () => {
    const { clientId, clientSecret } = oauthClientConfig()
    if (!clientId || !clientSecret) {
      log.error('[CentralWorkstation] auth:google-oauth-flow-with-backend MISCONFIGURED')
      return {
        ok: false,
        code: 'MISCONFIGURED',
        message: 'Google Desktop OAuth client nincs konfiguralva. Kerd az adminisztratort.',
      }
    }

    try {
      const result = await performGoogleOAuthFlowWithBackendLogin({
        clientId,
        clientSecret,
        apiBaseUrl: resolveConfiguredApiUrl(),
        appMode: activeAppMode,
      })
      log.info(
        '[CentralWorkstation] Google OAuth + backend login OK for:',
        result.email ?? '(unknown)',
      )
      return { ok: true, response: result.response, email: result.email }
    } catch (err) {
      if (err instanceof GoogleOAuthFailedException) {
        log.warn('[CentralWorkstation] Google OAuth + backend login failed:', err.code, err.message)
        return { ok: false, code: err.code, message: err.message }
      }
      const message = err instanceof Error ? err.message : String(err)
      log.error('[CentralWorkstation] Google OAuth + backend login unexpected error:', err)
      return { ok: false, code: 'UNEXPECTED', message }
    }
  })

  ipcMain.handle(
    'auth:password-login',
    async (
      _event,
      payload: {
        companyCode?: string
        workerCode?: string
        password?: string
        appMode?: string
      },
    ) => {
      if (!payload.companyCode || !payload.workerCode || !payload.password) {
        return { ok: false, code: 'BAD_REQUEST', message: 'Cégkód, dolgozókód és jelszó kötelező.' }
      }

      try {
        const response = await fetchViaElectronNet({
          method: 'POST',
          url: `${resolveConfiguredApiUrl()}/auth/login`,
          headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
          body: JSON.stringify({
            companyCode: payload.companyCode,
            workerCode: payload.workerCode,
            password: payload.password,
            appMode: activeAppMode,
          }),
        })

        if (!response.ok) {
          return {
            ok: false,
            code: `HTTP_${response.status}`,
            message: parseErrorMessage(response.body, response.statusText || 'Bejelentkezési hiba'),
          }
        }

        return { ok: true, response: JSON.parse(response.body) as unknown }
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err)
        log.warn('[auth:password-login] failed:', message)
        return { ok: false, code: 'NETWORK_ERROR', message }
      }
    },
  )

  ipcMain.handle('api:fetch', async (_event, params: ApiProxyRequest) => {
    if (!params?.url || !params.method) {
      return {
        ok: false,
        status: 0,
        statusText: 'BAD_REQUEST',
        headers: {},
        body: '{"error":"url and method required"}',
      }
    }

    const fullUrl = params.url.startsWith('http')
      ? params.url
      : `${resolveConfiguredApiUrl()}${params.url}`

    const retryDelays = [1000, 3000, 5000]
    for (let attempt = 0; attempt < retryDelays.length; attempt += 1) {
      try {
        return await fetchViaElectronNet({ ...params, url: fullUrl })
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err)
        if (attempt === retryDelays.length - 1) {
          log.warn('[api:fetch] failed:', params.method, params.url, message)
          return {
            ok: false,
            status: 0,
            statusText: 'NETWORK_ERROR',
            headers: {},
            body: JSON.stringify({ error: message }),
          }
        }
        await new Promise((resolve) => setTimeout(resolve, retryDelays[attempt]))
      }
    }

    return {
      ok: false,
      status: 0,
      statusText: 'NETWORK_ERROR',
      headers: {},
      body: '{"error":"unknown"}',
    }
  })
}

const gotTheLock = app.requestSingleInstanceLock()
if (!gotTheLock) {
  app.quit()
  process.exit(0)
}

app.on('second-instance', () => {
  const window = BrowserWindow.getAllWindows()[0]
  if (window) {
    if (window.isMinimized()) window.restore()
    window.focus()
  }
})

process.on('uncaughtException', (err) => log.error('[Process] uncaughtException', err))
process.on('unhandledRejection', (reason) => log.error('[Process] unhandledRejection', reason))

app
  .whenReady()
  .then(async () => {
    // 2026-05-15 user-direktiva (Google OAuth fix, analog penztar-client): production
    // buildben a dotenv NEM tolti be a userData/.env-et, ezert promotaljuk most.
    // FONTOS: ez a BASE userData-bol tolt, MIELOTT a mod-izolacios `app.setPath`
    // lefutna (#ERR-INST-01) — a .env kozos marad a ket mod kozott.
    promoteUserDataEnv({
      userDataPath: app.getPath('userData'),
      logger: log,
      missingEnvMessage: '[App] userData/.env nem letezik — Google OAuth lehet sikertelen.',
    })

    // EBC Hangsegéd Phase 9.5 — mikrofon engedély. A handler (F-006 default-deny +
    // explicit origin-allowlist) a platform-retegben van, egyetlen forrasbol.
    session.defaultSession.setPermissionRequestHandler(createMediaPermissionHandler(log))

    // Munkaállomás-mód kiválasztása (választó-ablak) MINDEN más init előtt —
    // a protokoll-kiszolgálás és az ablak-cím is ettől függ. A mód-választás a BASE
    // userData-ban perzisztál (a .env betöltés is innen történt fent).
    activeAppMode = await determineStartupMode()

    // #ERR-INST-01: a két mód offline perzisztencia-rétegeit (config/token/SQLite outbox)
    // mód-specifikus userData almappába izoláljuk → nincs kereszt-mód adatkeveredés a
    // helyi cache-ben. A .env + a mód-választás a BASE userData-ban marad (közös), minden
    // más (config.json, auth-token, local-first SQLite) a base/<mód> alá kerül.
    const baseUserData = app.getPath('userData')
    app.setPath('userData', path.join(baseUserData, MODE_DIST_SUBDIR[activeAppMode]))
    log.info(
      `[Workstation] Aktív mód: ${activeAppMode} — izolált userData: ${app.getPath('userData')}`,
    )

    ensureInitialConfig()
    registerIpcHandlers()
    registerLocalFirstIpcHandlers()
    registerProtocol()

    // Local-first: SQLite + sync engine initialization
    try {
      await initLocalFirst(resolveConfiguredApiUrl(), activeAppMode)
      log.info('[App] Local-first infrastructure ready')
    } catch (err) {
      log.error('[App] Local-first init failed (continuing online-only):', err)
    }

    createWindow()
  })
  .catch((err) => {
    log.error('[App] startup failed:', err)
    dialog.showErrorBox('Indítási hiba', err instanceof Error ? err.message : String(err))
    app.quit()
  })

app.on('window-all-closed', () => {
  shutdownLocalFirst()
  app.quit()
})

app.on('activate', () => {
  if (mainWindow === null) createWindow()
})
