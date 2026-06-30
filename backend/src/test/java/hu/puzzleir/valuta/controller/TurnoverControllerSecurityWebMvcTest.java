package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.turnover.TurnoverReportDto;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.TurnoverService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.MockedStatic;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.time.LocalDate;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-045 FR-10: a Napi forgalom végpontok @PreAuthorize RBAC regressziós hálója. A read-only
 * forgalom CSAK a kanonikus magyar olvasó szerepköröknek (FOERTEKTAR/UGYVEZETO/BELSO_ELLENOR/
 * PENZUGYI_VEZETO) elérhető; a régi angol CASHIER szerepkör NEM (a korábbi elavult RBAC regresszió).
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = TurnoverControllerSecurityWebMvcTest.TestConfig.class)
class TurnoverControllerSecurityWebMvcTest {

    @Autowired
    private TurnoverService turnoverService;

    @Autowired
    private TurnoverController controller;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final LocalDate FROM = LocalDate.of(2026, 6, 1);
    private static final LocalDate TO = LocalDate.of(2026, 6, 30);

    @BeforeEach
    void setup() {
        reset(turnoverService);
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        TurnoverService turnoverService() {
            return org.mockito.Mockito.mock(TurnoverService.class);
        }

        @Bean
        TurnoverController turnoverController(TurnoverService service) {
            return new TurnoverController(service);
        }
    }

    @Test
    @DisplayName("FR-10 AuthZ: FOERTEKTAR ENGEDÉLYEZETT a /daily-re (200)")
    @WithMockUser(roles = "FOERTEKTAR")
    void daily_foertektar_allowed() {
        when(turnoverService.getDailyTurnover(eq(BRANCH_ID), any()))
            .thenReturn(TurnoverReportDto.builder().build());
        controller.daily(BRANCH_ID, TO);
        verify(turnoverService).getDailyTurnover(eq(BRANCH_ID), any());
    }

    @Test
    @DisplayName("FR-10 AuthZ regresszió: régi CASHIER szerepkör TILTOTT a /daily-re (403)")
    @WithMockUser(roles = "CASHIER")
    void daily_old_cashier_role_forbidden() {
        assertThrows(AccessDeniedException.class, () -> controller.daily(BRANCH_ID, TO));
        verify(turnoverService, never()).getDailyTurnover(any(), any());
    }

    @Test
    @DisplayName("FR-9 AuthZ: FOERTEKTAR ENGEDÉLYEZETT a /territory-ra (200)")
    @WithMockUser(roles = "FOERTEKTAR")
    void territory_foertektar_allowed() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(turnoverService.getVaultTerritoryTurnover(eq(COMPANY_ID), eq(5), any(), any()))
                .thenReturn(TurnoverReportDto.builder().build());
            controller.territory(5, FROM, TO);
            verify(turnoverService).getVaultTerritoryTurnover(eq(COMPANY_ID), eq(5), any(), any());
        }
    }

    @Test
    @DisplayName("FR-9 AuthZ: CASHIER TILTOTT a /territory-ra (403)")
    @WithMockUser(roles = "CASHIER")
    void territory_cashier_forbidden() {
        assertThrows(AccessDeniedException.class, () -> controller.territory(5, FROM, TO));
        verify(turnoverService, never()).getVaultTerritoryTurnover(any(), any(), any(), any());
    }
}
