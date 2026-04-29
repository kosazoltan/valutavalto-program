package hu.puzzleir.valuta.config;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

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
 * `ObjectMapper`-en. Ezzel a Spring Boot 4 NEM probal property-bol bind-elni
 * Jackson 3 enum-okra, es a meglevo 39 fajl Jackson 2 import-ja tovabbra is
 * mukodik.</p>
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
     * stop-gap modulon keresztul.
     *
     * <p>A 3 setting (volt application.properties-ben):</p>
     * <ul>
     *   <li><code>WRITE_DATES_AS_TIMESTAMPS=false</code> — ISO-8601 formatum</li>
     *   <li><code>setTimeZone(UTC)</code> — minden datum UTC-ben serializalva</li>
     *   <li><code>setSerializationInclusion(NON_NULL)</code> — null mezok elhagyasa</li>
     * </ul>
     *
     * <p>Plusz: <code>JavaTimeModule</code> regisztracio (LocalDateTime, Instant
     * stb.) + <code>FAIL_ON_UNKNOWN_PROPERTIES=false</code> a kompatibilitashoz.</p>
     *
     * <p><code>@Primary</code> annotacio garantalja, hogy a Spring Boot 4 stop-gap
     * modul auto-konfiguracioja helyett ezt a bean-t hasznaljak az injection-ok.</p>
     */
    @Bean
    @Primary
    public ObjectMapper objectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        mapper.disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);
        mapper.setTimeZone(TimeZone.getTimeZone("UTC"));
        mapper.setSerializationInclusion(JsonInclude.Include.NON_NULL);
        mapper.registerModule(new JavaTimeModule());
        return mapper;
    }
}
