package hu.puzzleir.valuta.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.core.io.support.ResourcePropertySource;
import org.springframework.mock.env.MockPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

class RatePrintProofConfigTest {

    @Test
    @DisplayName("app.rate-print.hmac-secret az APP_RATE_PRINT_HMAC_SECRET env-ből oldódik fel")
    void ratePrintSecretResolvesFromEnvVar() throws Exception {
        StandardEnvironment env = new StandardEnvironment();
        env.getPropertySources().addFirst(
                new MockPropertySource("fake-env")
                        .withProperty("APP_RATE_PRINT_HMAC_SECRET", "env-provided-secret"));
        env.getPropertySources().addLast(
                new ResourcePropertySource("classpath:application.properties"));

        assertThat(env.getProperty("app.rate-print.hmac-secret"))
                .isEqualTo("env-provided-secret");
    }

    @Test
    @DisplayName("env nélkül a property üres defaultra oldódik (dev random-fallback megmarad)")
    void ratePrintSecretDefaultsToBlankWithoutEnv() throws Exception {
        StandardEnvironment env = new StandardEnvironment();
        env.getPropertySources().addLast(
                new ResourcePropertySource("classpath:application.properties"));

        assertThat(env.getProperty("app.rate-print.hmac-secret")).isEmpty();
    }

    @Test
    @DisplayName("app.rate-print.hmac-secret-required az APP_RATE_PRINT_HMAC_SECRET_REQUIRED env-ből oldódik fel")
    void ratePrintSecretRequiredResolvesFromEnvVar() throws Exception {
        StandardEnvironment env = new StandardEnvironment();
        env.getPropertySources().addFirst(
                new MockPropertySource("fake-env")
                        .withProperty("APP_RATE_PRINT_HMAC_SECRET_REQUIRED", "true"));
        env.getPropertySources().addLast(
                new ResourcePropertySource("classpath:application.properties"));

        assertThat(env.getProperty("app.rate-print.hmac-secret-required", Boolean.class))
                .isTrue();
    }

    @Test
    @DisplayName("env nélkül a required flag false defaultra oldódik")
    void ratePrintSecretRequiredDefaultsToFalseWithoutEnv() throws Exception {
        StandardEnvironment env = new StandardEnvironment();
        env.getPropertySources().addLast(
                new ResourcePropertySource("classpath:application.properties"));

        assertThat(env.getProperty("app.rate-print.hmac-secret-required", Boolean.class))
                .isFalse();
    }
}
