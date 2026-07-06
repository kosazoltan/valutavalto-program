package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.config.CreateValueBandConfigRequest;
import hu.puzzleir.valuta.entity.ValueBandConfig;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ValueBandConfigRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * FS-8: AML értéksávok egyetlen igazságforrása. MINDEN tranzakciós küszöb-olvasás
 * (AmlService, TransactionService, TransactionOperationHelper, TransactionValidationService)
 * innen jön — beleértve az FS-4 lejárt-okmány blokk küszöbét (A↔B egységes forrás).
 * Fail-closed: config-hiány/DB-hiba esetén a MAI törvényi hardcode-ok (sosem 0, sosem open).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ValueBandService {

    /** Effektív sáv-snapshot. Egy checkTransaction EGYSZER oldja fel (terv C3 invariáns). */
    public record ValueBands(
            BigDecimal simplifiedIdentificationLimitHuf,
            BigDecimal identificationLimitHuf,
            BigDecimal incomeProofLimitHuf,
            int rollingWindowDays) {

        /** Törvényi defaultok = a 2026-07 előtti hardcode-ok (Pmt. 7.§ + BIGCTRL parity). */
        public static final ValueBands DEFAULTS = new ValueBands(
                new BigDecimal("100000"),
                new BigDecimal("300000"),
                new BigDecimal("10000000"),
                8);
    }

    private final ValueBandConfigRepository valueBandConfigRepository;

    /**
     * Null-safe feloldó a @InjectMocks-kompatibilitáshoz: nem-mockolt/null service → DEFAULTS,
     * a meglévő tesztek nem törnek.
     */
    public static ValueBands resolve(ValueBandService service) {
        if (service == null) {
            return ValueBands.DEFAULTS;
        }
        ValueBands bands = service.getEffectiveBands();
        return bands != null ? bands : ValueBands.DEFAULTS;
    }

    @Transactional(readOnly = true)
    public ValueBands getEffectiveBands() {
        try {
            return valueBandConfigRepository
                    .findTopByEffectiveFromLessThanEqualOrderByEffectiveFromDesc(LocalDate.now())
                    .map(c -> new ValueBands(
                            nonNullOrDefault(c.getSimplifiedIdentificationLimitHuf(),
                                    ValueBands.DEFAULTS.simplifiedIdentificationLimitHuf()),
                            nonNullOrDefault(c.getIdentificationLimitHuf(),
                                    ValueBands.DEFAULTS.identificationLimitHuf()),
                            nonNullOrDefault(c.getIncomeProofLimitHuf(),
                                    ValueBands.DEFAULTS.incomeProofLimitHuf()),
                            c.getRollingWindowDays() != null && c.getRollingWindowDays() >= 1
                                    ? c.getRollingWindowDays()
                                    : ValueBands.DEFAULTS.rollingWindowDays()))
                    .orElse(ValueBands.DEFAULTS);
        } catch (Exception e) {
            log.warn("Értéksáv-feloldás sikertelen, törvényi defaultok (fail-closed): {}",
                    e.getMessage(), e);
            return ValueBands.DEFAULTS;
        }
    }

    @Transactional(readOnly = true)
    public List<ValueBandConfig> listAll() {
        return valueBandConfigRepository.findAllByOrderByEffectiveFromDesc();
    }

    @Transactional(rollbackFor = Exception.class)
    public ValueBandConfig create(CreateValueBandConfigRequest req) {
        validateBandValues(req);
        if (valueBandConfigRepository.existsByEffectiveFrom(req.getEffectiveFrom())) {
            throw new ValidationException(
                    "Erre a napra már létezik értéksáv-konfiguráció: " + req.getEffectiveFrom());
        }
        return valueBandConfigRepository.save(ValueBandConfig.builder()
                .simplifiedIdentificationLimitHuf(req.getSimplifiedIdentificationLimitHuf())
                .identificationLimitHuf(req.getIdentificationLimitHuf())
                .incomeProofLimitHuf(req.getIncomeProofLimitHuf())
                .rollingWindowDays(req.getRollingWindowDays())
                .effectiveFrom(req.getEffectiveFrom())
                .createdBy(currentWorkerCodeOrNull())
                .build());
    }

    @Transactional(rollbackFor = Exception.class)
    public ValueBandConfig update(UUID id, CreateValueBandConfigRequest req) {
        ValueBandConfig existing = findOrThrow(id);
        requireEditable(existing);
        validateBandValues(req);
        if (!existing.getEffectiveFrom().equals(req.getEffectiveFrom())
                && valueBandConfigRepository.existsByEffectiveFrom(req.getEffectiveFrom())) {
            throw new ValidationException(
                    "Erre a napra már létezik értéksáv-konfiguráció: " + req.getEffectiveFrom());
        }
        existing.setSimplifiedIdentificationLimitHuf(req.getSimplifiedIdentificationLimitHuf());
        existing.setIdentificationLimitHuf(req.getIdentificationLimitHuf());
        existing.setIncomeProofLimitHuf(req.getIncomeProofLimitHuf());
        existing.setRollingWindowDays(req.getRollingWindowDays());
        existing.setEffectiveFrom(req.getEffectiveFrom());
        return valueBandConfigRepository.save(existing);
    }

    @Transactional(rollbackFor = Exception.class)
    public void delete(UUID id) {
        ValueBandConfig existing = findOrThrow(id);
        requireEditable(existing);
        valueBandConfigRepository.delete(existing);
    }

    /** Center FS: "Mindaddig szerkeszthető, amíg a beállított nap előtt vagyunk." */
    private void requireEditable(ValueBandConfig config) {
        if (!config.getEffectiveFrom().isAfter(LocalDate.now())) {
            throw new ValidationException(
                    "Hatályos vagy múltbeli értéksáv-konfiguráció nem módosítható/törölhető "
                            + "(érvényesség kezdete: " + config.getEffectiveFrom() + ")");
        }
    }

    private void validateBandValues(CreateValueBandConfigRequest req) {
        if (req.getEffectiveFrom() == null || !req.getEffectiveFrom().isAfter(LocalDate.now())) {
            throw new ValidationException("Az érvényesség kezdete csak jövőbeli nap lehet!");
        }
        if (req.getSimplifiedIdentificationLimitHuf() == null
                || req.getSimplifiedIdentificationLimitHuf().signum() <= 0
                || req.getIdentificationLimitHuf() == null
                || req.getIdentificationLimitHuf().signum() <= 0
                || req.getIncomeProofLimitHuf() == null
                || req.getIncomeProofLimitHuf().signum() <= 0) {
            throw new ValidationException("Minden értéksáv-küszöbnek pozitívnak kell lennie!");
        }
        if (req.getSimplifiedIdentificationLimitHuf()
                .compareTo(req.getIdentificationLimitHuf()) > 0) {
            throw new ValidationException(
                    "Az egyszerűsített azonosítási küszöb nem lehet nagyobb a teljes azonosításinál!");
        }
        if (req.getRollingWindowDays() == null || req.getRollingWindowDays() < 1) {
            throw new ValidationException("A vizsgálandó időszak legalább 1 nap!");
        }
    }

    private ValueBandConfig findOrThrow(UUID id) {
        return valueBandConfigRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Értéksáv-konfiguráció nem található: " + id));
    }

    private String currentWorkerCodeOrNull() {
        try {
            return SecurityUtils.getCurrentWorkerCode();
        } catch (Exception e) {
            return null;
        }
    }

    private static BigDecimal nonNullOrDefault(BigDecimal value, BigDecimal defaultValue) {
        return value != null ? value : defaultValue;
    }
}
