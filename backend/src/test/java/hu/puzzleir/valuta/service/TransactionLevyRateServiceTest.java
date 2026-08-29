package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.levy.TransactionLevyRateCreateRequest;
import hu.puzzleir.valuta.dto.levy.TransactionLevyRateDto;
import hu.puzzleir.valuta.entity.TransactionLevyRateHistory;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransactionLevyRateHistoryRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-099 C-sorozat — append-only ráta-history use case (WU1 RED → WU5 GREEN).
 * C12–C14 a delta (D16/D17) esetei.
 */
@ExtendWith(MockitoExtension.class)
class TransactionLevyRateServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
    private static final UUID SEED_RATE_ID = UUID.fromString("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee");

    @Mock private TransactionLevyRateHistoryRepository rateHistoryRepository;
    @Mock private AuditLogService auditLogService;

    private TransactionLevyRateService service;

    @BeforeEach
    void setUp() {
        service = new TransactionLevyRateService(rateHistoryRepository, auditLogService);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    // ============================ FIXTURE-HELPEREK ============================

    private void authenticate(String role) {
        UsernamePasswordAuthenticationToken token = new UsernamePasswordAuthenticationToken(
                "WK099", "n/a", List.of(new SimpleGrantedAuthority("ROLE_" + role)));
        token.setDetails(new WorkerAuthenticationDetails(42L, COMPANY_ID, null, role));
        SecurityContextHolder.getContext().setAuthentication(token);
    }

    private static TransactionLevyRateHistory seedRateRow() {
        return TransactionLevyRateHistory.builder()
                .id(SEED_RATE_ID)
                .companyId(COMPANY_ID)
                .effectiveFrom(LocalDate.of(2013, 1, 1))
                .baseRatePercent(new BigDecimal("0.450"))
                .baseRateCapHuf(new BigDecimal("20000.00"))
                .supplementRatePercent(new BigDecimal("0.450"))
                .supplementRateCapHuf(new BigDecimal("20000.00"))
                .conversionSingleSideFlag(true)
                .createdBy("V384")
                .createdAt(OffsetDateTime.parse("2026-08-01T00:00:00Z"))
                .build();
    }

    private static TransactionLevyRateCreateRequest validRequest(LocalDate effectiveFrom) {
        return TransactionLevyRateCreateRequest.builder()
                .effectiveFrom(effectiveFrom)
                .baseRatePercent(new BigDecimal("0.500"))
                .baseRateCapHuf(new BigDecimal("25000.00"))
                .supplementRatePercent(new BigDecimal("0.500"))
                .supplementRateCapHuf(new BigDecimal("25000.00"))
                .conversionSingleSideFlag(Boolean.TRUE)
                .build();
    }

    private void stubMaxExisting(TransactionLevyRateHistory row) {
        when(rateHistoryRepository.findFirstByCompanyIdOrderByEffectiveFromDesc(COMPANY_ID))
                .thenReturn(Optional.ofNullable(row));
    }

    // ============================ C1–C4: append-only validáció ============================

    @Test
    @DisplayName("C1/FR-1: jövőbeli effective_from, max existing = seed → mentés a kért értékekkel")
    void c1_futureRateSavedVerbatim() {
        authenticate("FOERTEKTAR");
        LocalDate tomorrow = LocalDate.now().plusDays(1);
        stubMaxExisting(seedRateRow());
        when(rateHistoryRepository.saveAndFlush(any(TransactionLevyRateHistory.class)))
                .thenAnswer(invocation -> {
                    TransactionLevyRateHistory entity = invocation.getArgument(0);
                    return TransactionLevyRateHistory.builder()
                            .id(UUID.randomUUID())
                            .companyId(entity.getCompanyId())
                            .effectiveFrom(entity.getEffectiveFrom())
                            .baseRatePercent(entity.getBaseRatePercent())
                            .baseRateCapHuf(entity.getBaseRateCapHuf())
                            .supplementRatePercent(entity.getSupplementRatePercent())
                            .supplementRateCapHuf(entity.getSupplementRateCapHuf())
                            .conversionSingleSideFlag(entity.isConversionSingleSideFlag())
                            .createdBy(entity.getCreatedBy())
                            .createdAt(OffsetDateTime.parse("2026-08-29T10:00:00Z"))
                            .build();
                });

        var dto = service.create(validRequest(tomorrow));

        ArgumentCaptor<TransactionLevyRateHistory> captor =
                ArgumentCaptor.forClass(TransactionLevyRateHistory.class);
        verify(rateHistoryRepository).saveAndFlush(captor.capture());
        TransactionLevyRateHistory saved = captor.getValue();
        assertThat(saved.getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(saved.getEffectiveFrom()).isEqualTo(tomorrow);
        assertThat(saved.getBaseRatePercent()).isEqualByComparingTo("0.500");
        assertThat(saved.getBaseRateCapHuf()).isEqualByComparingTo("25000.00");
        assertThat(saved.getSupplementRatePercent()).isEqualByComparingTo("0.500");
        assertThat(saved.getSupplementRateCapHuf()).isEqualByComparingTo("25000.00");
        assertThat(saved.getCreatedBy()).isEqualTo("WK099");
        assertThat(dto.getEffectiveFrom()).isEqualTo(tomorrow);
    }

    @Test
    @DisplayName("C2/FR-1: effective_from = MA → ValidationException, nincs mentés")
    void c2_todayRejected() {
        authenticate("FOERTEKTAR");
        stubMaxExisting(seedRateRow());

        assertThatThrownBy(() -> service.create(validRequest(LocalDate.now())))
                .isInstanceOf(ValidationException.class);

        verify(rateHistoryRepository, never()).saveAndFlush(any());
    }

    @Test
    @DisplayName("C3/FR-1: tegnapi dátum → EGY ValidationException, amely MINDKÉT szabályt megnevezi")
    void c3_pastDateNamesBothBrokenRules() {
        authenticate("FOERTEKTAR");
        // max existing = ma+5: a tegnapi dátum egyszerre nem-jövőbeli ÉS nem monoton
        TransactionLevyRateHistory later = TransactionLevyRateHistory.builder()
                .companyId(COMPANY_ID)
                .effectiveFrom(LocalDate.now().plusDays(5))
                .baseRatePercent(BigDecimal.ONE)
                .baseRateCapHuf(BigDecimal.ONE)
                .supplementRatePercent(BigDecimal.ONE)
                .supplementRateCapHuf(BigDecimal.ONE)
                .build();
        stubMaxExisting(later);

        assertThatThrownBy(() -> service.create(validRequest(LocalDate.now().minusDays(1))))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("jövőbeli")
                .hasMessageContaining(LocalDate.now().plusDays(5).toString());

        verify(rateHistoryRepository, never()).saveAndFlush(any());
    }

    @Test
    @DisplayName("C4/FR-1: nem-monoton (max existing későbbi) → ValidationException a max dátummal")
    void c4_nonMonotonicRejected() {
        authenticate("FOERTEKTAR");
        LocalDate tomorrow = LocalDate.now().plusDays(1);
        TransactionLevyRateHistory later = TransactionLevyRateHistory.builder()
                .companyId(COMPANY_ID)
                .effectiveFrom(LocalDate.now().plusDays(5))
                .baseRatePercent(BigDecimal.ONE)
                .baseRateCapHuf(BigDecimal.ONE)
                .supplementRatePercent(BigDecimal.ONE)
                .supplementRateCapHuf(BigDecimal.ONE)
                .build();
        stubMaxExisting(later);

        assertThatThrownBy(() -> service.create(validRequest(tomorrow)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining(LocalDate.now().plusDays(5).toString());

        verify(rateHistoryRepository, never()).saveAndFlush(any());
    }

    // ============================ C5: FR-20 audit ============================

    @Test
    @DisplayName("C5/FR-20: sikeres create → logInNewTransactionForCompany CREATE + KAT:RATE")
    void c5_successfulCreateAuditsKatRate() {
        authenticate("FOERTEKTAR");
        LocalDate tomorrow = LocalDate.now().plusDays(1);
        stubMaxExisting(seedRateRow());
        when(rateHistoryRepository.saveAndFlush(any(TransactionLevyRateHistory.class)))
                .thenAnswer(invocation -> TransactionLevyRateHistory.builder()
                        .id(UUID.fromString("99999999-9999-9999-9999-999999999999"))
                        .companyId(COMPANY_ID)
                        .effectiveFrom(tomorrow)
                        .baseRatePercent(new BigDecimal("0.500"))
                        .baseRateCapHuf(new BigDecimal("25000.00"))
                        .supplementRatePercent(new BigDecimal("0.500"))
                        .supplementRateCapHuf(new BigDecimal("25000.00"))
                        .conversionSingleSideFlag(true)
                        .createdBy("WK099")
                        .build());

        service.create(validRequest(tomorrow));

        verify(auditLogService, times(1)).logInNewTransactionForCompany(
                eq("CREATE"),
                contains("\"KAT\":\"RATE\""),
                eq("99999999-9999-9999-9999-999999999999"),
                eq(COMPANY_ID));
        verify(auditLogService, times(1)).logInNewTransactionForCompany(
                eq("CREATE"), contains(tomorrow.toString()), anyString(), eq(COMPANY_ID));
    }

    // ============================ C6–C10: RBAC ============================

    @Test
    @DisplayName("C6/FR-18: IRODAVEZETO create → AccessDeniedException VV-AUTH-007 + audit, nincs mentés")
    void c6_irodavezetoCreateDenied() {
        authenticate("IRODAVEZETO");

        assertThatThrownBy(() -> service.create(validRequest(LocalDate.now().plusDays(1))))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageStartingWith("VV-AUTH-007");

        verify(auditLogService, times(1)).logInNewTransaction(
                eq("ACCESS_DENIED"), eq("TRANSACTION_LEVY_RATE"), any(),
                any(), any(), any(), any(), contains("\"VV-AUTH-007\""));
        verify(rateHistoryRepository, never()).saveAndFlush(any());
    }

    @Test
    @DisplayName("C7/FR-18: BELSO_ELLENOR create → AccessDeniedException VV-AUTH-007, nincs mentés")
    void c7_belsoEllenorCreateDenied() {
        authenticate("BELSO_ELLENOR");

        assertThatThrownBy(() -> service.create(validRequest(LocalDate.now().plusDays(1))))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageStartingWith("VV-AUTH-007");

        verify(rateHistoryRepository, never()).saveAndFlush(any());
    }

    @Test
    @DisplayName("C8/FR-18: BELSO_ELLENOR list → engedélyezett (a C7 jó fele)")
    void c8_belsoEllenorListAllowed() {
        authenticate("BELSO_ELLENOR");
        when(rateHistoryRepository.findByCompanyIdOrderByEffectiveFromDesc(COMPANY_ID))
                .thenReturn(List.of(seedRateRow()));

        List<TransactionLevyRateDto> rates = service.list();

        assertThat(rates).hasSize(1);
    }

    @Test
    @DisplayName("C9/FR-18: FOERTEKTAR create → engedélyezett (a C6 jó fele)")
    void c9_foertektarCreateAllowed() {
        authenticate("FOERTEKTAR");
        stubMaxExisting(seedRateRow());
        when(rateHistoryRepository.saveAndFlush(any(TransactionLevyRateHistory.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        assertThat(service.create(validRequest(LocalDate.now().plusDays(1)))).isNotNull();
    }

    @Test
    @DisplayName("C10/RBAC: PENZTAR list → AccessDeniedException + ACCESS_DENIED audit")
    void c10_penztarListDenied() {
        authenticate("PENZTAR");

        assertThatThrownBy(() -> service.list())
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageStartingWith("VV-AUTH-007");

        verify(auditLogService, times(1)).logInNewTransaction(
                eq("ACCESS_DENIED"), eq("TRANSACTION_LEVY_RATE"), any(),
                any(), any(), any(), any(), contains("\"VV-AUTH-007\""));
    }

    // ============================ C11: mapping ============================

    @Test
    @DisplayName("C11: list() → effectiveFrom DESC sorrend, DTO derived küszöbbel")
    void c11_listMapsDescWithDerivedThreshold() {
        authenticate("FOERTEKTAR");
        TransactionLevyRateHistory newer = TransactionLevyRateHistory.builder()
                .id(UUID.randomUUID())
                .companyId(COMPANY_ID)
                .effectiveFrom(LocalDate.of(2026, 8, 15))
                .baseRatePercent(new BigDecimal("0.300"))
                .baseRateCapHuf(new BigDecimal("15000.00"))
                .supplementRatePercent(new BigDecimal("0.300"))
                .supplementRateCapHuf(new BigDecimal("15000.00"))
                .conversionSingleSideFlag(true)
                .createdBy("WK001")
                .createdAt(OffsetDateTime.parse("2026-08-14T10:00:00Z"))
                .build();
        when(rateHistoryRepository.findByCompanyIdOrderByEffectiveFromDesc(COMPANY_ID))
                .thenReturn(List.of(newer, seedRateRow()));

        List<TransactionLevyRateDto> rates = service.list();

        assertThat(rates).hasSize(2);
        assertThat(rates.get(0).getEffectiveFrom()).isEqualTo(LocalDate.of(2026, 8, 15));
        assertThat(rates.get(0).getThresholdHuf()).isEqualByComparingTo("5000000");
        assertThat(rates.get(1).getEffectiveFrom()).isEqualTo(LocalDate.of(2013, 1, 1));
        assertThat(rates.get(1).getThresholdHuf()).isEqualByComparingTo("4444445");
        assertThat(rates.get(1).isConversionSingleSideFlag()).isTrue();
    }

    // ============================ C12–C14: delta-esetek (D16/D17) ============================

    @Test
    @DisplayName("C12/D16: saveAndFlush DataIntegrityViolationException → ValidationException, nincs CREATE audit")
    void c12_concurrentDuplicateMapsToValidationException() {
        authenticate("FOERTEKTAR");
        stubMaxExisting(seedRateRow());
        when(rateHistoryRepository.saveAndFlush(any(TransactionLevyRateHistory.class)))
                .thenThrow(new DataIntegrityViolationException(
                        "duplicate key value violates unique constraint \"uk_tlrh_company_effective\""));

        assertThatThrownBy(() -> service.create(validRequest(LocalDate.now().plusDays(1))))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining(LocalDate.now().plusDays(1).toString());

        verify(auditLogService, never())
                .logInNewTransactionForCompany(anyString(), anyString(), anyString(), any());
    }

    @Test
    @DisplayName("C13/D16: sikeres create → saveAndFlush (NEM save) hívódik és a KAT:RATE audit elsül")
    void c13_saveAndFlushIsThePersistMethod() {
        authenticate("FOERTEKTAR");
        stubMaxExisting(seedRateRow());
        when(rateHistoryRepository.saveAndFlush(any(TransactionLevyRateHistory.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        service.create(validRequest(LocalDate.now().plusDays(1)));

        verify(rateHistoryRepository, times(1)).saveAndFlush(any(TransactionLevyRateHistory.class));
        verify(auditLogService, times(1)).logInNewTransactionForCompany(
                eq("CREATE"), contains("\"KAT\":\"RATE\""), anyString(), eq(COMPANY_ID));
    }

    @Test
    @DisplayName("C14/D17: conversionSingleSideFlag = FALSE → a mentett primitív mező false")
    void c14_flagFalsePersistsToPrimitiveField() {
        authenticate("FOERTEKTAR");
        stubMaxExisting(seedRateRow());
        when(rateHistoryRepository.saveAndFlush(any(TransactionLevyRateHistory.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        TransactionLevyRateCreateRequest request = TransactionLevyRateCreateRequest.builder()
                .effectiveFrom(LocalDate.now().plusDays(1))
                .baseRatePercent(new BigDecimal("0.450"))
                .baseRateCapHuf(new BigDecimal("20000.00"))
                .supplementRatePercent(new BigDecimal("0.450"))
                .supplementRateCapHuf(new BigDecimal("20000.00"))
                .conversionSingleSideFlag(Boolean.FALSE)
                .build();

        TransactionLevyRateDto dto = service.create(request);

        ArgumentCaptor<TransactionLevyRateHistory> captor =
                ArgumentCaptor.forClass(TransactionLevyRateHistory.class);
        verify(rateHistoryRepository).saveAndFlush(captor.capture());
        assertThat(captor.getValue().isConversionSingleSideFlag()).isFalse();
        assertThat(dto.isConversionSingleSideFlag()).isFalse();
    }
}
