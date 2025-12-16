package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.cashbalance.AdjustBalanceDto;
import hu.puzzleir.valuta.dto.cashbalance.CashBalanceDto;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.service.CashBalanceService;
import org.springframework.stereotype.Component;

/**
 * CashBalance entity <-> DTO mapper
 */
@Component
public class CashBalanceMapper {

    public CashBalanceDto toDto(CashBalance entity) {
        if (entity == null) return null;

        return CashBalanceDto.builder()
                .id(entity.getId())
                .branchId(entity.getBranch().getId().toString())
                .branchName(entity.getBranch().getName())
                .currencyId(entity.getCurrency().getId())
                .currencyCode(entity.getCurrency().getCode())
                .currencyName(entity.getCurrency().getName())
                .currencySymbol(entity.getCurrency().getSymbol())
                .currentBalance(entity.getCurrentBalance())
                .openingBalance(entity.getOpeningBalance())
                .dailyChange(entity.getDailyChange())
                .minBalance(entity.getMinBalance())
                .maxBalance(entity.getMaxBalance())
                .lowBalanceAlert(entity.isLowBalance())
                .highBalanceAlert(entity.isHighBalance())
                .lastTransactionAt(entity.getLastTransactionAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    public CashBalanceService.AdjustBalanceRequest toServiceRequest(AdjustBalanceDto dto) {
        return CashBalanceService.AdjustBalanceRequest.builder()
                .currencyId(dto.getCurrencyId())
                .amount(dto.getAmount())
                .incoming(dto.getIncoming())
                .reason(dto.getReason())
                .build();
    }
}
