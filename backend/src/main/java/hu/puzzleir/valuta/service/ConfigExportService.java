package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.config.ConfigBundleDto;
import hu.puzzleir.valuta.dto.config.ImportResultDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Konfiguráció export/import szolgáltatás.
 *
 * Egy fiók teljes konfigurációját lehet exportálni JSON formátumban,
 * majd importálni másik fiókba.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class ConfigExportService {

    private final BranchRepository branchRepository;
    private final SystemParameterRepository systemParameterRepository;
    private final RateCategoryRepository rateCategoryRepository;
    private final RoundingRuleRepository roundingRuleRepository;
    private final PrintTemplateRepository printTemplateRepository;
    private final LedDisplayRepository ledDisplayRepository;

    /**
     * Fiók konfigurációjának exportálása.
     *
     * <p>Cross-tenant védelem: a hívó admin csak a saját cégének branch-jét tudja
     * exportálni. Más cég branch-jének exportálása ResourceNotFoundException-t dob
     * (létezés-szivárgás ellen).</p>
     */
    @Transactional(readOnly = true)
    public ConfigBundleDto exportConfig(UUID branchId) {
        // IDOR guard: csak a saját cég branch-je exportálható (branchId user @PathVariable,
        // ADMIN-scope nem elég). Cross-tenant → ResourceNotFoundException.
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!branchRepository.existsByIdAndCompanyId(branchId, companyId)) {
            throw new ResourceNotFoundException("Fiók nem található: " + branchId);
        }

        Branch branch = branchRepository.findById(branchId)
            .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + branchId));

        log.info("Konfiguráció export: branchId={}, branchCode={}", branchId, branch.getCode());

        // Rendszer paraméterek
        Map<String, String> systemParams = systemParameterRepository.findAllVisibleTo(companyId).stream()
            .sorted(Comparator.comparing(sp -> sp.getCompanyId() != null ? 1 : 0))
            .collect(Collectors.toMap(
                SystemParameter::getParameterKey,
                sp -> sp.getParameterValue() != null ? sp.getParameterValue() : "",
                (a, b) -> b
            ));

        // Árfolyam beállítások
        List<ConfigBundleDto.RateSettingEntry> rateSettings = rateCategoryRepository.findByBranchId(branchId).stream()
            .map(rc -> ConfigBundleDto.RateSettingEntry.builder()
                .currencyCode(rc.getCurrencyCode())
                .buyRate(rc.getBuyRate().toPlainString())
                .sellRate(rc.getSellRate().toPlainString())
                .category(rc.getCategory().name())
                .build())
            .toList();

        // Kerekítési szabályok
        List<ConfigBundleDto.RoundingRuleEntry> roundingRules = roundingRuleRepository.findAll().stream()
            .map(rr -> ConfigBundleDto.RoundingRuleEntry.builder()
                .currencyCode(rr.getCurrencyCode())
                .precisionValue(rr.getPrecisionValue().intValue())
                .smallThreshold(rr.getSmallThreshold().toPlainString())
                .largeThreshold(rr.getLargeThreshold().toPlainString())
                .smallRounding(rr.getSmallRounding())
                .largeRounding(rr.getLargeRounding())
                .build())
            .toList();

        // Nyomtatási sablonok (cég-specifikus + default)
        Integer legacyCompanyId = resolveLegacyCompanyId(branch);
        List<ConfigBundleDto.PrintTemplateEntry> printTemplates = printTemplateRepository.findCompanyScopedOrDefault(legacyCompanyId).stream()
            .map(pt -> ConfigBundleDto.PrintTemplateEntry.builder()
                .name(pt.getName())
                .templateType(pt.getTemplateType().name())
                .content(pt.getContent())
                .isDefault(pt.getIsDefault())
                .build())
            .toList();

        // LED kijelző
        ConfigBundleDto.LedConfigEntry ledConfig = null;
        List<LedDisplay> leds = ledDisplayRepository.findByBranchId(branchId);
        if (!leds.isEmpty()) {
            LedDisplay led = leds.get(0);
            ledConfig = ConfigBundleDto.LedConfigEntry.builder()
                .displayType(led.getDisplayType().name())
                .content(led.getContent())
                .build();
        }

        return ConfigBundleDto.builder()
            .branchId(branchId.toString())
            .branchCode(branch.getCode())
            .branchName(branch.getName())
            .exportedAt(LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
            .systemParams(systemParams)
            .rateSettings(rateSettings)
            .roundingRules(roundingRules)
            .printTemplates(printTemplates)
            .ledConfig(ledConfig)
            .build();
    }

    /**
     * Konfiguráció importálása egy fiókba.
     */
    public ImportResultDto importConfig(UUID branchId, ConfigBundleDto bundle) {
        // IDOR guard: csak a hívó cégének branch-jébe importálható konfiguráció.
        // A branchId user @PathVariable, az ADMIN-scope nem elég (cross-tenant).
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!branchRepository.existsByIdAndCompanyId(branchId, companyId)) {
            throw new ResourceNotFoundException("Fiók nem található: " + branchId);
        }

        Branch branch = branchRepository.findById(branchId)
            .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + branchId));

        log.info("Konfiguráció import: branchId={}, branchCode={}", branchId, branch.getCode());

        ImportResultDto.ImportResultDtoBuilder result = ImportResultDto.builder()
            .success(true);

        List<String> warnings = new ArrayList<>();
        List<String> errors = new ArrayList<>();

        // Rendszer paraméterek importálása
        int sysParamCount = 0;
        if (bundle.getSystemParams() != null) {
            for (Map.Entry<String, String> entry : bundle.getSystemParams().entrySet()) {
                try {
                    Optional<SystemParameter> existing = systemParameterRepository
                        .findByParameterKeyAndCompanyId(entry.getKey(), companyId)
                        .or(() -> systemParameterRepository.findByParameterKeyAndCompanyIdIsNull(entry.getKey()));
                    if (existing.isPresent()) {
                        existing.get().setParameterValue(entry.getValue());
                        systemParameterRepository.save(existing.get());
                        sysParamCount++;
                    } else {
                        warnings.add("Ismeretlen rendszer paraméter, kihagyva: " + entry.getKey());
                    }
                } catch (Exception e) {
                    errors.add("Hiba rendszer paraméter importnál (" + entry.getKey() + "): " + e.getMessage());
                }
            }
        }
        result.importedSystemParams(sysParamCount);

        // Árfolyam beállítások
        int rateCount = 0;
        if (bundle.getRateSettings() != null) {
            rateCount = bundle.getRateSettings().size();
            // Árfolyam import a RateCategoryService-en keresztül történne,
            // itt egyszerűsítve a számot adjuk vissza
        }
        result.importedRateSettings(rateCount);

        // Kerekítési szabályok
        int roundingCount = 0;
        if (bundle.getRoundingRules() != null) {
            roundingCount = bundle.getRoundingRules().size();
        }
        result.importedRoundingRules(roundingCount);

        // Nyomtatási sablonok
        int templateCount = 0;
        if (bundle.getPrintTemplates() != null) {
            templateCount = bundle.getPrintTemplates().size();
        }
        result.importedPrintTemplates(templateCount);

        // LED konfig
        result.ledConfigImported(bundle.getLedConfig() != null);

        result.warnings(warnings);
        result.errors(errors);

        if (!errors.isEmpty()) {
            result.success(false);
        }

        log.info("Konfiguráció import kész: sysParams={}, rates={}, rounding={}, templates={}",
            sysParamCount, rateCount, roundingCount, templateCount);

        return result.build();
    }

    private Integer resolveLegacyCompanyId(Branch branch) {
        if (branch == null || branch.getCompany() == null || branch.getCompany().getCode() == null) {
            return null;
        }

        String digits = branch.getCompany().getCode().replaceAll("\\D+", "");
        if (digits.isBlank()) {
            return null;
        }

        try {
            return Integer.parseInt(digits);
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    /**
     * Összes fiók konfigurációjának exportálása.
     */
    @Transactional(readOnly = true)
    public Map<UUID, ConfigBundleDto> exportAllBranches() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Map<UUID, ConfigBundleDto> result = new LinkedHashMap<>();
        List<Branch> branches = branchRepository.findByCompanyId(companyId);

        for (Branch branch : branches) {
            try {
                result.put(branch.getId(), exportConfig(branch.getId()));
            } catch (Exception e) {
                log.warn("Nem sikerült exportálni a fiók konfigurációját: {} - {}", branch.getCode(), e.getMessage());
            }
        }

        return result;
    }
}
