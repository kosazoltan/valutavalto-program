package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.service.FatfCountryRiskService.FatfTier;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FatfCountryRiskService unit tesztek (G4) — a 9. sz. körlevél (FZS-9/2024) listája.
 */
class FatfCountryRiskServiceTest {

    private final FatfCountryRiskService service = new FatfCountryRiskService();

    @Test
    @DisplayName("1/a csoport: Észak-Korea, Irán → TIER_1A_COUNTERMEASURE")
    void tier1a() {
        assertThat(service.classify("Észak-Korea")).isEqualTo(FatfTier.TIER_1A_COUNTERMEASURE);
        assertThat(service.classify("Irán")).isEqualTo(FatfTier.TIER_1A_COUNTERMEASURE);
        assertThat(service.classify("North Korea")).isEqualTo(FatfTier.TIER_1A_COUNTERMEASURE);
        assertThat(service.classify("IRAN")).isEqualTo(FatfTier.TIER_1A_COUNTERMEASURE);
        assertThat(service.classify("Észak-Korea").isHighRisk()).isTrue();
    }

    @Test
    @DisplayName("1/b csoport: Myanmar (Burma) → TIER_1B_ENHANCED_DD")
    void tier1b() {
        assertThat(service.classify("Myanmar")).isEqualTo(FatfTier.TIER_1B_ENHANCED_DD);
        assertThat(service.classify("Burma")).isEqualTo(FatfTier.TIER_1B_ENHANCED_DD);
        assertThat(service.classify("Myanmar").isHighRisk()).isTrue();
    }

    @Test
    @DisplayName("2. csoport: Törökország, Horvátország, Vietnám → TIER_2_INCREASED_MONITORING")
    void tier2() {
        assertThat(service.classify("Törökország")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
        assertThat(service.classify("Horvátország")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
        assertThat(service.classify("Vietnám")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
        assertThat(service.classify("Dél-Afrika")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
        assertThat(service.classify("Törökország").isHighRisk()).isFalse();
    }

    @Test
    @DisplayName("Accent/kisbetű-érzéketlen: 'torokorszag', 'TÖRÖKORSZÁG' is egyezik")
    void accentInsensitive() {
        assertThat(service.classify("torokorszag")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
        assertThat(service.classify("TÖRÖKORSZÁG")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
    }

    @Test
    @DisplayName("Nem listás / kikerült ország → NONE (Magyarország, Uganda, EAE, Barbados)")
    void none() {
        assertThat(service.classify("Magyarország")).isEqualTo(FatfTier.NONE);
        assertThat(service.classify("Németország")).isEqualTo(FatfTier.NONE);
        // 2024.02.27-én KIKERÜLT a 2. csoportból:
        assertThat(service.classify("Uganda")).isEqualTo(FatfTier.NONE);
        assertThat(service.classify("Egyesült Arab Emírségek")).isEqualTo(FatfTier.NONE);
        assertThat(service.classify("Barbados")).isEqualTo(FatfTier.NONE);
        assertThat(service.classify("Gibraltár")).isEqualTo(FatfTier.NONE);
    }

    @Test
    @DisplayName("FK-FATF: a NATIONALITY-szótár (V286) magyar állampolgárság-MELLÉKNEVEI is illeszkednek")
    void nationalityAdjectives() {
        // A CustomerPanel a name_hu melléknevet küldi (pl. "Iráni"), NEM az ország-nevet —
        // ezek korábban NONE-t adtak → a FATF-kockázat csendben elveszett.
        assertThat(service.classify("Iráni")).isEqualTo(FatfTier.TIER_1A_COUNTERMEASURE);
        assertThat(service.classify("Észak-koreai")).isEqualTo(FatfTier.TIER_1A_COUNTERMEASURE);
        assertThat(service.classify("Szíriai")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
        assertThat(service.classify("Török")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
        assertThat(service.classify("Horvát")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
        assertThat(service.classify("Vietnámi")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
        assertThat(service.classify("Nigériai")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
        assertThat(service.classify("Kenyai")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
        assertThat(service.classify("Fülöp-szigeteki")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
        assertThat(service.classify("Dél-afrikai")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
        assertThat(service.classify("Bolgár")).isEqualTo(FatfTier.TIER_2_INCREASED_MONITORING);
        // Magyar (a leggyakoribb) NEM listás → NONE
        assertThat(service.classify("Magyar")).isEqualTo(FatfTier.NONE);
    }

    @Test
    @DisplayName("Null / üres input → NONE")
    void blank() {
        assertThat(service.classify(null)).isEqualTo(FatfTier.NONE);
        assertThat(service.classify("")).isEqualTo(FatfTier.NONE);
        assertThat(service.classify("   ")).isEqualTo(FatfTier.NONE);
    }
}
