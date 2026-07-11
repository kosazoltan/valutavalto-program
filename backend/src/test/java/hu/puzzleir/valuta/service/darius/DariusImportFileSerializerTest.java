package hu.puzzleir.valuta.service.darius;

import hu.puzzleir.valuta.dto.darius.DariusImportFileModel;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.BranchBlock;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.FixingBlock;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.FixingRow;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.StockRow;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.TurnoverRow;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class DariusImportFileSerializerTest {

    private final DariusImportFileSerializer serializer = new DariusImportFileSerializer();

    @Test
    void serializesCompleteFileWithoutBomWithCrLfAndExactTabCounts() {
        BranchBlock branch = new BranchBlock(
                "276",
                true,
                -1,
                LocalTime.of(10, 58),
                List.of(
                        stock("HUF", "20000", 5),
                        stock("EUR", "100", 3)),
                List.of(
                        turnover("HUF", "0", "0", "5000", "20000", "100", "25", "30"),
                        turnover("EUR", "200", "100", "50", "12.50", "0", "0", "0")));
        DariusImportFileModel model = new DariusImportFileModel(
                LocalDate.of(2026, 7, 1), "108114", List.of(), List.of(branch));

        byte[] bytes = serializer.serialize(model);

        String expected = String.join("\r\n",
                "BEGIN",
                "TNAP\t2026-07-01",
                "PV_AZONOSITO\t108114",
                "JELENTES PENZTARALLOMANY",
                "UZLETHELYISEG_AZONOSITO\t276",
                "ERTEKNAP\t-1",
                "IDOPONT\t10:58",
                "KP\tEUR\t100\t3",
                "KP\tHUF\t20000\t5",
                "JELENTES END",
                "JELENTES UGYFELFORGALOM V3",
                "UZLETHELYISEG_AZONOSITO\t276",
                "ERTEKNAP\t-1",
                "EUR\t200\t100\t50\t12.5\t0\t0\t0",
                "HUF\t0\t0\t5000\t20000\t100\t25\t30",
                "JELENTES END",
                "END",
                "");
        String content = new String(bytes, StandardCharsets.UTF_8);

        assertThat(content).isEqualTo(expected);
        assertThat(bytes[0]).isEqualTo((byte) 'B');
        assertThat(content).doesNotContain("\nBEGIN").endsWith("END\r\n");
        for (String line : content.split("\r\n", -1)) {
            if (line.startsWith("KP\t")) {
                assertThat(tabCount(line)).isEqualTo(3);
            } else if (line.startsWith("EUR\t") || line.startsWith("HUF\t")) {
                assertThat(tabCount(line)).isEqualTo(7);
            }
        }
    }

    @Test
    void keepsFourPosColumnsEmptyWhenBranchHasNoPos() {
        BranchBlock branch = new BranchBlock(
                "276",
                false,
                0,
                LocalTime.NOON,
                List.of(stock("EUR", "100", 1)),
                List.of(turnover("EUR", "200", "100", "0", "0", "0", "0", "0")));

        String content = serialize(branch);

        assertThat(content).contains("EUR\t200\t100\t\t\t\t\t0\r\n");
        assertThat(tabCount("EUR\t200\t100\t\t\t\t\t0")).isEqualTo(7);
    }

    @Test
    void formatsFxPosBoughtWithoutTrailingZerosAndHufAsInteger() {
        BranchBlock branch = new BranchBlock(
                "276",
                true,
                0,
                LocalTime.NOON,
                List.of(stock("EUR", "100", 1)),
                List.of(
                        turnover("EUR", "0", "0", "0", "12.50", "0", "0", "0"),
                        turnover("HUF", "0", "0", "1234", "5000.00", "0", "0", "0")));

        String content = serialize(branch);

        assertThat(content).contains("EUR\t0\t0\t0\t12.5\t0\t0\t0\r\n");
        assertThat(content).contains("HUF\t0\t0\t1234\t5000\t0\t0\t0\r\n");
    }

    @Test
    void sortsBranchesByNumericBankCodeDeterministically() {
        BranchBlock high = branch("1000");
        BranchBlock low = branch("276");

        String content = new String(serializer.serialize(new DariusImportFileModel(
                LocalDate.of(2026, 7, 1), "108114", List.of(), List.of(high, low))), StandardCharsets.UTF_8);

        assertThat(content.indexOf("UZLETHELYISEG_AZONOSITO\t276"))
                .isLessThan(content.indexOf("UZLETHELYISEG_AZONOSITO\t1000"));
    }

    @Test
    void emitsFixingBlocksAfterHeaderBeforeStockBlocks() {
        FixingBlock high = new FixingBlock("7002", List.of(new FixingRow(
                "USD", BigDecimal.ZERO, new BigDecimal("20000"))));
        FixingBlock low = new FixingBlock("7001", List.of(new FixingRow(
                "EUR", new BigDecimal("50000"), BigDecimal.ZERO)));

        String content = new String(serializer.serialize(new DariusImportFileModel(
                LocalDate.of(2026, 7, 1),
                "108114",
                List.of(high, low),
                List.of(branch("276")))), StandardCharsets.UTF_8);

        String crlf = new String(new char[]{13, 10});
        String expectedPrefix = String.join(crlf,
                "BEGIN",
                "TNAP\t2026-07-01",
                "PV_AZONOSITO\t108114",
                "JELENTES UZLETKOTES",
                "BANKFIOK_AZONOSITO\t7001",
                "EUR\t50000\t0",
                "JELENTES END",
                "JELENTES UZLETKOTES",
                "BANKFIOK_AZONOSITO\t7002",
                "USD\t0\t20000",
                "JELENTES END",
                "JELENTES PENZTARALLOMANY") + crlf;
        assertThat(content).startsWith(expectedPrefix);
    }

    @Test
    void emitsFixingRowsSortedByCurrencyAsIntegers() {
        FixingBlock block = new FixingBlock("7001", List.of(
                new FixingRow("USD", BigDecimal.ZERO, new BigDecimal("20000.00")),
                new FixingRow("EUR", new BigDecimal("50000.00"), BigDecimal.ZERO)));

        String content = new String(serializer.serialize(new DariusImportFileModel(
                LocalDate.of(2026, 7, 1),
                "108114",
                List.of(block),
                List.of(branch("276")))), StandardCharsets.UTF_8);

        String crlf = new String(new char[]{13, 10});
        assertThat(content).contains("BANKFIOK_AZONOSITO\t7001" + crlf
                + "EUR\t50000\t0" + crlf
                + "USD\t0\t20000" + crlf
                + "JELENTES END" + crlf);
    }

    @Test
    void omitsFixingSectionEntirelyWhenNoBlocks() {
        String content = serialize(branch("276"));

        assertThat(content).doesNotContain("JELENTES UZLETKOTES");
    }

    private String serialize(BranchBlock branch) {
        return new String(serializer.serialize(new DariusImportFileModel(
                LocalDate.of(2026, 7, 1), "108114", List.of(), List.of(branch))), StandardCharsets.UTF_8);
    }

    private static BranchBlock branch(String bankCode) {
        return new BranchBlock(
                bankCode,
                false,
                0,
                LocalTime.NOON,
                List.of(stock("EUR", "100", 1)),
                List.of());
    }

    private static StockRow stock(String currency, String faceValue, int quantity) {
        return new StockRow(currency, new BigDecimal(faceValue), quantity);
    }

    private static TurnoverRow turnover(
            String currency,
            String cashSold,
            String cashBought,
            String posSold,
            String posBought,
            String hufPosFee,
            String fxPosFee,
            String cashFee) {
        return new TurnoverRow(
                currency,
                new BigDecimal(cashSold),
                new BigDecimal(cashBought),
                new BigDecimal(posSold),
                new BigDecimal(posBought),
                new BigDecimal(hufPosFee),
                new BigDecimal(fxPosFee),
                new BigDecimal(cashFee));
    }

    private static int tabCount(String value) {
        return (int) value.chars().filter(character -> character == '\t').count();
    }
}
