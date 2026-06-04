package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.AmlApprovalGrant;
import hu.puzzleir.valuta.entity.TransactionAmlApproval;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.AmlApprovalGrantRepository;
import hu.puzzleir.valuta.repository.TransactionAmlApprovalRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * AML felsővezetői jóváhagyás rögzítő szolgáltatás (Pmt. 14/A. § (4), 14/2025. MNB rendelet V.2.6).
 *
 * <p>A magas kockázatú esetekben (FATF 1/a, magas-kockázatú harmadik ország ≥5M Ft, PEP, éves limit)
 * a tranzakció kizárólag a kijelölt felelős vezető (supervisor/manager/admin) jóváhagyásával
 * teljesíthető. Ez a szolgáltatás validálja az engedélyező jogosultságát és INSERT-only audit-rekordba
 * rögzíti az engedélyező NEVÉT (a szabályzat V.2.6 4. lépése + 8 éves megőrzés).</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AmlApprovalService {

    private final WorkerRepository workerRepository;
    private final TransactionAmlApprovalRepository approvalRepository;
    private final AmlApprovalGrantRepository grantRepository;

    /** A jóváhagyásra jogosult worker-szerepek (Pmt. 14/A. § (4): kijelölt felelős vezető). */
    private static final Set<WorkerRole> SENIOR_APPROVER_ROLES =
            EnumSet.of(WorkerRole.SUPERVISOR, WorkerRole.MANAGER, WorkerRole.ADMIN);

    /** Az engedély (grant) érvényessége — bőven fedi a local-first offline → sync késleltetést. */
    private static final int GRANT_VALIDITY_DAYS = 7;

    /**
     * Egy PIN-ből kiállított grant felhasználási kapuja = {@code 1} (SINGLE-USE, server-fix — NEM a klienstől).
     *
     * <p><b>Codex P1 — „Derive grant use count on the server":</b> a korábbi klienstől-jövő {@code grantUses}
     * count amplifikálható volt (egy kompromittált renderer 6-ot küldhetett, majd a kliens-választott
     * {@code approvalSessionId}-t újrahasználva 6 nem-összefüggő tranzakciót hagyhatott jóvá egy PIN-ből). A
     * grant ezért SINGLE-USE, és a konkrét JÓVÁHAGYOTT ÜGYFÉLHEZ kötött ({@code customerKey}).</p>
     *
     * <p><b>Multi-line a kliens-count nélkül:</b> a penztar-client a multi-line nyugtát N független single-line
     * tranzakcióként synkronizálja, mind UGYANAZT az ügyfelet ÉS sessiont viszi. Az ELSŐ sor elhasználja az
     * egyetlen grantot és rögzíti a jóváhagyást; a többi sor (ugyanaz a session ÉS ugyanaz a
     * {@code customerKey}) JÓVÁHAGYÁS-FEDETTKÉNT átmegy újabb grant nélkül (nincs „kimerült" elhasalás). Egy
     * MÁS ügyfélre újrahasznált session viszont elbukik (customer-eltérés) → a „nem-összefüggő tranzakciók"
     * amplifikáció megszűnik. A jóváhagyás-audit így nyugtánként EGYSZER keletkezik (a tényleges
     * jóváhagyás-esemény = egy supervisor-PIN egy ügyfél nyugtájához). A consume {@code @Transactional}:
     * rollbacknél (retry) a felhasználás visszagördül.</p>
     */
    private static final int GRANT_USES_PER_PIN = 1;

    /**
     * Felsővezetői AML-jóváhagyás rögzítése. Validálja, hogy az {@code approverWorkerId} érvényes,
     * az aktuális céghez tartozó, supervisor-vagy-feljebb dolgozó, ÉS nem a tranzakciót rögzítő
     * pénztáros (4-szem-elv); majd INSERT-only audit-rekordba rögzíti az engedélyező NEVÉT.
     * Érvénytelen/hiányzó engedélyezőnél {@link ValidationException}.
     *
     * <p><b>Tranzakcionalitás:</b> a rögzítés a hívó tranzakció-flow tranzakcióján belül fut
     * ({@code REQUIRED}), így ha a tranzakció később rollbackel, a jóváhagyás-rekord is visszagördül —
     * azaz audit-rekord csak ténylegesen létrejött (committed) magas-kockázatú tranzakcióhoz tartozik,
     * nincs orphan jóváhagyás technikailag elhasalt kísérletekhez.</p>
     *
     * @return a rögzített jóváhagyás (az engedélyező nevével).
     */
    @Transactional
    public TransactionAmlApproval recordSeniorApproval(Long approverWorkerId, String approvalReason,
            BigDecimal hufAmount, String customerName, String receiptNumber, String approvalSessionId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
        Worker approver = resolveSeniorApprover(approverWorkerId, companyId);
        // PIN-jelenlét bizonyítása (Codex P1): csak akkor rögzítünk jóváhagyást, ha a /verify-approver
        // a supervisor-PIN sikeres ellenőrzésekor létrehozott egy grantot erre a (cég, pénztáros,
        // engedélyező, approval-session, ÜGYFÉL) ötösre. A grant SINGLE-USE és a jóváhagyott ügyfélhez
        // kötött, így (a) egy bare approverWorkerId-vel nem forgeolható az audit, (b) a session nem
        // hasznosítható újra MÁS ügyfél tranzakciójára. Az első sor atomikusan elhasználja a grantot; a
        // multi-line nyugta sibling sorai (ugyanaz a session+ügyfél) FEDETTEK (újabb grant nélkül).
        boolean grantConsumed = consumeApprovalGrant(approverWorkerId, companyId, approvalSessionId, customerName);

        // Codex P1: MINDEN magas-kockázatú tranzakció (a fedett sibling sor IS) KAP audit-rekordot — a
        // Pmt./MNB V.2.6 8 éves megőrzés szerint minden jóváhagyott tranzakció EGYÉNILEG visszakövethető kell
        // legyen (nincs csendben átengedett, auditálatlan magas-kockázatú tranzakció). A "covered" sornál csak
        // a grant-felhasználás marad el (single-use), az audit nem.
        TransactionAmlApproval rec = TransactionAmlApproval.builder()
                .companyId(companyId)
                .branchId(branchId)
                .receiptNumber(receiptNumber)
                .hufAmount(hufAmount)
                .customerName(customerName)
                .approvalReason(approvalReason != null ? approvalReason : "AML felsővezetői jóváhagyás")
                .approvedByWorkerId(approverWorkerId)
                .approvedByName(safeName(approver))
                .approvedAt(LocalDateTime.now())
                .build();
        TransactionAmlApproval saved = approvalRepository.save(rec);
        // Az engedélyező NEVE az audit-rekordba kerül (V.2.6 kötelező); a sima app-logba viszont csak
        // a workerId — a teljes név PII, ne szivárogjon a Loki/Grafana log-streambe. Az indokot a MENTETT
        // rekordból logoljuk, hogy a log és az audit-rekord konzisztens legyen (a default-feloldás után).
        log.info("[AML-APPROVAL] Felsővezetői jóváhagyás rögzítve ({}) — engedélyező #{}, indok: {}",
                grantConsumed ? "grant elhasználva" : "fedett sibling sor", approverWorkerId, saved.getApprovalReason());
        return saved;
    }

    /**
     * Engedély-grant kiállítása a supervisor-PIN SIKERES ellenőrzése után (a verify-approver hívja).
     * A grant bizonyítja, hogy az {@code approverWorkerId} PIN-nel igazolta a jelenlétét a bejelentkezett
     * (rögzítő) pénztáros sessionjében; a tranzakció-rögzítéskor a grant {@code usesRemaining}-je csökken.
     *
     * <p>Codex P1: EGY SINGLE-USE grant ({@link #GRANT_USES_PER_PIN}=1), a konkrét JÓVÁHAGYOTT ÜGYFÉLHEZ
     * ({@code customerKey}) ÉS a {@code sessionId}-hez kötve. A count NEM a klienstől jön (nincs grantUses
     * amplifikáció). A fel nem használt grant 7 nap múlva lejár.</p>
     *
     * @param customerKey a jóváhagyott ügyfél neve (a modal küldi) — a consume ehhez köti a fedett sorokat;
     *                    {@code null}/üres esetén nincs ügyfél-kötés (defenzív, de a modal mindig küldi).
     */
    @Transactional
    public void issueApprovalGrant(Long approverWorkerId, String sessionId, String customerKey) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long cashierWorkerId = SecurityUtils.getCurrentWorkerId();
        LocalDateTime now = LocalDateTime.now();
        grantRepository.save(AmlApprovalGrant.builder()
                .companyId(companyId)
                .cashierWorkerId(cashierWorkerId)
                .approverWorkerId(approverWorkerId)
                .sessionId(sessionId)
                .customerKey(normalizeKey(customerKey))
                .createdAt(now)
                .expiresAt(now.plusDays(GRANT_VALIDITY_DAYS))
                .usesRemaining(GRANT_USES_PER_PIN)
                .build());
        log.info("[AML-APPROVAL] Grant kiállítva (single-use, session {}, ügyfél-kötött) — engedélyező #{}, pénztáros #{}",
                sessionId, approverWorkerId, cashierWorkerId);
    }

    /**
     * Egy SINGLE-USE, le nem járt, az ÜGYFÉLHEZ kötött grant ATOMIKUS elhasználása a
     * (cég, pénztáros, engedélyező, session) négyesre. Codex P1: a grant a jóváhagyott ügyfélhez kötött, így
     * a kliens-választott session nem hasznosítható újra MÁS ügyfél tranzakciójára.
     *
     * <p>Visszatérés:</p>
     * <ul>
     *   <li>{@code true} (CONSUMED): volt felhasználható grant (uses&gt;0) az ügyfélhez → atomikusan
     *       elhasználva, a hívó RÖGZÍTSE a jóváhagyás-auditot.</li>
     *   <li>{@code false} (ALREADY_COVERED): a grant már kimerült, de LÉTEZIK az ügyfélhez+sessionhöz (egy
     *       multi-line nyugta sibling sora) → a jóváhagyás már rögzítve, a hívó NE rögzítsen duplán.</li>
     * </ul>
     *
     * <p>{@link ValidationException}: ha nincs (le nem járt) grant a sessionhöz (forge / PIN nélkül), VAGY a
     * session egy MÁS ügyfélhez tartozó granthoz van kötve (újrahasznált session) — utóbbi az amplifikáció-gát.</p>
     */
    private boolean consumeApprovalGrant(Long approverWorkerId, UUID companyId, String approvalSessionId,
            String customerName) {
        if (approvalSessionId == null || approvalSessionId.isBlank()) {
            throw new ValidationException("AML jóváhagyás PIN-ellenőrzés nélkül nem rögzíthető "
                    + "(hiányzó jóváhagyás-session). Kérjen jóváhagyást az engedélyező supervisor-PIN-jével.");
        }
        Long cashierWorkerId = SecurityUtils.getCurrentWorkerId();
        String custKey = normalizeKey(customerName);
        List<AmlApprovalGrant> grants = grantRepository.findActiveBySessionScope(
                companyId, cashierWorkerId, approverWorkerId, approvalSessionId, LocalDateTime.now());
        if (grants.isEmpty()) {
            throw new ValidationException("AML jóváhagyás PIN-ellenőrzés nélkül nem rögzíthető "
                    + "(hiányzó vagy lejárt engedély). Kérjen jóváhagyást az engedélyező supervisor-PIN-jével.");
        }
        // Ügyfél-kötés (Codex P1): csak az AZONOS ügyfélhez kötött grantok érvényesek erre a tranzakcióra.
        // A NULL customer_key-ű (régi, V294) grant bármely ügyfélre érvényes (visszafele-kompatibilitás).
        List<AmlApprovalGrant> matching = grants.stream()
                .filter(g -> g.getCustomerKey() == null || g.getCustomerKey().equals(custKey))
                .toList();
        if (matching.isEmpty()) {
            throw new ValidationException("AML jóváhagyás nem érvényes erre az ügyfélre "
                    + "(a jóváhagyás-session másik ügyfélhez tartozik). Kérjen jóváhagyást ehhez a nyugtához.");
        }
        // Atomikus single-use elhasználás: az első felhasználható grant a hívóé lesz (CONSUMED).
        for (AmlApprovalGrant g : matching) {
            if (grantRepository.decrementIfAvailable(g.getId()) == 1) {
                return true; // CONSUMED — a hívó rögzíti az auditot
            }
        }
        // Nincs felhasználható (mind 0), DE létezik az ügyfélhez+sessionhöz → multi-line sibling sor: FEDETT.
        return false; // ALREADY_COVERED — a jóváhagyás már rögzítve, nincs új audit
    }

    /** Ügyfél-kulcs normalizálása (trim); üres → {@code null}. A grant és a consume ugyanígy normalizál. */
    private static String normalizeKey(String customerKey) {
        if (customerKey == null) {
            return null;
        }
        String trimmed = customerKey.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    /** True, ha az adott worker (az aktuális cégben) jogosult AML felsővezetői jóváhagyásra. */
    public boolean isValidSeniorApprover(Long workerId) {
        if (workerId == null) {
            return false;
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return workerRepository.findById(workerId)
                .filter(w -> w.getCompany() != null && companyId.equals(w.getCompany().getId()))
                .map(w -> w.getRole() != null && SENIOR_APPROVER_ROLES.contains(w.getRole()))
                .orElse(false);
    }

    private Worker resolveSeniorApprover(Long approverWorkerId, UUID companyId) {
        if (approverWorkerId == null) {
            throw new ValidationException("AML felsővezetői jóváhagyás szükséges, de nincs megadva az engedélyező.");
        }
        // 4-szem-elv (Pmt. 14/A. § (4)): az engedélyező NEM lehet a tranzakciót rögzítő pénztáros — nincs
        // implicit self-approval kiskapu. (A POS-on bejelentkezett dolgozó workerId-ját hasonlítjuk össze.)
        Long currentWorkerId = SecurityUtils.getCurrentWorkerId();
        if (currentWorkerId != null && currentWorkerId.equals(approverWorkerId)) {
            throw new ValidationException(
                    "Az AML-engedélyező nem lehet a tranzakciót rögzítő dolgozó (4-szem-elv).");
        }
        Worker approver = workerRepository.findById(approverWorkerId)
                .orElseThrow(() -> new ValidationException(
                        "Az AML-engedélyező nem található (workerId=" + approverWorkerId + ")."));
        // Multi-tenant: az engedélyező az aktuális céghez tartozzon.
        if (approver.getCompany() == null || !companyId.equals(approver.getCompany().getId())) {
            throw new ValidationException("Az AML-engedélyező nem ehhez a céghez tartozik.");
        }
        if (approver.getRole() == null || !SENIOR_APPROVER_ROLES.contains(approver.getRole())) {
            throw new ValidationException("Az engedélyező (" + safeName(approver)
                    + ") nem jogosult AML felsővezetői jóváhagyásra (supervisor/manager/admin szükséges).");
        }
        return approver;
    }

    private static String safeName(Worker w) {
        return w.getName() != null && !w.getName().isBlank() ? w.getName() : ("#" + w.getId());
    }
}
