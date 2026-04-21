package hu.puzzleir.valuta.config;

/**
 * Production URL konstansok (v2.1.7 - AI review PR #97 Sourcery P2 fololdas).
 *
 * <p>Ez a Single Source of Truth a {@code https://excvaluta.com} hivatkozasokra
 * a Java kodban. Regebben a URL tobb helyen (ProblemDetailBuilder, @Value default-ok)
 * hardcoded volt — most minden innen olvasódik.</p>
 *
 * <p>Non-Java komponensek (frontend-react, penztar-client, launcher scripts, CI):
 * lasd {@code config/production-urls.json} a root-ban.</p>
 *
 * <p>Override: a {@code cors.allowed-origins} property es a
 * {@code GOOGLE_REDIRECT_URI} environment variable felulírhatja a default-okat
 * deploy-idoben (pl. custom domain vagy staging).</p>
 *
 * @since 2.1.7
 */
public final class ProductionUrls {

    /** Production domain (apex). */
    public static final String DOMAIN = "excvaluta.com";

    /** Production base URL (apex, HTTPS). */
    public static final String BASE_URL = "https://" + DOMAIN;

    /** Production www subdomain URL. */
    public static final String WWW_BASE_URL = "https://www." + DOMAIN;

    /** Production REST API root (v1). */
    public static final String API_URL = BASE_URL + "/api/v1";

    /** Production health-check endpoint (HTTP 200 ha eleresi). */
    public static final String HEALTH_URL = API_URL + "/auth/bootstrap-status";

    /** RFC 7807 Problem Details "type" URI base (pl. /errors/invalid-data). */
    public static final String TYPE_BASE = BASE_URL + "/errors";

    /** Hetzner primary failover DNS (CF-mentes, TTL 60s). */
    public static final String FALLBACK_PRIMARY = "https://primary." + DOMAIN;

    /** Scaleway standby DNS (CF-mentes, TTL 60s). */
    public static final String FALLBACK_SCALEWAY = "https://scaleway." + DOMAIN;

    private ProductionUrls() {
        // Utility class - nem instantialhato.
    }
}
