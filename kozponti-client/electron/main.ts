import { app, BrowserWindow, dialog, ipcMain, net, protocol, safeStorage, session } from 'electron'
import log from 'electron-log/main'
import { release as getOsRelease } from 'node:os'
import fs from 'node:fs'
import path from 'node:path'
import { pathToFileURL } from 'node:url'
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

function configPath(): string {
  return path.join(app.getPath('userData'), 'config.json')
}

function tokenPath(): string {
  return path.join(app.getPath('userData'), 'auth-token.bin')
}

function readConfig(): Record<string, string> {
  try {
    const raw = fs.readFileSync(configPath(), 'utf8')
    const parsed = JSON.parse(raw) as unknown
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
      ? parsed as Record<string, string>
      : {}
  } catch {
    return {}
  }
}

function writeConfig(config: Record<string, string>): void {
  const target = configPath()
  fs.mkdirSync(path.dirname(target), { recursive: true })
  const tmp = `${target}.tmp`
  fs.writeFileSync(tmp, JSON.stringify(config, null, 2), { encoding: 'utf8', mode: 0o600 })
  fs.renameSync(tmp, target)
}

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
  if (key === 'app_mode') return
  const config = readConfig()
  delete config[key]
  writeConfig(config)
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

function normalizeApiUrl(value: string): string {
  const trimmed = value.trim().replace(/\/+$/, '')
  return trimmed.endsWith('/api/v1') ? trimmed : `${trimmed}/api/v1`
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

function resolveConfiguredApiUrl(): string {
  const configured = getConfig('server_url')?.trim()
  if (!configured) return loadProductionUrls().api_url

  try {
    const parsed = new URL(configured)
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
      return loadProductionUrls().api_url
    }
    return normalizeApiUrl(configured)
  } catch {
    return loadProductionUrls().api_url
  }
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

  mainWindow.webContents.on('did-fail-load', (_event, errorCode, errorDescription, validatedURL) => {
    log.error(`[Renderer] did-fail-load ${errorCode} ${errorDescription} @ ${validatedURL}`)
  })

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
  protocol.handle('app', (request) => {
    const url = new URL(request.url)
    let filePath = path.join(distPath, decodeURIComponent(url.pathname))
    if (url.pathname === '/' || url.pathname === '') {
      filePath = path.join(distPath, 'index.html')
    }
    if (!path.extname(filePath)) {
      filePath = path.join(distPath, 'index.html')
    }

    const resolved = path.resolve(filePath)
    const resolvedDist = path.resolve(distPath)
    if (!resolved.startsWith(resolvedDist + path.sep) && resolved !== resolvedDist) {
      log.warn('[Protocol] Path traversal blokkolva:', request.url)
      filePath = path.join(distPath, 'index.html')
    }

    return net.fetch(pathToFileURL(filePath).toString())
  })
}

function parseErrorMessage(responseBody: string, fallback: string): string {
  try {
    const parsed = JSON.parse(responseBody) as { message?: unknown; error?: unknown }
    return String(parsed.message ?? parsed.error ?? fallback)
  } catch {
    return fallback
  }
}

function oauthClientConfig(): { clientId: string; clientSecret: string } {
  return {
    clientId: process.env.VITE_GOOGLE_DESKTOP_CLIENT_ID
      ?? process.env.GOOGLE_DESKTOP_CLIENT_ID
      ?? '',
    clientSecret: process.env.VITE_GOOGLE_DESKTOP_CLIENT_SECRET
      ?? process.env.GOOGLE_DESKTOP_CLIENT_SECRET
      ?? '',
  }
}

function registerIpcHandlers(): void {
  ipcMain.handle('get-config', (_event, key: string) => getConfig(key))
  ipcMain.handle('set-config', (_event, key: string, value: string) => setConfig(key, value))
  ipcMain.handle('delete-config', (_event, key: string) => deleteConfig(key))

  ipcMain.handle('secure-store-token', (_event, token: string): boolean => {
    if (!safeStorage.isEncryptionAvailable()) {
      log.warn('[Security] safeStorage nem elérhető, token nincs perzisztálva.')
      return false
    }
    fs.mkdirSync(app.getPath('userData'), { recursive: true })
    fs.writeFileSync(tokenPath(), safeStorage.encryptString(token), { mode: 0o600 })
    setAuthToken(token)
    return true
  })

  ipcMain.handle('secure-load-token', (): string | null => {
    try {
      if (!safeStorage.isEncryptionAvailable() || !fs.existsSync(tokenPath())) return null
      return safeStorage.decryptString(fs.readFileSync(tokenPath()))
    } catch (err) {
      log.warn('[Security] token visszafejtés sikertelen:', err)
      return null
    }
  })

  ipcMain.handle('secure-clear-token', (): void => {
    try {
      if (fs.existsSync(tokenPath())) fs.unlinkSync(tokenPath())
    } catch (err) {
      log.warn('[Security] token törlés sikertelen:', err)
    }
    setAuthToken(null)
  })

  ipcMain.handle('get-app-version', () => app.getVersion())
  ipcMain.handle('restart-app', () => {
    app.relaunch()
    app.quit()
  })

  ipcMain.handle('diagnostics:report-error', (_event, payload: { message?: string; component?: string }) => {
    log.warn('[Renderer diagnostic]', payload.component ?? 'renderer', payload.message ?? '')
    return { ok: true }
  })
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
      log.info('[CentralWorkstation] Google OAuth + backend login OK for:', result.email ?? '(unknown)')
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

  ipcMain.handle('auth:password-login', async (_event, payload: {
    companyCode?: string
    workerCode?: string
    password?: string
    appMode?: string
  }) => {
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
  })

  ipcMain.handle('api:fetch', async (_event, params: ApiProxyRequest) => {
    if (!params?.url || !params.method) {
      return { ok: false, status: 0, statusText: 'BAD_REQUEST', headers: {}, body: '{"error":"url and method required"}' }
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

    return { ok: false, status: 0, statusText: 'NETWORK_ERROR', headers: {}, body: '{"error":"unknown"}' }
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

app.whenReady().then(async () => {
  // 2026-05-15 user-direktiva (Google OAuth fix, analog penztar-client): production
  // buildben a dotenv NEM tolti be a userData/.env-et, ezert promotaljuk most.
  try {
    const envPath = path.join(app.getPath('userData'), '.env')
    if (fs.existsSync(envPath)) {
      const raw = fs.readFileSync(envPath, 'utf8')
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const dotenv = require('dotenv') as { parse: (input: string | Buffer) => Record<string, string> }
      const parsed = dotenv.parse(raw)
      for (const [k, v] of Object.entries(parsed)) {
        if (!process.env[k]) process.env[k] = v
      }
      log.info(`[App] userData/.env betoltve a process.env-be (${Object.keys(parsed).length} kulcs)`)
    } else {
      log.warn('[App] userData/.env nem letezik — Google OAuth lehet sikertelen.')
    }
  } catch (err) {
    log.error('[App] userData/.env betoltesi hiba:', err)
  }

  // EBC Hangsegéd Phase 9.5 — mikrofon engedély (lasd penztar-client/electron/main.ts).
  // Security: URL parse + exact hostname/protocol compare (Codex P1 + CodeQL + Copilot fix).
  // F-006 (audit 2026-05-29): non-media permission BIZTONSAGOS DEFAULT = DENY (nem default-allow).
  session.defaultSession.setPermissionRequestHandler((_webContents, permission, callback, details) => {
    if (permission !== 'media') {
      log.warn('[Security] Non-media permission elutasitva (default-deny):', permission)
      callback(false)
      return
    }
    try {
      const url = new URL(String(details?.requestingUrl ?? ''))
      const isLocalApp = url.protocol === 'app:' && url.hostname === 'localhost'
      const isLocalHttp = url.protocol === 'http:' && url.hostname === 'localhost'
      const isProduction = url.protocol === 'https:' && url.hostname === 'excvaluta.com'
      if (isLocalApp || isLocalHttp || isProduction) {
        log.info('[VoiceAssistant] media (mic) engedely megadva:', url.origin)
        callback(true)
        return
      }
      log.warn('[VoiceAssistant] media (mic) engedely elutasitva (idegen origin):', url.origin)
    } catch (err) {
      log.warn('[VoiceAssistant] media (mic) URL parse hiba — elutasitva:', err)
    }
    callback(false)
  })

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
  log.info(`[Workstation] Aktív mód: ${activeAppMode} — izolált userData: ${app.getPath('userData')}`)

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
}).catch((err) => {
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
