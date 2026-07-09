package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.mnbsettlement.MnbSettlementRateDto;
import hu.puzzleir.valuta.dto.mnbsettlement.MnbSettlementRateUpdateRequest;
import hu.puzzleir.valuta.service.MnbSettlementRateService;
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

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = MnbSettlementRateControllerSecurityWebMvcTest.TestConfig.class)
class MnbSettlementRateControllerSecurityWebMvcTest {

    @Autowired
    private MnbSettlementRateService service;

    @Autowired
    private MnbSettlementRateController controller;

    @BeforeEach
    void setup() {
        reset(service);
        when(service.list()).thenReturn(List.of());
        when(service.mnbQuery()).thenReturn(List.of());
        when(service.update(any(), eq(false))).thenReturn(List.of());
        when(service.update(any(), eq(true))).thenReturn(List.of());
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        MnbSettlementRateService mnbSettlementRateService() {
            return mock(MnbSettlementRateService.class);
        }

        @Bean
        MnbSettlementRateController mnbSettlementRateController(MnbSettlementRateService service) {
            return new MnbSettlementRateController(service);
        }
    }

    @Test
    @DisplayName("AuthZ: FOERTEKTAR/BELSO_ELLENOR/UGYVEZETO olvashatja az MNB elszámolási árfolyam listát")
    @WithMockUser(roles = "BELSO_ELLENOR")
    void list_allowedForReadRoles() {
        assertDoesNotThrow(() -> controller.list());

        verify(service).list();
    }

    @Test
    @DisplayName("AuthZ: PENZTAR nem olvashatja az MNB elszámolási árfolyam listát")
    @WithMockUser(roles = "PENZTAR")
    void list_forbiddenForPenztar() {
        assertThrows(AccessDeniedException.class, () -> controller.list());

        verifyNoInteractions(service);
    }

    @Test
    @DisplayName("AuthZ: BELSO_ELLENOR/UGYVEZETO átjut az mnb-query határ-annotáción, a FOERTEKTAR-only auditot a service végzi")
    @WithMockUser(roles = "UGYVEZETO")
    void mnbQuery_annotationAllowsReadRolesForServiceAuditGuard() {
        assertDoesNotThrow(() -> controller.mnbQuery());

        verify(service).mnbQuery();
    }

    @Test
    @DisplayName("AuthZ: PENZTAR nem hívhat mnb-query endpointot")
    @WithMockUser(roles = "PENZTAR")
    void mnbQuery_forbiddenForPenztar() {
        assertThrows(AccessDeniedException.class, () -> controller.mnbQuery());

        verifyNoInteractions(service);
    }

    @Test
    @DisplayName("AuthZ: BELSO_ELLENOR átjut az update határ-annotáción, a FOERTEKTAR-only auditot a service végzi")
    @WithMockUser(roles = "BELSO_ELLENOR")
    void update_annotationAllowsReadRolesForServiceAuditGuard() {
        MnbSettlementRateUpdateRequest request = new MnbSettlementRateUpdateRequest();

        assertDoesNotThrow(() -> controller.update(request));

        verify(service).update(request, false);
    }

    @Test
    @DisplayName("AuthZ: UGYVEZETO átjut a publish határ-annotáción, a FOERTEKTAR-only auditot a service végzi")
    @WithMockUser(roles = "UGYVEZETO")
    void publish_annotationAllowsReadRolesForServiceAuditGuard() {
        MnbSettlementRateUpdateRequest request = new MnbSettlementRateUpdateRequest();

        assertDoesNotThrow(() -> controller.publish(request));

        verify(service).update(request, true);
    }

    @Test
    @DisplayName("AuthZ: PENZTAR nem hívhat update/publish endpointot")
    @WithMockUser(roles = "PENZTAR")
    void writeEndpoints_forbiddenForPenztar() {
        MnbSettlementRateUpdateRequest request = new MnbSettlementRateUpdateRequest();

        assertThrows(AccessDeniedException.class, () -> controller.update(request));
        assertThrows(AccessDeniedException.class, () -> controller.publish(request));

        verifyNoInteractions(service);
    }
}
