package hu.puzzleir.valuta.logging;

import ch.qos.logback.classic.spi.ILoggingEvent;
import com.fasterxml.jackson.core.JsonGenerator;
import net.logstash.logback.composite.loggingevent.MessageJsonProvider;

import java.io.IOException;

/**
 * EBC Valutavalto - Logstash JSON encoder PII-redactor.
 *
 * <p>Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md (5.5)
 *
 * <p>Codex+Copilot PR #681 P0 fix: a {@code LogstashEncoder} NEM hasznalja a
 * Logback {@code PatternLayout}-ot, ezert a {@code %redact(%msg)} conversionRule
 * sosem fut a JSON-output-ra. Ez a osztaly direkten override-olja a
 * {@code message} mezo serialize-elaset, es a {@link RedactingPatternConverter#redact}
 * statikus metodussal moss el a PII-mintazatokat MIELOTT a JSON-be irodik.
 *
 * <p>A LogstashEncoder helyett a {@code LoggingEventCompositeJsonEncoder}
 * konfigja hivja ezt a provider-t (lasd logback-spring.xml).
 */
public class RedactingMessageJsonProvider extends MessageJsonProvider {

    @Override
    public void writeTo(JsonGenerator generator, ILoggingEvent event) throws IOException {
        String rawMessage = event.getFormattedMessage();
        String redacted = RedactingPatternConverter.redact(rawMessage);
        generator.writeStringField(getFieldName(), redacted);
    }
}
