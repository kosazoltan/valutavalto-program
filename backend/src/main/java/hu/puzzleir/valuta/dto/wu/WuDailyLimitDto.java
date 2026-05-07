package hu.puzzleir.valuta.dto.wu;

import hu.puzzleir.valuta.entity.WuDailyLimit;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
public class WuDailyLimitDto {
    private UUID id;
    private LocalDate businessDate;
    private String currencyCode;
    private BigDecimal dailyLimit;
    private BigDecimal usedAmount;
    private BigDecimal remainingAmount;
    private BigDecimal usagePercent;
    private LocalDateTime resetAt;

    public static WuDailyLimitDto from(WuDailyLimit limit) {
        BigDecimal dailyLimit = limit.getDailyLimit() != null ? limit.getDailyLimit() : BigDecimal.ZERO;
        BigDecimal usedAmount = limit.getUsedAmount() != null ? limit.getUsedAmount() : BigDecimal.ZERO;
        BigDecimal remaining = dailyLimit.subtract(usedAmount).max(BigDecimal.ZERO);
        BigDecimal percent = dailyLimit.compareTo(BigDecimal.ZERO) > 0
                ? usedAmount.multiply(new BigDecimal("100")).divide(dailyLimit, 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        return WuDailyLimitDto.builder()
                .id(limit.getId())
                .businessDate(limit.getBusinessDate())
                .currencyCode(limit.getCurrencyCode())
                .dailyLimit(dailyLimit)
                .usedAmount(usedAmount)
                .remainingAmount(remaining)
                .usagePercent(percent)
                .resetAt(limit.getResetAt())
                .build();
    }
}
