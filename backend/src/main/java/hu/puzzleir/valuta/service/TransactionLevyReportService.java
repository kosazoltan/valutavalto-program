package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.levy.AppliedRateDto;
import hu.puzzleir.valuta.dto.levy.MonthlySummaryDto;
import hu.puzzleir.valuta.dto.levy.TransactionLevyReportDto;
import hu.puzzleir.valuta.dto.levy.TypeGroupDto;
import hu.puzzleir.valuta.entity.TransactionLevyRateHistory;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.TransactionLevyRateHistoryRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.TransactionLevyCalculator;
import hu.puzzleir.valuta.util.TransactionLevyCalculator.LevyAmounts;
import hu.puzzleir.valuta.util.TransactionLevyCalculator.LevyRate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.UUID;

/**
 * FK-099 — pénzügyi tranzakciós illeték riport (read-only use case, D11).
 *
 * <p>RBAC + ACCESS_DENIED audit a service-ben (D10), hogy a megtagadás
 * audit-sort kapjon, ne csak a Spring filter 403-at.</p>
 *
 * <p>Univerzum (ticket §5): EGY query / kérés (NFR-4) — önálló BUY/SELL
 * (conversion_group_id IS NULL, financial_effective = true) és a konverzió-
 * csoportok mindhárom sora. A konverzió EGYSZER adózik (C2/FR-5): a parent
 * CONVERSION hufAmountja, parent nélkül a convBuy-é (D6). Flag TRUE → egy
 * illeték-pár a Konverzió oszlopcsoportban; flag FALSE → dokumentált fallback
 * (convBuy → Vétel, convSell → Eladás). A konverzió a havi panelbe NEM számít
 * be (TBD-3 OUT).</p>
 *
 * <p>D7 fail-closed: ha egy tranzakció-dátumra nincs hatályos ráta-sor, a
 * kérés ValidationException-nel (HTTP 400) elutasítva — nincs kód-default.</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class TransactionLevyReportService {

    /** FK-099 hibakód: az illeték-riport szerep-megtagadása. */
    public static final String ERR_REPORT_ROLE = "VV-AUTH-006";
    public static final String ACTION_ACCESS_DENIED = "ACCESS_DENIED";
    private static final String AUDIT_ENTITY_TYPE = "TRANSACTION_LEVY_REPORT";
    private static final String ERR_CROSS_TENANT = "VV-TENANT-001";

    /** D15: a riport-időszak felső korlátja (inclusive nap-szám). */
    private static final int MAX_RANGE_DAYS = 62;

    private static final Set<String> ALLOWED_ROLES = Set.of(
            "ROLE_FOERTEKTAR",
            "ROLE_UGYVEZETO",
            "ROLE_ADMIN",
            "ROLE_BELSO_ELLENOR",
            "ROLE_IRODAVEZETO");

    /** Object[] vetületi oszlop-indexek — a query és a fold szerződése (pitfall 7). */
    private static final int IDX_DATE = 0;
    private static final int IDX_BRANCH_ID = 1;
    private static final int IDX_BRANCH_CODE = 2;
    private static final int IDX_BRANCH_NAME = 3;
    private static final int IDX_TYPE = 4;
    private static final int IDX_HUF_AMOUNT = 5;
    private static final int IDX_CONVERSION_GROUP_ID = 6;
    private static final int IDX_CUSTOMER_ID = 8;
    /** Round-2 D19: a parent CONVERSION sor státusza (row[9]) — FR-16 csoport-szint. */
    private static final int IDX_STATUS = 9;

    private final TransactionRepository transactionRepository;
    private final TransactionLevyRateHistoryRepository rateHistoryRepository;
    private final BranchRepository branchRepository;
    private final AuditLogService auditLogService;

    /**
     * Riport számítása a megadott (inclusive) időszakra, opcionális iroda-szűréssel.
     *
     * <p>Sorrend (pitfall 23): előbb RBAC (egy illetéktelen hívó ne
     * különböztethesse meg a valid és invalid tartományt hitelesítés előtt),
     * aztán a batchelt intervallum-validáció (D8/D15), majd a tenant- és
     * ráta-feloldás.</p>
     */
    public TransactionLevyReportDto getReport(UUID branchId, LocalDate from, LocalDate to) {
        assertAuthorized();
        validateRange(from, to);

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (branchId != null) {
            // FR-19: idegen tenant iroda → 404 VV-TENANT-001, létezés nem szivárog.
            branchRepository.findByIdAndCompanyId(branchId, companyId)
                    .orElseThrow(() -> new BusinessException(
                            "Iroda nem található.", ERR_CROSS_TENANT, HttpStatus.NOT_FOUND));
        }

        List<LevyRate> ratesDesc = rateHistoryRepository
                .findByCompanyIdOrderByEffectiveFromDesc(companyId)
                .stream()
                .map(TransactionLevyReportService::toLevyRate)
                .toList();

        List<Object[]> sourceRows =
                transactionRepository.findTransactionLevySourceRows(companyId, branchId, from, to);

        FoldState state = new FoldState();
        for (Object[] sourceRow : sourceRows) {
            SourceRowData data = SourceRowData.of(sourceRow);
            if (data.conversionGroupId() == null) {
                state.standalone.add(data);
            } else {
                state.conversionGroups
                        .computeIfAbsent(data.conversionGroupId(), key -> new ArrayList<>())
                        .add(data);
            }
        }

        for (SourceRowData data : state.standalone) {
            LevyRate rate = resolveRateOrFailClosed(ratesDesc, data.date());
            LevyAmounts amounts = TransactionLevyCalculator.compute(data.hufAmount(), rate);
            state.recordAppliedRate(rate);

            TransactionLevyReportDto.Row row = rowFor(state, data.date(), data);
            TypeGroupDto group = data.type() == TransactionType.BUY ? row.getBuy() : row.getSell();
            addLevy(group, amounts);
            if (amounts.aboveThreshold()) {
                row.setLargeBaseHuf(row.getLargeBaseHuf().add(data.hufAmount()));
            }
            row.setLevyTotal(row.getLevyTotal()
                    .add(amounts.baseLevy()).add(amounts.supplementLevy()));

            // FR-12/13/14: a havi panel CSAK az önálló vétel/eladás tételekből épül.
            accumulateMonthlyPanel(state.monthly, data, amounts);
        }

        for (Map.Entry<UUID, List<SourceRowData>> entry : state.conversionGroups.entrySet()) {
            foldConversionGroup(state, ratesDesc, entry.getValue());
        }

        // D1 (round-3): sorrend-szerződés (TransactionLevyReportDto.rows): date ASC,
        // branchCode ASC. A rowsByKey beszúrás-rendű (az önálló sorok foldolódnak
        // előbb), ezért CSAK a rendezés garantálja a szerződést — sort csak,
        // újra-aggregálás NINCS. A nullsLast csak a teljesítési irányt tűzi (a
        // riport-sorokon date/branchCode sosem null; a totals külön épül).
        List<TransactionLevyReportDto.Row> rows = state.rowsByKey.values().stream()
                .sorted(Comparator
                        .comparing(TransactionLevyReportDto.Row::getDate,
                                Comparator.nullsLast(Comparator.naturalOrder()))
                        .thenComparing(TransactionLevyReportDto.Row::getBranchCode,
                                Comparator.nullsLast(Comparator.naturalOrder())))
                .toList();
        return TransactionLevyReportDto.builder()
                .from(from)
                .to(to)
                .appliedRates(List.copyOf(state.appliedRates.values()))
                .rows(rows)
                .totals(buildTotals(rows))
                .monthlySummary(state.monthly.build())
                .build();
    }

    // ============================ KONVERZIÓ-FOLD (D6/FR-5) ============================

    private void foldConversionGroup(FoldState state, List<LevyRate> ratesDesc,
                                     List<SourceRowData> groupRows) {
        SourceRowData parent = groupRows.stream()
                .filter(row -> row.type() == TransactionType.CONVERSION)
                .findFirst().orElse(null);
        SourceRowData convBuy = groupRows.stream()
                .filter(row -> row.type() == TransactionType.BUY)
                .findFirst().orElse(null);
        SourceRowData convSell = groupRows.stream()
                .filter(row -> row.type() == TransactionType.SELL)
                .findFirst().orElse(null);

        // D18/FR-16 (csoport-szint): sztornózott (vagy bármely nem-COMPLETED) parent → az EGÉSZ
        // csoport 0 illetéket ad, a flag FALSE ágon is. A parent TELJES hiánya ettől külön eset (D20).
        if (parent != null && parent.status() != TransactionStatus.COMPLETED) {
            log.info("FK-099: konverzió-csoport kihagyva, a parent nem COMPLETED: group={}, status={}",
                    parent.conversionGroupId(), parent.status());
            return;
        }

        // D6: az illeték-alap a parent CONVERSION hufAmountja; parent nélkül a convBuy-é.
        SourceRowData baseRow = parent != null ? parent : convBuy;
        if (baseRow == null) {
            // Védekező ág: konverzió-csoport convBuy/parent nélkül — nincs illeték-alap.
            log.warn("FK-099: konverzió-csoport parent és convBuy sor nélkül, illeték-alap hiányzik: {}",
                    groupRows.get(0).conversionGroupId());
            return;
        }

        LevyRate rate = resolveRateOrFailClosed(ratesDesc, baseRow.date());
        state.recordAppliedRate(rate);

        if (rate.conversionSingleSide()) {
            // TRUE: egy illeték-pár a Konverzió oszlopcsoportban; Eladás-komponens = 0.
            LevyAmounts amounts = TransactionLevyCalculator.compute(baseRow.hufAmount(), rate);
            TransactionLevyReportDto.Row row = rowFor(state, baseRow.date(), baseRow);
            addLevy(row.getConversion(), amounts);
            if (amounts.aboveThreshold()) {
                row.setLargeBaseHuf(row.getLargeBaseHuf().add(baseRow.hufAmount()));
            }
            row.setLevyTotal(row.getLevyTotal()
                    .add(amounts.baseLevy()).add(amounts.supplementLevy()));
            return;
        }

        // FALSE: dokumentált fallback — convBuy → Vétel, convSell → Eladás, Konverzió nulla.
        if (convBuy != null) {
            foldLeg(state, ratesDesc, convBuy, true);
        }
        if (convSell != null) {
            foldLeg(state, ratesDesc, convSell, false);
        }
    }

    private void foldLeg(FoldState state, List<LevyRate> ratesDesc,
                         SourceRowData leg, boolean isBuyLeg) {
        LevyRate legRate = resolveRateOrFailClosed(ratesDesc, leg.date());
        LevyAmounts amounts = TransactionLevyCalculator.compute(leg.hufAmount(), legRate);
        state.recordAppliedRate(legRate);
        TransactionLevyReportDto.Row row = rowFor(state, leg.date(), leg);
        TypeGroupDto group = isBuyLeg ? row.getBuy() : row.getSell();
        addLevy(group, amounts);
        if (amounts.aboveThreshold()) {
            row.setLargeBaseHuf(row.getLargeBaseHuf().add(leg.hufAmount()));
        }
        row.setLevyTotal(row.getLevyTotal().add(amounts.baseLevy()).add(amounts.supplementLevy()));
    }

    // ============================ HELPEREK ============================

    /** Fold-munkaállapot (D11: nincs párhuzamos stream, tisztán soros fold). */
    private static final class FoldState {
        final Map<RowKey, TransactionLevyReportDto.Row> rowsByKey = new LinkedHashMap<>();
        final List<SourceRowData> standalone = new ArrayList<>();
        final Map<UUID, List<SourceRowData>> conversionGroups = new LinkedHashMap<>();
        final TreeMap<LocalDate, AppliedRateDto> appliedRates = new TreeMap<>();
        final MonthlyPanel monthly = new MonthlyPanel();

        void recordAppliedRate(LevyRate rate) {
            appliedRates.computeIfAbsent(rate.effectiveFrom(), key -> AppliedRateDto.builder()
                    .effectiveFrom(rate.effectiveFrom())
                    .baseRatePercent(rate.baseRatePercent())
                    .baseRateCapHuf(rate.baseRateCapHuf())
                    .supplementRatePercent(rate.supplementRatePercent())
                    .supplementRateCapHuf(rate.supplementRateCapHuf())
                    .conversionSingleSideFlag(rate.conversionSingleSide())
                    .thresholdHuf(TransactionLevyCalculator.thresholdHuf(rate))
                    .build());
        }
    }

    /** FK-095 fold key: egy sor per (date, branchId) — records give equals/hashCode. */
    private record RowKey(LocalDate date, UUID branchId) {}

    private record SourceRowData(LocalDate date, UUID branchId, String branchCode, String branchName,
                                 TransactionType type, BigDecimal hufAmount, UUID conversionGroupId,
                                 String customerId, TransactionStatus status) {
        static SourceRowData of(Object[] row) {
            return new SourceRowData(
                    (LocalDate) row[IDX_DATE],
                    (UUID) row[IDX_BRANCH_ID],
                    (String) row[IDX_BRANCH_CODE],
                    (String) row[IDX_BRANCH_NAME],
                    (TransactionType) row[IDX_TYPE],
                    (BigDecimal) row[IDX_HUF_AMOUNT],
                    (UUID) row[IDX_CONVERSION_GROUP_ID],
                    (String) row[IDX_CUSTOMER_ID],
                    (TransactionStatus) row[IDX_STATUS]);
        }
    }

    private TransactionLevyReportDto.Row rowFor(FoldState state, LocalDate date, SourceRowData data) {
        return state.rowsByKey.computeIfAbsent(
                new RowKey(date, data.branchId()),
                key -> TransactionLevyReportDto.Row.builder()
                        .date(key.date())
                        .branchId(key.branchId())
                        .branchCode(data.branchCode())
                        .branchName(data.branchName())
                        .buy(zeroGroup())
                        .sell(zeroGroup())
                        .conversion(zeroGroup())
                        .largeBaseHuf(BigDecimal.ZERO)
                        .levyTotal(BigDecimal.ZERO)
                        .build());
    }

    private static TypeGroupDto zeroGroup() {
        return TypeGroupDto.builder()
                .normalBaseLevy(BigDecimal.ZERO)
                .normalSupplementLevy(BigDecimal.ZERO)
                .aboveThresholdCount(0)
                .aboveThresholdBaseLevy(BigDecimal.ZERO)
                .aboveThresholdSupplementLevy(BigDecimal.ZERO)
                .build();
    }

    private static void addLevy(TypeGroupDto group, LevyAmounts amounts) {
        if (amounts.aboveThreshold()) {
            group.setAboveThresholdCount(group.getAboveThresholdCount() + 1);
            group.setAboveThresholdBaseLevy(group.getAboveThresholdBaseLevy().add(amounts.baseLevy()));
            group.setAboveThresholdSupplementLevy(
                    group.getAboveThresholdSupplementLevy().add(amounts.supplementLevy()));
        } else {
            group.setNormalBaseLevy(group.getNormalBaseLevy().add(amounts.baseLevy()));
            group.setNormalSupplementLevy(group.getNormalSupplementLevy().add(amounts.supplementLevy()));
        }
    }

    /** FR-12/13/14: havi panel — kizárólag önálló BUY/SELL tételekből. */
    private static void accumulateMonthlyPanel(MonthlyPanel panel, SourceRowData data,
                                               LevyAmounts amounts) {
        boolean isBuy = data.type() == TransactionType.BUY;
        if (isBuy) {
            panel.buyCount++;
        } else {
            panel.sellCount++;
        }
        // JPQL/Java csapda: a customerId oszlop ''-t tárol, nem NULL-t — isBlank-szűrés.
        if (data.customerId() != null && !data.customerId().isBlank()) {
            panel.customerIds.add(data.customerId());
        }
        if (amounts.aboveThreshold()) {
            if (isBuy) {
                panel.aboveThresholdBuyHuf = panel.aboveThresholdBuyHuf.add(data.hufAmount());
            } else {
                panel.aboveThresholdSellHuf = panel.aboveThresholdSellHuf.add(data.hufAmount());
            }
        } else {
            if (isBuy) {
                panel.belowThresholdBuyHuf = panel.belowThresholdBuyHuf.add(data.hufAmount());
            } else {
                panel.belowThresholdSellHuf = panel.belowThresholdSellHuf.add(data.hufAmount());
            }
        }
    }

    private static final class MonthlyPanel {
        long buyCount;
        long sellCount;
        final Set<String> customerIds = new TreeSet<>();
        BigDecimal belowThresholdBuyHuf = BigDecimal.ZERO;
        BigDecimal belowThresholdSellHuf = BigDecimal.ZERO;
        BigDecimal aboveThresholdBuyHuf = BigDecimal.ZERO;
        BigDecimal aboveThresholdSellHuf = BigDecimal.ZERO;

        MonthlySummaryDto build() {
            return MonthlySummaryDto.builder()
                    .buyCount(buyCount)
                    .sellCount(sellCount)
                    .customerCount(customerIds.size())
                    .belowThresholdBuyHuf(belowThresholdBuyHuf)
                    .belowThresholdSellHuf(belowThresholdSellHuf)
                    .aboveThresholdBuyHuf(aboveThresholdBuyHuf)
                    .aboveThresholdSellHuf(aboveThresholdSellHuf)
                    .build();
        }
    }

    /** FR-11: az ÖSSZESEN sor komponensenkénti összeg; date/branch-mezők null-ok. */
    private static TransactionLevyReportDto.Row buildTotals(List<TransactionLevyReportDto.Row> rows) {
        TypeGroupDto buy = zeroGroup();
        TypeGroupDto sell = zeroGroup();
        TypeGroupDto conversion = zeroGroup();
        BigDecimal largeBaseHuf = BigDecimal.ZERO;
        BigDecimal levyTotal = BigDecimal.ZERO;
        for (TransactionLevyReportDto.Row row : rows) {
            sumGroup(buy, row.getBuy());
            sumGroup(sell, row.getSell());
            sumGroup(conversion, row.getConversion());
            largeBaseHuf = largeBaseHuf.add(row.getLargeBaseHuf());
            levyTotal = levyTotal.add(row.getLevyTotal());
        }
        return TransactionLevyReportDto.Row.builder()
                .date(null)
                .branchId(null)
                .branchCode(null)
                .branchName(null)
                .buy(buy)
                .sell(sell)
                .conversion(conversion)
                .largeBaseHuf(largeBaseHuf)
                .levyTotal(levyTotal)
                .build();
    }

    private static void sumGroup(TypeGroupDto target, TypeGroupDto source) {
        target.setNormalBaseLevy(target.getNormalBaseLevy().add(source.getNormalBaseLevy()));
        target.setNormalSupplementLevy(target.getNormalSupplementLevy().add(source.getNormalSupplementLevy()));
        target.setAboveThresholdCount(target.getAboveThresholdCount() + source.getAboveThresholdCount());
        target.setAboveThresholdBaseLevy(target.getAboveThresholdBaseLevy().add(source.getAboveThresholdBaseLevy()));
        target.setAboveThresholdSupplementLevy(
                target.getAboveThresholdSupplementLevy().add(source.getAboveThresholdSupplementLevy()));
    }

    /** D7 fail-closed: nincs hatályos ráta → ValidationException a dátummal. */
    private static LevyRate resolveRateOrFailClosed(List<LevyRate> ratesDesc, LocalDate date) {
        return TransactionLevyCalculator.resolveRate(ratesDesc, date)
                .orElseThrow(() -> new ValidationException(
                        "Nincs hatályos tranzakciósilleték-ráta a(z) " + date
                                + " tranzakció-dátumra. Rögzítsen ráta-sort a hatálybalépés dátumára."));
    }

    private static LevyRate toLevyRate(TransactionLevyRateHistory row) {
        return new LevyRate(
                row.getEffectiveFrom(),
                row.getBaseRatePercent(),
                row.getBaseRateCapHuf(),
                row.getSupplementRatePercent(),
                row.getSupplementRateCapHuf(),
                row.isConversionSingleSideFlag());
    }

    /** D15: batchelt intervallum-validáció (D8) — a két szabály EGY kivételben. */
    private void validateRange(LocalDate from, LocalDate to) {
        List<String> problems = new ArrayList<>();
        if (from.isAfter(to)) {
            problems.add("A kezdő dátum nem lehet a záró dátum után.");
        }
        // B25: fordított intervallumnál is mérjük a távolságot (abszolút nap-szám) —
        // a 62 napos korlát a kézzel barkácsolt kérések elleni védelem.
        if (Math.abs(ChronoUnit.DAYS.between(from, to)) > MAX_RANGE_DAYS - 1) {
            problems.add("A lekérdezett időszak nem haladhatja meg a " + MAX_RANGE_DAYS
                    + " napot (teljesítmény-védelem).");
        }
        if (!problems.isEmpty()) {
            throw new ValidationException(String.join(" ", problems));
        }
    }

    /**
     * FR-17: explicit kód-szintű RBAC, hogy a megtagadás ACCESS_DENIED audit-sort
     * kapjon (HandlingFeeDailySummaryService minta). Fail-closed.
     */
    private void assertAuthorized() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        boolean allowed = authentication != null && authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .anyMatch(ALLOWED_ROLES::contains);
        if (allowed) {
            return;
        }

        auditLogService.logInNewTransaction(
                ACTION_ACCESS_DENIED,
                AUDIT_ENTITY_TYPE,
                null,
                workerIdOrNull(),
                null,
                null,
                null,
                String.format(
                        "{\"KAT\":\"AUTH\",\"error_code\":\"%s\",\"endpoint\":\"/reports/transaction-levy\"}",
                        ERR_REPORT_ROLE));
        log.warn("FK-099 illeték-riport hozzáférés megtagadva");
        throw new AccessDeniedException(
                ERR_REPORT_ROLE + ": nincs jogosultsága a tranzakciós illeték riporthoz.");
    }

    private String workerIdOrNull() {
        try {
            return SecurityUtils.getCurrentWorkerId().toString();
        } catch (ValidationException e) {
            log.debug("FK-099 hozzáférés-megtagadás audit worker-azonosító nélkül: {}", e.getMessage());
            return null;
        }
    }
}
