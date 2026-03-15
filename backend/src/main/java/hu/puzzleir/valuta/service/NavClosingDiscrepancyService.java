package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.NavClosing;
import hu.puzzleir.valuta.entity.NavClosingStatus;
import hu.puzzleir.valuta.entity.NavClosingType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.NavClosingRepository;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * NAV zárás eltérés-kezelés.
 *
 * Legacy: NAVZARO.DLL — napi záráskor a pénztáros beüti a NAV pénztárgép
 * záró forint összegét. A rendszer összehasonlítja a nyilvántartás szerinti
 * záró értékkel. Ha eltérés van, kötelező megjegyzés (min 20 karakter) és
 * automatikus értesítés küldése a területi vezetőnek.
 *
 * Logika:
 * 1. Pénztáros beüti a NAV pénztárgépen kimutatott záró forint összeget
 * 2. Rendszer lekéri a napi kezelési díj + nyitó/záró egyenleg adatokat
 * 3. Összehasonlítás:
 *    - Ha egyezik → zöld (OK), továbbléphet
 *    - Ha eltér → piros, kötelező indoklás (min 20 karakter)
 * 4. Eltérés esetén automatikus riasztás (email/push) a területi vezetőnek
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NavClosingDiscrepancyService {

    private final NavClosingRepository navClosingRepository;
    private final BranchRepository branchRepository;

    /** Minimum indoklás hossz eltérés esetén (legacy: 20 karakter) */
    private static final int MIN_JUSTIFICATION_LENGTH = 20;

    /**
     * NAV záró összeg validálása.
     *
     * A pénztáros a NAV pénztárgépen leolvassa a záró forint összeget és beüti.
     * A rendszer összehasonlítja a nyilvántartás szerinti összeggel.
     *
     * @param branchId    iroda ID
     * @param date        zárás dátuma
     * @param navAmount   NAV pénztárgépen mutatott záró összeg (amit a pénztáros beüt)
     * @return validációs eredmény
     */
    @Transactional(readOnly = true)
    public NavClosingValidationResult validateNavClosingAmount(
            UUID branchId, LocalDate date, BigDecimal navAmount) {

        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        NavClosing closing = navClosingRepository
                .findByBranchIdAndClosingDateAndClosingType(branchId, date, NavClosingType.DAILY)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "NAV napi zárás nem található: branchId=" + branchId + ", date=" + date));

        // Nyilvántartás szerinti összeg = bevétel - kiadás + kezelési díj
        BigDecimal systemAmount = closing.getTotalRevenue()
                .subtract(closing.getTotalExpense())
                .add(closing.getHandlingFeeTotal());

        BigDecimal discrepancy = navAmount.subtract(systemAmount);
        boolean isMatch = discrepancy.compareTo(BigDecimal.ZERO) == 0;

        log.info("NAV zárás validáció: branch={}, date={}, NAV={}, rendszer={}, eltérés={}, egyezik={}",
                branch.getCode(), date, navAmount, systemAmount, discrepancy, isMatch);

        return NavClosingValidationResult.builder()
                .branchCode(branch.getCode())
                .branchName(branch.getName())
                .closingDate(date)
                .navAmount(navAmount)
                .systemAmount(systemAmount)
                .discrepancy(discrepancy)
                .isMatch(isMatch)
                .closingId(closing.getId())
                .build();
    }

    /**
     * NAV zárás eltérés jóváhagyása indoklással.
     *
     * Ha a záró összeg eltér, a pénztárosnak kötelező indoklást kell adnia.
     * Az indoklás minimum 20 karakter (legacy szabály).
     * Sikeres jóváhagyás után automatikus értesítés a területi vezetőnek.
     *
     * @param closingId     NAV zárás ID
     * @param navAmount     NAV pénztárgépen mutatott összeg
     * @param justification indoklás (min 20 karakter)
     */
    @Transactional
    public void approveDiscrepancy(UUID closingId, BigDecimal navAmount, String justification) {
        NavClosing closing = navClosingRepository.findById(closingId)
                .orElseThrow(() -> new ResourceNotFoundException("NAV zárás nem található: " + closingId));

        if (closing.getStatus() != NavClosingStatus.CLOSED) {
            throw new ValidationException(
                    "Csak CLOSED státuszú zárás hagyható jóvá! Jelenlegi: " + closing.getStatus());
        }

        // Validáció: indoklás min. 20 karakter
        if (justification == null || justification.trim().length() < MIN_JUSTIFICATION_LENGTH) {
            throw new ValidationException(
                    "Az eltérés indoklása legalább " + MIN_JUSTIFICATION_LENGTH +
                    " karakter kell legyen! Jelenlegi: " +
                    (justification != null ? justification.trim().length() : 0));
        }

        // Megjegyzésbe mentés
        closing.setNavReferenceNumber("DISCREPANCY-APPROVED");
        closing.setClosedAt(LocalDateTime.now());

        navClosingRepository.save(closing);

        log.warn("NAV zárás eltérés jóváhagyva: closingId={}, navAmount={}, indoklás={}",
                closingId, navAmount, justification.trim());

        // Értesítés küldése a területi vezetőnek
        sendDiscrepancyNotification(closing, navAmount, justification);
    }

    /**
     * Értesítés küldése a területi vezetőnek eltérés esetén.
     *
     * Legacy: NAVZARO.DLL — XML email generálás + FTP feltöltés.
     * Modern: REST API alapú push notification / email.
     */
    private void sendDiscrepancyNotification(NavClosing closing, BigDecimal navAmount, String justification) {
        Branch branch = closing.getBranch();

        BigDecimal systemAmount = closing.getTotalRevenue()
                .subtract(closing.getTotalExpense())
                .add(closing.getHandlingFeeTotal());
        BigDecimal discrepancy = navAmount.subtract(systemAmount);

        log.warn("NAV ELTÉRÉS ÉRTESÍTÉS: iroda={} ({}), dátum={}, NAV összeg={}, " +
                "rendszer összeg={}, eltérés={}, indoklás={}",
                branch.getName(), branch.getCode(),
                closing.getClosingDate(),
                navAmount, systemAmount, discrepancy,
                justification.trim());

        // TODO: Valódi email/push notification küldése
        // A legacy rendszerben ez FTP-n keresztül XML email-t küldött a területi vezetőnek.
        // Az új rendszerben a NotificationService-en keresztül küldünk email-t.
    }

    // ========== RESULT DTO ==========

    @Data
    @Builder
    public static class NavClosingValidationResult {
        private String branchCode;
        private String branchName;
        private LocalDate closingDate;
        private BigDecimal navAmount;
        private BigDecimal systemAmount;
        private BigDecimal discrepancy;
        private boolean isMatch;
        private UUID closingId;
    }
}
