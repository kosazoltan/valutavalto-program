package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.entity.DenominationCount;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DenominationCountRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * DenominationCategory és kategória alapú címletezés tesztek.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DenominationCategoryTest {

    @Mock
    private DenominationRepository denominationRepository;

    @Mock
    private DenominationCountRepository denominationCountRepository;

    @Mock
    private CurrencyRepository currencyRepository;

    @Mock
    private CompanyRepository companyRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock private DenominationAllowedRepository denominationAllowedRepository;
    @InjectMocks
    private DenominationService denominationService;

    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID SESSION_ID = UUID.randomUUID();
    private static final Long WORKER_ID = 42L;

    @BeforeEach
    void setUp() {
        hu.puzzleir.valuta.security.WorkerAuthenticationDetails details =
            new hu.puzzleir.valuta.security.WorkerAuthenticationDetails(
                WORKER_ID, COMPANY_ID, BRANCH_ID, "ADMIN");
        TestingAuthenticationToken auth = new TestingAuthenticationToken("test", "pass", "ROLE_ADMIN");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // ============ ENUM TESZTEK ============

    @Nested
    @DisplayName("DenominationCategory enum")
    class EnumTests {

        @Test
        @DisplayName("Összes kategória megvan")
        void allCategoriesExist() {
            assertThat(DenominationCategory.values()).hasSize(9);
        }

        @Test
        @DisplayName("Legacy sorszám mapping helyes")
        void legacySorszamMapping() {
            assertThat(DenominationCategory.EVENING.getLegacyCimletSorszam()).isEqualTo(1);
            assertThat(DenominationCategory.HANDLING_FEE.getLegacyCimletSorszam()).isEqualTo(2);
            assertThat(DenominationCategory.WESTERN_UNION.getLegacyCimletSorszam()).isEqualTo(3);
            assertThat(DenominationCategory.VAT.getLegacyCimletSorszam()).isEqualTo(4);
            assertThat(DenominationCategory.DEPOSIT.getLegacyCimletSorszam()).isEqualTo(5);
            assertThat(DenominationCategory.ECOMMERCE.getLegacyCimletSorszam()).isEqualTo(6);
            assertThat(DenominationCategory.AXA.getLegacyCimletSorszam()).isEqualTo(7);
            assertThat(DenominationCategory.MONEYGRAM.getLegacyCimletSorszam()).isEqualTo(8);
            assertThat(DenominationCategory.OTHER.getLegacyCimletSorszam()).isEqualTo(9);
        }

        @Test
        @DisplayName("fromLegacySorszam helyes konverzió")
        void fromLegacySorszamWorks() {
            assertThat(DenominationCategory.fromLegacySorszam(1)).isEqualTo(DenominationCategory.EVENING);
            assertThat(DenominationCategory.fromLegacySorszam(3)).isEqualTo(DenominationCategory.WESTERN_UNION);
            assertThat(DenominationCategory.fromLegacySorszam(8)).isEqualTo(DenominationCategory.MONEYGRAM);
        }

        @Test
        @DisplayName("fromLegacySorszam ismeretlen kód exception-t dob")
        void fromLegacySorszamInvalidThrows() {
            assertThatThrownBy(() -> DenominationCategory.fromLegacySorszam(99))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("99");
        }

        @Test
        @DisplayName("fromString helyes konverzió")
        void fromStringWorks() {
            assertThat(DenominationCategory.fromString("EVENING")).isEqualTo(DenominationCategory.EVENING);
            assertThat(DenominationCategory.fromString("handling_fee")).isEqualTo(DenominationCategory.HANDLING_FEE);
            assertThat(DenominationCategory.fromString("Western_Union")).isEqualTo(DenominationCategory.WESTERN_UNION);
        }

        @Test
        @DisplayName("fromString null/blank esetén EVENING-et ad vissza")
        void fromStringNullDefaultsToEvening() {
            assertThat(DenominationCategory.fromString(null)).isEqualTo(DenominationCategory.EVENING);
            assertThat(DenominationCategory.fromString("")).isEqualTo(DenominationCategory.EVENING);
            assertThat(DenominationCategory.fromString("  ")).isEqualTo(DenominationCategory.EVENING);
        }

        @Test
        @DisplayName("fromString ismeretlen érték exception-t dob")
        void fromStringInvalidThrows() {
            assertThatThrownBy(() -> DenominationCategory.fromString("INVALID"))
                .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        @DisplayName("displayName helyes")
        void displayNamesCorrect() {
            assertThat(DenominationCategory.EVENING.getDisplayName()).isEqualTo("Esti pénztárállomány");
            assertThat(DenominationCategory.HANDLING_FEE.getDisplayName()).isEqualTo("Kezelési díj");
            assertThat(DenominationCategory.VAT.getDisplayName()).isEqualTo("ÁFA");
        }
    }

    // ============ ENTITY TESZTEK ============

    @Nested
    @DisplayName("DenominationCount entity kategória támogatás")
    class EntityTests {

        @Test
        @DisplayName("Alapértelmezett kategória EVENING")
        void defaultCategoryIsEvening() {
            DenominationCount count = DenominationCount.builder()
                .branchId(BRANCH_ID)
                .sessionId(SESSION_ID)
                .currencyCode("HUF")
                .faceValue(new BigDecimal("10000"))
                .quantity(5)
                .build();

            assertThat(count.getDenominationCategory()).isEqualTo(DenominationCategory.EVENING);
        }

        @Test
        @DisplayName("Kategória explicit beállítás")
        void explicitCategorySet() {
            DenominationCount count = DenominationCount.builder()
                .branchId(BRANCH_ID)
                .sessionId(SESSION_ID)
                .currencyCode("HUF")
                .faceValue(new BigDecimal("5000"))
                .quantity(3)
                .denominationCategory(DenominationCategory.HANDLING_FEE)
                .build();

            assertThat(count.getDenominationCategory()).isEqualTo(DenominationCategory.HANDLING_FEE);
        }

        @Test
        @DisplayName("Különböző kategóriájú DenominationCount-ok egyedileg kezelhetők")
        void differentCategoriesAreDistinct() {
            DenominationCount evening = DenominationCount.builder()
                .branchId(BRANCH_ID)
                .sessionId(SESSION_ID)
                .currencyCode("HUF")
                .faceValue(new BigDecimal("10000"))
                .quantity(10)
                .denominationCategory(DenominationCategory.EVENING)
                .build();

            DenominationCount handlingFee = DenominationCount.builder()
                .branchId(BRANCH_ID)
                .sessionId(SESSION_ID)
                .currencyCode("HUF")
                .faceValue(new BigDecimal("10000"))
                .quantity(2)
                .denominationCategory(DenominationCategory.HANDLING_FEE)
                .build();

            assertThat(evening.getDenominationCategory())
                .isNotEqualTo(handlingFee.getDenominationCategory());
            assertThat(evening.getQuantity()).isNotEqualTo(handlingFee.getQuantity());
        }
    }

    // ============ SERVICE TESZTEK ============

    @Nested
    @DisplayName("DenominationService.recordDenomination")
    class RecordDenominationTests {

        @Test
        @DisplayName("Sikeres címletezés rögzítés több valutával")
        void recordDenominationSuccess() {
            when(denominationCountRepository.save(any(DenominationCount.class)))
                .thenAnswer(inv -> {
                    DenominationCount dc = inv.getArgument(0);
                    dc.setId(UUID.randomUUID());
                    return dc;
                });

            Map<String, Map<Integer, Integer>> denomCounts = new LinkedHashMap<>();
            Map<Integer, Integer> hufCounts = new LinkedHashMap<>();
            hufCounts.put(10000, 5);
            hufCounts.put(5000, 3);
            hufCounts.put(1000, 10);
            denomCounts.put("HUF", hufCounts);

            Map<Integer, Integer> eurCounts = new LinkedHashMap<>();
            eurCounts.put(100, 2);
            eurCounts.put(50, 4);
            denomCounts.put("EUR", eurCounts);

            List<DenominationCount> result = denominationService.recordDenomination(
                BRANCH_ID, SESSION_ID, DenominationCategory.EVENING, denomCounts);

            assertThat(result).hasSize(5); // 3 HUF + 2 EUR

            ArgumentCaptor<DenominationCount> captor = ArgumentCaptor.forClass(DenominationCount.class);
            verify(denominationCountRepository, times(5)).save(captor.capture());

            List<DenominationCount> saved = captor.getAllValues();
            assertThat(saved).allMatch(dc ->
                dc.getDenominationCategory() == DenominationCategory.EVENING);
            assertThat(saved).allMatch(dc ->
                dc.getBranchId().equals(BRANCH_ID));
            assertThat(saved).allMatch(dc ->
                dc.getCountType().equals("CLOSING"));
        }

        @Test
        @DisplayName("Kezelési díj kategóriával rögzítés")
        void recordDenominationHandlingFee() {
            when(denominationCountRepository.save(any(DenominationCount.class)))
                .thenAnswer(inv -> {
                    DenominationCount dc = inv.getArgument(0);
                    dc.setId(UUID.randomUUID());
                    return dc;
                });

            Map<String, Map<Integer, Integer>> denomCounts = new LinkedHashMap<>();
            Map<Integer, Integer> hufCounts = new LinkedHashMap<>();
            hufCounts.put(5000, 2);
            hufCounts.put(1000, 8);
            denomCounts.put("HUF", hufCounts);

            List<DenominationCount> result = denominationService.recordDenomination(
                BRANCH_ID, SESSION_ID, DenominationCategory.HANDLING_FEE, denomCounts);

            assertThat(result).hasSize(2);

            ArgumentCaptor<DenominationCount> captor = ArgumentCaptor.forClass(DenominationCount.class);
            verify(denominationCountRepository, times(2)).save(captor.capture());

            assertThat(captor.getAllValues()).allMatch(dc ->
                dc.getDenominationCategory() == DenominationCategory.HANDLING_FEE);
        }

        @Test
        @DisplayName("Üres adat validációs hibát dob")
        void recordDenominationEmptyThrows() {
            assertThatThrownBy(() ->
                denominationService.recordDenomination(
                    BRANCH_ID, SESSION_ID, DenominationCategory.EVENING, Map.of()))
                .isInstanceOf(ValidationException.class);

            assertThatThrownBy(() ->
                denominationService.recordDenomination(
                    BRANCH_ID, SESSION_ID, DenominationCategory.EVENING, null))
                .isInstanceOf(ValidationException.class);
        }

        @Test
        @DisplayName("Negatív darabszám validációs hibát dob")
        void recordDenominationNegativeQuantityThrows() {
            Map<String, Map<Integer, Integer>> denomCounts = new LinkedHashMap<>();
            Map<Integer, Integer> hufCounts = new LinkedHashMap<>();
            hufCounts.put(10000, -1);
            denomCounts.put("HUF", hufCounts);

            assertThatThrownBy(() ->
                denominationService.recordDenomination(
                    BRANCH_ID, SESSION_ID, DenominationCategory.EVENING, denomCounts))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Negatív");
        }
    }

    // ============ QUERY DELEGÁCIÓ TESZTEK ============

    @Nested
    @DisplayName("Kategória lekérdezés delegáció")
    class QueryDelegationTests {

        @Test
        @DisplayName("isCategoryDenominated delegál a repo-nak")
        void isCategoryDenominatedDelegates() {
            LocalDate today = LocalDate.now();
            when(denominationCountRepository.existsByBranchIdAndDateAndCategory(
                BRANCH_ID, today, DenominationCategory.WESTERN_UNION))
                .thenReturn(true);

            boolean result = denominationService.isCategoryDenominated(
                BRANCH_ID, today, DenominationCategory.WESTERN_UNION);

            assertThat(result).isTrue();
            verify(denominationCountRepository).existsByBranchIdAndDateAndCategory(
                BRANCH_ID, today, DenominationCategory.WESTERN_UNION);
        }

        @Test
        @DisplayName("getCategoryDenominatedTotal delegál a repo-nak")
        void getCategoryDenominatedTotalDelegates() {
            LocalDate today = LocalDate.now();
            BigDecimal expected = new BigDecimal("185000");
            when(denominationCountRepository.sumDenominatedAmountByCategory(
                BRANCH_ID, today, DenominationCategory.EVENING))
                .thenReturn(expected);

            BigDecimal result = denominationService.getCategoryDenominatedTotal(
                BRANCH_ID, today, DenominationCategory.EVENING);

            assertThat(result).isEqualByComparingTo(expected);
        }
    }
}
