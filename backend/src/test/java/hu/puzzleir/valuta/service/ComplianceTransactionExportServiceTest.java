package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionRowDto;
import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FS-11 S1: CSV/XLSX compliance tranzakció-export artefakt tesztek.
 */
class ComplianceTransactionExportServiceTest {

    private final ComplianceTransactionExportService service = new ComplianceTransactionExportService();

    @Test
    @DisplayName("FS-11 S1: CSV UTF-8 BOM, magyar fejléc, pontos escaping és BigDecimal toPlainString")
    void csvHasBomHeaderEscapingAndPlainDecimals() {
        byte[] bytes = service.toCsv(List.of(row("Kovács;\"Béla\"", new BigDecimal("12345678901234567890.12"))));

        assertThat(bytes[0]).isEqualTo((byte) 0xEF);
        assertThat(bytes[1]).isEqualTo((byte) 0xBB);
        assertThat(bytes[2]).isEqualTo((byte) 0xBF);
        String csv = new String(bytes, StandardCharsets.UTF_8);

        assertThat(csv).startsWith("\uFEFFBizonylatszám;Típus;Státusz;Dátum;Idő;Iroda;Valuta");
        assertThat(csv.lines()).hasSize(2);
        assertThat(csv).contains("\"Kovács;\"\"Béla\"\"\"");
        assertThat(csv).contains("12345678901234567890.12");
        assertThat(csv).contains(";igen;igen;igen;igen;igen;");
    }

    @Test
    @DisplayName("FS-11 S1: CSV export neutralizálja a képlet-injection ügyfélnevet")
    void csvNeutralizesFormulaInjectionCustomerName() {
        byte[] bytes = service.toCsv(List.of(row("=CMD(\"calc\")", new BigDecimal("4937.52"))));

        String csv = new String(bytes, StandardCharsets.UTF_8);

        assertThat(csv).contains(";\"'=CMD(\"\"calc\"\")\";");
        assertThat(csv).doesNotContain(";=CMD(");
    }

    @Test
    @DisplayName("FS-11 S1: XLSX visszaolvasható, magyar sheet/header, HUF numerikus, dátum string")
    void xlsxIsReadableWithNumericHufAndDateString() throws Exception {
        byte[] bytes = service.toXlsx(List.of(row("Kovács Béla", new BigDecimal("4937.52"))));

        try (Workbook workbook = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            Sheet sheet = workbook.getSheet("Tranzakciók");
            assertThat(sheet).isNotNull();
            assertThat(sheet.getPhysicalNumberOfRows()).isEqualTo(2);
            assertThat(sheet.getRow(0).getCell(0).getStringCellValue()).isEqualTo("Bizonylatszám");
            assertThat(sheet.getRow(1).getCell(9).getNumericCellValue()).isEqualTo(4937.52d);
            assertThat(sheet.getRow(1).getCell(3).getStringCellValue()).isEqualTo("2026.07.08");
        }
    }

    private static ComplianceTransactionRowDto row(String customerName, BigDecimal hufAmount) {
        return ComplianceTransactionRowDto.builder()
                .receiptNumber("FS11-CSV-001")
                .transactionType(TransactionType.BUY)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.of(2026, 7, 8))
                .transactionTime(LocalTime.of(10, 30, 5))
                .branchName("Belváros")
                .branchCode("BR001")
                .currencyCode("EUR")
                .currencyAmount(new BigDecimal("12.3400"))
                .exchangeRate(new BigDecimal("400.1234"))
                .hufAmount(hufAmount)
                .paymentMethod(PaymentMethod.CARD)
                .cashierCustomRate(true)
                .kkDiscount(true)
                .customerIsPep(true)
                .customerOnOwnBehalf(false)
                .amlSuspicious(true)
                .customerName(customerName)
                .customerBirthDate(LocalDate.of(1980, 1, 2))
                .customerNationality("Magyar")
                .customerDocumentNumber(null)
                .isLegalEntityCustomer(false)
                .legalEntityName(null)
                .legalEntityTaxNumber("12345678-2-42")
                .workerCode("P001")
                .workerName("Teszt Pénztáros")
                .build();
    }
}
