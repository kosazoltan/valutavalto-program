package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class UnconfirmedIncomingClosingGateTest {

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final LocalDate DAY = LocalDate.of(2026, 9, 8);

    @Mock private TransferService transferService;
    @Mock private ShipmentService shipmentService;
    @InjectMocks private UnconfirmedIncomingClosingGate gate;

    @Test
    @DisplayName("nothing unconfirmed → both services called once")
    void nothingUnconfirmed_callsBoth() {
        gate.ensureNoUnconfirmedIncoming(BRANCH_ID, DAY);
        verify(transferService).ensureNoUnconfirmedIncomingTransfers(BRANCH_ID, DAY);
        verify(shipmentService).ensureNoUnconfirmedIncomingShipments(BRANCH_ID, DAY);
    }

    @Test
    @DisplayName("transfers dirty → shipments not reached")
    void transferThrows_shipmentNotCalled() {
        doThrow(new ValidationException("Nyugtázatlan bejövő átadólap: AT-1"))
                .when(transferService).ensureNoUnconfirmedIncomingTransfers(BRANCH_ID, DAY);
        assertThatThrownBy(() -> gate.ensureNoUnconfirmedIncoming(BRANCH_ID, DAY))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("AT-1");
        verify(shipmentService, never()).ensureNoUnconfirmedIncomingShipments(any(), any());
    }

    @Test
    @DisplayName("transfers clean + shipments dirty → still throws")
    void shipmentArmReached() {
        doThrow(new ValidationException("Nyugtázatlan bejövő szállítás: SR-9"))
                .when(shipmentService).ensureNoUnconfirmedIncomingShipments(BRANCH_ID, DAY);
        assertThatThrownBy(() -> gate.ensureNoUnconfirmedIncoming(BRANCH_ID, DAY))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("SR-9");
        verify(transferService).ensureNoUnconfirmedIncomingTransfers(BRANCH_ID, DAY);
    }
}
