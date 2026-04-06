package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.sanction.SanctionMatch;
import hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult;
import hu.puzzleir.valuta.entity.SanctionEntry;
import hu.puzzleir.valuta.repository.SanctionEntryRepository;
import hu.puzzleir.valuta.repository.SanctionScreeningLogRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.ByteArrayInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * SanctionScreeningService UNIT tesztek — Mockito.
 *
 * Szankciós szűrés: exact match, fuzzy match (Levenshtein), XML import.
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class SanctionServiceTest {

    @InjectMocks
    private SanctionScreeningService service;

    @Mock
    private SanctionEntryRepository sanctionEntryRepository;

    @Mock
    private SanctionScreeningLogRepository screeningLogRepository;

    @Spy
    private ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Segéd: SanctionEntry létrehozása.
     */
    private SanctionEntry createEntry(String fullName, String aliases) {
        return SanctionEntry.builder()
                .id(UUID.randomUUID())
                .fullName(fullName)
                .aliases(aliases)
                .active(true)
                .listType("UN")
                .build();
    }

    // =====================================================================
    // Nincs találat → CLEAR
    // =====================================================================
    @Test
    @DisplayName("Szűrés: nincs találat → CLEAR kockázati szint")
    void testScreen_noMatch_pass() {
        // Arrange — üres lista, nincs egyezés
        when(sanctionEntryRepository.findByActiveTrue()).thenReturn(Collections.emptyList());
        when(sanctionEntryRepository.findByDocumentNumber(any())).thenReturn(Collections.emptyList());

        // Act
        SanctionScreeningResult result = service.screenCustomer(
                "Kiss János", "123456AB", null,
                "W001", "Teszt Pénztáros", "BP01"
        );

        // Assert
        assertThat(result.isMatched()).isFalse();
        assertThat(result.getMatches()).isEmpty();
        assertThat(result.getRiskLevel()).isEqualTo("CLEAR");
    }

    // =====================================================================
    // Exact match → CONFIRMED
    // =====================================================================
    @Test
    @DisplayName("Szűrés: pontos egyezés → CONFIRMED kockázati szint")
    void testScreen_exactMatch_fail() {
        // Arrange — pontosan ugyanaz a név a szankciós listán
        SanctionEntry entry = createEntry("John Smith", null);
        when(sanctionEntryRepository.findByActiveTrue()).thenReturn(List.of(entry));

        // Act
        SanctionScreeningResult result = service.screenCustomer(
                "John Smith", null, null,
                "W001", "Teszt Pénztáros", "BP01"
        );

        // Assert — EXACT match → CONFIRMED
        assertThat(result.isMatched()).isTrue();
        assertThat(result.getRiskLevel()).isEqualTo("CONFIRMED");
        assertThat(result.getMatches()).isNotEmpty();
        assertThat(result.getMatches().get(0).getMatchType()).isEqualTo("EXACT");
        assertThat(result.getMatches().get(0).getScore()).isEqualTo(1.0);
    }

    // =====================================================================
    // Fuzzy match: Levenshtein ≤ 2 → POSSIBLE
    // =====================================================================
    @Test
    @DisplayName("Szűrés: fuzzy match (Levenshtein ≤ 2) → POSSIBLE kockázati szint")
    void testScreen_fuzzyMatch_levenshtein2() {
        // Arrange — "Jon" vs "Jan" (Levenshtein = 1) → fuzzy match
        SanctionEntry entry = createEntry("Jon", null);
        when(sanctionEntryRepository.findByActiveTrue()).thenReturn(List.of(entry));

        // Act — "Jan" vs "Jon" = Levenshtein 1
        SanctionScreeningResult result = service.screenCustomer(
                "Jan", null, null,
                "W001", "Teszt Pénztáros", "BP01"
        );

        // Assert — fuzzy match → POSSIBLE
        assertThat(result.isMatched()).isTrue();
        assertThat(result.getRiskLevel()).isEqualTo("POSSIBLE");
        assertThat(result.getMatches()).isNotEmpty();
    }

    // =====================================================================
    // XML import: sikeres
    // =====================================================================
    @Test
    @DisplayName("XML import: ENSZ szankciós lista feldolgozás")
    void testImportXml_success() {
        // Arrange — minimális UN XML formátum
        String xml = """
                <?xml version="1.0" encoding="UTF-8"?>
                <CONSOLIDATED_LIST>
                    <INDIVIDUAL>
                        <FIRST_NAME>Ahmed</FIRST_NAME>
                        <SECOND_NAME>Ali</SECOND_NAME>
                        <THIRD_NAME/>
                        <DATE_OF_BIRTH>1970-01-01</DATE_OF_BIRTH>
                        <NATIONALITY>SY</NATIONALITY>
                        <REFERENCE_NUMBER>QDi.001</REFERENCE_NUMBER>
                        <INDIVIDUAL_ALIAS>
                            <ALIAS_NAME>Abu Ahmed</ALIAS_NAME>
                        </INDIVIDUAL_ALIAS>
                    </INDIVIDUAL>
                    <INDIVIDUAL>
                        <FIRST_NAME>Fatima</FIRST_NAME>
                        <SECOND_NAME>Hassan</SECOND_NAME>
                        <THIRD_NAME/>
                        <DATE_OF_BIRTH/>
                        <NATIONALITY/>
                        <REFERENCE_NUMBER>QDi.002</REFERENCE_NUMBER>
                    </INDIVIDUAL>
                </CONSOLIDATED_LIST>
                """;

        InputStream xmlStream = new ByteArrayInputStream(xml.getBytes(StandardCharsets.UTF_8));

        when(sanctionEntryRepository.save(any(SanctionEntry.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        // Act
        int importedCount = service.importSanctionList(xmlStream);

        // Assert — 2 bejegyzés importálva
        assertThat(importedCount).isEqualTo(2);
        verify(sanctionEntryRepository, times(2)).save(any(SanctionEntry.class));
    }

    // ── EU FSF v1.1 XML import tesztek ──

    @Test
    @DisplayName("importEuSanctionList — happy path: 2 sanctionEntity importalva")
    void testImportEuSanctionList_happyPath() {
        String euXml = """
                <?xml version="1.0" encoding="UTF-8"?>
                <export>
                  <sanctionEntity euReferenceNumber="EU-1234">
                    <nameAlias wholeName="Ivan Petrov" />
                    <nameAlias wholeName="Ivan P." />
                    <birthdate birthdate="1975-03-15" />
                  </sanctionEntity>
                  <sanctionEntity euReferenceNumber="EU-5678">
                    <nameAlias wholeName="Sergei Volkov" />
                    <birthdate year="1980" />
                  </sanctionEntity>
                </export>
                """;

        InputStream xmlStream = new ByteArrayInputStream(euXml.getBytes(StandardCharsets.UTF_8));

        when(sanctionEntryRepository.save(any(SanctionEntry.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        int count = service.importEuSanctionList(xmlStream);

        assertThat(count).isEqualTo(2);

        ArgumentCaptor<SanctionEntry> captor = ArgumentCaptor.forClass(SanctionEntry.class);
        verify(sanctionEntryRepository, times(2)).save(captor.capture());

        SanctionEntry first = captor.getAllValues().get(0);
        assertThat(first.getFullName()).isEqualTo("Ivan Petrov");
        assertThat(first.getListType()).isEqualTo("EU");
        assertThat(first.getListReference()).isEqualTo("EU-1234");
        assertThat(first.getDateOfBirth()).isEqualTo("1975-03-15");
        assertThat(first.getAliases()).contains("Ivan P.");

        SanctionEntry second = captor.getAllValues().get(1);
        assertThat(second.getFullName()).isEqualTo("Sergei Volkov");
        assertThat(second.getDateOfBirth()).isEqualTo("1980");
    }

    @Test
    @DisplayName("importEuSanctionList — blank name entity kihagyva")
    void testImportEuSanctionList_blankNameSkipped() {
        String euXml = """
                <?xml version="1.0" encoding="UTF-8"?>
                <export>
                  <sanctionEntity euReferenceNumber="EU-0001">
                    <nameAlias wholeName="" />
                  </sanctionEntity>
                  <sanctionEntity euReferenceNumber="EU-0002">
                    <nameAlias wholeName="Valid Name" />
                  </sanctionEntity>
                </export>
                """;

        InputStream xmlStream = new ByteArrayInputStream(euXml.getBytes(StandardCharsets.UTF_8));

        when(sanctionEntryRepository.save(any(SanctionEntry.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        int count = service.importEuSanctionList(xmlStream);

        assertThat(count).isEqualTo(1);
        verify(sanctionEntryRepository, times(1)).save(any(SanctionEntry.class));
    }

    @Test
    @DisplayName("importEuSanctionList — birthdate year fallback")
    void testImportEuSanctionList_yearFallback() {
        String euXml = """
                <?xml version="1.0" encoding="UTF-8"?>
                <export>
                  <sanctionEntity euReferenceNumber="EU-9999">
                    <nameAlias wholeName="Test Person" />
                    <birthdate year="1965" />
                  </sanctionEntity>
                </export>
                """;

        InputStream xmlStream = new ByteArrayInputStream(euXml.getBytes(StandardCharsets.UTF_8));

        when(sanctionEntryRepository.save(any(SanctionEntry.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        int count = service.importEuSanctionList(xmlStream);

        assertThat(count).isEqualTo(1);
        ArgumentCaptor<SanctionEntry> captor = ArgumentCaptor.forClass(SanctionEntry.class);
        verify(sanctionEntryRepository).save(captor.capture());
        assertThat(captor.getValue().getDateOfBirth()).isEqualTo("1965");
    }
}
