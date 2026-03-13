package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.wu.WuDailyReportDto;
import hu.puzzleir.valuta.dto.wu.WuTransactionDto;
import hu.puzzleir.valuta.entity.WuBalance;
import hu.puzzleir.valuta.entity.WuCustomer;
import hu.puzzleir.valuta.entity.WuTransaction;
import hu.puzzleir.valuta.repository.WuBalanceRepository;
import hu.puzzleir.valuta.repository.WuCustomerRepository;
import hu.puzzleir.valuta.repository.WuTransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/**
 * Western Union forgalom szolgáltatás.
 *
 * Legacy: WU DLL — WU küldés/fogadás nyilvántartás, egyenlegek, napi riport.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WesternUnionService {

    private final WuTransactionRepository wuTransactionRepository;
    private final WuCustomerRepository wuCustomerRepository;
    private final WuBalanceRepository wuBalanceRepository;
    private final BranchRepository branchRepository;

    /**
     * WU küldés rögzítése.
     */
    @Transactional
    public WuTransaction recordSend(WuTransactionDto dto) {
        Branch branch = findBranch(dto.getBranchId());

        WuTransaction tx = WuTransaction.builder()
                .branch(branch)
                .transactionType("SEND")
                .mtcn(dto.getMtcn())
                .amountUsd(dto.getAmountUsd())
                .amountHuf(dto.getAmountHuf())
                .exchangeRate(dto.getExchangeRate())
                .feeAmount(dto.getFeeAmount())
                .senderName(dto.getSenderName())
                .receiverName(dto.getReceiverName())
                .destinationCountry(dto.getDestinationCountry())
                .receiptNumber(dto.getReceiptNumber())
                .status("COMPLETED")
                .transactionDate(dto.getTransactionDate() != null ? dto.getTransactionDate() : LocalDateTime.now())
                .build();

        if (dto.getWuCustomerId() != null) {
            WuCustomer customer = wuCustomerRepository.findById(dto.getWuCustomerId())
                    .orElse(null);
            tx.setWuCustomer(customer);
        }

        WuTransaction saved = wuTransactionRepository.save(tx);

        // Egyenleg frissítés
        updateBalance(dto.getBranchId(), dto.getAmountUsd(), dto.getAmountHuf(), true);

        log.info("WU SEND recorded: MTCN={}, amount={} USD, branch={}",
                dto.getMtcn(), dto.getAmountUsd(), dto.getBranchId());
        return saved;
    }

    /**
     * WU fogadás rögzítése.
     */
    @Transactional
    public WuTransaction recordReceive(WuTransactionDto dto) {
        Branch branch = findBranch(dto.getBranchId());

        WuTransaction tx = WuTransaction.builder()
                .branch(branch)
                .transactionType("RECEIVE")
                .mtcn(dto.getMtcn())
                .amountUsd(dto.getAmountUsd())
                .amountHuf(dto.getAmountHuf())
                .exchangeRate(dto.getExchangeRate())
                .feeAmount(dto.getFeeAmount())
                .senderName(dto.getSenderName())
                .receiverName(dto.getReceiverName())
                .destinationCountry(dto.getDestinationCountry())
                .receiptNumber(dto.getReceiptNumber())
                .status("COMPLETED")
                .transactionDate(dto.getTransactionDate() != null ? dto.getTransactionDate() : LocalDateTime.now())
                .build();

        if (dto.getWuCustomerId() != null) {
            WuCustomer customer = wuCustomerRepository.findById(dto.getWuCustomerId())
                    .orElse(null);
            tx.setWuCustomer(customer);
        }

        WuTransaction saved = wuTransactionRepository.save(tx);

        // Egyenleg frissítés (fogadásnál ellentétes irány)
        updateBalance(dto.getBranchId(), dto.getAmountUsd(), dto.getAmountHuf(), false);

        log.info("WU RECEIVE recorded: MTCN={}, amount={} USD, branch={}",
                dto.getMtcn(), dto.getAmountUsd(), dto.getBranchId());
        return saved;
    }

    /**
     * WU tranzakciók lekérdezése irodánként és dátum tartomány szerint.
     */
    @Transactional(readOnly = true)
    public Page<WuTransaction> getTransactions(UUID branchId, LocalDate from, LocalDate to, Pageable pageable) {
        LocalDateTime fromDt = from != null ? from.atStartOfDay() : null;
        LocalDateTime toDt = to != null ? to.atTime(LocalTime.MAX) : null;
        return wuTransactionRepository.findByBranchAndDateRange(branchId, fromDt, toDt, pageable);
    }

    /**
     * WU napi riport.
     */
    @Transactional(readOnly = true)
    public WuDailyReportDto getDailyReport(UUID branchId, LocalDate date) {
        LocalDateTime from = date.atStartOfDay();
        LocalDateTime to = date.atTime(LocalTime.MAX);
        List<WuTransaction> transactions = wuTransactionRepository.findAllByBranchAndDateRange(branchId, from, to);

        int sendCount = 0;
        int receiveCount = 0;
        BigDecimal totalSendUsd = BigDecimal.ZERO;
        BigDecimal totalSendHuf = BigDecimal.ZERO;
        BigDecimal totalReceiveUsd = BigDecimal.ZERO;
        BigDecimal totalReceiveHuf = BigDecimal.ZERO;
        BigDecimal totalFees = BigDecimal.ZERO;

        for (WuTransaction tx : transactions) {
            if ("SEND".equals(tx.getTransactionType())) {
                sendCount++;
                if (tx.getAmountUsd() != null) totalSendUsd = totalSendUsd.add(tx.getAmountUsd());
                if (tx.getAmountHuf() != null) totalSendHuf = totalSendHuf.add(tx.getAmountHuf());
            } else {
                receiveCount++;
                if (tx.getAmountUsd() != null) totalReceiveUsd = totalReceiveUsd.add(tx.getAmountUsd());
                if (tx.getAmountHuf() != null) totalReceiveHuf = totalReceiveHuf.add(tx.getAmountHuf());
            }
            if (tx.getFeeAmount() != null) totalFees = totalFees.add(tx.getFeeAmount());
        }

        return WuDailyReportDto.builder()
                .date(date)
                .sendCount(sendCount)
                .receiveCount(receiveCount)
                .totalSendUsd(totalSendUsd)
                .totalSendHuf(totalSendHuf)
                .totalReceiveUsd(totalReceiveUsd)
                .totalReceiveHuf(totalReceiveHuf)
                .totalFees(totalFees)
                .build();
    }

    /**
     * WU egyenleg lekérdezése.
     */
    @Transactional(readOnly = true)
    public List<WuBalance> getBalance(UUID branchId) {
        return wuBalanceRepository.findAllByBranchId(branchId);
    }

    // ============ PRIVATE HELPERS ============

    private Branch findBranch(UUID branchId) {
        return branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Branch not found: " + branchId));
    }

    /**
     * WU egyenleg frissítése tranzakció után.
     */
    private void updateBalance(UUID branchId, BigDecimal amountUsd, BigDecimal amountHuf, boolean isSend) {
        WuBalance balance = wuBalanceRepository.findByBranchId(branchId)
                .orElseGet(() -> {
                    Branch branch = findBranch(branchId);
                    return WuBalance.builder()
                            .branch(branch)
                            .usdBalance(BigDecimal.ZERO)
                            .hufBalance(BigDecimal.ZERO)
                            .build();
                });

        if (isSend) {
            // Küldés: USD csökken (kifolyik), HUF nő (ügyfél befizeti HUF-ban)
            if (amountUsd != null) balance.setUsdBalance(balance.getUsdBalance().subtract(amountUsd));
            if (amountHuf != null) balance.setHufBalance(balance.getHufBalance().add(amountHuf));
        } else {
            // Fogadás: USD nő (befolyik), HUF csökken (ügyfélnek kifizetjük HUF-ban)
            if (amountUsd != null) balance.setUsdBalance(balance.getUsdBalance().add(amountUsd));
            if (amountHuf != null) balance.setHufBalance(balance.getHufBalance().subtract(amountHuf));
        }

        balance.setUpdatedAt(LocalDateTime.now());
        wuBalanceRepository.save(balance);
    }
}
