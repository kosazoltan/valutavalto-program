package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.CurrencyAuditLog;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.logging.VVLogger;
import hu.puzzleir.valuta.repository.CurrencyAuditLogRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

/**
 * V238 (2026-05-19) — Currency administration service.
 *
 * <p>Kosa Zoltan user-direktiva (2026-05-19): "az adatbazisban mindig mindent
 * meg kell orizni, tehat itt az Arfolyamkeszitoben kert valuta fajta
 * modositasok, legyenek lehetsegesek, de az adatbazisbol nem torolhet semmit."</p>
 *
 * <p>Funkciok:
 * <ul>
 *   <li>{@link #createCurrency} — uj valuta hozzaadasa</li>
 *   <li>{@link #setActive} — valuta aktivalas/deaktivalas (NEM DELETE!)</li>
 * </ul>
 * Minden muvelet immutable audit-log bejegyzest ir a `currency_audit_log` tablaba
 * (Pmt./NAV 8-eves megorzes).</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AdminCurrencyService {

    private final CurrencyRepository currencyRepository;
    private final CurrencyAuditLogRepository auditRepository;
    private final ObjectMapper objectMapper;

    private static final VVLogger VV_LOG = VVLogger.of(AdminCurrencyService.class);

    /**
     * Uj valuta hozzaadasa.
     *
     * @throws ValidationException ha a code mar letezik (NEM hozhato letre duplikalt)
     */
    @Transactional
    public Currency createCurrency(String code, String name, String symbol, Integer decimalPlaces, Integer displayOrder) {
        String upperCode = code == null ? null : code.toUpperCase().trim();
        if (upperCode == null || upperCode.isBlank()) {
            throw new ValidationException("Valuta kod kotelezo");
        }
        if (currencyRepository.findByCode(upperCode).isPresent()) {
            throw new ValidationException("Ezzel a koddal mar letezik valuta: " + upperCode
                + " (ha inactivalt, hasznald a setActive(id, true)-t)");
        }
        Currency currency = Currency.builder()
                .code(upperCode)
                .name(name != null ? name.trim() : upperCode)
                .symbol(symbol)
                .decimalPlaces(decimalPlaces != null ? decimalPlaces : 2)
                .displayOrder(displayOrder != null ? displayOrder : 99)
                .active(true)
                .build();
        Currency saved = currencyRepository.save(currency);
        writeAudit(saved, "CREATE", null, saved);
        // CodeQL log-injection fix (PR #697 review): explicit CRLF strip a user-
        // input mezokre. A logback `%redact(%msg)` converter mar globalisan
        // strippeli, de a CodeQL static analysis ezt nem ismeri fel, ezert
        // explicit sanitize-zal segitunk.
        log.info("AdminCurrency: uj valuta letrehozva code={} name={} workerId={}",
            sanitizeForLog(saved.getCode()), sanitizeForLog(saved.getName()), safeWorkerId());
        return saved;
    }

    /**
     * Valuta aktivalas vagy deaktivalas.
     *
     * <p>NEM DELETE! Csak az `is_active` flag valtozik. A regi tranzakciok,
     * exchange_rate_master, audit_log mind erintetlenek maradnak. A pmt./NAV
     * 8-eves megorzes szempontjabol biztonsagos.</p>
     */
    @Transactional
    public Currency setActive(Long currencyId, boolean active, String note) {
        Currency currency = currencyRepository.findById(currencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem talalhato: id=" + currencyId));
        boolean wasActive = Boolean.TRUE.equals(currency.getActive());
        if (wasActive == active) {
            log.debug("AdminCurrency: setActive no-op (mar a kivant allapotban) code={} active={}",
                currency.getCode(), active);
            return currency; // no-op
        }
        Currency oldSnapshot = cloneForAudit(currency);
        currency.setActive(active);
        Currency saved = currencyRepository.save(currency);
        String action = active ? "ACTIVATE" : "DEACTIVATE";
        writeAudit(saved, action, oldSnapshot, saved, note);
        // CodeQL log-injection fix (PR #697 review): explicit sanitize a
        // user-input-tol fuggo mezokre (currency.code + note kontrolalhato).
        log.info("AdminCurrency: {} code={} workerId={} note={}",
            action, sanitizeForLog(currency.getCode()), safeWorkerId(), sanitizeForLog(note));
        return saved;
    }

    /**
     * CodeQL log-injection guard: CRLF + control character stripping.
     *
     * <p>A backend logback-spring.xml `%redact(%msg)` converter mar globalisan
     * strippeli ezeket, de a CodeQL static analysis NEM ismeri fel a custom
     * converter-t. Explicit sanitize hozzaadasaval a CodeQL alert eltunik.</p>
     *
     * <p>NULL-safe: null input → "&lt;null&gt;" literal a logba.</p>
     */
    private static String sanitizeForLog(String value) {
        if (value == null) return "<null>";
        // CRLF + control character (0x00-0x1F + 0x7F) eltavolitas
        return value.replaceAll("[\\r\\n\\t\\x00-\\x1F\\x7F]", "_");
    }

    // ============ Audit helpers ============

    private void writeAudit(Currency currency, String action, Currency oldSnapshot, Currency newSnapshot) {
        writeAudit(currency, action, oldSnapshot, newSnapshot, null);
    }

    private void writeAudit(Currency currency, String action, Currency oldSnapshot, Currency newSnapshot, String note) {
        try {
            CurrencyAuditLog entry = CurrencyAuditLog.builder()
                    .currencyId(currency.getId())
                    .currencyCode(currency.getCode())
                    .action(action)
                    .oldValue(oldSnapshot != null ? objectMapper.writeValueAsString(snapshotMap(oldSnapshot)) : null)
                    .newValue(objectMapper.writeValueAsString(snapshotMap(newSnapshot)))
                    .workerId(safeWorkerId())
                    .companyId(safeCompanyId())
                    .note(note)
                    .build();
            auditRepository.save(entry);
        } catch (Exception e) {
            // V234/audit P2: strukturalt error_code (VV-SEC-004) — a Loki/Grafana audit-keresés
            // error_code='VV-SEC-004' szerint lassa az audit-iras meghiusulasat. A Currency-modositas
            // mar megtortent (NEM dobunk/rollbackolunk — business operation > audit completeness rovid ideig).
            VV_LOG.error("VV-SEC-004", "currency.audit.write_failed", e,
                java.util.Map.of("action", action, "currencyCode", currency.getCode()));
        }
    }

    private Map<String, Object> snapshotMap(Currency c) {
        Map<String, Object> m = new java.util.HashMap<>();
        m.put("code", c.getCode());
        m.put("name", c.getName());
        m.put("symbol", c.getSymbol());
        m.put("decimalPlaces", c.getDecimalPlaces());
        m.put("displayOrder", c.getDisplayOrder());
        m.put("active", c.getActive());
        return m;
    }

    private Currency cloneForAudit(Currency c) {
        return Currency.builder()
                .id(c.getId())
                .code(c.getCode())
                .name(c.getName())
                .symbol(c.getSymbol())
                .decimalPlaces(c.getDecimalPlaces())
                .displayOrder(c.getDisplayOrder())
                .active(c.getActive())
                .build();
    }

    private Long safeWorkerId() {
        try {
            return SecurityUtils.getCurrentWorkerId();
        } catch (Exception e) {
            return null;
        }
    }

    private java.util.UUID safeCompanyId() {
        try {
            return SecurityUtils.getCurrentCompanyId();
        } catch (Exception e) {
            return null;
        }
    }
}
