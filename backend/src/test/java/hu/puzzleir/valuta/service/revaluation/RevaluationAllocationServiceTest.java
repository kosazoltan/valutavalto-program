package hu.puzzleir.valuta.service.revaluation;

import hu.puzzleir.valuta.dto.revaluation.TerritoryReconciliationDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.MnbExchangeRateService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Területi reconciliation + értéktári átértékelés-lecsorgatás integrációs (mock) tesztje.
 */
@ExtendWith(MockitoExtension.class)
class RevaluationAllocationServiceTest {

    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyStockRepository currencyStockRepository;
    @Mock private ProfitLogRepository profitLogRepository;
    @Mock private TransferRepository transferRepository;
    @Mock private MnbExchangeRateService mnbExchangeRateService;
    @InjectMocks private RevaluationAllocationService service;

    private static final UUID COMPANY = UUID.randomUUID();
    private static final UUID A = UUID.randomUUID();
    private static final UUID B = UUID.randomUUID();
    private static final Integer TERR = 20;

    private static Branch cashier(UUID id, String code) {
        return Branch.builder().id(id).code(code).name(code + " pénztár")
                .isVault(false).vaultTerritoryId(TERR).build();
    }

    private static ProfitLog pl(UUID branch, String ccy, String profit, String qty) {
        return ProfitLog.builder().branchId(branch).currencyCode(ccy)
                .realizedProfit(new BigDecimal(profit)).quantity(new BigDecimal(qty))
                .acquisitionCost(BigDecimal.ONE).salePrice(BigDecimal.ONE).transactionType("SELL")
                .createdAt(LocalDateTime.now()).build();
    }

    private static Transfer draw(UUID toBranch, String amount) {
        return Transfer.builder()
                .toBranch(Branch.builder().id(toBranch).build())
                .currency(Currency.builder().code("EUR").build())
                .amount(new BigDecimal(amount)).build();
    }

    @Test
    @DisplayName("EUR puffer REVAL +500000 lecsorgatva: A(60000×5) 357143, B(40000×3) 142857; reconciliation OK")
    void testReconcileTerritory() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY);

            when(branchRepository.findByCompanyIdAndVaultTerritoryId(COMPANY, TERR))
                    .thenReturn(List.of(cashier(A, "BR-A"), cashier(B, "BR-B")));

            // Értéktár EUR készlet: 100000 @ WAC 395
            CurrencyStock vault = CurrencyStock.builder()
                    .entityType("VAULT").entityId(String.valueOf(TERR)).currencyCode("EUR")
                    .quantity(new BigDecimal("100000")).weightedAvgCost(new BigDecimal("395")).build();
            when(currencyStockRepository.findByCompanyIdAndEntityType(COMPANY, "VAULT"))
                    .thenReturn(List.of(vault));

            // MNB EUR 400 (unit 1) → REVAL = 100000×(400−395) = 500000
            when(mnbExchangeRateService.getRatesForDate(any(LocalDate.class))).thenReturn(Map.of(
                    "EUR", MnbExchangeRateCache.builder().currencyCode("EUR")
                            .officialRate(new BigDecimal("400")).unit(1).build()));

            when(profitLogRepository.findByBranchIdAndCreatedAtBetween(eq(A), any(), any()))
                    .thenReturn(List.of(pl(A, "EUR", "300000", "60000")));  // árrés 5
            when(profitLogRepository.findByBranchIdAndCreatedAtBetween(eq(B), any(), any()))
                    .thenReturn(List.of(pl(B, "EUR", "120000", "40000")));  // árrés 3

            when(transferRepository.findVaultDrawsToCashiers(anyList(), any(), any()))
                    .thenReturn(List.of(draw(A, "60000"), draw(B, "40000")));

            TerritoryReconciliationDto dto = service.reconcileTerritory(
                    TERR, LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31));

            assertThat(dto.getTerritoryRevaluation()).isEqualByComparingTo("500000");
            assertThat(dto.getTerritoryRealizedMargin()).isEqualByComparingTo("420000");
            assertThat(dto.getTerritoryTotalProfit()).isEqualByComparingTo("920000");
            assertThat(dto.isReconciliationOk()).isTrue();

            var a = dto.getCashiers().stream().filter(c -> c.getBranchId().equals(A.toString())).findFirst().orElseThrow();
            var b = dto.getCashiers().stream().filter(c -> c.getBranchId().equals(B.toString())).findFirst().orElseThrow();
            assertThat(a.getAllocatedRevaluation()).isEqualByComparingTo("357143");
            assertThat(a.getTotalProfit()).isEqualByComparingTo("657143");
            assertThat(b.getAllocatedRevaluation()).isEqualByComparingTo("142857");
            assertThat(b.getTotalProfit()).isEqualByComparingTo("262857");
            // INVARIÁNS: Σ pénztár összhaszon == terület összhaszon
            assertThat(a.getTotalProfit().add(b.getTotalProfit())).isEqualByComparingTo("920000");
        }
    }
}
