# S4a Electron dev watcher-ignore kontraktus

> Dátum: 2026-07-20 · Állapot: JÓVÁHAGYVA

## Cél

A `penztar-client` fejlesztői Vite watchere ne figyelje az Electron futás közben
írt állományait. A korábbi „csak a DB sidecarok legyenek kizárva” szöveg ezért
nem teljes: a kötelező, zárt ignore-lista két Electron dev-runtime könyvtárat és
három SQLite-fájlt tartalmaz.

## Rögzített döntés

Az `ELECTRON_DEV_WATCH_IGNORED` pontos mintakészlete:

- `**/.dev-user-data/**`
- `**/.dev-app/**`
- `**/local.db`
- `**/local.db-wal`
- `**/local.db-shm`

A `.dev-user-data` kizárását valós Windows futás igazolta: a Vite/chokidar
`FSWatcher` `EBUSY` (`errno -4082`) hibát kapott a futó Chromium profil zárolt
`.dev-user-data\session\Network\Cookies` fájlján, amitől a `dev:main` leállt. A
`.dev-app` az Electron fejlesztői indítás újraépített staging könyvtára; ugyanahhoz
a kizárólag dev-runtime határhoz tartozik, ezért szintén kötelezően ignorált.

Ez nem enged általános source/build kizárást: `src`, `dist` vagy más széles
generált-output minta nem adható hozzá külön, verifikált indok és
specifikációváltozás nélkül.

## Elfogadási kritériumok

- WHEN a Vite dev-server konfiguráció elkészül THEN a watcher SHALL pontosan a
  fenti öt mintát használni.
- WHEN valaki megpróbálja eltávolítani a `.dev-user-data` vagy `.dev-app`
  mintát THEN a regressziós teszt SHALL megbukni.
- WHEN a megosztott ignore-listát egy hívó módosítaná THEN a lista SHALL
  fagyasztott maradni, és a későbbi factory-hívások SHALL ugyanazt a változatlan
  referenciát használni.

## Regressziós bizonyíték

`penztar-client/electron/__tests__/vite-watch-config.test.ts` ellenőrzi mind az
öt pontos mintát, a fagyasztott listát és azt, hogy a Vite server-config
ugyanazt az exportált referenciát használja.

## Dev process cleanup biztonsági invariáns

- A cleanup kizárólag az explicit `-ProcessId` gyökerek bizonyított leszármazottait állíthatja le.
- A `-DevPort` kizárólag leállítás utáni, fail-closed `netstat` bizonyíték; port, owner vagy worktree-parancssor alapján önálló processz nem választható ki leállításra.
- Reparentelt listener ancestry-bizonyíték nélkül életben marad, a cleanup pedig `LISTENING` hibával tér vissza.
- A Pester suite és a disposable Vite runtime harness ezt a negatív biztonsági szerződést ellenőrzi.
