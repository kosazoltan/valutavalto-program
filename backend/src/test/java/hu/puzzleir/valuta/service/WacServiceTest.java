package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.ProfitLog;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.ProfitLogRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * A6 / b8 FR-8: a profit_log élesítését vezérlő {@code recordSellProfitIfEnabled}
 * viselkedésének lefedése — flag OFF (default) no-op, cold-start skip, WAC>0 profit.
 */
@ExtendWith(MockitoExtension.class)
class WacServiceTest {

    @Mock private CurrencyStockRepository currencyStockRepository;
    @Mock private ProfitLogRepository profitLogRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private SystemParameterService systemParameterService;

    @InjectMocks private WacService wacService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();

    @Test
    @DisplayName("recordSellProfitIfEnabled: flag OFF (default) → no-op, profit_log nem íródik")
    void flagOff_noOp() {
        when(systemParameterService.getValue(eq(WacService.WAC_PROFIT_TRACKING_PARAM), any()))
                .thenReturn("false");

        wacService.recordSellProfitIfEnabled(BRANCH_ID, 1L, "EUR",
                new BigDecimal("100"), new BigDecimal("400"));

        verifyNoInteractions(profitLogRepository);
        verifyNoInteractions(currencyStockRepository);
    }

    @Test
    @DisplayName("recordSellProfitIfEnabled: flag ON, de nincs WAC bekerülési ár (cold-start) → skip")
    void enabledColdStart_skip() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(systemParameterService.getValue(eq(WacService.WAC_PROFIT_TRACKING_PARAM), any()))
                    .thenReturn("true");
            when(currencyStockRepository.findByCompanyIdAndEntityTypeAndEntityIdAndCurrencyCode(
                    COMPANY_ID, "CASHIER", BRANCH_ID.toString(), "EUR"))
                    .thenReturn(Optional.empty());

            wacService.recordSellProfitIfEnabled(BRANCH_ID, 1L, "EUR",
                    new BigDecimal("100"), new BigDecimal("400"));

            verifyNoInteractions(profitLogRepository);
        }
    }

    @Test
    @DisplayName("recordSellProfitIfEnabled: flag ON + WAC>0 → realizált profit = (eladási ár - WAC) × mennyiség")
    void enabledWithWac_recordsProfit() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(systemParameterService.getValue(eq(WacService.WAC_PROFIT_TRACKING_PARAM), any()))
                    .thenReturn("true");
            Company company = mock(Company.class);
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            CurrencyStock stock = CurrencyStock.builder()
                    .company(company)
                    .entityType("CASHIER")
                    .entityId(BRANCH_ID.toString())
                    .currencyCode("EUR")
                    .quantity(new BigDecimal("500"))
                    .weightedAvgCost(new BigDecimal("380"))
                    .build();
            when(currencyStockRepository.findByCompanyIdAndEntityTypeAndEntityIdAndCurrencyCode(
                    COMPANY_ID, "CASHIER", BRANCH_ID.toString(), "EUR"))
                    .thenReturn(Optional.of(stock));

            wacService.recordSellProfitIfEnabled(BRANCH_ID, 7L, "EUR",
                    new BigDecimal("100"), new BigDecimal("400"));

            ArgumentCaptor<ProfitLog> captor = ArgumentCaptor.forClass(ProfitLog.class);
            verify(profitLogRepository).save(captor.capture());
            ProfitLog pl = captor.getValue();
            // profit = (400 - 380) × 100 = 2000
            assertThat(pl.getRealizedProfit()).isEqualByComparingTo("2000.00");
            assertThat(pl.getAcquisitionCost()).isEqualByComparingTo("380");
            assertThat(pl.getSalePrice()).isEqualByComparingTo("400");
            assertThat(pl.getQuantity()).isEqualByComparingTo("100");
            assertThat(pl.getTransactionType()).isEqualTo("SELL");
            assertThat(pl.getTransactionId()).isEqualTo(7L);
            assertThat(pl.getBranchId()).isEqualTo(BRANCH_ID);
        }
    }
}
