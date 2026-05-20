package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.RecurringCustomerDto;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

/**
 * Sprint P3.3 (v2.5.74) — RecurringCustomerReportService unit teszt.
 *
 * <p>C.25 checklist: minden code-branch fedve (null params, from>to, minTx<2,
 * happy path, empty, multi-tenant query, financial_effective).</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class RecurringCustomerReportServiceTest {

    @Mock private EntityManager entityManager;
    @Mock private Query query;

    @InjectMocks
    private RecurringCustomerReportService service;

    private final UUID companyId = UUID.randomUUID();
    private final LocalDate from = LocalDate.of(2026, 5, 1);
    private final LocalDate to = LocalDate.of(2026, 5, 31);

    @BeforeEach
    void setUp() throws Exception {
        Field f = RecurringCustomerReportService.class.getDeclaredField("entityManager");
        f.setAccessible(true);
        f.set(service, entityManager);

        when(entityManager.createQuery(anyString())).thenReturn(query);
        when(query.setParameter(anyString(), org.mockito.ArgumentMatchers.any())).thenReturn(query);
    }

    @Test
    @DisplayName("companyId null → IllegalArgumentException")
    void nullCompanyId_throws() {
        assertThatThrownBy(() -> service.generate(null, from, to, 3))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("companyId");
    }

    @Test
    @DisplayName("from/to null → IllegalArgumentException")
    void nullDates_throws() {
        assertThatThrownBy(() -> service.generate(companyId, null, to, 3))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("kötelező");
        assertThatThrownBy(() -> service.generate(companyId, from, null, 3))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("kötelező");
    }

    @Test
    @DisplayName("from > to → IllegalArgumentException")
    void fromAfterTo_throws() {
        assertThatThrownBy(() -> service.generate(companyId, to, from, 3))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("érvénytelen");
    }

    @Test
    @DisplayName("minTransactions < 2 → IllegalArgumentException")
    void minTxBelowTwo_throws() {
        assertThatThrownBy(() -> service.generate(companyId, from, to, 1))
                .isInstanceOf(IllegalArgumentException.class).hasMessageContaining("legalább 2");
    }

    @Test
    @DisplayName("Happy path: 2 visszatérő ügyfél (5 + 3 tranzakció)")
    void happyPath_twoRecurringCustomers() {
        Object[] cust1 = {"DOC123", "Kiss Béla", 5L, new BigDecimal("1500000")};
        Object[] cust2 = {"DOC456", "Nagy Anna", 3L, new BigDecimal("800000")};
        when(query.getResultList()).thenReturn(List.of(cust1, cust2));

        List<RecurringCustomerDto> result = service.generate(companyId, from, to, 3);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).getCustomerId()).isEqualTo("DOC123");
        assertThat(result.get(0).getCustomerName()).isEqualTo("Kiss Béla");
        assertThat(result.get(0).getTransactionCount()).isEqualTo(5L);
        assertThat(result.get(0).getTotalHufAmount()).isEqualByComparingTo("1500000");
        assertThat(result.get(0).getPeriodStart()).isEqualTo(from);
        assertThat(result.get(0).getPeriodEnd()).isEqualTo(to);
    }

    @Test
    @DisplayName("Üres eredmény: senki nem érte el a küszöböt")
    void noRecurringCustomers_empty() {
        when(query.getResultList()).thenReturn(Collections.emptyList());

        List<RecurringCustomerDto> result = service.generate(companyId, from, to, 10);

        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("Null hufAmount a sorban → BigDecimal.ZERO (NPE-védelem)")
    void nullHufAmount_zero() {
        Object[] row = {"DOC789", "Teszt", 4L, null};
        when(query.getResultList()).thenReturn(Collections.singletonList(row));

        List<RecurringCustomerDto> result = service.generate(companyId, from, to, 2);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getTotalHufAmount()).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    @DisplayName("Multi-tenant + financial_effective: JPQL tartalmazza a kritikus szűrőket")
    void query_containsTenantAndFinancialFilters() {
        when(query.getResultList()).thenReturn(Collections.emptyList());

        service.generate(companyId, from, to, 3);

        org.mockito.ArgumentCaptor<String> cap = org.mockito.ArgumentCaptor.forClass(String.class);
        org.mockito.Mockito.verify(entityManager).createQuery(cap.capture());
        String jpql = cap.getValue();
        assertThat(jpql).contains("company.id");          // multi-tenant
        assertThat(jpql).contains("financialEffective");  // CONVERSION parent kizárás
        assertThat(jpql).contains("COMPLETED");            // sztornózott kizárás
        assertThat(jpql).contains("customerId IS NOT NULL"); // anonim kihagyás
        assertThat(jpql).contains("customerId <> ''");       // üres-string ID kizárás (fals csoport ellen)
        assertThat(jpql).contains("HAVING");               // küszöb
    }

    @Test
    @DisplayName("Multi-tenant verify: companyId paraméter bind-olva (regression-guard)")
    void companyId_alwaysBound() {
        when(query.getResultList()).thenReturn(Collections.emptyList());

        service.generate(companyId, from, to, 3);

        org.mockito.Mockito.verify(query).setParameter("companyId", companyId);
    }

    @Test
    @DisplayName("minTx paraméter Long-ként bind-olva (HAVING COUNT >= :minTx típus-guard)")
    void minTx_boundAsLong() {
        when(query.getResultList()).thenReturn(Collections.emptyList());

        service.generate(companyId, from, to, 2);

        // int → (long) cast a service-ben: a JPQL COUNT(t) Long, ezért a bind is Long kell legyen
        org.mockito.Mockito.verify(query).setParameter("minTx", 2L);
    }
}
