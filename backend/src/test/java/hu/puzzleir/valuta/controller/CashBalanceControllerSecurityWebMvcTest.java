package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.mapper.CashBalanceMapper;
import hu.puzzleir.valuta.service.AccessScopeService;
import hu.puzzleir.valuta.service.CashBalanceService;
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
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;

/**
 * FK-037 (2026-06-20): a cegszintu cash-balance osszesitok (getCompanyTotals, getCompanyCashPosition)
 * a kozponti vezetoi szerepkoroknek (FOERTEKTAR/UGYVEZETO) is olvashatok lettek — osszhangban a mar
 * korabban is FOERTEKTAR/UGYVEZETO/ERTEKTAR szamara nyitott getCompanyBalances-szel. Az ERTEKTAR a
 * cegszintu OSSZESITOT/POZICIOT tovabbra sem latja (a sajat egyenleg-listat (getCompanyBalances) igen).
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = CashBalanceControllerSecurityWebMvcTest.TestConfig.class)
class CashBalanceControllerSecurityWebMvcTest {

    @Autowired
    private CashBalanceService cashBalanceService;

    @Autowired
    private CashBalanceController cashBalanceController;

    @BeforeEach
    void setup() {
        reset(cashBalanceService);
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        CashBalanceService cashBalanceService() {
            return mock(CashBalanceService.class);
        }

        @Bean
        CashBalanceController cashBalanceController(CashBalanceService cashBalanceService) {
            // FK-075 FR-1: IdempotencyGuard-injekció eltávolítva (adjust végpont 410 Gone).
            return new CashBalanceController(
                    cashBalanceService,
                    mock(CashBalanceMapper.class),
                    mock(AccessScopeService.class));
        }
    }

    @Test
    @DisplayName("AuthZ: FOERTEKTAR ENGEDÉLYEZETT a cégszintű valutánkénti összesítőre (FK-037)")
    @WithMockUser(roles = "FOERTEKTAR")
    void getCompanyTotals_allowedForFoertektar() {
        cashBalanceController.getCompanyTotals();
        verify(cashBalanceService).getCompanyTotals();
    }

    @Test
    @DisplayName("AuthZ: UGYVEZETO ENGEDÉLYEZETT a cégszintű pillanatállásra (FK-037)")
    @WithMockUser(roles = "UGYVEZETO")
    void getCompanyCashPosition_allowedForUgyvezeto() {
        cashBalanceController.getCompanyCashPosition();
        verify(cashBalanceService).getCompanyCashPosition();
    }

    @Test
    @DisplayName("AuthZ: MANAGER ENGEDÉLYEZETT marad (változatlan)")
    @WithMockUser(roles = "MANAGER")
    void getCompanyTotals_allowedForManager() {
        cashBalanceController.getCompanyTotals();
        verify(cashBalanceService).getCompanyTotals();
    }

    @Test
    @DisplayName("AuthZ: ERTEKTAR TILTOTT a cégszintű összesítőre (csak a saját egyenleg-listát látja)")
    @WithMockUser(roles = "ERTEKTAR")
    void getCompanyTotals_forbiddenForErtektar() {
        assertThrows(AccessDeniedException.class, () -> cashBalanceController.getCompanyTotals());
        verify(cashBalanceService, never()).getCompanyTotals();
    }

    @Test
    @DisplayName("AuthZ: ERTEKTAR TILTOTT a cégszintű pillanatállásra")
    @WithMockUser(roles = "ERTEKTAR")
    void getCompanyCashPosition_forbiddenForErtektar() {
        assertThrows(AccessDeniedException.class, () -> cashBalanceController.getCompanyCashPosition());
        verify(cashBalanceService, never()).getCompanyCashPosition();
    }
}
