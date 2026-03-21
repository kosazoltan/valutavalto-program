package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.treasury.TreasuryAggregateDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.BranchGroup;
import hu.puzzleir.valuta.entity.DailyReport;
import hu.puzzleir.valuta.repository.BranchGroupRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.DailyReportRepository;
import hu.puzzleir.valuta.repository.InventoryMovementRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TreasuryDashboardServiceTest {

    @Mock private DailyReportRepository dailyReportRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private InventoryMovementRepository movementRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private BranchGroupRepository branchGroupRepository;

    @Test
    void getBranchGroupSummary_countsUniqueBranches_and_skips_foreign_only_groups() {
        TreasuryDashboardService service = new TreasuryDashboardService(
                dailyReportRepository,
                cashBalanceRepository,
                movementRepository,
                branchRepository,
                branchGroupRepository
        );

        UUID companyId = UUID.randomUUID();
        UUID branchA = UUID.randomUUID();
        UUID branchB = UUID.randomUUID();
        UUID foreignBranch = UUID.randomUUID();
        LocalDate date = LocalDate.of(2026, 3, 21);

        when(dailyReportRepository.findByCompanyIdAndReportDate(companyId, date)).thenReturn(List.of(
                dailyReport(branchA, date, "100.00", "50.00", "10.00", "20.00", 3),
                dailyReport(branchB, date, "200.00", "70.00", "5.00", "30.00", 2)
        ));
        when(branchGroupRepository.findByIsActiveTrue()).thenReturn(List.of(
                BranchGroup.builder()
                        .id(UUID.randomUUID())
                        .code("G1")
                        .name("Group 1")
                        .branchIds(List.of(branchA, branchB, foreignBranch))
                        .isActive(true)
                        .build(),
                BranchGroup.builder()
                        .id(UUID.randomUUID())
                        .code("FOREIGN")
                        .name("Foreign only")
                        .branchIds(List.of(foreignBranch))
                        .isActive(true)
                        .build()
        ));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            List<TreasuryAggregateDto> result = service.getBranchGroupSummary(date);

            assertThat(result).hasSize(1);
            TreasuryAggregateDto group = result.get(0);
            assertThat(group.getCode()).isEqualTo("G1");
            assertThat(group.getBranchCount()).isEqualTo(2);
            assertThat(group.getTransactionCount()).isEqualTo(5);
            assertThat(group.getTotalBuyHuf()).isEqualByComparingTo("300.00");
            assertThat(group.getTotalSellHuf()).isEqualByComparingTo("120.00");
            assertThat(group.getTotalFeeHuf()).isEqualByComparingTo("15.00");
            assertThat(group.getTotalProfit()).isEqualByComparingTo("50.00");
        }
    }

    private DailyReport dailyReport(UUID branchId, LocalDate date, String buy, String sell, String fee, String profit, int txCount) {
        Branch branch = new Branch();
        branch.setId(branchId);

        return DailyReport.builder()
                .branch(branch)
                .reportDate(date)
                .totalBuyHuf(new BigDecimal(buy))
                .totalSellHuf(new BigDecimal(sell))
                .totalFeeHuf(new BigDecimal(fee))
                .totalProfit(new BigDecimal(profit))
                .transactionCount(txCount)
                .build();
    }
}
