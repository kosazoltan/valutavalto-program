---
date: 2026-04-29
session_type: bug-rootcause + manual-fix + v2.3.9-codefix-plan
context: v2.3.8 reinstall után a SetupWizard NEM jelent meg
priority: P0 — éles teszt-blokk
---

# 2026-04-29 — SetupWizard-stale-.env root-cause + manuális fix + v2.3.9 terv

## Tünet (user-jelentés)

> "A telepítő varázsló ismét nem futott le egyből belelépett, nélhetőleg a főértéktáros menübe, bár ott nincs átadásátvétel"

A v2.3.7 reinstall + v2.3.8 reinstall **kétszer is** ugyanazt a tünetet produkálta: SetupWizard nem jelent meg, az app egyenesen a főértéktár (vagy más default) view-ra ugrott.

## Root-cause

**Az `isFirstRun()` ellenőrzés CSAK a `.env` fájlt nézi**, ami az `<userData>/` mappában él (`%APPDATA%\valuta-penztar\.env`). Az installer (Penztar-Cleanup.nsi + Penztar-Setup.nsi):
- ✅ Törli a `C:\Program Files\Valutavalto Penztar\` install dirt
- ✅ Törli a `C:\ProgramData\BestChange\` data dirt (DB + backend + JRE)
- ❌ **NEM törli a `%APPDATA%\valuta-penztar\` user-data mappát** (.env, Electron cookies, sessionstore)
- ❌ **NEM törli a `~/.valuta/local.db` SQLite-ot** (app_mode, branch_code, worker_code)

**Eredmény:** Egy 6 napos `.env` (2026-04-23-i, BR035 + KOSA + valid JWT_SECRET + SETUP_COMPLETED=1) átélte mindkét reinstall-t. Az `isFirstRun()` látta `SETUP_COMPLETED=1` + valid JWT → **NEM redirectált** `/setup`-ra.

A SQLite `local.db` szintén túlélte: `app_mode`, `branch_code`, `worker_code` mind régi ertékkel.

## Részletes lokalizálás (Audit, 2026-04-29 14:55)

| Fájl | Útvonal | Méret | Modositva | Probléma |
|---|---|---|---|---|
| `.env` | `%APPDATA%\valuta-penztar\.env` | 850 byte | **2026-04-23 15:37:58** | 6 napos! BR035, KOSA worker, SETUP_COMPLETED=1 |
| `local.db` | `~\.valuta\local.db` | 229 KB | 2026-04-29 14:54:41 | A futó Penztar.exe IRJA — de stale config értékekkel |
| `local.db.backup-...` | `~\.valuta\` | 192 KB | 2026-04-21 21:10 | Régi backup (irreleváns) |

## Manuális fix (azonnali, hogy a user MOST tudjon tovább menni)

```powershell
# 1. Penztar.exe leállítása (4 process: PID 3812, 22396, 34604, 38960)
Get-Process Penztar | Stop-Process -Force

# 2. Stale .env törlése
Remove-Item "$env:APPDATA\valuta-penztar\.env" -Force

# 3. SQLite local.db törlése (backup-pal)
Copy-Item "$env:USERPROFILE\.valuta\local.db" `
          "$env:USERPROFILE\.valuta\local.db.pre-v2.3.8-wizard-fix-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Remove-Item "$env:USERPROFILE\.valuta\local.db" -Force

# 4. Penztar.exe újraindítás
Start-Process "C:\Program Files\Valutavalto Penztar\Penztar.exe"
```

**Eredmény:** A SetupWizard-nak meg kell jelennie az új Penztar.exe ablakban.

## v2.3.9 kódfix terv

### Fix #1: Penztar-Cleanup.nsi extension — APPDATA + .valuta törlése

**Probléma:** NSIS RequestExecutionLevel=admin kontextusban a `$APPDATA` az **admin user**-é, nem az **eredeti user**-é. Ezért az egyszerű `RMDir /r "$APPDATA\valuta-penztar"` NEM az igazi user-mappát törli.

**Megoldás:** PowerShell-en keresztül lekérni az `explorer.exe` (vagy más interactive process) tulajdonosát, és onnan deriválni a user-mappát:

```nsis
; Az "explorer.exe" mindig az interactive user nevén fut
nsExec::ExecToStack 'powershell.exe -NoProfile -EncodedCommand <BASE64>'
; A base64 a következőt dekódolja:
;   $u = (Get-WmiObject Win32_Process -Filter "Name='explorer.exe'" | Select-Object -First 1).GetOwner()
;   $home = "C:\Users\$($u.User)"
;   Remove-Item -Recurse -Force "$home\AppData\Roaming\valuta-penztar" -ErrorAction SilentlyContinue
;   Remove-Item -Recurse -Force "$home\.valuta" -ErrorAction SilentlyContinue
Pop $0  ; exit code
Pop $1  ; output
```

### Fix #2: `isFirstRun()` extension — SQLite consistency check

**Hely:** `penztar-client/electron/first-run.ts`

```typescript
export function isFirstRun(): SetupCheckResult {
  const envPath = getEnvFilePath();
  if (!fs.existsSync(envPath)) {
    return { isFirstRun: true, envPath, reason: 'env-missing' };
  }
  const values = parseEnvFile(envPath);
  if (values.SETUP_COMPLETED !== '1') {
    return { isFirstRun: true, envPath, reason: 'setup-not-completed' };
  }
  if (!looksLikeValidSecret(values.JWT_SECRET)) {
    return { isFirstRun: true, envPath, reason: 'jwt-secret-invalid' };
  }

  // v2.3.9: SQLite consistency check — ha a .env mond SETUP_COMPLETED=1-et,
  // de az SQLite nem tartalmaz `app_mode` + `branch_code`-ot, akkor a config
  // szétesett (pl. installer wipe-olta a SQLite-ot, de az .env maradt).
  // Force first-run reset.
  try {
    // late-bound import az init-order miatt
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const sqlite = require('./sqlite') as typeof import('./sqlite');
    if (typeof sqlite.getConfig === 'function') {
      const appMode = sqlite.getConfig('app_mode');
      const branchCode = sqlite.getConfig('branch_code');
      if (!appMode || !branchCode) {
        log.warn('[Setup] .env mond SETUP_COMPLETED=1, de SQLite app_mode/branch_code hianyzik. Force first-run reset.');
        // Auto-clean a stale .env-t, hogy ne kelljen kezzel
        try {
          fs.unlinkSync(envPath);
        } catch (err) {
          log.warn('[Setup] Stale .env auto-delete failed:', err);
        }
        return { isFirstRun: true, envPath, reason: 'sqlite-config-missing' };
      }
    }
  } catch (err) {
    // SQLite nem initializált még — fall through, .env-only check
    log.debug('[Setup] SQLite check skipped (not yet initialized):', err);
  }

  return { isFirstRun: false, envPath };
}
```

### Fix #3: Backend "device-recognized" check (opcionális, robustabb)

A SetupWizard után az installer a `cash_register_device` táblába regisztrálja az eszközt (V100). A Penztar.exe minden indításkor hívhat egy `/cash-register/heartbeat` endpoint-ot:
- Ha a backend válasza "device unknown" → force first-run (a `cash_register_device_id` SQLite config régi vagy nincs)
- Ez kezeli azt az esetet is, amikor egy gépet áthelyeznek vagy a backend-re manuálisan visszaállítunk

## Akció-lista

1. **Most (manuálisan, már megtörtént):** stale `.env` + `local.db` törlése + Penztar.exe restart → wizard megjelenik
2. **v2.3.9 build előtt:** Fix #1 + Fix #2 implementálása + tesztelés
3. **Opcionálisan:** Fix #3 backend integráció

## Megfigyelendő

- Ha a wizard megjelenik a manuális fix után → **CONFIRMED a root-cause**
- Ha NEM jelenik meg → másik bug (pl. `electronAPI.setupCheck` undefined, vagy a SetupGuard component nem renderelődik)

## Vault refs

- `references/legacy-anti-system.md` — szerep-szerinti üzleti modell
- `sessions/2026-04-29-legacy-memory-and-treasury-bug-fix.md` — TreasuryLayout role-filter fix
- `sessions/2026-04-29-v2.3.8-nsis-bug-fix.md` — v2.3.8 NSIS scoped kill + backend timeout fix
- **EZ a fájl** — SetupWizard stale-.env root cause
