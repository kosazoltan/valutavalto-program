package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.RatePublication;
import hu.puzzleir.valuta.entity.RateTemplate;
import hu.puzzleir.valuta.entity.RateWorkgroup;
import hu.puzzleir.valuta.entity.SyncOutboxEvent;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.RatePublicationRepository;
import hu.puzzleir.valuta.repository.RateTemplateRepository;
import hu.puzzleir.valuta.repository.RateWorkgroupRepository;
import hu.puzzleir.valuta.repository.SyncOutboxRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RatePublishServiceTest {

    @Mock
    private RateTemplateRepository templateRepository;

    @Mock
    private RateWorkgroupRepository workgroupRepository;

    @Mock
    private RatePublicationRepository publicationRepository;

    @Mock
    private CurrencyRepository currencyRepository;

    @Mock
    private ExchangeRateRepository exchangeRateRepository;

    @Mock
    private SyncOutboxRepository syncOutboxRepository;

    @Mock
    private hu.puzzleir.valuta.repository.WorkerRepository workerRepository;

    @Spy
    private ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @InjectMocks
    private RatePublishService service;

    // Az autentikált munkás cége — a tenant-IDOR ellenőrzéshez a workgroup ehhez kötött kell legyen.
    private UUID authCompanyId;
    private UUID authBranchId;

    @BeforeEach
    void setUpAuthContext() {
        authCompanyId = UUID.randomUUID();
        authBranchId = UUID.randomUUID();

        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken("WORKER001", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(99L, authCompanyId, authBranchId, "MANAGER"));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void clearAuthContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("FR-HL-11: getPublicationAuditHistory feloldja a módosító NEVÉT a workerId-ból")
    void getPublicationAuditHistory_resolvesWorkerName() {
        RatePublication pub = RatePublication.builder()
                .id(UUID.randomUUID())
                .companyId(authCompanyId)
                .workgroupId(UUID.randomUUID())
                .publishedBy(99L)
                .affectedBranches(3)
                .build();
        when(publicationRepository.findTop20ByCompanyIdOrderByPublishedAtDesc(authCompanyId))
                .thenReturn(List.of(pub));
        // A worker az AKTUÁLIS cégbe tartozik (multi-tenant szűrés feltétele a név-feloldáshoz).
        Company workerCompany = Company.builder().id(authCompanyId).code("BEST").build();
        hu.puzzleir.valuta.entity.Worker worker = hu.puzzleir.valuta.entity.Worker.builder()
                .id(99L).name("Kovács János").company(workerCompany).build();
        when(workerRepository.findAllById(any())).thenReturn(List.of(worker));

        var result = service.getPublicationAuditHistory(null);

        assertEquals(1, result.size());
        assertEquals("Kovács János", result.get(0).publishedByName());
        assertEquals(99L, result.get(0).publishedBy());
        assertEquals(3, result.get(0).affectedBranches());
    }

    @Test
    @DisplayName("FR-HL-11: ismeretlen/törölt worker → '#<id>' fallback név")
    void getPublicationAuditHistory_unknownWorker_fallback() {
        RatePublication pub = RatePublication.builder()
                .id(UUID.randomUUID())
                .companyId(authCompanyId)
                .workgroupId(UUID.randomUUID())
                .publishedBy(42L)
                .build();
        when(publicationRepository.findTop20ByCompanyIdOrderByPublishedAtDesc(authCompanyId))
                .thenReturn(List.of(pub));
        when(workerRepository.findAllById(any())).thenReturn(List.of());

        var result = service.getPublicationAuditHistory(null);

        assertEquals("#42", result.get(0).publishedByName());
    }

    @Test
    @DisplayName("publish enqueues RATE_PUBLISHED outbox event with expected payload")
    void publish_enqueuesRatePublishedOutboxEvent() throws Exception {
        UUID workgroupId = UUID.randomUUID();
        UUID templateId = UUID.randomUUID();
        UUID companyId = authCompanyId;
        UUID branchId = UUID.randomUUID();

        Company company = Company.builder()
                .id(companyId)
                .code("BEST")
                .name("Best Change")
                .build();

        Branch branch = Branch.builder()
                .id(branchId)
                .code("BORSI")
                .company(company)
                .build();

        RateWorkgroup workgroup = RateWorkgroup.builder()
                .id(workgroupId)
                .name("Main WG")
                .code("WG-1")
                .company(company)
                .branches(Set.of(branch))
                .build();

        RateTemplate template = RateTemplate.builder()
                .id(templateId)
                .workgroupId(workgroupId)
                .currencyId(1L)
                .baseBuyRate(new BigDecimal("395.1000"))
                .baseSellRate(new BigDecimal("398.1000"))
                .buySpread(new BigDecimal("0.2000"))
                .sellSpread(new BigDecimal("0.3000"))
                .roundingRule(1)
                .status(RateTemplate.RateTemplateStatus.APPROVED)
                .build();

        Currency eur = Currency.builder()
                .id(1L)
                .code("EUR")
                .name("Euro")
                .build();

        when(workgroupRepository.findById(workgroupId)).thenReturn(Optional.of(workgroup));
        when(templateRepository.findById(templateId)).thenReturn(Optional.of(template));
        when(templateRepository.save(any(RateTemplate.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(eur));
        when(exchangeRateRepository.findCurrentRate(companyId, 1L, branchId)).thenReturn(List.of());
        when(exchangeRateRepository.findActiveBranchRates(companyId, 1L, branchId)).thenReturn(List.of());
        when(exchangeRateRepository.save(any(ExchangeRate.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(publicationRepository.save(any(RatePublication.class))).thenAnswer(invocation -> {
            RatePublication p = invocation.getArgument(0);
            if (p.getId() == null) {
                p.setId(UUID.randomUUID());
            }
            return p;
        });
        when(syncOutboxRepository.save(any(SyncOutboxEvent.class))).thenAnswer(invocation -> invocation.getArgument(0));

        RatePublication publication = service.publish(workgroupId, List.of(templateId), "daily publish");

        assertNotNull(publication.getId());

        ArgumentCaptor<SyncOutboxEvent> outboxCaptor = ArgumentCaptor.forClass(SyncOutboxEvent.class);
        verify(syncOutboxRepository, times(1)).save(outboxCaptor.capture());

        SyncOutboxEvent outboxEvent = outboxCaptor.getValue();
        assertEquals("RATE_PUBLICATION", outboxEvent.getAggregateType());
        assertEquals("RATE_PUBLISHED", outboxEvent.getEventType());
        assertEquals(SyncOutboxEvent.SyncOutboxStatus.PENDING, outboxEvent.getStatus());
        assertEquals(publication.getId().toString(), outboxEvent.getAggregateId());
        assertNotNull(outboxEvent.getIdempotencyKey());

        JsonNode payload = objectMapper.readTree(outboxEvent.getPayload());
        assertEquals(workgroupId.toString(), payload.get("workgroupId").asText());
        assertTrue(payload.get("branchCodes").isArray());
        assertEquals("BORSI", payload.get("branchCodes").get(0).asText());
        assertTrue(payload.get("rates").isArray());
        assertEquals("EUR", payload.get("rates").get(0).get("currencyCode").asText());

        verify(exchangeRateRepository, times(1)).findCurrentRate(companyId, 1L, branchId);
        verify(exchangeRateRepository, times(1)).findActiveBranchRates(companyId, 1L, branchId);
        verify(exchangeRateRepository, times(1)).save(any(ExchangeRate.class));
        verify(templateRepository, times(1)).save(eq(template));
    }

    @Test
    @DisplayName("publish keeps global fallback rate active when writing branch-specific rate")
    void publish_keepsGlobalFallbackActive() {
        UUID workgroupId = UUID.randomUUID();
        UUID templateId = UUID.randomUUID();
        UUID companyId = authCompanyId;
        UUID branchId = UUID.randomUUID();

        Company company = Company.builder()
                .id(companyId)
                .code("BEST")
                .name("Best Change")
                .build();

        Branch branch = Branch.builder()
                .id(branchId)
                .code("BORSI")
                .company(company)
                .build();

        RateWorkgroup workgroup = RateWorkgroup.builder()
                .id(workgroupId)
                .name("Main WG")
                .code("WG-1")
                .company(company)
                .branches(Set.of(branch))
                .build();

        RateTemplate template = RateTemplate.builder()
                .id(templateId)
                .workgroupId(workgroupId)
                .currencyId(1L)
                .baseBuyRate(new BigDecimal("395.1000"))
                .baseSellRate(new BigDecimal("398.1000"))
                .buySpread(new BigDecimal("0.2000"))
                .sellSpread(new BigDecimal("0.3000"))
                .roundingRule(1)
                .status(RateTemplate.RateTemplateStatus.APPROVED)
                .build();

        Currency eur = Currency.builder()
                .id(1L)
                .code("EUR")
                .name("Euro")
                .build();

        ExchangeRate globalFallback = ExchangeRate.builder()
                .company(company)
                .branch(null)
                .currency(eur)
                .officialRate(new BigDecimal("396.5000"))
                .active(true)
                .build();

        when(workgroupRepository.findById(workgroupId)).thenReturn(Optional.of(workgroup));
        when(templateRepository.findById(templateId)).thenReturn(Optional.of(template));
        when(templateRepository.save(any(RateTemplate.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(eur));
        when(exchangeRateRepository.findCurrentRate(companyId, 1L, branchId)).thenReturn(List.of(globalFallback));
        when(exchangeRateRepository.findActiveBranchRates(companyId, 1L, branchId)).thenReturn(List.of());
        when(exchangeRateRepository.save(any(ExchangeRate.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(publicationRepository.save(any(RatePublication.class))).thenAnswer(invocation -> {
            RatePublication p = invocation.getArgument(0);
            if (p.getId() == null) {
                p.setId(UUID.randomUUID());
            }
            return p;
        });
        when(syncOutboxRepository.save(any(SyncOutboxEvent.class))).thenAnswer(invocation -> invocation.getArgument(0));

        service.publish(workgroupId, List.of(templateId), "daily publish");

        assertTrue(globalFallback.getActive());

        ArgumentCaptor<ExchangeRate> rateCaptor = ArgumentCaptor.forClass(ExchangeRate.class);
        verify(exchangeRateRepository, times(1)).save(rateCaptor.capture());
        ExchangeRate savedRate = rateCaptor.getValue();
        assertEquals(branchId, savedRate.getBranch().getId());
        assertFalse(savedRate == globalFallback);
    }

    @Test
    @DisplayName("publish NULL státuszú sablonra ValidationException-t dob (NPE helyett) — nullable status guard")
    void publish_nullStatusTemplate_throwsValidationNotNpe() {
        UUID workgroupId = UUID.randomUUID();
        UUID templateId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();

        Company company = Company.builder().id(authCompanyId).code("BEST").name("Best Change").build();
        Branch branch = Branch.builder().id(branchId).code("BORSI").company(company).build();
        RateWorkgroup workgroup = RateWorkgroup.builder()
                .id(workgroupId).name("Main WG").code("WG-1").company(company).branches(Set.of(branch)).build();

        // status szándékosan NULL (nullable oszlop, csak DEFAULT 'DRAFT' van)
        RateTemplate template = RateTemplate.builder()
                .id(templateId)
                .workgroupId(workgroupId)
                .currencyId(1L)
                .baseBuyRate(new BigDecimal("395.1000"))
                .baseSellRate(new BigDecimal("398.1000"))
                .status(null)
                .build();

        when(workgroupRepository.findById(workgroupId)).thenReturn(Optional.of(workgroup));
        when(templateRepository.findById(templateId)).thenReturn(Optional.of(template));

        ValidationException ex = assertThrows(ValidationException.class,
                () -> service.publish(workgroupId, List.of(templateId), "publish null"));
        assertTrue(ex.getMessage().contains("publikálható"),
                "A hibaüzenetnek a publikálhatóságra kell utalnia, üzenet: " + ex.getMessage());
    }

    // ============================================================
    // Multi-tenant IDOR — audit 2026-05-31 (P0)
    // ============================================================

    @Test
    @DisplayName("IDOR: másik cég workgroup-ja → 'nem található' (cross-tenant publish blokkolva)")
    void publish_foreignWorkgroup_throwsNotFound() {
        UUID workgroupId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        // A workgroup egy IDEGEN céghez tartozik (nem az auth company)
        Company foreign = Company.builder().id(UUID.randomUUID()).code("OTHER").name("Más Kft.").build();
        Branch branch = Branch.builder().id(branchId).code("BORSI").company(foreign).build();
        RateWorkgroup workgroup = RateWorkgroup.builder()
                .id(workgroupId).name("Foreign WG").code("WG-X").company(foreign).branches(Set.of(branch)).build();
        when(workgroupRepository.findById(workgroupId)).thenReturn(Optional.of(workgroup));

        ValidationException ex = assertThrows(ValidationException.class,
                () -> service.publish(workgroupId, List.of(UUID.randomUUID()), "cross-tenant"));
        assertTrue(ex.getMessage().contains("Munkacsoport nem található"),
                "id-enumeráció ellen ugyanaz a 'nem található' üzenet kell, kapott: " + ex.getMessage());
        // Semmilyen rátát nem írt és nem publikált idegen irodákra
        verify(exchangeRateRepository, org.mockito.Mockito.never()).save(any(ExchangeRate.class));
        verify(syncOutboxRepository, org.mockito.Mockito.never()).save(any(SyncOutboxEvent.class));
    }

    @Test
    @DisplayName("IDOR: a saját workgroup-hoz NEM tartozó sablon → 'Sablon nem található'")
    void publish_templateFromOtherWorkgroup_throwsNotFound() {
        UUID workgroupId = UUID.randomUUID();
        UUID otherWorkgroupId = UUID.randomUUID();
        UUID templateId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        Company company = Company.builder().id(authCompanyId).code("BEST").name("Best Change").build();
        Branch branch = Branch.builder().id(branchId).code("BORSI").company(company).build();
        RateWorkgroup workgroup = RateWorkgroup.builder()
                .id(workgroupId).name("Main WG").code("WG-1").company(company).branches(Set.of(branch)).build();
        // A sablon egy MÁSIK workgroup-hoz tartozik (akár másik cég sablonja is)
        RateTemplate template = RateTemplate.builder()
                .id(templateId).workgroupId(otherWorkgroupId).currencyId(1L)
                .baseBuyRate(new BigDecimal("395.0000")).baseSellRate(new BigDecimal("398.0000"))
                .status(RateTemplate.RateTemplateStatus.APPROVED).build();
        when(workgroupRepository.findById(workgroupId)).thenReturn(Optional.of(workgroup));
        when(templateRepository.findById(templateId)).thenReturn(Optional.of(template));

        ValidationException ex = assertThrows(ValidationException.class,
                () -> service.publish(workgroupId, List.of(templateId), "wrong wg"));
        assertTrue(ex.getMessage().contains("Sablon nem található"), "kapott: " + ex.getMessage());
        verify(exchangeRateRepository, org.mockito.Mockito.never()).save(any(ExchangeRate.class));
    }

    // ============================================================
    // FK-04/E.2 — árfolyamvédelem-validáció tesztek
    // ============================================================

    private RateWorkgroup wgWithProtection(UUID id, UUID companyId, UUID branchId, boolean protectionEnabled, Integer groupNum) {
        Company company = Company.builder().id(companyId).code("BEST").name("Best Change").build();
        Branch branch = Branch.builder().id(branchId).code("BORSI").company(company).build();
        return RateWorkgroup.builder()
                .id(id).name("WG").code("WG-1").legacyGroupNumber(groupNum).company(company)
                .protectionEnabled(protectionEnabled).branches(Set.of(branch)).build();
    }

    private RateTemplate tplWithRates(UUID id, UUID workgroupId, Long currencyId,
                                      BigDecimal officialJ, BigDecimal buyL, BigDecimal sellM) {
        return RateTemplate.builder()
                .id(id).workgroupId(workgroupId).currencyId(currencyId)
                .baseBuyRate(buyL).baseSellRate(sellM).officialRate(officialJ)
                .buySpread(BigDecimal.ZERO).sellSpread(BigDecimal.ZERO).roundingRule(1)
                .status(RateTemplate.RateTemplateStatus.APPROVED).build();
    }

    @Test
    @DisplayName("FK-04/E.2: védelem KI → magas vételi ráta publikálható (validáció kihagyva)")
    void protection_off_allowsBuyAboveJ() {
        UUID wgId = UUID.randomUUID(); UUID tplId = UUID.randomUUID();
        UUID companyId = ((WorkerAuthenticationDetails) SecurityContextHolder.getContext().getAuthentication().getDetails()).getCompanyId();
        UUID branchId = UUID.randomUUID();
        RateWorkgroup wg = wgWithProtection(wgId, companyId, branchId, false, 3);
        // baseBuyRate (400) > officialRate (395) — sértő, DE protection=false → nem dob
        RateTemplate tpl = tplWithRates(tplId, wgId, 1L,
                new BigDecimal("395.00"), new BigDecimal("400.00"), new BigDecimal("405.00"));
        when(workgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));
        when(templateRepository.findById(tplId)).thenReturn(Optional.of(tpl));
        when(templateRepository.save(any(RateTemplate.class))).thenAnswer(i -> i.getArgument(0));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(Currency.builder().id(1L).code("EUR").name("Euro").build()));
        when(exchangeRateRepository.findCurrentRate(any(), eq(1L), any())).thenReturn(List.of());
        when(exchangeRateRepository.findActiveBranchRates(any(), eq(1L), any())).thenReturn(List.of());
        when(exchangeRateRepository.save(any(ExchangeRate.class))).thenAnswer(i -> i.getArgument(0));
        when(publicationRepository.save(any(RatePublication.class))).thenAnswer(i -> {
            RatePublication p = i.getArgument(0); if (p.getId() == null) p.setId(UUID.randomUUID()); return p;
        });
        when(syncOutboxRepository.save(any(SyncOutboxEvent.class))).thenAnswer(i -> i.getArgument(0));

        RatePublication pub = service.publish(wgId, List.of(tplId), "off");
        assertNotNull(pub.getId());
    }

    @Test
    @DisplayName("FK-04/E.2: védelem BE + vételi > J → ValidationException magyar üzenettel")
    void protection_on_buyAboveJ_throws() {
        UUID wgId = UUID.randomUUID(); UUID tplId = UUID.randomUUID();
        UUID companyId = ((WorkerAuthenticationDetails) SecurityContextHolder.getContext().getAuthentication().getDetails()).getCompanyId();
        UUID branchId = UUID.randomUUID();
        RateWorkgroup wg = wgWithProtection(wgId, companyId, branchId, true, 3);
        RateTemplate tpl = tplWithRates(tplId, wgId, 1L,
                new BigDecimal("395.00"), new BigDecimal("400.00"), new BigDecimal("405.00")); // L > J
        when(workgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));
        when(templateRepository.findById(tplId)).thenReturn(Optional.of(tpl));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(
                Currency.builder().id(1L).code("EUR").name("Euro").build()));

        ValidationException ex = assertThrows(ValidationException.class,
                () -> service.publish(wgId, List.of(tplId), "on"));
        assertTrue(ex.getMessage().contains("3-es csoport"), "groupLabel hibás: " + ex.getMessage());
        assertTrue(ex.getMessage().contains("EUR"), "currency code hiányzik: " + ex.getMessage());
        assertTrue(ex.getMessage().contains("magasabb az elszámolónál"),
                "magyar 'magasabb' szöveg hibás: " + ex.getMessage());
    }

    @Test
    @DisplayName("FK-04/E.2: védelem BE + eladási < J → ValidationException 'alacsonyabb' üzenettel")
    void protection_on_sellBelowJ_throws() {
        UUID wgId = UUID.randomUUID(); UUID tplId = UUID.randomUUID();
        UUID companyId = ((WorkerAuthenticationDetails) SecurityContextHolder.getContext().getAuthentication().getDetails()).getCompanyId();
        UUID branchId = UUID.randomUUID();
        RateWorkgroup wg = wgWithProtection(wgId, companyId, branchId, true, 7);
        RateTemplate tpl = tplWithRates(tplId, wgId, 1L,
                new BigDecimal("400.00"), new BigDecimal("395.00"), new BigDecimal("390.00")); // M < J
        when(workgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));
        when(templateRepository.findById(tplId)).thenReturn(Optional.of(tpl));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(
                Currency.builder().id(1L).code("EUR").name("Euro").build()));

        ValidationException ex = assertThrows(ValidationException.class,
                () -> service.publish(wgId, List.of(tplId), "on"));
        assertTrue(ex.getMessage().contains("7-es csoport"), "groupLabel hibás: " + ex.getMessage());
        assertTrue(ex.getMessage().contains("alacsonyabb az elszámolónál"),
                "magyar 'alacsonyabb' szöveg hibás: " + ex.getMessage());
    }

    @Test
    @DisplayName("FK-04/E.2: védelem BE + minden ráta J körül (L≤J≤M) → publikálható")
    void protection_on_validRates_succeeds() {
        UUID wgId = UUID.randomUUID(); UUID tplId = UUID.randomUUID();
        UUID companyId = ((WorkerAuthenticationDetails) SecurityContextHolder.getContext().getAuthentication().getDetails()).getCompanyId();
        UUID branchId = UUID.randomUUID();
        RateWorkgroup wg = wgWithProtection(wgId, companyId, branchId, true, 1);
        // L=395 ≤ J=400 ≤ M=405 — minden szabály betartva
        RateTemplate tpl = tplWithRates(tplId, wgId, 1L,
                new BigDecimal("400.00"), new BigDecimal("395.00"), new BigDecimal("405.00"));
        when(workgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));
        when(templateRepository.findById(tplId)).thenReturn(Optional.of(tpl));
        when(templateRepository.save(any(RateTemplate.class))).thenAnswer(i -> i.getArgument(0));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(Currency.builder().id(1L).code("EUR").name("Euro").build()));
        when(exchangeRateRepository.findCurrentRate(any(), eq(1L), any())).thenReturn(List.of());
        when(exchangeRateRepository.findActiveBranchRates(any(), eq(1L), any())).thenReturn(List.of());
        when(exchangeRateRepository.save(any(ExchangeRate.class))).thenAnswer(i -> i.getArgument(0));
        when(publicationRepository.save(any(RatePublication.class))).thenAnswer(i -> {
            RatePublication p = i.getArgument(0); if (p.getId() == null) p.setId(UUID.randomUUID()); return p;
        });
        when(syncOutboxRepository.save(any(SyncOutboxEvent.class))).thenAnswer(i -> i.getArgument(0));

        RatePublication pub = service.publish(wgId, List.of(tplId), "ok");
        assertNotNull(pub.getId());
    }

    @Test
    @DisplayName("FK-04/E.2: védelem BE + sell=0 (nem beállított) → NEM dob (frontend-parity signum-skip)")
    void protection_on_zeroSell_skipped() {
        UUID wgId = UUID.randomUUID(); UUID tplId = UUID.randomUUID();
        UUID companyId = ((WorkerAuthenticationDetails) SecurityContextHolder.getContext().getAuthentication().getDetails()).getCompanyId();
        UUID branchId = UUID.randomUUID();
        RateWorkgroup wg = wgWithProtection(wgId, companyId, branchId, true, 1);
        // sell=0 < J=400 lenne, DE a 0 = nem beállított → a védelem kihagyja (signum-skip).
        RateTemplate tpl = tplWithRates(tplId, wgId, 1L,
                new BigDecimal("400.00"), new BigDecimal("395.00"), BigDecimal.ZERO);
        when(workgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));
        when(templateRepository.findById(tplId)).thenReturn(Optional.of(tpl));
        when(templateRepository.save(any(RateTemplate.class))).thenAnswer(i -> i.getArgument(0));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(Currency.builder().id(1L).code("EUR").name("Euro").build()));
        when(exchangeRateRepository.findCurrentRate(any(), eq(1L), any())).thenReturn(List.of());
        when(exchangeRateRepository.findActiveBranchRates(any(), eq(1L), any())).thenReturn(List.of());
        when(exchangeRateRepository.save(any(ExchangeRate.class))).thenAnswer(i -> i.getArgument(0));
        when(publicationRepository.save(any(RatePublication.class))).thenAnswer(i -> {
            RatePublication p = i.getArgument(0); if (p.getId() == null) p.setId(UUID.randomUUID()); return p;
        });
        when(syncOutboxRepository.save(any(SyncOutboxEvent.class))).thenAnswer(i -> i.getArgument(0));

        RatePublication pub = service.publish(wgId, List.of(tplId), "zero-sell");
        assertNotNull(pub.getId());
    }

    @Test
    @DisplayName("FK-04/E.2: védelem BE + base≤J DE base+buySpread>J → ValidationException (effektív ráta, Codex #899)")
    void protection_on_effectiveBuyAboveJ_throws() {
        UUID wgId = UUID.randomUUID(); UUID tplId = UUID.randomUUID();
        UUID companyId = ((WorkerAuthenticationDetails) SecurityContextHolder.getContext().getAuthentication().getDetails()).getCompanyId();
        UUID branchId = UUID.randomUUID();
        RateWorkgroup wg = wgWithProtection(wgId, companyId, branchId, true, 3);
        // baseBuyRate=395 ≤ J=400 (a régi check átengedte), DE buySpread=10 → effektív 405 > 400.
        RateTemplate tpl = RateTemplate.builder()
                .id(tplId).workgroupId(wgId).currencyId(1L)
                .baseBuyRate(new BigDecimal("395.00")).baseSellRate(new BigDecimal("405.00"))
                .officialRate(new BigDecimal("400.00"))
                .buySpread(new BigDecimal("10.00")).sellSpread(BigDecimal.ZERO).roundingRule(1)
                .status(RateTemplate.RateTemplateStatus.APPROVED).build();
        when(workgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));
        when(templateRepository.findById(tplId)).thenReturn(Optional.of(tpl));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(
                Currency.builder().id(1L).code("EUR").name("Euro").build()));

        ValidationException ex = assertThrows(ValidationException.class,
                () -> service.publish(wgId, List.of(tplId), "eff"));
        assertTrue(ex.getMessage().contains("magasabb az elszámolónál"),
                "az effektív (base+spread) vételit kell elkapnia: " + ex.getMessage());
    }

    @Test
    @DisplayName("Audit P2 #9: sell ≤ buy (mindkét pozitív) → ValidationException a publish-ban (protection KI is)")
    void publish_invertedRate_throws() {
        UUID wgId = UUID.randomUUID(); UUID tplId = UUID.randomUUID();
        UUID companyId = ((WorkerAuthenticationDetails) SecurityContextHolder.getContext().getAuthentication().getDetails()).getCompanyId();
        UUID branchId = UUID.randomUUID();
        RateWorkgroup wg = wgWithProtection(wgId, companyId, branchId, false, 1); // protection KI → csak a sanity fut
        RateTemplate tpl = tplWithRates(tplId, wgId, 1L,
                new BigDecimal("400.00"), new BigDecimal("400.00"), new BigDecimal("395.00")); // sell 395 < buy 400
        when(workgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));
        when(templateRepository.findById(tplId)).thenReturn(Optional.of(tpl));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(
                Currency.builder().id(1L).code("EUR").name("Euro").build()));

        ValidationException ex = assertThrows(ValidationException.class,
                () -> service.publish(wgId, List.of(tplId), "inv"));
        assertTrue(ex.getMessage().contains("Eladási árfolyam nagyobb kell legyen"), ex.getMessage());
    }

    @Test
    @DisplayName("Audit P2 #9: spread > 5% → RateSpreadGate elutasít a publish-ban (publishBatch sem kerüli meg)")
    void publish_spreadOver5pct_throws() {
        UUID wgId = UUID.randomUUID(); UUID tplId = UUID.randomUUID();
        UUID companyId = ((WorkerAuthenticationDetails) SecurityContextHolder.getContext().getAuthentication().getDetails()).getCompanyId();
        UUID branchId = UUID.randomUUID();
        RateWorkgroup wg = wgWithProtection(wgId, companyId, branchId, false, 1);
        // reference J=400, spread (420-380)=40 > 400*0.05=20 → tilos
        RateTemplate tpl = tplWithRates(tplId, wgId, 1L,
                new BigDecimal("400.00"), new BigDecimal("380.00"), new BigDecimal("420.00"));
        when(workgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));
        when(templateRepository.findById(tplId)).thenReturn(Optional.of(tpl));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(
                Currency.builder().id(1L).code("EUR").name("Euro").build()));

        ValidationException ex = assertThrows(ValidationException.class,
                () -> service.publish(wgId, List.of(tplId), "wide"));
        assertTrue(ex.getMessage().toLowerCase().contains("spread"), ex.getMessage());
    }

    @Test
    @DisplayName("Audit P2 #8: NULL buy/sell spread (DB-hidratált sablon) → buildRateUpdateMessage NEM NPE-zik")
    void publish_nullSpread_noNpe() {
        UUID wgId = UUID.randomUUID(); UUID tplId = UUID.randomUUID();
        UUID companyId = ((WorkerAuthenticationDetails) SecurityContextHolder.getContext().getAuthentication().getDetails()).getCompanyId();
        UUID branchId = UUID.randomUUID();
        RateWorkgroup wg = wgWithProtection(wgId, companyId, branchId, false, 1);
        RateTemplate tpl = tplWithRates(tplId, wgId, 1L,
                new BigDecimal("400.00"), new BigDecimal("398.00"), new BigDecimal("402.00"));
        tpl.setBuySpread(null);   // @Builder.Default csak builder-konstrukciónál hat — DB-hidratáltnál NULL lehet
        tpl.setSellSpread(null);
        when(workgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));
        when(templateRepository.findById(tplId)).thenReturn(Optional.of(tpl));
        when(templateRepository.save(any(RateTemplate.class))).thenAnswer(i -> i.getArgument(0));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(
                Currency.builder().id(1L).code("EUR").name("Euro").build()));
        when(exchangeRateRepository.findCurrentRate(any(), eq(1L), any())).thenReturn(List.of());
        when(exchangeRateRepository.findActiveBranchRates(any(), eq(1L), any())).thenReturn(List.of());
        when(exchangeRateRepository.save(any(ExchangeRate.class))).thenAnswer(i -> i.getArgument(0));
        when(publicationRepository.save(any(RatePublication.class))).thenAnswer(i -> {
            RatePublication p = i.getArgument(0); if (p.getId() == null) p.setId(UUID.randomUUID()); return p;
        });
        when(syncOutboxRepository.save(any(SyncOutboxEvent.class))).thenAnswer(i -> i.getArgument(0));

        RatePublication pub = service.publish(wgId, List.of(tplId), "null-spread");
        assertNotNull(pub.getId());
    }

    @Test
    @DisplayName("Audit P2 #938: sell-only sablon (buy=0, sell pozitív) → publikálható (spread-kapu NEM utasítja el)")
    void publish_sellOnlyZeroBuy_allowed() {
        UUID wgId = UUID.randomUUID(); UUID tplId = UUID.randomUUID();
        UUID companyId = ((WorkerAuthenticationDetails) SecurityContextHolder.getContext().getAuthentication().getDetails()).getCompanyId();
        UUID branchId = UUID.randomUUID();
        RateWorkgroup wg = wgWithProtection(wgId, companyId, branchId, false, 1);
        // buy=0 ("nem beállított"), sell=405, J=400 — a régi (Codex-előtti) kód 5%+ spreadként dobott.
        RateTemplate tpl = tplWithRates(tplId, wgId, 1L,
                new BigDecimal("400.00"), BigDecimal.ZERO, new BigDecimal("405.00"));
        when(workgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));
        when(templateRepository.findById(tplId)).thenReturn(Optional.of(tpl));
        when(templateRepository.save(any(RateTemplate.class))).thenAnswer(i -> i.getArgument(0));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(
                Currency.builder().id(1L).code("EUR").name("Euro").build()));
        when(exchangeRateRepository.findCurrentRate(any(), eq(1L), any())).thenReturn(List.of());
        when(exchangeRateRepository.findActiveBranchRates(any(), eq(1L), any())).thenReturn(List.of());
        when(exchangeRateRepository.save(any(ExchangeRate.class))).thenAnswer(i -> i.getArgument(0));
        when(publicationRepository.save(any(RatePublication.class))).thenAnswer(i -> {
            RatePublication p = i.getArgument(0); if (p.getId() == null) p.setId(UUID.randomUUID()); return p;
        });
        when(syncOutboxRepository.save(any(SyncOutboxEvent.class))).thenAnswer(i -> i.getArgument(0));

        RatePublication pub = service.publish(wgId, List.of(tplId), "sell-only");
        assertNotNull(pub.getId());
    }

    @Test
    @DisplayName("Audit P2 #938: negatív ráta (érvénytelen input) → ValidationException (NEM kezeljük 'nem beállítottként')")
    void publish_negativeRate_throws() {
        UUID wgId = UUID.randomUUID(); UUID tplId = UUID.randomUUID();
        UUID companyId = ((WorkerAuthenticationDetails) SecurityContextHolder.getContext().getAuthentication().getDetails()).getCompanyId();
        UUID branchId = UUID.randomUUID();
        RateWorkgroup wg = wgWithProtection(wgId, companyId, branchId, false, 1);
        // baseBuyRate = -1 (érvénytelen) — sem nem 'nem beállított' (0), sem nem szabályos pozitív.
        RateTemplate tpl = tplWithRates(tplId, wgId, 1L,
                new BigDecimal("400.00"), new BigDecimal("-1.00"), new BigDecimal("400.00"));
        when(workgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));
        when(templateRepository.findById(tplId)).thenReturn(Optional.of(tpl));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(
                Currency.builder().id(1L).code("EUR").name("Euro").build()));

        ValidationException ex = assertThrows(ValidationException.class,
                () -> service.publish(wgId, List.of(tplId), "neg"));
        assertTrue(ex.getMessage().contains("negatív"), ex.getMessage());
    }

    // === FK-04/E.2 #899-edge (#924): a fallback-J (template.officialRate == NULL) elleni vedelem ===

    @Test
    @DisplayName("FK-04/E.2 #899-edge: védelem BE + NULL officialRate + fallback-J (latestRate) alá eső vétel → ValidationException")
    void protection_on_nullOfficialRate_fallbackJ_buyAbove_throws() {
        UUID wgId = UUID.randomUUID(); UUID tplId = UUID.randomUUID();
        UUID companyId = ((WorkerAuthenticationDetails) SecurityContextHolder.getContext().getAuthentication().getDetails()).getCompanyId();
        UUID branchId = UUID.randomUUID();
        RateWorkgroup wg = wgWithProtection(wgId, companyId, branchId, true, 5);
        // officialRate = NULL → a pre-pass validateRateProtection KIHAGYJA. A publish viszont
        // fallback-J-t rendel a latestRate-ből (395). baseBuy=400 > 395 → a hurok-check elkapja.
        RateTemplate tpl = tplWithRates(tplId, wgId, 1L,
                null, new BigDecimal("400.00"), new BigDecimal("410.00"));
        ExchangeRate latest = ExchangeRate.builder().officialRate(new BigDecimal("395.00")).build();
        when(workgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));
        when(templateRepository.findById(tplId)).thenReturn(Optional.of(tpl));
        when(templateRepository.save(any(RateTemplate.class))).thenAnswer(i -> i.getArgument(0));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(
                Currency.builder().id(1L).code("EUR").name("Euro").build()));
        when(exchangeRateRepository.findCurrentRate(any(), eq(1L), any())).thenReturn(List.of(latest));
        when(exchangeRateRepository.findActiveBranchRates(any(), eq(1L), any())).thenReturn(List.of());

        ValidationException ex = assertThrows(ValidationException.class,
                () -> service.publish(wgId, List.of(tplId), "fallback-J"));
        assertTrue(ex.getMessage().contains("5-es csoport"), "groupLabel: " + ex.getMessage());
        assertTrue(ex.getMessage().contains("EUR"), "currency: " + ex.getMessage());
        assertTrue(ex.getMessage().contains("magasabb az elszámolónál"), "üzenet: " + ex.getMessage());
    }

    @Test
    @DisplayName("FK-04/E.2 #899-edge: védelem BE + NULL officialRate + midpoint-fallback szabályos ráta → publikálható (nincs false-positive)")
    void protection_on_nullOfficialRate_midpointFallback_valid_succeeds() {
        UUID wgId = UUID.randomUUID(); UUID tplId = UUID.randomUUID();
        UUID companyId = ((WorkerAuthenticationDetails) SecurityContextHolder.getContext().getAuthentication().getDetails()).getCompanyId();
        UUID branchId = UUID.randomUUID();
        RateWorkgroup wg = wgWithProtection(wgId, companyId, branchId, true, 6);
        // officialRate=NULL, nincs latestRate → midpoint J=(400+410)/2=405; buy=400≤405 ✓, sell=410≥405 ✓ → szabályos.
        RateTemplate tpl = tplWithRates(tplId, wgId, 1L,
                null, new BigDecimal("400.00"), new BigDecimal("410.00"));
        when(workgroupRepository.findById(wgId)).thenReturn(Optional.of(wg));
        when(templateRepository.findById(tplId)).thenReturn(Optional.of(tpl));
        when(templateRepository.save(any(RateTemplate.class))).thenAnswer(i -> i.getArgument(0));
        when(currencyRepository.findAllById(anyList())).thenReturn(List.of(
                Currency.builder().id(1L).code("EUR").name("Euro").build()));
        when(exchangeRateRepository.findCurrentRate(any(), eq(1L), any())).thenReturn(List.of());
        when(exchangeRateRepository.findActiveBranchRates(any(), eq(1L), any())).thenReturn(List.of());
        when(exchangeRateRepository.save(any(ExchangeRate.class))).thenAnswer(i -> i.getArgument(0));
        when(publicationRepository.save(any(RatePublication.class))).thenAnswer(i -> {
            RatePublication p = i.getArgument(0); if (p.getId() == null) p.setId(UUID.randomUUID()); return p;
        });
        when(syncOutboxRepository.save(any(SyncOutboxEvent.class))).thenAnswer(i -> i.getArgument(0));

        RatePublication pub = service.publish(wgId, List.of(tplId), "midpoint-ok");
        assertNotNull(pub.getId());
    }
}
