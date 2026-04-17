## Valutavalto Penztar v2.1.0 — First-Run Setup Wizard + Standalone Eltavolito

Ez a kiadas a **penztar-kliens elso futasa utani beallitasi folyamatot teljesen ujraszervezi**, valamint egy onallo uninstaller-t is szallit, hogy a kollegak gepein a regi, hibas telepitesek egyetlen kattintassal eltavolithatok legyenek.

### Lenyeg

- **First-Run Setup Wizard (4 lepes)**
  - 1. **Udvozles** -> tajekoztatas
  - 2. **Fiok valasztas** -> ~60 iroda, 2x8 racs, kereses + lapozas
  - 3. **Szerver kapcsolat** -> URL mezo mar elore kitoltve a Hetzner VPS cimevel (`https://api.excvaluta.com/api/v1`), teszt felhasznalo + jelszo + "Kapcsolat tesztelese" gomb vagy "Offline mod" checkbox
  - 4. **Admin jelszo** -> min. 8 karakter + megerositeto mezo + osszegzes
  - "Telepites befejezese" gomb:
    - Generalja: `JWT_SECRET`, `SQLCIPHER_KEY`, `OFFLINE_LICENSE_SECRET` (256 bit hex, `crypto.randomBytes(32).toString('hex')`)
    - Atomikusan kiirja `<userData>/.env`-et (`.env.tmp` + rename, `0o600` mode)
    - Hatterben `app.relaunch()` + `app.exit(0)`
- **Penztar-Eltavolito.exe (uninstaller)**
  - ~60 KB standalone NSIS executable
  - Windows service-ek leallitasa (BestChange-Backend, BestChange-PostgreSQL), process kill, file lock feloldasa, teljes konyvtar tisztitas

### Installer artifactok

| Fajl | Meret | SHA-256 |
|---|---|---|
| Penztar-Setup-2.1.0-20260417.exe | 431.32 MB | `89E32F1E0C7744A313364D8BD213B3B7395CC318E0317B9EA2871D53C92BB129` |
| Penztar-Eltavolito-2.1.0-20260417.exe | 58.48 KB | `D6404015F2C24A457977D0C48A6BAE97F0972F06BE93766B45FB8500073AC8CA` |

### Hasznalat (kollegaknak)

1. `Penztar-Setup-2.1.0-20260417.exe` -> jobb klikk -> **Futtatas rendszergazdakent**
2. A telepito maga elvegez mindent (regi telepites tiszta eltavolitasa, PostgreSQL 17.5 + JRE + Electron kliens + backend service)
3. Elso indulaskor a wizard beallitja a fiokot es az admin jelszot
4. Ha fennakadas van: `Penztar-Eltavolito-2.1.0-20260417.exe` -> rendszergazdakent -> reboot -> setup ujra

### Backend + frontend minor javitasok

- **CB-016**: `NavClosingService` 27% AFA hardcode megszuntetese
  - Uj `nav.vat-rate.<TAX_CODE>` `SystemParameter` kulcsok (`STANDARD`, `REDUCED_18`, `REDUCED_5`, `ZERO`)
  - V143 Flyway migracio alapertekekkel
  - `NavTaxCode` enum + `resolveVatRate(NavTaxCode)` + 7 uj unit teszt
- **Companyid audit tool**: `scripts/security/companyid-audit.ps1` + riport a `security-reports/latest/companyid-audit.md`-be (61 entity, 379 metodus, 172 gyanus sorban manualis review-ra)
- **Wizard URL default**: `https://` + general placeholder helyett mar az `api.excvaluta.com` kerul elore kitoltesre
- **Modul verzio egysegites**: backend, frontend-react, penztar-client, installer mind v2.1.0
- **NSIS encoding harden**: Windows-1252 ACP kompatibilis ASCII metadata (nincs mojibake a File Explorerben)

### CI status

- 1559 unit/integration teszt zold (backend 957 + frontend 505 + penztar-client 97)
- Security gate PASSED
- Dependabot nyitott alert: 0

### Verzio forras

- Git tag: [`v2.1.0`](https://github.com/kosazoltan/valutavalto-program/releases/tag/v2.1.0)
- CHANGELOG.md `[2.1.0] - 2026-04-17`
- Session memo: `docs/knowledge/memory/2026-04-17-installer-release-v2.1.0-session.yaml`
