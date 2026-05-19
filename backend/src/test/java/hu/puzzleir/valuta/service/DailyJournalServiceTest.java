package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.BranchRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.io.IOException;
import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

/**
 * Sprint A P2.4 (v2.5.68) — DailyJournalService unit tesztek (legacy NAPKONYV).
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DailyJournalServiceTest {

    @Mock private EntityManager entityManager;
    @Mock private BranchRepository branchRepository;
    @Mock private TypedQuery<Transaction> typedQuery;

    @InjectMocks
    private DailyJournalService service;

    private final UUID branchId = UUID.randomUUID();
    private final LocalDate testDate = LocalDate.of(2026, 5, 19);

    @BeforeEach
    void setUp() throws Exception {
        Field f = DailyJournalService.class.getDeclaredField("entityManager");
        f.setAccessible(true);
        f.set(service, entityManager);

        when(entityManager.createQuery(anyString(), eq(Transaction.class))).thenReturn(typedQuery);
        when(typedQuery.setParameter(anyString(), org.mockito.ArgumentMatchers.any())).thenReturn(typedQuery);
    }

    @Test
    @DisplayName("Null branchId → IllegalArgumentException")
    void nullBranchId_throws() {
        assertThatThrownBy(() -> service.generatePdf(null, testDate))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("kötelező");
    }

    @Test
    @DisplayName("Null date → IllegalArgumentException")
    void nullDate_throws() {
        assertThatThrownBy(() -> service.generatePdf(branchId, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("kötelező");
    }

    @Test
    @DisplayName("Nem létező branch → IllegalArgumentException")
    void nonExistentBranch_throws() {
        when(branchRepository.findById(branchId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.generatePdf(branchId, testDate))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Nem létező branch");
    }

    @Test
    @DisplayName("Üres tranzakció lista → PDF generálódik (csak fejléc + 0 db tranz)")
    void emptyTransactions_pdfWithHeader() throws IOException {
        Branch branch = createBranch();
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(typedQuery.getResultList()).thenReturn(List.of());

        byte[] pdf = service.generatePdf(branchId, testDate);

        assertThat(pdf).isNotEmpty();
        // PDF magic: %PDF-
        assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");
    }

    @Test
    @DisplayName("3 tranzakció (BUY+SELL+CONVERSION) → PDF generálódik + összesítés")
    void threeTxs_pdfGenerated() throws IOException {
        Branch branch = createBranch();
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));

        Currency eur = new Currency();
        eur.setCode("EUR");

        Transaction buy = createTx("V202600001", TransactionType.BUY, eur, "1000", "365000", LocalTime.of(9, 15));
        Transaction sell = createTx("V202600002", TransactionType.SELL, eur, "500", "180000", LocalTime.of(11, 30));
        Transaction conv = createTx("V202600003", TransactionType.CONVERSION, eur, "200", "73000", LocalTime.of(14, 0));

        when(typedQuery.getResultList()).thenReturn(List.of(buy, sell, conv));

        byte[] pdf = service.generatePdf(branchId, testDate);

        assertThat(pdf).isNotEmpty();
        assertThat(new String(pdf, 0, 5)).isEqualTo("%PDF-");
        // PDF size > 1KB legalább (fejléc + 3 tranzakció + összesítés)
        assertThat(pdf.length).isGreaterThan(1000);
    }

    @Test
    @DisplayName("JPQL query a financialEffective=TRUE szűrőt tartalmazza (parent CONVERSION kizárás)")
    void query_filtersFinancialEffective() throws IOException {
        Branch branch = createBranch();
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(typedQuery.getResultList()).thenReturn(List.of());

        service.generatePdf(branchId, testDate);

        org.mockito.ArgumentCaptor<String> jpqlCaptor =
                org.mockito.ArgumentCaptor.forClass(String.class);
        org.mockito.Mockito.verify(entityManager).createQuery(jpqlCaptor.capture(), eq(Transaction.class));
        String jpql = jpqlCaptor.getValue();
        assertThat(jpql).contains("financialEffective");
        assertThat(jpql).contains("TRUE");
        // Status szűrés is
        assertThat(jpql).contains("status");
    }

    // ==========================================================================
    // Helpers
    // ==========================================================================

    private Branch createBranch() {
        Branch b = new Branch();
        b.setId(branchId);
        b.setCode("BR001");
        b.setName("Teszt iroda");
        return b;
    }

    private Transaction createTx(String receipt, TransactionType type, Currency currency,
                                  String currAmt, String hufAmt, LocalTime time) {
        Transaction t = Transaction.builder()
                .receiptNumber(receipt)
                .transactionType(type)
                .currency(currency)
                .currencyAmount(new BigDecimal(currAmt))
                .hufAmount(new BigDecimal(hufAmt))
                .transactionDate(testDate)
                .transactionTime(time)
                .status(TransactionStatus.COMPLETED)
                .financialEffective(true)
                .build();
        return t;
    }
}
