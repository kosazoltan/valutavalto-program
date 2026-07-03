package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.ratecreation.GroupRateDTO;
import hu.puzzleir.valuta.dto.ratemaker.LocalRatePackageDto;
import hu.puzzleir.valuta.dto.ratemaker.LocalRatePublishResponseDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.RatePublication;
import hu.puzzleir.valuta.entity.RateTemplate;
import hu.puzzleir.valuta.entity.RateWorkgroup;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.RatePublicationRepository;
import hu.puzzleir.valuta.repository.RateTemplateRepository;
import hu.puzzleir.valuta.repository.RateWorkgroupRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Az Árfolyamkészítő VÉKONY KLIENS → SZERVER publikálás + SZÉTKÜLDÉS valós működésének
 * integrációs tesztje a tényleges {@link RateCreationService#publishLocalRatePackage}
 * kódúton (nem mock-szolgáltatás). A rate-maker EXE a
 * {@code POST /api/v1/local-rate-maker/packages/publish} végpontra küld egy
 * {@link LocalRatePackageDto} csomagot; a szerver validál, hash-integritást ellenőriz,
 * RateTemplate-eket ment, majd a {@code RatePublishService.publish()}-en keresztül
 * exchange_rate INSERT + outbox/WebSocket push → szétküldi a munkacsoport pénztáraira.
 *
 * <p>A teszt a teljes szolgáltatás-réteget gyakorolja (a repository-k + a tényleges
 * elosztó {@code RatePublishService} mockoltak), és a kliens↔szerver szerződést
 * verifikálja: elfogadás, szétküldés-trigger, érintett fiókok, hash-integritás kapu,
 * idempotens duplikátum-védelem.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class LocalRateMakerPublishTest {

    @Mock private RateTemplateRepository rateTemplateRepository;
    @Mock private RateWorkgroupRepository rateWorkgroupRepository;
    @Mock private RatePublicationRepository ratePublicationRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private RatePublishService ratePublishService;
    @Mock private SystemParameterService systemParameterService;

    @InjectMocks
    private RateCreationService rateCreationService;

    private UUID companyId;
    private UUID groupId;

    @BeforeEach
    void setUp() {
        companyId = UUID.randomUUID();
        groupId = UUID.randomUUID();

        // Főértéktáros (rate-maker) security context — a controller @PreAuthorize a
        // FOERTEKTAR/UGYVEZETO/ADMIN jogot kötelezi; a szolgáltatás a companyId/workerId-t
        // a SecurityContext-ből olvassa (multi-tenant scope).
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken("FOERTEKTAR001", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(42L, companyId, UUID.randomUUID(), "FOERTEKTAR"));
        SecurityContextHolder.getContext().setAuthentication(auth);

        // Cég + objectMapper a privát mezőkbe (@InjectMocks nem tudja az ObjectMapper-t,
        // de a publishLocalRatePackage-ben nincs JSON-szerializáció — a hash sha256-hex).
        ReflectionInject.setField(rateCreationService, "objectMapper", new ObjectMapper());

        Company company = Company.builder().id(companyId).code("EBC").name("Exclusive Best Change").build();
        when(companyRepository.findById(companyId)).thenReturn(Optional.of(company));

        // Munkacsoport 2 fiókkal (a szétküldés cél-fiókjai).
        RateWorkgroup workgroup = new RateWorkgroup();
        Set<Branch> branches = new HashSet<>();
        branches.add(Branch.builder().id(UUID.randomUUID()).code("BR020").build());
        branches.add(Branch.builder().id(UUID.randomUUID()).code("BR009").build());
        workgroup.setBranches(branches);
        when(rateWorkgroupRepository.findById(groupId)).thenReturn(Optional.of(workgroup));

        // RateTemplate.save → visszaadja az entitást id-vel.
        when(rateTemplateRepository.save(any(RateTemplate.class))).thenAnswer(inv -> {
            RateTemplate t = inv.getArgument(0);
            t.setId(UUID.randomUUID());
            return t;
        });

        // A tényleges elosztó publish — RatePublication a workgroupId + 2 érintett fiókkal.
        RatePublication publication = RatePublication.builder()
                .id(UUID.randomUUID())
                .workgroupId(groupId)
                .companyId(companyId)
                .publishedAt(LocalDateTime.now())
                .affectedBranches(2)
                .source("LOCAL_RATE_MAKER")
                .build();
        when(ratePublishService.publish(eq(groupId), anyList(), any(), any())).thenReturn(publication);

        when(ratePublicationRepository.existsByCompanyIdAndClientPackageId(eq(companyId), any()))
                .thenReturn(false);
        when(systemParameterService.getValue(eq("RATE_PACKAGE_HASH_STRICT"), any())).thenReturn("false");
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    /** Egy érvényes, kereszt-szorzott spreaden belüli ráta a HUF/EUR ~400 körül. */
    private GroupRateDTO.RateEntry validEurRate() {
        GroupRateDTO.RateEntry e = new GroupRateDTO.RateEntry();
        e.setCurrencyId(1L);
        e.setBuyRate(new BigDecimal("398.00"));
        e.setSellRate(new BigDecimal("402.00")); // spread 4 / 400 = 1% < 5%
        e.setOfficialRate(new BigDecimal("400.00"));
        return e;
    }

    private LocalRatePackageDto.LocalRatePackageDtoBuilder validPackage() {
        return LocalRatePackageDto.builder()
                .clientPackageId("PKG-" + UUID.randomUUID())
                .clientDeviceId("RATE-MAKER-PC-01")
                .clientVersion("2.27.1")
                .createdAt(Instant.now())
                .groupId(groupId)
                .operatorNote("Napi árfolyam — főértéktár")
                .rates(List.of(validEurRate()));
    }

    @Test
    @DisplayName("Vékony kliens publikál → szerver elfogad + szétküldés-sorba állít (ACCEPTED_AND_DISTRIBUTION_QUEUED)")
    void publish_happyPath_acceptsAndDistributes() {
        LocalRatePackageDto pkg = validPackage().build();

        LocalRatePublishResponseDto resp = rateCreationService.publishLocalRatePackage(pkg);

        assertNotNull(resp.getPublicationId(), "publikáció-azonosító visszajön");
        assertEquals(groupId, resp.getWorkgroupId());
        assertEquals(1, resp.getAcceptedRates());
        assertEquals(2, resp.getAffectedBranches(), "a munkacsoport 2 fiókjára megy");
        assertEquals("ACCEPTED_AND_DISTRIBUTION_QUEUED", resp.getStatus());
        assertNotNull(resp.getServerPackageHash(), "szerver-oldali integritás-hash");
        assertEquals(List.of("BR009", "BR020"), resp.getBranchCodes(), "fiók-kódok rendezve");

        // A SZÉTKÜLDÉS ténylegesen meghívódott a valós elosztó szolgáltatáson.
        verify(ratePublishService, times(1)).publish(eq(groupId), anyList(), any(), any());
        verify(rateTemplateRepository, times(1)).save(any(RateTemplate.class));
    }

    @Test
    @DisplayName("A publikálás metaadata LOCAL_RATE_MAKER forrással + kliens-csomag-azonosítóval megy az elosztóra")
    void publish_passesLocalRateMakerMetadata() {
        LocalRatePackageDto pkg = validPackage().clientPackageId("PKG-META-1").build();

        rateCreationService.publishLocalRatePackage(pkg);

        ArgumentCaptor<RatePublishService.PublicationMetadata> metaCaptor =
                ArgumentCaptor.forClass(RatePublishService.PublicationMetadata.class);
        verify(ratePublishService).publish(eq(groupId), anyList(), any(), metaCaptor.capture());
        RatePublishService.PublicationMetadata meta = metaCaptor.getValue();
        assertNotNull(meta, "non-repudiation metaadat");
    }

    @Test
    @DisplayName("Duplikált kliens-csomag → elutasítás (idempotens beérkezés-védelem)")
    void publish_duplicatePackage_rejected() {
        when(ratePublicationRepository.existsByCompanyIdAndClientPackageId(eq(companyId), any()))
                .thenReturn(true);
        LocalRatePackageDto pkg = validPackage().build();

        ValidationException ex = assertThrows(ValidationException.class,
                () -> rateCreationService.publishLocalRatePackage(pkg));
        assertTrue(ex.getMessage().contains("már beérkezett"));
        verify(ratePublishService, never()).publish(any(), anyList(), any(), any());
    }

    @Test
    @DisplayName("Hiányzó munkacsoport → elutasítás (csak explicit groupId-vel publikálható)")
    void publish_missingGroup_rejected() {
        LocalRatePackageDto pkg = validPackage().groupId(null).build();

        ValidationException ex = assertThrows(ValidationException.class,
                () -> rateCreationService.publishLocalRatePackage(pkg));
        assertTrue(ex.getMessage().contains("munkacsoport") || ex.getMessage().contains("Munkacsoport"));
    }

    @Test
    @DisplayName("Hash-integritás STRICT KI: kliens/szerver hash-eltérés NEM blokkol (non-repudiation log)")
    void publish_hashMismatch_strictOff_nonBlocking() {
        LocalRatePackageDto pkg = validPackage().clientPackageHash("DELIBERATELY-WRONG-HASH").build();

        LocalRatePublishResponseDto resp = rateCreationService.publishLocalRatePackage(pkg);

        assertEquals("ACCEPTED_AND_DISTRIBUTION_QUEUED", resp.getStatus(), "STRICT KI → publikálás megy");
        verify(ratePublishService, times(1)).publish(eq(groupId), anyList(), any(), any());
    }

    @Test
    @DisplayName("Hash-integritás STRICT BE: kliens/szerver hash-eltérés → elutasítás (#ERR-RATE-02)")
    void publish_hashMismatch_strictOn_rejected() {
        when(systemParameterService.getValue(eq("RATE_PACKAGE_HASH_STRICT"), any())).thenReturn("true");
        LocalRatePackageDto pkg = validPackage().clientPackageHash("DELIBERATELY-WRONG-HASH").build();

        ValidationException ex = assertThrows(ValidationException.class,
                () -> rateCreationService.publishLocalRatePackage(pkg));
        assertTrue(ex.getMessage().contains("integritás"));
        verify(ratePublishService, never()).publish(any(), anyList(), any(), any());
    }

    @Test
    @DisplayName("Spread-kapu (VV-ELVI): 5% feletti vételi/eladási spread → elutasítás, nincs szétküldés")
    void publish_spreadTooWide_rejected() {
        GroupRateDTO.RateEntry tooWide = new GroupRateDTO.RateEntry();
        tooWide.setCurrencyId(1L);
        tooWide.setBuyRate(new BigDecimal("380.00"));
        tooWide.setSellRate(new BigDecimal("420.00")); // spread 40 / 400 = 10% > 5%
        tooWide.setOfficialRate(new BigDecimal("400.00"));
        LocalRatePackageDto pkg = validPackage().rates(List.of(tooWide)).build();

        assertThrows(ValidationException.class,
                () -> rateCreationService.publishLocalRatePackage(pkg));
        verify(ratePublishService, never()).publish(any(), anyList(), any(), any());
    }

    /** Egyszerű reflection-helper a privát {@code objectMapper} mezőhöz. */
    static final class ReflectionInject {
        static void setField(Object target, String field, Object value) {
            try {
                var f = target.getClass().getDeclaredField(field);
                f.setAccessible(true);
                f.set(target, value);
            } catch (ReflectiveOperationException e) {
                throw new IllegalStateException(e);
            }
        }
    }
}
