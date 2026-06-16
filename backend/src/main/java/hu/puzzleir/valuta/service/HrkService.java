package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.CreateHrkTransactionDto;
import hu.puzzleir.valuta.dto.HrkTransactionDto;
import hu.puzzleir.valuta.entity.HrkTransaction;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.HrkTransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(rollbackFor = Exception.class)
public class HrkService {

    private final HrkTransactionRepository hrkTransactionRepository;

    private static final DateTimeFormatter REF_DATE_FMT = DateTimeFormatter.ofPattern("yyMMdd");

    /**
     * HRK átadás (pénztár → bank)
     */
    public HrkTransactionDto handover(UUID companyId, UUID branchId, Long workerId,
                                       CreateHrkTransactionDto dto) {
        log.info("HRK átadás - branch: {}, összeg: {} {}", branchId, dto.getAmount(), dto.getCurrencyCode());

        String reference = generateReference(branchId);

        HrkTransaction tx = HrkTransaction.builder()
                .companyId(companyId)
                .branchId(branchId)
                .type("HANDOVER")
                .currencyCode(dto.getCurrencyCode())
                .amount(dto.getAmount())
                .hufAmount(dto.getHufAmount())
                .bankAccountNumber(dto.getBankAccountNumber())
                .reference(reference)
                .note(dto.getNote())
                .status("COMPLETED")
                .workerId(workerId)
                .completedAt(LocalDateTime.now())
                .build();

        HrkTransaction saved = hrkTransactionRepository.save(tx);
        log.info("HRK átadás rögzítve: {}", saved.getReference());
        return toDto(saved);
    }

    /**
     * HRK átvétel (bank → pénztár)
     */
    public HrkTransactionDto receive(UUID companyId, UUID branchId, Long workerId,
                                      CreateHrkTransactionDto dto) {
        log.info("HRK átvétel - branch: {}, összeg: {} {}", branchId, dto.getAmount(), dto.getCurrencyCode());

        String reference = generateReference(branchId);

        HrkTransaction tx = HrkTransaction.builder()
                .companyId(companyId)
                .branchId(branchId)
                .type("RECEIVE")
                .currencyCode(dto.getCurrencyCode())
                .amount(dto.getAmount())
                .hufAmount(dto.getHufAmount())
                .bankAccountNumber(dto.getBankAccountNumber())
                .reference(reference)
                .note(dto.getNote())
                .status("COMPLETED")
                .workerId(workerId)
                .completedAt(LocalDateTime.now())
                .build();

        HrkTransaction saved = hrkTransactionRepository.save(tx);
        log.info("HRK átvétel rögzítve: {}", saved.getReference());
        return toDto(saved);
    }

    /**
     * HRK napló — egy adott iroda tranzakciói
     */
    @Transactional(readOnly = true)
    public List<HrkTransactionDto> getJournal(UUID branchId) {
        return hrkTransactionRepository.findByBranchIdOrderByCreatedAtDesc(branchId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * HRK napi zárás összesítő
     */
    @Transactional(readOnly = true)
    public List<HrkTransactionDto> getDailyTransactions(UUID branchId, LocalDate date) {
        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = date.plusDays(1).atStartOfDay();
        return hrkTransactionRepository.findByBranchIdAndDateRange(branchId, startOfDay, endOfDay)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * HRK tranzakció törlése (csak PENDING státuszú)
     */
    public void cancel(UUID transactionId) {
        // IDOR-guard: cég-scope-olt lekérés (a HrkTransaction-nak NOT NULL companyId-ja van).
        // Cross-tenant id → ugyanaz a ResourceNotFoundException, mint a nem létező id-nél.
        HrkTransaction tx = hrkTransactionRepository
                .findByIdAndCompanyId(transactionId, SecurityUtils.getCurrentCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("HRK tranzakció nem található: " + transactionId));

        if (!"PENDING".equals(tx.getStatus())) {
            throw new ValidationException("Csak PENDING státuszú tranzakció törölhető");
        }

        tx.setStatus("CANCELLED");
        hrkTransactionRepository.save(tx);
        log.info("HRK tranzakció törölve: {}", transactionId);
    }

    // --- Helper ---

    private String generateReference(UUID branchId) {
        String dateStr = LocalDate.now().format(REF_DATE_FMT);
        String prefix = "HRK-" + dateStr;
        long count = hrkTransactionRepository.countByBranchIdAndReferencePrefix(branchId, prefix);
        return String.format("%s-%04d", prefix, count + 1);
    }

    private HrkTransactionDto toDto(HrkTransaction entity) {
        return HrkTransactionDto.builder()
                .id(entity.getId())
                .branchId(entity.getBranchId())
                .type(entity.getType())
                .currencyCode(entity.getCurrencyCode())
                .amount(entity.getAmount())
                .hufAmount(entity.getHufAmount())
                .bankAccountNumber(entity.getBankAccountNumber())
                .reference(entity.getReference())
                .note(entity.getNote())
                .status(entity.getStatus())
                .workerId(entity.getWorkerId())
                .createdAt(entity.getCreatedAt())
                .completedAt(entity.getCompletedAt())
                .build();
    }
}
