# B.2 — Pénzügyi adatintegritás invariáns mandate

**Hatály:** always, P0
**Forrás:** `claude-code-korrekcios-mandate-2026-05-17.md` 1.2 szakasz

## 7 alapinvariáns

1. **`készlet = SUM(tranzakciók)` — semmi külön counter.** Bármely PR, amely független `cashCounter` / `cash_counter` / `inventoryCount` mezőt vezet be **P0 reject**. A `business-invariant-guard.yml` workflow ezt regex-szel csekkolja.
2. **Idempotency-Key kötelező minden write-on** (POST/PUT/PATCH/DELETE), kivéve a kifejezetten whitelist-elt prefixek (`/auth/`, `/public/`, `/health`, `/actuator/`, OAuth callback, `/api/v1/diagnostics/`, `/ws/`, swagger). Új write endpoint hozzáadásakor a whitelist NEM bővíthető jóváhagyás nélkül.
3. **Bizonylat-sorszám atomic + monoton + iroda-szintű no-skip.** A `V<3-jegyű iroda-kód><6-jegyű sorszám>` formátum sosem ugorható, sosem duplikálható. DB-szekvencia vagy `SELECT ... FOR UPDATE` kötelező, NEM alkalmazás-szintű counter.
4. **HUF kerekítés (`roundHuf`)** kötelező minden HUF display + print + bizonylat előtt. Magyar 5 Ft-os egységre. Tranzakciós szolgáltatáson + frontend formatter-en is.
5. **Árfolyam validity (`Rate.validTo > now()`)** ellenőrzés a tranzakció **belépésekor** kötelező, NEM a végén. Lejárt árfolyammal tranzakció TILTOTT (HTTP 400).
6. **Spring `@Transactional` minden write servicen.** PR-review-ban explicit ellenőrizendő. Hiányzó `@Transactional` = P1 finding.
7. **Készlet-korrekció (manuális override)** kizárólag MAIN_TREASURY szerepkörrel + audit-log + indoklás kötelező. Régi sorok módosítása soha (immutable transaction log).

## PR-template checklist

- [ ] Nem vezetek be új `cashCounter` / `inventoryCount` mezőt
- [ ] Új write endpoint-hoz Idempotency-Key kötelező (vagy whitelist-jóváhagyott)
- [ ] Bizonylat-sorszámozás DB-szekvenciás
- [ ] Minden HUF display `roundHuf`-on átmegy
- [ ] `Rate.validTo` check a tranzakció elején
- [ ] Minden új write service `@Transactional`-os

## Regressziós tesztek

```
backend/.../CashInventorySumInvariantTest.java
backend/.../IdempotencyCoverageTest.java
backend/.../ReceiptSequenceTest.java
backend/.../RoundHufTest.java
backend/.../RateValidityTest.java
```
