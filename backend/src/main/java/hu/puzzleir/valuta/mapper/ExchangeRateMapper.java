package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.exchangerate.CreateExchangeRateDto;
import hu.puzzleir.valuta.dto.exchangerate.ExchangeRateDto;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.service.ExchangeRateService;
import org.springframework.stereotype.Component;

/**
 * ExchangeRate entity <-> DTO mapper
 */
@Component
public class ExchangeRateMapper {

    public ExchangeRateDto toDto(ExchangeRate entity) {
        if (entity == null) return null;

        return ExchangeRateDto.builder()
                .id(entity.getId())
                .currencyId(entity.getCurrency().getId())
                .currencyCode(entity.getCurrency().getCode())
                .currencyName(entity.getCurrency().getName())
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
}
