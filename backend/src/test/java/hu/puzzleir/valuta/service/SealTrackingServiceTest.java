package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.SealTracking;
import hu.puzzleir.valuta.entity.SealTransitStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.SealTrackingRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class SealTrackingServiceTest {

    @InjectMocks
    private SealTrackingService sealTrackingService;

    @Mock
    private SealTrackingRepository sealTrackingRepository;

    @Mock
    private AuditLogService auditLogService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 42L;
    private static final String TRANSFER_TYPE = "VAULT";
    private static final Long TRANSFER_ID = 100L;
    private static final String SEAL_NUMBER = "BC01-20260316-001";

    @BeforeEach
    void setUp() {
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(WORKER_ID, COMPANY_ID, BRANCH_ID, "SUPERVISOR");
        TestingAuthenticationToken auth =
                new TestingAuthenticationToken("testworker", "pass", "ROLE_SUPERVISOR");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // ─── 1. seal: SEALED rekord létrehozása ───

    @Test
    @DisplayName("seal: SEALED rekord jön létre helyes companyId-val és workerId-vel")
    void seal_createsSealedRecordWithCorrectCompanyAndWorker() {
        when(sealTrackingRepository.existsBySealNumber(SEAL_NUMBER)).thenReturn(false);
        when(sealTrackingRepository.save(any(SealTracking.class)))
                .thenAnswer(inv -> {
                    SealTracking st = inv.getArgument(0);
                    st.setId(1L);
                    return st;
                });

        SealTracking result = sealTrackingService.seal(TRANSFER_TYPE, TRANSFER_ID, SEAL_NUMBER);

        assertThat(result.getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(result.getSealedBy()).isEqualTo(WORKER_ID);
        assertThat(result.getTransitStatus()).isEqualTo(SealTransitStatus.SEALED);
        assertThat(result.getSealNumber()).isEqualTo(SEAL_NUMBER);
        assertThat(result.getTransferType()).isEqualTo(TRANSFER_TYPE);
        assertThat(result.getTransferId()).isEqualTo(TRANSFER_ID);
        assertThat(result.getSealedAt()).isNotNull();

        verify(sealTrackingRepository).save(any(SealTracking.class));
        verify(auditLogService).log(eq("SEAL_CREATED"), anyString(), any(Long.class));
    }

    // ─── 2. seal: duplikált plomba szám → ValidationException ───

    @Test
    @DisplayName("seal: duplikált plomba szám ValidationException-t dob")
    void seal_duplicateSealNumber_throwsValidationException() {
        when(sealTrackingRepository.existsBySealNumber(SEAL_NUMBER)).thenReturn(true);

        assertThatThrownBy(() -> sealTrackingService.seal(TRANSFER_TYPE, TRANSFER_ID, SEAL_NUMBER))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("már foglalt");

        verify(sealTrackingRepository, never()).save(any());
    }

    // ─── 3. startTransit: SEALED → IN_TRANSIT ───

    @Test
    @DisplayName("startTransit: SEALED állapotból IN_TRANSIT-ba vált")
    void startTransit_fromSealed_changesStatusToInTransit() {
        SealTracking existing = buildTracking(SealTransitStatus.SEALED);
        when(sealTrackingRepository.findByTransferTypeAndTransferId(TRANSFER_TYPE, TRANSFER_ID))
                .thenReturn(Optional.of(existing));
        when(sealTrackingRepository.save(any(SealTracking.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        SealTracking result = sealTrackingService.startTransit(TRANSFER_TYPE, TRANSFER_ID);

        assertThat(result.getTransitStatus()).isEqualTo(SealTransitStatus.IN_TRANSIT);
        verify(auditLogService).log(eq("SEAL_IN_TRANSIT"), anyString(), any(Long.class));
    }

    // ─── 4. confirmArrival: IN_TRANSIT → ARRIVED ───

    @Test
    @DisplayName("confirmArrival: IN_TRANSIT állapotból ARRIVED-ba vált")
    void confirmArrival_fromInTransit_changesStatusToArrived() {
        SealTracking existing = buildTracking(SealTransitStatus.IN_TRANSIT);
        when(sealTrackingRepository.findByTransferTypeAndTransferId(TRANSFER_TYPE, TRANSFER_ID))
                .thenReturn(Optional.of(existing));
        when(sealTrackingRepository.save(any(SealTracking.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        SealTracking result = sealTrackingService.confirmArrival(TRANSFER_TYPE, TRANSFER_ID);

        assertThat(result.getTransitStatus()).isEqualTo(SealTransitStatus.ARRIVED);
        verify(auditLogService).log(eq("SEAL_ARRIVED"), anyString(), any(Long.class));
    }

    // ─── 5. openSeal: ARRIVED → OPENED, rögzíti a megnyitót ───

    @Test
    @DisplayName("openSeal: ARRIVED állapotból OPENED-be vált és rögzíti a megnyitó workert")
    void openSeal_fromArrived_changesStatusToOpenedAndRecordsOpener() {
        SealTracking existing = buildTracking(SealTransitStatus.ARRIVED);
        when(sealTrackingRepository.findByTransferTypeAndTransferId(TRANSFER_TYPE, TRANSFER_ID))
                .thenReturn(Optional.of(existing));
        when(sealTrackingRepository.save(any(SealTracking.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        SealTracking result = sealTrackingService.openSeal(TRANSFER_TYPE, TRANSFER_ID);

        assertThat(result.getTransitStatus()).isEqualTo(SealTransitStatus.OPENED);
        assertThat(result.getOpenedBy()).isEqualTo(WORKER_ID);
        assertThat(result.getOpenedAt()).isNotNull();
        verify(auditLogService).log(eq("SEAL_OPENED"), anyString(), any(Long.class));
    }

    // ─── 6. startTransit helytelen státuszból → ValidationException ───

    @Test
    @DisplayName("startTransit: nem SEALED státuszból indítva ValidationException-t dob")
    void startTransit_fromWrongStatus_throwsValidationException() {
        SealTracking existing = buildTracking(SealTransitStatus.IN_TRANSIT);
        when(sealTrackingRepository.findByTransferTypeAndTransferId(TRANSFER_TYPE, TRANSFER_ID))
                .thenReturn(Optional.of(existing));

        assertThatThrownBy(() -> sealTrackingService.startTransit(TRANSFER_TYPE, TRANSFER_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("SEALED");

        verify(sealTrackingRepository, never()).save(any());
    }

    // ─── 7. validateSealIntegrity ───

    @Test
    @DisplayName("validateSealIntegrity: egyező szám true-t ad vissza")
    void validateSealIntegrity_matchingNumber_returnsTrue() {
        SealTracking existing = buildTracking(SealTransitStatus.SEALED);
        when(sealTrackingRepository.findByTransferTypeAndTransferId(TRANSFER_TYPE, TRANSFER_ID))
                .thenReturn(Optional.of(existing));

        boolean result = sealTrackingService.validateSealIntegrity(TRANSFER_TYPE, TRANSFER_ID, SEAL_NUMBER);

        assertThat(result).isTrue();
    }

    @Test
    @DisplayName("validateSealIntegrity: eltérő szám false-t ad vissza")
    void validateSealIntegrity_mismatchedNumber_returnsFalse() {
        SealTracking existing = buildTracking(SealTransitStatus.SEALED);
        when(sealTrackingRepository.findByTransferTypeAndTransferId(TRANSFER_TYPE, TRANSFER_ID))
                .thenReturn(Optional.of(existing));

        boolean result = sealTrackingService.validateSealIntegrity(TRANSFER_TYPE, TRANSFER_ID, "WRONG-NUMBER");

        assertThat(result).isFalse();
    }

    // ─── 8. getActiveTransits: SEALED + IN_TRANSIT rekordok ───

    @Test
    @DisplayName("getActiveTransits: SEALED és IN_TRANSIT rekordokat ad vissza az aktuális céghez")
    void getActiveTransits_returnsSealedAndInTransitRecords() {
        SealTracking sealed = buildTracking(SealTransitStatus.SEALED);
        SealTracking inTransit = buildTracking(SealTransitStatus.IN_TRANSIT);
        inTransit.setId(2L);

        when(sealTrackingRepository.findByCompanyIdAndTransitStatusIn(
                eq(COMPANY_ID),
                eq(List.of(SealTransitStatus.SEALED, SealTransitStatus.IN_TRANSIT))))
                .thenReturn(List.of(sealed, inTransit));

        List<SealTracking> result = sealTrackingService.getActiveTransits();

        assertThat(result).hasSize(2);
        assertThat(result).extracting(SealTracking::getTransitStatus)
                .containsExactlyInAnyOrder(SealTransitStatus.SEALED, SealTransitStatus.IN_TRANSIT);
    }

    // ─── 9. getBySealNumber: más cég rekordja nem látható ───

    @Test
    @DisplayName("getBySealNumber: más cég plombája üres Optional-t ad vissza")
    void getBySealNumber_otherCompany_returnsEmpty() {
        UUID otherCompanyId = UUID.randomUUID();
        SealTracking otherTracking = buildTrackingForCompany(SealTransitStatus.SEALED, otherCompanyId);
        when(sealTrackingRepository.findBySealNumber(SEAL_NUMBER))
                .thenReturn(Optional.of(otherTracking));

        Optional<SealTracking> result = sealTrackingService.getBySealNumber(SEAL_NUMBER);

        assertThat(result).isEmpty();
    }

    // ─── 10. getByTransfer: más cég rekordja nem látható ───

    @Test
    @DisplayName("getByTransfer: más cég transfer rekordja üres Optional-t ad vissza")
    void getByTransfer_otherCompany_returnsEmpty() {
        UUID otherCompanyId = UUID.randomUUID();
        SealTracking otherTracking = buildTrackingForCompany(SealTransitStatus.SEALED, otherCompanyId);
        when(sealTrackingRepository.findByTransferTypeAndTransferId(TRANSFER_TYPE, TRANSFER_ID))
                .thenReturn(Optional.of(otherTracking));

        Optional<SealTracking> result = sealTrackingService.getByTransfer(TRANSFER_TYPE, TRANSFER_ID);

        assertThat(result).isEmpty();
    }

    // ─── 11. validateSealIntegrity: más cég rekordja false-t ad vissza ───

    @Test
    @DisplayName("validateSealIntegrity: más cég rekordja false-t ad vissza (ne szivárogjon ki az integritás)")
    void validateSealIntegrity_otherCompany_returnsFalse() {
        UUID otherCompanyId = UUID.randomUUID();
        SealTracking otherTracking = buildTrackingForCompany(SealTransitStatus.SEALED, otherCompanyId);
        when(sealTrackingRepository.findByTransferTypeAndTransferId(TRANSFER_TYPE, TRANSFER_ID))
                .thenReturn(Optional.of(otherTracking));

        boolean result = sealTrackingService.validateSealIntegrity(TRANSFER_TYPE, TRANSFER_ID, SEAL_NUMBER);

        assertThat(result).isFalse();
    }

    // ─── 12. startTransit: más cég rekordja ResourceNotFoundException-t dob ───

    @Test
    @DisplayName("startTransit: más cég rekordján ResourceNotFoundException-t dob")
    void startTransit_otherCompany_throwsResourceNotFoundException() {
        UUID otherCompanyId = UUID.randomUUID();
        SealTracking otherTracking = buildTrackingForCompany(SealTransitStatus.SEALED, otherCompanyId);
        when(sealTrackingRepository.findByTransferTypeAndTransferId(TRANSFER_TYPE, TRANSFER_ID))
                .thenReturn(Optional.of(otherTracking));

        assertThatThrownBy(() -> sealTrackingService.startTransit(TRANSFER_TYPE, TRANSFER_ID))
                .isInstanceOf(ResourceNotFoundException.class);

        verify(sealTrackingRepository, never()).save(any());
    }

    // --- helper ---

    private SealTracking buildTracking(SealTransitStatus status) {
        return buildTrackingForCompany(status, COMPANY_ID);
    }

    private SealTracking buildTrackingForCompany(SealTransitStatus status, UUID companyId) {
        return SealTracking.builder()
                .id(1L)
                .companyId(companyId)
                .transferType(TRANSFER_TYPE)
                .transferId(TRANSFER_ID)
                .sealNumber(SEAL_NUMBER)
                .sealedAt(LocalDateTime.now())
                .sealedBy(WORKER_ID)
                .transitStatus(status)
                .build();
    }
}
