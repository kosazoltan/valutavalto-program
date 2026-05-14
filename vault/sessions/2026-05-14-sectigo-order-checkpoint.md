# Session 2026-05-14 — Sectigo OV CS megrendelés CHECKPOINT

**Időszak:** 2026-05-14 17:45-tól folyamatos
**Felelős:** Kósa Zoltán (megrendelés) + AI Ügynök (workflow + secrets + trigger)

## Mai mai-i napi progress (PR-ek)

8 PR mergelve main-re (#581+#584+#585+#586+#587+#588+#589+#590) — release-relatív tartalom v2.5.51-be:
- Rate-maker főlap Phase 1 MVP
- CustomerPanel UX (hiányzó mezők hint)
- Google OAuth diagnostic endpoint
- AML offline degradált mód (local-first)
- Devizastátusz per-tétel (DSZ oszlop)
- GOOGLE_DESKTOP_CLIENT_ID multi-value support
- v2.5.51 4-way version bump
- sql.js externals fix (kozponti+arfolyamkeszito)

2 PR nyitva:
- **#591** — Windows signed release workflow (`.github/workflows/windows-signed-release.yml`) — vár a cert acquisition-ra
- **#592** — Code signing setup path runbook (`vault/operations/code-signing-setup-path.md`)

## Cert acquisition — döntések (2026-05-14, frissítve Perplexity research után + user korrekcio)

| Döntés | Érték | Indok |
|---|---|---|
| Reseller | **SignMyCode** (FRISSÍTVE) | 3-5 nap validation (gyorsabb mint CodeSigningStore 4-8 nap), Sectigo Platinum Partner, jobban skálázott automation. Ár ~azonos ($660 vs $658 BYOH-val). |
| Storage | **DigiCert KeyLocker** (cloud HSM) | CI workflow-kompatibilis, NEM USB token, BYOH = no shipping fee |
| Fizetés | **Cég bankkártya** (számlázás USD-ben) | CodeSigningStore csak USD-ben számláz, EUR-kártya konvertál (~1-3% banki díj) |
| Cert validity | **3 év (annual re-issuance)** | Iparági policy 2026 Feb: max 460 napos validity → multi-year plan annual re-issue HSM-en automatikus |

### Új 2026-os realitások (eltérés a 2026-05-05-i tervtől)

A 2026-05-05-i `code-signing-cert-beszerzes-csomag.md` ezeket NEM tartalmazta:

1. **Sectigo 460-napos max validity** (2026 Feb iparági policy). Multi-year plans **annual re-issuance**-szal mennek HSM-en automatikus. NEM kell tőled új order minden évben — csak a cert technikailag újra-kibocsát ~15 havonta.
2. **Reális ár:** ~$1 260 / 3 év (cert $658 + KeyLocker $200/év × 3). A régi terv $329 árat jósolt → mai ár ~2-3x annyi.
3. **EUR fizetés:** CodeSigningStore USD-ben számláz, a Te EUR-kártyád bankja konvertál (Visa/MC standard processing).

## Cert acquisition — jelenlegi lépés

**Status (2026-05-14 19:26 CEST):** ✅ **MEGRENDELÉS LEADVA SignMyCode-on, fizetés sikeres.**

### Order részletek (SignMyCode dashboard)

| Mező | Érték |
|---|---|
| Vendor | SignMyCode |
| Account email | kosa.zoltan.ebc@gmail.com |
| Order Date | 2026-05-14 (UTC) |
| Order Type | New |
| Order Validity | 36 Months (3 év, annual re-issuance HSM-en) |
| Delivery Mode | Use Existing Token (= BYOH, $0 shipping) |
| Amount paid | $659.97 (cég Visa/MC, USD) |
| **Transaction ID** | **SMC1015225S638431** |
| **Stripe Payment Intent** | pi_3TX2zbEtX5pB0VYc1SeX4Y0n |
| **Enrollment Token** ⚠️ | `wrmxwidaaxyzceh` (CSR upload + enrollment-hez) |
| Dashboard | https://signmycode.com/dashboard/order-detail?odid=BNYD |

### NEXT: DigiCert KeyLocker activation

A SignMyCode enrollment NEM indítható el CSR nélkül. A CSR a DigiCert KeyLocker-ben generálódik (HSM-belső, NEM letölthető private key).

URL: https://codesigningstore.com/sectigo-code-signing

### Form-értékek (verifikálva a `Best cégkivonat 2026 05. hó.pdf` 2025-12-14-i cégkivonatból)

| Mező | Érték |
|---|---|
| Organization Name | `EXCLUSIVE BEST Change Zrt.` |
| Full Legal Name | `EXCLUSIVE BEST Change Pénzügyi Zártkörűen működő Részvénytársaság` |
| Country | `Hungary (HU)` |
| State/Province | `Baranya` |
| City | `Pécs` |
| Postal Code | `7621` |
| Address Line 1 | `Citrom utca 2-6. földszint 26. ajtó` |
| Phone | `+36 70 380 0202` |
| Email (DCV) | `info@excbestchange.hu` |
| Tax ID / VAT | `HU32313332` |
| Cégjegyzékszám | `02-10-060505` |
| Bejegyezve | `2023-08-01` (Pécsi Törvényszék Cégbírósága) |

## Iratok-helyzet

A `C:\Users\Kósa Zoltán\Downloads\` mappa készleten lévő relevant iratok:

- `Best cégkivonat 2026 05. hó.pdf` — friss elektronikus cégkivonat (215 KB)
- `Cegkivonat_0209080730_13448_14715.pdf` — másik verzió
- `Bizalmi vagyonkezelési szerződés kivonata_elektronikusan aláírt.pdf` — bizalmi vagyonkezelési
- `Vagyonkezelési_megbízási_szertődés-kivonata.pdf`
- `CM26110739294_40_31_signed.pdf` + `CM26110752548_40_31_signed.pdf` — 2 közjegyzői jegyzőkönyv (signed PDF)

Az aláírási minta + közjegyzői hitelesítés (Dolgán Antal közjegyző?) elkészült. A Sectigo verifier kérheti a cégkivonatot + aláírási mintát + személyi okmány scan-t.

## Várható következő lépések (időrendben)

| Lépés | Kinek | Eszköz | Becsült idő |
|---|---|---|---|
| 1. Order form kitöltés + fizetés | **User** | CodeSigningStore checkout | 15 perc |
| 2. DCV email kattintás | **User** | info@excbestchange.hu inbox | 2 perc |
| 3. Cégkivonat + aláírási minta upload | **User** | Sectigo verifier portal | 10 perc |
| 4. Phone callback | **User** | +36 70 380 0202 | 5-15 perc |
| 5. **Sectigo cert kiadás** | Auto | email | 3-5 munkanap |
| 6. DigiCert KeyLocker megrendelés (külön ~$200/év) | **User + AI** | DigiCert ONE | 30 perc |
| 7. KeyLocker keypair generálás | **User + AI** | DigiCert portal | 5 perc |
| 8. CSR átadás Sectigo-nak | **User + AI** | Sectigo "Re-Key" form | 10 perc |
| 9. Cert importálás KeyLocker-be | Auto | DigiCert + Sectigo | 1 nap |
| 10. .p12 client cert letöltés | **User** | DigiCert portal | 5 perc |
| 11. Smctl tools install lokálisan | **User** | MSI install | 5 perc |
| 12. **10 GitHub Secret feltöltés** | **AI** | `gh secret set` | 5 perc |
| 13. **Workflow trigger v2.5.51** | **AI** | `gh workflow run` | 30-45 perc CI |
| 14. Aláírás verifikálás | **AI** | `Get-AuthenticodeSignature` | 1 perc |
| 15. SmartScreen reputation building | Passive | Microsoft submission | 4-6 hét |

## AI Ügynök szerepkör (egyértelmű)

**NEM tudom megtenni:**
- Sectigo/CodeSigningStore portal-ba belépni (nincs jelszó/MFA)
- DCV email linkjére kattintani
- DigiCert portal-on keypair-t generálni
- .p12 cert-et letölteni
- Cég-bankkártyával fizetni

**Tudom megtenni:**
- Step-by-step navigáció (te kattintasz a UI-n, én magyarázom mit/hova)
- GitHub Secrets feltöltés (`gh secret set` 10x)
- Workflow trigger (`gh workflow run windows-signed-release.yml`)
- Aláírás verifikálás Windows-on
- Vault dokumentálás minden lépésnél

## Következő ülés handoff (cert kiadás után)

Amikor a Sectigo cert kiadásra kerül (kb. 3-5 munkanap):
1. User: szólj nekem az email-érkezésről
2. AI: vezetem a DigiCert KeyLocker activation flow-t
3. User: a portal-ban kattint (én vezetlek)
4. AI: a 10 GitHub Secret-et feltöltöm a values alapján
5. AI: `gh workflow run` trigger
6. AI: signing verify
7. Done — v2.5.51 signed release publikálva

## Hivatkozott fájlok

- `vault/operations/code-signing-setup-path.md` — full runbook (PR #592)
- `vault/operations/windows-signed-release-runbook.md` — workflow runbook (PR #591)
- `C:\Users\Kósa Zoltán\Downloads\code-signing-cert-beszerzes-csomag.md` — eredeti terv (2026-05-05)
- `.github/workflows/windows-signed-release.yml` — workflow (PR #591)
- `penztar-client/scripts/sign-with-keylocker.js` — signing hook implementáció
