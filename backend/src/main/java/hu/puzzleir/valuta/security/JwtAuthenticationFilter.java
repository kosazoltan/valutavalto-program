package hu.puzzleir.valuta.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import hu.puzzleir.valuta.service.TokenBlacklistService;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

/**
 * JWT Authentication Filter - minden request-nél ellenőrzi a token-t.
 * Blacklist ellenőrzés: kijelentkeztetett tokeneket elutasítja.
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;
    private final TokenBlacklistService tokenBlacklistService;

    public JwtAuthenticationFilter(JwtTokenProvider jwtTokenProvider,
                                   TokenBlacklistService tokenBlacklistService) {
        this.jwtTokenProvider = jwtTokenProvider;
        this.tokenBlacklistService = tokenBlacklistService;
    }
    
    @Override
    protected void doFilterInternal(HttpServletRequest request, 
                                    HttpServletResponse response, 
                                    FilterChain filterChain) 
            throws ServletException, IOException {
        
        String jwt = getJwtFromRequest(request);
        
        if (!StringUtils.hasText(jwt)) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            if (jwtTokenProvider.validateToken(jwt)) {
                String tokenId = jwtTokenProvider.getTokenIdFromToken(jwt);
                if (tokenBlacklistService.isBlacklisted(tokenId)) {
                    // CodeQL java/sensitive-log + log-injection fix:
                    // - parent OncePerRequestFilter.logger Apache Commons Logging Log,
                    //   ami String.format-os "{}" placeholder-t NEM tamogat.
                    // - Hash-elt tokenId (Integer.toHexString) String.format()-tal,
                    //   szandekosan int->hex (NEM user-input string-szel concat-elt
                    //   tokenId, ezert log-injection sem aktiv).
                    logger.warn(String.format("Blacklisted token used: tokenIdHash=%s",
                            Integer.toHexString(tokenId.hashCode())));
                    response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Token blacklisted");
                    return;
                }

                Long workerId = jwtTokenProvider.getWorkerIdFromToken(jwt);
                String workerCode = jwtTokenProvider.getWorkerCodeFromToken(jwt);
                String role = jwtTokenProvider.getRoleFromToken(jwt);
                UUID companyId = jwtTokenProvider.getCompanyIdFromToken(jwt);
                UUID branchId = jwtTokenProvider.getBranchIdFromToken(jwt);

                // Audit P0.4 (2026-05-03): a JWT `permissions` claim-et SimpleGrantedAuthority-va
                // konvertaljuk, hogy a `@PreAuthorize("hasAnyAuthority('VIDEO_EXPORT', ...)")`
                // mintat hasznalo endpointok (CameraExportController, DariusReportController, stb.)
                // ne adjanak 403-at jogosult felhasznaloknak. Korabban CSAK a `ROLE_<role>`
                // authority kerult be, igy a permission-alapu vedelem teljesen torott volt.
                List<SimpleGrantedAuthority> authorities = new ArrayList<>();
                authorities.add(new SimpleGrantedAuthority("ROLE_" + role));

                String activeRole = jwtTokenProvider.getActiveRoleFromToken(jwt);
                String activeRoleAuthority = normalizeOperationalRoleForAuthority(activeRole);
                if (activeRoleAuthority != null && !activeRoleAuthority.equals(role)) {
                    authorities.add(new SimpleGrantedAuthority("ROLE_" + activeRoleAuthority));
                }

                // FK-076 (B1 + appMode-szures): a `grantedRoles` claim MINDEN canonical
                // szerepkoret authority-va tesszuk. Korabban csak `ROLE_<worker.role>` +
                // `ROLE_<activeRole>` keletkezett, mikozben a frontend a login-valasz teljes
                // canonical listajaval kapuzott -> a UI engedte, a szerver 403-azott
                // (AML threshold, discount apply, HANDLING_FEE mentes).
                // A claim mar a login/role-select/refresh againal appMode-ra van szurve, ezert
                // a penztargep-token itt sem kaphat ertektar-authority-t. Regi, claim nelkuli
                // tokeneknel a lista ures -> a fenti ket authority marad (backward compat).
                for (String grantedRole : jwtTokenProvider.getGrantedRolesFromToken(jwt)) {
                    String grantedAuthority = normalizeOperationalRoleForAuthority(grantedRole);
                    if (grantedAuthority != null) {
                        SimpleGrantedAuthority authority = new SimpleGrantedAuthority("ROLE_" + grantedAuthority);
                        if (!authorities.contains(authority)) {
                            authorities.add(authority);
                        }
                    }
                }

                List<String> permissions = jwtTokenProvider.getPermissionsFromToken(jwt);
                if (permissions != null) {
                    for (String perm : permissions) {
                        if (perm != null && !perm.isBlank()) {
                            // Sourcery PR #353 follow-up: trim a permission string-en, hogy a
                            // " VIDEO_EXPORT " (extra whitespace) NE adjon eltero authority-t,
                            // mint amit a `@PreAuthorize("hasAnyAuthority('VIDEO_EXPORT')")` var.
                            authorities.add(new SimpleGrantedAuthority(perm.trim()));
                        }
                    }
                }

                UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                        workerCode,
                        null,
                        authorities
                    );

                WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
                    workerId, companyId, branchId, role, activeRole
                );
                authentication.setDetails(details);
                
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
            
            filterChain.doFilter(request, response);
        } catch (JwtTokenException ex) {
            logger.warn("JWT token rejected: " + ex.getMessage());
            SecurityContextHolder.clearContext();
            filterChain.doFilter(request, response);
        } catch (Exception ex) {
            logger.error("Unexpected authentication error — rejecting request", ex);
            SecurityContextHolder.clearContext();
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Authentication failed");
        }
    }

    private String normalizeOperationalRoleForAuthority(String activeRole) {
        if (activeRole == null || activeRole.isBlank()) {
            return null;
        }

        String normalized = activeRole.trim().toUpperCase(Locale.ROOT);
        return switch (normalized) {
            case "CHIEF_VAULT" -> "FOERTEKTAR";
            case "DIRECTOR" -> "UGYVEZETO";
            case "CASHIER" -> "PENZTAR";
            case "VAULT_KEEPER" -> "ERTEKTAR";
            case "COURIER" -> "ERTEKSZALLITO";
            case "OFFICE_MGR" -> "IRODAVEZETO";
            case "REGIONAL_MGR" -> "TERULETI_VEZETO";
            case "AUDITOR" -> "BELSO_ELLENOR";
            case "SECURITY" -> "BIZTONSAGI_VEZETO";
            default -> normalized;
        };
    }
    
    /**
     * JWT kinyerése Authorization header-ből
     */
    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
