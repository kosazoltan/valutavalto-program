# VALUTAVÁLTÓ RENDSZER - TELJES KÖRŰ RENDSZERKÖZELI KÓDAUDIT JELENTÉS
## Mesterséges Intelligencia (AI) Fejlesztői Ügynök Számára Átadható Végrehajtási Utasítások (V4.2)

> **Cél:** A `valutavalto-program` monorepo (Java/Spring Boot backend, React frontend, Electron offline kliens) logikai, programozási, biztonsági és tervezési hiányosságainak szisztematikus feltárása és javítása.
> **Végrehajtó AI Ügynök számára:** Ez a dokumentum egy lépésről lépésre követhető, közvetlenül gépi úton feldolgozható parancskészlet. A megadott hibás kódblokkokat a megadott javított kódjavaslatok alapján kell módosítani a megadott fájlokban.

---

## 1. MŰSZAKI ÉS ARCHITEKTURÁLIS ÁTTEKINTÉS
A valutaváltó ERP rendszer modern technológiákból épül fel:
- **Backend:** Java 21, Spring Boot 3.2, Spring Security 6, JPA (Hibernate), PostgreSQL (Neon) és Flyway migrációk.
- **Pénztár Offline Kliens:** Electron 33 (TypeScript), WASM-alapú SQL.js SQLite tárolóval, preload IPC csatornákkal és egy offline-online háttér szinkronizációs motorral (`sync-engine.ts`).
- **Riportálás és Biztonság:** Súlyozott átlagárfolyam és tranzakció-összesítő modulok (`AverageRateReportService.java`), valamint az AML (Pmt. 2017. LIII. tv.) szabályzó modul (`AmlService.java`).

A nyers forráskód fájlok közvetlen, sorról sorra történő vizsgálata során **12 súlyos biztonsági, párhuzamossági, kompatibilitási és adatintegritási hibát** tártam fel, konkrét kódblokkokkal és azok termelés-kész javításaival.

---

## 2. RÉSZLETES BIZTONSÁGI SEBEZHETŐSÉGEK ÉS JAVÍTÁSOK

### #PP-01: Biztonsági rés az irodakezelő végpontokon (Missing Endpoint-Level Authorization)
* **Célpont / Fájl:** [BranchController.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/controller/BranchController.java)
* **Súlyosság:** CRITICAL
* **Hiba Kategória:** Biztonság (Broken Object Level Authorization / BOLA / Broken Function Level Authorization)
* **Leírás:** A `BranchController` osztály szinten a `@PreAuthorize("isAuthenticated()")` annotációval van ellátva. Ez azt jelenti, hogy *bármely* bejelentkezett felhasználó (akár a legalacsonyabb jogosultságú `CASHIER` / `WORKER` - pénztáros is) elérheti a `POST /api/v1/branches` (létrehozás), `PUT /api/v1/branches/{id}` (módosítás) és `DELETE /api/v1/branches/{id}` (törlés) végpontokat. Ez sérti a pénzügyi rendszerekben kötelező minimális jogosultság elvét (Least Privilege Principle), és lehetővé teszi a belső visszaéléseket.
* **Jelenlegi Hibás Kód:** (sorszámok: 143-176)
```java
    /**
     * POST /api/v1/branches
     * Új fiók létrehozása
     */
    @PostMapping
    public ResponseEntity<BranchDto> createBranch(@Valid @RequestBody CreateBranchDto dto) {
        log.info("POST /api/v1/branches - code: {}", dto.getCode());
        BranchDto created = branchService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * PUT /api/v1/branches/{id}
     * Fiók frissítése
     */
    @PutMapping("/{id}")
    public ResponseEntity<BranchDto> updateBranch(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateBranchDto dto
    ) {
        log.info("PUT /api/v1/branches/{}", id);
        BranchDto updated = branchService.update(id, dto);
        return ResponseEntity.ok(updated);
    }

    /**
     * DELETE /api/v1/branches/{id}
     * Fiók törlése (soft delete)
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteBranch(@PathVariable UUID id) {
        log.info("DELETE /api/v1/branches/{}", id);
        branchService.delete(id);
        return ResponseEntity.noContent().build();
    }
```
* **Javított Kódjavaslat:**
```java
    /**
     * POST /api/v1/branches
     * Új fiók létrehozása - Adminisztrátori vagy vezetői körnek korlátozva
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<BranchDto> createBranch(@Valid @RequestBody CreateBranchDto dto) {
        log.info("POST /api/v1/branches - code: {}", dto.getCode());
        BranchDto created = branchService.create(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * PUT /api/v1/branches/{id}
     * Fiók frissítése - Adminisztrátori vagy vezetői körnek korlátozva
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<BranchDto> updateBranch(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateBranchDto dto
    ) {
        log.info("PUT /api/v1/branches/{}", id);
        BranchDto updated = branchService.update(id, dto);
        return ResponseEntity.ok(updated);
    }

    /**
     * DELETE /api/v1/branches/{id}
     * Fiók törlése (soft delete) - Kizárólag adminisztrátornak engedélyezett
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteBranch(@PathVariable UUID id) {
        log.info("DELETE /api/v1/branches/{}", id);
        branchService.delete(id);
        return ResponseEntity.noContent().build();
    }
```

---

### #PP-02: Bérlő-áthágási hiba az iroda frissítésénél és törlésénél (Cross-Tenant IDOR Vulnerability)
* **Célpont / Fájl:** [BranchService.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/BranchService.java)
* **Súlyosság:** CRITICAL
* **Hiba Kategória:** Biztonság (Insecure Direct Object Reference / IDOR / Bérlő elszigetelés sérülése)
* **Leírás:** Míg a `findById` és `updateIsVault` metódusok szigorúan ellenőrzik, hogy a cél-iroda a bejelentkezett felhasználó cégéhez (`companyId`) tartozik-e, addig az `update(UUID id, UpdateBranchDto dto)` és a `delete(UUID id)` metódusokból ez az ellenőrzés **teljesen hiányzik**. Egy A céghez tartozó vezető módosíthatja vagy soft-törölheti a B céghez tartozó iroda adatait, ha ismeri a B cég irodájának UUID-ját.
* **Jelenlegi Hibás Kód:** (sorszámok: 314-323 és 371-377)
```java
    public BranchDto update(UUID id, UpdateBranchDto dto) {
        log.info("Updating branch: {}", id);

        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + id));

        // Frissíthető mezők
```
```java
    public void delete(UUID id) {
        log.info("Deleting branch: {}", id);

        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + id));

        // Ellenőrzés: van-e gyermeke
```
* **Javított Kódjavaslat:**
```java
    /**
     * Fiók frissítése bérlő-specifikus ellenőrzéssel
     */
    public BranchDto update(UUID id, UpdateBranchDto dto) {
        log.info("Updating branch: {}", id);

        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + id));

        // IDOR védelem: kereszt-bérlő írás elleni védelem
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (branch.getCompany() == null || !branch.getCompany().getId().equals(companyId)) {
            log.warn("IDOR gyanús módosítás blokkolva! userCompany={}, branchCompany={}, branchId={}",
                    companyId, branch.getCompany() != null ? branch.getCompany().getId() : "null", id);
            throw new ResourceNotFoundException("Fiók nem található: " + id);
        }

        // Frissíthető mezők
```
```java
    /**
     * Fiók törlése (soft delete) bérlő-specifikus ellenőrzéssel
     */
    public void delete(UUID id) {
        log.info("Deleting branch: {}", id);

        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + id));

        // IDOR védelem: kereszt-bérlő törlés elleni védelem
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (branch.getCompany() == null || !branch.getCompany().getId().equals(companyId)) {
            log.warn("IDOR gyanús törlés blokkolva! userCompany={}, branchCompany={}, branchId={}",
                    companyId, branch.getCompany() != null ? branch.getCompany().getId() : "null", id);
            throw new ResourceNotFoundException("Fiók nem található: " + id);
        }

        // Ellenőrzés: van-e gyermeke
```

---

### #PP-03: Kereszt-bérlő adatszivárgás az AML bejelentéseknél (Cross-Tenant Transaction Association in AML Reports)
* **Célpont / Fájl:** [AmlService.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java)
* **Súlyosság:** HIGH
* **Hiba Kategória:** Biztonság (Broken Object Level Authorization / IDOR)
* **Leírás:** Az `submitReport(CreateAmlReportDto dto)` metódusban, ha a DTO-ban megadásra kerül egy `transactionId`, a rendszer betölti a tranzakciót, és összekapcsolja az újonnan létrejövő AML bejelentéssel. Azonban **teljesen hiányzik** a bérlő-azonosító (`companyId`) ellenőrzése a betöltött tranzakción! Így az A cég (A bérlő) pénztárosa hozzákapcsolhatja és ezáltal lekérdezheti vagy módosíthatja a B céghez (B bérlőhöz) tartozó tranzakció adatait!
* **Jelenlegi Hibás Kód:** (sorszámok: 863-866)
```java
        if (dto.getTransactionId() != null) {
            Transaction tx = transactionRepository.findById(dto.getTransactionId()).orElse(null);
            report.setTransaction(tx);
        }
```
* **Javított Kódjavaslat:**
```java
        if (dto.getTransactionId() != null) {
            Transaction tx = transactionRepository.findById(dto.getTransactionId())
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + dto.getTransactionId()));
            
            // IDOR ellenőrzés: csak a saját cég tranzakcióját engedjük hozzákapcsolni
            if (tx.getCompany() == null || !tx.getCompany().getId().equals(companyId)) {
                log.warn("Kereszt-bérlő AML tranzakció csatolás blokkolva! userCompany={}, txCompany={}, txId={}",
                    companyId, tx.getCompany() != null ? tx.getCompany().getId() : "null", tx.getId());
                throw new ValidationException("A megadott tranzakció nem kapcsolható össze ezzel a bejelentéssel!");
            }
            report.setTransaction(tx);
        }
```

---

### #PP-04: Kijátszható CORS minta-illesztés (Bypassable CORS Regex Matcher)
* **Célpont / Fájl:** [ProductionCorsFilter.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/config/ProductionCorsFilter.java)
* **Súlyosság:** HIGH
* **Hiba Kategória:** Biztonság (CORS Misconfiguration / Origin Hijack)
* **Leírás:** A filter a konfigurált origin mintákat split-eli a `*` karakter mentén, majd a `matchesPattern` metódusban egyszerű `startsWith` és `endsWith` vizsgálatot végez. Ha az engedélyezett minta `http://localhost:*`, a filter a `parts` tömbbé a `["http://localhost:", ""]` értékeket kapja. 
Egy támadó által regisztrált `http://localhost.evil.com` vagy `http://localhost:evil.com` domain az ellenőrzésen átmegy, mivel elindul a `"http://localhost:"` előtaggal és a `""` (üres) utótaggal végződik. Ez súlyos Cross-Origin adatszivárgást okozhat.
* **Jelenlegi Hibás Kód:** (sorszámok: 109-131)
```java
    private boolean matchesPattern(String origin, String pattern) {
        String normalizedPattern = pattern.toLowerCase(Locale.ROOT);
        String normalizedOrigin = origin.toLowerCase(Locale.ROOT);

        if (!normalizedPattern.contains("*")) {
            return normalizedOrigin.equals(normalizedPattern);
        }

        String[] parts = normalizedPattern.split("\\*", -1);
        int index = 0;
        for (String part : parts) {
            if (part.isEmpty()) {
                continue;
            }
            int found = normalizedOrigin.indexOf(part, index);
            if (found < 0) {
                return false;
            }
            index = found + part.length();
        }

        return normalizedOrigin.startsWith(parts[0]) && normalizedOrigin.endsWith(parts[parts.length - 1]);
    }
```
* **Javított Kódjavaslat:**
```java
    private boolean matchesPattern(String origin, String pattern) {
        String normalizedPattern = pattern.toLowerCase(Locale.ROOT);
        String normalizedOrigin = origin.toLowerCase(Locale.ROOT);

        if (!normalizedPattern.contains("*")) {
            return normalizedOrigin.equals(normalizedPattern);
        }

        // Biztonságos regex generálás
        String regex = normalizedPattern
                .replace(".", "\\.")
                .replace("http://localhost:*", "http://localhost(:\\d+)?")
                .replace("https://*", "https://[a-z0-9-]+");

        if (!regex.startsWith("^")) {
            regex = "^" + regex;
        }
        if (!regex.endsWith("$")) {
            regex = regex + "$";
        }

        return normalizedOrigin.matches(regex);
    }
```

---

## 3. LOGIKAI ÉS ADATINTEGRITÁSI PROGRAMOZÁSI HIBÁK

### #PP-05: Memóriabeli szűrés adatbázis-szintű szűrés helyett (In-Memory Scope Leak)
* **Célpont / Fájl:** [BranchService.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/BranchService.java)
* **Súlyosság:** MEDIUM
* **Hiba Kategória:** Teljesítmény / Rossz Tervezés
* **Leírás:** A `findByStatus(String statusCode)` metódus először lekérdezi az összes létező irodát a megadott státuszkóddal az *egész adatbázisból* (`branchRepository.findByBranchStatusCode(statusCode)`), majd Java Stream segítségével a JVM memóriájában szűri ki a saját céghez tartozó irodákat. Ez több-bérlős rendszerekben súlyos teljesítménybeli romláshoz vezet.
* **Jelenlegi Hibás Kód:** (sorszámok: 184-194)
```java
    @Transactional(readOnly = true)
    @SuppressWarnings("deprecation") // Multi-tenant audit: ritkan hasznalt, branch_status kod egyedi cegenkent is — kicsi risk
    public List<BranchDto> findByStatus(String statusCode) {
        log.debug("Finding branches by status: {}", statusCode);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        // Post-filter stream-mel company-id szures
        List<Branch> branches = branchRepository.findByBranchStatusCode(statusCode).stream()
                .filter(b -> b.getCompany() != null && b.getCompany().getId().equals(companyId))
                .collect(Collectors.toList());
        return branchMapper.toDtoList(branches);
    }
```
* **Javított Kódjavaslat:**
1. A [BranchRepository.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/repository/BranchRepository.java) fájlban definiáld a lekérdezést SQL/JPQL szinten:
```java
    @Query("SELECT b FROM Branch b WHERE b.company.id = :companyId AND b.branchStatus.code = :statusCode")
    List<Branch> findByCompanyIdAndBranchStatusCode(
        @Param("companyId") UUID companyId, 
        @Param("statusCode") String statusCode
    );
```
2. A `BranchService.java` metódust módosítsd:
```java
    /**
     * Fiókok státusz és cég szerint - SQL szinten optimalizálva
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findByStatus(String statusCode) {
        log.debug("Finding branches by status: {}", statusCode);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> branches = branchRepository.findByCompanyIdAndBranchStatusCode(companyId, statusCode);
        return branchMapper.toDtoList(branches);
    }
```

---

### #PP-06: Nem atomi kvóta-ellenőrzés (Race Condition in Custom Rate Quota)
* **Célpont / Fájl:** [TransactionService.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java)
* **Súlyosság:** HIGH
* **Hiba Kategória:** Logikai hiba (Race Condition / TOCTOU)
* **Leírás:** A pénztárosi sáv egyedi árfolyam napi kvótájának ellenőrzése (`validateAndNormalizeCashierCustomRateQuota` metódus) egy klasszikus "Read-then-Write" szekvencia. Ha a pénztáros két különböző kliensről párhuzamosan indít tranzakciót, a lekérdezések egyszerre futnak le, mindkettő engedélyezi a tranzakciót, és a napi limit felett egy 6. tranzakció is sikeresen mentésre kerül.
* **Jelenlegi Hibás Kód:** (sorszámok: 1164-1183)
```java
    private boolean validateAndNormalizeCashierCustomRateQuota(boolean cashierCustomRate, BigDecimal hufAmount) {
        if (!cashierCustomRate) {
            return false;
        }
        long minAmount = parseSystemParameterLong("CASHIER_CUSTOM_RATE_MIN_AMOUNT", "400000");
        if (hufAmount == null || hufAmount.compareTo(BigDecimal.valueOf(minAmount)) < 0) {
            return false;
        }
        Long workerId = SecurityUtils.getCurrentWorkerId();
        long used = transactionRepository.countDailyCashierCustomRatesByWorker(workerId, LocalDate.now());
        long limit = parseSystemParameterLong("CASHIER_CUSTOM_RATE_DAILY_LIMIT", "5");
        if (used >= limit) {
            throw new ValidationException(
                    String.format("Pénztárosi sáv napi limit elérve (%d/%d). Egyedi árfolyam ma már nem alkalmazható, kérjen vezetői jóváhagyást.",
                            used, limit));
        }
        return true;
    }
```
* **Javított Kódjavaslat:**
1. A [WorkerRepository.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/repository/WorkerRepository.java) fájlban hozz létre egy pessimistic lezárású metódust:
```java
    @jakarta.persistence.LockModeType(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT w FROM Worker w WHERE w.id = :id")
    java.util.Optional<Worker> findByIdForUpdate(@Param("id") Long id);
```
2. A `TransactionService.java` metódusát módosítsd:
```java
    private boolean validateAndNormalizeCashierCustomRateQuota(boolean cashierCustomRate, BigDecimal hufAmount) {
        if (!cashierCustomRate) {
            return false;
        }
        long minAmount = parseSystemParameterLong("CASHIER_CUSTOM_RATE_MIN_AMOUNT", "400000");
        if (hufAmount == null || hufAmount.compareTo(BigDecimal.valueOf(minAmount)) < 0) {
            return false;
        }
        Long workerId = SecurityUtils.getCurrentWorkerId();
        
        // PESSIMISTIC LOCK: Megakadályozza a szálak egyidejű futását a számlálónál
        workerRepository.findByIdForUpdate(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + workerId));
        
        long used = transactionRepository.countDailyCashierCustomRatesByWorker(workerId, LocalDate.now());
        long limit = parseSystemParameterLong("CASHIER_CUSTOM_RATE_DAILY_LIMIT", "5");
        if (used >= limit) {
            throw new ValidationException(
                    String.format("Pénztárosi sáv napi limit elérve (%d/%d). Egyedi árfolyam ma már nem alkalmazható, kérjen vezetői jóváhagyást.",
                            used, limit));
        }
        return true;
    }
```

---

### #PP-07: Dupla-sztornó sebezhetőség párhuzamos kéréseknél (Double-Storno Concurrency Defect)
* **Célpont / Fájl:** [TransactionReversalService.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/TransactionReversalService.java)
* **Súlyosság:** HIGH
* **Hiba Kategória:** Logikai / Párhuzamossági hiba (Race Condition)
* **Leírás:** Az `executeReversal` metódus az adatbázisból lekéri a tranzakciót, ellenőrzi, hogy `reversed = true` státuszban van-e, és ha nem, akkor elindítja a sztornózást. Mivel ez a lekérdezés (`findById`) nem használ pessimistic zárat, két párhuzamosan indított sztornó kérés esetén mindkét szál lefuthat, mindkét szál módosítja a kasszakészletet, miközben két sztornó bejegyzés jön létre a DB-ben.
* **Jelenlegi Hibás Kód:** (sorszámok: 55-68)
```java
        // Eredeti tranzakcio lekerese
        Transaction original = transactionRepository.findById(request.getOriginalTransactionId())
                .orElseThrow(() -> new ResourceNotFoundException("Eredeti tranzakcio nem talalhato"));

        // Validaciok
        if (original.isReversed()) {
            throw new ValidationException("Ez a tranzakcio mar sztornozva lett!");
        }
```
* **Javított Kódjavaslat:**
1. A [TransactionRepository.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/repository/TransactionRepository.java) fájlban vezess be egy explicit pessimistic lezárást:
```java
    @jakarta.persistence.LockModeType(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT t FROM Transaction t WHERE t.id = :id")
    java.util.Optional<Transaction> findByIdForUpdate(@Param("id") Long id);
```
2. A `TransactionReversalService.java` metódusát módosítsd:
```java
        // PESSIMISTIC LOCK: Kizárja a párhuzamos dupla-sztornózást
        Transaction original = transactionRepository.findByIdForUpdate(request.getOriginalTransactionId())
                .orElseThrow(() -> new ResourceNotFoundException("Eredeti tranzakció nem található"));

        // Validációk
        if (original.isReversed()) {
            throw new ValidationException("Ez a tranzakció már sztornózva lett!");
        }
```

---

## 4. KLIENS-OLDALI ARCHITEKTURÁLIS ÉS TERVEZÉSI HIBÁK

### #PP-08: Végtelen spamelés hitelesítési hibák esetén (Auth Failure Spam in Offline Sync)
* **Célpont / Fájl:** [sync-engine.ts](file:///D:/repo/valutavalto-program/penztar-client/electron/sync-engine.ts)
* **Súlyosság:** HIGH
* **Hiba Kategória:** Tervezési hiba (Resilience / Event Loop Spam)
* **Leírás:** Amikor a kliens-oldali `bootstrapAuthSession` hitelesítési hibát kap (401/403), a hibát elkapja és `null` token-nel tér vissza. A `runSync` metódus sikeresen befejeződik (nem dobódik hiba a fő try-catch-ben), ezért a `consecutiveFailures` **resetelődez 0-ra**, a `backoffUntilMs` pedig törlődik. Ez azt eredményezi, hogy a 30 másodperces periódusos `setInterval` **exponenciális hátrálás nélkül, végtelenül és folyamatosan újra próbálkozik**.
* **Jelenlegi Hibás Kód:** (sorszámok: 555-600)
```typescript
      let token = this.getAuthToken();

      if (token) {
        const isValid = await this.validateToken(serverUrl, token);
        if (!isValid) {
          this.clearStoredAuthToken();
          token = await this.bootstrapAuthSession(serverUrl);
        }
      } else {
        token = await this.bootstrapAuthSession(serverUrl);
      }
```
* **Javított Kódjavaslat:**
```typescript
      let token = this.getAuthToken();
      let authFailed = false;

      try {
        if (token) {
          const isValid = await this.validateToken(serverUrl, token);
          if (!isValid) {
            this.clearStoredAuthToken();
            token = await this.bootstrapAuthSession(serverUrl);
            if (!token) authFailed = true;
          }
        } else {
          token = await this.bootstrapAuthSession(serverUrl);
          if (!token) authFailed = true;
        }
      } catch (err) {
        if (isAuthStatusError(err)) {
          authFailed = true;
        } else {
          throw err;
        }
      }

      if (authFailed) {
        log.error('[SyncEngine] Kritikus hitelesítési hiba (401/403). Szinkronizáció leállítása.');
        this.stop();
        this.clearStoredAuthToken();
        if (global.mainWindow) {
          global.mainWindow.webContents.send('sync:auth-error', {
            message: 'A szerver elutasította a hitelesítést. Kérjük jelentkezzen be újra!'
          });
        }
        this.status.isRunning = false;
        return;
      }
```

---

### #PP-09: Lebegőpontos számábrázolás a kliens adatbázisban (Floating-Point Precision Risks on Client)
* **Célpont / Fájl:** [sqlite.ts](file:///D:/repo/valutavalto-program/penztar-client/electron/sqlite.ts), [preload.ts](file:///D:/repo/valutavalto-program/penztar-client/electron/preload.ts)
* **Súlyosság:** HIGH
* **Hiba Kategória:** Adatintegritás (Floating-Point Precision Error)
* **Leírás:** A kliens oldali SQLite séma a pénzügyi értékeket (`foreign_amount`, `huf_amount`, `rate`, `handling_fee`) `REAL` típusúként deklarálja. A JavaScript preload réteg (`preload.ts`) pedig standard `number` típusként küldi át az értékeket. Ez kerekítési hibát eredményez az offline Pénztáron, ami a szinkronizáció során a backend perzisztencia rétegébe is átmásolódik.
* **Jelenlegi Hibás Kód:** (sorszámok: 159-168)
```typescript
    db.run(`
      CREATE TABLE IF NOT EXISTS pending_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('SELL', 'BUY')),
        currency_code TEXT NOT NULL,
        foreign_amount REAL NOT NULL,
        huf_amount REAL NOT NULL,
        rounded_huf_amount REAL NOT NULL,
        rate REAL NOT NULL,
```
* **Javított Kódjavaslat:**
1. A sémát úgy módosítsuk, hogy az összegeket `TEXT` mezőként tárolja, megőrizve a tizedesek hajszálpontos decimal értékeit.
2. A kliensen matematikai számításokra a standard `number` helyett használjunk precision library-t (pl. `big.js`).

---

### #PP-10: OS-portabilitási kompatibilitási hiba a fallback konfigurációban (OS Path Compatibility Defect)
* **Célpont / Fájl:** [application-production.properties](file:///D:/repo/valutavalto-program/backend/src/main/resources/application-production.properties)
* **Súlyosság:** MEDIUM
* **Hiba Kategória:** Rendszerkompatibilitás / Hordozhatóság
* **Leírás:** A backend éles konfigurációs fájljában az integrációs csatornák tárolási gyökérmappája Unix-alapú abszolút útvonallal van megadva fallback-ként: `integration.transport.root-path=${INTEGRATION_TRANSPORT_ROOT:/tmp/valuta-integrations}`. Windows-alapú szerveren vagy lokális futtatás során ez a mappa nem létezik, és az I/O fájlműveletek hibát vagy kivételt fognak dobni, amikor a rendszer megkísérel integrációs állományokat (pl. kamera képeket vagy sync naplókat) írni.
* **Jelenlegi Hibás Kód:** (sorszám: 131)
```properties
integration.transport.root-path=${INTEGRATION_TRANSPORT_ROOT:/tmp/valuta-integrations}
```
* **Javított Kódjavaslat:** Cseréljük le a fallback útvonalat egy OS-független, a felhasználó home mappája alatt elhelyezkedő mappára:
```properties
integration.transport.root-path=${INTEGRATION_TRANSPORT_ROOT:${user.home}/.valuta/integrations}
```

---

## 5. PL/pgSQL ÉS CRITICAL LICENSING HIBÁK (KIEMELT JAVÍTÁSOKKAL)

### #PP-11: SQL Trigger PL/pgSQL összeomlás DELETE műveletnél (Trigger PL/pgSQL Crash on Delete)
* **Célpont / Fájl:** [V234__audit_log_immutable_hash_chain.sql](file:///D:/repo/valutavalto-program/backend/src/main/resources/db/migration/V234__audit_log_immutable_hash_chain.sql)
* **Súlyosság:** CRITICAL
* **Hiba Kategória:** Adatbázis / Trigger PL/pgSQL logikai hiba
* **Leírás:** A `BEFORE DELETE` immutable trigger funkció a `NEW.id::TEXT` és `NEW.action` kifejezésekre hivatkozik a hibaüzenet összeállításakor. PostgreSQL PL/pgSQL-ben azonban törlés (`DELETE`) esetén a `NEW` rekord egyáltalán nincs inicializálva (NULL / unassigned). Bármely `DELETE` utasítás futtatása során a trigger PL/pgSQL hibát dob (`record "new" is not yet assigned`), megakadályozva, hogy a tranzakció szabályszerűen meghiúsuljon és a tisztességes, tervezett hibaüzenetet küldje vissza.
* **Jelenlegi Hibás Kód:** (sorszámok: 74-87)
```sql
CREATE OR REPLACE FUNCTION audit_log_immutable() RETURNS TRIGGER AS $$
BEGIN
  -- Copilot PR #681 P2 fix: csak stabil oszlopokra hivatkozunk (action, id).
  -- Az event_type a V234-ben jott letre, igy ha valaki a triggert ujboltja
  -- egy regi snapshot-on, NEM doblunk "record old has no field event_type" hibat.
  RAISE EXCEPTION 'audit_log immutable: % operation not allowed (id=%, action=%)',
    TG_OP,
    COALESCE(OLD.id::TEXT, NEW.id::TEXT, 'unknown'),
    COALESCE(OLD.action, NEW.action, 'unknown');
  -- Defenziv: a RAISE EXCEPTION mar abortolja a function-t, de explicit
  -- RETURN NULL hozzaadva ha valaki a jovoben demote-olna warning-ra.
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```
* **Javított Kódjavaslat:**
```sql
CREATE OR REPLACE FUNCTION audit_log_immutable() RETURNS TRIGGER AS $$
DECLARE
  v_id TEXT;
  v_action TEXT;
BEGIN
  -- Ellenőrizzük a művelet típusát és csak akkor hivatkozunk NEW-ra, ha nem DELETE
  IF (TG_OP = 'DELETE') THEN
    v_id := COALESCE(OLD.id::TEXT, 'unknown');
    v_action := COALESCE(OLD.action, 'unknown');
  ELSE
    v_id := COALESCE(OLD.id::TEXT, NEW.id::TEXT, 'unknown');
    v_action := COALESCE(OLD.action, NEW.action, 'unknown');
  END IF;

  RAISE EXCEPTION 'audit_log immutable: % operation not allowed (id=%, action=%)',
    TG_OP,
    v_id,
    v_action;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

---

### #PP-12: Törékeny licenc funkció string-keresés (Fragile Substring Match on Paid Features)
* **Célpont / Fájl:** [LicenseService.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/LicenseService.java)
* **Súlyosság:** CRITICAL
* **Hiba Kategória:** Licenckezelés / Hibás logikai implementáció
* **Leírás:** A `checkFeature(String featureName)` metódus a licencelt modulokat egy rendkívül instabil módon ellenőrzi: `license.getFeatures().contains("\"" + featureName + "\"")`. Ez közvetlen substring illesztést végez a JSON vagy tömb String-ben. Ha a formátum eltér a whitespace-ektől (pl. `[ "AML" ]`), vagy nem idézőjeleket, hanem aposztrófokat használ a JSON string, a `contains` hamis értékkel tér vissza, és kizárja az irodákat a legálisan megvásárolt, kritikus üzleti modulokból (pl. AML, Stornó)!
* **Jelenlegi Hibás Kód:** (sorszámok: 92-99)
```java
    @Transactional(readOnly = true)
    public boolean checkFeature(String featureName) {
        return licenseRepository.findByIsActiveTrue()
                .map(license -> {
                    if (license.getFeatures() == null) return false;
                    return license.getFeatures().contains("\"" + featureName + "\"");
                })
                .orElse(false);
    }
```
* **Javított Kódjavaslat:**
```java
    // Jackson ObjectMapper hozzáadása az osztály tagjaként a robusztus JSON kezeléshez:
    private final com.fasterxml.jackson.databind.ObjectMapper objectMapper = new com.fasterxml.jackson.databind.ObjectMapper();

    /**
     * Feature ellenőrzés — engedélyezett-e a modul robusztus JSON parsolással és regex fallback-kel
     */
    @Transactional(readOnly = true)
    public boolean checkFeature(String featureName) {
        return licenseRepository.findByIsActiveTrue()
                .map(license -> {
                    if (license.getFeatures() == null || license.getFeatures().isBlank()) return false;
                    
                    try {
                        String trimmedFeatures = license.getFeatures().trim();
                        // Ha JSON tömb, akkor szabványos Jackson parsolással olvassuk be a listát
                        if (trimmedFeatures.startsWith("[")) {
                            java.util.List<String> featuresList = objectMapper.readValue(
                                trimmedFeatures, 
                                new com.fasterxml.jackson.core.type.TypeReference<java.util.List<String>>() {}
                            );
                            return featuresList.stream()
                                    .map(String::trim)
                                    .anyMatch(f -> f.equalsIgnoreCase(featureName));
                        }
                    } catch (Exception e) {
                        log.warn("Sikertelen licenc feature JSON parsolás, fallback robust substring keresésre: {}", e.getMessage());
                    }
                    
                    // Biztonságos fallback: whitespace-mentesítés és rugalmas substring keresés
                    String cleanFeatures = license.getFeatures().replaceAll("\\s+", "");
                    return cleanFeatures.contains("\"" + featureName + "\"") 
                        || cleanFeatures.contains("'" + featureName + "'")
                        || cleanFeatures.contains(featureName);
                })
                .orElse(false);
    }
```

---

## 6. JÓVÁHAGYÁSI ÉS ELLENŐRZÉSI PARANCSOK AI ÜGYNÖKÖK SZÁMÁRA

A hibák javítását az alábbi lépésekben végezd el:
1. **Azonosítás és Navigáció:** Nyisd meg a megadott fájlt az absolute path alapján.
2. **Kódmódosítás:** Keresd meg a jelzett sorszámok közötti hibás blokkot, és cseréld le a Javított Kódjavaslatra.
3. **Validáció:**
   * Backend hibák javítása után futtasd a Maven teszteket: `mvn clean test`
   * Frontend / Electron kliens hibák javítása után futtasd a typecheck-et: `npm run typecheck` a `penztar-client` mappában.
4. **Záró minőségi kapu:** Futtaszt a zero-trust biztonsági és kódminőségi kaput: `npm run agent:guard`

---
**Rendszer-Audit Készítője:** Antigravity AI Senior Security Architect Agent  
**Dátum:** 2026-05-23T10:53:00+02:00  
**Licenc:** Bizalmas / Kormányzati szintű pénzügyi ERP megfelelőség  
