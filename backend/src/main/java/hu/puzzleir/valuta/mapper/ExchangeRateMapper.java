package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.exchangerate.CreateExchangeRateDto;
import hu.puzzleir.valuta.dto.exchangerate.CurrentRateDto;
import hu.puzzleir.valuta.dto.exchangerate.ExchangeRateDto;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.service.ExchangeRateService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Set;

/**
 * ExchangeRate entity <-> DTO mapper
 */
@Component
public class ExchangeRateMapper {

    /** Valuták ahol az egység 100 (pl. JPY) */
    private static final Set<String> UNIT_100_CURRENCIES = Set.of("JPY");

    /**
     * FKH-032 FR-6: ugyanaz a korhatar, amit az ExchangeRateService.validateRateFreshness
     * hasznal — a listazo valasz isStale/ageHours mezoje nem terhet el a dobo validaciotol.
     */
    @Value("${exchange-rate.max-age-hours:24}")
    private int maxAgeHours;

    public ExchangeRateDto toDto(ExchangeRate entity) {
        if (entity == null) return null;

        // FKH-032 FR-6: szamitott frissesseg-mezok, a service kozos (nem dobo) logikajaval.
        long minutesOld = ExchangeRateService.calculateRateAgeMinutes(
                entity.getValidDate(), entity.getValidTime(), LocalDateTime.now());
        boolean stale = entity.getValidDate() != null && entity.getValidTime() != null
                && ExchangeRateService.isRateStale(minutesOld, maxAgeHours);

        return ExchangeRateDto.builder()
                .id(entity.getId())
                .currencyId(entity.getCurrency() != null ? entity.getCurrency().getId() : null)
                .currencyCode(entity.getCurrency() != null ? entity.getCurrency().getCode() : null)
                .currencyName(entity.getCurrency() != null ? entity.getCurrency().getName() : null)
                .validDate(entity.getValidDate())
                .validTime(entity.getValidTime())
                .baseBuyRate(entity.getBaseBuyRate())
                .baseSellRate(entity.getBaseSellRate())
                .limit1Amount(entity.getLimit1Amount())
                .limit1BuyRate(entity.getLimit1BuyRate())
                .limit1SellRate(entity.getLimit1SellRate())
                .limit2Amount(entity.getLimit2Amount())
                .limit2BuyRate(entity.getLimit2BuyRate())
                .limit2SellRate(entity.getLimit2SellRate())
                .limit3Amount(entity.getLimit3Amount())
                .limit3BuyRate(entity.getLimit3BuyRate())
                .limit3SellRate(entity.getLimit3SellRate())
                .officialRate(entity.getOfficialRate())
                .active(entity.getActive())
                .createdBy(entity.getCreatedBy())
                .createdAt(entity.getCreatedAt())
                .ageHours(minutesOld / 60L)
                .stale(stale)
                .build();
    }

    public ExchangeRateService.CreateExchangeRateRequest toServiceRequest(CreateExchangeRateDto dto) {
        return ExchangeRateService.CreateExchangeRateRequest.builder()
                .currencyId(dto.getCurrencyId())
                .branchId(dto.getBranchId())
                .baseBuyRate(dto.getBaseBuyRate())
                .baseSellRate(dto.getBaseSellRate())
                .limit1Amount(dto.getLimit1Amount())
                .limit1BuyRate(dto.getLimit1BuyRate())
                .limit1SellRate(dto.getLimit1SellRate())
                .limit2Amount(dto.getLimit2Amount())
                .limit2BuyRate(dto.getLimit2BuyRate())
                .limit2SellRate(dto.getLimit2SellRate())
                .limit3Amount(dto.getLimit3Amount())
                .limit3BuyRate(dto.getLimit3BuyRate())
                .limit3SellRate(dto.getLimit3SellRate())
                .officialRate(dto.getOfficialRate())
                .build();
    }

    /**
     * POS kliens számára egyszerűsített árfolyam DTO.
     * Pontosan a frontend ExchangeRate TypeScript típusra képez.
     */
    public CurrentRateDto toCurrentRateDto(ExchangeRate entity) {
        String currencyCode = entity.getCurrency() != null ? entity.getCurrency().getCode() : null;
        int unit = currencyCode != null && UNIT_100_CURRENCIES.contains(currencyCode) ? 100 : 1;

        String updatedAt = null;
        if (entity.getCreatedAt() != null) {
            updatedAt = entity.getCreatedAt().toString();
        } else if (entity.getValidDate() != null) {
            updatedAt = entity.getValidDate().toString();
        }

        return CurrentRateDto.builder()
                .currencyCode(currencyCode)
                .buyRate(entity.getBaseBuyRate())
                .sellRate(entity.getBaseSellRate())
                .unit(unit)
                .updatedAt(updatedAt)
                .officialRate(entity.getOfficialRate())
                .limit1Amount(entity.getLimit1Amount())
                .limit1BuyRate(entity.getLimit1BuyRate())
                .limit1SellRate(entity.getLimit1SellRate())
                .limit2Amount(entity.getLimit2Amount())
                .limit2BuyRate(entity.getLimit2BuyRate())
                .limit2SellRate(entity.getLimit2SellRate())
                .limit3Amount(entity.getLimit3Amount())
                .limit3BuyRate(entity.getLimit3BuyRate())
                .limit3SellRate(entity.getLimit3SellRate())
                .build();
    }
}
