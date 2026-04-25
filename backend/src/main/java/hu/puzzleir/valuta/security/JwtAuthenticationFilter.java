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

import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.UnsupportedJwtException;

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
        
        String jwt = getJwtFromRequest(request);
        
        if (!StringUtils.hasText(jwt)) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            if (jwtTokenProvider.validateToken(jwt)) {
                String tokenId = jwtTokenProvider.getTokenIdFromToken(jwt);
                if (tokenBlacklistService.isBlacklisted(tokenId)) {
                    // CodeQL java/sensitive-log + log-injection fix: hash-elt tokenId,
                    // SLF4J parameterized format (string concat helyett), nem-rekonstrualhato.
                    logger.warn("Blacklisted token used: tokenIdHash={}", Integer.toHexString(tokenId.hashCode()));
                    response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Token blacklisted");
                    return;
                }

                Long workerId = jwtTokenProvider.getWorkerIdFromToken(jwt);
                String workerCode = jwtTokenProvider.getWorkerCodeFromToken(jwt);
                String role = jwtTokenProvider.getRoleFromToken(jwt);
                UUID companyId = jwtTokenProvider.getCompanyIdFromToken(jwt);
                UUID branchId = jwtTokenProvider.getBranchIdFromToken(jwt);
                
                SimpleGrantedAuthority authority = new SimpleGrantedAuthority("ROLE_" + role);
                
                UsernamePasswordAuthenticationToken authentication = 
                    new UsernamePasswordAuthenticationToken(
                        workerCode, 
                        null, 
                        Collections.singletonList(authority)
                    );
                
                String activeRole = jwtTokenProvider.getActiveRoleFromToken(jwt);

                WorkerAuthenticationDetails details = new WorkerAuthenticationDetails(
                    workerId, companyId, branchId, role, activeRole
                );
                authentication.setDetails(details);
                
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
            
            filterChain.doFilter(request, response);
        } catch (ExpiredJwtException | MalformedJwtException | UnsupportedJwtException
                 | io.jsonwebtoken.security.SignatureException ex) {
            logger.warn("JWT token rejected: " + ex.getMessage());
            SecurityContextHolder.clearContext();
            filterChain.doFilter(request, response);
        } catch (Exception ex) {
            logger.error("Unexpected authentication error — rejecting request", ex);
            SecurityContextHolder.clearContext();
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Authentication failed");
        }
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
