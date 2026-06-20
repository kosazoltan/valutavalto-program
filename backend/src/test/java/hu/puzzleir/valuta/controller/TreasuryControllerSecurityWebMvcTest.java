package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.TreasuryDashboardService;
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

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;

/**
 * FK-037 (2026-06-20): a cegszintu treasury-osszesitok (TreasuryController, kizarolag read-only GET)
 * a kozponti ertektari vezetoi szerepkoroknek (FOERTEKTAR/UGYVEZETO) is olvashatok — korabban csak
 * MANAGER/ADMIN, igy a Foertektaros/Ugyvezeto 403-at kapott a sajat dashboardjan. Az ERTEKTAR
 * (egytelephelyes ertektaros) tovabbra is TILTOTT (cegszintu vezetoi adat nem az o hatasköre).
 *
 * <p>A @PreAuthorize-t a @EnableMethodSecurity AOP-proxy ervenyesiti a bean kozvetlen hivasakor is
 * (a @WithMockUser allitja be a SecurityContextet) — CustomerControlControllerSecurityWebMvcTest mintaja.</p>
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = TreasuryControllerSecurityWebMvcTest.TestConfig.class)
class TreasuryControllerSecurityWebMvcTest {

    @Autowired
    private TreasuryDashboardService treasuryDashboardService;

    @Autowired
    private TreasuryController treasuryController;

    @BeforeEach
    void setup() {
        reset(treasuryDashboardService);
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        TreasuryDashboardService treasuryDashboardService() {
            return mock(TreasuryDashboardService.class);
        }

        @Bean
        TreasuryController treasuryController(TreasuryDashboardService treasuryDashboardService) {
            return new TreasuryController(treasuryDashboardService);
        }
    }

    @Test
    @DisplayName("AuthZ: FOERTEKTAR ENGEDÉLYEZETT a cégszintű treasury dashboard olvasásra (FK-037)")
    @WithMockUser(roles = "FOERTEKTAR")
    void getDashboard_allowedForFoertektar() {
        treasuryController.getDashboard();
        verify(treasuryDashboardService).getCompanyWideSummary();
    }

    @Test
    @DisplayName("AuthZ: UGYVEZETO ENGEDÉLYEZETT a cégszintű treasury dashboard olvasásra (FK-037)")
    @WithMockUser(roles = "UGYVEZETO")
    void getDashboard_allowedForUgyvezeto() {
        treasuryController.getDashboard();
        verify(treasuryDashboardService).getCompanyWideSummary();
    }

    @Test
    @DisplayName("AuthZ: MANAGER ENGEDÉLYEZETT marad (változatlan)")
    @WithMockUser(roles = "MANAGER")
    void getDashboard_allowedForManager() {
        treasuryController.getDashboard();
        verify(treasuryDashboardService).getCompanyWideSummary();
    }

    @Test
    @DisplayName("AuthZ: ERTEKTAR TILTOTT a cégszintű treasury összesítőkre (egytelephelyes scope)")
    @WithMockUser(roles = "ERTEKTAR")
    void getDashboard_forbiddenForErtektar() {
        assertThrows(AccessDeniedException.class, () -> treasuryController.getDashboard());
        verify(treasuryDashboardService, never()).getCompanyWideSummary();
    }

    @Test
    @DisplayName("AuthZ: ERTEKTAR TILTOTT a fiók-összehasonlításra is")
    @WithMockUser(roles = "ERTEKTAR")
    void getBranchComparison_forbiddenForErtektar() {
        assertThrows(AccessDeniedException.class, () -> treasuryController.getBranchComparison());
        verify(treasuryDashboardService, never()).getBranchComparison();
    }

    @Test
    @DisplayName("AuthZ: CASHIER TILTOTT a cégszintű treasury összesítőkre")
    @WithMockUser(roles = "CASHIER")
    void getDashboard_forbiddenForCashier() {
        assertThrows(AccessDeniedException.class, () -> treasuryController.getDashboard());
        verify(treasuryDashboardService, never()).getCompanyWideSummary();
    }
}
