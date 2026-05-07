package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

/**
 * Szállítmánykérés szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class ShipmentService {

    private final ShipmentRequestRepository shipmentRequestRepository;

    @Transactional(readOnly = true)
    public Page<ShipmentRequest> findAll(ShipmentRequestStatus status, Pageable pageable) {
        if (status != null) {
            return shipmentRequestRepository.findByStatus(status, pageable);
        }
        return shipmentRequestRepository.findAllOrdered(pageable);
    }

    @Transactional(readOnly = true)
    public ShipmentRequest findById(UUID id) {
        return shipmentRequestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Szállítmánykérés nem található: " + id));
    }

    public ShipmentRequest create(ShipmentRequest request) {
        validateCreateRequest(request);
        request.setRequestNumber(generateRequestNumber());
        request.setStatus(ShipmentRequestStatus.DRAFT);
        request.setRequestedById(SecurityUtils.getCurrentWorkerId());
        request.setRequestDate(LocalDate.now());

        log.info("Szállítmánykérés létrehozva: {}, from={}, to={}",
                request.getRequestNumber(), request.getFromBranchId(), request.getToBranchId());
        return shipmentRequestRepository.save(request);
    }

    public ShipmentRequest update(UUID id, ShipmentRequest updated) {
        ShipmentRequest existing = findById(id);
        if (existing.getStatus() != ShipmentRequestStatus.DRAFT) {
            throw new ValidationException("Csak DRAFT státuszú kérés módosítható!");
        }
        validateEditableRequest(updated);

        existing.setFromBranchId(updated.getFromBranchId());
        existing.setToBranchId(updated.getToBranchId());
        existing.setDeliveryDate(updated.getDeliveryDate());
        existing.setNotes(updated.getNotes());

        if (updated.getItems() != null) {
            existing.setItems(updated.getItems());
        }

        log.info("Szállítmánykérés frissítve: {}", id);
        return shipmentRequestRepository.save(existing);
    }

    public ShipmentRequest submit(UUID id) {
        ShipmentRequest request = findById(id);
        validateStatusTransition(request, ShipmentRequestStatus.DRAFT, ShipmentRequestStatus.SUBMITTED);
        request.setStatus(ShipmentRequestStatus.SUBMITTED);
        log.info("Szállítmánykérés beküldve: {}", request.getRequestNumber());
        return shipmentRequestRepository.save(request);
    }

    public ShipmentRequest approve(UUID id) {
        ShipmentRequest request = findById(id);
        validateStatusTransition(request, ShipmentRequestStatus.SUBMITTED, ShipmentRequestStatus.APPROVED);
        request.setStatus(ShipmentRequestStatus.APPROVED);
        log.info("Szállítmánykérés jóváhagyva: {}", request.getRequestNumber());
        return shipmentRequestRepository.save(request);
    }

    public ShipmentRequest deliver(UUID id) {
        ShipmentRequest request = findById(id);
        if (request.getStatus() != ShipmentRequestStatus.APPROVED
                && request.getStatus() != ShipmentRequestStatus.IN_TRANSIT) {
            throw new ValidationException("Csak APPROVED vagy IN_TRANSIT státuszú kérés szállítható le!");
        }
        request.setStatus(ShipmentRequestStatus.DELIVERED);
        request.setDeliveryDate(LocalDate.now());
        log.info("Szállítmánykérés leszállítva: {}", request.getRequestNumber());
        return shipmentRequestRepository.save(request);
    }

    public ShipmentRequest cancel(UUID id) {
        ShipmentRequest request = findById(id);
        if (request.getStatus() == ShipmentRequestStatus.DELIVERED
                || request.getStatus() == ShipmentRequestStatus.CANCELLED) {
            throw new ValidationException("DELIVERED vagy CANCELLED státuszú kérés nem vonható vissza!");
        }
        request.setStatus(ShipmentRequestStatus.CANCELLED);
        log.info("Szállítmánykérés visszavonva: {}", request.getRequestNumber());
        return shipmentRequestRepository.save(request);
    }

    private void validateStatusTransition(ShipmentRequest request,
                                          ShipmentRequestStatus expectedCurrent,
                                          ShipmentRequestStatus targetStatus) {
        if (request.getStatus() != expectedCurrent) {
            throw new ValidationException(
                    String.format("A kérés státusza %s, de %s kellene a(z) %s művelethez!",
                            request.getStatus(), expectedCurrent, targetStatus));
        }
    }

    private void validateCreateRequest(ShipmentRequest request) {
        validateEditableRequest(request);
        validateRequiredItems(request.getItems());
    }

    private void validateEditableRequest(ShipmentRequest request) {
        if (request == null) {
            throw new ValidationException("Szállítmánykérés adatai kötelezőek!");
        }
        if (request.getFromBranchId() == null || request.getToBranchId() == null) {
            throw new ValidationException("Forrás és cél iroda megadása kötelező!");
        }
        if (request.getFromBranchId().equals(request.getToBranchId())) {
            throw new ValidationException("A forrás és cél iroda nem lehet ugyanaz!");
        }
        if (request.getDeliveryDate() != null && request.getDeliveryDate().isBefore(LocalDate.now())) {
            throw new ValidationException("A kézbesítési dátum nem lehet múltbeli!");
        }
        if (request.getItems() != null) {
            validateRequiredItems(request.getItems());
        }
    }

    private void validateRequiredItems(List<ShipmentRequestItem> items) {
        if (items == null || items.isEmpty()) {
            throw new ValidationException("Legalább egy szállítmány tétel kötelező!");
        }
        validateItems(items);
    }

    private void validateItems(List<ShipmentRequestItem> items) {
        items.forEach(item -> {
            if (item == null) {
                throw new ValidationException("Minden szállítmány tétel megadása kötelező!");
            }
            BigDecimal requestedAmount = item.getRequestedAmount();
            if (item.getCurrencyId() == null || requestedAmount == null || requestedAmount.signum() <= 0) {
                throw new ValidationException("Minden tételnél valuta és pozitív összeg kötelező!");
            }
        });
    }

    private String generateRequestNumber() {
        String prefix = "SHR-" + LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd")) + "-";
        int nextNum = shipmentRequestRepository.findMaxRequestNumber(prefix) + 1;
        return prefix + String.format("%04d", nextNum);
    }
}
