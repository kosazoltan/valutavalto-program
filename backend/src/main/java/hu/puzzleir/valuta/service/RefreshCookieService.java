package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.BusinessException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import org.springframework.stereotype.Service;

import java.time.Duration;

@Service
@RequiredArgsConstructor
@Slf4j
public class RefreshCookieService {

    public static final String COOKIE_NAME = "refreshToken";
    public static final String COOKIE_PATH = "/api/v1/auth";
    public static final String SAME_SITE = "Strict";

    private static final Duration COOKIE_MAX_AGE = Duration.ofDays(7);
    private static final String LOGIN_SESSION_ISSUE_FAILED = "LOGIN_SESSION_ISSUE_FAILED";

    private final RefreshTokenService refreshTokenService;

    public void issueOrThrow(
            Worker worker,
            HttpServletRequest request,
            HttpServletResponse response,
            String logContext,
            String userMessage) {
        issueOrThrow(worker, request, response, null, logContext, userMessage);
    }

    public void issueOrThrow(
            Worker worker,
            HttpServletRequest request,
            HttpServletResponse response,
            String activeRole,
            String logContext,
            String userMessage) {
        issueOrThrow(worker, request, response, activeRole, null, logContext, userMessage);
    }

    /**
     * FK-076: kibocsatas a kliens appMode-javal — a silent refresh ebbol szuri ujra a JWT
     * {@code grantedRoles} claim-et, hogy a rotacio ne kerulje meg az appMode-izolaciot.
     */
    public void issueOrThrow(
            Worker worker,
            HttpServletRequest request,
            HttpServletResponse response,
            String activeRole,
            String appMode,
            String logContext,
            String userMessage) {
        try {
            RefreshTokenService.IssuedToken issued =
                    refreshTokenService.issue(worker, request, activeRole, appMode);
            addIssuedCookie(issued, request, response);
        } catch (Exception e) {
            log.error("{}: {}", logContext, e.getMessage(), e);
            throw new BusinessException(
                    userMessage,
                    LOGIN_SESSION_ISSUE_FAILED,
                    HttpStatus.SERVICE_UNAVAILABLE);
        }
    }

    public void addIssuedCookie(
            RefreshTokenService.IssuedToken issued,
            HttpServletRequest request,
            HttpServletResponse response) {
        addCookie(response, request.isSecure(), issued.rawUuid(), COOKIE_MAX_AGE);
    }

    public void clearCookie(HttpServletRequest request, HttpServletResponse response) {
        addCookie(response, request.isSecure(), "", Duration.ZERO);
    }

    public String extractRefreshCookie(HttpServletRequest request) {
        if (request.getCookies() == null) {
            return null;
        }
        for (Cookie cookie : request.getCookies()) {
            if (COOKIE_NAME.equals(cookie.getName())) {
                return cookie.getValue();
            }
        }
        return null;
    }

    private static void addCookie(
            HttpServletResponse response,
            boolean secure,
            String value,
            Duration maxAge) {
        ResponseCookie cookie = ResponseCookie.from(COOKIE_NAME, value)
                .httpOnly(true)
                .secure(secure)
                .sameSite(SAME_SITE)
                .path(COOKIE_PATH)
                .maxAge(maxAge)
                .build();
        response.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());
    }
}
