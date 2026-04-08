package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.trb.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * TRB Export szolgáltatás — legacy Import felíró (unit5.pas) modern megfelelője.
 *
 * Cégenként napi összesítő generálás:
 * - JELENTES PENZTARALLOMANY: irodánként, valutanemenként, címletenként
 * - JELENTES UGYFELFORGALOM: irodánként, valutanemenként eladott/vett
 * - JELENTES BANKIFORGALOM: valutanemenként felvett/kifizetett
 *
 * Legacy: unit5.pas WImport + ExcelTablaKeszito
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TrbExportService {

    private final BranchRepository branchRepository;
    private final TransactionRepository transactionRepository;
    private final DenominationBalanceRepository denominationBalanceRepository;
    private final InventoryMovementRepository movementRepository;

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    // ============ PREVIEW (JSON) ============

    /**
     * Előnézet: cégenként összesített TRB adat JSON-ben.
     */
    @Transactional(readOnly = true)
    public TrbExportDto getPreview(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> branches = branchRepository.findByCompanyId(companyId);

        // Branch-ök lekérése aktív company-hoz
        Branch firstBranch = branches.isEmpty() ? null : branches.get(0);
        String companyCode = firstBranch != null && firstBranch.getCompany() != null
                ? firstBranch.getCompany().getCode() : "UNKNOWN";
        String companyName = firstBranch != null && firstBranch.getCompany() != null
                ? firstBranch.getCompany().getName() : "Ismeretlen cég";

        List<TrbBranchReportDto> branchReports = new ArrayList<>();
        for (Branch branch : branches) {
            TrbBranchReportDto report = buildBranchReport(branch, date);
            if (!report.getDenominationLines().isEmpty() || !report.getCustomerTurnoverLines().isEmpty()) {
                branchReports.add(report);
            }
        }

        List<TrbBankFlowLineDto> bankFlowLines = buildBankFlowLines(companyId, date);

        return TrbExportDto.builder()
                .companyCode(companyCode)
                .companyName(companyName)
                .reportDate(date)
                .valueDate(date.plusDays(1))
                .branchReports(branchReports)
                .bankFlowLines(bankFlowLines)
                .build();
    }

    // ============ TXT EXPORT ============

    /**
     * Legacy-kompatibilis TRB TXT fájl generálás.
     * Formátum: BEGIN/END blokk, JELENTES szekciók, TAB szeparált.
     */
    @Transactional(readOnly = true)
    public byte[] generateTxt(LocalDate date) {
        TrbExportDto export = getPreview(date);
        StringBuilder sb = new StringBuilder();

        sb.append("# ").append(export.getCompanyName())
                .append(" - ").append(date.format(DATE_FMT)).append("\r\n\r\n");
        sb.append("BEGIN\r\n");
        sb.append("TNAP\t").append(export.getValueDate().format(DATE_FMT)).append("\r\n\r\n");

        sb.append("# ").append(export.getCompanyName()).append("\r\n");
        sb.append("PV_AZONOSITO\t").append(padRight(export.getCompanyCode(), 8)).append("\r\n");

        // Pénztárállomány irodánként
        for (TrbBranchReportDto branch : export.getBranchReports()) {
            if (!branch.getDenominationLines().isEmpty()) {
                sb.append("\r\nJELENTES PENZTARALLOMANY\r\n");
                sb.append("UZLETHELYISEG_AZONOSITO\t").append(padRight(branch.getBranchCode(), 4)).append("\r\n");
                sb.append("ERTEKNAP\t-1\r\n");
                sb.append("IDOPONT\t").append("23:59").append("\r\n");

                for (TrbDenominationLineDto line : branch.getDenominationLines()) {
                    sb.append("KP\t")
                            .append(line.getCurrencyCode()).append("\t")
                            .append(line.getDenomination()).append("\t")
                            .append(line.getQuantity()).append("\r\n");
                }
                sb.append("JELENTES END\r\n");
            }
        }

        // Ügyfélforgalom irodánként
        for (TrbBranchReportDto branch : export.getBranchReports()) {
            if (!branch.getCustomerTurnoverLines().isEmpty()) {
                sb.append("\r\nJELENTES UGYFELFORGALOM\r\n");
                sb.append("UZLETHELYISEG_AZONOSITO\t").append(padRight(branch.getBranchCode(), 4)).append("\r\n");
                sb.append("ERTEKNAP\t-1\r\n");

                for (TrbCurrencyLineDto line : branch.getCustomerTurnoverLines()) {
                    sb.append(line.getCurrencyCode()).append("\t")
                            .append(formatBd(line.getSold())).append("\t")
                            .append(formatBd(line.getBought())).append("\t")
                            .append("0");
                    if ("HUF".equals(line.getCurrencyCode())) {
                        sb.append("\t").append(formatBd(line.getBankCardAmount()))
                                .append("\t").append(formatBd(line.getBankCardFee()));
                    } else {
                        sb.append("\t0\t0");
                    }
                    sb.append("\r\n");
                }
                sb.append("JELENTES END\r\n");
            }
        }

        // Bankforgalom
        if (!export.getBankFlowLines().isEmpty()) {
            sb.append("\r\nJELENTES BANKIFORGALOM\r\n");
            sb.append("ERTEKNAP\t-1\r\n");
            for (TrbBankFlowLineDto line : export.getBankFlowLines()) {
                sb.append(line.getCurrencyCode()).append("\t")
                        .append(formatBd(line.getWithdrawn())).append("\t")
                        .append(formatBd(line.getDeposited())).append("\t")
                        .append("0\r\n");
            }
            sb.append("JELENTES END\r\n");
        }

        sb.append("END\r\n");
        return sb.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8);
    }

    // ============ EXCEL EXPORT ============

    /**
     * TRB Excel generálás — bankforgalom összesítő.
     */
    @Transactional(readOnly = true)
    public byte[] generateExcel(LocalDate date) throws IOException {
        TrbExportDto export = getPreview(date);

        try (XSSFWorkbook workbook = new XSSFWorkbook()) {
            // --- Bankforgalom lap ---
            Sheet bankSheet = workbook.createSheet("Bankforgalom");
            CellStyle headerStyle = createHeaderStyle(workbook);
            CellStyle numberStyle = createNumberStyle(workbook);

            Row titleRow = bankSheet.createRow(1);
            Cell titleCell = titleRow.createCell(0);
            titleCell.setCellValue(export.getCompanyName() + " TRB TRANZAKCIÓI");
            CellStyle titleStyle = workbook.createCellStyle();
            Font titleFont = workbook.createFont();
            titleFont.setFontName("Arial");
            titleFont.setFontHeightInPoints((short) 14);
            titleFont.setBold(true);
            titleFont.setItalic(true);
            titleStyle.setFont(titleFont);
            titleCell.setCellStyle(titleStyle);

            Row headerRow = bankSheet.createRow(3);
            String[] headers = {"DÁTUM", "VALUTANEM", "FELVETT ÖSSZEG", "KIFIZETETT ÖSSZEG"};
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowIdx = 4;
            String dateStr = date.format(DATE_FMT);
            for (TrbBankFlowLineDto line : export.getBankFlowLines()) {
                Row row = bankSheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(dateStr);
                row.createCell(1).setCellValue(line.getCurrencyCode());
                Cell withdrawCell = row.createCell(2);
                withdrawCell.setCellValue(line.getWithdrawn().doubleValue());
                withdrawCell.setCellStyle(numberStyle);
                Cell depositCell = row.createCell(3);
                depositCell.setCellValue(line.getDeposited().doubleValue());
                depositCell.setCellStyle(numberStyle);
            }

            for (int i = 0; i < 4; i++) bankSheet.autoSizeColumn(i);

            // --- Ügyfélforgalom lap ---
            Sheet custSheet = workbook.createSheet("Ügyfélforgalom");
            Row custTitleRow = custSheet.createRow(0);
            custTitleRow.createCell(0).setCellValue("Ügyfélforgalom összesítő — " + dateStr);

            Row custHeaderRow = custSheet.createRow(2);
            String[] custHeaders = {"IRODA", "VALUTANEM", "ELADOTT", "VETT"};
            for (int i = 0; i < custHeaders.length; i++) {
                Cell cell = custHeaderRow.createCell(i);
                cell.setCellValue(custHeaders[i]);
                cell.setCellStyle(headerStyle);
            }

            int custRowIdx = 3;
            for (TrbBranchReportDto branch : export.getBranchReports()) {
                for (TrbCurrencyLineDto line : branch.getCustomerTurnoverLines()) {
                    Row row = custSheet.createRow(custRowIdx++);
                    row.createCell(0).setCellValue(branch.getBranchName());
                    row.createCell(1).setCellValue(line.getCurrencyCode());
                    Cell soldCell = row.createCell(2);
                    soldCell.setCellValue(line.getSold().doubleValue());
                    soldCell.setCellStyle(numberStyle);
                    Cell boughtCell = row.createCell(3);
                    boughtCell.setCellValue(line.getBought().doubleValue());
                    boughtCell.setCellStyle(numberStyle);
                }
            }

            for (int i = 0; i < 4; i++) custSheet.autoSizeColumn(i);

            // --- Pénztárállomány lap ---
            Sheet denomSheet = workbook.createSheet("Pénztárállomány");
            Row denomTitleRow = denomSheet.createRow(0);
            denomTitleRow.createCell(0).setCellValue("Pénztárállomány címletszintű összesítő — " + dateStr);

            Row denomHeaderRow = denomSheet.createRow(2);
            String[] denomHeaders = {"IRODA", "VALUTANEM", "CÍMLET", "DARAB"};
            for (int i = 0; i < denomHeaders.length; i++) {
                Cell cell = denomHeaderRow.createCell(i);
                cell.setCellValue(denomHeaders[i]);
                cell.setCellStyle(headerStyle);
            }

            int denomRowIdx = 3;
            for (TrbBranchReportDto branch : export.getBranchReports()) {
                for (TrbDenominationLineDto line : branch.getDenominationLines()) {
                    Row row = denomSheet.createRow(denomRowIdx++);
                    row.createCell(0).setCellValue(branch.getBranchName());
                    row.createCell(1).setCellValue(line.getCurrencyCode());
                    row.createCell(2).setCellValue(line.getDenomination());
                    row.createCell(3).setCellValue(line.getQuantity());
                }
            }

            for (int i = 0; i < 4; i++) denomSheet.autoSizeColumn(i);

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            workbook.write(baos);
            return baos.toByteArray();
        }
    }

    // ============ PRIVATE BUILDERS ============

    private TrbBranchReportDto buildBranchReport(Branch branch, LocalDate date) {
        List<TrbDenominationLineDto> denomLines = buildDenominationLines(branch);
        List<TrbCurrencyLineDto> turnoverLines = buildCustomerTurnoverLines(branch, date);

        return TrbBranchReportDto.builder()
                .branchCode(branch.getCode())
                .branchName(branch.getName())
                .denominationLines(denomLines)
                .customerTurnoverLines(turnoverLines)
                .build();
    }

    private List<TrbDenominationLineDto> buildDenominationLines(Branch branch) {
        // cashDeskId = branch ID a jelenlegi sémában
        List<DenominationBalance> balances = denominationBalanceRepository.findByCashDeskId(branch.getId());
        List<TrbDenominationLineDto> result = new ArrayList<>();

        for (DenominationBalance bal : balances) {
            if (bal.getQuantity() != null && bal.getQuantity() > 0) {
                result.add(TrbDenominationLineDto.builder()
                        .currencyCode(bal.getDenomination().getCurrency() != null
                                ? bal.getDenomination().getCurrency().getCode() : "???")
                        .denomination(bal.getDenomination().getFaceValue() != null
                                ? bal.getDenomination().getFaceValue().intValue() : 0)
                        .quantity(bal.getQuantity())
                        .build());
            }
        }

        // Összevonjuk az azonos valuta+címlet sorokat (több pénztárgép esetén)
        Map<String, TrbDenominationLineDto> merged = new LinkedHashMap<>();
        for (TrbDenominationLineDto line : result) {
            String key = line.getCurrencyCode() + "|" + line.getDenomination();
            merged.merge(key, line, (a, b) -> {
                a.setQuantity(a.getQuantity() + b.getQuantity());
                return a;
            });
        }

        return new ArrayList<>(merged.values());
    }

    private List<TrbCurrencyLineDto> buildCustomerTurnoverLines(Branch branch, LocalDate date) {
        // Eladások valutanemenként
        List<Object[]> sellRows = transactionRepository.sumAmountByCurrencyAndBranchAndTypeAndDate(
                branch.getId(), TransactionType.SELL, date);
        // Vásárlások valutanemenként
        List<Object[]> buyRows = transactionRepository.sumAmountByCurrencyAndBranchAndTypeAndDate(
                branch.getId(), TransactionType.BUY, date);

        Map<String, TrbCurrencyLineDto> map = new LinkedHashMap<>();

        for (Object[] row : sellRows) {
            String code = (String) row[0];
            BigDecimal amount = row[1] != null ? ((BigDecimal) row[1]).setScale(4, RoundingMode.HALF_UP) : BigDecimal.ZERO;
            map.computeIfAbsent(code, k -> TrbCurrencyLineDto.builder()
                    .currencyCode(k)
                    .sold(BigDecimal.ZERO)
                    .bought(BigDecimal.ZERO)
                    .bankCardAmount(BigDecimal.ZERO)
                    .bankCardFee(BigDecimal.ZERO)
                    .build()).setSold(amount);
        }

        // Bankkártyás eladások valutanemenként (legacy: _bankkartyas + _bkkezdij)
        List<Object[]> cardRows = transactionRepository.sumCardSalesByCurrencyAndBranchAndDate(
                branch.getId(), date);
        for (Object[] row : cardRows) {
            String code = (String) row[0];
            BigDecimal cardAmount = row[1] != null ? ((BigDecimal) row[1]).setScale(4, RoundingMode.HALF_UP) : BigDecimal.ZERO;
            BigDecimal cardFee = row[2] != null ? ((BigDecimal) row[2]).setScale(4, RoundingMode.HALF_UP) : BigDecimal.ZERO;
            TrbCurrencyLineDto dto = map.get(code);
            if (dto != null) {
                dto.setBankCardAmount(cardAmount);
                dto.setBankCardFee(cardFee);
            }
        }

        for (Object[] row : buyRows) {
            String code = (String) row[0];
            BigDecimal amount = row[1] != null ? ((BigDecimal) row[1]).setScale(4, RoundingMode.HALF_UP) : BigDecimal.ZERO;
            map.computeIfAbsent(code, k -> TrbCurrencyLineDto.builder()
                    .currencyCode(k)
                    .sold(BigDecimal.ZERO)
                    .bought(BigDecimal.ZERO)
                    .bankCardAmount(BigDecimal.ZERO)
                    .bankCardFee(BigDecimal.ZERO)
                    .build()).setBought(amount);
        }

        return new ArrayList<>(map.values());
    }

    private List<TrbBankFlowLineDto> buildBankFlowLines(UUID companyId, LocalDate date) {
        List<InventoryMovement> bankFlows = movementRepository.findBankFlowsByCompanyId(
                companyId, date, date);

        Map<String, TrbBankFlowLineDto> flowMap = new LinkedHashMap<>();
        for (InventoryMovement m : bankFlows) {
            String code = m.getCurrency().getCode();
            TrbBankFlowLineDto flow = flowMap.computeIfAbsent(code,
                    k -> TrbBankFlowLineDto.builder()
                            .currencyCode(code)
                            .withdrawn(BigDecimal.ZERO)
                            .deposited(BigDecimal.ZERO)
                            .build());

            if (m.getMovementType() == MovementType.BANK_WITHDRAW) {
                flow.setWithdrawn(flow.getWithdrawn().add(m.getAmount()).setScale(4, RoundingMode.HALF_UP));
            } else if (m.getMovementType() == MovementType.BANK_DEPOSIT) {
                flow.setDeposited(flow.getDeposited().add(m.getAmount()).setScale(4, RoundingMode.HALF_UP));
            }
        }

        return new ArrayList<>(flowMap.values());
    }

    // ============ UTILITIES ============

    private CellStyle createHeaderStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        Font font = wb.createFont();
        font.setBold(true);
        font.setFontHeightInPoints((short) 10);
        style.setFont(font);
        style.setAlignment(HorizontalAlignment.CENTER);
        return style;
    }

    private CellStyle createNumberStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        DataFormat format = wb.createDataFormat();
        style.setDataFormat(format.getFormat("#,##0.0000"));
        return style;
    }

    private String padRight(String s, int len) {
        if (s == null) s = "";
        return String.format("%-" + len + "s", s);
    }

    private String formatBd(BigDecimal bd) {
        if (bd == null) return "0";
        return bd.setScale(0, RoundingMode.HALF_UP).toPlainString();
    }
}
