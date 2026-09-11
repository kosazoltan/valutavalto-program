package hu.puzzleir.valuta.service.central;

import hu.puzzleir.valuta.dto.central.ReceivedDenominationsDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DailyDenominationSnapshot;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DailyDenominationSnapshotRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
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
    private final ReceivedDenominationsService service =
            new ReceivedDenominationsService(branchRepository, snapshotRepository);

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
}
