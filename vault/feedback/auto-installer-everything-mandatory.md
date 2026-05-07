---
created: 2026-05-05
priority: NULLADIK (legmagasabb)
hatály: minden conversation, minden Valutaváltó deliverable
forrás: Kósa Zoltán direkt utasítás
trigger-szituáció: Borsi-Helga-Tomi-Heni manual-debug-ciklus 2026-05-04
---

# KÖTELEZŐ ÉRVÉNYŰ: nem-informatikus végfelhasználó alapelv

## Az alapszabály

**A kollégák NEM informatikusok ÉS NEM programozók.** Pénztárosok, főértéktárosok, irodai dolgozók, terül eti vezetők. Az IT-jártasságuk alap-szintű (Windows használat, Edge/Chrome böngészés, e-mail).

**TILOS** nekik küldeni:

| Tiltott | Helyette |
|---|---|
| `ipconfig /flushdns` | NSIS Setup Section: `nsExec::ExecToLog 'ipconfig /flushdns'` |
| `netsh winhttp reset proxy` | NSIS Section beépítve |
| `Win+R %APPDATA%\valuta-penztar` → "töröld le" | NSIS uninstaller: `SetShellVarContext current` + `RMDir /r "$APPDATA\..."` |
| `.env` fájl szerkesztés | Electron `main.ts` `app.whenReady` automatikus migration |
| ESET URL Filter konfigurálás | Cloudflare DNS-en server-oldali fix az `excvaluta.com`-ra (API-n keresztül) |
| `regedit` → registry kulcs törlés | NSIS `DeleteRegKey` Section |
| Cloudflare dashboard navigálás | Saját CF API token-nel én végzem el |
| Cmd / PowerShell parancs-másolás | Diagnosztika beépítve a Penztar-ba (Start menu shortcut) |

## A telepítő MINDENT automatikusan elvégez

1. **DNS cache flush** — NSIS Section
2. **userData migration** — Electron `main.ts` regex-átírás (üres `https://` → `https://excvaluta.com/api/v1`)
3. **Régi mappa-törlés** — NSIS uninstaller `SetShellVarContext current` + `RMDir /r`
4. **Registry-cleanup** — `DeleteRegKey HKLM "Software\BestChange\..."`
5. **Tűzfal-szabályok** — `netsh advfirewall firewall add/delete rule`
6. **Setup Wizard auto-indítás** — telepítés végén `Penztar.exe` kinyitja
7. **Diagnosztika** — Start menu "Hálózati diagnosztika" parancsikon (1 dupla-klikk)
8. **Auto-update** — electron-updater background

## Felhasználói lépések MAXIMÁLIS halmaza

1. **Dupla-klikk** a `Penztar-Setup-X.Y.Z.exe`-re
2. **UAC dialog**: "Igen"
3. **NSIS varázsló**: Welcome → License → "Telepítés típusa" (default OK) → Directory (default OK) → Install
4. **Setup Wizard 5 lépés**: Iroda választás → Program-típus (default) → Fiók (vagy default) → Szerver kapcsolat (default + 1 gomb) → Admin jelszó beírás (8+ karakter)
5. **Login**: "Belépés Google fiókkal" gomb → Google fiók választás → kész

**Ennyi.** Semmi más nem várható el.

## Diagnosztikai protokoll

Ha **valami nem működik**, a felhasználó **csak**:
1. **Start menü** → "Hálózati diagnosztika" parancsikon → dupla-klikk
2. Várj 60 másodpercet (semmi nem jelenik meg, csak fut)
3. Az asztalon megjelent a `penztar-diagnostic-YYYYMMDD-HHMMSS.txt` fájl
4. **Email-ben elküldi** Kosa Zoltánnak

**A debug-utat ezután a fejlesztő végzi**, NEM a felhasználó.

## Server-oldali fix is a fejlesztő dolga

Példa: Cloudflare IPv6 routing konflikt. Ha a fix Cloudflare DNS-szintű:
- A fejlesztő (én) **CF API token-nel** elvégzi
- A felhasználónak NEM kell semmit a Cloudflare dashboard-on csinálnia
- A telepítő/electron client a deploy után automatikusan helyes viselkedést mutat

## Ha mégis kódbeli kompromisszum kell

A telepítő **soha NEM hagy hátra**:
- "Az alkalmazás futása előtt töröld le ezt a mappát"
- "ESET-ben kapcsold ki a SSL/TLS protokoll-szűrést"
- "Add hozzá a hosts-hoz ezt a sort"
- "Futtasd ezt a CMD-t admin-ként"

**Mindezt a telepítő (NSIS Section vagy Electron `main.ts` migration) elvégzi automatikusan.**

## A user-direktíva 2026-05-05 forrás

Borsi-Helga-Tomi-Heni 2026-05-04-i debug-ciklusa után:
- Borsi: ESET kivétel, ipconfig flushdns, böngészős teszt küldve
- Helga: %APPDATA% mappa manuális törlés küldve  
- Tomi: SetupWizard 4. lépés-magyarázat (rossz lépés-szám)
- Heni: jelszó-beírási útmutató (10 percig nem értette)

**Mindez ELFOGADHATATLAN volt.** A user explicit utasította:
> "Ezentúl mindig olyan telepítőt készíts, ami mindent automatikusan elkészít,
>  letelepít, javít, töröl, NEM PEDIG parancssorokat futtattatni emberekkel.
>  Csak 100%-ban működő, tökéletes programot adhatsz a kezeid közül."

## Hatálybalépés

**AZONNAL és visszamenőleg**: a v2.5.13+ telepítők kötelezően:
- DNS flush automatikus
- userData migration automatikus
- userData régi-mappa cleanup automatikus
- Beépített diagnosztika parancsikonnal

**A v2.5.10 már részben tartalmazza**: Setup Wizard, beépített diagnosztika, userData migration. **A jövőbeni release-ekben** minden új végfelhasználói probléma esetén a fix a TELEPÍTŐBE kerül, NEM a felhasználói instrukcióba.
