package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.CashLockOrdering;
import hu.puzzleir.valuta.util.HungarianRounding;
import hu.puzzleir.valuta.dto.pos.PosTransactionResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import hu.puzzleir.valuta.service.TransactionService.BuyRequest;
import hu.puzzleir.valuta.service.TransactionService.SellRequest;
import hu.puzzleir.valuta.service.TransactionService.LineRequest;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Multi-line tranzakciok kezelese (tobb valutasor egy bizonylaton).
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class TransactionMultiLineService {

    private final TransactionRepository transactionRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;
    private final CurrencyRepository currencyRepository;
    private final ExchangeRateService exchangeRateService;
    private final ReceiptSequenceService receiptSequenceService;
    private final HandlingFeeCalculator handlingFeeCalculator;
    private final HandlingFeeOverrideService handlingFeeOverrideService;
    private final AmlService amlService;
    private final CashBalanceRepository cashBalanceRepository;
    private final DailySessionService dailySessionService;
    private final PosTerminalService posTerminalService;
    private final TransactionOperationHelper helper;
    private final TransactionCalculationService calculationService;
    private final TransactionLineRepository transactionLineRepository;
    private final TransactionValidationService transactionValidationService;
    private final WacService wacService;

    /**
     * FK-KEZDÍJ (2026-06-02): a kezelési díj override jogosultság-ellenőrzéséhez a bejelentkezett
     * dolgozó operatív szerepköre (activeRole, fallback currentRole) — nem a kliensből.
     */
    private String currentWorkerRoleForOverride() {
        try {
            String active = SecurityUtils.getActiveOperationalRole();
            return (active != null && !active.isBlank()) ? active : SecurityUtils.getCurrentRole();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Multi-line vetel tranzakcio.
     */
    public Transaction executeMultiLineBuy(BuyRequest request) {
        helper.validateOpenSession();
        validateMultiLineRequest(request.getLines());

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem talalhato"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Penztaros nem talalhato"));

        // Kedvezmeny validalas
        if (request.getDiscountPercent() != null && request.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            calculationService.validateDiscount(request.getDiscountPercent());
        }

        // Elso sor valutaja a fejlec valutaja
        LineRequest firstLine = request.getLines().get(0);
        Long firstCurrencyId = helper.resolveCurrencyId(firstLine.getCurrencyId(), firstLine.getCurrencyCode());
        Currency firstCurrency = currencyRepository.findById(firstCurrencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem talalhato"));

        // Soronkenti feldolgozas: arfolyam + HUF szamitas
        BigDecimal totalHuf = BigDecimal.ZERO;
        BigDecimal totalCurrencyAmount = BigDecimal.ZERO;
        List<TransactionLine> transactionLines = new ArrayList<>();

        for (int i = 0; i < request.getLines().size(); i++) {
            final int lineIdx = i;
            LineRequest lineReq = request.getLines().get(i);
            Long lineCurrencyId = helper.resolveCurrencyId(lineReq.getCurrencyId(), lineReq.getCurrencyCode());
            Currency lineCurrency = currencyRepository.findById(lineCurrencyId)
                    .orElseThrow(() -> new ResourceNotFoundException("Valuta nem talalhato: sor " + (lineIdx + 1)));
            transactionValidationService.validateCurrencyExchangeable(lineCurrency);

            ExchangeRate lineRate = exchangeRateService.getCurrentRate(lineCurrencyId);
            BigDecimal appliedRate = calculationService.resolveBuyRate(lineRate, lineReq.getBanknoteCount(), lineReq.getCustomExchangeRate());

            TransactionLine line = TransactionLine.builder()
                    .lineNumber(lineIdx + 1)
                    .currency(lineCurrency)
                    .appliedRate(appliedRate)
                    .originalRate(lineRate.getBaseBuyRate())
                    .settlementRate(lineRate.getBaseBuyRate())
                    .banknoteCount(lineReq.getBanknoteCount())
                    .discountType(lineReq.getDiscountType() != null ? lineReq.getDiscountType() : 0)
                    .foreignStatus(resolveForeignStatus(lineReq.getForeignStatus(), request.getForeignStatus()))
                    .build();

            // Forint ertek szamitas (calculateHufValue hasznalja a currency entity-t)
            BigDecimal lineHuf = line.calculateHufValue();
            line.setHufValue(lineHuf);

            totalHuf = totalHuf.add(lineHuf);
            totalCurrencyAmount = totalCurrencyAmount.add(lineReq.getBanknoteCount());
            transactionLines.add(line);
        }

        // Kedvezmeny az osszes sorra
        BigDecimal hufAfterDiscount = calculationService.applyBuyDiscount(totalHuf, request.getDiscountPercent());

        // Kezelesi dij
        BigDecimal handlingFeeBase = handlingFeeCalculator.calculate(
                hufAfterDiscount, TransactionType.BUY, request.getHandlingFee(), branchId);
        // FK-KEZDÍJ (2026-06-02): kezelési díj override AUTORITATÍV validálása a multi-line ágon is.
        BigDecimal serverHandlingFee = (request.getHandlingFeeOverrideType() != null
                && request.getHandlingFeeOverrideType() != hu.puzzleir.valuta.entity.HandlingFeeOverrideType.NONE)
                ? handlingFeeOverrideService.resolveOverride(
                        handlingFeeBase, request.getHandlingFeeOverrideType(), request.getHandlingFeeOverrideReason(),
                        request.getCustomerCardNumber(), request.getHandlingFee(), currentWorkerRoleForOverride())
                : handlingFeeBase;
        BigDecimal grossAmount = handlingFeeCalculator.calculateBuyGross(hufAfterDiscount, serverHandlingFee);

        // Magyar 5 Ft kerekites
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // 300K+ ugyfelazonositas
        helper.validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // AML ellenorzes az aggregalt osszegre
        helper.performAmlCheck(payableAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), firstCurrency.getCode(), request.getCustomerNationality(),
                request.getApproverWorkerId(), request.getApprovalSessionId());

        // A3 (Pmt. 50M, b4-foglalo FR-16): 50M Ft feletti aggregált ügyletnél is kötelező a forrás-igazolás
        // (a single-line úttal egyezően). Flag-gated (default false). Így multi-line sem kerüli meg a gate-et.
        helper.enforceSourceOfFunds(payableAmount, request.getSourceOfFundsDocType(), request.getSourceOfFundsDocDate());

        // CASH-VS-CASH LOCK-ORDERING (deadlock-megelozes): a multi-line vetel a HUF-ot + minden tetelsor
        // devizajat mozgatja; ezeket GLOBALISAN egyseges, NOVEKVO currencyId sorrendben elo-lockoljuk a
        // keszlet-ellenorzes / soronkenti updateCashBalance ELOTT, egyezoen a BUY/SELL/sztorno aggal.
        // Igy tobb-devizas multi-line eseten sincs AB-BA deadlock. Lasd: CashLockOrdering.
        List<Long> buyLockCurrencyIds = new ArrayList<>();
        buyLockCurrencyIds.add(helper.getHufCurrencyId());
        for (TransactionLine line : transactionLines) {
            buyLockCurrencyIds.add(line.getCurrency().getId());
        }
        CashLockOrdering.lockInAscendingCurrencyOrder(branchId, helper::lockCashBalance,
                buyLockCurrencyIds.toArray(new Long[0]));

        // 2026-05-15 user-direktíva: BUY ágon a pénztár HUF készletet ellenőrizni KELL.
        // Multi-line vétel végén egyetlen HUF kifizetés a payableAmount-ra — ezt
        // kassza-egyenleg fedezi-e? Tilos negatív HUF készletre tranzakciót engedni.
        helper.validateCurrencyStock(branchId, helper.getHufCurrencyId(), payableAmount);

        // Bizonylat szam generalas
        String receiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.BUY);

        BigDecimal discountAmount = calculationService.calculateDiscountAmount(totalHuf, request.getDiscountPercent());

        // POS terminal kezeles
        PaymentMethod paymentMethod = request.getPaymentMethod() != null ? request.getPaymentMethod() : PaymentMethod.CASH;
        String posAuthCode = null;
        String posRefNumber = null;
        String posTerminalId = request.getPosTerminalId();

        if (paymentMethod == PaymentMethod.CARD) {
            if (posTerminalId == null || posTerminalId.isBlank()) {
                throw new ValidationException("Bankkartyas fizetesehez POS terminal azonosito kotelezony!");
            }
            PosTransactionResult posResult = posTerminalService.initiatePayment(
                    payableAmount, "HUF", posTerminalId);
            if (!posResult.approved()) {
                throw new ValidationException("Bankkartyas fizetés elutasitva: " + posResult.errorMessage());
            }
            posAuthCode = posResult.authorizationCode();
            posRefNumber = posResult.referenceNumber();
        }

        // Atlagos arfolyam a fejlechez (sulyozott atlag)
        BigDecimal avgRate = totalCurrencyAmount.compareTo(BigDecimal.ZERO) > 0
                ? totalHuf.divide(totalCurrencyAmount, 4, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        // Tranzakcio fejlec letrehozasa.
        // V226 (2026-05-14): foreignStatus tranzakcio-szinten — Sourcery P3 #587 DRY:
        // resolveTransactionForeignStatus helper egyseges request+lines feloldas.
        ForeignStatus txForeignStatus = resolveTransactionForeignStatus(request.getForeignStatus(), transactionLines);

        Transaction transaction = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.BUY)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(firstCurrency)
                .currencyAmount(totalCurrencyAmount)
                .sourceOfFunds(request.getSourceOfFunds())
                // A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum perzisztálása
                .sourceOfFundsDocType(request.getSourceOfFundsDocType())
                .sourceOfFundsDocDate(request.getSourceOfFundsDocDate())
                .customerIsPep(Boolean.TRUE.equals(request.getCustomerIsPep()))
                // V312 / FR-BSZUR-05: a jóváhagyás-session perzisztálása a bizonylat-ENGEDÉLYEZŐ lookuphoz
                .approvalSessionId(request.getApprovalSessionId())
                .exchangeRate(avgRate)
                .hufAmount(payableAmount)
                .handlingFee(serverHandlingFee)
                .handlingFeeBase(handlingFeeBase)
                .handlingFeeOverrideType(request.getHandlingFeeOverrideType())
                .handlingFeeOverrideReason(request.getHandlingFeeOverrideReason())
                .customerCardNumber(request.getCustomerCardNumber())
                .discountPercent(request.getDiscountPercent() != null ? request.getDiscountPercent() : BigDecimal.ZERO)
                .discountAmount(discountAmount)
                .roundingAmount(roundingDifference)
                .multiLine(true)
                .lineCount(request.getLines().size())
                .paymentMethod(paymentMethod)
                .posAuthorizationCode(posAuthCode)
                .posReferenceNumber(posRefNumber)
                .posTerminalId(posTerminalId)
                .customerId(request.getCustomerId())
                .customerName(request.getCustomerName())
                .customerAddress(request.getCustomerAddress())
                .customerDocumentNumber(request.getCustomerDocumentNumber())
                .customerNationality(request.getCustomerNationality())
                .foreignStatus(txForeignStatus)
                .notes(request.getNotes())
                .build();

        Transaction saved = transactionRepository.save(transaction);

        // Tetelsorok mentese
        for (TransactionLine line : transactionLines) {
            line.setTransaction(saved);
        }
        saved.getLines().addAll(transactionLines);
        saved = transactionRepository.save(saved);
        helper.linkCameraEvidence(saved);
        helper.flagHighRiskAfterBooking(request.getCustomerId());

        // Kassza frissites - soronkent valuta +, ossz HUF -
        for (TransactionLine line : transactionLines) {
            helper.updateCashBalance(branchId, line.getCurrency().getId(), line.getBanknoteCount(), true);
        }
        helper.updateCashBalance(branchId, helper.getHufCurrencyId(), payableAmount.negate(), false);

        // Napi statisztika
        dailySessionService.updateSessionStats(TransactionType.BUY, payableAmount, serverHandlingFee);

        log.info("Multi-line vetel: {} - {} sor, osszesen {} HUF (kerekites: {} Ft, dij: {} Ft)",
                receiptNumber, request.getLines().size(), payableAmount, roundingDifference, serverHandlingFee);

        return saved;
    }

    /**
     * Multi-line eladas tranzakcio.
     */
    public Transaction executeMultiLineSell(SellRequest request) {
        helper.validateOpenSession();
        validateMultiLineRequest(request.getLines());

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem talalhato"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Penztaros nem talalhato"));

        // Kedvezmeny validalas
        if (request.getDiscountPercent() != null && request.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            calculationService.validateDiscount(request.getDiscountPercent());
        }

        // Elso sor valutaja a fejlec valutaja
        LineRequest firstLine = request.getLines().get(0);
        Long firstCurrencyId = helper.resolveCurrencyId(firstLine.getCurrencyId(), firstLine.getCurrencyCode());
        Currency firstCurrency = currencyRepository.findById(firstCurrencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem talalhato"));

        BigDecimal totalHuf = BigDecimal.ZERO;
        BigDecimal totalCurrencyAmount = BigDecimal.ZERO;
        List<TransactionLine> transactionLines = new ArrayList<>();

        // CASH-VS-CASH LOCK-ORDERING (deadlock-megelozes): a multi-line eladas a HUF-ot + minden tetelsor
        // devizajat mozgatja. A soronkenti keszlet-ellenorzes (lenti validateCurrencyStock a ciklusban) mar
        // lockolna — ezert MAR ITT, a ciklus ELOTT GLOBALISAN egyseges, NOVEKVO currencyId sorrendben
        // elo-lockoljuk az osszes erintett cash_balance sort, egyezoen a BUY/SELL/sztorno aggal. Lasd:
        // CashLockOrdering.
        List<Long> sellLockCurrencyIds = new ArrayList<>();
        sellLockCurrencyIds.add(helper.getHufCurrencyId());
        for (LineRequest preLockLine : request.getLines()) {
            sellLockCurrencyIds.add(helper.resolveCurrencyId(preLockLine.getCurrencyId(), preLockLine.getCurrencyCode()));
        }
        CashLockOrdering.lockInAscendingCurrencyOrder(branchId, helper::lockCashBalance,
                sellLockCurrencyIds.toArray(new Long[0]));

        for (int i = 0; i < request.getLines().size(); i++) {
            final int lineIdx = i;
            LineRequest lineReq = request.getLines().get(i);
            Long lineCurrencyId = helper.resolveCurrencyId(lineReq.getCurrencyId(), lineReq.getCurrencyCode());
            Currency lineCurrency = currencyRepository.findById(lineCurrencyId)
                    .orElseThrow(() -> new ResourceNotFoundException("Valuta nem talalhato: sor " + (lineIdx + 1)));
            transactionValidationService.validateCurrencyExchangeable(lineCurrency);

            ExchangeRate lineRate = exchangeRateService.getCurrentRate(lineCurrencyId);
            BigDecimal appliedRate = calculationService.resolveSellRate(lineRate, lineReq.getBanknoteCount(), lineReq.getCustomExchangeRate());

            // Keszlet ellenorzes soronkent
            helper.validateCurrencyStock(branchId, lineCurrency.getId(), lineReq.getBanknoteCount());

            TransactionLine line = TransactionLine.builder()
                    .lineNumber(lineIdx + 1)
                    .currency(lineCurrency)
                    .appliedRate(appliedRate)
                    .originalRate(lineRate.getBaseSellRate())
                    .settlementRate(lineRate.getBaseSellRate())
                    .banknoteCount(lineReq.getBanknoteCount())
                    .discountType(lineReq.getDiscountType() != null ? lineReq.getDiscountType() : 0)
                    .foreignStatus(resolveForeignStatus(lineReq.getForeignStatus(), request.getForeignStatus()))
                    .build();

            BigDecimal lineHuf = line.calculateHufValue();
            line.setHufValue(lineHuf);

            totalHuf = totalHuf.add(lineHuf);
            totalCurrencyAmount = totalCurrencyAmount.add(lineReq.getBanknoteCount());
            transactionLines.add(line);
        }

        // Kedvezmeny az osszes sorra
        BigDecimal hufAfterDiscount = calculationService.applySellDiscount(totalHuf, request.getDiscountPercent());

        // Kezelesi dij
        BigDecimal handlingFeeBase = handlingFeeCalculator.calculate(
                hufAfterDiscount, TransactionType.SELL, request.getHandlingFee(), branchId);
        // FK-KEZDÍJ (2026-06-02): kezelési díj override AUTORITATÍV validálása a multi-line ágon is.
        BigDecimal serverHandlingFee = (request.getHandlingFeeOverrideType() != null
                && request.getHandlingFeeOverrideType() != hu.puzzleir.valuta.entity.HandlingFeeOverrideType.NONE)
                ? handlingFeeOverrideService.resolveOverride(
                        handlingFeeBase, request.getHandlingFeeOverrideType(), request.getHandlingFeeOverrideReason(),
                        request.getCustomerCardNumber(), request.getHandlingFee(), currentWorkerRoleForOverride())
                : handlingFeeBase;
        BigDecimal grossAmount = handlingFeeCalculator.calculateSellGross(hufAfterDiscount, serverHandlingFee);

        // Magyar 5 Ft kerekites
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // 300K+ ugyfelazonositas
        helper.validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // AML ellenorzes
        helper.performAmlCheck(payableAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), firstCurrency.getCode(), request.getCustomerNationality(),
                request.getApproverWorkerId(), request.getApprovalSessionId());

        // A3 (Pmt. 50M, b4-foglalo FR-16): 50M Ft feletti aggregált ügyletnél is kötelező a forrás-igazolás
        // (a single-line úttal egyezően). Flag-gated (default false). Így multi-line sem kerüli meg a gate-et.
        helper.enforceSourceOfFunds(payableAmount, request.getSourceOfFundsDocType(), request.getSourceOfFundsDocDate());

        String receiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.SELL);
        BigDecimal discountAmount = calculationService.calculateDiscountAmount(totalHuf, request.getDiscountPercent());

        // POS terminal kezeles
        PaymentMethod paymentMethod = request.getPaymentMethod() != null ? request.getPaymentMethod() : PaymentMethod.CASH;
        String posAuthCode = null;
        String posRefNumber = null;
        String posTerminalId = request.getPosTerminalId();

        if (paymentMethod == PaymentMethod.CARD) {
            if (posTerminalId == null || posTerminalId.isBlank()) {
                throw new ValidationException("Bankkartyas fizetesehez POS terminal azonosito kotelezony!");
            }
            PosTransactionResult posResult = posTerminalService.initiatePayment(
                    payableAmount, "HUF", posTerminalId);
            if (!posResult.approved()) {
                throw new ValidationException("Bankkartyas fizetés elutasitva: " + posResult.errorMessage());
            }
            posAuthCode = posResult.authorizationCode();
            posRefNumber = posResult.referenceNumber();
        }

        BigDecimal avgRate = totalCurrencyAmount.compareTo(BigDecimal.ZERO) > 0
                ? totalHuf.divide(totalCurrencyAmount, 4, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        // V226 (2026-05-14): foreignStatus tranzakcio-szinten — request explicit erteke vagy az
        // elso tetel devizastatusza. Lasd processBuy ugyanazon logika.
        ForeignStatus txForeignStatus = resolveForeignStatus(null, request.getForeignStatus());
        if (txForeignStatus == null && !transactionLines.isEmpty()) {
            txForeignStatus = transactionLines.get(0).getForeignStatus();
        }

        Transaction transaction = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.SELL)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(firstCurrency)
                .currencyAmount(totalCurrencyAmount)
                .sourceOfFunds(request.getSourceOfFunds())
                // A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum perzisztálása
                .sourceOfFundsDocType(request.getSourceOfFundsDocType())
                .sourceOfFundsDocDate(request.getSourceOfFundsDocDate())
                .customerIsPep(Boolean.TRUE.equals(request.getCustomerIsPep()))
                // V312 / FR-BSZUR-05: a jóváhagyás-session perzisztálása a bizonylat-ENGEDÉLYEZŐ lookuphoz
                .approvalSessionId(request.getApprovalSessionId())
                .exchangeRate(avgRate)
                .hufAmount(payableAmount)
                .handlingFee(serverHandlingFee)
                .handlingFeeBase(handlingFeeBase)
                .handlingFeeOverrideType(request.getHandlingFeeOverrideType())
                .handlingFeeOverrideReason(request.getHandlingFeeOverrideReason())
                .customerCardNumber(request.getCustomerCardNumber())
                .discountPercent(request.getDiscountPercent() != null ? request.getDiscountPercent() : BigDecimal.ZERO)
                .discountAmount(discountAmount)
                .roundingAmount(roundingDifference)
                .multiLine(true)
                .lineCount(request.getLines().size())
                .paymentMethod(paymentMethod)
                .posAuthorizationCode(posAuthCode)
                .posReferenceNumber(posRefNumber)
                .posTerminalId(posTerminalId)
                .customerId(request.getCustomerId())
                .customerName(request.getCustomerName())
                .customerAddress(request.getCustomerAddress())
                .customerDocumentNumber(request.getCustomerDocumentNumber())
                .customerNationality(request.getCustomerNationality())
                .foreignStatus(txForeignStatus)
                .notes(request.getNotes())
                .build();

        Transaction saved = transactionRepository.save(transaction);

        // Tetelsorok mentese
        for (TransactionLine line : transactionLines) {
            line.setTransaction(saved);
        }
        saved.getLines().addAll(transactionLines);
        saved = transactionRepository.save(saved);
        helper.linkCameraEvidence(saved);
        helper.flagHighRiskAfterBooking(request.getCustomerId());

        // Kassza frissites - soronkent valuta -, ossz HUF +
        for (TransactionLine line : transactionLines) {
            helper.updateCashBalance(branchId, line.getCurrency().getId(), line.getBanknoteCount().negate(), false);
        }
        helper.updateCashBalance(branchId, helper.getHufCurrencyId(), payableAmount, true);

        // A6 / b8 FR-8: soronkenti realizalt profit best-effort rogzitese a tranzakcio COMMITJA
        // UTAN (flag-gated, cold-start-safe, read-only a keszleten). Egysoros executeSell-lel egyezo
        // logika. A tranzakcio-szintu kedvezmenyt soronkent atadjuk (uniform % a teljes osszegre).
        // Az afterCommit garantalja, hogy a profit_log CSAK sikeres eladas utan irodjon (nincs
        // orphan rollback eseten) es a best-effort iras SOHA ne torje meg az eladast.
        final Transaction savedTx = saved;
        for (TransactionLine line : transactionLines) {
            final TransactionLine l = line;
            TransactionAfterCommit.run(
                    () -> wacService.recordSellProfitIfEnabled(branchId, savedTx.getId(), l.getCurrency().getCode(),
                            l.getBanknoteCount(), l.getAppliedRate(), request.getDiscountPercent()),
                    "WAC multi-line sell profit tx=" + savedTx.getId() + " " + l.getCurrency().getCode());
        }

        // Napi statisztika
        dailySessionService.updateSessionStats(TransactionType.SELL, payableAmount, serverHandlingFee);

        log.info("Multi-line eladas: {} - {} sor, osszesen {} HUF (kerekites: {} Ft, dij: {} Ft)",
                receiptNumber, request.getLines().size(), payableAmount, roundingDifference, serverHandlingFee);

        return saved;
    }

    /**
     * Multi-line request validacio.
     */
    private void validateMultiLineRequest(java.util.List<LineRequest> lines) {
        if (lines == null || lines.isEmpty()) {
            throw new ValidationException("Multi-line bizonylathoz legalabb egy tetelsor szukseges!");
        }
        if (lines.size() > helper.getMaxTransactionLines()) {
            throw new ValidationException(
                String.format("Egy bizonylaton maximum %d tetelsor lehet (BLOKKTETEL limit)!", helper.getMaxTransactionLines()));
        }
        for (int i = 0; i < lines.size(); i++) {
            LineRequest line = lines.get(i);
            if (line.getBanknoteCount() == null || line.getBanknoteCount().compareTo(BigDecimal.ZERO) <= 0) {
                throw new ValidationException(
                    String.format("Tetelsor %d: bankjegy darabszam kotelezo es pozitiv kell legyen!", i + 1));
            }
            if ((line.getCurrencyId() == null || line.getCurrencyId() <= 0)
                    && (line.getCurrencyCode() == null || line.getCurrencyCode().isBlank())) {
                throw new ValidationException(
                    String.format("Tetelsor %d: valuta azonosito (currencyId) vagy kod (currencyCode) kotelezo!", i + 1));
            }
        }
    }

    /**
     * Tranzakcio tetelsorainak lekerdezese.
     */
    @Transactional(readOnly = true)
    public java.util.List<TransactionLine> getTransactionLines(Long transactionId) {
        return transactionLineRepository.findByTransactionIdOrderByLineNumber(transactionId);
    }

    /**
     * Devizastatusz feloldas: tetel-szintu ertek -> parent request ertek -> NULL (default).
     *
     * <p>V226 (2026-05-14): tetelenkent kulonbozo devizastatusz lehet egy bizonylaton belul.
     * Ha a tetel-szintu ertek NULL, a parent request foreignStatus orokitt at. Case-insensitive
     * normalizalas (DOMESTIC/FOREIGN), invalid ertek -> NULL + warning log.</p>
     */
    private static ForeignStatus resolveForeignStatus(String lineLevel, String parentLevel) {
        String effective = (lineLevel != null && !lineLevel.isBlank()) ? lineLevel : parentLevel;
        if (effective == null || effective.isBlank()) return null;
        try {
            return ForeignStatus.valueOf(effective.toUpperCase(java.util.Locale.ROOT));
        } catch (IllegalArgumentException ex) {
            // Sourcery P3 #587: invalid ertek loggolva (DTO @Pattern validacionak elobb meg kell
            // fognia, de defenziven jelezzuk legacy kliens / manualis DB edit eseten).
            log.warn("Invalid foreignStatus value '{}' encountered, normalized to NULL", effective);
            return null;
        }
    }

    /**
     * Tranzakcio-szintu foreignStatus feloldas (Sourcery P3 #587 DRY helper).
     *
     * <p>Logika:
     * <ol>
     *   <li>Request explicit erteke (ha nem ures es valid)</li>
     *   <li>Else: elso tetel devizastatusza</li>
     *   <li>Else: NULL (Hibernate enum-null OK, Transaction.foreignStatus nullable)</li>
     * </ol></p>
     *
     * @param requestLevel a parent BuyRequest/SellRequest foreignStatus String erteke
     * @param transactionLines a feldolgozott tetel-listai (mar resolveForeignStatus-szal feltoltve)
     * @return effektiv tranzakcio-szintu ForeignStatus, vagy NULL
     */
    private static ForeignStatus resolveTransactionForeignStatus(
            String requestLevel,
            List<TransactionLine> transactionLines) {
        ForeignStatus fromRequest = resolveForeignStatus(null, requestLevel);
        if (fromRequest != null) return fromRequest;
        if (transactionLines != null && !transactionLines.isEmpty()) {
            return transactionLines.get(0).getForeignStatus();
        }
        return null;
    }
}