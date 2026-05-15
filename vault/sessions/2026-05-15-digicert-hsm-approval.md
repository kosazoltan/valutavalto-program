---
title: 2026-05-15 DigiCert HSM Approval submitted (Azure Key Vault Premium)
type: session-log
project: Valutavalto-program (BEC ERP) + EXZ (Zalog)
created_at: 2026-05-15
operator: Claude Opus 4.7 (1M context, autonomous mode)
status: PROGRESS — HSM Approval submitted, váró DigiCert next steps
---

# 2026-05-15 DigiCert HSM Approval — Azure Key Vault elfogadva

A 2026-05-15 hajnali pivot után (Sectigo → DigiCert EV CS), 6:55 CEST-kor DigiCert email érkezett a `kosa.zoltan.ebc@gmail.com`-ra:

> **Subject:** [Action Required] Private key protection requirements for DigiCert Order # 1524362467
> **From:** DigiCert <admin@digicert.com>
> 
> "We've received your EV Code Signing request using the Install on an HSM provisioning method.
> Account ID: 1663074
> Order ID: 1524362467
> Organization: EXCLUSIVE BEST Change Zrt.
> ...
> Before we issue your certificate, you must agree to the private key protection requirements on your hardware security module (HSM)."

## HSM Approval form

A link: `https://www.digicert.com/link/hsm-approval.php?token=nk5fx32pffcm62jgdc11rzq7chc2`

A DigiCert form **explicit elfogadja az Azure Key Vault-ot**:

> "The HSM is and will remain in your sole control or configured for your sole use through an audited cloud (**e.g., Azure or AWS**)."

Ez megerősíti a 2026-05-15-i pivot helyességét: a DigiCert EV CS hivatalosan jóváhagyott Azure Key Vault Premium HSM-mel.

### Submitted form data

- **Company name:** EXCLUSIVE BEST Change Zrt.
- **First name:** Zoltan
- **Last name:** Kosa
- **Email:** kosa.zoltan.ebc@gmail.com
- **Title:** CEO
- **Agree checkbox:** ✅ (You agree that you are only using a suitable Hardware Crypto Module to generate Key Pairs to be associated with your EV Code Signing Certificates)
- **Submitted at:** 2026-05-15 ~09:55 CEST

### Aláírt nyilatkozat tartalma (DigiCert legal commitment)

A felhasználó (Zoltan Kosa, EXCLUSIVE BEST Change Zrt. képviselője) megerősítette:

1. ✅ A privát kulcs(ok) biztonságos tárolása HSM-ben, amely megakadályozza a privát kulcs(ok) eltávolítását
2. ✅ A HSM az ügyfél kizárólagos kontrollja alatt marad, audited cloud-on (Azure) keresztül
3. ✅ Nincs ok azt feltételezni, hogy a privát kulcs(ok) HSM-en kívülre kerültek
4. ✅ A privát kulcs FIPS 140-2 Level 2 (vagy Common Criteria EAL4+) ellenőrzött kriptográfiai modulban van védve — Azure Key Vault Premium = FIPS 140-2 Level 3 (még szigorúbb)
5. ✅ Az ügyfél megegyezik kizárólag suitable hardware crypto module-t használni a Key Pair generálásra

DigiCert response: "Thank you! We will continue to work on your order and notify you about further updates."

## Várt további DigiCert lépések (EV CS standard)

| Lépés | Várható | Mit kell tenni |
|---|---|---|
| 1. ✅ HSM Approval (Private Key Protection commitment) | Done 2026-05-15 09:55 | — |
| 2. ⏳ Phone callback verification | Általában 1-2 nap | Felveszi cég publikus telefonját (+36 70 380 0202) |
| 3. ⏳ Document verification | 1-3 nap | Cégkivonat scan + aláírási minta + vezérigazgatói okmány feltöltése (DigiCert portal-on) |
| 4. ⏳ Video verification call (EV mandatory 2024+) | 1-3 nap | Live video call DigiCert validator-ral, ügyfélé személyazonosság megerősítés |
| 5. ⏳ Cert issuance | 3-5 nap a teljes folyamatból | .cer link emailben |

## Időközben elvégzett munka

- ✅ 2026-05-14: Sectigo OV CS + Azure Key Vault Premium setup (8 PR)
- ✅ 2026-05-15 hajnal: Sectigo cancel + DigiCert EV CS order
- ✅ 2026-05-15 reggel: DigiCert HSM Approval form

## Hátralévő AI-action a cert kiadása után

1. **DigiCert email-figyelés** (én pollozom)
2. **Cert letöltés** (én vagy te, ha email link érkezik)
3. **`az keyvault certificate pending merge`** parancs
4. **Workflow trigger `windows-signed-release.yml`** v2.5.51
5. **GitHub Release publikálás** + signature verifikálás (`Get-AuthenticodeSignature`)
