# Teljes Biztonsági Audit es Vedelmi Rendszer

Verzio: 2.0  
Datum: 2026-03-18  
Klasszifikacio: Bizalmas - belso fejlesztoi hasznalatra

> Deprecated baseline. Use `SECURITY_BASELINE_V3.md` as the mandatory source of truth.

Ez a dokumentum a repository kotelezo AI-agent security baseline-je. A cel a Java backend + Electron/React alkalmazas teljes koru auditja, javitasa es aktiv vedelmi mechanizmusainak fenntartasa.

## 0. Kotelezo mukodesi elvek

- Minden coding agent ezt a baseline-t alkalmazza alapertelmezetten.
- Deploy elott kotelezo a teljes security gate futtatasa.
- Nincs hallucinacio: csak bizonyitott, ellenorizheto eredmeny.
- Nincs lustasag: a kotelezo checkeket nem lehet atugrani.
- Nincs hazugsag: BLOCKED allapotot jelolni kell, ha valami nem futtathato.
- Kritikus/High sebezhetosegnel deploy blokkolas.

## 1. Fazis - Statikus kodanalizis es sebezhetoseg-feltaras

### 1.1 Dependency audit

Kotelezo ellenorzesek:

- Backend: `mvn dependency-check:check`
- Electron: `npm audit --production`
- Frontend: `npm audit --omit=dev`
- `pom.xml` es `package-lock.json` atvizsgalas
- Transitiv fuggosegek ellenorzese
- Elavult (2+ ev) es abandonware (6+ honap inaktiv) csomagok listazasa

Elvart output tabla:

| Csomag | Jelenlegi verzio | Legujabb verzio | CVE | CVSS | Javitasi terv |
|---|---|---|---|---|---|

Kotelezo szabaly:

- CRITICAL/HIGH CVE: azonnali javitas vagy kompenzacios kontroll + dokumentacio.

### 1.2 SAST

Backend minimum:

- SpotBugs + FindSecBugs
- PMD security rules
- Hardcoded credential, SQLi, XXE, SSRF, deserialization, path traversal, command injection keresese
- Gyenge crypto mintak (MD5, SHA-1, DES, ECB)
- Error leakage (stack trace, debug info)

Electron minimum:

- `nodeIntegration=false`
- `contextIsolation=true`
- `sandbox=true`
- `webSecurity=true`
- `allowRunningInsecureContent=false`
- `remote` tiltasa
- IPC validation, preload whitelist, CSP, `eval`/`new Function` tiltasa

### 1.3 Hardcoded sensitive data

Keresendo mintak:

- password, secret, api_key, token, private key
- `.env`, `.pem`, `.key` leak
- JWT secret, DB jelszo, OAuth secret, SMTP secret

Szabaly:

- Titkok externalizalasa (env/vault)
- Git history incident dokumentalasa + key rotation terv

## 2. Fazis - Halozati es API biztonsag

### 2.1 HTTPS/TLS

- HTTPS enforcement
- Minimum TLS 1.2 (ajanlott 1.3)
- Gyenge ciphers tiltasa
- HSTS aktiv
- Electron certificate hiba szigoru kezeles

### 2.2 HTTP security headers

Kotelezo header baseline:

- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Content-Security-Policy` (szigoru)
- `Referrer-Policy`
- `Permissions-Policy`
- `Cross-Origin-*` vedelem
- Szenzitiv endpoint cache tiltasa

### 2.3 API endpoint vedelem

- Rate limiting (altalanos + szenzitiv endpoint profilok)
- Input validacio minden bemeneten
- Request body meret limit
- Kulso hivas timeout
- CORS explicit whitelist (soha nem `*`)
- Szigoru HTTP method policy
- Request/response logging szenzitiv adatok nelkul

### 2.4 CORS

- Csak explicit allowed origins
- Credential policy kontroll
- Minimalis szukseges methods/headers

## 3. Fazis - AuthN/AuthZ

### 3.1 Jelszo policy

- BCrypt vagy Argon2id (ajanlott Argon2id)
- Min 12, max 128 karakter
- Komplexitas
- Common password tiltasa
- Password history
- Konstans ideju osszehasonlitas

### 3.2 JWT security

- RS256/ES256
- Access token <= 15 perc
- Refresh <= 7 nap
- Refresh token rotacio
- Blacklist/revocation
- `jti`, `iss`, `aud`, fingerprint validacio

### 3.3 MFA

- TOTP tamogatas
- Adminnal kotelezo
- Backup kodok
- Brute-force vedelem MFA kodra

### 3.4 Session security

- Session fixation vedelem
- Absolute + idle timeout
- Secure/HttpOnly/SameSite cookie
- Parallel session limit

### 3.5 Authorization es IDOR

- Least privilege
- Method-level security (`@PreAuthorize`)
- Ownership check minden erzekeny eroforrasnal
- Vertical/horizontal privilege escalation vedelem

## 4. Fazis - Adatbiztonsag

### 4.1 Input validacio/sanitizacio

- Whitelist validacio
- Server-side validacio kotelezo
- SQLi/XSS/path traversal/CRLF vedelmek
- Unicode normalizacio
- File upload: mime, meret, fajlnev, tiltott kiterjesztes

### 4.2 DB hardening

- Prepared statement mindenhol
- Minimal DB jogosultsag
- Szenzitiv adatok titkositasa
- Query timeout es connection pool limit

### 4.3 Crypto

- At-rest: AES-256-GCM
- In-transit: TLS 1.2/1.3
- Secure random
- Key rotation policy
- Kulcsok kodon kivul (vault/HSM)

## 5. Fazis - Electron specifikus hardening

- Hardened BrowserWindow config
- Navigation es window-open policy
- Permission handler deny-by-default
- Session-level CSP
- Insecure cert elfogadas tiltasa
- Preload `contextBridge` + channel whitelist
- IPC sender, endpoint, method, meret validacio
- Biztonsagos auto-update policy

## 6. Fazis - Aktiv vedelmi rendszer

- Kozponti security audit log
- IDS jellegu detekcio: brute force, SQLi, XSS, traversal
- Auto-ban rendszer
- CSRF vedelem
- Request fingerprinting + anomaly detekcio
- Honeypot endpointok
- Request ID tracing

## 7. Fazis - Teszteles es validacio

Kotelezo:

- Unit + integration security tesztek
- JWT manipulation, IDOR, rate limit, CSRF, SQLi, XSS, traversal tesztek
- Error handling leakage teszt
- Header presence teszt

## 8. Fazis - Monitoring es riasztas

- Sikertelen login, rate-limit, honeypot, banolt IP metrikak
- IDS alert severity szerinti osztalyozas
- CVE monitoring napi frissitessel

## 9. Fazis - Dokumentacio

Kotelezo dokumentumok:

- Security architecture
- Threat model (STRIDE)
- Incident response
- Security runbook
- API security guide
- Dependency update policy
- Key rotation procedure
- Backup/recovery terv

## Vegso teljesitesi checklist (deploy gate)

Deploy csak akkor engedelyezett, ha:

- [ ] Nincs unresolved CRITICAL/HIGH finding
- [ ] Dependency audit lefutott es dokumentalt
- [ ] Hardcoded secret scan lefutott
- [ ] Security header policy ellenorzott
- [ ] Auth/JWT/session policy validalt
- [ ] Electron hardening validalt
- [ ] Security tesztek lefutottak
- [ ] Monitoring/alerting baseline rendben
- [ ] Changelog vagy security report frissitve

## Megjegyzes

Ez elo baseline. Minden security valtozas utan ujrafuttatas, ujravalidacio, es egyertelmu evidence reporting kotelezo.
