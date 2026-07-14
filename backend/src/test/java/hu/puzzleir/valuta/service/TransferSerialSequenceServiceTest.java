package hu.puzzleir.valuta.service;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TransferSerialSequenceServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");

    @Mock private EntityManager entityManager;
    @Mock private Query query;

    @InjectMocks private TransferSerialSequenceService service;

    @Test
    void handlingFeePrefixIsAcceptedBySerialSequence() {
        when(entityManager.createNativeQuery(anyString())).thenReturn(query);
        when(query.setParameter(anyString(), any())).thenReturn(query);
        when(query.getSingleResult()).thenReturn(1L);

        assertThat(service.next(COMPANY_ID, ShipmentHandlingFeeService.SERIAL_PREFIX_HANDLING_FEE))
                .isEqualTo(1L);
    }
}
