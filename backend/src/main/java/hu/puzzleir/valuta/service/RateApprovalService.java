package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.dto.rateapproval.RateApprovalDto;
import hu.puzzleir.valuta.dto.rateapproval.RequestRateChangeDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.RateApprovalRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Árfolyam engedélyezés service.
 *
 * Legacy: ratectrl.dll — az értéktár kontrollálja a pénztárak árfolyamait.
 * A jóváhagyott árfolyam változtatásokat az ExchangeRateService-en
 * keresztül érvényesíti a rendszer.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RateApprovalService {

    private final RateApprovalRepository rateApprovalRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;
    private final ExchangeRateService exchangeRateService;
    private final CurrencyRepository currencyRepository;

    /**
     * Új árfolyam változtatási kérelem.
     */
    @Transactional
    public RateApprovalDto requestRateChange(RequestRateChangeDto dto, Long requestedById) {
        Branch branch = branchRepository.findById(dto.getBranchId())
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + dto.getBranchId()));

        Worker requester = workerRepository.findById(requestedById)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + requestedById));

        RateApproval approval = RateApproval.builder()
                .branch(branch)
                .currencyCode(dto.getCurrencyCode())
                .newBuyRate(dto.getNewBuyRate())
                .newSellRate(dto.getNewSellRate())
                .status(RateApprovalStatus.PENDING)
                .requestedByWorker(requester)
                .requestedAt(LocalDateTime.now())
                .reason(dto.getReason())
                .build();

        approval = rateApprovalRepository.save(approval);
        log.info("Árfolyam változtatási kérelem: branch={}, currency={}, buy={}, sell={}",
                branch.getCode(), dto.getCurrencyCode(), dto.getNewBuyRate(), dto.getNewSellRate());
        return toDto(approval);
    }

    /**
     * Árfolyam változtatás jóváhagyása.
     *
     * A jóváhagyás után automatikusan létrehozza az új ExchangeRate rekordot
     * a megadott irodához, így az árfolyam azonnal érvénybe lép.
     *
     * Legacy: ratectrl.dll — az értéktáros jóváhagyja a pénztáros
     * által kért árfolyam változtatást, és az új árfolyam bekerül
     * az ARFOLYAM táblába.
     */
    @Transactional
    public RateApprovalDto approveRateChange(UUID approvalId, Long approvedById) {
        RateApproval approval = rateApprovalRepository.findById(approvalId)
                .orElseThrow(() -> new ResourceNotFoundException("Jóváhagyás nem található: " + approvalId));

        if (approval.getStatus() != RateApprovalStatus.PENDING) {
            throw new ValidationException("Csak PENDING státuszú kérelem hagyható jóvá! Jelenlegi: " + approval.getStatus());
        }

        Worker approver = workerRepository.findById(approvedById)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + approvedById));

        approval.setStatus(RateApprovalStatus.APPROVED);
        approval.setApprovedByWorker(approver);
        approval.setApprovedAt(LocalDateTime.now());

        approval = rateApprovalRepository.save(approval);

        // Create new ExchangeRate from the approved rate change
        applyApprovedRateChange(approval);

        log.info("Árfolyam változtatás jóváhagyva és érvényesítve: id={}, branch={}, currency={}",
                approvalId, approval.getBranch().getCode(), approval.getCurrencyCode());
        return toDto(approval);
    }

    /**
     * Apply approved rate change by creating a new ExchangeRate record.
     */
    private void applyApprovedRateChange(RateApproval approval) {
        Currency currency = currencyRepository.findByCode(approval.getCurrencyCode())
                .orElse(null);

        if (currency == null) {
            log.warn("Valuta nem található a jóváhagyott kérelemhez: code={}", approval.getCurrencyCode());
            return;
        }

        ExchangeRateService.CreateExchangeRateRequest request =
                ExchangeRateService.CreateExchangeRateRequest.builder()
                        .currencyId(currency.getId())
                        .branchId(approval.getBranch().getId())
                        .baseBuyRate(approval.getNewBuyRate())
                        .baseSellRate(approval.getNewSellRate())
                        .build();

        exchangeRateService.createExchangeRate(request);
        log.info("Új árfolyam létrehozva jóváhagyásból: currency={}, branch={}, buy={}, sell={}",
                approval.getCurrencyCode(), approval.getBranch().getCode(),
                approval.getNewBuyRate(), approval.getNewSellRate());
    }

    /**
     * Árfolyam változtatás elutasítása.
     */
    @Transactional
    public RateApprovalDto rejectRateChange(UUID approvalId, String reason) {
        RateApproval approval = rateApprovalRepository.findById(approvalId)
                .orElseThrow(() -> new ResourceNotFoundException("Jóváhagyás nem található: " + approvalId));

        if (approval.getStatus() != RateApprovalStatus.PENDING) {
            throw new ValidationException("Csak PENDING státuszú kérelem utasítható el! Jelenlegi: " + approval.getStatus());
        }

        approval.setStatus(RateApprovalStatus.REJECTED);
        approval.setReason(reason);

        approval = rateApprovalRepository.save(approval);
        log.info("Árfolyam változtatás elutasítva: id={}, reason={}", approvalId, reason);
        return toDto(approval);
    }

    /**
     * Függőben lévő jóváhagyások listája.
     */
    @Transactional(readOnly = true)
    public List<RateApprovalDto> getPendingApprovals() {
        return rateApprovalRepository.findByStatusOrderByRequestedAtDesc(RateApprovalStatus.PENDING)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Jóváhagyás történet egy iroda számára.
     */
    @Transactional(readOnly = true)
    public List<RateApprovalDto> getApprovalHistory(UUID branchId) {
        return rateApprovalRepository.findByBranchIdOrderByRequestedAtDesc(branchId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    // ============ HELPERS ============

    private RateApprovalDto toDto(RateApproval a) {
        return RateApprovalDto.builder()
                .id(a.getId().toString())
                .branchId(a.getBranch().getId().toString())
                .branchName(a.getBranch().getName())
                .currencyCode(a.getCurrencyCode())
                .oldBuyRate(a.getOldBuyRate())
                .oldSellRate(a.getOldSellRate())
                .newBuyRate(a.getNewBuyRate())
                .newSellRate(a.getNewSellRate())
                .status(a.getStatus().name())
                .requestedById(a.getRequestedByWorker() != null ? a.getRequestedByWorker().getId() : null)
                .requestedByName(a.getRequestedByWorker() != null ? a.getRequestedByWorker().getName() : null)
                .approvedById(a.getApprovedByWorker() != null ? a.getApprovedByWorker().getId() : null)
                .approvedByName(a.getApprovedByWorker() != null ? a.getApprovedByWorker().getName() : null)
                .requestedAt(a.getRequestedAt() != null ? a.getRequestedAt().toString() : null)
                .approvedAt(a.getApprovedAt() != null ? a.getApprovedAt().toString() : null)
                .reason(a.getReason())
                .build();
    }
}
