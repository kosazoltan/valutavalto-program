package hu.puzzleir.valuta.service.darius;

import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.dto.darius.DariusImportFile;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel;
import hu.puzzleir.valuta.dto.darius.DariusImportReadinessDto;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.BranchBlock;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.FixingBlock;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.FixingRow;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.StockRow;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.TurnoverRow;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DailyDenominationSnapshot;
import hu.puzzleir.valuta.entity.DariusBankBranch;
import hu.puzzleir.valuta.entity.DariusFixingRequest;
import hu.puzzleir.valuta.entity.DariusFixingRequestLine;
import hu.puzzleir.valuta.entity.DariusFixingRequestStatus;
import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DailyDenominationSnapshotRepository;
import hu.puzzleir.valuta.repository.DariusBankBranchRepository;
import hu.puzzleir.valuta.repository.DariusFixingRequestLineRepository;
import hu.puzzleir.valuta.repository.DariusFixingRequestRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AuditLogService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@Service
@Slf4j
public class DariusImportFileService {

    private final BranchRepository branchRepository;
    private final DailyDenominationSnapshotRepository snapshotRepository;
    private final TransactionRepository transactionRepository;
    private final CompanyRepository companyRepository;
    private final DariusImportPreflightValidator validator;
    private final DariusImportFileSerializer serializer;
    private final AuditLogService auditLogService;
    private final IntegrationTransportProperties properties;
    private final DariusFixingRequestRepository fixingRequestRepository;
    private final DariusFixingRequestLineRepository fixingLineRepository;
    private final DariusBankBranchRepository bankBranchRepository;
    private final Clock clock;

    @Autowired
    public DariusImportFileService(
            BranchRepository branchRepository,
            DailyDenominationSnapshotRepository snapshotRepository,
            TransactionRepository transactionRepository,
            CompanyRepository companyRepository,
            DariusImportPreflightValidator validator,
            DariusImportFileSerializer serializer,
            AuditLogService auditLogService,
            IntegrationTransportProperties properties,
            DariusFixingRequestRepository fixingRequestRepository,
            DariusFixingRequestLineRepository fixingLineRepository,
            DariusBankBranchRepository bankBranchRepository) {
        this(
                branchRepository,
                snapshotRepository,
                transactionRepository,
                companyRepository,
                validator,
                serializer,
                auditLogService,
                properties,
                fixingRequestRepository,
                fixingLineRepository,
                bankBranchRepository,
                Clock.system(DariusImportPreflightValidator.BUSINESS_ZONE));
    }

    DariusImportFileService(
            BranchRepository branchRepository,
            DailyDenominationSnapshotRepository snapshotRepository,
            TransactionRepository transactionRepository,
            CompanyRepository companyRepository,
            DariusImportPreflightValidator validator,
            DariusImportFileSerializer serializer,
            AuditLogService auditLogService,
            IntegrationTransportProperties properties,
            DariusFixingRequestRepository fixingRequestRepository,
            DariusFixingRequestLineRepository fixingLineRepository,
            DariusBankBranchRepository bankBranchRepository,
            Clock clock) {
        this.branchRepository = branchRepository;
        this.snapshotRepository = snapshotRepository;
        this.transactionRepository = transactionRepository;
        this.companyRepository = companyRepository;
        this.validator = validator;
        this.serializer = serializer;
        this.auditLogService = auditLogService;
        this.properties = properties;
        this.fixingRequestRepository = fixingRequestRepository;
        this.fixingLineRepository = fixingLineRepository;
        this.bankBranchRepository = bankBranchRepository;
        this.clock = clock;
    }

    @Transactional
    public DariusImportFile generateImportFile(LocalDate date, int erteknap) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található: " + companyId));
        String pvCode = properties.getDarius().getPvCodes().get(company.getCode());
        List<String> preErrors = new ArrayList<>();
        List<FixingBlock> fixingBlocks = new ArrayList<>();
        List<DariusFixingRequest> toInclude = new ArrayList<>();
        List<DariusFixingRequest> liveRequests = fixingRequestRepository
                .findForUpdateByCompanyIdAndRequestDateAndStatusInOrderByCreatedAtAscIdAsc(
                        companyId,
                        date,
                        List.of(
                                DariusFixingRequestStatus.DRAFT,
                                DariusFixingRequestStatus.APPROVED,
                                DariusFixingRequestStatus.INCLUDED));
        for (DariusFixingRequest request : liveRequests) {
            DariusBankBranch bankBranch = bankBranchRepository
                    .findByIdAndCompanyId(request.getBankBranchId(), companyId)
                    .orElse(null);
            String code = bankBranch == null ? null : bankBranch.getBankBranchCode();
            if (request.getStatus() == DariusFixingRequestStatus.DRAFT) {
                preErrors.add("[FIXING:" + (code == null ? request.getId() : code)
                        + "] jóváhagyatlan (DRAFT) fixing-igény a napra — hagyd jóvá vagy vond vissza");
                continue;
            }
            if (bankBranch == null
                    || !Boolean.TRUE.equals(bankBranch.getIsActive())
                    || code == null
                    || code.isBlank()) {
                preErrors.add("[FIXING:" + request.getId()
                        + "] a fixing-igény bankfiókja hiányzik/inaktív/kód nélküli — export tiltva");
                continue;
            }
            List<DariusFixingRequestLine> lines = fixingLineRepository
                    .findByCompanyIdAndRequestIdOrderByCurrencyCodeAsc(companyId, request.getId());
            fixingBlocks.add(new FixingBlock(
                    code,
                    lines.stream()
                            .map(line -> new FixingRow(
                                    line.getCurrencyCode(),
                                    line.getDeliveredAmount(),
                                    line.getCollectedAmount()))
                            .toList()));
            if (request.getStatus() == DariusFixingRequestStatus.APPROVED) {
                toInclude.add(request);
            }
        }
        List<BranchBlock> branchBlocks = new ArrayList<>();

        List<Branch> branches =
                branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId);
        for (Branch branch : branches) {
            List<DailyDenominationSnapshot> snapshots = snapshotRepository
                    .findByBranchIdAndSnapshotDateAndClosingType(branch.getId(), date, 1);
            List<Object[]> turnover = transactionRepository
                    .groupByCurrencyTypeAndPaymentMethodForBranch(branch.getId(), date, date);
            branchBlocks.add(toBranchBlock(branch, erteknap, snapshots, turnover));
        }

        DariusImportFileModel model = new DariusImportFileModel(date, pvCode, fixingBlocks, branchBlocks);
        List<String> errors = validator.validate(model);
        errors.addAll(0, preErrors);
        if (!errors.isEmpty()) {
            throw new ValidationException(String.join("; ", errors));
        }

        byte[] content = serializer.serialize(model);
        String fileName = "raiffeisen_import_" + company.getCode() + "_" + date + ".imp";
        String hash = sha256(content);
        auditLogService.logForCompany(
                "DARIUS_IMPORT_FILE_EXPORTED",
                "Raiffeisen importfájl exportálva: date=" + date
                        + ", fileName=" + fileName
                        + ", sha256=" + hash,
                fileName,
                companyId);
        for (DariusFixingRequest request : toInclude) {
            auditLogService.logForCompany(
                    "DARIUS_FIXING_REQUEST_INCLUDED",
                    "Fixing-igény exportálva: requestId=" + request.getId()
                            + ", date=" + date
                            + ", sha256=" + hash,
                    request.getId().toString(),
                    companyId);
        }
        LocalDateTime includedAt = LocalDateTime.now(clock);
        for (DariusFixingRequest request : toInclude) {
            request.setStatus(DariusFixingRequestStatus.INCLUDED);
            request.setIncludedAt(includedAt);
            request.setIncludedFileSha256(hash);
            fixingRequestRepository.save(request);
        }
        log.info("Raiffeisen importfájl elkészült: companyId={}, date={}, fileName={}, sha256={}",
                companyId, date, fileName, hash);
        return new DariusImportFile(fileName, content);
    }

    @Transactional(readOnly = true)
    public DariusImportReadinessDto importReadiness() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található: " + companyId));
        String pvCode = properties.getDarius().getPvCodes().get(company.getCode());
        List<Branch> branches =
                branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId);
        List<String> invalidBankCodes = branches.stream()
                .filter(branch -> branch.getBankCode() == null
                        || !branch.getBankCode().matches("[1-9][0-9]*"))
                .map(branch -> branch.getName() + " (" + branch.getBankCode() + ")")
                .toList();
        int activeBankBranchCount = bankBranchRepository
                .findByCompanyIdAndIsActiveTrueOrderByBankBranchCodeAsc(companyId)
                .size();
        return new DariusImportReadinessDto(
                company.getCode(),
                pvCode != null && !pvCode.isBlank(),
                branches.size(),
                invalidBankCodes,
                activeBankBranchCount,
                activeBankBranchCount > 0);
    }

    private BranchBlock toBranchBlock(
            Branch branch,
            int erteknap,
            List<DailyDenominationSnapshot> snapshots,
            List<Object[]> turnover) {
        List<StockRow> stockRows = snapshots.stream()
                .map(snapshot -> new StockRow(
                        snapshot.getCurrencyCode(),
                        snapshot.getFaceValue(),
                        snapshot.getQuantity()))
                .toList();
        LocalTime idopont = snapshots.stream()
                .map(DailyDenominationSnapshot::getCreatedAt)
                .filter(createdAt -> createdAt != null)
                .min(Comparator.naturalOrder())
                .map(createdAt -> createdAt.toLocalTime().withSecond(0).withNano(0))
                .orElse(null);
        List<TurnoverRow> turnoverRows = aggregateTurnover(turnover);
        return new BranchBlock(
                branch.getBankCode(),
                Boolean.TRUE.equals(branch.getHasPos()),
                erteknap,
                idopont,
                stockRows,
                turnoverRows);
    }

    private List<TurnoverRow> aggregateTurnover(List<Object[]> rows) {
        Map<String, TurnoverAccumulator> totals = new LinkedHashMap<>();
        for (Object[] row : rows) {
            String currencyCode = (String) row[0];
            String transactionType = transactionType(row[1]);
            if (!"BUY".equals(transactionType) && !"SELL".equals(transactionType)) {
                continue;
            }
            PaymentMethod paymentMethod = paymentMethod(row[2]);
            BigDecimal currencyAmount = amount(row[3]);
            BigDecimal hufAmount = amount(row[4]);
            BigDecimal fee = amount(row[5]);
            TurnoverAccumulator currency = totals.computeIfAbsent(currencyCode, ignored -> new TurnoverAccumulator());

            if (paymentMethod == PaymentMethod.CASH) {
                if ("BUY".equals(transactionType)) {
                    currency.cashBought = currency.cashBought.add(currencyAmount);
                } else {
                    currency.cashSold = currency.cashSold.add(currencyAmount);
                }
                if (fee.signum() != 0) {
                    huf(totals).cashFee = huf(totals).cashFee.add(fee);
                }
            } else if ("SELL".equals(transactionType)) {
                currency.posSold = currency.posSold.add(currencyAmount);
                if (!"HUF".equals(currencyCode)) {
                    huf(totals).posBought = huf(totals).posBought.add(hufAmount);
                }
                huf(totals).hufPosFee = huf(totals).hufPosFee.add(fee);
            } else {
                currency.posBought = currency.posBought.add(currencyAmount);
                if (!"HUF".equals(currencyCode)) {
                    huf(totals).posSold = huf(totals).posSold.add(hufAmount);
                }
                huf(totals).fxPosFee = huf(totals).fxPosFee.add(fee);
            }
        }

        return totals.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .map(entry -> entry.getValue().toRow(entry.getKey()))
                .toList();
    }

    private PaymentMethod paymentMethod(Object value) {
        if (value == null) {
            return PaymentMethod.CASH;
        }
        if (value instanceof PaymentMethod paymentMethod) {
            return paymentMethod;
        }
        return PaymentMethod.valueOf(value.toString());
    }

    private String transactionType(Object value) {
        if (value instanceof TransactionType transactionType) {
            return transactionType.name();
        }
        if (value instanceof String transactionType) {
            return transactionType.trim().toUpperCase(Locale.ROOT);
        }
        return null;
    }

    private BigDecimal amount(Object value) {
        if (value == null) {
            return BigDecimal.ZERO;
        }
        if (value instanceof BigDecimal amount) {
            return amount;
        }
        if (value instanceof BigInteger amount) {
            return new BigDecimal(amount);
        }
        if (value instanceof Byte || value instanceof Short || value instanceof Integer || value instanceof Long) {
            return BigDecimal.valueOf(((Number) value).longValue());
        }
        if (value instanceof Double amount) {
            if (!Double.isFinite(amount)) {
                throw nonFiniteAmount(value);
            }
            return BigDecimal.valueOf(amount);
        }
        if (value instanceof Float amount) {
            if (!Float.isFinite(amount)) {
                throw nonFiniteAmount(value);
            }
            return new BigDecimal(Float.toString(amount));
        }
        throw new IllegalStateException(
                "Nem támogatott numerikus típus a Darius forgalmi aggregátumban: "
                        + value.getClass().getName());
    }

    private IllegalStateException nonFiniteAmount(Object value) {
        return new IllegalStateException(
                "A Darius forgalmi aggregátum numerikus értéke nem véges: "
                        + value.getClass().getName());
    }

    private TurnoverAccumulator huf(Map<String, TurnoverAccumulator> totals) {
        return totals.computeIfAbsent("HUF", ignored -> new TurnoverAccumulator());
    }

    private String sha256(byte[] content) {
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256").digest(content);
            return java.util.HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 nem elérhető", exception);
        }
    }

    private static final class TurnoverAccumulator {
        private BigDecimal cashSold = BigDecimal.ZERO;
        private BigDecimal cashBought = BigDecimal.ZERO;
        private BigDecimal posSold = BigDecimal.ZERO;
        private BigDecimal posBought = BigDecimal.ZERO;
        private BigDecimal hufPosFee = BigDecimal.ZERO;
        private BigDecimal fxPosFee = BigDecimal.ZERO;
        private BigDecimal cashFee = BigDecimal.ZERO;

        private TurnoverRow toRow(String currencyCode) {
            return new TurnoverRow(
                    currencyCode,
                    cashSold,
                    cashBought,
                    posSold,
                    posBought,
                    hufPosFee,
                    fxPosFee,
                    cashFee);
        }
    }
}
