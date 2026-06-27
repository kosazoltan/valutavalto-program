package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.competitor.CompetitorRateEntryDto;
import hu.puzzleir.valuta.service.CompetitorRateService;
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
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;

/**
 * FK-041/II — a versenytárs-árfolyam BEVITEL @PreAuthorize regressziós hálója. Az élő repró egyszeri
 * volt; ez köti le automatikusan, hogy a végpontok CSAK az ARFOLYAM_NEZO / FOERTEKTAR / UGYVEZETO / ADMIN
 * szerepkörnek elérhetők, a pénztáros (CASHIER) NEM írhat versenytárs-árfolyamot.
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = CompetitorRateControllerSecurityWebMvcTest.TestConfig.class)
class CompetitorRateControllerSecurityWebMvcTest {

    @Autowired
    private CompetitorRateService competitorRateService;

    @Autowired
    private CompetitorRateController controller;

    @BeforeEach
    void setup() {
        reset(competitorRateService);
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        CompetitorRateService competitorRateService() {
            return mock(CompetitorRateService.class);
        }

        @Bean
        CompetitorRateController competitorRateController(CompetitorRateService service) {
            return new CompetitorRateController(service);
        }
    }

    @Test
    @DisplayName("AuthZ: ARFOLYAM_NEZO ENGEDÉLYEZETT a versenytárs-bevitel bootstrapra")
    @WithMockUser(roles = "ARFOLYAM_NEZO")
    void bootstrap_allowedForArfolyamNezo() {
        controller.getBootstrap();
        verify(competitorRateService).getBootstrap();
    }

    @Test
    @DisplayName("AuthZ: FOERTEKTAR ENGEDÉLYEZETT")
    @WithMockUser(roles = "FOERTEKTAR")
    void bootstrap_allowedForFoertektar() {
        controller.getBootstrap();
        verify(competitorRateService).getBootstrap();
    }

    @Test
    @DisplayName("AuthZ: CASHIER (pénztáros) TILTOTT a bootstrapra")
    @WithMockUser(roles = "CASHIER")
    void bootstrap_forbiddenForCashier() {
        assertThrows(AccessDeniedException.class, () -> controller.getBootstrap());
        verify(competitorRateService, never()).getBootstrap();
    }

    @Test
    @DisplayName("AuthZ: CASHIER (pénztáros) TILTOTT a versenytárs-árfolyam beküldésre")
    @WithMockUser(roles = "CASHIER")
    void submit_forbiddenForCashier() {
        assertThrows(AccessDeniedException.class, () -> controller.submit(new CompetitorRateEntryDto()));
        verify(competitorRateService, never()).submit(any());
    }
}
