package hu.puzzleir.valuta.mapper;

import hu.puzzleir.valuta.dto.denomination.DenominationDto;
import hu.puzzleir.valuta.dto.denomination.UpdateDenominationDto;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.service.DenominationService;
import org.springframework.stereotype.Component;

/**
 * Denomination entity <-> DTO mapper
 */
@Component
public class DenominationMapper {

    public DenominationDto toDto(Denomination entity) {
        if (entity == null) return null;

        return DenominationDto.builder()
                .id(entity.getId())
                .branchId(entity.getBranch().getId().toString())
                .branchName(entity.getBranch().getName())
                .currencyId(entity.getCurrency().getId())
                .currencyCode(entity.getCurrency().getCode())
                .currencyName(entity.getCurrency().getName())
                .faceValue(entity.getFaceValue())
                .denominationType(entity.getDenominationType())
                .quantity(entity.getQuantity())
                .totalValue(entity.getTotalValue())
                .minQuantity(entity.getMinQuantity())
                .maxQuantity(entity.getMaxQuantity())
                .lowStock(entity.isLowStock())
                .active(entity.getActive())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    public DenominationService.UpdateDenominationRequest toServiceRequest(UpdateDenominationDto dto) {
        return DenominationService.UpdateDenominationRequest.builder()
                .currencyId(dto.getCurrencyId())
                .faceValue(dto.getFaceValue())
                .newQuantity(dto.getNewQuantity())
                .build();
    }
}
