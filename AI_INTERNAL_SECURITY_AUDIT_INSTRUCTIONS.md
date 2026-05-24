# AI-EXECUTABLE INTERNAL SECURITY & CODE AUDIT HANDBOOK (V2.0)
## Gépi Úton Végrehajtható Biztonsági, Logikai és Üzleti Logikai Hardening Protokoll a Valutaváltó Monorepóhoz

> **Hatály:** Minden kódfejlesztő, refaktoráló, tesztelő és biztonsági auditőr AI ágens (Jules, Gemini, Claude, GPT).  
> **Cél:** A `valutavalto-program` monorepo logikai, biztonsági és kriptográfiai épségének 100%-os garantálása.
> **Gépi Feldolgozhatóság:** Ez a dokumentum strukturált, parserek és szabály-alapú AI motorok számára közvetlenül végrehajtható formátumban tartalmazza a kritikus ellenőrzési és hardening utasításokat.

---

## 1. EXPLICIT BIZTONSÁGI ELLENŐRZÉSI MÁTRIX (AI CHECKLIST)

Az alábbi JSON struktúra a végrehajtó AI ágensek számára definiálja az elvárt ellenőrzési pontokat. Az ágens köteles ezt a checklist-et programozottan végigfuttatni és a találatokat dokumentálni.

```json
{
  "audit_ruleset": "ValutaERP-Security-V2.0",
  "verification_points": [
    {
      "id": "RULE-BOLA-101",
      "component": "backend",
      "target_pattern": ".*(Service|Controller)\\.java$",
      "rule": "Every read/write/delete query on resource by ID must perform tenant (company) isolation match.",
      "severity": "CRITICAL",
      "remediation": "Inject SecurityUtils.getCurrentCompanyId() and match it with resource.getCompany().getId()."
    },
    {
      "id": "RULE-AUTH-102",
      "component": "backend",
      "target_pattern": ".*Controller\\.java$",
      "rule": "State-modifying endpoints (POST, PUT, DELETE) must not rely on simple isAuthenticated() and must enforce role-based access.",
      "severity": "HIGH",
      "remediation": "Apply @PreAuthorize(\"hasAnyRole('ADMIN', 'FOERTEKTAR', 'UGYVEZETO')\") on sensitive mappings."
    },
    {
      "id": "RULE-CONC-103",
      "component": "backend",
      "target_pattern": ".*Service\\.java$",
      "rule": "Read-then-Write sequences on balance and quota counts must use Pessimistic Write Lock to prevent Race Conditions.",
      "severity": "HIGH",
      "remediation": "Call findByIdForUpdate() with LockModeType.PESSIMISTIC_WRITE inside transaction."
    },
    {
      "id": "RULE-MFA-104",
      "component": "backend",
      "target_pattern": "TotpService\\.java$",
      "rule": "Backup recovery codes must be stored using BCrypt (strength 12) instead of raw or SHA-256 hashes.",
      "severity": "HIGH",
      "remediation": "Utilize passwordEncoder.encode(code) for serialization and passwordEncoder.matches(input, hashed) for verification."
    },
    {
      "id": "RULE-XXE-105",
      "component": "backend",
      "target_pattern": ".*Service\\.java$",
      "rule": "XML parsers for consolidated sanction lists must explicitly disable external entities (XXE prevention).",
      "severity": "HIGH",
      "remediation": "Configure DocumentBuilderFactory with disallow-doctype-decl=true and external-general-entities=false."
    },
    {
      "id": "RULE-PREC-201",
      "component": "client",
      "target_pattern": "(sqlite\\.ts|preload\\.ts)$",
      "rule": "Financial amounts, rates, and fees must never use REAL (SQLite) or number (JS) float types.",
      "severity": "HIGH",
      "remediation": "Define database schema as TEXT for decimals, process calculations using big.js library, and sync as String."
    },
    {
      "id": "RULE-IPC-202",
      "component": "client",
      "target_pattern": ".*(main|preload)\\.ts$",
      "rule": "Electron main process sandbox must be active, disabling direct node integration in renderer.",
      "severity": "CRITICAL",
      "remediation": "Set contextIsolation: true, nodeIntegration: false, and strictly whitelist preload contextBridge APIs."
    },
    {
      "id": "RULE-TRIG-301",
      "component": "database",
      "target_pattern": ".*\\.sql$",
      "rule": "BEFORE DELETE PL/pgSQL triggers must not reference NEW record fields to prevent 'record NEW is unassigned' crash.",
      "severity": "CRITICAL",
      "remediation": "Isolate DELETE operations using IF (TG_OP = 'DELETE') block and reference only OLD record fields."
    }
  ]
}
```

---

## 2. BACKEND (SPRING BOOT) - MÉLY TECHNIKAI ELŐÍRÁSOK

### 2.1. Broken Object Level Authorization (BOLA / IDOR)
A monorepo egy multi-tenant (több-bérlős) vállalatirányítási rendszer. Az A cég pénztárosa vagy vezetője nem láthatja, módosíthatja vagy törölheti a B cég tranzakcióit, irodáit vagy dolgozóit, még akkor sem, ha ismeri azok belső azonosítóját (UUID vagy Long ID).

* **Gépi Ellenőrzési Utasítás:**
  Az ágensnek a `backend/src/main/java/` könyvtár összes `@Service` osztályában meg kell keresnie azokat a metódusokat, amelyek adatbázisból kérnek le adatot `id` alapján (`findById`, `getReferenceById`, stb.).
  
* **Példa a helyes és biztonságos implementációra fiók (Branch) frissítése esetén:**
  ```java
  // Célfájl: BranchService.java
  public BranchDto update(UUID id, UpdateBranchDto dto) {
      log.info("Updating branch: {}", id);

      Branch branch = branchRepository.findById(id)
              .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + id));

      // IDOR védelem: kereszt-bérlő írás elleni védelem (B-101 szabály)
      UUID companyId = SecurityUtils.getCurrentCompanyId();
      if (branch.getCompany() == null || !branch.getCompany().getId().equals(companyId)) {
          log.warn("IDOR gyanús módosítás blokkolva! userCompany={}, branchCompany={}, branchId={}",
                  companyId, branch.getCompany() != null ? branch.getCompany().getId() : "null", id);
          throw new ResourceNotFoundException("Fiók nem található: " + id); // Defenzív módon 404-et dobunk, titkolva a létezést
      }

      // Frissítési logika...
  }
  ```

---

### 2.2. Műveleti és Szerepkör-szintű Végpont-hitelesítés
Az `@PreAuthorize("isAuthenticated()")` nem elegendő az olyan végpontokon, amelyek a rendszer állapotát, törzsadatait vagy pénzügyi beállításait módosítják.

* **Gépi Ellenőrzési Utasítás:**
  Az ágensnek a `backend/src/main/java/hu/puzzleir/valuta/controller/` mappában lévő összes `@RestController` osztályt át kell vizsgálnia. A POST, PUT és DELETE leképezéseknél explicit szerepkör-ellenőrzésnek kell szerepelnie.

* **Fiókkezelés (BranchController) Elvárt Jogosultságai:**
  ```java
  // Célfájl: BranchController.java
  
  @PostMapping
  @PreAuthorize("hasAnyRole('ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
  public ResponseEntity<BranchDto> createBranch(@Valid @RequestBody CreateBranchDto dto) { ... }

  @PutMapping("/{id}")
  @PreAuthorize("hasAnyRole('ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
  public ResponseEntity<BranchDto> updateBranch(@PathVariable UUID id, @Valid @RequestBody UpdateBranchDto dto) { ... }

  @DeleteMapping("/{id}")
  @PreAuthorize("hasRole('ADMIN')") // Fiókot törölni kizárólag a főadminisztrátor jogosult!
  public ResponseEntity<Void> deleteBranch(@PathVariable UUID id) { ... }
  ```

---

### 2.3. Tranzakciós Párhuzamosság és Versenyhelyzet Kezelés (Race Conditions)
A pénzügyi ERP rendszerekben a párhuzamos tranzakció-indítások (pl. egyidejű kasszamódosítások, napi kvóta-lefutások, párhuzamos sztornózások) súlyos adatintegritási és pénzügyi visszaélésekhez vezethetnek.

* **Gépi Ellenőrzési Utasítás:**
  Az ágensnek az egyenleget módosító vagy limiteket ellenőrző folyamatokat (pl. `TransactionService`, `TransactionReversalService`) kell vizsgálnia. Keresni kell a "lekérdezem az aktuális állapotot -> validálom -> elmentem az újat" szekvenciákat. Ezeknél explicit zárolást kell alkalmazni.

* **Példa a Dupla-Sztornózás Elleni Védelemre (Pessimistic Lock):**
  A sztornózás folyamán két párhuzamosan indított kérés esetén meg kell akadályozni, hogy mindkét szál sikeresen lefusson.
  
  1. Definíció a Repository-ban:
     ```java
     // Célfájl: TransactionRepository.java
     @jakarta.persistence.LockModeType(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
     @Query("SELECT t FROM Transaction t WHERE t.id = :id")
     java.util.Optional<Transaction> findByIdForUpdate(@Param("id") Long id);
     ```
  
  2. Alkalmazás a Service-ben:
     ```java
     // Célfájl: TransactionReversalService.java
     @Transactional(rollbackFor = Exception.class)
     public ReversalResponseDto executeReversal(ReversalRequestDto request) {
         // PESSIMISTIC LOCK: Kizárja a párhuzamos dupla-sztornózást az adatbázis szintjén
         Transaction original = transactionRepository.findByIdForUpdate(request.getOriginalTransactionId())
                 .orElseThrow(() -> new ResourceNotFoundException("Eredeti tranzakció nem található"));

         if (original.isReversed()) {
             throw new ValidationException("Ez a tranzakció már sztornózva lett!");
         }
         
         // Sztornózási műveletek végrehajtása...
     }
     ```

---

### 2.4. Kétlépcsős Azonosítás (MFA) Recovery Hardening
A rendszer által generált 8 jegyű backup kódok kombinációs tere szűk ($10^8$ kombináció). Ha ezeket az adatbázisban egyszerű egyirányú hasheléssel (pl. SHA-256) tároljuk, egy adatbázis-szivárgás esetén a támadó modern hardveren másodpercek alatt visszafejti az összes backup kódot offline brute-force támadással.

* **Audit Szabály:** A backup kódokat lassú, sózott, brute-force rezisztens algoritmussal kell tárolni és ellenőrizni, backward-compatibility biztosításával.

* **Elvárt Kódstruktúra:**
  ```java
  // Célfájl: TotpService.java
  
  // 1. Hashelés a generálás során BCrypt-tel
  private String hashBackupCodes(List<String> codes) {
      try {
          List<String> hashed = new ArrayList<>();
          for (String code : codes) {
              // Spring Security BCryptPasswordEncoder (strength 12) használata
              hashed.add(passwordEncoder.encode(code));
          }
          return objectMapper.writeValueAsString(hashed);
      } catch (Exception e) {
          throw new RuntimeException("Backup kód hashelése sikertelen", e);
      }
  }

  // 2. Ellenőrzés backward-compatible módon
  private boolean matchesBackupHash(String code, String storedHash) {
      if (storedHash == null) {
          return false;
      }
      // Ha BCrypt hash ($2a$ prefix)
      if (storedHash.startsWith("$2")) {
          return passwordEncoder.matches(code, storedHash);
      }
      // Legacy SHA-256 fallback a régi enrolled felhasználók támogatásához
      try {
          java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
          String sha256b64 = Base64.getEncoder().encodeToString(
                  md.digest(code.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
          return sha256b64.equals(storedHash);
      } catch (Exception e) {
          return false;
      }
  }
  ```

---

## 3. KLIENSOLDALI (ELECTRON) - MÉLY TECHNIKAI ELŐÍRÁSOK

### 3.1. Lebegőpontos Számítások Megakadályozása (SQLite és WASM)
Az offline Pénztár kliens SQLite adatbázisában (`local.db`) a pénzügyi tranzakciók értékeit és árfolyamait `REAL` típusúként tárolni tilos. A lebegőpontos ábrázolás a JavaScript és a SQLite rétegben pontatlanságot és filléres eltéréseket eredményez a szinkronizáció során.

* **Gépi Ellenőrzési Utasítás:**
  Az ágensnek át kell vizsgálnia a `penztar-client/electron/sqlite.ts` fájl séma-deklarációit. Minden lebegőpontos mezőt (`REAL`) át kell alakítani `TEXT` típusra, és a kliensoldali aritmetikához be kell vezetni egy decimális könyvtárat (pl. `big.js`).

* **Helyes Séma Mintázat:**
  ```typescript
  // Célfájl: sqlite.ts
  db.run(`
    CREATE TABLE IF NOT EXISTS pending_transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL CHECK(type IN ('SELL', 'BUY')),
      currency_code TEXT NOT NULL,
      foreign_amount TEXT NOT NULL,       -- TEXT típus a tizedesek precíz tárolásához
      huf_amount TEXT NOT NULL,           -- TEXT típus
      rounded_huf_amount TEXT NOT NULL,   -- TEXT típus
      rate TEXT NOT NULL,                 -- TEXT típus
      handling_fee TEXT,                  -- TEXT típus
      discount_percent TEXT,              -- TEXT típus
      ...
  `);
  ```

---

### 3.2. Windows Path Traversal Guard a Kliensoldalon
A kliens oldali fájlmentéseknél (tranzakciós bizonylatok PDF mentése, kameraképek mentése) meg kell akadályozni, hogy a felhasználói inputból (pl. bizonylatszám, dolgozói kód) képzett fájlnevek segítségével a támadó kitörjön a megengedett báziskönyvtárból.

* **Biztonságos Path Guard Implementáció:**
  ```typescript
  // Célfájl: path-guard.ts vagy helper osztályok
  import path from 'node:path';

  export function assertInsideBase(baseDir: string, targetPath: string): void {
    const resolvedBase = path.resolve(baseDir);
    const resolvedTarget = path.resolve(targetPath);
    
    // Windows specifikus backslash normalizálás és prefix ellenőrzés
    if (!resolvedTarget.startsWith(resolvedBase)) {
      log.error(`Path traversal kísérlet észlelve! base=${resolvedBase}, target=${resolvedTarget}`);
      throw new Error("Biztonsági hiba: Érvénytelen fájl útvonal!");
    }
  }
  ```

---

## 4. ADATBÁZIS (FLYWAY MIGRATIONS & POSTGRESQL TRIGGERS)

### 4.1. Defenziv PL/pgSQL Trigger Írás
A PostgreSQL triggerek a tranzakció-naplók (`audit_log`) megváltoztathatatlanságát (immutability) hivatottak biztosítani. `BEFORE DELETE` trigger esetén a PL/pgSQL végrehajtásakor a `NEW` rekord nincs inicializálva (`NEW == NULL`). Ha a trigger függvény hivatkozik a `NEW` rekord bármely mezőjére (pl. `NEW.id`), a PostgreSQL azonnal összeomlik és nem engedi lefutni a szabályos hibakezelést.

* **Audit Szabály:** A triggerben explicit módon szét kell választani a művelet típusokat (`TG_OP`), és törlés esetén kizárólag az `OLD` rekord mezőit szabad elérni.

* **Biztonságos Trigger Mintázat:**
  ```sql
  -- Célfájl: db/migration/V263__fix_audit_log_immutable_trigger_delete.sql vagy újabbak
  
  CREATE OR REPLACE FUNCTION audit_log_immutable() RETURNS TRIGGER AS $$
  DECLARE
      v_id     TEXT;
      v_action TEXT;
  BEGIN
      -- Szigorú szétválasztás a PL/pgSQL null-pointer exception elkerülésére
      IF (TG_OP = 'DELETE') THEN
          v_id     := COALESCE(OLD.id::TEXT, 'unknown');
          v_action := COALESCE(OLD.action, 'unknown');
      ELSE
          -- UPDATE / INSERT műveleteknél mindkét rekord elérhető
          v_id     := COALESCE(OLD.id::TEXT, NEW.id::TEXT, 'unknown');
          v_action := COALESCE(OLD.action, NEW.action, 'unknown');
      END IF;

      -- Szabályos, ellenőrzött biztonsági kivétel dobása a tranzakció abortálásához
      RAISE EXCEPTION 'audit_log immutable: % operation not allowed (id=%, action=%)',
          TG_OP, v_id, v_action;
      RETURN NULL;
  END;
  $$ LANGUAGE plpgsql;
  ```

---

## 5. MINŐSÉGI KAPUK ÉS STATIKUS KÓDELLENŐRZÉSI UTASÍTÁSOK

Minden kódjavító AI ágens köteles a módosítások után a lokális ellenőrző kaput lefuttatni a zero-trust elvnek megfelelően.

```powershell
# 1. Monorepo gyökérkönyvtárában a guard és titok-ellenőrző parancs futtatása
npm run agent:guard

# 2. Döntési és változtatási napló archiválása (hash-láncolt archiválás)
npm run agent:archive -- --summary "A végrehajtott biztonsági audit és hardening pontok részletes leírása."
```

Ha a fenti parancsok bármelyike hibát ad, az ágensnek a refaktort addig kell folytatnia, amíg a statikus ellenőrzések zöld jelzést nem adnak.

---
**Audit Kézikönyv Szerzője:** Antigravity AI Senior Security Architect Agent  
**Dátum:** 2026-05-24  
**Licenc:** Confident / Zero-Trust Financial ERP Standard Compliance  
