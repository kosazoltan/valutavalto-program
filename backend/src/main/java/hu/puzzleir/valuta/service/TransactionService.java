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
import hu.puzzleir.valuta.util.CashLockOrdering;
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
    private final ShipmentHandlingFeeRepository shipmentHandlingFeeRepository;
    private final TransactionLineRepository transactionLineRepository;
    // V325 (Batch3-C): tenyleges tulajdonosok perzisztalasa jogi szemely ugyfelnel
    private final TransactionBeneficialOwnerRepository transactionBeneficialOwnerRepository;
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
    private final HandlingFeeOverrideService handlingFeeOverrideService;
    private final AmlService amlService;
    private final AmlApprovalService amlApprovalService;
    private final PosTerminalService posTerminalService;
    private final ObjectProvider<CameraTransactionLinker> cameraTransactionLinkerProvider;
    private final TransactionCalculationService calculationService;

    // Delegate services — @Lazy to avoid circular dependency (they import inner DTOs from this class)
    private final @org.springframework.context.annotation.Lazy TransactionReversalService reversalService;
    private final @org.springframework.context.annotation.Lazy TransactionConversionService conversionService;
    private final @org.springframework.context.annotation.Lazy TransactionMultiLineService multiLineService;
    private final PmtComplianceValidator pmtComplianceValidator;
    private final LicenseService licenseService;
    private final SystemParameterService systemParameterService;
    private final WacService wacService;
    /** A4: kötelező körlevél-nyugtázás gate (flag-gated, default OFF → @InjectMocks tesztekben nem hívódik). */
    private final hu.puzzleir.valuta.repository.CircularRepository circularRepository;
    private final TransactionValidationService transactionValidationService;
    private final VaultStockFlowService vaultStockFlowService;
    private final ValueBandService valueBandService;

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


    /** G11: a 10M+ vezetői-jóváhagyás enforcement feature-flag SystemParameter kulcsa. */
    static final String AML_HIGH_VALUE_APPROVAL_PARAM = "AML_HIGH_VALUE_APPROVAL_ENFORCEMENT";
    /** G11: a feature-flag alapértéke (false = WARN-only, kompatibilis a meglévő kliensekkel). */
    static final String AML_HIGH_VALUE_APPROVAL_DEFAULT = "false";

    /** A4 (b9-korlevelek FR-02): a kötelező körlevél-nyugtázás tranzakció-blokkoló enforcement flag-je. */
    static final String CIRCULAR_ACK_BLOCKING_PARAM = "CIRCULAR_ACK_BLOCKING_ENFORCEMENT";
    /** A4: alapérték false (NEM blokkol) — production-biztos; a business kapcsolja élesre. */
    static final String CIRCULAR_ACK_BLOCKING_DEFAULT = "false";

    /** A3 (Pmt. 50M, b4-foglalo FR-16): forrás-igazolás enforcement feature-flag. */
    static final String SOURCE_OF_FUNDS_50M_PARAM = "AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT";
    /** A3: alapérték false (NEM blokkol) — production-biztos; a business kapcsolja élesre. */
    static final String SOURCE_OF_FUNDS_50M_DEFAULT = "false";
    /** A3: Pmt. 50M Ft küszöb a forrás-igazoláshoz. */
    private static final BigDecimal SOURCE_OF_FUNDS_THRESHOLD = new BigDecimal("50000000");
    /** A3: banki bizonylat (szlip) maximális kora — 3 év = 1095 nap. */
    private static final long BANK_SLIP_MAX_AGE_DAYS = 1095;
    /** A3: elfogadható forrás-dokumentum típusok (normalizált, exact-match). */
    private static final java.util.Set<String> ACCEPTABLE_SOURCE_DOC_TYPES = java.util.Set.of(
            "MAGANOKIRAT_KOZJEGYZO", "MAGANOKIRAT_UGYVED", "BANK_SZLIP");
    /** A3: 50M felett TILOS két tanús magánnyilatkozat ismert kódjai (a contains("TANU") a fallback). */
    private static final java.util.Set<String> TWO_WITNESS_DOC_TYPES = java.util.Set.of(
            "KET_TANU", "KETTANU", "KET_TANUS", "KET_TANUVAL", "TWO_WITNESS", "2_TANU");

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

    /**
     * V325 (Batch3-C, Codex P2 #1116): jogi személy ügyfélnél az entitás neve kötelező —
     * enélkül a 300k+ bizonylat jogi blokkja üresen nyomtatódna. A teljes követelményt
     * (székhely + legalább egy tényleges tulajdonos) a pénztári UI kényszeríti ki; itt
     * az integritás-minimum fut, hogy a régi offline pending sorok sync-je ne ragadjon be.
     */
    private void requireLegalEntityName(Boolean isLegalEntity, String legalEntityName) {
        if (Boolean.TRUE.equals(isLegalEntity)
                && (legalEntityName == null || legalEntityName.isBlank())) {
            throw new hu.puzzleir.valuta.exception.ValidationException(
                    "Jogi személy ügyfélnél a jogi személy neve kötelező!");
        }
    }

    /**
     * V325 (Batch3-C): a tényleges tulajdonosok perzisztálása jogi személy ügyfélnél.
     * Legacy UJTULAJOK tükre — MAX 4 tulajdonos (array[1..4]); a sorszám (ownerNo) a
     * bizonylat "N. tulajdonos:" fejlécét adja. Üres/null lista: no-op.
     */
    private void saveBeneficialOwners(Transaction saved,
                                      java.util.List<hu.puzzleir.valuta.dto.transaction.BeneficialOwnerDto> owners) {
        if (owners == null || owners.isEmpty()) {
            return;
        }
        if (owners.size() > 4) {
            throw new hu.puzzleir.valuta.exception.ValidationException(
                    "Legfeljebb 4 tényleges tulajdonos adható meg (Pmt./legacy UJTULAJOK korlát)!");
        }
        int no = 1;
        for (var o : owners) {
            if (o.getName() == null || o.getName().isBlank()) {
                continue; // üres sor a UI-ból — kihagyjuk
            }
            transactionBeneficialOwnerRepository.save(TransactionBeneficialOwner.builder()
                    .companyId(saved.getCompany().getId())
                    .transactionId(saved.getId())
                    .ownerNo(no++)
                    .ownerName(o.getName().trim())
                    .ownerAddress(o.getAddress())
                    .ownerBirthPlace(o.getBirthPlace())
                    .ownerBirthDate(o.getBirthDate())
                    .ownerNationality(o.getNationality())
                    .ownerResidenceAbroad(o.getResidenceAbroad())
                    .ownerInterestNature(o.getInterestNature())
                    .ownerInterestExtent(o.getInterestExtent())
                    .ownerIsPep(Boolean.TRUE.equals(o.getIsPep()))
                    .build());
        }
        log.info("V325: {} tényleges tulajdonos rögzítve a(z) {} tranzakcióhoz",
                no - 1, saved.getReceiptNumber());
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
        transactionValidationService.validateCurrencyExchangeable(currency);

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
        BigDecimal handlingFeeBase = handlingFeeCalculator.calculate(
                hufAmount, TransactionType.BUY, request.getHandlingFee(), branchId);
        // FK-KEZDÍJ (2026-06-02): kezelési díj módosítás (override) AUTORITATÍV szerver-oldali
        // validálása az engedély-mátrix szerint. NONE → a számolt alap díj marad.
        BigDecimal serverHandlingFee = (request.getHandlingFeeOverrideType() != null
                && request.getHandlingFeeOverrideType() != hu.puzzleir.valuta.entity.HandlingFeeOverrideType.NONE)
                ? handlingFeeOverrideService.resolveOverride(
                        handlingFeeBase, request.getHandlingFeeOverrideType(), request.getHandlingFeeOverrideReason(),
                        request.getCustomerCardNumber(), request.getHandlingFee(), currentWorkerRoleForOverride())
                : handlingFeeBase;

        // Bruttó: vételnél nettó - díj (a cég levonja a kezelési díjat)
        BigDecimal grossAmount = handlingFeeCalculator.calculateBuyGross(hufAmount, serverHandlingFee);

        // Magyar 5 Ft-os kerekítés a fizetendő összegre
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // 300K+ tranzakcio eseten ugyfelazonositas kotelezo.
        validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // Sourcery #612: JOGCIM nyilatkozat validacio (FALSE -> actorName kotelezo)
        validateJogcimDeclaration(request.getCustomerOnOwnBehalf(), request.getCustomerActorName());

        // Codex P1 (PR #695): Pmt. compliance WARN-szintu naplozas 300k+ tranzakcional,
        // ha PEP minoseg vagy actor teljes azonositas hianyzik. v2.5.61+ exception lesz.
        validatePmtComplianceFields(
            payableAmount,
            request.getCustomerIsPep(),
            request.getCustomerPepKind(),
            request.getCustomerOnOwnBehalf(),
            request.getCustomerActorName(),
            request.getCustomerActorBirthPlace(),
            request.getCustomerActorBirthDate() != null ? request.getCustomerActorBirthDate().toString() : null,
            request.getCustomerActorMotherName(),
            request.getCustomerActorDocumentNumber(),
            request.getCustomerActorAddress(),
            "BUY"
        );

        // LOCK-ORDERING (cash-vs-cash deadlock-megelozes): a modositando cash_balance sorokat
        // (HUF + deviza) GLOBALISAN egyseges, NOVEKVO currencyId sorrendben elo-lockoljuk, mielott
        // barmilyen kasszamuvelet (validateCurrencyStock / updateCashBalance) tortenne. Igy a BUY a
        // SELL-lel / sztornoval / konverzioval NEM tud AB-BA deadlockot okozni ugyanazon iroda+valuta
        // paroson. A lenti validateCurrencyStock/updateCashBalance ugyanezeket a sorokat mar lockoltan
        // kapja (no-op re-lock). Lasd: CashLockOrdering.
        CashLockOrdering.lockInAscendingCurrencyOrder(branchId,
                (bid, cid) -> cashBalanceRepository
                        .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(bid, cid, companyId),
                getHufCurrencyId(), currency.getId());

        // 2026-05-15 user-direktíva: BUY ágon a pénztár HUF készletet ellenőrizni KELL
        // (vételnél a cég HUF-ot fizet ki az ügyfélnek). Korábban csak SELL ágon volt
        // készlet-ellenőrzés (foreign currency), ezért negatív HUF egyenlegre is
        // engedett tranzakciót — ez TILOS mind a pénztárban, mind az értéktárban.
        validateCurrencyStock(branchId, getHufCurrencyId(), payableAmount, companyId);

        // 2026-05-13 v2.5.49+ (Codex P1 #562/#564): pénztárosi sáv napi kvóta backend enforcement + normalizálás
        boolean buyCashierCustomRate = validateAndNormalizeCashierCustomRateQuota(
                Boolean.TRUE.equals(request.getCashierCustomRate()), payableAmount);

        // AML ellenőrzés (Pmt. 2017. évi LIII. tv.) — flagek a Transaction-be CB-018 szerint
        AmlService.AmlBasicCheckResult amlResult = performAmlCheck(
                payableAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), currency.getCode(), request.getCustomerNationality(),
                request.getApproverWorkerId(), request.getApprovalSessionId());

        // A3 (Pmt. 50M, b4-foglalo FR-16): 50M Ft feletti ügyletnél kötelező forrás-igazolás
        // (közjegyző/ügyvéd magánokirat vagy max. 3 éves banki szlip; két tanú TILOS). Flag-gated.
        enforceSourceOfFunds(payableAmount, request.getSourceOfFundsDocType(), request.getSourceOfFundsDocDate());

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
                .handlingFeeBase(handlingFeeBase)
                .handlingFeeOverrideType(request.getHandlingFeeOverrideType())
                .handlingFeeOverrideReason(request.getHandlingFeeOverrideReason())
                .customerCardNumber(request.getCustomerCardNumber())
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
                // A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum perzisztálása
                .sourceOfFundsDocType(request.getSourceOfFundsDocType())
                .sourceOfFundsDocDate(request.getSourceOfFundsDocDate())
                .customerIsPep(Boolean.TRUE.equals(request.getCustomerIsPep()))
                // V312 / FR-BSZUR-05: a jóváhagyás-session perzisztálása a bizonylat-ENGEDÉLYEZŐ lookuphoz
                .approvalSessionId(request.getApprovalSessionId())
                // V229 Pmt. snapshot (HIBA #5+#7+#8)
                .customerBirthPlace(request.getCustomerBirthPlace())
                .customerBirthDate(request.getCustomerBirthDate())
                .customerMotherName(request.getCustomerMotherName())
                .customerDocumentType(request.getCustomerDocumentType())
                .customerOnOwnBehalf(request.getCustomerOnOwnBehalf())
                .customerActorName(request.getCustomerActorName())
                // V235 PEP minoseg + actor teljes azonositasa (HIBA #15 + #17 2026-05-19)
                .customerPepKind(request.getCustomerPepKind())
                .customerActorBirthPlace(request.getCustomerActorBirthPlace())
                .customerActorBirthDate(request.getCustomerActorBirthDate())
                .customerActorMotherName(request.getCustomerActorMotherName())
                .customerActorNationality(request.getCustomerActorNationality())
                .customerActorDocumentType(request.getCustomerActorDocumentType())
                .customerActorDocumentNumber(request.getCustomerActorDocumentNumber())
                .customerActorAddress(request.getCustomerActorAddress())
                // V325 (Batch3-C): jogi szemely ugyfel torzsadatai
                .isLegalEntityCustomer(request.getIsLegalEntityCustomer())
                .legalEntityName(request.getLegalEntityName())
                .legalEntitySeat(request.getLegalEntitySeat())
                .legalEntityTaxNumber(request.getLegalEntityTaxNumber())
                .legalDeedNumber(request.getLegalDeedNumber())
                .amlSuspicious(amlResult.isSuspiciousFlag())
                .amlAnnualLimitReached(amlResult.isAnnualLimitReached())
                .notes(request.getNotes())
                .cashierCustomRate(buyCashierCustomRate)
                .foreignStatus(ForeignStatus.parseOrNull(request.getForeignStatus()))
                .build();

        requireLegalEntityName(request.getIsLegalEntityCustomer(), request.getLegalEntityName());
        Transaction saved = transactionRepository.save(transaction);
        saveBeneficialOwners(saved, request.getBeneficialOwners());
        linkCameraEvidence(saved);
        flagHighRiskAfterBooking(request.getCustomerId());

        // Kassza frissítése - HUF csökken, valuta nő
        updateCashBalance(branchId, currency.getId(), request.getCurrencyAmount(), true, companyId);  // valuta +
        updateCashBalance(branchId, getHufCurrencyId(), payableAmount.negate(), false, companyId);    // HUF -

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
        transactionValidationService.validateCurrencyExchangeable(currency);

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

        // LOCK-ORDERING (cash-vs-cash deadlock-megelozes): a modositando cash_balance sorokat
        // (HUF + deviza) GLOBALISAN egyseges, NOVEKVO currencyId sorrendben elo-lockoljuk a
        // keszlet-ellenorzes ELOTT. Korabban az eladas a devizat lockolta eloszor (lenti
        // validateCurrencyStock(currency)), majd a vegen a HUF-ot — ez a BUY-jal (HUF-first)
        // keresztezve AB-BA deadlockot okozhatott. Lasd: CashLockOrdering.
        CashLockOrdering.lockInAscendingCurrencyOrder(branchId,
                (bid, cid) -> cashBalanceRepository
                        .findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(bid, cid, companyId),
                getHufCurrencyId(), currency.getId());

        // Készlet ellenőrzése
        validateCurrencyStock(branchId, currency.getId(), request.getCurrencyAmount(), companyId);

        // Kezelési díj szerver oldali számítás (kliens értékét felülírjuk)
        BigDecimal handlingFeeBase = handlingFeeCalculator.calculate(
                hufAmount, TransactionType.SELL, request.getHandlingFee(), branchId);
        // FK-KEZDÍJ (2026-06-02): kezelési díj módosítás (override) AUTORITATÍV validálása.
        BigDecimal serverHandlingFee = (request.getHandlingFeeOverrideType() != null
                && request.getHandlingFeeOverrideType() != hu.puzzleir.valuta.entity.HandlingFeeOverrideType.NONE)
                ? handlingFeeOverrideService.resolveOverride(
                        handlingFeeBase, request.getHandlingFeeOverrideType(), request.getHandlingFeeOverrideReason(),
                        request.getCustomerCardNumber(), request.getHandlingFee(), currentWorkerRoleForOverride())
                : handlingFeeBase;

        // Bruttó: eladásnál nettó + díj
        BigDecimal grossAmount = handlingFeeCalculator.calculateSellGross(hufAmount, serverHandlingFee);

        // Magyar 5 Ft-os kerekítés a fizetendő összegre
        BigDecimal payableAmount = HungarianRounding.roundToFive(grossAmount);
        BigDecimal roundingDifference = payableAmount.subtract(grossAmount);

        // 300K+ tranzakció esetén ügyfél-azonosítás kötelező (NAV jogi követelmény).
        validateIdentification(payableAmount, request.getCustomerName(), request.getCustomerDocumentNumber());

        // Sourcery #612: JOGCIM nyilatkozat validacio (FALSE -> actorName kotelezo)
        validateJogcimDeclaration(request.getCustomerOnOwnBehalf(), request.getCustomerActorName());

        // Codex P1 (PR #695): Pmt. compliance WARN naplozas 300k+ tranzakcional, ha
        // PEP minoseg vagy actor teljes azonositas hianyzik. v2.5.61+ exception lesz.
        validatePmtComplianceFields(
            payableAmount,
            request.getCustomerIsPep(),
            request.getCustomerPepKind(),
            request.getCustomerOnOwnBehalf(),
            request.getCustomerActorName(),
            request.getCustomerActorBirthPlace(),
            request.getCustomerActorBirthDate() != null ? request.getCustomerActorBirthDate().toString() : null,
            request.getCustomerActorMotherName(),
            request.getCustomerActorDocumentNumber(),
            request.getCustomerActorAddress(),
            "SELL"
        );

        // 2026-05-13 v2.5.49+ (Codex P1 #562/#564): pénztárosi sáv napi kvóta backend enforcement + normalizálás
        boolean sellCashierCustomRate = validateAndNormalizeCashierCustomRateQuota(
                Boolean.TRUE.equals(request.getCashierCustomRate()), payableAmount);

        // AML ellenőrzés (Pmt. 2017. évi LIII. tv.) — flagek a Transaction-be CB-018 szerint
        AmlService.AmlBasicCheckResult amlResult = performAmlCheck(
                payableAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), currency.getCode(), request.getCustomerNationality(),
                request.getApproverWorkerId(), request.getApprovalSessionId());

        // A3 (Pmt. 50M, b4-foglalo FR-16): 50M Ft feletti ügyletnél kötelező forrás-igazolás. Flag-gated.
        enforceSourceOfFunds(payableAmount, request.getSourceOfFundsDocType(), request.getSourceOfFundsDocDate());

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
                .handlingFeeBase(handlingFeeBase)
                .handlingFeeOverrideType(request.getHandlingFeeOverrideType())
                .handlingFeeOverrideReason(request.getHandlingFeeOverrideReason())
                .customerCardNumber(request.getCustomerCardNumber())
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
                // A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum perzisztálása
                .sourceOfFundsDocType(request.getSourceOfFundsDocType())
                .sourceOfFundsDocDate(request.getSourceOfFundsDocDate())
                .customerIsPep(Boolean.TRUE.equals(request.getCustomerIsPep()))
                // V312 / FR-BSZUR-05: a jóváhagyás-session perzisztálása a bizonylat-ENGEDÉLYEZŐ lookuphoz
                .approvalSessionId(request.getApprovalSessionId())
                // V229 Pmt. snapshot (HIBA #5+#7+#8)
                .customerBirthPlace(request.getCustomerBirthPlace())
                .customerBirthDate(request.getCustomerBirthDate())
                .customerMotherName(request.getCustomerMotherName())
                .customerDocumentType(request.getCustomerDocumentType())
                .customerOnOwnBehalf(request.getCustomerOnOwnBehalf())
                .customerActorName(request.getCustomerActorName())
                // V235 PEP minoseg + actor teljes azonositasa (HIBA #15 + #17 2026-05-19)
                .customerPepKind(request.getCustomerPepKind())
                .customerActorBirthPlace(request.getCustomerActorBirthPlace())
                .customerActorBirthDate(request.getCustomerActorBirthDate())
                .customerActorMotherName(request.getCustomerActorMotherName())
                .customerActorNationality(request.getCustomerActorNationality())
                .customerActorDocumentType(request.getCustomerActorDocumentType())
                .customerActorDocumentNumber(request.getCustomerActorDocumentNumber())
                .customerActorAddress(request.getCustomerActorAddress())
                // V325 (Batch3-C): jogi szemely ugyfel torzsadatai
                .isLegalEntityCustomer(request.getIsLegalEntityCustomer())
                .legalEntityName(request.getLegalEntityName())
                .legalEntitySeat(request.getLegalEntitySeat())
                .legalEntityTaxNumber(request.getLegalEntityTaxNumber())
                .legalDeedNumber(request.getLegalDeedNumber())
                .amlSuspicious(amlResult.isSuspiciousFlag())
                .amlAnnualLimitReached(amlResult.isAnnualLimitReached())
                .notes(request.getNotes())
                .cashierCustomRate(sellCashierCustomRate)
                .foreignStatus(ForeignStatus.parseOrNull(request.getForeignStatus()))
                .build();

        requireLegalEntityName(request.getIsLegalEntityCustomer(), request.getLegalEntityName());
        Transaction saved = transactionRepository.save(transaction);
        saveBeneficialOwners(saved, request.getBeneficialOwners());
        linkCameraEvidence(saved);
        flagHighRiskAfterBooking(request.getCustomerId());

        // Kassza frissítése - HUF nő, valuta csökken
        updateCashBalance(branchId, currency.getId(), request.getCurrencyAmount().negate(), false, companyId); // valuta -
        updateCashBalance(branchId, getHufCurrencyId(), payableAmount, true, companyId);                       // HUF +

        // A6 / b8 FR-8: realizált profit best-effort rögzítése a tranzakció COMMITJA UTÁN
        // (flag-gated, cold-start-safe, read-only a készleten → nincs havi-zárás/cash_balance
        // kettős-számolás). A diszkontált eladási rátát használja. Az afterCommit garantálja, hogy
        // a profit_log CSAK sikeres eladás után íródjon (nincs orphan-tétel rollback esetén), és a
        // best-effort írás SOHA ne törje meg az eladást.
        TransactionAfterCommit.run(
                () -> wacService.recordSellProfitIfEnabled(branchId, saved.getId(), currency.getCode(),
                        request.getCurrencyAmount(), appliedRate, request.getDiscountPercent()),
                "WAC sell profit tx=" + saved.getId());

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
     * Tranzakció keresése bizonylat szám alapján.
     *
     * <p>FK-071 HIGH-D (Codex security review): a pénztáros (nem supervisor+) csak a
     * SAJÁT fiókja bizonylatát kérheti le — a korábbi, csak companyId-szűrt lekérdezés
     * bizonylatszám-tippeléssel/URL-manipulációval ugyanazon cég MÁS fiókjának
     * tranzakcióját is kiadta. Supervisor+ (SUPERVISOR/MANAGER/ADMIN,
     * {@link SecurityUtils#isSupervisorOrAbove()}) számára a cégszintű viselkedés
     * változatlan. Scope-on kívüli bizonylat = 404 (létezés-maszkolás), ugyanúgy,
     * ahogy a cross-tenant (F9) és a territory-scope (Transfer) konvenció teszi.</p>
     */
    @Transactional(readOnly = true)
    public Transaction findByReceiptNumber(String receiptNumber) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        var found = SecurityUtils.isSupervisorOrAbove()
                ? transactionRepository.findByReceiptNumberAndCompanyId(receiptNumber, companyId)
                : transactionRepository.findByReceiptNumberAndCompanyIdAndBranchId(
                        receiptNumber, companyId, SecurityUtils.getCurrentBranchId());
        Transaction tx = found
                .orElseThrow(() -> new ResourceNotFoundException("Bizonylat nem található: " + receiptNumber));
        initMultiLineForMapping(tx);
        return tx;
    }

    /**
     * Napi tranzakciók lekérése
     */
    @Transactional(readOnly = true)
    public List<Transaction> getDailyTransactions() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        List<Transaction> txs = transactionRepository.findByBranchAndDate(branchId, LocalDate.now());
        txs.forEach(this::initMultiLineForMapping);
        return txs;
    }

    /**
     * #LazyInit (2026-05-27, architect-mode): a TransactionMapper.toDto multiLine=true esetén
     * a lazy `lines` kollekciót (+ soronkénti currency-t) olvassa. A controllerek a session
     * lezárása UTÁN (OSIV=false) mappelnek → LazyInit 500 minden multi-line tranzakciónál a
     * napi listán / bizonylat-keresőn / lapozott keresőn. Itt, a tranzakción belül töltjük be.
     * Lapozás-biztos (a már betöltött page-content sorain fut, nem JOIN FETCH a Pageable mellé).
     */
    private void initMultiLineForMapping(Transaction tx) {
        if (tx != null && Boolean.TRUE.equals(tx.getMultiLine()) && tx.getLines() != null) {
            org.hibernate.Hibernate.initialize(tx.getLines());
            tx.getLines().forEach(line -> org.hibernate.Hibernate.initialize(line.getCurrency()));
        }
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
            boolean customerOnly,
            Pageable pageable) {
        if (branchId == null) {
            throw new IllegalArgumentException(
                "branchId KÖTELEZŐ a searchTransactions hívásnál (B17 multi-tenant hardening). " +
                "A SecurityUtils.getCurrentBranchId()-t kell használni a hívó kontextusban.");
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Page<Transaction> page = transactionRepository.findWithFilters(companyId, branchId, startDate, endDate, type, customerOnly, pageable);
        page.getContent().forEach(this::initMultiLineForMapping);
        return page;
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
        BigDecimal buyTotal = transactionRepository.sumDailyTurnover(companyId, branchId, date, TransactionType.BUY);
        BigDecimal sellTotal = transactionRepository.sumDailyTurnover(companyId, branchId, date, TransactionType.SELL);
        long reversalCount = transactionRepository.countReversalsByBranchAndDate(companyId, branchId, date);

        long buyCount = transactionRepository.countByBranchIdAndTransactionDateAndTransactionType(branchId, date, TransactionType.BUY);
        long sellCount = transactionRepository.countByBranchIdAndTransactionDateAndTransactionType(branchId, date, TransactionType.SELL);
        BigDecimal totalHandlingFees = transactionRepository.sumDailyHandlingFees(branchId, date);
        BigDecimal shipmentFees = shipmentHandlingFeeRepository.sumDailyReceivedFees(companyId, branchId, date);

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
                // FR-6: tranzakciós + Shipment-eredetű (FKH-018) kezelési díj — KÉT külön gazdasági esemény, additív (user-verifikált döntés 2026-07-14)
                .totalHandlingFees((totalHandlingFees != null ? totalHandlingFees : BigDecimal.ZERO)
                        .add(shipmentFees != null ? shipmentFees : BigDecimal.ZERO))
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
     * Audit-finding 2026-05-31 (P1): a sikeres tranzakció KÖNYVELÉSE UTÁN frissíti az ügyfél
     * highRiskFlag-jét, ha az éves göngyölt elérte az AML limitet. Eddig az
     * {@code AmlService.setHighRiskFlagIfNeeded} SEHOL nem hívódott → a fokozott átvilágítási
     * jelölés éles üzemben sosem aktiválódott. A save UTÁN hívandó (a getAnnualRollingTotal a
     * friss, már elmentett összeget tükrözze).
     */
    private void flagHighRiskAfterBooking(String customerId) {
        if (customerId == null || customerId.isBlank()) {
            return;
        }
        amlService.setHighRiskFlagIfNeeded(customerId, amlService.getAnnualRollingTotal(customerId));
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
                                 String customerName, String documentNumber, String currencyCode,
                                 String customerNationality, Long approverWorkerId, String approvalSessionId) {
        // A4 (b9-korlevelek FR-02): kötelező körlevél-nyugtázás gate. Feature-flag mögött
        // (CIRCULAR_ACK_BLOCKING_ENFORCEMENT, default false → nem blokkol → a meglévő kliensek és a
        // @InjectMocks tesztek nem törnek meg). Bekapcsolva: ha a pénztárosnak van olvasatlan,
        // KÖTELEZŐ-nyugtázandó (requires_acknowledgment=true) körlevele, a tranzakció elutasul, amíg
        // nem nyugtázza (CircularPage). A circularRepository CSAK enforce=true ágon dereferálódik.
        boolean circularEnforce = systemParameterService != null && circularRepository != null
                && "true".equalsIgnoreCase(
                        systemParameterService.getValue(CIRCULAR_ACK_BLOCKING_PARAM, CIRCULAR_ACK_BLOCKING_DEFAULT));
        if (circularEnforce) {
            java.util.UUID companyId = SecurityUtils.getCurrentCompanyId();
            Long workerId = SecurityUtils.getCurrentWorkerId();
            java.util.UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
            String circularBlock = circularAckBlockReason(
                    circularRepository.findUnacknowledgedMandatoryForWorker(companyId, workerId, branchId,
                            hu.puzzleir.valuta.util.LegacyCompanyIdentityCodec.toLegacyInt(companyId)),
                    true);
            if (circularBlock != null) {
                throw new ValidationException(circularBlock);
            }
        }

        AmlService.AmlBasicCheckResult basicResult = amlService.checkTransaction(
                hufAmount, customerId, customerName, documentNumber, currencyCode, customerNationality);

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

        // Egyszeri jóváhagyás-rögzítés flag: ha a tranzakció EGYSZERRE üti meg a basicResult-alapú
        // (gate-a) ÉS a threshold-alapú manager-kaput (gate-b), a 4-szem-elvű jóváhagyást csak EGYSZER
        // rögzítjük (ne legyen dupla audit-rekord ugyanarra a tranzakcióra).
        boolean approvalRecorded = false;

        if (basicResult.isRequiresApproval()) {
            // Pmt. 14/A. § (4) / MNB 14/2025 V.2.6: a magas-kockázatú tranzakció kizárólag a kijelölt
            // felelős vezető jóváhagyásával teljesíthető. Ha a POS-on érvényes (supervisor/manager/admin,
            // az aktuális céghez tartozó) engedélyezőt adtak meg, a jóváhagyást INSERT-only audit-rekordba
            // rögzítjük (az engedélyező NEVÉVEL, 8 éves megőrzés) és a tranzakció folytatódhat; különben
            // elutasul. Engedélyező hiányában a pénztáros az AML-indokot kapja (hívja a vezetőt).
            String approvalReason = basicResult.getApprovalReason() != null
                    ? basicResult.getApprovalReason()
                    : "Supervisor jóváhagyás szükséges (AML limit)!";
            if (approverWorkerId == null || amlApprovalService == null) {
                throw new ValidationException(approvalReason);
            }
            // recordSeniorApproval validálja az engedélyező jogosultságát (multi-tenant + szerepkör + 4-szem);
            // érvénytelennél ValidationException-t dob ("nem jogosult" / "nem ehhez a céghez").
            // receiptNumber=null: a bizonylatszám az AML-check pillanatában még nem ismert, az okmányszámot
            // pedig TILOS a receipt_number audit-mezőbe tenni (adatminimalizálás / GDPR).
            amlApprovalService.recordSeniorApproval(
                    approverWorkerId, approvalReason, hufAmount, customerName, null, approvalSessionId);
            approvalRecorded = true;
        }

        if (customerId != null && !customerId.isBlank()) {
            var thresholdResult = amlService.checkAllThresholds(customerId, hufAmount, currencyCode);
            if (thresholdResult != null && thresholdResult.isBlocked()) {
                String warnings = thresholdResult.getWarnings() != null && !thresholdResult.getWarnings().isEmpty()
                        ? String.join("; ", thresholdResult.getWarnings())
                        : "AML szabály alapján blokkolva";
                throw new ValidationException(warnings);
            }
            // G11 (EXCMD b5-kezeles FR-KC-11): 10M+ / fokozott (TranzTipus>=4) tranzakció
            // kötelező vezetői jóváhagyása. A besorolás eddig csak flag/warning volt; most
            // feature-flag mögött enforce-olható (AML_HIGH_VALUE_APPROVAL_ENFORCEMENT).
            // Default false → WARN-only naplózás (a meglévő kliensek nem törnek meg, és
            // nincs supervisor-jóváhagyó UI a Buy/Sell képernyőn); true → ValidationException.
            // A bekapcsolás a pénztáros supervisor-jóváhagyó útvonalával együtt aktiválható.
            // Megjegyzés: bekapcsolt enforcement esetén MINDEN szerepkörre (a pénztáros
            // supervisor/manager is) blokkol — a jóváhagyásnak explicitnek és
            // auditálhatónak kell lennie (4-szem-elv), nincs implicit self-approval kiskapu.
            if (thresholdResult != null && thresholdResult.isRequiresManagerApproval()) {
                // Konzisztencia a basicResult-alapú kapuval: ha a POS-on érvényes felelős vezető
                // engedélyezett (és még nem rögzítettük), a 4-szem-elvű jóváhagyást rögzítjük és engedünk
                // — a flag-től függetlenül, mert az explicit, auditált vezetői jóváhagyás erősebb, mint a
                // WARN/enforce kapcsoló. Engedélyező nélkül a meglévő flag-alapú enforce-logika dönt.
                String managerReason = thresholdResult.getManagerApprovalReason() != null
                        ? thresholdResult.getManagerApprovalReason()
                        : "Vezetői jóváhagyás szükséges (AML magas-értékű / gördülő limit)";
                if (!approvalRecorded && approverWorkerId != null && amlApprovalService != null
                        && amlApprovalService.isValidSeniorApprover(approverWorkerId)) {
                    amlApprovalService.recordSeniorApproval(
                            approverWorkerId, managerReason, hufAmount, customerName, null, approvalSessionId);
                    approvalRecorded = true;
                } else {
                    boolean enforce = systemParameterService != null
                            && "true".equalsIgnoreCase(
                                    systemParameterService.getValue(
                                            AML_HIGH_VALUE_APPROVAL_PARAM, AML_HIGH_VALUE_APPROVAL_DEFAULT));
                    String blockReason = highValueApprovalBlockReason(thresholdResult, enforce);
                    if (blockReason != null) {
                        throw new ValidationException(blockReason);
                    }
                    log.warn("AML magas-értékű jóváhagyás szükséges (WARN-only, enforcement kikapcsolva): "
                            + "{} (ügyfél: {}, összeg: {} Ft)",
                            thresholdResult.getManagerApprovalReason(), customerId, hufAmount);
                }
            }
        }

        if (basicResult.isRequiresDetailedId()) {
            log.warn("AML: Részletes azonosítás szükséges - {} Ft, ügyfél: {}", hufAmount, customerId);
        }

        return basicResult;
    }

    /**
     * G11 (EXCMD b5-kezeles FR-KC-11): eldönti, hogy a magas-értékű / fokozott
     * tranzakciót blokkolni kell-e vezetői jóváhagyás hiányában.
     *
     * <p>Csomag-privát, függőség-mentes (statikus) a tesztelhetőségért: a
     * {@code performAmlCheck} a SystemParameter feature-flag aktuális értékét adja át
     * {@code enforcementEnabled}-ként.</p>
     *
     * @return a blokkoló indok szövege, ha (jóváhagyás-köteles ÉS enforce bekapcsolva);
     *         {@code null}, ha nincs blokk (a hívó WARN-only naplózást végez)
     */
    /**
     * A4 (b9-korlevelek FR-02): eldönti, hogy a kötelező körlevél-nyugtázás hiánya blokkolja-e a
     * tranzakciót. Csomag-privát, statikus a tesztelhetőségért (a hívó a feature-flag állapotát és a
     * lekérdezett olvasatlan-kötelező listát adja át).
     *
     * @param unacknowledgedMandatory a pénztáros olvasatlan, requires_acknowledgment=true körlevelei
     * @param enforcementEnabled a CIRCULAR_ACK_BLOCKING_ENFORCEMENT flag aktuális értéke
     * @return a blokkoló indok, ha (enforce ÉS van olvasatlan kötelező); különben {@code null}
     */
    static String circularAckBlockReason(
            java.util.List<hu.puzzleir.valuta.entity.Circular> unacknowledgedMandatory,
            boolean enforcementEnabled) {
        if (!enforcementEnabled) {
            return null;
        }
        if (unacknowledgedMandatory == null || unacknowledgedMandatory.isEmpty()) {
            return null;
        }
        String titles = unacknowledgedMandatory.stream()
                .map(hu.puzzleir.valuta.entity.Circular::getTitle)
                .filter(t -> t != null && !t.isBlank())
                .limit(5)
                .collect(java.util.stream.Collectors.joining("; "));
        return "Olvasatlan kötelező körlevél — a tranzakció előtt nyugtázni kell a Körlevelek menüben"
                + (titles.isBlank() ? "" : (": " + titles));
    }

    /**
     * A3 (Pmt. 50M, b4-foglalo FR-16): eldönti, hogy az 50M Ft feletti ügyletnél a pénzeszköz-forrás
     * igazolása hiányzik/érvénytelen-e. Csomag-privát, statikus a tesztelhetőségért.
     *
     * Szabály (a spec szerint LEZÁRT): >= 50M Ft → KÖTELEZŐ közjegyző/ügyvéd ellenjegyzésű, teljes
     * bizonyító erejű magánokirat VAGY max. 3 éves banki bizonylat (szlip). Két tanús magánnyilatkozat TILOS.
     *
     * @return a blokkoló indok, ha (enforce ÉS >=50M ÉS hiányzó/érvénytelen forrás-igazolás); különben null.
     */
    static String sourceOfFundsBlockReason(BigDecimal hufAmount, String docType,
                                           java.time.LocalDate docDate, java.time.LocalDate txDate,
                                           boolean enforcementEnabled) {
        if (!enforcementEnabled) {
            return null;
        }
        if (hufAmount == null || hufAmount.compareTo(SOURCE_OF_FUNDS_THRESHOLD) < 0) {
            return null; // 50M alatt nincs külön forrás-igazolási kényszer (a 300k jogcím külön szabály)
        }
        String t = docType == null ? "" : docType.trim().toUpperCase(java.util.Locale.ROOT);
        if (t.isEmpty()) {
            return "50M Ft feletti ügylet: a pénzeszközök forrását igazolni kell (közjegyző/ügyvéd "
                    + "ellenjegyzésű teljes bizonyító erejű magánokirat vagy max. 3 éves banki bizonylat).";
        }
        // Sourcery/Copilot review: az elfogadható típusokat ELŐSZÖR ellenőrizzük (explicit, exact-match
        // halmaz) — így egyetlen érvényes típus sem osztályozható félre semmilyen substring-egyezés miatt.
        if (!ACCEPTABLE_SOURCE_DOC_TYPES.contains(t)) {
            // Nem elfogadható. Ha két tanús magánnyilatkozat (Pmt. 50M felett TILOS) → specifikus,
            // segítő üzenet; a contains("TANU") itt már CSAK nem-elfogadható típusra fut (az accept-lista
            // egyetlen eleme sem tartalmazza), ezért nem okozhat érvényes típus téves blokkolását.
            if (TWO_WITNESS_DOC_TYPES.contains(t) || t.contains("TANU")) {
                return "50M Ft feletti ügylet: két tanúval ellátott magánnyilatkozat NEM fogadható el "
                        + "forrás-igazolásként (Pmt.). Közjegyző/ügyvéd ellenjegyzésű magánokirat vagy banki bizonylat szükséges.";
            }
            return "50M Ft feletti ügylet: nem elfogadható forrás-dokumentum típus (" + docType + "). "
                    + "Elfogadható: MAGANOKIRAT_KOZJEGYZO, MAGANOKIRAT_UGYVED vagy BANK_SZLIP.";
        }
        if (t.equals("BANK_SZLIP")) {
            if (docDate == null) {
                return "50M Ft feletti ügylet: banki bizonylat esetén kötelező a kiállítás dátuma (max. 3 év).";
            }
            java.time.LocalDate effectiveTxDate = txDate != null ? txDate : docDate;
            long ageDays = java.time.temporal.ChronoUnit.DAYS.between(docDate, effectiveTxDate);
            if (ageDays < 0) {
                return "50M Ft feletti ügylet: a banki bizonylat kiállítási dátuma a jövőben van — érvénytelen.";
            }
            if (ageDays > BANK_SLIP_MAX_AGE_DAYS) {
                return "50M Ft feletti ügylet: a banki bizonylat 3 évnél régebbi (" + ageDays
                        + " nap) — nem fogadható el forrás-igazolásként.";
            }
        }
        return null;
    }

    /**
     * A3: a forrás-igazolás enforcement feature-flag feloldása (egyetlen igazságforrás, a single-line
     * és a multi-line {@link TransactionOperationHelper} úton egyaránt). null/nem-true → false.
     */
    static boolean isSourceOfFundsEnforcementEnabled(SystemParameterService sp) {
        return sp != null && "true".equalsIgnoreCase(
                sp.getValue(SOURCE_OF_FUNDS_50M_PARAM, SOURCE_OF_FUNDS_50M_DEFAULT));
    }

    /**
     * A3: a forrás-igazolás gate flag-olvasással + dobással (a buy/sell hívja). A flag default false
     * → @InjectMocks tesztekben (systemParameterService mock → null → "false") no-op, így a tesztek
     * nem törnek és nem kell forrás-dokumentumot megadniuk.
     */
    private void enforceSourceOfFunds(BigDecimal hufAmount, String docType, java.time.LocalDate docDate) {
        if (!isSourceOfFundsEnforcementEnabled(systemParameterService)) {
            return;
        }
        String reason = sourceOfFundsBlockReason(hufAmount, docType, docDate, java.time.LocalDate.now(), true);
        if (reason != null) {
            throw new ValidationException(reason);
        }
    }

    static String highValueApprovalBlockReason(
            hu.puzzleir.valuta.dto.aml.AmlCheckResult thresholdResult, boolean enforcementEnabled) {
        if (thresholdResult == null || !thresholdResult.isRequiresManagerApproval()) {
            return null;
        }
        if (!enforcementEnabled) {
            return null;
        }
        String reason = thresholdResult.getManagerApprovalReason();
        // Copilot #786: üres/blank indok esetén is értelmes hibaüzenet (ne dobjon üres ValidationException-t).
        return (reason != null && !reason.isBlank())
                ? reason
                : "Magas értékű / fokozott tranzakció — vezetői (SUPERVISOR/MANAGER) jóváhagyás szükséges";
    }

    private void validateIdentification(BigDecimal hufAmount, String customerName, String documentNumber) {
        BigDecimal limit = ValueBandService.resolve(valueBandService).identificationLimitHuf();
        if (hufAmount.compareTo(limit) >= 0) {
            if (customerName == null || customerName.isBlank()) {
                throw new ValidationException(
                    String.format("%s Ft feletti tranzakcióhoz ügyfél azonosítás kötelező!",
                        limit.toPlainString()));
            }
            if (documentNumber == null || documentNumber.isBlank()) {
                throw new ValidationException(
                    String.format("%s Ft feletti tranzakcióhoz igazolvány szám kötelező!",
                        limit.toPlainString()));
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

    /**
     * Codex P1 (PR #695): a v2.5.60 V235 mezok (customerPepKind + actor teljes
     * azonositasa) nincs server-oldali enforcement-tel a TransactionService
     * mentes elott. Egy regi vagy hibas kliens (vagy direkt API hivas) 300k+
     * tranzakciot tudna mentem nem-compliance allapotban: customerIsPep=true
     * de pepKind null, vagy customerOnOwnBehalf=false de actor mezok hianyoznak.
     *
     * <p>A v2.5.60 release-ben WARN-szintu naplozas. A v2.5.61+ release-ben a
     * VALIDATION_ENABLED rendszerparameter alapjan exception-t fog dobni
     * (feature-flag kontrollalt strict enforcement). Igy a meglevo v2.5.59-es
     * kliensek azonnal nem blokkolodnak meg, de a hianyok auditalva vannak.</p>
     */
    private void validatePmtComplianceFields(
            BigDecimal hufAmount,
            Boolean customerIsPep,
            String customerPepKind,
            Boolean customerOnOwnBehalf,
            String customerActorName,
            String customerActorBirthPlace,
            String customerActorBirthDate,
            String customerActorMotherName,
            String customerActorDocumentNumber,
            String customerActorAddress,
            String operation) {
        // F-002 + Codex P1 (audit 2026-05-29): a Pmt-compliance ellenorzes a megosztott
        // PmtComplianceValidator-ban el, hogy a BUY/SELL ES a KONVERZIO (TransactionConversionService)
        // UGYANAZT futtassa — a konverzio-ag korabban kicsuszott a Pmt-validacio alol.
        pmtComplianceValidator.validate(
                hufAmount, customerIsPep, customerPepKind, customerOnOwnBehalf,
                customerActorName, customerActorBirthPlace, customerActorBirthDate,
                customerActorMotherName, customerActorDocumentNumber, customerActorAddress, operation);
    }

    private void validateCurrencyStock(UUID branchId, Long currencyId, BigDecimal amount, UUID companyId) {
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(branchId, currencyId, companyId)
                .orElse(null);

        if (balance == null || balance.getCurrentBalance().compareTo(amount) < 0) {
            // 2026-05-27 (live-API teszt): a generikus "Nincs elegendő valuta készlet!" üzenet
            // FÉLREVEZETŐ volt a BUY ágon — ott a pénztár HUF-ot fizet (HUF-készletet ellenőrzünk),
            // de az üzenet "valuta" (deviza) készletet emlegetett, miközben a vevő épp devizát HOZ.
            // Currency-specifikus üzenet + szükséges/elérhető összeg a pénztárosnak.
            String code = currencyRepository.findById(currencyId).map(Currency::getCode).orElse("?");
            BigDecimal available = balance != null ? balance.getCurrentBalance() : BigDecimal.ZERO;
            String label = "HUF".equals(code) ? "HUF (forint)" : code + " valuta";
            throw new ValidationException(String.format(
                "Nincs elegendő %s készlet a tranzakcióhoz! Szükséges: %s, elérhető: %s.",
                label, amount.toPlainString(), available.toPlainString()));
        }

        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));
        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található"));
        vaultStockFlowService.validateVaultStockCoverage(branch, currency.getCode(), amount);
    }

    private void updateCashBalance(UUID branchId, Long currencyId, BigDecimal amount, boolean isIncoming, UUID companyId) {
        // Pessimistic lock használata race condition elkerülésére
        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyIdAndCompanyIdForUpdate(branchId, currencyId, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Kassza egyenleg nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));
        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található"));
        BigDecimal normalizedAmount = amount.abs();

        balance.updateBalance(normalizedAmount, isIncoming);
        cashBalanceRepository.save(balance);

        if (Boolean.TRUE.equals(branch.getIsVault())) {
            vaultStockFlowService.applyGenericVaultStock(branch, currency.getCode(), normalizedAmount, isIncoming);
        }
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

    /**
     * FK-KEZDÍJ (2026-06-02): a kezelési díj override jogosultság-ellenőrzéséhez a bejelentkezett
     * dolgozó operatív szerepköre (activeRole, fallback currentRole).
     */
    private String currentWorkerRoleForOverride() {
        try {
            String active = hu.puzzleir.valuta.security.SecurityUtils.getActiveOperationalRole();
            return (active != null && !active.isBlank())
                    ? active
                    : hu.puzzleir.valuta.security.SecurityUtils.getCurrentRole();
        } catch (Exception e) {
            return null;
        }
    }

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
        // FK-KEZDÍJ (2026-06-02): kezelési díj override (lásd HandlingFeeOverrideService)
        private hu.puzzleir.valuta.entity.HandlingFeeOverrideType handlingFeeOverrideType;
        private hu.puzzleir.valuta.entity.HandlingFeeOverrideReason handlingFeeOverrideReason;
        private String customerCardNumber;
        private BigDecimal customExchangeRate;
        private String customerId;
        private String customerName;
        private String customerAddress;
        private String customerDocumentNumber;
        private String customerNationality;
        private String sourceOfFunds;
        // A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum a szerver-oldali validációhoz.
        private String sourceOfFundsDocType;
        private java.time.LocalDate sourceOfFundsDocDate;
        // AML felsővezetői jóváhagyás (Pmt. 14/A.§(4) V.2.6): a POS-on jóváhagyó supervisor workerId-ja.
        private Long approverWorkerId;
        // AML jóváhagyás-session azonosító — a grantot a konkrét nyugtához köti (Codex P1).
        private String approvalSessionId;
        private Boolean customerIsPep;
        // V229 Pmt. snapshot (HIBA #5+#7+#8 2026-05-15)
        private String customerBirthPlace;
        private java.time.LocalDate customerBirthDate;
        private String customerMotherName;
        private String customerDocumentType;
        private Boolean customerOnOwnBehalf;
        private String customerActorName;
        // V235 PEP minoseg + actor teljes azonositasa (HIBA #15 + #17 2026-05-19)
        private String customerPepKind;
        private String customerActorBirthPlace;
        private java.time.LocalDate customerActorBirthDate;
        private String customerActorMotherName;
        private String customerActorNationality;
        private String customerActorDocumentType;
        private String customerActorDocumentNumber;
        private String customerActorAddress;
        // V325 (Batch3-C): jogi szemely ugyfel + tenyleges tulajdonosok
        private Boolean isLegalEntityCustomer;
        private String legalEntityName;
        private String legalEntitySeat;
        private String legalEntityTaxNumber;
        private String legalDeedNumber;
        private java.util.List<hu.puzzleir.valuta.dto.transaction.BeneficialOwnerDto> beneficialOwners;
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
        // FK-KEZDÍJ (2026-06-02): kezelési díj override (lásd HandlingFeeOverrideService)
        private hu.puzzleir.valuta.entity.HandlingFeeOverrideType handlingFeeOverrideType;
        private hu.puzzleir.valuta.entity.HandlingFeeOverrideReason handlingFeeOverrideReason;
        private String customerCardNumber;
        private BigDecimal customExchangeRate;
        private String customerId;
        private String customerName;
        private String customerAddress;
        private String customerDocumentNumber;
        private String customerNationality;
        private String sourceOfFunds;
        // A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum a szerver-oldali validációhoz.
        private String sourceOfFundsDocType;
        private java.time.LocalDate sourceOfFundsDocDate;
        // AML felsővezetői jóváhagyás (Pmt. 14/A.§(4) V.2.6): a POS-on jóváhagyó supervisor workerId-ja.
        private Long approverWorkerId;
        // AML jóváhagyás-session azonosító — a grantot a konkrét nyugtához köti (Codex P1).
        private String approvalSessionId;
        private Boolean customerIsPep;
        // V229 Pmt. snapshot (HIBA #5+#7+#8 2026-05-15)
        private String customerBirthPlace;
        private java.time.LocalDate customerBirthDate;
        private String customerMotherName;
        private String customerDocumentType;
        private Boolean customerOnOwnBehalf;
        private String customerActorName;
        // V235 PEP minoseg + actor teljes azonositasa (HIBA #15 + #17 2026-05-19)
        private String customerPepKind;
        private String customerActorBirthPlace;
        private java.time.LocalDate customerActorBirthDate;
        private String customerActorMotherName;
        private String customerActorNationality;
        private String customerActorDocumentType;
        private String customerActorDocumentNumber;
        private String customerActorAddress;
        // V325 (Batch3-C): jogi szemely ugyfel + tenyleges tulajdonosok
        private Boolean isLegalEntityCustomer;
        private String legalEntityName;
        private String legalEntitySeat;
        private String legalEntityTaxNumber;
        private String legalDeedNumber;
        private java.util.List<hu.puzzleir.valuta.dto.transaction.BeneficialOwnerDto> beneficialOwners;
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
        /**
         * Szándék-jelző: aktuális/egyedi árfolyamú sztornó. A tényleges árfolyamot a
         * {@link #customExchangeRate} hordozza — a könyvelés trigger-e az, ha az &gt; 0.
         */
        private Boolean useCurrentRate;
        /**
         * Az egyedi (aktuális) árfolyam értéke a sztornóhoz (G2). Ha {@code > 0}, a sztornó
         * ezzel könyvel (a díjakat megőrizve, csak az árfolyam-különbözettel igazítva);
         * egyébként az eredeti tranzakció árfolyama marad.
         */
        private BigDecimal customExchangeRate;
        /**
         * Codex P2 (2026-05-31, #944 review): a napi sztornó-plafon 3. (limit-1) sztornójához
         * supervisori jóváhagyás kell. A dokumentált flow: a pénztáros jóváhagyást kér, a supervisor
         * megadja (StornoApproval), majd a PÉNZTÁROS hajtja végre. Ez a flag jelzi, hogy a
         * végrehajtáshoz tartozik ÉRVÉNYES, MEGADOTT (APPROVED) jóváhagyás — ezt a {@code StornoService}
         * verifikálja SZERVER-OLDALON (approvalId → APPROVED StornoApproval ehhez a tranzakcióhoz/irodához),
         * és csak verifikáltan állítja {@code true}-ra. Az {@code executeReversal} a 3. sztornó kapuját
         * supervisor-végrehajtó VAGY {@code supervisorApproved} esetén engedi át; a 4.+ abszolút plafon
         * ettől függetlenül tilt. Default {@code false} (közvetlen hívóknál nincs jóváhagyás).
         */
        private boolean supervisorApproved;
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
        // Cimletezeshez lefele modositott cel-osszeg (null = teljes fedezet). HIBA 2026-05-26.
        private BigDecimal toAmount;
        // Ugyfel deviza-statusza (DOMESTIC/FOREIGN). HIBA 2026-05-26.
        private String foreignStatus;
        private BigDecimal handlingFee;
        private String customerId;
        private String customerName;
        private String customerAddress;
        private String customerDocumentNumber;
        private String customerNationality;
        private String sourceOfFunds;
        // A3 (Pmt. 50M, b4-foglalo FR-16): strukturált forrás-dokumentum a szerver-oldali validációhoz.
        private String sourceOfFundsDocType;
        private java.time.LocalDate sourceOfFundsDocDate;
        // AML felsővezetői jóváhagyás (Pmt. 14/A.§(4) V.2.6): a POS-on jóváhagyó supervisor workerId-ja.
        private Long approverWorkerId;
        // AML jóváhagyás-session azonosító — a grantot a konkrét nyugtához köti (Codex P1).
        private String approvalSessionId;
        private Boolean customerIsPep;
        // V235 + V236 Konverzio Pmt. azonositas (HIBA #19 2026-05-19)
        private String customerBirthPlace;
        private java.time.LocalDate customerBirthDate;
        private String customerMotherName;
        private String customerDocumentType;
        private Boolean customerOnOwnBehalf;
        private String customerActorName;
        private String customerPepKind;
        private String customerActorBirthPlace;
        private java.time.LocalDate customerActorBirthDate;
        private String customerActorMotherName;
        private String customerActorNationality;
        private String customerActorDocumentType;
        private String customerActorDocumentNumber;
        private String customerActorAddress;
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
     * <p>2026-06-09 Product Ready audit: a kvótaellenőrzés pesszimista zárat vesz a
     * pénztáros sorára, így az ugyanazon pénztároshoz tartozó párhuzamos limit-checkek
     * tranzakciós sorrendbe kerülnek.</p>
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
        // PP-06: pesszimista zár a pénztáros sorára — szerializálja a párhuzamos kvóta-ellenőrzést
        // (TOCTOU race ellen: két párhuzamos kliens ne tudja átlépni a napi limitet).
        workerRepository.findByIdForUpdate(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Pénztáros nem található: " + workerId));
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
