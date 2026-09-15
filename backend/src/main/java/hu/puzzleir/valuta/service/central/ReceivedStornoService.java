package hu.puzzleir.valuta.service.central;

import hu.puzzleir.valuta.dto.central.ReceivedBankTurnoverDto;
import hu.puzzleir.valuta.dto.central.ReceivedStornoDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionLine;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.TransferLine;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.MnbExchangeRateService;
import hu.puzzleir.valuta.service.MnbSettlementRateService;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * FK-115: read-only merged storno list (Transaction REVERSAL + cancelled Transfer).
 * Not {@code readOnly}: MNB SOAP cache writes may occur on rate lookup.
 */
@Service
@Slf4j
public class ReceivedStornoService {

    static final UUID EMPTY_IN_SENTINEL = UUID.fromString("00000000-0000-0000-0000-000000000000");
    private static final String HUF = "HUF";
    private static final int MNB_WALKBACK_DAYS = 7;

    private final TransactionRepository transactionRepository;
    private final TransferRepository transferRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;
    private final MnbExchangeRateService mnbExchangeRateService;
    private final MnbSettlementRateService mnbSettlementRateService;

    public ReceivedStornoService(
            TransactionRepository transactionRepository,
            TransferRepository transferRepository,
            BranchRepository branchRepository,
            WorkerRepository workerRepository,
            MnbExchangeRateService mnbExchangeRateService,
            MnbSettlementRateService mnbSettlementRateService) {
        this.transactionRepository = transactionRepository;
        this.transferRepository = transferRepository;
        this.branchRepository = branchRepository;
        this.workerRepository = workerRepository;
        this.mnbExchangeRateService = mnbExchangeRateService;
        this.mnbSettlementRateService = mnbSettlementRateService;
    }

    @Transactional(rollbackFor = Exception.class)
    public ReceivedStornoDto load(LocalDate fromDate, LocalDate toDate, UUID branchId,
                                  Integer vaultTerritoryId) {
        if (fromDate == null || toDate == null) {
            throw new ValidationException("A sztornó-listához a kezdő és záró dátum kötelező.");
        }
        if (fromDate.isAfter(toDate)) {
            throw new ValidationException("A kezdő dátum nem lehet későbbi a záró dátumnál.");
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> companyBranches = branchRepository.findByCompanyId(companyId);
        Scope scope = resolveScope(companyId, branchId, vaultTerritoryId, companyBranches);

        List<UUID> queryIds = scope.allBranches() ? List.of(EMPTY_IN_SENTINEL) : scope.branchIds();
        List<ReceivedStornoDto.RowDto> rows = new ArrayList<>();
        if (!scope.branchIds().isEmpty() || scope.allBranches()) {
            rows.addAll(mapTransactions(companyId, fromDate, toDate, scope.allBranches(), queryIds));
            rows.addAll(mapTransfers(companyId, fromDate, toDate, scope.allBranches(), queryIds));
        }
        rows.sort(Comparator
                .comparing(ReceivedStornoDto.RowDto::getDate, Comparator.nullsLast(Comparator.naturalOrder()))
                .thenComparing(ReceivedStornoDto.RowDto::getTime, Comparator.nullsLast(Comparator.naturalOrder()))
                .reversed());

        return ReceivedStornoDto.builder()
                .fromDate(fromDate)
                .toDate(toDate)
                .branchId(branchId)
                .vaultTerritoryId(vaultTerritoryId)
                .branches(toBranchOptions(companyBranches))
                .territories(toTerritoryOptions(companyBranches))
                .rows(rows)
                .build();
    }

    private Scope resolveScope(UUID companyId, UUID branchId, Integer vaultTerritoryId,
                               List<Branch> companyBranches) {
        if (branchId != null) {
            Branch branch = branchRepository.findByIdAndCompanyId(branchId, companyId)
                    .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
            return new Scope(false, List.of(branch.getId()));
        }
        if (vaultTerritoryId == null) {
            return new Scope(true, companyBranches.stream().map(Branch::getId).toList());
        }
        List<UUID> ids = companyBranches.stream()
                .filter(b -> vaultTerritoryId.equals(b.getVaultTerritoryId()))
                .map(Branch::getId)
                .toList();
        return new Scope(false, ids);
    }

    private List<ReceivedStornoDto.RowDto> mapTransactions(
            UUID companyId, LocalDate fromDate, LocalDate toDate, boolean allBranches, List<UUID> branchIds) {
        List<Transaction> reversals = transactionRepository.findReversalsForReceivedData(
                companyId, TransactionType.REVERSAL, fromDate, toDate, allBranches, branchIds);
        List<ReceivedStornoDto.RowDto> rows = new ArrayList<>();
        for (Transaction reversal : reversals) {
            Transaction original = reversal.getOriginalTransaction();
            if (original == null) {
                continue;
            }
            Branch office = reversal.getBranch();
            Worker worker = reversal.getWorker();
            rows.add(ReceivedStornoDto.RowDto.builder()
                    .type(ReceivedStornoDto.TYPE_SALE_PURCHASE)
                    .officeCode(office != null ? office.getCode() : null)
                    .officeName(office != null ? office.getName() : null)
                    .date(reversal.getTransactionDate())
                    .time(reversal.getTransactionTime())
                    .originalDocumentNumber(original.getReceiptNumber())
                    .stornoDocumentNumber(reversal.getReceiptNumber())
                    .workerName(worker != null ? worker.getName() : null)
                    .reason(reversal.getReversalReason())
                    .lines(mapTransactionLines(original.getLines()))
                    .build());
        }
        return rows;
    }

    private List<ReceivedStornoDto.LineDto> mapTransactionLines(List<TransactionLine> lines) {
        if (lines == null || lines.isEmpty()) {
            return List.of();
        }
        List<ReceivedStornoDto.LineDto> result = new ArrayList<>();
        for (TransactionLine line : lines) {
            Currency currency = line.getCurrency();
            result.add(ReceivedStornoDto.LineDto.builder()
                    .currencyCode(currency != null ? currency.getCode() : null)
                    .amount(line.getBanknoteCount())
                    .hufValue(line.getHufValue())
                    .rateMissing(false)
                    .build());
        }
        return result;
    }

    private List<ReceivedStornoDto.RowDto> mapTransfers(
            UUID companyId, LocalDate fromDate, LocalDate toDate, boolean allBranches, List<UUID> branchIds) {
        LocalDateTime fromTs = fromDate.atStartOfDay();
        LocalDateTime toTsExclusive = toDate.plusDays(1).atStartOfDay();
        List<Transfer> transfers = transferRepository.findCancelledForReceivedData(
                companyId, fromTs, toTsExclusive, allBranches, branchIds, Transfer.TransferStatus.REJECTED);
        Set<Long> workerIds = transfers.stream()
                .map(Transfer::getCancelledBy)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        Map<Long, String> workerNames = new HashMap<>();
        if (!workerIds.isEmpty()) {
            for (Worker worker : workerRepository.findAllById(workerIds)) {
                workerNames.put(worker.getId(), worker.getName());
            }
        }
        List<ReceivedStornoDto.RowDto> rows = new ArrayList<>();
        for (Transfer transfer : transfers) {
            Branch office = transfer.getFromBranch();
            LocalDateTime cancelledAt = transfer.getCancelledAt();
            String number = transfer.getTransferNumber();
            rows.add(ReceivedStornoDto.RowDto.builder()
                    .type(ReceivedStornoDto.TYPE_TRANSFER)
                    .officeCode(office != null ? office.getCode() : null)
                    .officeName(office != null ? office.getName() : null)
                    .date(cancelledAt != null ? cancelledAt.toLocalDate() : transfer.getTransferDate())
                    .time(cancelledAt != null ? cancelledAt.toLocalTime() : transfer.getTransferTime())
                    .originalDocumentNumber(number)
                    .stornoDocumentNumber(number != null ? number + "-SZ" : null)
                    .workerName(transfer.getCancelledBy() != null
                            ? workerNames.get(transfer.getCancelledBy()) : null)
                    .reason(transfer.getCancellationReason())
                    .lines(mapTransferLines(companyId, transfer))
                    .build());
        }
        return rows;
    }

    private List<ReceivedStornoDto.LineDto> mapTransferLines(UUID companyId, Transfer transfer) {
        List<TransferLine> lines = transfer.getLines();
        boolean multi = lines != null && lines.size() > 1;
        if (!multi) {
            Currency currency = transfer.getCurrency();
            String code = currency != null ? currency.getCode() : null;
            return List.of(ReceivedStornoDto.LineDto.builder()
                    .currencyCode(code)
                    .amount(transfer.getAmount())
                    .hufValue(transfer.getHufValue())
                    .rateMissing(false)
                    .build());
        }
        LocalDate rateDate = transfer.getTransferDate() != null
                ? transfer.getTransferDate() : LocalDate.now();
        List<ReceivedStornoDto.LineDto> result = new ArrayList<>();
        for (TransferLine line : lines) {
            Currency currency = line.getCurrency();
            String code = currency != null ? currency.getCode() : null;
            BigDecimal amount = line.getAmount();
            ReceivedStornoDto.LineDto.LineDtoBuilder builder = ReceivedStornoDto.LineDto.builder()
                    .currencyCode(code)
                    .amount(amount);
            applyTransferHuf(builder, companyId, code, amount, rateDate);
            result.add(builder.build());
        }
        return result;
    }

    private void applyTransferHuf(ReceivedStornoDto.LineDto.LineDtoBuilder builder,
                                  UUID companyId, String currency, BigDecimal amount, LocalDate date) {
        if (amount == null) {
            builder.hufValue(null).rateMissing(true);
            return;
        }
        if (HUF.equals(currency)) {
            builder.hufValue(HungarianRounding.roundToFive(amount)).rateMissing(false);
            return;
        }
        Optional<BigDecimal> rate = resolveUnitRate(companyId, currency, date);
        if (rate.isEmpty()) {
            builder.hufValue(null).rateMissing(true);
            return;
        }
        builder.hufValue(HungarianRounding.roundToFive(amount.multiply(rate.get()))).rateMissing(false);
    }

    private Optional<BigDecimal> resolveUnitRate(UUID companyId, String currency, LocalDate date) {
        if (currency == null) {
            return Optional.empty();
        }
        try {
            Map<String, MnbExchangeRateCache> rates = mnbExchangeRateService.getRatesForDate(date);
            MnbExchangeRateCache hit = rates.get(currency);
            if (hit != null && hit.getRatePerUnit() != null) {
                return Optional.of(hit.getRatePerUnit());
            }
            for (int i = 1; i <= MNB_WALKBACK_DAYS; i++) {
                Map<String, MnbExchangeRateCache> fallback =
                        mnbExchangeRateService.getRatesForDate(date.minusDays(i));
                MnbExchangeRateCache fb = fallback.get(currency);
                if (fb != null && fb.getRatePerUnit() != null) {
                    return Optional.of(fb.getRatePerUnit());
                }
            }
        } catch (RuntimeException ex) {
            log.warn("FK-115 MNB lookup failed for {} on {}: {}", currency, date, ex.getMessage());
        }
        return mnbSettlementRateService.findSettlementRateAsOf(companyId, currency, date);
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
                    ? branch.getRegion() : ("Terület " + id);
            byId.put(id, name);
        }
        List<ReceivedBankTurnoverDto.TerritoryOptionDto> list = new ArrayList<>();
        byId.forEach((id, name) -> list.add(ReceivedBankTurnoverDto.TerritoryOptionDto.builder()
                .id(id).name(name).build()));
        list.sort(Comparator.comparing(ReceivedBankTurnoverDto.TerritoryOptionDto::getName,
                Comparator.nullsLast(String::compareTo)));
        return list;
    }

    private record Scope(boolean allBranches, List<UUID> branchIds) {
    }
}
