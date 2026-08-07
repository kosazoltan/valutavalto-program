package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.AmlService;
import hu.puzzleir.valuta.service.DiscountThresholdService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.concurrent.Callable;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.reset;

/**
 * FK-076: a PÉNZTÁRI tranzakció-folyamat által kötelezően hívott, mellékhatás nélküli
 * ellenőrző/számoló végpontok jogosultsági körét védi method-security szinten.
 *
 * <p>Regresszió, amit befagyaszt: az {@code AmlController} és a
 * {@code DiscountThresholdController} osztály-szintű köre csak
 * {@code SUPERVISOR/MANAGER/ADMIN} volt, miközben a {@code TransactionController} rögzítési
 * köre {@code CASHIER}-t is tartalmaz. A pénztáros így rögzíthetett volna tranzakciót, de a
 * folyamat kötelező AML-ellenőrzése 403-at adott; a kliens fail-closed ága ezt
 * „TRANZAKCIO BLOKKOLT — AML szabalysertes" üzenetre fordította, tehát éles pénztárban
 * MINDEN tranzakció blokkolt volt (prod nginx access.log, 2026-08-07).</p>
 *
 * <p>A könnyű method-security mintát követi (mint
 * {@code AverageRateReportControllerSecurityTest}): a {@code @PreAuthorize} a
 * controller-metódus hívásakor érvényesül — deny → AccessDeniedException, allow → a hívás
 * lefut. Nincs teljes web/JPA context, a service-ek mockoltak.</p>
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = PenztarTransactionFlowSecurityTest.TestConfig.class)
class PenztarTransactionFlowSecurityTest {

    private static final BigDecimal HUF = new BigDecimal("686000");

    @Autowired
    private AmlService amlService;

    @Autowired
    private DiscountThresholdService discountThresholdService;

    @Autowired
    private AmlController amlController;

    @Autowired
    private DiscountThresholdController discountThresholdController;

    @BeforeEach
    void setup() {
        reset(amlService, discountThresholdService);
    }

    /**
     * Igazolja, hogy a {@code @PreAuthorize} ÁTENGEDTE a hívást: NEM dob AccessDeniedException-t.
     * A biztonsági rétegen túli üzleti hiba elfogadható — az már bizonyítja, hogy a
     * jogosultság-ellenőrzés engedélyezett (a metódustörzs elkezdett futni).
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

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        AmlService amlService() {
            return mock(AmlService.class);
        }

        @Bean
        DiscountThresholdService discountThresholdService() {
            return mock(DiscountThresholdService.class);
        }

        @Bean
        AmlController amlController(AmlService svc) {
            return new AmlController(svc);
        }

        @Bean
        DiscountThresholdController discountThresholdController(DiscountThresholdService svc) {
            return new DiscountThresholdController(svc);
        }
    }

    // ----- ALLOW: a pénztári folyamat szerepkörei (a regresszió lényege) -----

    @Test
    @WithMockUser(roles = {"CASHIER"})
    @DisplayName("FK-076: legacy CASHIER → AML check-all-thresholds engedélyezett (a blokkolt tranzakció gyökéroka)")
    void amlCheckAllThresholds_allowed_cashier() {
        assertAuthorized(() -> amlController.checkAllThresholds("2", HUF, "GBP"));
    }

    @Test
    @WithMockUser(roles = {"PENZTAR"})
    @DisplayName("FK-076: kanonikus PENZTAR → AML check-all-thresholds engedélyezett")
    void amlCheckAllThresholds_allowed_penztar() {
        assertAuthorized(() -> amlController.checkAllThresholds("2", HUF, "GBP"));
    }

    @Test
    @WithMockUser(roles = {"CASHIER"})
    @DisplayName("FK-076: legacy CASHIER → discount-threshold apply engedélyezett")
    void discountApply_allowed_cashier() {
        assertAuthorized(() -> discountThresholdController.apply(HUF, BigDecimal.ZERO));
    }

    @Test
    @WithMockUser(roles = {"PENZTAR"})
    @DisplayName("FK-076: kanonikus PENZTAR → discount-threshold resolve engedélyezett")
    void discountResolve_allowed_penztar() {
        assertAuthorized(() -> discountThresholdController.resolve(HUF));
    }

    @Test
    @WithMockUser(roles = {"BELSO_ELLENOR"})
    @DisplayName("FK-076: BELSO_ELLENOR (pénztár-ellenőrzés) → AML check-all-thresholds engedélyezett")
    void amlCheckAllThresholds_allowed_belsoEllenor() {
        assertAuthorized(() -> amlController.checkAllThresholds("2", HUF, "GBP"));
    }

    @Test
    @WithMockUser(roles = {"BELSO_ELLENOR"})
    @DisplayName("FK-076: BELSO_ELLENOR → discount-threshold apply engedélyezett")
    void discountApply_allowed_belsoEllenor() {
        assertAuthorized(() -> discountThresholdController.apply(HUF, BigDecimal.ZERO));
    }

    // ----- ALLOW: legacy vezetői kör (regresszió-védelem, változatlan) -----

    @Test
    @WithMockUser(roles = {"MANAGER"})
    @DisplayName("FK-076: MANAGER hozzáférése változatlan (AML)")
    void amlCheckAllThresholds_allowed_manager() {
        assertAuthorized(() -> amlController.checkAllThresholds("2", HUF, "GBP"));
    }

    @Test
    @WithMockUser(roles = {"SUPERVISOR"})
    @DisplayName("FK-076: SUPERVISOR hozzáférése változatlan (discount)")
    void discountApply_allowed_supervisor() {
        assertAuthorized(() -> discountThresholdController.apply(HUF, BigDecimal.ZERO));
    }

    // ----- DENY: a bejelentő/audit végpontok SZÁNDÉKOSAN vezetői körben maradnak -----

    @Test
    @WithMockUser(roles = {"CASHIER"})
    @DisplayName("FK-076: CASHIER NEM listázhatja a függő AML bejelentéseket")
    void amlPending_denied_cashier() {
        assertThrows(AccessDeniedException.class, () -> amlController.getPendingReports());
    }

    @Test
    @WithMockUser(roles = {"CASHIER"})
    @DisplayName("FK-076: CASHIER NEM futtathat rolling-window compliance auditot")
    void amlRollingWindowAudit_denied_cashier() {
        assertThrows(AccessDeniedException.class,
                () -> amlController.getRollingWindowAudit(new BigDecimal("4500000")));
    }

    @Test
    @WithMockUser(roles = {"CASHIER"})
    @DisplayName("FK-076: CASHIER NEM kérheti le az ügyfél kockázati profilt")
    void amlCustomerRisk_denied_cashier() {
        assertThrows(AccessDeniedException.class, () -> amlController.getCustomerRiskProfile("2"));
    }

    @Test
    @WithMockUser(roles = {"CASHIER"})
    @DisplayName("FK-076: CASHIER NEM kérheti le a napi AML összesítőt")
    void amlSummary_denied_cashier() {
        assertThrows(AccessDeniedException.class,
                () -> amlController.getDailySummary(LocalDate.of(2026, 8, 7)));
    }

    @Test
    @WithMockUser(roles = {"CASHIER"})
    @DisplayName("FK-076: CASHIER NEM listázhatja a teljes kedvezmény-törzset")
    void discountListActive_denied_cashier() {
        assertThrows(AccessDeniedException.class, () -> discountThresholdController.listActive());
    }

    @Test
    @WithMockUser(roles = {"PENZTAR"})
    @DisplayName("FK-076: kanonikus PENZTAR sem listázhatja a teljes kedvezmény-törzset")
    void discountListActive_denied_penztar() {
        assertThrows(AccessDeniedException.class, () -> discountThresholdController.listActive());
    }
}
