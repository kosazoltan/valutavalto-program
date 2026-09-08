package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UnconfirmedIncomingClosingGate {

    private final TransferService transferService;
    private final ShipmentService shipmentService;

    public void ensureNoUnconfirmedIncoming(UUID branchId, LocalDate date) {
        transferService.ensureNoUnconfirmedIncomingTransfers(branchId, date);
        shipmentService.ensureNoUnconfirmedIncomingShipments(branchId, date);
    }
}
