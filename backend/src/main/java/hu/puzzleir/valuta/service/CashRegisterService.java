package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.repository.BranchRepository;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterEventDto;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterReceiptRequest;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterStornoRequest;
import hu.puzzleir.valuta.entity.CashRegisterEvent;
import hu.puzzleir.valuta.entity.CashRegisterEventType;
import hu.puzzleir.valuta.repository.CashRegisterEventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Pénztárgép szolgáltatás.
 * NAV online pénztárgép integráció — egyelőre mock/log implementáció.
 * A tényleges hardware kommunikáció abstract.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CashRegisterService {

    private final CashRegisterEventRepository cashRegisterEventRepository;
    private final BranchRepository branchRepository;

    /**
     * Napi nyitás — OPEN esemény rögzítése.
     */
    @Transactional
    public CashRegisterEventDto openDay(UUID branchId) {
        Branch branch = findBranch(branchId);

        CashRegisterEvent event = CashRegisterEvent.builder()
                .branch(branch)
                .eventType(CashRegisterEventType.OPEN)
                .eventTimestamp(LocalDateTime.now())
                .rawResponse("{\"status\":\"OK\",\"message\":\"Pénztárgép napi nyitás sikeres\"}")
                .build();

        event = cashRegisterEventRepository.save(event);
        log.info("Pénztárgép napi nyitás: branch={}", branch.getCode());
        return toDto(event);
    }

    /**
     * Napi zárás — Z jelentés, CLOSE esemény.
     */
    @Transactional
    public CashRegisterEventDto closeDay(UUID branchId) {
        Branch branch = findBranch(branchId);

        CashRegisterEvent event = CashRegisterEvent.builder()
                .branch(branch)
                .eventType(CashRegisterEventType.CLOSE)
                .eventTimestamp(LocalDateTime.now())
                .rawResponse("{\"status\":\"OK\",\"message\":\"Z jelentés nyomtatva, pénztárgép napi zárás sikeres\"}")
                .build();

        event = cashRegisterEventRepository.save(event);
        log.info("Pénztárgép napi zárás (Z): branch={}", branch.getCode());
        return toDto(event);
    }

    /**
     * Bizonylat nyomtatása a pénztárgépen.
     */
    @Transactional
    public CashRegisterEventDto printReceipt(CashRegisterReceiptRequest request) {
        Branch branch = findBranch(request.getBranchId());

        CashRegisterEvent event = CashRegisterEvent.builder()
                .branch(branch)
                .eventType(CashRegisterEventType.RECEIPT)
                .receiptNumber(request.getReceiptNumber())
                .amount(request.getAmount())
                .currencyCode(request.getCurrencyCode())
                .amountHuf(request.getAmountHuf())
                .eventTimestamp(LocalDateTime.now())
                .rawResponse("{\"status\":\"OK\",\"message\":\"Bizonylat sikeresen nyomtatva\"}")
                .build();

        event = cashRegisterEventRepository.save(event);
        log.info("Pénztárgép bizonylat: branch={}, receipt={}", branch.getCode(), request.getReceiptNumber());
        return toDto(event);
    }

    /**
     * Sztornó bizonylat nyomtatása.
     */
    @Transactional
    public CashRegisterEventDto printStorno(CashRegisterStornoRequest request) {
        Branch branch = findBranch(request.getBranchId());

        // Eredeti bizonylat esemény keresése
        CashRegisterEvent originalEvent = cashRegisterEventRepository.findById(request.getOriginalReceiptId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Eredeti bizonylat esemény nem található: " + request.getOriginalReceiptId()));

        CashRegisterEvent event = CashRegisterEvent.builder()
                .branch(branch)
                .eventType(CashRegisterEventType.STORNO)
                .receiptNumber("S-" + (originalEvent.getReceiptNumber() != null ? originalEvent.getReceiptNumber() : ""))
                .amount(originalEvent.getAmount())
                .currencyCode(originalEvent.getCurrencyCode())
                .amountHuf(originalEvent.getAmountHuf())
                .eventTimestamp(LocalDateTime.now())
                .rawResponse("{\"status\":\"OK\",\"message\":\"Sztornó bizonylat nyomtatva\"}")
                .build();

        event = cashRegisterEventRepository.save(event);
        log.info("Pénztárgép sztornó: branch={}, original={}", branch.getCode(), request.getOriginalReceiptId());
        return toDto(event);
    }

    /**
     * X jelentés (köztes) lekérdezése.
     */
    @Transactional
    public CashRegisterEventDto getXReport(UUID branchId) {
        Branch branch = findBranch(branchId);

        CashRegisterEvent event = CashRegisterEvent.builder()
                .branch(branch)
                .eventType(CashRegisterEventType.X_REPORT)
                .eventTimestamp(LocalDateTime.now())
                .rawResponse("{\"status\":\"OK\",\"message\":\"X jelentés lekérdezve\"}")
                .build();

        event = cashRegisterEventRepository.save(event);
        log.info("Pénztárgép X jelentés: branch={}", branch.getCode());
        return toDto(event);
    }

    /**
     * Napi események lekérdezése.
     */
    @Transactional(readOnly = true)
    public List<CashRegisterEventDto> getDailyEvents(UUID branchId, LocalDate date) {
        LocalDateTime from = date.atStartOfDay();
        LocalDateTime to = date.atTime(LocalTime.MAX);

        return cashRegisterEventRepository
                .findByBranchIdAndEventTimestampBetweenOrderByEventTimestampDesc(branchId, from, to)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    // ============ HELPERS ============

    private Branch findBranch(UUID branchId) {
        return branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
    }

    private CashRegisterEventDto toDto(CashRegisterEvent e) {
        return CashRegisterEventDto.builder()
                .id(e.getId())
                .branchId(e.getBranch().getId())
                .eventType(e.getEventType().name())
                .receiptNumber(e.getReceiptNumber())
                .amount(e.getAmount())
                .currencyCode(e.getCurrencyCode())
                .amountHuf(e.getAmountHuf())
                .taxNumber(e.getTaxNumber())
                .cashRegisterId(e.getCashRegisterId())
                .eventTimestamp(e.getEventTimestamp())
                .rawResponse(e.getRawResponse())
                .build();
    }
}
