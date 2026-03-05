package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.repository.BranchRepository;
import hu.puzzleir.valuta.dto.ratecategory.CreateRateCategoryDto;
import hu.puzzleir.valuta.dto.ratecategory.RateCategoryDto;
import hu.puzzleir.valuta.entity.RateCategory;
import hu.puzzleir.valuta.entity.RateCategory.RateCategoryType;
import hu.puzzleir.valuta.repository.RateCategoryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Kis/Nagy váltós árfolyam szolgáltatás.
 * SMALL: < 500 EUR egyenérték
 * STANDARD: 500-5000 EUR egyenérték
 * LARGE: > 5000 EUR egyenérték
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RateCategoryService {

    private final RateCategoryRepository rateCategoryRepository;
    private final BranchRepository branchRepository;

    private static final BigDecimal SMALL_THRESHOLD_EUR = new BigDecimal("500");
    private static final BigDecimal LARGE_THRESHOLD_EUR = new BigDecimal("5000");

    /**
     * Összeg alapján az adott valuta kategóriájának megfelelő árfolyam.
     */
    @Transactional(readOnly = true)
    public RateCategoryDto getRateForAmount(UUID branchId, String currencyCode, BigDecimal amount) {
        RateCategoryType category = determineCategory(amount);

        // Először a megfelelő kategóriát keressük
        RateCategory rc = rateCategoryRepository
            .findByBranchIdAndCurrencyCodeAndCategory(branchId, currencyCode, category)
            .orElse(null);

        // Ha nincs ilyen kategória, STANDARD-ra fallback
        if (rc == null) {
            rc = rateCategoryRepository
                .findByBranchIdAndCurrencyCodeAndCategory(branchId, currencyCode, RateCategoryType.STANDARD)
                .orElse(null);
        }

        if (rc == null) {
            throw new ResourceNotFoundException("Nincs árfolyam kategória: " +
                currencyCode + " / " + category + " a(z) " + branchId + " irodához.");
        }

        return toDto(rc);
    }

    @Transactional
    public RateCategoryDto setRateCategory(CreateRateCategoryDto dto) {
        Branch branch = branchRepository.findById(dto.getBranchId())
            .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + dto.getBranchId()));

        RateCategoryType catType = RateCategoryType.valueOf(dto.getCategory());

        RateCategory rc = rateCategoryRepository
            .findByBranchIdAndCurrencyCodeAndCategory(dto.getBranchId(), dto.getCurrencyCode(), catType)
            .orElse(RateCategory.builder()
                .branch(branch)
                .currencyCode(dto.getCurrencyCode())
                .category(catType)
                .validFrom(LocalDateTime.now())
                .build());

        rc.setBuyRate(dto.getBuyRate());
        rc.setSellRate(dto.getSellRate());
        rc.setMinAmount(dto.getMinAmount());
        rc.setMaxAmount(dto.getMaxAmount());

        rc = rateCategoryRepository.save(rc);
        log.info("Árfolyam kategória beállítva: branch={}, currency={}, category={}",
            dto.getBranchId(), dto.getCurrencyCode(), dto.getCategory());

        return toDto(rc);
    }

    @Transactional(readOnly = true)
    public List<RateCategoryDto> getAll(UUID branchId) {
        return rateCategoryRepository.findByBranchId(branchId).stream()
            .map(this::toDto)
            .toList();
    }

    // ============ HELPER ============

    /**
     * Kategória meghatározása EUR-egyenérték alapján.
     * Az összeg már EUR-ben vagy EUR-ekvivalensben értendő.
     */
    private RateCategoryType determineCategory(BigDecimal eurEquivalent) {
        if (eurEquivalent.compareTo(SMALL_THRESHOLD_EUR) < 0) {
            return RateCategoryType.SMALL;
        } else if (eurEquivalent.compareTo(LARGE_THRESHOLD_EUR) > 0) {
            return RateCategoryType.LARGE;
        }
        return RateCategoryType.STANDARD;
    }

    private RateCategoryDto toDto(RateCategory entity) {
        return RateCategoryDto.builder()
            .id(entity.getId())
            .branchId(entity.getBranch().getId())
            .currencyCode(entity.getCurrencyCode())
            .category(entity.getCategory().name())
            .buyRate(entity.getBuyRate())
            .sellRate(entity.getSellRate())
            .minAmount(entity.getMinAmount())
            .maxAmount(entity.getMaxAmount())
            .validFrom(entity.getValidFrom())
            .validTo(entity.getValidTo())
            .build();
    }
}
