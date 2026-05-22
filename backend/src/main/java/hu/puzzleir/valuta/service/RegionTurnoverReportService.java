package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.RegionTurnoverReportDto;
import hu.puzzleir.valuta.dto.report.RegionTurnoverReportDto.RegionLineDto;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * G23 (EXCMD b8-forgalom FR-13..15): körzet-szintű havi forgalmi/trend riport.
 *
 * <p>Régiónként (branch.regionCode) összesíti a havi forgalmat, és az előző
 * hónaphoz képest trend%-ot számít. Read-only, multi-tenant
 * (company.id = aktuális cég). Nincs adatbázis-írás, nincs migráció.</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class RegionTurnoverReportService {

    private static final String UNKNOWN_REGION = "EGYÉB";

    private final TransactionRepository transactionRepository;

    /**
     * Körzet-szintű havi forgalmi riport.
     *
     * @param yearMonth a hónap "YYYY-MM" formátumban (kötelező)
     * @return régiónkénti forgalmi sorok + trend% az előző hónaphoz képest
     */
    public RegionTurnoverReportDto getRegionTurnover(String yearMonth) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        YearMonth ym = parseYearMonth(yearMonth);
        YearMonth prev = ym.minusMonths(1);

        List<RegionAggregate> current = aggregate(companyId, ym);
        List<RegionAggregate> previous = aggregate(companyId, prev);

        // Copilot/Sourcery #782: az előző hó forgalmát régiókód → összeg map-be
        // indexeljük (O(1) lookup az O(n²) stream-filter helyett).
        Map<String, BigDecimal> prevTurnoverByRegion = new LinkedHashMap<>();
        BigDecimal grandPrevTotal = BigDecimal.ZERO;
        for (RegionAggregate p : previous) {
            BigDecimal pt = p.buyHuf.add(p.sellHuf);
            prevTurnoverByRegion.put(p.regionCode, pt);
            // A teljes előző-havi forgalom MINDEN régiót tartalmaz (azokat is,
            // amelyeknek a jelenlegi hónapban nincs forgalma) — Copilot #782 fix.
            grandPrevTotal = grandPrevTotal.add(pt);
        }

        List<RegionLineDto> lines = new ArrayList<>();
        BigDecimal grandTotal = BigDecimal.ZERO;

        for (RegionAggregate cur : current) {
            BigDecimal prevTurnover = prevTurnoverByRegion.getOrDefault(cur.regionCode, BigDecimal.ZERO);

            BigDecimal total = cur.buyHuf.add(cur.sellHuf);
            BigDecimal avgDaily = cur.activeDays > 0
                ? total.divide(BigDecimal.valueOf(cur.activeDays), 0, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

            grandTotal = grandTotal.add(total);

            lines.add(RegionLineDto.builder()
                .regionCode(cur.regionCode)
                .buyCount(cur.buyCount)
                .sellCount(cur.sellCount)
                .buyHuf(cur.buyHuf)
                .sellHuf(cur.sellHuf)
                .totalTurnoverHuf(total)
                .distinctCustomers(cur.distinctCustomers)
                .activeDays(cur.activeDays)
                .avgDailyTurnoverHuf(avgDaily)
                .previousTurnoverHuf(prevTurnover)
                .trendPercent(trendPercent(total, prevTurnover))
                .build());
        }

        lines.sort(Comparator.comparing(RegionLineDto::getRegionCode));

        return RegionTurnoverReportDto.builder()
            .yearMonth(yearMonth)
            .previousYearMonth(prev.toString())
            .regions(lines)
            .totalTurnoverHuf(grandTotal)
            .previousTotalTurnoverHuf(grandPrevTotal)
            .totalTrendPercent(trendPercent(grandTotal, grandPrevTotal))
            .build();
    }

    /**
     * "YYYY-MM" parse. Hibás formátum → ValidationException (HTTP 400),
     * nem nyers DateTimeParseException (ami 500-at adna) — Copilot #782.
     */
    private YearMonth parseYearMonth(String yearMonth) {
        try {
            return YearMonth.parse(yearMonth);
        } catch (DateTimeParseException | NullPointerException e) {
            throw new ValidationException(
                "Érvénytelen hónap formátum (várt: YYYY-MM): " + yearMonth);
        }
    }

    /**
     * Trend% = (aktuális - előző) / előző * 100, 1 tizedesre kerekítve.
     * Ha az előző 0 és az aktuális > 0 → 100% (új forgalom); mindkettő 0 → 0%.
     */
    private BigDecimal trendPercent(BigDecimal current, BigDecimal previous) {
        if (previous == null || previous.signum() == 0) {
            return (current != null && current.signum() > 0)
                ? BigDecimal.valueOf(100)
                : BigDecimal.ZERO;
        }
        return current.subtract(previous)
            .multiply(BigDecimal.valueOf(100))
            .divide(previous, 1, RoundingMode.HALF_UP);
    }

    private List<RegionAggregate> aggregate(UUID companyId, YearMonth ym) {
        LocalDate start = ym.atDay(1);
        LocalDate end = ym.atEndOfMonth();
        List<Object[]> rows = transactionRepository.aggregateRegionTurnover(companyId, start, end);

        List<RegionAggregate> result = new ArrayList<>();
        for (Object[] r : rows) {
            String regionCode = r[0] != null ? (String) r[0] : UNKNOWN_REGION;
            result.add(new RegionAggregate(
                regionCode,
                toLong(r[1]),
                toLong(r[2]),
                toBigDecimal(r[3]),
                toBigDecimal(r[4]),
                toLong(r[5]),
                toLong(r[6])
            ));
        }
        return result;
    }

    private long toLong(Object o) {
        return o instanceof Number n ? n.longValue() : 0L;
    }

    private BigDecimal toBigDecimal(Object o) {
        // A query SUM(hufAmount) BigDecimal-t ad; a Number-fallback csak
        // védelmi ág — ott is string-konstruktor a double-kerekítés ellen
        // (Copilot #782 pontosságvesztés-figyelmeztetés).
        return o instanceof BigDecimal b ? b
            : o instanceof Number n ? new BigDecimal(n.toString())
            : BigDecimal.ZERO;
    }

    /** Belső aggregátum a query Object[] sorból. */
    private record RegionAggregate(
        String regionCode,
        long buyCount,
        long sellCount,
        BigDecimal buyHuf,
        BigDecimal sellHuf,
        long distinctCustomers,
        long activeDays) {
    }
}
