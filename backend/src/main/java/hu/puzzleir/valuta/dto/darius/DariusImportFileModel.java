package hu.puzzleir.valuta.dto.darius;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

public record DariusImportFileModel(LocalDate tnap, String pvCode, List<BranchBlock> branches) {

    public record BranchBlock(
            String uzlethelyisegAzonosito,
            boolean hasPos,
            int erteknap,
            LocalTime idopont,
            List<StockRow> stockRows,
            List<TurnoverRow> turnoverRows) {
    }

    public record StockRow(String currencyCode, BigDecimal faceValue, int quantity) {
    }

    public record TurnoverRow(
            String currencyCode,
            BigDecimal cashSold,
            BigDecimal cashBought,
            BigDecimal posSold,
            BigDecimal posBought,
            BigDecimal hufPosFee,
            BigDecimal fxPosFee,
            BigDecimal cashFee) {
    }
}
