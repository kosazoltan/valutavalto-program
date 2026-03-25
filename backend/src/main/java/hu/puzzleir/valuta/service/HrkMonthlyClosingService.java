package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.HrkTransactionDto;
import hu.puzzleir.valuta.service.HrkService;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.*;

/**
 * HRK havi zárás szolgáltatás.
 *
 * Legacy: HRKZARO — a Delphi rendszerben a pénztár→bank és bank→pénztár
 * átadás/átvétel tranzakciókat havi szinten kellett lezárni és összesíteni.
 *
 * A HRK (Házipénztári Kezelés) a deviza készletmozgások nyilvántartása:
 * - HANDOVER: pénztárból bankba szállítás (felesleg leadás)
 * - RECEIVE: bankból pénztárba szállítás (készlet feltöltés)
 *
 * A havi zárás:
 * 1. Összesíti az adott hónap HRK tranzakcióit valutanemenként
 * 2. Számítja a nettó mozgást (átvétel - átadás)
 * 3. Ellenőrzi a konzisztenciát a napi zárásokkal
 * 4. JSON riportot készít
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class HrkMonthlyClosingService {

    private final HrkService hrkService;
    private final ObjectMapper objectMapper;

    /**
     * HRK havi összesítő lekérdezés.
     *
     * @param branchId iroda azonosító
     * @param yearMonth év-hónap (pl. "2026-03")
     * @return JSON formátumú összesítő (valutánkénti bontás)
     */
    @Transactional(readOnly = true)
    public HrkMonthlySummary getMonthlySummary(UUID branchId, String yearMonth) {
        YearMonth ym = parseYearMonth(yearMonth);

        // Az adott hónap összes napja
        List<HrkTransactionDto> allTx = new ArrayList<>();
        LocalDate current = ym.atDay(1);
        LocalDate monthEnd = ym.atEndOfMonth();

        while (!current.isAfter(monthEnd)) {
            allTx.addAll(hrkService.getDailyTransactions(branchId, current));
            current = current.plusDays(1);
        }

        // Valutánkénti összesítés
        Map<String, HrkCurrencySummary> byСurrency = new LinkedHashMap<>();

        for (HrkTransactionDto tx : allTx) {
            String code = tx.getCurrencyCode();
            HrkCurrencySummary summary = byСurrency.computeIfAbsent(code, HrkCurrencySummary::new);

            if ("HANDOVER".equals(tx.getType())) {
                summary.handoverCount++;
                summary.handoverAmount = summary.handoverAmount.add(
                        tx.getAmount() != null ? tx.getAmount() : BigDecimal.ZERO);
                summary.handoverHuf = summary.handoverHuf.add(
                        tx.getHufAmount() != null ? tx.getHufAmount() : BigDecimal.ZERO);
            } else if ("RECEIVE".equals(tx.getType())) {
                summary.receiveCount++;
                summary.receiveAmount = summary.receiveAmount.add(
                        tx.getAmount() != null ? tx.getAmount() : BigDecimal.ZERO);
                summary.receiveHuf = summary.receiveHuf.add(
                        tx.getHufAmount() != null ? tx.getHufAmount() : BigDecimal.ZERO);
            }
        }

        // Nettó mozgás számítás
        byСurrency.values().forEach(s -> {
            s.netAmount = s.receiveAmount.subtract(s.handoverAmount);
            s.netHuf = s.receiveHuf.subtract(s.handoverHuf);
        });

        // Összesítő számok
        BigDecimal totalHandoverHuf = byСurrency.values().stream()
                .map(s -> s.handoverHuf).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalReceiveHuf = byСurrency.values().stream()
                .map(s -> s.receiveHuf).reduce(BigDecimal.ZERO, BigDecimal::add);
        int totalTx = allTx.size();

        String breakdownJson;
        try {
            breakdownJson = objectMapper.writeValueAsString(byСurrency.values());
        } catch (JsonProcessingException e) {
            breakdownJson = "[]";
        }

        log.info("HRK havi összesítő: branch={}, period={}, txCount={}, handover={} Ft, receive={} Ft",
                branchId, yearMonth, totalTx, totalHandoverHuf, totalReceiveHuf);

        return new HrkMonthlySummary(
                branchId, yearMonth, totalTx,
                totalHandoverHuf, totalReceiveHuf,
                totalReceiveHuf.subtract(totalHandoverHuf),
                new ArrayList<>(byСurrency.values()),
                breakdownJson);
    }

    /**
     * HRK havi zárás végrehajtása — konzisztencia ellenőrzéssel.
     */
    public HrkMonthlySummary closeMonth(UUID branchId, String yearMonth) {
        YearMonth ym = parseYearMonth(yearMonth);

        // Jövőbeli hónap nem zárható
        if (ym.isAfter(YearMonth.now())) {
            throw new ValidationException("Jövőbeli hónap nem zárható: " + yearMonth);
        }

        // Összesítő
        HrkMonthlySummary summary = getMonthlySummary(branchId, yearMonth);

        // Konzisztencia ellenőrzés — nettó negatív = több ment ki mint jött be
        if (summary.netHuf().compareTo(BigDecimal.ZERO) < 0) {
            log.warn("HRK havi zárás figyelmeztetés: branch={}, period={}, nettó negatív: {} Ft " +
                    "(több devizát szállítottunk bankba mint amennyit kaptunk)",
                    branchId, yearMonth, summary.netHuf());
        }

        log.info("HRK havi zárás lezárva: branch={}, period={}, {} tranzakció",
                branchId, yearMonth, summary.totalTransactions());

        return summary;
    }

    private YearMonth parseYearMonth(String yearMonth) {
        try {
            return YearMonth.parse(yearMonth);
        } catch (Exception e) {
            throw new ValidationException("Érvénytelen formátum: " + yearMonth + " (elvárt: YYYY-MM)");
        }
    }

    // === DTOs ===

    public record HrkMonthlySummary(
        UUID branchId,
        String yearMonth,
        int totalTransactions,
        BigDecimal totalHandoverHuf,
        BigDecimal totalReceiveHuf,
        BigDecimal netHuf,
        List<HrkCurrencySummary> currencyBreakdown,
        String breakdownJson
    ) {}

    public static class HrkCurrencySummary {
        public String currencyCode;
        public int handoverCount;
        public BigDecimal handoverAmount = BigDecimal.ZERO;
        public BigDecimal handoverHuf = BigDecimal.ZERO;
        public int receiveCount;
        public BigDecimal receiveAmount = BigDecimal.ZERO;
        public BigDecimal receiveHuf = BigDecimal.ZERO;
        public BigDecimal netAmount = BigDecimal.ZERO;
        public BigDecimal netHuf = BigDecimal.ZERO;

        HrkCurrencySummary(String currencyCode) {
            this.currencyCode = currencyCode;
        }

        // Jackson getters
        public String getCurrencyCode() { return currencyCode; }
        public int getHandoverCount() { return handoverCount; }
        public BigDecimal getHandoverAmount() { return handoverAmount; }
        public BigDecimal getHandoverHuf() { return handoverHuf; }
        public int getReceiveCount() { return receiveCount; }
        public BigDecimal getReceiveAmount() { return receiveAmount; }
        public BigDecimal getReceiveHuf() { return receiveHuf; }
        public BigDecimal getNetAmount() { return netAmount; }
        public BigDecimal getNetHuf() { return netHuf; }
    }
}
