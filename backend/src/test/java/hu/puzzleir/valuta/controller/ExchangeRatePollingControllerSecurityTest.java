package hu.puzzleir.valuta.controller;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.prepost.PreAuthorize;

import java.lang.reflect.Method;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * F5 audit verification (2026-05-07): az exchange_rate_source globalis
 * rendszer-katalogus, de a forras URL-ek es hibak uzemeltetesi adatok.
 */
class ExchangeRatePollingControllerSecurityTest {

    @Test
    @DisplayName("GET /rates/polling/sources csak supervisor/manager/admin szerepkorrel elerheto")
    void getSourcesRequiresPrivilegedRole() throws NoSuchMethodException {
        Method method = ExchangeRatePollingController.class.getMethod("getSources");
        PreAuthorize annotation = method.getAnnotation(PreAuthorize.class);

        assertThat(annotation)
            .as("getSources endpointnek explicit role guard kell")
            .isNotNull();
        assertThat(annotation.value())
            .isEqualTo("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')");
    }
}
