package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.dailysession.DailySessionDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DailySession;
import hu.puzzleir.valuta.entity.DailySessionStatus;
import hu.puzzleir.valuta.entity.Worker;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class DailySessionMapperTest {

    private final DailySessionMapper mapper = new DailySessionMapper();

    @Test
    @DisplayName("null entity → null DTO")
    void mapsNullEntity() {
        assertThat(mapper.toDto(null)).isNull();
    }

    @Test
    @DisplayName("Napi pénzügyi mezők és számított dailyChange átkerülnek a DTO-ba")
    void mapsFinancialFieldsAndComputesDailyChange() {
        UUID branchId = UUID.fromString("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee");
        LocalDate sessionDate = LocalDate.of(2026, 7, 6);
        LocalDateTime openedAt = LocalDateTime.of(2026, 7, 6, 8, 0);
        LocalDateTime closedAt = LocalDateTime.of(2026, 7, 6, 18, 0);
        DailySession entity = DailySession.builder()
                .id(3L)
                .sessionDate(sessionDate)
                .status(DailySessionStatus.CLOSED)
                .branch(Branch.builder().id(branchId).name("Kecskemét").build())
                .openedAt(openedAt)
                .openedByWorker(Worker.builder().id(10L).name("Nyitó Pénztáros").build())
                .openingBalanceHuf(new BigDecimal("100000"))
                .closedAt(closedAt)
                .closedByWorker(Worker.builder().id(11L).name("Záró Pénztáros").build())
                .closingBalanceHuf(new BigDecimal("125000"))
                .denominationVerified(true)
                .transactionCount(15)
                .reversalCount(1)
                .buyTurnoverHuf(new BigDecimal("50000"))
                .sellTurnoverHuf(new BigDecimal("30000"))
                .handlingFeeTotal(new BigDecimal("1500"))
                .build();

        DailySessionDto dto = mapper.toDto(entity);

        assertThat(dto.getId()).isEqualTo(3L);
        assertThat(dto.getSessionDate()).isEqualTo(sessionDate);
        assertThat(dto.getStatus()).isEqualTo(DailySessionStatus.CLOSED);
        assertThat(dto.getBranchId()).isEqualTo(branchId.toString());
        assertThat(dto.getBranchName()).isEqualTo("Kecskemét");
        assertThat(dto.getOpenedAt()).isEqualTo(openedAt);
        assertThat(dto.getOpenedByWorkerId()).isEqualTo(10L);
        assertThat(dto.getOpenedByWorkerName()).isEqualTo("Nyitó Pénztáros");
        assertThat(dto.getClosedAt()).isEqualTo(closedAt);
        assertThat(dto.getClosedByWorkerId()).isEqualTo(11L);
        assertThat(dto.getClosedByWorkerName()).isEqualTo("Záró Pénztáros");
        assertThat(dto.getOpeningBalanceHuf()).isEqualByComparingTo("100000");
        assertThat(dto.getClosingBalanceHuf()).isEqualByComparingTo("125000");
        assertThat(dto.getDailyChange()).isEqualByComparingTo("25000");
        assertThat(dto.getTotalBuyHuf()).isEqualByComparingTo("50000");
        assertThat(dto.getTotalSellHuf()).isEqualByComparingTo("30000");
        assertThat(dto.getNetTurnover()).isEqualByComparingTo("-20000");
        assertThat(dto.getTotalHandlingFees()).isEqualByComparingTo("1500");
        assertThat(dto.getTransactionCount()).isEqualTo(15);
        assertThat(dto.getReversalCount()).isEqualTo(1);
        assertThat(dto.getDenominationVerified()).isTrue();
    }

    @Test
    @DisplayName("Hiányzó nyitó vagy záró egyenleg esetén dailyChange ZERO")
    void mapsDailyChangeAsZeroWhenOpeningOrClosingMissing() {
        DailySession missingClosing = DailySession.builder()
                .openingBalanceHuf(new BigDecimal("100000"))
                .closingBalanceHuf(null)
                .build();
        DailySession missingOpening = DailySession.builder()
                .openingBalanceHuf(null)
                .closingBalanceHuf(new BigDecimal("125000"))
                .build();

        assertThat(mapper.toDto(missingClosing).getDailyChange()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(mapper.toDto(missingOpening).getDailyChange()).isEqualByComparingTo(BigDecimal.ZERO);
    }

    @Test
    @DisplayName("Hiányzó branch és dolgozók → null ID/name mezők NPE nélkül")
    void mapsNullBranchAndWorkersSafely() {
        DailySession entity = DailySession.builder()
                .branch(null)
                .openedByWorker(null)
                .closedByWorker(null)
                .openingBalanceHuf(new BigDecimal("1000"))
                .closingBalanceHuf(new BigDecimal("1500"))
                .build();

        DailySessionDto dto = mapper.toDto(entity);

        assertThat(dto.getBranchId()).isNull();
        assertThat(dto.getBranchName()).isNull();
        assertThat(dto.getOpenedByWorkerId()).isNull();
        assertThat(dto.getOpenedByWorkerName()).isNull();
        assertThat(dto.getClosedByWorkerId()).isNull();
        assertThat(dto.getClosedByWorkerName()).isNull();
    }
}
