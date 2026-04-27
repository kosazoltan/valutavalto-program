# Bejelentkezesi Flow E2E Acceptance Teszt — v2.3.0

Ez a dokumentum a teljes bejelentkezesi flow end-to-end teszteleset irja le
a telepitotol a valodi bejelentkezesig.

## Elokovetelmenyek

1. Tiszta Windows 11 VM (nincs korabbi penztar-client telepites)
2. Internet kapcsolat (az `excvaluta.com` elerheto)
3. Penztar-Setup-X.Y.Z.exe telepito legfrisebb valtozata
4. A szerver oldali V161 migracio mar alkalmazva a Neon/Hetzner DB-n

## Test scenariok

### S1 — Friss telepites BORSI dolgozoval

**Lepesek:**

1. Indites: `Penztar-Setup-2.3.0.exe` admin joggal
2. NSIS wizard (nyelvvalasztas, EULA, path) — alapertelmezett valaszok
3. Telepites lezar, a SetupWizard React app elindul

**SetupWizard lepesek:**

4. **Welcome** step: klick "Tovabb"
5. **Fiok kivalasztasa** step:
   - Varhato: a list lefrisul a backend-rol
   - Valasztas: "TISZA Sarok" (Szeged, Tisza Sarok)
   - Klick "Tovabb"
6. **Program tipus** step:
   - Valasztas: "penztar"
   - Klick "Tovabb"
7. **Szerver kapcsolat** step:
   - **AUTO connection test**: ~1-2 mp-en belul zold banner:
     "Kapcsolodva (HTTP 200, ~150 ms)"
   - **Teszt penztaros** dropdown: automatikusan lefrissul, tartalmazza:
     - Borsi Tamas (BORSI) MANAGER
     - Bali Henrietta (BALI) SUPERVISOR
     - Kasza Helga (KASZA) MANAGER
   - Valasztas: **"Borsi Tamas (BORSI)"**
   - Teszt-jelszo mezo: add meg "1234" (V111 seed, V161 utan meg elfogadott
     currentPassword-kent a first-time-setup flow-ban)
   - Klick "Tovabb"
8. **Admin jelszo** step:
   - A adminUsername mezoben mutatja: "admin" (vagy a user modositsa)
   - **FONTOS:** itt add meg az UJ jelszot a BORSI-nak, NEM az admin-nak
   - Jelszo: `ValaszBorsi123!` (min 8 kar, complex)
   - Confirm: ugyanaz
   - Klick "Tovabb"
9. **Telepites osszefoglalo** step:
   - Ellenorizd az adatokat
   - Klick "Telepites befejezese"

**Elvart backend hatas:**

- `/api/v1/auth/first-time-worker-setup` HTTP 200
- `worker.password_hash` frissul (BCrypt(ValaszBorsi123!))
- `worker.password_changed_at` most mar NEM NULL
- Rendszer-flag `auth.bootstrap-completed` NEM allitodik be (csak a legacy
  admin bootstrap flow allitja)

**Elvart electron hatas:**

- `.env` fajl: `VITE_BRANCH_CODE=TISZA`, `PENZTAR_BOOTSTRAP_WORKER_CODE=BORSI`
- SQLite config:
  - `worker_code = "BORSI"`
  - `worker_name = "Borsi Tamas"`
  - `worker_role = "MANAGER"`

### S2 — Elso bejelentkezes

**Lepesek:**

1. Penztar-client app automatikusan ujraindul a wizard utan
2. Login oldal jelenik meg

**Elvart UI:**

- `companyCode` mezo **"EBC"** pre-filled
- `workerCode` dropdown: **"BORSI"** kivalasztva ("Borsi Tamas" megjelenitve)
- Zold banner: "✓ A telepitoben kivalasztott dolgozo: **Borsi Tamas**"
- Jelszo mezo: ures

**Login akció:**

3. Add meg: `ValaszBorsi123!` (amit a wizard-ban beallitottam)
4. Klick "Belepes"

**Elvart backend hatas:**

- `/api/v1/auth/login` HTTP 200
- JWT token-t ad vissza, worker role = MANAGER
- `worker.last_login_at` frissul

**Elvart UI:**

- Navigacio: `/cashier` (penztaros dashboard) vagy a MANAGER default screen-je
- Worker nev jelzve a header-ben: "Borsi Tamas"

### S3 — Masodik telepites (KASZA dolgozoval)

Ugyanaz mint S1, de:

- 7. lepes: valasztasa "Kasza Helga (KASZA)"
- 8. lepes: uj jelszo `KaszaPass2025!`

**Elvart:**

- A BORSI fiok NEM serult
- KASZA sajat jelszavat kapja
- S2 elvegeztetve KASZA-val, ő is sikeresen belep

### S4 — Helytelen jelszo

1. Wizard befejezese (BORSI + ValaszBorsi123!)
2. Login oldal: jelszo "WrongPassword"
3. Klick "Belepes"

**Elvart:**

- HTTP 401
- Piros hibauzenet: "Hibas jelszo" vagy hasonlo
- Nincs JWT, nincs navigacio

### S5 — Telepito offline mode

1. Wizard "Offline mode" toggle ON
2. Connection test skippeive, nincs worker dropdown
3. adminUsername / adminPassword megadasa kotelezo
4. Legacy bootstrap-admin flow lefut a lokalis backend-en

**Elvart:**

- Bootstrap admin letrejon
- Login oldal a `admin` usernev-vel mukodik
- Worker identity config NEM iromodik be (nincs kivalasztott dolgozo)

## Regression check: korabbi fuctionality

- **R1:** A nappnyitas tovabbra is mukodik (dailySession creation)
- **R2:** A bizonylatszam generalas tovabbra is helyes (V035000XXX prefix)
- **R3:** A Sync engine elerhetosegi check futo, pending transactions kuldeshoz
- **R4:** Multi-tenant boundary: BORSI a TISZA branch-en belul lat csak tranzakciokat

## Automatizalt script (opcional)

```powershell
# scripts/e2e-login-flow.ps1
# Futtatasa: powershell -ExecutionPolicy Bypass -File scripts/e2e-login-flow.ps1

# 1. Backend indit
& ./scripts/start-valuta-ecosystem.ps1 -BackendOnly

# 2. Flyway migrate (V161 biztos alkalmazva)
cd backend
./mvnw flyway:migrate "-Dflyway.url=jdbc:postgresql://localhost:5433/valuta" `
  "-Dflyway.user=valuta_user" "-Dflyway.password=valuta_pass"

# 3. DB assertion: worker.password_changed_at IS NULL a BORSI-nal
psql "postgresql://valuta_user:valuta_pass@localhost:5433/valuta" `
  -c "SELECT code, password_changed_at FROM worker WHERE code IN ('BORSI','BALI','KASZA','KOSA');"

# 4. Test curl: first-time-worker-setup BORSI-val
$body = @{
    companyCode = 'EBC'
    workerCode = 'BORSI'
    newPassword = 'TestBorsi123!'
    currentPassword = '1234'
} | ConvertTo-Json
curl -s -X POST http://localhost:8080/api/v1/auth/first-time-worker-setup `
  -H 'Content-Type: application/json' -d $body | ConvertFrom-Json

# 5. Verify: password_changed_at NOT NULL most
psql ... -c "SELECT code, password_changed_at FROM worker WHERE code = 'BORSI';"

# 6. Test login BORSI-val
$login = @{ companyCode='EBC'; workerCode='BORSI'; password='TestBorsi123!' } | ConvertTo-Json
curl -s -X POST http://localhost:8080/api/v1/auth/login `
  -H 'Content-Type: application/json' -d $login
# Elvarhato: HTTP 200, JWT visszaad
```

## Kovetkezo teendok (kivul ezen a scope-on)

- [ ] Production V161 alkalmazas (Hetzner Neon DB-n)
- [ ] Kollegak ujratelepitese az uj 2.3.0 installerrel
- [ ] A zero-knowledge password reset (e-mailes flow) kihatasa —
      kulon PR, ha a V161 migration utan KOSA-t (ugyvezeto) akarnal
      mas e-mailes flow-val induktalni

## Dokumentum verzio

- **v1.0 (2026-04-24):** elso E2E acceptance dokumentum
- Felelos: a kovetkezo testfutasok
- Vonatkozo kod: PR #216 (feat/worker-first-time-setup) + PR #XXX
  (feat/worker-first-time-setup-electron-ipc)