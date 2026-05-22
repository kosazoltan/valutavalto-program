package hu.puzzleir.valuta.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.text.Normalizer;
import java.util.Collections;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/**
 * FATF többszintű ország-kockázati lista (AML/CFT).
 *
 * <p>Forrás: 9. sz. Körlevél (FZS-9/2024), hatályos 2024.02.27 — a FATF "public statement"
 * alapján. A lista <b>időponti pillanatkép</b>; a FATF időszakonként módosít, ezért a
 * {@link #LIST_VERSION} mezővel jelöljük az érvényességet. Új körlevélnél a listát
 * frissíteni kell (lásd EXCMD/b9-korlevelek-compliance.md, FR: verzió-követés).
 *
 * <p>Csoportok:
 * <ul>
 *   <li><b>1/a</b> — ellenintézkedésekkel érintett ország (legmagasabb kockázat)</li>
 *   <li><b>1/b</b> — kockázatokkal arányos fokozott átvilágítás szükséges</li>
 *   <li><b>2.</b>  — fokozott monitoring alatt (fejlesztés/vizsgálat folyamatban)</li>
 * </ul>
 */
@Service
@Slf4j
public class FatfCountryRiskService {

    /** A betöltött FATF lista érvényességi verziója (körlevél hatálya). */
    public static final String LIST_VERSION = "FZS-9/2024 (2024-02-27)";

    public enum FatfTier {
        TIER_1A_COUNTERMEASURE("1/a — ellenintézkedéssel érintett ország"),
        TIER_1B_ENHANCED_DD("1/b — fokozott átvilágítás szükséges"),
        TIER_2_INCREASED_MONITORING("2. csoport — fokozott monitoring"),
        NONE("Nincs FATF-kockázati besorolás");

        private final String displayName;
        FatfTier(String displayName) { this.displayName = displayName; }
        public String getDisplayName() { return displayName; }
        /** Magas kockázat (1/a vagy 1/b) — kötelező fokozott ügyfél-átvilágítás. */
        public boolean isHighRisk() { return this == TIER_1A_COUNTERMEASURE || this == TIER_1B_ENHANCED_DD; }
    }

    /** Normalizált országnév → tier. Több alias (magyar/angol/ISO) ugyanarra a tier-re. */
    private static final Map<String, FatfTier> COUNTRY_TIER;

    static {
        Map<String, FatfTier> m = new HashMap<>();
        // 1/a — ellenintézkedés
        putAll(m, FatfTier.TIER_1A_COUNTERMEASURE,
                "eszak-korea", "eszak korea", "koreai nepi demokratikus koztarsasag",
                "north korea", "dprk", "prk", "kp");
        putAll(m, FatfTier.TIER_1A_COUNTERMEASURE,
                "iran", "iran iszlam koztarsasag", "irn", "ir");
        // 1/b — fokozott átvilágítás
        putAll(m, FatfTier.TIER_1B_ENHANCED_DD,
                "myanmar", "burma", "mmr", "mm");
        // 2. csoport — fokozott monitoring (21 ország, 2024.02.27)
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "bulgaria", "bgr", "bg");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "burkina faso", "bfa");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "del-afrika", "del afrika", "south africa", "zaf");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "del-szudan", "del szudan", "south sudan", "ssd");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "fulop-szigetek", "fulop szigetek", "philippines", "phl");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "haiti", "hti");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "horvatorszag", "croatia", "hrv", "hr");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "jamaica", "jam");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "jemen", "yemen", "yem");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "kamerun", "cameroon", "cmr");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "kenya", "ken");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING,
                "kongoi demokratikus koztarsasag", "kongo", "dr congo", "cod");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "mali", "mli");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "mozambik", "mozambique", "moz");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "namibia", "nam");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "nigeria", "nga");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "szenegal", "senegal", "sen");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "sziria", "syria", "syr");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "tanzania", "tza");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "torokorszag", "turkey", "turkiye", "tur", "tr");
        putAll(m, FatfTier.TIER_2_INCREASED_MONITORING, "vietnam", "vnm", "vn");
        COUNTRY_TIER = Collections.unmodifiableMap(m);
    }

    private static void putAll(Map<String, FatfTier> m, FatfTier tier, String... aliases) {
        for (String a : aliases) {
            FatfTier prev = m.put(a, tier);
            // Fail-fast: ne fedjen el konfigurációs hibát egy eltérő tier-rel duplikált alias
            // (Sourcery #767). Azonos tier-re ismétlés ártalmatlan.
            if (prev != null && prev != tier) {
                throw new IllegalStateException(
                        "FATF duplikált ország-alias eltérő tier-rel: '" + a + "' (" + prev + " vs " + tier + ")");
            }
        }
    }

    /**
     * Egy ország/állampolgárság FATF-besorolása.
     *
     * @param country szabad-szöveges ország- vagy állampolgárság-megnevezés (magyar/angol/ISO)
     * @return a megfelelő {@link FatfTier}, vagy {@link FatfTier#NONE} ha nincs a listán / üres
     */
    public FatfTier classify(String country) {
        String key = normalize(country);
        if (key.isBlank()) {
            return FatfTier.NONE;
        }
        FatfTier tier = COUNTRY_TIER.get(key);
        if (tier == null) {
            return FatfTier.NONE;
        }
        if (tier.isHighRisk()) {
            log.warn("[FATF] Magas kockázatú ország ({}): '{}' — fokozott átvilágítás kötelező.",
                    tier.name(), country);
        }
        return tier;
    }

    /** Az összes FATF-listás (nem NONE) normalizált kulcs — diagnosztikához/teszthez. */
    public Set<String> listedKeys() {
        return COUNTRY_TIER.keySet();
    }

    private static String normalize(String s) {
        if (s == null) return "";
        String decomposed = Normalizer.normalize(s, Normalizer.Form.NFD);
        return decomposed.toLowerCase(Locale.ROOT)
                .replaceAll("\\p{M}+", "")
                .replaceAll("[^a-z0-9\\s-]", "")
                .replaceAll("\\s+", " ")
                .trim();
    }
}
