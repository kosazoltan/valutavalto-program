package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.CashLockOrdering;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import hu.puzzleir.valuta.service.TransactionService.ConversionRequest;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

/**
 * Valuta konverzio tranzakciok kezelese.
 * Legacy: valuta-valuta csere HUF-on keresztul, 2 bizonylat (GAP 4).
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class TransactionConversionService {

    private final TransactionRepository transactionRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;
    private final CurrencyRepository currencyRepository;
    private final ExchangeRateService exchangeRateService;
    private final ReceiptSequenceService receiptSequenceService;
    private final HandlingFeeCalculator handlingFeeCalculator;
    private final DailySessionService dailySessionService;
    private final TransactionOperationHelper helper;
    private final PmtComplianceValidator pmtComplianceValidator;

    /**
     * Konverzio vegrehajtasa (valuta-valuta csere).
     */
    public Transaction executeConversion(ConversionRequest request) {
        helper.validateOpenSession();

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem talalhato"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem talalhato"));
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Penztaros nem talalhato"));

        Long fromCurrencyId = helper.resolveCurrencyId(request.getFromCurrencyId(), request.getFromCurrencyCode());
        Long toCurrencyId = helper.resolveCurrencyId(request.getToCurrencyId(), request.getToCurrencyCode());

        Currency fromCurrency = currencyRepository.findById(fromCurrencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Forras valuta nem talalhato"));
        Currency toCurrency = currencyRepository.findById(toCurrencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cel valuta nem talalhato"));

        if (fromCurrencyId.equals(toCurrencyId)) {
            throw new ValidationException("Azonos valutanemek kozotti konverzio nem lehetseges!");
        }
        if ("HUF".equals(fromCurrency.getCode()) || "HUF".equals(toCurrency.getCode())) {
            throw new ValidationException("HUF konverzio nem lehetseges! Hasznalja a vetel/eladas funkciot.");
        }

        ExchangeRate fromRate = exchangeRateService.getCurrentRate(fromCurrencyId);
        ExchangeRate toRate = exchangeRateService.getCurrentRate(toCurrencyId);

        // HUF-on keresztul konvertalas
        BigDecimal hufAmount = request.getFromAmount().multiply(fromRate.getBaseBuyRate())
                .setScale(0, RoundingMode.HALF_UP);
        BigDecimal roundedHufAmount = HungarianRounding.roundToFive(hufAmount);
        BigDecimal roundingDifference = roundedHufAmount.subtract(hufAmount);

        // A forrás-fedezetből számolt MAXIMÁLIS cél-összeg (lefelé kerekítve 2 tizedesre).
        BigDecimal maxToAmount = roundedHufAmount.divide(toRate.getBaseSellRate(), 2, RoundingMode.FLOOR);

        // HIBA 2026-05-26 (#5): a pénztáros címletezéshez LEFELÉ módosíthatja a cél-összeget;
        // a maradék forint-fedezet KÉSZPÉNZBEN visszajár. A cél-összeg SOHA nem lehet több a
        // forrás-fedezetből számolt maximumnál (az a forrást módosítaná) — a felső határra
        // vágjuk (clamp), így a kliens/szerver árfolyam-eltérés sem okoz hibás elutasítást.
        BigDecimal toAmount;
        if (request.getToAmount() != null && request.getToAmount().signum() > 0) {
            toAmount = request.getToAmount().setScale(2, RoundingMode.FLOOR).min(maxToAmount);
        } else {
            toAmount = maxToAmount;
        }

        // HIBA 2026-05-26 (#4): visszajáró forint = a cél-összegre fel nem használt HUF-fedezet,
        // magyar 5 Ft-os kerekítéssel. A bizonylaton fel kell tüntetni.
        BigDecimal usedHuf = toAmount.multiply(toRate.getBaseSellRate()).setScale(0, RoundingMode.HALF_UP);
        BigDecimal returnedHufExact = roundedHufAmount.subtract(usedHuf).max(BigDecimal.ZERO);
        BigDecimal returnedHuf = HungarianRounding.roundToFive(returnedHufExact);
        // A visszajáró 5 Ft-os kerekítési maradéka a parent kerekítés-különbözetbe olvad.
        roundingDifference = roundingDifference.add(returnedHuf.subtract(returnedHufExact));

        // AML ellenorzes
        // Legacy GAP-003: konverziónál az AML küszöb a vétel + eladás EGYÜTTES összegén dönt.
        // Delphi: if _konverzio=1 then _fizetendo := _fizetendo + _fizetendo
        // Indok: a konverzió valójában vétel+eladás, tehát a tényleges pénzmozgás összegzendő.
        // Codex P1 (#858): ha a cél-összeg lefelé módosul (címletezés), a SELL leg `usedHuf`-fal
        // könyvel, ezért az AML-alap a TÉNYLEGES legek összege (BUY=roundedHufAmount + SELL=usedHuf),
        // NEM a 2× felülbecslés — különben sub-limit konverzió is hibásan azonosítást kérne.
        BigDecimal amlAmount = roundedHufAmount.add(usedHuf);
        // A foreign-USD blokk a kapott valutara vonatkozik, nem a leadott devizara.
        // Legacy parity (CB-018): az AML flagek a parent CONVERSION bizonylatra kerulnek.
        AmlService.AmlBasicCheckResult amlResult = helper.performAmlCheck(
                amlAmount, request.getCustomerId(), request.getCustomerName(),
                request.getCustomerDocumentNumber(), toCurrency.getCode(), request.getCustomerNationality(),
                request.getApproverWorkerId(), request.getApprovalSessionId());

        // F-002 / Codex P1 (audit 2026-05-29): a Pmt-compliance ellenorzes a KONVERZIORA is
        // kotelezo (300k+ HUF eseten PEP-minoseg / kepviselt-fel azonositas) — korabban a
        // konverzio-ag kicsuszott e validacio alol. Az AML-alap (amlAmount = BUY+SELL leg) a
        // kuszob alapja, a BUY/SELL aggal konzisztensen.
        pmtComplianceValidator.validate(
                amlAmount,
                request.getCustomerIsPep(),
                request.getCustomerPepKind(),
                request.getCustomerOnOwnBehalf(),
                request.getCustomerActorName(),
                request.getCustomerActorBirthPlace(),
                request.getCustomerActorBirthDate() != null ? request.getCustomerActorBirthDate().toString() : null,
                request.getCustomerActorMotherName(),
                request.getCustomerActorDocumentNumber(),
                request.getCustomerActorAddress(),
                "KONVERZIO");

        // CASH-VS-CASH LOCK-ORDERING (deadlock-megelozes): a konverzio HAROM cash_balance sort mozgat
        // (forras-deviza, cel-deviza, HUF) — ezeket GLOBALISAN egyseges, NOVEKVO currencyId sorrendben
        // elo-lockoljuk a keszlet-ellenorzes / mutacio ELOTT, egyezoen a BUY/SELL/sztorno aggal, hogy ne
        // alakulhasson ki AB-BA deadlock egy parhuzamos tranzakcioval. Lasd: CashLockOrdering.
        CashLockOrdering.lockInAscendingCurrencyOrder(branchId, helper::lockCashBalance,
                fromCurrency.getId(), toCurrency.getId(), helper.getHufCurrencyId());

        // Keszlet ellenorzes — a kifizetett cel valuta + (ha van) a visszajaro HUF.
        helper.validateCurrencyStock(branchId, toCurrency.getId(), toAmount);
        if (returnedHuf.signum() > 0) {
            helper.validateCurrencyStock(branchId, helper.getHufCurrencyId(), returnedHuf);
        }

        // Ugyfel deviza-statusza (HIBA 2026-05-26 #2). Default: FOREIGN (penzvalto a leggyakoribb).
        ForeignStatus foreignStatus = ForeignStatus.FOREIGN;
        if (request.getForeignStatus() != null && !request.getForeignStatus().isBlank()) {
            foreignStatus = ForeignStatus.valueOf(request.getForeignStatus());
        }

        // Kezelesi dij
        BigDecimal serverHandlingFee = handlingFeeCalculator.calculate(
                roundedHufAmount, TransactionType.CONVERSION, request.getHandlingFee(), branchId);

        // GAP 4: konverzio = 2 bizonylat
        String buyReceiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.BUY);
        String sellReceiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.SELL);

        BigDecimal conversionRate = fromRate.getBaseBuyRate().divide(toRate.getBaseSellRate(), 6, RoundingMode.HALF_UP);

        String conversionReceiptNumber = receiptSequenceService.generateReceiptNumber(branchId, TransactionType.CONVERSION);

        // Audit P0.8 (V177, 2026-05-03): a parent CONVERSION sor `financial_effective = false` —
        // csak metadata + receipt-summary, NEM duplikalja a tenyleges penzmozgast a child convBuy
        // + convSell sorokkal. Az osszes szum-jellegu riport (AML, NGM, cash-balance, daily turnover)
        // alapertelmezetten szur `financial_effective = true`-ra.
        // A `conversion_group_id` hozzakot a parent + ket child sort -> teljes konverzio lekerdezheto.
        UUID conversionGroupId = UUID.randomUUID();

        Transaction transaction = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(conversionReceiptNumber)
                .transactionType(TransactionType.CONVERSION)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(fromCurrency)
                .currencyAmount(request.getFromAmount())
                .exchangeRate(conversionRate)
                .hufAmount(roundedHufAmount)
                .handlingFee(serverHandlingFee)
                .roundingAmount(roundingDifference)
                .returnedHuf(returnedHuf)
                .foreignStatus(foreignStatus)
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
                // V235 + V236 Konverzio Pmt. azonositas (HIBA #19 2026-05-19)
                .customerBirthPlace(request.getCustomerBirthPlace())
                .customerBirthDate(request.getCustomerBirthDate())
                .customerMotherName(request.getCustomerMotherName())
                .customerDocumentType(request.getCustomerDocumentType())
                .customerOnOwnBehalf(request.getCustomerOnOwnBehalf())
                .customerActorName(request.getCustomerActorName())
                .customerPepKind(request.getCustomerPepKind())
                .customerActorBirthPlace(request.getCustomerActorBirthPlace())
                .customerActorBirthDate(request.getCustomerActorBirthDate())
                .customerActorMotherName(request.getCustomerActorMotherName())
                .customerActorNationality(request.getCustomerActorNationality())
                .customerActorDocumentType(request.getCustomerActorDocumentType())
                .customerActorDocumentNumber(request.getCustomerActorDocumentNumber())
                .customerActorAddress(request.getCustomerActorAddress())
                .amlSuspicious(amlResult.isSuspiciousFlag())
                .amlAnnualLimitReached(amlResult.isAnnualLimitReached())
                .notes(String.format("Konverzio: %s %s -> %s %s",
                    request.getFromAmount(), fromCurrency.getCode(),
                    toAmount, toCurrency.getCode()))
                .conversionGroupId(conversionGroupId)
                .financialEffective(false)
                .build();

        Transaction saved = transactionRepository.save(transaction);
        helper.linkCameraEvidence(saved);

        // Konverzios vetel bizonylat — financial_effective = TRUE (default), conversionGroupId =
        // parent.conversion_group_id (a sum riportokban a parent NEM, a convBuy IGEN szamol).
        Transaction convBuy = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(buyReceiptNumber)
                .transactionType(TransactionType.BUY)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(fromCurrency)
                .currencyAmount(request.getFromAmount())
                .exchangeRate(fromRate.getBaseBuyRate())
                .hufAmount(roundedHufAmount)
                .handlingFee(BigDecimal.ZERO)
                .roundingAmount(roundingDifference)
                .foreignStatus(foreignStatus)
                .linkedReceiptNumber(sellReceiptNumber)
                .customerId(request.getCustomerId())
                .customerName(request.getCustomerName())
                .notes(String.format("Konverzios vetel: %s %s -> %s HUF (par: %s)",
                    request.getFromAmount(), fromCurrency.getCode(),
                    roundedHufAmount, sellReceiptNumber))
                .conversionGroupId(conversionGroupId)
                // Sourcery PR #360 follow-up: explicit financialEffective(true) — kritikus AML/NGM/
                // cash-balance flag, NEM bizhatunk a builder default-jaban a regression vedelem ervenyere.
                .financialEffective(true)
                .build();
        convBuy = transactionRepository.save(convBuy);
        helper.linkCameraEvidence(convBuy);

        // Konverzios eladas bizonylat — financial_effective = TRUE (default), conversionGroupId
        // azonos.
        Transaction convSell = Transaction.builder()
                .company(company)
                .branch(branch)
                .worker(worker)
                .receiptNumber(sellReceiptNumber)
                .transactionType(TransactionType.SELL)
                .status(TransactionStatus.COMPLETED)
                .transactionDate(LocalDate.now())
                .transactionTime(LocalTime.now())
                .currency(toCurrency)
                .currencyAmount(toAmount)
                .exchangeRate(toRate.getBaseSellRate())
                .hufAmount(usedHuf)
                .handlingFee(serverHandlingFee)
                .roundingAmount(BigDecimal.ZERO)
                .foreignStatus(foreignStatus)
                .linkedReceiptNumber(buyReceiptNumber)
                .customerId(request.getCustomerId())
                .customerName(request.getCustomerName())
                .notes(String.format("Konverzios eladas: %s HUF -> %s %s (par: %s)",
                    usedHuf, toAmount, toCurrency.getCode(),
                    buyReceiptNumber))
                .conversionGroupId(conversionGroupId)
                // Sourcery PR #360 follow-up: explicit financialEffective(true) — kritikus AML/NGM/
                // cash-balance flag, NEM bizhatunk a builder default-jaban a regression vedelem ervenyere.
                .financialEffective(true)
                .build();
        convSell = transactionRepository.save(convSell);
        helper.linkCameraEvidence(convSell);

        // Audit/Codex P1 #937: a highRiskFlag-frissítést az EFFEKTÍV (financialEffective=true) sorok
        // — convBuy + convSell — mentése UTÁN hívjuk. A sumCustomerAnnualTotal csak a financialEffective
        // sorokat összegzi; a parent (false) után hívva a friss konverzió még nem számítana bele, így a
        // konverzió-okozta éves-limit átlépés sosem állítaná be a flag-et.
        helper.flagHighRiskAfterBooking(request.getCustomerId());

        // Kassza frissites
        helper.updateCashBalance(branchId, fromCurrency.getId(), request.getFromAmount(), true);
        helper.updateCashBalance(branchId, toCurrency.getId(), toAmount.negate(), false);
        // Visszajaro forint kifizetese -> HUF kassza csokkenese (HIBA 2026-05-26 #4).
        if (returnedHuf.signum() > 0) {
            helper.updateCashBalance(branchId, helper.getHufCurrencyId(), returnedHuf.negate(), false);
        }

        // Napi statisztika — a SELL forgalma a tenylegesen felhasznalt HUF (usedHuf).
        dailySessionService.updateSessionStats(TransactionType.BUY, roundedHufAmount, BigDecimal.ZERO);
        dailySessionService.updateSessionStats(TransactionType.SELL, usedHuf, serverHandlingFee);

        log.info("Konverzio: {} - {} {} -> {} {} (HUF koztes: {}, felhasznalt: {}, visszajaro: {}, kerekites: {}, bizonylatok: {} + {})",
                conversionReceiptNumber, request.getFromAmount(), fromCurrency.getCode(),
                toAmount, toCurrency.getCode(), roundedHufAmount, usedHuf, returnedHuf, roundingDifference,
                buyReceiptNumber, sellReceiptNumber);

        return saved;
    }
}
