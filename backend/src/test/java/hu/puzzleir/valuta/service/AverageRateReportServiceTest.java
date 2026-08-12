package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.AverageRateReportResponse;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse.ColumnGroup;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
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
