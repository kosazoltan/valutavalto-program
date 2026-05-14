---
title: Valutavalto Windows signed release runbook
type: runbook
project: Valutavalto-program (BEC ERP)
created_at: 2026-05-14
valid_until: current
---

# Valutavalto Windows signed release runbook

A production Windows release path:

```text
.github/workflows/windows-signed-release.yml
```

Műveletvégzők:

- `Penztar-Setup-<version>-<date>.exe` — pénztáros kliens (NSIS, ~281 MB, DigiCert KeyLocker aláírva)
- `Penztar-Eltavolito-<version>-<date>.exe` — uninstaller (NSIS, ~60 KB)
- `Kozponti-Iranyitokozpont-Setup-<version>.exe` — központi irányítóközpont (~100 MB, aláírva)
- `Arfolyamkeszito-Setup-<version>.exe` — RFM (rate-maker) főértéktáros (~100 MB, aláírva)
- `valuta-backend-<version>.jar` — backend (Hetzner deploy-hoz)
- `windows-signed-release-sha256.txt` — SHA-256 hash manifest

## Required GitHub Secrets

A workflow `preflight` job előbb leáll, ha bármi hiányzik. Beállítandó: **GitHub Repo → Settings → Secrets and variables → Actions → Repository secrets**.

```text
SM_HOST                    https://clientauth.one.digicert.com (DigiCert KeyLocker endpoint)
SM_API_KEY                 KeyLocker API kulcs
SM_CLIENT_CERT_FILE_B64    A kliens authentication .p12 fájl tartalma base64-elve
                           (PowerShell: [Convert]::ToBase64String([IO.File]::ReadAllBytes('client.p12')))
SM_CLIENT_CERT_PASSWORD    Kliens .p12 cert jelszava
SM_KEYPAIR_ALIAS           KeyLocker keypair alias (pl. valuta-penztar-sign)
```

Ezek a `penztar-client/scripts/sign-with-keylocker.js` electron-builder signtoolOptions hook-on át kerülnek az aláíráshoz. `CODE_SIGN_ENABLED=1` a workflow lépéseiben explicit.

A `SM_CLIENT_CERT_FILE_B64` szükséges mert CI-en nincs fájlrendszer (a sign hook base64-ből egy temp .p12-t dekódol). Lokálisan: `SM_CLIENT_CERT_FILE` pontosan a .p12 fájl path-ja.

## Production gate

A release CSAK akkor signed production, ha a workflow minden lépése ZÖLD:

- **preflight** — minden SM_* secret jelen + verzió felodva
- **build-backend** — Maven `mvn -B package -DskipTests` SUCCESS
- **build-penztar** — `installer/build-installer.ps1` + Eltavolito NSIS, aláírás `Status=Valid`
- **build-kozponti** — `npm run package` (electron-builder), aláírás `Status=Valid`
- **build-arfolyamkeszito** — `npm run package`, aláírás `Status=Valid`
- **publish-release** (opcionális, `publish_release=true` esetén) — GitHub Release létrehozás + SHA-256 manifest

A workflow upload-olja az aláírt EXE-ket, JAR-t, és `windows-signed-release-sha256.txt`-t.

**TILOS** lokálisan készített *unsigned* (`ALLOW_UNSIGNED_BUILD=1`) build-et production release-ként terjeszteni.

## Workflow indítás

GitHub UI:
1. **Actions** → **Windows Signed Release (v2.x)**
2. **Run workflow** → ágat válassz (jellemzően `main`)
3. Mezők:
   - `version` (üres = `package.json` aktuális — pl. `2.5.51`)
   - `release_notes` (markdown, opcionális)
   - `publish_release` = `true` (alapértelmezett — GitHub Release létrehoz)

CLI-vel:
```bash
gh workflow run windows-signed-release.yml \
  -f version=2.5.51 \
  -f release_notes="v2.5.51 — Bali Google login fix + AML offline + devizastátusz" \
  -f publish_release=true
```

Watch progress:
```bash
gh run watch  # interactive
# vagy
gh run list --workflow=windows-signed-release.yml --limit 1
```

## Aláírás verifikálás (helyileg, deploy előtt)

A workflow `Verify * signature` lépései `Get-AuthenticodeSignature`-rel ellenőriznek.

Helyileg, miután letöltötted a release artifact-ot:

```powershell
# Egyenként
Get-AuthenticodeSignature .\Penztar-Setup-2.5.51-20260514.exe
Get-AuthenticodeSignature .\Kozponti-Iranyitokozpont-Setup-2.5.51.exe
Get-AuthenticodeSignature .\Arfolyamkeszito-Setup-2.5.51.exe

# Várt eredmény:
# Status        : Valid
# SignerCertificate.Subject : CN=<BestChange entity-name>, ...
# TimeStamperCertificate    : (timestamp.digicert.com)
```

SHA-256 ellenőrzés a manifest alapján:
```powershell
$expected = Get-Content .\windows-signed-release-sha256.txt | Where-Object { $_ -match '^[a-f0-9]{64}\s+(.+\.exe)$' }
$expected | ForEach-Object {
  $line = $_
  $hash = ($line -split '\s+')[0]
  $file = ($line -split '\s+')[1]
  $actual = (Get-FileHash ".\$file" -Algorithm SHA256).Hash.ToLower()
  if ($hash -eq $actual) { Write-Host "OK   $file" -ForegroundColor Green }
  else { Write-Host "FAIL $file (expected $hash, got $actual)" -ForegroundColor Red }
}
```

## v2.5.51 release készítés (2026-05-14)

Előfeltételek (BEFORE workflow run):

1. Minden PR mergelve main-re (#581, #584, #585, #586, #587, #588, #589, #590)
2. 5-way version sync ellenőrzött: `2.5.51`
   - `package.json`
   - `frontend-react/package.json`
   - `penztar-client/package.json`
   - `kozponti-client/package.json`
   - `arfolyam-keszito-client/package.json`
   - `backend/pom.xml`
3. GitHub Secrets (4 db SM_*) be vannak állítva — `gh api repos/kosazoltan/valutavalto-program/actions/secrets` ellenőrizhetőek
4. PR #590 mergelve (`fix(build): kozponti + arfolyamkeszito vite externals — sql.js + electron deps`)

Workflow trigger:
```bash
gh workflow run windows-signed-release.yml -f version=2.5.51 -f publish_release=true
```

Expected runtime: **~30-45 perc** (4 párhuzamos build job + signing + upload).

## Hetzner backend deploy

A backend JAR a `windows-signed-release.yml` `build-backend` job-ban épül, de a Hetzner deploy-hoz külön workflow van:

```text
.github/workflows/deploy-hetzner.yml
```

Ez automatikusan fut minden `main` push-ra. A `windows-signed-release.yml` artifact-ja közvetlenül NEM deploy-ol Hetzner-re — csak Windows installer build-hez.

## User-action POST-release (Hetzner env var)

A PR #588 (multi-desktop client ID) miatt a Hetzner backend GOOGLE_DESKTOP_CLIENT_ID env var-ja **bővítendő** a régi Electron build client ID-jével:

```bash
ssh valuta@95.216.191.162

# /opt/valutavalto/backend/.env (vagy ahol a systemd EnvironmentFile)
nano /opt/valutavalto/backend/.env

# Régi:
GOOGLE_DESKTOP_CLIENT_ID=316504483942-<existing>.apps.googleusercontent.com

# Új (vesszővel elválasztva, BOTH értékek):
GOOGLE_DESKTOP_CLIENT_ID=316504483942-<existing>.apps.googleusercontent.com,28369624592-3cf88hndlq4eru6ht15f3ikt5e8gs8te.apps.googleusercontent.com

systemctl restart valuta-backend

# Verifikálás
curl -s https://excvaluta.com/api/v1/public/auth/google-config-status | jq .desktopPrefixes
# Várható: ["31650448***", "28369624***"]
```

Nélküle a régi Electron telepítés (28369...) Google bejelentkezése **továbbra is sikertelen** lesz, ahogy Bali / Fabulya bejelentette.

## Tiltások

- ❌ `ALLOW_UNSIGNED_BUILD=1` használata lokal release-ként — CSAK fejlesztői debug-hoz.
- ❌ `--no-verify` git push / signtool bypass / `CODE_SIGN_ENABLED=0`.
- ❌ Lokálisan készített installer terjesztése felhasználóknak.
- ❌ Aláírás verifikálás nélkül distribution.

## Hivatkozott fájlok

- `.github/workflows/windows-signed-release.yml` — a workflow
- `penztar-client/scripts/sign-with-keylocker.js` — signing hook
- `penztar-client/electron-builder.json` — Penztar electron-builder config
- `kozponti-client/electron-builder.json` — Kozponti electron-builder config
- `arfolyam-keszito-client/electron-builder.json` — Arfolyamkeszito electron-builder config
- `installer/build-installer.ps1` — Penztar NSIS wrapper (backend JAR + Electron + JBR)
- `installer/build-cleanup.ps1` — Eltavolito NSIS

## Operations TODO (jövőbeli sprintek)

- **Smoke tests**: EXZ runbook mintájára `npm run smoke:packaged -- -RequireCodeSignature` parancsok hozzáadása a workflow-hoz (currently csak `Get-AuthenticodeSignature` Status=Valid check)
- **SLSA attestation**: `gh attestation` provenance + verification az artifact-okra
- **Blockmap / latest.yml**: auto-update support a Penztar-Eltavolito-ban (electron-updater)
- **Renovate / Dependabot**: SM_* rotation reminder havonta
