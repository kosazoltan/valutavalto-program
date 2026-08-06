package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.CurrencyAuditLog;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.logging.VVLogger;
import hu.puzzleir.valuta.repository.CurrencyAuditLogRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
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
     * FK-074 FR-3 (2026-08-06): valuta-aktiváláskor automatikus cash_balance
     * inicializálás az aktív fiókokra (Értéktárakra is). Nincs körkörös függőség:
     * a CashBalanceService nem függ az AdminCurrencyService-től.
     */
    private final CashBalanceService cashBalanceService;

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
        // FK04 (FR-7): display_order egyediseg — a V318 UNIQUE constraint elott service-szinten
        // ellenorzunk, hogy beszedes 409 + VV-VALID-003 valaszt kapjon a Valutakezelo (ne 500-at).
        // Ha a hivo nem adott sorrendet, max+1-et osztunk ki (a korabbi fix 99 default a UNIQUE
        // mellett a masodik hianyzo-sorrendu felvetelnel utkozne).
        int resolvedDisplayOrder = displayOrder != null
                ? displayOrder
                : currencyRepository.findMaxDisplayOrder() + 1;
        if (currencyRepository.existsByDisplayOrder(resolvedDisplayOrder)) {
            VV_LOG.error("VV-VALID-003", "currency.create.duplicate_display_order", null,
                Map.of("code", upperCode, "displayOrder", resolvedDisplayOrder));
            throw new BusinessException(
                "A megjelenitesi sorrend (" + resolvedDisplayOrder + ") mar foglalt — valassz masik erteket",
                "VV-VALID-003", HttpStatus.CONFLICT);
        }
        Currency currency = Currency.builder()
                .code(upperCode)
                .name(name != null ? name.trim() : upperCode)
                .symbol(symbol)
                .decimalPlaces(decimalPlaces != null ? decimalPlaces : 2)
                .displayOrder(resolvedDisplayOrder)
                .active(true)
                .build();
        Currency saved;
        try {
            // saveAndFlush: a V318 UNIQUE constraint MOST serüljon (a metoduson belul), ne a
            // tranzakcio-commitnal — igy a konkurens eset is 409-et ad, nem 500-at.
            saved = currencyRepository.saveAndFlush(currency);
        } catch (org.springframework.dao.DataIntegrityViolationException e) {
            // Codex PR #1096 P2: ket parhuzamos createCurrency ugyanazt a resolvedDisplayOrder-t
            // szamolhatja ki (vagy ugyanazt a kodot szurna be) — az existsBy* eloszures atengedi,
            // a DB unique constraint kapja el. Ugyanaz a 409 + VV-VALID-003, mint az eloszuresnel.
            VV_LOG.error("VV-VALID-003", "currency.create.unique_constraint_conflict", e,
                Map.of("code", upperCode, "displayOrder", resolvedDisplayOrder));
            throw new BusinessException(
                "Egyideju valuta-felvetel utkozes: a kod vagy a megjelenitesi sorrend ("
                    + resolvedDisplayOrder + ") idokozben foglalt lett — probald ujra",
                "VV-VALID-003", HttpStatus.CONFLICT);
        }
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
        // FK-074 FR-3/FR-5 (2026-08-06): aktiváláskor automatikus 0-s cash_balance sorok
        // létrehozása MINDEN aktív fióknál (Értéktárakat is beleértve), idempotens módon.
        // Deaktiváláskor a meglévő sorok érintetlenek maradnak (FR-4) — ezért csak
        // aktív irányban hívjuk. NFR-4: ugyanabban a tranzakcióban fut (REQUIRED
        // propagáció), így az inicializálás hibája az egész aktiválást visszagörgeti.
        if (active) {
            cashBalanceService.initializeCurrencyBalancesForActiveBranches(saved);
        }
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
