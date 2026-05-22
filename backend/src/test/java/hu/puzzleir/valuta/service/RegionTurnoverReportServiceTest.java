package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.RegionTurnoverReportDto;
import hu.puzzleir.valuta.dto.report.RegionTurnoverReportDto.RegionLineDto;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * G23 RegionTurnoverReportService unit teszt.
 *
 * <p>Lefedi: happy path régió-aggregáció + trend%, NULL régió → "EGYÉB",
 * előző-hó nélküli régió (100% trend), üres hónap, átlagos napi forgalom.</p>
 */
@ExtendWith(MockitoExtension.class)
class RegionTurnoverReportServiceTest {

    @Mock private TransactionRepository transactionRepository;

    @InjectMocks
    private RegionTurnoverReportService service;

    private final UUID companyId = UUID.randomUUID();

    private Object[] row(String region, long buyCount, long sellCount,
                         String buyHuf, String sellHuf, long customers, long days) {
        return new Object[]{region, buyCount, sellCount,
            new BigDecimal(buyHuf), new BigDecimal(sellHuf), customers, days};
    }

    @Test
    @DisplayName("Happy path: régiónkénti aggregáció + trend% az előző hónaphoz képest")
    void happyPath() {
        LocalDate curStart = LocalDate.of(2026, 3, 1);
        LocalDate curEnd = LocalDate.of(2026, 3, 31);
        LocalDate prevStart = LocalDate.of(2026, 2, 1);
        LocalDate prevEnd = LocalDate.of(2026, 2, 28);

        // Aktuális hó: régió "20" összesen 2.000.000 Ft, 4 nap aktív
        when(transactionRepository.aggregateRegionTurnover(eq(companyId), eq(curStart), eq(curEnd)))
            .thenReturn(List.<Object[]>of(
                row("20", 5, 3, "1200000", "800000", 6, 4)
            ));
        // Előző hó: régió "20" összesen 1.000.000 Ft → trend = +100%
        when(transactionRepository.aggregateRegionTurnover(eq(companyId), eq(prevStart), eq(prevEnd)))
            .thenReturn(List.<Object[]>of(
                row("20", 2, 2, "600000", "400000", 3, 2)
            ));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            RegionTurnoverReportDto dto = service.getRegionTurnover("2026-03");

            assertThat(dto.getYearMonth()).isEqualTo("2026-03");
            assertThat(dto.getPreviousYearMonth()).isEqualTo("2026-02");
            assertThat(dto.getRegions()).hasSize(1);

            RegionLineDto line = dto.getRegions().get(0);
            assertThat(line.getRegionCode()).isEqualTo("20");
            assertThat(line.getBuyCount()).isEqualTo(5);
            assertThat(line.getSellCount()).isEqualTo(3);
            assertThat(line.getTotalTurnoverHuf()).isEqualByComparingTo("2000000");
            assertThat(line.getDistinctCustomers()).isEqualTo(6);
            assertThat(line.getActiveDays()).isEqualTo(4);
            // 2.000.000 / 4 = 500.000
            assertThat(line.getAvgDailyTurnoverHuf()).isEqualByComparingTo("500000");
            assertThat(line.getPreviousTurnoverHuf()).isEqualByComparingTo("1000000");
            // (2M - 1M) / 1M * 100 = 100.0
            assertThat(line.getTrendPercent()).isEqualByComparingTo("100.0");

            assertThat(dto.getTotalTurnoverHuf()).isEqualByComparingTo("2000000");
            assertThat(dto.getTotalTrendPercent()).isEqualByComparingTo("100.0");
        }
    }

    @Test
    @DisplayName("NULL régiókód → 'EGYÉB'; előző hónap nélkül 100% trend")
    void nullRegionAndNoPrevious() {
        when(transactionRepository.aggregateRegionTurnover(eq(companyId),
                eq(LocalDate.of(2026, 3, 1)), eq(LocalDate.of(2026, 3, 31))))
            .thenReturn(List.<Object[]>of(
                row(null, 1, 0, "500000", "0", 1, 1)
            ));
        when(transactionRepository.aggregateRegionTurnover(eq(companyId),
                eq(LocalDate.of(2026, 2, 1)), eq(LocalDate.of(2026, 2, 28))))
            .thenReturn(List.<Object[]>of());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            RegionTurnoverReportDto dto = service.getRegionTurnover("2026-03");

            assertThat(dto.getRegions()).hasSize(1);
            RegionLineDto line = dto.getRegions().get(0);
            assertThat(line.getRegionCode()).isEqualTo("EGYÉB");
            assertThat(line.getPreviousTurnoverHuf()).isEqualByComparingTo("0");
            assertThat(line.getTrendPercent()).isEqualByComparingTo("100");
        }
    }

    @Test
    @DisplayName("Üres hónap → üres régiólista, 0 trend")
    void emptyMonth() {
        when(transactionRepository.aggregateRegionTurnover(eq(companyId),
                eq(LocalDate.of(2026, 3, 1)), eq(LocalDate.of(2026, 3, 31))))
            .thenReturn(List.<Object[]>of());
        when(transactionRepository.aggregateRegionTurnover(eq(companyId),
                eq(LocalDate.of(2026, 2, 1)), eq(LocalDate.of(2026, 2, 28))))
            .thenReturn(List.<Object[]>of());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            RegionTurnoverReportDto dto = service.getRegionTurnover("2026-03");

            assertThat(dto.getRegions()).isEmpty();
            assertThat(dto.getTotalTurnoverHuf()).isEqualByComparingTo("0");
            assertThat(dto.getTotalTrendPercent()).isEqualByComparingTo("0");
        }
    }
}
