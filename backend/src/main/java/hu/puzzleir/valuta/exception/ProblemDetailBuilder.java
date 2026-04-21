package hu.puzzleir.valuta.exception;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import hu.puzzleir.valuta.config.ProductionUrls;

import java.net.URI;
import java.time.Instant;

/**
 * RFC 7807 ProblemDetail builder - egyseges, szabvanyos hibaformatum
 * minden uj endpoint + @ExceptionHandler reszere.
 *
 * <p>A vezerlokonyv par.7.5 szerint: type, title, status, detail, instance
 * mezok minden hibanal. A "type" URI azonosito, ami a hiba kategoriat irja le
 * (statikus dokumentacios link is lehet).</p>
 *
 * <p>Pelda hasznalat egy @RestController-ben:</p>
 * <pre>{@code
 *   if (!hasPermission) {
 *       throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Nincs jog");
 *   }
 * }</pre>
 *
 * <p>Vagy kozvetlenul:</p>
 * <pre>{@code
 *   @ExceptionHandler(MyException.class)
 *   public ProblemDetail handle(MyException e, HttpServletRequest req) {
 *       return ProblemDetailBuilder.of(HttpStatus.BAD_REQUEST, req)
 *           .title("Hibas adat")
 *           .detail(e.getMessage())
 *           .type("https://excvaluta.com/errors/invalid-data")
 *           .property("field", e.getField())
 *           .build();
 *   }
 * }</pre>
 */
public final class ProblemDetailBuilder {

    /**
     * Alap domain az RFC 7807 "type" mezo URI-jaihoz.
     * Production-ban a type URI egy valos dokumentacios oldalra mutathat.
     */
    /** @deprecated hasznaljuk {@link ProductionUrls#TYPE_BASE}-t. Itt a backward-compat alias. */
    public static final String TYPE_BASE = ProductionUrls.TYPE_BASE;

    private final ProblemDetail pd;

    private ProblemDetailBuilder(HttpStatus status, HttpServletRequest request) {
        this.pd = ProblemDetail.forStatus(status);
        this.pd.setProperty("timestamp", Instant.now().toString());
        if (request != null) {
            this.pd.setInstance(URI.create(request.getRequestURI()));
            String traceId = request.getHeader("X-Trace-Id");
            if (traceId != null && !traceId.isBlank()) {
                this.pd.setProperty("traceId", traceId);
            }
        }
    }

    public static ProblemDetailBuilder of(HttpStatus status, HttpServletRequest request) {
        return new ProblemDetailBuilder(status, request);
    }

    public static ProblemDetailBuilder of(HttpStatus status) {
        return new ProblemDetailBuilder(status, null);
    }

    public ProblemDetailBuilder title(String title) {
        pd.setTitle(title);
        return this;
    }

    public ProblemDetailBuilder detail(String detail) {
        pd.setDetail(detail);
        return this;
    }

    /** Abszolut URI vagy slug (TYPE_BASE-hez csatlakoztat). */
    public ProblemDetailBuilder type(String typeOrSlug) {
        if (typeOrSlug == null) return this;
        String uri = typeOrSlug.startsWith("http://") || typeOrSlug.startsWith("https://")
            ? typeOrSlug
            : TYPE_BASE + "/" + typeOrSlug.replaceAll("^/+", "");
        pd.setType(URI.create(uri));
        return this;
    }

    public ProblemDetailBuilder property(String key, Object value) {
        pd.setProperty(key, value);
        return this;
    }

    public ProblemDetail build() {
        return pd;
    }
}
