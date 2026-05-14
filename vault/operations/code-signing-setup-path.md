---
title: Code Signing Setup Path — Cert → CI → Signed Release
type: runbook
project: Valutavalto-program (BEC ERP)
created_at: 2026-05-14
valid_until: cert kiadás után 3 év (~2029-05)
status: ACTIVE — végrehajtás alatt
---

# Code Signing Setup Path — Cert → CI → Signed Release

A windows-signed-release.yml workflow CSAK akkor mukodokepes, ha a teljes 4 lepeses lanc fut:

1. **Cert acquisition** (Sectigo / DigiCert OV CS — 5-10 nap validation + 4-6 hét reputation)
2. **KeyLocker bind** (DigiCert KeyLocker activation + .p12 client cert + smctl install)
3. **GitHub Secrets setup** (10 db — 6 KeyLocker + 4 Google OAuth)
4. **Workflow trigger** (`gh workflow run windows-signed-release.yml`)

A jelenlegi állapot (2026-05-14): **0/4 lépés komplett**. Az alábbi runbook a teljes utat dokumentálja.

## Audit eredmény (2026-05-14)

| Komponens | Állapot | Forrás |
|---|---|---|
| Sectigo OV CS megrendelés | NINCS leadva | `code-signing-cert-beszerzes-csomag.md` csak terv |
| DigiCert KeyLocker activation | NINCS | nincs `.p12` fájl sehol |
| Windows cert store CodeSigning EKU | 0 cert | `Get-ChildItem Cert:\CurrentUser\My` üres CodeSigning szűrőre |
| Lokál PFX/P12 fájlok | 0 darab | Documents/Downloads/OneDrive/Desktop full keresés |
| smctl.exe telepítve | NINCS | `Get-Command smctl` üres, `C:\Program Files\DigiCert*` nem létezik |
| GitHub Repo Secrets (signing) | 0/6 | `gh api repos/.../actions/secrets` nincs SM_* |
| GitHub Repo Secrets (Google OAuth) | 0/4 | nincs GOOGLE_* |
| GitHub Environment "production" secrets | 0/10 | environment létezik, üres |
| Workflow file (`.github/workflows/windows-signed-release.yml`) | Implementálva | PR #591 (nyitva) |

## 1. Lépés — Sectigo OV Code Signing megrendelés

Forrás: `C:\Users\Kósa Zoltán\Downloads\code-signing-cert-beszerzes-csomag.md` (Kósa Zoltán, 2026-05-05)

### 1.1 Cégadatok bekészítés (Sectigo OV form-hoz)

A `code-signing-cert-beszerzes-csomag.md` tartalmazza:
- Hivatalos cégnév: **EXCLUSIVE BEST Change Zrt.**
- Cégjegyzékszám: **02-10-060505**
- Adószám: **32313332-2-02**
- EU VAT: **HU32313332**
- Székhely: 7621 Pécs, Citrom utca 2-6. földszint 26. ajtó
- D-U-N-S szám: TBD (Dun & Bradstreet lookup vagy kérelem)

### 1.2 Hiányzó adatok beszerzése (CSAK ezek után rendelhető)

- [ ] Friss elektronikus cégkivonat (30 napnál nem régebbi, e-Cégjegyzék)
- [ ] Statisztikai számjel
- [ ] Vezérigazgató / igazgatóság aláírási joga (cégkivonatból)
- [ ] D-U-N-S szám (Dun & Bradstreet)
- [ ] Vezérigazgató személyi igazoló okmány színes scan
- [ ] DCV email előkészítés (admin@excbestchange.hu vagy hasonló)

### 1.3 Megrendelés platformja

**Ajánlott:** [Sectigo CodeSigningStore](https://codesigningstore.com/) reseller — olcsóbb mint közvetlenül Sectigo-tól.

- Sectigo OV Code Signing — 3 év: $649 (acquireSSL ~$580)
- DigiCert KeyLocker (cloud HSM) — add-on, ~$80/év

Alternatíva: SSL.com OV Code Signing — gyorsabb (3-5 nap), de drágább.

### 1.4 Validation folyamat (5-10 munkanap)

A CA visszaigazol:
1. **Domain validation** — DCV email a `info@excbestchange.hu`-ra (vagy alternatíva)
2. **Phone verification** — a cég weboldalán szereplő telefonra hívnak
3. **Document verification** — cégkivonat, aláírási jog, személyi okmány
4. **CN review** — `EXCLUSIVE BEST Change Zrt.` mint Subject Common Name

### 1.5 Kiadás után

- Sectigo emailben küldi a CSR-aláírási linket
- DigiCert KeyLocker portal-on a kulcs generálódik (NEM letöltődik — HSM-ben marad)
- Letöltődik egy `.p12` **kliens authentication** fájl (NEM a signing kulcs!)
- E-mail tartalmazza a `SM_API_KEY` + `SM_KEYPAIR_ALIAS` értékeket

## 2. Lépés — DigiCert KeyLocker activation + tools install

### 2.1 KeyLocker portal-on aktiváló lépések

1. https://one.digicert.com/keylocker bejelentkezés
2. **Generate Keypair** → ECDSA P-256 vagy RSA 3072 (Sectigo OV CS-vel kompatibilis)
3. **Keypair Alias**: `valuta-penztar-sign` (vagy egyéb stabil név)
4. **Activate Certificate** — Sectigo CSR feltöltés vagy keypair-import
5. **Generate Client Certificate** → letöltődik `.p12` (kliens auth)
   - Megjegyzendő jelszót kérdez — ez lesz `SM_CLIENT_CERT_PASSWORD`

### 2.2 Lokális KeyLocker Tools install

DigiCert ONE → KeyLocker → Downloads → **Windows x64 MSI** letöltés.

```powershell
# Lokálisan (egyszeri):
$msi = "$env:USERPROFILE\Downloads\Keylockertools-windows-x64.msi"
Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet /norestart" -Wait

# Verifikáció
& "C:\Program Files\DigiCert\DigiCert Keylocker Tools\smctl.exe" healthcheck
# OK: KeyLocker server reachable
```

### 2.3 MSI URL kinyerés (CI workflow-hoz)

A DigiCert ONE Downloads oldalon **jobb-klikk → Copy link** a Windows x64 MSI letöltési URL-jén. Ez lesz a `SM_CLIENT_TOOLS_MSI_URL` secret értéke. A URL időnként cserélődik (verzió-upgrade); a runbook utolsó frissítését ellenőrizni.

## 3. Lépés — GitHub Secrets feltöltés (10 db)

### 3.1 Signing secrets (DigiCert KeyLocker — 6 db)

```bash
# A .p12 fájlt base64-elj sd:
$p12Path = "$env:USERPROFILE\Downloads\valuta-keylocker-client.p12"
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($p12Path))

# CLI feltöltés
gh secret set SM_HOST --body "https://clientauth.one.digicert.com"
gh secret set SM_API_KEY --body "<KeyLocker portal-ról kapott API key>"
gh secret set SM_CLIENT_CERT_FILE_B64 --body "$b64"
gh secret set SM_CLIENT_CERT_PASSWORD --body "<.p12 jelszó>"
gh secret set SM_KEYPAIR_ALIAS --body "valuta-penztar-sign"
gh secret set SM_CLIENT_TOOLS_MSI_URL --body "<DigiCert MSI letöltési URL>"
```

### 3.2 Google OAuth secrets (production secret gate — 4 db)

```bash
# A .env fájlból:
$env = Get-Content "D:\repo\valutavalto-program\.env"
$webClientId    = ($env | Where-Object { $_ -match '^GOOGLE_CLIENT_ID=' }) -replace '^GOOGLE_CLIENT_ID=',''
$webClientSecret    = ($env | Where-Object { $_ -match '^GOOGLE_CLIENT_SECRET=' }) -replace '^GOOGLE_CLIENT_SECRET=',''
$desktopClientId    = ($env | Where-Object { $_ -match '^GOOGLE_DESKTOP_CLIENT_ID=' }) -replace '^GOOGLE_DESKTOP_CLIENT_ID=',''
$desktopClientSecret    = ($env | Where-Object { $_ -match '^GOOGLE_DESKTOP_CLIENT_SECRET=' }) -replace '^GOOGLE_DESKTOP_CLIENT_SECRET=',''

gh secret set GOOGLE_CLIENT_ID --body "$webClientId"
gh secret set GOOGLE_CLIENT_SECRET --body "$webClientSecret"
gh secret set GOOGLE_DESKTOP_CLIENT_ID --body "$desktopClientId"
gh secret set GOOGLE_DESKTOP_CLIENT_SECRET --body "$desktopClientSecret"
```

### 3.3 Verifikáció

```bash
gh secret list --json name --jq '.[] | .name' | Sort-Object
# Várt 10 új secret a meglévő 20 mellett (összesen 30):
#  SM_HOST, SM_API_KEY, SM_CLIENT_CERT_FILE_B64, SM_CLIENT_CERT_PASSWORD,
#  SM_KEYPAIR_ALIAS, SM_CLIENT_TOOLS_MSI_URL,
#  GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, GOOGLE_DESKTOP_CLIENT_ID, GOOGLE_DESKTOP_CLIENT_SECRET
```

## 4. Lépés — Workflow trigger + verifikáció

### 4.1 Trigger

```bash
gh workflow run windows-signed-release.yml \
  -f version=2.5.51 \
  -f release_notes="v2.5.51 — first signed production release after cert acquisition" \
  -f publish_release=true

# Watch progress
gh run watch
```

Várható runtime: **30-45 perc** (4 párhuzamos build job + signing + upload).

### 4.2 Sikeres lefutás után

```bash
# Letöltés
gh release download v2.5.51 -D D:\release\v2.5.51

# Verifikáció
cd D:\release\v2.5.51
Get-AuthenticodeSignature .\Penztar-Setup-2.5.51-*.exe
# Várt:
# Status                    : Valid
# SignerCertificate.Subject : CN=EXCLUSIVE BEST Change Zrt., O=EXCLUSIVE BEST Change Zrt., L=Pécs, S=Baranya, C=HU
# TimeStamperCertificate    : (timestamp.digicert.com)
```

### 4.3 Distribution

A 4 EXE-t terjesztheted a felhasználóknak (Windows Defender SmartScreen 4-6 hét reputation building után csendes):
- `Penztar-Setup-2.5.51-20260514.exe` (pénztáros klienssel)
- `Penztar-Eltavolito-2.5.51-20260514.exe` (uninstaller)
- `Kozponti-Iranyitokozpont-Setup-2.5.51.exe` (irodavezetői munkaállomás)
- `Arfolyamkeszito-Setup-2.5.51.exe` (RFM főértéktáros)

A `windows-signed-release-sha256.txt` manifestet adj át a kollégáknak verifikálásra (`Get-FileHash` + összehasonlítás).

## Smart-Screen Reputation Building (4-6 hét)

A first signed releaseből Windows Defender SmartScreen "Unrecognized Publisher" warning-ot ad **a reputation building időszak alatt** (~4-6 hét + min 1000 letöltés). Stratégia:

1. **Belső használat** — kollégák gépein telepítés azonnal (User Account Control "Igen" elég, SmartScreen "Run anyway" gomb)
2. **Microsoft submit** — `https://www.microsoft.com/en-us/wdsi/filesubmission` formon submit-eld minden új installer-t Microsoft-nak felülvizsgálatra (24-48 órán belül whitelistelik OV CS alapján)
3. **EV CS upgrade** (~$300/év extra) — ha azonnali SmartScreen jó kell, EV (Extended Validation) CS azonnal reputation-os, de drágább

## Tiltások

- ❌ `ALLOW_UNSIGNED_BUILD=1` használata production release-ként — CSAK fejlesztői debug-hoz.
- ❌ Lokálisan készített installer terjesztése felhasználóknak.
- ❌ `SM_CLIENT_CERT_FILE` (lokális path) — NEM működik CI-en, csak `SM_CLIENT_CERT_FILE_B64` (base64-elt tartalom).
- ❌ A `.p12` fájl commit-olása a repo-ba (SOHA — gitignore-olva van `*.p12` extension).
- ❌ A `SM_API_KEY` / `SM_CLIENT_CERT_PASSWORD` log-olása CI-en (a `set -x` típusú parancsok elkerülendők).

## Aktuális helyzet (2026-05-14)

A workflow infrastruktúra (PR #591) **HASZNÁLHATATLAN**, amíg a 4-lépéses lánc nincs komplett:

| Lépés | Eseménytípus | Becsült idő | Felelős |
|---|---|---|---|
| 1. Sectigo OV CS rendelés | User-action | 5-10 munkanap | Kósa Zoltán |
| 2. KeyLocker activation + tools | User-action | 30 perc | Kósa Zoltán |
| 3. GitHub Secrets feltöltés | User-action | 15 perc | Kósa Zoltán |
| 4. Workflow trigger | CI-task | 30-45 perc | Bárki (gh workflow run) |

**Megjegyzés:** A workflow PR (#591) merge-elése előtt vagy után is végrehajtható a cert acquisition. A merge nem blokkolja a használhatóságot, de a `preflight` job a 10 secret hiánya miatt early-exit-elne, ha jelenleg trigger-elnénk.

## Referencia fájlok

- `C:\Users\Kósa Zoltán\Downloads\code-signing-cert-beszerzes-csomag.md` — cégadat csomag (1. lépéshez)
- `.github/workflows/windows-signed-release.yml` — workflow definíció (PR #591)
- `vault/operations/windows-signed-release-runbook.md` — workflow runbook (PR #591)
- `penztar-client/scripts/sign-with-keylocker.js` — signing hook implementáció
- `penztar-client/electron-builder.json` — signtoolOptions + sign hook reference
- `installer/build-installer.ps1` — Penztar NSIS build (production secret gate)
