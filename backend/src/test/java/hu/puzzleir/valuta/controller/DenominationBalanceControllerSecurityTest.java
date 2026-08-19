package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.service.DenominationBalanceService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-077 FR-1 — a DenominationBalanceController RBAC-bovitese, KETFELE kezelessel:
 *
 * <ul>
 *   <li>3 OLVASO vegpont (lista, valuta szerinti lista, osszesito): ERTEKTAR, FOERTEKTAR
 *       ES UGYVEZETO is hozzafer — a testver-kontroller (DenominationController) mintaja.</li>
 *   <li>2 IRO vegpont (PUT egyedi, POST batch): kizarolag ERTEKTAR + FOERTEKTAR —
 *       UGYVEZETO NELKUL, mert a §3 RBAC-matrix az Ugyvezetonel "letrehoz: –"-t ir.</li>
 * </ul>
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = DenominationBalanceControllerSecurityTest.TestConfig.class)
class DenominationBalanceControllerSecurityTest {

    private static final String READ_AUTH =
            "hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')";
    private static final String WRITE_AUTH =
            "hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', 'ERTEKTAR', 'FOERTEKTAR')";

    private static final UUID CASH_DESK_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    // FK-078 FR-4: a self-check olvaso vegpont — ugyanaz a bovitett olvaso RBAC vedi.
    private static final List<String> READ_METHODS =
            List.of("getCashDeskDenominations", "getCashDeskDenominationsByCurrency", "calculateTotal",
                    "selfCheck");
    private static final List<String> WRITE_METHODS = List.of("updateQuantity", "batchUpdate");

    @Autowired private DenominationBalanceController controller;
    @Autowired private DenominationBalanceService service;

    @BeforeEach
    void setUp() {
        reset(service);
    }

    @Test
    void readEndpointsCarryTheExtendedRoleList() {
        for (String name : READ_METHODS) {
            PreAuthorize annotation = handler(name).getAnnotation(PreAuthorize.class);
            assertThat(annotation).as(name + " must be protected").isNotNull();
            assertThat(annotation.value()).as(name + " read RBAC").isEqualTo(READ_AUTH);
        }
    }

    @Test
    void writeEndpointsExcludeUgyvezeto() {
        for (String name : WRITE_METHODS) {
            PreAuthorize annotation = handler(name).getAnnotation(PreAuthorize.class);
            assertThat(annotation).as(name + " must be protected").isNotNull();
            assertThat(annotation.value()).as(name + " write RBAC").isEqualTo(WRITE_AUTH);
            assertThat(annotation.value())
                    .as(name + " must NOT grant write access to UGYVEZETO (§3 RBAC matrix)")
                    .doesNotContain("UGYVEZETO");
        }
    }

    @Test
    @WithMockUser(roles = "FOERTEKTAR")
    void read_allowsFoertektar() {
        when(service.getCashDeskDenominations(CASH_DESK_ID)).thenReturn(List.of());

        controller.getCashDeskDenominations(CASH_DESK_ID);

        verify(service).getCashDeskDenominations(CASH_DESK_ID);
    }

    @Test
    @WithMockUser(roles = "ERTEKTAR")
    void read_allowsErtektar() {
        when(service.getCashDeskDenominationsByCurrency(CASH_DESK_ID, 1L, null)).thenReturn(List.of());

        controller.getCashDeskDenominationsByCurrency(CASH_DESK_ID, 1L, null);

        verify(service).getCashDeskDenominationsByCurrency(CASH_DESK_ID, 1L, null);
    }

    @Test
    @WithMockUser(roles = "UGYVEZETO")
    void read_allowsUgyvezetoOnTotal() {
        when(service.calculateTotal(CASH_DESK_ID, 1L)).thenReturn(BigDecimal.ZERO);

        controller.calculateTotal(CASH_DESK_ID, 1L);

        verify(service).calculateTotal(CASH_DESK_ID, 1L);
    }

    @Test
    @WithMockUser(roles = "ERTEKTAR")
    void write_allowsErtektarOnBatch() {
        when(service.batchUpdate(any(), any(), any())).thenReturn(List.of());

        controller.batchUpdate(CASH_DESK_ID, List.of(), DenominationCategory.EVENING);

        verify(service).batchUpdate(any(), any(), any());
    }

    @Test
    @WithMockUser(roles = "UGYVEZETO")
    void write_deniesUgyvezetoOnUpdateQuantity() {
        assertThrows(
                AccessDeniedException.class,
                () -> controller.updateQuantity(CASH_DESK_ID, 1L, 5, DenominationCategory.EVENING));

        verify(service, never()).updateQuantity(any(), anyLong(), anyInt(), any());
    }

    @Test
    @WithMockUser(roles = "UGYVEZETO")
    void write_deniesUgyvezetoOnBatch() {
        assertThrows(AccessDeniedException.class,
                () -> controller.batchUpdate(CASH_DESK_ID, List.of(), DenominationCategory.EVENING));

        verify(service, never()).batchUpdate(any(), any(), any());
    }

    /** FK-077 FR-4 regresszio: a ma is mukodo CASHIER szerepkor valtozatlanul ir. */
    @Test
    @WithMockUser(roles = "CASHIER")
    void write_stillAllowsCashier() {
        when(service.batchUpdate(any(), any(), any())).thenReturn(List.of());

        controller.batchUpdate(CASH_DESK_ID, List.of(), DenominationCategory.EVENING);

        verify(service).batchUpdate(any(), any(), any());
    }

    private static Method handler(String name) {
        for (Method method : DenominationBalanceController.class.getDeclaredMethods()) {
            if (method.getName().equals(name)) {
                return method;
            }
        }
        throw new AssertionError("Handler nem talalhato: " + name);
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        DenominationBalanceService denominationBalanceService() {
            return mock(DenominationBalanceService.class);
        }

        @Bean
        DenominationBalanceController denominationBalanceController(DenominationBalanceService service) {
            return new DenominationBalanceController(service);
        }
    }
}
