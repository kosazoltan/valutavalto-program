package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Napi kĂ©szlet / forgalom szolgĂˇltatĂˇs.
 * 
 * A Delphi napi zĂˇrĂˇskor szĂˇmolta a kĂ©szletmozgĂˇst:
 * nyitĂł + vĂ©tel + ĂˇtvĂ©tel - eladĂˇs - ĂˇtadĂˇs = zĂˇrĂł
 * 
 * Ez a szĂˇmviteli lĂˇnc alapja, nĂ©lkĂĽlĂ¶zhetetlen a havi zĂˇrĂˇshoz.
 * 
 * Legacy: NAPZAR.DLL â€” napi forgalom szĂˇmĂ­tĂˇs
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class DailyBalanceService {

    private final DailyBalanceRepository dailyBalanceRepository;
    private final TransactionRepository transactionRepository;
    private final TransferRepository transferRepository;
    private final CurrencyRepository currencyRepository;
    private final CompanyRepository companyRepository;
    private final AuditLogService auditLogService;

    /**
     * Napi mĂ©rleg szĂˇmĂ­tĂˇsa egy iroda + dĂˇtum + valuta kombinĂˇciĂłhoz.
     * 
     * @param branchId Iroda ID
     * @param date DĂˇtum
     * @param currencyCode Valuta kĂłd
     * @return SzĂˇmĂ­tott DailyBalance
     */
    public DailyBalance calculateDailyBalance(UUID branchId, LocalDate date, String currencyCode) {
        log.info("Napi mĂ©rleg szĂˇmĂ­tĂˇsa: branchId={}, date={}, currency={}", branchId, date, currencyCode);

        // CĂ©g azonosĂ­tĂł
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
            .orElseThrow(() -> new ValidationException("CĂ©g nem talĂˇlhatĂł: " + companyId));

        // EllenĹ‘rzĂ©s: mĂˇr lĂ©tezik-e
        DailyBalance existing = dailyBalanceRepository
            .findByBranchIdAndBalanceDateAndCurrencyCode(branchId, date, currencyCode)
            .orElse(null);

        if (existing != null && existing.getIsClosed()) {
            throw new ValidationException(
                String.format("A %s napi mĂ©rleg mĂˇr lezĂˇrva! (%s)", date, currencyCode)
            );
        }

        // 1. NyitĂł kĂ©szlet (elĹ‘zĹ‘ nap zĂˇrĂł VAGY elĹ‘zĹ‘ hĂł vĂ©gi zĂˇrĂł)
        BigDecimal openingBalance = getOpeningBalance(branchId, date, currencyCode);

        // 2. VĂˇsĂˇrlĂˇs (BUY tĂ­pusĂş tranzakciĂłk â€” beĂ©rkezett valuta)
        BigDecimal purchases = transactionRepository.sumDailyTurnoverByCurrency(
            branchId, date, TransactionType.BUY, currencyCode
        );
        if (purchases == null) {
            purchases = BigDecimal.ZERO;
        }

        // 3. EladĂˇs (SELL tĂ­pusĂş tranzakciĂłk â€” kiadott valuta)
        BigDecimal sales = transactionRepository.sumDailyTurnoverByCurrency(
            branchId, date, TransactionType.SELL, currencyCode
        );
        if (sales == null) {
            sales = BigDecimal.ZERO;
        }

        // 4. ĂtvĂ©tel mĂˇs irodĂˇtĂłl (transfer IN)
        BigDecimal transfersIn = getTransfersIn(branchId, date, currencyCode);
        if (transfersIn == null) {
            transfersIn = BigDecimal.ZERO;
        }

        // 5. ĂtadĂˇs mĂˇs irodĂˇba (transfer OUT)
        BigDecimal transfersOut = getTransfersOut(branchId, date, currencyCode);
        if (transfersOut == null) {
            transfersOut = BigDecimal.ZERO;
        }

        // 6. ZĂˇrĂł kĂ©szlet szĂˇmĂ­tĂˇsa
        BigDecimal closingBalance = openingBalance
            .add(purchases)
            .add(transfersIn)
            .subtract(sales)
            .subtract(transfersOut);

        // DailyBalance entity
        DailyBalance balance = existing != null ? existing : DailyBalance.builder()
            .branchId(branchId)
            .balanceDate(date)
            .currencyCode(currencyCode)
            .company(company)
            .isClosed(false)
            .build();

        balance.setOpeningBalance(openingBalance);
        balance.setPurchases(purchases);
        balance.setTransfersIn(transfersIn);
        balance.setSales(sales);
        balance.setTransfersOut(transfersOut);
        balance.setClosingBalance(closingBalance);

        // MentĂ©s
        DailyBalance saved = dailyBalanceRepository.save(balance);

        log.info("Napi mĂ©rleg kĂ©sz: opening={}, purchases={}, transfersIn={}, sales={}, transfersOut={}, closing={}",
            openingBalance, purchases, transfersIn, sales, transfersOut, closingBalance);

        return saved;
    }

    /**
     * Ă–sszes valuta napi mĂ©rlege (egy napra)
     */
    public List<DailyBalance> calculateAllCurrenciesForDay(UUID branchId, LocalDate date) {
        log.info("Ă–sszes valuta napi mĂ©rlege: branchId={}, date={}", branchId, date);

        // AktĂ­v valutĂˇk
        List<Currency> currencies = currencyRepository.findActiveByCompany(SecurityUtils.getCurrentCompanyId());

        return currencies.stream()
            .map(currency -> calculateDailyBalance(branchId, date, currency.getCode()))
            .collect(Collectors.toList());
    }

    /**
     * NyitĂł kĂ©szlet szĂˇmĂ­tĂˇsa (elĹ‘zĹ‘ nap zĂˇrĂł VAGY elĹ‘zĹ‘ hĂł vĂ©gi zĂˇrĂł)
     */
    private BigDecimal getOpeningBalance(UUID branchId, LocalDate date, String currencyCode) {
        // 1. ElĹ‘zĹ‘ nap zĂˇrĂł
        LocalDate previousDay = date.minusDays(1);
        BigDecimal previousClosing = dailyBalanceRepository
            .findClosingBalance(branchId, currencyCode, previousDay)
            .orElse(null);

        // NULL vĂ©delem: ha az elĹ‘zĹ‘ nap lĂ©tezik DE closingBalance NULL â†’ 0
        if (previousClosing != null) {
            return previousClosing;
        }

        // 2. Ha az elĹ‘zĹ‘ nap nincs (pl. hĂłnap elsĹ‘ napja) â†’ elĹ‘zĹ‘ hĂł vĂ©gi zĂˇrĂł
        LocalDate previousMonthEnd = date.minusMonths(1).withDayOfMonth(
            date.minusMonths(1).lengthOfMonth()
        );
        
        List<DailyBalance> monthlyClosing = dailyBalanceRepository.findMonthlyClosingBalance(
            branchId,
            currencyCode,
            previousMonthEnd.getYear(),
            previousMonthEnd.getMonthValue()
        );

        if (!monthlyClosing.isEmpty() && monthlyClosing.get(0).getClosingBalance() != null) {
            return monthlyClosing.get(0).getClosingBalance();
        }

        // 3. Ha semmi nincs â†’ 0 (elsĹ‘ nap az irodĂˇban)
        log.warn("Nincs elĹ‘zĹ‘ napi/havi kĂ©szlet: branchId={}, currency={}, date={} â†’ nyitĂł=0",
            branchId, currencyCode, date);
        return BigDecimal.ZERO;
    }

    /**
     * ĂtvĂ©tel (transfer IN) szĂˇmĂ­tĂˇsa
     * 
     * Transfer query a TransferRepository-bĂł nincs implementĂˇlva â€” future scope.
     * Ha a rendszer iroda-kĂ¶zĂ¶tti ĂˇtutalĂˇst hasznĂˇl, implementĂˇld ezt a metĂłdust.
     * 
     * @param branchId Iroda ID
     * @param date DĂˇtum
     * @param currencyCode Valuta kĂłd
     * @return Transfer IN Ă¶sszeg (jelenleg mindig 0)
     */
    private BigDecimal getTransfersIn(UUID branchId, LocalDate date, String currencyCode) {
        return transferRepository.sumTransfersIn(branchId, date, currencyCode);
    }

    /**
     * ĂtadĂˇs (transfer OUT) szĂˇmĂ­tĂˇsa
     * 
     * Transfer query a TransferRepository-bĂł nincs implementĂˇlva â€” future scope.
     * Ha a rendszer iroda-kĂ¶zĂ¶tti ĂˇtutalĂˇst hasznĂˇl, implementĂˇld ezt a metĂłdust.
     * 
     * @param branchId Iroda ID
     * @param date DĂˇtum
     * @param currencyCode Valuta kĂłd
     * @return Transfer OUT Ă¶sszeg (jelenleg mindig 0)
     */
    private BigDecimal getTransfersOut(UUID branchId, LocalDate date, String currencyCode) {
        return transferRepository.sumTransfersOut(branchId, date, currencyCode);
    }

    /**
     * Napi mĂ©rleg lezĂˇrĂˇsa
     */
    public void closeDailyBalance(UUID branchId, LocalDate date, String currencyCode) {
        DailyBalance balance = dailyBalanceRepository
            .findByBranchIdAndBalanceDateAndCurrencyCode(branchId, date, currencyCode)
            .orElseThrow(() -> new ValidationException(
                String.format("Nincs napi mĂ©rleg: %s / %s", date, currencyCode)
            ));

        if (balance.getIsClosed()) {
            throw new ValidationException("A mĂ©rleg mĂˇr lezĂˇrva!");
        }

        balance.setIsClosed(true);
        balance.setClosedAt(LocalDateTime.now());
        balance.setClosedBy(SecurityUtils.getCurrentWorkerCode());

        dailyBalanceRepository.save(balance);

        auditLogService.log(
            "DAILY_BALANCE_CLOSED",
            String.format("Napi mĂ©rleg lezĂˇrva: %s / %s", date, currencyCode),
            branchId.toString()
        );

        log.info("Napi mĂ©rleg lezĂˇrva: branchId={}, date={}, currency={}", branchId, date, currencyCode);
    }

    /**
     * LeltĂˇri eltĂ©rĂ©s rĂ¶gzĂ­tĂ©se
     */
    public void recordActualStock(
        UUID branchId,
        LocalDate date,
        String currencyCode,
        BigDecimal actualStock,
        String note
    ) {
        DailyBalance balance = dailyBalanceRepository
            .findByBranchIdAndBalanceDateAndCurrencyCode(branchId, date, currencyCode)
            .orElseThrow(() -> new ValidationException(
                String.format("Nincs napi mĂ©rleg: %s / %s", date, currencyCode)
            ));

        balance.setActualStock(actualStock);
        balance.calculateDifference();
        
        if (note != null && !note.isBlank()) {
            balance.setDifferenceNote(note);
        }

        dailyBalanceRepository.save(balance);

        log.info("LeltĂˇri eltĂ©rĂ©s rĂ¶gzĂ­tve: branchId={}, date={}, currency={}, actual={}, difference={}",
            branchId, date, currencyCode, actualStock, balance.getDifference());
    }

    /**
     * Napi mĂ©rleg lekĂ©rdezĂ©se
     */
    @Transactional(readOnly = true)
    public List<DailyBalance> getDailyBalances(UUID branchId, LocalDate date) {
        return dailyBalanceRepository.findByBranchIdAndBalanceDate(branchId, date);
    }

    /**
     * Havi mĂ©rlegek lekĂ©rdezĂ©se
     */
    @Transactional(readOnly = true)
    public List<DailyBalance> getMonthlyBalances(UUID branchId, int year, int month) {
        return dailyBalanceRepository.findByBranchAndMonth(branchId, year, month);
    }
}

