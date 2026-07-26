package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.supervisor.SupervisorAuthRequest;
import hu.puzzleir.valuta.service.SupervisorService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

import java.lang.reflect.Method;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;

@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = SupervisorControllerSecurityTest.TestConfig.class)
class SupervisorControllerSecurityTest {

    private static final String REQUIRED_AUTH =
            "hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')";

    @Autowired private SupervisorController controller;
    @Autowired private SupervisorService service;

    @BeforeEach
    void setUp() {
        reset(service);
    }

    @Test
    void everyHandlerMethodHasSupervisorRoles() {
        Stream.of(SupervisorController.class.getDeclaredMethods())
                .filter(SupervisorControllerSecurityTest::isHandlerMethod)
                .forEach(method -> {
                    PreAuthorize preAuthorize = method.getAnnotation(PreAuthorize.class);
                    assertThat(preAuthorize)
                            .as(method.getName() + " must be protected")
                            .isNotNull();
                    assertThat(preAuthorize.value()).isEqualTo(REQUIRED_AUTH);
                });
    }

    @Test
    @WithMockUser(roles = "CASHIER")
    void authenticate_deniesCashierBeforeServiceCall() {
        SupervisorAuthRequest request = new SupervisorAuthRequest();
        request.setPassword("test-password");

        assertThrows(AccessDeniedException.class, () -> controller.authenticate(request));

        verify(service, never()).authenticate(any());
    }

    @Test
    @WithMockUser(roles = "SUPERVISOR")
    void authenticate_allowsSupervisorAndDelegates() {
        SupervisorAuthRequest request = new SupervisorAuthRequest();
        request.setPassword("test-password");

        controller.authenticate(request);

        verify(service).authenticate("test-password");
    }

    private static boolean isHandlerMethod(Method method) {
        return method.isAnnotationPresent(GetMapping.class)
                || method.isAnnotationPresent(PostMapping.class);
    }

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        SupervisorService supervisorService() {
            return mock(SupervisorService.class);
        }

        @Bean
        SupervisorController supervisorController(SupervisorService service) {
            return new SupervisorController(service);
        }
    }
}
