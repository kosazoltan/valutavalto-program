package hu.puzzleir.valuta.service.darius;

import hu.puzzleir.valuta.dto.darius.DariusImportFileModel;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.BranchBlock;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.StockRow;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.TurnoverRow;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.time.format.DateTimeFormatter;
import java.util.Comparator;

@Component
public class DariusImportFileSerializer {

    private static final String CRLF = "\r\n";
    private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("HH:mm");

    public byte[] serialize(DariusImportFileModel model) {
        StringBuilder output = new StringBuilder();
        appendLine(output, "BEGIN");
        appendLine(output, "TNAP\t" + model.tnap());
        appendLine(output, "PV_AZONOSITO\t" + model.pvCode());

        model.branches().stream()
                .sorted(Comparator.comparing(
                        branch -> new BigInteger(branch.uzlethelyisegAzonosito())))
                .forEach(branch -> appendBranch(output, branch));

        appendLine(output, "END");
        return output.toString().getBytes(StandardCharsets.UTF_8);
    }

    private void appendBranch(StringBuilder output, BranchBlock branch) {
        appendLine(output, "JELENTES PENZTARALLOMANY");
        appendLine(output, "UZLETHELYISEG_AZONOSITO\t" + branch.uzlethelyisegAzonosito());
        appendLine(output, "ERTEKNAP\t" + branch.erteknap());
        appendLine(output, "IDOPONT\t" + branch.idopont().format(TIME_FORMAT));
        branch.stockRows().stream()
                .sorted(Comparator.comparing(StockRow::currencyCode)
                        .thenComparing(StockRow::faceValue, Comparator.reverseOrder()))
                .forEach(row -> appendLine(output,
                        "KP\t" + row.currencyCode()
                                + "\t" + formatInteger(row.faceValue())
                                + "\t" + row.quantity()));
        appendLine(output, "JELENTES END");

        if (!branch.turnoverRows().isEmpty()) {
            appendLine(output, "JELENTES UGYFELFORGALOM V3");
            appendLine(output, "UZLETHELYISEG_AZONOSITO\t" + branch.uzlethelyisegAzonosito());
            appendLine(output, "ERTEKNAP\t" + branch.erteknap());
            branch.turnoverRows().stream()
                    .sorted(Comparator.comparing(TurnoverRow::currencyCode))
                    .forEach(row -> appendTurnoverRow(output, branch.hasPos(), row));
            appendLine(output, "JELENTES END");
        }
    }

    private void appendTurnoverRow(StringBuilder output, boolean hasPos, TurnoverRow row) {
        output.append(row.currencyCode())
                .append('\t').append(formatInteger(row.cashSold()))
                .append('\t').append(formatInteger(row.cashBought()))
                .append('\t');
        if (hasPos) {
            output.append(formatInteger(row.posSold()))
                    .append('\t').append(formatPosBought(row.currencyCode(), row.posBought()))
                    .append('\t').append(formatInteger(row.hufPosFee()))
                    .append('\t').append(formatInteger(row.fxPosFee()));
        } else {
            output.append("\t\t\t");
        }
        output.append('\t').append(formatInteger(row.cashFee())).append(CRLF);
    }

    private String formatInteger(BigDecimal value) {
        return value.stripTrailingZeros().toBigIntegerExact().toString();
    }

    private String formatPosBought(String currencyCode, BigDecimal value) {
        if ("HUF".equals(currencyCode)) {
            return formatInteger(value);
        }
        return value.stripTrailingZeros().toPlainString();
    }

    private void appendLine(StringBuilder output, String line) {
        output.append(line).append(CRLF);
    }
}
