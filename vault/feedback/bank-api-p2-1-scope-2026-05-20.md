---
title: "P2.1 Bank API integráció — scope tisztázás + Raiffeisen defer"
status: active
priority: P2
hatály: 2026-05-20+
forrás: Sprint 50-step S17-S19 (API_bank.docx beolvasás)
related: vault/references/strategic-development-plan-v2-5-64-2026-05-19.md P2.1
---

# P2.1 Bank API — scope tisztázás

## API_bank.docx tartalom (beolvasva 2026-05-20)

A `Felmérés/Valuta/Kósa Tervezés és fejlesztés/Bank API/API_bank.docx` (14 KB)
**NEM** részletes API-spec — csak 2 referencia-URL:

1. **MNB árfolyam webservice**:
   `https://www.mnb.hu/.../tajekoztatas-az-arfolyam-webservice-mukodeserol`
2. **Raiffeisen API**:
   `https://api.rbinternational.com/api-categories?provider=raiffeisenbank-zrt`

## Státusz

### MNB — ✅ MÁR INTEGRÁLVA
Az `ExchangeRatePollingService` (41 MNB-hivatkozás) már használja az MNB SOAP
webservice-t (+ ECB XML fallback) a napi árfolyamokhoz, @Scheduled poll-lal,
XXE-védelemmel. **NINCS TEENDŐ.**

### Raiffeisen — ⏳ CREDENTIALS-GATED (autonomous-doable nélkül)
A Raiffeisen RBI API:
- OAuth2 client credentials kell (API onboarding a bank-nál)
- Sandbox + production API-key regisztráció (developer.rbinternational.com)
- A docx NEM tartalmaz endpoint-spec-et, csak a kategória-listázó URL-t

**Döntés**: a Raiffeisen API integráció **NEM autonomous-doable** — bank-oldali
onboarding + OAuth credentials szükséges, amit Kósa Zoltánnak kell beszereznie.
Amíg nincs credential, a P2.1 Raiffeisen-rész **defer**.

## Akció ha a user beszerzi a credentials-t

1. OAuth2 client_id + client_secret a `.env`-be (NEM commitolva)
2. Új `RaiffeisenApiService` + adapter (rate-fetch a competitor-rate-hez)
3. `BankApiCredential` entity (encrypted at-rest)
4. Scheduled poll integráció a CompetitorRate-be

## Hivatkozások

- `vault/references/strategic-development-plan-v2-5-64-2026-05-19.md` P2.1
- `backend/.../service/ExchangeRatePollingService.java` (MNB — működik)
- API_bank.docx (2 URL, NEM részletes spec)
