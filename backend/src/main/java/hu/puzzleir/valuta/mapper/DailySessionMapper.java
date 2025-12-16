package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.dailysession.DailySessionDto;
import hu.puzzleir.valuta.entity.DailySession;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

/**
 * DailySession entity <-> DTO mapper
 */
@Component
public class DailySessionMapper {

    public DailySessionDto toDto(DailySession entity) {
        if (entity == null) return null;

        BigDecimal dailyChange = BigDecimal.ZERO;
        if (entity.getClosingBalanceHuf() != null && entity.getOpeningBalanceHuf() != null) {
            dailyChange = entity.getClosingBalanceHuf().subtract(entity.getOpeningBalanceHuf());
        }

        return DailySessionDto.builder()
                .id(entity.getId())
                .sessionDate(entity.getSessionDate())
                .status(entity.getStatus())
                .branchId(entity.getBranch().getId().toString())
                .branchName(entity.getBranch().getName())
                .openedAt(entity.getOpenedAt())
                .openedByWorkerId(entity.getOpenedByWorker() != null ? entity.getOpenedByWorker().getId() : null)
                .openedByWorkerName(entity.getOpenedByWorker() != null ? entity.getOpenedByWorker().getName() : null)
                .openingBalanceHuf(entity.getOpeningBalanceHuf())
                .closedAt(entity.getClosedAt())
                .closedByWorkerId(entity.getClosedByWorker() != null ? entity.getClosedByWorker().getId() : null)
                .closedByWorkerName(entity.getClosedByWorker() != null ? entity.getClosedByWorker().getName() : null)
                .closingBalanceHuf(entity.getClosingBalanceHuf())
                .denominationVerified(entity.getDenominationVerified())
                .transactionCount(entity.getTransactionCount())
                .reversalCount(entity.getReversalCount())
                .totalBuyHuf(entity.getBuyTurnoverHuf())
                .totalSellHuf(entity.getSellTurnoverHuf())
                .totalHandlingFees(entity.getHandlingFeeTotal())
                .dailyChange(dailyChange)
                .netTurnover(entity.getNetTurnover())
                .build();
    }
}
