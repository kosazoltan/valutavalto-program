# Kliens-összevonás — döntési előterjesztés

**Készült:** 2026-08-10 | **Repo-állapot:** `47522cb8` (v2.28.74)
**Státusz:** DÖNTÉSRE VÁR — kód nem készült hozzá
**Kapcsolódó:** `.hermes/tickets/2026-08-10-fkh036-*`, `.hermes/evidence/2026-08-10/architektura-duplikacio-felmeres.md`

---

## 1. Kérdés, amire döntés kell

Legyen-e **egyetlen** Electron-kliens a mai három helyett, amely belépéskor,
a szerepkör alapján dönti el, milyen felületet ad (pénztár / értéktár / központi /
árfolyamkészítő)?

---

## 2. Ami már megvan (nem kell megépíteni)

### 2.1 A login-alapú rétegválasztás ÉLESBEN FUT

| Funkció | Hely |
|---|---|
| Szerepkör → jogosult módok, egy forrás-igazság | `backend/.../util/AppModeRoleConstants.java` |
| Backend belépéskor visszaadja | `validAppModes` (login response) |
| Mód-választó, ha több szerep van | `frontend-react/src/pages/auth/LoginPage.tsx` (`showModeSelector`) |
| Session-szintű mód | `frontend-react/src/utils/sessionAppMode.ts` |
| Mód-feloldás a UI-ban | `frontend-react/src/hooks/useAppMode.ts` |

`AppModeRoleConstants.java` fejlécéből: *„Egyetlen helyen a forrás-igazság — módosításkor
a hivatkozók automatikusan követik."* A `LOCAL_CANONICAL_ROLES` = `penztar`, `ertektar`,
`ertekszallito`; a komment szerint *„kis irodákban egy dolgozó több módban is dolgozhat"*.

**Következtetés:** a megbízás „bejelentkezés alapján döntse el" pontja **kész funkció**.

### 2.2 Az összevonás FELE MÁR MEGTÖRTÉNT

A `kozponti-client/build/installer-cleanup.nsh` fejléce:

> „Régi Valutaváltó kliensek tisztítása az összevont Központi Munkaállomás előtt …
> eltávolítja a két korábbi klienst (Központi Irányítóközpont + Árfolyamkészítő),
> amelyeket az összevont »Központi Munkaállomás« kiváltott."

Megvalósítás: **egy** Electron-váz, **két** frontend-flavor build-időben:
```
build:central    → VITE_APP_FLAVOR=central-workstation
build:ratemaker  → VITE_APP_FLAVOR=rate-maker
```
A `VITE_APP_FLAVOR`-t a `useAppMode.ts`, `App.tsx`, `clientEnv.ts`,
`exchange-rates.ts`, `RateCreationPage.tsx` olvassa.

**Van tehát bevált, éles precedens.** A kérdés nem az, hogy működik-e a minta,
hanem hogy a pénztár belefér-e.

---

## 3. A valódi akadály: a pénztár nem olyan, mint a másik kettő

| Electron-modul | pénztár | központi |
|---|---:|---:|
| `sqlite.ts` (offline SQL.js DB) | **3 912 sor** | — |
| `sync-engine.ts` | **3 501** | — |
| `printer.ts` + `serial-printer.ts` | **2 547** | — |
| `first-run.ts` (Setup Wizard) | **1 529** | — |
| `camera` + `rtsp-recorder` + `video-manager` + `camera-encryption` | **1 435** | — |
| `scanner.ts`, `customer-display.ts`, `business-retry.ts` | 363 | — |
| `api-proxy`, `google-oauth`, `vv-logger`, `main`, `preload` | közös | közös |
| **Összes** | **29 211 sor** | **1 798 sor** |

Az előző összevonás két *közel azonos* dolgot vont össze (klón-mérés: 60-70% azonos kód).
Ez most **egy kicsi és egy 16-szor nagyobb** összevonása.

---

## 4. Mérleg

### Nyereség
1. **Egy telepítő ~90 irodára**, három helyett → rossz kliens telepítése lehetetlen.
2. **Nulla betanítás** — a UI nem változik.
3. **Elviszi a C-csoportos duplikációt ingyen**: `vv-logger`, `api-proxy`, token-tár,
   config-olvasó, `local-first` IPC, Electron bootstrap ≈ **1 000+ sor** (a 27
   komponensközi klónból 25 ez).
4. **Jogosultság egy kapun**: a `validAppModes` marad az egyetlen döntéshozó,
   a telepítéskor rögzített `app_mode` csak alapértelmezés.

### Költség és kockázat
| Kockázat | Súly | Megjegyzés |
|---|---|---|
| **Offline pénzügyi DB kód a központi gépen is** | **magas** | `sqlite.ts` + `sync-engine.ts` a támadási felület része lesz olyan gépeken, amelyek nem használják. Biztonsági döntés. |
| EXE-méret ~2-3× | közepes | ~90 iroda letöltése. |
| `first-run.ts` módfüggővé tétele | közepes | 1 529 sor; a központi gép ne keressen nyomtatót/kamerát. |
| Adat-migráció a meglévő telepítéseken | **magas** | `deleteAppDataOnUninstall: false`; `~/.valuta/local.db` szinkronizálatlan tranzakciókkal. |
| Telepítő-réteg törékenysége | **magas** | `installer-cleanup.nsh` `#1428`: `System.dll 0xc0000005` crash, WER-fingerprint, upstream electron-builder #7921. Drágán lett stabil. |

---

## 5. Nyitott kérdés, ami sokat spórolhat

Az `arfolyam-keszito-client` a `.hermes.md` szerint **LEGACY, önálló release nem készül
belőle** — de az Electron-rétege (1 406 sor) aktívan duplikálja a `kozponti-client`-et
(a mért 27 komponensközi klónból 25 ez a pár).

**Ha tényleg nem kell, akkor ott nem kiemelés, hanem törlés a helyes lépés** — az
lényegesen olcsóbb, mint bármilyen refaktor. Ezt az összevonás előtt kell eldönteni.

---

## 6. Javasolt sorrend (ha a döntés IGEN)

| Fázis | Tartalom | Kockázat |
|---|---|---|
| 0 | Döntés az `arfolyam-keszito-client` sorsáról | — |
| 1 | Közös `packages/electron-platform`: `vv-logger`, `api-proxy`, token-tár, config, bootstrap | alacsony |
| 2 | `first-run.ts` + hardver-init módfüggővé tétele | közepes |
| 3 | Összevonás: **pénztár a bázis**, `central-workstation` flavorként | **magas** |
| 4 | `validAppModes` szerver-oldali szigorítás — egyetlen jogosultsági kapu | **magas** |
| 5 | Adat-migrációs terv a meglévő telepítésekre (`~/.valuta`, `%APPDATA%`) | **magas** |

Az 1. fázis a mért duplikáció alapján **önmagában is megéri**, és nem igényli
az összevonási döntést.

---

## 7. Amit ehhez a döntéshez tudni kell (FKH-036 melléktermék)

A telepítő-vizsgálat két, korábban nem jelentett defektet talált. Az egyiket
(D1) ez a ciklus javította; a másik (D2) **nyitva van, és érinti az 5. fázist**:

- **D2:** a `~/.valuta/local.db` (offline, szinkronizálatlan pénzügyi tranzakciók)
  útvonalát **egyetlen telepítő-szkript sem ismeri**. A takarítása azért nem
  történt meg, mert admin-kontextusban a `$PROFILE` a *telepítő adminra* oldódik
  fel, nem a pénztárosra — a mentés/törlés a rossz profilon futna.

Ez az összevonásnál blokkoló: **egy egyesített kliens adat-migrációja nem tervezhető,
amíg a pénztáros valódi profiljának megtalálása nincs megoldva.**

---

*Kód ehhez a dokumentumhoz nem készült. Döntés után külön terv szükséges.*
