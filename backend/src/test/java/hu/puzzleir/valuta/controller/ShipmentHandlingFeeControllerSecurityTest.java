package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.shipment.ShipmentHandlingFeeCreateRequest;
import hu.puzzleir.valuta.dto.shipment.ShipmentHandlingFeeCreateResponseDto;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.service.ShipmentHandlingFeeService;
import hu.puzzleir.valuta.service.ShipmentVatSupplyService;
import hu.puzzleir.valuta.service.ShipmentService;
import hu.puzzleir.valuta.util.IdempotencyGuard;
import jakarta.validation.Validation;
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
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = ShipmentHandlingFeeControllerSecurityTest.TestConfig.class)
class ShipmentHandlingFeeControllerSecurityTest {

    private static final String CREATE_AUTH = "hasAnyRole('ERTEKTAR', 'FOERTEKTAR', 'ADMIN')";
    private static final UUID SHIPMENT_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID FROM_BRANCH_ID = UUID.fromString("44444444-4444-4444-4444-444444444444");
    private static final UUID TO_BRANCH_ID = UUID.fromString("55555555-5555-5555-5555-555555555555");

    @Autowired private ShipmentController controller;
    @Autowired private ShipmentHandlingFeeService handlingFeeService;

    @BeforeEach
    void setUp() {
        reset(handlingFeeService);
    }

    @Test
    void handlers_haveRequiredPreAuthorizeContract() throws Exception {
        Method create = ShipmentController.class.getDeclaredMethod(
                "createHandlingFee", ShipmentHandlingFeeCreateRequest.class);
        PreAuthorize createAuth = create.getAnnotation(PreAuthorize.class);
        assertThat(createAuth).isNotNull();
        assertThat(createAuth.value()).isEqualTo(CREATE_AUTH);

        Method get = ShipmentController.class.getDeclaredMethod("getHandlingFee", UUID.class);
        assertThat(get.getAnnotation(PreAuthorize.class)).isNull();
        PreAuthorize classAuth = ShipmentController.class.getAnnotation(PreAuthorize.class);
        assertThat(classAuth).isNotNull();
        assertThat(classAuth.value()).contains("'ERTEKTAR'").contains("'FOERTEKTAR'").contains("'ADMIN'");
    }

    @Test
    @WithMockUser(roles = "ERTEKTAR")
    void create_allowsErtektarAndDelegates() {
        ShipmentHandlingFeeCreateRequest request = validRequest();
        ShipmentHandlingFeeCreateResponseDto response = ShipmentHandlingFeeCreateResponseDto.builder().build();
        when(handlingFeeService.create(request)).thenReturn(response);

        assertThat(controller.createHandlingFee(request).getBody()).isSameAs(response);

        verify(handlingFeeService).create(request);
    }

    @Test
    @WithMockUser(roles = "PENZTAR")
    void create_deniesPenztarBeforeServiceCall() {
        ShipmentHandlingFeeCreateRequest request = validRequest();

        assertThatThrownBy(() -> controller.createHandlingFee(request))
                .isInstanceOf(AccessDeniedException.class);

        verify(handlingFeeService, never()).create(any());
    }

    @Test
    @WithMockUser(roles = "ERTEKSZALLITO")
    void create_deniesErtekszallitoBeforeServiceCall() {
        ShipmentHandlingFeeCreateRequest request = validRequest();

        assertThatThrownBy(() -> controller.createHandlingFee(request))
                .isInstanceOf(AccessDeniedException.class);

        verify(handlingFeeService, never()).create(any());
    }

    @Test
    @WithMockUser(roles = "ERTEKTAR")
    void get_propagatesResourceNotFound() {
        when(handlingFeeService.findByShipmentId(SHIPMENT_ID))
                .thenThrow(new ResourceNotFoundException("nincs fee"));

        assertThatThrownBy(() -> controller.getHandlingFee(SHIPMENT_ID))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("nincs fee");
    }

    @Test
    void createRequest_nullAmountViolatesValidationContract() {
        ShipmentHandlingFeeCreateRequest request = validRequest();
        request.setHufAmount(null);

        try (var factory = Validation.buildDefaultValidatorFactory()) {
            assertThat(factory.getValidator().validate(request))
                    .anySatisfy(violation ->
                            assertThat(violation.getPropertyPath().toString()).isEqualTo("hufAmount"));
        }
    }

    private static ShipmentHandlingFeeCreateRequest validRequest() {
        return ShipmentHandlingFeeCreateRequest.builder()
                .fromBranchId(FROM_BRANCH_ID)
                .toBranchId(TO_BRANCH_ID)
                .hufAmount(new BigDecimal("125000"))
                .carrierName("Brink's Hungary Kft.")
                .sealNumber("FKH-018")
                .build();
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {

        @Bean
        ShipmentService shipmentService() {
            return mock(ShipmentService.class);
        }

        @Bean
        ShipmentHandlingFeeService shipmentHandlingFeeService() {
            return mock(ShipmentHandlingFeeService.class);
        }

        @Bean
        ShipmentVatSupplyService shipmentVatSupplyService() {
            return mock(ShipmentVatSupplyService.class);
        }

        @Bean
        IdempotencyGuard idempotencyGuard() {
            return mock(IdempotencyGuard.class);
        }

        @Bean
        ShipmentController shipmentController(
                ShipmentService shipmentService,
                ShipmentHandlingFeeService shipmentHandlingFeeService,
                ShipmentVatSupplyService shipmentVatSupplyService,
                IdempotencyGuard idempotencyGuard) {
            return new ShipmentController(
                    shipmentService, shipmentHandlingFeeService, shipmentVatSupplyService, idempotencyGuard);
        }
    }
}
