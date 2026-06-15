package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.AverageRateReportDto;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse.ColumnGroup;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.lang.reflect.Field;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * Sprint A P2.5 (v2.5.66) — AverageRateReportService unit teszt.
 *
 * <p>Verifikálja a súlyozott átlagárfolyam számítást és multi-tenant védelmet.</p>
 */
@ExtendWith(MockitoExtension.class)
class AverageRateReportServiceTest {

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private CurrencyRepository currencyRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private EntityManager entityManager;

    @Mock
    private Query query;

    @InjectMocks
    private AverageRateReportService service;

    private final UUID companyId = UUID.randomUUID();

    @BeforeEach
    void setUp() throws Exception {
        // EntityManager injection via reflection (JPA @PersistenceContext nem fut @InjectMocks-szal)
        Field f = AverageRateReportService.class.getDeclaredField("entityManager");
        f.setAccessible(true);
        f.set(service, entityManager);

        lenient().when(entityManager.createQuery(anyString())).thenReturn(query);
        lenient().when(query.setParameter(anyString(), Mockito_any())).thenReturn(query);
    }

    private static Object Mockito_any() {
        return org.mockito.ArgumentMatchers.any();
    }

    @Test
    @DisplayName("companyId null → IllegalArgumentException")
    void nullCompanyId_throws() {
        assertThatThrownBy(() -> service.generate(null,
                LocalDate.now(), LocalDate.now(), null, null, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("companyId");
    }

    @Test
    @DisplayName("from null vagy to null → IllegalArgumentException")
    void nullDates_throws() {
        assertThatThrownBy(() -> service.generate(companyId, null, LocalDate.now(), null, null, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("kötelező");

        assertThatThrownBy(() -> service.generate(companyId, LocalDate.now(), null, null, null, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("kötelező");
    }

    @Test
    @DisplayName("from > to → IllegalArgumentException")
    void fromAfterTo_throws() {
        LocalDate from = LocalDate.of(2026, 5, 20);
        LocalDate to = LocalDate.of(2026, 5, 19);
        assertThatThrownBy(() -> service.generate(companyId, from, to, null, null, null))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("érvénytelen");
    }

    @Test
    @DisplayName("Súlyozott átlag: 2 tranzakció EUR-ra, 1×100EUR×350HUF + 1×200EUR×360HUF → avg=356.67")
    void weightedAverage_correct() {
        // SUM(currency) = 300 EUR, SUM(huf) = 35000+72000 = 107000 → avg = 107000/300 = 356.67
        Object[] row = {1L, "EUR", 2L, new BigDecimal("300"), new BigDecimal("107000")};
        when(query.getResultList()).thenReturn(java.util.Collections.singletonList(row));

        List<AverageRateReportDto> result = service.generate(companyId,
                LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31), null, null, null);

        assertThat(result).hasSize(1);
        AverageRateReportDto dto = result.get(0);
        assertThat(dto.getCurrencyCode()).isEqualTo("EUR");
        assertThat(dto.getTransactionCount()).isEqualTo(2L);
        assertThat(dto.getTotalCurrencyAmount()).isEqualByComparingTo("300");
        assertThat(dto.getTotalHufAmount()).isEqualByComparingTo("107000");
        // 107000 / 300 = 356.6667 → HALF_UP scale 4 → 356.6667
        assertThat(dto.getWeightedAverageRate()).isEqualByComparingTo(new BigDecimal("356.6667"));
    }

    @Test
    @DisplayName("Több valuta — sor per valuta")
    void multipleCurrencies_oneRowEach() {
        Object[] eur = {1L, "EUR", 5L, new BigDecimal("1000"), new BigDecimal("360000")};
        Object[] usd = {2L, "USD", 3L, new BigDecimal("500"), new BigDecimal("160000")};
        when(query.getResultList()).thenReturn(Arrays.asList(eur, usd));

        List<AverageRateReportDto> result = service.generate(companyId,
                LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31), null, null, null);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).getCurrencyCode()).isEqualTo("EUR");
        assertThat(result.get(0).getWeightedAverageRate()).isEqualByComparingTo("360.0000");
        assertThat(result.get(1).getCurrencyCode()).isEqualTo("USD");
        assertThat(result.get(1).getWeightedAverageRate()).isEqualByComparingTo("320.0000");
    }

    @Test
    @DisplayName("Üres eredmény: 0 tranzakció időszakban → üres lista")
    void noTransactions_emptyResult() {
        when(query.getResultList()).thenReturn(List.of());

        List<AverageRateReportDto> result = service.generate(companyId,
                LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31), null, null, null);

        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("Érvénytelen transactionType → IllegalArgumentException")
    void invalidTransactionType_throws() {
        assertThatThrownBy(() -> service.generate(companyId,
                LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31), null, null, "INVALID_TYPE"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("transactionType");
    }

    @Test
    @DisplayName("Multi-tenant verify: companyId paraméter MINDIG bind-olva (regression-guard)")
    void multiTenant_companyIdAlwaysBound() {
        when(query.getResultList()).thenReturn(List.of());

        service.generate(companyId, LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31),
                null, null, null);

        org.mockito.Mockito.verify(query).setParameter("companyId", companyId);
    }

    @Test
    @DisplayName("Optional branchId bind: ha != null, akkor a query-be bekerül")
    void optionalBranchId_boundWhenProvided() {
        UUID branchId = UUID.randomUUID();
        when(query.getResultList()).thenReturn(List.of());

        service.generate(companyId, LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31),
                branchId, null, null);

        org.mockito.Mockito.verify(query).setParameter("branchId", branchId);
    }

    @Test
    @DisplayName("transactionType BUY → enum bind, INVALID → IllegalArgumentException (már tesztelve fent)")
    void validTransactionType_bound() {
        when(query.getResultList()).thenReturn(List.of());

        service.generate(companyId, LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31),
                null, null, "BUY");

        org.mockito.Mockito.verify(query).setParameter("transactionType",
                hu.puzzleir.valuta.entity.TransactionType.BUY);
    }

    @Test
    @DisplayName("JPQL query a status=COMPLETED + financialEffective=TRUE feltételeket tartalmazza")
    void query_filtersOnCompletedAndFinancialEffective() {
        when(query.getResultList()).thenReturn(List.of());

        service.generate(companyId, LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31),
                null, null, null);

        org.mockito.ArgumentCaptor<String> jpqlCaptor = org.mockito.ArgumentCaptor.forClass(String.class);
        org.mockito.Mockito.verify(entityManager).createQuery(jpqlCaptor.capture());
        String jpql = jpqlCaptor.getValue();
        assertThat(jpql).contains("COMPLETED");
        // Copilot P0 #703 regression-guard: parent CONVERSION kizárás
        assertThat(jpql).contains("financialEffective");
        assertThat(jpql).contains("TRUE");
    }

    @Test
    @DisplayName("Zero currency amount → weightedAvg=0 (NEM ArithmeticException)")
    void zeroCurrencyAmount_avgZero() {
        Object[] row = {1L, "EUR", 1L, BigDecimal.ZERO, new BigDecimal("100")};
        when(query.getResultList()).thenReturn(java.util.Collections.singletonList(row));

        List<AverageRateReportDto> result = service.generate(companyId,
                LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31), null, null, null);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getWeightedAverageRate()).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    @DisplayName("FK-027 pivot: Összes iroda → 8+1 oszlopcsoport, Vétel/Eladás súlyozott átlag + összesítő")
    void generatePivot_allOffices_regionsPlusTotalWeightedAverages() {
        // Régió-lista query (DISTINCT b.region) — külön mock a tartalom alapján.
        Query regionsQuery = org.mockito.Mockito.mock(Query.class);
        when(entityManager.createQuery(org.mockito.ArgumentMatchers.contains("DISTINCT b.region")))
                .thenReturn(regionsQuery);
        lenient().when(regionsQuery.setParameter(anyString(), Mockito_any())).thenReturn(regionsQuery);
        when(regionsQuery.getResultList()).thenReturn(List.of("PECS", "SZEGED"));

        // Aggregáló query (SUM(t.currencyAmount)).
        Query aggQuery = org.mockito.Mockito.mock(Query.class);
        when(entityManager.createQuery(org.mockito.ArgumentMatchers.contains("SUM(t.currencyAmount)")))
                .thenReturn(aggQuery);
        lenient().when(aggQuery.setParameter(anyString(), Mockito_any())).thenReturn(aggQuery);
        when(aggQuery.getResultList()).thenReturn(Arrays.asList(
                new Object[]{"SZEGED", "EUR", TransactionType.BUY, new BigDecimal("1000"), new BigDecimal("400000")},
                new Object[]{"SZEGED", "EUR", TransactionType.SELL, new BigDecimal("500"), new BigDecimal("210000")},
                new Object[]{"PECS", "EUR", TransactionType.BUY, new BigDecimal("1000"), new BigDecimal("402000")}
        ));

        Currency eur = org.mockito.Mockito.mock(Currency.class);
        when(eur.getCode()).thenReturn("EUR");
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur));

        AverageRateReportResponse resp = service.generatePivot(
                companyId, LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30), null);

        // 2 terület + "total" (EXCLUSIVE BEST CHANGE ZRT)
        assertThat(resp.getColumnGroups()).extracting(ColumnGroup::getGroupCode)
                .containsExactly("PECS", "SZEGED", "total");
        assertThat(resp.getColumnGroups().get(2).getGroupName()).isEqualTo("EXCLUSIVE BEST CHANGE ZRT");
        assertThat(resp.getCurrencyRows()).hasSize(1);

        var eurRow = resp.getCurrencyRows().get(0);
        // SZEGED: Vétel 400000/1000=400, Eladás 210000/500=420
        assertThat(eurRow.getValues().get("SZEGED").getBuyAvgRate()).isEqualByComparingTo("400.0000");
        assertThat(eurRow.getValues().get("SZEGED").getSellAvgRate()).isEqualByComparingTo("420.0000");
        // total Vétel: (400000+402000)/(1000+1000)=401; összeg=2000
        assertThat(eurRow.getValues().get("total").getBuyAvgRate()).isEqualByComparingTo("401.0000");
        assertThat(eurRow.getValues().get("total").getBuySumAmount()).isEqualByComparingTo("2000");
        // PECS: nincs Eladás → 0 (nem null/hiányzó)
        assertThat(eurRow.getValues().get("PECS").getSellAvgRate()).isEqualByComparingTo("0");
        assertThat(eurRow.getValues().get("PECS").getSellSumAmount()).isEqualByComparingTo("0");
    }

    // ============ FK-030: az "ORSZAGOS" oszlop (VAULT_COUNTERPARTY) kizárása ============

    @Test
    @DisplayName("FK-030: a pivot mindkét lekérdezése kizárja a VAULT_COUNTERPARTY branch-eket (FR-2/FR-3)")
    void generatePivot_queriesExcludeVaultCounterparty() {
        Query regionsQuery = org.mockito.Mockito.mock(Query.class);
        when(entityManager.createQuery(org.mockito.ArgumentMatchers.contains("DISTINCT b.region")))
                .thenReturn(regionsQuery);
        lenient().when(regionsQuery.setParameter(anyString(), Mockito_any())).thenReturn(regionsQuery);
        when(regionsQuery.getResultList()).thenReturn(List.of("SZEGED"));
        Query aggQuery = org.mockito.Mockito.mock(Query.class);
        when(entityManager.createQuery(org.mockito.ArgumentMatchers.contains("SUM(t.currencyAmount)")))
                .thenReturn(aggQuery);
        lenient().when(aggQuery.setParameter(anyString(), Mockito_any())).thenReturn(aggQuery);
        when(aggQuery.getResultList()).thenReturn(List.of());
        Currency eur = org.mockito.Mockito.mock(Currency.class);
        lenient().when(eur.getCode()).thenReturn("EUR");
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur));

        service.generatePivot(companyId, LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30), null);

        org.mockito.ArgumentCaptor<String> cap = org.mockito.ArgumentCaptor.forClass(String.class);
        org.mockito.Mockito.verify(entityManager, org.mockito.Mockito.atLeastOnce()).createQuery(cap.capture());
        String regionJpql = cap.getAllValues().stream()
                .filter(s -> s.contains("DISTINCT b.region")).findFirst().orElseThrow();
        assertThat(regionJpql).contains("LEFT JOIN b.branchType").contains("VAULT_COUNTERPARTY");
        String aggJpql = cap.getAllValues().stream()
                .filter(s -> s.contains("SUM(t.currencyAmount)")).findFirst().orElseThrow();
        assertThat(aggJpql).contains("VAULT_COUNTERPARTY");
    }

    @Test
    @DisplayName("FK-030: a pivot oszlopcsoportjai NEM tartalmaznak 'ORSZAGOS'-t (FR-4)")
    void generatePivot_noOrszagosColumnGroup() {
        Query regionsQuery = org.mockito.Mockito.mock(Query.class);
        when(entityManager.createQuery(org.mockito.ArgumentMatchers.contains("DISTINCT b.region")))
                .thenReturn(regionsQuery);
        lenient().when(regionsQuery.setParameter(anyString(), Mockito_any())).thenReturn(regionsQuery);
        // A javított DISTINCT lekérdezés a VAULT_COUNTERPARTY-t kizárja → 'ORSZAGOS' nincs a listában.
        when(regionsQuery.getResultList()).thenReturn(List.of("PECS", "SZEGED"));
        Query aggQuery = org.mockito.Mockito.mock(Query.class);
        when(entityManager.createQuery(org.mockito.ArgumentMatchers.contains("SUM(t.currencyAmount)")))
                .thenReturn(aggQuery);
        lenient().when(aggQuery.setParameter(anyString(), Mockito_any())).thenReturn(aggQuery);
        when(aggQuery.getResultList()).thenReturn(List.of());
        Currency eur = org.mockito.Mockito.mock(Currency.class);
        lenient().when(eur.getCode()).thenReturn("EUR");
        when(currencyRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(eur));

        AverageRateReportResponse resp = service.generatePivot(
                companyId, LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30), null);

        assertThat(resp.getColumnGroups()).extracting(ColumnGroup::getGroupCode)
                .doesNotContain("ORSZAGOS")
                .containsExactly("PECS", "SZEGED", "total");
    }
}
