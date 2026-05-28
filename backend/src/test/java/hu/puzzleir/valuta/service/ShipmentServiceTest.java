package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ShipmentServiceTest {

    @Mock
    private ShipmentRequestRepository repository;

    @Mock
    private hu.puzzleir.valuta.repository.BranchRepository branchRepository;

    @Mock
    private ExchangeRateService exchangeRateService;

    @InjectMocks
    private ShipmentService service;

    @Test
    void createSetsDraftMetadataForValidRequest() {
        when(repository.findMaxRequestNumber(any())).thenReturn(0);
        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            ShipmentRequest saved = service.create(validRequest());

            assertThat(saved.getRequestNumber()).startsWith("SHR-");
            assertThat(saved.getRequestedById()).isEqualTo(42L);
            assertThat(saved.getStatus().name()).isEqualTo("DRAFT");
        }
    }

    @Test
    void createRejectsSameSourceAndTargetBranch() {
        ShipmentRequest request = validRequest();
        request.setToBranchId(request.getFromBranchId());

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nem lehet ugyanaz");
        verifyNoInteractions(repository);
    }

    @Test
    void createRejectsMissingItems() {
        ShipmentRequest request = validRequest();
        request.setItems(List.of());

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Legalább egy");
        verifyNoInteractions(repository);
    }

    @Test
    void createRejectsNonPositiveAmount() {
        ShipmentRequest request = validRequest();
        request.getItems().getFirst().setRequestedAmount(BigDecimal.ZERO);

        assertThatThrownBy(() -> service.create(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("pozitív összeg");
        verifyNoInteractions(repository);
    }

    private static ShipmentRequest validRequest() {
        return ShipmentRequest.builder()
                .fromBranchId(UUID.randomUUID())
                .toBranchId(UUID.randomUUID())
                .deliveryDate(LocalDate.now().plusDays(1))
                .items(new ArrayList<>(List.of(ShipmentRequestItem.builder()
                        .currencyId(4L)
                        .requestedAmount(new BigDecimal("1000"))
                        .build())))
                .build();
    }
}
