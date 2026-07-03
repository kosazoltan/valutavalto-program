package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.inventory.ReceiveMovementDto;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.AccessScopeService;
import hu.puzzleir.valuta.service.BranchService;
import hu.puzzleir.valuta.service.InventoryService;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.core.Authentication;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.anyLong;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;

/**
 * FK-xxx (2026-07-03): inventory status/history endpointok ERTEKTAR RBAC-regressziói.
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = InventoryControllerSecurityWebMvcTest.TestConfig.class)
class InventoryControllerSecurityWebMvcTest {

    @Autowired
    private InventoryService inventoryService;

    @Autowired
    private InventoryController controller;

    @BeforeEach
    void setup() {
        reset(inventoryService);
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        InventoryService inventoryService() {
            return mock(InventoryService.class);
        }

        @Bean
        InventoryController inventoryController(InventoryService inventoryService) {
            return new InventoryController(
                    inventoryService,
                    mock(BranchService.class),
                    mock(AccessScopeService.class));
        }
    }

    @Test
    @DisplayName("AuthZ: ERTEKTAR ENGEDÉLYEZETT inventory mozgás jóváhagyására (4-szem-elv service szinten)")
    @WithMockUser(roles = "ERTEKTAR")
    void approve_allowedForErtektar() {
        assertDoesNotThrow(() -> controller.approve(1L, authWithWorker(10L)));

        verify(inventoryService).approveMovement(1L, 10L);
    }

    @Test
    @DisplayName("AuthZ: ERTEKTAR ENGEDÉLYEZETT inventory mozgás átvételére")
    @WithMockUser(roles = "ERTEKTAR")
    void receive_allowedForErtektar() {
        ReceiveMovementDto dto = ReceiveMovementDto.builder()
                .receivedAmount(BigDecimal.TEN)
                .build();

        assertDoesNotThrow(() -> controller.receive(1L, dto, authWithWorker(10L)));

        verify(inventoryService).receiveMovement(1L, 10L, dto);
    }

    @Test
    @DisplayName("AuthZ: ERTEKTAR ENGEDÉLYEZETT inventory mozgás visszavonására")
    @WithMockUser(roles = "ERTEKTAR")
    void cancel_allowedForErtektar() {
        assertDoesNotThrow(() -> controller.cancel(1L));

        verify(inventoryService).cancelMovement(1L);
    }

    @Test
    @DisplayName("AuthZ: ERTEKTAR ENGEDÉLYEZETT inventory mozgás részleteinek lekérdezésére")
    @WithMockUser(roles = "ERTEKTAR")
    void getMovement_allowedForErtektar() {
        assertDoesNotThrow(() -> controller.getMovement(1L));

        verify(inventoryService).getMovement(1L);
    }

    @Test
    @DisplayName("AuthZ: CASHIER TILTOTT inventory mozgás jóváhagyására")
    @WithMockUser(roles = "CASHIER")
    void approve_forbiddenForCashier() {
        assertThrows(AccessDeniedException.class, () -> controller.approve(1L, authWithWorker(10L)));

        verify(inventoryService, never()).approveMovement(anyLong(), anyLong());
    }

    @Test
    @DisplayName("AuthZ: SUPERVISOR ENGEDÉLYEZETT marad inventory mozgás jóváhagyására")
    @WithMockUser(roles = "SUPERVISOR")
    void approve_allowedForSupervisor() {
        assertDoesNotThrow(() -> controller.approve(1L, authWithWorker(10L)));

        verify(inventoryService).approveMovement(1L, 10L);
    }

    private Authentication authWithWorker(long workerId) {
        var token = new UsernamePasswordAuthenticationToken("user", "n/a", List.of());
        token.setDetails(new WorkerAuthenticationDetails(workerId, UUID.randomUUID(), UUID.randomUUID(), "ERTEKTAR"));
        return token;
    }
}
