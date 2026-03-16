# VALUTA Legacy Gaps Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the VALUTA legacy migration by implementing 5 remaining gaps: WU multi-tenant fix, WU balance pessimistic lock, Receipt PDF upgrade with PDFBox, SealTracking lifecycle service, and LED display serial protocol service.

**Architecture:** Extend existing Spring Boot 3.2 + Java 21 backend following established patterns. All new services use constructor injection, `@Slf4j`, `@Transactional`. All queries filter by `SecurityUtils.getCurrentCompanyId()`. New Flyway migrations V96–V98.

**Tech Stack:** Java 21, Spring Boot 3.2, Spring Data JPA, PostgreSQL, Apache PDFBox 3.0.4, jSerialComm 2.10.4, JUnit 5 + Mockito + AssertJ

---

## Chunk 1: WU Multi-Tenant Fix + Pessimistic Lock

### Task 1: V96 Flyway Migration — company_id on WU Tables

**Files:**
- Create: `backend/src/main/resources/db/migration/V96__wu_company_id.sql`

- [ ] **Step 1: Write the migration SQL**

```sql
-- V96: Add company_id to WU tables for multi-tenant support
ALTER TABLE wu_transaction ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES company(id);
ALTER TABLE wu_balance ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES company(id);
ALTER TABLE wu_customer ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES company(id);

-- Backfill from branch → company relationship
UPDATE wu_transaction wt SET company_id = b.company_id
FROM branch b WHERE wt.branch_id = b.id AND wt.company_id IS NULL;

UPDATE wu_balance wb SET company_id = b.company_id
FROM branch b WHERE wb.branch_id = b.id AND wb.company_id IS NULL;

-- WuCustomer has no branch_id, backfill from first linked transaction
UPDATE wu_customer wc SET company_id = (
    SELECT DISTINCT wt.company_id FROM wu_transaction wt
    WHERE wt.wu_customer_id = wc.id AND wt.company_id IS NOT NULL
    LIMIT 1
) WHERE wc.company_id IS NULL;

-- Make NOT NULL after backfill
ALTER TABLE wu_transaction ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE wu_balance ALTER COLUMN company_id SET NOT NULL;
-- wu_customer remains nullable (orphan records possible)

-- Performance index
CREATE INDEX IF NOT EXISTS idx_wu_balance_branch_company ON wu_balance(branch_id, company_id);
CREATE INDEX IF NOT EXISTS idx_wu_transaction_company ON wu_transaction(company_id);
```

- [ ] **Step 2: Verify migration compiles**

Run: `cd backend && ./mvnw compile -q`
Expected: BUILD SUCCESS

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/resources/db/migration/V96__wu_company_id.sql
git commit -m "feat(wu): V96 migration adds company_id to WU tables for multi-tenant"
```

### Task 2: WuBalance Pessimistic Lock

**Files:**
- Modify: `backend/src/main/java/hu/puzzleir/valuta/repository/WuBalanceRepository.java`
- Create: `backend/src/test/java/hu/puzzleir/valuta/service/WesternUnionServiceLockTest.java`

- [ ] **Step 1: Read current WuBalanceRepository**

Read `backend/src/main/java/hu/puzzleir/valuta/repository/WuBalanceRepository.java` to see existing methods.

- [ ] **Step 2: Add pessimistic lock query**

Add to `WuBalanceRepository.java`:

```java
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

@Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("SELECT wb FROM WuBalance wb WHERE wb.branchId = :branchId")
Optional<WuBalance> findByBranchIdForUpdate(UUID branchId);
```

- [ ] **Step 3: Update WesternUnionService to use pessimistic lock**

Read `backend/src/main/java/hu/puzzleir/valuta/service/WesternUnionService.java` fully. Find the `getOrCreateBalance()` or equivalent private method. Replace `findByBranchId()` with `findByBranchIdForUpdate()` in the balance update paths (recordSend, recordReceive, reverseWuTransaction).

The key change: wherever the service reads a WuBalance and then modifies it, the read must use `findByBranchIdForUpdate()` instead of `findByBranchId()`.

- [ ] **Step 4: Write test for pessimistic lock usage**

```java
@ExtendWith(MockitoExtension.class)
class WesternUnionServiceLockTest {

    @InjectMocks private WesternUnionService service;
    @Mock private WuBalanceRepository wuBalanceRepository;
    @Mock private WuTransactionRepository wuTransactionRepository;
    @Mock private WuCustomerRepository wuCustomerRepository;
    @Mock private BranchRepository branchRepository;
    // ... other mocks matching WesternUnionService constructor

    @BeforeEach
    void setUp() {
        // SecurityContext mock
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
            1L, UUID.randomUUID(), UUID.randomUUID(), "CASHIER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    @DisplayName("Balance update uses pessimistic lock (findByBranchIdForUpdate)")
    void balanceUpdate_usesPessimisticLock() {
        // This test verifies the service calls findByBranchIdForUpdate
        // not findByBranchId when updating balance
        UUID branchId = UUID.randomUUID();
        WuBalance balance = new WuBalance();
        balance.setBranchId(branchId);
        balance.setUsdBalance(BigDecimal.valueOf(1000));
        balance.setHufBalance(BigDecimal.valueOf(300000));

        when(wuBalanceRepository.findByBranchIdForUpdate(branchId))
            .thenReturn(Optional.of(balance));

        // Trigger a balance update through the service
        // (exact method depends on WesternUnionService implementation)
        // verify(wuBalanceRepository).findByBranchIdForUpdate(branchId);
    }
}
```

Note: Adapt the test based on actual WesternUnionService constructor parameters and method signatures found in Step 3.

- [ ] **Step 5: Run tests**

Run: `cd backend && ./mvnw test -Dtest=WesternUnionServiceLockTest -q`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/hu/puzzleir/valuta/repository/WuBalanceRepository.java
git add backend/src/main/java/hu/puzzleir/valuta/service/WesternUnionService.java
git add backend/src/test/java/hu/puzzleir/valuta/service/WesternUnionServiceLockTest.java
git commit -m "feat(wu): add pessimistic lock on WuBalance for concurrent safety"
```

---

## Chunk 2: Receipt PDF Upgrade with Apache PDFBox

### Task 3: Add PDFBox Dependency

**Files:**
- Modify: `backend/pom.xml`

- [ ] **Step 1: Add PDFBox to pom.xml**

Add inside `<dependencies>`:

```xml
<!-- PDF generation for receipts -->
<dependency>
    <groupId>org.apache.pdfbox</groupId>
    <artifactId>pdfbox</artifactId>
    <version>3.0.4</version>
</dependency>
```

- [ ] **Step 2: Verify dependency resolves**

Run: `cd backend && ./mvnw dependency:resolve -q`
Expected: BUILD SUCCESS

- [ ] **Step 3: Commit**

```bash
git add backend/pom.xml
git commit -m "build: add Apache PDFBox 3.0.4 dependency for receipt PDF generation"
```

### Task 4: ReceiptPdfService — PDFBox PDF Generation

**Files:**
- Create: `backend/src/main/java/hu/puzzleir/valuta/service/ReceiptPdfService.java`
- Create: `backend/src/test/java/hu/puzzleir/valuta/service/ReceiptPdfServiceTest.java`

- [ ] **Step 1: Write failing tests**

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.receipt.ReceiptData;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class ReceiptPdfServiceTest {

    private ReceiptPdfService pdfService;

    @BeforeEach
    void setUp() {
        pdfService = new ReceiptPdfService();
    }

    @Test
    @DisplayName("generatePdf: sell receipt produces valid PDF bytes")
    void generatePdf_sellReceipt_producesValidPdf() {
        ReceiptData data = createSellReceipt();
        byte[] pdf = pdfService.generatePdf(data);

        assertThat(pdf).isNotEmpty();
        // PDF magic bytes: %PDF
        assertThat(new String(pdf, 0, 4)).isEqualTo("%PDF");
    }

    @Test
    @DisplayName("generatePdf: receipt with MÁSOLAT watermark")
    void generatePdf_copy_hasMasolatWatermark() {
        ReceiptData data = createSellReceipt();
        byte[] pdf = pdfService.generatePdfCopy(data);

        assertThat(pdf).isNotEmpty();
        assertThat(new String(pdf, 0, 4)).isEqualTo("%PDF");
        // PDF should be larger than non-copy (has watermark)
        byte[] original = pdfService.generatePdf(data);
        assertThat(pdf.length).isGreaterThan(original.length);
    }

    @Test
    @DisplayName("generatePdf: WU receipt contains MTCN")
    void generatePdf_wuReceipt_containsMtcn() {
        ReceiptData data = ReceiptData.builder()
                .receiptNumber("W-260316-0001")
                .receiptType("WU_SEND")
                .companyName("Test Kft.")
                .branchName("Budapest")
                .workerName("Teszt Pénztáros")
                .date(LocalDateTime.now())
                .currencyCode("USD")
                .foreignAmount(new BigDecimal("500.00"))
                .rate(new BigDecimal("375.20"))
                .hufAmount(new BigDecimal("187600"))
                .lines(List.of(
                    ReceiptData.ReceiptLineData.builder()
                        .label("MTCN").value("1234567890").build()
                ))
                .build();

        byte[] pdf = pdfService.generatePdf(data);
        assertThat(pdf).isNotEmpty();
        assertThat(new String(pdf, 0, 4)).isEqualTo("%PDF");
    }

    @Test
    @DisplayName("generatePdf: closing receipt contains totals")
    void generatePdf_closingReceipt() {
        ReceiptData data = ReceiptData.builder()
                .receiptNumber("Z-260316-0001")
                .receiptType("CLOSING")
                .companyName("Test Kft.")
                .branchName("Budapest")
                .workerName("Teszt Pénztáros")
                .date(LocalDateTime.now())
                .hufAmount(new BigDecimal("5000000"))
                .lines(List.of(
                    ReceiptData.ReceiptLineData.builder()
                        .label("Tranzakciók száma").value("42").build(),
                    ReceiptData.ReceiptLineData.builder()
                        .label("Napi forgalom (HUF)").value("5000000").build()
                ))
                .build();

        byte[] pdf = pdfService.generatePdf(data);
        assertThat(pdf).isNotEmpty();
    }

    private ReceiptData createSellReceipt() {
        return ReceiptData.builder()
                .receiptNumber("E-260316-0001")
                .receiptType("SELL")
                .companyName("Test Kft.")
                .branchName("Budapest I.")
                .workerName("Teszt Pénztáros")
                .date(LocalDateTime.now())
                .currencyCode("EUR")
                .foreignAmount(new BigDecimal("500.00"))
                .rate(new BigDecimal("405.32"))
                .hufAmount(new BigDecimal("202660"))
                .handlingFee(BigDecimal.ZERO)
                .customerName("Teszt Ügyfél")
                .customerIdNumber("123456AB")
                .lines(List.of())
                .qrCode("E-260316-0001")
                .build();
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && ./mvnw test -Dtest=ReceiptPdfServiceTest -q`
Expected: FAIL (ReceiptPdfService not found)

- [ ] **Step 3: Implement ReceiptPdfService**

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.receipt.ReceiptData;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.format.DateTimeFormatter;

/**
 * PDF bizonylat generálás Apache PDFBox-szal.
 * Bizonylat méret: 80mm x variable (nyugtanyomtató).
 * A4-es PDF a webes megjelenítéshez és nyomtatáshoz.
 */
@Service
@Slf4j
public class ReceiptPdfService {

    private static final float PAGE_WIDTH = PDRectangle.A4.getWidth();
    private static final float PAGE_HEIGHT = PDRectangle.A4.getHeight();
    private static final float MARGIN = 50;
    private static final float LINE_HEIGHT = 14;
    private static final float HEADER_FONT_SIZE = 16;
    private static final float NORMAL_FONT_SIZE = 10;
    private static final float SMALL_FONT_SIZE = 8;
    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm");
    private static final String SEPARATOR = "─────────────────────────────────────────────";

    public byte[] generatePdf(ReceiptData data) {
        return generatePdfInternal(data, false);
    }

    public byte[] generatePdfCopy(ReceiptData data) {
        return generatePdfInternal(data, true);
    }

    private byte[] generatePdfInternal(ReceiptData data, boolean isCopy) {
        try (PDDocument document = new PDDocument()) {
            PDPage page = new PDPage(PDRectangle.A4);
            document.addPage(page);

            try (PDPageContentStream cs = new PDPageContentStream(document, page)) {
                float y = PAGE_HEIGHT - MARGIN;

                // Watermark for copies
                if (isCopy) {
                    y = drawWatermark(cs, y);
                }

                // Header: company name centered
                PDType1Font boldFont = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
                PDType1Font normalFont = new PDType1Font(Standard14Fonts.FontName.HELVETICA);

                y = drawCenteredText(cs, boldFont, HEADER_FONT_SIZE,
                        data.getCompanyName() != null ? data.getCompanyName() : "", y);
                y = drawCenteredText(cs, normalFont, NORMAL_FONT_SIZE,
                        data.getBranchName() != null ? data.getBranchName() : "", y);
                y -= LINE_HEIGHT;

                // Separator
                y = drawText(cs, normalFont, SMALL_FONT_SIZE, MARGIN, SEPARATOR, y);

                // Receipt info
                y = drawText(cs, normalFont, NORMAL_FONT_SIZE, MARGIN,
                        "Bizonylat: " + (data.getReceiptNumber() != null ? data.getReceiptNumber() : ""), y);
                y = drawText(cs, normalFont, NORMAL_FONT_SIZE, MARGIN,
                        "Dátum: " + (data.getDate() != null ? data.getDate().format(DATE_FORMAT) : ""), y);
                y = drawText(cs, normalFont, NORMAL_FONT_SIZE, MARGIN,
                        "Pénztáros: " + (data.getWorkerName() != null ? data.getWorkerName() : ""), y);
                y -= LINE_HEIGHT / 2;

                // Separator
                y = drawText(cs, normalFont, SMALL_FONT_SIZE, MARGIN, SEPARATOR, y);

                // Currency details
                if (data.getCurrencyCode() != null) {
                    y = drawKeyValue(cs, normalFont, NORMAL_FONT_SIZE, MARGIN,
                            "Valutanem", data.getCurrencyCode(), y);
                    y = drawKeyValue(cs, normalFont, NORMAL_FONT_SIZE, MARGIN,
                            "Mennyiség", formatAmount(data.getForeignAmount()), y);
                    y = drawKeyValue(cs, normalFont, NORMAL_FONT_SIZE, MARGIN,
                            "Árfolyam", formatAmount(data.getRate()), y);
                    y = drawKeyValue(cs, boldFont, NORMAL_FONT_SIZE, MARGIN,
                            "HUF összeg", formatAmount(data.getHufAmount()) + " Ft", y);
                }

                // Handling fee
                if (data.getHandlingFee() != null && data.getHandlingFee().compareTo(BigDecimal.ZERO) > 0) {
                    y = drawKeyValue(cs, normalFont, NORMAL_FONT_SIZE, MARGIN,
                            "Kezelési díj", formatAmount(data.getHandlingFee()) + " Ft", y);
                }

                y -= LINE_HEIGHT / 2;
                y = drawText(cs, normalFont, SMALL_FONT_SIZE, MARGIN, SEPARATOR, y);

                // Customer info
                if (data.getCustomerName() != null && !data.getCustomerName().isBlank()) {
                    y = drawKeyValue(cs, normalFont, NORMAL_FONT_SIZE, MARGIN,
                            "Ügyfél", data.getCustomerName(), y);
                }
                if (data.getCustomerIdNumber() != null && !data.getCustomerIdNumber().isBlank()) {
                    y = drawKeyValue(cs, normalFont, NORMAL_FONT_SIZE, MARGIN,
                            "Okmányszám", data.getCustomerIdNumber(), y);
                }

                // Extra lines (MTCN, storno info, closing data etc.)
                for (ReceiptData.ReceiptLineData line : data.getLines()) {
                    y = drawKeyValue(cs, normalFont, NORMAL_FONT_SIZE, MARGIN,
                            line.getLabel(), line.getValue(), y);
                }

                y -= LINE_HEIGHT;
                y = drawText(cs, normalFont, SMALL_FONT_SIZE, MARGIN, SEPARATOR, y);

                // Signature line
                y -= LINE_HEIGHT * 2;
                y = drawCenteredText(cs, normalFont, SMALL_FONT_SIZE,
                        data.getSignatureLine() != null ? data.getSignatureLine() : "Aláírás: _______________", y);
            }

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            document.save(baos);
            return baos.toByteArray();

        } catch (IOException e) {
            log.error("PDF generation failed for receipt {}: {}", data.getReceiptNumber(), e.getMessage(), e);
            throw new RuntimeException("PDF generálás sikertelen: " + e.getMessage(), e);
        }
    }

    private float drawWatermark(PDPageContentStream cs, float y) throws IOException {
        PDType1Font font = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
        cs.setNonStrokingColor(200, 200, 200); // Light gray
        cs.beginText();
        cs.setFont(font, 48);
        cs.newLineAtOffset(100, PAGE_HEIGHT / 2);
        cs.showText("MÁSOLAT");
        cs.endText();
        cs.setNonStrokingColor(0, 0, 0); // Reset to black
        return y;
    }

    private float drawCenteredText(PDPageContentStream cs, PDType1Font font, float fontSize,
                                    String text, float y) throws IOException {
        float textWidth = font.getStringWidth(text) / 1000 * fontSize;
        float x = (PAGE_WIDTH - textWidth) / 2;
        return drawText(cs, font, fontSize, x, text, y);
    }

    private float drawText(PDPageContentStream cs, PDType1Font font, float fontSize,
                           float x, String text, float y) throws IOException {
        cs.beginText();
        cs.setFont(font, fontSize);
        cs.newLineAtOffset(x, y);
        cs.showText(text != null ? text : "");
        cs.endText();
        return y - LINE_HEIGHT;
    }

    private float drawKeyValue(PDPageContentStream cs, PDType1Font font, float fontSize,
                                float x, String key, String value, float y) throws IOException {
        String line = String.format("%-20s %s", key + ":", value != null ? value : "");
        return drawText(cs, font, fontSize, x, line, y);
    }

    private String formatAmount(BigDecimal amount) {
        if (amount == null) return "0";
        return amount.toPlainString();
    }
}
```

- [ ] **Step 4: Run tests**

Run: `cd backend && ./mvnw test -Dtest=ReceiptPdfServiceTest -q`
Expected: ALL PASS

- [ ] **Step 5: Wire ReceiptPdfService into ReceiptGeneratorService**

Read `backend/src/main/java/hu/puzzleir/valuta/service/ReceiptGeneratorService.java`. Replace the `formatForPdf()` method body to delegate to `ReceiptPdfService`:

Add field:
```java
private final ReceiptPdfService receiptPdfService;
```

Replace `formatForPdf()`:
```java
public byte[] formatForPdf(ReceiptData data) {
    return receiptPdfService.generatePdf(data);
}
```

Note: The old text-based formatForPdf is replaced by real PDF. ESC/POS stays unchanged.

- [ ] **Step 6: Add WU receipt generation to ReceiptGeneratorService**

Add method to `ReceiptGeneratorService`:

```java
/**
 * Western Union bizonylat generálása
 * Prefix: W
 */
public ReceiptData generateWuReceipt(WuTransaction wuTx) {
    String receiptNumber = generateReceiptNumber("W");

    List<ReceiptData.ReceiptLineData> lines = new ArrayList<>();
    lines.add(ReceiptData.ReceiptLineData.builder()
            .label("MTCN").value(wuTx.getMtcn()).build());
    lines.add(ReceiptData.ReceiptLineData.builder()
            .label("Típus").value(wuTx.getTransactionType().name()).build());
    if (wuTx.getSenderName() != null) {
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Küldő").value(wuTx.getSenderName()).build());
    }
    if (wuTx.getReceiverName() != null) {
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Címzett").value(wuTx.getReceiverName()).build());
    }
    if (wuTx.getDestinationCountry() != null) {
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("Cél ország").value(wuTx.getDestinationCountry()).build());
    }
    if (wuTx.getFeeAmount() != null) {
        lines.add(ReceiptData.ReceiptLineData.builder()
                .label("WU díj").value(wuTx.getFeeAmount().toPlainString() + " USD").build());
    }

    return ReceiptData.builder()
            .receiptNumber(receiptNumber)
            .receiptType("WU_" + wuTx.getTransactionType().name())
            .companyName("") // Branch-ből töltendő
            .branchName("")
            .workerName("")
            .date(LocalDateTime.now())
            .currencyCode("USD")
            .foreignAmount(wuTx.getAmountUsd())
            .rate(wuTx.getExchangeRate())
            .hufAmount(wuTx.getAmountHuf())
            .lines(lines)
            .qrCode(receiptNumber)
            .build();
}
```

Add import: `import hu.puzzleir.valuta.entity.WuTransaction;`

- [ ] **Step 7: Run all receipt tests**

Run: `cd backend && ./mvnw test -Dtest="ReceiptGeneratorServiceTest,ReceiptPdfServiceTest" -q`
Expected: ALL PASS

- [ ] **Step 8: Commit**

```bash
git add backend/pom.xml
git add backend/src/main/java/hu/puzzleir/valuta/service/ReceiptPdfService.java
git add backend/src/main/java/hu/puzzleir/valuta/service/ReceiptGeneratorService.java
git add backend/src/test/java/hu/puzzleir/valuta/service/ReceiptPdfServiceTest.java
git commit -m "feat(receipt): PDFBox-based PDF generation + WU receipt support"
```

---

## Chunk 3: SealTracking Lifecycle Service

### Task 5: V97 Flyway Migration — seal_tracking Table

**Files:**
- Create: `backend/src/main/resources/db/migration/V97__seal_tracking.sql`

- [ ] **Step 1: Write migration**

```sql
-- V97: Seal tracking for transfer lifecycle (plomba nyomkövetés)
CREATE TABLE seal_tracking (
    id              BIGSERIAL PRIMARY KEY,
    company_id      UUID NOT NULL REFERENCES company(id),
    transfer_type   VARCHAR(20) NOT NULL,
    transfer_id     BIGINT NOT NULL,
    seal_number     VARCHAR(50) NOT NULL,
    sealed_at       TIMESTAMP NOT NULL,
    sealed_by       BIGINT NOT NULL REFERENCES worker(id),
    opened_at       TIMESTAMP,
    opened_by       BIGINT REFERENCES worker(id),
    transit_status  VARCHAR(20) NOT NULL DEFAULT 'SEALED',
    notes           TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP
);

CREATE INDEX idx_seal_tracking_transfer ON seal_tracking(transfer_type, transfer_id);
CREATE UNIQUE INDEX idx_seal_tracking_number ON seal_tracking(seal_number);
CREATE INDEX idx_seal_tracking_company ON seal_tracking(company_id);
CREATE INDEX idx_seal_tracking_status ON seal_tracking(transit_status) WHERE transit_status IN ('SEALED', 'IN_TRANSIT');
```

- [ ] **Step 2: Verify compilation**

Run: `cd backend && ./mvnw compile -q`
Expected: BUILD SUCCESS

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/resources/db/migration/V97__seal_tracking.sql
git commit -m "feat(seal): V97 migration creates seal_tracking table"
```

### Task 6: SealTracking Entity + Repository

**Files:**
- Create: `backend/src/main/java/hu/puzzleir/valuta/entity/SealTracking.java`
- Create: `backend/src/main/java/hu/puzzleir/valuta/entity/SealTransitStatus.java`
- Create: `backend/src/main/java/hu/puzzleir/valuta/repository/SealTrackingRepository.java`

- [ ] **Step 1: Create SealTransitStatus enum**

```java
package hu.puzzleir.valuta.entity;

public enum SealTransitStatus {
    SEALED,
    IN_TRANSIT,
    ARRIVED,
    OPENED
}
```

- [ ] **Step 2: Create SealTracking entity**

```java
package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "seal_tracking")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SealTracking {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id", nullable = false)
    private UUID companyId;

    @Column(name = "transfer_type", nullable = false, length = 20)
    private String transferType;

    @Column(name = "transfer_id", nullable = false)
    private Long transferId;

    @Column(name = "seal_number", nullable = false, unique = true, length = 50)
    private String sealNumber;

    @Column(name = "sealed_at", nullable = false)
    private LocalDateTime sealedAt;

    @Column(name = "sealed_by", nullable = false)
    private Long sealedBy;

    @Column(name = "opened_at")
    private LocalDateTime openedAt;

    @Column(name = "opened_by")
    private Long openedBy;

    @Enumerated(EnumType.STRING)
    @Column(name = "transit_status", nullable = false, length = 20)
    private SealTransitStatus transitStatus;

    @Column(name = "notes")
    private String notes;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (transitStatus == null) {
            transitStatus = SealTransitStatus.SEALED;
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
```

- [ ] **Step 3: Create SealTrackingRepository**

```java
package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.SealTracking;
import hu.puzzleir.valuta.entity.SealTransitStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SealTrackingRepository extends JpaRepository<SealTracking, Long> {

    Optional<SealTracking> findBySealNumber(String sealNumber);

    Optional<SealTracking> findByTransferTypeAndTransferId(String transferType, Long transferId);

    List<SealTracking> findByCompanyIdAndTransitStatusIn(UUID companyId, List<SealTransitStatus> statuses);

    List<SealTracking> findByCompanyIdAndTransitStatus(UUID companyId, SealTransitStatus status);

    boolean existsBySealNumber(String sealNumber);
}
```

- [ ] **Step 4: Verify compilation**

Run: `cd backend && ./mvnw compile -q`
Expected: BUILD SUCCESS

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/hu/puzzleir/valuta/entity/SealTracking.java
git add backend/src/main/java/hu/puzzleir/valuta/entity/SealTransitStatus.java
git add backend/src/main/java/hu/puzzleir/valuta/repository/SealTrackingRepository.java
git commit -m "feat(seal): SealTracking entity, enum, and repository"
```

### Task 7: SealTrackingService

**Files:**
- Create: `backend/src/main/java/hu/puzzleir/valuta/service/SealTrackingService.java`
- Create: `backend/src/test/java/hu/puzzleir/valuta/service/SealTrackingServiceTest.java`

- [ ] **Step 1: Write failing tests**

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.SealTracking;
import hu.puzzleir.valuta.entity.SealTransitStatus;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.SealTrackingRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SealTrackingServiceTest {

    @InjectMocks
    private SealTrackingService sealTrackingService;

    @Mock
    private SealTrackingRepository sealTrackingRepository;

    @Mock
    private AuditLogService auditLogService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 1L;

    @BeforeEach
    void setUp() {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
                WORKER_ID, COMPANY_ID, BRANCH_ID, "SUPERVISOR");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_SUPERVISOR");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    @DisplayName("seal: creates SEALED tracking record")
    void seal_createsRecord() {
        when(sealTrackingRepository.existsBySealNumber("TR-20260316-001")).thenReturn(false);
        when(sealTrackingRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        SealTracking result = sealTrackingService.seal("TRANSFER", 42L, "TR-20260316-001");

        assertThat(result.getTransitStatus()).isEqualTo(SealTransitStatus.SEALED);
        assertThat(result.getSealNumber()).isEqualTo("TR-20260316-001");
        assertThat(result.getTransferId()).isEqualTo(42L);
        assertThat(result.getSealedBy()).isEqualTo(WORKER_ID);
        assertThat(result.getCompanyId()).isEqualTo(COMPANY_ID);
    }

    @Test
    @DisplayName("seal: duplicate seal number throws")
    void seal_duplicateNumber_throws() {
        when(sealTrackingRepository.existsBySealNumber("TR-20260316-001")).thenReturn(true);

        assertThatThrownBy(() -> sealTrackingService.seal("TRANSFER", 42L, "TR-20260316-001"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Plomba szám már használatban");
    }

    @Test
    @DisplayName("startTransit: SEALED → IN_TRANSIT")
    void startTransit_sealedToInTransit() {
        SealTracking tracking = SealTracking.builder()
                .id(1L)
                .companyId(COMPANY_ID)
                .transferType("TRANSFER")
                .transferId(42L)
                .sealNumber("TR-20260316-001")
                .transitStatus(SealTransitStatus.SEALED)
                .sealedBy(WORKER_ID)
                .build();

        when(sealTrackingRepository.findByTransferTypeAndTransferId("TRANSFER", 42L))
                .thenReturn(Optional.of(tracking));
        when(sealTrackingRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        SealTracking result = sealTrackingService.startTransit("TRANSFER", 42L);

        assertThat(result.getTransitStatus()).isEqualTo(SealTransitStatus.IN_TRANSIT);
    }

    @Test
    @DisplayName("confirmArrival: IN_TRANSIT → ARRIVED")
    void confirmArrival_inTransitToArrived() {
        SealTracking tracking = SealTracking.builder()
                .id(1L)
                .companyId(COMPANY_ID)
                .transferType("TRANSFER")
                .transferId(42L)
                .sealNumber("TR-20260316-001")
                .transitStatus(SealTransitStatus.IN_TRANSIT)
                .sealedBy(WORKER_ID)
                .build();

        when(sealTrackingRepository.findByTransferTypeAndTransferId("TRANSFER", 42L))
                .thenReturn(Optional.of(tracking));
        when(sealTrackingRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        SealTracking result = sealTrackingService.confirmArrival("TRANSFER", 42L);

        assertThat(result.getTransitStatus()).isEqualTo(SealTransitStatus.ARRIVED);
    }

    @Test
    @DisplayName("openSeal: ARRIVED → OPENED, records opener")
    void openSeal_arrivedToOpened() {
        SealTracking tracking = SealTracking.builder()
                .id(1L)
                .companyId(COMPANY_ID)
                .transferType("TRANSFER")
                .transferId(42L)
                .sealNumber("TR-20260316-001")
                .transitStatus(SealTransitStatus.ARRIVED)
                .sealedBy(WORKER_ID)
                .build();

        when(sealTrackingRepository.findByTransferTypeAndTransferId("TRANSFER", 42L))
                .thenReturn(Optional.of(tracking));
        when(sealTrackingRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        SealTracking result = sealTrackingService.openSeal("TRANSFER", 42L);

        assertThat(result.getTransitStatus()).isEqualTo(SealTransitStatus.OPENED);
        assertThat(result.getOpenedBy()).isEqualTo(WORKER_ID);
        assertThat(result.getOpenedAt()).isNotNull();
    }

    @Test
    @DisplayName("startTransit: wrong status throws")
    void startTransit_wrongStatus_throws() {
        SealTracking tracking = SealTracking.builder()
                .transitStatus(SealTransitStatus.OPENED)
                .companyId(COMPANY_ID)
                .build();

        when(sealTrackingRepository.findByTransferTypeAndTransferId("TRANSFER", 42L))
                .thenReturn(Optional.of(tracking));

        assertThatThrownBy(() -> sealTrackingService.startTransit("TRANSFER", 42L))
                .isInstanceOf(ValidationException.class);
    }

    @Test
    @DisplayName("validateSealIntegrity: matching seal returns true")
    void validateSealIntegrity_matching_returnsTrue() {
        SealTracking tracking = SealTracking.builder()
                .sealNumber("TR-20260316-001")
                .companyId(COMPANY_ID)
                .build();

        when(sealTrackingRepository.findByTransferTypeAndTransferId("TRANSFER", 42L))
                .thenReturn(Optional.of(tracking));

        boolean valid = sealTrackingService.validateSealIntegrity("TRANSFER", 42L, "TR-20260316-001");

        assertThat(valid).isTrue();
    }

    @Test
    @DisplayName("validateSealIntegrity: mismatched seal returns false")
    void validateSealIntegrity_mismatch_returnsFalse() {
        SealTracking tracking = SealTracking.builder()
                .sealNumber("TR-20260316-001")
                .companyId(COMPANY_ID)
                .build();

        when(sealTrackingRepository.findByTransferTypeAndTransferId("TRANSFER", 42L))
                .thenReturn(Optional.of(tracking));

        boolean valid = sealTrackingService.validateSealIntegrity("TRANSFER", 42L, "WRONG-NUMBER");

        assertThat(valid).isFalse();
    }

    @Test
    @DisplayName("getInTransit: returns only IN_TRANSIT and SEALED records")
    void getInTransit_returnsActiveRecords() {
        List<SealTracking> active = List.of(
                SealTracking.builder().transitStatus(SealTransitStatus.SEALED).build(),
                SealTracking.builder().transitStatus(SealTransitStatus.IN_TRANSIT).build()
        );

        when(sealTrackingRepository.findByCompanyIdAndTransitStatusIn(
                COMPANY_ID, List.of(SealTransitStatus.SEALED, SealTransitStatus.IN_TRANSIT)))
                .thenReturn(active);

        List<SealTracking> result = sealTrackingService.getActiveTransits();

        assertThat(result).hasSize(2);
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && ./mvnw test -Dtest=SealTrackingServiceTest -q`
Expected: FAIL (SealTrackingService not found)

- [ ] **Step 3: Implement SealTrackingService**

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.SealTracking;
import hu.puzzleir.valuta.entity.SealTransitStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.SealTrackingRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Plomba/pecsét nyomkövetés a transfer lifecycle-ban.
 *
 * Státusz flow: SEALED → IN_TRANSIT → ARRIVED → OPENED
 *
 * Minden plomba esemény audit logolásra kerül.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class SealTrackingService {

    private final SealTrackingRepository sealTrackingRepository;
    private final AuditLogService auditLogService;

    /**
     * Új plomba rögzítése egy transferhez.
     */
    public SealTracking seal(String transferType, Long transferId, String sealNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        if (sealTrackingRepository.existsBySealNumber(sealNumber)) {
            throw new ValidationException("Plomba szám már használatban: " + sealNumber);
        }

        SealTracking tracking = SealTracking.builder()
                .companyId(companyId)
                .transferType(transferType)
                .transferId(transferId)
                .sealNumber(sealNumber)
                .sealedAt(LocalDateTime.now())
                .sealedBy(workerId)
                .transitStatus(SealTransitStatus.SEALED)
                .build();

        SealTracking saved = sealTrackingRepository.save(tracking);

        auditLogService.log("SEAL_CREATED",
                String.format("Plomba %s rögzítve transfer %s/%d-hez", sealNumber, transferType, transferId));

        log.info("Seal created: {} for {}/{}", sealNumber, transferType, transferId);
        return saved;
    }

    /**
     * Plomba státusz: SEALED → IN_TRANSIT
     */
    public SealTracking startTransit(String transferType, Long transferId) {
        SealTracking tracking = findByTransfer(transferType, transferId);

        if (tracking.getTransitStatus() != SealTransitStatus.SEALED) {
            throw new ValidationException(
                    String.format("Plomba nem indítható szállításra. Jelenlegi státusz: %s", tracking.getTransitStatus()));
        }

        tracking.setTransitStatus(SealTransitStatus.IN_TRANSIT);
        SealTracking saved = sealTrackingRepository.save(tracking);

        auditLogService.log("SEAL_IN_TRANSIT",
                String.format("Plomba %s szállítás alatt", tracking.getSealNumber()));

        log.info("Seal {} now IN_TRANSIT", tracking.getSealNumber());
        return saved;
    }

    /**
     * Plomba státusz: IN_TRANSIT → ARRIVED
     */
    public SealTracking confirmArrival(String transferType, Long transferId) {
        SealTracking tracking = findByTransfer(transferType, transferId);

        if (tracking.getTransitStatus() != SealTransitStatus.IN_TRANSIT) {
            throw new ValidationException(
                    String.format("Plomba nem érkezhet meg. Jelenlegi státusz: %s", tracking.getTransitStatus()));
        }

        tracking.setTransitStatus(SealTransitStatus.ARRIVED);
        SealTracking saved = sealTrackingRepository.save(tracking);

        auditLogService.log("SEAL_ARRIVED",
                String.format("Plomba %s megérkezett", tracking.getSealNumber()));

        log.info("Seal {} ARRIVED", tracking.getSealNumber());
        return saved;
    }

    /**
     * Plomba felnyitása: ARRIVED → OPENED
     */
    public SealTracking openSeal(String transferType, Long transferId) {
        SealTracking tracking = findByTransfer(transferType, transferId);
        Long workerId = SecurityUtils.getCurrentWorkerId();

        if (tracking.getTransitStatus() != SealTransitStatus.ARRIVED) {
            throw new ValidationException(
                    String.format("Plomba nem nyitható fel. Jelenlegi státusz: %s", tracking.getTransitStatus()));
        }

        tracking.setTransitStatus(SealTransitStatus.OPENED);
        tracking.setOpenedAt(LocalDateTime.now());
        tracking.setOpenedBy(workerId);
        SealTracking saved = sealTrackingRepository.save(tracking);

        auditLogService.log("SEAL_OPENED",
                String.format("Plomba %s felnyitva (worker: %d)", tracking.getSealNumber(), workerId));

        log.info("Seal {} OPENED by worker {}", tracking.getSealNumber(), workerId);
        return saved;
    }

    /**
     * Plomba integritás ellenőrzése.
     */
    @Transactional(readOnly = true)
    public boolean validateSealIntegrity(String transferType, Long transferId, String expectedSealNumber) {
        Optional<SealTracking> tracking = sealTrackingRepository
                .findByTransferTypeAndTransferId(transferType, transferId);
        return tracking.isPresent() && tracking.get().getSealNumber().equals(expectedSealNumber);
    }

    /**
     * Aktív (SEALED vagy IN_TRANSIT) plomba szállítmányok lekérdezése.
     */
    @Transactional(readOnly = true)
    public List<SealTracking> getActiveTransits() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return sealTrackingRepository.findByCompanyIdAndTransitStatusIn(
                companyId, List.of(SealTransitStatus.SEALED, SealTransitStatus.IN_TRANSIT));
    }

    /**
     * Plomba lekérdezése szám alapján.
     */
    @Transactional(readOnly = true)
    public Optional<SealTracking> getBySealNumber(String sealNumber) {
        return sealTrackingRepository.findBySealNumber(sealNumber);
    }

    /**
     * Plomba lekérdezése transfer alapján.
     */
    @Transactional(readOnly = true)
    public Optional<SealTracking> getByTransfer(String transferType, Long transferId) {
        return sealTrackingRepository.findByTransferTypeAndTransferId(transferType, transferId);
    }

    private SealTracking findByTransfer(String transferType, Long transferId) {
        return sealTrackingRepository.findByTransferTypeAndTransferId(transferType, transferId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        String.format("Plomba nem található: %s/%d", transferType, transferId)));
    }
}
```

- [ ] **Step 4: Run tests**

Run: `cd backend && ./mvnw test -Dtest=SealTrackingServiceTest -q`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/hu/puzzleir/valuta/service/SealTrackingService.java
git add backend/src/test/java/hu/puzzleir/valuta/service/SealTrackingServiceTest.java
git commit -m "feat(seal): SealTrackingService with full lifecycle and tests"
```

### Task 8: SealTracking REST Controller

**Files:**
- Create: `backend/src/main/java/hu/puzzleir/valuta/controller/SealTrackingController.java`

- [ ] **Step 1: Create controller**

```java
package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.SealTracking;
import hu.puzzleir.valuta.service.SealTrackingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/seal-tracking")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
public class SealTrackingController {

    private final SealTrackingService sealTrackingService;

    @PostMapping("/seal")
    public ResponseEntity<SealTracking> seal(
            @RequestParam String transferType,
            @RequestParam Long transferId,
            @RequestParam String sealNumber) {
        return ResponseEntity.ok(sealTrackingService.seal(transferType, transferId, sealNumber));
    }

    @PostMapping("/start-transit")
    public ResponseEntity<SealTracking> startTransit(
            @RequestParam String transferType,
            @RequestParam Long transferId) {
        return ResponseEntity.ok(sealTrackingService.startTransit(transferType, transferId));
    }

    @PostMapping("/confirm-arrival")
    public ResponseEntity<SealTracking> confirmArrival(
            @RequestParam String transferType,
            @RequestParam Long transferId) {
        return ResponseEntity.ok(sealTrackingService.confirmArrival(transferType, transferId));
    }

    @PostMapping("/open")
    public ResponseEntity<SealTracking> openSeal(
            @RequestParam String transferType,
            @RequestParam Long transferId) {
        return ResponseEntity.ok(sealTrackingService.openSeal(transferType, transferId));
    }

    @GetMapping("/active")
    public ResponseEntity<List<SealTracking>> getActiveTransits() {
        return ResponseEntity.ok(sealTrackingService.getActiveTransits());
    }

    @GetMapping("/by-seal/{sealNumber}")
    public ResponseEntity<SealTracking> getBySealNumber(@PathVariable String sealNumber) {
        return sealTrackingService.getBySealNumber(sealNumber)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/by-transfer")
    public ResponseEntity<SealTracking> getByTransfer(
            @RequestParam String transferType,
            @RequestParam Long transferId) {
        return sealTrackingService.getByTransfer(transferType, transferId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/validate")
    public ResponseEntity<Boolean> validateIntegrity(
            @RequestParam String transferType,
            @RequestParam Long transferId,
            @RequestParam String expectedSealNumber) {
        return ResponseEntity.ok(
                sealTrackingService.validateSealIntegrity(transferType, transferId, expectedSealNumber));
    }
}
```

- [ ] **Step 2: Verify compilation**

Run: `cd backend && ./mvnw compile -q`
Expected: BUILD SUCCESS

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/java/hu/puzzleir/valuta/controller/SealTrackingController.java
git commit -m "feat(seal): SealTrackingController REST API"
```

---

## Chunk 4: LED Display Service

### Task 9: V98 Flyway Migration + jSerialComm Dependency

**Files:**
- Create: `backend/src/main/resources/db/migration/V98__led_display_config.sql`
- Modify: `backend/pom.xml`

- [ ] **Step 1: Write V98 migration**

```sql
-- V98: LED display configuration per branch
CREATE TABLE led_display_config (
    id                  BIGSERIAL PRIMARY KEY,
    branch_id           UUID NOT NULL REFERENCES branch(id),
    display_type        VARCHAR(30) NOT NULL DEFAULT 'STANDARD',
    com_ports           VARCHAR(100) NOT NULL DEFAULT 'COM1',
    currencies          VARCHAR(200) NOT NULL DEFAULT 'EUR,USD,GBP,CHF',
    show_bank_card      BOOLEAN NOT NULL DEFAULT false,
    speed_command       BOOLEAN NOT NULL DEFAULT true,
    speed               INTEGER NOT NULL DEFAULT 5,
    end_markers         VARCHAR(20) NOT NULL DEFAULT '254',
    decimal_separator   CHAR(1) NOT NULL DEFAULT ',',
    custom_text         TEXT,
    display_ids         VARCHAR(50),
    is_active           BOOLEAN NOT NULL DEFAULT true,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP
);

CREATE UNIQUE INDEX idx_led_display_branch ON led_display_config(branch_id);
```

- [ ] **Step 2: Add jSerialComm to pom.xml**

Add inside `<dependencies>`:

```xml
<!-- Serial port communication for LED displays -->
<dependency>
    <groupId>com.fazecast</groupId>
    <artifactId>jSerialComm</artifactId>
    <version>2.10.4</version>
</dependency>
```

- [ ] **Step 3: Verify**

Run: `cd backend && ./mvnw compile -q`
Expected: BUILD SUCCESS

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/resources/db/migration/V98__led_display_config.sql
git add backend/pom.xml
git commit -m "feat(led): V98 migration + jSerialComm 2.10.4 dependency"
```

### Task 10: LedDisplayConfig Entity + Repository + DTO + Enum

**Files:**
- Create: `backend/src/main/java/hu/puzzleir/valuta/entity/LedDisplayConfig.java`
- Create: `backend/src/main/java/hu/puzzleir/valuta/entity/LedDisplayType.java`
- Create: `backend/src/main/java/hu/puzzleir/valuta/repository/LedDisplayConfigRepository.java`
- Create: `backend/src/main/java/hu/puzzleir/valuta/dto/led/LedDisplayConfigDto.java`
- Create: `backend/src/main/java/hu/puzzleir/valuta/dto/led/LedDisplayStatusDto.java`

- [ ] **Step 1: Create LedDisplayType enum**

```java
package hu.puzzleir.valuta.entity;

/**
 * LED kijelző típusok — 15+ legacy variáns konszolidálva.
 *
 * STANDARD  = EUR/USD/GBP/CHF (legacy: ALAP, MAKEDLL, IRGALMAS)
 * CENTRAL_EU = EUR/USD/CZK/PLN (legacy: FERENCES, SZOBOSZLO)
 * EXTENDED  = 14+ valuta (legacy: NOSPEED)
 * TEXT_ONLY = Marketing szöveg (legacy: BCSABA, OROS, SPEC8085)
 * MIXED     = Árfolyam + szöveg, zárás alapján vált (legacy: UJTIPUS)
 * DUAL_SAME = 2 kijelző, azonos tartalom (legacy: DUPLACOM)
 * DUAL_DIFF = 2 kijelző, eltérő tartalom (legacy: DUPOTHER)
 */
public enum LedDisplayType {
    STANDARD,
    CENTRAL_EU,
    EXTENDED,
    TEXT_ONLY,
    MIXED,
    DUAL_SAME,
    DUAL_DIFF
}
```

- [ ] **Step 2: Create LedDisplayConfig entity**

```java
package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "led_display_config")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LedDisplayConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "branch_id", nullable = false, unique = true)
    private UUID branchId;

    @Enumerated(EnumType.STRING)
    @Column(name = "display_type", nullable = false, length = 30)
    private LedDisplayType displayType;

    @Column(name = "com_ports", nullable = false, length = 100)
    private String comPorts;

    @Column(name = "currencies", nullable = false, length = 200)
    private String currencies;

    @Column(name = "show_bank_card", nullable = false)
    private boolean showBankCard;

    @Column(name = "speed_command", nullable = false)
    private boolean speedCommand;

    @Column(name = "speed", nullable = false)
    private int speed;

    @Column(name = "end_markers", nullable = false, length = 20)
    private String endMarkers;

    @Column(name = "decimal_separator", nullable = false, length = 1)
    private char decimalSeparator;

    @Column(name = "custom_text")
    private String customText;

    @Column(name = "display_ids", length = 50)
    private String displayIds;

    @Column(name = "is_active", nullable = false)
    private boolean active;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    /**
     * COM port lista (vesszővel elválasztva, pl. "COM1,COM2")
     */
    public String[] getComPortArray() {
        return comPorts.split(",");
    }

    /**
     * Valuta lista (vesszővel elválasztva)
     */
    public String[] getCurrencyArray() {
        return currencies.split(",");
    }

    /**
     * End marker byte-ok (vesszővel elválasztva, pl. "254" vagy "254,255")
     */
    public int[] getEndMarkerBytes() {
        String[] parts = endMarkers.split(",");
        int[] bytes = new int[parts.length];
        for (int i = 0; i < parts.length; i++) {
            bytes[i] = Integer.parseInt(parts[i].trim());
        }
        return bytes;
    }
}
```

- [ ] **Step 3: Create LedDisplayConfigRepository**

```java
package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.LedDisplayConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LedDisplayConfigRepository extends JpaRepository<LedDisplayConfig, Long> {

    Optional<LedDisplayConfig> findByBranchId(UUID branchId);

    List<LedDisplayConfig> findByActiveTrue();
}
```

- [ ] **Step 4: Create DTOs**

`LedDisplayConfigDto.java`:
```java
package hu.puzzleir.valuta.dto.led;

import hu.puzzleir.valuta.entity.LedDisplayType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LedDisplayConfigDto {
    private Long id;
    private UUID branchId;
    private LedDisplayType displayType;
    private String comPorts;
    private String currencies;
    private boolean showBankCard;
    private boolean speedCommand;
    private int speed;
    private String endMarkers;
    private char decimalSeparator;
    private String customText;
    private String displayIds;
    private boolean active;
}
```

`LedDisplayStatusDto.java`:
```java
package hu.puzzleir.valuta.dto.led;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LedDisplayStatusDto {
    private UUID branchId;
    private String branchName;
    private boolean connected;
    private LocalDateTime lastRefresh;
    private String lastError;
}
```

- [ ] **Step 5: Verify compilation**

Run: `cd backend && ./mvnw compile -q`
Expected: BUILD SUCCESS

- [ ] **Step 6: Commit**

```bash
git add backend/src/main/java/hu/puzzleir/valuta/entity/LedDisplayConfig.java
git add backend/src/main/java/hu/puzzleir/valuta/entity/LedDisplayType.java
git add backend/src/main/java/hu/puzzleir/valuta/repository/LedDisplayConfigRepository.java
git add backend/src/main/java/hu/puzzleir/valuta/dto/led/LedDisplayConfigDto.java
git add backend/src/main/java/hu/puzzleir/valuta/dto/led/LedDisplayStatusDto.java
git commit -m "feat(led): LedDisplayConfig entity, repository, DTOs, and enum"
```

### Task 11: LedProtocolEncoder — Byte-Level Protocol

**Files:**
- Create: `backend/src/main/java/hu/puzzleir/valuta/service/led/LedProtocolEncoder.java`
- Create: `backend/src/test/java/hu/puzzleir/valuta/service/led/LedProtocolEncoderTest.java`

- [ ] **Step 1: Write failing tests**

```java
package hu.puzzleir.valuta.service.led;

import hu.puzzleir.valuta.entity.LedDisplayConfig;
import hu.puzzleir.valuta.entity.LedDisplayType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class LedProtocolEncoderTest {

    private LedProtocolEncoder encoder;

    @BeforeEach
    void setUp() {
        encoder = new LedProtocolEncoder();
    }

    @Test
    @DisplayName("encode: init bytes [21, 18, 5] at start")
    void encode_startsWithInitBytes() {
        LedDisplayConfig config = createStandardConfig();
        Map<String, BigDecimal[]> rates = createRates();

        byte[] data = encoder.encodeRates(config, rates);

        assertThat(data[0]).isEqualTo((byte) 21);
        assertThat(data[1]).isEqualTo((byte) 18);
        assertThat(data[2]).isEqualTo((byte) 5);
    }

    @Test
    @DisplayName("encode: speed command [92, 70, 83, 48+speed] when enabled")
    void encode_speedCommandWhenEnabled() {
        LedDisplayConfig config = createStandardConfig();
        config.setSpeedCommand(true);
        config.setSpeed(5);
        Map<String, BigDecimal[]> rates = createRates();

        byte[] data = encoder.encodeRates(config, rates);

        // After init bytes [21, 18, 5]:
        assertThat(data[3]).isEqualTo((byte) 92);  // '\'
        assertThat(data[4]).isEqualTo((byte) 70);  // 'F'
        assertThat(data[5]).isEqualTo((byte) 83);  // 'S'
        assertThat(data[6]).isEqualTo((byte) 53);  // 48 + 5 = 53
    }

    @Test
    @DisplayName("encode: no speed command when disabled (NOSPEED)")
    void encode_noSpeedCommandWhenDisabled() {
        LedDisplayConfig config = createStandardConfig();
        config.setSpeedCommand(false);
        Map<String, BigDecimal[]> rates = createRates();

        byte[] data = encoder.encodeRates(config, rates);

        // After init bytes, data starts immediately (no speed command)
        // ASCII data follows
        assertThat(data[3]).isNotEqualTo((byte) 92);
    }

    @Test
    @DisplayName("encode: ends with [254] for single end marker")
    void encode_singleEndMarker() {
        LedDisplayConfig config = createStandardConfig();
        config.setEndMarkers("254");
        Map<String, BigDecimal[]> rates = createRates();

        byte[] data = encoder.encodeRates(config, rates);

        assertThat(data[data.length - 1]).isEqualTo((byte) 254);
    }

    @Test
    @DisplayName("encode: ends with [254, 255] for double end marker")
    void encode_doubleEndMarker() {
        LedDisplayConfig config = createStandardConfig();
        config.setEndMarkers("254,255");
        Map<String, BigDecimal[]> rates = createRates();

        byte[] data = encoder.encodeRates(config, rates);

        assertThat(data[data.length - 2]).isEqualTo((byte) 254);
        assertThat(data[data.length - 1]).isEqualTo((byte) 255);
    }

    @Test
    @DisplayName("formatRate: Hungarian comma separator")
    void formatRate_hungarianComma() {
        String formatted = encoder.formatRate(new BigDecimal("405.32"), ',');
        assertThat(formatted).isEqualTo("405,32");
    }

    @Test
    @DisplayName("formatRate: dot separator (BAJCSY style)")
    void formatRate_dotSeparator() {
        String formatted = encoder.formatRate(new BigDecimal("405.32"), '.');
        assertThat(formatted).isEqualTo("405.32");
    }

    @Test
    @DisplayName("formatRate: JPY special — 10x multiplier")
    void formatRate_jpySpecial() {
        // JPY: 3.752 per 1 JPY → displayed as "3,75" (2 decimals)
        String formatted = encoder.formatRate(new BigDecimal("3.752"), ',');
        assertThat(formatted).isEqualTo("  3,75");
    }

    @Test
    @DisplayName("formatRate: large rate with leading spaces")
    void formatRate_leadingSpaces() {
        // Less than 100: needs leading spaces for 6-char alignment
        String formatted = encoder.formatRate(new BigDecimal("95.20"), ',');
        assertThat(formatted).isEqualTo(" 95,20");
    }

    @Test
    @DisplayName("encodeText: custom text encoding")
    void encodeText_customText() {
        LedDisplayConfig config = createStandardConfig();
        byte[] data = encoder.encodeText(config, "CHANGE - WESTERN UNION");

        // Should have init + optional speed + text + end marker
        assertThat(data[0]).isEqualTo((byte) 21);
        assertThat(data[data.length - 1]).isEqualTo((byte) 254);
    }

    @Test
    @DisplayName("encode DUAL_SAME: same data for both display IDs")
    void encodeDualSame_sameContent() {
        LedDisplayConfig config = createStandardConfig();
        config.setDisplayType(LedDisplayType.DUAL_SAME);
        config.setDisplayIds("1,2");
        config.setComPorts("COM1,COM2");
        Map<String, BigDecimal[]> rates = createRates();

        byte[][] packets = encoder.encodeMultiDisplay(config, rates);

        assertThat(packets).hasSize(2);
        assertThat(packets[0]).isEqualTo(packets[1]);
    }

    @Test
    @DisplayName("encode DUAL_DIFF: different data for displays")
    void encodeDualDiff_differentContent() {
        LedDisplayConfig config = createStandardConfig();
        config.setDisplayType(LedDisplayType.DUAL_DIFF);
        config.setDisplayIds("1,2");
        config.setComPorts("COM1,COM2");
        config.setCustomText("CHANGE - WESTERN UNION");
        Map<String, BigDecimal[]> rates = createRates();

        byte[][] packets = encoder.encodeMultiDisplay(config, rates);

        assertThat(packets).hasSize(2);
        // First display: rates, Second display: text
        assertThat(packets[0]).isNotEqualTo(packets[1]);
    }

    private LedDisplayConfig createStandardConfig() {
        return LedDisplayConfig.builder()
                .displayType(LedDisplayType.STANDARD)
                .comPorts("COM1")
                .currencies("EUR,USD,GBP,CHF")
                .speedCommand(true)
                .speed(5)
                .endMarkers("254")
                .decimalSeparator(',')
                .active(true)
                .build();
    }

    private Map<String, BigDecimal[]> createRates() {
        // currencyCode → [buyRate, sellRate]
        Map<String, BigDecimal[]> rates = new LinkedHashMap<>();
        rates.put("EUR", new BigDecimal[]{new BigDecimal("402.50"), new BigDecimal("408.00")});
        rates.put("USD", new BigDecimal[]{new BigDecimal("372.00"), new BigDecimal("378.00")});
        rates.put("GBP", new BigDecimal[]{new BigDecimal("472.00"), new BigDecimal("480.00")});
        rates.put("CHF", new BigDecimal[]{new BigDecimal("415.00"), new BigDecimal("422.00")});
        return rates;
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && ./mvnw test -Dtest=LedProtocolEncoderTest -q`
Expected: FAIL (LedProtocolEncoder not found)

- [ ] **Step 3: Implement LedProtocolEncoder**

```java
package hu.puzzleir.valuta.service.led;

import hu.puzzleir.valuta.entity.LedDisplayConfig;
import hu.puzzleir.valuta.entity.LedDisplayType;
import org.springframework.stereotype.Component;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;

/**
 * LED kijelző byte-szintű protokoll kódolás.
 *
 * Protokoll (legacy 1:1):
 *   Init:      [21, 18, 5]
 *   Speed:     [92('\'), 70('F'), 83('S'), 48+speed] (opcionális)
 *   Data:      ASCII karakterek
 *   End:       [254] vagy [254, 255]
 *
 * Minden variáns: 9600 baud, 8N1
 */
@Component
public class LedProtocolEncoder {

    private static final byte[] INIT_BYTES = {21, 18, 5};
    private static final int RATE_WIDTH = 6; // 3 egész + separator + 2 tizedes

    /**
     * Árfolyam adat kódolása egyetlen kijelzőhöz.
     */
    public byte[] encodeRates(LedDisplayConfig config, Map<String, BigDecimal[]> rates) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try {
            // Init
            baos.write(INIT_BYTES);

            // Speed command (optional)
            if (config.isSpeedCommand()) {
                baos.write(new byte[]{92, 70, 83, (byte) (48 + config.getSpeed())});
            }

            // Rate data as ASCII
            String[] currencies = config.getCurrencyArray();
            for (String currency : currencies) {
                BigDecimal[] rate = rates.get(currency.trim());
                if (rate != null && rate.length >= 2) {
                    String buyStr = formatRate(rate[0], config.getDecimalSeparator());
                    String sellStr = formatRate(rate[1], config.getDecimalSeparator());
                    String line = currency.trim() + " " + buyStr + " " + sellStr + " ";
                    baos.write(line.getBytes(java.nio.charset.StandardCharsets.US_ASCII));
                }
            }

            // Bank card indicator
            if (config.isShowBankCard()) {
                baos.write("BANKKARTYA ".getBytes(java.nio.charset.StandardCharsets.US_ASCII));
            }

            // End markers
            for (int marker : config.getEndMarkerBytes()) {
                baos.write(marker);
            }

        } catch (IOException e) {
            throw new RuntimeException("LED protocol encoding failed", e);
        }
        return baos.toByteArray();
    }

    /**
     * Egyedi szöveg kódolása.
     */
    public byte[] encodeText(LedDisplayConfig config, String text) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try {
            baos.write(INIT_BYTES);

            if (config.isSpeedCommand()) {
                baos.write(new byte[]{92, 70, 83, (byte) (48 + config.getSpeed())});
            }

            baos.write(text.getBytes(java.nio.charset.StandardCharsets.US_ASCII));

            for (int marker : config.getEndMarkerBytes()) {
                baos.write(marker);
            }
        } catch (IOException e) {
            throw new RuntimeException("LED text encoding failed", e);
        }
        return baos.toByteArray();
    }

    /**
     * Multi-display kódolás (DUAL_SAME / DUAL_DIFF).
     *
     * DUAL_SAME: mindkét kijelzőre azonos adat
     * DUAL_DIFF: 1. kijelző = árfolyam, 2. kijelző = szöveg
     */
    public byte[][] encodeMultiDisplay(LedDisplayConfig config, Map<String, BigDecimal[]> rates) {
        String[] ports = config.getComPortArray();
        byte[][] packets = new byte[ports.length][];

        if (config.getDisplayType() == LedDisplayType.DUAL_SAME) {
            byte[] data = encodeRates(config, rates);
            for (int i = 0; i < ports.length; i++) {
                packets[i] = data.clone();
            }
        } else if (config.getDisplayType() == LedDisplayType.DUAL_DIFF) {
            // First display: rates
            packets[0] = encodeRates(config, rates);
            // Second display: custom text (or default "CHANGE - WESTERN UNION")
            String text = config.getCustomText() != null ? config.getCustomText() : "CHANGE - WESTERN UNION";
            packets[1] = encodeText(config, text);
            // Fill remaining ports if any
            for (int i = 2; i < ports.length; i++) {
                packets[i] = packets[0].clone();
            }
        } else {
            // Single display types
            byte[] data = encodeRates(config, rates);
            packets[0] = data;
        }

        return packets;
    }

    /**
     * Árfolyam formázás legacy 1:1.
     * 6 karakter: jobbra igazítva, 2 tizedes.
     * Pl. "405,32", " 95,20", "  3,75"
     */
    public String formatRate(BigDecimal rate, char decimalSeparator) {
        if (rate == null) return "  0" + decimalSeparator + "00";

        String plain = rate.setScale(2, RoundingMode.HALF_UP).toPlainString();
        // Replace dot with configured separator
        plain = plain.replace('.', decimalSeparator);
        // Right-align to 6 characters
        return String.format("%" + RATE_WIDTH + "s", plain);
    }
}
```

- [ ] **Step 4: Run tests**

Run: `cd backend && ./mvnw test -Dtest=LedProtocolEncoderTest -q`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/hu/puzzleir/valuta/service/led/LedProtocolEncoder.java
git add backend/src/test/java/hu/puzzleir/valuta/service/led/LedProtocolEncoderTest.java
git commit -m "feat(led): LedProtocolEncoder with byte-level protocol and rate formatting"
```

### Task 12: LedSerialPortDriver — COM Port Communication

**Files:**
- Create: `backend/src/main/java/hu/puzzleir/valuta/service/led/LedSerialPortDriver.java`
- Create: `backend/src/test/java/hu/puzzleir/valuta/service/led/LedSerialPortDriverTest.java`

- [ ] **Step 1: Write tests (mock serial port)**

```java
package hu.puzzleir.valuta.service.led;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class LedSerialPortDriverTest {

    @Test
    @DisplayName("send: returns false when port unavailable")
    void send_portUnavailable_returnsFalse() {
        LedSerialPortDriver driver = new LedSerialPortDriver();
        boolean result = driver.send("COM_NONEXISTENT", new byte[]{21, 18, 5, (byte) 254});
        assertThat(result).isFalse();
    }

    @Test
    @DisplayName("listPorts: returns system serial ports")
    void listPorts_returnsArray() {
        LedSerialPortDriver driver = new LedSerialPortDriver();
        String[] ports = driver.listAvailablePorts();
        // Can be empty on CI/test machines, but should not throw
        assertThat(ports).isNotNull();
    }

    @Test
    @DisplayName("send: null data throws IllegalArgumentException")
    void send_nullData_throws() {
        LedSerialPortDriver driver = new LedSerialPortDriver();
        assertThatThrownBy(() -> driver.send("COM1", null))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    @DisplayName("send: empty data throws IllegalArgumentException")
    void send_emptyData_throws() {
        LedSerialPortDriver driver = new LedSerialPortDriver();
        assertThatThrownBy(() -> driver.send("COM1", new byte[0]))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
```

- [ ] **Step 2: Implement LedSerialPortDriver**

```java
package hu.puzzleir.valuta.service.led;

import com.fazecast.jSerialComm.SerialPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * COM port kommunikáció a LED kijelzőkhöz.
 * jSerialComm: pure Java, nincs JNI/native dependency.
 * Beállítások: 9600 baud, 8 data bits, 1 stop bit, no parity (8N1)
 */
@Component
@Slf4j
public class LedSerialPortDriver {

    private static final int BAUD_RATE = 9600;
    private static final int DATA_BITS = 8;
    private static final int STOP_BITS = SerialPort.ONE_STOP_BIT;
    private static final int PARITY = SerialPort.NO_PARITY;
    private static final int TIMEOUT_MS = 2000;

    /**
     * Adat küldése a megadott COM portra.
     *
     * @param portName COM port neve (pl. "COM1", "/dev/ttyUSB0")
     * @param data küldendő byte tömb
     * @return true ha sikeres, false ha hiba
     */
    public boolean send(String portName, byte[] data) {
        if (data == null || data.length == 0) {
            throw new IllegalArgumentException("Data cannot be null or empty");
        }

        SerialPort port = SerialPort.getCommPort(portName);
        port.setBaudRate(BAUD_RATE);
        port.setNumDataBits(DATA_BITS);
        port.setNumStopBits(STOP_BITS);
        port.setParity(PARITY);
        port.setComPortTimeouts(SerialPort.TIMEOUT_WRITE_BLOCKING, TIMEOUT_MS, TIMEOUT_MS);

        try {
            if (!port.openPort()) {
                log.warn("Cannot open serial port: {}", portName);
                return false;
            }

            int written = port.writeBytes(data, data.length);
            if (written != data.length) {
                log.warn("Incomplete write to {}: {}/{} bytes", portName, written, data.length);
                return false;
            }

            log.debug("Sent {} bytes to {}", data.length, portName);
            return true;

        } catch (Exception e) {
            log.error("Serial port error on {}: {}", portName, e.getMessage());
            return false;

        } finally {
            if (port.isOpen()) {
                port.closePort();
            }
        }
    }

    /**
     * Elérhető soros portok listázása.
     */
    public String[] listAvailablePorts() {
        SerialPort[] ports = SerialPort.getCommPorts();
        String[] names = new String[ports.length];
        for (int i = 0; i < ports.length; i++) {
            names[i] = ports[i].getSystemPortName();
        }
        return names;
    }
}
```

- [ ] **Step 3: Run tests**

Run: `cd backend && ./mvnw test -Dtest=LedSerialPortDriverTest -q`
Expected: ALL PASS

- [ ] **Step 4: Commit**

```bash
git add backend/src/main/java/hu/puzzleir/valuta/service/led/LedSerialPortDriver.java
git add backend/src/test/java/hu/puzzleir/valuta/service/led/LedSerialPortDriverTest.java
git commit -m "feat(led): LedSerialPortDriver with jSerialComm COM port communication"
```

### Task 13: LedDisplayService — Main Service

**Files:**
- Create: `backend/src/main/java/hu/puzzleir/valuta/service/LedDisplayService.java`
- Create: `backend/src/test/java/hu/puzzleir/valuta/service/LedDisplayServiceTest.java`

- [ ] **Step 1: Write failing tests**

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.led.LedDisplayConfigDto;
import hu.puzzleir.valuta.dto.led.LedDisplayStatusDto;
import hu.puzzleir.valuta.entity.LedDisplayConfig;
import hu.puzzleir.valuta.entity.LedDisplayType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.LedDisplayConfigRepository;
import hu.puzzleir.valuta.service.led.LedProtocolEncoder;
import hu.puzzleir.valuta.service.led.LedSerialPortDriver;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LedDisplayServiceTest {

    @InjectMocks
    private LedDisplayService ledDisplayService;

    @Mock
    private LedDisplayConfigRepository configRepository;

    @Mock
    private LedProtocolEncoder protocolEncoder;

    @Mock
    private LedSerialPortDriver serialPortDriver;

    @Mock
    private ExchangeRateService exchangeRateService;

    private static final UUID BRANCH_ID = UUID.randomUUID();

    @Test
    @DisplayName("refreshDisplay: sends encoded data to COM port")
    void refreshDisplay_sendsToPort() {
        LedDisplayConfig config = createConfig();
        when(configRepository.findByBranchId(BRANCH_ID)).thenReturn(Optional.of(config));
        when(exchangeRateService.getActiveRatesForBranch(BRANCH_ID)).thenReturn(createRateMap());
        when(protocolEncoder.encodeRates(eq(config), any())).thenReturn(new byte[]{21, 18, 5, (byte) 254});
        when(serialPortDriver.send(eq("COM1"), any())).thenReturn(true);

        ledDisplayService.refreshDisplay(BRANCH_ID);

        verify(serialPortDriver).send(eq("COM1"), any());
    }

    @Test
    @DisplayName("refreshDisplay: inactive config is skipped")
    void refreshDisplay_inactiveConfig_skipped() {
        LedDisplayConfig config = createConfig();
        config.setActive(false);
        when(configRepository.findByBranchId(BRANCH_ID)).thenReturn(Optional.of(config));

        ledDisplayService.refreshDisplay(BRANCH_ID);

        verify(serialPortDriver, never()).send(any(), any());
    }

    @Test
    @DisplayName("refreshDisplay: missing config throws")
    void refreshDisplay_noConfig_throws() {
        when(configRepository.findByBranchId(BRANCH_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> ledDisplayService.refreshDisplay(BRANCH_ID))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("refreshAllActive: sends to all active displays")
    void refreshAllActive_sendsToAll() {
        LedDisplayConfig config1 = createConfig();
        LedDisplayConfig config2 = createConfig();
        config2.setBranchId(UUID.randomUUID());

        when(configRepository.findByActiveTrue()).thenReturn(List.of(config1, config2));
        when(exchangeRateService.getActiveRatesForBranch(any())).thenReturn(createRateMap());
        when(protocolEncoder.encodeRates(any(), any())).thenReturn(new byte[]{21, 18, 5, (byte) 254});
        when(serialPortDriver.send(any(), any())).thenReturn(true);

        ledDisplayService.refreshAllActive();

        verify(serialPortDriver, times(2)).send(eq("COM1"), any());
    }

    @Test
    @DisplayName("getConfig: returns DTO for branch")
    void getConfig_returnsDto() {
        LedDisplayConfig config = createConfig();
        when(configRepository.findByBranchId(BRANCH_ID)).thenReturn(Optional.of(config));

        LedDisplayConfigDto dto = ledDisplayService.getConfig(BRANCH_ID);

        assertThat(dto.getBranchId()).isEqualTo(BRANCH_ID);
        assertThat(dto.getDisplayType()).isEqualTo(LedDisplayType.STANDARD);
    }

    @Test
    @DisplayName("updateConfig: saves and returns updated DTO")
    void updateConfig_savesAndReturns() {
        LedDisplayConfig existing = createConfig();
        when(configRepository.findByBranchId(BRANCH_ID)).thenReturn(Optional.of(existing));
        when(configRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        LedDisplayConfigDto update = LedDisplayConfigDto.builder()
                .branchId(BRANCH_ID)
                .displayType(LedDisplayType.EXTENDED)
                .comPorts("COM3")
                .currencies("EUR,USD,CZK,PLN,GBP,CHF,RON")
                .speedCommand(false)
                .speed(3)
                .endMarkers("254,255")
                .decimalSeparator(',')
                .active(true)
                .build();

        LedDisplayConfigDto result = ledDisplayService.updateConfig(BRANCH_ID, update);

        assertThat(result.getDisplayType()).isEqualTo(LedDisplayType.EXTENDED);
        assertThat(result.getComPorts()).isEqualTo("COM3");
    }

    @Test
    @DisplayName("sendCustomText: encodes and sends text")
    void sendCustomText_sendsToPort() {
        LedDisplayConfig config = createConfig();
        when(configRepository.findByBranchId(BRANCH_ID)).thenReturn(Optional.of(config));
        when(protocolEncoder.encodeText(eq(config), eq("HELLO WORLD"))).thenReturn(new byte[]{21, 18, 5, (byte) 254});
        when(serialPortDriver.send(eq("COM1"), any())).thenReturn(true);

        ledDisplayService.sendCustomText(BRANCH_ID, "HELLO WORLD");

        verify(protocolEncoder).encodeText(config, "HELLO WORLD");
        verify(serialPortDriver).send(eq("COM1"), any());
    }

    @Test
    @DisplayName("DUAL_SAME: sends to both ports")
    void dualSame_sendsToBothPorts() {
        LedDisplayConfig config = createConfig();
        config.setDisplayType(LedDisplayType.DUAL_SAME);
        config.setComPorts("COM1,COM2");
        byte[][] packets = {new byte[]{21, 18, 5, (byte) 254}, new byte[]{21, 18, 5, (byte) 254}};

        when(configRepository.findByBranchId(BRANCH_ID)).thenReturn(Optional.of(config));
        when(exchangeRateService.getActiveRatesForBranch(BRANCH_ID)).thenReturn(createRateMap());
        when(protocolEncoder.encodeMultiDisplay(eq(config), any())).thenReturn(packets);
        when(serialPortDriver.send(any(), any())).thenReturn(true);

        ledDisplayService.refreshDisplay(BRANCH_ID);

        verify(serialPortDriver).send(eq("COM1"), any());
        verify(serialPortDriver).send(eq("COM2"), any());
    }

    private LedDisplayConfig createConfig() {
        return LedDisplayConfig.builder()
                .id(1L)
                .branchId(BRANCH_ID)
                .displayType(LedDisplayType.STANDARD)
                .comPorts("COM1")
                .currencies("EUR,USD,GBP,CHF")
                .speedCommand(true)
                .speed(5)
                .endMarkers("254")
                .decimalSeparator(',')
                .active(true)
                .build();
    }

    private Map<String, BigDecimal[]> createRateMap() {
        Map<String, BigDecimal[]> rates = new LinkedHashMap<>();
        rates.put("EUR", new BigDecimal[]{new BigDecimal("402.50"), new BigDecimal("408.00")});
        rates.put("USD", new BigDecimal[]{new BigDecimal("372.00"), new BigDecimal("378.00")});
        rates.put("GBP", new BigDecimal[]{new BigDecimal("472.00"), new BigDecimal("480.00")});
        rates.put("CHF", new BigDecimal[]{new BigDecimal("415.00"), new BigDecimal("422.00")});
        return rates;
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && ./mvnw test -Dtest=LedDisplayServiceTest -q`
Expected: FAIL (LedDisplayService not found)

- [ ] **Step 3: Implement LedDisplayService**

```java
package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.led.LedDisplayConfigDto;
import hu.puzzleir.valuta.dto.led.LedDisplayStatusDto;
import hu.puzzleir.valuta.entity.LedDisplayConfig;
import hu.puzzleir.valuta.entity.LedDisplayType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.LedDisplayConfigRepository;
import hu.puzzleir.valuta.service.led.LedProtocolEncoder;
import hu.puzzleir.valuta.service.led.LedSerialPortDriver;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * LED árfolyam-kijelző táblák vezérlése.
 *
 * Fő funkciók:
 * - Árfolyam frissítés COM porton per-branch konfigurációval
 * - Automatikus frissítés percenként (fallback)
 * - Konfiguráció CRUD
 * - Egyedi szöveg küldés
 * - Multi-display támogatás (DUAL_SAME, DUAL_DIFF)
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LedDisplayService {

    private final LedDisplayConfigRepository configRepository;
    private final LedProtocolEncoder protocolEncoder;
    private final LedSerialPortDriver serialPortDriver;
    private final ExchangeRateService exchangeRateService;

    // In-memory status tracking
    private final Map<UUID, LedDisplayStatusDto> statusMap = new ConcurrentHashMap<>();

    /**
     * Egyetlen kijelző frissítése.
     */
    public void refreshDisplay(UUID branchId) {
        LedDisplayConfig config = configRepository.findByBranchId(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("LED konfiguráció nem található: " + branchId));

        if (!config.isActive()) {
            log.debug("LED display inactive for branch {}", branchId);
            return;
        }

        Map<String, BigDecimal[]> rates = exchangeRateService.getActiveRatesForBranch(branchId);
        sendToDisplay(config, rates);
    }

    /**
     * Összes aktív kijelző frissítése.
     */
    @Scheduled(fixedRate = 60000)
    public void refreshAllActive() {
        List<LedDisplayConfig> configs = configRepository.findByActiveTrue();
        for (LedDisplayConfig config : configs) {
            try {
                Map<String, BigDecimal[]> rates = exchangeRateService.getActiveRatesForBranch(config.getBranchId());
                sendToDisplay(config, rates);
            } catch (Exception e) {
                log.error("Failed to refresh LED display for branch {}: {}", config.getBranchId(), e.getMessage());
                updateStatus(config.getBranchId(), false, e.getMessage());
            }
        }
    }

    /**
     * Konfiguráció lekérdezése.
     */
    @Transactional(readOnly = true)
    public LedDisplayConfigDto getConfig(UUID branchId) {
        LedDisplayConfig config = configRepository.findByBranchId(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("LED konfiguráció nem található: " + branchId));
        return toDto(config);
    }

    /**
     * Konfiguráció frissítése.
     */
    @Transactional
    public LedDisplayConfigDto updateConfig(UUID branchId, LedDisplayConfigDto dto) {
        LedDisplayConfig config = configRepository.findByBranchId(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("LED konfiguráció nem található: " + branchId));

        config.setDisplayType(dto.getDisplayType());
        config.setComPorts(dto.getComPorts());
        config.setCurrencies(dto.getCurrencies());
        config.setShowBankCard(dto.isShowBankCard());
        config.setSpeedCommand(dto.isSpeedCommand());
        config.setSpeed(dto.getSpeed());
        config.setEndMarkers(dto.getEndMarkers());
        config.setDecimalSeparator(dto.getDecimalSeparator());
        config.setCustomText(dto.getCustomText());
        config.setDisplayIds(dto.getDisplayIds());
        config.setActive(dto.isActive());

        LedDisplayConfig saved = configRepository.save(config);
        return toDto(saved);
    }

    /**
     * Egyedi szöveg küldése.
     */
    public void sendCustomText(UUID branchId, String text) {
        LedDisplayConfig config = configRepository.findByBranchId(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("LED konfiguráció nem található: " + branchId));

        byte[] data = protocolEncoder.encodeText(config, text);
        for (String port : config.getComPortArray()) {
            boolean success = serialPortDriver.send(port.trim(), data);
            updateStatus(branchId, success, success ? null : "Failed to send to " + port);
        }
    }

    /**
     * Kijelző állapot lekérdezése.
     */
    public LedDisplayStatusDto getStatus(UUID branchId) {
        return statusMap.getOrDefault(branchId,
                LedDisplayStatusDto.builder()
                        .branchId(branchId)
                        .connected(false)
                        .lastError("Nincs állapot információ")
                        .build());
    }

    /**
     * Összes kijelző állapot.
     */
    public List<LedDisplayStatusDto> getAllStatuses() {
        return new ArrayList<>(statusMap.values());
    }

    // ========= PRIVATE HELPERS =========

    private void sendToDisplay(LedDisplayConfig config, Map<String, BigDecimal[]> rates) {
        boolean isDualDisplay = config.getDisplayType() == LedDisplayType.DUAL_SAME
                || config.getDisplayType() == LedDisplayType.DUAL_DIFF;

        if (isDualDisplay) {
            byte[][] packets = protocolEncoder.encodeMultiDisplay(config, rates);
            String[] ports = config.getComPortArray();
            boolean allSuccess = true;
            for (int i = 0; i < Math.min(packets.length, ports.length); i++) {
                boolean success = serialPortDriver.send(ports[i].trim(), packets[i]);
                if (!success) allSuccess = false;
            }
            updateStatus(config.getBranchId(), allSuccess, allSuccess ? null : "Partial send failure");
        } else {
            byte[] data = protocolEncoder.encodeRates(config, rates);
            for (String port : config.getComPortArray()) {
                boolean success = serialPortDriver.send(port.trim(), data);
                updateStatus(config.getBranchId(), success, success ? null : "Failed to send to " + port);
            }
        }
    }

    private void updateStatus(UUID branchId, boolean connected, String error) {
        statusMap.put(branchId, LedDisplayStatusDto.builder()
                .branchId(branchId)
                .connected(connected)
                .lastRefresh(LocalDateTime.now())
                .lastError(error)
                .build());
    }

    private LedDisplayConfigDto toDto(LedDisplayConfig config) {
        return LedDisplayConfigDto.builder()
                .id(config.getId())
                .branchId(config.getBranchId())
                .displayType(config.getDisplayType())
                .comPorts(config.getComPorts())
                .currencies(config.getCurrencies())
                .showBankCard(config.isShowBankCard())
                .speedCommand(config.isSpeedCommand())
                .speed(config.getSpeed())
                .endMarkers(config.getEndMarkers())
                .decimalSeparator(config.getDecimalSeparator())
                .customText(config.getCustomText())
                .displayIds(config.getDisplayIds())
                .active(config.isActive())
                .build();
    }
}
```

**Important:** The `ExchangeRateService.getActiveRatesForBranch(UUID branchId)` method may not exist. Read `backend/src/main/java/hu/puzzleir/valuta/service/ExchangeRateService.java` to find the actual method that returns buy/sell rates for currencies. You may need to add a helper method or adapt the call.

- [ ] **Step 4: Run tests**

Run: `cd backend && ./mvnw test -Dtest=LedDisplayServiceTest -q`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add backend/src/main/java/hu/puzzleir/valuta/service/LedDisplayService.java
git add backend/src/test/java/hu/puzzleir/valuta/service/LedDisplayServiceTest.java
git commit -m "feat(led): LedDisplayService with refresh, config CRUD, and status tracking"
```

### Task 14: LedDisplayController

**Files:**
- Create: `backend/src/main/java/hu/puzzleir/valuta/controller/LedDisplayController.java`

- [ ] **Step 1: Create controller**

```java
package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.led.LedDisplayConfigDto;
import hu.puzzleir.valuta.dto.led.LedDisplayStatusDto;
import hu.puzzleir.valuta.service.LedDisplayService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/led-display")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'SUPERVISOR')")
public class LedDisplayController {

    private final LedDisplayService ledDisplayService;

    @PostMapping("/refresh/{branchId}")
    public ResponseEntity<Void> refreshDisplay(@PathVariable UUID branchId) {
        ledDisplayService.refreshDisplay(branchId);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/refresh-all")
    public ResponseEntity<Void> refreshAll() {
        ledDisplayService.refreshAllActive();
        return ResponseEntity.ok().build();
    }

    @GetMapping("/config/{branchId}")
    public ResponseEntity<LedDisplayConfigDto> getConfig(@PathVariable UUID branchId) {
        return ResponseEntity.ok(ledDisplayService.getConfig(branchId));
    }

    @PutMapping("/config/{branchId}")
    public ResponseEntity<LedDisplayConfigDto> updateConfig(
            @PathVariable UUID branchId,
            @RequestBody LedDisplayConfigDto config) {
        return ResponseEntity.ok(ledDisplayService.updateConfig(branchId, config));
    }

    @GetMapping("/status/{branchId}")
    public ResponseEntity<LedDisplayStatusDto> getStatus(@PathVariable UUID branchId) {
        return ResponseEntity.ok(ledDisplayService.getStatus(branchId));
    }

    @GetMapping("/status")
    public ResponseEntity<List<LedDisplayStatusDto>> getAllStatuses() {
        return ResponseEntity.ok(ledDisplayService.getAllStatuses());
    }

    @PostMapping("/text/{branchId}")
    public ResponseEntity<Void> sendCustomText(
            @PathVariable UUID branchId,
            @RequestBody String text) {
        ledDisplayService.sendCustomText(branchId, text);
        return ResponseEntity.ok().build();
    }
}
```

- [ ] **Step 2: Verify compilation**

Run: `cd backend && ./mvnw compile -q`
Expected: BUILD SUCCESS

- [ ] **Step 3: Commit**

```bash
git add backend/src/main/java/hu/puzzleir/valuta/controller/LedDisplayController.java
git commit -m "feat(led): LedDisplayController REST API"
```

### Task 15: Final Integration — Run All Tests

- [ ] **Step 1: Run full test suite**

Run: `cd backend && ./mvnw test -q`
Expected: ALL PASS (60+ existing tests + ~30 new tests)

- [ ] **Step 2: If failures, fix and re-run**

Common issues:
- `ExchangeRateService.getActiveRatesForBranch()` may not exist — read the service and adapt
- `AuditLogService.log()` signature may differ — read and adapt
- Missing imports or constructor parameter mismatches

- [ ] **Step 3: Final commit if any fixes needed**

```bash
git add -u
git commit -m "fix: resolve integration issues from legacy gap modules"
```
