package hu.puzzleir.valuta.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

/**
 * FK-066: pénznemenkénti záráskori tolerancia közös lekérdezője — a kemény kapu
 * (DailyClosingService.checkEveningDenomination) és a puha kapu
 * (ClosingWizardService.finalizeClosing) KIZÁRÓLAGOS tolerancia-forrása (FR-6).
 *
 * <p>Kulcs-minta: {@code CLOSING_TOLERANCE_<pénznemkód>} (pl. CLOSING_TOLERANCE_HUF).
 * A lekérdezés a {@link SystemParameterService#getValue(String, String)} meglévő
 * findEffective-mechanizmusán megy, így a cég-specifikus felülírás automatikusan
 * érvényesül (NFR-1). Cache-réteg szándékosan nincs (NFR-2): a zárás nem hot path,
 * a SystemParameterService-nek sincs cache-e.
 *
 * <p>KÓD-SZINTŰ fallback-default, ha nincs system_parameter sor (FR-5):
 * {@code HUF → 1 Ft} (kerekítési tolerancia), {@code nem-HUF → 0} (darabra pontos) —
 * az FK-066 előtti viselkedés tükre. A seedelt érték (pl. HUF=5) kizárólag a migráció
 * által beszúrt explicit sor tartalma, nem kód-fallback.
 *
 * <p>Az explicit/fallback ÁG-ELDÖNTÉS a system_parameter SOR JELENLÉTÉN alapul
 * ({@link SystemParameterService#findEffectiveValue} — Codex M1 fix), NEM az érték
 * és a kód-default egyezésén: így a kód-defaulttal karakterre azonos explicit sor
 * (pl. HUF-sor '1' értékkel) is helyesen explicit ágra ({@code >=} operátor) esik.
 *
 * <p>Érvénytelen (nem szám), negatív vagy üres paraméter-érték → TELJES fallback-ág
 * (fallback-érték ÉS fallback-operátor), WARN-loggal.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ClosingToleranceService {

    static final String KEY_PREFIX = "CLOSING_TOLERANCE_";

    private final SystemParameterService systemParameterService;

    public ClosingTolerance getToleranceFor(String currencyCode) {
        // Codex LOW fix: normalizálás (trim + uppercase) a kulcs-összeállítás ÉS a
        // HUF-fallback-döntés ELŐTT — " huf " ugyanaz, mint "HUF"; null → üres kód
        // (nincs ilyen kulcs → nem-HUF fallback 0, fail-conservative).
        String normalizedCode = currencyCode == null
                ? ""
                : currencyCode.trim().toUpperCase(java.util.Locale.ROOT);
        String fallbackDefault = "HUF".equals(normalizedCode) ? "1" : "0";
        java.util.Optional<String> raw =
                systemParameterService.findEffectiveValue(KEY_PREFIX + normalizedCode);

        if (raw.isPresent()) {
            try {
                BigDecimal parsed = new BigDecimal(raw.get().trim());
                if (parsed.signum() >= 0) {
                    return ClosingTolerance.explicitOf(parsed);
                }
                log.warn("FK-066: negatív záráskori tolerancia a paraméterben, fallback él: "
                        + "kulcs={}, érték={}, fallback={}", KEY_PREFIX + normalizedCode, raw.get(), fallbackDefault);
            } catch (NumberFormatException e) {
                log.warn("FK-066: érvénytelen záráskori tolerancia a paraméterben, fallback él: "
                        + "kulcs={}, érték={}, fallback={}", KEY_PREFIX + normalizedCode, raw.get(), fallbackDefault);
            }
        }
        return ClosingTolerance.fallbackOf(new BigDecimal(fallbackDefault));
    }
}
