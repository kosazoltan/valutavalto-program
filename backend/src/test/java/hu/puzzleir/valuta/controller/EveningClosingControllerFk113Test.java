package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.ClosingMarkType;
import hu.puzzleir.valuta.dto.eveningclosing.DailyDataPackage;
import hu.puzzleir.valuta.dto.eveningclosing.DataSyncResult;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.ClosingControlService;
import hu.puzzleir.valuta.service.ClosingWizardService;
import hu.puzzleir.valuta.service.DailyBalanceService;
import hu.puzzleir.valuta.service.EveningClosingService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-113 FR-4: evening send is the vault's real closing path, so bank_in/bank_out
 * must be recorded there — not only on DailyClosingService.startDailyClosing.
 */
@ExtendWith(MockitoExtension.class)
class EveningClosingControllerFk113Test {

    @Mock private EveningClosingService eveningClosingService;
    @Mock private ClosingControlService closingControlService;
    @Mock private ClosingWizardService closingWizardService;
    @Mock private DailyBalanceService dailyBalanceService;
    @InjectMocks private EveningClosingController controller;

    private static final UUID BRANCH_ID = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
    private static final UUID COMPANY_ID = UUID.fromString("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
    private static final LocalDate DATE = LocalDate.of(2026, 9, 14);

    @Test
    @DisplayName("FK-113 FR-4: sikeres HQ-kuldes utan recordVaultBankAdjustments lefut")
    void sendPackageSuccessRecordsVaultBankAdjustments() {
        DailyDataPackage pkg = DailyDataPackage.builder().checksum("chk").build();
        when(eveningClosingService.prepareDailyPackage(BRANCH_ID, DATE)).thenReturn(pkg);
        when(eveningClosingService.sendToHeadquarters(pkg)).thenReturn(DataSyncResult.success("chk"));

        try (MockedStatic<SecurityUtils> security = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            ResponseEntity<DataSyncResult> response = controller.sendPackage(BRANCH_ID, DATE);

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
            verify(closingControlService).markClosingDone(COMPANY_ID, BRANCH_ID, DATE, ClosingMarkType.EVENING);
            verify(dailyBalanceService).recordVaultBankAdjustments(BRANCH_ID, DATE);
        }
    }

    @Test
    @DisplayName("FK-113 FR-4: sikertelen HQ-kuldes nem ir banki adatot")
    void sendPackageFailureDoesNotRecordBankAdjustments() {
        DailyDataPackage pkg = DailyDataPackage.builder().checksum("chk").build();
        when(eveningClosingService.prepareDailyPackage(BRANCH_ID, DATE)).thenReturn(pkg);
        when(eveningClosingService.sendToHeadquarters(pkg))
                .thenReturn(DataSyncResult.failure("HQ down", 3));

        ResponseEntity<DataSyncResult> response = controller.sendPackage(BRANCH_ID, DATE);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.INTERNAL_SERVER_ERROR);
        verify(closingControlService, never()).markClosingDone(any(), any(), any(), any());
        verify(dailyBalanceService, never()).recordVaultBankAdjustments(any(), any());
    }

    @Test
    @DisplayName("FK-113 FR-4: banki igazitas hibaja nem buktatja a mar sikeres kuldest")
    void bankAdjustmentFailureStillReturnsOkAfterSuccessfulSend() {
        DailyDataPackage pkg = DailyDataPackage.builder().checksum("chk").build();
        when(eveningClosingService.prepareDailyPackage(BRANCH_ID, DATE)).thenReturn(pkg);
        when(eveningClosingService.sendToHeadquarters(pkg)).thenReturn(DataSyncResult.success("chk"));
        doThrow(new RuntimeException("bank adj failed"))
                .when(dailyBalanceService).recordVaultBankAdjustments(BRANCH_ID, DATE);

        try (MockedStatic<SecurityUtils> security = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            ResponseEntity<DataSyncResult> response = controller.sendPackage(BRANCH_ID, DATE);

            assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
            verify(closingControlService).markClosingDone(COMPANY_ID, BRANCH_ID, DATE, ClosingMarkType.EVENING);
        }
    }
}
