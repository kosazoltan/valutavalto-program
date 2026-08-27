import { AxiosError } from 'axios'
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi, type MockInstance } from 'vitest'
import { api } from '../../services/api/client'

// FK14 — Fázis 0 (RED): a Főlap szinkron-jelző hálózat-állapot tesztjei a
// docs/specs/fk014-halozat-allapot-jelzo.md 4. szekció (FR-1–FR-7) alapján.
// A tesztek a JELENLEGI kóddal szemben szándékosan buknak — az implementáció
// (Fázis 2) ezekhez a fagyasztott tesztekhez készül.
//
// Implementációs pinek (a spec 9.2 Fázis 2 + NFR-1 alapján):
//  - a health-ping a közös axios klienst hívja: api.get('/health') — a baseURL
//    adja a /api/v1 prefixet (DashboardPage-minta); a teszt az `api` példány
//    get-jét spy-olja, így a services/api/client és services/api/index import
//    útvonal egyaránt lefedett
//  - a ping időzítése setInterval-alapú, 30 000 ms (NFR-1) — a teszt csak a
//    setInterval/clearInterval timereket fake-eli, hogy a testing-library
//    waitFor (setTimeout) valós maradjon
//  - az interval NEM lehet isElectron()-gate mögött (a jsdom tesztkörnyezet
//    nem Electron; a spec FR-2 platformfüggetlenül írja elő a pinget)

const STORAGE_KEY = 'arfolyamkeszito.mainSheet.v1'
const HEALTH_PING_INTERVAL_MS = 30_000 // NFR-1

const mocks = vi.hoisted(() => ({
  hasRole: vi.fn(() => true),
  hasCanonicalRole: vi.fn(() => true),
  publishAllWorkgroups: vi.fn(),
  summarizePublishAll: vi.fn(),
  listActivePublished: vi.fn(() => Promise.resolve([] as unknown[])),
  listExchangeRates: vi.fn(() => Promise.resolve([])),
  toast: { success: vi.fn(), error: vi.fn(), warning: vi.fn(), info: vi.fn() },
  catalog: {
    loading: false,
    error: null as Error | null,
    all: [
      { id: 1, code: 'EUR', name: 'Euró', symbol: '€', decimals: 2, displayOrder: 1, active: true },
    ],
    currencies: [
      { id: 1, code: 'EUR', name: 'Euró', symbol: '€', decimals: 2, displayOrder: 1, active: true },
    ],
    reload: vi.fn(),
  },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))
vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))
vi.mock('../../components/ui/toaster', () => ({ toast: mocks.toast }))
vi.mock('react-router-dom', () => ({ useNavigate: () => vi.fn() }))
vi.mock('../../stores/authStore', () => ({
  useAuthStore: Object.assign(
    (selector: (state: unknown) => unknown) =>
      selector({ hasRole: mocks.hasRole, hasCanonicalRole: mocks.hasCanonicalRole }),
    { getState: () => ({ logout: vi.fn() }) },
  ),
}))
vi.mock('../../hooks/useCurrencyCatalog', () => ({
  useCurrencyCatalog: () => mocks.catalog,
  getCrossBase: () => null,
}))
vi.mock('./publishAllWorkgroups', () => ({
  publishAllWorkgroups: mocks.publishAllWorkgroups,
  summarizePublishAll: mocks.summarizePublishAll,
}))
vi.mock('../../services/api/exchangeRateMaster', () => ({
  exchangeRateMasterApi: { listActivePublished: mocks.listActivePublished },
}))
vi.mock('../../services/api/exchange-rates', () => ({
  exchangeRateApi: { list: mocks.listExchangeRates },
}))
vi.mock('../../services/api/arfolyamInternetLinks', () => ({
  arfolyamInternetLinkApi: { list: vi.fn(() => Promise.resolve([])) },
}))

const EUR_ROW = {
  currency: 'EUR',
  settlement: 400,
  otp: 0,
  helper: 0,
  weakMultiBuy: 395,
  weakMultiSell: 405,
  crossRate: 0,
  wholesale: 0,
  crossBase: null,
  crossSettlement: 0,
  settlementManual: false,
}

// Szerver publikált master ráta: E=390, F=410 — a merge/resync ezekkel írna felül
const SERVER_EUR = {
  currencyCode: 'EUR',
  currencyId: 1,
  officialRate: 400,
  baseBuyRate: 390,
  baseSellRate: 410,
}

const ONLINE_TEXT = /Online \(kp\. szerver\)/
const OFFLINE_TEXT = /Offline — helyi cache/
const LOADING_TEXT = /Szerver szinkron/

function networkError() {
  const error = new AxiosError('Network Error')
  error.code = 'ERR_NETWORK'
  return error
}

function seedStorage(row = EUR_ROW) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify([row]))
}

async function importPage() {
  const module = await import('./MainRateSheetPage')
  return module.default
}

let apiGetSpy: MockInstance

// Per-hívás attribúció: csak a health-végpont hívásait számoljuk, a többi
// api.get (ha lenne) nem szennyezi az assertöt.
const healthCallCount = () => apiGetSpy.mock.calls.filter((call) => call[0] === '/health').length

function fireWindowEvent(type: 'online' | 'offline') {
  act(() => {
    window.dispatchEvent(new Event(type))
  })
}

// FK14 FR-8/FR-10 (Cursor Bugbot race-tesztek): kézzel vezérelt health-ping
// promise-ok — a teszt dönti el, MIKOR (milyen state mellett) fut le a válasz,
// így a stale-race determinisztikusan előidézhető.
type DeferredPing = { resolve: (value: unknown) => void; reject: (error: unknown) => void }
let healthPings: DeferredPing[] = []
function deferHealthPings() {
  healthPings = []
  apiGetSpy.mockImplementation((url: string) => {
    if (url === '/health') {
      return new Promise((resolve, reject) => {
        healthPings.push({ resolve, reject })
      })
    }
    return Promise.resolve({ data: {} })
  })
}

function pingAt(index: number): DeferredPing {
  const ping = healthPings[index]
  if (!ping) throw new Error(`nincs függő health-ping a(z) ${index}. indexen`)
  return ping
}

// Valós (nem fake-elt) setTimeout-tal engedjük leürülni a teljes async
// merge-láncot (listActivePublished → exchangeRateApi.list → setRows).
async function flushAsync() {
  await act(async () => {
    await new Promise((resolve) => setTimeout(resolve, 0))
  })
}

async function renderOnline() {
  seedStorage()
  const Page = await importPage()
  const view = render(<Page />)
  await screen.findByText(ONLINE_TEXT)
  return view
}

// Kétállapotú cella: Enter (startEdit) → F2 → change → Enter (commit)
async function editCell(cellId: string, value: string) {
  const cell = document.getElementById(cellId) as HTMLInputElement
  await act(async () => fireEvent.keyDown(cell, { key: 'Enter' }))
  await act(async () => fireEvent.keyDown(cell, { key: 'F2' }))
  await act(async () => fireEvent.change(cell, { target: { value } }))
  await act(async () => fireEvent.keyDown(cell, { key: 'Enter' }))
}

describe('FK14 — Főlap szinkron-jelző hálózat-állapot (Fázis 0, RED)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    mocks.hasRole.mockReturnValue(true)
    mocks.hasCanonicalRole.mockReturnValue(true)
    mocks.catalog.loading = false
    mocks.catalog.error = null
    mocks.listActivePublished.mockResolvedValue([SERVER_EUR])
    mocks.listExchangeRates.mockResolvedValue([])
    apiGetSpy = vi.spyOn(api, 'get').mockImplementation((url: string) => {
      if (url === '/health') return Promise.resolve({ data: { status: 'UP' } })
      return Promise.resolve({ data: {} })
    })
    vi.spyOn(window, 'confirm').mockReturnValue(true)
  })

  afterEach(() => {
    apiGetSpy.mockRestore()
    vi.useRealTimers()
  })

  it('FR-1: window offline esemény hatására a jelző Offline-ra vált', async () => {
    await renderOnline()

    fireWindowEvent('offline')

    expect(await screen.findByText(OFFLINE_TEXT)).toBeVisible()
    expect(screen.queryByText(ONLINE_TEXT)).not.toBeInTheDocument()
  })

  it('FR-2: 30 mp-enként health-ping fut a /health végpontra, sikeres válasznál Online marad', async () => {
    vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval'] })
    await renderOnline()

    const before = healthCallCount()
    await act(async () => {
      vi.advanceTimersByTime(HEALTH_PING_INTERVAL_MS)
    })
    expect(healthCallCount()).toBe(before + 1)

    await act(async () => {
      vi.advanceTimersByTime(HEALTH_PING_INTERVAL_MS)
    })
    expect(healthCallCount()).toBe(before + 2)

    // sikeres ping → a state a válasz alapján frissül: Online marad, nincs villogás
    await flushAsync()
    expect(screen.getByText(ONLINE_TEXT)).toBeVisible()
    expect(screen.queryByText(OFFLINE_TEXT)).not.toBeInTheDocument()
  })

  it('FR-3: health-ping hiba Online állapotban Offline-ra vált (meglévő felirat)', async () => {
    vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval'] })
    await renderOnline()

    apiGetSpy.mockImplementation((url: string) => {
      if (url === '/health') return Promise.reject(networkError())
      return Promise.resolve({ data: {} })
    })
    await act(async () => {
      vi.advanceTimersByTime(HEALTH_PING_INTERVAL_MS)
    })

    expect(await screen.findByText(OFFLINE_TEXT)).toBeVisible()
    expect(screen.queryByText(ONLINE_TEXT)).not.toBeInTheDocument()
  })

  it('FR-4: offline állapotból window online eseményre Online + automatikus katalógus-resync', async () => {
    // kezdeti mount-sync hibázik → Offline, cache-értékek (E=395)
    mocks.listActivePublished.mockRejectedValueOnce(networkError())
    seedStorage()
    const Page = await importPage()
    render(<Page />)
    expect(await screen.findByText(OFFLINE_TEXT)).toBeVisible()
    expect(screen.getByDisplayValue('395.00')).toBeInTheDocument()
    const callsBefore = mocks.listActivePublished.mock.calls.length

    fireWindowEvent('online')

    expect(await screen.findByText(ONLINE_TEXT)).toBeVisible()
    // per-hívás attribúció: a resync ténylegesen újrafuttatta a mount-sync logikát
    expect(mocks.listActivePublished.mock.calls.length).toBe(callsBefore + 1)
    // a resync eredménye meg is jelenik: a szerver E=390 felülírja a cache 395-öt
    expect(await screen.findByDisplayValue('390.00')).toBeInTheDocument()
    expect(screen.queryByDisplayValue('395.00')).not.toBeInTheDocument()
  })

  it('FR-4: ping-hiba miatti offline állapotból egy sikeres health-ping önmagában Online-ra vált és resyncet indít', async () => {
    vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval'] })
    await renderOnline()
    expect(await screen.findByDisplayValue('390.00')).toBeInTheDocument()

    // health-ping hibázik → Offline. Böngésző-esemény NINCS: a navigator.onLine
    // végig true marad, tehát a visszaváltást sem hozhatja window 'online' esemény.
    apiGetSpy.mockImplementation((url: string) => {
      if (url === '/health') return Promise.reject(networkError())
      return Promise.resolve({ data: {} })
    })
    await act(async () => {
      vi.advanceTimersByTime(HEALTH_PING_INTERVAL_MS)
    })
    expect(await screen.findByText(OFFLINE_TEXT)).toBeVisible()
    expect(window.navigator.onLine).toBe(true)

    // a következő ping sikeres; a szerveren közben ÚJ érték van (E=385) — a konkrét
    // érték megjelenése bizonyítja a resyncet, nem csak a hívásszám
    mocks.listActivePublished.mockResolvedValue([{ ...SERVER_EUR, baseBuyRate: 385 }])
    const callsBefore = mocks.listActivePublished.mock.calls.length
    apiGetSpy.mockImplementation((url: string) => {
      if (url === '/health') return Promise.resolve({ data: { status: 'UP' } })
      return Promise.resolve({ data: {} })
    })
    await act(async () => {
      vi.advanceTimersByTime(HEALTH_PING_INTERVAL_MS)
    })

    expect(await screen.findByText(ONLINE_TEXT)).toBeVisible()
    await flushAsync()
    expect(mocks.listActivePublished.mock.calls.length).toBe(callsBefore + 1)
    expect(await screen.findByDisplayValue('385.00')).toBeInTheDocument()
    expect(screen.queryByDisplayValue('390.00')).not.toBeInTheDocument()
  })

  it('FR-5: mount alatt (katalógus-lekérés folyamatban) a jelző azonnal Szerver szinkron…, nem üres', async () => {
    mocks.catalog.loading = true
    seedStorage()
    const Page = await importPage()
    render(<Page />)

    // a render-lyuk: jelenleg `idle` marad és SEMMILYEN jelző nem látszik
    expect(screen.getByText(LOADING_TEXT)).toBeInTheDocument()
    expect(screen.queryByText(ONLINE_TEXT)).not.toBeInTheDocument()
    expect(screen.queryByText(OFFLINE_TEXT)).not.toBeInTheDocument()
  })

  it('FR-6: dirty szerkesztés mellett a state-váltás megtörténik, de a dirty cella értéke nem cserélődik', async () => {
    await renderOnline()
    // a mount-sync a szerver E=390-ét mutatja
    expect(await screen.findByDisplayValue('390.00')).toBeInTheDocument()

    // helyi, ki nem küldött szerkesztés: E = 396
    await editCell('cell-0-weakMultiBuy', '396')
    expect(screen.getByDisplayValue('396.00')).toBeInTheDocument()

    // passzív hálózat-vesztés dirty alatt: a jelző váltson, az adat maradjon
    fireWindowEvent('offline')
    expect(await screen.findByText(OFFLINE_TEXT)).toBeVisible()
    expect(screen.getByDisplayValue('396.00')).toBeInTheDocument()

    // hálózat vissza: resync fut, de a dirty cellát NEM írhatja felül a szerver 390-e
    const callsBefore = mocks.listActivePublished.mock.calls.length
    fireWindowEvent('online')
    expect(await screen.findByText(ONLINE_TEXT)).toBeVisible()
    await waitFor(() => expect(mocks.listActivePublished.mock.calls.length).toBe(callsBefore + 1))
    await flushAsync()
    // sentinel: a szerkesztett érték maradt, a szerver-érték NEM került vissza a cellába
    expect(screen.getByDisplayValue('396.00')).toBeInTheDocument()
    expect(screen.queryByDisplayValue('390.00')).not.toBeInTheDocument()
  })

  it('FR-7: unmount után a health-ping interval leáll (pozitív kontrollal)', async () => {
    vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval'] })
    const view = await renderOnline()

    // pozitív kontroll: mountolva az interval ténylegesen pingel
    await act(async () => {
      vi.advanceTimersByTime(HEALTH_PING_INTERVAL_MS)
    })
    const callsWhileMounted = healthCallCount()
    expect(callsWhileMounted).toBeGreaterThan(0)

    view.unmount()

    // sentinel: unmount után hiába telik az idő, nem történik több ping
    await act(async () => {
      vi.advanceTimersByTime(HEALTH_PING_INTERVAL_MS * 3)
    })
    expect(healthCallCount()).toBe(callsWhileMounted)
  })

  it('FR-7: unmount után az online/offline listener leiratkozik (pozitív kontrollal)', async () => {
    // kezdeti mount-sync hibázik → Offline állapot
    mocks.listActivePublished.mockRejectedValueOnce(networkError())
    seedStorage()
    const Page = await importPage()
    const view = render(<Page />)
    expect(await screen.findByText(OFFLINE_TEXT)).toBeVisible()

    // pozitív kontroll: mountolva az online esemény resyncet indít (FR-4 mechanizmus él)
    const callsBefore = mocks.listActivePublished.mock.calls.length
    fireWindowEvent('online')
    expect(await screen.findByText(ONLINE_TEXT)).toBeVisible()
    await waitFor(() => expect(mocks.listActivePublished.mock.calls.length).toBe(callsBefore + 1))

    // vissza offline állapotba, hogy a leakelt listener resync-kísérlete detektálható legyen
    fireWindowEvent('offline')
    expect(await screen.findByText(OFFLINE_TEXT)).toBeVisible()
    const callsAtUnmount = mocks.listActivePublished.mock.calls.length

    view.unmount()

    // sentinel: unmount után az online esemény már NEM indíthat resyncet
    fireWindowEvent('online')
    fireWindowEvent('offline')
    await flushAsync()
    expect(mocks.listActivePublished.mock.calls.length).toBe(callsAtUnmount)
  })

  // ── FK14 13. szekció — Cursor Bugbot race-condition regressziós tesztek ──

  it('FR-8: offline esemény UTÁN beérkező stale ping-siker nem váltja vissza Online-ra', async () => {
    vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval'] })
    await renderOnline()

    // a ping ONLINE állapotban indul el, és függőben marad
    deferHealthPings()
    await act(async () => {
      vi.advanceTimersByTime(HEALTH_PING_INTERVAL_MS)
    })
    expect(healthPings.length).toBe(1)

    // közben passzív hálózat-vesztés: offline esemény
    fireWindowEvent('offline')
    expect(await screen.findByText(OFFLINE_TEXT)).toBeVisible()
    const callsBefore = mocks.listActivePublished.mock.calls.length

    // a RÉGI (offline esemény ELŐTT indult) ping most tér vissza sikerrel
    await act(async () => {
      pingAt(0).resolve({ data: { status: 'UP' } })
      await new Promise((resolve) => setTimeout(resolve, 0))
    })

    // stale siker: a jelző NEM válthat vissza, és resync sem indulhat
    expect(screen.getByText(OFFLINE_TEXT)).toBeVisible()
    expect(screen.queryByText(ONLINE_TEXT)).not.toBeInTheDocument()
    expect(mocks.listActivePublished.mock.calls.length).toBe(callsBefore)
  })

  it('FR-8: loading közben indult ping kései hibája nem viszi Offline-ba a közben Online-ra váltott jelzőt', async () => {
    vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval'] })
    // a kezdeti katalógus-sync függőben marad → tartós 'loading' állapot
    mocks.listActivePublished.mockImplementationOnce(() => new Promise(() => {}))
    seedStorage()
    const Page = await importPage()
    render(<Page />)
    expect(screen.getByText(LOADING_TEXT)).toBeInTheDocument()

    // a ping LOADING állapotban indul el, és függőben marad
    deferHealthPings()
    await act(async () => {
      vi.advanceTimersByTime(HEALTH_PING_INTERVAL_MS)
    })
    expect(healthPings.length).toBe(1)

    // másik trigger (online esemény) útján az állapot Online-ra vált (resync sikeres)
    fireWindowEvent('online')
    expect(await screen.findByText(ONLINE_TEXT)).toBeVisible()
    expect(await screen.findByDisplayValue('390.00')).toBeInTheDocument()

    // a RÉGI (loading alatt indult) ping most hibázik
    await act(async () => {
      pingAt(0).reject(networkError())
      await new Promise((resolve) => setTimeout(resolve, 0))
    })

    // stale hiba: az Online jelző marad, nem eshet vissza Offline-ba
    expect(screen.getByText(ONLINE_TEXT)).toBeVisible()
    expect(screen.queryByText(OFFLINE_TEXT)).not.toBeInTheDocument()

    // sentinel-ellenpróba: egy FRISS (Online alatt indult) ping hibája viszont
    // jogosan visz Offline-ba (FR-3) — a guard nem „minden hibát elnyelő"
    await act(async () => {
      vi.advanceTimersByTime(HEALTH_PING_INTERVAL_MS)
    })
    expect(healthPings.length).toBe(2)
    await act(async () => {
      pingAt(1).reject(networkError())
      await new Promise((resolve) => setTimeout(resolve, 0))
    })
    expect(await screen.findByText(OFFLINE_TEXT)).toBeVisible()
  })

  it('FR-9: ismételt sikertelen resync-körök alatt az Offline toast legfeljebb egyszer jelenik meg', async () => {
    await renderOnline()

    // a szerver tartósan elérhetetlenné válik
    mocks.listActivePublished.mockRejectedValue(networkError())
    fireWindowEvent('offline')
    expect(await screen.findByText(OFFLINE_TEXT)).toBeVisible()

    // 3 egymást követő online-esemény → 3 resync-próbálkozás, mind hibázik
    for (let round = 0; round < 3; round++) {
      const before = mocks.listActivePublished.mock.calls.length
      fireWindowEvent('online')
      await waitFor(() => expect(mocks.listActivePublished.mock.calls.length).toBe(before + 1))
      expect(await screen.findByText(OFFLINE_TEXT)).toBeVisible()
    }

    // per-hívás attribúció: pontosan az 'Offline' című toastokat számoljuk
    const offlineToasts = mocks.toast.warning.mock.calls.filter(
      (call) => call[0] === 'Offline',
    ).length
    expect(offlineToasts).toBeLessThanOrEqual(1)
  })

  it('FR-10: unmount után beérkező in-flight ping-válasz nem ír state-et és nem indít resyncet', async () => {
    // MEGJEGYZÉS (Fázis 0 jelzés): ez a teszt a jelenlegi kóddal is zöld, mert a
    // React 18+ az unmountolt komponens setState-jét csendben eldobja — a hibás
    // setState fekete-dobozból nem figyelhető meg. Regressziós őrszemként marad:
    // a resync-mellékhatást és a console.error-csendet rögzíti szerződésként.
    vi.useFakeTimers({ toFake: ['setInterval', 'clearInterval'] })
    const view = await renderOnline()

    // offline állapot + in-flight ping (ez a legveszélyesebb kombináció: a stale
    // siker a jelenlegi kódban goOnlineAndResync-et hívna)
    deferHealthPings()
    fireWindowEvent('offline')
    expect(await screen.findByText(OFFLINE_TEXT)).toBeVisible()
    await act(async () => {
      vi.advanceTimersByTime(HEALTH_PING_INTERVAL_MS)
    })
    expect(healthPings.length).toBe(1)
    const callsBefore = mocks.listActivePublished.mock.calls.length
    const consoleErrorSpy = vi.spyOn(console, 'error')

    view.unmount()

    // az in-flight ping válasza unmount UTÁN érkezik
    await act(async () => {
      pingAt(0).resolve({ data: { status: 'UP' } })
      await new Promise((resolve) => setTimeout(resolve, 0))
    })

    // sentinel: nem indult resync az unmountolt fáról, és nincs React-hiba/warning
    expect(mocks.listActivePublished.mock.calls.length).toBe(callsBefore)
    expect(consoleErrorSpy).not.toHaveBeenCalled()
  })

  it('FR-11: resync közben érkező offline esemény után a kései resync-siker nem vált Online-ra', async () => {
    // kezdeti mount-sync hibázik → Offline (cache-értékek)
    mocks.listActivePublished.mockRejectedValueOnce(networkError())
    // a KÖVETKEZŐ (resync-beli) hívást a teszt vezérli: függőben marad, amíg el nem engedjük
    let releaseResync: ((rows: unknown[]) => void) | null = null
    mocks.listActivePublished.mockImplementationOnce(
      () =>
        new Promise((resolve) => {
          releaseResync = resolve
        }),
    )
    seedStorage()
    const Page = await importPage()
    render(<Page />)
    expect(await screen.findByText(OFFLINE_TEXT)).toBeVisible()

    // resync indul online eseményre — a HTTP-hívás függőben (loading jelző)
    fireWindowEvent('online')
    await waitFor(() => expect(mocks.listActivePublished.mock.calls.length).toBe(2))
    expect(releaseResync).not.toBeNull()

    // a resync-hívás REPÜLÉSE KÖZBEN passzív hálózat-vesztés érkezik
    fireWindowEvent('offline')
    expect(await screen.findByText(OFFLINE_TEXT)).toBeVisible()

    // a resync HTTP-hívás most tér vissza SIKERREL (stale siker)
    await act(async () => {
      releaseResync?.([SERVER_EUR])
      await new Promise((resolve) => setTimeout(resolve, 0))
    })

    // a kései siker nem írhatja felül az offline eseményt: a jelző Offline marad
    expect(screen.getByText(OFFLINE_TEXT)).toBeVisible()
    expect(screen.queryByText(ONLINE_TEXT)).not.toBeInTheDocument()

    // sentinel-ellenpróba: egy ÚJABB online esemény friss resyncje viszont jogosan
    // vált Online-ra (FR-4 él) — a guard nem „örökre offline"
    const callsBefore = mocks.listActivePublished.mock.calls.length
    fireWindowEvent('online')
    expect(await screen.findByText(ONLINE_TEXT)).toBeVisible()
    await waitFor(() => expect(mocks.listActivePublished.mock.calls.length).toBe(callsBefore + 1))
    expect(await screen.findByDisplayValue('390.00')).toBeInTheDocument()
  })
})
