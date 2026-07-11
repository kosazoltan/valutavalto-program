package hu.puzzleir.valuta.service.darius;

import hu.puzzleir.valuta.dto.darius.DariusImportFileModel;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.BranchBlock;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.FixingBlock;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.FixingRow;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.StockRow;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.TurnoverRow;
import hu.puzzleir.valuta.entity.ShiftedCalendarDay;
import hu.puzzleir.valuta.repository.ShiftedCalendarDayRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.MonthDay;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Pattern;

@Component
public class DariusImportPreflightValidator {

    private static final Pattern ISO_CODE = Pattern.compile("[A-Z]{3}");
    private static final Pattern POSITIVE_INTEGER = Pattern.compile("[1-9][0-9]*");
    private static final Set<String> POS_FX_CURRENCIES = Set.of("EUR", "GBP", "USD");
    static final ZoneId BUSINESS_ZONE = ZoneId.of("Europe/Budapest");
    private static final Set<MonthDay> HUNGARIAN_FIXED_HOLIDAYS = Set.of(
            MonthDay.of(1, 1),
            MonthDay.of(3, 15),
            MonthDay.of(5, 1),
            MonthDay.of(8, 20),
            MonthDay.of(10, 23),
            MonthDay.of(11, 1),
            MonthDay.of(12, 25),
            MonthDay.of(12, 26));

    private final ShiftedCalendarDayRepository shiftedCalendarDayRepository;
    private final Clock clock;

    @Autowired
    public DariusImportPreflightValidator(ShiftedCalendarDayRepository shiftedCalendarDayRepository) {
        this(shiftedCalendarDayRepository, Clock.system(BUSINESS_ZONE));
    }

    DariusImportPreflightValidator(ShiftedCalendarDayRepository shiftedCalendarDayRepository, Clock clock) {
        this.shiftedCalendarDayRepository = shiftedCalendarDayRepository;
        this.clock = clock;
    }

    public List<String> validate(DariusImportFileModel model) {
        List<String> errors = new ArrayList<>();
        if (model == null) {
            errors.add(global("hiányzó importfájl-modell"));
            return errors;
        }
        if (model.pvCode() == null || model.pvCode().isBlank()) {
            errors.add(global("hiányzik a PV_AZONOSITO konfiguráció"));
        }
        if (model.tnap() == null) {
            errors.add(global("hiányzik a TNAP"));
        } else {
            if (model.tnap().isAfter(LocalDate.now(clock))) {
                errors.add(global("a TNAP nem lehet jövőbeli"));
            }
            if (!isBusinessDay(model.tnap())) {
                errors.add(global("a TNAP csak banki munkanap lehet"));
            }
        }
        if (model.fixingBlocks() == null) {
            errors.add(global("hiányzik a fixing blokklista"));
        } else {
            validateUniqueFixingIdentifiers(model.fixingBlocks(), errors);
            for (FixingBlock block : model.fixingBlocks()) {
                validateFixingBlock(block, errors);
            }
        }
        if (model.branches() == null || model.branches().isEmpty()) {
            errors.add(global("nincs jelenthető adat egyetlen aktív irodához sem"));
            return errors;
        }

        validateUniqueBranchIdentifiers(model.branches(), errors);
        for (BranchBlock branch : model.branches()) {
            validateBranch(branch, errors);
        }
        return errors;
    }

    private void validateUniqueFixingIdentifiers(List<FixingBlock> blocks, List<String> errors) {
        Set<String> seen = new HashSet<>();
        Set<String> duplicates = new LinkedHashSet<>();
        for (FixingBlock block : blocks) {
            if (block != null && !seen.add(block.bankfiokAzonosito())) {
                duplicates.add(String.valueOf(block.bankfiokAzonosito()));
            }
        }
        if (!duplicates.isEmpty()) {
            errors.add(global("duplikált BANKFIOK_AZONOSITO: " + String.join(", ", duplicates)));
        }
    }

    private void validateFixingBlock(FixingBlock block, List<String> errors) {
        if (block == null) {
            errors.add(global("hiányzó UZLETKOTES blokk"));
            return;
        }
        String code = block.bankfiokAzonosito();
        String fixingScope = "FIXING:" + String.valueOf(code);
        if (code == null || code.isBlank() || code.chars().anyMatch(Character::isWhitespace)) {
            errors.add(error(fixingScope,
                    "a BANKFIOK_AZONOSITO nem lehet üres, whitespace-os vagy TAB-os"));
        }
        if (block.rows() == null || block.rows().isEmpty()) {
            errors.add(error(fixingScope, "üres az UZLETKOTES sorlista"));
            return;
        }

        Set<String> seenCurrencies = new HashSet<>();
        Set<String> duplicateCurrencies = new LinkedHashSet<>();
        for (FixingRow row : block.rows()) {
            if (row == null) {
                errors.add(error(fixingScope, "hiányzó UZLETKOTES adatsor"));
                continue;
            }
            validateCurrencyCode(fixingScope, row.currencyCode(), errors);
            validateNonNegativeInteger(fixingScope, "beszállított összeg", row.deliveredAmount(), errors);
            validateNonNegativeInteger(fixingScope, "elvitt összeg", row.collectedAmount(), errors);
            if (isZero(row.deliveredAmount()) && isZero(row.collectedAmount())) {
                errors.add(error(fixingScope, "legalább az egyik összegnek pozitívnak kell lennie"));
            }
            if (!seenCurrencies.add(row.currencyCode())) {
                duplicateCurrencies.add(String.valueOf(row.currencyCode()));
            }
        }
        if (!duplicateCurrencies.isEmpty()) {
            errors.add(error(fixingScope,
                    "duplikált valutakód az UZLETKOTES blokkban: "
                            + String.join(", ", duplicateCurrencies)));
        }
    }

    private void validateUniqueBranchIdentifiers(List<BranchBlock> branches, List<String> errors) {
        Set<String> seen = new HashSet<>();
        Set<String> duplicates = new LinkedHashSet<>();
        for (BranchBlock branch : branches) {
            if (branch != null && !seen.add(branch.uzlethelyisegAzonosito())) {
                duplicates.add(String.valueOf(branch.uzlethelyisegAzonosito()));
            }
        }
        if (!duplicates.isEmpty()) {
            errors.add(global("duplikált uzlethelyisegAzonosito: " + String.join(", ", duplicates)));
        }
    }

    private void validateBranch(BranchBlock branch, List<String> errors) {
        if (branch == null) {
            errors.add(global("hiányzó irodai jelentésblokk"));
            return;
        }
        String scope = scope(branch.uzlethelyisegAzonosito());
        if (!isPositiveInteger(branch.uzlethelyisegAzonosito())) {
            errors.add(error(scope, "a branch bankCode nem pozitív egész: '"
                    + String.valueOf(branch.uzlethelyisegAzonosito()) + "'"));
        }
        if (branch.erteknap() < -200 || branch.erteknap() > 200) {
            errors.add(error(scope, "az ERTEKNAP értéke csak -200 és 200 között lehet"));
        }
        if (branch.stockRows() == null || branch.stockRows().isEmpty()) {
            errors.add(error(scope, "nincs címlet-snapshot (closingType=1)"));
        } else {
            if (branch.idopont() == null) {
                errors.add(error(scope, "a címlet-snapshot IDOPONT értéke hiányzik"));
            }
            for (StockRow row : branch.stockRows()) {
                validateStockRow(scope, row, errors);
            }
        }

        List<TurnoverRow> turnoverRows = branch.turnoverRows();
        if (turnoverRows == null) {
            errors.add(error(scope, "hiányzik az ügyfélforgalom sorlista"));
            return;
        }
        for (TurnoverRow row : turnoverRows) {
            validateTurnoverRow(scope, branch.hasPos(), row, errors);
        }
        validatePosRelationships(scope, turnoverRows, errors);
    }

    private void validateStockRow(String scope, StockRow row, List<String> errors) {
        if (row == null) {
            errors.add(error(scope, "hiányzó PENZTARALLOMANY adatsor"));
            return;
        }
        validateCurrencyCode(scope, row.currencyCode(), errors);
        if (row.faceValue() == null
                || row.faceValue().signum() <= 0
                || !isIntegral(row.faceValue())) {
            errors.add(error(scope, "a címlet-kód csak pozitív egész lehet: " + row.faceValue()));
        }
        if (row.quantity() <= 0) {
            errors.add(error(scope, "a címlet darabszám csak pozitív egész lehet: " + row.quantity()));
        }
    }

    private void validateTurnoverRow(
            String scope,
            boolean hasPos,
            TurnoverRow row,
            List<String> errors) {
        if (row == null) {
            errors.add(error(scope, "hiányzó UGYFELFORGALOM V3 adatsor"));
            return;
        }
        validateCurrencyCode(scope, row.currencyCode(), errors);
        validateNonNegativeInteger(scope, "készpénz eladott", row.cashSold(), errors);
        validateNonNegativeInteger(scope, "készpénz vett", row.cashBought(), errors);
        validateNonNegativeInteger(scope, "POS eladott", row.posSold(), errors);
        validateNonNegative(scope, "POS vett", row.posBought(), errors);
        validateNonNegativeInteger(scope, "HUF POS kezelési költség", row.hufPosFee(), errors);
        validateNonNegativeInteger(scope, "deviza POS kezelési költség", row.fxPosFee(), errors);
        validateNonNegativeInteger(scope, "készpénz kezelési költség", row.cashFee(), errors);

        if (row.posBought() != null && row.posBought().signum() >= 0) {
            if ("HUF".equals(row.currencyCode()) && !isIntegral(row.posBought())) {
                errors.add(error(scope, "a HUF POS vett összeg csak egész lehet"));
            } else if (POS_FX_CURRENCIES.contains(row.currencyCode()) && !scaleAtMost2(row.posBought())) {
                errors.add(error(scope, "a deviza POS vett összeg legfeljebb 2 tizedes lehet"));
            }
        }

        boolean hasAnyPosValue = nonZero(row.posSold())
                || nonZero(row.posBought())
                || nonZero(row.hufPosFee())
                || nonZero(row.fxPosFee());
        if (!hasPos && hasAnyPosValue) {
            errors.add(error(scope, "az irodának nincs POS jogosultsága, de POS adat érkezett"));
        }
        if (hasAnyPosAmount(row)
                && !"HUF".equals(row.currencyCode())
                && !POS_FX_CURRENCIES.contains(row.currencyCode())) {
            errors.add(error(scope, row.currencyCode() + " valutához nem engedélyezett POS forgalom"));
        }
        if (!"HUF".equals(row.currencyCode()) && positive(row.hufPosFee())) {
            errors.add(error(scope, "a HUF POS kezelési költség kizárólag a HUF sorban jelenthető"));
        }
        if (!"HUF".equals(row.currencyCode()) && positive(row.fxPosFee())) {
            errors.add(error(scope, "a deviza POS kezelési költség kizárólag a HUF sorban jelenthető"));
        }
        if (!"HUF".equals(row.currencyCode()) && positive(row.cashFee())) {
            errors.add(error(scope, "a készpénz kezelési költség kizárólag a HUF sorban jelenthető"));
        }
    }

    private void validatePosRelationships(String scope, List<TurnoverRow> rows, List<String> errors) {
        TurnoverRow huf = rows.stream()
                .filter(row -> row != null && "HUF".equals(row.currencyCode()))
                .findFirst()
                .orElse(null);
        boolean hufPosSold = huf != null && positive(huf.posSold());
        boolean hufPosBought = huf != null && positive(huf.posBought());
        boolean fxPosSold = rows.stream().anyMatch(row -> isFx(row) && positive(row.posSold()));
        boolean fxPosBought = rows.stream().anyMatch(row -> isFx(row) && positive(row.posBought()));

        if (fxPosBought && !hufPosSold) {
            errors.add(error(scope, "a deviza POS vett forgalomhoz hiányzik a POS eladott HUF tükör"));
        }
        if (hufPosSold && !fxPosBought) {
            errors.add(error(scope, "a POS eladott HUF forgalomhoz hiányzik a deviza POS vett pár"));
        }
        if (fxPosSold && !hufPosBought) {
            errors.add(error(scope, "a deviza POS eladott forgalomhoz hiányzik a POS vett HUF tükör"));
        }
        if (hufPosBought && !fxPosSold) {
            errors.add(error(scope, "a POS vett HUF forgalomhoz hiányzik a deviza POS eladott pár"));
        }
        if (huf != null && positive(huf.fxPosFee()) && (!hufPosSold || !fxPosBought)) {
            errors.add(error(scope,
                    "a deviza POS kezelési költség csak párosított HUF eladás és deviza vétel mellett lehet pozitív"));
        }
        if (huf != null && positive(huf.hufPosFee()) && (!hufPosBought || !fxPosSold)) {
            errors.add(error(scope,
                    "a HUF POS kezelési költség csak párosított deviza eladás és HUF vétel mellett lehet pozitív"));
        }
    }

    private void validateCurrencyCode(String scope, String currencyCode, List<String> errors) {
        if (currencyCode == null || !ISO_CODE.matcher(currencyCode).matches()) {
            errors.add(error(scope, "az ISO valutakód formátuma csak [A-Z]{3} lehet: " + currencyCode));
        }
    }

    private void validateNonNegativeInteger(
            String scope,
            String field,
            BigDecimal value,
            List<String> errors) {
        validateNonNegative(scope, field, value, errors);
        if (value != null && !isIntegral(value)) {
            errors.add(error(scope, "a(z) " + field + " értéke csak egész lehet: " + value));
        }
    }

    private void validateNonNegative(
            String scope,
            String field,
            BigDecimal value,
            List<String> errors) {
        if (value == null) {
            errors.add(error(scope, "hiányzik a(z) " + field + " értéke"));
        } else if (value.signum() < 0) {
            errors.add(error(scope, "a(z) " + field + " értéke nem lehet negatív: " + value));
        }
    }

    private boolean isPositiveInteger(String value) {
        return value != null && POSITIVE_INTEGER.matcher(value).matches();
    }

    private boolean isIntegral(BigDecimal value) {
        return value.stripTrailingZeros().scale() <= 0;
    }

    private boolean scaleAtMost2(BigDecimal value) {
        return value.stripTrailingZeros().scale() <= 2;
    }

    private boolean hasAnyPosAmount(TurnoverRow row) {
        return nonZero(row.posSold()) || nonZero(row.posBought());
    }

    private boolean isFx(TurnoverRow row) {
        return row != null && POS_FX_CURRENCIES.contains(row.currencyCode());
    }

    private boolean isBusinessDay(LocalDate date) {
        Optional<ShiftedCalendarDay> shifted = shiftedCalendarDayRepository.findByCalendarDate(date);
        if (shifted.isPresent()) {
            return shifted.get().isWorkday();
        }
        DayOfWeek dayOfWeek = date.getDayOfWeek();
        boolean weekend = dayOfWeek == DayOfWeek.SATURDAY || dayOfWeek == DayOfWeek.SUNDAY;
        return !weekend && !isHungarianHoliday(date);
    }

    private boolean isHungarianHoliday(LocalDate date) {
        if (HUNGARIAN_FIXED_HOLIDAYS.contains(MonthDay.from(date))) {
            return true;
        }
        LocalDate easter = easterSunday(date.getYear());
        return date.equals(easter.minusDays(2))
                || date.equals(easter.plusDays(1))
                || date.equals(easter.plusDays(50));
    }

    private LocalDate easterSunday(int year) {
        int a = year % 19;
        int b = year / 100;
        int c = year % 100;
        int d = b / 4;
        int e = b % 4;
        int f = (b + 8) / 25;
        int g = (b - f + 1) / 3;
        int h = (19 * a + b - d - g + 15) % 30;
        int i = c / 4;
        int k = c % 4;
        int l = (32 + 2 * e + 2 * i - h - k) % 7;
        int m = (a + 11 * h + 22 * l) / 451;
        int month = (h + l - 7 * m + 114) / 31;
        int day = ((h + l - 7 * m + 114) % 31) + 1;
        return LocalDate.of(year, month, day);
    }

    private boolean positive(BigDecimal value) {
        return value != null && value.signum() > 0;
    }

    private boolean isZero(BigDecimal value) {
        return value != null && value.signum() == 0;
    }

    private boolean nonZero(BigDecimal value) {
        return value != null && value.signum() != 0;
    }

    private String scope(String bankCode) {
        return bankCode == null || bankCode.isBlank() ? "GLOBAL" : bankCode;
    }

    private String global(String message) {
        return error("GLOBAL", message);
    }

    private String error(String scope, String message) {
        return "[" + scope + "] " + message;
    }
}
