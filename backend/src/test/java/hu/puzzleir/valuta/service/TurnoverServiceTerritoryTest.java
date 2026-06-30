package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.turnover.TurnoverReportDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * FK-045 FR-4/FR-7/FR-9: területi forgalom-aggregáció + MNB elszámolási árfolyam + tenant-guard.
 */
@ExtendWith(MockitoExtension.class)
class TurnoverServiceTerritoryTest {

    @InjectMocks
    private TurnoverService service;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private ExchangeRateRepository exchangeRateRepository;

    @Mock
    private BranchService branchService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final Integer TERRITORY_ID = 5;
    private static final LocalDate FROM = LocalDate.of(2026, 6, 1);
    private static final LocalDate TO = LocalDate.of(2026, 6, 30);

    @Test
    @DisplayName("official_rate megjelenik a CurrencyTurnoverDto-ban (FR-7)")
    void official_rate_included_in_currency_row() {
        when(transactionRepository.countBranchesInTerritory(COMPANY_ID, TERRITORY_ID)).thenReturn(3L);
        lenient().when(transactionRepository.sumHufAmountByTerritoryAndTypeAndPeriod(
                eq(COMPANY_ID), eq(TERRITORY_ID), any(), any(), any()))
            .thenReturn(new BigDecimal("1000000"));
        lenient().when(transactionRepository.sumFeeByTerritoryAndPeriod(
                eq(COMPANY_ID), eq(TERRITORY_ID), any(), any()))
            .thenReturn(new BigDecimal("5000"));

        List<Object[]> rows = new ArrayList<>();
        rows.add(new Object[]{"EUR", "BUY", new BigDecimal("2000"), new BigDecimal("800000"), new BigDecimal("2000"), 4L});
        rows.add(new Object[]{"USD", "SELL", new BigDecimal("500"), new BigDecimal("200000"), new BigDecimal("500"), 2L});
        when(transactionRepository.groupByCurrencyAndTypeForTerritory(
                eq(COMPANY_ID), eq(TERRITORY_ID), any(), any()))
            .thenReturn(rows);

        // MNB official_rate: csak EUR-hoz van; USD-hez nincs → USD officialRate null marad.
        when(exchangeRateRepository.findActiveRatesByDate(COMPANY_ID, TO))
            .thenReturn(List.of(rate("EUR", new BigDecimal("405.1200"))));

        TurnoverReportDto report = service.getVaultTerritoryTurnover(COMPANY_ID, TERRITORY_ID, FROM, TO);

        assertThat(report.getByCurrency()).hasSize(2);
        TurnoverReportDto.CurrencyTurnoverDto eur = report.getByCurrency().stream()
            .filter(c -> "EUR".equals(c.getCurrencyCode())).findFirst().orElseThrow();
        assertThat(eur.getOfficialRate()).isEqualByComparingTo("405.1200");
        TurnoverReportDto.CurrencyTurnoverDto usd = report.getByCurrency().stream()
            .filter(c -> "USD".equals(c.getCurrencyCode())).findFirst().orElseThrow();
        assertThat(usd.getOfficialRate()).isNull(); // nincs MNB árfolyam → null (UI: „–")
    }

    @Test
    @DisplayName("forgalom nélküli időszak → üres byCurrency, nem hiba")
    void empty_period_returns_empty_byCurrency() {
        when(transactionRepository.countBranchesInTerritory(COMPANY_ID, TERRITORY_ID)).thenReturn(2L);
        lenient().when(transactionRepository.sumHufAmountByTerritoryAndTypeAndPeriod(
                any(), any(), any(), any(), any())).thenReturn(null);
        lenient().when(transactionRepository.sumFeeByTerritoryAndPeriod(
                any(), any(), any(), any())).thenReturn(null);
        when(transactionRepository.groupByCurrencyAndTypeForTerritory(
                eq(COMPANY_ID), eq(TERRITORY_ID), any(), any()))
            .thenReturn(new ArrayList<>());

        TurnoverReportDto report = service.getVaultTerritoryTurnover(COMPANY_ID, TERRITORY_ID, FROM, TO);

        assertThat(report.getByCurrency()).isEmpty();
        assertThat(report.getTotalBuy()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(report.getTotalSell()).isEqualByComparingTo(BigDecimal.ZERO);
        // üres byCurrency esetén az official_rate lekérdezés le sem fut (rövidzár) — nincs NPE
    }

    @Test
    @DisplayName("idegen tenant / nemlétező terület → ResourceNotFoundException (404)")
    void cross_tenant_or_unknown_territory_throws() {
        when(transactionRepository.countBranchesInTerritory(COMPANY_ID, TERRITORY_ID)).thenReturn(0L);

        assertThatThrownBy(() -> service.getVaultTerritoryTurnover(COMPANY_ID, TERRITORY_ID, FROM, TO))
            .isInstanceOf(ResourceNotFoundException.class)
            .hasMessageContaining("Értéktári terület nem található");
    }

    @Test
    @DisplayName("NFR-3: a VETT/ELADOTT összesítők 5 Ft-ra kerekítve (HungarianRounding)")
    void totals_rounded_to_five_huf() {
        when(transactionRepository.countBranchesInTerritory(COMPANY_ID, TERRITORY_ID)).thenReturn(1L);
        // nyers összegek, amik NEM 5 többszörösei → kerekítés után 5-re kell esniük
        when(transactionRepository.sumHufAmountByTerritoryAndTypeAndPeriod(
                eq(COMPANY_ID), eq(TERRITORY_ID), eq("BUY"), any(), any()))
            .thenReturn(new BigDecimal("1002347")); // → 1002345
        when(transactionRepository.sumHufAmountByTerritoryAndTypeAndPeriod(
                eq(COMPANY_ID), eq(TERRITORY_ID), eq("SELL"), any(), any()))
            .thenReturn(new BigDecimal("2008923")); // → 2008925
        lenient().when(transactionRepository.sumFeeByTerritoryAndPeriod(
                eq(COMPANY_ID), eq(TERRITORY_ID), any(), any())).thenReturn(BigDecimal.ZERO);
        when(transactionRepository.groupByCurrencyAndTypeForTerritory(
                eq(COMPANY_ID), eq(TERRITORY_ID), any(), any())).thenReturn(new ArrayList<>());

        TurnoverReportDto report = service.getVaultTerritoryTurnover(COMPANY_ID, TERRITORY_ID, FROM, TO);

        // 5 Ft-os kerekítés (HALF_UP): az utolsó számjegy 5 többszöröse
        assertThat(report.getTotalBuy().remainder(new BigDecimal("5"))).isEqualByComparingTo("0");
        assertThat(report.getTotalSell().remainder(new BigDecimal("5"))).isEqualByComparingTo("0");
        assertThat(report.getTotalBuy()).isEqualByComparingTo("1002345");
        assertThat(report.getTotalSell()).isEqualByComparingTo("2008925");
    }

    private static ExchangeRate rate(String code, BigDecimal officialRate) {
        Currency c = new Currency();
        c.setCode(code);
        ExchangeRate er = new ExchangeRate();
        er.setCurrency(c);
        er.setOfficialRate(officialRate);
        return er;
    }
}
