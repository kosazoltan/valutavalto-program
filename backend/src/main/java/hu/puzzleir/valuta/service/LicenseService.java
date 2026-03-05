package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.license.LicenseResponse;
import hu.puzzleir.valuta.dto.license.LicenseStatusResponse;
import hu.puzzleir.valuta.entity.License;
import hu.puzzleir.valuta.repository.LicenseRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

/**
 * Licenc kezelés szolgáltatás.
 * Validáció, aktuális licenc lekérdezés, feature ellenőrzés, aktiválás.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LicenseService {

    private final LicenseRepository licenseRepository;

    /**
     * Licenc validáció — VALID / EXPIRED / EXCEEDED / NO_LICENSE.
     */
    @Transactional(readOnly = true)
    public LicenseStatusResponse validateLicense() {
        return licenseRepository.findByIsActiveTrue()
                .map(license -> {
                    String status;
                    LocalDate now = LocalDate.now();

                    if (now.isAfter(license.getValidTo())) {
                        status = "EXPIRED";
                    } else if (now.isBefore(license.getValidFrom())) {
                        status = "NOT_YET_VALID";
                    } else {
                        status = "VALID";
                    }

                    int remaining = (int) ChronoUnit.DAYS.between(now, license.getValidTo());

                    return LicenseStatusResponse.builder()
                            .status(status)
                            .remainingDays(Math.max(remaining, 0))
                            .maxBranches(license.getMaxBranches())
                            .maxWorkers(license.getMaxWorkers())
                            .features(license.getFeatures())
                            .build();
                })
                .orElse(LicenseStatusResponse.builder()
                        .status("NO_LICENSE")
                        .remainingDays(0)
                        .maxBranches(0)
                        .maxWorkers(0)
                        .build());
    }

    /**
     * Aktuális aktív licenc lekérdezése.
     */
    @Transactional(readOnly = true)
    public LicenseResponse getCurrentLicense() {
        License license = licenseRepository.findByIsActiveTrue()
                .orElseThrow(() -> new RuntimeException("Nincs aktív licenc."));

        int remaining = (int) ChronoUnit.DAYS.between(LocalDate.now(), license.getValidTo());

        return LicenseResponse.builder()
                .id(license.getId())
                .companyId(license.getCompanyId())
                .licenseKey(license.getLicenseKey())
                .validFrom(license.getValidFrom())
                .validTo(license.getValidTo())
                .maxBranches(license.getMaxBranches())
                .maxWorkers(license.getMaxWorkers())
                .features(license.getFeatures())
                .isActive(license.getIsActive())
                .remainingDays(Math.max(remaining, 0))
                .build();
    }

    /**
     * Feature ellenőrzés — engedélyezett-e a modul.
     */
    @Transactional(readOnly = true)
    public boolean checkFeature(String featureName) {
        return licenseRepository.findByIsActiveTrue()
                .map(license -> {
                    if (license.getFeatures() == null) return false;
                    return license.getFeatures().contains("\"" + featureName + "\"");
                })
                .orElse(false);
    }

    /**
     * Hátralévő napok.
     */
    @Transactional(readOnly = true)
    public int getRemainingDays() {
        return licenseRepository.findByIsActiveTrue()
                .map(license -> {
                    int remaining = (int) ChronoUnit.DAYS.between(LocalDate.now(), license.getValidTo());
                    return Math.max(remaining, 0);
                })
                .orElse(0);
    }

    /**
     * Licenc aktiválás kulccsal.
     */
    @Transactional
    public LicenseResponse activateLicense(String licenseKey) {
        final License license = licenseRepository.findByLicenseKey(licenseKey)
                .orElseThrow(() -> new RuntimeException("Érvénytelen licenc kulcs: " + licenseKey));

        // Korábbi aktív licencek deaktiválása
        licenseRepository.findByIsActiveTrue().ifPresent(existing -> {
            if (!existing.getId().equals(license.getId())) {
                existing.setIsActive(false);
                licenseRepository.save(existing);
                log.info("Korábbi licenc deaktiválva: {}", existing.getId());
            }
        });

        license.setIsActive(true);
        license.setActivatedAt(LocalDateTime.now());
        License savedLicense = licenseRepository.save(license);

        log.info("Licenc aktiválva: key={}, validTo={}", licenseKey, savedLicense.getValidTo());

        int remaining = (int) ChronoUnit.DAYS.between(LocalDate.now(), savedLicense.getValidTo());

        return LicenseResponse.builder()
                .id(savedLicense.getId())
                .companyId(savedLicense.getCompanyId())
                .licenseKey(savedLicense.getLicenseKey())
                .validFrom(savedLicense.getValidFrom())
                .validTo(savedLicense.getValidTo())
                .maxBranches(savedLicense.getMaxBranches())
                .maxWorkers(savedLicense.getMaxWorkers())
                .features(savedLicense.getFeatures())
                .isActive(savedLicense.getIsActive())
                .remainingDays(Math.max(remaining, 0))
                .build();
    }
}
