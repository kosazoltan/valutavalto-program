package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.nav.NavReportDto;
import hu.puzzleir.valuta.dto.nav.NavReportableTransactionDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * NavReportService UNIT tesztek — Mockito.
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class NavReportServiceTest {

    @InjectMocks
    private NavReportService navReportService;

    @Mock
    private TransactionRepository transactionRepository;

    private static final UUID TEST_COMPANY_ID = UUID.randomUUID();
    private static final UUID TEST_BRANCH_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
            1L, TEST_COMPANY_ID, TEST_BRANCH_ID, "MANAGER");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_MANAGER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    @DisplayName("getReportableTransactions: 2M+ HUF tranzakciók szűrése")
    void testGetReportableTransactions_above2M() {
        LocalDate date = LocalDate.of(2026, 3, 5);

        Currency eur = Currency.builder().code("EUR").build();

        // 2.5M — reportable
        Transaction tx1 = Transaction.builder()
            .id(1L)
            .receiptNumber("V00001")
            .transactionType(TransactionType.BUY)
            .currency(eur)
            .currencyAmount(new BigDecimal("6000"))
            .hufAmount(new BigDecimal("2500000"))
            .exchangeRate(new BigDecimal("416.67"))
            .transactionDate(date)
            .transactionTime(LocalTime.of(10, 0))
            .customerId("C001")
            .customerName("Nagy István")
            .customerAddress("Budapest, Fő u. 1.")
            .customerDocumentNumber("123456AB")
            .build();

        // 3M — reportable
        Transaction tx2 = Transaction.builder()
            .id(2L)
            .receiptNumber("E00002")
            .transactionType(TransactionType.SELL)
            .currency(eur)
            .currencyAmount(new BigDecimal("7500"))
            .hufAmount(new BigDecimal("3000000"))
            .exchangeRate(new BigDecimal("400"))
            .transactionDate(date)
            .transactionTime(LocalTime.of(14, 30))
            .customerId("C002")
            .customerName("Kis Péter")
            .customerAddress("Debrecen, Kossuth u. 5.")
            .customerDocumentNumber("789012CD")
            .build();

        when(transactionRepository.findReportableTransactions(
            eq(TEST_COMPANY_ID), eq(date), any(BigDecimal.class)))
            .thenReturn(List.of(tx1, tx2));

        List<NavReportableTransactionDto> result = navReportService.getReportableTransactions(date);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).getReceiptNumber()).isEqualTo("V00001");
        assertThat(result.get(0).getHufAmount()).isEqualByComparingTo(new BigDecimal("2500000"));
        assertThat(result.get(1).getReceiptNumber()).isEqualTo("E00002");
        assertThat(result.get(1).getHufAmount()).isEqualByComparingTo(new BigDecimal("3000000"));
    }

    @Test
    @DisplayName("exportNavCsv: valid CSV formátum fejléccel és sorokkal")
    void testExportCsv() {
        LocalDate date = LocalDate.of(2026, 3, 5);

        Currency usd = Currency.builder().code("USD").build();
        Transaction tx = Transaction.builder()
            .id(1L)
            .receiptNumber("V00100")
            .transactionType(TransactionType.BUY)
            .currency(usd)
            .currencyAmount(new BigDecimal("5000"))
            .hufAmount(new BigDecimal("2200000"))
            .exchangeRate(new BigDecimal("440"))
            .transactionDate(date)
            .transactionTime(LocalTime.of(11, 0))
            .customerId("C003")
            .customerName("Szabó Anna")
            .customerAddress("Szeged, Kárász u. 10.")
            .customerDocumentNumber("EF345678")
            .build();

        when(transactionRepository.findReportableTransactions(
            eq(TEST_COMPANY_ID), eq(date), any(BigDecimal.class)))
            .thenReturn(List.of(tx));

        byte[] csvBytes = navReportService.exportNavCsv(date);
        String csv = new String(csvBytes, StandardCharsets.UTF_8);

        assertThat(csv).isNotNull();
        // Fejléc ellenőrzés
        assertThat(csv).startsWith("Bizonylat;Típus;Dátum;");
        assertThat(csv).contains("Ügyfél kód");
        // Adat sor ellenőrzés
        assertThat(csv).contains("V00100");
        assertThat(csv).contains("BUY");
        assertThat(csv).contains("USD");
        assertThat(csv).contains("Szabó Anna");
        assertThat(csv).contains("EF345678");
        // Sorok száma: fejléc + 1 adat sor
        String[] lines = csv.split("\n");
        assertThat(lines).hasSize(2);
    }
}
