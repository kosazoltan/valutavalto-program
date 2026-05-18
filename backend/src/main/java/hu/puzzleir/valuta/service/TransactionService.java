package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.transaction.CashierCustomRateQuotaDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.logging.VVLogger;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.dto.pos.PosResultStatus;
import hu.puzzleir.valuta.dto.pos.PosTransactionResult;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.annotation.PostConstruct;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/**
 * NOTE: Calculation logic (rate resolution, discount, HUF amount) delegated to
 * {@link TransactionCalculationService}.  Validation helpers (identification,
 * AML, stock, session, multi-line) delegated to
 * {@link TransactionValidationService}.  Export logic lives in
 * {@link TransactionExportService}.
 */

/**
 * Tranzakció szolgáltatás.
 *
 * Legacy: VASARLAS.DLL, ELADAS.DLL, STORNO.DLL funkciók
 * - Vétel: Ügyfél valutát ad el, cég HUF-ot ad
 * - Eladás: Ügyfél HUF-ot ad, cég valutát ad
 * - Sztornó: Korábbi tranzakció visszavonása
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TransactionService {

    // V234 belso log+audit modul - strukturalt error code-szintu log
    private static final VVLogger VV_LOG = VVLogger.of(TransactionService.class);

    private final TransactionRepository transactionRepository;
    private final TransactionLineRepository transactionLineRepository;
    private final CurrencyRepository currencyRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final WorkerRepository workerRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final DailySessionService dailySessionService;
    private final ExchangeRateService exchangeRateService;
    private final ReceiptSequenceService receiptSequenceService;
    private final HandlingFeeCalculator handlingFeeCalculator;
    private final AmlService amlService;
    private final PosTerminalService posTerminalService;
    private final ObjectProvider<CameraTransactionLinker> cameraTransactionLinkerProvider;
    private final TransactionCalculationService calculationService;

    // Delegate services — @Lazy to avoid circular dependency (they import inner DTOs from this class)
    private final @org.springframework.context.annotation.Lazy TransactionReversalService reversalService;
    private final @org.springframework.context.annotation.Lazy TransactionConversionService conversionService;
    private final @org.springframework.context.annotation.Lazy TransactionMultiLineService multiLineService;
    private final LicenseService licenseService;
    private final SystemParameterService systemParameterService;

    // Sztornó limit supervisor nélkül (3 db/nap)
    private static final int DAILY_REVERSAL_LIMIT = 3;

    /**
     * Licenc ellenőrzés — tranzakció csak érvényes licenccel engedélyezett (P0-6 fix).
     */
    private void validateActiveLicense() {
        var status = licenseService.validateLicense();
        if (!"VALID".equals(status.getStatus())) {
            throw new ValidationException("Tranzakció nem engedélyezett — licenc státusz: " + status.getStatus()
                    + ". Kérjük, vegye fel a kapcsolatot az adminisztrátorral.");
        }
    }

    // Azonosítás nélküli limit HUF-ban (300.000 Ft - NAV szabályozás)
    private static final BigDecimal IDENTIFICATION_LIMIT = new BigDecimal("300000");

    // Max tetelsorok szama bizonylaton (Legacy: BLOKKTETEL limit)
    private static final int MAX_TRANSACTION_LINES = 6;

    // HUF currency ID cache - startup-kor betöltve, ne kelljen minden tranzakciónál DB-t kérdezni
    private volatile Long cachedHufCurrencyId;

    @PostConstruct
    void initHufCurrencyId() {
        try {
            cachedHufCurrencyId = currencyRepository.findByCode("HUF")
                    .map(c -> c.getId())
                    .orElse(null);
            if (cachedHufCurrencyId != null) {
                log.info("HUF currency ID cached: {}", cachedHufCurrencyId);
            } else {
                log.warn("HUF currency not found in DB - cash balance operations may fail until seeded");
            }
        } catch (Exception e) {
            VV_LOG.error("VV-TECH-003", "currency.huf.cache_failed", e,
                    java.util.Map.of("startup_phase", "PostConstruct"));
            cachedHufCurrencyId = null;
        }
    }

    private void linkCameraEvidence(Transaction transaction) {
        if (cameraTransactionLinkerProvider == null) {
            return;
        }

        CameraTransactionLinker linker = cameraTransactionLinkerProvider.getIfAvailable();
        if (linker == null || transaction == null || transaction.getId() == null || transaction.getBranch() == null) {
            return;
        }

        LocalDate txDate = transaction.getTransactionDate();
        LocalTime txTime = transaction.getTransactionTime();
        if (txDate == null || txTime == null) {
            log.debug("Kamera linkeles kihagyva hianyzo datum/ido miatt: tx={}", transaction.getId());
            return;
        }

        try {
            linker.linkTransaction(
                    transaction.getId(),
                    transaction.getBranch().getId(),
                    txDate.atTime(txTime),
                    transaction.getReceiptNumber());
        } catch (Exception e) {
            VV_LOG.error("VV-TECH-004", "transaction.camera_link_failed", e,
                    java.util.Map.of("tx_id", transaction.getId(),
                            "receipt_number", transaction.getReceiptNumber(),
                            "branch_id", transaction.getBranch().getId()));
        }
    }

    /**
     * Vétel tranzakció végrehajtása
     * (Ügyfél valutát ad el, cég HUF-ot fizet)
     *
     * Legacy: VASARLAS.DLL - VETEL funkció
     */
    @Transactional(rollbackFor = Exception.class)
    public Transaction executeBuy(BuyRequest request) {
        // Multi-line delegalas ha vannak tetelsorok
        if (request.getLines() != null && !request.getLines().isEmpty()) {
            return executeMultiLineBuy(request);
        }

        validateActiveLicense();
        validateOpenSession();

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Entitások betöltése
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));
        Long currencyId = resolveCurrencyId(request.getCurrencyId(), request.getCurrencyCode());
        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található"));

        // Ürfolyam meghatározása
        ExchangeRate rate = exchangeRateService.getCurrentRate(currencyId);

        // Kedvezmény validálás (ELŐBB, mielőtt bármilyen számítás történne)
        if (request.getDiscountPercent() != null && request.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            calculationService.validateDiscount(request.getDiscountPercent());
        }

        BigDecimal appliedRate = calculationService.resolveBuyRate(rate, request.getCurrencyAmount(), request.getCustomExchangeRate());
        BigDecimal fullHufBeforeDiscount = request.getCurrencyAmount()
            .multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);
        BigDecimal hufAmount = calculationService.applyBuyDiscount(fullHufBeforeDiscount, request.getDiscountPercent());

        // Kezelési díj szerver oldali számítás (kliens értékét felülírjuk)
        BigDecimal serverHandlingFee = handlingFeeCalculator.calculate(
                hufAmount, TransactionType.BUY, request.getHandlingFee());

        // Bruttó: vételnél nettó - díj (a cég levonja a kezelési díjat)
        BigDecimal grossAmount = handlingFeeCalculator.calculateBuyGross(hufAmount, serverHandlingFee);

        // Magyar 5 Ft-os kerekítés a fizetendő összegre
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // 300K+ tranzakcio eseten ugyfelazonositas kotelezo.
        validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // Sourcery #612: JOGCIM nyilatkozat validacio (FALSE -> actorName kotelezo)
        validateJogcimDeclaration(request.getCustomerOnOwnBehalf(), request.getCustomerActorName());

        // 2026-05-15 user-direktíva: BUY ágon a pénztár HUF készletet ellenőrizni KELL
        // (vételnél a cég HUF-ot fizet ki az ügyfélnek). Korábban csak SELL ágon volt
        // készlet-ellenőrzés (foreign currency), ezért negatív HUF egyenlegre is
        // engedett tranzakciót — ez TILOS mind a pénztárban, mind az értéktárban.
        validateCurrencyStock(branchId, getHufCurrencyId(), payableAmount);

        // 2026-05-13 v2.5.49+ (Codex P1 #562/#564): pénztárosi sáv napi kvóta backend enforcement + normalizálás
        boolean buyCashierCustomRate = validateAndNormalizeCashierCustomRateQuota(
                Boolean.TRUE.equals(request.getCashierCustomRate()), payableAmount);

        // AML ellenőrzés (Pmt. 2017. évi LIII. tv.) — flagek a Transaction-be CB-018 szerint
        AmlService.AmlBasicCheckResult amlResult = performAmlCheck(
                payableAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), currency.getCode());

        // Bizonylat szám generálása (új szekvencia rendszer)
        String receiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.BUY);

        // Kedvezmény összeg a PRE-DISCOUNT értékből (nem a már csökkentett hufAmount-ból!)
        BigDecimal discountAmount = calculationService.calculateDiscountAmount(fullHufBeforeDiscount, request.getDiscountPercent());

        // POS terminál integráció - bankkártyás fizetésnél
        PaymentMethod paymentMethod = request.getPaymentMethod() != null ? request.getPaymentMethod() : PaymentMethod.CASH;
        String posAuthCode = null;
        String posRefNumber = null;
        String posTerminalId = request.getPosTerminalId();

        if (paymentMethod == PaymentMethod.CARD) {
            if (posTerminalId == null || posTerminalId.isBlank()) {
                throw new ValidationException("Bankkártyás fizetéshez POS terminál azonosító kötelező!");
            }
            PosTransactionResult posResult = posTerminalService.initiatePayment(
                    payableAmount, "HUF", posTerminalId);
            if (!posResult.approved()) {
                throw new ValidationException("Bankkártyás fizetés elutasítva: " + posResult.errorMessage());
            }
            posAuthCode = posResult.authorizationCode();
            posRefNumber = posResult.referenceNumber();
            log.info("POS fizetés elfogadva: auth={}, ref={}", posAuthCode, posRefNumber);
        }

        // Tranzakció létrehozása
        Transaction transaction = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.BUY)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(currency)
                .currencyAmount(request.getCurrencyAmount())
                .exchangeRate(appliedRate)
                .hufAmount(payableAmount)
                .handlingFee(serverHandlingFee)
                .discountPercent(request.getDiscountPercent() != null ? request.getDiscountPercent() : BigDecimal.ZERO)
                .discountAmount(discountAmount)
                .roundingAmount(roundingDifference)
                .paymentMethod(paymentMethod)
                .posAuthorizationCode(posAuthCode)
                .posReferenceNumber(posRefNumber)
                .posTerminalId(posTerminalId)
                .customerId(request.getCustomerId())
                .customerName(request.getCustomerName())
                .customerAddress(request.getCustomerAddress())
                .customerDocumentNumber(request.getCustomerDocumentNumber())
                .customerNationality(request.getCustomerNationality())
                .sourceOfFunds(request.getSourceOfFunds())
                .customerIsPep(Boolean.TRUE.equals(request.getCustomerIsPep()))
                // V229 Pmt. snapshot (HIBA #5+#7+#8)
                .customerBirthPlace(request.getCustomerBirthPlace())
                .customerBirthDate(request.getCustomerBirthDate())
                .customerMotherName(request.getCustomerMotherName())
                .customerDocumentType(request.getCustomerDocumentType())
                .customerOnOwnBehalf(request.getCustomerOnOwnBehalf())
                .customerActorName(request.getCustomerActorName())
                .amlSuspicious(amlResult.isSuspiciousFlag())
                .amlAnnualLimitReached(amlResult.isAnnualLimitReached())
                .notes(request.getNotes())
                .cashierCustomRate(buyCashierCustomRate)
                .foreignStatus(ForeignStatus.parseOrNull(request.getForeignStatus()))
                .build();

        Transaction saved = transactionRepository.save(transaction);
        linkCameraEvidence(saved);

        // Kassza frissítése - HUF csökken, valuta nő
        updateCashBalance(branchId, currency.getId(), request.getCurrencyAmount(), true);  // valuta +
        updateCashBalance(branchId, getHufCurrencyId(), payableAmount.negate(), false);    // HUF -

        // Napi statisztika frissítése
        dailySessionService.updateSessionStats(
            TransactionType.BUY,
            payableAmount,
            transaction.getHandlingFee()
        );

        log.info("Vétel tranzakció: {} - {} {} @ {} = {} HUF (kerekítés: {} Ft, díj: {} Ft)",
                receiptNumber, request.getCurrencyAmount(), currency.getCode(),
                appliedRate, payableAmount, roundingDifference, serverHandlingFee);

        return saved;
    }

    /**
     * Eladás tranzakció végrehajtása
     * (Ügyfél HUF-ot ad, cég valutát ad)
     *
     * Legacy: ELADAS.DLL - ELADAS funkció
     */
    @Transactional(rollbackFor = Exception.class)
    public Transaction executeSell(SellRequest request) {
        // Multi-line delegalas ha vannak tetelsorok
        if (request.getLines() != null && !request.getLines().isEmpty()) {
            return executeMultiLineSell(request);
        }

        validateActiveLicense();
        validateOpenSession();

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Entitások betöltése
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található"));
        Long currencyId = resolveCurrencyId(request.getCurrencyId(), request.getCurrencyCode());
        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található"));

        // Ürfolyam meghatározása
        ExchangeRate rate = exchangeRateService.getCurrentRate(currencyId);

        // Kedvezmény validálás (ELŐBB, mielőtt bármilyen számítás történne)
        if (request.getDiscountPercent() != null && request.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            calculationService.validateDiscount(request.getDiscountPercent());
        }

        BigDecimal appliedRate = calculationService.resolveSellRate(rate, request.getCurrencyAmount(), request.getCustomExchangeRate());
        BigDecimal fullHufBeforeDiscount = request.getCurrencyAmount()
            .multiply(appliedRate).setScale(0, RoundingMode.HALF_UP);
        BigDecimal hufAmount = calculationService.applySellDiscount(fullHufBeforeDiscount, request.getDiscountPercent());

        // Készlet ellenőrzése
        validateCurrencyStock(branchId, currency.getId(), request.getCurrencyAmount());

        // Kezelési díj szerver oldali számítás (kliens értékét felülírjuk)
        BigDecimal serverHandlingFee = handlingFeeCalculator.calculate(
                hufAmount, TransactionType.SELL, request.getHandlingFee());

        // Bruttó: eladásnál nettó + díj
        BigDecimal grossAmount = handlingFeeCalculator.calculateSellGross(hufAmount, serverHandlingFee);

        // Magyar 5 Ft-os kerekítés a fizetendő összegre
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // 300K+ tranzakció esetén ügyfél-azonosítás kötelező (NAV jogi követelmény).
        validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // Sourcery #612: JOGCIM nyilatkozat validacio (FALSE -> actorName kotelezo)
        validateJogcimDeclaration(request.getCustomerOnOwnBehalf(), request.getCustomerActorName());

        // 2026-05-13 v2.5.49+ (Codex P1 #562/#564): pénztárosi sáv napi kvóta backend enforcement + normalizálás
        boolean sellCashierCustomRate = validateAndNormalizeCashierCustomRateQuota(
                Boolean.TRUE.equals(request.getCashierCustomRate()), payableAmount);

        // AML ellenőrzés (Pmt. 2017. évi LIII. tv.) — flagek a Transaction-be CB-018 szerint
        AmlService.AmlBasicCheckResult amlResult = performAmlCheck(
                payableAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), currency.getCode());

        // Bizonylat szám generálása (új szekvencia rendszer)
        String receiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.SELL);

        // Kedvezmény összeg a PRE-DISCOUNT értékből (nem a már csökkentett hufAmount-ból!)
        BigDecimal discountAmount = calculationService.calculateDiscountAmount(fullHufBeforeDiscount, request.getDiscountPercent());

        // POS terminál integráció - bankkártyás fizetésnél
        PaymentMethod paymentMethod = request.getPaymentMethod() != null ? request.getPaymentMethod() : PaymentMethod.CASH;
        String posAuthCode = null;
        String posRefNumber = null;
        String posTerminalId = request.getPosTerminalId();

        if (paymentMethod == PaymentMethod.CARD) {
            if (posTerminalId == null || posTerminalId.isBlank()) {
                throw new ValidationException("Bankkártyás fizetéshez POS terminál azonosító kötelező!");
            }
            PosTransactionResult posResult = posTerminalService.initiatePayment(
                    payableAmount, "HUF", posTerminalId);
            if (!posResult.approved()) {
                throw new ValidationException("Bankkártyás fizetés elutasítva: " + posResult.errorMessage());
            }
            posAuthCode = posResult.authorizationCode();
            posRefNumber = posResult.referenceNumber();
            log.info("POS fizetés elfogadva: auth={}, ref={}", posAuthCode, posRefNumber);
        }

        // Tranzakció létrehozása
        Transaction transaction = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(receiptNumber)
                .transactionType(TransactionType.SELL)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(currency)
                .currencyAmount(request.getCurrencyAmount())
                .exchangeRate(appliedRate)
                .hufAmount(payableAmount)
                .handlingFee(serverHandlingFee)
                .discountPercent(request.getDiscountPercent() != null ? request.getDiscountPercent() : BigDecimal.ZERO)
                .discountAmount(discountAmount)
                .roundingAmount(roundingDifference)
                .paymentMethod(paymentMethod)
                .posAuthorizationCode(posAuthCode)
                .posReferenceNumber(posRefNumber)
                .posTerminalId(posTerminalId)
                .customerId(request.getCustomerId())
                .customerName(request.getCustomerName())
                .customerAddress(request.getCustomerAddress())
                .customerDocumentNumber(request.getCustomerDocumentNumber())
                .customerNationality(request.getCustomerNationality())
                .sourceOfFunds(request.getSourceOfFunds())
                .customerIsPep(Boolean.TRUE.equals(request.getCustomerIsPep()))
                // V229 Pmt. snapshot (HIBA #5+#7+#8)
                .customerBirthPlace(request.getCustomerBirthPlace())
                .customerBirthDate(request.getCustomerBirthDate())
                .customerMotherName(request.getCustomerMotherName())
                .customerDocumentType(request.getCustomerDocumentType())
                .customerOnOwnBehalf(request.getCustomerOnOwnBehalf())
                .customerActorName(request.getCustomerActorName())
                .amlSuspicious(amlResult.isSuspiciousFlag())
                .amlAnnualLimitReached(amlResult.isAnnualLimitReached())
                .notes(request.getNotes())
                .cashierCustomRate(sellCashierCustomRate)
                .foreignStatus(ForeignStatus.parseOrNull(request.getForeignStatus()))
                .build();

        Transaction saved = transactionRepository.save(transaction);
        linkCameraEvidence(saved);

        // Kassza frissítése - HUF nő, valuta csökken
        updateCashBalance(branchId, currency.getId(), request.getCurrencyAmount().negate(), false); // valuta -
        updateCashBalance(branchId, getHufCurrencyId(), payableAmount, true);                       // HUF +

        // Napi statisztika frissítése
        dailySessionService.updateSessionStats(
            TransactionType.SELL,
            payableAmount,
            transaction.getHandlingFee()
        );

        log.info("Eladás tranzakció: {} - {} {} @ {} = {} HUF (kerekítés: {} Ft, díj: {} Ft)",
                receiptNumber, request.getCurrencyAmount(), currency.getCode(),
                appliedRate, payableAmount, roundingDifference, serverHandlingFee);

        return saved;
    }

    // ============ DELEGÁLT MŰVELETEK ============
    // Reversal, Conversion, MultiLine logika kiszervezve:
    // - TransactionReversalService (sztornó + részleges visszatérítés)
    // - TransactionConversionService (valuta-valuta csere)
    // - TransactionMultiLineService (multi-line bizonylatok)

    @Transactional(rollbackFor = Exception.class)
    public Transaction executeReversal(ReversalRequest request) {
        return reversalService.executeReversal(request);
    }

    @Transactional(rollbackFor = Exception.class)
    public Transaction executePartialRefund(PartialRefundRequest request) {
        return reversalService.executePartialRefund(request);
    }

    @Transactional(rollbackFor = Exception.class)
    public Transaction executeConversion(ConversionRequest request) {
        return conversionService.executeConversion(request);
    }

    private Transaction executeMultiLineBuy(BuyRequest request) {
        return multiLineService.executeMultiLineBuy(request);
    }

    private Transaction executeMultiLineSell(SellRequest request) {
        return multiLineService.executeMultiLineSell(request);
    }

    @Transactional(readOnly = true)
    public java.util.List<TransactionLine> getTransactionLines(Long transactionId) {
        return multiLineService.getTransactionLines(transactionId);
    }

    // ============ LEKÉRDEZÉSEK ============
    // ============ LEKÉRDEZÉSEK ============

    /**
     * Tranzakció keresése bizonylat szám alapján
     */
    @Transactional(readOnly = true)
    public Transaction findByReceiptNumber(String receiptNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return transactionRepository.findByReceiptNumberAndCompanyId(receiptNumber, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Bizonylat nem található: " + receiptNumber));
    }

    /**
     * Napi tranzakciók lekérése
     */
    @Transactional(readOnly = true)
    public List<Transaction> getDailyTransactions() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return transactionRepository.findByBranchAndDate(branchId, LocalDate.now());
    }

    /**
     * Tranzakciók szűrése és lapozás
     */
    /**
     * 2026-04-29 v2.3.25 (B17 multi-tenant hardening):
     * KÖTELEZŐ branchId param (defenzív IDOR-megelőzés). A null-check exception-t
     * dob, hogy egyetlen hívó se kerülhesse meg a multi-tenant szűrést.
     * A `SecurityUtils.getCurrentBranchId()` mindig non-null vagy exception, de
     * a defenzív validáció kötelező a repo-szinten is.
     */
    @Transactional(readOnly = true)
    public Page<Transaction> searchTransactions(
            UUID branchId,
            LocalDate startDate,
            LocalDate endDate,
            TransactionType type,
            Pageable pageable) {
        if (branchId == null) {
            throw new IllegalArgumentException(
                "branchId KÖTELEZŐ a searchTransactions hívásnál (B17 multi-tenant hardening). " +
                "A SecurityUtils.getCurrentBranchId()-t kell használni a hívó kontextusban.");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return transactionRepository.findWithFilters(companyId, branchId, startDate, endDate, type, pageable);
    }

    /**
     * Napi forgalom összesítés
     */
    @Transactional(readOnly = true)
    public DailyTurnoverSummary getDailyTurnoverForDate(LocalDate date) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return buildTurnoverSummary(branchId, date);
    }

    @Transactional(readOnly = true)
    public DailyTurnoverSummary getDailyTurnover() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return buildTurnoverSummary(branchId, LocalDate.now());
    }

    private DailyTurnoverSummary buildTurnoverSummary(UUID branchId, LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        BigDecimal buyTotal = transactionRepository.sumDailyTurnover(branchId, date, TransactionType.BUY);
        BigDecimal sellTotal = transactionRepository.sumDailyTurnover(branchId, date, TransactionType.SELL);
        long reversalCount = transactionRepository.countReversalsByBranchAndDate(companyId, branchId, date);

        long buyCount = transactionRepository.countByBranchIdAndTransactionDateAndTransactionType(branchId, date, TransactionType.BUY);
        long sellCount = transactionRepository.countByBranchIdAndTransactionDateAndTransactionType(branchId, date, TransactionType.SELL);
        BigDecimal totalHandlingFees = transactionRepository.sumDailyHandlingFees(branchId, date);

        return DailyTurnoverSummary.builder()
                .date(date)
                .buyTotal(buyTotal != null ? buyTotal : BigDecimal.ZERO)
                .sellTotal(sellTotal != null ? sellTotal : BigDecimal.ZERO)
                .netTotal((sellTotal != null ? sellTotal : BigDecimal.ZERO)
                        .subtract(buyTotal != null ? buyTotal : BigDecimal.ZERO))
                .reversalCount(reversalCount)
                .totalBuyCount(buyCount)
                .totalSellCount(sellCount)
                .totalBuyHuf(buyTotal != null ? buyTotal : BigDecimal.ZERO)
                .totalSellHuf(sellTotal != null ? sellTotal : BigDecimal.ZERO)
                .totalHandlingFees(totalHandlingFees != null ? totalHandlingFees : BigDecimal.ZERO)
                .totalReversalCount(reversalCount)
                .build();
    }

    // ============ HELPER METÓDUSOK ============

    private void validateOpenSession() {
        if (!dailySessionService.hasOpenSession()) {
            throw new ValidationException("Nincs nyitott napi munkamenet! Először nyissa meg a napot.");
        }
    }

    /**
     * Teljes AML ellenőrzés a tranzakció előtt (Pmt. 2017. évi LIII. tv.).
     *
     * Hívja az AmlService.checkTransaction()-t az alapszintű ellenőrzéshez
     * (azonosítás, éves göngyölés, napi gyanúsági limit), valamint a
     * checkAllThresholds()-t a legacy BIGCTRL.DLL klasszifikációhoz (TranzTipus).
     *
     * Legacy parity (CB-018): a visszaadott {@link AmlService.AmlBasicCheckResult}
     * {@code suspiciousFlag} es {@code annualLimitReached} boolean-ja a hivo oldalon
     * a Transaction entitasba kerul (amlSuspicious / amlAnnualLimitReached), hogy a
     * bizonylat ora-szintben tartalmazza az AML besorolast - ugy, ahogy a legacy
     * BIGCTRL.DLL a blokkra kiirta.
     */
    private AmlService.AmlBasicCheckResult performAmlCheck(BigDecimal hufAmount, String customerId,
                                 String customerName, String documentNumber, String currencyCode) {
        AmlService.AmlBasicCheckResult basicResult = amlService.checkTransaction(
                hufAmount, customerId, customerName, documentNumber, currencyCode);

        if (basicResult == null) {
            // Codex+Copilot PR #682 finding: VV-AML-004 a katalogusban FATAL.
            // VV_LOG.fatal() szukseges hogy a level_severity=FATAL MDC marker
            // is bekeruljon a strukturalt log-ba (Loki/Grafana alerting szempontjabol).
            VV_LOG.fatal("VV-AML-004", "aml.service_unavailable_tx_blocked", null,
                    java.util.Map.of("policy", "FAIL_CLOSED"));
            throw new ValidationException("AML ellenőrzés nem elérhető, a tranzakció nem hajtható végre!");
        }

        if (!basicResult.isApproved()) {
            throw new ValidationException(basicResult.getRejectionReason() != null
                    ? basicResult.getRejectionReason()
                    : "AML ellenőrzés sikertelen!");
        }

        if (basicResult.isRequiresApproval()) {
            throw new ValidationException(basicResult.getApprovalReason() != null
                    ? basicResult.getApprovalReason()
                    : "Supervisor jóváhagyás szükséges (AML limit)!");
        }

        if (customerId != null && !customerId.isBlank()) {
            var thresholdResult = amlService.checkAllThresholds(customerId, hufAmount, currencyCode);
            if (thresholdResult != null && thresholdResult.isBlocked()) {
                String warnings = thresholdResult.getWarnings() != null && !thresholdResult.getWarnings().isEmpty()
                        ? String.join("; ", thresholdResult.getWarnings())
                        : "AML szabály alapján blokkolva";
                throw new ValidationException(warnings);
            }
        }

        if (basicResult.isRequiresDetailedId()) {
            log.warn("AML: Részletes azonosítás szükséges - {} Ft, ügyfél: {}", hufAmount, customerId);
        }

        return basicResult;
    }

    private void validateIdentification(BigDecimal hufAmount, String customerName, String documentNumber) {
        if (hufAmount.compareTo(IDENTIFICATION_LIMIT) >= 0) {
            if (customerName == null || customerName.isBlank()) {
                throw new ValidationException(
                    String.format("%s Ft feletti tranzakcióhoz ügyfél azonosítás kötelező!",
                        IDENTIFICATION_LIMIT.toPlainString()));
            }
            if (documentNumber == null || documentNumber.isBlank()) {
                throw new ValidationException(
                    String.format("%s Ft feletti tranzakcióhoz igazolvány szám kötelező!",
                        IDENTIFICATION_LIMIT.toPlainString()));
            }
        }
    }

    /**
     * Sourcery #612 (2026-05-15): a customerOnOwnBehalf=FALSE eseten kotelezo
     * a customerActorName (a kepviselt fel neve). Pmt. JOGCIM nyilatkozat.
     */
    private void validateJogcimDeclaration(Boolean onOwnBehalf, String actorName) {
        if (Boolean.FALSE.equals(onOwnBehalf) && (actorName == null || actorName.isBlank())) {
            throw new ValidationException(
                "JOGCÍM nyilatkozat: ha az ügyfél NEM saját nevében jár el, "
                + "a képviselt fél nevét kötelező megadni (customerActorName).");
        }
    }

    private void validateCurrencyStock(UUID branchId, Long currencyId, BigDecimal amount) {
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(branchId, currencyId)
                .orElse(null);

        if (balance == null || balance.getCurrentBalance().compareTo(amount) < 0) {
            throw new ValidationException("Nincs elegendő valuta készlet!");
        }
    }

    private void updateCashBalance(UUID branchId, Long currencyId, BigDecimal amount, boolean isIncoming) {
        // Pessimistic lock használata race condition elkerülésére
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(branchId, currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Kassza egyenleg nem található"));

        balance.updateBalance(amount.abs(), isIncoming);
        cashBalanceRepository.save(balance);
    }

    /**
     * @deprecated Használd a {@link ReceiptSequenceService#generateReceiptNumber} metódust.
     * Ez a metódus a régi E+MMDD+5szám formátumot generálja - csak backward compatibility-hez.
     */
    @Deprecated
    private String generateReceiptNumber(UUID branchId, String prefix) {
        LocalDate today = LocalDate.now();
        String datePrefix = prefix + String.format("%02d%02d", today.getMonthValue(), today.getDayOfMonth());

        String maxReceipt = transactionRepository.findMaxReceiptNumber(branchId, today, datePrefix)
                .orElse(datePrefix + "00000");

        int lastNumber = Integer.parseInt(maxReceipt.substring(datePrefix.length()));
        return datePrefix + String.format("%05d", lastNumber + 1);
    }

    private Long getHufCurrencyId() {
        if (cachedHufCurrencyId == null) {
            // Újrapróbálás: lehet hogy a DB-ben késve került be a HUF valuta
            cachedHufCurrencyId = currencyRepository.findByCode("HUF")
                    .map(c -> c.getId())
                    .orElse(null);
            if (cachedHufCurrencyId == null) {
                throw new ValidationException("HUF valuta nem található az adatbázisban! Kérjük inicializálja a valuta táblát.");
            }
        }
        return cachedHufCurrencyId;
    }

    /**
     * Currency ID feloldása: ha currencyId megvan, azt használjuk, egyébként currencyCode alapján.
     */
    private Long resolveCurrencyId(Long currencyId, String currencyCode) {
        if (currencyId != null && currencyId > 0) {
            return currencyId;
        }
        if (currencyCode != null && !currencyCode.isBlank()) {
            return currencyRepository.findByCode(currencyCode.toUpperCase())
                    .map(c -> c.getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Ismeretlen valuta kód: " + currencyCode));
        }
        throw new ValidationException("Valuta azonosító (currencyId) vagy valuta kód (currencyCode) kötelező!");
    }

    // ============ REQUEST/RESPONSE DTO-k ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class BuyRequest {
        private Long currencyId;
        private String currencyCode;
        private BigDecimal currencyAmount;
        private BigDecimal discountPercent;
        private BigDecimal handlingFee;
        private BigDecimal customExchangeRate;
        private String customerId;
        private String customerName;
        private String customerAddress;
        private String customerDocumentNumber;
        private String customerNationality;
        private String sourceOfFunds;
        private Boolean customerIsPep;
        // V229 Pmt. snapshot (HIBA #5+#7+#8 2026-05-15)
        private String customerBirthPlace;
        private java.time.LocalDate customerBirthDate;
        private String customerMotherName;
        private String customerDocumentType;
        private Boolean customerOnOwnBehalf;
        private String customerActorName;
        private String notes;
        private Boolean cashierCustomRate;
        private String foreignStatus;
        /** Fizetési mód: CASH (alapértelmezett) vagy CARD (bankkártya) */
        private PaymentMethod paymentMethod;
        /** POS terminál azonosító (csak CARD fizetésnél kötelező) */
        private String posTerminalId;
        /** Multi-line bizonylat tetelsorai (max 6). Ha nem ures, multi-line feldolgozas. */
        private java.util.List<LineRequest> lines;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class SellRequest {
        private Long currencyId;
        private String currencyCode;
        private BigDecimal currencyAmount;
        private BigDecimal discountPercent;
        private BigDecimal handlingFee;
        private BigDecimal customExchangeRate;
        private String customerId;
        private String customerName;
        private String customerAddress;
        private String customerDocumentNumber;
        private String customerNationality;
        private String sourceOfFunds;
        private Boolean customerIsPep;
        // V229 Pmt. snapshot (HIBA #5+#7+#8 2026-05-15)
        private String customerBirthPlace;
        private java.time.LocalDate customerBirthDate;
        private String customerMotherName;
        private String customerDocumentType;
        private Boolean customerOnOwnBehalf;
        private String customerActorName;
        private String notes;
        private Boolean cashierCustomRate;
        private String foreignStatus;
        /** Fizetési mód: CASH (alapértelmezett) vagy CARD (bankkártya) */
        private PaymentMethod paymentMethod;
        /** POS terminál azonosító (csak CARD fizetésnél kötelező) */
        private String posTerminalId;
        /** Multi-line bizonylat tetelsorai (max 6). Ha nem ures, multi-line feldolgozas. */
        private java.util.List<LineRequest> lines;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class ReversalRequest {
        private Long originalTransactionId;
        private String reason;
        private String approvedBy;
        /** Ha true, az aktuális árfolyammal sztornózunk (eltérő árfolyam kezelés) */
        private Boolean useCurrentRate;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class PartialRefundRequest {
        private Long originalTransactionId;
        /** Visszatérítendő HUF összeg */
        private BigDecimal refundHufAmount;
        /** Visszatérítendő valutaösszeg - ha null, arányosan számítjuk */
        private BigDecimal refundCurrencyAmount;
        private String reason;
        private String approvedBy;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class ConversionRequest {
        private Long fromCurrencyId;
        private String fromCurrencyCode;
        private Long toCurrencyId;
        private String toCurrencyCode;
        private BigDecimal fromAmount;
        private BigDecimal handlingFee;
        private String customerId;
        private String customerName;
        private String customerAddress;
        private String customerDocumentNumber;
        private String customerNationality;
        private String sourceOfFunds;
        private Boolean customerIsPep;
    }

    /**
     * Egy tetelsor request multi-line bizonylathoz.
     */
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class LineRequest {
        private Long currencyId;
        private String currencyCode;
        /** Bankjegy darabszam / valuta osszeg */
        private BigDecimal banknoteCount;
        /** Egyedi arfolyam (opcionalis) */
        private BigDecimal customExchangeRate;
        /** Sor kedvezmeny tipus (0=nincs, 4=VIP, stb.) */
        private Integer discountType;
        /**
         * Devizastatusz tetel-szinten (V226, 2026-05-14): DOMESTIC / FOREIGN.
         * Ha NULL, a parent request foreignStatus-a orokitt at.
         */
        private String foreignStatus;
    }

    public CashierCustomRateQuotaDto getCashierCustomRateQuota() {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        long used = transactionRepository.countDailyCashierCustomRatesByWorker(workerId, LocalDate.now());
        long limit = Long.parseLong(systemParameterService.getValue("CASHIER_CUSTOM_RATE_DAILY_LIMIT", "5"));
        long minAmount = Long.parseLong(systemParameterService.getValue("CASHIER_CUSTOM_RATE_MIN_AMOUNT", "400000"));
        return CashierCustomRateQuotaDto.builder()
                .used(used)
                .limit(limit)
                .remaining(Math.max(0, limit - used))
                .minAmountHuf(minAmount)
                .build();
    }

    /**
     * Pénztárosi sáv (cashier custom rate) kvóta enforce-olás.
     * Visszaadja a normalizált flag-et, hogy a sub-threshold tranzakciók ne fogyasszanak kvótát.
     *
     * <p>Logika:
     * <ul>
     *   <li>flag=false → visszaadja false (no-op)</li>
     *   <li>flag=true + hufAmount &lt; CASHIER_CUSTOM_RATE_MIN_AMOUNT → visszaadja FALSE (normalizál!)
     *       — ezzel a kis összegnél is bejelölt flag NEM kerül mentésre, nem fogyasztja a kvótát</li>
     *   <li>flag=true + hufAmount &gt;= min → kvóta-ellenőrzés:
     *       <ul>
     *         <li>used &lt; limit → visszaadja true (engedi, mentésre kerül a flag)</li>
     *         <li>used &gt;= limit → dob ValidationException-t</li>
     *       </ul>
     *   </li>
     * </ul></p>
     *
     * <p>2026-05-13 v2.5.49+ (Codex P1 #562): a frontend tracking-only volt, így 6. tranzakció
     * is sikeresen átment, ha a frontend nem stoppolta. Mostantól a backend validál.</p>
     *
     * <p>2026-05-13 v2.5.50+ (Codex P1 #564 follow-up): sub-threshold normalization +
     * NumberFormatException védelem.</p>
     *
     * <p><b>Ismert korlátozás (P3 future sprint):</b> a read-check-write nem atomikus.
     * Két párhuzamos tranzakció elméletben túlfuttathatja a kvótát 1-gyel. Real-world
     * pénztári környezetben 1 pénztáros/gép, így a verseny nehéz. Megoldás később:
     * pessimistic lock a worker-day count-on, vagy SERIALIZABLE isolation level.</p>
     *
     * @return a normalizált flag (false ha sub-threshold, egyébként az eredeti)
     */
    private boolean validateAndNormalizeCashierCustomRateQuota(boolean cashierCustomRate, BigDecimal hufAmount) {
        if (!cashierCustomRate) {
            return false;
        }
        long minAmount = parseSystemParameterLong("CASHIER_CUSTOM_RATE_MIN_AMOUNT", "400000");
        if (hufAmount == null || hufAmount.compareTo(BigDecimal.valueOf(minAmount)) < 0) {
            // Sub-threshold tranzakció: a flag nem értelmezett, normalizáljuk FALSE-ra
            // (különben a countDailyCashierCustomRatesByWorker felülszámolná)
            return false;
        }
        Long workerId = SecurityUtils.getCurrentWorkerId();
        long used = transactionRepository.countDailyCashierCustomRatesByWorker(workerId, LocalDate.now());
        long limit = parseSystemParameterLong("CASHIER_CUSTOM_RATE_DAILY_LIMIT", "5");
        if (used >= limit) {
            throw new ValidationException(
                    String.format("Pénztárosi sáv napi limit elérve (%d/%d). Egyedi árfolyam ma már nem alkalmazható, kérjen vezetői jóváhagyást.",
                            used, limit));
        }
        return true;
    }

    /**
     * SystemParameter érték biztonságos parseolása long-ra. NumberFormatException
     * esetén loggol és a default értékkel tér vissza — egy elgépelt admin UI ne
     * okozzon 500-as hibát az élesi tranzakciós folyamatban.
     */
    private long parseSystemParameterLong(String key, String defaultValue) {
        String value = systemParameterService.getValue(key, defaultValue);
        try {
            return Long.parseLong(value.trim());
        } catch (NumberFormatException e) {
            log.warn("SystemParameter '{}' nem numerikus érték: '{}' — default '{}' használata", key, value, defaultValue);
            return Long.parseLong(defaultValue);
        }
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DailyTurnoverSummary {
        private LocalDate date;
        private BigDecimal buyTotal;
        private BigDecimal sellTotal;
        private BigDecimal netTotal;
        private long reversalCount;
        // Bővített mezők - frontend kompatibilitás
        private long totalBuyCount;
        private long totalSellCount;
        private BigDecimal totalBuyHuf;
        private BigDecimal totalSellHuf;
        private BigDecimal totalHandlingFees;
        private long totalReversalCount;
    }
}
