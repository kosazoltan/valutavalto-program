package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.CompanyAdminService;
import hu.puzzleir.valuta.service.CompanyVersionService;
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

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;

/**
 * FK-043 (2026-06-27): a Pénztár Törzs Adatbázis lista-nézet "ADMIN STAT" oszlopát betöltő
 * {@code GET /api/v1/admin/branches} végpont metódus-szintű {@code @PreAuthorize}-zal megnyílt
 * FOERTEKTAR és UGYVEZETO szerepkörnek is (dolgozószám + szinkron állapot felügyeleti adat).
 *
 * A teszt verifikálja, hogy (a) a stat-végpont engedélyezett ADMIN/FOERTEKTAR/UGYVEZETO-nek,
 * (b) ERTEKTAR/CASHIER számára továbbra is tiltott (deny-by-default), és (c) a controller
 * TÖBBI végpontja (osztály-szintű {@code hasRole('ADMIN')}) NEM nyílt meg FOERTEKTAR-nak.
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = CompanyAdminControllerSecurityWebMvcTest.TestConfig.class)
class CompanyAdminControllerSecurityWebMvcTest {

    @Autowired
    private CompanyAdminService companyAdminService;

    @Autowired
    private CompanyAdminController companyAdminController;

    @BeforeEach
    void setup() {
        reset(companyAdminService);
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        CompanyAdminService companyAdminService() {
            return mock(CompanyAdminService.class);
        }

        @Bean
        CompanyVersionService companyVersionService() {
            return mock(CompanyVersionService.class);
        }

        @Bean
        CompanyAdminController companyAdminController(
                CompanyAdminService companyAdminService,
                CompanyVersionService companyVersionService) {
            return new CompanyAdminController(companyAdminService, companyVersionService);
        }
    }

    // === stat-végpont (GET /admin/branches) — FK-043 megnyitva ===

    @Test
    @DisplayName("AuthZ: ADMIN ENGEDÉLYEZETT az admin stat (branches) lekérdezésre (regresszió)")
    @WithMockUser(roles = "ADMIN")
    void getAllBranchesWithStats_allowedForAdmin() {
        companyAdminController.getAllBranchesWithStats();
        verify(companyAdminService).getAllBranchesWithStats();
    }

    @Test
    @DisplayName("AuthZ: FOERTEKTAR ENGEDÉLYEZETT az admin stat lekérdezésre (FK-043)")
    @WithMockUser(roles = "FOERTEKTAR")
    void getAllBranchesWithStats_allowedForFoertektar() {
        companyAdminController.getAllBranchesWithStats();
        verify(companyAdminService).getAllBranchesWithStats();
    }

    @Test
    @DisplayName("AuthZ: UGYVEZETO ENGEDÉLYEZETT az admin stat lekérdezésre (FK-043)")
    @WithMockUser(roles = "UGYVEZETO")
    void getAllBranchesWithStats_allowedForUgyvezeto() {
        companyAdminController.getAllBranchesWithStats();
        verify(companyAdminService).getAllBranchesWithStats();
    }

    @Test
    @DisplayName("AuthZ: ERTEKTAR TILTOTT az admin stat lekérdezésre (deny-by-default)")
    @WithMockUser(roles = "ERTEKTAR")
    void getAllBranchesWithStats_forbiddenForErtektar() {
        assertThrows(AccessDeniedException.class, () -> companyAdminController.getAllBranchesWithStats());
        verify(companyAdminService, never()).getAllBranchesWithStats();
    }

    @Test
    @DisplayName("AuthZ: CASHIER TILTOTT az admin stat lekérdezésre (deny-by-default)")
    @WithMockUser(roles = "CASHIER")
    void getAllBranchesWithStats_forbiddenForCashier() {
        assertThrows(AccessDeniedException.class, () -> companyAdminController.getAllBranchesWithStats());
        verify(companyAdminService, never()).getAllBranchesWithStats();
    }

    // === a controller TÖBBI végpontja NEM nyílt meg (osztály-szintű ADMIN-only marad) ===

    @Test
    @DisplayName("AuthZ: FOERTEKTAR TILTOTT a cég-részletek lekérdezésére (osztály-szintű ADMIN-only változatlan)")
    @WithMockUser(roles = "FOERTEKTAR")
    void getCompanyDetails_forbiddenForFoertektar() {
        UUID id = UUID.randomUUID();
        assertThrows(AccessDeniedException.class, () -> companyAdminController.getCompanyDetails(id));
        verify(companyAdminService, never()).getCompanyDetails(id);
    }

    @Test
    @DisplayName("AuthZ: FOERTEKTAR TILTOTT az iroda-frissítésre (osztály-szintű ADMIN-only változatlan)")
    @WithMockUser(roles = "FOERTEKTAR")
    void updateBranch_forbiddenForFoertektar() {
        UUID id = UUID.randomUUID();
        assertThrows(AccessDeniedException.class, () -> companyAdminController.updateBranch(id, null));
        verify(companyAdminService, never()).updateBranch(id, null);
    }
}
