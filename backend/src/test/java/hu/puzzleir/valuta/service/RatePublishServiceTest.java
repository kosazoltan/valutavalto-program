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

    @Spy
    private ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @InjectMocks
    private RatePublishService service;

    @BeforeEach
    void setUpAuthContext() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();

        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken("WORKER001", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(99L, companyId, branchId, "MANAGER"));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void clearAuthContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("publish enqueues RATE_PUBLISHED outbox event with expected payload")
    void publish_enqueuesRatePublishedOutboxEvent() throws Exception {
        UUID workgroupId = UUID.randomUUID();
        UUID templateId = UUID.randomUUID();
        UUID companyId = UUID.randomUUID();
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
        UUID companyId = UUID.randomUUID();
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

        Company company = Company.builder().id(UUID.randomUUID()).code("BEST").name("Best Change").build();
        Branch branch = Branch.builder().id(branchId).code("BORSI").company(company).build();
        RateWorkgroup workgroup = RateWorkgroup.builder()
                .id(workgroupId).name("Main WG").code("WG-1").branches(Set.of(branch)).build();

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
    // FK-04/E.2 — árfolyamvédelem-validáció tesztek
    // ============================================================

    private RateWorkgroup wgWithProtection(UUID id, UUID companyId, UUID branchId, boolean protectionEnabled, Integer groupNum) {
        Branch branch = Branch.builder().id(branchId).code("BORSI")
                .company(Company.builder().id(companyId).code("BEST").name("Best Change").build()).build();
        return RateWorkgroup.builder()
                .id(id).name("WG").code("WG-1").legacyGroupNumber(groupNum)
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
}
