package hu.puzzleir.valuta.config;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jdk8.Jdk8Module;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.fasterxml.jackson.module.paramnames.ParameterNamesModule;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;

import java.util.TimeZone;

/**
 * Jackson 2 ObjectMapper konfiguracio (Spring Boot 4 sprint, 2026-04-29).
 *
 * <p><b>Hatter:</b> a 04-27 production outage-t (#247 hotfix-revert) a
 * `spring.jackson.serialization.*` properties Spring Boot 4-ben Jackson 3
 * (`tools.jackson.*`) enum-okra bind-elese okozta. A
 * `spring.jackson.use-jackson2-defaults=true` stop-gap modul aktivalja a
 * Jackson 2 ObjectMapper-t, de a property-bind-et NEM oldja meg.</p>
 *
 * <p><b>Megoldas:</b> a 3 problematic property-t kivettuk az
 * application.properties-bol es itt programmatic-an allitjuk be a Jackson 2
 * `ObjectMapper`-en a `Jackson2ObjectMapperBuilder`-en keresztul (Sourcery
 * PR #263 P2 ajanlas). Igy orokoljuk a Spring Boot/Web common Jackson modul-
 * regisztraciot (parameter names, JDK 8 Optional, Java time) plusz a 3
 * critical override-ot.</p>
 *
 * <p><b>Future work:</b> egy nagyobb refaktor PR-ben a teljes Jackson 3
 * migracio (`tools.jackson.*` import-ok + ObjectMapper API breaking changes)
 * — utana ez a config + a `spring.jackson.use-jackson2-defaults` torolheto.</p>
 *
 * @since 2.4.0 (Spring Boot 4)
 */
@Configuration
public class JacksonConfig {

    /**
     * Primary ObjectMapper bean — Jackson 2 API a `spring-boot-jackson2`
     * stop-gap modulon keresztul, `Jackson2ObjectMapperBuilder`-rel epitve.
     *
     * <p><b>Modulok</b> (Spring Boot defaults + projekt-specifikus):</p>
     * <ul>
     *   <li>{@link JavaTimeModule} — LocalDateTime, Instant, ZonedDateTime ISO-8601</li>
     *   <li>{@link Jdk8Module} — Optional, Stream support</li>
     *   <li>{@link ParameterNamesModule} — constructor parameter names (Java 8+)</li>
     * </ul>
     *
     * <p><b>Override-ok</b> (volt application.properties-ben):</p>
     * <ul>
     *   <li><code>WRITE_DATES_AS_TIMESTAMPS=false</code> — ISO-8601 formatum</li>
     *   <li><code>setTimeZone(UTC)</code> — minden datum UTC-ben serializalva</li>
     *   <li><code>setSerializationInclusion(NON_NULL)</code> — null mezok elhagyasa</li>
     *   <li><code>FAIL_ON_UNKNOWN_PROPERTIES=false</code> — kompatibilitas</li>
     * </ul>
     *
     * <p><code>@Primary</code> annotacio garantalja, hogy a Spring Boot 4 stop-gap
     * modul auto-konfiguracioja helyett ezt a bean-t hasznaljak az injection-ok.</p>
     */
    @Bean
    @Primary
    public ObjectMapper objectMapper() {
        return Jackson2ObjectMapperBuilder.json()
            .modules(
                new JavaTimeModule(),
                new Jdk8Module(),
                new ParameterNamesModule()
            )
            .featuresToDisable(
                SerializationFeature.WRITE_DATES_AS_TIMESTAMPS,
                DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES
            )
            .timeZone(TimeZone.getTimeZone("UTC"))
            .serializationInclusion(JsonInclude.Include.NON_NULL)
            .build();
    }
}
