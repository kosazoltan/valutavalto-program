package hu.puzzleir.valuta.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import hu.puzzleir.valuta.service.TokenBlacklistService;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;
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
        
        try {
            String jwt = getJwtFromRequest(request);
            
            if (StringUtils.hasText(jwt) && jwtTokenProvider.validateToken(jwt)) {
                // 🔴 Blacklist ellenőrzés — kijelentkeztetett token elutasítása
                String tokenId = jwtTokenProvider.getTokenIdFromToken(jwt);
                if (tokenBlacklistService.isBlacklisted(tokenId)) {
                    logger.warn("Blacklisted token used: tokenId=" + tokenId);
                    response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Token blacklisted");
                    return;
                }

                Long workerId = jwtTokenProvider.getWorkerIdFromToken(jwt);
                String workerCode = jwtTokenProvider.getWorkerCodeFromToken(jwt);
                String role = jwtTokenProvider.getRoleFromToken(jwt);
                UUID companyId = jwtTokenProvider.getCompanyIdFromToken(jwt);
                UUID branchId = jwtTokenProvider.getBranchIdFromToken(jwt);
                
                // Authority létrehozás role alapján
                SimpleGrantedAuthority authority = new SimpleGrantedAuthority("ROLE_" + role);
                
                // Authentication object
                UsernamePasswordAuthenticationToken authentication = 
                    new UsernamePasswordAuthenticationToken(
                        workerCode, 
                        null, 
                        Collections.singletonList(authority)
                    );
                
                // Operatív szerepkör kinyerése (V57)
                String activeRole = jwtTokenProvider.getActiveRoleFromToken(jwt);

                // Custom details (workerId, companyId, branchId, role, activeRole)
                WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
                    workerId, companyId, branchId, role, activeRole
                );
                authentication.setDetails(details);
                
                // SecurityContext beállítás
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        } catch (Exception ex) {
            logger.error("Could not set user authentication in security context", ex);
        }
        
        filterChain.doFilter(request, response);
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
