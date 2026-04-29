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
 * Jackson 2 ObjectMapper configuration (Spring Boot 4 sprint, 2026-04-29).
 *
 * <p>Background: the 04-27 production outage was caused by Spring Boot 4
 * binding {@code spring.jackson.serialization.*} properties to Jackson 3
 * ({@code tools.jackson.*}) enums. The {@code spring-boot-jackson2}
 * stop-gap module activates the Jackson 2 ObjectMapper but does not solve
 * the property binding. Solution: removed the 3 problematic properties
 * from application.properties and configure them programmatically here
 * via {@link Jackson2ObjectMapperBuilder} (extends Spring Boot defaults).
 * Future work: full Jackson 3 migration ({@code tools.jackson.*} imports)
 * will allow removing this config and {@code spring.jackson.use-jackson2-defaults}.</p>
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
     * Disabled serialization features:
     * ISO-8601 timestamps instead of epoch millis
     * (legacy {@code spring.jackson.serialization.write-dates-as-timestamps=false}).
     */
    private static final SerializationFeature[] DISABLED_SER_FEATURES = {
        SerializationFeature.WRITE_DATES_AS_TIMESTAMPS,
    };

    /**
     * Disabled deserialization features:
     * tolerate unknown properties for forward compatibility
     * (e.g., a v2.x client receiving a v3.x payload with extra fields).
     */
    private static final DeserializationFeature[] DISABLED_DESER_FEATURES = {
        DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES,
    };

    /**
     * Primary {@link ObjectMapper} bean.
     *
     * <p>{@code modulesToInstall} extends Spring Boot's default module set
     * (so any Boot-provided modules like JsonComponentModule or future Kotlin
     * support are preserved) and adds: {@link JavaTimeModule},
     * {@link Jdk8Module}, {@link ParameterNamesModule}.</p>
     *
     * <p>{@code @Primary} ensures injection points use this bean instead of
     * the {@code spring-boot-jackson2} stop-gap auto-configuration.</p>
     */
    @Bean
    @Primary
    public ObjectMapper objectMapper() {
        return Jackson2ObjectMapperBuilder.json()
            .modulesToInstall(
                JavaTimeModule.class,
                Jdk8Module.class,
                ParameterNamesModule.class
            )
            .featuresToDisable(DISABLED_SER_FEATURES)
            .featuresToDisable(DISABLED_DESER_FEATURES)
            .timeZone(DEFAULT_TIME_ZONE)
            .serializationInclusion(DEFAULT_INCLUSION)
            .build();
    }
}
