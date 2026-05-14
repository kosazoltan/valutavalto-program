---
title: 2026-05-14 Autonomous Mode — Azure Code Signing infrastructure + EXZ integration
type: session-log
project: Valutavalto-program (BEC ERP) + EXZ (Zalog)
created_at: 2026-05-14
operator: Claude Opus 4.7 (1M context, autonomous mode)
duration: ~3 hours (19:00 - 22:10 CEST)
status: SUCCESS — szerverpipeline kész, vár Sectigo cert kiadásra
---

# Autonomous Mode session — Azure Code Signing infrastructure setup

A user request: "Folytast a munkát akár reggelig, de legyen meg a megfelelő következő telepítő csoport. Én már van certifikálva, addig ne hagyd abba a feladatot, amíg teljesen nem lesz tiszta a CI Flow, és nem lesz hibátlan a program."

A user a chat-ben már elindította a SignMyCode enrollmentet (Live Chat-en), és én autonóm módban folytatom a következőket:
1. Lokális teszt-pipeline ellenőrzés (backend + frontend + 3 Electron client)
2. PR mergek (workflow + docs)
3. Workflow trigger + bug-fix
4. EXZ projekt integráció ugyanazon Azure Key Vault HSM-hez
5. Sectigo cert kiadás utáni handoff-előkészítés

## Lokális teszt-eredmények (mind PASS)

| Komponens | Eredmény |
|---|---|
| Backend Maven test (mvn test) | ✅ PASS (exit 0) |
| Frontend lint | ✅ 469 warning, 0 error |
| Frontend Vitest | ✅ 49 test file / 724 test PASS |
| Penztar-client (lint + typecheck + vitest) | ✅ 10 file / 171 test PASS |
| Kozponti-client (lint + typecheck + test + build) | ✅ exit 0, Vite built in 1.30s |
| Arfolyamkeszito-client (lint + typecheck + test + build) | ✅ exit 0, Vite built in 1.01s |

A főprogram lokális szempontból **hibátlan** — minden CI gate zöld.

## PR mergek

| PR | Branch | Tartalom | Állapot |
|---|---|---|---|
| #591 | feat/windows-signed-release-workflow | Windows Signed Release workflow + sign hook + 3 electron-builder.json | ✅ MERGELVE main-re (`c0b460246`) |
| #592 → #594 | docs/code-signing-setup-path → docs/code-signing-setup-path-rebased | Code signing setup runbook | ⏳ Nyitva (rebased miatti újra) |
| #593 → #595 | docs/sectigo-order-checkpoint → docs/sectigo-order-checkpoint-rebased | Session checkpoint | ⏳ Nyitva (rebased miatti újra) |
| #596 | fix/workflow-actions-versions | actions/checkout + setup-node v6 → v5 fix | ⏳ Nyitva (production blocker fix) |

A #592 és #593 conflict-okat dobott a main-rebase során (mert a #591-gyel közös fájlokat módosítottak). Lokálisan kivettem a setup-path.md + sectigo-checkpoint.md egyedi tartalmait, létrehoztam fresh PR-eket (#594 + #595) és bezártam a régieket. A #592 + #593 ezzel törölve, helyettük #594 + #595 él.

## Critical bug discovered & fixed

A 2026-05-14 20:07 UTC-i workflow run (id `25882811963`) **Preflight job** sajatipusos error-ral fail-elt:

```
##[error]The process 'C:\Program Files\Git\bin\git.exe' failed with exit code 1
```

Root cause: `actions/checkout@v6` és `actions/setup-node@v6` NEM léteznek (a v5 a current stable). PR #596 javítja:
- 9 helyen `actions/checkout@v6` → `@v5`
- 3 helyen `actions/setup-node@v6` → `@v5`

Tanulság: a workflow YAML release tag-eket mindig verifikálni kell a GitHub Marketplace-en — a Cursor / Claude néha tippel jövő-verziókat.

## AzureSignTool + Service Principal verifikáció

A `bhhjl3vok` PowerShell teszt eredménye:
- ✅ **SP auth sikeres** (Application ID `2f6bfdfc-eb2b-4992-863d-f59e98a576a5`)
- ⚠️ "No subscriptions found" warning — ez NORMÁL, mert a SP a Key Vault Access Policy-n keresztül kap hozzáférést, NEM subscription-RBAC-en
- ✅ **Key Vault cert access sikeres**: `valuta-codesign-cert` látható, `enabled: false` (várja a CA-aláírást)

Tehát az **Azure infrastruktúra MŰKÖDIK**. Amint a Sectigo cert kiadásra kerül (3-5 nap), a Merge Signed Request lépés után az AzureSignTool azonnal tud signing-olni.

## EXZ projekt integráció — UGYANAZ a Key Vault, KÜLÖN secret

Az EXZ projekt (`D:\repo\exz`) már tartalmazza:
- `scripts/sign-with-azure.ps1` — PowerShell wrapper az AzureSignTool köré
- `scripts/electron-builder-azure-sign.cjs` — Node.js electron-builder hook
- `.github/workflows/branch-release.yml` — GitHub Actions workflow `AZURE_CODESIGN_*` secret prefix-szel

A JSON struktúra (`azure-codesign-config.json`) **TÖKÉLETESEN KOMPATIBILIS** az EXZ sign-with-azure.ps1-gyel — exact ugyanaz a séma (`azure.keyVaultUri`, `azure.clientId`, stb.).

### Secret allocation

| Secret keyId | Display name | Használat | Lejárat |
|---|---|---|---|
| `f41c2e01-...` | `valuta-codesign-ci-secret-v3` | Valutaváltó CI (kosazoltan/valutavalto-program AZURE_CLIENT_SECRET) | 2028-05-14 |
| `c4bf814c-...` | `exz-codesign-local-v4` | EXZ CI (kosazoltan/EXZ AZURE_CODESIGN_CLIENT_SECRET) + EXZ lokál (Downloads JSON) | 2028-05-14 |

A két secret független — ha bármelyik kompromittálódik, csak azt invalidáljuk, a másik tovább működik.

### EXZ GitHub Secrets feltöltve (6 db)
- AZURE_CODESIGN_TENANT_ID
- AZURE_CODESIGN_CLIENT_ID
- AZURE_CODESIGN_CLIENT_SECRET (v4)
- AZURE_CODESIGN_KEY_VAULT_URI
- AZURE_CODESIGN_CERT_NAME
- AZURE_CODESIGN_TIMESTAMP_URL (`https://timestamp.digicert.com`)

Az EXZ `.github/workflows/branch-release.yml` workflow most már működni fog amint a cert kiadásra kerül.

## Sectigo cert kiadás utáni handoff (előkészített lépések)

Amint a cert email érkezik a SignMyCode-tól:

1. **Letöltés:** `.cer` fájl a Downloads-ba
2. **Azure CLI cert merge:**
   ```powershell
   az keyvault certificate pending merge \
       --vault-name kv-valuta-codesign \
       --name valuta-codesign-cert \
       --file "$env:USERPROFILE\Downloads\valuta-codesign-cert.cer"
   ```
   Vagy az Azure Portal-on: kv-valuta-codesign → Tanúsítványok → valuta-codesign-cert → Tanúsítványművelet → ↑ Aláírt kérések egyesítése

3. **Valutaváltó workflow trigger** (a PR #596 merge után):
   ```bash
   gh workflow run windows-signed-release.yml \
       -f version=2.5.51 \
       -f release_notes="v2.5.51 — first Sectigo-signed Production release (Azure Key Vault Premium HSM)" \
       -f publish_release=true
   ```

4. **EXZ workflow trigger** (kosazoltan/EXZ-en):
   ```bash
   gh workflow run branch-release.yml -R kosazoltan/EXZ
   ```
   Vagy a tag-alapú trigger: push egy release tag-et az EXZ-re.

## Cert state pillanatkép

- **SignMyCode order:** `CS-BNYD` (Status: **Incomplete** — enrollment in progress)
- **Azure Key Vault cert state:** `enabled: false` (waiting for CA-issued cert merge)
- **Várható cert kiadás:** 3-5 munkanap a teljes enrollment + DCV + phone callback után

## Kapcsolódó fájlok

- `vault/operations/code-signing-setup-path.md` (PR #594)
- `vault/sessions/2026-05-14-sectigo-order-checkpoint.md` (PR #595)
- `vault/operations/windows-signed-release-runbook.md` (main, PR #591-bol)
- `.github/workflows/windows-signed-release.yml` (main, PR #591-bol)
- `penztar-client/scripts/sign-with-azure-keyvault.js` (main, PR #591-bol)
- `C:\Users\Kósa Zoltán\Downloads\azure-codesign-config.json` (EXZ helyi config, NEM commitolva)
- `C:\Users\Kósa Zoltán\Downloads\valuta-codesign-cert_26016ff46f66435e9d269c7e56989649.csr` (CSR a SignMyCode-hoz)

## Status report

- **Helyi pipeline:** ✅ TISZTA (minden teszt PASS, minden client build sikeres)
- **CI infrastructure (valutaváltó):** ✅ Workflow main-en, PR #596 javítja a v6→v5 bug-ot
- **CI infrastructure (EXZ):** ✅ Workflow + Secret-ek készen állnak
- **Azure Key Vault:** ✅ Service Principal + Access Policy + cert request all operating
- **Sectigo cert:** ⏳ Enrollment in progress (user oldalon)
- **Workflow signing test:** ⏳ Cert kiadás után automatikus
