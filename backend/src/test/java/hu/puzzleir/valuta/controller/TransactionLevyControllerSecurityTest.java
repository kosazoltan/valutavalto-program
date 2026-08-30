package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.levy.TransactionLevyRateCreateRequest;
import hu.puzzleir.valuta.dto.levy.TransactionLevyRateDto;
import hu.puzzleir.valuta.service.TransactionLevyRateService;
import hu.puzzleir.valuta.service.TransactionLevyReportService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.security.test.context.support.WithAnonymousUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.Callable;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * FK-099 D-sorozat — method-security a két controlleren (WU1 RED → WU6 GREEN).
 *
 * <p>D10: az osztály-szintű {@code @PreAuthorize("isAuthenticated()")} a
 * controlleren van, a SZEREP-döntés a service-ben (hogy a megtagadás
 * ACCESS_DENIED audit-sort kapjon). Ezért a D1/D3 esetekben a mockolt service
 * dobja az {@code AccessDeniedException}-t — a teszt azt bizonyítja, hogy a
 * {@code @PreAuthorize} átengedi a hívást a service-ig.</p>
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = TransactionLevyControllerSecurityTest.TestConfig.class)
class TransactionLevyControllerSecurityTest {

    private static final LocalDate FROM = LocalDate.of(2026, 8, 1);
    private static final LocalDate TO = LocalDate.of(2026, 8, 31);

    @Autowired
    private TransactionLevyReportService reportService;

    @Autowired
    private TransactionLevyRateService rateService;

    @Autowired
    private TransactionLevyReportController reportController;

    @Autowired
    private TransactionLevyRateController rateController;

    /**
     * A Spring-kontextus cache-elt a tesztosztályon belül — a mock bean-eken
     * szivárogna a stub az esetek között (AverageRateReportControllerSecurityTest
     * minta): minden eset tiszta mock-kal induljon.
     */
    @org.junit.jupiter.api.BeforeEach
    void resetMocks() {
        org.mockito.Mockito.reset(reportService, rateService);
    }

    /**
     * Igazolja, hogy a {@code @PreAuthorize} ÁTENGEDTE a hívást: NEM dob
     * AccessDeniedException-t a security-réteg (a mockolt service visszatérése
     * vagy üzleti kivétele irreleváns).
     */
    private static void assertAuthorized(Callable<?> call) {
        try {
            call.call();
        } catch (AccessDeniedException denied) {
            throw new AssertionError("A @PreAuthorize tévesen elutasította a jogosult szerepkört", denied);
        } catch (Exception businessError) {
            // OK: a security átengedett.
        }
    }

    private static TransactionLevyRateCreateRequest createRequest() {
        return TransactionLevyRateCreateRequest.builder()
                .effectiveFrom(LocalDate.now().plusDays(1))
                .baseRatePercent(new BigDecimal("0.500"))
                .baseRateCapHuf(new BigDecimal("25000.00"))
                .supplementRatePercent(new BigDecimal("0.500"))
                .supplementRateCapHuf(new BigDecimal("25000.00"))
                .conversionSingleSideFlag(Boolean.TRUE)
                .build();
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        TransactionLevyReportService transactionLevyReportService() {
            return mock(TransactionLevyReportService.class);
        }

        @Bean
        TransactionLevyRateService transactionLevyRateService() {
            return mock(TransactionLevyRateService.class);
        }

        @Bean
        TransactionLevyReportController transactionLevyReportController(
                TransactionLevyReportService reportService) {
            return new TransactionLevyReportController(reportService);
        }

        @Bean
        TransactionLevyRateController transactionLevyRateController(
                TransactionLevyRateService rateService) {
            return new TransactionLevyRateController(rateService);
        }
    }

    // ============================ D1–D2: riport RBAC ============================

    @Test
    @WithMockUser(roles = {"PENZTAR"})
    @DisplayName("D1/FR-17: PENZTAR → a hívás eljut a service-ig, annak szerep-ellenőrzése dob")
    void d1_penztarReachesServiceRoleCheck() {
        when(reportService.getReport(any(), any(), any()))
                .thenThrow(new AccessDeniedException("VV-AUTH-006: nincs jogosultsága."));

        assertThrows(AccessDeniedException.class,
                () -> reportController.report(null, FROM, TO));
    }

    @ParameterizedTest(name = "engedélyezett szerep: {0}")
    @ValueSource(strings = {"FOERTEKTAR", "UGYVEZETO", "ADMIN", "BELSO_ELLENOR", "IRODAVEZETO"})
    @WithMockUser(roles = {})
    void d2_allReportRolesPassTheWebGate(String role) {
        // A @WithMockUser(roles = {}) nem használható paraméterezett role-lal, ezért
        // a SecurityContextet kézzel állítjuk be az adott szerepre.
        org.springframework.security.authentication.UsernamePasswordAuthenticationToken token =
                new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(
                        "WK099", "n/a",
                        List.of(new org.springframework.security.core.authority.SimpleGrantedAuthority(
                                "ROLE_" + role)));
        org.springframework.security.core.context.SecurityContextHolder.getContext()
                .setAuthentication(token);
        try {
            assertAuthorized(() -> reportController.report(null, FROM, TO));
        } finally {
            org.springframework.security.core.context.SecurityContextHolder.clearContext();
        }
    }

    // ============================ D3–D4: ráta-írás RBAC ============================

    @Test
    @WithMockUser(roles = {"IRODAVEZETO"})
    @DisplayName("D3/FR-18: IRODAVEZETO POST → a service szerep-ellenőrzése dob (VV-AUTH-007)")
    void d3_irodavezetoPostDeniedByService() {
        when(rateService.create(any(TransactionLevyRateCreateRequest.class)))
                .thenThrow(new AccessDeniedException("VV-AUTH-007: nincs jogosultsága."));

        assertThrows(AccessDeniedException.class, () -> rateController.create(createRequest()));
    }

    @Test
    @WithMockUser(roles = {"BELSO_ELLENOR"})
    @DisplayName("D3/FR-18: BELSO_ELLENOR POST → a service szerep-ellenőrzése dob (VV-AUTH-007)")
    void d3_belsoEllenorPostDeniedByService() {
        when(rateService.create(any(TransactionLevyRateCreateRequest.class)))
                .thenThrow(new AccessDeniedException("VV-AUTH-007: nincs jogosultsága."));

        assertThrows(AccessDeniedException.class, () -> rateController.create(createRequest()));
    }

    @Test
    @WithMockUser(roles = {"FOERTEKTAR"})
    @DisplayName("D4/FR-18: FOERTEKTAR POST → átengedve")
    void d4_foertektarPostAllowed() {
        when(rateService.create(any(TransactionLevyRateCreateRequest.class)))
                .thenReturn(TransactionLevyRateDto.builder().build());

        assertAuthorized(() -> rateController.create(createRequest()));
    }

    // ============================ D5: hitelesítés ============================

    @Test
    @WithAnonymousUser
    @DisplayName("D5: anonim hívó → a riport osztály-szintű isAuthenticated() elutasít")
    void d5_anonymousReportRejected() {
        assertThrows(AccessDeniedException.class,
                () -> reportController.report(null, FROM, TO));
    }

    @Test
    @WithAnonymousUser
    @DisplayName("D5: anonim hívó → a ráta osztály-szintű isAuthenticated() elutasít")
    void d5_anonymousRatesRejected() {
        assertThrows(AccessDeniedException.class, () -> rateController.list());
        assertThrows(AccessDeniedException.class, () -> rateController.create(createRequest()));
    }

    // ============================ D6: FR-1 — nincs mutáló metódus ============================

    @Test
    @DisplayName("D6/FR-1: a ráta-controlleren nincs PUT/PATCH/DELETE; pontosan egy GET és egy POST")
    void d6_rateControllerHasNoMutatingMapping() {
        Method[] methods = TransactionLevyRateController.class.getDeclaredMethods();

        for (Method method : methods) {
            assertThat(method.getAnnotation(PutMapping.class))
                    .as("PUT mapping tilos: %s", method.getName()).isNull();
            assertThat(method.getAnnotation(PatchMapping.class))
                    .as("PATCH mapping tilos: %s", method.getName()).isNull();
            assertThat(method.getAnnotation(DeleteMapping.class))
                    .as("DELETE mapping tilos: %s", method.getName()).isNull();
            RequestMapping requestMapping = method.getAnnotation(RequestMapping.class);
            if (requestMapping != null) {
                assertThat(Arrays.asList(requestMapping.method()))
                        .as("mutáló RequestMapping tilos: %s", method.getName())
                        .doesNotContain(
                                RequestMethod.PUT, RequestMethod.PATCH, RequestMethod.DELETE);
            }
        }

        long getCount = Arrays.stream(methods)
                .filter(m -> m.getAnnotation(GetMapping.class) != null).count();
        long postCount = Arrays.stream(methods)
                .filter(m -> m.getAnnotation(PostMapping.class) != null).count();
        assertThat(getCount).as("pontosan egy @GetMapping").isEqualTo(1);
        assertThat(postCount).as("pontosan egy @PostMapping").isEqualTo(1);
    }
}
