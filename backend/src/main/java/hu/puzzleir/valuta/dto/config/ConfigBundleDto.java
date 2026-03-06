package hu.puzzleir.valuta.dto.config;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

/**
 * Konfiguráció export/import csomag DTO.
 *
 * Tartalmazza egy fiók teljes konfigurációját:
 * - Rendszer paraméterek
 * - Árfolyam beállítások
 * - Kerekítési szabályok
 * - Nyomtatási sablonok
 * - LED kijelző konfig
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConfigBundleDto {

    private String branchId;
    private String branchCode;
    private String branchName;
    private String exportedAt;

    private Map<String, String> systemParams;
    private List<RateSettingEntry> rateSettings;
    private List<RoundingRuleEntry> roundingRules;
    private List<PrintTemplateEntry> printTemplates;
    private LedConfigEntry ledConfig;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RateSettingEntry {
        private String currencyCode;
        private String buyRate;
        private String sellRate;
        private String category;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RoundingRuleEntry {
        private String currencyCode;
        private int precisionValue;
        private String smallThreshold;
        private String largeThreshold;
        private String smallRounding;
        private String largeRounding;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PrintTemplateEntry {
        private String name;
        private String templateType;
        private String content;
        private boolean isDefault;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LedConfigEntry {
        private String displayType;
        private String content;
    }
}
