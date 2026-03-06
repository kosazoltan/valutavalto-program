package com.puzzleir.backend.service;

import com.puzzleir.backend.dto.CreateRestrictionDto;
import com.puzzleir.backend.dto.CustomerRestrictionDto;
import com.puzzleir.backend.dto.CustomerScreeningLogDto;
import com.puzzleir.backend.entity.CustomerRestriction;
import com.puzzleir.backend.entity.CustomerScreeningLog;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.repository.CustomerRestrictionRepository;
import com.puzzleir.backend.repository.CustomerScreeningLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class CustomerControlService {

    private final CustomerRestrictionRepository restrictionRepository;
    private final CustomerScreeningLogRepository screeningLogRepository;

    // 15M HUF/év limit
    private static final BigDecimal ANNUAL_LIMIT_HUF = new BigDecimal("15000000");

    /**
     * Ügyfél korlátozásainak lekérdezése (aktívak)
     */
    @Transactional(readOnly = true)
    public List<CustomerRestrictionDto> getActiveRestrictions(Long customerId) {
        return restrictionRepository.findByCustomerIdAndActiveTrue(customerId)
                .stream()
                .map(this::toRestrictionDto)
                .collect(Collectors.toList());
    }

    /**
     * Ügyfél összes korlátozása (aktív + inaktív)
     */
    @Transactional(readOnly = true)
    public List<CustomerRestrictionDto> getAllRestrictions(Long customerId) {
        return restrictionRepository.findByCustomerId(customerId)
                .stream()
                .map(this::toRestrictionDto)
                .collect(Collectors.toList());
    }

    /**
     * Új korlátozás hozzáadása
     */
    public CustomerRestrictionDto addRestriction(Long customerId, Long workerId,
                                                  CreateRestrictionDto dto) {
        log.info("Új korlátozás - ügyfél: {}, típus: {}", customerId, dto.getRestrictionType());

        CustomerRestriction restriction = CustomerRestriction.builder()
                .customerId(customerId)
                .restrictionType(dto.getRestrictionType())
                .reason(dto.getReason())
                .addedBy(workerId)
                .addedAt(LocalDateTime.now())
                .expiresAt(dto.getExpiresAt())
                .active(true)
                .build();

        CustomerRestriction saved = restrictionRepository.save(restriction);
        log.info("Korlátozás rögzítve: {}", saved.getId());
        return toRestrictionDto(saved);
    }

    /**
     * Korlátozás eltávolítása (soft: active = false)
     */
    public void removeRestriction(UUID restrictionId) {
        CustomerRestriction restriction = restrictionRepository.findById(restrictionId)
                .orElseThrow(() -> new ResourceNotFoundException("Korlátozás nem található: " + restrictionId));

        restriction.setActive(false);
        restrictionRepository.save(restriction);
        log.info("Korlátozás deaktiválva: {}", restrictionId);
    }

    /**
     * Éves tranzakció összeg lekérdezése (HUF)
     * TODO(integration): Integráció a Transaction repository-val — TransactionRepository.sumHufByCustomerAndYear() szükséges
     */
    @Transactional(readOnly = true)
    public BigDecimal getAnnualTransactionTotal(Long customerId, int year) {
        log.debug("Éves összeg lekérdezés - ügyfél: {}, év: {}", customerId, year);
        // TODO(integration): SELECT SUM(huf_amount) FROM transaction WHERE customer_id = :customerId AND YEAR(transaction_date) = :year
        return BigDecimal.ZERO;
    }

    /**
     * Éves limit ellenőrzés (>15M HUF → figyelmeztetés)
     */
    @Transactional(readOnly = true)
    public boolean checkAnnualLimit(Long customerId) {
        int currentYear = LocalDateTime.now().getYear();
        BigDecimal total = getAnnualTransactionTotal(customerId, currentYear);
        boolean exceeded = total.compareTo(ANNUAL_LIMIT_HUF) > 0;
        if (exceeded) {
            log.warn("Éves limit túllépve! Ügyfél: {}, összeg: {} HUF", customerId, total);
        }
        return exceeded;
    }

    /**
     * Szűrési napló lekérdezése
     */
    @Transactional(readOnly = true)
    public List<CustomerScreeningLogDto> getScreeningHistory(Long customerId) {
        return screeningLogRepository.findByCustomerIdOrderByScreenedAtDesc(customerId)
                .stream()
                .map(this::toScreeningDto)
                .collect(Collectors.toList());
    }

    // --- Helpers ---

    private CustomerRestrictionDto toRestrictionDto(CustomerRestriction entity) {
        return CustomerRestrictionDto.builder()
                .id(entity.getId())
                .customerId(entity.getCustomerId())
                .restrictionType(entity.getRestrictionType())
                .reason(entity.getReason())
                .addedBy(entity.getAddedBy())
                .addedAt(entity.getAddedAt())
                .expiresAt(entity.getExpiresAt())
                .active(entity.getActive())
                .build();
    }

    private CustomerScreeningLogDto toScreeningDto(CustomerScreeningLog entity) {
        return CustomerScreeningLogDto.builder()
                .id(entity.getId())
                .customerId(entity.getCustomerId())
                .screeningType(entity.getScreeningType())
                .result(entity.getResult())
                .details(entity.getDetails())
                .screenedAt(entity.getScreenedAt())
                .screenedBy(entity.getScreenedBy())
                .build();
    }
}
