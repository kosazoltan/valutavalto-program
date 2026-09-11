package hu.puzzleir.valuta.service.central;

import hu.puzzleir.valuta.dto.central.ReceivedDenominationsDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DailyDenominationSnapshot;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DailyDenominationSnapshotRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.TreeMap;
import java.util.UUID;

/**
 * FK-111 FR-1: read-only denomination stock view over {@code daily_denomination_snapshot}
 * (written by {@code DailyClosingArchiveService.snapshotDenominations}, Delphi: CIMTCopy).
 *
 * <p>Tenant isolation: the branch set always comes from
 * {@link BranchRepository#findByCompanyIdAndIsActiveTrueExcludingCounterparties(UUID)}, and an
 * explicit {@code branchId} is only honoured when it is inside that company-scoped set — a
 * foreign id yields an empty result instead of another company's data.</p>
 *
 * <p>Data quality: a malformed snapshot row is flagged per cell, never dropped and never
 * fatal — the vault manager must see that the row exists AND that it is suspicious.</p>
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

    private final BranchRepository branchRepository;
    private final DailyDenominationSnapshotRepository snapshotRepository;

    @Transactional(readOnly = true)
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

        return buildDto(date, branchId, branchOptions, snapshots);
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
            log.warn("FK-111: a kert iroda nincs a ceg hatokoreben, ures valasz. branchId={}", branchId);
            return List.of();
        }
        return List.of(branchId);
    }

    private ReceivedDenominationsDto buildDto(
            LocalDate date,
            UUID branchId,
            List<ReceivedDenominationsDto.BranchOptionDto> branchOptions,
            List<DailyDenominationSnapshot> snapshots) {

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

        List<ReceivedDenominationsDto.CurrencyRowDto> rows = new ArrayList<>();
        BigDecimal hufTotalValue = BigDecimal.ZERO;
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

            rows.add(ReceivedDenominationsDto.CurrencyRowDto.builder()
                    .currencyCode(entry.getKey())
                    .totalValue(rowValue)
                    .totalQuantity(rowQuantity)
                    .cells(cells)
                    .hasDataQualityIssue(rowHasIssue)
                    .build());

            if (HUF.equals(entry.getKey())) {
                hufTotalValue = rowValue;
            }
            totalQuantity += rowQuantity;
        }

        return ReceivedDenominationsDto.builder()
                .date(date)
                .branchId(branchId)
                .branches(branchOptions)
                .rows(rows)
                .hufTotalValue(hufTotalValue)
                .currencyCount(rows.size())
                .totalQuantity(totalQuantity)
                .dataQualityIssueCount(issueCount)
                .build();
    }

    /** HUF first (the legacy screen leads with "Forint keszlet"), the rest alphabetically. */
    private static Comparator<String> currencyOrder() {
        return Comparator
                .comparing((String code) -> HUF.equals(code) ? 0 : 1)
                .thenComparing(Comparator.naturalOrder());
    }

    private record CellKey(BigDecimal faceValue, String denominationType) {
    }

    private static final class CellAccumulator {
        private final BigDecimal faceValue;
        private final String denominationType;
        private long quantity;
        private BigDecimal totalValue = BigDecimal.ZERO;

        private CellAccumulator(BigDecimal faceValue, String denominationType) {
            this.faceValue = faceValue;
            this.denominationType = denominationType;
        }

        private void add(DailyDenominationSnapshot snapshot) {
            quantity += snapshot.getQuantity() == null ? 0L : snapshot.getQuantity().longValue();
            totalValue = totalValue.add(
                    snapshot.getTotalValue() == null ? BigDecimal.ZERO : snapshot.getTotalValue());
        }

        /**
         * Cell-level data quality. Order matters: a fractional face value is the legacy-known
         * defect (Delphi stored integer face values), so it wins over the derived value check.
         */
        private String flag() {
            if (faceValue.signum() <= 0) {
                return FLAG_NON_POSITIVE_FACE_VALUE;
            }
            if (faceValue.stripTrailingZeros().scale() > 0) {
                return FLAG_FRACTIONAL_FACE_VALUE;
            }
            BigDecimal expected = faceValue.multiply(BigDecimal.valueOf(quantity));
            if (expected.compareTo(totalValue) != 0) {
                return FLAG_VALUE_MISMATCH;
            }
            return FLAG_OK;
        }
    }
}
