package hu.puzzleir.valuta.service.central;

import hu.puzzleir.valuta.dto.central.ReceivedDenominationsDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DailyDenominationSnapshot;
import hu.puzzleir.valuta.entity.DenominationAllowed;
import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DailyDenominationSnapshotRepository;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.MnbExchangeRateService;
import hu.puzzleir.valuta.service.MnbSettlementRateService;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.TreeMap;
import java.util.UUID;

/**
 * FK-111 FR-1 / FK-112 FR-1+FR-2: read-only denomination stock view over
 * {@code daily_denomination_snapshot} (written by {@code DailyClosingArchiveService.snapshotDenominations},
 * Delphi: CIMTCopy).
 *
 * <p>Tenant isolation: the branch set always comes from
 * {@link BranchRepository#findByCompanyIdAndIsActiveTrueExcludingCounterparties(UUID)}, and an
 * explicit {@code branchId} is only honoured when it is inside that company-scoped set — a
 * foreign id yields an empty result instead of another company's data.</p>
 *
 * <p>Data quality: a malformed snapshot row is flagged per cell, never dropped and never
 * fatal — the vault manager must see that the row exists AND that it is suspicious.</p>
 *
 * <p>FK-112: the matrix is catalog-aligned (14 fixed face values + "Egyeb") and foreign
 * rows are valued at query-time MNB / manual settlement rates. A missing rate marks that
 * row {@code rateMissing}; it must not take down the rest of the response.</p>
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class ReceivedDenominationsService {

    public static final String FLAG_OK = "OK";
    public static final String FLAG_FRACTIONAL_FACE_VALUE = "FRACTIONAL_FACE_VALUE";
    public static final String FLAG_NON_POSITIVE_FACE_VALUE = "NON_POSITIVE_FACE_VALUE";
    public static final String FLAG_VALUE_MISMATCH = "VALUE_MISMATCH";

    /** Evening closing (Delphi CIMLETTYPE = 1) — the stock snapshot the page reports on. */
    private static final int EVENING_CLOSING_TYPE = 1;

    private static final String HUF = "HUF";
    private static final int MNB_WALKBACK_DAYS = 7;

    private final BranchRepository branchRepository;
    private final DailyDenominationSnapshotRepository snapshotRepository;
    private final DenominationAllowedRepository denominationAllowedRepository;
    private final MnbExchangeRateService mnbExchangeRateService;
    private final MnbSettlementRateService mnbSettlementRateService;

    /**
     * Not {@code readOnly}: {@link MnbExchangeRateService#getRatesForDate} may persist SOAP
     * results into the rate cache (FK-112 TBD-1). Keeping readOnly here would join that write
     * into a read-only transaction and drop the cache update.
     */
    @Transactional(rollbackFor = Exception.class)
    public ReceivedDenominationsDto load(LocalDate date, UUID branchId) {
        if (date == null) {
            throw new ValidationException("A keszlet-lekerdezeshez kotelezo a datum megadasa.");
        }

        final UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> branches =
                branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId);

        List<ReceivedDenominationsDto.BranchOptionDto> branchOptions = branches.stream()
                .map(b -> ReceivedDenominationsDto.BranchOptionDto.builder()
                        .id(b.getId())
                        .code(b.getCode())
                        .name(b.getName())
                        .build())
                .toList();

        List<UUID> queriedBranchIds = resolveQueriedBranchIds(branches, branchId);
        List<DailyDenominationSnapshot> snapshots = queriedBranchIds.isEmpty()
                ? List.of()
                : snapshotRepository.findByBranchIdInAndSnapshotDateAndClosingType(
                        queriedBranchIds, date, EVENING_CLOSING_TYPE);

        Map<String, Set<BigDecimal>> allowedByCurrency = loadAllowedFaceValues(companyId);
        return buildDto(date, branchId, companyId, branchOptions, snapshots, allowedByCurrency);
    }

    /**
     * Company-scoped branch ids to query. An explicit branch outside the company scope returns
     * an empty list, so no snapshot query is issued at all.
     */
    private List<UUID> resolveQueriedBranchIds(List<Branch> branches, UUID branchId) {
        List<UUID> all = branches.stream().map(Branch::getId).filter(Objects::nonNull).toList();
        if (branchId == null) {
            return all;
        }
        if (!all.contains(branchId)) {
            log.warn("FK-111: requested branch is outside the company scope, returning empty result. branchId={}",
                    branchId);
            return List.of();
        }
        return List.of(branchId);
    }

    private Map<String, Set<BigDecimal>> loadAllowedFaceValues(UUID companyId) {
        Map<String, Set<BigDecimal>> allowed = new HashMap<>();
        if (companyId == null) {
            return allowed;
        }
        List<DenominationAllowed> catalog = denominationAllowedRepository.findActiveByCompanyId(companyId);
        for (DenominationAllowed row : catalog) {
            if (row.getCurrency() == null || row.getCurrency().getCode() == null || row.getFaceValue() == null) {
                continue;
            }
            allowed.computeIfAbsent(row.getCurrency().getCode(), ignored -> new LinkedHashSet<>())
                    .add(row.getFaceValue().stripTrailingZeros());
        }
        return allowed;
    }

    private ReceivedDenominationsDto buildDto(
            LocalDate date,
            UUID branchId,
            UUID companyId,
            List<ReceivedDenominationsDto.BranchOptionDto> branchOptions,
            List<DailyDenominationSnapshot> snapshots,
            Map<String, Set<BigDecimal>> allowedByCurrency) {

        // currency -> (face value + type) -> accumulator; TreeMap keeps the cells ordered by
        // face value, reversed below so that the matrix runs from the largest note downwards.
        Map<String, Map<CellKey, CellAccumulator>> byCurrency = new TreeMap<>(currencyOrder());

        for (DailyDenominationSnapshot snapshot : snapshots) {
            String currency = snapshot.getCurrencyCode() == null ? "" : snapshot.getCurrencyCode();
            BigDecimal faceValue = snapshot.getFaceValue() == null ? BigDecimal.ZERO : snapshot.getFaceValue();
            String type = snapshot.getDenominationType() == null ? "BANKNOTE" : snapshot.getDenominationType();
            CellKey key = new CellKey(faceValue.stripTrailingZeros(), type);
            byCurrency
                    .computeIfAbsent(currency, ignored -> new LinkedHashMap<>())
                    .computeIfAbsent(key, ignored -> new CellAccumulator(faceValue, type))
                    .add(snapshot);
        }

        Map<String, MnbExchangeRateCache> ratesForDate = loadRatesSafely(date);

        List<ReceivedDenominationsDto.CurrencyRowDto> rows = new ArrayList<>();
        BigDecimal hufTotalValue = BigDecimal.ZERO;
        BigDecimal currencyValueHuf = BigDecimal.ZERO;
        long totalQuantity = 0L;
        int issueCount = 0;

        for (Map.Entry<String, Map<CellKey, CellAccumulator>> entry : byCurrency.entrySet()) {
            List<CellAccumulator> accumulators = new ArrayList<>(entry.getValue().values());
            accumulators.sort(Comparator
                    .comparing((CellAccumulator a) -> a.faceValue)
                    .reversed()
                    .thenComparing(a -> a.denominationType));

            List<ReceivedDenominationsDto.DenominationCellDto> cells = new ArrayList<>();
            BigDecimal rowValue = BigDecimal.ZERO;
            long rowQuantity = 0L;
            boolean rowHasIssue = false;

            for (CellAccumulator accumulator : accumulators) {
                String flag = accumulator.flag();
                if (!FLAG_OK.equals(flag)) {
                    rowHasIssue = true;
                    issueCount++;
                }
                cells.add(ReceivedDenominationsDto.DenominationCellDto.builder()
                        .faceValue(accumulator.faceValue)
                        .denominationType(accumulator.denominationType)
                        .quantity(accumulator.quantity)
                        .totalValue(accumulator.totalValue)
                        .dataQualityFlag(flag)
                        .build());
                rowValue = rowValue.add(accumulator.totalValue);
                rowQuantity += accumulator.quantity;
            }

            Set<BigDecimal> allowed = allowedByCurrency.getOrDefault(entry.getKey(), Set.of());
            List<ReceivedDenominationsDto.FixedColumnDto> fixedColumns =
                    buildFixedColumns(accumulators, allowed);
            List<ReceivedDenominationsDto.DenominationCellDto> otherCells =
                    buildOtherCells(cells);

            ReceivedDenominationsDto.CurrencyRowDto.CurrencyRowDtoBuilder rowBuilder =
                    ReceivedDenominationsDto.CurrencyRowDto.builder()
                            .currencyCode(entry.getKey())
                            .totalValue(rowValue)
                            .totalQuantity(rowQuantity)
                            .cells(cells)
                            .fixedColumns(fixedColumns)
                            .otherCells(otherCells)
                            .allowedFaceValues(allowed.stream()
                                    .sorted(Comparator.reverseOrder())
                                    .toList())
                            .hasDataQualityIssue(rowHasIssue);

            applyRate(rowBuilder, entry.getKey(), rowValue, date, companyId, ratesForDate);

            ReceivedDenominationsDto.CurrencyRowDto row = rowBuilder.build();
            rows.add(row);

            if (HUF.equals(entry.getKey())) {
                hufTotalValue = rowValue;
            } else if (row.getHufEquivalent() != null) {
                currencyValueHuf = currencyValueHuf.add(row.getHufEquivalent());
            }
            totalQuantity += rowQuantity;
        }

        return ReceivedDenominationsDto.builder()
                .date(date)
                .branchId(branchId)
                .branches(branchOptions)
                .rows(rows)
                .hufTotalValue(hufTotalValue)
                .currencyValueHuf(currencyValueHuf)
                .grandTotalHuf(hufTotalValue.add(currencyValueHuf))
                .fixedFaceValues(ReceivedDenominationsDto.FIXED_FACE_VALUES)
                .currencyCount(rows.size())
                .totalQuantity(totalQuantity)
                .dataQualityIssueCount(issueCount)
                .build();
    }

    private List<ReceivedDenominationsDto.FixedColumnDto> buildFixedColumns(
            List<CellAccumulator> accumulators, Set<BigDecimal> allowed) {
        List<ReceivedDenominationsDto.FixedColumnDto> columns = new ArrayList<>();
        for (BigDecimal faceValue : ReceivedDenominationsDto.FIXED_FACE_VALUES) {
            CellAccumulator match = findCanonicalAccumulator(accumulators, faceValue);
            boolean inCatalog = containsFaceValue(allowed, faceValue);
            Long quantity;
            String flag = FLAG_OK;
            if (match != null) {
                // TBD-3: snapshot stock of an inactivated catalog face value stays visible.
                quantity = match.quantity;
                flag = match.flag();
            } else if (inCatalog) {
                quantity = 0L;
            } else {
                quantity = null;
            }
            columns.add(ReceivedDenominationsDto.FixedColumnDto.builder()
                    .faceValue(faceValue)
                    .quantity(quantity)
                    .inCatalog(inCatalog)
                    .dataQualityFlag(flag)
                    .build());
        }
        return columns;
    }

    private List<ReceivedDenominationsDto.DenominationCellDto> buildOtherCells(
            List<ReceivedDenominationsDto.DenominationCellDto> cells) {
        List<ReceivedDenominationsDto.DenominationCellDto> other = new ArrayList<>();
        for (ReceivedDenominationsDto.DenominationCellDto cell : cells) {
            if (cell.getFaceValue() == null || !isCanonicalFaceValue(cell.getFaceValue())) {
                other.add(cell);
            }
        }
        return other;
    }

    private static boolean isCanonicalFaceValue(BigDecimal faceValue) {
        for (BigDecimal canonical : ReceivedDenominationsDto.FIXED_FACE_VALUES) {
            if (canonical.compareTo(faceValue) == 0) {
                return true;
            }
        }
        return false;
    }

    private static CellAccumulator findCanonicalAccumulator(
            List<CellAccumulator> accumulators, BigDecimal faceValue) {
        for (CellAccumulator accumulator : accumulators) {
            if (accumulator.faceValue.compareTo(faceValue) == 0) {
                return accumulator;
            }
        }
        return null;
    }

    private static boolean containsFaceValue(Set<BigDecimal> allowed, BigDecimal faceValue) {
        for (BigDecimal candidate : allowed) {
            if (candidate.compareTo(faceValue) == 0) {
                return true;
            }
        }
        return false;
    }

    private void applyRate(
            ReceivedDenominationsDto.CurrencyRowDto.CurrencyRowDtoBuilder rowBuilder,
            String currency,
            BigDecimal rowValue,
            LocalDate date,
            UUID companyId,
            Map<String, MnbExchangeRateCache> ratesForDate) {
        if (HUF.equals(currency)) {
            rowBuilder.rateMissing(false).hufEquivalent(rowValue);
            return;
        }
        Optional<ResolvedRate> resolved = resolveUnitRate(ratesForDate, companyId, currency, date);
        if (resolved.isEmpty()) {
            rowBuilder.rateMissing(true);
            return;
        }
        ResolvedRate rate = resolved.get();
        BigDecimal hufEquivalent = HungarianRounding.roundToFive(rowValue.multiply(rate.perUnit()));
        rowBuilder
                .rate(rate.perUnit())
                .rateDate(rate.date())
                .rateSource(rate.source())
                .hufEquivalent(hufEquivalent)
                .rateMissing(false);
    }

    /**
     * DecadeReportService.resolveUnitRate pattern, fail-open: a missing rate is "nincs adat"
     * on that row, never a thrown error and never a silent 0 that would pollute the total.
     */
    private Optional<ResolvedRate> resolveUnitRate(
            Map<String, MnbExchangeRateCache> rates,
            UUID companyId,
            String currency,
            LocalDate date) {
        MnbExchangeRateCache rate = rates.get(currency);
        if (rate != null && rate.getRatePerUnit() != null) {
            return Optional.of(new ResolvedRate(
                    rate.getRatePerUnit(),
                    rate.getRateDate() != null ? rate.getRateDate() : date,
                    ReceivedDenominationsDto.RATE_SOURCE_MNB));
        }

        for (int i = 1; i <= MNB_WALKBACK_DAYS; i++) {
            LocalDate fallbackDate = date.minusDays(i);
            Map<String, MnbExchangeRateCache> fallbackRates = loadRatesSafely(fallbackDate);
            MnbExchangeRateCache fallbackRate = fallbackRates.get(currency);
            if (fallbackRate != null && fallbackRate.getRatePerUnit() != null) {
                log.info("FK-112 MNB rate fallback: no {} rate for {}, stepping back {} day(s) ({})",
                        currency, date, i, fallbackDate);
                return Optional.of(new ResolvedRate(
                        fallbackRate.getRatePerUnit(),
                        fallbackRate.getRateDate() != null ? fallbackRate.getRateDate() : fallbackDate,
                        ReceivedDenominationsDto.RATE_SOURCE_MNB));
            }
        }

        if (!mnbExchangeRateService.isQuotedByMnb(currency)) {
            Optional<BigDecimal> manualRate =
                    mnbSettlementRateService.findSettlementRateAsOf(companyId, currency, date);
            if (manualRate.isPresent()) {
                return Optional.of(new ResolvedRate(
                        manualRate.get(), date, ReceivedDenominationsDto.RATE_SOURCE_MANUAL));
            }
        }
        return Optional.empty();
    }

    private Map<String, MnbExchangeRateCache> loadRatesSafely(LocalDate date) {
        try {
            Map<String, MnbExchangeRateCache> rates = mnbExchangeRateService.getRatesForDate(date);
            return rates == null ? Map.of() : rates;
        } catch (RuntimeException ex) {
            log.warn("FK-112: MNB rate lookup failed for {} — continuing without that date. {}",
                    date, ex.getMessage());
            return Map.of();
        }
    }

    /** HUF first (the legacy screen leads with "Forint keszlet"), the rest alphabetically. */
    private static Comparator<String> currencyOrder() {
        return Comparator
                .comparing((String code) -> HUF.equals(code) ? 0 : 1)
                .thenComparing(Comparator.naturalOrder());
    }

    private record CellKey(BigDecimal faceValue, String denominationType) {
    }

    private record ResolvedRate(BigDecimal perUnit, LocalDate date, String source) {
    }

    private static final class CellAccumulator {
        private final BigDecimal faceValue;
        private final String denominationType;
        private long quantity;
        private BigDecimal totalValue = BigDecimal.ZERO;
        /**
         * Sticky flag from the INDIVIDUAL source rows. Aggregation must never let two opposite
         * per-row errors cancel out (e.g. 100x2 stored as 199 plus 100x1 stored as 101 sums to a
         * perfect 100x3=300): a malformed snapshot row is always surfaced.
         */
        private boolean sourceRowMismatch;

        private CellAccumulator(BigDecimal faceValue, String denominationType) {
            this.faceValue = faceValue;
            this.denominationType = denominationType;
        }

        private void add(DailyDenominationSnapshot snapshot) {
            long rowQuantity = snapshot.getQuantity() == null ? 0L : snapshot.getQuantity().longValue();
            BigDecimal rowValue =
                    snapshot.getTotalValue() == null ? BigDecimal.ZERO : snapshot.getTotalValue();
            quantity += rowQuantity;
            totalValue = totalValue.add(rowValue);
            if (faceValue.signum() > 0
                    && faceValue.multiply(BigDecimal.valueOf(rowQuantity)).compareTo(rowValue) != 0) {
                sourceRowMismatch = true;
            }
        }

        /**
         * Cell-level data quality. Order matters: a fractional face value is the legacy-known
         * defect (Delphi stored integer face values), so it wins over the value check.
         */
        private String flag() {
            if (faceValue.signum() <= 0) {
                return FLAG_NON_POSITIVE_FACE_VALUE;
            }
            if (faceValue.stripTrailingZeros().scale() > 0) {
                return FLAG_FRACTIONAL_FACE_VALUE;
            }
            BigDecimal expected = faceValue.multiply(BigDecimal.valueOf(quantity));
            if (sourceRowMismatch || expected.compareTo(totalValue) != 0) {
                return FLAG_VALUE_MISMATCH;
            }
            return FLAG_OK;
        }
    }
}
