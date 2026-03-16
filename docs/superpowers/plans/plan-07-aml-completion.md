# AML Completion Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the AML module: (1) add `highRiskFlag` to `Customer` entity and wire up `reverseAccumulation`, (2) integrate `SanctionScreeningService` into `checkTransaction`, (3) implement `submitToAuthority()` and `acknowledgeReport()` status transitions, (4) add a structured daily AML export method.

**Architecture:** Customer entity gets one new column (Flyway V90). AmlService gets three new public methods. A new `SanctionScreeningService` is introduced as a Spring `@Service` stub (real integration deferred). AmlReport lifecycle: `DRAFT → SUBMITTED → ACKNOWLEDGED`. Daily export returns structured XML/JSON.

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Context

- **AmlService:** `backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java`
- **AmlReport entity:** `backend/src/main/java/hu/puzzleir/valuta/entity/AmlReport.java`
  - has fields: `status` (AmlReportStatus), `submittedAt`, `acknowledgedAt`, `externalReference`, `reviewedBy`, `reviewedAt`
- **AmlReportStatus enum:** `backend/src/main/java/hu/puzzleir/valuta/entity/AmlReportStatus.java`
  - values: `DRAFT, SUBMITTED, ACKNOWLEDGED, FLAGGED`
- **Customer entity:** `backend/src/main/java/hu/puzzleir/valuta/entity/Customer.java`
  - has `isPep`, `isForeign`, `isVip` — **does NOT have `highRiskFlag`**
- **AmlReportRepository:** `backend/src/main/java/hu/puzzleir/valuta/repository/AmlReportRepository.java`
- **CustomerRepository:** `backend/src/main/java/hu/puzzleir/valuta/repository/CustomerRepository.java`
- **Migrations dir:** `backend/src/main/resources/db/migration/` — V89 reserved for plan-06

### Current bugs

1. **`reverseAccumulation()` line 794** — commented out `customer.setHighRiskFlag(false)` because the field does not exist on `Customer` entity.
2. **No sanction screening** — `checkTransaction()` javadoc mentions terrorist/sanction list check but it is completely absent from the implementation.
3. **AmlReport lifecycle incomplete** — `submitReport()` creates DRAFT records only; no `DRAFT → SUBMITTED` or `SUBMITTED → ACKNOWLEDGED` transition methods exist.
4. **No daily export** — authorities require a structured export of AML reports (XML per Hungarian MNB regulation, or JSON for internal systems).

---

## Task 1: Add highRiskFlag to Customer entity

### 1a: Flyway migration V90

- [ ] Create: `backend/src/main/resources/db/migration/V90__customer_high_risk_flag.sql`

```sql
-- V90: AML highRiskFlag column on customer
ALTER TABLE customer
    ADD COLUMN IF NOT EXISTS high_risk_flag BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS high_risk_reason VARCHAR(500),
    ADD COLUMN IF NOT EXISTS high_risk_set_at TIMESTAMP;

COMMENT ON COLUMN customer.high_risk_flag IS
    'AML: ügyfél magas kockázatú jelölés (BIGCTRL.DLL gongyolesi limit átlépésekor)';
```

### 1b: Add fields to Customer entity

- [ ] Edit: `backend/src/main/java/hu/puzzleir/valuta/entity/Customer.java`

Add after the `isPep` field (line ~234):

```java
/**
 * AML magas kockázatú jelölés.
 * Legacy: BIGCTRL.DLL — éves göngyölési limit (3.6M Ft) átlépésekor setHighRiskFlag(true).
 * reverseAccumulation: ha visszacsökken a limit alá → setHighRiskFlag(false).
 */
@Column(name = "high_risk_flag")
@Builder.Default
private Boolean highRiskFlag = false;

/**
 * Miért lett magas kockázatú
 */
@Column(name = "high_risk_reason", length = 500)
private String highRiskReason;

/**
 * Mikor lett megjelölve
 */
@Column(name = "high_risk_set_at")
private LocalDateTime highRiskSetAt;
```

### 1c: Fix reverseAccumulation in AmlService

- [ ] Edit: `backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java`

Replace the commented-out block in `reverseAccumulation()` (lines 790-797) with:

```java
if (customerOpt.isPresent()) {
    Customer customer = customerOpt.get();
    // Ha az éves összeg visszacsökken a limit alá → highRiskFlag törlése
    if (Boolean.TRUE.equals(customer.getHighRiskFlag())) {
        customer.setHighRiskFlag(false);
        customer.setHighRiskReason(null);
        customer.setHighRiskSetAt(null);
        customerRepository.save(customer);
        log.info("Ügyfél highRiskFlag törölve (göngyölés limit alá csökkent): {}", customerId);
    }
}
```

Also update the `checkTransaction()` and `classifyTransaction()` methods to SET the flag when the limit is crossed:

In `checkTransaction()`, after the `annualLimitReached` block (line ~131):
```java
// Ha a göngyölési limit átlépve → highRiskFlag beállítása
if (result.build().isAnnualLimitReached() && customerId != null && !customerId.isBlank()) {
    setHighRiskFlagIfNeeded(customerId, companyId,
        "Éves göngyölési limit (" + ANNUAL_ROLLING_LIMIT + " Ft) átlépve");
}
```

New helper method:
```java
private void setHighRiskFlagIfNeeded(String customerId, UUID companyId, String reason) {
    customerRepository.findByCustomerCodeAndCompanyId(customerId, companyId).ifPresent(customer -> {
        if (!Boolean.TRUE.equals(customer.getHighRiskFlag())) {
            customer.setHighRiskFlag(true);
            customer.setHighRiskReason(reason);
            customer.setHighRiskSetAt(LocalDateTime.now());
            customerRepository.save(customer);
            log.warn("Ügyfél highRiskFlag beállítva: customerId={}, reason={}", customerId, reason);
        }
    });
}
```

---

## Task 2: SanctionScreeningService stub + integration

### 2a: Create SanctionScreeningService

- [ ] Create: `backend/src/main/java/hu/puzzleir/valuta/service/SanctionScreeningService.java`

```java
package hu.puzzleir.valuta.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Szankciós lista és terrorlista ellenőrzés.
 *
 * Legacy: BIGCTRL.DLL — terrorlista ellenőrzés (javadocban szerepelt, de nem volt implementálva).
 *
 * Jelenlegi implementáció: STUB — mindig "nem szerepel" eredményt ad.
 * Jövőbeli fejlesztés: EU Financial Sanctions Files (European External Action Service)
 * és OFAC SDN List integrációja.
 *
 * URL: https://webgate.ec.europa.eu/fsd/fsf
 */
@Service
@Slf4j
public class SanctionScreeningService {

    /**
     * Ellenőrzi, hogy az ügyfél szerepel-e szankciós/terrorlistán.
     *
     * @param fullName       ügyfél teljes neve
     * @param documentNumber okmányszám (opcionális)
     * @param nationality    állampolgárság (opcionális, ISO 3-letter)
     * @return SanctionCheckResult
     */
    public SanctionCheckResult checkPerson(String fullName, String documentNumber, String nationality) {
        if (fullName == null || fullName.isBlank()) {
            return SanctionCheckResult.builder()
                .matched(false)
                .message("Névhiány — szankciós ellenőrzés kihagyva")
                .build();
        }

        // TODO: Implementálni az EU FSF és OFAC SDN lista lekérdezését
        // Jelenleg STUB: minden ügyfél "clear"
        log.debug("Szankciós ellenőrzés (STUB): name={}, doc={}", fullName, documentNumber);

        return SanctionCheckResult.builder()
            .matched(false)
            .screenedName(fullName)
            .message("Szankciós lista ellenőrzés nem elérhető (stub)")
            .stubMode(true)
            .build();
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class SanctionCheckResult {
        private boolean matched;           // true = szerepel a listán → BLOKKOLÁS
        private String screenedName;
        private String matchedListEntry;   // a listabejegyzés ha matched=true
        private String listSource;         // "EU_FSF" / "OFAC_SDN" / stb.
        private String message;
        private boolean stubMode;          // true = nem valós ellenőrzés
    }
}
```

### 2b: Inject SanctionScreeningService into AmlService and call from checkTransaction

- [ ] Edit: `backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java`

Add to injected fields:
```java
private final SanctionScreeningService sanctionScreeningService;
```

In `checkTransaction()`, add sanction check as the FIRST check (before identification limit check):

```java
// 0. Szankciós lista / terrorlista ellenőrzés
if (customerName != null && !customerName.isBlank()) {
    SanctionScreeningService.SanctionCheckResult sanction =
        sanctionScreeningService.checkPerson(customerName, documentNumber, null);
    if (sanction.isMatched()) {
        log.error("AML KRITIKUS: Ügyfél szankciós listán szerepel! name={}, forrás={}",
            customerName, sanction.getListSource());
        return AmlBasicCheckResult.builder()
            .approved(false)
            .rejectionReason("SZANKCIÓS LISTA: Az ügyfél terrorfinanszírozási / szankciós " +
                "listán szerepel. Tranzakció MEGTAGADVA. Értesítse a compliance osztályt!")
            .suspiciousFlag(true)
            .build();
    }
    if (!sanction.isStubMode()) {
        log.info("AML szankciós ellenőrzés: name={} — nem szerepel a listán", customerName);
    }
}
```

---

## Task 3: AML report status transitions

- [ ] Edit: `backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java`

### 3a: submitToAuthority()

```java
/**
 * AML bejelentés hatósághoz küldése (DRAFT → SUBMITTED).
 *
 * 2017. évi LIII. tv. 30. §: bejelentési kötelezettség teljesítése.
 * Supervisor vagy COMPLIANCE_OFFICER szerepkör szükséges.
 *
 * @param reportId AML bejelentés UUID
 * @param externalReference a hatóság által adott hivatkozási szám (opcionális)
 */
@Transactional
public AmlReportDto submitToAuthority(UUID reportId, String externalReference) {
    UUID companyId = SecurityUtils.getCurrentCompanyId();
    String workerCode = SecurityUtils.getCurrentWorkerCode();

    AmlReport report = amlReportRepository.findById(reportId)
        .orElseThrow(() -> new ResourceNotFoundException("AML bejelentés nem található: " + reportId));

    // Multi-tenant ellenőrzés
    if (!report.getCompany().getId().equals(companyId)) {
        throw new ValidationException("Nincs jogosultsága ehhez a bejelentéshez!");
    }

    if (report.getStatus() != AmlReportStatus.DRAFT) {
        throw new ValidationException(
            "Csak DRAFT státuszú bejelentés küldhető be! Jelenlegi: " + report.getStatus());
    }

    report.setStatus(AmlReportStatus.SUBMITTED);
    report.setSubmittedAt(LocalDateTime.now());
    report.setReviewedBy(workerCode);
    report.setReviewedAt(LocalDateTime.now());
    if (externalReference != null && !externalReference.isBlank()) {
        report.setExternalReference(externalReference);
    }

    AmlReport saved = amlReportRepository.save(report);
    auditLogService.log("AML_SUBMITTED",
        "AML bejelentés hatósághoz beküldve: id=" + reportId +
        ", type=" + report.getReportType() + ", ref=" + externalReference,
        report.getCustomerId());
    log.info("AML bejelentés beküldve: id={}, type={}, by={}", reportId, report.getReportType(), workerCode);
    return toDto(saved);
}
```

### 3b: acknowledgeReport()

```java
/**
 * AML bejelentés hatósági visszaigazolása (SUBMITTED → ACKNOWLEDGED).
 *
 * @param reportId          AML bejelentés UUID
 * @param externalReference hatóság által adott hivatkozási szám
 */
@Transactional
public AmlReportDto acknowledgeReport(UUID reportId, String externalReference) {
    UUID companyId = SecurityUtils.getCurrentCompanyId();
    String workerCode = SecurityUtils.getCurrentWorkerCode();

    AmlReport report = amlReportRepository.findById(reportId)
        .orElseThrow(() -> new ResourceNotFoundException("AML bejelentés nem található: " + reportId));

    if (!report.getCompany().getId().equals(companyId)) {
        throw new ValidationException("Nincs jogosultsága ehhez a bejelentéshez!");
    }

    if (report.getStatus() != AmlReportStatus.SUBMITTED) {
        throw new ValidationException(
            "Csak SUBMITTED státuszú bejelentés nyugtázható! Jelenlegi: " + report.getStatus());
    }

    report.setStatus(AmlReportStatus.ACKNOWLEDGED);
    report.setAcknowledgedAt(LocalDateTime.now());
    if (externalReference != null && !externalReference.isBlank()) {
        report.setExternalReference(externalReference);
    }

    AmlReport saved = amlReportRepository.save(report);
    auditLogService.log("AML_ACKNOWLEDGED",
        "AML bejelentés visszaigazolva: id=" + reportId + ", ref=" + externalReference,
        report.getCustomerId());
    log.info("AML bejelentés visszaigazolva: id={}, ref={}, by={}", reportId, externalReference, workerCode);
    return toDto(saved);
}
```

### 3c: Add AmlReportRepository queries needed for transitions

- [ ] Edit: `backend/src/main/java/hu/puzzleir/valuta/repository/AmlReportRepository.java`

Ensure these methods exist (add if missing):

```java
@Query("SELECT r FROM AmlReport r WHERE r.company.id = :companyId AND r.id = :id")
Optional<AmlReport> findByIdAndCompanyId(@Param("id") UUID id, @Param("companyId") UUID companyId);

List<AmlReport> findByCompanyIdAndStatus(UUID companyId, AmlReportStatus status);
```

---

## Task 4: Structured daily AML export

- [ ] Edit `AmlService.java` — add export method

### DTO for export

- [ ] Create: `backend/src/main/java/hu/puzzleir/valuta/dto/aml/AmlDailyExportDto.java`

```java
package hu.puzzleir.valuta.dto.aml;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Napi AML export DTO — hatósági bejelentéshez.
 * Formátum: JSON (belső) vagy XML (MNB hatóság).
 */
@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class AmlDailyExportDto {

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate exportDate;

    private String companyId;
    private String companyName;

    private int totalReports;
    private int draftCount;
    private int submittedCount;
    private int acknowledgedCount;
    private int flaggedCount;

    private BigDecimal totalAmountHuf;

    private List<AmlExportEntryDto> entries;

    @Data @Builder @NoArgsConstructor @AllArgsConstructor
    public static class AmlExportEntryDto {
        private String reportId;
        private String reportType;
        private String riskLevel;
        private String status;
        private String customerId;
        private String customerName;
        private String documentType;
        private String documentNumber;
        private BigDecimal amountHuf;
        private String currencyCode;
        private BigDecimal originalAmount;
        private String workerNotes;
        private String externalReference;
        @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
        private java.time.LocalDateTime createdAt;
        @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
        private java.time.LocalDateTime submittedAt;
    }
}
```

### Export method in AmlService

```java
/**
 * Napi AML export generálása — hatósági bejelentéshez.
 *
 * 2017. évi LIII. tv. 38. §: nyilvántartási és adatszolgáltatási kötelezettség.
 * Az export tartalmazza az adott nap összes AML bejelentését.
 *
 * @param date export dátuma
 * @return AmlDailyExportDto — JSON/XML alapjául
 */
@Transactional(readOnly = true)
public AmlDailyExportDto generateDailyExport(LocalDate date) {
    UUID companyId = SecurityUtils.getCurrentCompanyId();
    LocalDateTime from = date.atStartOfDay();
    LocalDateTime to = date.atTime(LocalTime.MAX);

    List<AmlReport> reports = amlReportRepository.findByCompanyIdAndDateRange(companyId, from, to);

    // Cég neve (company névből kell — egyszerűsítés: companyId string-ként)
    int draft = 0, submitted = 0, acknowledged = 0, flagged = 0;
    BigDecimal total = BigDecimal.ZERO;

    List<AmlDailyExportDto.AmlExportEntryDto> entries = new ArrayList<>();

    for (AmlReport r : reports) {
        switch (r.getStatus()) {
            case DRAFT        -> draft++;
            case SUBMITTED    -> submitted++;
            case ACKNOWLEDGED -> acknowledged++;
            case FLAGGED      -> flagged++;
        }
        total = total.add(r.getAmountHuf() != null ? r.getAmountHuf() : BigDecimal.ZERO);

        entries.add(AmlDailyExportDto.AmlExportEntryDto.builder()
            .reportId(r.getId().toString())
            .reportType(r.getReportType().name())
            .riskLevel(r.getRiskLevel().name())
            .status(r.getStatus().name())
            .customerId(r.getCustomerId())
            .customerName(r.getCustomerName())
            .documentType(r.getDocumentType())
            .documentNumber(r.getDocumentNumber())
            .amountHuf(r.getAmountHuf())
            .currencyCode(r.getCurrencyCode())
            .originalAmount(r.getOriginalAmount())
            .workerNotes(r.getWorkerNotes())
            .externalReference(r.getExternalReference())
            .createdAt(r.getCreatedAt())
            .submittedAt(r.getSubmittedAt())
            .build());
    }

    return AmlDailyExportDto.builder()
        .exportDate(date)
        .companyId(companyId.toString())
        .totalReports(reports.size())
        .draftCount(draft)
        .submittedCount(submitted)
        .acknowledgedCount(acknowledged)
        .flaggedCount(flagged)
        .totalAmountHuf(total)
        .entries(entries)
        .build();
}
```

---

## TDD Steps

### Test file location
`backend/src/test/java/hu/puzzleir/valuta/service/AmlServiceTest.java`

### Test cases

- [ ] **T1: highRiskFlag SET on annual limit breach** — when `checkTransaction` detects annual limit exceeded and customer exists, `customer.getHighRiskFlag()` becomes true
- [ ] **T2: reverseAccumulation clears highRiskFlag** — when year total drops below 3.6M after reversal, highRiskFlag is set to false
- [ ] **T3: sanction match blocks transaction** — when `sanctionScreeningService.checkPerson` returns `matched=true`, result is `approved=false`
- [ ] **T4: submitToAuthority DRAFT→SUBMITTED** — status becomes SUBMITTED, submittedAt is non-null
- [ ] **T5: submitToAuthority rejects non-DRAFT** — throws ValidationException when status=SUBMITTED
- [ ] **T6: acknowledgeReport SUBMITTED→ACKNOWLEDGED** — status becomes ACKNOWLEDGED, acknowledgedAt is non-null
- [ ] **T7: acknowledgeReport rejects non-SUBMITTED** — throws ValidationException when status=DRAFT
- [ ] **T8: generateDailyExport entry count** — export entries count equals mock report count
- [ ] **T9: multi-tenant guard on submitToAuthority** — throws ValidationException when report belongs to different company

```java
@Test
void submitToAuthority_draftBecomesSubmitted() {
    UUID companyId = UUID.randomUUID();
    UUID reportId = UUID.randomUUID();
    AmlReport report = AmlReport.builder()
        .id(reportId).status(AmlReportStatus.DRAFT)
        .reportType(AmlReportType.STANDARD).riskLevel(AmlRiskLevel.LOW)
        .amountHuf(BigDecimal.ZERO).build();
    Company company = new Company(); company.setId(companyId);
    report.setCompany(company);

    when(amlReportRepository.findById(reportId)).thenReturn(Optional.of(report));
    when(SecurityUtils.getCurrentCompanyId()).thenReturn(companyId); // static mock with Mockito 5
    when(amlReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    AmlReportDto result = amlService.submitToAuthority(reportId, "REF-001");

    assertEquals("SUBMITTED", result.getStatus());
    assertNotNull(result.getSubmittedAt());
}
```

---

## Test commands

```bash
cd backend
./mvnw test -Dtest=AmlServiceTest -q
```

---

## Commit message

```
feat(aml): highRiskFlag on Customer, sanction screening stub, report lifecycle, daily export

- V90 migration: customer.high_risk_flag + high_risk_reason + high_risk_set_at
- reverseAccumulation: actually clears highRiskFlag when annual total drops below limit
- SanctionScreeningService: stub service (EU FSF / OFAC SDN — real integration deferred)
- checkTransaction: calls sanctionScreeningService; hard-blocks on match
- submitToAuthority(): DRAFT → SUBMITTED transition with audit log
- acknowledgeReport(): SUBMITTED → ACKNOWLEDGED transition with external reference
- generateDailyExport(): structured AmlDailyExportDto for authority submission

Fixes: commented-out highRiskFlag, missing sanction check, lifecycle dead-end
```
