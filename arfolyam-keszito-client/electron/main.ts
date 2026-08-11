import { app, BrowserWindow, dialog, ipcMain, net, protocol, session } from 'electron'
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
import {
  readConfig,
  writeConfig,
  deleteConfigKey,
  storeToken,
  loadToken,
  clearToken,
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
const devServerUrl = process.env.ELECTRON_RENDERER_URL ?? 'http://127.0.0.1:3010'
const defaultApiUrl = 'https://excvaluta.com/api/v1'

let mainWindow: BrowserWindow | null = null

// A config/token primitivek (configPath, tokenPath, readConfig, writeConfig,
// deleteConfigKey, storeToken, loadToken, clearToken) a KOZOS platform-retegben
// elnek: packages/electron-platform/src/config-store.ts
// Az utvonalat a platform MINDEN HIVASKOR ujra oldja fel az
// `app.getPath('userData')`-bol (#ERR-INST-01 invarians).

function getConfig(key: string): string | null {
  if (key === 'app_mode') return 'rate-maker'
  const config = readConfig()
  if (key === 'server_url') return config.server_url || loadProductionUrls().api_url
  return config[key] ?? null
}

function setConfig(key: string, value: string): void {
  const config = readConfig()
  if (key === 'app_mode') {
    config.app_mode = 'rate-maker'
  } else {
    config[key] = value
  }
  writeConfig(config)
}

function deleteConfig(key: string): void {
  // Kliens-specifikus guard: az app_mode kulcs NEM torolheto.
  if (key === 'app_mode') return
  deleteConfigKey(key)
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
    log.warn('[RateMaker] production-urls.json nem olvasható, fallback:', err)
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
  config.app_mode = 'rate-maker'
  config.server_url = config.server_url || loadProductionUrls().api_url
  writeConfig(config)
}

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 900,
    minWidth: 1100,
    minHeight: 720,
    autoHideMenuBar: true,
    title: 'Valuta Árfolyamkészítő',
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
      `Az árfolyamkészítő megjelenítő folyamata leállt.\nOk: ${details.reason}\n\nIndítsa újra az alkalmazást.`,
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
  const distPath = path.join(__dirname, '../dist')
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

function registerIpcHandlers(): void {
  ipcMain.handle('get-config', (_event, key: string) => getConfig(key))
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
    const clientId =
      process.env.VITE_GOOGLE_DESKTOP_CLIENT_ID ?? process.env.GOOGLE_DESKTOP_CLIENT_ID ?? ''
    const clientSecret =
      process.env.VITE_GOOGLE_DESKTOP_CLIENT_SECRET ??
      process.env.GOOGLE_DESKTOP_CLIENT_SECRET ??
      ''

    if (!clientId || !clientSecret) {
      log.error('[RateMaker] auth:google-oauth-flow MISCONFIGURED')
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
        log.warn('[RateMaker] Google OAuth flow failed:', err.code, err.message)
        return { ok: false, code: err.code, message: err.message }
      }
      const message = err instanceof Error ? err.message : String(err)
      log.error('[RateMaker] Google OAuth flow unexpected error:', err)
      return { ok: false, code: 'UNEXPECTED', message }
    }
  })

  ipcMain.handle('auth:google-oauth-flow-with-backend', async () => {
    const clientId =
      process.env.VITE_GOOGLE_DESKTOP_CLIENT_ID ?? process.env.GOOGLE_DESKTOP_CLIENT_ID ?? ''
    const clientSecret =
      process.env.VITE_GOOGLE_DESKTOP_CLIENT_SECRET ??
      process.env.GOOGLE_DESKTOP_CLIENT_SECRET ??
      ''

    if (!clientId || !clientSecret) {
      log.error('[RateMaker] auth:google-oauth-flow-with-backend MISCONFIGURED')
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
        appMode: 'rate-maker',
      })
      log.info('[RateMaker] Google OAuth + backend login OK for:', result.email ?? '(unknown)')
      return { ok: true, response: result.response, email: result.email }
    } catch (err) {
      if (err instanceof GoogleOAuthFailedException) {
        log.warn('[RateMaker] Google OAuth + backend login failed:', err.code, err.message)
        return { ok: false, code: err.code, message: err.message }
      }
      const message = err instanceof Error ? err.message : String(err)
      log.error('[RateMaker] Google OAuth + backend login unexpected error:', err)
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
            appMode: 'rate-maker',
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
    try {
      const envPath = path.join(app.getPath('userData'), '.env')
      if (fs.existsSync(envPath)) {
        const raw = fs.readFileSync(envPath, 'utf8')
        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const dotenv = require('dotenv') as {
          parse: (input: string | Buffer) => Record<string, string>
        }
        const parsed = dotenv.parse(raw)
        for (const [k, v] of Object.entries(parsed)) {
          if (!process.env[k]) process.env[k] = v
        }
        log.info(
          `[App] userData/.env betoltve a process.env-be (${Object.keys(parsed).length} kulcs)`,
        )
      } else {
        log.warn('[App] userData/.env nem letezik — Google OAuth lehet sikertelen.')
      }
    } catch (err) {
      log.error('[App] userData/.env betoltesi hiba:', err)
    }

    // EBC Hangsegéd Phase 9.5 — mikrofon engedély (lasd penztar-client/electron/main.ts).
    // Security: URL parse + exact hostname/protocol compare (Codex P1 + CodeQL + Copilot fix).
    // F-006 (audit 2026-05-29): non-media permission BIZTONSAGOS DEFAULT = DENY (nem default-allow).
    session.defaultSession.setPermissionRequestHandler(
      (_webContents, permission, callback, details) => {
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
      },
    )

    ensureInitialConfig()
    registerIpcHandlers()
    registerLocalFirstIpcHandlers()
    registerProtocol()

    // Local-first: SQLite + sync engine initialization
    try {
      await initLocalFirst(resolveConfiguredApiUrl())
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
