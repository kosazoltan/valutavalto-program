package hu.puzzleir.valuta.service.central;

import hu.puzzleir.valuta.dto.central.ReceivedDenominationsDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DailyDenominationSnapshot;
import hu.puzzleir.valuta.entity.DenominationAllowed;
import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DailyDenominationSnapshotRepository;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.MnbExchangeRateService;
import hu.puzzleir.valuta.service.MnbSettlementRateService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;

/**
 * FK-111 FR-1: read-only denomination matrix behind the "Keszletek, cimletek" tab.
 */
class ReceivedDenominationsServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("10000000-0000-0000-0000-000000000001");
    private static final UUID BRANCH_A = UUID.fromString("20000000-0000-0000-0000-00000000000a");
    private static final UUID BRANCH_B = UUID.fromString("20000000-0000-0000-0000-00000000000b");
    private static final UUID FOREIGN_BRANCH = UUID.fromString("30000000-0000-0000-0000-00000000000f");
    private static final LocalDate DATE = LocalDate.of(2026, 9, 10);

    private final BranchRepository branchRepository = mock(BranchRepository.class);
    private final DailyDenominationSnapshotRepository snapshotRepository =
            mock(DailyDenominationSnapshotRepository.class);
    private final DenominationAllowedRepository denominationAllowedRepository =
            mock(DenominationAllowedRepository.class);
    private final MnbExchangeRateService mnbExchangeRateService = mock(MnbExchangeRateService.class);
    private final MnbSettlementRateService mnbSettlementRateService = mock(MnbSettlementRateService.class);
    private final ReceivedDenominationsService service = new ReceivedDenominationsService(
            branchRepository,
            snapshotRepository,
            denominationAllowedRepository,
            mnbExchangeRateService,
            mnbSettlementRateService);

    @BeforeEach
    void stubRateLookups() {
        when(denominationAllowedRepository.findActiveByCompanyId(COMPANY_ID)).thenReturn(List.of());
        when(mnbExchangeRateService.getRatesForDate(any())).thenReturn(Map.of());
        when(mnbExchangeRateService.isQuotedByMnb(anyString())).thenReturn(true);
        when(mnbSettlementRateService.findSettlementRateAsOf(any(), anyString(), any()))
                .thenReturn(Optional.empty());
    }

    private static Branch branch(UUID id, String code, String name) {
        Branch branch = new Branch();
        branch.setId(id);
        branch.setCode(code);
        branch.setName(name);
        return branch;
    }

    private static DailyDenominationSnapshot snapshot(
            UUID branchId, String currency, String faceValue, int quantity, String totalValue) {
        return DailyDenominationSnapshot.builder()
                .branchId(branchId)
                .snapshotDate(DATE)
                .currencyCode(currency)
                .denominationType("BANKNOTE")
                .faceValue(new BigDecimal(faceValue))
                .quantity(quantity)
                .totalValue(new BigDecimal(totalValue))
                .closingType(1)
                .build();
    }

    private void withCompany(Runnable body) {
        try (MockedStatic<SecurityUtils> securityUtils = mockStatic(SecurityUtils.class)) {
            securityUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            body.run();
        }
    }

    @Test
    @DisplayName("FR-1: a ceg osszes irodaja EGYETLEN bulk lekerdezessel keszul")
    void allBranches_singleBulkQuery() {
        withCompany(() -> {
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                    .thenReturn(List.of(branch(BRANCH_A, "BR001", "Deak ter"), branch(BRANCH_B, "BR002", "Szeged")));
            when(snapshotRepository.findByBranchIdInAndSnapshotDateAndClosingType(anyList(), any(), any()))
                    .thenReturn(List.of(
                            snapshot(BRANCH_A, "EUR", "50", 10, "500"),
                            snapshot(BRANCH_B, "EUR", "50", 4, "200")));

            ReceivedDenominationsDto dto = service.load(DATE, null);

            verify(snapshotRepository, times(1)).findByBranchIdInAndSnapshotDateAndClosingType(
                    List.of(BRANCH_A, BRANCH_B), DATE, 1);
            verifyNoMoreInteractions(snapshotRepository);
            assertThat(dto.getBranches()).extracting("id").containsExactly(BRANCH_A, BRANCH_B);
            assertThat(dto.getRows()).hasSize(1);
            assertThat(dto.getRows().get(0).getCurrencyCode()).isEqualTo("EUR");
            assertThat(dto.getRows().get(0).getCells().get(0).getQuantity()).isEqualTo(14L);
            assertThat(dto.getRows().get(0).getTotalValue()).isEqualByComparingTo("700");
        });
    }

    @Test
    @DisplayName("FR-1: matrix — valutankent egy sor, cimlet-cellak nagytol kicsiig, HUF elol")
    void matrixShape() {
        withCompany(() -> {
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                    .thenReturn(List.of(branch(BRANCH_A, "BR001", "Deak ter")));
            when(snapshotRepository.findByBranchIdInAndSnapshotDateAndClosingType(anyList(), any(), any()))
                    .thenReturn(List.of(
                            snapshot(BRANCH_A, "EUR", "20", 3, "60"),
                            snapshot(BRANCH_A, "EUR", "100", 2, "200"),
                            snapshot(BRANCH_A, "USD", "10", 1, "10"),
                            snapshot(BRANCH_A, "HUF", "20000", 5, "100000")));

            ReceivedDenominationsDto dto = service.load(DATE, BRANCH_A);

            assertThat(dto.getRows()).extracting("currencyCode").containsExactly("HUF", "EUR", "USD");
            assertThat(dto.getRows().get(1).getCells()).extracting("faceValue")
                    .containsExactly(new BigDecimal("100"), new BigDecimal("20"));
            assertThat(dto.getHufTotalValue()).isEqualByComparingTo("100000");
            assertThat(dto.getCurrencyCount()).isEqualTo(3);
            assertThat(dto.getTotalQuantity()).isEqualTo(11L);
        });
    }

    @Test
    @DisplayName("FR-1: tort nevertek cellaja megjelolve, de a valasz tobbi resze ep marad")
    void fractionalFaceValueIsFlaggedNotDropped() {
        withCompany(() -> {
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                    .thenReturn(List.of(branch(BRANCH_A, "BR001", "Deak ter")));
            when(snapshotRepository.findByBranchIdInAndSnapshotDateAndClosingType(anyList(), any(), any()))
                    .thenReturn(List.of(
                            snapshot(BRANCH_A, "EUR", "0.50", 4, "2"),
                            snapshot(BRANCH_A, "EUR", "100", 2, "200")));

            ReceivedDenominationsDto dto = service.load(DATE, BRANCH_A);

            assertThat(dto.getRows()).hasSize(1);
            assertThat(dto.getRows().get(0).getCells()).hasSize(2);
            assertThat(dto.getRows().get(0).getCells())
                    .extracting("dataQualityFlag")
                    .containsExactly(
                            ReceivedDenominationsService.FLAG_OK,
                            ReceivedDenominationsService.FLAG_FRACTIONAL_FACE_VALUE);
            assertThat(dto.getRows().get(0).isHasDataQualityIssue()).isTrue();
            assertThat(dto.getDataQualityIssueCount()).isEqualTo(1);
        });
    }

    @Test
    @DisplayName("FR-1: total_value elteres a nevertek*darab szorzattol megjelolve")
    void valueMismatchIsFlagged() {
        withCompany(() -> {
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                    .thenReturn(List.of(branch(BRANCH_A, "BR001", "Deak ter")));
            when(snapshotRepository.findByBranchIdInAndSnapshotDateAndClosingType(anyList(), any(), any()))
                    .thenReturn(List.of(snapshot(BRANCH_A, "EUR", "100", 2, "199")));

            ReceivedDenominationsDto dto = service.load(DATE, BRANCH_A);

            assertThat(dto.getRows().get(0).getCells().get(0).getDataQualityFlag())
                    .isEqualTo(ReceivedDenominationsService.FLAG_VALUE_MISMATCH);
        });
    }

    @Test
    @DisplayName("FR-1: ket iroda egymast kiolto hibas sora NEM valik OK cellava az osszesitesben")
    void aggregationMustNotCancelOutRowLevelMismatches() {
        withCompany(() -> {
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                    .thenReturn(List.of(branch(BRANCH_A, "BR001", "Deak ter"), branch(BRANCH_B, "BR002", "Szeged")));
            // 100 x 2 = 200, but stored as 199 (bad); 100 x 1 = 100, but stored as 101 (bad).
            // Aggregated they look like 100 x 3 = 300, which would wrongly read as OK.
            when(snapshotRepository.findByBranchIdInAndSnapshotDateAndClosingType(anyList(), any(), any()))
                    .thenReturn(List.of(
                            snapshot(BRANCH_A, "EUR", "100", 2, "199"),
                            snapshot(BRANCH_B, "EUR", "100", 1, "101")));

            ReceivedDenominationsDto dto = service.load(DATE, null);

            assertThat(dto.getRows()).hasSize(1);
            assertThat(dto.getRows().get(0).getCells()).hasSize(1);
            assertThat(dto.getRows().get(0).getCells().get(0).getQuantity()).isEqualTo(3L);
            assertThat(dto.getRows().get(0).getCells().get(0).getTotalValue()).isEqualByComparingTo("300");
            assertThat(dto.getRows().get(0).getCells().get(0).getDataQualityFlag())
                    .isEqualTo(ReceivedDenominationsService.FLAG_VALUE_MISMATCH);
            assertThat(dto.getRows().get(0).isHasDataQualityIssue()).isTrue();
            assertThat(dto.getDataQualityIssueCount()).isEqualTo(1);
        });
    }

    @Test
    @DisplayName("FR-1: egyetlen hibas forrassor is megjeloli a cellat, ha a tobbi sor rendben van")
    void singleBadSourceRowFlagsTheMergedCell() {
        withCompany(() -> {
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                    .thenReturn(List.of(branch(BRANCH_A, "BR001", "Deak ter"), branch(BRANCH_B, "BR002", "Szeged")));
            when(snapshotRepository.findByBranchIdInAndSnapshotDateAndClosingType(anyList(), any(), any()))
                    .thenReturn(List.of(
                            snapshot(BRANCH_A, "EUR", "100", 2, "200"),
                            snapshot(BRANCH_B, "EUR", "100", 1, "90")));

            ReceivedDenominationsDto dto = service.load(DATE, null);

            assertThat(dto.getRows().get(0).getCells().get(0).getDataQualityFlag())
                    .isEqualTo(ReceivedDenominationsService.FLAG_VALUE_MISMATCH);
        });
    }

    @Test
    @DisplayName("FR-1b tenant-izolacio: idegen ceg branchId-jara ures valasz, snapshot-lekerdezes nelkul")
    void foreignBranchIdIsNotQueried() {
        withCompany(() -> {
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                    .thenReturn(List.of(branch(BRANCH_A, "BR001", "Deak ter")));

            ReceivedDenominationsDto dto = service.load(DATE, FOREIGN_BRANCH);

            verify(snapshotRepository, never())
                    .findByBranchIdInAndSnapshotDateAndClosingType(anyList(), any(), any());
            assertThat(dto.getRows()).isEmpty();
            assertThat(dto.getTotalQuantity()).isZero();
            assertThat(dto.getBranches()).extracting("id").containsExactly(BRANCH_A);
        });
    }

    @Test
    @DisplayName("FR-1: iroda nelkuli cegnel sincs felesleges bulk lekerdezes")
    void noBranchesMeansNoQuery() {
        withCompany(() -> {
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                    .thenReturn(List.of());

            ReceivedDenominationsDto dto = service.load(DATE, null);

            verify(snapshotRepository, never())
                    .findByBranchIdInAndSnapshotDateAndClosingType(anyList(), any(), any());
            assertThat(dto.getRows()).isEmpty();
        });
    }

    @Test
    @DisplayName("FR-1: hianyzo datum validacios hiba")
    void nullDateRejected() {
        withCompany(() -> assertThatThrownBy(() -> service.load(null, null))
                .isInstanceOf(ValidationException.class));
    }

    @Test
    @DisplayName("FK-112 FR-1: 14 fix oszlop, katalogus szerinti 0, hianyzonal null (–), Egyeb a tortrészre")
    void fixedColumnsUseCatalogAndCollectFractionalsInOther() {
        withCompany(() -> {
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                    .thenReturn(List.of(branch(BRANCH_A, "BR001", "Deak ter")));
            when(denominationAllowedRepository.findActiveByCompanyId(COMPANY_ID))
                    .thenReturn(List.of(allowed("EUR", "100"), allowed("EUR", "50")));
            when(snapshotRepository.findByBranchIdInAndSnapshotDateAndClosingType(anyList(), any(), any()))
                    .thenReturn(List.of(
                            snapshot(BRANCH_A, "EUR", "100", 2, "200"),
                            snapshot(BRANCH_A, "EUR", "0.50", 4, "2")));

            ReceivedDenominationsDto dto = service.load(DATE, BRANCH_A);

            ReceivedDenominationsDto.CurrencyRowDto eur = dto.getRows().get(0);
            assertThat(dto.getFixedFaceValues()).isEqualTo(ReceivedDenominationsDto.FIXED_FACE_VALUES);
            assertThat(eur.getFixedColumns()).hasSize(14);
            assertThat(column(eur, "100").getQuantity()).isEqualTo(2L);
            assertThat(column(eur, "100").isInCatalog()).isTrue();
            assertThat(column(eur, "50").getQuantity()).isZero();
            assertThat(column(eur, "50").isInCatalog()).isTrue();
            assertThat(column(eur, "20").getQuantity()).isNull();
            assertThat(column(eur, "20").isInCatalog()).isFalse();
            assertThat(eur.getOtherCells()).extracting("faceValue")
                    .containsExactly(new BigDecimal("0.50"));
        });
    }

    @Test
    @DisplayName("FK-112 TBD-3: inaktiv katalogus-nevertek a snapshotban megis darabszamot kap, nem –-t")
    void snapshotFaceValueSurvivesInactiveCatalog() {
        withCompany(() -> {
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                    .thenReturn(List.of(branch(BRANCH_A, "BR001", "Deak ter")));
            when(denominationAllowedRepository.findActiveByCompanyId(COMPANY_ID))
                    .thenReturn(List.of(allowed("EUR", "50")));
            when(snapshotRepository.findByBranchIdInAndSnapshotDateAndClosingType(anyList(), any(), any()))
                    .thenReturn(List.of(snapshot(BRANCH_A, "EUR", "100", 3, "300")));

            ReceivedDenominationsDto dto = service.load(DATE, BRANCH_A);

            assertThat(column(dto.getRows().get(0), "100").getQuantity()).isEqualTo(3L);
            assertThat(column(dto.getRows().get(0), "100").isInCatalog()).isFalse();
        });
    }

    @Test
    @DisplayName("FK-112 FR-2: MNB arfolyam atszamitja a nem-HUF sort, HUF sajat osszeg marad")
    void mnbRateConvertsForeignRowAndKeepsHufOwnTotal() {
        withCompany(() -> {
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                    .thenReturn(List.of(branch(BRANCH_A, "BR001", "Deak ter")));
            when(snapshotRepository.findByBranchIdInAndSnapshotDateAndClosingType(anyList(), any(), any()))
                    .thenReturn(List.of(
                            snapshot(BRANCH_A, "HUF", "20000", 5, "100000"),
                            snapshot(BRANCH_A, "EUR", "100", 2, "200")));
            when(mnbExchangeRateService.getRatesForDate(DATE))
                    .thenReturn(Map.of("EUR", mnbRate("EUR", DATE, "400.00")));

            ReceivedDenominationsDto dto = service.load(DATE, BRANCH_A);

            ReceivedDenominationsDto.CurrencyRowDto eur = dto.getRows().stream()
                    .filter(row -> "EUR".equals(row.getCurrencyCode()))
                    .findFirst()
                    .orElseThrow();
            assertThat(eur.getRate()).isEqualByComparingTo("400.00");
            assertThat(eur.getRateDate()).isEqualTo(DATE);
            assertThat(eur.getRateSource()).isEqualTo(ReceivedDenominationsDto.RATE_SOURCE_MNB);
            assertThat(eur.isRateMissing()).isFalse();
            assertThat(eur.getHufEquivalent()).isEqualByComparingTo("80000");
            assertThat(dto.getHufTotalValue()).isEqualByComparingTo("100000");
            assertThat(dto.getCurrencyValueHuf()).isEqualByComparingTo("80000");
            assertThat(dto.getGrandTotalHuf()).isEqualByComparingTo("180000");
        });
    }

    @Test
    @DisplayName("FK-112 FR-2: hetvege/unnep — 7 napos MNB walk-back")
    void mnbWalkBackUsesPreviousBusinessDay() {
        withCompany(() -> {
            LocalDate sunday = LocalDate.of(2026, 9, 13);
            LocalDate friday = LocalDate.of(2026, 9, 11);
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                    .thenReturn(List.of(branch(BRANCH_A, "BR001", "Deak ter")));
            when(snapshotRepository.findByBranchIdInAndSnapshotDateAndClosingType(anyList(), any(), any()))
                    .thenReturn(List.of(snapshot(BRANCH_A, "EUR", "100", 1, "100")));
            when(mnbExchangeRateService.getRatesForDate(sunday)).thenReturn(Map.of());
            when(mnbExchangeRateService.getRatesForDate(sunday.minusDays(1))).thenReturn(Map.of());
            when(mnbExchangeRateService.getRatesForDate(friday))
                    .thenReturn(Map.of("EUR", mnbRate("EUR", friday, "395.10")));

            ReceivedDenominationsDto dto = service.load(sunday, BRANCH_A);

            ReceivedDenominationsDto.CurrencyRowDto eur = dto.getRows().get(0);
            assertThat(eur.getRateDate()).isEqualTo(friday);
            assertThat(eur.getRateSource()).isEqualTo(ReceivedDenominationsDto.RATE_SOURCE_MNB);
            assertThat(eur.getHufEquivalent()).isEqualByComparingTo("39510");
        });
    }

    @Test
    @DisplayName("FK-112 FR-2: MNB altal nem jegyzett deviza a kezi elszamolasi history-t hasznalja")
    void unquotedCurrencyUsesManualSettlementRate() {
        withCompany(() -> {
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                    .thenReturn(List.of(branch(BRANCH_A, "BR001", "Deak ter")));
            when(snapshotRepository.findByBranchIdInAndSnapshotDateAndClosingType(anyList(), any(), any()))
                    .thenReturn(List.of(snapshot(BRANCH_A, "BAM", "100", 2, "200")));
            when(mnbExchangeRateService.isQuotedByMnb("BAM")).thenReturn(false);
            when(mnbSettlementRateService.findSettlementRateAsOf(COMPANY_ID, "BAM", DATE))
                    .thenReturn(Optional.of(new BigDecimal("210.50")));

            ReceivedDenominationsDto dto = service.load(DATE, BRANCH_A);

            ReceivedDenominationsDto.CurrencyRowDto bam = dto.getRows().get(0);
            assertThat(bam.getRateSource()).isEqualTo(ReceivedDenominationsDto.RATE_SOURCE_MANUAL);
            assertThat(bam.getRate()).isEqualByComparingTo("210.50");
            assertThat(bam.getHufEquivalent()).isEqualByComparingTo("42100");
            assertThat(bam.isRateMissing()).isFalse();
        });
    }

    @Test
    @DisplayName("FK-112 FR-2: hianyzo arfolyam a sort nincs adat-ra jeloli, a valaszt nem dobja el")
    void missingRateFlagsRowAndLeavesTheRest() {
        withCompany(() -> {
            when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(COMPANY_ID))
                    .thenReturn(List.of(branch(BRANCH_A, "BR001", "Deak ter")));
            when(snapshotRepository.findByBranchIdInAndSnapshotDateAndClosingType(anyList(), any(), any()))
                    .thenReturn(List.of(
                            snapshot(BRANCH_A, "HUF", "20000", 1, "20000"),
                            snapshot(BRANCH_A, "EUR", "100", 1, "100")));
            when(mnbExchangeRateService.getRatesForDate(any())).thenThrow(new RuntimeException("SOAP down"));

            ReceivedDenominationsDto dto = service.load(DATE, BRANCH_A);

            assertThat(dto.getRows()).hasSize(2);
            ReceivedDenominationsDto.CurrencyRowDto eur = dto.getRows().stream()
                    .filter(row -> "EUR".equals(row.getCurrencyCode()))
                    .findFirst()
                    .orElseThrow();
            assertThat(eur.isRateMissing()).isTrue();
            assertThat(eur.getHufEquivalent()).isNull();
            assertThat(dto.getHufTotalValue()).isEqualByComparingTo("20000");
            assertThat(dto.getCurrencyValueHuf()).isEqualByComparingTo("0");
            assertThat(dto.getGrandTotalHuf()).isEqualByComparingTo("20000");
        });
    }

    private static ReceivedDenominationsDto.FixedColumnDto column(
            ReceivedDenominationsDto.CurrencyRowDto row, String faceValue) {
        return row.getFixedColumns().stream()
                .filter(col -> col.getFaceValue().compareTo(new BigDecimal(faceValue)) == 0)
                .findFirst()
                .orElseThrow();
    }

    private static DenominationAllowed allowed(String currencyCode, String faceValue) {
        Currency currency = new Currency();
        currency.setCode(currencyCode);
        return DenominationAllowed.builder()
                .currency(currency)
                .faceValue(new BigDecimal(faceValue))
                .active(true)
                .build();
    }

    private static MnbExchangeRateCache mnbRate(String currency, LocalDate date, String officialRate) {
        return MnbExchangeRateCache.builder()
                .currencyCode(currency)
                .rateDate(date)
                .officialRate(new BigDecimal(officialRate))
                .unit(1)
                .source("MNB")
                .build();
    }
}
