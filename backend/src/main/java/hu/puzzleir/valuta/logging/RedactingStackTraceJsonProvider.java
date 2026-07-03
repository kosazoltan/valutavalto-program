package hu.puzzleir.valuta.logging;

import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.classic.spi.IThrowableProxy;
import com.fasterxml.jackson.core.JsonGenerator;
import net.logstash.logback.composite.loggingevent.StackTraceJsonProvider;
import net.logstash.logback.stacktrace.ShortenedThrowableConverter;

import java.io.IOException;

/**
 * EBC Valutavalto - stack-trace JSON serialize PII-redactor.
 *
 * <p>Codex+Copilot PR #681 P0 fix: a stack trace gyakran tartalmaz PII-t
 * (`Caused by: AuthFailure(token=...) `, kartya-szam, IBAN-mintazatok). A
 * {@code RedactingPatternConverter#redact} statikus metodusat futtatjuk
 * a serialized stack-en mielott a JSON-be kerul.
 * <p>Jackson 2 SZÁNDÉKOSAN: a logstash-logback-encoder 8.x Jackson 2-alapú,
 * ezért ezt a provider-signature-t NE migráld a #386 Jackson 3 flipben.</p>
 */
public class RedactingStackTraceJsonProvider extends StackTraceJsonProvider {

    private final ShortenedThrowableConverter throwableConverter = new ShortenedThrowableConverter();

    public RedactingStackTraceJsonProvider() {
        throwableConverter.start();
    }

    @Override
    public void writeTo(JsonGenerator generator, ILoggingEvent event) throws IOException {
        IThrowableProxy proxy = event.getThrowableProxy();
        if (proxy == null) return;
        String rendered = throwableConverter.convert(event);
        String redacted = RedactingPatternConverter.redact(rendered);
        generator.writeStringField(getFieldName(), redacted);
    }
}
