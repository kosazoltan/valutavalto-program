# VALUTAVÁLTÓ RENDSZER - REJTETT HIVATKOZÁSOK ÉS HÁTSÓ KAPUK (BACKDOOR) BIZTONSÁGI AUDIT JELENTÉSE
## Mesterséges Intelligencia (AI) Fejlesztői Ügynök Számára Átadható Végrehajtási Utasítások (V1.0)

> **Cél:** A `valutavalto-program` monorepo alapos biztonsági átvizsgálása abból a szempontból, hogy találhatóak-e benne nem szándékos logikai bypass-ok, fejlesztői debug kódokból maradt hátsó kapuk (backdoor-ok), információ-szivárgások vagy sérülékeny külső függőségek.
> **Végrehajtó AI Ügynök számára:** Ez a dokumentum közvetlenül gépi úton feldolgozható parancskészlet. A megadott hibás kódblokkokat a megadott javított kódjavaslatok alapján kell módosítani a megadott fájlokban.

---

## 1. MŰSZAKI ÉS ARCHITEKTURÁLIS FELÜLVIZSGÁLAT
A zero-trust alapelvek és a statikus kódelemzés alapján a teljes monorepo (backend, frontend, Electron kliens, Flyway migrációk) átvilágításra került. A vizsgálat során **3 kritikus logikai és jogosultsági sérülékenységet/backdoor-szerű logikát** tártam fel, amelyeket a fejlesztés során kényelmi okokból vagy nem szándékosan hagytak a kódban, valamint ellenőriztem az összes harmadik féltől származó függőséget és rendszerhívást.

---

## 2. RÉSZLETES BIZTONSÁGI SEBEZHETŐSÉGEK ÉS JAVÍTÁSOK

### #PP-13: Nyitva maradó Setup Google Auto-Detection Végpont (Bypassable Google Linkage Backdoor)
* **Célpont / Fájl:** [SecurityConfig.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/config/SecurityConfig.java) / [SetupGoogleController.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/controller/SetupGoogleController.java) / [SetupGoogleIdentificationService.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/SetupGoogleIdentificationService.java)
* **Súlyosság:** CRITICAL
* **Hiba Kategória:** Jogosultsági Kerülés / Fiók Átvételi Sérülékenység (Account Takeover / Hijacking)
* **Leírás:** A `SetupGoogleController` (`/api/v1/public/setup/google-identify`) a bejelentkezés nélküli Setup Wizard Google azonosításhoz készült.
Azonban ez a végpont a telepítés és az admin bootstrap befejezése után is **örökre publikusan elérhető marad**. Semmilyen guard nincs benne, ami ellenőrizné, hogy a `auth.bootstrap-completed` flag `true`-ra váltott-e! 
Ez egy rendkívül súlyos sérülékenység: ha egy cég dolgozójának vagy fiókjának az email címe megegyezik egy Google fiókkal, és a dolgozóhoz még nincs Google Subject rendelve (vagy ha megosztott fiók-emailről van szó), egy támadó a saját Google fiókjával meghívhatja a publikus végpontot, és hozzárendelheti a saját Google azonosítóját (`googleSubject`) a cél-dolgozóhoz. Innentől kezdve a támadó hitelesített Google bejelentkezéssel teljesen átveheti az ellenőrzést az adott dolgozó (akár ADMIN) felett!
* **Jelenlegi Hibás Kód:** (SetupGoogleIdentificationService.java, 36-39. sorok)
```java
    @Transactional
    public SetupGoogleIdentifyResponseDto identify(SetupGoogleIdentifyRequestDto request) {
        GoogleIdTokenService.VerifiedGoogleIdentity identity = verifyIdentity(request.getIdToken());
        Company company = resolveCompany(request.getCompanyCode());
```
* **Javított Kódjavaslat:**
Adjuk hozzá a bootstrap completed ellenőrzést közvetlenül a Google Setup azonosítás elejére, hogy ha a bootstrap már lezajlott, a végpont azonnal tiltsa le a hívásokat!
```java
    // Fecskendezzük be a SystemParameterRepository-t vagy ellenőrizzük a bootstrap flaget:
    private final hu.puzzleir.valuta.repository.SystemParameterRepository systemParameterRepository;

    @Transactional
    public SetupGoogleIdentifyResponseDto identify(SetupGoogleIdentifyRequestDto request) {
        // Védelem: Ha a setup már befejeződött, tiltsuk le a publikus Google setup végpontot
        boolean setupCompleted = systemParameterRepository.findByParameterKey("auth.bootstrap-completed")
                .map(sp -> "true".equalsIgnoreCase(sp.getParameterValue()) && Boolean.TRUE.equals(sp.getIsActive()))
                .orElse(false);
        
        if (setupCompleted) {
            log.warn("Publikus Google setup azonosítás elutasítva, mert a rendszer setup már lezárult!");
            throw new hu.puzzleir.valuta.exception.AuthenticationException("A rendszer setup már lezárult. Kérjük használja a normál bejelentkezést.");
        }

        GoogleIdTokenService.VerifiedGoogleIdentity identity = verifyIdentity(request.getIdToken());
        Company company = resolveCompany(request.getCompanyCode());
```

---

### #PP-14: Cégkód Felfedési Információ-szivárgás a Bootstrap Admin Végponton (Unauthenticated Company Code Enumeration)
* **Célpont / Fájl:** [AdminBootstrapService.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/AdminBootstrapService.java)
* **Súlyosság:** HIGH
* **Hiba Kategória:** Információ-szivárgás (Information Disclosure / Enumeration)
* **Leírás:** Az `bootstrapAdmin` metódusban a cégkód feloldása (`companyRepository.findByCode(...)`) azelőtt történik meg, hogy ellenőriznénk, a bootstrap folyamat már lezárult-e (`alreadyCompleted`).
Ha a megadott cégkód nem létezik az adatbázisban, a rendszer `ValidationException`-t dob ("Ismeretlen cégkód..."). Ha a cégkód létezik, de a setup már lezárult, akkor a "A bootstrap már lezajlott..." hibaüzenetet küldi vissza.
Ez lehetővé teszi egy külső, be nem jelentkezett támadó számára, hogy **cégkódokat teszteljen és térképezzen fel (Company Enumeration)** az adatbázisban, ami a multi-tenant izoláció és a brute-force támadások előkészítésének egyik alappillére.
* **Jelenlegi Hibás Kód:** (sorszámok: 57-77)
```java
    @Transactional(rollbackFor = Exception.class)
    public BootstrapAdminResponseDto bootstrapAdmin(BootstrapAdminRequestDto dto) {
        boolean alreadyCompleted = isBootstrapAlreadyCompleted();

        String normalizedCompanyCode = normalize(dto.getCompanyCode());
        String normalizedWorkerCode = normalize(dto.getWorkerCode());

        Company company = companyRepository.findByCode(normalizedCompanyCode)
                .or(() -> companyRepository.findByCodeIgnoreCase(normalizedCompanyCode))
                .orElseThrow(() -> new ValidationException(
                        "Ismeretlen cégkód: " + normalizedCompanyCode
                        + ". Ellenőrizd az adatbázisban, hogy létrejött-e a cég."
                ));

        if (alreadyCompleted) {
            log.warn("Admin bootstrap elutasítva, mert már lezárult: companyCode={}, workerCode={}",
                    company.getCode(), normalizedWorkerCode);
            throw new ValidationException(
                    "A bootstrap már lezajlott; jelszó frissítéshez használd a hitelesített "
                            + "dolgozói jelszócsere vagy reset folyamatot."
            );
        }
```
* **Javított Kódjavaslat:**
Az `alreadyCompleted` flag ellenőrzését és elutasítását vigyük a metódus legelső sorába, a cégkód adatbázis-alapú feloldása elé. Így ha a bootstrap már lezajlott (ami a normál állapot), a támadó minden cégkódra pontosan ugyanazt az elutasító hibaüzenetet kapja, megakadályozva a cégkód feltérképezést.
```java
    @Transactional(rollbackFor = Exception.class)
    public BootstrapAdminResponseDto bootstrapAdmin(BootstrapAdminRequestDto dto) {
        // Biztonsági fix: Fail-fast ellenőrzés a cégkód feloldása előtt az információ-szivárgás ellen
        if (isBootstrapAlreadyCompleted()) {
            log.warn("Admin bootstrap kísérlet elutasítva, mert a folyamat már korábban sikeresen lezárult.");
            throw new ValidationException(
                    "A bootstrap már lezajlott; jelszó frissítéshez használd a hitelesített "
                            + "dolgozói jelszócsere vagy reset folyamatot."
            );
        }

        String normalizedCompanyCode = normalize(dto.getCompanyCode());
        String normalizedWorkerCode = normalize(dto.getWorkerCode());

        Company company = companyRepository.findByCode(normalizedCompanyCode)
                .or(() -> companyRepository.findByCodeIgnoreCase(normalizedCompanyCode))
                .orElseThrow(() -> new ValidationException(
                        "Ismeretlen cégkód: " + normalizedCompanyCode
                        + ". Ellenőrizd az adatbázisban, hogy létrejött-e a cég."
                ));
```

---

### #PP-15: Logikai Bypass a Dolgozói Név-alapú Bejelentkezésnél (Loose Worker Identification by Name)
* **Célpont / Fájl:** [WorkerService.java](file:///D:/repo/valutavalto-program/backend/src/main/java/hu/puzzleir/valuta/service/WorkerService.java)
* **Súlyosság:** MEDIUM
* **Hiba Kategória:** Logikai hiányosság / Gyenge Hitelesítés
* **Leírás:** A bejelentkezés feloldásakor (`resolveWorkerForLogin` metódus) a rendszer a kód paraméterrel először a dolgozó kódjára (`workerCode`) keres rá. Ha nem találja meg, végigmegy a cég összes dolgozóján, és ha a megadott azonosító egyezik a dolgozó **normalizált nevével** (`worker.getName()`), akkor azonosítja a dolgozót:
`if (nameMatch == null && normalizeLoginCode(worker.getName()).equals(normalizedInput))`
Ez egy nem szándékos logikai bypass: a dolgozók a pénztáros kód helyett a saját nevükkel is bejelentkezhetnek. Pénzügyi rendszerekben a bejelentkezési azonosító szigorú kód-alapú elválasztása az elvárt, mivel a nevek könnyen kitalálhatóak, ami növeli a brute-force és a célzott támadások sikerességét.
* **Jelenlegi Hibás Kód:** (sorszámok: 617-627)
```java
        List<Worker> companyWorkers = workerRepository.findByCompanyId(company.getId());
        Worker nameMatch = null;
        for (Worker worker : companyWorkers) {
            if (normalizeLoginCode(worker.getCode()).equals(normalizedInput)) {
                return Optional.of(worker);
            }
            if (nameMatch == null && normalizeLoginCode(worker.getName()).equals(normalizedInput)) {
                nameMatch = worker;
            }
        }
        return Optional.ofNullable(nameMatch);
```
* **Javított Kódjavaslat:**
Szigorítsuk a bejelentkezést kizárólag a hivatalos, egyedi pénztáros kódra. Távolítsuk el a név-alapú fallback-et a hitelesítési láncból.
```java
        List<Worker> companyWorkers = workerRepository.findByCompanyId(company.getId());
        for (Worker worker : companyWorkers) {
            if (normalizeLoginCode(worker.getCode()).equals(normalizedInput)) {
                return Optional.of(worker);
            }
        }
        return Optional.empty();
```

---

## 3. DEPENDENCY ÉS KÜLSŐ HIVATKOZÁSOK AUDIT EREDMÉNYEI

### 3.1. Függőség Audit (Supply-Chain Verification)
* **Maven POM (`backend/pom.xml`):** Minden függőség hivatalos, ellenőrzött repository-ból érkezik. A legújabb **Spring Boot 4.0.6** és **Spring Security 6.5.10** verziók használatával az összes ismert belső keretrendszerbeli sérülékenység (például a Spring Actuator hitelesítési bypass: CVE-2026-22731 és a Tomcat CLIENT_CERT sérülékenység: CVE-2026-29145) orvosolva lett.
* **OWASP Dependency Check:** Integrálva van a build folyamatba, amely minden fordítás során automatikusan ellenőrzi a függőségeket az ismert CVE-k ellen.
* **Electron Kliens (`penztar-client/package.json`):** Kizárólag elterjedt és standard csomagokat használ (`sql.js`, `serialport`, `electron-updater`). Nincsenek elavult, gyanús vagy nem auditált npm függőségek.

### 3.2. Operációs Rendszer és Rendszerhívások Auditja
* **Tetszőleges Parancsfuttatás (RCE) vizsgálata:** A teljes backend forráskódban kizárólag a `BackupService.java` használ parancsindítást (`ProcessBuilder`), ami a Postgres `pg_dump` és `pg_restore` futtatásához szükséges az adatbázis-mentéshez és visszaállításhoz.
* **Injekció elleni védelem:** A `BackupService` a `pg_dump` path-ot nem közvetlenül a környezeti változókból vagy külső paraméterből indítja, hanem az explicit `resolveAbsoluteExecutablePath` helper segítségével **abszolút útvonalra oldja fel**, megelőzve a `PATH` manipulációs támadásokat és a CodeQL `java/relative-path-command` sérülékenységeket.

---

## 4. JÓVÁHAGYÁSI ÉS ELLENŐRZÉSI UTASÍTÁSOK AI ÜGYNÖKÖK SZÁMÁRA

1. **SetupGoogleController javítása:** Alkalmazd a #PP-13-as drop-in javítást, hogy a telepítés lezárása után a Google setup végpont se legyen bypassolható.
2. **AdminBootstrapService szigorítása:** Alkalmazd a #PP-14-es javítást a cégkód-feltérképezési adatszivárgás megszüntetésére.
3. **WorkerService bejelentkezési szigorítás:** Alkalmazd a #PP-15-ös javítást a név-alapú bejelentkezési bypass megszüntetésére.
4. **Validáció futtatása:** Futtasd a Maven teszteket (`mvn clean test`) és a zero-trust biztonsági kaput (`npm run agent:guard`).

---
**Rendszer-Audit Készítője:** Antigravity AI Senior Security Architect Agent  
**Dátum:** 2026-05-24T07:20:00+02:00  
**Licenc:** Bizalmas / Kormányzati szintű pénzügyi ERP megfelelőség  
