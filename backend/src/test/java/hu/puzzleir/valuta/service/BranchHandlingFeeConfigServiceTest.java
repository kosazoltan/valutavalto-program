package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigDraftRequest;
import hu.puzzleir.valuta.dto.handlingfee.BranchFeeConfigDto;
import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeBracketDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.BranchHandlingFeeConfig;
import hu.puzzleir.valuta.entity.FeeConfigStatus;
import hu.puzzleir.valuta.entity.HandlingFeeBracket;
import hu.puzzleir.valuta.entity.HandlingFeeType;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchHandlingFeeConfigRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.HandlingFeeBracketRepository;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InOrder;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.orm.ObjectOptimisticLockingFailureException;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-096 WU-6 — BranchHandlingFeeConfigService UNIT tesztek (RED elsőnek).
 *
 * Lefedett szabályok:
 * - FR-8: saveDraft nem nyúl a LIVE sorhoz.
 * - FR-9/NFR-5: publish atomi csere + audit (KAT:RATE, before/after értékek).
 * - FR-13: cross-tenant publish → 404 (ResourceNotFoundException), nincs írás.
 * - D8: verzióütközés → ObjectOptimisticLockingFailureException (409);
 *       expectedVersion = 0 LEGITIM első publikálás (B2), csak a null → 400 (N9).
 * - D17/W3: publish-sorrend: inaktiválás → flush → előléptetés.
 * - D5/NFR-2: a draft-save az cap-et 5 Ft-ra kerekíti (2003 → 2005).
 * - FR-11: a közös sáv-publikálás soros zárás (lockAllForCompany) előtt ír.
 * - D18/W4: seedDefaultLive a D6 precedenciával és D5 verbatim cappal.
 */
@ExtendWith(MockitoExtension.class)
class BranchHandlingFeeConfigServiceTest {

    @Mock private BranchHandlingFeeConfigRepository configRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private HandlingFeeBracketRepository bracketRepository;
    @Mock private SystemParameterRepository systemParameterRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private AuditLogService auditLogService;

    @InjectMocks
    private BranchHandlingFeeConfigService service;

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID BRANCH_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    // =====================================================================
    // FR-8 — saveDraft nem nyúl a LIVE sorhoz
    // =====================================================================
    @Test
    @DisplayName("FR-8: saveDraft csak a DRAFT sort írja, a LIVE sértetlen marad")
    void saveDraftNemNyulALiveSorhoz() {
        BranchHandlingFeeConfig live = liveConfig(HandlingFeeType.PER_MILLE,
                new BigDecimal("3"), null, 0L);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(Optional.of(branch()));
            when(configRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    COMPANY_ID, BRANCH_ID, FeeConfigStatus.DRAFT))
                    .thenReturn(Optional.empty());
            when(configRepository.saveAndFlush(any(BranchHandlingFeeConfig.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            BranchFeeConfigDto result = service.saveDraft(BRANCH_ID,
                    draftRequest("PER_MILLE", new BigDecimal("5"), new BigDecimal("1000")));

            assertThat(result.isHasDraft()).isTrue();
            // FR-8 bizonyíték: a LIVE sort a draft-mentés kódútja SEM lekérdezésben,
            // SEM írásban nem érinti; a lokálisan felépített LIVE fixture sértetlen.
            verify(configRepository, never()).findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    COMPANY_ID, BRANCH_ID, FeeConfigStatus.LIVE);
            verify(configRepository, never()).save(live);
            assertThat(live.getFeeMode()).isEqualTo(HandlingFeeType.PER_MILLE);
            assertThat(live.getPerMilleRate()).isEqualByComparingTo("3");
            assertThat(live.getActive()).isTrue();
            assertThat(live.getStatus()).isEqualTo(FeeConfigStatus.LIVE);
        }
    }

    // =====================================================================
    // FR-9 / NFR-5 — publish atomi csere + audit
    // =====================================================================
    @Test
    @DisplayName("FR-9: publish — DRAFT lesz LIVE, régi LIVE archiválva, egy audit KAT:RATE before/after-rel")
    void publishAtomicCsere() {
        BranchHandlingFeeConfig live = liveConfig(HandlingFeeType.PER_MILLE,
                new BigDecimal("3"), null, 7L);
        BranchHandlingFeeConfig draft = draftConfig(HandlingFeeType.PER_MILLE,
                new BigDecimal("5"), new BigDecimal("1000"), 2L);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(Optional.of(branch()));
            when(configRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    COMPANY_ID, BRANCH_ID, FeeConfigStatus.LIVE))
                    .thenReturn(Optional.of(live));
            when(configRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    COMPANY_ID, BRANCH_ID, FeeConfigStatus.DRAFT))
                    .thenReturn(Optional.of(draft));
            when(configRepository.save(any(BranchHandlingFeeConfig.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            service.publish(BRANCH_ID, 2L);

            // Régi LIVE archiválva (nem törölve)
            assertThat(live.getActive()).as("FR-9: a régi LIVE sor is_active=false lesz").isFalse();
            // DRAFT előléptetve
            assertThat(draft.getStatus()).isEqualTo(FeeConfigStatus.LIVE);
            assertThat(draft.getActive()).isTrue();
            assertThat(draft.getPublishedBy()).isEqualTo("KOSA");
            assertThat(draft.getPublishedAt()).isNotNull();
            // Egyetlen audit-bejegyzés KAT:RATE + before/after értékekkel
            ArgumentCaptor<String> changesCaptor = ArgumentCaptor.forClass(String.class);
            verify(auditLogService, times(1)).log(
                    eq("BRANCH_FEE_CONFIG_PUBLISHED"), anyString(), anyString(),
                    anyString(), anyString(), anyString(), any(),
                    changesCaptor.capture(), any(), any());
            String changes = changesCaptor.getValue();
            assertThat(changes).contains("\"KAT\":\"RATE\"");
            assertThat(changes).contains("before");
            assertThat(changes).contains("after");
            assertThat(changes).contains("\"per_mille_rate\":\"3\"");
            assertThat(changes).contains("\"per_mille_rate\":\"5\"");
        }
    }

    // =====================================================================
    // FR-13 — cross-tenant publish → 404, nincs írás
    // =====================================================================
    @Test
    @DisplayName("FR-13: másik cég irodájára publish → ResourceNotFoundException (404), írás nélkül")
    void publishCrossTenant404() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.publish(BRANCH_ID, 0L))
                    .isInstanceOf(ResourceNotFoundException.class);

            verify(configRepository, never()).save(any());
            // ITEM 2 (round 2): a 404 ellenére a forenzikus audit REQUIRES_NEW-ben íródik —
            // a korábbi verifyNoInteractions(auditLogService) assert a ruling (ITEM 2) szerinti
            // audit-követelménnyel ellentétes volt; ez a csere SZIGORÍTÁS (write-side bizonyíték),
            // nem gyengítés (a publikálás KAT:RATE auditja továbbra sem íródhat itt).
            verify(auditLogService).logInNewTransaction(
                    eq("BRANCH_FEE_CONFIG_ACCESS_DENIED"), any(), any(),
                    any(), any(), any(), any(), any(), eq(COMPANY_ID));
            verify(auditLogService, never()).log(
                    anyString(), anyString(), anyString(),
                    anyString(), anyString(), anyString(), any(),
                    anyString(), any(), any());
        }
    }

    // =====================================================================
    // D8 — verzióütközés → 409
    // =====================================================================
    @Test
    @DisplayName("D8: elavult expectedVersion → ObjectOptimisticLockingFailureException (409)")
    void publishVerzioUtkozes409() {
        BranchHandlingFeeConfig draft = draftConfig(HandlingFeeType.PER_MILLE,
                new BigDecimal("5"), null, 5L);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(Optional.of(branch()));
            when(configRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    COMPANY_ID, BRANCH_ID, FeeConfigStatus.DRAFT))
                    .thenReturn(Optional.of(draft));

            assertThatThrownBy(() -> service.publish(BRANCH_ID, 4L))
                    .as("D8: a stale verzió 409 konfliktus")
                    .isInstanceOf(ObjectOptimisticLockingFailureException.class);

            verify(configRepository, never()).flush();
        }
    }

    // =====================================================================
    // B2 — expectedVersion = 0 legitim ELSŐ publikálás
    // =====================================================================
    @Test
    @DisplayName("B2: V383-seeded sor version=0 — az első publikálás expectedVersion=0-val SIKERES")
    void publishNullaVerzioval_ElsoPublikalasSikeres() {
        BranchHandlingFeeConfig live = liveConfig(HandlingFeeType.BRACKET, null, null, 0L);
        BranchHandlingFeeConfig draft = draftConfig(HandlingFeeType.PER_MILLE,
                new BigDecimal("4"), null, 0L);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(Optional.of(branch()));
            when(configRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    COMPANY_ID, BRANCH_ID, FeeConfigStatus.LIVE))
                    .thenReturn(Optional.of(live));
            when(configRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    COMPANY_ID, BRANCH_ID, FeeConfigStatus.DRAFT))
                    .thenReturn(Optional.of(draft));
            when(configRepository.save(any(BranchHandlingFeeConfig.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            service.publish(BRANCH_ID, 0L);

            assertThat(draft.getStatus()).as("B2: a DRAFT LIVE lesz").isEqualTo(FeeConfigStatus.LIVE);
            assertThat(live.getActive()).isFalse();
            verify(auditLogService, times(1)).log(
                    eq("BRANCH_FEE_CONFIG_PUBLISHED"), anyString(), anyString(),
                    anyString(), anyString(), anyString(), any(), anyString(), any(), any());
        }
    }

    @Test
    @DisplayName("B2/N9: expectedVersion = null → ValidationException (400)")
    void publishNullVerzioval400() {
        // A null-ellenőrzés a SecurityUtils-olvasás ELŐTT van — nincs szükség kontextusra.
        assertThatThrownBy(() -> service.publish(BRANCH_ID, null))
                .isInstanceOf(ValidationException.class);

        verify(configRepository, never()).save(any());
    }

    // =====================================================================
    // D17 / W3 — publish-sorrend: inaktiválás → flush → előléptetés
    // =====================================================================
    @Test
    @DisplayName("D17: a publish ELŐBB inaktiválja a régi LIVE-ot és flush-ol, CSAK AZTÁN lépteti elő a DRAFT-ot")
    void publishSorrend_ElobbInaktival_AztanEloptet() {
        BranchHandlingFeeConfig live = liveConfig(HandlingFeeType.BRACKET, null, null, 0L);
        BranchHandlingFeeConfig draft = draftConfig(HandlingFeeType.PER_MILLE,
                new BigDecimal("4"), null, 0L);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(Optional.of(branch()));
            when(configRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    COMPANY_ID, BRANCH_ID, FeeConfigStatus.LIVE))
                    .thenReturn(Optional.of(live));
            when(configRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    COMPANY_ID, BRANCH_ID, FeeConfigStatus.DRAFT))
                    .thenReturn(Optional.of(draft));
            when(configRepository.save(any(BranchHandlingFeeConfig.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            service.publish(BRANCH_ID, 0L);

            // Mockito csak a hívás-sorrendet bizonyítja; a parciális egyedi index
            // viselkedési bizonyítéka a WU-8 valós-sémás Postgres IT-ben van.
            InOrder inOrder = inOrder(configRepository);
            inOrder.verify(configRepository).save(live);      // 1. régi LIVE inaktiválva mentve
            inOrder.verify(configRepository).flush();          // 2. kötelező flush — az index csak ezután szabadul
            inOrder.verify(configRepository).save(draft);      // 3. DRAFT előléptetve
            inOrder.verify(configRepository).flush();          // 4. flush, majd audit
        }
    }

    // =====================================================================
    // D5 / NFR-2 — a draft-save a cap-et 5 Ft-ra kerekíti
    // =====================================================================
    @Test
    @DisplayName("D5: saveDraft a per_mille_cap-et 5 Ft-ra kerekíti (2003 → 2005)")
    void saveDraftKerekitiACapot() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(Optional.of(branch()));
            when(configRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    COMPANY_ID, BRANCH_ID, FeeConfigStatus.DRAFT))
                    .thenReturn(Optional.empty());
            when(configRepository.saveAndFlush(any(BranchHandlingFeeConfig.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            service.saveDraft(BRANCH_ID,
                    draftRequest("PER_MILLE", new BigDecimal("3.5"), new BigDecimal("2003")));

            ArgumentCaptor<BranchHandlingFeeConfig> captor =
                    ArgumentCaptor.forClass(BranchHandlingFeeConfig.class);
            // R2-WU-3: save → saveAndFlush mechanikus átnevezés (R2-D9, nem gyengítés).
            verify(configRepository).saveAndFlush(captor.capture());
            assertThat(captor.getValue().getPerMilleCap())
                    .as("D5: az írási út 5 Ft-ra kerekíti a cap-et")
                    .isEqualByComparingTo("2005");
        }
    }

    // =====================================================================
    // FR-11 — közös sáv-publikálás soros zárás
    // =====================================================================
    @Test
    @DisplayName("FR-11: publishBrackets ELŐSZÖR lockAllForCompany (PESSIMISTIC_WRITE), csak aztán ír")
    void bracketPublishSorosZarolasal() {
        HandlingFeeBracket draftBracket = HandlingFeeBracket.builder()
                .id(1L)
                .bracketOrder(1)
                .upperLimit(new BigDecimal("100000"))
                .feeAmount(new BigDecimal("300"))
                .active(true)
                .status(FeeConfigStatus.DRAFT)
                .build();
        HandlingFeeBracket liveBracket = HandlingFeeBracket.builder()
                .id(2L)
                .bracketOrder(1)
                .upperLimit(new BigDecimal("100000"))
                .feeAmount(new BigDecimal("200"))
                .active(true)
                .status(FeeConfigStatus.LIVE)
                .build();

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");
            when(bracketRepository.lockAllForCompany(COMPANY_ID))
                    .thenReturn(List.of(liveBracket));
            when(bracketRepository.findByCompanyIdAndStatusAndActiveOrderByBracketOrder(
                    COMPANY_ID, FeeConfigStatus.DRAFT, true))
                    .thenReturn(List.of(draftBracket));
            when(bracketRepository.save(any(HandlingFeeBracket.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            service.publishBrackets();

            InOrder inOrder = inOrder(bracketRepository);
            inOrder.verify(bracketRepository).lockAllForCompany(COMPANY_ID);
            inOrder.verify(bracketRepository, org.mockito.Mockito.atLeastOnce())
                    .save(any(HandlingFeeBracket.class));
            assertThat(draftBracket.getStatus()).as("A DRAFT sáv LIVE lesz").isEqualTo(FeeConfigStatus.LIVE);
            assertThat(liveBracket.getActive()).as("A régi LIVE sáv inaktiválódik").isFalse();
        }
    }

    // =====================================================================
    // D18 / W4 — seedDefaultLive új irodának
    // =====================================================================
    @Test
    @DisplayName("D18: seedDefaultLive a D6 precedenciával és D5 VERBATIM cappal seed-el (2003, nem 2005)")
    void seedDefaultLive_UjIrodaOroksegiErtekkel() {
        // D6: nincs cég-scope override → a globális aktív sor öröklődik.
        when(systemParameterRepository.findEffectiveByParameterKeyAndCompanyId(
                anyString(), eq(COMPANY_ID))).thenReturn(Optional.empty());
        when(systemParameterRepository.findEffectiveGlobalByParameterKey("HANDLING_FEE_TYPE"))
                .thenReturn(Optional.of(parameter("HANDLING_FEE_TYPE", "PER_MILLE")));
        when(systemParameterRepository.findEffectiveGlobalByParameterKey("HANDLING_FEE_PER_MILLE"))
                .thenReturn(Optional.of(parameter("HANDLING_FEE_PER_MILLE", "3.5")));
        when(systemParameterRepository.findEffectiveGlobalByParameterKey("HANDLING_FEE_PER_MILLE_MAX"))
                .thenReturn(Optional.of(parameter("HANDLING_FEE_PER_MILLE_MAX", "2003")));
        when(configRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                COMPANY_ID, BRANCH_ID, FeeConfigStatus.LIVE))
                .thenReturn(Optional.empty());
        when(configRepository.save(any(BranchHandlingFeeConfig.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        service.seedDefaultLive(COMPANY_ID, BRANCH_ID, "SYSTEM");

        ArgumentCaptor<BranchHandlingFeeConfig> captor =
                ArgumentCaptor.forClass(BranchHandlingFeeConfig.class);
        verify(configRepository).save(captor.capture());
        BranchHandlingFeeConfig seeded = captor.getValue();
        assertThat(seeded.getFeeMode()).isEqualTo(HandlingFeeType.PER_MILLE);
        assertThat(seeded.getPerMilleRate()).isEqualByComparingTo("3.5");
        assertThat(seeded.getPerMilleCap())
                .as("D5: a seed VERBATIM 2003 — nincs 5 Ft kerekítés")
                .isEqualByComparingTo("2003");
        assertThat(seeded.getStatus()).isEqualTo(FeeConfigStatus.LIVE);
        assertThat(seeded.getActive()).isTrue();
        assertThat(seeded.getCreatedBy()).isEqualTo("SYSTEM");
    }

    // =====================================================================
    // ITEM 2 (round 2) — ACCESS_DENIED audit mindkét 404-helyen
    // =====================================================================
    @Test
    @DisplayName("ITEM 2: cross-tenant publish → 404 + BRANCH_FEE_CONFIG_ACCESS_DENIED audit (REQUIRES_NEW, túléli a rollbacket)")
    void publishCrossTenant_ACCESS_DENIED_auditotIr() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.publish(BRANCH_ID, 0L))
                    .isInstanceOf(ResourceNotFoundException.class);

            ArgumentCaptor<String> changesCaptor = ArgumentCaptor.forClass(String.class);
            verify(auditLogService).logInNewTransaction(
                    eq("BRANCH_FEE_CONFIG_ACCESS_DENIED"), eq("BranchHandlingFeeConfig"),
                    eq(BRANCH_ID.toString()), any(), any(), eq(BRANCH_ID.toString()), any(),
                    changesCaptor.capture(), eq(COMPANY_ID));
            String changes = changesCaptor.getValue();
            assertThat(changes).contains("\"KAT\":\"AUTH\"");
            assertThat(changes).contains("\"error_code\":\"VV-AUTH-001\"");
            assertThat(changes).contains("\"reason\":\"CROSS_TENANT_BRANCH\"");
            verify(configRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("ITEM 2: idegen iroda /live olvasása → 404 + FOREIGN_BRANCH_LIVE_READ audit, tenant-guard nélkül")
    void getLiveForBranch_IdegenIroda_ACCESS_DENIED_auditotIr() {
        UUID otherBranchId = UUID.fromString("33333333-3333-3333-3333-333333333333");
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentBranchId).thenReturn(otherBranchId);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");

            assertThatThrownBy(() -> service.getLiveForBranch(BRANCH_ID))
                    .isInstanceOf(ResourceNotFoundException.class);

            ArgumentCaptor<String> changesCaptor = ArgumentCaptor.forClass(String.class);
            verify(auditLogService).logInNewTransaction(
                    eq("BRANCH_FEE_CONFIG_ACCESS_DENIED"), eq("BranchHandlingFeeConfig"),
                    eq(BRANCH_ID.toString()), any(), any(), eq(BRANCH_ID.toString()), any(),
                    changesCaptor.capture(), eq(COMPANY_ID));
            assertThat(changesCaptor.getValue()).contains("\"reason\":\"FOREIGN_BRANCH_LIVE_READ\"");
            // A saját-iroda guard a tenant-guard ELŐTT dob — cég-lookup soha nem történik.
            verify(branchRepository, never()).findByIdAndCompanyId(any(), any());
        }
    }

    // =====================================================================
    // ITEM 4 (round 2) — PER_MILLE draft null/negatív mértékkel → 400
    // =====================================================================
    @Test
    @DisplayName("ITEM 4: saveDraft PER_MILLE módban üres (null) mértékkel → ValidationException, írás nélkül")
    void saveDraft_PerMilleUresMertekkel_400() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(Optional.of(branch()));
            when(configRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    COMPANY_ID, BRANCH_ID, FeeConfigStatus.DRAFT))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.saveDraft(BRANCH_ID,
                    draftRequest("PER_MILLE", null, null)))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("mérték");

            verify(configRepository, never()).save(any());
            verify(configRepository, never()).saveAndFlush(any());
        }
    }

    @Test
    @DisplayName("ITEM 4: saveDraft PER_MILLE módban negatív mértékkel → ValidationException, írás nélkül")
    void saveDraft_PerMilleNegativMertekkel_400() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");
            when(branchRepository.findByIdAndCompanyId(BRANCH_ID, COMPANY_ID))
                    .thenReturn(Optional.of(branch()));
            when(configRepository.findByCompanyIdAndBranchIdAndStatusAndActiveTrue(
                    COMPANY_ID, BRANCH_ID, FeeConfigStatus.DRAFT))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.saveDraft(BRANCH_ID,
                    draftRequest("PER_MILLE", new BigDecimal("-1"), null)))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("mérték");

            verify(configRepository, never()).save(any());
            verify(configRepository, never()).saveAndFlush(any());
        }
    }

    // =====================================================================
    // ITEM 3 (round 2) — sáv-piszkozat validáció (null/negatív/zero → 400)
    // =====================================================================
    @Test
    @DisplayName("ITEM 3: saveBracketDraft negatív díjjal → ValidationException, save soha nem hívódik")
    void saveBracketDraft_NegativDijat_Elutasit() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");

            assertThatThrownBy(() -> service.saveBracketDraft(List.of(
                    HandlingFeeBracketDto.builder()
                            .upperLimit(new BigDecimal("100000"))
                            .feeAmount(new BigDecimal("-500"))
                            .build())))
                    .isInstanceOf(ValidationException.class);

            verify(bracketRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("ITEM 3: saveBracketDraft üres sorral ([{}]) → ValidationException, nem DataIntegrityViolationException")
    void saveBracketDraft_UresSort_Elutasit() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");

            assertThatThrownBy(() -> service.saveBracketDraft(List.of(new HandlingFeeBracketDto())))
                    .isInstanceOf(ValidationException.class)
                    .isNotInstanceOf(org.springframework.dao.DataIntegrityViolationException.class);

            verify(bracketRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("ITEM 3: saveBracketDraft MINDEN hibás sort EGY hibaüzenetben jelent (batch)")
    void saveBracketDraft_MindenHibasSortEgyszerreJelent() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("KOSA");

            assertThatThrownBy(() -> service.saveBracketDraft(List.of(
                    HandlingFeeBracketDto.builder()
                            .upperLimit(BigDecimal.ZERO)
                            .feeAmount(new BigDecimal("100"))
                            .build(),
                    HandlingFeeBracketDto.builder()
                            .upperLimit(new BigDecimal("100000"))
                            .feeAmount(null)
                            .build())))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("1.")
                    .hasMessageContaining("2.");

            verify(bracketRepository, never()).save(any());
        }
    }

    // ============================ HELPEREK ============================

    private static BranchFeeConfigDraftRequest draftRequest(String feeMode,
                                                            BigDecimal rate, BigDecimal cap) {
        BranchFeeConfigDraftRequest req = new BranchFeeConfigDraftRequest();
        req.setFeeMode(feeMode);
        req.setPerMilleRate(rate);
        req.setPerMilleCap(cap);
        return req;
    }

    private static BranchHandlingFeeConfig liveConfig(HandlingFeeType mode, BigDecimal rate,
                                                      BigDecimal cap, long version) {
        BranchHandlingFeeConfig config = BranchHandlingFeeConfig.builder()
                .id(UUID.randomUUID())
                .companyId(COMPANY_ID)
                .branchId(BRANCH_ID)
                .feeMode(mode)
                .perMilleRate(rate)
                .perMilleCap(cap)
                .status(FeeConfigStatus.LIVE)
                .active(true)
                .build();
        config.setVersion(version);
        return config;
    }

    private static BranchHandlingFeeConfig draftConfig(HandlingFeeType mode, BigDecimal rate,
                                                       BigDecimal cap, long version) {
        BranchHandlingFeeConfig config = BranchHandlingFeeConfig.builder()
                .id(UUID.randomUUID())
                .companyId(COMPANY_ID)
                .branchId(BRANCH_ID)
                .feeMode(mode)
                .perMilleRate(rate)
                .perMilleCap(cap)
                .status(FeeConfigStatus.DRAFT)
                .active(true)
                .build();
        config.setVersion(version);
        return config;
    }

    private static Branch branch() {
        return Branch.builder()
                .id(BRANCH_ID)
                .code("B01")
                .name("Test branch")
                .build();
    }

    private static SystemParameter parameter(String key, String value) {
        SystemParameter parameter = new SystemParameter();
        parameter.setParameterKey(key);
        parameter.setParameterValue(value);
        parameter.setIsActive(true);
        return parameter;
    }
}
