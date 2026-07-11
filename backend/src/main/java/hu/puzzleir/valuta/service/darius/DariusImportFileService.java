package hu.puzzleir.valuta.service.darius;

import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.dto.darius.DariusImportFile;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.BranchBlock;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.StockRow;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.TurnoverRow;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DailyDenominationSnapshot;
import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DailyDenominationSnapshotRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AuditLogService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
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

    @Transactional
    public DariusImportFile generateImportFile(LocalDate date, int erteknap) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található: " + companyId));
        String pvCode = properties.getDarius().getPvCodes().get(company.getCode());
        List<BranchBlock> branchBlocks = new ArrayList<>();

        List<Branch> branches = branchRepository.findByCompanyIdAndIsActiveTrue(companyId);
        for (Branch branch : branches) {
            List<DailyDenominationSnapshot> snapshots = snapshotRepository
                    .findByBranchIdAndSnapshotDateAndClosingType(branch.getId(), date, 1);
            List<Object[]> turnover = transactionRepository
                    .groupByCurrencyTypeAndPaymentMethodForBranch(branch.getId(), date, date);
            if (snapshots.isEmpty() && turnover.isEmpty()) {
                continue;
            }
            branchBlocks.add(toBranchBlock(branch, erteknap, snapshots, turnover));
        }

        DariusImportFileModel model = new DariusImportFileModel(date, pvCode, branchBlocks);
        List<String> errors = validator.validate(model);
        if (!errors.isEmpty()) {
            throw new ValidationException(String.join("; ", errors));
        }

        byte[] content = serializer.serialize(model);
        String fileName = "raiffeisen_import_" + company.getCode() + "_" + date + ".imp";
        String hash = sha256(content);
        auditLogService.log(
                "DARIUS_IMPORT_FILE_EXPORTED",
                "Raiffeisen importfájl exportálva: date=" + date
                        + ", fileName=" + fileName
                        + ", sha256=" + hash,
                companyId.toString());
        log.info("Raiffeisen importfájl elkészült: companyId={}, date={}, fileName={}, sha256={}",
                companyId, date, fileName, hash);
        return new DariusImportFile(fileName, content);
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
        return value == null ? BigDecimal.ZERO : (BigDecimal) value;
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
