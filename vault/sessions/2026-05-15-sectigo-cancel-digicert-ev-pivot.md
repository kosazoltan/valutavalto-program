---
title: 2026-05-15 Sectigo Cancel + DigiCert EV CS Pivot (Azure Key Vault native)
type: session-log
project: Valutavalto-program (BEC ERP) + EXZ (Zalog)
created_at: 2026-05-15
operator: Claude Opus 4.7 (1M context, autonomous mode)
status: ENROLLED — Vendor Status pending, várja DigiCert EV validation 3-5 nap
---

# Sectigo Cancel + DigiCert EV CS Pivot — 2026-05-15

A 2026-05-14-i autonomous mode session után, amelyben a teljes Sectigo OV CS infra+workflow felépítettem ($659.97 paid via SignMyCode reseller, Azure Key Vault Premium HSM-mel), 2026-05-15-i kutatás kiderítette egy KRITIKUS hibát: **a Sectigo OV CS NEM Azure Key Vault-kompatibilis**.

## Pivotot eredményező kutatás

**Microsoft Q&A megerősítés** (https://learn.microsoft.com/en-us/answers/questions/1487290):
> "Azure KeyVault HSM does not support key attestation. Currently, only Luna or YubiKey do."

Sectigo CSR enrollment **key attestation file**-t kér, amit az Azure Key Vault NEM tud előállítani (FIPS 140-2 Level 3 ellenére). Ezért **NINCS az Azure Key Vault opció a SignMyCode HSM Type dropdown**-jában (csak YubiKey, Luna, Google Cloud KMS).

**A teljes Azure Key Vault Premium setup (2026-05-14-i autonomous mode) sajnos NEM működött a Sectigo cert-tel.**

## Megoldás: DigiCert "Azure Key Vault EV Code Signing"

A SignMyCode katalógusában találtam egy SPECIÁLIS terméket:
- **Product: Azure Key Vault EV Code Signing**
- **Supported CA: DigiCert** (NEM Sectigo)
- **Delivery Mode: Azure KeyVault HSM ($0.00)** ← natívan!
- **Validation: EV** (Extended Validation, AZONNALI SmartScreen elfogadás, NEM 4-6 hét reputation building)
- **Ár: $559.99/év** (1 év, CA/B Forum 2026-02 policy)

DigiCert NEM kéri a sectigo-féle key attestation-t — az Azure Key Vault Premium-ot natívan, hivatalosan támogatja.

## Folyamat dokumentálása (Live Chat Douglas-szal)

| Lépés | Eredmény |
|---|---|
| 1. Live Chat indítás SignMyCode-on (Douglas support) | "We have received your cancellation and provided store credit" |
| 2. Cancellation Request submit (CS-BNYD, indok: "I Want to Upgrade Certificate") | Cancellation ticket submitted |
| 3. Douglas immediate store credit aktiválás | $659.97 store credit elérhető a fiókban |
| 4. Új order: Azure Key Vault EV Code Signing | Cart total $559.99 |
| 5. Checkout (cégadat, VAT HU32313332) | Payable Amount: $0.00 (full credit fedezi) |
| 6. Order leadva | Új TX: SMC1015225S262925, Order #CS-BNYK |
| 7. Enrollment Submit (CSR + Org + Contact + Note + Agreement) | Vendor Status: **pending** ✅ |

## Új DigiCert EV CS order részletek

- **Order Number:** CS-BNYK
- **Vendor Order ID:** 1524362467
- **Transaction ID:** SMC1015225S262925
- **Token:** `hdnhnd0xjs20u4u`
- **Product:** Azure Key Vault EV Code Signing, 12 Months
- **Organization Name:** EXCLUSIVE BEST Change Zrt.
- **Delivery Mode:** Azure KeyVault HSM
- **Vendor Status:** pending
- **Verification Email:** kosa.zoltan.ebc@gmail.com
- **Amount:** $559.99
- **Paid:** $0.00 (Store Credit fedezte teljesen)
- **Maradó credit:** $99.98 (jövőbeli renewal-ra)
- **VAT ID:** HU32313332 (rögzítve a invoice-ra)

## Mit MARAD VÁLTOZATLAN a 2026-05-14-i munkámból

A 2026-05-14-i autonomous mode-ban épített infra **100% használható**:

| Komponens | Marad? | Megjegyzés |
|---|---|---|
| Azure subscription "1. előfizetés" | ✅ | Változatlan |
| Resource Group `rg-valuta-signing` | ✅ | Változatlan |
| Key Vault Premium `kv-valuta-codesign` | ✅ | Változatlan |
| Cert request `valuta-codesign-cert` (pending state) | ✅ | Ugyanaz a CSR használva |
| App Registration `sp-valuta-codesign-ci` | ✅ | Változatlan |
| Client Secret v3 (CI) | ✅ | Változatlan |
| Client Secret v4 (EXZ + local JSON) | ✅ | Változatlan |
| Key Vault Access Policy (Cert: Get, Key: Get+Sign) | ✅ | Változatlan |
| 9 GitHub Secret valutavalto repo-n | ✅ | Változatlan |
| 6 GitHub Secret EXZ repo-n | ✅ | Változatlan |
| `windows-signed-release.yml` workflow | ✅ | Változatlan |
| `sign-with-azure-keyvault.js` | ✅ | Változatlan |
| EXZ projekt `sign-with-azure.ps1` integráció | ✅ | Változatlan |
| `azure-codesign-config.json` (EXZ helyi) | ✅ | Változatlan |

**Csak a CA változik** (Sectigo → DigiCert). Az AzureSignTool tooling Az + DigiCert cert-tel ugyanúgy működik, mint Az + Sectigo cert-tel működött volna.

## Pénzügyi összegzés (2 nap alatt)

| Sectigo (2026-05-14) | DigiCert EV (2026-05-15) |
|---|---|
| -$659.97 (paid Sectigo OV 3y) | +$659.97 (store credit refund) |
| | -$559.99 (DigiCert EV 1y) |
| | = +$99.98 maradó credit |
| Net: -$0 (no cash loss, $99.98 credit balance) | |

**Pluszként:** A DigiCert EV → Microsoft SmartScreen **AZONNAL** elfogadja (vs Sectigo OV 4-6 hét reputation building). Ez ÉRTÉKES: a 2026-05-14-i terv "v2.5.51 release után 4-6 hét warning a felhasználóknál" — most NINCS warning!

## Várt timeline

- **2026-05-15** (ma): Enrollment submitted, Vendor Status: pending
- **~2026-05-16 / 2026-05-17** (24-48 óra): DigiCert validation team email — DCV (Domain Control Validation) + dokumentum kérelmek
- **~2026-05-18 / 2026-05-19** (3-5 nap, expedited): DigiCert kibocsátja a cert-et
- **+5 perc** (én): `az keyvault certificate pending merge --vault-name kv-valuta-codesign --name valuta-codesign-cert --file <path>.cer`
- **+30 perc** (én): `gh workflow run windows-signed-release.yml -f version=2.5.51 -f publish_release=true`
- **= ~2026-05-19 / 2026-05-20**: v2.5.51 signed release publikálva GitHub Release-en

## Hivatkozott fájlok

- `vault/sessions/2026-05-14-sectigo-order-checkpoint.md` (régi Sectigo terv)
- `vault/sessions/2026-05-14-autonomous-azure-signing-mode.md` (a 2026-05-14-i autonomous mode log)
- `vault/sessions/2026-05-14-autonomous-final-status.md` (a 2026-05-14-i napi zárás)
- `vault/operations/code-signing-setup-path.md` (most már DigiCert EV-re érvényes a 2-7. lépés)
- `.github/workflows/windows-signed-release.yml` (változatlan)
- `penztar-client/scripts/sign-with-azure-keyvault.js` (változatlan)
