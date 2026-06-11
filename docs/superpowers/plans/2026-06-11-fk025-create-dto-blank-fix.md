# FK-025 kiegészítés: CreateBranchDto üres opcionális mezők (TBD#1) — Implementációs terv

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Az FK-025 spec Scope IN 3. pontjának (TBD#1) teljesítése: a spec "BranchCreateRequest.java"-jának ebben a repóban megfelelő `CreateBranchDto.java` (POST /api/v1/branches) opcionális mezőin (shortName, phone, email) blank→null normalizálás + openingDate blank-toleráns deszerializálás.

**Architecture:** Ugyanaz a minta, mint az UpdateBranchDto-ban már bevált fix (commit 4cf0ebc6f): explicit Lombok-felülíró setterek blank→null normalizálással (a Jackson setter-úton deszerializál), és a `BlankTolerantLocalDateDeserializer` kiemelése top-level osztállyá, hogy mindkét DTO DRY módon használja. Create-nél NINCS clear-szemantika (nincs előző érték, amit törölni lehetne). A kötelező @NotBlank mezőkhöz (code, bankCode, name, address, city, zipCode) NEM nyúlunk — ott a "" elutasítása helyes viselkedés.

**Tech Stack:** Java 21, Spring Boot, Jackson, Jakarta Bean Validation (Hibernate Validator), JUnit 5 + AssertJ, Maven (backend/mvnw.cmd).

**Előzmény / gap-elemzés (2026-06-11):**
- ✅ KÉSZ (PR #1093, commit 4cf0ebc6f): UpdateBranchDto blank→null setterek + clear* jelzők + BlankTolerantLocalDateDeserializer; BranchService.update() törlés-ágak; UpdateBranchDtoValidationTest (8 teszt); BranchServiceTest bővítés.
- ✅ KÉSZ: CreateSimpleCashierBranchDto ellenőrizve — már blank-toleráns (zipCode `^(\d{4})?$`, phone csak @Size), nem kell módosítani (Scope OUT: más DTO-khoz nem nyúlunk).
- ❌ HIÁNYZIK (TBD#1): CreateBranchDto — `phone: ""` → @Pattern `^\+?[0-9\s\-\(\)]+$` nem illeszkedik üres stringre → 400; `openingDate: ""` → Jackson `HttpMessageNotReadableException` → kontextus nélküli 400; `shortName`/`email` "" tárolódna null helyett.
- Megjegyzés: a frontend BranchCreatePage a /simple-cashier végpontot használja és `undefined`-ot küld üres mezőre — a POST /api/v1/branches viszont publikus API-felület (Postman/integráció/jövőbeli kliens), a spec TBD#1 explicit kéri az ellenőrzést + javítást.

---

### Task 1: Branch létrehozása

**Files:** (nincs fájlmódosítás)

- [ ] **Step 1: Friss branch a main-ről**

```powershell
git -C D:\repo\valutavalto-program checkout -b feature/kozponti-fk025-create-dto-blank-fix main
```

Megjegyzés: a spec-beli `feature/kozponti-fk022-hotfix-dto-validation` branch már létezik az origin-en (merge-ölt PR #1093) — ütközés elkerülésére új, beszédes név.

- [ ] **Step 2: Baseline tesztek futtatása (zöldnek kell lennie)**

```powershell
cd D:\repo\valutavalto-program\backend
.\mvnw.cmd test "-Dtest=UpdateBranchDtoValidationTest,BranchServiceTest,BranchControllerTest" -q
```

Elvárt: BUILD SUCCESS, 0 failure.

### Task 2: Failing teszt — CreateBranchDtoValidationTest

**Files:**
- Create: `backend/src/test/java/hu/puzzleir/valuta/dto/CreateBranchDtoValidationTest.java`

- [ ] **Step 1: Tesztfájl megírása**

```java
package hu.puzzleir.valuta.dto;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-025 TBD#1: a spec "BranchCreateRequest.java"-ja ebben a repóban a CreateBranchDto
 * (POST /api/v1/branches). Az opcionális mezők (shortName, phone, email) üres stringként
 * ("") érkezve nem okozhatnak 400-at (blank → null normalizálás, az UpdateBranchDto
 * mintája — commit 4cf0ebc6f); az üres openingDate Jackson-hiba helyett tiszta Bean
 * Validation hibaüzenetet adjon (@NotNull). A kötelező @NotBlank mezők ""-elutasítása
 * változatlan marad.
 *
 * A teszt a VALÓS utat járja: Jackson deszerializáció (setter-alapú) + jakarta Validator.
 */
class CreateBranchDtoValidationTest {

    private static ObjectMapper objectMapper;
    private static ValidatorFactory validatorFactory;
    private static Validator validator;

    @BeforeAll
    static void setUp() {
        objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());
        // Codex P1 (#1093) minta: a factory a tesztek alatt nyitva marad, @AfterAll zárja.
        validatorFactory = Validation.buildDefaultValidatorFactory();
        validator = validatorFactory.getValidator();
    }

    @AfterAll
    static void tearDown() {
        validatorFactory.close();
    }

    /** Minden kötelező mező kitöltve, az opcionálisak üres stringként (programmatic kliens mintája). */
    private static final String EMPTY_OPTIONALS_JSON = """
            {
              "code": "BR099",
              "companyId": "00000000-0000-0000-0000-000000000010",
              "bankCode": "210",
              "branchTypeId": "00000000-0000-0000-0000-000000000001",
              "name": "BR099 Teszt Iroda",
              "address": "6722 Szeged, Teszt utca 1.",
              "city": "Szeged",
              "zipCode": "6722",
              "countryId": "00000000-0000-0000-0000-000000000002",
              "branchStatusId": "00000000-0000-0000-0000-000000000003",
              "openingDate": "2020-01-15",
              "shortName": "",
              "phone": "",
              "email": ""
            }
            """;

    @Test
    @DisplayName("TBD#1: üres opcionális mezők (shortName/phone/email) → 0 violation, null-ra normalizálva")
    void emptyOptionalStrings_areNormalizedToNull_andValid() throws Exception {
        CreateBranchDto dto = objectMapper.readValue(EMPTY_OPTIONALS_JSON, CreateBranchDto.class);

        assertThat(dto.getShortName()).isNull();
        assertThat(dto.getPhone()).isNull();
        assertThat(dto.getEmail()).isNull();

        Set<ConstraintViolation<CreateBranchDto>> violations = validator.validate(dto);
        assertThat(violations).isEmpty();
    }

    @Test
    @DisplayName("FR-5 analóg: érvénytelen telefonszám ('nem-szam-abc') továbbra is hibát ad")
    void invalidPhone_stillRejected() throws Exception {
        String json = EMPTY_OPTIONALS_JSON.replace("\"phone\": \"\"", "\"phone\": \"nem-szam-abc\"");
        CreateBranchDto dto = objectMapper.readValue(json, CreateBranchDto.class);

        Set<ConstraintViolation<CreateBranchDto>> violations = validator.validate(dto);
        assertThat(violations)
                .anySatisfy(v -> assertThat(v.getPropertyPath().toString()).isEqualTo("phone"));
    }

    @Test
    @DisplayName("FR-4 analóg: openingDate üres string → nincs Jackson-hiba, @NotNull ad tiszta hibaüzenetet")
    void blankOpeningDate_givesCleanNotNullViolation() throws Exception {
        String json = EMPTY_OPTIONALS_JSON.replace("\"openingDate\": \"2020-01-15\"", "\"openingDate\": \"\"");
        CreateBranchDto dto = objectMapper.readValue(json, CreateBranchDto.class);

        assertThat(dto.getOpeningDate()).isNull();
        Set<ConstraintViolation<CreateBranchDto>> violations = validator.validate(dto);
        assertThat(violations)
                .anySatisfy(v -> {
                    assertThat(v.getPropertyPath().toString()).isEqualTo("openingDate");
                    assertThat(v.getMessage()).isEqualTo("A nyitás dátuma kötelező");
                });
    }

    @Test
    @DisplayName("Érvényes openingDate parse-olódik; jövőbeli dátum továbbra is hibát ad (@PastOrPresent)")
    void openingDate_parsedAndFutureStillRejected() throws Exception {
        CreateBranchDto parsed = objectMapper.readValue(EMPTY_OPTIONALS_JSON, CreateBranchDto.class);
        assertThat(parsed.getOpeningDate()).isEqualTo(LocalDate.of(2020, 1, 15));

        String futureJson = EMPTY_OPTIONALS_JSON.replace("2020-01-15", LocalDate.now().plusDays(30).toString());
        CreateBranchDto future = objectMapper.readValue(futureJson, CreateBranchDto.class);
        assertThat(validator.validate(future))
                .anySatisfy(v -> assertThat(v.getPropertyPath().toString()).isEqualTo("openingDate"));
    }

    @Test
    @DisplayName("Érvényes opcionális értékek trimmelve maradnak meg")
    void validValues_areTrimmedAndKept() throws Exception {
        String json = EMPTY_OPTIONALS_JSON
                .replace("\"shortName\": \"\"", "\"shortName\": \" BR099 \"")
                .replace("\"phone\": \"\"", "\"phone\": \"  +36 30 123 4567  \"")
                .replace("\"email\": \"\"", "\"email\": \" teszt@example.hu \"");
        CreateBranchDto dto = objectMapper.readValue(json, CreateBranchDto.class);

        assertThat(dto.getShortName()).isEqualTo("BR099");
        assertThat(dto.getPhone()).isEqualTo("+36 30 123 4567");
        assertThat(dto.getEmail()).isEqualTo("teszt@example.hu");
        assertThat(validator.validate(dto)).isEmpty();
    }

    @Test
    @DisplayName("Kötelező mezők üres stringgel továbbra is hibát adnak (@NotBlank nem lazult)")
    void mandatoryBlankFields_stillRejected() throws Exception {
        String json = EMPTY_OPTIONALS_JSON
                .replace("\"code\": \"BR099\"", "\"code\": \"\"")
                .replace("\"bankCode\": \"210\"", "\"bankCode\": \"\"")
                .replace("\"name\": \"BR099 Teszt Iroda\"", "\"name\": \"\"")
                .replace("\"address\": \"6722 Szeged, Teszt utca 1.\"", "\"address\": \"\"")
                .replace("\"city\": \"Szeged\"", "\"city\": \"\"")
                .replace("\"zipCode\": \"6722\"", "\"zipCode\": \"\"");
        CreateBranchDto dto = objectMapper.readValue(json, CreateBranchDto.class);

        Set<ConstraintViolation<CreateBranchDto>> violations = validator.validate(dto);
        assertThat(violations.stream().map(v -> v.getPropertyPath().toString()))
                .contains("code", "bankCode", "name", "address", "city", "zipCode");
    }
}
```

- [ ] **Step 2: Futtatás — bukást várunk**

```powershell
cd D:\repo\valutavalto-program\backend
.\mvnw.cmd test "-Dtest=CreateBranchDtoValidationTest" -q
```

Elvárt: FAIL — `emptyOptionalStrings_areNormalizedToNull_andValid` (phone "" violation + mezők nem null-ok), `blankOpeningDate_givesCleanNotNullViolation` (Jackson parse exception), `validValues_areTrimmedAndKept` (nincs trim).

### Task 3: Deszerializáló kiemelése top-level osztállyá (DRY)

**Files:**
- Create: `backend/src/main/java/hu/puzzleir/valuta/dto/BlankTolerantLocalDateDeserializer.java`
- Modify: `backend/src/main/java/hu/puzzleir/valuta/dto/UpdateBranchDto.java` (beágyazott osztály törlése, importok takarítása)

- [ ] **Step 1: Új top-level deszerializáló**

```java
package hu.puzzleir.valuta.dto;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;

import java.io.IOException;
import java.time.LocalDate;

/**
 * FK-025: üres string ("") → null LocalDate mezőkre, hogy a Jackson ne dobjon
 * deszerializálási hibát (HttpMessageNotReadableException → kontextus nélküli 400).
 * Üres érték után a Bean Validation ad érthető hibaüzenetet (@NotNull mezőn), vagy
 * átengedi (opcionális mezőn). ISO-8601 formátum (pl. "2020-01-15").
 *
 * Eredetileg az UpdateBranchDto beágyazott osztálya volt (commit 4cf0ebc6f) — a
 * CreateBranchDto TBD#1 javításával közös használatra top-level osztályba került.
 */
public class BlankTolerantLocalDateDeserializer extends JsonDeserializer<LocalDate> {
    @Override
    public LocalDate deserialize(JsonParser p, DeserializationContext ctx) throws IOException {
        String value = p.getText();
        if (value == null || value.isBlank()) {
            return null;
        }
        return LocalDate.parse(value.trim());
    }
}
```

- [ ] **Step 2: UpdateBranchDto-ból a beágyazott osztály törlése**

Törlendő az `UpdateBranchDto.java`-ból (136-151. sor): a `BlankTolerantLocalDateDeserializer` beágyazott osztály a javadoc-jával együtt. A 137-139. sori magyarázat lényege átkerült az új top-level osztályba. Törlendő importok: `com.fasterxml.jackson.core.JsonParser`, `com.fasterxml.jackson.databind.DeserializationContext`, `com.fasterxml.jackson.databind.JsonDeserializer`, `java.io.IOException`. A `@JsonDeserialize(using = BlankTolerantLocalDateDeserializer.class)` hivatkozás változatlan (azonos package, azonos osztálynév).

- [ ] **Step 3: Regressziós futtatás**

```powershell
cd D:\repo\valutavalto-program\backend
.\mvnw.cmd test "-Dtest=UpdateBranchDtoValidationTest" -q
```

Elvárt: PASS (8 teszt zöld, a `blankOpeningDate_deserializesToNull` fedi a kiemelést).

### Task 4: CreateBranchDto javítás

**Files:**
- Modify: `backend/src/main/java/hu/puzzleir/valuta/dto/CreateBranchDto.java`

- [ ] **Step 1: blank→null setterek + openingDate deszerializáló**

A `CreateBranchDto.java`-ban:

1. Import hozzáadása: `com.fasterxml.jackson.databind.annotation.JsonDeserialize`
2. Az `openingDate` mezőre annotáció:

```java
    @NotNull(message = "A nyitás dátuma kötelező")
    @PastOrPresent(message = "A nyitás dátuma nem lehet jövőbeli")
    @JsonDeserialize(using = BlankTolerantLocalDateDeserializer.class)
    private LocalDate openingDate;
```

3. Az osztály végére (a V293 mezőblokk után):

```java
    // ========================================================================
    // FK-022 hotfix (FK-025 TBD#1): a spec "BranchCreateRequest"-je ebben a repóban ez a
    // DTO (POST /api/v1/branches). Az opcionális szövegmezők üres stringként ("") is
    // érkezhetnek (programmatic kliens) → blank → null normalizálás, hogy a @Pattern/@Email
    // ne utasítsa vissza (a null-t a Bean Validation átengedi) — az UpdateBranchDto
    // mintája (commit 4cf0ebc6f). Create-nél nincs clear-szemantika (nincs előző érték).
    // A kötelező @NotBlank mezőkhöz nem nyúlunk — ott a "" elutasítása a helyes viselkedés.
    // ========================================================================

    private static String blankToNull(String value) {
        return (value == null || value.isBlank()) ? null : value.trim();
    }

    public void setShortName(String shortName) {
        this.shortName = blankToNull(shortName);
    }

    public void setPhone(String phone) {
        this.phone = blankToNull(phone);
    }

    public void setEmail(String email) {
        this.email = blankToNull(email);
    }
```

- [ ] **Step 2: Új teszt futtatása — zöldet várunk**

```powershell
cd D:\repo\valutavalto-program\backend
.\mvnw.cmd test "-Dtest=CreateBranchDtoValidationTest" -q
```

Elvárt: PASS, 6 teszt zöld.

- [ ] **Step 3: A 4 érintett tesztosztály együtt**

```powershell
cd D:\repo\valutavalto-program\backend
.\mvnw.cmd test "-Dtest=CreateBranchDtoValidationTest,UpdateBranchDtoValidationTest,BranchServiceTest,BranchControllerTest" -q
```

Elvárt: BUILD SUCCESS, 0 failure.

### Task 5: Pipeline (Definition of Done) + commit

**Files:** (nincs új fájl)

- [ ] **Step 1: Repo-szintű kötelező dev-tool gate-ek (CLAUDE.md)**

```powershell
cd D:\repo\valutavalto-program
python scripts/dev-tools/blast-radius.py CreateBranchDto
python scripts/dev-tools/blast-radius.py UpdateBranchDto
.\scripts\dev-tools\typecheck-all.ps1
```

Elvárt: nincs váratlan érintettség (a CreateBranchDto-t a BranchService.create + BranchController használja), typecheck PASS.

- [ ] **Step 2: mvn verify**

```powershell
cd D:\repo\valutavalto-program\backend
.\mvnw.cmd verify -q
```

Elvárt: BUILD SUCCESS. (Checkstyle nincs a pom-ban — a lint gate-et a compile+verify fedi.)

- [ ] **Step 3: Secret-scan + tiltott annotáció grep**

```powershell
cd D:\repo\valutavalto-program
python scripts/dev-tools/secrets-deep-scan.py
git diff main --name-only | ForEach-Object { git diff main -- $_ } | Select-String "@Disabled|@Ignore|skip\("
```

Elvárt: secret-scan PASS, grep 0 találat az új kódon.

- [ ] **Step 4: Commit (magyar üzenet, repo-konvenció)**

```powershell
cd D:\repo\valutavalto-program
git add backend/src/main/java/hu/puzzleir/valuta/dto/CreateBranchDto.java backend/src/main/java/hu/puzzleir/valuta/dto/UpdateBranchDto.java backend/src/main/java/hu/puzzleir/valuta/dto/BlankTolerantLocalDateDeserializer.java backend/src/test/java/hu/puzzleir/valuta/dto/CreateBranchDtoValidationTest.java docs/superpowers/plans/2026-06-11-fk025-create-dto-blank-fix.md
git commit -m "fix(branches): FK-025 TBD#1 — CreateBranchDto üres opcionális mezők blank→null"
```

### Task 6: Code review + PR

- [ ] **Step 1: Code review a diffen** (a DoD "1 reviewer" gate-je): /code-review futtatása, findingok javítása, re-teszt.
- [ ] **Step 2: Push + PR létrehozása** (`gh pr create`), magyar leírással, FK-025 TBD#1 hivatkozással.
- [ ] **Step 3: Pre-push gate**

```powershell
cd D:\repo\valutavalto-program
.\scripts\dev-tools\pre-push-gate.ps1 -Fast
.\scripts\dev-tools\branch-hygiene.ps1
```

---

## Self-review (spec-lefedettség)

- Scope IN 1-2 (UpdateBranchDto + openingDate): már kész a main-en — Task 1 Step 2 baseline igazolja.
- Scope IN 3 (BranchCreateRequest ≙ CreateBranchDto): Task 2-4. ✅
- Scope IN 4 (UpdateBranchDtoValidationTest zöld): Task 1 Step 2 + Task 4 Step 3. ✅
- FR-1..FR-6: update-úton kész (meglévő tesztek); create-úton analóg esetek: Task 2 tesztjei. ✅
- NFR-2 (meglévő tesztek nem törnek): Task 4 Step 3 + Task 5 Step 2 (mvn verify). ✅
- Scope OUT betartva: frontend nem változik; CreateSimpleCashierBranchDto nem változik (ellenőrizve: már blank-toleráns); új mező nincs.
- Pipeline/DoD: Task 5-6 (lint→verify→secret-scan→grep→PR→review). Deploy/telepítő: a következő release-bump részeként (a v2.27.98 mintájára) — a kód-DoD-on kívüli kiadási lépés.
