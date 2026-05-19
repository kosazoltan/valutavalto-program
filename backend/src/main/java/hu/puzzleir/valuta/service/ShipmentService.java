package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.repository.BranchRepository;
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
    private final BranchRepository branchRepository;

    /**
     * v2.5.70 P0 multi-tenant fix (companyId audit follow-up): a régi findByStatus /
     * findAllOrdered globális queries voltak (NEM cég-szintű szűréssel), helyettük a
     * tenant-aware *ByCompanyId variánsokat hívjuk SecurityUtils.getCurrentCompanyId()-val.
     */
    @Transactional(readOnly = true)
    public Page<ShipmentRequest> findAll(ShipmentRequestStatus status, Pageable pageable) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (status != null) {
            return shipmentRequestRepository.findByStatusAndCompanyId(status, companyId, pageable);
        }
        return shipmentRequestRepository.findAllOrderedByCompanyId(companyId, pageable);
    }

    @Transactional(readOnly = true)
    public ShipmentRequest findById(UUID id) {
        ShipmentRequest sr = shipmentRequestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Szállítmánykérés nem található: " + id));
        // v2.5.70 P0 fix: cross-tenant IDOR guard — fromBranchId-n keresztül kérdezzük le
        // a Branch.company.id-t és összevetjük a jelenlegi user company-jával.
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        UUID branchCompanyId = branchRepository.findById(sr.getFromBranchId())
                .map(b -> b.getCompany() != null ? b.getCompany().getId() : null)
                .orElse(null);
        if (branchCompanyId == null || !currentCompanyId.equals(branchCompanyId)) {
            log.warn("Cross-tenant access blocked: shipmentRequest={}, fromBranch={}, branchCompany={}, currentCompany={}",
                    id, sr.getFromBranchId(), branchCompanyId, currentCompanyId);
            throw new ValidationException("A szállítmánykérés nem tartozik a jelenlegi céghez (cross-tenant access blocked)");
        }
        return sr;
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
        if (request.getItems() == null) {
            throw new ValidationException("Legalább egy szállítmány tétel kötelező!");
        }
    }

    private void validateEditableRequest(ShipmentRequest request) {
        if (request == null || request.getFromBranchId() == null || request.getToBranchId() == null) {
            throw new ValidationException("Forrás és cél iroda megadása kötelező!");
        }
        if (request.getFromBranchId().equals(request.getToBranchId())) {
            throw new ValidationException("A forrás és cél iroda nem lehet ugyanaz!");
        }
        if (request.getDeliveryDate() != null && request.getDeliveryDate().isBefore(LocalDate.now())) {
            throw new ValidationException("A kézbesítési dátum nem lehet múltbeli!");
        }
        if (request.getItems() != null && request.getItems().isEmpty()) {
            throw new ValidationException("Legalább egy szállítmány tétel kötelező!");
        }
        if (request.getItems() != null) {
            validateItems(request);
        }
    }

    private void validateItems(ShipmentRequest request) {
        request.getItems().forEach(item -> {
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
