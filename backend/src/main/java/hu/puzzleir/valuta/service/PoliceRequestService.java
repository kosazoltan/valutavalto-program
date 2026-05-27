package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.police.CreatePoliceRequestDto;
import hu.puzzleir.valuta.dto.police.PoliceRequestDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.PoliceRequestRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Rendőrségi adatkérés service.
 *
 * Hatósági megkeresések kezelése — automatikus tranzakció keresés.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PoliceRequestService {

    private final PoliceRequestRepository policeRequestRepository;
    private final CustomerRepository customerRepository;
    private final TransactionRepository transactionRepository;
    private final WorkerRepository workerRepository;

    /**
     * Új rendőrségi adatkérés létrehozása.
     */
    @Transactional(rollbackFor = Exception.class)
    public PoliceRequestDto createRequest(CreatePoliceRequestDto dto, Long createdById) {
        Worker creator = workerRepository.findById(createdById)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + createdById));

        PoliceRequest request = PoliceRequest.builder()
                .companyId(SecurityUtils.getCurrentCompanyId())  // V270: multi-tenant tulajdonos
                .requestNumber(dto.getRequestNumber())
                .requestDate(dto.getRequestDate())
                .requestedBy(dto.getRequestedBy())
                .customerName(dto.getCustomerName())
                .documentNumber(dto.getDocumentNumber())
                .dateRangeFrom(dto.getDateRangeFrom())
                .dateRangeTo(dto.getDateRangeTo())
                .status(PoliceRequestStatus.RECEIVED)
                .createdByWorker(creator)
                .build();

        request = policeRequestRepository.save(request);
        log.info("Rendőrségi adatkérés létrehozva: number={}, requestedBy={}",
                dto.getRequestNumber(), dto.getRequestedBy());
        return toDto(request);
    }

    /**
     * Adatkérés feldolgozása — automatikus tranzakció keresés.
     */
    @Transactional(rollbackFor = Exception.class)
    public PoliceRequestDto processRequest(UUID requestId) {
        // V270 multi-tenant: csak a hívó cégének adatkérése dolgozható fel (cross-tenant → 404).
        PoliceRequest request = policeRequestRepository
                .findByIdAndCompanyId(requestId, SecurityUtils.getCurrentCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("Adatkérés nem található: " + requestId));

        if (request.getStatus() != PoliceRequestStatus.RECEIVED &&
                request.getStatus() != PoliceRequestStatus.PROCESSING) {
            throw new ValidationException("Csak RECEIVED/PROCESSING státuszú kérelem dolgozható fel! Jelenlegi: "
                    + request.getStatus());
        }

        request.setStatus(PoliceRequestStatus.PROCESSING);

        // Tranzakciók keresése ügyfél név és okmányszám alapján
        StringBuilder responseJson = new StringBuilder("{\"results\":[");
        boolean hasResults = false;

        if (request.getCustomerName() != null || request.getDocumentNumber() != null) {
            // Ügyfelek keresése
            UUID companyId = SecurityUtils.getCurrentCompanyId();
            List<Customer> customers;
            if (request.getDocumentNumber() != null && !request.getDocumentNumber().isBlank()) {
                customers = customerRepository.findByCompanyIdAndDocumentNumberContainingIgnoreCase(
                        companyId, request.getDocumentNumber());
            } else {
                customers = customerRepository.findByCompanyIdAndNameContainingIgnoreCase(
                        companyId, request.getCustomerName());
            }

            for (Customer c : customers) {
                if (hasResults) responseJson.append(",");
                responseJson.append("{\"customerId\":").append(c.getId())
                        .append(",\"customerName\":\"").append(escapeJson(c.getName())).append("\"")
                        .append(",\"documentNumber\":\"")
                        .append(escapeJson(c.getDocumentNumber() != null ? c.getDocumentNumber() : ""))
                        .append("\"}");
                hasResults = true;
            }
        }

        responseJson.append("]}");

        request.setResponseData(responseJson.toString());
        request.setStatus(PoliceRequestStatus.COMPLETED);
        request.setCompletedAt(LocalDateTime.now());

        request = policeRequestRepository.save(request);
        log.info("Rendőrségi adatkérés feldolgozva: id={}, results={}",
                requestId, hasResults ? "found" : "empty");
        return toDto(request);
    }

    /**
     * Adatkérés részletei.
     */
    @Transactional(readOnly = true)
    public PoliceRequestDto getRequest(UUID requestId) {
        // V270 multi-tenant: csak a hívó cégének adatkérése kérdezhető le (cross-tenant → 404).
        PoliceRequest request = policeRequestRepository
                .findByIdAndCompanyId(requestId, SecurityUtils.getCurrentCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("Adatkérés nem található: " + requestId));
        return toDto(request);
    }

    /**
     * Adatkérések listája (paginated).
     */
    @Transactional(readOnly = true)
    public Page<PoliceRequestDto> getRequestHistory(Pageable pageable) {
        // V270 multi-tenant: csak a hívó cégének adatkérései.
        return policeRequestRepository
                .findByCompanyIdOrderByCreatedAtDesc(SecurityUtils.getCurrentCompanyId(), pageable)
                .map(this::toDto);
    }

    // ============ HELPERS ============

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private PoliceRequestDto toDto(PoliceRequest r) {
        return PoliceRequestDto.builder()
                .id(r.getId().toString())
                .requestNumber(r.getRequestNumber())
                .requestDate(r.getRequestDate() != null ? r.getRequestDate().toString() : null)
                .requestedBy(r.getRequestedBy())
                .customerName(r.getCustomerName())
                .documentNumber(r.getDocumentNumber())
                .dateRangeFrom(r.getDateRangeFrom() != null ? r.getDateRangeFrom().toString() : null)
                .dateRangeTo(r.getDateRangeTo() != null ? r.getDateRangeTo().toString() : null)
                .status(r.getStatus().name())
                .responseData(r.getResponseData())
                .completedAt(r.getCompletedAt() != null ? r.getCompletedAt().toString() : null)
                .createdAt(r.getCreatedAt() != null ? r.getCreatedAt().toString() : null)
                .createdById(r.getCreatedByWorker() != null ? r.getCreatedByWorker().getId() : null)
                .createdByName(r.getCreatedByWorker() != null ? r.getCreatedByWorker().getName() : null)
                .build();
    }
}
