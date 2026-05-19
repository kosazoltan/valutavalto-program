package hu.puzzleir.valuta.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.CurrencyAuditLog;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
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
        log.info("AdminCurrency: uj valuta letrehozva code={} name={} workerId={}",
            saved.getCode(), saved.getName(), safeWorkerId());
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
        log.info("AdminCurrency: {} code={} workerId={} note={}",
            action, currency.getCode(), safeWorkerId(), note);
        return saved;
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
            log.error("AdminCurrency: audit log write FAILED for action={} code={}",
                action, currency.getCode(), e);
            // NEM dobunk — a Currency modositas mar megtortent. Az audit-fail
            // logolva, de a tranzakcio nem rolled back (kompromisszum: business
            // operation > audit completeness rovid ideig).
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
