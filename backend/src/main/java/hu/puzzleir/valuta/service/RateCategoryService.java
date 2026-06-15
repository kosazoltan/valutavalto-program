package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.ratecategory.CreateRateCategoryDto;
import hu.puzzleir.valuta.dto.ratecategory.RateCategoryDto;
import hu.puzzleir.valuta.entity.RateCategory;
import hu.puzzleir.valuta.entity.RateCategory.RateCategoryType;
import hu.puzzleir.valuta.repository.RateCategoryRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
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
        // FINDING #7 IDOR fix: a branch a hívó cégéé kell legyen (RateCategory branch→company
        // multi-tenant). Cross-tenant branchId → ResourceNotFoundException, hogy ne szivárogjon
        // ki más cég árfolyam-kategóriája.
        assertBranchOwnership(branchId);

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

    @Transactional(rollbackFor = Exception.class)
    public RateCategoryDto setRateCategory(CreateRateCategoryDto dto) {
        Branch branch = branchRepository.findById(dto.getBranchId())
            .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + dto.getBranchId()));

        RateCategoryType catType;
        try {
            catType = RateCategoryType.valueOf(dto.getCategory());
        } catch (IllegalArgumentException e) {
            throw new ResourceNotFoundException("Érvénytelen árfolyam kategória: " + dto.getCategory());
        }

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
        // FINDING #7 IDOR fix: branch-ownership guard a cross-tenant lekérdezés ellen.
        assertBranchOwnership(branchId);

        return rateCategoryRepository.findByBranchId(branchId).stream()
            .map(this::toDto)
            .toList();
    }

    // ============ HELPER ============

    /**
     * FINDING #7 (multi-tenant IDOR): a megadott branch a hívó cégéhez tartozik-e.
     * A RateCategory branch→company láncon multi-tenant; a branch-param végpontoknál
     * (getRateForAmount / getAll) a hívó cégéhez kötjük a hozzáférést. Ha a branch nem
     * létezik vagy más céghez tartozik, ResourceNotFoundException (nem leak-elő üzenet).
     */
    private void assertBranchOwnership(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (branchId == null || !branchRepository.existsByIdAndCompanyId(branchId, companyId)) {
            throw new ResourceNotFoundException("Iroda nem található: " + branchId);
        }
    }

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
