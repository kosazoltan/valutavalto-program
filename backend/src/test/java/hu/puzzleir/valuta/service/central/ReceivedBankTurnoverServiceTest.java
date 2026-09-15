package hu.puzzleir.valuta.service.central;

import hu.puzzleir.valuta.dto.central.ReceivedBankTurnoverDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ClosingControlRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AmlEddService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-114 FR-1/FR-2/FR-3: period bank turnover over vault daily_balance rows.
 */
class ReceivedBankTurnoverServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("10000000-0000-0000-0000-000000000001");
    private static final UUID VAULT_A = UUID.fromString("20000000-0000-0000-0000-00000000000a");
    private static final UUID VAULT_B = UUID.fromString("20000000-0000-0000-0000-00000000000b");
    private static final UUID CASHIER = UUID.fromString("20000000-0000-0000-0000-00000000000c");
    private static final UUID FOREIGN = UUID.fromString("30000000-0000-0000-0000-00000000000f");
    private static final LocalDate FROM = LocalDate.of(2026, 9, 10);
    private static final LocalDate TO = LocalDate.of(2026, 9, 12);
    /** Frozen "today" so TO (Sep 12) is a closed day. */
    private static final Clock CLOCK = Clock.fixed(
            Instant.parse("2026-09-15T10:00:00Z"), AmlEddService.BUSINESS_ZONE);

    private final DailyBalanceRepository dailyBalanceRepository = mock(DailyBalanceRepository.class);
    private final ClosingControlRepository closingControlRepository = mock(ClosingControlRepository.class);
    private final BranchRepository branchRepository = mock(BranchRepository.class);
    private final ReceivedBankTurnoverService service = new ReceivedBankTurnoverService(
            dailyBalanceRepository, closingControlRepository, branchRepository, CLOCK);

    @Test
    @DisplayName("FR-1: sums vault bank_in/bank_out per currency; cashier rows are not queried")
    void sumsOnlyVaultBranches() {
        Branch vault = vault(VAULT_A, "ET1", 2, "Szeged");
        Branch cashier = cashier(CASHIER, "BR001", 2, "Szeged");
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(vault, cashier));
        when(dailyBalanceRepository.sumBankInOutByCurrency(eq(COMPANY_ID), anyList(), eq(FROM), eq(TO)))
                .thenReturn(List.<Object[]>of(new Object[]{"EUR", new BigDecimal("1000"), new BigDecimal("250")}));
        when(closingControlRepository.findEveningClosedBranchDates(eq(COMPANY_ID), anyList(), eq(FROM), eq(TO)))
                .thenReturn(List.<Object[]>of(
                        new Object[]{VAULT_A, FROM},
                        new Object[]{VAULT_A, FROM.plusDays(1)},
                        new Object[]{VAULT_A, TO}));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            ReceivedBankTurnoverDto dto = service.load(FROM, TO, null, null);

            assertThat(dto.getRows()).hasSize(1);
            assertThat(dto.getRows().get(0).getCurrencyCode()).isEqualTo("EUR");
            assertThat(dto.getRows().get(0).getBankIn()).isEqualByComparingTo("1000");
            assertThat(dto.getRows().get(0).getBankOut()).isEqualByComparingTo("250");
            assertThat(dto.getMissingClosingDays()).isEmpty();
            verify(dailyBalanceRepository).sumBankInOutByCurrency(
                    eq(COMPANY_ID), eq(List.of(VAULT_A)), eq(FROM), eq(TO));
        }
    }

    @Test
    @DisplayName("FR-2: missing evening closings listed per vault day; empty = fully covered")
    void missingEveningClosingDays() {
        Branch vault = vault(VAULT_A, "ET1", 2, "Szeged");
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(vault));
        when(dailyBalanceRepository.sumBankInOutByCurrency(eq(COMPANY_ID), anyList(), eq(FROM), eq(TO)))
                .thenReturn(List.of());
        when(closingControlRepository.findEveningClosedBranchDates(eq(COMPANY_ID), anyList(), eq(FROM), eq(TO)))
                .thenReturn(List.<Object[]>of(new Object[]{VAULT_A, FROM}));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            ReceivedBankTurnoverDto dto = service.load(FROM, TO, null, null);

            assertThat(dto.getMissingClosingDays()).extracting(ReceivedBankTurnoverDto.MissingClosingDayDto::getDate)
                    .containsExactly(FROM.plusDays(1), TO);
            assertThat(dto.getMissingClosingDays()).allMatch(d -> VAULT_A.equals(d.getBranchId()));
            assertThat(dto.getMissingClosingDays()).allMatch(d -> "ET1".equals(d.getBranchCode()));
        }
    }

    @Test
    @DisplayName("FR-3: vault_territory_id filters the branch set the same way as the daily grid")
    void territoryScope() {
        Branch vaultIn = vault(VAULT_A, "ET1", 2, "Szeged");
        Branch vaultOut = vault(VAULT_B, "ET2", 3, "Pécs");
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(vaultIn, vaultOut));
        when(dailyBalanceRepository.sumBankInOutByCurrency(eq(COMPANY_ID), anyList(), eq(FROM), eq(TO)))
                .thenReturn(List.of());
        when(closingControlRepository.findEveningClosedBranchDates(eq(COMPANY_ID), anyList(), eq(FROM), eq(TO)))
                .thenReturn(List.<Object[]>of(new Object[]{VAULT_A, FROM}, new Object[]{VAULT_A, FROM.plusDays(1)},
                        new Object[]{VAULT_A, TO}));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            service.load(FROM, TO, null, 2);
            verify(dailyBalanceRepository).sumBankInOutByCurrency(
                    eq(COMPANY_ID), eq(List.of(VAULT_A)), eq(FROM), eq(TO));
            verify(dailyBalanceRepository, never()).sumBankInOutByCurrency(
                    eq(COMPANY_ID), eq(List.of(VAULT_A, VAULT_B)), eq(FROM), eq(TO));
        }
    }

    @Test
    @DisplayName("FR-3: foreign branchId is 404, not another tenant's data")
    void foreignBranch404() {
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of());
        when(branchRepository.findByIdAndCompanyId(FOREIGN, COMPANY_ID)).thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            assertThatThrownBy(() -> service.load(FROM, TO, FOREIGN, null))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(dailyBalanceRepository, never()).sumBankInOutByCurrency(any(), anyList(), any(), any());
        }
    }

    @Test
    @DisplayName("FR-1: toDate must be before today; range at most 92 inclusive days")
    void dateGuards() {
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            assertThatThrownBy(() -> service.load(FROM, LocalDate.of(2026, 9, 15), null, null))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("lezárt");
            assertThatThrownBy(() -> service.load(LocalDate.of(2026, 1, 1), LocalDate.of(2026, 4, 3), null, null))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("92");
            assertThatThrownBy(() -> service.load(TO, FROM, null, null))
                    .isInstanceOf(ValidationException.class);
        }
        verify(dailyBalanceRepository, never()).sumBankInOutByCurrency(any(), anyList(), any(), any());
    }

    @Test
    @DisplayName("FR-1: 92-day inclusive range is accepted")
    void maxRangeAccepted() {
        LocalDate from = LocalDate.of(2026, 6, 15);
        LocalDate to = from.plusDays(91);
        Branch vault = vault(VAULT_A, "ET1", 2, "Szeged");
        when(branchRepository.findByCompanyId(COMPANY_ID)).thenReturn(List.of(vault));
        when(dailyBalanceRepository.sumBankInOutByCurrency(eq(COMPANY_ID), anyList(), eq(from), eq(to)))
                .thenReturn(List.of());
        when(closingControlRepository.findEveningClosedBranchDates(eq(COMPANY_ID), anyList(), eq(from), eq(to)))
                .thenReturn(List.of());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            ReceivedBankTurnoverDto dto = service.load(from, to, null, null);
            assertThat(dto.getRows()).isEmpty();
        }
    }

    private static Branch vault(UUID id, String code, int territory, String region) {
        return branch(id, code, true, territory, region);
    }

    private static Branch cashier(UUID id, String code, int territory, String region) {
        return branch(id, code, false, territory, region);
    }

    private static Branch branch(UUID id, String code, boolean vault, int territory, String region) {
        Branch branch = new Branch();
        branch.setId(id);
        branch.setCode(code);
        branch.setName(code);
        branch.setIsVault(vault);
        branch.setVaultTerritoryId(territory);
        branch.setRegion(region);
        return branch;
    }
}
