# MNB Report Submit Implementation Plan
> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the placeholder `MnbReportService.submitReport()` with a real HTTP-based MNB API client, add proper status flow (DRAFT → SUBMITTED → ACKNOWLEDGED → REJECTED), fix XML to be MNB XSD compliant, add retry logic for failed submissions, and implement weekly report generation.

**Architecture:** New `MnbApiClient` Spring `@Service` wraps a `RestTemplate`/`WebClient`. The endpoint URL and credentials are read from `SystemParameterService` at runtime (no hardcoded config). Retry is handled via `@Retryable` (Spring Retry) or a manual exponential-backoff loop stored in the `MnbReport` entity's `retryCount` / `lastRetryAt` fields. A Flyway migration adds the necessary columns and the `WEEKLY` report type. Weekly generation reuses the existing daily aggregation logic over a 7-day window.

**Tech Stack:** Java 21, Spring Boot 3.2, JPA, PostgreSQL, JUnit 5

---

## Priority & Context

- **Priority:** P2-MEDIUM
- **Jogszabályi háttér:** 32/2010 MNB rendelet — pénzváltók kötelező adatszolgáltatása
- **Érintett fájlok:**
  - `backend/src/main/java/hu/puzzleir/valuta/service/MnbReportService.java` (fő módosítás)
  - `backend/src/main/java/hu/puzzleir/valuta/service/MnbApiClient.java` (ÚJ)
  - `backend/src/main/java/hu/puzzleir/valuta/entity/MnbReport.java` (új mezők)
  - `backend/src/main/java/hu/puzzleir/valuta/entity/MnbReportType.java` (WEEKLY hozzáadás)
  - `backend/src/main/resources/db/migration/V89__mnb_report_weekly_and_retry.sql` (ÚJ)
  - `backend/src/test/java/hu/puzzleir/valuta/service/MnbReportServiceTest.java` (bővítés)
  - `backend/src/test/java/hu/puzzleir/valuta/service/MnbApiClientTest.java` (ÚJ)

---

## Task 1: MnbApiClient service létrehozása

### 1.1 TDD — Teszt előbb

- [ ] Nyisd meg: `backend/src/test/java/hu/puzzleir/valuta/service/MnbApiClientTest.java` (ÚJ fájl)
- [ ] Írj tesztet arra, hogy `submitXml()` sikeres HTTP 200 esetén `MnbSubmissionResult.success=true` és a válasz törzséből kinyeri a `referenceNumber`-t:

```java
@ExtendWith(MockitoExtension.class)
class MnbApiClientTest {

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private SystemParameterService systemParameterService;

    @InjectMocks
    private MnbApiClient mnbApiClient;

    @Test
    @DisplayName("submitXml: HTTP 200 → success=true, referenceNumber visszaadva")
    void submitXml_success() {
        when(systemParameterService.getValue("MNB_API_URL"))
            .thenReturn("https://mnb-test.example.com/api/report");
        when(systemParameterService.getValue("MNB_API_TOKEN"))
            .thenReturn("test-token-abc");

        ResponseEntity<String> mockResponse = ResponseEntity.ok(
            "<SubmissionResponse><ReferenceNumber>MNB-2026-00123</ReferenceNumber>" +
            "<Status>ACCEPTED</Status></SubmissionResponse>"
        );
        when(restTemplate.exchange(anyString(), eq(HttpMethod.POST), any(HttpEntity.class), eq(String.class)))
            .thenReturn(mockResponse);

        MnbSubmissionResult result = mnbApiClient.submitXml("<MNBReport>...</MNBReport>", "DAILY");

        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getReferenceNumber()).isEqualTo("MNB-2026-00123");
        assertThat(result.getErrorMessage()).isNull();
    }

    @Test
    @DisplayName("submitXml: HTTP 500 → success=false, errorMessage set")
    void submitXml_serverError() {
        when(systemParameterService.getValue("MNB_API_URL"))
            .thenReturn("https://mnb-test.example.com/api/report");
        when(systemParameterService.getValue("MNB_API_TOKEN"))
            .thenReturn("test-token-abc");

        when(restTemplate.exchange(anyString(), eq(HttpMethod.POST), any(HttpEntity.class), eq(String.class)))
            .thenThrow(new HttpServerErrorException(HttpStatus.INTERNAL_SERVER_ERROR, "Server Error"));

        MnbSubmissionResult result = mnbApiClient.submitXml("<MNBReport>...</MNBReport>", "DAILY");

        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getErrorMessage()).contains("500");
    }

    @Test
    @DisplayName("submitXml: MNB_API_URL hiányzik → ValidationException")
    void submitXml_missingUrl() {
        when(systemParameterService.getValue("MNB_API_URL"))
            .thenThrow(new ResourceNotFoundException("SystemParameter not found: MNB_API_URL"));

        assertThatThrownBy(() -> mnbApiClient.submitXml("<xml/>", "DAILY"))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("MNB_API_URL");
    }
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=MnbApiClientTest` → PIROS (osztály nem létezik)

### 1.2 Implementáció

- [ ] Hozd létre: `backend/src/main/java/hu/puzzleir/valuta/service/MnbApiClient.java`

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.mnb.MnbSubmissionResult;
import hu.puzzleir.valuta.exception.ValidationException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;

/**
 * MNB API kliens — valós HTTP beküldés.
 *
 * Az endpoint URL és token a SystemParameter táblából jön:
 *   MNB_API_URL  — pl. https://mnbgyujto.mnb.hu/api/submit
 *   MNB_API_TOKEN — Bearer token (MNB által kiadott)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class MnbApiClient {

    private final RestTemplate restTemplate;
    private final SystemParameterService systemParameterService;

    /**
     * XML beküldése az MNB API-nak.
     *
     * @param xmlContent MNB-kompatibilis XML tartalom
     * @param reportType Riport típus (DAILY/WEEKLY/MONTHLY) — csak loghoz
     * @return MnbSubmissionResult (success, referenceNumber, errorMessage)
     */
    public MnbSubmissionResult submitXml(String xmlContent, String reportType) {
        String apiUrl;
        String apiToken;

        try {
            apiUrl = systemParameterService.getValue("MNB_API_URL");
            apiToken = systemParameterService.getValue("MNB_API_TOKEN");
        } catch (Exception e) {
            throw new ValidationException("MNB_API_URL vagy MNB_API_TOKEN SystemParameter hiányzik: " + e.getMessage());
        }

        if (apiUrl == null || apiUrl.isBlank()) {
            throw new ValidationException("MNB_API_URL SystemParameter üres!");
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_XML);
        headers.setBearerAuth(apiToken != null ? apiToken : "");
        HttpEntity<String> entity = new HttpEntity<>(xmlContent, headers);

        log.info("MNB API beküldés: url={}, reportType={}", apiUrl, reportType);

        try {
            ResponseEntity<String> response = restTemplate.exchange(
                apiUrl, HttpMethod.POST, entity, String.class);

            String body = response.getBody();
            String referenceNumber = parseReferenceNumber(body);

            log.info("MNB API siker: referenceNumber={}", referenceNumber);
            return MnbSubmissionResult.builder()
                .success(true)
                .referenceNumber(referenceNumber)
                .build();

        } catch (HttpStatusCodeException e) {
            String error = "HTTP " + e.getStatusCode() + ": " + e.getResponseBodyAsString();
            log.error("MNB API hiba: {}", error);
            return MnbSubmissionResult.builder()
                .success(false)
                .errorMessage(error)
                .build();
        } catch (Exception e) {
            log.error("MNB API kommunikációs hiba: {}", e.getMessage(), e);
            return MnbSubmissionResult.builder()
                .success(false)
                .errorMessage("Kommunikációs hiba: " + e.getMessage())
                .build();
        }
    }

    /** XML válaszból kinyeri a ReferenceNumber elemet. */
    private String parseReferenceNumber(String xml) {
        if (xml == null) return null;
        int start = xml.indexOf("<ReferenceNumber>");
        int end = xml.indexOf("</ReferenceNumber>");
        if (start >= 0 && end > start) {
            return xml.substring(start + "<ReferenceNumber>".length(), end).trim();
        }
        return null;
    }
}
```

- [ ] Regisztráld a `RestTemplate` bean-t (ha még nincs) a `WebConfig` vagy egy külön `RestTemplateConfig` osztályban:

```java
// backend/src/main/java/hu/puzzleir/valuta/config/RestTemplateConfig.java
@Configuration
public class RestTemplateConfig {
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=MnbApiClientTest` → ZÖLD

---

## Task 2: Státusz flow implementálás (DRAFT → SUBMITTED → ACKNOWLEDGED → REJECTED)

### 2.1 Flyway migráció

- [ ] Hozd létre: `backend/src/main/resources/db/migration/V89__mnb_report_weekly_and_retry.sql`

```sql
-- MNB riport: retry mezők és WEEKLY típus
ALTER TABLE mnb_report
    ADD COLUMN IF NOT EXISTS retry_count        INTEGER     NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_retry_at      TIMESTAMP,
    ADD COLUMN IF NOT EXISTS mnb_reference_number VARCHAR(64),
    ADD COLUMN IF NOT EXISTS submission_error   TEXT,
    ADD COLUMN IF NOT EXISTS acknowledged_at    TIMESTAMP,
    ADD COLUMN IF NOT EXISTS rejected_at        TIMESTAMP,
    ADD COLUMN IF NOT EXISTS rejection_reason   TEXT;

-- WEEKLY enum value (ha string-ként tárolva)
-- Ha a report_type oszlop CHECK constraint-et használ, frissíteni kell:
-- ALTER TABLE mnb_report DROP CONSTRAINT IF EXISTS mnb_report_report_type_check;
-- ALTER TABLE mnb_report ADD CONSTRAINT mnb_report_report_type_check
--     CHECK (report_type IN ('DAILY', 'WEEKLY', 'MONTHLY'));

COMMENT ON COLUMN mnb_report.retry_count IS 'Hányszor próbálta beküldeni sikertelen után';
COMMENT ON COLUMN mnb_report.mnb_reference_number IS 'MNB által visszaadott referenciaszám sikeres beküldésnél';
COMMENT ON COLUMN mnb_report.submission_error IS 'Utolsó beküldési hiba szövege';
```

### 2.2 Entitás frissítés

- [ ] Nyisd meg: `backend/src/main/java/hu/puzzleir/valuta/entity/MnbReport.java`
- [ ] Add hozzá a következő mezőket (Lombok `@Builder.Default` ahol szükséges):

```java
@Column(name = "retry_count", nullable = false)
@Builder.Default
private Integer retryCount = 0;

@Column(name = "last_retry_at")
private LocalDateTime lastRetryAt;

@Column(name = "mnb_reference_number", length = 64)
private String mnbReferenceNumber;

@Column(name = "submission_error", columnDefinition = "TEXT")
private String submissionError;

@Column(name = "acknowledged_at")
private LocalDateTime acknowledgedAt;

@Column(name = "rejected_at")
private LocalDateTime rejectedAt;

@Column(name = "rejection_reason", columnDefinition = "TEXT")
private String rejectionReason;
```

- [ ] Frissítsd: `backend/src/main/java/hu/puzzleir/valuta/entity/MnbReportType.java`

```java
public enum MnbReportType {
    DAILY,
    WEEKLY,  // ← ÚJ
    MONTHLY
}
```

### 2.3 submitReport() implementálás

- [ ] Nyisd meg: `backend/src/main/java/hu/puzzleir/valuta/service/MnbReportService.java`
- [ ] Add `MnbApiClient` függőséget a konstruktorhoz (Lombok `@RequiredArgsConstructor` kezeli)
- [ ] Cseréld le a `submitReport()` metódust:

```java
/**
 * Riport beküldése az MNB-nek.
 * Státusz flow: DRAFT → SUBMITTED → (ACKNOWLEDGED | REJECTED)
 */
public MnbSubmissionResult submitReport(UUID reportId) {
    MnbReport report = mnbReportRepository.findById(reportId)
        .orElseThrow(() -> new ResourceNotFoundException("MNB riport nem található: " + reportId));

    if (report.getStatus() != MnbReportStatus.DRAFT) {
        throw new ValidationException(
            "Csak DRAFT státuszú riport küldhető be! Jelenlegi: " + report.getStatus());
    }

    log.info("MNB riport beküldés: reportId={}, type={}", reportId, report.getReportType());

    // SUBMITTED státusz beállítása azonnal (optimista: ha a hálózat elszakad, látszik)
    report.setStatus(MnbReportStatus.SUBMITTED);
    report.setSubmittedAt(LocalDateTime.now());
    mnbReportRepository.save(report);

    // Tényleges HTTP beküldés
    MnbSubmissionResult result = mnbApiClient.submitXml(
        report.getXmlContent(), report.getReportType().name());

    if (result.isSuccess()) {
        report.setMnbReferenceNumber(result.getReferenceNumber());
        report.setStatus(MnbReportStatus.ACKNOWLEDGED);
        report.setAcknowledgedAt(LocalDateTime.now());
        report.setSubmissionError(null);
    } else {
        report.setStatus(MnbReportStatus.REJECTED);
        report.setRejectedAt(LocalDateTime.now());
        report.setRejectionReason(result.getErrorMessage());
        report.setSubmissionError(result.getErrorMessage());
    }

    mnbReportRepository.save(report);

    log.info("MNB riport beküldés eredmény: success={}, ref={}, status={}",
        result.isSuccess(), result.getReferenceNumber(), report.getStatus());

    return result;
}
```

- [ ] Frissítsd az `MnbReportStatus` enum-ot (ha `ACKNOWLEDGED`/`REJECTED` hiányzik):

```java
public enum MnbReportStatus {
    DRAFT,
    SUBMITTED,
    ACKNOWLEDGED,  // ← ÚJ (MNB visszaigazolta)
    REJECTED       // ← ÚJ (MNB visszautasította)
}
```

### 2.4 Tesztek

- [ ] Nyisd meg: `backend/src/test/java/hu/puzzleir/valuta/service/MnbReportServiceTest.java`
- [ ] Add hozzá:

```java
@Mock
private MnbApiClient mnbApiClient;

@Test
@DisplayName("submitReport: siker → ACKNOWLEDGED státusz, referenceNumber mentve")
void submitReport_success_acknowledged() {
    MnbReport draftReport = MnbReport.builder()
        .id(UUID.randomUUID())
        .status(MnbReportStatus.DRAFT)
        .reportType(MnbReportType.DAILY)
        .xmlContent("<MNBReport/>")
        .build();

    when(mnbReportRepository.findById(any())).thenReturn(Optional.of(draftReport));
    when(mnbApiClient.submitXml(any(), any()))
        .thenReturn(MnbSubmissionResult.builder()
            .success(true).referenceNumber("MNB-2026-00999").build());
    when(mnbReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    MnbSubmissionResult result = mnbReportService.submitReport(draftReport.getId());

    assertThat(result.isSuccess()).isTrue();
    assertThat(result.getReferenceNumber()).isEqualTo("MNB-2026-00999");
    assertThat(draftReport.getStatus()).isEqualTo(MnbReportStatus.ACKNOWLEDGED);
    assertThat(draftReport.getMnbReferenceNumber()).isEqualTo("MNB-2026-00999");
}

@Test
@DisplayName("submitReport: MNB visszautasítja → REJECTED státusz")
void submitReport_failed_rejected() {
    MnbReport draftReport = MnbReport.builder()
        .id(UUID.randomUUID())
        .status(MnbReportStatus.DRAFT)
        .reportType(MnbReportType.DAILY)
        .xmlContent("<MNBReport/>")
        .build();

    when(mnbReportRepository.findById(any())).thenReturn(Optional.of(draftReport));
    when(mnbApiClient.submitXml(any(), any()))
        .thenReturn(MnbSubmissionResult.builder()
            .success(false).errorMessage("HTTP 422: Invalid XML schema").build());
    when(mnbReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    MnbSubmissionResult result = mnbReportService.submitReport(draftReport.getId());

    assertThat(result.isSuccess()).isFalse();
    assertThat(draftReport.getStatus()).isEqualTo(MnbReportStatus.REJECTED);
    assertThat(draftReport.getRejectionReason()).contains("422");
}

@Test
@DisplayName("submitReport: nem DRAFT → ValidationException")
void submitReport_notDraft_throws() {
    MnbReport submitted = MnbReport.builder()
        .id(UUID.randomUUID())
        .status(MnbReportStatus.SUBMITTED)
        .build();
    when(mnbReportRepository.findById(any())).thenReturn(Optional.of(submitted));

    assertThatThrownBy(() -> mnbReportService.submitReport(submitted.getId()))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("DRAFT");
}
```

- [ ] Futtasd: `cd backend && ./mvnw test -Dtest=MnbReportServiceTest` → ZÖLD

---

## Task 3: MNB XML XSD-kompatibilitás

### 3.1 Az MNB elvárás szerint az XML struktúra

Az MNB Gyűjtő rendszer (mnbgyujto) a következő XSD-t várja (32/2010 MNB rendelet melléklete alapján):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Jelentes xmlns="http://www.mnb.hu/penzvaltok/2010"
          AdoSzam="12345678-1-11"
          Datum="2026-03-16"
          TipusKod="N">          <!-- N=napi, H=heti, M=havi -->
  <Devizanem KodIso="EUR">
    <Vetel>
      <Osszeg>5000.00</Osszeg>
      <Arfolyam>390.50</Arfolyam>
    </Vetel>
    <Eladas>
      <Osszeg>3000.00</Osszeg>
      <Arfolyam>396.20</Arfolyam>
    </Eladas>
  </Devizanem>
</Jelentes>
```

- [ ] Nyisd meg: `MnbReportService.java` → `generateMnbXml()` metódus
- [ ] Cseréld le a teljes metódust:

```java
/**
 * MNB XSD-kompatibilis XML generálása (32/2010 MNB rendelet).
 * Namespace: http://www.mnb.hu/penzvaltok/2010
 * TipusKod: N=napi, H=heti, M=havi
 */
private String generateMnbXml(MnbReport report, Branch branch) {
    String taxId = resolveTaxId();

    String tipusKod = switch (report.getReportType()) {
        case DAILY   -> "N";
        case WEEKLY  -> "H";
        case MONTHLY -> "M";
    };

    // Riport időszak vége
    String datum = report.getReportDate().toString();

    StringBuilder xml = new StringBuilder();
    xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    xml.append("<Jelentes xmlns=\"http://www.mnb.hu/penzvaltok/2010\"");
    xml.append(" AdoSzam=\"").append(escapeXml(taxId)).append("\"");
    xml.append(" Datum=\"").append(datum).append("\"");
    xml.append(" TipusKod=\"").append(tipusKod).append("\"");
    xml.append(" IrodaKod=\"").append(escapeXml(branch.getCode())).append("\"");
    xml.append(">\n");

    for (MnbReportLine line : report.getLines()) {
        xml.append("  <Devizanem KodIso=\"").append(escapeXml(line.getCurrencyCode())).append("\">\n");

        if (line.getBuyAmount().compareTo(BigDecimal.ZERO) > 0) {
            xml.append("    <Vetel>\n");
            xml.append("      <Osszeg>").append(line.getBuyAmount().setScale(2, RoundingMode.HALF_UP)).append("</Osszeg>\n");
            xml.append("      <Arfolyam>").append(line.getBuyRate().setScale(4, RoundingMode.HALF_UP)).append("</Arfolyam>\n");
            xml.append("      <DarabSzam>").append(line.getTransactionCount()).append("</DarabSzam>\n");
            xml.append("    </Vetel>\n");
        }

        if (line.getSellAmount().compareTo(BigDecimal.ZERO) > 0) {
            xml.append("    <Eladas>\n");
            xml.append("      <Osszeg>").append(line.getSellAmount().setScale(2, RoundingMode.HALF_UP)).append("</Osszeg>\n");
            xml.append("      <Arfolyam>").append(line.getSellRate().setScale(4, RoundingMode.HALF_UP)).append("</Arfolyam>\n");
            xml.append("    </Eladas>\n");
        }

        xml.append("  </Devizanem>\n");
    }

    xml.append("</Jelentes>");
    return xml.toString();
}

private String resolveTaxId() {
    try {
        List<OwnCompany> companies = ownCompanyService.listActive();
        if (!companies.isEmpty() && companies.get(0).getTaxNumber() != null) {
            return companies.get(0).getTaxNumber();
        }
    } catch (Exception e) {
        log.warn("Saját cég adószám nem elérhető: {}", e.getMessage());
    }
    throw new ValidationException("Cég adószáma hiányzik — MNB beküldés nem lehetséges!");
}
```

- [ ] Írj tesztet az XML struktúrára:

```java
// MnbReportServiceTest.java
@Test
@DisplayName("generateMnbXml: XSD-kompatibilis struktúra — Jelentes gyökér, AdoSzam, TipusKod=N")
void generateMnbXml_xsdCompliant_daily() {
    // A generateMnbXml privát, az exportMnbXml publikus wrapper-en keresztül tesztelhetjük
    mockSecurityContext(TEST_COMPANY_ID, TEST_BRANCH_ID);
    when(transactionRepository.findActiveByCompanyAndDate(any(), any()))
        .thenReturn(buildSampleTransactions());
    when(ownCompanyService.listActive())
        .thenReturn(List.of(OwnCompany.builder().taxNumber("12345678-1-11").build()));

    String xml = mnbReportService.exportMnbXml(LocalDate.of(2026, 3, 16));

    assertThat(xml).contains("<Jelentes xmlns=\"http://www.mnb.hu/penzvaltok/2010\"");
    assertThat(xml).contains("AdoSzam=\"12345678-1-11\"");
    assertThat(xml).contains("TipusKod=\"N\"");
    assertThat(xml).contains("<Devizanem KodIso=\"EUR\"");
    assertThat(xml).doesNotContain("<MNBReport>");  // régi formátum
}
```

---

## Task 4: Retry mechanizmus

### 4.1 Retry service metódus

- [ ] Add a `MnbReportService`-be:

```java
/**
 * Sikertelen (REJECTED) riport újraküldése.
 * Maximum 3 kísérlet exponenciális várakozással (1h, 2h, 4h).
 */
public MnbSubmissionResult retrySubmission(UUID reportId) {
    MnbReport report = mnbReportRepository.findById(reportId)
        .orElseThrow(() -> new ResourceNotFoundException("MNB riport nem található: " + reportId));

    if (report.getStatus() != MnbReportStatus.REJECTED) {
        throw new ValidationException(
            "Csak REJECTED státuszú riport küldhető újra! Jelenlegi: " + report.getStatus());
    }

    int MAX_RETRIES = 3;
    if (report.getRetryCount() >= MAX_RETRIES) {
        throw new ValidationException(
            "Maximum újraküldési limit (" + MAX_RETRIES + ") elérve! Kézi beavatkozás szükséges.");
    }

    // Exponenciális backoff ellenőrzés: 1h, 2h, 4h
    if (report.getLastRetryAt() != null) {
        long hoursRequired = (long) Math.pow(2, report.getRetryCount() - 1);
        LocalDateTime nextAllowed = report.getLastRetryAt().plusHours(hoursRequired);
        if (LocalDateTime.now().isBefore(nextAllowed)) {
            throw new ValidationException(
                "Korai újraküldés! Következő lehetséges idő: " + nextAllowed);
        }
    }

    // Visszaállítás DRAFT-ra → újraküldés
    report.setStatus(MnbReportStatus.DRAFT);
    report.setRetryCount(report.getRetryCount() + 1);
    report.setLastRetryAt(LocalDateTime.now());
    mnbReportRepository.save(report);

    log.info("MNB riport újraküldés #{}: reportId={}", report.getRetryCount(), reportId);
    return submitReport(reportId);
}
```

- [ ] Tesztek:

```java
@Test
@DisplayName("retrySubmission: REJECTED riport → DRAFT-ra állít, submitReport-ot hív")
void retrySubmission_rejected_resetsAndSubmits() {
    MnbReport rejected = MnbReport.builder()
        .id(UUID.randomUUID())
        .status(MnbReportStatus.REJECTED)
        .retryCount(0)
        .reportType(MnbReportType.DAILY)
        .xmlContent("<MNBReport/>")
        .build();

    when(mnbReportRepository.findById(any())).thenReturn(Optional.of(rejected));
    when(mnbApiClient.submitXml(any(), any()))
        .thenReturn(MnbSubmissionResult.builder().success(true).referenceNumber("MNB-RETRY").build());
    when(mnbReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    MnbSubmissionResult result = mnbReportService.retrySubmission(rejected.getId());

    assertThat(result.isSuccess()).isTrue();
    assertThat(rejected.getRetryCount()).isEqualTo(1);
}

@Test
@DisplayName("retrySubmission: 3 kísérlet után → ValidationException")
void retrySubmission_maxRetries_throws() {
    MnbReport rejected = MnbReport.builder()
        .id(UUID.randomUUID())
        .status(MnbReportStatus.REJECTED)
        .retryCount(3)
        .build();
    when(mnbReportRepository.findById(any())).thenReturn(Optional.of(rejected));

    assertThatThrownBy(() -> mnbReportService.retrySubmission(rejected.getId()))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining("limit");
}
```

---

## Task 5: Heti riport generálás

### 5.1 generateWeeklyReport() metódus

- [ ] Add a `MnbReportService`-be:

```java
/**
 * Heti MNB riport generálása.
 * Hétfőtől vasárnapig (ISO hét).
 */
public MnbReport generateWeeklyReport(UUID branchId, LocalDate weekStart) {
    log.info("MNB heti riport generálás: branchId={}, weekStart={}", branchId, weekStart);

    // Hét eleje mindig hétfő
    LocalDate monday = weekStart.with(java.time.DayOfWeek.MONDAY);
    LocalDate sunday = monday.plusDays(6);

    Branch branch = branchRepository.findById(branchId)
        .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

    Optional<MnbReport> existing = mnbReportRepository
        .findByReportTypeAndReportDateAndBranchId(MnbReportType.WEEKLY, sunday, branchId);
    if (existing.isPresent()) {
        throw new ValidationException("Már létezik MNB heti riport erre a hétre: " + monday + " – " + sunday);
    }

    // Heti tranzakciók (hétfő–vasárnap)
    List<Transaction> transactions = transactionRepository
        .findByBranchAndMonth(branchId, monday, sunday);

    MnbReport report = MnbReport.builder()
        .reportType(MnbReportType.WEEKLY)
        .reportDate(sunday)           // riport dátuma: hét utolsó napja
        .branch(branch)
        .status(MnbReportStatus.DRAFT)
        .build();

    Map<String, CurrencyAggregation> aggregations = aggregateTransactions(transactions);
    BigDecimal totalBuyHuf = BigDecimal.ZERO;
    BigDecimal totalSellHuf = BigDecimal.ZERO;
    int totalTxCount = 0;

    for (Map.Entry<String, CurrencyAggregation> entry : aggregations.entrySet()) {
        CurrencyAggregation agg = entry.getValue();
        MnbReportLine line = MnbReportLine.builder()
            .currencyCode(entry.getKey())
            .buyAmount(agg.buyAmount)
            .sellAmount(agg.sellAmount)
            .buyRate(agg.getBuyCount() > 0
                ? agg.buyRateSum.divide(BigDecimal.valueOf(agg.getBuyCount()), 4, RoundingMode.HALF_UP)
                : BigDecimal.ZERO)
            .sellRate(agg.getSellCount() > 0
                ? agg.sellRateSum.divide(BigDecimal.valueOf(agg.getSellCount()), 4, RoundingMode.HALF_UP)
                : BigDecimal.ZERO)
            .transactionCount(agg.totalCount)
            .build();
        report.addLine(line);
        totalBuyHuf = totalBuyHuf.add(agg.buyHufTotal);
        totalSellHuf = totalSellHuf.add(agg.sellHufTotal);
        totalTxCount += agg.totalCount;
    }

    report.setTotalBuyHuf(totalBuyHuf);
    report.setTotalSellHuf(totalSellHuf);
    report.setTotalTransactions(totalTxCount);
    report.setXmlContent(generateMnbXml(report, branch));

    MnbReport saved = mnbReportRepository.save(report);
    log.info("MNB heti riport létrehozva: id={}, hét={} – {}", saved.getId(), monday, sunday);
    return saved;
}
```

- [ ] Teszt:

```java
@Test
@DisplayName("generateWeeklyReport: hétfőtől vasárnapig aggregál, WEEKLY típus")
void generateWeeklyReport_createsWeeklyReport() {
    UUID branchId = UUID.randomUUID();
    LocalDate monday = LocalDate.of(2026, 3, 9);  // hétfő
    LocalDate sunday = LocalDate.of(2026, 3, 15); // vasárnap

    when(branchRepository.findById(branchId)).thenReturn(Optional.of(testBranch));
    when(mnbReportRepository.findByReportTypeAndReportDateAndBranchId(
        MnbReportType.WEEKLY, sunday, branchId)).thenReturn(Optional.empty());
    when(transactionRepository.findByBranchAndMonth(branchId, monday, sunday))
        .thenReturn(buildSampleTransactions());
    when(ownCompanyService.listActive())
        .thenReturn(List.of(OwnCompany.builder().taxNumber("12345678-1-11").build()));
    when(mnbReportRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

    MnbReport report = mnbReportService.generateWeeklyReport(branchId, monday);

    assertThat(report.getReportType()).isEqualTo(MnbReportType.WEEKLY);
    assertThat(report.getReportDate()).isEqualTo(sunday);
    assertThat(report.getStatus()).isEqualTo(MnbReportStatus.DRAFT);
    assertThat(report.getXmlContent()).contains("TipusKod=\"H\"");
}
```

---

## Futtatandó parancsok

```bash
# Migrációk futtatása
cd backend && ./mvnw flyway:migrate -Dflyway.url=... -Dflyway.user=... -Dflyway.password=...

# Tesztek
cd backend && ./mvnw test -Dtest=MnbApiClientTest,MnbReportServiceTest

# Teljes backend build
cd backend && ./mvnw clean compile

# Kódminőség
cd backend && ./mvnw checkstyle:check
```

---

## Commit üzenetek

```
feat(mnb): add MnbApiClient with configurable endpoint from SystemParameter

feat(mnb): implement DRAFT→SUBMITTED→ACKNOWLEDGED/REJECTED status flow

feat(mnb): fix XML to MNB XSD compliant format (Jelentes namespace, TipusKod)

feat(mnb): add retry mechanism with exponential backoff (max 3 attempts)

feat(mnb): add weekly report generation (ISO week, Mon–Sun)

test(mnb): add MnbApiClientTest and extend MnbReportServiceTest
```

---

## SystemParameter seedelés

A `MNB_API_URL` és `MNB_API_TOKEN` system parameter-eket be kell szúrni az adatbázisba (vagy az admin felületen kell felvenni):

```sql
-- Teszt/UAT környezet
INSERT INTO system_parameter (param_key, param_value, description, is_sensitive)
VALUES
  ('MNB_API_URL',   'https://mnbgyujto-test.mnb.hu/api/submit', 'MNB adatszolgáltatás API URL', false),
  ('MNB_API_TOKEN', 'PLACEHOLDER_TOKEN',                        'MNB Bearer token',              true)
ON CONFLICT (param_key) DO NOTHING;
```

> **Figyelem:** Éles token-t soha ne commitolj! Az `is_sensitive=true` jelzésű paraméterek a loggolásból ki vannak szűrve.
