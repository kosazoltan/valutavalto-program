---
title: 2026-05-16 DigiCert EV CS — phone verification ONLY pending
type: session-log
project: Valutavalto-program (BEC ERP)
created_at: 2026-05-16
operator: Claude Opus 4.7 (1M context)
status: SCHEDULED — DigiCert authenticity call booked for 2026-05-18 16:30-17:00 CEST
---

# DigiCert EV CS — current status (2026-05-16)

> Privacy note: operational identifiers (DigiCert order/account/validation IDs,
> verified phone number, support thread IDs) are kept in a private ops store
> outside this public repo. See `~/.claude/projects/.../memory/project_codesigning_pivot_digicert_ev_2026_05_15.md` for the values.

## Order info (redacted)

- **DigiCert Order ID:** `<REDACTED — private ops store>`
- **Vendor (SignMyCode) Order:** `<REDACTED>`
- **Validation ID:** `<REDACTED>`
- **Org:** EXCLUSIVE BEST Change Zrt. (publicly listed company)
- **Account ID:** `<REDACTED>`
- **Provisioning method:** Install on HSM (Azure Key Vault Premium)
- **Phone number under verification:** `<REDACTED verified company phone>` (DigiCert-VERIFIED via cégnyilvántartás)

## Timeline summary

| CEST | Event | Source |
|---|---|---|
| 2026-05-15 06:55 | DigiCert: HSM Approval form requested | DigiCert (admin) |
| 2026-05-15 09:55 | HSM Approval submitted (Azure KV Premium accepted) | (manual confirm) |
| 2026-05-15 12:33 | SignMyCode: company validation done; phone calls failed | SignMyCode support |
| 2026-05-15 13:08 | DigiCert Scheduling: appointment canceled | DigiCert scheduling |
| 2026-05-15 13:20 | User forwarded cancelation to self | (sent) |
| 2026-05-16 00:54 | SignMyCode follow-up: still waiting for callback scheduling | SignMyCode support |
| 2026-05-16 11:09 | User booked DigiCert call scheduler slot (2026-05-18 16:30 CEST); SignMyCode ticket created; DigiCert acknowledged with case numbers | SignMyCode ticket + DigiCert auto-reply |
| 2026-05-18 16:30 | **DigiCert authenticity call SCHEDULED** at company office line | (pending) |

## What's done

- ✅ HSM Approval (Azure Key Vault Premium HSM accepted as "audited cloud")
- ✅ Company validation (cégkivonat / Hungarian Companies registry)

## What's pending

- ⏳ **Phone verification SCHEDULED** — DigiCert callback booked for **Monday 2026-05-18 16:30-17:00 CEST** (during Hungarian office hours, so the registered office line will answer). Booking confirmed via SignMyCode ticket and DigiCert case (IDs in private ops store).
- Previous booking attempt failed because slot was outside Hungarian office hours (23:00 Budapest local).

## After phone verification (auto)

1. DigiCert issues `.cer` file (1-2 business days)
2. `az keyvault certificate pending merge --vault-name kv-valuta-codesign --name valuta-codesign-cert --file <cer>`
3. `gh workflow run windows-signed-release.yml -f version=<x.y.z> -f publish_release=true`
4. Signed installer build + GitHub Release publish

## Fallback option

If the primary verified phone cannot reliably answer:

- Reply to the SignMyCode support thread requesting DigiCert to use the alternate verified company number listed in the public Companies registry.
- DigiCert generally accepts alternate numbers if also publicly listed (cégbíróság, Yellow Pages, official company website).

## Hivatkozott artefaktok

- Previous session: `vault/sessions/2026-05-15-digicert-hsm-approval.md`
- Private ops store: auto-memory `project_codesigning_pivot_digicert_ev_2026_05_15.md` (off-repo)
- Email threads: in operator inbox, IDs not committed to public repo
