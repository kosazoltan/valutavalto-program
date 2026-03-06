package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Company;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.CompanyRepository;
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
 * Napi készlet / forgalom szolgáltatás.
 * 
 * A Delphi napi záráskor számolta a készletmozgást:
 * nyitó + vétel + átvétel - eladás - átadás = záró
 * 
 * Ez a számviteli lánc alapja, nélkülözhetetlen a havi záráshoz.
 * 
 * Legacy: NAPZAR.DLL — napi forgalom számítás
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
     * Napi mérleg számítása egy iroda + dátum + valuta kombinációhoz.
     * 
     * @param branchId Iroda ID
     * @param date Dátum
     * @param currencyCode Valuta kód
     * @return Számított DailyBalance
     */
    public DailyBalance calculateDailyBalance(UUID branchId, LocalDate date, String currencyCode) {
        log.info("Napi mérleg számítása: branchId={}, date={}, currency={}", branchId, date, currencyCode);

        // Cég azonosító
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
            .orElseThrow(() -> new ValidationException("Cég nem található: " + companyId));

        // Ellenőrzés: már létezik-e
        DailyBalance existing = dailyBalanceRepository
            .findByBranchIdAndBalanceDateAndCurrencyCode(branchId, date, currencyCode)
            .orElse(null);

        if (existing != null && existing.getIsClosed()) {
            throw new ValidationException(
                String.format("A %s napi mérleg már lezárva! (%s)", date, currencyCode)
            );
        }

        // 1. Nyitó készlet (előző nap záró VAGY előző hó végi záró)
        BigDecimal openingBalance = getOpeningBalance(branchId, date, currencyCode);

        // 2. Vásárlás (BUY típusú tranzakciók — beérkezett valuta)
        BigDecimal purchases = transactionRepository.sumDailyTurnover(
            branchId, date, TransactionType.BUY
        );
        if (purchases == null) {
            purchases = BigDecimal.ZERO;
        }

        // 3. Eladás (SELL típusú tranzakciók — kiadott valuta)
        BigDecimal sales = transactionRepository.sumDailyTurnover(
            branchId, date, TransactionType.SELL
        );
        if (sales == null) {
            sales = BigDecimal.ZERO;
        }

        // 4. Átvétel más irodától (transfer IN)
        BigDecimal transfersIn = getTransfersIn(branchId, date, currencyCode);

        // 5. Átadás más irodába (transfer OUT)
        BigDecimal transfersOut = getTransfersOut(branchId, date, currencyCode);

        // 6. Záró készlet számítása
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

        // Mentés
        DailyBalance saved = dailyBalanceRepository.save(balance);

        log.info("Napi mérleg kész: opening={}, purchases={}, transfersIn={}, sales={}, transfersOut={}, closing={}",
            openingBalance, purchases, transfersIn, sales, transfersOut, closingBalance);

        return saved;
    }

    /**
     * Összes valuta napi mérlege (egy napra)
     */
    public List<DailyBalance> calculateAllCurrenciesForDay(UUID branchId, LocalDate date) {
        log.info("Összes valuta napi mérlege: branchId={}, date={}", branchId, date);

        // Aktív valuták
        List<Currency> currencies = currencyRepository.findActiveByCompany(SecurityUtils.getCurrentCompanyId());

        return currencies.stream()
            .map(currency -> calculateDailyBalance(branchId, date, currency.getCode()))
            .collect(Collectors.toList());
    }

    /**
     * Nyitó készlet számítása (előző nap záró VAGY előző hó végi záró)
     */
    private BigDecimal getOpeningBalance(UUID branchId, LocalDate date, String currencyCode) {
        // 1. Előző nap záró
        LocalDate previousDay = date.minusDays(1);
        BigDecimal previousClosing = dailyBalanceRepository
            .findClosingBalance(branchId, currencyCode, previousDay)
            .orElse(null);

        // NULL védelem: ha az előző nap létezik DE closingBalance NULL → 0
        if (previousClosing != null) {
            return previousClosing;
        }

        // 2. Ha az előző nap nincs (pl. hónap első napja) → előző hó végi záró
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

        // 3. Ha semmi nincs → 0 (első nap az irodában)
        log.warn("Nincs előző napi/havi készlet: branchId={}, currency={}, date={} → nyitó=0",
            branchId, currencyCode, date);
        return BigDecimal.ZERO;
    }

    /**
     * Átvétel (transfer IN) számítása
     * 
     * TODO: Transfer funkció nincs implementálva — future scope.
     * Ha a rendszer iroda-közötti átutalást használ, implementáld ezt a metódust.
     * 
     * @param branchId Iroda ID
     * @param date Dátum
     * @param currencyCode Valuta kód
     * @return Transfer IN összeg (jelenleg mindig 0)
     */
    private BigDecimal getTransfersIn(UUID branchId, LocalDate date, String currencyCode) {
        // Transfer entitás lekérdezés (ha van Transfer tábla)
        // return transferRepository.sumTransfersIn(branchId, date, currencyCode);
        return BigDecimal.ZERO;
    }

    /**
     * Átadás (transfer OUT) számítása
     * 
     * TODO: Transfer funkció nincs implementálva — future scope.
     * Ha a rendszer iroda-közötti átutalást használ, implementáld ezt a metódust.
     * 
     * @param branchId Iroda ID
     * @param date Dátum
     * @param currencyCode Valuta kód
     * @return Transfer OUT összeg (jelenleg mindig 0)
     */
    private BigDecimal getTransfersOut(UUID branchId, LocalDate date, String currencyCode) {
        // Transfer entitás lekérdezés (ha van Transfer tábla)
        // return transferRepository.sumTransfersOut(branchId, date, currencyCode);
        return BigDecimal.ZERO;
    }

    /**
     * Napi mérleg lezárása
     */
    public void closeDailyBalance(UUID branchId, LocalDate date, String currencyCode) {
        DailyBalance balance = dailyBalanceRepository
            .findByBranchIdAndBalanceDateAndCurrencyCode(branchId, date, currencyCode)
            .orElseThrow(() -> new ValidationException(
                String.format("Nincs napi mérleg: %s / %s", date, currencyCode)
            ));

        if (balance.getIsClosed()) {
            throw new ValidationException("A mérleg már lezárva!");
        }

        balance.setIsClosed(true);
        balance.setClosedAt(LocalDateTime.now());
        balance.setClosedBy(SecurityUtils.getCurrentUsername());

        dailyBalanceRepository.save(balance);

        auditLogService.log(
            "DAILY_BALANCE_CLOSED",
            String.format("Napi mérleg lezárva: %s / %s", date, currencyCode),
            branchId.toString()
        );

        log.info("Napi mérleg lezárva: branchId={}, date={}, currency={}", branchId, date, currencyCode);
    }

    /**
     * Leltári eltérés rögzítése
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
                String.format("Nincs napi mérleg: %s / %s", date, currencyCode)
            ));

        balance.setActualStock(actualStock);
        balance.calculateDifference();
        
        if (note != null && !note.isBlank()) {
            balance.setDifferenceNote(note);
        }

        dailyBalanceRepository.save(balance);

        log.info("Leltári eltérés rögzítve: branchId={}, date={}, currency={}, actual={}, difference={}",
            branchId, date, currencyCode, actualStock, balance.getDifference());
    }

    /**
     * Napi mérleg lekérdezése
     */
    @Transactional(readOnly = true)
    public List<DailyBalance> getDailyBalances(UUID branchId, LocalDate date) {
        return dailyBalanceRepository.findByBranchIdAndBalanceDate(branchId, date);
    }

    /**
     * Havi mérlegek lekérdezése
     */
    @Transactional(readOnly = true)
    public List<DailyBalance> getMonthlyBalances(UUID branchId, int year, int month) {
        return dailyBalanceRepository.findByBranchAndMonth(branchId, year, month);
    }
}
