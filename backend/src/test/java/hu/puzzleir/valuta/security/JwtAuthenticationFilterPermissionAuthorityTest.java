package hu.puzzleir.valuta.security;

import hu.puzzleir.valuta.service.TokenBlacklistService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

/**
 * Audit P0.4 (2026-05-03) regressziovedelem.
 *
 * <p>Bizonyitja, hogy a `JwtAuthenticationFilter` a JWT `permissions` claim
 * minden elemet `SimpleGrantedAuthority`-ve alakitja a Spring Security
 * Authentication-jeben — enelkul a `@PreAuthorize("hasAnyAuthority('VIDEO_EXPORT', ...)")`
 * mintat hasznalo endpointok (CameraExportController, DariusReportController, stb.)
 * minden jogosult felhasznalonak is 403-at adnak.</p>
 */
class JwtAuthenticationFilterPermissionAuthorityTest {

    private JwtTokenProvider jwtTokenProvider;
    private TokenBlacklistService tokenBlacklistService;
    private JwtAuthenticationFilter filter;

    @BeforeEach
    void setUp() {
        jwtTokenProvider = Mockito.mock(JwtTokenProvider.class);
        tokenBlacklistService = Mockito.mock(TokenBlacklistService.class);
        filter = new JwtAuthenticationFilter(jwtTokenProvider, tokenBlacklistService);
        SecurityContextHolder.clearContext();
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("JWT permissions claim minden elemebol SimpleGrantedAuthority lesz")
    void permissionsClaimBecomesAuthorities() throws Exception {
        String fakeJwt = "fake-jwt-token";
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();

        when(jwtTokenProvider.validateToken(fakeJwt)).thenReturn(true);
        when(jwtTokenProvider.getTokenIdFromToken(fakeJwt)).thenReturn("token-id-1");
        when(tokenBlacklistService.isBlacklisted("token-id-1")).thenReturn(false);
        when(jwtTokenProvider.getWorkerIdFromToken(fakeJwt)).thenReturn(42L);
        when(jwtTokenProvider.getWorkerCodeFromToken(fakeJwt)).thenReturn("P001");
        when(jwtTokenProvider.getRoleFromToken(fakeJwt)).thenReturn("ADMIN");
        when(jwtTokenProvider.getCompanyIdFromToken(fakeJwt)).thenReturn(companyId);
        when(jwtTokenProvider.getBranchIdFromToken(fakeJwt)).thenReturn(branchId);
        when(jwtTokenProvider.getActiveRoleFromToken(fakeJwt)).thenReturn("CASHIER");
        when(jwtTokenProvider.getPermissionsFromToken(fakeJwt))
            .thenReturn(List.of("VIDEO_EXPORT", "DARIUS_REPORT_RUN", "SYSTEM_ADMIN"));

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/camera/exports");
        request.addHeader("Authorization", "Bearer " + fakeJwt);
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        assertThat(auth).as("Authentication beallitva").isNotNull();
        List<String> authorityNames = auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .toList();
        assertThat(authorityNames)
            .as("ROLE_ADMIN + permission kodok mindegyike authority")
            .containsExactlyInAnyOrder(
                "ROLE_ADMIN",
                "VIDEO_EXPORT",
                "DARIUS_REPORT_RUN",
                "SYSTEM_ADMIN"
            );
    }

    @Test
    @DisplayName("permissions claim hianyzasa eseten csak ROLE_xxx authority")
    void noPermissionsFallbackToRoleOnly() throws Exception {
        String fakeJwt = "fake-jwt-empty-perms";
        when(jwtTokenProvider.validateToken(fakeJwt)).thenReturn(true);
        when(jwtTokenProvider.getTokenIdFromToken(fakeJwt)).thenReturn("token-id-2");
        when(tokenBlacklistService.isBlacklisted(anyString())).thenReturn(false);
        when(jwtTokenProvider.getWorkerIdFromToken(fakeJwt)).thenReturn(7L);
        when(jwtTokenProvider.getWorkerCodeFromToken(fakeJwt)).thenReturn("P002");
        when(jwtTokenProvider.getRoleFromToken(fakeJwt)).thenReturn("CASHIER");
        when(jwtTokenProvider.getCompanyIdFromToken(fakeJwt)).thenReturn(UUID.randomUUID());
        when(jwtTokenProvider.getBranchIdFromToken(fakeJwt)).thenReturn(UUID.randomUUID());
        when(jwtTokenProvider.getActiveRoleFromToken(fakeJwt)).thenReturn(null);
        when(jwtTokenProvider.getPermissionsFromToken(fakeJwt)).thenReturn(List.of());

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/transactions");
        request.addHeader("Authorization", "Bearer " + fakeJwt);
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        assertThat(auth).isNotNull();
        List<String> authorityNames = auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .toList();
        assertThat(authorityNames)
            .as("Csak ROLE_CASHIER, mert nincs permission")
            .containsExactly("ROLE_CASHIER");
    }

    @Test
    @DisplayName("null/blank permission elemek kihagyva (defenziv)")
    void nullAndBlankPermissionsAreSkipped() throws Exception {
        String fakeJwt = "fake-jwt-mixed-perms";
        when(jwtTokenProvider.validateToken(fakeJwt)).thenReturn(true);
        when(jwtTokenProvider.getTokenIdFromToken(fakeJwt)).thenReturn("token-id-3");
        when(tokenBlacklistService.isBlacklisted(anyString())).thenReturn(false);
        when(jwtTokenProvider.getWorkerIdFromToken(fakeJwt)).thenReturn(8L);
        when(jwtTokenProvider.getWorkerCodeFromToken(fakeJwt)).thenReturn("P003");
        when(jwtTokenProvider.getRoleFromToken(fakeJwt)).thenReturn("CASHIER");
        when(jwtTokenProvider.getCompanyIdFromToken(fakeJwt)).thenReturn(UUID.randomUUID());
        when(jwtTokenProvider.getBranchIdFromToken(fakeJwt)).thenReturn(UUID.randomUUID());
        when(jwtTokenProvider.getActiveRoleFromToken(fakeJwt)).thenReturn(null);
        // Mockito nem fogadja a null-t List.of()-ban — ArrayList-tel hozzuk
        java.util.List<String> mixed = new java.util.ArrayList<>();
        mixed.add("VALID_PERM");
        mixed.add(null);
        mixed.add("");
        mixed.add("   ");
        mixed.add("ANOTHER_PERM");
        when(jwtTokenProvider.getPermissionsFromToken(fakeJwt)).thenReturn(mixed);

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/test");
        request.addHeader("Authorization", "Bearer " + fakeJwt);
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        assertThat(auth).isNotNull();
        List<String> authorityNames = auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .toList();
        assertThat(authorityNames)
            .as("Csak nem-blank permission-ok kerulnek be authority-kent")
            .containsExactlyInAnyOrder("ROLE_CASHIER", "VALID_PERM", "ANOTHER_PERM");
    }
}
