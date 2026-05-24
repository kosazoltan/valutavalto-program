# Session: PP-16 MFA Backup Kód BCrypt Hardening — v2.26.35

**Dátum:** 2026-05-24  
**Verzió:** v2.26.35  
**PR:** #818 (admin-merged, squash, `2cb6859d8`)  
**Trigger:** antivaluta_audit_2026_05_24.md PP-16 finding  

---

## Feladat

Az audit azonosította, hogy a `TotpService.hashBackupCodes()` metódus SHA-256-tal hash-eli az MFA backup kódokat. A backup kódok 8 decimális számjegyből állnak (10^8 kombináció), SHA-256 gyors és sózatlan → offline brute-force (Hashcat) másodpercek alatt visszafejtheti DB-szivárgás esetén.

---

## Implementáció (4 fájl)

### 1. `TotpService.java`
- `hashBackupCodes()` → SHA-256 JSON builder eltávolítva, `passwordEncoder.encode(code)` (BCrypt 12) + `objectMapper.writeValueAsString()` hívás
- Új `verifyBackupCode(Long workerId, String code)` public metódus: JSON parse → iterál → `matchesBackupHash()` → egyezésnél hash eltávolítva, save, return true
- Új `matchesBackupHash(String code, String storedHash)` private helper:
  - `storedHash.startsWith("$2")` → `passwordEncoder.matches()` (BCrypt)
  - Egyéb → SHA-256/Base64 fallback (Codex P1 backward compat — pre-PP-16 enrolled userek)
- `lastVerifiedAt` frissítve sikeres backup code ellenőrzésnél (Copilot P2)

### 2. `MfaController.java`
- Új `POST /api/v1/mfa/verify-backup` endpoint
- Új `BackupCodeRequest` DTO (`@Pattern(regexp = "^[0-9]{8}$")`)

### 3. `RateLimitFilter.java`
- `/api/v1/auth/login` || `/api/v1/mfa/verify*` → loginLimits (10 req/perc/IP) — Codex P2

### 4. `TotpServiceTest.java`
- 6 új PP-16 teszt:
  - `PP16_backupCodes_storedAsBcryptFormat` — JSON parse + `allMatch(h -> h.startsWith("$2a$"))`
  - `PP16_verifyBackupCode_validCode_removesCodeAndReturnsTrue` — egyszeri felhasználás + eltávolítás
  - `PP16_verifyBackupCode_invalidCode_returnsFalse` — nincs save
  - `PP16_verifyBackupCode_noMfa_returnsFalse` — passwordEncoder soha nem hívódik
  - `PP16_verifyBackupCode_disabledMfa_returnsFalse` — disabled guard
  - `PP16_verifyBackupCode_legacySha256Hash_stillAccepted` — backward compat: SHA-256 hash elfogadva, passwordEncoder.matches() NEM hívódik

---

## Teszt eredmény

**1638/1638 PASS** (volt: 1632, +6 PP-16 teszt)

---

## Build stratégia

Backend-only change → **NINCS telepítő-build**. Hetzner auto-deploy a merge után.

## Production

- Hetzner deploy: SUCCESS
- `curl https://excvaluta.com/api/v1/auth/bootstrap-status` → **200 OK**
- `curl https://excvaluta.com/api/v1/public/branches?companyCode=EBC` → **73 iroda**

---

## AI Review (PR #818)

- Copilot P2: `lastVerifiedAt` hiányzott a `verifyBackupCode` success path-ból → javítva
- Codex P1: backward compat SHA-256 fallback → implementálva `matchesBackupHash()`-ban
- Codex P2: rate limit kiterjesztés MFA verify endpointokra → `RateLimitFilter` javítva
- Copilot P2: `doesNotContain("SHA")` gyenge assertion → JSON parse + `startsWith("$2a$")`

---

## Tanulság

A BCrypt backward-compat minta (prefix-alapú detekció: `$2` = BCrypt, egyéb = SHA-256) alkalmazható minden helyzetben ahol DB-migrálás nélkül kell hash-algoritmust váltani. A legacy userek teljesen transzparensen váltanak az új formátumra a következő backup code felhasználáskor (az új kódok már BCrypt-tel generálódnak az enrollment során).
