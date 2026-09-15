package hu.puzzleir.valuta.service.central;

import hu.puzzleir.valuta.dto.central.ReceivedBankTurnoverDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ClosingControlRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AmlEddService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

/**
 * FK-114: read-only period bank turnover for the received-data "Banki forgalmi adatok"
 * tab. Tenant isolation matches {@code DailyBalanceGridService.resolveBranchScope}
 * (company / {@code vault_territory_id} / single branch). Only {@code is_vault=true}
 * daily_balance rows are summed.
 */
@Service
public class ReceivedBankTurnoverService {

    static final int MAX_RANGE_DAYS_INCLUSIVE = 92;

    private final DailyBalanceRepository dailyBalanceRepository;
    private final ClosingControlRepository closingControlRepository;
    private final BranchRepository branchRepository;
    private final Clock clock;

    @Autowired
    public ReceivedBankTurnoverService(
            DailyBalanceRepository dailyBalanceRepository,
            ClosingControlRepository closingControlRepository,
            BranchRepository branchRepository) {
        this(dailyBalanceRepository, closingControlRepository, branchRepository,
                Clock.system(AmlEddService.BUSINESS_ZONE));
    }

    ReceivedBankTurnoverService(
            DailyBalanceRepository dailyBalanceRepository,
            ClosingControlRepository closingControlRepository,
            BranchRepository branchRepository,
            Clock clock) {
        this.dailyBalanceRepository = dailyBalanceRepository;
        this.closingControlRepository = closingControlRepository;
        this.branchRepository = branchRepository;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public ReceivedBankTurnoverDto load(LocalDate fromDate, LocalDate toDate, UUID branchId,
                                        Integer vaultTerritoryId) {
        validateRange(fromDate, toDate);

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> companyBranches = branchRepository.findByCompanyId(companyId);
        ScopeBranches scope = resolveBranchScope(companyId, branchId, vaultTerritoryId, companyBranches);

        List<ReceivedBankTurnoverDto.CurrencyRowDto> rows = loadTurnoverRows(companyId, scope, fromDate, toDate);
        List<ReceivedBankTurnoverDto.MissingClosingDayDto> missing =
                loadMissingClosingDays(companyId, scope, fromDate, toDate);

        return ReceivedBankTurnoverDto.builder()
                .fromDate(fromDate)
                .toDate(toDate)
                .branchId(branchId)
                .vaultTerritoryId(vaultTerritoryId)
                .branches(toBranchOptions(companyBranches))
                .territories(toTerritoryOptions(companyBranches))
                .rows(rows)
                .missingClosingDays(missing)
                .build();
    }

    private void validateRange(LocalDate fromDate, LocalDate toDate) {
        if (fromDate == null || toDate == null) {
            throw new ValidationException("A banki forgalom lekérdezéséhez a kezdő és záró dátum kötelező.");
        }
        if (fromDate.isAfter(toDate)) {
            throw new ValidationException("A kezdő dátum nem lehet későbbi a záró dátumnál.");
        }
        LocalDate today = LocalDate.now(clock);
        if (!toDate.isBefore(today)) {
            throw new ValidationException("Csak már lezárt napok kérdezhetők le (a záró dátum korábbi kell legyen a mainál).");
        }
        long inclusiveDays = ChronoUnit.DAYS.between(fromDate, toDate) + 1;
        if (inclusiveDays > MAX_RANGE_DAYS_INCLUSIVE) {
            throw new ValidationException("A lekérdezhető időszak legfeljebb "
                    + MAX_RANGE_DAYS_INCLUSIVE + " nap lehet.");
        }
    }

    private ScopeBranches resolveBranchScope(
            UUID companyId, UUID branchId, Integer vaultTerritoryId, List<Branch> companyBranches) {
        if (branchId != null) {
            Branch branch = branchRepository.findByIdAndCompanyId(branchId, companyId)
                    .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
            Set<UUID> vaultIds = Boolean.TRUE.equals(branch.getIsVault()) ? Set.of(branchId) : Set.of();
            return new ScopeBranches(List.of(branchId), vaultIds, Map.of(branchId, branch));
        }
        List<UUID> branchIds = new ArrayList<>();
        Set<UUID> vaultIds = new HashSet<>();
        Map<UUID, Branch> byId = new LinkedHashMap<>();
        for (Branch branch : companyBranches) {
            if (vaultTerritoryId != null && !vaultTerritoryId.equals(branch.getVaultTerritoryId())) {
                continue;
            }
            branchIds.add(branch.getId());
            byId.put(branch.getId(), branch);
            if (Boolean.TRUE.equals(branch.getIsVault())) {
                vaultIds.add(branch.getId());
            }
        }
        return new ScopeBranches(branchIds, vaultIds, byId);
    }

    private List<ReceivedBankTurnoverDto.CurrencyRowDto> loadTurnoverRows(
            UUID companyId, ScopeBranches scope, LocalDate fromDate, LocalDate toDate) {
        if (scope.vaultBranchIds().isEmpty()) {
            return List.of();
        }
        List<Object[]> tuples = dailyBalanceRepository.sumBankInOutByCurrency(
                companyId, List.copyOf(scope.vaultBranchIds()), fromDate, toDate);
        List<ReceivedBankTurnoverDto.CurrencyRowDto> rows = new ArrayList<>();
        for (Object[] tuple : tuples) {
            if (tuple == null || tuple.length < 3 || tuple[0] == null) {
                continue;
            }
            rows.add(ReceivedBankTurnoverDto.CurrencyRowDto.builder()
                    .currencyCode(String.valueOf(tuple[0]))
                    .bankIn(toDecimal(tuple[1]))
                    .bankOut(toDecimal(tuple[2]))
                    .build());
        }
        rows.sort(Comparator.comparing(ReceivedBankTurnoverDto.CurrencyRowDto::getCurrencyCode));
        return rows;
    }

    private List<ReceivedBankTurnoverDto.MissingClosingDayDto> loadMissingClosingDays(
            UUID companyId, ScopeBranches scope, LocalDate fromDate, LocalDate toDate) {
        if (scope.vaultBranchIds().isEmpty()) {
            return List.of();
        }
        List<UUID> vaultIds = List.copyOf(scope.vaultBranchIds());
        Set<String> closed = new HashSet<>();
        for (Object[] tuple : closingControlRepository.findEveningClosedBranchDates(
                companyId, vaultIds, fromDate, toDate)) {
            if (tuple == null || tuple.length < 2 || tuple[0] == null || tuple[1] == null) {
                continue;
            }
            closed.add(tuple[0] + "|" + tuple[1]);
        }
        List<ReceivedBankTurnoverDto.MissingClosingDayDto> missing = new ArrayList<>();
        for (UUID vaultId : vaultIds) {
            Branch branch = scope.byId().get(vaultId);
            String code = branch != null ? branch.getCode() : null;
            String name = branch != null ? branch.getName() : null;
            for (LocalDate day = fromDate; !day.isAfter(toDate); day = day.plusDays(1)) {
                if (!closed.contains(vaultId + "|" + day)) {
                    missing.add(ReceivedBankTurnoverDto.MissingClosingDayDto.builder()
                            .branchId(vaultId)
                            .branchCode(code)
                            .branchName(name)
                            .date(day)
                            .build());
                }
            }
        }
        missing.sort(Comparator
                .comparing(ReceivedBankTurnoverDto.MissingClosingDayDto::getDate)
                .thenComparing(d -> Objects.toString(d.getBranchCode(), "")));
        return missing;
    }

    private static List<ReceivedBankTurnoverDto.BranchOptionDto> toBranchOptions(List<Branch> branches) {
        return branches.stream()
                .map(b -> ReceivedBankTurnoverDto.BranchOptionDto.builder()
                        .id(b.getId())
                        .code(b.getCode())
                        .name(b.getName())
                        .isVault(b.getIsVault())
                        .vaultTerritoryId(b.getVaultTerritoryId())
                        .region(b.getRegion())
                        .build())
                .toList();
    }

    private static List<ReceivedBankTurnoverDto.TerritoryOptionDto> toTerritoryOptions(List<Branch> branches) {
        Map<Integer, String> byId = new LinkedHashMap<>();
        for (Branch branch : branches) {
            Integer id = branch.getVaultTerritoryId();
            if (id == null || byId.containsKey(id)) {
                continue;
            }
            String name = branch.getRegion() != null && !branch.getRegion().isBlank()
                    ? branch.getRegion()
                    : ("Terület " + id);
            byId.put(id, name);
        }
        List<ReceivedBankTurnoverDto.TerritoryOptionDto> list = new ArrayList<>();
        byId.forEach((id, name) -> list.add(ReceivedBankTurnoverDto.TerritoryOptionDto.builder()
                .id(id)
                .name(name)
                .build()));
        list.sort(Comparator.comparing(ReceivedBankTurnoverDto.TerritoryOptionDto::getName,
                Comparator.nullsLast(String::compareTo)));
        return list;
    }

    private static BigDecimal toDecimal(Object value) {
        if (value instanceof BigDecimal bd) {
            return bd;
        }
        if (value instanceof Number n) {
            return BigDecimal.valueOf(n.doubleValue());
        }
        return BigDecimal.ZERO;
    }

    private record ScopeBranches(List<UUID> branchIds, Set<UUID> vaultBranchIds, Map<UUID, Branch> byId) {
    }
}
