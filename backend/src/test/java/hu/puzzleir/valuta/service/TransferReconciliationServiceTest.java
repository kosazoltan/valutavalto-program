package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.central.TransferReconciliationResultDto;
import hu.puzzleir.valuta.dto.central.TransferReconciliationRowDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.entity.TransferLine;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * FK-003 egyeztetési modul UNIT tesztjei (Mockito).
 */
@ExtendWith(MockitoExtension.class)
class TransferReconciliationServiceTest {

    @Mock private TransferRepository transferRepository;
    @Mock private NotificationService notificationService;

    private TransferReconciliationService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID VAULT_BRANCH_ID = UUID.randomUUID();
    private static final LocalDate D = LocalDate.of(2026, 5, 22);
    private static final ZoneId HU = TransferReconciliationService.BUSINESS_ZONE;

    @BeforeEach
    void setUp() {
        service = new TransferReconciliationService(
                transferRepository, notificationService, clockOn(D));
    }

    private static Clock clockOn(LocalDate day) {
        Instant instant = day.atTime(12, 0).atZone(HU).toInstant();
        return Clock.fixed(instant, HU);
    }

    private static String entityId(UUID companyId, String transferNumber, LocalDate day) {
        return companyId + ":" + transferNumber + ":" + day;
    }

    private static Currency currency(String code) {
        Currency c = new Currency();
        c.setCode(code);
        return c;
    }

    private static Branch branch(UUID id, String code, boolean isVault) {
        hu.puzzleir.valuta.entity.Company company = new hu.puzzleir.valuta.entity.Company();
        company.setId(COMPANY_ID);
        return Branch.builder().id(id).code(code).name(code + " név").isVault(isVault).company(company).build();
    }

    private static Transfer.TransferBuilder baseTransfer(String number, Transfer.TransferStatus status) {
        return Transfer.builder()
                .id(1L)
                .transferNumber(number)
                .fromBranch(branch(UUID.randomUUID(), "BR009", false))
                .toBranch(branch(VAULT_BRANCH_ID, "BR020", true))
                .currency(currency("EUR"))
                .transferDate(D)
                .status(status);
    }

    @Test
    @DisplayName("EGYEZIK — fogadott == küldött, fogadó megerősítette (COMPLETED), nincs értesítés")
    void testMatch() {
        Transfer t = baseTransfer("AT0001", Transfer.TransferStatus.COMPLETED)
                .amount(new BigDecimal("5000"))
                .receivedAmount(new BigDecimal("5000.0000"))
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getTotalRows()).isEqualTo(1);
            assertThat(result.getMatchedRows()).isEqualTo(1);
            assertThat(result.getDiscrepancyRows()).isZero();
            assertThat(result.getRows().get(0).getStatus()).isEqualTo(TransferReconciliationService.STATUS_MATCH);
            verifyNoInteractions(notificationService);
        }
    }

    @Test
    @DisplayName("ELTÉRÉS — eltérő összeg (COMPLETED, received != sent) → értéktár értesítve")
    void testAmountMismatch() {
        Transfer t = baseTransfer("AT0002", Transfer.TransferStatus.COMPLETED)
                .amount(new BigDecimal("5000"))
                .receivedAmount(new BigDecimal("4900"))
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));
            when(notificationService.notifyBranchOnce(eq(VAULT_BRANCH_ID), any(), any(), any(), any(),
                    eq(entityId(COMPANY_ID, "AT0002", D)), any()))
                    .thenReturn(true);

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getDiscrepancyRows()).isEqualTo(1);
            assertThat(result.getMatchedRows()).isZero();
            assertThat(result.getNotifiedBranches()).isEqualTo(1);
            TransferReconciliationRowDto row = result.getRows().get(0);
            assertThat(row.getStatus()).isEqualTo(TransferReconciliationService.STATUS_MISMATCH);
            assertThat(row.getDiscrepancyNote()).contains("Eltérő összeg");
            verify(notificationService).notifyBranchOnce(eq(VAULT_BRANCH_ID), any(), any(), any(),
                    eq("TransferReconciliation"), eq(entityId(COMPANY_ID, "AT0002", D)),
                    eq("TRANSFER_DISCREPANCY"));
        }
    }

    @Test
    @DisplayName("FK-090 FR-2: Feladó + PENDING → FOLYAMATBAN, nincs eltérés-számlálás, nincs értesítés")
    void testMissingReceiver() {
        Transfer t = baseTransfer("AT0003", Transfer.TransferStatus.PENDING)
                .direction(Transfer.TransferDirection.F)
                .amount(new BigDecimal("3000"))
                .receivedAmount(null)
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getDiscrepancyRows()).isZero();
            assertThat(result.getMatchedRows()).isZero();
            assertThat(result.getNotifiedBranches()).isZero();
            assertThat(result.getRows().get(0).getStatus())
                    .isEqualTo(TransferReconciliationService.STATUS_IN_PROGRESS);
            assertThat(result.getRows().get(0).getDiscrepancyNote()).contains("Fogadó megerősítésére vár");
            verifyNoInteractions(notificationService);
        }
    }

    @Test
    @DisplayName("FK-090 FR-2: Feladó + IN_TRANSIT → FOLYAMATBAN, nincs értesítés")
    void senderInTransitIsNeutral() {
        Transfer t = baseTransfer("AT0013", Transfer.TransferStatus.IN_TRANSIT)
                .direction(Transfer.TransferDirection.F)
                .amount(new BigDecimal("3000"))
                .receivedAmount(null)
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getRows().get(0).getStatus())
                    .isEqualTo(TransferReconciliationService.STATUS_IN_PROGRESS);
            assertThat(result.getDiscrepancyRows()).isZero();
            verifyNoInteractions(notificationService);
        }
    }

    @Test
    @DisplayName("FK-090 FR-3: Vevő (U) üres fogadott összeggel → EGYEZIK a rögzített összeggel")
    void buyerDirectionMatchesOnSentAmount() {
        Transfer t = baseTransfer("AT0010", Transfer.TransferStatus.COMPLETED)
                .direction(Transfer.TransferDirection.U)
                .amount(new BigDecimal("2500"))
                .receivedAmount(null)
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getMatchedRows()).isEqualTo(1);
            assertThat(result.getDiscrepancyRows()).isZero();
            TransferReconciliationRowDto row = result.getRows().get(0);
            assertThat(row.getStatus()).isEqualTo(TransferReconciliationService.STATUS_MATCH);
            assertThat(row.getSentAmount()).isEqualByComparingTo("2500");
            assertThat(row.getReceivedAmount()).isEqualByComparingTo("2500");
            verifyNoInteractions(notificationService);
        }
    }

    @Test
    @DisplayName("FK-090 FR-3: Korrekció (FF) üres fogadott összeggel → EGYEZIK")
    void correctionDirectionMatchesOnSentAmount() {
        Transfer t = baseTransfer("AT0011", Transfer.TransferStatus.COMPLETED)
                .direction(Transfer.TransferDirection.FF)
                .amount(new BigDecimal("800"))
                .receivedAmount(null)
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getMatchedRows()).isEqualTo(1);
            assertThat(result.getRows().get(0).getStatus())
                    .isEqualTo(TransferReconciliationService.STATUS_MATCH);
            verifyNoInteractions(notificationService);
        }
    }

    @Test
    @DisplayName("FK-090 FR-4: Teljes körforgás (UF) COMPLETED, egyező összeg → EGYEZIK (regresszió)")
    void fullCycleDirectionStillMatches() {
        Transfer t = baseTransfer("AT0012", Transfer.TransferStatus.COMPLETED)
                .direction(Transfer.TransferDirection.UF)
                .amount(new BigDecimal("5000"))
                .receivedAmount(new BigDecimal("5000"))
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getMatchedRows()).isEqualTo(1);
            assertThat(result.getRows().get(0).getStatus())
                    .isEqualTo(TransferReconciliationService.STATUS_MATCH);
            verifyNoInteractions(notificationService);
        }
    }

    @Test
    @DisplayName("FK-090 regresszió: Feladó + COMPLETED, valódi összeg-eltérés → ELTÉRÉS + értesítés")
    void senderCompletedAmountMismatchStillNotifies() {
        Transfer t = baseTransfer("AT0014", Transfer.TransferStatus.COMPLETED)
                .direction(Transfer.TransferDirection.F)
                .amount(new BigDecimal("5000"))
                .receivedAmount(new BigDecimal("4900"))
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));
            when(notificationService.notifyBranchOnce(any(), any(), any(), any(), any(), any(), any()))
                    .thenReturn(true);

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getDiscrepancyRows()).isEqualTo(1);
            assertThat(result.getRows().get(0).getStatus())
                    .isEqualTo(TransferReconciliationService.STATUS_MISMATCH);
            verify(notificationService).notifyBranchOnce(any(), any(), any(), any(), any(), any(), any());
        }
    }

    @Test
    @DisplayName("FK-090 edge: null direction → UF fallback, üres lines → fejléc-alapú egysoros")
    void nullDirectionFallsBackToUfHeaderRow() {
        Transfer t = baseTransfer("AT0015", Transfer.TransferStatus.COMPLETED)
                .direction(null)
                .amount(new BigDecimal("100"))
                .receivedAmount(new BigDecimal("100"))
                .lines(List.of())
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getTotalRows()).isEqualTo(1);
            assertThat(result.getMatchedRows()).isEqualTo(1);
            assertThat(result.getRows().get(0).getStatus())
                    .isEqualTo(TransferReconciliationService.STATUS_MATCH);
        }
    }

    /**
     * FK-090 FR-1 (dokumentált spec-döntés): a RECEIVED státusz soha nem íródik a
     * TransferService-ből, ezért a fixture COMPLETED-re frissül — ez a ténylegesen
     * lezárt állapot, nem teszt-kozmetika.
     */
    @Test
    @DisplayName("Több-valutás átadólap — soronkénti egyeztetés (egy egyezik, egy eltér), 1 értesítés")
    void testMultiCurrencyLines() {
        Transfer t = baseTransfer("AT0004", Transfer.TransferStatus.COMPLETED)
                .direction(Transfer.TransferDirection.F)
                .build();
        TransferLine ok = TransferLine.builder().currency(currency("USD"))
                .amount(new BigDecimal("1000")).receivedAmount(new BigDecimal("1000")).build();
        TransferLine bad = TransferLine.builder().currency(currency("GBP"))
                .amount(new BigDecimal("2000")).receivedAmount(new BigDecimal("1950")).build();
        t.setLines(List.of(ok, bad));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));
            when(notificationService.notifyBranchOnce(any(), any(), any(), any(), any(), any(), any()))
                    .thenReturn(true);

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getTotalRows()).isEqualTo(2);
            assertThat(result.getMatchedRows()).isEqualTo(1);
            assertThat(result.getDiscrepancyRows()).isEqualTo(1);
            assertThat(result.getNotifiedBranches()).isEqualTo(1);
            verify(notificationService, times(1)).notifyBranchOnce(any(), any(), any(), any(), any(), any(), any());
        }
    }

    @Test
    @DisplayName("Multi-tenant — cégek közötti átadásnál az értesítés a SAJÁT céges irodát kapja, nem a másik bérlő értéktárát")
    void testCrossCompanyNotificationStaysOwnTenant() {
        UUID otherCompany = UUID.randomUUID();
        UUID ownFromId = UUID.randomUUID();
        UUID foreignVaultId = UUID.randomUUID();

        hu.puzzleir.valuta.entity.Company own = new hu.puzzleir.valuta.entity.Company();
        own.setId(COMPANY_ID);
        hu.puzzleir.valuta.entity.Company foreign = new hu.puzzleir.valuta.entity.Company();
        foreign.setId(otherCompany);

        Branch ownFrom = Branch.builder().id(ownFromId).code("BR009").name("Saját").isVault(false).company(own).build();
        Branch foreignVault = Branch.builder().id(foreignVaultId).code("BRX").name("Idegen értéktár").isVault(true).company(foreign).build();

        Transfer t = Transfer.builder().id(9L).transferNumber("AT0009")
                .fromBranch(ownFrom).toBranch(foreignVault).currency(currency("EUR"))
                .transferDate(D).status(Transfer.TransferStatus.COMPLETED)
                .amount(new BigDecimal("5000")).receivedAmount(new BigDecimal("4000")).build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));
            when(notificationService.notifyBranchOnce(eq(ownFromId), any(), any(), any(), any(), any(), any()))
                    .thenReturn(true);

            TransferReconciliationResultDto result = service.reconcile(D, D);

            assertThat(result.getDiscrepancyRows()).isEqualTo(1);
            // a SAJÁT cég irodáját értesítjük (foreign vault NEM kaphat értesítést)
            verify(notificationService).notifyBranchOnce(eq(ownFromId), any(), any(), any(), any(), any(), any());
            verify(notificationService, never()).notifyBranchOnce(eq(foreignVaultId), any(), any(), any(), any(), any(), any());
        }
    }

    @Test
    @DisplayName("FK-092 FR-3: ugyanazon a napon kétszer futtatott egyeztetés azonos entityId-t ad")
    void sameDaySecondRunReusesCompositeEntityId() {
        Transfer t = baseTransfer("AT0002", Transfer.TransferStatus.COMPLETED)
                .amount(new BigDecimal("5000"))
                .receivedAmount(new BigDecimal("4900"))
                .build();
        String expectedId = entityId(COMPANY_ID, "AT0002", D);
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));
            when(notificationService.notifyBranchOnce(any(), any(), any(), any(), any(), any(), any()))
                    .thenReturn(true, false);

            TransferReconciliationResultDto first = service.reconcile(D, D);
            TransferReconciliationResultDto second = service.reconcile(D, D);

            assertThat(first.getNotifiedBranches()).isEqualTo(1);
            assertThat(second.getNotifiedBranches()).isZero();
            ArgumentCaptor<String> entityIds = ArgumentCaptor.forClass(String.class);
            verify(notificationService, times(2)).notifyBranchOnce(
                    eq(VAULT_BRANCH_ID), any(), any(), any(),
                    eq("TransferReconciliation"), entityIds.capture(), eq("TRANSFER_DISCREPANCY"));
            assertThat(entityIds.getAllValues()).containsExactly(expectedId, expectedId);
        }
    }

    @Test
    @DisplayName("FK-092 FR-4: két egymást követő napon külön entityId / külön riasztás")
    void nextDayGetsNewEntityId() {
        Transfer t = baseTransfer("AT0002", Transfer.TransferStatus.COMPLETED)
                .amount(new BigDecimal("5000"))
                .receivedAmount(new BigDecimal("4900"))
                .build();
        LocalDate next = D.plusDays(1);
        TransferReconciliationService nextDayService = new TransferReconciliationService(
                transferRepository, notificationService, clockOn(next));
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(eq(COMPANY_ID), any(), any())).thenReturn(List.of(t));
            when(notificationService.notifyBranchOnce(any(), any(), any(), any(), any(), any(), any()))
                    .thenReturn(true);

            service.reconcile(D, D);
            nextDayService.reconcile(next, next);

            ArgumentCaptor<String> entityIds = ArgumentCaptor.forClass(String.class);
            verify(notificationService, times(2)).notifyBranchOnce(
                    eq(VAULT_BRANCH_ID), any(), any(), any(),
                    eq("TransferReconciliation"), entityIds.capture(), eq("TRANSFER_DISCREPANCY"));
            assertThat(entityIds.getAllValues()).containsExactly(
                    entityId(COMPANY_ID, "AT0002", D),
                    entityId(COMPANY_ID, "AT0002", next));
        }
    }

    @Test
    @DisplayName("FK-092 FR-5: két cég azonos átadólap-számmal nem némítja el egymást")
    void twoCompaniesSameTransferNumberDoNotMuteEachOther() {
        UUID companyB = UUID.randomUUID();
        UUID vaultBId = UUID.randomUUID();
        hu.puzzleir.valuta.entity.Company coB = new hu.puzzleir.valuta.entity.Company();
        coB.setId(companyB);
        Branch fromB = Branch.builder().id(UUID.randomUUID()).code("BRB1").name("B pénztár")
                .isVault(false).company(coB).build();
        Branch vaultB = Branch.builder().id(vaultBId).code("BRB0").name("B értéktár")
                .isVault(true).company(coB).build();
        Transfer tA = baseTransfer("TR-001", Transfer.TransferStatus.COMPLETED)
                .amount(new BigDecimal("100"))
                .receivedAmount(new BigDecimal("90"))
                .build();
        Transfer tB = Transfer.builder().id(2L).transferNumber("TR-001")
                .fromBranch(fromB).toBranch(vaultB).currency(currency("EUR"))
                .transferDate(D).status(Transfer.TransferStatus.COMPLETED)
                .amount(new BigDecimal("100")).receivedAmount(new BigDecimal("90")).build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID, companyB);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(tA));
            when(transferRepository.findForReconciliation(companyB, D, D)).thenReturn(List.of(tB));
            when(notificationService.notifyBranchOnce(any(), any(), any(), any(), any(), any(), any()))
                    .thenReturn(true);

            service.reconcile(D, D);
            service.reconcile(D, D);

            ArgumentCaptor<String> entityIds = ArgumentCaptor.forClass(String.class);
            verify(notificationService, times(2)).notifyBranchOnce(
                    any(), any(), any(), any(),
                    eq("TransferReconciliation"), entityIds.capture(), eq("TRANSFER_DISCREPANCY"));
            assertThat(entityIds.getAllValues()).containsExactly(
                    entityId(COMPANY_ID, "TR-001", D),
                    entityId(companyB, "TR-001", D));
        }
    }

    @Test
    @DisplayName("FK-092 FR-2: az idempotencia-dátum Europe/Budapest, nem a JVM/UTC nap")
    void entityIdUsesBudapestDateAcrossUtcMidnight() {
        // 2026-05-22 22:30 UTC = 2026-05-23 00:30 Europe/Budapest
        Clock utcStillMay22 = Clock.fixed(Instant.parse("2026-05-22T22:30:00Z"), HU);
        TransferReconciliationService midnightService = new TransferReconciliationService(
                transferRepository, notificationService, utcStillMay22);
        Transfer t = baseTransfer("AT0002", Transfer.TransferStatus.COMPLETED)
                .amount(new BigDecimal("5000"))
                .receivedAmount(new BigDecimal("4900"))
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(transferRepository.findForReconciliation(COMPANY_ID, D, D)).thenReturn(List.of(t));
            when(notificationService.notifyBranchOnce(any(), any(), any(), any(), any(), any(), any()))
                    .thenReturn(true);

            midnightService.reconcile(D, D);

            verify(notificationService).notifyBranchOnce(any(), any(), any(), any(), any(),
                    eq(entityId(COMPANY_ID, "AT0002", LocalDate.of(2026, 5, 23))), any());
        }
    }

    @Test
    @DisplayName("Validáció — hiányzó dátum / fordított intervallum → ValidationException")
    void testValidation() {
        assertThatThrownBy(() -> service.reconcile(null, D)).isInstanceOf(ValidationException.class);
        assertThatThrownBy(() -> service.reconcile(D, D.minusDays(1))).isInstanceOf(ValidationException.class);
        verifyNoInteractions(transferRepository);
    }
}
