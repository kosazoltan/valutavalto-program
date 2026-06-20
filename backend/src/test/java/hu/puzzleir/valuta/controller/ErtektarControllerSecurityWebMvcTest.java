package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.BranchMonitoringService;
import hu.puzzleir.valuta.service.ConsolidatedReportService;
import hu.puzzleir.valuta.service.MaterialReceiptService;
import hu.puzzleir.valuta.service.StockCorrectionService;
import hu.puzzleir.valuta.service.VaultBankTransactionService;
import hu.puzzleir.valuta.service.VaultCollectionService;
import hu.puzzleir.valuta.service.VaultDistributionService;
import hu.puzzleir.valuta.service.VaultTransferService;
import hu.puzzleir.valuta.util.IdempotencyGuard;
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
 * FK-037 (2026-06-20): az ertektari READ (listazo GET) vegpontok a kozponti vezetoi szerepkoroknek
 * (FOERTEKTAR/UGYVEZETO) is olvashatok lettek (READ_ROLES, method-level @PreAuthorize), de az IRAS/
 * letrehozas/jovahagyas TOVABBRA is csak SUPERVISOR/MANAGER/ADMIN (osztaly-szintu default). Ez a teszt
 * verifikalja, hogy (a) a read megnyilt FOERTEKTAR-nak, (b) az ERTEKTAR tovabbra is tiltott, (c) a
 * write NEM nyilt meg FOERTEKTAR-nak (read-only grant), (d) a write a SUPERVISOR szamara valtozatlan.
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = ErtektarControllerSecurityWebMvcTest.TestConfig.class)
class ErtektarControllerSecurityWebMvcTest {

    @Autowired
    private VaultCollectionService vaultCollectionService;

    @Autowired
    private ErtektarController ertektarController;

    @BeforeEach
    void setup() {
        reset(vaultCollectionService);
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        VaultCollectionService vaultCollectionService() {
            return mock(VaultCollectionService.class);
        }

        @Bean
        ErtektarController ertektarController(VaultCollectionService vaultCollectionService) {
            return new ErtektarController(
                    vaultCollectionService,
                    mock(VaultDistributionService.class),
                    mock(VaultBankTransactionService.class),
                    mock(VaultTransferService.class),
                    mock(MaterialReceiptService.class),
                    mock(StockCorrectionService.class),
                    mock(ConsolidatedReportService.class),
                    mock(BranchMonitoringService.class),
                    mock(IdempotencyGuard.class));
        }
    }

    // === READ (listázás) — FK-037 megnyitva FOERTEKTAR/UGYVEZETO-nek ===

    @Test
    @DisplayName("AuthZ: FOERTEKTAR ENGEDÉLYEZETT az értéktári begyűjtés-lista (read) lekérdezésre (FK-037)")
    @WithMockUser(roles = "FOERTEKTAR")
    void getCollections_allowedForFoertektar() {
        ertektarController.getCollections();
        verify(vaultCollectionService).getCollections();
    }

    @Test
    @DisplayName("AuthZ: UGYVEZETO ENGEDÉLYEZETT az értéktári begyűjtés-lista (read) lekérdezésre (FK-037)")
    @WithMockUser(roles = "UGYVEZETO")
    void getCollections_allowedForUgyvezeto() {
        ertektarController.getCollections();
        verify(vaultCollectionService).getCollections();
    }

    @Test
    @DisplayName("AuthZ: SUPERVISOR ENGEDÉLYEZETT marad a read-re (változatlan)")
    @WithMockUser(roles = "SUPERVISOR")
    void getCollections_allowedForSupervisor() {
        ertektarController.getCollections();
        verify(vaultCollectionService).getCollections();
    }

    @Test
    @DisplayName("AuthZ: ERTEKTAR TILTOTT az értéktári begyűjtés-lista lekérdezésre")
    @WithMockUser(roles = "ERTEKTAR")
    void getCollections_forbiddenForErtektar() {
        assertThrows(AccessDeniedException.class, () -> ertektarController.getCollections());
        verify(vaultCollectionService, never()).getCollections();
    }

    // === WRITE (létrehozás) — read-only grant: FOERTEKTAR NEM kap írást ===

    @Test
    @DisplayName("AuthZ: FOERTEKTAR TILTOTT az értéktári begyűjtés LÉTREHOZÁSÁRA (read-only grant)")
    @WithMockUser(roles = "FOERTEKTAR")
    void createCollection_forbiddenForFoertektar() {
        assertThrows(AccessDeniedException.class, () -> ertektarController.createCollection(null));
        verify(vaultCollectionService, never()).createCollection(null);
    }

    @Test
    @DisplayName("AuthZ: SUPERVISOR ENGEDÉLYEZETT a begyűjtés létrehozására (változatlan)")
    @WithMockUser(roles = "SUPERVISOR")
    void createCollection_allowedForSupervisor() {
        ertektarController.createCollection(null);
        verify(vaultCollectionService).createCollection(null);
    }
}
