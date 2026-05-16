---
title: 2026-05-16 DigiCert EV CS — phone verification ONLY pending
type: session-log
project: Valutavalto-program (BEC ERP)
created_at: 2026-05-16
operator: Claude Opus 4.7 (1M context)
status: BLOCKED on user — phone callback scheduling needed
---

# DigiCert EV CS — current status (2026-05-16)

## Order info
- **DigiCert Order ID:** 1524362467
- **Vendor (SignMyCode) Order:** CS-BNYK
- **Validation ID:** 2206189
- **Org:** EXCLUSIVE BEST Change Zrt.
- **Account ID:** 1663074
- **Provisioning method:** Install on HSM (Azure Key Vault Premium)
- **Phone number under verification:** +36 72 515 625 (DigiCert-VERIFIED via cégnyilvántartás)

## Timeline summary

| CEST | Event | Source email |
|---|---|---|
| 2026-05-15 06:55 | DigiCert: HSM Approval form requested | admin@digicert.com |
| 2026-05-15 09:55 | HSM Approval submitted (Azure KV Premium accepted) | (manual confirm) |
| 2026-05-15 12:33 | SignMyCode: company validation done; phone calls to +36 72 515 625 failed | Avery James, support@signmycode.com |
| 2026-05-15 13:08 | DigiCert Scheduling: appointment canceled | scheduling@digicert.com |
| 2026-05-15 13:20 | User forwarded cancelation to self | (sent) |
| 2026-05-16 00:54 | SignMyCode follow-up: still waiting for callback scheduling | Daniel Grant, support@signmycode.com |

## What's done
- ✅ HSM Approval (Azure Key Vault Premium HSM accepted as "audited cloud")
- ✅ Company validation (cégkivonat / Hungarian Companies registry)

## What's pending
- ⏳ **Phone verification ONLY** — user must schedule callback via https://callscheduler.digicert.com/v2/#book and ensure someone answers +36 72 515 625 in English at the scheduled time

## After phone verification (auto)
1. DigiCert issues `.cer` file (1-2 business days)
2. `az keyvault certificate pending merge --vault-name kv-valuta-codesign --name valuta-codesign-cert --file <cer>`
3. `gh workflow run windows-signed-release.yml -f version=2.5.54 -f publish_release=true`
4. Signed installer build + GitHub Release publish

## Fallback option

If +36 72 515 625 cannot reliably answer (Pécs landline, 72 area code):
- Reply to SignMyCode thread #68145 with: *"Please request DigiCert to use alternate verified number +36 70 380 0202 if present in company registry."*
- DigiCert generally accepts alternate numbers if also publicly listed (cégbíróság, Yellow Pages, official company website)

## Hivatkozott artefaktok

- DigiCert order email: `admin@digicert.com` → "[Action Required] Private key protection requirements for DigiCert Order # 1524362467" (Thread `19e29fdccc191809`)
- SignMyCode validation-complete: Thread `19e2b32c5afd7969`
- DigiCert cancel: Thread `19e2b52f35c67718`
- SignMyCode follow-up: Thread `19e2dd9988d9e6d8`
- Previous session: `vault/sessions/2026-05-15-digicert-hsm-approval.md`
