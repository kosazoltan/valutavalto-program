package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.dto.pos.PosTransactionResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import hu.puzzleir.valuta.service.TransactionService.ReversalRequest;
import hu.puzzleir.valuta.service.TransactionService.PartialRefundRequest;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

/**
 * Sztorno es reszleges visszaterites tranzakciok kezelese.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class TransactionReversalService {

    private final TransactionRepository transactionRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;
    private final ReceiptSequenceService receiptSequenceService;
    private final DailySessionService dailySessionService;
    private final PosTerminalService posTerminalService;
    private final AmlService amlService;
    private final CashBalanceRepository cashBalanceRepository;
    private final TransactionOperationHelper helper;

    /**
     * Sztorno vegrehajtasa.
     */
    public Transaction executeReversal(ReversalRequest request) {
        helper.validateOpenSession();

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Eredeti tranzakcio lekerese
        Transaction original = transactionRepository.findById(request.getOriginalTransactionId())
                .orElseThrow(() -> new ResourceNotFoundException("Eredeti tranzakcio nem talalhato"));

        // Validaciok
        if (original.isReversed()) {
            throw new ValidationException("Ez a tranzakcio mar sztornozva lett!");
        }
        if (original.isReversal()) {
            throw new ValidationException("Sztorno tranzakcio nem sztornozhatoh!");
        }
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Csak sajat iroda tranzakciojat lehet sztornozni!");
        }
        // Csak aznapi tranzakcio sztornozhatoh supervisor nelkul
        if (!original.getTransactionDate().equals(LocalDate.now()) && !SecurityUtils.isSupervisorOrAbove()) {
            throw new ValidationException("Korabbi napi tranzakcio sztornozasahoz supervisor jovahagyas szukseges!");
        }

        // Napi sztorno limit ellenorzese
        int dailyReversals = dailySessionService.getDailyReversalCount();
        if (dailyReversals >= helper.getDailyReversalLimit() && !SecurityUtils.isSupervisorOrAbove()) {
            throw new ValidationException(
                String.format("Napi sztorno limit (%d) elerve! Supervisor jovahagyas szukseges.", helper.getDailyReversalLimit()));
        }

        // Entitasok betoltese
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem talalhato"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Penztaros nem talalhato"));

        // POS terminal sztorno - ha az eredeti tranzakcio bankkartyas volt
        String posAuthCode = null;
        String posRefNumber = null;
        if (original.getPaymentMethod() == PaymentMethod.CARD
                && original.getPosTerminalId() != null && !original.getPosTerminalId().isBlank()) {
            String originalPosRef = original.getPosReferenceNumber() != null
                    ? original.getPosReferenceNumber()
                    : original.getReceiptNumber();
            PosTransactionResult posResult = posTerminalService.initiateReversal(
                    originalPosRef, original.getPosTerminalId());
            if (!posResult.approved()) {
                throw new ValidationException("POS sztorno elutasitva: " + posResult.errorMessage());
            }
            posAuthCode = posResult.authorizationCode();
            posRefNumber = posResult.referenceNumber();
            log.info("POS sztorno elfogadva: auth={}, ref={}", posAuthCode, posRefNumber);
        }

        // Bizonylat szam generalas - az EREDETI tpus szamlalojabol (NEM kuzon S prefix!)
        String receiptNumber = receiptSequenceService.generateReversalReceiptNumber(
                branchId, original.getTransactionType());

        // Sztorno tranzakcio letrehozasa (ellentetes ertekekkel)
        Transaction reversal = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.REVERSAL)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(original.getCurrency())
                .currencyAmount(original.getCurrencyAmount())
                .exchangeRate(original.getExchangeRate())
                .hufAmount(original.getHufAmount())
                .handlingFee(original.getHandlingFee())
                .discountPercent(original.getDiscountPercent())
                .discountAmount(original.getDiscountAmount())
                .roundingAmount(original.getRoundingAmount())
                .paymentMethod(original.getPaymentMethod())
                .posAuthorizationCode(posAuthCode)
                .posReferenceNumber(posRefNumber)
                .posTerminalId(original.getPosTerminalId())
                .originalTransaction(original)
                .reversalReason(request.getReason())
                .approvedBy(request.getApprovedBy())
                .customerName(original.getCustomerName())
                .customerDocumentNumber(original.getCustomerDocumentNumber())
                .notes("Sztorno: " + original.getReceiptNumber() + " - " + request.getReason())
                .build();

        Transaction savedReversal = transactionRepository.save(reversal);
        helper.linkCameraEvidence(savedReversal);

        // Eredeti tranzakcio statuszanak frissitese
        original.setStatus(TransactionStatus.REVERSED);
        transactionRepository.save(original);

        // Kassza visszaallitasa (eredeti tranzakcio ellentete)
        Long currencyId = original.getCurrency().getId();
        if (original.getTransactionType() == TransactionType.BUY) {
            // Eredeti vetel visszavonasa: valuta -, HUF +
            // Stock validation: van-e eleg valuta a kasszaban a visszavethez
            helper.validateCurrencyStock(branchId, currencyId, original.getCurrencyAmount());
            helper.updateCashBalance(branchId, currencyId, original.getCurrencyAmount().negate(), false);
            helper.updateCashBalance(branchId, helper.getHufCurrencyId(), original.getHufAmount(), true);
        } else if (original.getTransactionType() == TransactionType.SELL) {
            // Eredeti eladas visszavonasa: valuta +, HUF -
            helper.updateCashBalance(branchId, currencyId, original.getCurrencyAmount(), true);
            helper.updateCashBalance(branchId, helper.getHufCurrencyId(), original.getHufAmount().negate(), false);
        }

        // Napi statisztika frissitese
        dailySessionService.updateSessionStats(
            TransactionType.REVERSAL,
            original.getHufAmount(),
            BigDecimal.ZERO
        );

        // AML gonyolodes visszavonasa (ha van ugyfel ID)
        if (original.getCustomerId() != null && !original.getCustomerId().isBlank()) {
            amlService.reverseAccumulation(
                original.getCustomerId(),
                original.getHufAmount(),
                original.getTransactionDate().atTime(original.getTransactionTime())
            );
        }

        log.info("Sztorno tranzakcio: {} - eredeti: {} - ok: {}",
                receiptNumber, original.getReceiptNumber(), request.getReason());

        return savedReversal;
    }

    /**
     * Reszleges visszaterites vegrehajtasa.
     */
    public Transaction executePartialRefund(PartialRefundRequest request) {
        helper.validateOpenSession();

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Eredeti tranzakcio lekerese
        Transaction original = transactionRepository.findById(request.getOriginalTransactionId())
                .orElseThrow(() -> new ResourceNotFoundException("Eredeti tranzakcio nem talalhato"));

        // Validaciok
        if (original.isReversed()) {
            throw new ValidationException("Ez a tranzakcio mar sztornozva lett - reszleges visszaterites nem lehetséges!");
        }
        if (original.isReversal() || original.isPartialRefund()) {
            throw new ValidationException("Visszavonasi tranzakcio nem vonhato vissza reszlegesen!");
        }
        if (!original.getBranch().getId().equals(branchId)) {
            throw new ValidationException("Csak sajat iroda tranzakciojat lehet visszateriteni!");
        }

        BigDecimal refundHuf = request.getRefundHufAmount();
        if (refundHuf == null || refundHuf.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("Visszaterites osszege pozitiv kell legyen!");
        }
        if (refundHuf.compareTo(original.getHufAmount()) > 0) {
            throw new ValidationException(
                String.format("Visszaterites osszege (%s Ft) nem haladhatja meg az eredeti osszeget (%s Ft)!",
                    refundHuf.toPlainString(), original.getHufAmount().toPlainString()));
        }

        // Aryonos valutaosszeg kiszamitasa, ha nem adtak meg
        BigDecimal refundCurrency = request.getRefundCurrencyAmount();
        if (refundCurrency == null || refundCurrency.compareTo(BigDecimal.ZERO) <= 0) {
            if (original.getHufAmount().compareTo(BigDecimal.ZERO) > 0) {
                // arany: refundCurrency = originalCurrency * (refundHuf / originalHuf)
                refundCurrency = original.getCurrencyAmount()
                        .multiply(refundHuf)
                        .divide(original.getHufAmount(), 4, RoundingMode.HALF_UP);
            } else {
                refundCurrency = BigDecimal.ZERO;
            }
        }

        // Entitasok betoltese
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem talalhato"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Penztaros nem talalhato"));

        // Bizonylat szam generalas (az eredeti tpus szamlalojabol)
        String receiptNumber = receiptSequenceService.generateReversalReceiptNumber(
                branchId, original.getTransactionType());

        // Reszleges visszateritesi tranzakcio letrehozasa
        Transaction partialRefund = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.PARTIAL_REFUND)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(original.getCurrency())
                .currencyAmount(refundCurrency)
                .exchangeRate(original.getExchangeRate())
                .hufAmount(refundHuf)
                .paymentMethod(original.getPaymentMethod())
                .originalTransaction(original)
                .partialRefundAmount(refundHuf)
                .reversalReason(request.getReason())
                .approvedBy(request.getApprovedBy())
                .customerName(original.getCustomerName())
                .customerDocumentNumber(original.getCustomerDocumentNumber())
                .notes("Reszleges visszaterites: " + original.getReceiptNumber()
                        + " - " + refundHuf.toPlainString() + " Ft - " + request.getReason())
                .build();

        Transaction saved = transactionRepository.save(partialRefund);
        helper.linkCameraEvidence(saved);

        // Kassza korrekcio: csak a visszateritett osszeggel
        Long currencyId = original.getCurrency().getId();
        if (original.getTransactionType() == TransactionType.BUY) {
            // Eredeti vetel reszleges visszavonasa: valuta -, HUF +
            // Stock validation: van-e eleg valuta a kasszaban a reszleges visszavethez
            helper.validateCurrencyStock(branchId, currencyId, refundCurrency);
            helper.updateCashBalance(branchId, currencyId, refundCurrency.negate(), false);
            helper.updateCashBalance(branchId, helper.getHufCurrencyId(), refundHuf, true);
        } else if (original.getTransactionType() == TransactionType.SELL) {
            // Eredeti eladas reszleges visszavonasa: valuta +, HUF -
            helper.updateCashBalance(branchId, currencyId, refundCurrency, true);
            helper.updateCashBalance(branchId, helper.getHufCurrencyId(), refundHuf.negate(), false);
        }

        // Napi statisztika frissitese
        dailySessionService.updateSessionStats(
            TransactionType.PARTIAL_REFUND,
            refundHuf,
            BigDecimal.ZERO
        );

        log.info("Reszleges visszaterites: {} - eredeti: {} - osszeg: {} Ft - ok: {}",
                receiptNumber, original.getReceiptNumber(), refundHuf.toPlainString(), request.getReason());

        return saved;
    }
}
