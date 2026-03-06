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
                .branchId(entity.getBranch() != null ? entity.getBranch().getId().toString() : null)
                .branchName(entity.getBranch() != null ? entity.getBranch().getName() : null)
                .currencyId(entity.getCurrency() != null ? entity.getCurrency().getId() : null)
                .currencyCode(entity.getCurrency() != null ? entity.getCurrency().getCode() : null)
                .currencyName(entity.getCurrency() != null ? entity.getCurrency().getName() : null)
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
