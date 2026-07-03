package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.license.LicenseStatusResponse;
import hu.puzzleir.valuta.entity.License;
import hu.puzzleir.valuta.repository.LicenseRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * LicenseService UNIT tesztek — Mockito.
 */
@ExtendWith(MockitoExtension.class)
class LicenseServiceTest {

    @InjectMocks
    private LicenseService service;

    @Mock
    private LicenseRepository licenseRepository;

    @Spy
    private ObjectMapper objectMapper = new ObjectMapper();

    private License createValidLicense() {
        return License.builder()
                .id(UUID.randomUUID())
                .companyId(1)
                .licenseKey("LIC-VALID-2026")
                .validFrom(LocalDate.now().minusDays(30))
                .validTo(LocalDate.now().plusDays(90))
                .maxBranches(5)
                .maxWorkers(20)
                .features("[\"WU\",\"HRK\",\"STAMPS\",\"AML\"]")
                .isActive(true)
                .build();
    }

    private License createExpiredLicense() {
        return License.builder()
                .id(UUID.randomUUID())
                .companyId(1)
                .licenseKey("LIC-EXPIRED-2025")
                .validFrom(LocalDate.now().minusYears(1))
                .validTo(LocalDate.now().minusDays(10))
                .maxBranches(3)
                .maxWorkers(10)
                .features("[\"WU\"]")
                .isActive(true)
                .build();
    }

    @Test
    @DisplayName("validateLicense → valid license → VALID status")
    void testValidateLicense_valid() {
        when(licenseRepository.findByIsActiveTrue()).thenReturn(Optional.of(createValidLicense()));

        LicenseStatusResponse result = service.validateLicense();

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo("VALID");
        assertThat(result.getRemainingDays()).isGreaterThan(0);
        assertThat(result.getMaxBranches()).isEqualTo(5);
        assertThat(result.getMaxWorkers()).isEqualTo(20);
    }

    @Test
    @DisplayName("validateLicense → expired license → EXPIRED status")
    void testValidateLicense_expired() {
        when(licenseRepository.findByIsActiveTrue()).thenReturn(Optional.of(createExpiredLicense()));

        LicenseStatusResponse result = service.validateLicense();

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo("EXPIRED");
        assertThat(result.getRemainingDays()).isEqualTo(0);
    }

    @Test
    @DisplayName("checkFeature → enabled feature → true")
    void testCheckFeature_enabled() {
        when(licenseRepository.findByIsActiveTrue()).thenReturn(Optional.of(createValidLicense()));

        boolean result = service.checkFeature("WU");

        assertThat(result).isTrue();
    }

    @Test
    @DisplayName("checkFeature → disabled feature → false")
    void testCheckFeature_disabled() {
        when(licenseRepository.findByIsActiveTrue()).thenReturn(Optional.of(createValidLicense()));

        boolean result = service.checkFeature("NONEXISTENT_MODULE");

        assertThat(result).isFalse();
    }

    @Test
    @DisplayName("getRemainingDays → valid license → positive days")
    void testGetRemainingDays() {
        when(licenseRepository.findByIsActiveTrue()).thenReturn(Optional.of(createValidLicense()));

        int result = service.getRemainingDays();

        assertThat(result).isGreaterThan(0);
        assertThat(result).isLessThanOrEqualTo(90);
    }

    @Test
    @DisplayName("validateLicense → no license → NO_LICENSE")
    void testValidateLicense_noLicense() {
        when(licenseRepository.findByIsActiveTrue()).thenReturn(Optional.empty());

        LicenseStatusResponse result = service.validateLicense();

        assertThat(result.getStatus()).isEqualTo("NO_LICENSE");
        assertThat(result.getRemainingDays()).isEqualTo(0);
        assertThat(result.getMaxBranches()).isEqualTo(0);
    }

    @Test
    @DisplayName("getRemainingDays → no license → 0")
    void testGetRemainingDays_noLicense() {
        when(licenseRepository.findByIsActiveTrue()).thenReturn(Optional.empty());

        int result = service.getRemainingDays();

        assertThat(result).isEqualTo(0);
    }

    @Test
    @DisplayName("checkFeature → no license → false")
    void testCheckFeature_noLicense() {
        when(licenseRepository.findByIsActiveTrue()).thenReturn(Optional.empty());

        boolean result = service.checkFeature("WU");

        assertThat(result).isFalse();
    }

    // PP-12 fix edge cases

    @Test
    @DisplayName("PP-12: checkFeature → JSON array szóközzel → helyes felismerés")
    void testCheckFeature_jsonWithSpaces() {
        License l = createValidLicense();
        l.setFeatures("[ \"WU\", \"AML\" ]");
        when(licenseRepository.findByIsActiveTrue()).thenReturn(Optional.of(l));

        assertThat(service.checkFeature("WU")).isTrue();
        assertThat(service.checkFeature("AML")).isTrue();
        assertThat(service.checkFeature("NONEXISTENT")).isFalse();
    }

    @Test
    @DisplayName("PP-12: checkFeature → kis/nagybetű érzéketlenség")
    void testCheckFeature_caseInsensitive() {
        License l = createValidLicense();
        l.setFeatures("[\"wu\",\"aml\"]");
        when(licenseRepository.findByIsActiveTrue()).thenReturn(Optional.of(l));

        assertThat(service.checkFeature("WU")).isTrue();
        assertThat(service.checkFeature("AML")).isTrue();
    }

    @Test
    @DisplayName("PP-12: checkFeature → null features → false")
    void testCheckFeature_nullFeatures() {
        License l = createValidLicense();
        l.setFeatures(null);
        when(licenseRepository.findByIsActiveTrue()).thenReturn(Optional.of(l));

        assertThat(service.checkFeature("WU")).isFalse();
    }

    @Test
    @DisplayName("PP-12: checkFeature → hibás JSON → fallback substring match")
    void testCheckFeature_malformedJsonFallback() {
        License l = createValidLicense();
        l.setFeatures("[invalid json but contains \"WU\"]");
        when(licenseRepository.findByIsActiveTrue()).thenReturn(Optional.of(l));

        assertThat(service.checkFeature("WU")).isTrue();
        assertThat(service.checkFeature("NOTHERE")).isFalse();
    }
}
