package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ClientErrorLog;
import hu.puzzleir.valuta.repository.ClientErrorLogRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.regex.Pattern;

/**
 * Kritikus kliens-hibák AUTOMATIKUS GitHub Issue eskalálása.
 *
 * <p>2026-05-05 user-direktíva: a kollégák gépén történő hibákat NE
 * manuálisan kelljen lekérdezni. Ha kritikus mintázat (uncaughtException,
 * Network Error visszatérő minimum 3 felhasználón), automatikusan GitHub
 * issue-t nyitunk a Claude bot számára, aki AI-review-auto-fix workflow-val
 * reagálhat.</p>
 *
 * <p>Deduplikáció: ugyanazon "hiba-aláírás" (component + error_message első
 * 80 karakter) NEM hoz létre új issue-t, ha az utolsó 24 órán belül már
 * volt ilyen.</p>
 *
 * <p>Privacy: az issue body-ban NEM szerepel a user_identifier (Google email),
 * csak az OS, version, error_message, context (sanitized).</p>
 *
 * <p>Konfig:</p>
 * <ul>
 *   <li>{@code github.issue.auto-create.enabled} — true/false</li>
 *   <li>{@code github.issue.auto-create.token} — fine-grained PAT, repo:write scope</li>
 *   <li>{@code github.issue.auto-create.repo} — pl. "kosazoltan/valutavalto-program"</li>
 * </ul>
 */
@Service
@Slf4j
public class GitHubIssueAutoCreator {

    private static final Pattern CRITICAL_PATTERN = Pattern.compile(
            "(uncaughtException|unhandledRejection|Network Error|timeout|EHOSTUNREACH|ECONNREFUSED|setupWizard.*fail)",
            Pattern.CASE_INSENSITIVE);

    private final ClientErrorLogRepository errorLogRepository;
    private final HttpClient httpClient;
    private final boolean enabled;
    private final String token;
    private final String repo;

    public GitHubIssueAutoCreator(
            ClientErrorLogRepository errorLogRepository,
            @Value("${github.issue.auto-create.enabled:false}") boolean enabled,
            @Value("${github.issue.auto-create.token:}") String token,
            @Value("${github.issue.auto-create.repo:kosazoltan/valutavalto-program}") String repo) {
        this.errorLogRepository = errorLogRepository;
        this.enabled = enabled;
        this.token = token;
        this.repo = repo;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(8))
                .build();
        log.info("[GitHubIssueAutoCreator] enabled={}, repo={}", enabled, repo);
    }

    /**
     * Aszinkron eskalálás. Hívandó az új ClientErrorLog mentése után.
     */
    @Async
    public void evaluateAndEscalate(ClientErrorLog entry) {
        try {
            if (!enabled || token == null || token.isBlank()) {
                return;
            }
            if (!isCritical(entry)) {
                return;
            }
            if (isDuplicateRecent(entry)) {
                log.debug("[GitHubIssueAutoCreator] dedup match - skip issue create for: {}",
                        entry.getErrorMessage() == null ? "" : entry.getErrorMessage().replace("\r", "").replace("\n", " "));
                return;
            }
            createIssue(entry);
        } catch (Exception ex) {
            // Send-and-forget: az issue-letrehozas hibaja NEM bukhatja a hibajelentest
            log.warn("[GitHubIssueAutoCreator] eskala hiba: {}", ex.getMessage());
        }
    }

    private boolean isCritical(ClientErrorLog entry) {
        if (entry.getErrorMessage() == null) return false;
        return CRITICAL_PATTERN.matcher(entry.getErrorMessage()).find()
                || "electron-main".equals(entry.getComponent());
    }

    /**
     * Dedup: az utolsó 24 órán belül volt-e már ugyanilyen hiba-aláírás (component
     * + error_message első 80 char).
     */
    private boolean isDuplicateRecent(ClientErrorLog entry) {
        // Egyszerű in-memory check az utolsó 1000 bejegyzésen.
        // (Nagyobb forgalomhoz külön index + native query indokolt.)
        String signature = signatureOf(entry);
        LocalDateTime cutoff = LocalDateTime.now().minusHours(24);
        List<ClientErrorLog> recent = errorLogRepository.findAll(
                org.springframework.data.domain.PageRequest.of(0, 200,
                        org.springframework.data.domain.Sort.by(
                                org.springframework.data.domain.Sort.Direction.DESC, "createdAt")))
                .getContent();
        return recent.stream()
                .filter(r -> r.getCreatedAt() != null && r.getCreatedAt().isAfter(cutoff))
                .filter(r -> !r.getId().equals(entry.getId()))
                .anyMatch(r -> signatureOf(r).equals(signature));
    }

    private String signatureOf(ClientErrorLog entry) {
        String msg = entry.getErrorMessage() == null ? "" : entry.getErrorMessage();
        if (msg.length() > 80) msg = msg.substring(0, 80);
        return entry.getComponent() + "|" + msg;
    }

    private void createIssue(ClientErrorLog entry) throws Exception {
        String title = "[auto] " + truncate(entry.getErrorMessage(), 100)
                + " — " + entry.getComponent();
        String body = buildIssueBody(entry);
        String json = "{\"title\":" + jsonStr(title)
                + ",\"body\":" + jsonStr(body)
                + ",\"labels\":[\"client-error\",\"auto-reported\"]}";

        HttpRequest req = HttpRequest.newBuilder(URI.create("https://api.github.com/repos/" + repo + "/issues"))
                .header("Authorization", "Bearer " + token)
                .header("Accept", "application/vnd.github+json")
                .header("X-GitHub-Api-Version", "2022-11-28")
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(8))
                .POST(HttpRequest.BodyPublishers.ofString(json))
                .build();
        HttpResponse<String> resp = httpClient.send(req, HttpResponse.BodyHandlers.ofString());
        if (resp.statusCode() / 100 == 2) {
            log.info("[GitHubIssueAutoCreator] issue created for client-error #{}, response={}",
                    entry.getId(), resp.statusCode());
        } else {
            log.warn("[GitHubIssueAutoCreator] issue create failed: HTTP {}, body={}",
                    resp.statusCode(), truncate(resp.body(), 300));
        }
    }

    private String buildIssueBody(ClientErrorLog entry) {
        StringBuilder sb = new StringBuilder();
        sb.append("**Auto-eskalalt kliens hiba** (kosazoltan/valutavalto-program)\n\n");
        sb.append("| Mezo | Ertek |\n|------|-------|\n");
        sb.append("| ID | ").append(entry.getId()).append(" |\n");
        sb.append("| Idopont | ").append(entry.getCreatedAt()).append(" |\n");
        sb.append("| Komponens | `").append(safe(entry.getComponent())).append("` |\n");
        sb.append("| Verzio | `").append(safe(entry.getVersion())).append("` |\n");
        sb.append("| OS | `").append(safe(entry.getOsInfo())).append("` |\n");
        sb.append("\n## Hibauzenet\n```\n")
                .append(safe(entry.getErrorMessage()))
                .append("\n```\n");
        if (entry.getStackTrace() != null && !entry.getStackTrace().isBlank()) {
            sb.append("\n## Stack trace\n```\n")
                    .append(truncate(entry.getStackTrace(), 4000))
                    .append("\n```\n");
        }
        if (entry.getContextJson() != null) {
            sb.append("\n## Kontextus\n```json\n")
                    .append(truncate(entry.getContextJson(), 1500))
                    .append("\n```\n");
        }
        sb.append("\n---\n*Privacy: a user_identifier (Google email) NEM kerul ide. ")
                .append("SSH-zel barmikor lekerheto: `bash scripts/fetch-client-errors.sh detail ")
                .append(entry.getId()).append("`.*\n");
        return sb.toString();
    }

    private String safe(String s) { return s == null ? "" : s; }
    private String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, max);
    }

    /** Minimal JSON string escape — \", \\, \n, \r, \t. */
    private String jsonStr(String s) {
        if (s == null) return "\"\"";
        StringBuilder sb = new StringBuilder("\"");
        for (char c : s.toCharArray()) {
            switch (c) {
                case '"': sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                default:
                    if (c < 0x20) sb.append(String.format("\\u%04x", (int) c));
                    else sb.append(c);
            }
        }
        sb.append("\"");
        return sb.toString();
    }
}
