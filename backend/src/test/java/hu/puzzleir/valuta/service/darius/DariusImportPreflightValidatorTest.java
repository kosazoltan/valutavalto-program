package hu.puzzleir.valuta.service.darius;

import hu.puzzleir.valuta.dto.darius.DariusImportFileModel;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.BranchBlock;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.StockRow;
import hu.puzzleir.valuta.dto.darius.DariusImportFileModel.TurnoverRow;
import hu.puzzleir.valuta.entity.ShiftedCalendarDay;
import hu.puzzleir.valuta.repository.ShiftedCalendarDayRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class DariusImportPreflightValidatorTest {

    private static final LocalDate BUSINESS_DAY = LocalDate.of(2025, 4, 22);
    private static final Clock CLOCK = Clock.fixed(Instant.parse("2025-04-22T12:00:00Z"), ZoneOffset.UTC);

    private final ShiftedCalendarDayRepository shiftedCalendarDayRepository =
            mock(ShiftedCalendarDayRepository.class);
    private final DariusImportPreflightValidator validator =
            new DariusImportPreflightValidator(shiftedCalendarDayRepository, CLOCK);

    @BeforeEach
    void setUp() {
        when(shiftedCalendarDayRepository.findByCalendarDate(any())).thenReturn(Optional.empty());
    }

    @Test
    void validatesGlobalFieldsAndErteknapBoundaries() {
        assertError(model(null, BUSINESS_DAY, branch("276", false, 0)), "GLOBAL", "PV_AZONOSITO");
        assertError(model("108114", BUSINESS_DAY.plusDays(1), branch("276", false, 0)), "GLOBAL", "jövőbeli");
        assertError(model("108114", BUSINESS_DAY, branch("276", false, -201)), "276", "ERTEKNAP");
        assertError(model("108114", BUSINESS_DAY, branch("276", false, 201)), "276", "ERTEKNAP");

        for (int value : List.of(-200, 0, 200)) {
            assertThat(validator.validate(model("108114", BUSINESS_DAY, branch("276", false, value))))
                    .isEmpty();
        }
    }

    @Test
    void usesBudapestBusinessDateAtUtcMidnightBoundary() {
        Clock utcMidnightBoundary = Clock.fixed(
                Instant.parse("2025-04-21T22:30:00Z"),
                ZoneId.of("Europe/Budapest"));
        DariusImportPreflightValidator budapestValidator =
                new DariusImportPreflightValidator(shiftedCalendarDayRepository, utcMidnightBoundary);

        assertThat(budapestValidator.validate(model("108114", BUSINESS_DAY, branch("276", false, 0))))
                .isEmpty();
    }

    @Test
    void accumulatesDuplicateBranchIdentifiersAsSingleGlobalError() {
        DariusImportFileModel duplicateBranches = new DariusImportFileModel(
                BUSINESS_DAY,
                "108114",
                List.of(
                        branch("276", false, 0),
                        branch("276", true, 1),
                        branch("277", false, 0),
                        branch("277", true, 1)));

        assertThat(validator.validate(duplicateBranches))
                .containsExactly("[GLOBAL] duplikált uzlethelyisegAzonosito: 276, 277");
    }

    @Test
    void rejectsWeekendAndFixedHungarianHolidayAsNonBusinessDays() {
        assertError(model("108114", LocalDate.of(2025, 4, 19), branch("276", false, 0)),
                "GLOBAL", "banki munkanap");
        assertError(model("108114", LocalDate.of(2025, 1, 1), branch("276", false, 0)),
                "GLOBAL", "banki munkanap");
    }

    @Test
    void shiftedSaturdayWorkdayOverridesWeekend() {
        LocalDate shiftedSaturday = LocalDate.of(2025, 4, 19);
        when(shiftedCalendarDayRepository.findByCalendarDate(shiftedSaturday))
                .thenReturn(Optional.of(ShiftedCalendarDay.builder()
                        .calendarDate(shiftedSaturday)
                        .workday(true)
                        .build()));

        assertThat(validator.validate(model("108114", shiftedSaturday, branch("276", false, 0))))
                .isEmpty();
    }

    @Test
    void shiftedWeekdayRestDayOverridesNormalBusinessDay() {
        when(shiftedCalendarDayRepository.findByCalendarDate(BUSINESS_DAY))
                .thenReturn(Optional.of(ShiftedCalendarDay.builder()
                        .calendarDate(BUSINESS_DAY)
                        .workday(false)
                        .build()));

        assertError(model("108114", BUSINESS_DAY, branch("276", false, 0)),
                "GLOBAL", "banki munkanap");
    }

    @Test
    void requiresPositiveIntegerBankCode() {
        for (String bankCode : List.of("BR076", "", "0", "-3")) {
            assertError(model("108114", BUSINESS_DAY, branch(bankCode, false, 0)), "bankCode", "pozitív egész");
        }
        assertThat(validator.validate(model("108114", BUSINESS_DAY, branch("276", false, 0))))
                .isEmpty();
    }

    @Test
    void validatesStockFaceValueQuantityAndCurrencyCode() {
        BranchBlock invalid = new BranchBlock(
                "276",
                false,
                0,
                LocalTime.NOON,
                List.of(
                        stock("EUR", "0.50", 1),
                        stock("usd", "100", 0),
                        stock("ABCD", "50", -1)),
                List.of());

        List<String> errors = validator.validate(model("108114", BUSINESS_DAY, invalid));

        assertThat(errors).anyMatch(error -> error.contains("címlet-kód") && error.contains("egész"));
        assertThat(errors).anyMatch(error -> error.contains("darabszám") && error.contains("pozitív"));
        assertThat(errors).anyMatch(error -> error.contains("ISO") && error.contains("[A-Z]{3}"));
    }

    @Test
    void validatesCashAndFeeIntegersAndNonNegativeAmounts() {
        BranchBlock invalid = branchWithTurnover(false, List.of(
                turnover("EUR", "1.5", "-1", "0", "0", "0", "0", "2.5")));

        List<String> errors = validator.validate(model("108114", BUSINESS_DAY, invalid));

        assertThat(errors).anyMatch(error -> error.contains("készpénz eladott") && error.contains("egész"));
        assertThat(errors).anyMatch(error -> error.contains("készpénz vett") && error.contains("negatív"));
        assertThat(errors).anyMatch(error -> error.contains("készpénz kezelési költség") && error.contains("egész"));
    }

    @Test
    void validatesPosScaleAndCurrencyRestrictions() {
        assertError(model("108114", BUSINESS_DAY, branchWithTurnover(true, List.of(
                turnover("EUR", "0", "0", "0", "12.345", "0", "0", "0")))), "POS vett", "2 tizedes");
        assertError(model("108114", BUSINESS_DAY, branchWithTurnover(true, List.of(
                turnover("HUF", "0", "0", "0", "12.5", "0", "0", "0")))), "POS vett", "egész");
        assertError(model("108114", BUSINESS_DAY, branchWithTurnover(true, List.of(
                turnover("CHF", "0", "0", "0", "1", "0", "0", "0")))), "CHF", "POS forgalom");

        BranchBlock scaleTwo = branchWithTurnover(true, List.of(
                turnover("EUR", "0", "0", "0", "12.50", "0", "0", "0"),
                turnover("HUF", "0", "0", "5000", "0", "0", "0", "0")));
        assertThat(validator.validate(model("108114", BUSINESS_DAY, scaleTwo))).isEmpty();
    }

    @Test
    void rejectsAnyPosValueForBranchWithoutPos() {
        BranchBlock invalid = branchWithTurnover(false, List.of(
                turnover("EUR", "0", "0", "1", "0", "0", "0", "0")));

        assertError(model("108114", BUSINESS_DAY, invalid), "276", "nincs POS");
    }

    @Test
    void enforcesBidirectionalPosMirrorMappings() {
        BranchBlock missingHufMirror = branchWithTurnover(true, List.of(
                turnover("EUR", "0", "0", "0", "10", "0", "0", "0")));
        BranchBlock orphanHufMirror = branchWithTurnover(true, List.of(
                turnover("HUF", "0", "0", "1000", "0", "0", "0", "0")));

        assertError(model("108114", BUSINESS_DAY, missingHufMirror), "POS vett", "HUF");
        assertError(model("108114", BUSINESS_DAY, orphanHufMirror), "POS eladott HUF", "deviza");
    }

    @Test
    void enforcesFeePlacementAndFxFeePairing() {
        BranchBlock feeOutsideHuf = branchWithTurnover(true, List.of(
                turnover("EUR", "0", "0", "0", "0", "0", "1", "0")));
        BranchBlock unpairedFxFee = branchWithTurnover(true, List.of(
                turnover("HUF", "0", "0", "0", "0", "0", "1", "0")));
        BranchBlock hufPosFeeOutsideHuf = branchWithTurnover(true, List.of(
                turnover("EUR", "0", "0", "0", "0", "1", "0", "0")));

        assertError(model("108114", BUSINESS_DAY, feeOutsideHuf), "deviza POS kezelési költség", "HUF");
        assertError(model("108114", BUSINESS_DAY, unpairedFxFee), "deviza POS kezelési költség", "párosított");
        assertError(model("108114", BUSINESS_DAY, hufPosFeeOutsideHuf), "HUF POS kezelési költség", "HUF sor");
    }

    @Test
    void requiresSnapshotAndAtLeastOneReportableBranch() {
        BranchBlock noSnapshot = new BranchBlock(
                "276",
                false,
                0,
                null,
                List.of(),
                List.of(turnover("EUR", "1", "0", "0", "0", "0", "0", "0")));

        assertError(model("108114", BUSINESS_DAY, noSnapshot), "276", "nincs címlet-snapshot");
        assertError(new DariusImportFileModel(BUSINESS_DAY, "108114", List.of()), "GLOBAL", "nincs jelenthető adat");
    }

    @Test
    void accumulatesAllIndependentErrors() {
        DariusImportFileModel invalid = model(
                null,
                LocalDate.of(2025, 4, 19),
                branch("276", false, 0));

        List<String> errors = validator.validate(invalid);

        assertThat(errors).hasSize(2);
        assertThat(errors).allMatch(error -> error.startsWith("[GLOBAL]"));
        assertThat(errors).anyMatch(error -> error.contains("PV_AZONOSITO"));
        assertThat(errors).anyMatch(error -> error.contains("banki munkanap"));
    }

    private void assertError(DariusImportFileModel model, String... fragments) {
        assertThat(validator.validate(model)).anyMatch(error -> {
            for (String fragment : fragments) {
                if (!error.contains(fragment)) {
                    return false;
                }
            }
            return true;
        });
    }

    private static DariusImportFileModel model(String pvCode, LocalDate tnap, BranchBlock branch) {
        return new DariusImportFileModel(tnap, pvCode, List.of(branch));
    }

    private static BranchBlock branch(String bankCode, boolean hasPos, int erteknap) {
        return new BranchBlock(
                bankCode,
                hasPos,
                erteknap,
                LocalTime.NOON,
                List.of(stock("EUR", "100", 1)),
                List.of());
    }

    private static BranchBlock branchWithTurnover(boolean hasPos, List<TurnoverRow> rows) {
        return new BranchBlock(
                "276",
                hasPos,
                0,
                LocalTime.NOON,
                List.of(stock("EUR", "100", 1)),
                rows);
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
}
