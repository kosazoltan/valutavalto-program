# Semgrep teljes-kódbázis audit — 2026-05-26 (v2.27.9)

**Eszköz:** semgrep 1.133.0 `--config auto` (registry security/OWASP/nyelv-specifikus).
**Scannelt:** 2015 forrásfájl (backend Java, frontend-react, 3 Electron kliens, packages).
**Nyers JSON (gitignore-olt):** `security-reports/semgrep/semgrep-2.27.8.json` + `SEMGREP-AUDIT-2.27.8.md`.

## Eredmény: 224 finding (220 ERROR / 3 WARNING / 1 INFO)

Ebből **213 `detected-bcrypt-hash`** = Flyway seed-migrációkban lévő bcrypt-HASH-ek (NEM
plaintext titok; a V161/V184/V186/V193 amúgy is first-time-setup-resetre kényszerít). Nem
sebezhetőség. A maradék 11-ből **3 valódi hardening (javítva)**, 8 FP/by-design.

## ✅ Javítva (v2.27.9)

1. **httpclient-http-request** — `MnbExchangeRateService.java:49`: `http://` → `https://www.mnb.hu/arfolyamok.asmx`
   (HTTPS verifikálva 200 a `?wsdl`-en; MITM-védelem, ráta-integritás). **Backend, szerver-served.**
2. **gcm-no-tag-length** — `penztar-client/electron/scanner.ts:54,62` (+ teszt): AES-256-GCM
   `createCipheriv`/`createDecipheriv` explicit `{ authTagLength: 16 }` → csonkolt tag elutasítva.
   **⚠️ Electron-natív (penztar-only) → Penztar telepítő-rebuild szükséges, hogy a pénztárgépekre eljusson.**
3. **use-snakeyaml-constructor** — `ErrorCodeCatalogService.java:39`: `new Yaml()` →
   `new Yaml(new SafeConstructor(new LoaderOptions()))`. **Backend, szerver-served.**

## ⚪ False positive / by-design (nem javítva)

- **command-injection-process-builder ×2** (`BackupService.java:93,171`) — ProcessBuilder **tömb-argumentumok**
  (nincs shell), config-forrású host/port/db, abszolút binár-útvonal. FP.
- **formatted-sql-string ×3** (`NeonReplicationService.java:181`) — tábla-név **hardcode whitelist**
  (`SYNC_TABLES`), oszlopok DB-metaadatból, értékek `?`-paraméterezve. FP.
- **unencrypted-socket** (`OtpTerminalProtocolService.java:469`) — OTP POS terminál legacy plaintext
  TCP LAN-on; hardver nem támogat TLS-t. By-design.
- **unsafe-formatstring INFO** (`logger.ts:67`) — `tag` kód-konstans, nem user-input. FP.

## Tanulság (memóriába)

- Semgrep Windows-on: `--text` konzol-render **crashel cp1250-en** (UnicodeEncodeError) → kizárólag
  `--json --output` + `PYTHONUTF8=1`/`PYTHONIOENCODING=utf-8`.
- `penztar-client`-nek nincs `src/` (renderer = server-served frontend-react); csak `electron/` van.
- A scanner.ts GCM-tag már korábban is verifikálva volt (`setAuthTag`+`final()`); az `authTagLength:16`
  a csonkolt-tag forgery-vektort zárja (defense-in-depth, alacsony gyakorlati kockázat).
