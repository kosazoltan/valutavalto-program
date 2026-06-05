package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.repository.EmailCacheRepository;
import hu.puzzleir.valuta.service.EmailAccountService;
import hu.puzzleir.valuta.service.GmailApiService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;

/**
 * RBAC-audit (2026-06-05): az EmailController osztály-szintű {@code @PreAuthorize} korábban CSAK
 * {@code isAuthenticated()} volt → bármely belépett user (pl. pénztáros) olvashatta a postaláda-
 * üzeneteket közvetlen API-hívással. Mostantól {@code hasAnyRole('ADMIN','MANAGER','UGYVEZETO',
 * 'IRODAVEZETO')} (az /email-settings menü-szerepkörök + admin). Ez a teszt a method-security
 * enforcement-et verifikálja (a @PreAuthorize interceptor a metódus-test ELŐTT dob a tiltott
 * szerepköröknél; az engedélyezetteknél átengedi — a body más okból eshet el, de NEM AccessDenied).
 */
@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = EmailControllerSecurityWebMvcTest.TestConfig.class)
class EmailControllerSecurityWebMvcTest {

    @Autowired
    private EmailController emailController;

    @Configuration
    @EnableMethodSecurity
    static class TestConfig {
        @Bean
        EmailAccountService emailAccountService() {
            return mock(EmailAccountService.class);
        }

        @Bean
        GmailApiService gmailApiService() {
            return mock(GmailApiService.class);
        }

        @Bean
        EmailCacheRepository emailCacheRepository() {
            return mock(EmailCacheRepository.class);
        }

        @Bean
        EmailController emailController(EmailAccountService a, GmailApiService g, EmailCacheRepository r) {
            return new EmailController(a, g, r);
        }
    }

    @Test
    @DisplayName("AuthZ: CASHIER TILTOTT a postaláda-olvasásra (AccessDenied a gate-en)")
    @WithMockUser(roles = "CASHIER")
    void getUnreadCount_forbiddenForCashier() {
        assertThrows(AccessDeniedException.class, () -> emailController.getUnreadCount(null));
    }

    @Test
    @DisplayName("AuthZ: PENZTAR TILTOTT a postaláda-olvasásra")
    @WithMockUser(roles = "PENZTAR")
    void getUnreadCount_forbiddenForPenztar() {
        assertThrows(AccessDeniedException.class, () -> emailController.getUnreadCount(null));
    }

    @Test
    @DisplayName("AuthZ: UGYVEZETO ÁTENGEDVE a gate-en (nem AccessDenied)")
    @WithMockUser(roles = "UGYVEZETO")
    void getUnreadCount_allowedForUgyvezeto() {
        // A gate átengedi → a body fut; @WithMockUser kontextusban a getAuthDetails(null) más
        // hibát dob, de NEM AccessDeniedException → bizonyítja, hogy a szerepkör átment a kapun.
        Throwable t = catchThrowable(() -> emailController.getUnreadCount(null));
        assertThat(t).isNotInstanceOf(AccessDeniedException.class);
    }

    @Test
    @DisplayName("AuthZ: ADMIN ÁTENGEDVE a gate-en")
    @WithMockUser(roles = "ADMIN")
    void getUnreadCount_allowedForAdmin() {
        Throwable t = catchThrowable(() -> emailController.getUnreadCount(null));
        assertThat(t).isNotInstanceOf(AccessDeniedException.class);
    }
}
