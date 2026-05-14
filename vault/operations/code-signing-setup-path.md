---
title: Code Signing Setup Path — Cert → CI → Signed Release (Azure Key Vault Premium HSM)
type: runbook
project: Valutavalto-program (BEC ERP)
created_at: 2026-05-14
updated_at: 2026-05-14
valid_until: cert kiadás után 3 év (~2029-05)
status: ACTIVE — végrehajtás alatt
hsm_platform: Azure Key Vault Premium HSM (NEM DigiCert KeyLocker — kompatibilitási ok)
---

# Code Signing Setup Path — Cert → CI → Signed Release

A `windows-signed-release.yml` workflow CSAK akkor mukodokepes, ha a teljes **4 lepeses lanc** fut:

1. **Cert acquisition** (Sectigo OV CS via SignMyCode — 3-5 nap validation + 4-6 hét reputation building)
2. **Azure Key Vault Premium HSM setup** (Resource Group + Key Vault + RSA-HSM key + CSR + cert import)
3. **GitHub Secrets setup** (9 db — 5 Azure + 4 Google OAuth)
4. **Workflow trigger** (`gh workflow run windows-signed-release.yml`)

## ⚠️ HSM platform váltás (2026-05-14)

A korábbi terv **DigiCert KeyLocker** volt — ezt elvetettük, mert csak DigiCert-issued cert-ekkel mukodik (forrás: SignMyCode official tutorial). Sectigo OV CS-vel a Microsoft **Azure Key Vault Premium HSM** a hivatalos, Sectigo-jovahagyott alternativa.

| Tétel | DigiCert KeyLocker (elvetve) | Azure Key Vault Premium (új) |
|---|---|---|
| Sectigo OV CS (3 év) | $659.97 | $659.97 (változatlan) |
| HSM platform | $600 / 3 év | ~$180 / 3 év |
| Tooling | smctl (proprietary) | AzureSignTool (open-source, vcsjones) |
| **Összesen** | **~$1260** | **~$840** |

## Audit eredmény (2026-05-14)

| Komponens | Állapot | Forrás |
|---|---|---|
| Sectigo OV CS megrendelés | ✅ **LEADVA** | SignMyCode order SMC1015225S638431, $659.97 paid |
| Order Token | ✅ `wrmxwidaaxyzceh` | Email visszaigazolás |
| Azure subscription | ⏳ Folyamatban | User: Azure free tier (~$200 credit, NEM kötelezo) |
| Azure Key Vault Premium | ⏳ Folyamatban | `kv-valuta-codesign` névvel, West Europe |
| RSA-HSM key + CSR | ⏳ Folyamatban | Certificate Policy alapján generálandó |
| CSR upload a SignMyCode portalra | ⏳ Folyamatban | Token wrmxwidaaxyzceh-vel |
| Sectigo DCV + validation | ⏳ Folyamatban | 3-5 nap (SignMyCode SLA) |
| App Registration + Access Policy | ⏳ Pending | Service Principal a CI-hez |
| Cert import Azure-ba | ⏳ Pending | A Sectigo .cer kiadás után |
| GitHub Repo Secrets (signing) | 0/5 | `AZURE_*` még feltöltendo |
| GitHub Repo Secrets (Google OAuth) | 0/4 | `GOOGLE_*` még feltöltendo |
| Workflow file | ✅ Implementálva | PR #591 (Azure-átírás 2026-05-14) |
| Sign hook | ✅ `sign-with-azure-keyvault.js` | PR #591 (electron-builder hook) |

## 1. Lépés — Sectigo OV Code Signing megrendelés ✅ KÉSZ

**Megrendelés:** SignMyCode (Sectigo Platinum Partner reseller).

- **Order ID:** SMC1015225S638431
- **Token:** wrmxwidaaxyzceh
- **Termék:** Sectigo OV Code Signing, 3 év (36 hónap)
- **Ár:** $659.97 (cégkártyával fizetve, 2026-05-14)
- **Delivery method:** "Use Existing Token" / BYOH (Bring Your Own HSM) — a kulcs az Azure Key Vault-ban marad

A SignMyCode email tartalmazza:
- Validation team email cím
- Enrollment portal link (CSR feltöltéshez)
- DCV email választás link
- Document upload portal

## 2. Lépés — Azure Key Vault Premium HSM setup

### 2.1 Azure subscription (egyszeri)

🔗 https://azure.microsoft.com/free

- **Start free** → bejelentkezés Microsoft account-tal (vagy új account a `kosa.zoltan.ebc@gmail.com`-mal)
- Cégadatok kitöltése (EXCLUSIVE BEST Change Zrt.)
- Cégkártya hozzáadása (verifikációs ~1 USD lefoglalás, visszaadja)
- 12 hónap **$200 credit** kap automatikusan + 12 hónap ingyenes szolgáltatások

**Megjegyzés:** A Key Vault Premium tier ~$5/hó. A $200 credit kb. 36 hónapra elég.

### 2.2 Resource Group létrehozás

Azure Portal → **Resource groups** → **+ Create**:

- **Subscription:** Az imént létrehozott
- **Resource group:** `rg-valuta-signing`
- **Region:** `West Europe` (közeli, GDPR-kompatibilis)
- **Tags:** `purpose=code-signing`, `owner=kosa.zoltan`

### 2.3 Key Vault Premium létrehozás

Azure Portal → **Create a resource** → **Key Vault**:

- **Resource group:** `rg-valuta-signing`
- **Key vault name:** `kv-valuta-codesign` (globálisan egyedi)
- **Region:** `West Europe`
- **Pricing tier:** **Premium** ← **KÖTELEZO** (HSM-backed kulcshoz)
- **Soft delete:** Enabled (90 napos retention)
- **Purge protection:** Enabled (rendszerszintu biztonság)

### 2.4 RSA-HSM kulcs + CSR generálás (Certificate Policy alapján)

A Sectigo OV CS-hez egy **Certificate signing request (CSR)**-t kell elokészíteni a Key Vault-ban.

Azure Portal → `kv-valuta-codesign` → **Certificates** → **+ Generate/Import**:

- **Method of Certificate Creation:** **Generate**
- **Certificate Name:** `valuta-codesign-cert`
- **Type of Certificate Authority (CA):** **Certificate issued by a non-integrated CA**
- **Subject:** `CN=EXCLUSIVE BEST Change Zrt., O=EXCLUSIVE BEST Change Zrt., L=Pécs, S=Baranya, C=HU`
- **DNS Names:** (üres — code signing cert NEM domain-specifikus)
- **Validity Period (months):** **36** (3 év — de Sectigo automatikusan 460 napra korlátozza)
- **Content Type:** **PKCS #12**
- **Lifetime Action Type:** Email all contacts at 80% expiry
- **Advanced Policy Configuration:**
  - **Subject Alternative Name (SAN):** üres
  - **Key Type:** **RSA-HSM** ← **KÖTELEZO** (Sectigo OV CS minimum követelmény)
  - **Key Size:** **3072** (Sectigo 2026 minimum; 4096 is OK, de lassabb signing)
  - **Exportable Private Key:** **No** ← **KÖTELEZO** (HSM = nem-exportálható)
  - **Reuse Key on Renewal:** No
  - **Enhanced Key Usages (EKU):** `1.3.6.1.5.5.7.3.3` (Code Signing)

**Create** → 30-60 sec.

### 2.5 CSR letöltés

Azure Portal → `kv-valuta-codesign` → **Certificates** → `valuta-codesign-cert` → **Certificate Operation** → **Download CSR**.

Letöltés: `valuta-codesign-cert.csr` (PEM-formátumú szöveges fájl).

## 3. Lépés — SignMyCode enrollment + Sectigo validation

### 3.1 CSR feltöltés a SignMyCode portalra

A SignMyCode email-ben kapott "Enrollment Link" megnyitása, vagy:

🔗 https://signmycode.com/enrollment-portal/order/SMC1015225S638431

- **Order Token:** `wrmxwidaaxyzceh`
- **CSR upload:** a 2.5 lépésben letöltött `valuta-codesign-cert.csr` fájlt feltölteni
- **Validation Type:** OV (Organization Validation)
- **Common Name:** EXCLUSIVE BEST Change Zrt. (automatikusan kitöltodik a CSR-bol)

### 3.2 DCV (Domain Control Validation)

Választható módok:
- **Email DCV** (gyors, 5 perc): `admin@excbestchange.hu` (vagy `info@`, `webmaster@`, `postmaster@`, `hostmaster@`) — Sectigo kuld egy email-t verification linkkel
- **HTTP DCV** (10-30 perc): egy `.txt` fájlt elhelyezni a `https://excbestchange.hu/.well-known/pki-validation/<hash>.txt` URL-en
- **DNS DCV** (5-30 perc DNS propagation): TXT record a `_sectigo-validation.excbestchange.hu`-ra

**Ajánlott:** Email DCV (ha az `admin@` postafiók muködik).

### 3.3 Document upload

A SignMyCode portal-on a következo iratokat kérik (a 2026-05-05-i csomag alapján már elokészítve):

- ✅ Friss cégkivonat (e-Cégjegyzék, 30 napnál nem régebbi)
- ✅ Statisztikai számjel (cégkivonatból)
- ✅ Vezérigazgató aláírási joga (cégkivonatból, képviseleti jogcím)
- ✅ Vezérigazgató személyi okmány színes scan
- D-U-N-S szám: TBD (Dun & Bradstreet lookup, ha még nincs)

### 3.4 Phone callback

Sectigo a cég weboldalán szereplo telefonra hív (+36 70 380 0202 — a `valuta.tracker` szerint a cég official phone-ja). Az ügyintézo verifikálja:
- Cégnév
- Címet
- A rendelés szándékát

### 3.5 Cert kiadás (3-5 nap SignMyCode SLA)

A Sectigo email-ben küldi a kiadott cert-et:
- `valuta-codesign-cert.cer` (PEM-encoded X.509 certificate)
- Vagy a portal-on letöltheto bundle (a Sectigo intermediate chain-nel)

### 3.6 Cert import az Azure Key Vault-ba

Azure Portal → `kv-valuta-codesign` → **Certificates** → `valuta-codesign-cert` → **Certificate Operation** → **Merge Signed Request**:

- **Certificate file:** a Sectigo-tól kapott `.cer` (vagy `.crt`, `.pem`) fájlt feltölteni
- **Merge** → 5-10 sec

Most a Key Vault-ban van egy teljes cert-private key pair, ahol a private key **soha nem hagyja el a HSM-et**.

## 4. Lépés — App Registration (Service Principal) + Access Policy

A CI workflow nem human-account-tal autentikál, hanem Service Principal-lal.

### 4.1 App Registration létrehozás

Azure Portal → **Microsoft Entra ID** → **App registrations** → **+ New registration**:

- **Name:** `sp-valuta-codesign-ci`
- **Supported account types:** "Accounts in this organizational directory only"
- **Redirect URI:** (üres)
- **Register**

A regisztráció után az "Overview" oldalon:
- **Application (client) ID** → ez lesz az `AZURE_CLIENT_ID` secret
- **Directory (tenant) ID** → ez lesz az `AZURE_TENANT_ID` secret

### 4.2 Client secret létrehozás

App Registration → **Certificates & secrets** → **Client secrets** → **+ New client secret**:

- **Description:** `valuta-codesign-ci-secret`
- **Expires:** **24 months** (max 2028-05-14)
- **Add** → MÁSOLD KI azonnal a **Value** mezot (csak egyszer látszik!)

A **Value** lesz az `AZURE_CLIENT_SECRET` secret. A **Secret ID** NEM kell.

### 4.3 Access Policy a Key Vault-ban

Azure Portal → `kv-valuta-codesign` → **Access policies** → **+ Create**:

- **Permissions:**
  - **Certificate Permissions:** `Get`
  - **Key Permissions:** `Sign`, `Get`
- **Principal:** `sp-valuta-codesign-ci` (a Service Principal nevét beírni, kiválasztani a dropdown-ból)
- **Application:** (üres, nem kell)
- **Next** → **Create**

⚠️ A **Sign** key permission KÖTELEZO — enélkül az `azuresigntool` 403 Forbidden-t kap.

## 5. Lépés — GitHub Secrets feltöltés (9 db)

### 5.1 Signing secrets (Azure Key Vault — 5 db)

```bash
# Az AI agent (Claude) feltölti, a user-nek nem kell.
gh secret set AZURE_KEY_VAULT_URI --body "https://kv-valuta-codesign.vault.azure.net/"
gh secret set AZURE_KEY_VAULT_CERT_NAME --body "valuta-codesign-cert"
gh secret set AZURE_TENANT_ID --body "<Microsoft Entra Tenant ID — App Registration overview-ról>"
gh secret set AZURE_CLIENT_ID --body "<Application (client) ID — App Registration overview-ról>"
gh secret set AZURE_CLIENT_SECRET --body "<Client secret Value — az 4.2-bol kimásolt>"
```

### 5.2 Google OAuth secrets (production secret gate — 4 db)

```bash
# A .env fájlból:
gh secret set GOOGLE_CLIENT_ID --body "$(grep '^GOOGLE_CLIENT_ID=' .env | cut -d= -f2-)"
gh secret set GOOGLE_CLIENT_SECRET --body "$(grep '^GOOGLE_CLIENT_SECRET=' .env | cut -d= -f2-)"
gh secret set GOOGLE_DESKTOP_CLIENT_ID --body "$(grep '^GOOGLE_DESKTOP_CLIENT_ID=' .env | cut -d= -f2-)"
gh secret set GOOGLE_DESKTOP_CLIENT_SECRET --body "$(grep '^GOOGLE_DESKTOP_CLIENT_SECRET=' .env | cut -d= -f2-)"
```

### 5.3 Verifikáció

```bash
gh secret list --json name --jq '.[] | .name' | Sort-Object
# Várt 9 új secret a meglévo X mellett:
#  AZURE_KEY_VAULT_URI, AZURE_KEY_VAULT_CERT_NAME, AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET
#  GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, GOOGLE_DESKTOP_CLIENT_ID, GOOGLE_DESKTOP_CLIENT_SECRET
```

## 6. Lépés — Workflow trigger + verifikáció

### 6.1 Trigger

```bash
gh workflow run windows-signed-release.yml \
  -f version=2.5.51 \
  -f release_notes="v2.5.51 — first signed production release (Sectigo OV CS + Azure Key Vault Premium HSM)" \
  -f publish_release=true

# Watch progress
gh run watch
```

Várható runtime: **30-45 perc** (4 párhuzamos build job + signing + upload).

### 6.2 Sikeres lefutás után

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

### 6.3 Distribution

A 4 EXE-t terjesztheted a felhasználóknak:
- `Penztar-Setup-2.5.51-20260514.exe` (pénztáros klienssel)
- `Penztar-Eltavolito-2.5.51-20260514.exe` (uninstaller)
- `Kozponti-Iranyitokozpont-Setup-2.5.51.exe` (irodavezetoi munkaállomás)
- `Arfolyamkeszito-Setup-2.5.51.exe` (RFM foértéktáros)

A `windows-signed-release-sha256.txt` manifestet add át a kollégáknak verifikálásra (`Get-FileHash` + összehasonlítás).

## Smart-Screen Reputation Building (4-6 hét)

A first signed release-bol Windows Defender SmartScreen "Unrecognized Publisher" warning-ot ad **a reputation building idoszak alatt** (~4-6 hét + min 1000 letöltés). Stratégia:

1. **Belso használat** — kollégák gépein telepítés azonnal (UAC "Igen" elég, SmartScreen "Run anyway" gomb)
2. **Microsoft submit** — `https://www.microsoft.com/en-us/wdsi/filesubmission` form-on submit-eld minden új installer-t (24-48 órán belül whitelistelik OV CS alapján)
3. **EV CS upgrade** (~$300/év extra) — ha azonnali SmartScreen jó kell, EV (Extended Validation) CS azonnal reputation-os, de drágább

## Tiltások

- ❌ `ALLOW_UNSIGNED_BUILD=1` használata production release-ként — CSAK fejlesztoi debug-hoz.
- ❌ Lokálisan készített installer terjesztése felhasználóknak.
- ❌ A `.p12` / `.pfx` fájl commit-olása a repo-ba (SOHA — gitignore-olva van `*.p12`, `*.pfx` extension).
- ❌ `AZURE_CLIENT_SECRET` log-olása CI-en (a `set -x` típusú parancsok elkerülendok).
- ❌ Service Principal-nak felesleges Key Vault permissions (Delete, Update — NEM kell, csak Get + Sign).
- ❌ Exportable Private Key-vel létrehozott kulcs Key Vault-ban (a HSM-tier értelmét veszti).
- ❌ DigiCert KeyLocker telepítés — **inkompatibilis** a Sectigo cert-tel, idoveszteség.

## Aktuális helyzet (2026-05-14)

| Lépés | Állapot | Felelos | Várható ido |
|---|---|---|---|
| 1. Sectigo OV CS rendelés | ✅ KÉSZ | Kósa Zoltán | — |
| 2. Azure Key Vault Premium setup | ⏳ User-action | Kósa Zoltán | 30 perc |
| 3. SignMyCode enrollment + validation | ⏳ User-action + waiting | Kósa Zoltán + Sectigo | 3-5 munkanap |
| 4. App Registration + Access Policy | ⏳ User-action | Kósa Zoltán | 15 perc |
| 5. GitHub Secrets feltöltés | ⏳ AI-action | Claude (autonóm) | 5 perc |
| 6. Workflow trigger | ⏳ AI-action | Claude (autonóm) | 30-45 perc CI |

## Referencia fájlok

- `.github/workflows/windows-signed-release.yml` — workflow definíció (PR #591, Azure-átírt)
- `penztar-client/scripts/sign-with-azure-keyvault.js` — signing hook (AzureSignTool)
- `penztar-client/electron-builder.json` — signtoolOptions + sign hook reference
- `installer/build-installer.ps1` — Penztar NSIS build (production secret gate)
- `vault/operations/windows-signed-release-runbook.md` — workflow runbook
- `vault/sessions/2026-05-14-sectigo-order-checkpoint.md` — order details + HSM döntés
