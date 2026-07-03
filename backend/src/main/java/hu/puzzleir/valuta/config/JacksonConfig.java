package hu.puzzleir.valuta.config;

import com.fasterxml.jackson.annotation.JsonInclude;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import tools.jackson.databind.DeserializationFeature;
import tools.jackson.databind.cfg.DateTimeFeature;
import tools.jackson.databind.json.JsonMapper;

import java.util.TimeZone;

/**
 * Jackson 3 JsonMapper configuration (Spring Boot 4 sprint, 2026-07-03).
 *
 * <p>Background: the 04-27 production outage was caused by Spring Boot 4
 * binding {@code spring.jackson.serialization.*} properties to Jackson enums.
 * To avoid that property-binding failure class, JSON behavior is configured
 * programmatically here instead of in {@code application.properties}.</p>
 *
 * <p>Jackson 3 includes Java Time / JDK8 / parameter-name support in databind,
 * so no Jackson 2 datatype modules are registered here.</p>
 *
 * @since 2.4.0 (Spring Boot 4)
 */
@Configuration
public class JacksonConfig {

    /** Default time zone for serialized timestamps (legacy {@code spring.jackson.time-zone=UTC}). */
    private static final TimeZone DEFAULT_TIME_ZONE = TimeZone.getTimeZone("UTC");

    /** Omit {@code null} fields (legacy {@code spring.jackson.default-property-inclusion=non_null}). */
    private static final JsonInclude.Include DEFAULT_INCLUSION = JsonInclude.Include.NON_NULL;

    /**
     * Primary Jackson 3 {@link JsonMapper} bean.
     *
     * <p>Explicitly preserves the legacy JSON contract: ISO-8601 dates, unknown
     * properties tolerated for forward compatibility, UTC default time zone, and
     * null-valued properties omitted.</p>
     */
    @Bean
    @Primary
    public JsonMapper jsonMapper() {
        return JsonMapper.builder()
            .disable(DateTimeFeature.WRITE_DATES_AS_TIMESTAMPS)
            .disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES)
            .defaultTimeZone(DEFAULT_TIME_ZONE)
            .changeDefaultPropertyInclusion(inclusion ->
                inclusion.withValueInclusion(DEFAULT_INCLUSION))
            .build();
    }
}
